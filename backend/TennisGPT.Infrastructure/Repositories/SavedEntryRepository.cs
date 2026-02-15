using Microsoft.EntityFrameworkCore;
using TennisGPT.Application.Interfaces;
using TennisGPT.Domain.Entities;
using TennisGPT.Infrastructure.Data;

namespace TennisGPT.Infrastructure.Repositories;

public class SavedEntryRepository : ISavedEntryRepository
{
    private readonly TennisGPTDbContext _context;
    private const int MaxEntriesPerCategory = 3;

    public SavedEntryRepository(TennisGPTDbContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Save a new entry and trim to 3 per category per user.
    /// Runs inside a transaction to guarantee atomicity.
    /// </summary>
    public async Task<SavedEntry> SaveAndTrimAsync(Guid userId, SavedEntryCategory category, string content)
    {
        await using var transaction = await _context.Database.BeginTransactionAsync();

        try
        {
            // 1) Insert new entry
            var entry = new SavedEntry
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Category = category,
                Content = content,
                CreatedAtUtc = DateTime.UtcNow
            };
            _context.SavedEntries.Add(entry);
            await _context.SaveChangesAsync();

            // 2) Get all entries for this user+category, ordered newest first
            var allEntries = await _context.SavedEntries
                .Where(e => e.UserId == userId && e.Category == category)
                .OrderByDescending(e => e.CreatedAtUtc)
                .ToListAsync();

            // 3) If more than 3, delete the oldest (everything beyond index 2)
            if (allEntries.Count > MaxEntriesPerCategory)
            {
                var toDelete = allEntries.Skip(MaxEntriesPerCategory).ToList();
                _context.SavedEntries.RemoveRange(toDelete);
                await _context.SaveChangesAsync();
            }

            await transaction.CommitAsync();
            return entry;
        }
        catch
        {
            await transaction.RollbackAsync();
            throw;
        }
    }

    /// <summary>
    /// Get saved entries for a user + category. Max 3, newest first.
    /// </summary>
    public async Task<IEnumerable<SavedEntry>> GetByUserAndCategoryAsync(Guid userId, SavedEntryCategory category)
    {
        return await _context.SavedEntries
            .Where(e => e.UserId == userId && e.Category == category)
            .OrderByDescending(e => e.CreatedAtUtc)
            .Take(MaxEntriesPerCategory)
            .AsNoTracking()
            .ToListAsync();
    }
}
