using System.Text.Json.Serialization;

namespace TennisGPT.Application.DTOs.Coaching;

/// <summary>
/// Structured tactical coach response built for fast scanning between matches.
/// </summary>
public class TacticalAnalysisResponse
{
    [JsonPropertyName("whatYoureSeeing")]
    public string WhatYoureSeeing { get; set; } = string.Empty;

    [JsonPropertyName("whyItMatters")]
    public string WhyItMatters { get; set; } = string.Empty;

    [JsonPropertyName("nextFocus")]
    public string NextFocus { get; set; } = string.Empty;

    [JsonPropertyName("optionalPracticePlan")]
    public PracticePlanBlock? OptionalPracticePlan { get; set; }
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
