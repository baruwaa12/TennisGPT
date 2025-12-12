using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TennisGPT.Application.DTOs.Match;
using TennisGPT.Application.Interfaces;
using TennisGPT.Domain.Entities;

namespace TennisGPT.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class MatchesController : ControllerBase
{
    private readonly IMatchRepository _matchRepository;

    public MatchesController(IMatchRepository matchRepository)
    {
        _matchRepository = matchRepository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<MatchDto>>> GetAll()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var matches = await _matchRepository.GetAllByUserIdAsync(userId.Value);
        return Ok(matches.Select(MapToDto));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<MatchDto>> GetById(Guid id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var match = await _matchRepository.GetByIdAsync(id);
        if (match == null || match.UserId != userId)
            return NotFound();

        return Ok(MapToDto(match));
    }

    [HttpGet("recent")]
    public async Task<ActionResult<IEnumerable<MatchDto>>> GetRecent([FromQuery] int count = 5)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var matches = await _matchRepository.GetRecentByUserIdAsync(userId.Value, count);
        return Ok(matches.Select(MapToDto));
    }

    [HttpPost]
    public async Task<ActionResult<MatchDto>> Create([FromBody] CreateMatchRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var match = new Match
        {
            UserId = userId.Value,
            Date = request.Date,
            Opponent = request.Opponent,
            Result = request.Result,
            SetsWon = request.SetsWon,
            SetsLost = request.SetsLost,
            Surface = request.Surface,
            Weather = request.Weather,
            Notes = request.Notes,
            Strengths = request.Strengths,
            Weaknesses = request.Weaknesses,
            KeyMoments = request.KeyMoments,
            TacticalAnalysis = request.TacticalAnalysis,
            RecommendedDrills = request.RecommendedDrills
        };

        var created = await _matchRepository.CreateAsync(match);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, MapToDto(created));
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<MatchDto>> Update(Guid id, [FromBody] UpdateMatchRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var match = await _matchRepository.GetByIdAsync(id);
        if (match == null || match.UserId != userId)
            return NotFound();

        match.Date = request.Date;
        match.Opponent = request.Opponent;
        match.Result = request.Result;
        match.SetsWon = request.SetsWon;
        match.SetsLost = request.SetsLost;
        match.Surface = request.Surface;
        match.Weather = request.Weather;
        match.Notes = request.Notes;
        match.Strengths = request.Strengths;
        match.Weaknesses = request.Weaknesses;
        match.KeyMoments = request.KeyMoments;
        match.TacticalAnalysis = request.TacticalAnalysis;
        match.RecommendedDrills = request.RecommendedDrills;

        var updated = await _matchRepository.UpdateAsync(match);
        return Ok(MapToDto(updated));
    }

    [HttpDelete("{id}")]
    public async Task<ActionResult> Delete(Guid id)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var match = await _matchRepository.GetByIdAsync(id);
        if (match == null || match.UserId != userId)
            return NotFound();

        await _matchRepository.DeleteAsync(id);
        return NoContent();
    }

    private Guid? GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrEmpty(userIdClaim))
            return null;

        return Guid.TryParse(userIdClaim, out var userId) ? userId : null;
    }

    private static MatchDto MapToDto(Match match)
    {
        return new MatchDto
        {
            Id = match.Id,
            Date = match.Date,
            Opponent = match.Opponent,
            Result = match.Result,
            SetsWon = match.SetsWon,
            SetsLost = match.SetsLost,
            Surface = match.Surface,
            Weather = match.Weather,
            Notes = match.Notes,
            Strengths = match.Strengths,
            Weaknesses = match.Weaknesses,
            KeyMoments = match.KeyMoments,
            TacticalAnalysis = match.TacticalAnalysis,
            RecommendedDrills = match.RecommendedDrills,
            CreatedAt = match.CreatedAt,
            UpdatedAt = match.UpdatedAt
        };
    }
}
