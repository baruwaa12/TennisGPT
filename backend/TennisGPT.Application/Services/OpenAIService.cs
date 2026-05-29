using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.Extensions.Logging;
using TennisGPT.Application.DTOs.Coaching;
using TennisGPT.Application.Interfaces;

namespace TennisGPT.Application.Services;

/// <summary>
/// AI coaching service with analytical, data-driven responses.
/// Tone: Analytical and Logical (locked per survey data — 60% preference).
/// </summary>
public class OpenAIService : IOpenAIService
{
    private readonly IOpenAIClient _openAIClient;
    private readonly IPromptComposer _promptComposer;
    private readonly ILogger<OpenAIService> _logger;

    private const double TacticalTemperature = 0.5;

    public OpenAIService(
        IOpenAIClient openAIClient,
        IPromptComposer promptComposer,
        ILogger<OpenAIService> logger)
    {
        _openAIClient = openAIClient;
        _promptComposer = promptComposer;
        _logger = logger;
    }

    /// <summary>
    /// Pre-Match Prep (formerly Mental Check-In) - Tactical preparation before a match
    /// </summary>
    public async Task<string> MentalCheckInAsync(int mood, string journalEntry)
    {
        var prompt = await _promptComposer.ComposeAsync(
            ["prematch/system.md"],
            new Dictionary<string, string>
            {
                ["mood"] = mood.ToString(),
                ["journalEntry"] = journalEntry
            });

        return await _openAIClient.SendPromptAsync(prompt);
    }

    /// <summary>
    /// Post-Match Debrief (formerly Emotional Reset) - Tactical analysis after a tough situation
    /// </summary>
    public async Task<string> EmotionalResetAsync(string situation)
    {
        var prompt = await _promptComposer.ComposeAsync(
            ["emotional-reset/system.md"],
            new Dictionary<string, string>
            {
                ["situation"] = situation
            });

        return await _openAIClient.SendPromptAsync(prompt);
    }

    /// <summary>
    /// Tactical Analysis — Core feature.
    /// Uses locked system prompt + structured JSON output.
    /// Parses response into TacticalAnalysisResponse; retries once on parse failure.
    /// </summary>
    public async Task<TacticalAnalysisResponse> TacticalAnalysisAsync(
        string matchDescription,
        string? recentMatchesJson,
        string? focusType,
        IReadOnlyList<string>? recentAdviceHistory)
    {
        var matchesContext = BuildMatchContext(recentMatchesJson);
        var recentAdviceContext = BuildRecentAdviceContext(recentAdviceHistory);
        var focusInstructions = BuildFocusInstructions(focusType);

        var variables = BuildTacticalVariables(
            matchDescription,
            matchesContext,
            recentAdviceContext,
            focusType,
            focusInstructions);
        var systemPrompt = await BuildTacticalSystemPromptAsync();
        var userPrompt = await _promptComposer.ComposeAsync(
            ["tactical/user-analysis.md"],
            variables);

        // First attempt
        var rawResponse = await _openAIClient.SendPromptAsync(
            userPrompt,
            systemPrompt,
            TacticalTemperature);
        
        var parsed = TryParseTacticalResponse(rawResponse);
        if (parsed != null)
        {
            return await EnsureNoveltyIfNeededAsync(
                parsed,
                matchDescription,
                matchesContext,
                recentAdviceContext,
                focusType,
                focusInstructions,
                recentAdviceHistory);
        }

        // Don't retry if the response is a known error/fallback (not AI content)
        if (rawResponse.StartsWith("No response") ||
            rawResponse.StartsWith("AI coaching") ||
            rawResponse.StartsWith("The request took") ||
            rawResponse.StartsWith("Unable to") ||
            rawResponse.StartsWith("Something went wrong") ||
            rawResponse.StartsWith("Received an unexpected") ||
            rawResponse.StartsWith("OpenAI is experiencing") ||
            rawResponse.StartsWith("The coaching service"))
        {
            _logger.LogWarning("Tactical analysis received error response, skipping retry: {Msg}", rawResponse);
            return new TacticalAnalysisResponse
            {
                WhatYoureSeeing = rawResponse,
                WhyItMatters = "",
                NextFocus = ""
            };
        }

        // Only retry if we got actual AI content that failed to parse
        _logger.LogWarning("Tactical analysis JSON parse failed. Raw (truncated): {Raw}", 
            rawResponse.Length > 300 ? rawResponse[..300] : rawResponse);

        var retryPrompt = await _promptComposer.ComposeAsync(
            ["tactical/retry-valid-json.md"],
            variables);

        var retryResponse = await _openAIClient.SendPromptAsync(
            retryPrompt,
            systemPrompt,
            TacticalTemperature);
        
        parsed = TryParseTacticalResponse(retryResponse);
        if (parsed != null)
        {
            return await EnsureNoveltyIfNeededAsync(
                parsed,
                matchDescription,
                matchesContext,
                recentAdviceContext,
                focusType,
                focusInstructions,
                recentAdviceHistory);
        }

        // Fallback — wrap raw text in structured response
        _logger.LogError("Tactical analysis JSON parse failed after retry. Returning fallback.");
        return new TacticalAnalysisResponse
        {
            WhatYoureSeeing = rawResponse.Length > 500 ? rawResponse[..500] : rawResponse,
            WhyItMatters = "The available response was not structured enough to turn into a reliable tactical read.",
            NextFocus = "Add one clear match pattern or pressure moment and run the coach again."
        };
    }

