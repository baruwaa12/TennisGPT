using TennisGPT.Application.DTOs.Auth;

namespace TennisGPT.Application.Interfaces;

public interface IAuthService
{
    Task<AuthResponse> AuthenticateWithGoogleAsync(string idToken);
    Task<AuthResponse> RefreshTokenAsync(string refreshToken);
    Task RevokeRefreshTokenAsync(Guid userId);
    Task<UserDto?> GetCurrentUserAsync(Guid userId);
}
