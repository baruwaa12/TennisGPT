using Microsoft.Extensions.Logging;
using TennisGPT.Application.Interfaces;

namespace TennisGPT.Application.Services;

public class PromptComposer : IPromptComposer
{
    private readonly ILogger<PromptComposer> _logger;

    public PromptComposer(ILogger<PromptComposer> logger)
    {
        _logger = logger;
    }

    public async Task<string> ComposeAsync(
        IEnumerable<string> promptPaths,
        IReadOnlyDictionary<string, string>? variables = null,
        CancellationToken cancellationToken = default)
    {
        var parts = new List<string>();

        foreach (var promptPath in promptPaths)
        {
            var fullPath = ResolvePromptPath(promptPath);
            if (!File.Exists(fullPath))
            {
                _logger.LogError("Prompt file not found: {PromptPath}", fullPath);
                throw new FileNotFoundException("Prompt file not found.", fullPath);
            }

            var content = await File.ReadAllTextAsync(fullPath, cancellationToken);
            parts.Add(ApplyVariables(content, variables));
        }

        return string.Concat(parts);
    }

    private static string ResolvePromptPath(string promptPath)
    {
        var normalized = promptPath.Replace('/', Path.DirectorySeparatorChar);
        return Path.Combine(AppContext.BaseDirectory, "Prompts", normalized);
    }

    private static string ApplyVariables(
        string content,
        IReadOnlyDictionary<string, string>? variables)
    {
        if (variables == null || variables.Count == 0)
            return content;

        foreach (var variable in variables)
        {
            content = content.Replace(
                "{{" + variable.Key + "}}",
                variable.Value,
                StringComparison.Ordinal);
        }

        return content;
    }
}