    /// <summary>
    /// Generate Drills - Data-driven drill recommendations based on match history
    /// </summary>
    public async Task<string> GenerateDrillsAsync(string matchesJson)
    {
        var prompt = await _promptComposer.ComposeAsync(
            ["drills/system.md"],
            new Dictionary<string, string>
            {
                ["matchesJson"] = matchesJson
            });

        return await _openAIClient.SendPromptAsync(prompt);
    }

    /// <summary>
    /// Quick Tactical Tip - Fast, actionable advice for specific situations
    /// </summary>
    public async Task<string> QuickTacticalTipAsync(string situation)
    {
        var prompt = await _promptComposer.ComposeAsync(
            ["quick-tip/system.md"],
            new Dictionary<string, string>
            {
                ["situation"] = situation
            });

        return await _openAIClient.SendPromptAsync(prompt);
    }

    /// <summary>
    /// Technique Analysis - Analytical breakdown of technique issues
    /// </summary>
    public async Task<string> AnalyzeTechniqueAsync(string description)
    {
        var prompt = await _promptComposer.ComposeAsync(
            ["technique/system.md"],
            new Dictionary<string, string>
            {
                ["description"] = description
            });

        return await _openAIClient.SendPromptAsync(prompt);
    }

    /// <summary>
    /// Match Strategy - Opponent-specific game plan
    /// </summary>
    public async Task<string> GetMatchStrategyAsync(string opponentDescription)
    {
        var prompt = await _promptComposer.ComposeAsync(
            ["match-strategy/system.md"],
            new Dictionary<string, string>
            {
                ["opponentDescription"] = opponentDescription
            });

        return await _openAIClient.SendPromptAsync(prompt);
    }

    /// <summary>
    /// Training Plan - Structured weekly training schedule
    /// </summary>
    public async Task<string> GenerateTrainingPlanAsync(string playerLevel, string goals)
    {
        var prompt = await _promptComposer.ComposeAsync(
            ["training-plan/system.md"],
            new Dictionary<string, string>
            {
                ["playerLevel"] = playerLevel,
                ["goals"] = goals
            });

        return await _openAIClient.SendPromptAsync(prompt);
    }

    // ============ Private Helpers ============

