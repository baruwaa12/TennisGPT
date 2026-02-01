using System.IdentityModel.Tokens.Jwt;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using TennisGPT.Application.Interfaces;

namespace TennisGPT.Infrastructure.External;

public class AppleAuthClient : IAppleAuthClient
{
    private const string AppleKeysUrl = "https://appleid.apple.com/auth/keys";
    private const string AppleIssuer = "https://appleid.apple.com";
    
    private readonly IConfiguration _configuration;
    private readonly HttpClient _httpClient;
    
    public AppleAuthClient(IConfiguration configuration, HttpClient httpClient)
    {
        _configuration = configuration;
        _httpClient = httpClient;
    }
    
    public async Task<AppleUserInfo?> ValidateIdentityTokenAsync(string identityToken)
    {
        try
        {
            var clientId = _configuration["Apple:ClientId"];
            if (string.IsNullOrWhiteSpace(clientId))
            {
                throw new InvalidOperationException("Apple ClientId not configured");
            }
            
            var jwksJson = await _httpClient.GetStringAsync(AppleKeysUrl);
            var jwks = new JsonWebKeySet(jwksJson);
            
            var tokenHandler = new JwtSecurityTokenHandler();
            var validationParams = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = AppleIssuer,
                ValidateAudience = true,
                ValidAudience = clientId,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                IssuerSigningKeys = jwks.Keys,
                ClockSkew = TimeSpan.FromMinutes(2)
            };
            
            var principal = tokenHandler.ValidateToken(identityToken, validationParams, out var validatedToken);
            var jwtToken = (JwtSecurityToken)validatedToken;
            
            var appleId = principal.FindFirst("sub")?.Value;
            if (string.IsNullOrEmpty(appleId))
            {
                return null;
            }
            
            var email = principal.FindFirst("email")?.Value;
            var emailVerified = principal.FindFirst("email_verified")?.Value == "true";
            
            return new AppleUserInfo
            {
                AppleId = appleId,
                Email = email,
                EmailVerified = emailVerified
            };
        }
        catch
        {
            return null;
        }
    }
}

