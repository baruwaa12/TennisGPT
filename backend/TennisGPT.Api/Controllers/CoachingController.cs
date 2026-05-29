using System.Security.Claims;
using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TennisGPT.Application.DTOs.Coaching;
using TennisGPT.Application.Interfaces;
using TennisGPT.Domain.Entities;

namespace TennisGPT.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CoachingController : ControllerBase
{
    private readonly IOpenAIService _openAIService;
    private readonly IQuotaService _quotaService;
    private readonly ISavedEntryRepository _savedEntryRepository;
    private readonly ILogger<CoachingController> _logger;

    public CoachingController(
        IOpenAIService openAIService, 
        IQuotaService quotaService,
        ISavedEntryRepository savedEntryRepository,
        ILogger<CoachingController> logger)
    {
        _openAIService = openAIService;
        _quotaService = quotaService;
        _savedEntryRepository = savedEntryRepository;
        _logger = logger;
    }
    
    private Guid? GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrEmpty(userIdClaim))
            return null;

        return Guid.TryParse(userIdClaim, out var userId) ? userId : null;
    }
    
    private string GetClientIp()
    {
        return HttpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
    }
    
    private async Task<ActionResult?> CheckQuotaAndRateLimitAsync(string endpoint)
    {
        var userId = GetUserId();
        if (userId == null)
        {
            return Unauthorized(new ErrorResponse 
            { 
                Error = "Authentication required",
                RequestId = GenerateRequestId()
            });
        }
        
        // Rate limit check
        var rateLimitResult = await _quotaService.CheckRateLimitAsync(userId.Value, GetClientIp());
        if (rateLimitResult.IsLimited)
        {
            Response.Headers.Append("Retry-After", rateLimitResult.RetryAfterSeconds.ToString());
            return StatusCode(429, new ErrorResponse
            {
                Error = "Too many requests — please slow down",
                RequestId = rateLimitResult.RequestId,
                RetryAfterSeconds = rateLimitResult.RetryAfterSeconds
            });
        }
        
        // Only check quota for AI-consuming endpoints
        if (endpoint is "tactical-analysis" or "mental-check-in" or "emotional-reset" or "quick-tip" or "technique" or "match-strategy" or "drills" or "training-plan")
        {
            var quotaResult = await _quotaService.CheckAndConsumeQuotaAsync(userId.Value, endpoint);
            if (!quotaResult.CanProceed)
            {
                return StatusCode(quotaResult.StatusCode, new ErrorResponse
                {
                    Error = quotaResult.ErrorMessage ?? "Access denied",
                    RequestId = quotaResult.RequestId,
                    UpgradeRequired = quotaResult.StatusCode == 402
                });
            }
            
            // Add remaining quota to response headers
            Response.Headers.Append("X-Quota-Remaining", quotaResult.RemainingQuota.ToString());
            Response.Headers.Append("X-User-Plan", quotaResult.UserPlan.ToString().ToLower());
        }
        
        return null; // All checks passed
    }
    
    private static string GenerateRequestId() => Guid.NewGuid().ToString("N")[..8];

    private static bool IsLowDetailTacticalInput(string input)
    {
        var normalized = input.Trim().ToLowerInvariant();
        if (string.IsNullOrWhiteSpace(normalized))
            return true;

        // Likely score-only input, such as "6-4 6-3" or "lost 7-5 6-2".
        var hasScorePattern = Regex.IsMatch(normalized, @"\b\d{1,2}\s*-\s*\d{1,2}\b");
        var hasTacticalSignal = Regex.IsMatch(
            normalized,
            @"\b(serve|return|forehand|backhand|volley|rally|tactic|pattern|pressure|footwork|position|opponent|strategy)\b");

        var wordCount = normalized.Split(' ', StringSplitOptions.RemoveEmptyEntries).Length;
        if (hasScorePattern && !hasTacticalSignal && wordCount <= 10)
            return true;

        // Very short tactical requests typically produce generic output.
        return wordCount < 5;
    }

    private static string GetReflectiveQuestion()
    {
        var questions = new[]
        {
            "What exactly broke down when the score got tight?",
            "Which repeated pattern cost you the most points?",
            "What shot or movement felt least reliable under pressure?"
        };

        return questions[Random.Shared.Next(questions.Length)];
    }

    private static string BuildTacticalHistorySnapshot(TacticalAnalysisResponse response)
    {
        return string.Join("\n", new[]
        {
            $"WhatYoureSeeing: {response.WhatYoureSeeing}",
            $"WhyItMatters: {response.WhyItMatters}",
            $"NextFocus: {response.NextFocus}",
            $"PracticePlan: {response.OptionalPracticePlan?.DrillName} - {response.OptionalPracticePlan?.Objective}"
        });
    }

    [HttpPost("mental-check-in")]
    public async Task<ActionResult<CoachingResponse>> MentalCheckIn([FromBody] MentalCheckInRequest request)
    {
        var requestId = GenerateRequestId();
        var userId = GetUserId();
        
        _logger.LogInformation("[{RequestId}] MentalCheckIn User={UserId}, Mood={Mood}", requestId, userId, request.Mood);
        
        // Check quota and rate limit
        var blockResult = await CheckQuotaAndRateLimitAsync("mental-check-in");
        if (blockResult != null) return blockResult;
        
        try
        {
            var response = await _openAIService.MentalCheckInAsync(request.Mood, request.JournalEntry);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[{RequestId}] MentalCheckIn failed", requestId);
            return StatusCode(500, new ErrorResponse
            {
                Error = "Unable to generate your briefing right now. Please try again.",
                RequestId = requestId
            });
        }
    }

    [HttpPost("emotional-reset")]
    public async Task<ActionResult<CoachingResponse>> EmotionalReset([FromBody] EmotionalResetRequest request)
    {
        var requestId = GenerateRequestId();
        var userId = GetUserId();
        
        _logger.LogInformation("[{RequestId}] EmotionalReset User={UserId}, Situation length={Length}", 
            requestId, userId, request.Situation?.Length ?? 0);
        
        // Check quota and rate limit
        var blockResult = await CheckQuotaAndRateLimitAsync("emotional-reset");
        if (blockResult != null) return blockResult;
        
        if (string.IsNullOrWhiteSpace(request.Situation))
        {
            return BadRequest(new ErrorResponse 
            { 
                Error = "Please describe your situation",
                RequestId = requestId
            });
        }
        
        try
        {
            var response = await _openAIService.EmotionalResetAsync(request.Situation);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[{RequestId}] EmotionalReset failed", requestId);
            return StatusCode(500, new ErrorResponse
            {
                Error = "Unable to generate your debrief right now. Please try again.",
                RequestId = requestId
            });
        }
    }

    [HttpPost("tactical-analysis")]
    public async Task<ActionResult<TacticalAnalysisResponse>> TacticalAnalysis([FromBody] TacticalAnalysisRequest request)
    {
        var requestId = GenerateRequestId();
        var userId = GetUserId();
        
        _logger.LogInformation("[{RequestId}] TacticalAnalysis User={UserId}, Description length={Length}", 
            requestId, userId, request.MatchDescription?.Length ?? 0);
        
        if (string.IsNullOrWhiteSpace(request.MatchDescription))
        {
            return BadRequest(new ErrorResponse 
            { 
                Error = "Please describe your match or question",
                RequestId = requestId
            });
        }

        if (IsLowDetailTacticalInput(request.MatchDescription))
        {
            var reflectiveQuestion = GetReflectiveQuestion();
            return BadRequest(new ErrorResponse
            {
                Error = $"To get useful tactical feedback, add a short self-analysis (what happened, when it happened, and what pattern you noticed). Start with this: {reflectiveQuestion}",
                RequestId = requestId
            });
        }

        // Check quota and rate limit after validating request quality.
        var blockResult = await CheckQuotaAndRateLimitAsync("tactical-analysis");
        if (blockResult != null) return blockResult;
        
        try
        {
            var matchesJson = request.RecentMatches != null
                ? JsonSerializer.Serialize(request.RecentMatches)
                : null;

            var recentAdviceHistory = new List<string>();
            if (userId.HasValue)
            {
                var recentHistoryEntries = await _savedEntryRepository.GetByUserAndCategoryAsync(
                    userId.Value,
                    SavedEntryCategory.TacticalHistory);

                recentAdviceHistory = recentHistoryEntries
                    .Select(e => e.Content)
                    .Where(c => !string.IsNullOrWhiteSpace(c))
                    .Take(3)
                    .ToList();

                if (recentAdviceHistory.Count == 0)
                {
                    // Backward-compatible bootstrap from manually saved tactical advice.
                    var savedAdvice = await _savedEntryRepository.GetByUserAndCategoryAsync(
                        userId.Value,
                        SavedEntryCategory.TacticalAdvice);
                    recentAdviceHistory = savedAdvice
                        .Select(e => e.Content)
                        .Where(c => !string.IsNullOrWhiteSpace(c))
                        .Take(3)
                        .ToList();
                }
            }

            var response = await _openAIService.TacticalAnalysisAsync(
                request.MatchDescription,
                matchesJson,
                request.FocusType,
                recentAdviceHistory);

            if (userId.HasValue && !string.IsNullOrWhiteSpace(response.WhatYoureSeeing))
            {
                // Auto-capture tactical outputs so future requests can adapt and avoid repetition.
                var snapshot = BuildTacticalHistorySnapshot(response);
                await _savedEntryRepository.SaveAndTrimAsync(
                    userId.Value,
                    SavedEntryCategory.TacticalHistory,
                    snapshot);
            }
            
            _logger.LogInformation("[{RequestId}] TacticalAnalysis success", requestId);
            
            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[{RequestId}] TacticalAnalysis failed", requestId);
            return StatusCode(500, new ErrorResponse
            {
                Error = "Unable to generate tactical insight right now. Please try again.",
                RequestId = requestId
            });
        }
    }

    [HttpPost("drills")]
    public async Task<ActionResult<CoachingResponse>> GenerateDrills([FromBody] DrillsRequest request)
    {
        var requestId = GenerateRequestId();
        var userId = GetUserId();
        
        _logger.LogInformation("[{RequestId}] GenerateDrills User={UserId}, Matches={Count}", 
            requestId, userId, request.Matches?.Count ?? 0);
        
        var blockResult = await CheckQuotaAndRateLimitAsync("drills");
        if (blockResult != null) return blockResult;
        
        try
        {
            var matchesJson = JsonSerializer.Serialize(request.Matches);
            var response = await _openAIService.GenerateDrillsAsync(matchesJson);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[{RequestId}] GenerateDrills failed", requestId);
            return StatusCode(500, new ErrorResponse
            {
                Error = "Unable to generate drills right now. Please try again.",
                RequestId = requestId
            });
        }
    }

    [HttpPost("quick-tip")]
    public async Task<ActionResult<CoachingResponse>> QuickTip([FromBody] QuickTipRequest request)
    {
        var requestId = GenerateRequestId();
        var userId = GetUserId();
        
        _logger.LogInformation("[{RequestId}] QuickTip User={UserId}", requestId, userId);
        
        var blockResult = await CheckQuotaAndRateLimitAsync("quick-tip");
        if (blockResult != null) return blockResult;
        
        try
        {
            var response = await _openAIService.QuickTacticalTipAsync(request.Situation);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[{RequestId}] QuickTip failed", requestId);
            return StatusCode(500, new ErrorResponse
            {
                Error = "Unable to generate a tip right now. Please try again.",
                RequestId = requestId
            });
        }
    }

    [HttpPost("technique")]
    public async Task<ActionResult<CoachingResponse>> AnalyzeTechnique([FromBody] TechniqueAnalysisRequest request)
    {
        var requestId = GenerateRequestId();
        var userId = GetUserId();
        
        _logger.LogInformation("[{RequestId}] AnalyzeTechnique User={UserId}", requestId, userId);
        
        var blockResult = await CheckQuotaAndRateLimitAsync("technique");
        if (blockResult != null) return blockResult;
        
        try
        {
            var response = await _openAIService.AnalyzeTechniqueAsync(request.Description);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[{RequestId}] AnalyzeTechnique failed", requestId);
            return StatusCode(500, new ErrorResponse
            {
                Error = "Unable to analyze technique right now. Please try again.",
                RequestId = requestId
            });
        }
    }

    [HttpPost("match-strategy")]
    public async Task<ActionResult<CoachingResponse>> MatchStrategy([FromBody] MatchStrategyRequest request)
    {
        var requestId = GenerateRequestId();
        var userId = GetUserId();
        
        _logger.LogInformation("[{RequestId}] MatchStrategy User={UserId}", requestId, userId);
        
        var blockResult = await CheckQuotaAndRateLimitAsync("match-strategy");
        if (blockResult != null) return blockResult;
        
        try
        {
            var response = await _openAIService.GetMatchStrategyAsync(request.OpponentDescription);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[{RequestId}] MatchStrategy failed", requestId);
            return StatusCode(500, new ErrorResponse
            {
                Error = "Unable to generate strategy right now. Please try again.",
                RequestId = requestId
            });
        }
    }

    [HttpPost("training-plan")]
    public async Task<ActionResult<CoachingResponse>> TrainingPlan([FromBody] TrainingPlanRequest request)
    {
        var requestId = GenerateRequestId();
        var userId = GetUserId();
        
        _logger.LogInformation("[{RequestId}] TrainingPlan User={UserId}", requestId, userId);
        
        var blockResult = await CheckQuotaAndRateLimitAsync("training-plan");
        if (blockResult != null) return blockResult;
        
        try
        {
            var response = await _openAIService.GenerateTrainingPlanAsync(request.PlayerLevel, request.Goals);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[{RequestId}] TrainingPlan failed", requestId);
            return StatusCode(500, new ErrorResponse
            {
                Error = "Unable to generate training plan right now. Please try again.",
                RequestId = requestId
            });
        }
    }
}

// Error response DTO for consistent error handling
public class ErrorResponse
{
    public string Error { get; set; } = "";
    public string? RequestId { get; set; }
    public bool UpgradeRequired { get; set; } = false;
    public int? RetryAfterSeconds { get; set; }
}
