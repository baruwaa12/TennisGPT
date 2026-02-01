namespace TennisGPT.Application.DTOs.Auth;

public class UserDto
{
    public Guid Id { get; set; }
    public required string Email { get; set; }
    public string? DisplayName { get; set; }
    public string? PhotoUrl { get; set; }
    public string Plan { get; set; } = "free";
    public bool OnboardingCompleted { get; set; } = false;
    public int TacticalUsedThisPeriod { get; set; } = 0;
    public int TacticalRemaining { get; set; } = 4;
    
    /// <summary>
    /// Lifetime free access - bypasses all paywalls and limits.
    /// </summary>
    public bool IsComped { get; set; } = false;
}
