namespace TennisGPT.Application.DTOs.Auth;

public class AuthResponse
{
    public required string AccessToken { get; set; }
    public string? RefreshToken { get; set; }
    public required UserDto User { get; set; }
}
