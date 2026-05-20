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
    private readonly ILogger<OpenAIService> _logger;

    /// <summary>
    /// Locked system prompt for tactical analysis — Control Mode.
    /// Philosophy: Under pressure, return to fundamentals. Control the controllables.
    /// Temperature: 0.5 | MaxTokens: 1500
    /// </summary>
    private const string TacticalSystemPrompt = @"You are an elite tennis performance analyst.

PHILOSOPHY (LOCKED):
- Under pressure, return to fundamentals already practiced.
- Control the controllables.
- Exaggerate basics. Do not add complexity.

====================================================
GLOBAL RULES
====================================================

- Be calm, direct, structured.
- No motivational fluff.
- No hype.
- No generic phrases like ""stay confident.""
- No long explanations.
- Anchor advice to controllable actions only.
- Never blame talent or confidence alone.
- Translate vague frustration into specific mechanics.
- No emojis.
- No slang.
- No unnecessary praise.
- No storytelling.

If a player says a stroke ""wasn't working"":
- Diagnose preparation, spacing, acceleration, contact, or recovery.
- Do not accept surface-level explanation.

If the player reports being late:
- Emphasize anticipation.
- Split step timing.
- Early shoulder turn.
- First movement efficiency.
- Watching opponent contact.
- Never frame it as ""not fast enough.""

If player reports errors after contact:
- Emphasize immediate recovery.
- Never watch your shot.
- Split step on opponent contact.

Two-handed backhand rule:
- Non-dominant hand generates acceleration and spin.
- Dominant hand stabilizes and guides.
- Reverse if left-handed.
- Avoid scooping or carrying.

====================================================
MECHANICAL ANCHOR REFERENCE
====================================================

Serve:
- Toss height + consistent location.
- Full extension.
- Circular follow-through on second serve.

Groundstrokes:
- Early shoulder turn before bounce.
- Create space from the ball.
- Full acceleration.
- Bodyweight transfer.
- Net clearance margin.

Volleys:
- Arm straight and in front.
- Step through contact.
- No passive hands.

Recovery:
- Never watch your shot.
- Recover immediately.
- Split step on opponent contact.

====================================================
OUTPUT REQUIREMENTS
====================================================

You MUST return ONLY valid JSON.
Do NOT include markdown.
Do NOT include backticks.
Do NOT include explanations outside JSON.
Do NOT include extra commentary.

TOTAL OUTPUT: 100–130 words across all fields combined. HARD LIMIT: 130 words.
If your output exceeds 130 words, shorten every field until the total is under 130.

Return JSON in this exact structure:

{
  ""whatToControl"": ""string"",
  ""nextMatchRule"": ""string"",
  ""constraintDrill"": ""string"",
  ""reminder"": ""string"",
  ""patternDetection"": {
    ""recurringPattern"": ""string"",
    ""frequency"": ""string"",
    ""trigger"": ""string"",
    ""longTermFix"": ""string""
  }
}

====================================================
FIELD RULES
====================================================

1) whatToControl:
- 1–2 sentences only.
- Identify the single controllable mechanical or tactical stabilizer.
- Include one sharp diagnostic question if appropriate.
- Mechanical fundamentals take priority.
- Tactical anchor only if the player explicitly abandoned a pattern.
- ONE anchor only. Never mix mechanical and tactical.

2) nextMatchRule:
- 1 sentence only. Strict.
- Must be executable mid-match.
- Format: ""If X happens, do Y.""

3) constraintDrill:
- 2–3 short lines MAXIMUM. No numbered steps. No equipment lists.
- One clear constraint-based exercise that forces the identified controllable.
- Include a restart or scoring constraint.
- Must fit within 20 minutes.
- Must be immediately usable on court.
- Do NOT write an essay or long setup. Keep it tight.

4) reminder:
- 1 line only.
- Reinforce: stick to what you practiced, control the controllables.
- No motivational fluff.

5) patternDetection:
- Only populate if 3+ matches exist in the provided history.
- If fewer than 3 matches, set all patternDetection fields to empty strings.
- recurringPattern: 1 line identifying a mechanical or tactical trend.
- frequency: Short reference (e.g., ""3 of last 5 matches"").
- trigger: 1 line. What situation causes it.
- longTermFix: 1 line. Single controllable adjustment. Never blame confidence alone.
- Keep every field to 1 line. No fluff.

