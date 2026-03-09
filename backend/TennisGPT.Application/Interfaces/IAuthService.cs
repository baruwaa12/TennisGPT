using TennisGPT.Application.DTOs.Auth;

namespace TennisGPT.Application.Interfaces;

public interface IAuthService
{
    Task<AuthResponse> AuthenticateWithGoogleAsync(string? idToken, string? accessToken);
    Task<AuthResponse> AuthenticateWithAppleAsync(string identityToken, string? email, string? displayName);
    Task<AuthResponse> RefreshTokenAsync(string refreshToken);
    Task RevokeRefreshTokenAsync(Guid userId);
    Task<bool> DeleteAccountAsync(Guid userId);
    Task<UserDto?> GetCurrentUserAsync(Guid userId);
    Task MarkOnboardingCompleteAsync(Guid userId);
}
