using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using TennisGPT.Application.Interfaces;
using TennisGPT.Domain.Entities;

namespace TennisGPT.Infrastructure.External;

public class RevenueCatSubscriptionSyncService : IRevenueCatSubscriptionSyncService
{
    public const string PremiumEntitlementId = "premium";

    private readonly IUserRepository _userRepository;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<RevenueCatSubscriptionSyncService> _logger;

    public RevenueCatSubscriptionSyncService(
        IUserRepository userRepository,
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        ILogger<RevenueCatSubscriptionSyncService> logger)
    {
        _userRepository = userRepository;
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _logger = logger;
    }

    public async Task<bool> SyncPlanForAppUserAsync(string appUserId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(appUserId))
            return false;

        var secret = _configuration["RevenueCat:SecretApiKey"];
        if (string.IsNullOrWhiteSpace(secret))
        {
            _logger.LogWarning("RevenueCat SecretApiKey is not configured; skipping subscription sync");
            return false;
        }

        var user = await _userRepository.GetByEmailCaseInsensitiveAsync(appUserId.Trim());
        if (user == null)
        {
            _logger.LogInformation("No user found for RevenueCat app_user_id {AppUserId}", appUserId);
            return false;
        }

        var isPremium = await FetchPremiumActiveAsync(appUserId.Trim(), secret, cancellationToken);

        var newPlan = isPremium ? UserPlan.Premium : UserPlan.Free;
        if (user.Plan == newPlan)
        {
            _logger.LogInformation(
                "User {Email} already has plan {Plan} (RevenueCat sync)",
                user.Email,
                newPlan);
            return true;
        }

        user.Plan = newPlan;
        await _userRepository.UpdateAsync(user);

        _logger.LogInformation(
            "Updated user {Email} plan to {Plan} from RevenueCat",
            user.Email,
            newPlan);

        return true;
    }

    private async Task<bool> FetchPremiumActiveAsync(string appUserId, string secret, CancellationToken cancellationToken)
    {
        var client = _httpClientFactory.CreateClient("RevenueCat");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", secret);

        var encoded = Uri.EscapeDataString(appUserId);
        using var response = await client.GetAsync($"v1/subscribers/{encoded}", cancellationToken);

        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            _logger.LogInformation("RevenueCat subscriber not found for {AppUserId}", appUserId);
            return false;
        }

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogWarning(
                "RevenueCat GET subscribers failed: {Status} {Body}",
                response.StatusCode,
                body);
            return false;
        }

        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);

        if (!doc.RootElement.TryGetProperty("subscriber", out var subscriber))
            return false;

        if (!subscriber.TryGetProperty("entitlements", out var entitlements))
            return false;

        if (!entitlements.TryGetProperty(PremiumEntitlementId, out var premium))
            return false;

        return IsPremiumEntitlementActive(premium);
    }

    private static bool IsPremiumEntitlementActive(JsonElement premium)
    {
        if (!premium.TryGetProperty("expires_date", out var expEl))
            return true;

        var expStr = expEl.GetString();
        if (string.IsNullOrEmpty(expStr))
            return true;

        if (!DateTime.TryParse(expStr, null, System.Globalization.DateTimeStyles.RoundtripKind, out var expUtc))
            return true;

        return expUtc > DateTime.UtcNow;
    }
}