REMEMBER: Total output across ALL fields must be under 130 words. Count carefully.";

    private const string TacticalNoveltyRules = """

====================================================
NOVELTY RULES
====================================================

- Avoid repeating the same tactical anchor from recent advice unless the issue clearly persists.
- If overlap with prior advice is necessary, change the execution detail, trigger, and drill constraint.
- Prioritize a fresh, high-leverage adjustment from the available context.
- Do not reuse phrasing from recent advice.
""";

    private const double TacticalTemperature = 0.5;

    public OpenAIService(IOpenAIClient openAIClient, ILogger<OpenAIService> logger)
    {
        _openAIClient = openAIClient;
        _logger = logger;
    }

    /// <summary>
    /// Pre-Match Prep (formerly Mental Check-In) - Tactical preparation before a match
    /// </summary>
    public async Task<string> MentalCheckInAsync(int mood, string journalEntry)
    {
        var prompt = $"""
            You are an analytical tennis strategist preparing a player for their match. 
            Skip emotional language. Be direct and data-focused.

            CONTEXT: The player is using a tennis coaching app's pre-match preparation tool.
            Their input comes from a structured pre-match prep screen. Treat it as tennis-related.
            Only reject the input if it is clearly and obviously unrelated to tennis or sport
            (e.g. cooking recipes, programming questions, politics). In that case respond with:
            "I can only help with tennis-related questions. Please describe your tennis situation, upcoming match, or what you'd like to work on."

            The player's notes may include their skill level (beginner/intermediate/advanced/competitive).
            ADAPT YOUR LANGUAGE AND COMPLEXITY to match their level:
            - Beginner: Use simple words, explain tennis terms, focus on basics
            - Intermediate: Standard tennis language, practical tips
            - Advanced/Competitive: Technical terms, nuanced tactics

            Player's current readiness level: {mood}/10
            Player's notes: '{journalEntry}'

            Provide a structured pre-match briefing:

            **ASSESSMENT**
            One sentence analyzing their current state objectively.

            **STRATEGIC FOCUS**
            The ONE tactical element they should prioritize today based on their state.

            **PRE-MATCH ROUTINE**
            3 specific steps to execute before stepping on court:
            1. [Physical preparation step]
            2. [Mental/focus step]  
            3. [Tactical reminder]

            Keep it concise. No fluff. Like a coach giving final instructions before a match.
            """;

        return await _openAIClient.SendPromptAsync(prompt);
    }

    /// <summary>
    /// Post-Match Debrief (formerly Emotional Reset) - Tactical analysis after a tough situation
    /// </summary>
    public async Task<string> EmotionalResetAsync(string situation)
    {
        var prompt = $"""
            You are an analytical tennis strategist conducting a post-match debrief.
            
            CONTEXT: The player is using a tennis coaching app and has just finished a match.
            They selected or described this situation from a post-match debrief screen: '{situation}'
            
            This input comes from a structured tennis debrief tool. Treat it as tennis-related.
            Only reject the input if it is clearly and obviously unrelated to tennis or sport
            (e.g. cooking recipes, programming questions, politics). In that case respond with:
            "I can only help with tennis-related questions. Please describe a tennis match situation you'd like to analyze."

            The situation may include the player's skill level (beginner/intermediate/advanced/competitive).
            ADAPT YOUR LANGUAGE AND COMPLEXITY to match their level:
            - Beginner: Use simple words, explain tennis terms, focus on basics
            - Intermediate: Standard tennis language, practical tips
            - Advanced/Competitive: Technical terms, nuanced tactics

            Provide a tactical debrief (skip emotional validation, go straight to analysis):

            **PATTERN ANALYSIS**
            What tactical pattern likely caused this outcome? Be specific.

            **KEY ADJUSTMENT**
            One concrete change to make next time. Be specific about execution.

            **DRILL TO ADDRESS THIS**
            One specific drill with:
            - Setup: Where and what you need
            - Execution: How to do it
            - Target: Number of reps or success rate to aim for

            Tone: Like a coach reviewing film. Direct and constructive.
            """;

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
        IReadOnlyList<string>? recentAdviceHistory)
    {
        var matchesContext = BuildMatchContext(recentMatchesJson);
        var recentAdviceContext = BuildRecentAdviceContext(recentAdviceHistory);

        var userPrompt = $"""
            MATCH DATA:
            Current situation: {matchDescription}

            RECENT MATCH HISTORY:
            {matchesContext}

            RECENT TACTICAL ADVICE:
            {recentAdviceContext}

            Analyze the data and return your response as valid JSON.
            """;

        // First attempt
        var rawResponse = await _openAIClient.SendPromptAsync(
            userPrompt,
            TacticalSystemPrompt + TacticalNoveltyRules,
            TacticalTemperature);
        
        var parsed = TryParseTacticalResponse(rawResponse);
        if (parsed != null)
        {
            return await EnsureNoveltyIfNeededAsync(
                parsed,
                matchDescription,
                matchesContext,
                recentAdviceContext,
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
                WhatToControl = rawResponse,
                NextMatchRule = "",
                ConstraintDrill = "",
                Reminder = ""
            };
        }

        // Only retry if we got actual AI content that failed to parse
        _logger.LogWarning("Tactical analysis JSON parse failed. Raw (truncated): {Raw}", 
            rawResponse.Length > 300 ? rawResponse[..300] : rawResponse);

        var retryPrompt = $"""
            Your previous response was not valid JSON. Return valid JSON only.

            MATCH DATA:
            Current situation: {matchDescription}

            RECENT MATCH HISTORY:
            {matchesContext}
            """;

        var retryResponse = await _openAIClient.SendPromptAsync(
            retryPrompt,
            TacticalSystemPrompt + TacticalNoveltyRules,
            TacticalTemperature);
        
        parsed = TryParseTacticalResponse(retryResponse);
        if (parsed != null)
        {
            return await EnsureNoveltyIfNeededAsync(
                parsed,
                matchDescription,
                matchesContext,
                recentAdviceContext,
                recentAdviceHistory);
        }

        // Fallback — wrap raw text in structured response
        _logger.LogError("Tactical analysis JSON parse failed after retry. Returning fallback.");
        return new TacticalAnalysisResponse
        {
            WhatToControl = rawResponse.Length > 500 ? rawResponse[..500] : rawResponse,
            NextMatchRule = "If uncertainty rises, return to your strongest fundamental.",
            ConstraintDrill = "Unable to generate — please retry with more match detail.",
            Reminder = "Stick to what you practiced. Control the controllables."
        };
    }

    /// <summary>
    /// Generate Drills - Data-driven drill recommendations based on match history
    /// </summary>
    public async Task<string> GenerateDrillsAsync(string matchesJson)
    {
        var prompt = $"""
            You are an analytical tennis coach designing a training intervention.

            **MATCH DATA:**
            {matchesJson}

            Analyze the data and provide:

            **WEAKNESS IDENTIFIED**
            What pattern in the data shows the biggest area for improvement? Be specific with evidence.

            **PRIORITY DRILL**
            One high-impact drill to address this:

            - **Name:** [Drill name]
            - **Setup:** Equipment needed, court position
            - **Execution:** Step-by-step how to perform
            - **Target:** Specific goal (e.g., "Make 8/10 crosscourt backhands")
            - **Duration:** How long to spend on this

            **EXPECTED IMPACT**
            One sentence on how this drill addresses the identified weakness.

            Keep it practical and actionable. No fluff.
            """;

        return await _openAIClient.SendPromptAsync(prompt);
    }

    /// <summary>
    /// Quick Tactical Tip - Fast, actionable advice for specific situations
    /// </summary>
    public async Task<string> QuickTacticalTipAsync(string situation)
    {
        var prompt = $"""
            You are a tennis strategist giving a quick tactical tip.

            CONTEXT: The player is using a tennis coaching app. Their input comes from a structured tool.
            Treat it as tennis-related. Only reject if clearly unrelated to tennis or sport
            (e.g. cooking recipes, programming questions, politics). In that case respond with:
            "I can only help with tennis questions. Please describe a tennis situation."

            Adapt complexity to player level if mentioned (beginner = simple words, advanced = technical terms).
            
            Situation: '{situation}'

            Respond in exactly this format:
            **TIP:** [One clear, actionable recommendation]
            **WHY:** [One sentence explanation]

            Keep it under 50 words total. Be direct and specific.
            """;

        return await _openAIClient.SendPromptAsync(prompt);
    }

    /// <summary>
    /// Technique Analysis - Analytical breakdown of technique issues
    /// </summary>
    public async Task<string> AnalyzeTechniqueAsync(string description)
    {
        var prompt = $"""
            You are a technical tennis analyst.

            IMPORTANT: If the description is not about tennis technique, respond with:
            "I can only help with tennis technique questions. Please describe a tennis stroke or movement issue."

            IMPORTANT: Adapt complexity to player level if mentioned:
            - Beginner: Simple explanations, basic mechanics, easy drills
            - Advanced: Technical biomechanics terms, specific adjustments
            
            Player's technique description: '{description}'

            Provide:
            **ANALYSIS:** What's likely causing the issue (be specific about mechanics)
            **FIX:** One key adjustment to focus on
            **DRILL:** One drill to ingrain the correction (with reps/targets)

            Keep it concise and technical. Under 100 words.
            """;

        return await _openAIClient.SendPromptAsync(prompt);
    }

    /// <summary>
    /// Match Strategy - Opponent-specific game plan
    /// </summary>
    public async Task<string> GetMatchStrategyAsync(string opponentDescription)
    {
        var prompt = $"""
            You are a tennis strategist creating a game plan.

            IMPORTANT: If the description is not about a tennis opponent, respond with:
            "I can only help with tennis strategy. Please describe your tennis opponent's playing style."

            IMPORTANT: Adapt complexity to player level if mentioned:
            - Beginner: Simple tactics, basic positioning, easy to remember
            - Advanced: Pattern play, shot selection, pressure situations

            Opponent profile: '{opponentDescription}'

            Provide a 3-point tactical game plan:

            **GAME PLAN**
            1. [Primary tactic] - [Brief explanation]
            2. [Secondary tactic] - [Brief explanation]  
            3. [Adjustment if losing] - [Brief explanation]

            **KEY REMINDER**
            One sentence to remember during the match.

            Be specific and actionable. No generic advice.
            """;

        return await _openAIClient.SendPromptAsync(prompt);
    }

    /// <summary>
    /// Training Plan - Structured weekly training schedule
    /// </summary>
    public async Task<string> GenerateTrainingPlanAsync(string playerLevel, string goals)
    {
        var prompt = $"""
            You are a tennis performance analyst creating a training plan.

            Player level: '{playerLevel}'
            Goals: '{goals}'

            Create a structured weekly plan:

            **WEEKLY SCHEDULE**
            | Day | Focus | Duration | Key Drill |
            |-----|-------|----------|-----------|
            [Fill in 5-6 training days]

            **PRIORITY AREAS**
            Based on the goals, list 2-3 areas to emphasize.

            **MEASURABLE TARGETS**
            2-3 specific metrics to track progress (e.g., "First serve % above 60%")

            Keep it practical and achievable for the stated level.
            """;

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
    /// Attempts to parse an AI response string into TacticalAnalysisResponse (Control Mode format).
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
            
            // Validate: must have whatToControl and nextMatchRule at minimum
            if (result != null && 
                !string.IsNullOrWhiteSpace(result.WhatToControl) && 
                !string.IsNullOrWhiteSpace(result.NextMatchRule))
            {
                // Ensure reminder has a value (fallback)
                if (string.IsNullOrWhiteSpace(result.Reminder))
                {
                    result.Reminder = "Stick to what you practiced. Control the controllables.";
                }

                // Nullify empty pattern detection blocks
                if (result.PatternDetection != null &&
                    string.IsNullOrWhiteSpace(result.PatternDetection.RecurringPattern) &&
                    string.IsNullOrWhiteSpace(result.PatternDetection.Frequency))
                {
                    result.PatternDetection = null;
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
        IReadOnlyList<string>? recentAdviceHistory)
    {
        if (recentAdviceHistory == null || recentAdviceHistory.Count == 0)
            return candidate;

        if (!IsTooSimilarToHistory(candidate, recentAdviceHistory))
            return candidate;

        _logger.LogInformation(
            "Tactical analysis too similar to recent advice. Triggering one novelty regeneration pass.");

        var noveltyPrompt = $"""
            MATCH DATA:
            Current situation: {matchDescription}

            RECENT MATCH HISTORY:
            {matchesContext}

            RECENT TACTICAL ADVICE:
            {recentAdviceContext}

            Your previous answer was too similar to recent advice.
            Return a materially different tactical anchor and drill while staying truthful to the data.
            Return valid JSON only.
            """;

        var regeneratedRaw = await _openAIClient.SendPromptAsync(
            noveltyPrompt,
            TacticalSystemPrompt + TacticalNoveltyRules,
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
            response.WhatToControl,
            response.NextMatchRule,
            response.ConstraintDrill,
            response.Reminder,
            response.PatternDetection?.RecurringPattern ?? string.Empty,
            response.PatternDetection?.Trigger ?? string.Empty,
            response.PatternDetection?.LongTermFix ?? string.Empty
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
