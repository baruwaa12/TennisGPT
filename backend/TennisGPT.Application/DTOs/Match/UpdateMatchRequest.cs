namespace TennisGPT.Application.DTOs.Match;

public class UpdateMatchRequest
{
    public DateTime Date { get; set; }
    public required string Opponent { get; set; }
    public required string Result { get; set; }
    public int SetsWon { get; set; }
    public int SetsLost { get; set; }
    public required string Surface { get; set; }
    public string? Weather { get; set; }
    public string? Notes { get; set; }
    public string? Strengths { get; set; }
    public string? Weaknesses { get; set; }
    public string? KeyMoments { get; set; }
    public string? TacticalAnalysis { get; set; }
    public string? RecommendedDrills { get; set; }
}
