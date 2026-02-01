namespace TennisGPT.Application.DTOs.Auth;

public class AppleTokenRequest
{
    public required string IdentityToken { get; set; }
    public string? Email { get; set; }
    public string? DisplayName { get; set; }
}

