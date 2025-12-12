using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TennisGPT.Application.DTOs.CheckIn;
using TennisGPT.Application.Interfaces;
using TennisGPT.Domain.Entities;

namespace TennisGPT.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CheckInsController : ControllerBase
{
    private readonly ICheckInRepository _checkInRepository;

    public CheckInsController(ICheckInRepository checkInRepository)
    {
        _checkInRepository = checkInRepository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CheckInDto>>> GetAll()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var checkIns = await _checkInRepository.GetAllByUserIdAsync(userId.Value);
        return Ok(checkIns.Select(MapToDto));
    }

    [HttpGet("last-rating")]
    public async Task<ActionResult<object>> GetLastRating()
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var lastCheckIn = await _checkInRepository.GetLastByUserIdAsync(userId.Value);
        if (lastCheckIn == null)
            return Ok(new { rating = (int?)null });

        return Ok(new { rating = lastCheckIn.Rating });
    }

    [HttpPost]
    public async Task<ActionResult<CheckInDto>> Create([FromBody] CreateCheckInRequest request)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var checkIn = new CheckIn
        {
            UserId = userId.Value,
            Timestamp = request.Timestamp,
            Rating = request.Rating,
            JournalText = request.JournalText,
            CoachResponse = request.CoachResponse
        };

        var created = await _checkInRepository.CreateAsync(checkIn);
        return CreatedAtAction(nameof(GetAll), MapToDto(created));
    }

    private Guid? GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrEmpty(userIdClaim))
            return null;

        return Guid.TryParse(userIdClaim, out var userId) ? userId : null;
    }

    private static CheckInDto MapToDto(CheckIn checkIn)
    {
        return new CheckInDto
        {
            Id = checkIn.Id,
            Timestamp = checkIn.Timestamp,
            Rating = checkIn.Rating,
            JournalText = checkIn.JournalText,
            CoachResponse = checkIn.CoachResponse,
            CreatedAt = checkIn.CreatedAt
        };
    }
}
