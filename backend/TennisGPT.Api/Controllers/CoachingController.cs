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

    public CoachingController(IOpenAIService openAIService)
    {
        _openAIService = openAIService;
    }

    [HttpPost("mental-check-in")]
    public async Task<ActionResult<CoachingResponse>> MentalCheckIn([FromBody] MentalCheckInRequest request)
    {
        var response = await _openAIService.MentalCheckInAsync(request.Mood, request.JournalEntry);
        return Ok(new CoachingResponse { Response = response });
    }

    [HttpPost("emotional-reset")]
    public async Task<ActionResult<CoachingResponse>> EmotionalReset([FromBody] EmotionalResetRequest request)
    {
        var response = await _openAIService.EmotionalResetAsync(request.Situation);
        return Ok(new CoachingResponse { Response = response });
    }

    [HttpPost("tactical-analysis")]
    public async Task<ActionResult<CoachingResponse>> TacticalAnalysis([FromBody] TacticalAnalysisRequest request)
    {
        var matchesJson = request.RecentMatches != null
            ? JsonSerializer.Serialize(request.RecentMatches)
            : null;

        var response = await _openAIService.TacticalAnalysisAsync(request.MatchDescription, matchesJson);
        return Ok(new CoachingResponse { Response = response });
    }

    [HttpPost("drills")]
    public async Task<ActionResult<CoachingResponse>> GenerateDrills([FromBody] DrillsRequest request)
    {
        var matchesJson = JsonSerializer.Serialize(request.Matches);
        var response = await _openAIService.GenerateDrillsAsync(matchesJson);
        return Ok(new CoachingResponse { Response = response });
    }

    [HttpPost("quick-tip")]
    public async Task<ActionResult<CoachingResponse>> QuickTip([FromBody] QuickTipRequest request)
    {
        var response = await _openAIService.QuickTacticalTipAsync(request.Situation);
        return Ok(new CoachingResponse { Response = response });
    }

    [HttpPost("technique")]
    public async Task<ActionResult<CoachingResponse>> AnalyzeTechnique([FromBody] TechniqueAnalysisRequest request)
    {
        var response = await _openAIService.AnalyzeTechniqueAsync(request.Description);
        return Ok(new CoachingResponse { Response = response });
    }

    [HttpPost("match-strategy")]
    public async Task<ActionResult<CoachingResponse>> MatchStrategy([FromBody] MatchStrategyRequest request)
    {
        var response = await _openAIService.GetMatchStrategyAsync(request.OpponentDescription);
        return Ok(new CoachingResponse { Response = response });
    }

    [HttpPost("training-plan")]
    public async Task<ActionResult<CoachingResponse>> TrainingPlan([FromBody] TrainingPlanRequest request)
    {
        var response = await _openAIService.GenerateTrainingPlanAsync(request.PlayerLevel, request.Goals);
        return Ok(new CoachingResponse { Response = response });
    }
}
