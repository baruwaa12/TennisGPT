using System.Text.Json.Serialization;

namespace TennisGPT.Application.DTOs.Coaching;

/// <summary>
/// Structured tactical analysis response from OpenAI.
/// Matches the enforced JSON output schema.
/// </summary>
public class TacticalAnalysisResponse
{
    [JsonPropertyName("summary")]
    public string Summary { get; set; } = string.Empty;

    [JsonPropertyName("recommendations")]
    public List<TacticalRecommendation> Recommendations { get; set; } = new();

    [JsonPropertyName("patternDetected")]
    public string PatternDetected { get; set; } = string.Empty;

    [JsonPropertyName("nextMatchFocus")]
    public string NextMatchFocus { get; set; } = string.Empty;
}

/// <summary>
/// A single tactical recommendation with title, reasoning, and execution.
/// </summary>
public class TacticalRecommendation
{
    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("why")]
    public string Why { get; set; } = string.Empty;

    [JsonPropertyName("how")]
    public string How { get; set; } = string.Empty;
}
