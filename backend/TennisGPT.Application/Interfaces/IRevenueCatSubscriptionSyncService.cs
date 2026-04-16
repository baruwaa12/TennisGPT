namespace TennisGPT.Application.Interfaces;

/// <summary>
/// Syncs subscription state from RevenueCat REST API into <see cref="Domain.Entities.User.Plan"/>.
/// </summary>
public interface IRevenueCatSubscriptionSyncService
{
    /// <summary>
    /// Fetches subscriber entitlements from RevenueCat and updates the matching user by app user id (email).
    /// </summary>
    /// <returns>true if a user row was found and updated.</returns>
    Task<bool> SyncPlanForAppUserAsync(string appUserId, CancellationToken cancellationToken = default);
}
