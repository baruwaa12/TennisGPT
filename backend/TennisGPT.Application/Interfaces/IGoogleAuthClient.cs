namespace TennisGPT.Application.Interfaces;

public interface IGoogleAuthClient
{
    Task<GoogleUserInfo?> ValidateIdTokenAsync(string idToken);
}

public class GoogleUserInfo
{
    public required string GoogleId { get; set; }
    public required string Email { get; set; }
    public string? DisplayName { get; set; }
    public string? PhotoUrl { get; set; }
}
