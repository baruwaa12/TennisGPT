namespace TennisGPT.Domain.Entities;

public class CheckIn
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public long Timestamp { get; set; } // Unix milliseconds
    public int Rating { get; set; } // 1-5
    public required string JournalText { get; set; }
    public string? CoachResponse { get; set; } // AI response stored
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation property
    public User? User { get; set; }
}
