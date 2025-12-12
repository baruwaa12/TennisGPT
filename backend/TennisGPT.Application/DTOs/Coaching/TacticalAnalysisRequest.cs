using System.Text.Json;

namespace TennisGPT.Application.DTOs.Coaching;

public class TacticalAnalysisRequest
{
    public required string MatchDescription { get; set; }
    public List<JsonElement>? RecentMatches { get; set; }
}
