using TennisGPT.Domain.Entities;

namespace TennisGPT.Application.Interfaces;

public interface IQuotaService
{
    /// <summary>
    /// Check if user can make an AI request. Returns (canProceed, error message if blocked)
    /// </summary>
    Task<QuotaCheckResult> CheckAndConsumeQuotaAsync(Guid userId, string requestType = "tactical");
    
    /// <summary>
    /// Check rate limit for user + IP combination
    /// </summary>
    Task<RateLimitResult> CheckRateLimitAsync(Guid userId, string ipAddress);
}

public class QuotaCheckResult
{
    public bool CanProceed { get; set; }
    public string? ErrorMessage { get; set; }
    public int StatusCode { get; set; } = 200;
    public string? RequestId { get; set; }
    public int RemainingQuota { get; set; }
    public UserPlan UserPlan { get; set; }
    
    public static QuotaCheckResult Success(int remaining, UserPlan plan) => new()
    {
        CanProceed = true,
        RemainingQuota = remaining,
        UserPlan = plan
    };
    
    public static QuotaCheckResult QuotaExceeded(string requestId) => new()
    {
        CanProceed = false,
        ErrorMessage = "You've used all your free analyses this month. Upgrade to Premium for unlimited access.",
        StatusCode = 402, // Payment Required
        RequestId = requestId
    };
    
    public static QuotaCheckResult UserNotFound(string requestId) => new()
    {
        CanProceed = false,
        ErrorMessage = "User not found",
        StatusCode = 401,
        RequestId = requestId
    };
}

public class RateLimitResult
{
    public bool IsLimited { get; set; }
    public int RetryAfterSeconds { get; set; }
    public string? RequestId { get; set; }
    
    public static RateLimitResult Ok() => new() { IsLimited = false };
    
    public static RateLimitResult Limited(int retryAfter, string requestId) => new()
    {
        IsLimited = true,
        RetryAfterSeconds = retryAfter,
        RequestId = requestId
    };
}

