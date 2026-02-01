using TennisGPT.Domain.Entities;

namespace TennisGPT.Application.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid id);
    Task<User?> GetByGoogleIdAsync(string googleId);
    Task<User?> GetByAppleIdAsync(string appleId);
    Task<User?> GetByEmailAsync(string email);
    Task<User?> GetByRefreshTokenAsync(string refreshToken);
    Task<User> CreateAsync(User user);
    Task<User> UpdateAsync(User user);
    Task DeleteAsync(Guid id);
    
    // Admin: Paginated user listing
    Task<(List<User> Users, int TotalCount)> GetAllPaginatedAsync(int limit = 20, Guid? cursor = null);
    Task<int> GetTotalUserCountAsync();
}
