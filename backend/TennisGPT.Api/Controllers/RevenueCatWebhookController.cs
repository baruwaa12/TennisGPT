using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TennisGPT.Application.DTOs.RevenueCat;
using TennisGPT.Application.Interfaces;

namespace TennisGPT.Api.Controllers;

[ApiController]
[Route("api/webhooks/revenuecat")]
public class RevenueCatWebhookController : ControllerBase
{
    private readonly IRevenueCatSubscriptionSyncService _syncService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<RevenueCatWebhookController> _logger;

    private readonly IWebHostEnvironment _environment;

    public RevenueCatWebhookController(
        IRevenueCatSubscriptionSyncService syncService,
        IConfiguration configuration,
        ILogger<RevenueCatWebhookController> logger,
        IWebHostEnvironment environment)
    {
        _syncService = syncService;
        _configuration = configuration;
        _logger = logger;
        _environment = environment;
    }

    [HttpPost]
    [AllowAnonymous]
    public async Task<IActionResult> Post([FromBody] RevenueCatWebhookEnvelope? envelope, CancellationToken cancellationToken)
    {
        var expectedAuth = _configuration["RevenueCat:WebhookAuthorization"];

        // Require a shared secret outside Development. Anonymous webhooks would let any caller
        // mutate subscription state for known/guessed app user IDs.
        if (string.IsNullOrEmpty(expectedAuth))
        {
            if (!_environment.IsDevelopment())
            {
                _logger.LogError("RevenueCat webhook rejected: RevenueCat:WebhookAuthorization is not configured in {Env}", _environment.EnvironmentName);
                return Unauthorized();
            }

            _logger.LogWarning("RevenueCat webhook: no Authorization secret configured (allowed in Development only)");
        }
        else
        {
            var sent = Request.Headers.Authorization.ToString();
            if (string.IsNullOrEmpty(sent) || sent != expectedAuth)
            {
                _logger.LogWarning("RevenueCat webhook rejected: invalid Authorization header");
                return Unauthorized();
            }
        }

        var ev = envelope?.Event;
        if (ev == null)
        {
            _logger.LogWarning("RevenueCat webhook: missing event");
            return BadRequest();
        }

        if (string.Equals(ev.Type, "TRANSFER", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogInformation("RevenueCat webhook: TRANSFER event ignored (id {EventId})", ev.Id);
            return Ok();
        }

        if (string.Equals(ev.Type, "TEST", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogInformation("RevenueCat webhook: TEST event received");
        }

        var ids = new List<string>();
        if (!string.IsNullOrWhiteSpace(ev.AppUserId))
            ids.Add(ev.AppUserId.Trim());
        if (!string.IsNullOrWhiteSpace(ev.OriginalAppUserId))
            ids.Add(ev.OriginalAppUserId.Trim());
        if (ev.Aliases != null)
        {
            foreach (var a in ev.Aliases)
            {
                if (!string.IsNullOrWhiteSpace(a))
                    ids.Add(a.Trim());
            }
        }

        var distinct = ids.Distinct(StringComparer.OrdinalIgnoreCase).ToList();
        if (distinct.Count == 0)
        {
            _logger.LogWarning("RevenueCat webhook: no app user id (event {EventId}, type {Type})", ev.Id, ev.Type);
            return Ok();
        }

        foreach (var id in distinct)
        {
            try
            {
                await _syncService.SyncPlanForAppUserAsync(id, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "RevenueCat webhook: sync failed for {AppUserId}", id);
                return StatusCode(500);
            }
        }

        return Ok();
    }
}
