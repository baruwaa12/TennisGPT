namespace TennisGPT.Domain.Entities;

/// <summary>
/// Categories for saved coaching entries.
/// </summary>
public enum SavedEntryCategory
{
    TacticalAdvice = 0,
    PostMatchDebrief = 1,
    PreMatchPlan = 2
}

/// <summary>
/// A saved coaching entry (tactical advice, debrief, or pre-match plan).
/// Max 3 per category per user — oldest auto-deletes on 4th save.
/// </summary>
public class SavedEntry
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public SavedEntryCategory Category { get; set; }
    public required string Content { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    // Navigation property
    public User? User { get; set; }
}
