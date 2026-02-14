using System.Text.Json;
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
    /// Locked system prompt for tactical analysis.
    /// Temperature: 0.5 | MaxTokens: 1500
    /// </summary>
    private const string TacticalSystemPrompt = @"You are an elite-level tennis performance analyst.

Your role is to provide structured, analytical tactical feedback based on recorded match data.

TONE REQUIREMENTS:
- Primary tone: Analytical and logical.
- Calm, professional, and precise.
- No hype language.
- No motivational slogans.
- No emotional exaggeration.
- No slang.
- No emojis.
- No unnecessary praise.
- Do not cheerlead.
- Focus on tactical reasoning and performance trends.

You think like a performance analyst reviewing match data, not a motivational coach.

OUTPUT REQUIREMENTS:
You MUST return ONLY valid JSON.
Do NOT include markdown.
Do NOT include backticks.
Do NOT include explanations outside JSON.
Do NOT include extra commentary.

Return JSON in this exact structure:

{
  ""summary"": ""string"",
  ""recommendations"": [
    {
      ""title"": ""string"",
      ""why"": ""string"",
      ""how"": ""string""
    }
  ],
  ""patternDetected"": ""string"",
  ""nextMatchFocus"": ""string""
}

RULES:

1) summary:
- Maximum 5 concise lines.
- Explain what happened tactically.
- Reference score context when relevant.
- Avoid storytelling.

2) recommendations:
- EXACTLY 3 items.
- Each must include:
  - title (short tactical theme)
  - why (performance reasoning)
  - how (specific instruction)
- Keep why and how to max 2 short sentences.

3) patternDetected:
- If multiple matches exist, identify recurring trends.
- Reference frequency when possible (e.g., appeared in 3 of last 5 matches).
- If insufficient data, state that more matches are required.
- Keep concise and data-driven.

4) nextMatchFocus:
- One sentence only.
- Must be tactical.
- No motivational language.

5) Tactical Philosophy:
- Emphasize controllable variables.
- Encourage defining a primary weapon:
  Serve, Forehand, Backhand, Return, Net Play.
- Strategy must build around repeatable weapon.
- Avoid vague advice.

6) Pre-Match Strategy Logic:
When prep context is provided:
- Define primary weapon.
- Define secondary weapon.
- Define opponent weakness hypothesis.
- Define first two service game plan.
- Keep structured.";

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

            IMPORTANT: If the player's notes are not related to tennis, respond with:
            "I can only help with tennis-related questions. Please describe your tennis situation, upcoming match, or what you'd like to work on."

            IMPORTANT: The player's notes may include their skill level (beginner/intermediate/advanced/competitive).
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
            The player experienced this situation: '{situation}'

            IMPORTANT: If the situation described is not related to tennis, respond with:
            "I can only help with tennis-related questions. Please describe a tennis match situation you'd like to analyze."

            IMPORTANT: The situation may include the player's skill level (beginner/intermediate/advanced/competitive).
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
    public async Task<TacticalAnalysisResponse> TacticalAnalysisAsync(string matchDescription, string? recentMatchesJson)
    {
        var matchesContext = BuildMatchContext(recentMatchesJson);

        var userPrompt = $"""
            MATCH DATA:
            Current situation: {matchDescription}

            RECENT MATCH HISTORY:
            {matchesContext}

            Analyze the data and return your response as valid JSON.
            """;

        // First attempt
        var rawResponse = await _openAIClient.SendPromptAsync(userPrompt, TacticalSystemPrompt, TacticalTemperature);
        
        var parsed = TryParseTacticalResponse(rawResponse);
        if (parsed != null) return parsed;

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
                Summary = rawResponse,
                Recommendations = new List<TacticalRecommendation>
                {
                    new() { Title = "Service unavailable", Why = "The AI service could not process your request.", How = "Please try again in a moment." }
                },
                PatternDetected = "",
                NextMatchFocus = ""
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

        var retryResponse = await _openAIClient.SendPromptAsync(retryPrompt, TacticalSystemPrompt, TacticalTemperature);
        
        parsed = TryParseTacticalResponse(retryResponse);
        if (parsed != null) return parsed;

        // Fallback — wrap raw text in structured response
        _logger.LogError("Tactical analysis JSON parse failed after retry. Returning fallback.");
        return new TacticalAnalysisResponse
        {
            Summary = rawResponse.Length > 500 ? rawResponse[..500] : rawResponse,
            Recommendations = new List<TacticalRecommendation>
            {
                new() { Title = "Review needed", Why = "The analysis could not be structured automatically.", How = "Please try again or rephrase your input." }
            },
            PatternDetected = "Unable to determine — please retry.",
            NextMatchFocus = "Focus on your strongest controllable weapon."
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

            IMPORTANT: If the situation is not tennis-related, respond with:
            "I can only help with tennis questions. Please describe a tennis situation."

            IMPORTANT: Adapt complexity to player level if mentioned (beginner = simple words, advanced = technical terms).
            
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
            
            // Basic validation: must have summary and exactly 3 recommendations
            if (result != null && 
                !string.IsNullOrWhiteSpace(result.Summary) && 
                result.Recommendations.Count >= 1)
            {
                // Pad to 3 recommendations if AI returned fewer
                while (result.Recommendations.Count < 3)
                {
                    result.Recommendations.Add(new TacticalRecommendation
                    {
                        Title = "Additional focus needed",
                        Why = "Not enough data for a third recommendation.",
                        How = "Log more matches to unlock deeper analysis."
                    });
                }

                // Trim to 3 if more were returned
                if (result.Recommendations.Count > 3)
                {
                    result.Recommendations = result.Recommendations.Take(3).ToList();
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
}
