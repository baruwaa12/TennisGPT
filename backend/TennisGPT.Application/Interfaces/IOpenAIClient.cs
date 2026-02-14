namespace TennisGPT.Application.Interfaces;

public interface IOpenAIClient
{
    Task<string> SendPromptAsync(string prompt, string? systemPrompt = null, double? temperature = null);
}
