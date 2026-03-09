using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TennisGPT.Application.DTOs.Auth;
using TennisGPT.Application.Interfaces;

namespace TennisGPT.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("google")]
    public async Task<ActionResult<AuthResponse>> AuthenticateWithGoogle([FromBody] GoogleTokenRequest request)
    {
        try
        {
            // Validate that at least one token is provided
            if (string.IsNullOrEmpty(request.IdToken) && string.IsNullOrEmpty(request.AccessToken))
            {
                return BadRequest(new { message = "Either idToken or accessToken must be provided" });
            }

            var result = await _authService.AuthenticateWithGoogleAsync(request.IdToken, request.AccessToken);
            return Ok(result);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
    }

    [HttpPost("apple")]
    public async Task<ActionResult<AuthResponse>> AuthenticateWithApple([FromBody] AppleTokenRequest request)
    {
        try
        {
            if (string.IsNullOrEmpty(request.IdentityToken))
            {
                return BadRequest(new { message = "identityToken is required" });
            }

            var result = await _authService.AuthenticateWithAppleAsync(
                request.IdentityToken,
                request.Email,
                request.DisplayName);
            return Ok(result);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
    }

    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResponse>> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        try
        {
            var result = await _authService.RefreshTokenAsync(request.RefreshToken);
            return Ok(result);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
    }

    [Authorize]
    [HttpPost("logout")]
    public async Task<ActionResult> Logout()
    {
        var userId = GetUserId();
        if (userId == null)
            return Unauthorized();

        await _authService.RevokeRefreshTokenAsync(userId.Value);
        return NoContent();
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<ActionResult<UserDto>> GetCurrentUser()
    {
        var userId = GetUserId();
        if (userId == null)
            return Unauthorized();

        var user = await _authService.GetCurrentUserAsync(userId.Value);
        if (user == null)
            return NotFound();

        return Ok(user);
    }

    [Authorize]
    [HttpDelete("account")]
    public async Task<ActionResult> DeleteAccount()
    {
        var userId = GetUserId();
        if (userId == null)
            return Unauthorized();

        var deleted = await _authService.DeleteAccountAsync(userId.Value);
        if (!deleted)
            return NotFound();

        return NoContent();
    }

    [Authorize]
    [HttpPost("onboarding-complete")]
    public async Task<ActionResult> MarkOnboardingComplete()
    {
        var userId = GetUserId();
        if (userId == null)
            return Unauthorized();

        await _authService.MarkOnboardingCompleteAsync(userId.Value);
        return Ok(new { success = true });
    }

    private Guid? GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? User.FindFirst("sub")?.Value;

        if (string.IsNullOrEmpty(userIdClaim))
            return null;

        return Guid.TryParse(userIdClaim, out var userId) ? userId : null;
    }
}
