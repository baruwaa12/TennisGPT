namespace TennisGPT.Application.DTOs.SavedEntries;

public class SavedEntryDto
{
    public Guid Id { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; }
}
