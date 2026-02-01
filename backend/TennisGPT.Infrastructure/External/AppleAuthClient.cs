using System.IdentityModel.Tokens.Jwt;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using TennisGPT.Application.Interfaces;

namespace TennisGPT.Infrastructure.External;

public class AppleAuthClient : IAppleAuthClient
{
    private const string AppleKeysUrl = "https://appleid.apple.com/auth/keys";
    private const string AppleIssuer = "https://appleid.apple.com";
    
    private readonly IConfiguration _configuration;
    private readonly HttpClient _httpClient;
    private readonly ILogger<AppleAuthClient> _logger;
    
    public AppleAuthClient(IConfiguration configuration, HttpClient httpClient, ILogger<AppleAuthClient> logger)
    {
        _configuration = configuration;
        _httpClient = httpClient;
        _logger = logger;
    }
    
    public async Task<AppleUserInfo?> ValidateIdentityTokenAsync(string identityToken)
    {
        try
        {
            var clientId = _configuration["Apple:ClientId"];
            _logger.LogInformation("Apple ClientId from config: {ClientId}", clientId ?? "NULL");
            
            if (string.IsNullOrWhiteSpace(clientId))
            {
                _logger.LogError("Apple ClientId not configured in environment variables");
                throw new InvalidOperationException("Apple ClientId not configured");
            }
            
            // Decode token to see what audience it has (for debugging)
            var handler = new JwtSecurityTokenHandler();
            if (handler.CanReadToken(identityToken))
            {
                var jwt = handler.ReadJwtToken(identityToken);
                _logger.LogInformation("Token audience (aud): {Audience}", string.Join(", ", jwt.Audiences));
                _logger.LogInformation("Token issuer (iss): {Issuer}", jwt.Issuer);
                _logger.LogInformation("Expected audience: {Expected}", clientId);
            }
            
            var jwksJson = await _httpClient.GetStringAsync(AppleKeysUrl);
            var jwks = new JsonWebKeySet(jwksJson);
            
            var tokenHandler = new JwtSecurityTokenHandler();
            
            // Read the token first to get the actual audience for comparison
            var unvalidatedToken = tokenHandler.ReadJwtToken(identityToken);
            var tokenAudience = unvalidatedToken.Audiences.FirstOrDefault();
            
            _logger.LogInformation("=== APPLE TOKEN DEBUG ===");
            _logger.LogInformation("Configured ClientId: '{ConfiguredId}'", clientId);
            _logger.LogInformation("Token Audience: '{TokenAudience}'", tokenAudience);
            _logger.LogInformation("Audiences match: {Match}", tokenAudience == clientId);
            
            // Use the audience from the token if it differs (for debugging)
            var audienceToValidate = clientId;
            if (!string.IsNullOrEmpty(tokenAudience) && tokenAudience != clientId)
            {
                _logger.LogWarning("Audience mismatch! Token has '{TokenAud}' but config has '{ConfigAud}'. " +
                    "Update Apple__ClientId in Railway to: {TokenAud}", tokenAudience, clientId, tokenAudience);
            }
            
            var validationParams = new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidIssuer = AppleIssuer,
                ValidateAudience = true,
                ValidAudience = audienceToValidate,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                IssuerSigningKeys = jwks.Keys,
                ClockSkew = TimeSpan.FromMinutes(5) // Increased for clock differences
            };
            
            // Disable default claim mapping so 'sub' stays as 'sub'
            tokenHandler.InboundClaimTypeMap.Clear();
            
            var principal = tokenHandler.ValidateToken(identityToken, validationParams, out var validatedToken);
            var jwtToken = (JwtSecurityToken)validatedToken;
            
            // Try multiple ways to get the Apple ID (sub claim)
            var appleId = principal.FindFirst("sub")?.Value 
                ?? principal.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                ?? jwtToken.Subject;
            
            _logger.LogInformation("Found AppleId/sub: '{AppleId}'", appleId ?? "NULL");
            
            if (string.IsNullOrEmpty(appleId))
            {
                _logger.LogWarning("Apple token validated but no 'sub' claim found. Claims: {Claims}", 
                    string.Join(", ", principal.Claims.Select(c => $"{c.Type}={c.Value}")));
                return null;
            }
            
            var email = principal.FindFirst("email")?.Value 
                ?? principal.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value;
            var emailVerified = principal.FindFirst("email_verified")?.Value == "true";
            
            _logger.LogInformation("Apple Sign-In successful for AppleId: {AppleId}", appleId);
            
            return new AppleUserInfo
            {
                AppleId = appleId,
                Email = email,
                EmailVerified = emailVerified
            };
        }
        catch (SecurityTokenValidationException ex)
        {
            _logger.LogError(ex, "Apple token validation failed: {Message}", ex.Message);
            throw new InvalidOperationException($"Token validation failed: {ex.Message}", ex);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Apple Sign-In error: {Message}", ex.Message);
            throw new InvalidOperationException($"Apple auth error: {ex.Message}", ex);
        }
    }
}

