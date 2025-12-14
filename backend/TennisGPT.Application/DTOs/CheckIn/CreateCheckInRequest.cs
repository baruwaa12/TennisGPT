namespace TennisGPT.Application.DTOs.CheckIn;

public class CreateCheckInRequest
{
    public long Timestamp { get; set; }
    public int Rating { get; set; }
    public required string JournalText { get; set; }
    public string? CoachResponse { get; set; }
}
