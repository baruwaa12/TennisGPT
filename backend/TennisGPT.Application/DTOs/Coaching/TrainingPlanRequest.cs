namespace TennisGPT.Application.DTOs.Coaching;

public class TrainingPlanRequest
{
    public required string PlayerLevel { get; set; }
    public required string Goals { get; set; }
}
