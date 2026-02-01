using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using TennisGPT.Application.DTOs.Auth;
using TennisGPT.Application.Interfaces;
using TennisGPT.Domain.Entities;

namespace TennisGPT.Application.Services;

public class AuthService : IAuthService
{
    private readonly IUserRepository _userRepository;
    private readonly IGoogleAuthClient _googleAuthClient;
    private readonly IAppleAuthClient _appleAuthClient;
    private readonly IConfiguration _configuration;

    public AuthService(
        IUserRepository userRepository,
        IGoogleAuthClient googleAuthClient,
        IAppleAuthClient appleAuthClient,
        IConfiguration configuration)
    {
        _userRepository = userRepository;
        _googleAuthClient = googleAuthClient;
        _appleAuthClient = appleAuthClient;
        _configuration = configuration;
    }

    public async Task<AuthResponse> AuthenticateWithGoogleAsync(string? idToken, string? accessToken)
    {
        GoogleUserInfo? googleUser = null;

        // Try ID token first (mobile apps)
        if (!string.IsNullOrEmpty(idToken))
        {
            googleUser = await _googleAuthClient.ValidateIdTokenAsync(idToken);
        }

        // Fall back to access token (web apps)
        if (googleUser == null && !string.IsNullOrEmpty(accessToken))
        {
            googleUser = await _googleAuthClient.ValidateAccessTokenAsync(accessToken);
        }

        if (googleUser == null)
        {
            throw new UnauthorizedAccessException("Invalid Google token");
        }

        // Find or create user
        var user = await _userRepository.GetByGoogleIdAsync(googleUser.GoogleId);

        if (user == null)
        {
            user = await _userRepository.CreateAsync(new User
            {
                GoogleId = googleUser.GoogleId,
                Email = googleUser.Email,
                DisplayName = googleUser.DisplayName,
                PhotoUrl = googleUser.PhotoUrl,
                LastLoginAt = DateTime.UtcNow
            });
        }
        else
        {
            // Update user info from Google
            user.Email = googleUser.Email;
            user.DisplayName = googleUser.DisplayName;
            user.PhotoUrl = googleUser.PhotoUrl;
            user.LastLoginAt = DateTime.UtcNow;
            await _userRepository.UpdateAsync(user);
        }

        // Generate tokens
        var jwtToken = GenerateJwtToken(user);
        var newRefreshToken = GenerateRefreshToken();

        // Store refresh token
        user.RefreshToken = newRefreshToken;
        user.RefreshTokenExpiry = DateTime.UtcNow.AddDays(7);
        await _userRepository.UpdateAsync(user);

        return new AuthResponse
        {
            AccessToken = jwtToken,
            RefreshToken = newRefreshToken,
            User = MapToDto(user)
        };
    }

    public async Task<AuthResponse> AuthenticateWithAppleAsync(string identityToken, string? email, string? displayName)
    {
        var appleUser = await _appleAuthClient.ValidateIdentityTokenAsync(identityToken);
        if (appleUser == null)
        {
            throw new UnauthorizedAccessException("Invalid Apple identity token");
        }

        // Prefer email from token; fall back to provided email from credential
        var resolvedEmail = appleUser.Email ?? email;

        // Find by Apple ID first
        var user = await _userRepository.GetByAppleIdAsync(appleUser.AppleId);

        // Fallback: link to existing account by email (if we have it)
        if (user == null && !string.IsNullOrWhiteSpace(resolvedEmail))
        {
            user = await _userRepository.GetByEmailAsync(resolvedEmail);
        }

        if (user == null)
        {
            if (string.IsNullOrWhiteSpace(resolvedEmail))
            {
                throw new UnauthorizedAccessException("Apple account email not available. Please re-authorize.");
            }

            user = await _userRepository.CreateAsync(new User
            {
                GoogleId = $"apple:{appleUser.AppleId}", // Required field, namespace to avoid collisions
                AppleId = appleUser.AppleId,
                Email = resolvedEmail,
                DisplayName = displayName,
                LastLoginAt = DateTime.UtcNow
            });
        }
        else
        {
            // Link Apple ID if not already set
            if (string.IsNullOrEmpty(user.AppleId))
            {
                user.AppleId = appleUser.AppleId;
            }

            // Update email/name if provided
            if (!string.IsNullOrWhiteSpace(resolvedEmail))
            {
                user.Email = resolvedEmail;
            }
            if (!string.IsNullOrWhiteSpace(displayName))
            {
                user.DisplayName = displayName;
            }

            user.LastLoginAt = DateTime.UtcNow;
            await _userRepository.UpdateAsync(user);
        }

        // Generate tokens
        var jwtToken = GenerateJwtToken(user);
        var newRefreshToken = GenerateRefreshToken();

        // Store refresh token
        user.RefreshToken = newRefreshToken;
        user.RefreshTokenExpiry = DateTime.UtcNow.AddDays(7);
        await _userRepository.UpdateAsync(user);

        return new AuthResponse
        {
            AccessToken = jwtToken,
            RefreshToken = newRefreshToken,
            User = MapToDto(user)
        };
    }

    public async Task<AuthResponse> RefreshTokenAsync(string refreshToken)
    {
        var user = await _userRepository.GetByRefreshTokenAsync(refreshToken)
            ?? throw new UnauthorizedAccessException("Invalid refresh token");

        if (user.RefreshTokenExpiry < DateTime.UtcNow)
        {
            throw new UnauthorizedAccessException("Refresh token expired");
        }

        // Generate new tokens
        var accessToken = GenerateJwtToken(user);
        var newRefreshToken = GenerateRefreshToken();

        // Update refresh token
        user.RefreshToken = newRefreshToken;
        user.RefreshTokenExpiry = DateTime.UtcNow.AddDays(7);
        await _userRepository.UpdateAsync(user);

        return new AuthResponse
        {
            AccessToken = accessToken,
            RefreshToken = newRefreshToken,
            User = MapToDto(user)
        };
    }

    public async Task RevokeRefreshTokenAsync(Guid userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user != null)
        {
            user.RefreshToken = null;
            user.RefreshTokenExpiry = null;
            await _userRepository.UpdateAsync(user);
        }
    }

    public async Task<UserDto?> GetCurrentUserAsync(Guid userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        return user != null ? MapToDto(user) : null;
    }

    public async Task MarkOnboardingCompleteAsync(Guid userId)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user != null)
        {
            user.OnboardingCompleted = true;
            await _userRepository.UpdateAsync(user);
        }
    }

    private string GenerateJwtToken(User user)
    {
        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]
                ?? throw new InvalidOperationException("JWT Key not configured")));

        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim("name", user.DisplayName ?? "")
        };

        var expiryMinutes = int.Parse(_configuration["Jwt:ExpiryMinutes"] ?? "60");

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expiryMinutes),
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static string GenerateRefreshToken()
    {
        var randomBytes = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomBytes);
        return Convert.ToBase64String(randomBytes);
    }

    private static UserDto MapToDto(User user)
    {
        return new UserDto
        {
            Id = user.Id,
            Email = user.Email,
            DisplayName = user.DisplayName,
            PhotoUrl = user.PhotoUrl,
            Plan = user.Plan.ToString().ToLower(),
            OnboardingCompleted = user.OnboardingCompleted,
            TacticalUsedThisPeriod = user.TacticalUsedPeriod,
            TacticalRemaining = user.GetRemainingTacticalAnalyses(),
            IsComped = user.IsComped
        };
    }
}