    /// <summary>
    /// Builds multi-match context with frequency counts for the AI prompt.
    /// </summary>
    private static string BuildMatchContext(string? recentMatchesJson)
    {
        if (string.IsNullOrEmpty(recentMatchesJson))
        {
            return "No recent match data available. Fewer than 3 matches logged.";
        }

        try
        {
            using var doc = JsonDocument.Parse(recentMatchesJson);
            var root = doc.RootElement;

            if (root.ValueKind != JsonValueKind.Array || root.GetArrayLength() == 0)
            {
                return "No recent match data available.";
            }

            var matchCount = root.GetArrayLength();
            var wins = 0;
            var losses = 0;
            var surfaces = new Dictionary<string, int>();
            var weaponCounts = new Dictionary<string, int>();

            foreach (var match in root.EnumerateArray())
            {
                // Count outcomes
                var result = match.TryGetProperty("result", out var resultProp) 
                    ? resultProp.GetString()?.ToLower() : null;
                if (result == "win") wins++;
                else losses++;

                // Count surfaces
                if (match.TryGetProperty("surface", out var surfaceProp))
                {
                    var surface = surfaceProp.GetString() ?? "Unknown";
                    surfaces[surface] = surfaces.GetValueOrDefault(surface) + 1;
                }

                // Count strengths as weapon indicators
                if (match.TryGetProperty("strengths", out var strengthsProp) && 
                    strengthsProp.ValueKind == JsonValueKind.Object)
                {
                    foreach (var str in strengthsProp.EnumerateObject())
                    {
                        weaponCounts[str.Name] = weaponCounts.GetValueOrDefault(str.Name) + 1;
                    }
                }
            }

            var contextBuilder = new System.Text.StringBuilder();
            contextBuilder.AppendLine($"Total matches in context: {matchCount}");
            contextBuilder.AppendLine($"Record: {wins}W - {losses}L");

            if (surfaces.Count > 0)
            {
                var surfaceStr = string.Join(", ", surfaces.Select(s => $"{s.Key}: {s.Value}"));
                contextBuilder.AppendLine($"Surfaces: {surfaceStr}");
            }

            if (weaponCounts.Count > 0)
            {
                var topWeapon = weaponCounts.OrderByDescending(w => w.Value).First();
                contextBuilder.AppendLine($"Most frequent strength: {topWeapon.Key} (in {topWeapon.Value}/{matchCount} matches)");
            }

            contextBuilder.AppendLine();
            contextBuilder.AppendLine("Raw match data:");
            contextBuilder.AppendLine(recentMatchesJson);

            return contextBuilder.ToString();
        }
        catch
        {
            return recentMatchesJson;
        }
    }

    /// <summary>
    /// Attempts to parse an AI response string into TacticalAnalysisResponse.
    /// Returns null on failure.
    /// </summary>
    private TacticalAnalysisResponse? TryParseTacticalResponse(string rawResponse)
    {
        try
        {
            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };
            var result = JsonSerializer.Deserialize<TacticalAnalysisResponse>(rawResponse, options);
            
            // Validate: must have the three required coach sections.
            if (result != null && 
                !string.IsNullOrWhiteSpace(result.WhatYoureSeeing) && 
                !string.IsNullOrWhiteSpace(result.WhyItMatters) &&
                !string.IsNullOrWhiteSpace(result.NextFocus))
            {
                if (result.OptionalPracticePlan != null &&
                    string.IsNullOrWhiteSpace(result.OptionalPracticePlan.DrillName) &&
                    string.IsNullOrWhiteSpace(result.OptionalPracticePlan.Objective))
                {
                    result.OptionalPracticePlan = null;
                }

                return result;
            }
        }
        catch (JsonException ex)
        {
            _logger.LogWarning(ex, "Failed to deserialize tactical analysis response");
        }

