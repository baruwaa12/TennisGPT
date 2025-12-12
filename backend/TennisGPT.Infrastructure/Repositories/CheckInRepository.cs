using Microsoft.EntityFrameworkCore;
using TennisGPT.Application.Interfaces;
using TennisGPT.Domain.Entities;
using TennisGPT.Infrastructure.Data;

namespace TennisGPT.Infrastructure.Repositories;

public class CheckInRepository : ICheckInRepository
{
    private readonly TennisGPTDbContext _context;

    public CheckInRepository(TennisGPTDbContext context)
    {
        _context = context;
    }

    public async Task<CheckIn?> GetByIdAsync(Guid id)
    {
        return await _context.CheckIns.FindAsync(id);
    }

    public async Task<IEnumerable<CheckIn>> GetAllByUserIdAsync(Guid userId)
    {
        return await _context.CheckIns
            .Where(c => c.UserId == userId)
            .OrderByDescending(c => c.Timestamp)
            .ToListAsync();
    }

    public async Task<CheckIn?> GetLastByUserIdAsync(Guid userId)
    {
        return await _context.CheckIns
            .Where(c => c.UserId == userId)
            .OrderByDescending(c => c.Timestamp)
            .FirstOrDefaultAsync();
    }

    public async Task<CheckIn> CreateAsync(CheckIn checkIn)
    {
        checkIn.Id = Guid.NewGuid();
        checkIn.CreatedAt = DateTime.UtcNow;
        _context.CheckIns.Add(checkIn);
        await _context.SaveChangesAsync();
        return checkIn;
    }

    public async Task DeleteAsync(Guid id)
    {
        var checkIn = await _context.CheckIns.FindAsync(id);
        if (checkIn != null)
        {
            _context.CheckIns.Remove(checkIn);
            await _context.SaveChangesAsync();
        }
    }
}
