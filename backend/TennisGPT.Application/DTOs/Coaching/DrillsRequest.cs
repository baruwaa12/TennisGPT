using System.Text.Json;

namespace TennisGPT.Application.DTOs.Coaching;

public class DrillsRequest
{
    public required List<JsonElement> Matches { get; set; }
}
