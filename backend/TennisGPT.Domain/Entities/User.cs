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
    
    // Quota tracking (monthly rolling window)
    public int TacticalUsedPeriod { get; set; } = 0;
    public DateTime? TacticalPeriodStart { get; set; }

    // Navigation properties
    public ICollection<Match> Matches { get; set; } = [];
    public ICollection<CheckIn> CheckIns { get; set; } = [];
    
    // Quota constants
    public const int FreeTierMonthlyLimit = 4;
    
    /// <summary>
    /// Check if user can use tactical analysis (respects plan and quota)
    /// </summary>
    public bool CanUseTacticalAnalysis()
    {
        if (Plan == UserPlan.Premium) return true;
        
        // Reset period if more than 30 days have passed
        if (TacticalPeriodStart == null || DateTime.UtcNow.Subtract(TacticalPeriodStart.Value).TotalDays >= 30)
        {
            return true; // Will be reset when used
        }
        
        return TacticalUsedPeriod < FreeTierMonthlyLimit;
    }
    
    /// <summary>
    /// Get remaining tactical analyses for free tier
    /// </summary>
    public int GetRemainingTacticalAnalyses()
    {
        if (Plan == UserPlan.Premium) return -1; // Unlimited
        
        // If period expired, they have full quota
        if (TacticalPeriodStart == null || DateTime.UtcNow.Subtract(TacticalPeriodStart.Value).TotalDays >= 30)
        {
            return FreeTierMonthlyLimit;
        }
        
        return Math.Max(0, FreeTierMonthlyLimit - TacticalUsedPeriod);
    }
    
    /// <summary>
    /// Increment usage count atomically
    /// </summary>
    public void IncrementTacticalUsage()
    {
        // Reset period if expired
        if (TacticalPeriodStart == null || DateTime.UtcNow.Subtract(TacticalPeriodStart.Value).TotalDays >= 30)
        {
            TacticalPeriodStart = DateTime.UtcNow;
            TacticalUsedPeriod = 1;
        }
        else
        {
            TacticalUsedPeriod++;
        }
    }
}
