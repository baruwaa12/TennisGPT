using Microsoft.EntityFrameworkCore;
using TennisGPT.Application.Interfaces;
using TennisGPT.Domain.Entities;
using TennisGPT.Infrastructure.Data;

namespace TennisGPT.Infrastructure.Repositories;

public class UserRepository : IUserRepository
{
    private readonly TennisGPTDbContext _context;

    public UserRepository(TennisGPTDbContext context)
    {
        _context = context;
    }

    public async Task<User?> GetByIdAsync(Guid id)
    {
        return await _context.Users.FindAsync(id);
    }

    public async Task<User?> GetByGoogleIdAsync(string googleId)
    {
        return await _context.Users.FirstOrDefaultAsync(u => u.GoogleId == googleId);
    }
    
    public async Task<User?> GetByAppleIdAsync(string appleId)
    {
        return await _context.Users.FirstOrDefaultAsync(u => u.AppleId == appleId);
    }

    public async Task<User?> GetByEmailAsync(string email)
    {
        return await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
    }

    public async Task<User?> GetByRefreshTokenAsync(string refreshToken)
    {
        return await _context.Users.FirstOrDefaultAsync(u => u.RefreshToken == refreshToken);
    }

    public async Task<User> CreateAsync(User user)
    {
        user.Id = Guid.NewGuid();
        user.CreatedAt = DateTime.UtcNow;
        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        return user;
    }

    public async Task<User> UpdateAsync(User user)
    {
        _context.Users.Update(user);
        await _context.SaveChangesAsync();
        return user;
    }

    public async Task DeleteAsync(Guid id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user != null)
        {
            _context.Users.Remove(user);
            await _context.SaveChangesAsync();
        }
    }
    
    public async Task<(List<User> Users, int TotalCount)> GetAllPaginatedAsync(int limit = 20, Guid? cursor = null)
    {
        var query = _context.Users.AsNoTracking().OrderByDescending(u => u.CreatedAt);
        
        if (cursor.HasValue)
        {
            var cursorUser = await _context.Users.FindAsync(cursor.Value);
            if (cursorUser != null)
            {
                query = (IOrderedQueryable<User>)query.Where(u => u.CreatedAt < cursorUser.CreatedAt);
            }
        }
        
        var totalCount = await _context.Users.CountAsync();
        var users = await query.Take(limit).ToListAsync();
        
        return (users, totalCount);
    }
    
    public async Task<int> GetTotalUserCountAsync()
    {
        return await _context.Users.CountAsync();
    }
}