        return null;
    }

    private async Task<TacticalAnalysisResponse> EnsureNoveltyIfNeededAsync(
        TacticalAnalysisResponse candidate,
        string matchDescription,
        string matchesContext,
        string recentAdviceContext,
        string? focusType,
        string focusInstructions,
        IReadOnlyList<string>? recentAdviceHistory)
    {
        if (recentAdviceHistory == null || recentAdviceHistory.Count == 0)
            return candidate;

        if (!IsTooSimilarToHistory(candidate, recentAdviceHistory))
            return candidate;

        _logger.LogInformation(
            "Tactical analysis too similar to recent advice. Triggering one novelty regeneration pass.");

        var variables = BuildTacticalVariables(
            matchDescription,
            matchesContext,
            recentAdviceContext,
            focusType,
            focusInstructions);
        var noveltyPrompt = await _promptComposer.ComposeAsync(
            ["tactical/regenerate-novelty.md"],
            variables);
        var systemPrompt = await BuildTacticalSystemPromptAsync();

        var regeneratedRaw = await _openAIClient.SendPromptAsync(
            noveltyPrompt,
            systemPrompt,
            TacticalTemperature);

        var regenerated = TryParseTacticalResponse(regeneratedRaw);
        if (regenerated == null)
            return candidate;

        if (IsTooSimilarToHistory(regenerated, recentAdviceHistory))
        {
            _logger.LogInformation(
                "Novelty regeneration still too similar. Returning original parsed candidate.");
            return candidate;
        }

        return regenerated;
    }

    private Task<string> BuildTacticalSystemPromptAsync()
    {
        return _promptComposer.ComposeAsync([
            "tactical/system-control-mode.md",
            "tactical/novelty-rules.md"
        ]);
    }

    private static Dictionary<string, string> BuildTacticalVariables(
        string matchDescription,
        string matchesContext,
        string recentAdviceContext,
        string? focusType,
        string focusInstructions)
    {
        return new Dictionary<string, string>
        {
            ["matchDescription"] = matchDescription,
            ["matchesContext"] = matchesContext,
            ["recentAdviceContext"] = recentAdviceContext,
            ["focusType"] = string.IsNullOrWhiteSpace(focusType) ? "what_keeps_showing_up" : focusType,
            ["focusInstructions"] = focusInstructions
        };
    }

    private static string BuildFocusInstructions(string? focusType)
    {
        return focusType switch
        {
            "what_keeps_showing_up" =>
                "Analyze recurring themes across recent matches. Look for repeated strengths, weaknesses, momentum shifts, score patterns, and tactical habits.",
            "whats_helping_you_win" =>
                "Focus on wins and strongest performances where possible. Identify what is working well and what the player should keep trusting.",
            "what_breaks_under_pressure" =>
                "Focus on losses, close sets, missed leads, deciding sets, and pressure moments. Identify where execution, decision-making, or composure drops.",
            "next_match_focus" =>
                "Use recent match history to give one clear tactical priority for the next match. Keep it practical and easy to remember.",
            _ =>
                "Analyze recurring themes across recent matches and provide the most useful tactical priority for the next match."
        };
    }

    private static string BuildRecentAdviceContext(IReadOnlyList<string>? recentAdviceHistory)
    {
        if (recentAdviceHistory == null || recentAdviceHistory.Count == 0)
        {
            return "No recent tactical advice history available.";
        }

        var trimmed = recentAdviceHistory
            .Where(a => !string.IsNullOrWhiteSpace(a))
            .Select((a, i) =>
                $"Advice {i + 1}: {(a.Length > 260 ? a[..260] + "..." : a)}")
            .ToList();

        return trimmed.Count == 0
            ? "No recent tactical advice history available."
            : string.Join(Environment.NewLine, trimmed);
    }

    private static bool IsTooSimilarToHistory(
        TacticalAnalysisResponse response,
        IReadOnlyList<string> recentAdviceHistory)
    {
        var candidate = NormalizeForSimilarity(FlattenForSimilarity(response));
        if (string.IsNullOrWhiteSpace(candidate))
            return false;

        const double similarityThreshold = 0.72;
        foreach (var history in recentAdviceHistory)
        {
            var normalizedHistory = NormalizeForSimilarity(history);
            if (string.IsNullOrWhiteSpace(normalizedHistory))
                continue;

            var similarity = JaccardSimilarity(candidate, normalizedHistory);
            if (similarity >= similarityThreshold)
                return true;
        }

        return false;
    }

    private static string FlattenForSimilarity(TacticalAnalysisResponse response)
    {
        return string.Join(" ", new[]
        {
            response.WhatYoureSeeing,
            response.WhyItMatters,
            response.NextFocus,
            response.OptionalPracticePlan?.DrillName ?? string.Empty,
            response.OptionalPracticePlan?.Objective ?? string.Empty
        });
    }

    private static string NormalizeForSimilarity(string input)
    {
        var lowered = input.ToLowerInvariant();
        lowered = Regex.Replace(lowered, @"[^a-z0-9\s]", " ");
        lowered = Regex.Replace(lowered, @"\s+", " ").Trim();
        return lowered;
    }

    private static double JaccardSimilarity(string a, string b)
    {
        var setA = a.Split(' ', StringSplitOptions.RemoveEmptyEntries).ToHashSet();
        var setB = b.Split(' ', StringSplitOptions.RemoveEmptyEntries).ToHashSet();
        if (setA.Count == 0 || setB.Count == 0)
            return 0;

        var intersectionCount = setA.Intersect(setB).Count();
        var unionCount = setA.Union(setB).Count();
        if (unionCount == 0)
            return 0;

        return (double)intersectionCount / unionCount;
    }
}
