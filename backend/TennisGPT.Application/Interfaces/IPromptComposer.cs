namespace TennisGPT.Application.Interfaces;

public interface IPromptComposer
{
    Task<string> ComposeAsync(
        IEnumerable<string> promptPaths,
        IReadOnlyDictionary<string, string>? variables = null,
        CancellationToken cancellationToken = default);
}
