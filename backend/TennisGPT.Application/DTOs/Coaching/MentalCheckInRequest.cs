namespace TennisGPT.Application.DTOs.Coaching;

public class MentalCheckInRequest
{
    public int Mood { get; set; }
    public required string JournalEntry { get; set; }
}
