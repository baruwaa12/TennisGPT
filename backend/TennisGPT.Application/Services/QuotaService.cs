using System.Collections.Concurrent;
using Microsoft.Extensions.Logging;
using TennisGPT.Application.Interfaces;
using TennisGPT.Domain.Entities;

namespace TennisGPT.Application.Services;

public class QuotaService : IQuotaService
{
    private readonly IUserRepository _userRepository;
    private readonly ILogger<QuotaService> _logger;
    
    // Simple in-memory rate limiter (per user)
    // In production, use Redis or similar for distributed rate limiting
    private static readonly ConcurrentDictionary<string, RateLimitEntry> _rateLimits = new();
    
    // Rate limit: 10 requests per minute per user
    private const int RateLimitPerMinute = 10;
    private const int RateLimitWindowSeconds = 60;

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

            // Premium users have unlimited access
            if (user.Plan == UserPlan.Premium)
            {
                _logger.LogInformation("[{RequestId}] User {UserId} is Premium - unlimited access", requestId, userId);
                return QuotaCheckResult.Success(-1, UserPlan.Premium);
            }

            // Check quota for free users
            if (!user.CanUseTacticalAnalysis())
            {
                _logger.LogInformation("[{RequestId}] User {UserId} quota exceeded (used: {Used})", 
                    requestId, userId, user.TacticalUsedPeriod);
                return QuotaCheckResult.QuotaExceeded(requestId);
            }

            // Consume quota atomically
            var remainingBefore = user.GetRemainingTacticalAnalyses();
            user.IncrementTacticalUsage();
            await _userRepository.UpdateAsync(user);
            
            var remainingAfter = user.GetRemainingTacticalAnalyses();
            
            _logger.LogInformation("[{RequestId}] User {UserId} quota consumed: {Remaining} remaining", 
                requestId, userId, remainingAfter);

            return QuotaCheckResult.Success(remainingAfter, user.Plan);
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
        var key = $"{userId}:{ipAddress}";
        var now = DateTime.UtcNow;
        
        var entry = _rateLimits.GetOrAdd(key, _ => new RateLimitEntry
        {
            WindowStart = now,
            RequestCount = 0
        });

        lock (entry)
        {
            // Reset window if expired
            if ((now - entry.WindowStart).TotalSeconds >= RateLimitWindowSeconds)
            {
                entry.WindowStart = now;
                entry.RequestCount = 0;
            }

            entry.RequestCount++;

            if (entry.RequestCount > RateLimitPerMinute)
            {
                var retryAfter = (int)(RateLimitWindowSeconds - (now - entry.WindowStart).TotalSeconds);
                _logger.LogWarning("[{RequestId}] Rate limit exceeded for {Key}: {Count} requests", 
                    requestId, key, entry.RequestCount);
                return Task.FromResult(RateLimitResult.Limited(Math.Max(1, retryAfter), requestId));
            }
        }

        return Task.FromResult(RateLimitResult.Ok());
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

