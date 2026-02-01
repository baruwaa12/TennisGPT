namespace TennisGPT.Application.Interfaces;

public interface IAppleAuthClient
{
    Task<AppleUserInfo?> ValidateIdentityTokenAsync(string identityToken);
}

public class AppleUserInfo
{
    public required string AppleId { get; set; }
    public string? Email { get; set; }
    public bool EmailVerified { get; set; }
}

