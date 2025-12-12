using TennisGPT.Application.Interfaces;

namespace TennisGPT.Application.Services;

public class OpenAIService : IOpenAIService
{
    private readonly IOpenAIClient _openAIClient;

    public OpenAIService(IOpenAIClient openAIClient)
    {
        _openAIClient = openAIClient;
    }

    public async Task<string> MentalCheckInAsync(int mood, string journalEntry)
    {
        var prompt = $"""
            You are a tough but fair tennis mental coach. Your goal is to build mental resilience, not to coddle. Write your response in a conversational, human-like tone, using paragraphs.

            The user is checking in with a mood rating of {mood} out of 5.
            They wrote this in their journal: '{journalEntry}'.

            First, acknowledge their state based on their rating and journal entry. Be direct and validate their feelings without being overly soft.

            Next, transition into asking a sharp, insightful, and challenging question that forces them to confront the root cause of their feelings or the reality of their performance. Frame it as a genuine question from a coach who sees their potential.

            Finally, provide a concrete, actionable tip they can apply in their next practice or match. Break this down into simple steps if it makes sense. Explain *why* this tip is important for them right now. End on a firm but encouraging note.
            """;

        return await _openAIClient.SendPromptAsync(prompt);
    }

    public async Task<string> EmotionalResetAsync(string situation)
    {
        var prompt = $"""
            You are a supportive and wise tennis coach. The user is feeling down about this situation: '{situation}'.

            Write a thoughtful, encouraging paragraph to help them reset emotionally. Acknowledge the frustration of the situation, validate their feelings, and then gently guide their perspective towards what they can control. Help them regain focus with a powerful, human-like message.
            """;

        return await _openAIClient.SendPromptAsync(prompt);
    }

    public async Task<string> TacticalAnalysisAsync(string matchDescription, string? recentMatchesJson)
    {
        var matchesData = string.IsNullOrEmpty(recentMatchesJson)
            ? "No recent match data provided."
            : recentMatchesJson;

        var prompt = $"""
            You are a world-class tennis strategist, but you're explaining your thoughts to your player in a clear, human-like way. Use paragraphs to explain your thinking.

            Here's the situation you need to analyze:
            - Current Match/Problem: '{matchDescription}'
            - Recent Match History: {matchesData}

            Start by giving an overall assessment of the situation in a conversational paragraph. Then, lay out your 3 most important tactical recommendations. For each recommendation, present it as a clear step or point, and write a short paragraph explaining the reasoning behind it and how to execute it. Make it sound like you're talking directly to the player.
            """;

        return await _openAIClient.SendPromptAsync(prompt);
    }

    public async Task<string> GenerateDrillsAsync(string matchesJson)
    {
        var prompt = $"""
            You are an expert tennis coach crafting a new training focus for your player. Write your response in a conversational tone, using paragraphs.

            You've reviewed the player's recent match history here:
            {matchesJson}

            Start by explaining what pattern or weakness you've identified from their matches. Talk about why it's important to address this now.

            Then, introduce the specific, high-impact drill you want them to work on. Break down the drill into clear, easy-to-follow steps:
            1.  **Setup:** What they need and where to be on the court.
            2.  **Execution:** How to perform the drill.
            3.  **Goal:** What they should be aiming for (e.g., number of successful shots, consistency).

            End with an encouraging sentence about how this drill will impact their game.
            """;

        return await _openAIClient.SendPromptAsync(prompt);
    }

    public async Task<string> QuickTacticalTipAsync(string situation)
    {
        var prompt = $"You are a tennis coach providing a quick tactical tip for your player. For the situation: '{situation}', give a concise and helpful piece of advice in a supportive, human tone. Keep it to a couple of sentences.";

        return await _openAIClient.SendPromptAsync(prompt);
    }

    public async Task<string> AnalyzeTechniqueAsync(string description)
    {
        var prompt = $"You are a friendly and knowledgeable tennis coach. A player has described their technique to you: '{description}'. In a conversational paragraph, analyze what they've said, identify one key area for improvement, and then clearly explain a drill they can use to practice it.";

        return await _openAIClient.SendPromptAsync(prompt);
    }

    public async Task<string> GetMatchStrategyAsync(string opponentDescription)
    {
        var prompt = $"You are a smart tennis strategist talking to your player. You've been told about an opponent: '{opponentDescription}'. Lay out a simple, 3-step game plan in a clear, encouraging, and human-like tone. Explain each point briefly.";

        return await _openAIClient.SendPromptAsync(prompt);
    }

    public async Task<string> GenerateTrainingPlanAsync(string playerLevel, string goals)
    {
        var prompt = $"You are a helpful and organized tennis coach. A player who describes themselves as '{playerLevel}' wants a training plan to achieve these goals: '{goals}'. Create a sample weekly training plan, writing in a clear and encouraging tone. Use paragraphs and lists to make it easy to understand. Include sections for on-court drills and off-court fitness.";

        return await _openAIClient.SendPromptAsync(prompt);
    }
}
