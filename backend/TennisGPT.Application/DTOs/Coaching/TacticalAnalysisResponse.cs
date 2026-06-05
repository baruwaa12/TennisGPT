using System.Text.Json.Serialization;

namespace TennisGPT.Application.DTOs.Coaching;

/// <summary>
/// Structured tactical coach response built for fast scanning between matches.
/// </summary>
public class TacticalAnalysisResponse
{
    [JsonPropertyName("dataScope")]
    public DataScopeBlock? DataScope { get; set; }

    [JsonPropertyName("whatKeepsShowingUp")]
    public SectionBlock WhatKeepsShowingUp { get; set; } = new();

    [JsonPropertyName("whatsHelpingYouWin")]
    public SectionBlock WhatsHelpingYouWin { get; set; } = new();

    [JsonPropertyName("whatBreaksUnderPressure")]
    public SectionBlock WhatBreaksUnderPressure { get; set; } = new();

    [JsonPropertyName("nextMatchFocus")]
    public NextMatchFocusBlock NextMatchFocus { get; set; } = new();

    [JsonPropertyName("optionalPracticePlan")]
    public PracticePlanBlock? OptionalPracticePlan { get; set; }
}

public class DataScopeBlock
{
    [JsonPropertyName("matchesUsed")]
    public int MatchesUsed { get; set; }

    [JsonPropertyName("note")]
    public string Note { get; set; } = string.Empty;
}

public class SectionBlock
{
    [JsonPropertyName("text")]
    public string Text { get; set; } = string.Empty;

    [JsonPropertyName("evidence")]
    public string Evidence { get; set; } = string.Empty;

    [JsonPropertyName("confidence")]
    public string Confidence { get; set; } = string.Empty;

    [JsonPropertyName("trend")]
    public string Trend { get; set; } = string.Empty;
}

public class NextMatchFocusBlock
{
    [JsonPropertyName("text")]
    public string Text { get; set; } = string.Empty;

    [JsonPropertyName("triggerRule")]
    public string TriggerRule { get; set; } = string.Empty;

    [JsonPropertyName("confidence")]
    public string Confidence { get; set; } = string.Empty;
}

/// <summary>
/// Optional short practice block. Omitted unless the evidence supports a useful drill.
/// </summary>
public class PracticePlanBlock
{
    [JsonPropertyName("drillName")]
    public string DrillName { get; set; } = string.Empty;

    [JsonPropertyName("objective")]
    public string Objective { get; set; } = string.Empty;
}
