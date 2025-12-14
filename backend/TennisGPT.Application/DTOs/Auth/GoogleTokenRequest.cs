namespace TennisGPT.Application.DTOs.Auth;

public class GoogleTokenRequest
{
    // ID Token - provided by mobile apps (Android/iOS)
    public string? IdToken { get; set; }
    
    // Access Token - provided by web apps
    public string? AccessToken { get; set; }
}
