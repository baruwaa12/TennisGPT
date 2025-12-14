namespace TennisGPT.Domain.Entities;

public class Match
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public DateTime Date { get; set; }
    public required string Opponent { get; set; }
    public required string Result { get; set; } // "Win" or "Loss"
    public int SetsWon { get; set; }
    public int SetsLost { get; set; }
    public required string Surface { get; set; } // Hard, Clay, Grass, Carpet, Indoor
    public string? Weather { get; set; }
    public string? Notes { get; set; }
    public string? Strengths { get; set; } // JSON: {"serve": 8, "forehand": 7}
    public string? Weaknesses { get; set; } // JSON: {"backhand": 4}
    public string? KeyMoments { get; set; } // JSON array: ["moment1", "moment2"]
    public string? TacticalAnalysis { get; set; }
    public string? RecommendedDrills { get; set; } // JSON array
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    // Navigation property
    public User? User { get; set; }
}
