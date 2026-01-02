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
    private readonly ILogger<CoachingController> _logger;

    public CoachingController(IOpenAIService openAIService, ILogger<CoachingController> logger)
    {
        _openAIService = openAIService;
        _logger = logger;
    }

    [HttpPost("mental-check-in")]
    public async Task<ActionResult<CoachingResponse>> MentalCheckIn([FromBody] MentalCheckInRequest request)
    {
        var userId = User.FindFirst("sub")?.Value ?? "unknown";
        _logger.LogInformation("[MentalCheckIn] User={UserId}, Mood={Mood}", userId, request.Mood);
        
        try
        {
            var response = await _openAIService.MentalCheckInAsync(request.Mood, request.JournalEntry);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[MentalCheckIn] Failed for user {UserId}", userId);
            return Ok(new CoachingResponse { Response = "Unable to generate your briefing right now. Please try again." });
        }
    }

    [HttpPost("emotional-reset")]
    public async Task<ActionResult<CoachingResponse>> EmotionalReset([FromBody] EmotionalResetRequest request)
    {
        var userId = User.FindFirst("sub")?.Value ?? "unknown";
        _logger.LogInformation("[EmotionalReset] User={UserId}, Situation length={Length}", userId, request.Situation?.Length ?? 0);
        
        if (string.IsNullOrWhiteSpace(request.Situation))
        {
            return BadRequest(new { error = "Please describe your situation" });
        }
        
        try
        {
            var response = await _openAIService.EmotionalResetAsync(request.Situation);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[EmotionalReset] Failed for user {UserId}", userId);
            return Ok(new CoachingResponse { Response = "Unable to generate your debrief right now. Please try again." });
        }
    }

    [HttpPost("tactical-analysis")]
    public async Task<ActionResult<CoachingResponse>> TacticalAnalysis([FromBody] TacticalAnalysisRequest request)
    {
        var userId = User.FindFirst("sub")?.Value ?? "unknown";
        _logger.LogInformation("[TacticalAnalysis] User={UserId}, Description length={Length}, HasMatches={HasMatches}", 
            userId, request.MatchDescription?.Length ?? 0, request.RecentMatches != null);
        
        if (string.IsNullOrWhiteSpace(request.MatchDescription))
        {
            return BadRequest(new { error = "Please describe your match or question" });
        }
        
        try
        {
            var matchesJson = request.RecentMatches != null
                ? JsonSerializer.Serialize(request.RecentMatches)
                : null;

            var response = await _openAIService.TacticalAnalysisAsync(request.MatchDescription, matchesJson);
            _logger.LogInformation("[TacticalAnalysis] Success for user {UserId}, Response length={Length}", userId, response?.Length ?? 0);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[TacticalAnalysis] Failed for user {UserId}", userId);
            return Ok(new CoachingResponse { Response = "Unable to generate tactical insight right now. Please try again." });
        }
    }

    [HttpPost("drills")]
    public async Task<ActionResult<CoachingResponse>> GenerateDrills([FromBody] DrillsRequest request)
    {
        var userId = User.FindFirst("sub")?.Value ?? "unknown";
        _logger.LogInformation("[GenerateDrills] User={UserId}, Matches={Count}", userId, request.Matches?.Count ?? 0);
        
        try
        {
            var matchesJson = JsonSerializer.Serialize(request.Matches);
            var response = await _openAIService.GenerateDrillsAsync(matchesJson);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[GenerateDrills] Failed for user {UserId}", userId);
            return Ok(new CoachingResponse { Response = "Unable to generate drills right now. Please try again." });
        }
    }

    [HttpPost("quick-tip")]
    public async Task<ActionResult<CoachingResponse>> QuickTip([FromBody] QuickTipRequest request)
    {
        var userId = User.FindFirst("sub")?.Value ?? "unknown";
        _logger.LogInformation("[QuickTip] User={UserId}", userId);
        
        try
        {
            var response = await _openAIService.QuickTacticalTipAsync(request.Situation);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[QuickTip] Failed for user {UserId}", userId);
            return Ok(new CoachingResponse { Response = "Unable to generate a tip right now. Please try again." });
        }
    }

    [HttpPost("technique")]
    public async Task<ActionResult<CoachingResponse>> AnalyzeTechnique([FromBody] TechniqueAnalysisRequest request)
    {
        var userId = User.FindFirst("sub")?.Value ?? "unknown";
        _logger.LogInformation("[AnalyzeTechnique] User={UserId}", userId);
        
        try
        {
            var response = await _openAIService.AnalyzeTechniqueAsync(request.Description);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[AnalyzeTechnique] Failed for user {UserId}", userId);
            return Ok(new CoachingResponse { Response = "Unable to analyze technique right now. Please try again." });
        }
    }

    [HttpPost("match-strategy")]
    public async Task<ActionResult<CoachingResponse>> MatchStrategy([FromBody] MatchStrategyRequest request)
    {
        var userId = User.FindFirst("sub")?.Value ?? "unknown";
        _logger.LogInformation("[MatchStrategy] User={UserId}", userId);
        
        try
        {
            var response = await _openAIService.GetMatchStrategyAsync(request.OpponentDescription);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[MatchStrategy] Failed for user {UserId}", userId);
            return Ok(new CoachingResponse { Response = "Unable to generate strategy right now. Please try again." });
        }
    }

    [HttpPost("training-plan")]
    public async Task<ActionResult<CoachingResponse>> TrainingPlan([FromBody] TrainingPlanRequest request)
    {
        var userId = User.FindFirst("sub")?.Value ?? "unknown";
        _logger.LogInformation("[TrainingPlan] User={UserId}", userId);
        
        try
        {
            var response = await _openAIService.GenerateTrainingPlanAsync(request.PlayerLevel, request.Goals);
            return Ok(new CoachingResponse { Response = response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[TrainingPlan] Failed for user {UserId}", userId);
            return Ok(new CoachingResponse { Response = "Unable to generate training plan right now. Please try again." });
        }
    }
}
