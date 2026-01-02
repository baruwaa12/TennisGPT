using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using TennisGPT.Application.Interfaces;

namespace TennisGPT.Infrastructure.External;

public class OpenAIClient : IOpenAIClient
{
    private readonly HttpClient _httpClient;
    private readonly string _model;
    private readonly ILogger<OpenAIClient> _logger;
    private readonly bool _isConfigured;

    public OpenAIClient(HttpClient httpClient, IConfiguration configuration, ILogger<OpenAIClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _httpClient.BaseAddress = new Uri("https://api.openai.com/v1/");
        _httpClient.Timeout = TimeSpan.FromSeconds(60);

        var apiKey = configuration["OpenAI:ApiKey"];
        
        if (string.IsNullOrEmpty(apiKey) || apiKey == "REPLACE_WITH_ENV_VAR")
        {
            _logger.LogError("OpenAI:ApiKey not configured! AI features will not work.");
            _isConfigured = false;
        }
        else
        {
            _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {apiKey}");
            _isConfigured = true;
            _logger.LogInformation("OpenAI client configured successfully with model {Model}", configuration["OpenAI:Model"] ?? "gpt-4o");
        }

        _model = configuration["OpenAI:Model"] ?? "gpt-4o";
    }

    public async Task<string> SendPromptAsync(string prompt)
    {
        if (!_isConfigured)
        {
            _logger.LogWarning("OpenAI API key not configured - returning fallback message");
            return "AI coaching is temporarily unavailable. Please try again later or contact support.";
        }

        var requestId = Guid.NewGuid().ToString("N")[..8];
        
        try
        {
            _logger.LogInformation("[{RequestId}] Sending prompt to OpenAI ({Length} chars)", requestId, prompt.Length);

            var request = new
            {
                model = _model,
                messages = new[]
                {
                    new { role = "system", content = "You are a helpful tennis coaching assistant." },
                    new { role = "user", content = prompt }
                },
                temperature = 0.7,
                max_tokens = 1500
            };

            var response = await _httpClient.PostAsJsonAsync("chat/completions", request);

            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                _logger.LogError("[{RequestId}] OpenAI API error: {Status} - {Body}", 
                    requestId, (int)response.StatusCode, errorBody);

                // Handle specific error codes
                if ((int)response.StatusCode == 429)
                {
                    return "The coaching service is experiencing high demand. Please try again in a moment.";
                }
                if ((int)response.StatusCode == 401)
                {
                    _logger.LogCritical("[{RequestId}] OpenAI API key is invalid!", requestId);
                    return "AI coaching is temporarily unavailable. Please contact support.";
                }
                if ((int)response.StatusCode >= 500)
                {
                    return "OpenAI is experiencing issues. Please try again in a moment.";
                }

                return "Unable to generate coaching insight right now. Please try again.";
            }

            var result = await response.Content.ReadFromJsonAsync<JsonDocument>();
            var content = result?.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString();

            _logger.LogInformation("[{RequestId}] OpenAI response received ({Length} chars)", 
                requestId, content?.Length ?? 0);

            return content?.Trim() ?? "No response generated. Please try again.";
        }
        catch (TaskCanceledException ex) when (ex.InnerException is TimeoutException)
        {
            _logger.LogWarning("[{RequestId}] OpenAI request timed out", requestId);
            return "The request took too long. Please try again with a simpler question.";
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "[{RequestId}] Network error calling OpenAI", requestId);
            return "Unable to reach the coaching service. Please check your connection and try again.";
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "[{RequestId}] Failed to parse OpenAI response", requestId);
            return "Received an unexpected response. Please try again.";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[{RequestId}] Unexpected error in OpenAI call", requestId);
            return "Something went wrong. Please try again.";
        }
    }
}
