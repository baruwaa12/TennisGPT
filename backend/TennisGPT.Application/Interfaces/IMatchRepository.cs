using TennisGPT.Domain.Entities;

namespace TennisGPT.Application.Interfaces;

public interface IMatchRepository
{
    Task<Match?> GetByIdAsync(Guid id);
    Task<IEnumerable<Match>> GetAllByUserIdAsync(Guid userId);
    Task<IEnumerable<Match>> GetRecentByUserIdAsync(Guid userId, int count);
    Task<Match> CreateAsync(Match match);
    Task<Match> UpdateAsync(Match match);
    Task DeleteAsync(Guid id);
}
