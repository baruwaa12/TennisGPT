using TennisGPT.Domain.Entities;

namespace TennisGPT.Application.Interfaces;

public interface ICheckInRepository
{
    Task<CheckIn?> GetByIdAsync(Guid id);
    Task<IEnumerable<CheckIn>> GetAllByUserIdAsync(Guid userId);
    Task<CheckIn?> GetLastByUserIdAsync(Guid userId);
    Task<CheckIn> CreateAsync(CheckIn checkIn);
    Task DeleteAsync(Guid id);
}
