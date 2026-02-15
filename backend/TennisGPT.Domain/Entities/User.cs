namespace TennisGPT.Domain.Entities;

public enum UserPlan
{
    Free = 0,
    Premium = 1
}

public class User
{
    public Guid Id { get; set; }
    public required string GoogleId { get; set; }
    public string? AppleId { get; set; }
    public required string Email { get; set; }
    public string? DisplayName { get; set; }
    public string? PhotoUrl { get; set; }
    public string? RefreshToken { get; set; }
    public DateTime? RefreshTokenExpiry { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastLoginAt { get; set; }
    
    // Subscription & Plan
    public UserPlan Plan { get; set; } = UserPlan.Free;
    public bool OnboardingCompleted { get; set; } = false;
    
    /// <summary>
    /// Lifetime free access - bypasses all paywalls and limits.
    /// Use for special users (e.g., Nicholas, beta testers, friends).
    /// </summary>
    public bool IsComped { get; set; } = false;
    
    // Quota tracking (daily reset, UTC-based)
    // Reuses existing DB columns — no migration needed
    public int TacticalUsedPeriod { get; set; } = 0;
    public DateTime? TacticalPeriodStart { get; set; }

    // Navigation properties
    public ICollection<Match> Matches { get; set; } = [];
    public ICollection<CheckIn> CheckIns { get; set; } = [];
    public ICollection<SavedEntry> SavedEntries { get; set; } = [];
    
    // Quota constants
    public const int FreeTierDailyLimit = 10;
    
    /// <summary>
    /// Check if user can make an AI request.
    /// Premium/Comped = always true.
    /// Free = max 10 per day, reset at midnight UTC.
    /// </summary>
    public bool CanUseAI()
    {
        if (IsComped) return true;
        if (Plan == UserPlan.Premium) return true;
        
        // If no usage today yet, allow
        if (!IsToday(TacticalPeriodStart))
            return true;
        
        return TacticalUsedPeriod < FreeTierDailyLimit;
    }
    
    /// <summary>
    /// Get remaining AI calls for free tier today.
    /// Returns -1 for unlimited (Premium/Comped).
    /// </summary>
    public int GetRemainingAICalls()
    {
        if (IsComped) return -1;
        if (Plan == UserPlan.Premium) return -1;
        
        if (!IsToday(TacticalPeriodStart))
            return FreeTierDailyLimit;
        
        return Math.Max(0, FreeTierDailyLimit - TacticalUsedPeriod);
    }
    
    /// <summary>
    /// Increment daily usage count. Resets if new UTC day.
    /// </summary>
    public void IncrementUsage()
    {
        if (!IsToday(TacticalPeriodStart))
        {
            TacticalPeriodStart = DateTime.UtcNow;
            TacticalUsedPeriod = 1;
        }
        else
        {
            TacticalUsedPeriod++;
        }
    }
    
    private static bool IsToday(DateTime? date)
    {
        return date.HasValue && date.Value.Date == DateTime.UtcNow.Date;
    }
}
