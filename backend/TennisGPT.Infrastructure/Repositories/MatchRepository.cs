using Microsoft.EntityFrameworkCore;
using TennisGPT.Application.Interfaces;
using TennisGPT.Domain.Entities;
using TennisGPT.Infrastructure.Data;

namespace TennisGPT.Infrastructure.Repositories;

public class MatchRepository : IMatchRepository
{
    private readonly TennisGPTDbContext _context;

    public MatchRepository(TennisGPTDbContext context)
    {
        _context = context;
    }

    public async Task<Match?> GetByIdAsync(Guid id)
    {
        return await _context.Matches.FindAsync(id);
    }

    public async Task<IEnumerable<Match>> GetAllByUserIdAsync(Guid userId)
    {
        return await _context.Matches
            .Where(m => m.UserId == userId)
            .OrderByDescending(m => m.CreatedAt)
            .ToListAsync();
    }

    public async Task<IEnumerable<Match>> GetRecentByUserIdAsync(Guid userId, int count)
    {
        return await _context.Matches
            .Where(m => m.UserId == userId)
            .OrderByDescending(m => m.CreatedAt)
            .Take(count)
            .ToListAsync();
    }

    public async Task<Match> CreateAsync(Match match)
    {
        match.Id = Guid.NewGuid();
        match.CreatedAt = DateTime.UtcNow;
        _context.Matches.Add(match);
        await _context.SaveChangesAsync();
        return match;
    }

    public async Task<Match> UpdateAsync(Match match)
    {
        match.UpdatedAt = DateTime.UtcNow;
        _context.Matches.Update(match);
        await _context.SaveChangesAsync();
        return match;
    }

    public async Task DeleteAsync(Guid id)
    {
        var match = await _context.Matches.FindAsync(id);
        if (match != null)
        {
            _context.Matches.Remove(match);
            await _context.SaveChangesAsync();
        }
    }
}
