using TennisGPT.Application.DTOs.Coaching;

namespace TennisGPT.Application.Interfaces;

public interface IOpenAIService
{
    Task<string> MentalCheckInAsync(int mood, string journalEntry);
    Task<string> EmotionalResetAsync(string situation);
    Task<TacticalAnalysisResponse> TacticalAnalysisAsync(string matchDescription, string? recentMatchesJson);
    Task<string> GenerateDrillsAsync(string matchesJson);
    Task<string> QuickTacticalTipAsync(string situation);
    Task<string> AnalyzeTechniqueAsync(string description);
    Task<string> GetMatchStrategyAsync(string opponentDescription);
    Task<string> GenerateTrainingPlanAsync(string playerLevel, string goals);
}
