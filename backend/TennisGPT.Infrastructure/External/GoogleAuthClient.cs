using System.Net.Http.Json;
using System.Text.Json.Serialization;
using Google.Apis.Auth;
using Microsoft.Extensions.Configuration;
using TennisGPT.Application.Interfaces;

namespace TennisGPT.Infrastructure.External;

public class GoogleAuthClient : IGoogleAuthClient
{
    private readonly List<string> _clientIds;
    private readonly HttpClient _httpClient;

    public GoogleAuthClient(IConfiguration configuration, HttpClient httpClient)
    {
        // Support multiple client IDs (web, iOS, Android) separated by semicolons
        var clientIdConfig = configuration["Google:ClientId"]
            ?? throw new InvalidOperationException("Google:ClientId not configured");
        
        _clientIds = clientIdConfig
            .Split(';', StringSplitOptions.RemoveEmptyEntries)
            .Select(id => id.Trim())
            .Where(id => !string.IsNullOrEmpty(id))
            .ToList();
        
        if (_clientIds.Count == 0)
        {
            throw new InvalidOperationException("Google:ClientId must contain at least one valid client ID");
        }
        
        _httpClient = httpClient;
    }

    public async Task<GoogleUserInfo?> ValidateIdTokenAsync(string idToken)
    {
        try
        {
            // Accept tokens from any of the configured client IDs
            var settings = new GoogleJsonWebSignature.ValidationSettings
            {
                Audience = _clientIds
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

    public async Task<GoogleUserInfo?> ValidateAccessTokenAsync(string accessToken)
    {
        try
        {
            // Call Google's userinfo endpoint to validate access token and get user info
            var request = new HttpRequestMessage(HttpMethod.Get, "https://www.googleapis.com/oauth2/v3/userinfo");
            request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);

            var response = await _httpClient.SendAsync(request);
            
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            var userInfo = await response.Content.ReadFromJsonAsync<GoogleUserInfoResponse>();
            
            if (userInfo == null || string.IsNullOrEmpty(userInfo.Sub))
            {
                return null;
            }

            return new GoogleUserInfo
            {
                GoogleId = userInfo.Sub,
                Email = userInfo.Email ?? "",
                DisplayName = userInfo.Name,
                PhotoUrl = userInfo.Picture
            };
        }
        catch
        {
            return null;
        }
    }

    private class GoogleUserInfoResponse
    {
        [JsonPropertyName("sub")]
        public string? Sub { get; set; }
        
        [JsonPropertyName("email")]
        public string? Email { get; set; }
        
        [JsonPropertyName("name")]
        public string? Name { get; set; }
        
        [JsonPropertyName("picture")]
        public string? Picture { get; set; }
    }
}
