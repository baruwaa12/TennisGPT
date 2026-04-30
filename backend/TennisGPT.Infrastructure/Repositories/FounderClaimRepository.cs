using Microsoft.EntityFrameworkCore;
using TennisGPT.Application.Interfaces;
using TennisGPT.Application.Options;
using TennisGPT.Domain.Entities;
using TennisGPT.Infrastructure.Data;

namespace TennisGPT.Infrastructure.Repositories;

public class FounderClaimRepository : IFounderClaimRepository
{
    private readonly TennisGPTDbContext _context;

    public FounderClaimRepository(TennisGPTDbContext context)
    {
        _context = context;
    }

    public Task<int> GetClaimCountAsync(CancellationToken cancellationToken = default) =>
        _context.FounderClaims.AsNoTracking().CountAsync(cancellationToken);

    public async Task EnsureClaimForFounderSubscriberAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var strategy = _context.Database.CreateExecutionStrategy();
        await strategy.ExecuteAsync(async () =>
        {
            await using var tx =
                await _context.Database.BeginTransactionAsync(cancellationToken);
            if (await _context.FounderClaims.AnyAsync(
                c => c.UserId == userId, cancellationToken))
            {
                await tx.CommitAsync(cancellationToken);
                return;
            }

            var total = await _context.FounderClaims.CountAsync(cancellationToken);
            if (total >= FounderSubscriptionOptions.MaxFounderSpots)
            {
                await tx.CommitAsync(cancellationToken);
                return;
            }

            _context.FounderClaims.Add(new FounderClaim
            {
                UserId = userId,
                ClaimedAtUtc = DateTime.UtcNow,
            });

            await _context.SaveChangesAsync(cancellationToken);
            await tx.CommitAsync(cancellationToken);
        });
    }
}
