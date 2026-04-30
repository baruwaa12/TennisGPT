namespace TennisGPT.Domain.Entities;

/// <summary>
/// Records that a user has claimed a founder-priced subscription slot (server-authoritative count).
/// </summary>
public class FounderClaim
{
    public Guid UserId { get; set; }
    public DateTime ClaimedAtUtc { get; set; }
}
