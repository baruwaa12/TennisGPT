using System.Collections.Concurrent;
using Microsoft.Extensions.Logging;
using TennisGPT.Application.Interfaces;
using TennisGPT.Domain.Entities;

namespace TennisGPT.Application.Services;

public class QuotaService : IQuotaService
{
    private readonly IUserRepository _userRepository;
    private readonly ILogger<QuotaService> _logger;
    
    // In-memory rate limiter (per user, NOT per user+IP)
    // Two windows: per-minute and per-hour for fair use
    private static readonly ConcurrentDictionary<string, RateLimitEntry> _minuteLimits = new();
    private static readonly ConcurrentDictionary<string, RateLimitEntry> _hourLimits = new();
    
    // Rate limits — applies to ALL users (including premium)
    private const int MaxPerMinute = 30;
    private const int MaxPerHour = 300;
    private const int MinuteWindowSeconds = 60;
    private const int HourWindowSeconds = 3600;

    public QuotaService(IUserRepository userRepository, ILogger<QuotaService> logger)
    {
        _userRepository = userRepository;
        _logger = logger;
    }

    public async Task<QuotaCheckResult> CheckAndConsumeQuotaAsync(Guid userId, string requestType = "tactical")
    {
        var requestId = GenerateRequestId();
        
        try
        {
            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null)
            {
                _logger.LogWarning("[{RequestId}] Quota check failed: User {UserId} not found", requestId, userId);
                return QuotaCheckResult.UserNotFound(requestId);
            }

            // Premium and comped users — unlimited, skip quota entirely
            if (user.Plan == UserPlan.Premium || user.IsComped)
            {
                _logger.LogInformation("[{RequestId}] User {UserId} is Premium/Comped — unlimited access", requestId, userId);
                return QuotaCheckResult.Success(-1, user.Plan);
            }

            // Free users — daily quota check
            if (!user.CanUseAI())
            {
                _logger.LogInformation("[{RequestId}] User {UserId} daily limit reached (used: {Used}/{Limit})", 
                    requestId, userId, user.TacticalUsedPeriod, User.FreeTierDailyLimit);
                return QuotaCheckResult.QuotaExceeded(requestId);
            }

            // Consume daily quota
            user.IncrementUsage();
            await _userRepository.UpdateAsync(user);
            
            var remaining = user.GetRemainingAICalls();
            
            _logger.LogInformation("[{RequestId}] User {UserId} quota consumed: {Remaining} remaining today", 
                requestId, userId, remaining);

            return QuotaCheckResult.Success(remaining, user.Plan);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[{RequestId}] Error checking quota for user {UserId}", requestId, userId);
            throw;
        }
    }

    public Task<RateLimitResult> CheckRateLimitAsync(Guid userId, string ipAddress)
    {
        var requestId = GenerateRequestId();
        var key = userId.ToString();
        var now = DateTime.UtcNow;
        
        // Check per-minute limit (30 req/min)
        var minuteResult = CheckWindow(_minuteLimits, key, now, MinuteWindowSeconds, MaxPerMinute);
        if (minuteResult.exceeded)
        {
            _logger.LogWarning("[{RequestId}] Rate limit exceeded (minute) for user {UserId}: {Count} requests", 
                requestId, userId, minuteResult.count);
            return Task.FromResult(RateLimitResult.Limited(Math.Max(1, minuteResult.retryAfter), requestId));
        }
        
        // Check per-hour limit (300 req/hr)
        var hourResult = CheckWindow(_hourLimits, key, now, HourWindowSeconds, MaxPerHour);
        if (hourResult.exceeded)
        {
            _logger.LogWarning("[{RequestId}] Rate limit exceeded (hour) for user {UserId}: {Count} requests", 
                requestId, userId, hourResult.count);
            return Task.FromResult(RateLimitResult.Limited(Math.Max(1, hourResult.retryAfter), requestId));
        }

        return Task.FromResult(RateLimitResult.Ok());
    }
    
    private static (bool exceeded, int retryAfter, int count) CheckWindow(
        ConcurrentDictionary<string, RateLimitEntry> store,
        string key,
        DateTime now,
        int windowSeconds,
        int maxRequests)
    {
        var entry = store.GetOrAdd(key, _ => new RateLimitEntry
        {
            WindowStart = now,
            RequestCount = 0
        });

        lock (entry)
        {
            if ((now - entry.WindowStart).TotalSeconds >= windowSeconds)
            {
                entry.WindowStart = now;
                entry.RequestCount = 0;
            }

            entry.RequestCount++;

            if (entry.RequestCount > maxRequests)
            {
                var retryAfter = (int)(windowSeconds - (now - entry.WindowStart).TotalSeconds);
                return (true, retryAfter, entry.RequestCount);
            }
        }

        return (false, 0, entry.RequestCount);
    }

    private static string GenerateRequestId()
    {
        return Guid.NewGuid().ToString("N")[..8];
    }

    private class RateLimitEntry
    {
        public DateTime WindowStart { get; set; }
        public int RequestCount { get; set; }
    }
}

