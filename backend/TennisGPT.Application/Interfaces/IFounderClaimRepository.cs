namespace TennisGPT.Application.Interfaces;

public interface IFounderClaimRepository
{
    Task<int> GetClaimCountAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Ensures this user has a founder claim row if they have an active founder product
    /// and total claims are under the cap. Idempotent per user.
    /// </summary>
    Task EnsureClaimForFounderSubscriberAsync(Guid userId, CancellationToken cancellationToken = default);
}
