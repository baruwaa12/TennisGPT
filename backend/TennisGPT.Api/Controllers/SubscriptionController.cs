using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TennisGPT.Application.Interfaces;
using TennisGPT.Application.Options;

namespace TennisGPT.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SubscriptionController : ControllerBase
{
    private readonly IRevenueCatSubscriptionSyncService _syncService;
    private readonly IFounderClaimRepository _founderClaimRepository;
    private readonly IConfiguration _configuration;
    private readonly ILogger<SubscriptionController> _logger;

    public SubscriptionController(
        IRevenueCatSubscriptionSyncService syncService,
        IFounderClaimRepository founderClaimRepository,
        IConfiguration configuration,
        ILogger<SubscriptionController> logger)
    {
        _syncService = syncService;
        _founderClaimRepository = founderClaimRepository;
        _configuration = configuration;
        _logger = logger;
    }

    /// <summary>
    /// Public founder spot counter for paywall UI (not authenticated).
    /// </summary>
    [HttpGet("founder-inventory")]
    [AllowAnonymous]
    public async Task<IActionResult> FounderInventory(CancellationToken cancellationToken)
    {
        var taken = await _founderClaimRepository.GetClaimCountAsync(cancellationToken);
        return Ok(new
        {
            spotsClaimed = taken,
            spotsTotal = FounderSubscriptionOptions.MaxFounderSpots,
        });
    }

    /// <summary>
    /// Pulls the latest entitlements from RevenueCat and updates the signed-in user's plan.
    /// Call after purchase, restore, or login on a new device.
    /// </summary>
    [HttpPost("sync")]
    public async Task<IActionResult> Sync(CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_configuration["RevenueCat:SecretApiKey"]))
        {
            _logger.LogWarning("RevenueCat SecretApiKey is not configured");
            return StatusCode(503, new { message = "Subscription sync is not configured" });
        }

        var email = User.FindFirstValue(JwtRegisteredClaimNames.Email)
            ?? User.FindFirstValue(ClaimTypes.Email);

        if (string.IsNullOrEmpty(email))
        {
            return BadRequest(new { message = "Email claim missing" });
        }

        var ok = await _syncService.SyncPlanForAppUserAsync(email, cancellationToken);
        return Ok(new { synced = ok, email });
    }
}
