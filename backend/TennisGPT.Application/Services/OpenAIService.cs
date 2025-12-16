using TennisGPT.Application.Interfaces;

namespace TennisGPT.Application.Services;

/// <summary>
/// AI coaching service with analytical, data-driven responses.
/// Tone: 65% of users prefer "Analytical and Logical" based on survey data.
/// </summary>
public class OpenAIService : IOpenAIService
{
    private readonly IOpenAIClient _openAIClient;

    public OpenAIService(IOpenAIClient openAIClient)
    {
        _openAIClient = openAIClient;
    }

    /// <summary>
    /// Pre-Match Prep (formerly Mental Check-In) - Tactical preparation before a match
    /// </summary>
    public async Task<string> MentalCheckInAsync(int mood, string journalEntry)
    {
        var prompt = $"""
            You are an analytical tennis strategist preparing a player for their match. 
            Skip emotional language. Be direct and data-focused.

            Player's current readiness level: {mood}/5
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
    /// Tactical Analysis - Core feature for match strategy analysis
    /// </summary>
    public async Task<string> TacticalAnalysisAsync(string matchDescription, string? recentMatchesJson)
    {
        var matchesData = string.IsNullOrEmpty(recentMatchesJson)
            ? "No recent match data available."
            : recentMatchesJson;

        var prompt = $"""
            You are an elite tennis strategist analyzing match data.

            **MATCH DATA:**
            Current situation: '{matchDescription}'
            Recent match history: {matchesData}

            Deliver your analysis in this structured format:

            **SUMMARY**
            2-3 sentences assessing the overall situation. Be direct and data-focused.

            **3 TACTICAL RECOMMENDATIONS**
            1. [First recommendation]
               - Why: [One sentence reasoning]
               - How: [Specific execution detail]

            2. [Second recommendation]
               - Why: [One sentence reasoning]
               - How: [Specific execution detail]

            3. [Third recommendation]
               - Why: [One sentence reasoning]
               - How: [Specific execution detail]

            **PATTERN DETECTED**
            If match history is available, identify one recurring pattern (positive or negative).

            Tone: Analytical and logical. Like a sports analyst breaking down film.
            """;

        return await _openAIClient.SendPromptAsync(prompt);
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
}
