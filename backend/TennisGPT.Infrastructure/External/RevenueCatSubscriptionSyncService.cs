using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using TennisGPT.Application.Interfaces;
using TennisGPT.Application.Options;
using TennisGPT.Domain.Entities;

namespace TennisGPT.Infrastructure.External;

public class RevenueCatSubscriptionSyncService : IRevenueCatSubscriptionSyncService
{
    public const string PremiumEntitlementId = "premium";

    private readonly IUserRepository _userRepository;
    private readonly IFounderClaimRepository _founderClaimRepository;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly ILogger<RevenueCatSubscriptionSyncService> _logger;

    public RevenueCatSubscriptionSyncService(
        IUserRepository userRepository,
        IFounderClaimRepository founderClaimRepository,
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        ILogger<RevenueCatSubscriptionSyncService> logger)
    {
        _userRepository = userRepository;
        _founderClaimRepository = founderClaimRepository;
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

        using var doc = await FetchSubscriberDocumentAsync(appUserId.Trim(), secret, cancellationToken);
        if (doc == null)
            return false;

        if (!doc.RootElement.TryGetProperty("subscriber", out var subscriber))
            return false;

        var isPremium = IsPremiumEntitlementActive(subscriber);
        var hasFounderMonthly = HasActiveSubscriptionProduct(
            subscriber,
            FounderSubscriptionOptions.FounderMonthlyProductId);

        var newPlan = isPremium ? UserPlan.Premium : UserPlan.Free;
        if (user.Plan != newPlan)
        {
            user.Plan = newPlan;
            await _userRepository.UpdateAsync(user);
            _logger.LogInformation(
                "Updated user {Email} plan to {Plan} from RevenueCat",
                user.Email,
                newPlan);
        }
        else
        {
            _logger.LogInformation(
                "User {Email} already has plan {Plan} (RevenueCat sync)",
                user.Email,
                newPlan);
        }

        if (hasFounderMonthly && isPremium)
            await _founderClaimRepository.EnsureClaimForFounderSubscriberAsync(user.Id, cancellationToken);

        return true;
    }

    private async Task<JsonDocument?> FetchSubscriberDocumentAsync(
        string appUserId,
        string secret,
        CancellationToken cancellationToken)
    {
        var client = _httpClientFactory.CreateClient("RevenueCat");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", secret);

        var encoded = Uri.EscapeDataString(appUserId);
        using var response = await client.GetAsync($"v1/subscribers/{encoded}", cancellationToken);

        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            _logger.LogInformation("RevenueCat subscriber not found for {AppUserId}", appUserId);
            return null;
        }

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogWarning(
                "RevenueCat GET subscribers failed: {Status} {Body}",
                response.StatusCode,
                body);
            return null;
        }

        var json = await response.Content.ReadAsStringAsync(cancellationToken);
        return JsonDocument.Parse(json);
    }

    private static bool IsPremiumEntitlementActive(JsonElement subscriber)
    {
        if (!subscriber.TryGetProperty("entitlements", out var entitlements))
            return false;

        if (!entitlements.TryGetProperty(PremiumEntitlementId, out var premium))
            return false;

        if (!premium.TryGetProperty("expires_date", out var expEl))
            return true;

        var expStr = expEl.GetString();
        if (string.IsNullOrEmpty(expStr))
            return true;

        if (!DateTime.TryParse(expStr, null, System.Globalization.DateTimeStyles.RoundtripKind, out var expUtc))
            return true;

        return expUtc > DateTime.UtcNow;
    }

    /// <summary>
    /// RevenueCat nests subscriptions under subscriber.subscriptions keyed by store product id.
    /// </summary>
    private static bool HasActiveSubscriptionProduct(JsonElement subscriber, string productId)
    {
        if (!subscriber.TryGetProperty("subscriptions", out var subscriptions))
            return false;

        if (!subscriptions.TryGetProperty(productId, out var sub))
            return false;

        if (!sub.TryGetProperty("expires_date", out var expEl))
            return true;

        var expStr = expEl.GetString();
        if (string.IsNullOrEmpty(expStr))
            return true;

        if (!DateTime.TryParse(expStr, null, System.Globalization.DateTimeStyles.RoundtripKind, out var expUtc))
            return true;

        return expUtc > DateTime.UtcNow;
    }
}
