using Google.Apis.Auth;
using Microsoft.Extensions.Configuration;
using TennisGPT.Application.Interfaces;

namespace TennisGPT.Infrastructure.External;

public class GoogleAuthClient : IGoogleAuthClient
{
    private readonly string _clientId;

    public GoogleAuthClient(IConfiguration configuration)
    {
        _clientId = configuration["Google:ClientId"]
            ?? throw new InvalidOperationException("Google:ClientId not configured");
    }

    public async Task<GoogleUserInfo?> ValidateIdTokenAsync(string idToken)
    {
        try
        {
            var settings = new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = [_clientId]
            };

            var payload = await GoogleJsonWebSignature.ValidateAsync(idToken, settings);

            return new GoogleUserInfo
            {
                GoogleId = payload.Subject,
                Email = payload.Email,
                DisplayName = payload.Name,
                PhotoUrl = payload.Picture
            };
        }
        catch (InvalidJwtException)
        {
            return null;
        }
    }
}
