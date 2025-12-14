namespace TennisGPT.Application.Interfaces;

public interface IGoogleAuthClient
{
    // Validate ID token (for mobile apps)
    Task<GoogleUserInfo?> ValidateIdTokenAsync(string idToken);
    
    // Validate access token by calling Google's userinfo endpoint (for web apps)
    Task<GoogleUserInfo?> ValidateAccessTokenAsync(string accessToken);
}

public class GoogleUserInfo
{
    public required string GoogleId { get; set; }
    public required string Email { get; set; }
    public string? DisplayName { get; set; }
    public string? PhotoUrl { get; set; }
}
