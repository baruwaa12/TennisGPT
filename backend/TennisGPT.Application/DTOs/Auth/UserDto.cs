namespace TennisGPT.Application.DTOs.Auth;

public class UserDto
{
    public Guid Id { get; set; }
    public required string Email { get; set; }
    public string? DisplayName { get; set; }
    public string? PhotoUrl { get; set; }
}
