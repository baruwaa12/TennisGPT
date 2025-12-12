using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using TennisGPT.Application.Interfaces;

namespace TennisGPT.Infrastructure.External;

public class OpenAIClient : IOpenAIClient
{
    private readonly HttpClient _httpClient;
    private readonly string _model;

    public OpenAIClient(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _httpClient.BaseAddress = new Uri("https://api.openai.com/v1/");

        var apiKey = configuration["OpenAI:ApiKey"]
            ?? throw new InvalidOperationException("OpenAI:ApiKey not configured");

        _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {apiKey}");

        _model = configuration["OpenAI:Model"] ?? "gpt-4o";
    }

    public async Task<string> SendPromptAsync(string prompt)
    {
        var request = new
        {
            model = _model,
            messages = new[]
            {
                new { role = "system", content = "You are a helpful tennis coaching assistant." },
                new { role = "user", content = prompt }
            },
            temperature = 0.7
        };

        var response = await _httpClient.PostAsJsonAsync("chat/completions", request);
        response.EnsureSuccessStatusCode();

        var result = await response.Content.ReadFromJsonAsync<JsonDocument>();
        var content = result?.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString();

        return content?.Trim() ?? throw new InvalidOperationException("No response from OpenAI");
    }
}
