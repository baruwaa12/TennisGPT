namespace TennisGPT.Application.DTOs.CheckIn;

public class CheckInDto
{
    public Guid Id { get; set; }
    public long Timestamp { get; set; }
    public int Rating { get; set; }
    public required string JournalText { get; set; }
    public string? CoachResponse { get; set; }
    public DateTime CreatedAt { get; set; }
}
