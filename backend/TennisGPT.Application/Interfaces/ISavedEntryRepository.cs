using TennisGPT.Domain.Entities;

namespace TennisGPT.Application.Interfaces;

public interface ISavedEntryRepository
{
    /// <summary>
    /// Save an entry and auto-trim to 3 per category per user (atomic).
    /// Returns the newly created entry.
    /// </summary>
    Task<SavedEntry> SaveAndTrimAsync(Guid userId, SavedEntryCategory category, string content);

    /// <summary>
    /// Get saved entries for a user + category, newest first, max 3.
    /// </summary>
    Task<IEnumerable<SavedEntry>> GetByUserAndCategoryAsync(Guid userId, SavedEntryCategory category);
}
