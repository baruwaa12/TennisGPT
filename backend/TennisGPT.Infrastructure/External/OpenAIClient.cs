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

    private const string DefaultSystemPrompt = "You are a helpful tennis coaching assistant.";
    private const double DefaultTemperature = 0.5;
    private const int DefaultMaxTokens = 1500;

    public OpenAIClient(HttpClient httpClient, IConfiguration configuration, ILogger<OpenAIClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _httpClient.BaseAddress = new Uri("https://api.openai.com/v1/");
        _httpClient.Timeout = TimeSpan.FromSeconds(60);

        var apiKey = configuration["OpenAI:ApiKey"]?.Trim();
        
        if (string.IsNullOrEmpty(apiKey) || apiKey == "REPLACE_WITH_ENV_VAR")
        {
            _logger.LogError("OpenAI:ApiKey not configured! AI features will not work.");
            _isConfigured = false;
        }
        else
        {
            _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {apiKey}");
            _isConfigured = true;
            _logger.LogInformation("OpenAI client configured successfully with model {Model}", configuration["OpenAI:Model"] ?? "gpt-4o-mini");
        }

        _model = configuration["OpenAI:Model"] ?? "gpt-4o-mini";
    }

    public async Task<string> SendPromptAsync(string prompt, string? systemPrompt = null, double? temperature = null)
    {
        if (!_isConfigured)
        {
            _logger.LogWarning("OpenAI API key not configured - returning fallback message");
            return "AI coaching is temporarily unavailable. Please try again later or contact support.";
        }

        var requestId = Guid.NewGuid().ToString("N")[..8];
        var effectiveSystemPrompt = systemPrompt ?? DefaultSystemPrompt;
        var effectiveTemp = temperature ?? DefaultTemperature;
        
        try
        {
            _logger.LogInformation("[{RequestId}] Sending prompt to OpenAI ({Length} chars)", requestId, prompt.Length);

            var content = await CallOpenAIAsync(prompt, effectiveSystemPrompt, effectiveTemp, requestId);
            
            if (content == null)
            {
                return "No response generated. Please try again.";
            }

            // Strip accidental backticks/markdown fencing from response
            content = StripMarkdownFencing(content);

            return content;
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

    /// <summary>
    /// Makes the actual HTTP call to OpenAI and extracts the content string.
    /// </summary>
    private async Task<string?> CallOpenAIAsync(string prompt, string systemPrompt, double temperature, string requestId)
    {
        var request = new
        {
            model = _model,
            messages = new[]
            {
                new { role = "system", content = systemPrompt },
                new { role = "user", content = prompt }
            },
            temperature = temperature,
            max_tokens = DefaultMaxTokens
        };

        var response = await _httpClient.PostAsJsonAsync("chat/completions", request);

        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync();
            _logger.LogError("[{RequestId}] OpenAI API error: {Status} - {Body}", 
                requestId, (int)response.StatusCode, errorBody);

            if ((int)response.StatusCode == 429)
                return null;
            if ((int)response.StatusCode == 401)
            {
                _logger.LogCritical("[{RequestId}] OpenAI API key is invalid!", requestId);
                return null;
            }
            if ((int)response.StatusCode >= 500)
                return null;

            return null;
        }

        var result = await response.Content.ReadFromJsonAsync<JsonDocument>();
        var content = result?.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        _logger.LogInformation("[{RequestId}] OpenAI response received ({Length} chars)", 
            requestId, content?.Length ?? 0);

        return content?.Trim();
    }

    /// <summary>
    /// Strips accidental markdown code fencing (```json ... ```) from AI responses.
    /// </summary>
    private static string StripMarkdownFencing(string content)
    {
        var trimmed = content.Trim();

        // Strip ```json ... ``` or ``` ... ```
        if (trimmed.StartsWith("```"))
        {
            // Remove opening fence (```json or ```)
            var firstNewline = trimmed.IndexOf('\n');
            if (firstNewline > 0)
            {
                trimmed = trimmed[(firstNewline + 1)..];
            }

            // Remove closing fence
            if (trimmed.EndsWith("```"))
            {
                trimmed = trimmed[..^3].TrimEnd();
            }
        }

        return trimmed;
    }
}
