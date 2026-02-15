using System.Text.Json.Serialization;

namespace TennisGPT.Application.DTOs.Coaching;

/// <summary>
/// Structured tactical analysis response — Control Mode format.
/// 4 sections: What To Control, Next Match Rule, Constraint Drill, Reminder.
/// Plus Pattern Detection when match history is available.
/// Total output: 120–160 words.
/// </summary>
public class TacticalAnalysisResponse
{
    [JsonPropertyName("whatToControl")]
    public string WhatToControl { get; set; } = string.Empty;

    [JsonPropertyName("nextMatchRule")]
    public string NextMatchRule { get; set; } = string.Empty;

    [JsonPropertyName("constraintDrill")]
    public string ConstraintDrill { get; set; } = string.Empty;

    [JsonPropertyName("reminder")]
    public string Reminder { get; set; } = string.Empty;

    [JsonPropertyName("patternDetection")]
    public PatternDetectionBlock? PatternDetection { get; set; }
}

/// <summary>
/// Pattern Detection block — populated when sufficient match history exists.
/// Identifies recurring mechanical or tactical trends across logged matches.
/// </summary>
public class PatternDetectionBlock
{
    [JsonPropertyName("recurringPattern")]
    public string RecurringPattern { get; set; } = string.Empty;

    [JsonPropertyName("frequency")]
    public string Frequency { get; set; } = string.Empty;

    [JsonPropertyName("trigger")]
    public string Trigger { get; set; } = string.Empty;

    [JsonPropertyName("longTermFix")]
    public string LongTermFix { get; set; } = string.Empty;
}
