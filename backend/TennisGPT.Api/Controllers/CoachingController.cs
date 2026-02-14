using System.Security.Claims;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TennisGPT.Application.DTOs.Coaching;
using TennisGPT.Application.Interfaces;

namespace TennisGPT.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CoachingController : ControllerBase
{
    private readonly IOpenAIService _openAIService;
    private readonly IQuotaService _quotaService;
    private readonly ILogger<CoachingController> _logger;

    public CoachingController(
        IOpenAIService openAIService, 
        IQuotaService quotaService,
        ILogger<CoachingController> logger)
    {
        _openAIService = openAIService;
        _quotaService = quotaService;
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
                Error = "Too many requests. Please wait before trying again.",
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
        
        // Check quota and rate limit
        var blockResult = await CheckQuotaAndRateLimitAsync("tactical-analysis");
        if (blockResult != null) return blockResult;
        
        if (string.IsNullOrWhiteSpace(request.MatchDescription))
        {
            return BadRequest(new ErrorResponse 
            { 
                Error = "Please describe your match or question",
                RequestId = requestId
            });
        }
        
        try
        {
            var matchesJson = request.RecentMatches != null
                ? JsonSerializer.Serialize(request.RecentMatches)
                : null;

            var response = await _openAIService.TacticalAnalysisAsync(request.MatchDescription, matchesJson);
            
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
