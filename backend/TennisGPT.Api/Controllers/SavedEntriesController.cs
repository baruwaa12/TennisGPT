using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TennisGPT.Application.DTOs.SavedEntries;
using TennisGPT.Application.Interfaces;
using TennisGPT.Domain.Entities;

namespace TennisGPT.Api.Controllers;

[ApiController]
[Authorize]
public class SavedEntriesController : ControllerBase
{
    private readonly ISavedEntryRepository _repository;
    private readonly ILogger<SavedEntriesController> _logger;

    /// <summary>
    /// Debounce window in seconds — reject duplicate saves within this window.
    /// </summary>
    private const int DebounceDuplicateSeconds = 5;

    public SavedEntriesController(ISavedEntryRepository repository, ILogger<SavedEntriesController> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    // ============ Tactical Advice ============

    [HttpPost("api/tactical/save")]
    public Task<ActionResult<SavedEntryDto>> SaveTactical([FromBody] SaveEntryRequest request)
        => SaveEntry(request, SavedEntryCategory.TacticalAdvice);

    [HttpGet("api/tactical/saved")]
    public Task<ActionResult<IEnumerable<SavedEntryDto>>> GetTactical()
        => GetEntries(SavedEntryCategory.TacticalAdvice);

    // ============ Post-Match Debrief ============

    [HttpPost("api/debrief/save")]
    public Task<ActionResult<SavedEntryDto>> SaveDebrief([FromBody] SaveEntryRequest request)
        => SaveEntry(request, SavedEntryCategory.PostMatchDebrief);

    [HttpGet("api/debrief/saved")]
    public Task<ActionResult<IEnumerable<SavedEntryDto>>> GetDebriefs()
        => GetEntries(SavedEntryCategory.PostMatchDebrief);

    // ============ Pre-Match Plan ============

    [HttpPost("api/prematch/save")]
    public Task<ActionResult<SavedEntryDto>> SavePreMatch([FromBody] SaveEntryRequest request)
        => SaveEntry(request, SavedEntryCategory.PreMatchPlan);

    [HttpGet("api/prematch/saved")]
    public Task<ActionResult<IEnumerable<SavedEntryDto>>> GetPreMatch()
        => GetEntries(SavedEntryCategory.PreMatchPlan);

    // ============ Shared Logic ============

    private async Task<ActionResult<SavedEntryDto>> SaveEntry(SaveEntryRequest request, SavedEntryCategory category)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        if (string.IsNullOrWhiteSpace(request.Content))
            return BadRequest(new { error = "Content is required." });

        // Double-tap prevention: reject if identical content was saved in last N seconds
        var existing = await _repository.GetByUserAndCategoryAsync(userId.Value, category);
        var recentDuplicate = existing.FirstOrDefault(e =>
            e.Content == request.Content &&
            (DateTime.UtcNow - e.CreatedAtUtc).TotalSeconds < DebounceDuplicateSeconds);

        if (recentDuplicate != null)
        {
            _logger.LogInformation("Duplicate save blocked for user {UserId}, category {Category}", userId, category);
            return Ok(MapToDto(recentDuplicate));
        }

        try
        {
            var entry = await _repository.SaveAndTrimAsync(userId.Value, category, request.Content);
            _logger.LogInformation("Saved {Category} entry for user {UserId}", category, userId);
            return Ok(MapToDto(entry));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to save {Category} entry for user {UserId}", category, userId);
            return StatusCode(500, new { error = "Unable to save. Please try again." });
        }
    }

    private async Task<ActionResult<IEnumerable<SavedEntryDto>>> GetEntries(SavedEntryCategory category)
    {
        var userId = GetUserId();
        if (userId == null) return Unauthorized();

        var entries = await _repository.GetByUserAndCategoryAsync(userId.Value, category);
        return Ok(entries.Select(MapToDto));
    }

    private Guid? GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrEmpty(userIdClaim)) return null;
        return Guid.TryParse(userIdClaim, out var userId) ? userId : null;
    }

    private static SavedEntryDto MapToDto(SavedEntry entry) => new()
    {
        Id = entry.Id,
        Content = entry.Content,
        CreatedAtUtc = entry.CreatedAtUtc
    };
}
