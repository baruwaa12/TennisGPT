using Microsoft.AspNetCore.Mvc;
using TennisGPT.Application.Interfaces;

namespace TennisGPT.Api.Controllers;

/// <summary>
/// Admin endpoints for user management and debugging.
/// Protected by admin key or development environment only.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class AdminController : ControllerBase
{
    private readonly IUserRepository _userRepository;
    private readonly IConfiguration _configuration;
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<AdminController> _logger;

    public AdminController(
        IUserRepository userRepository,
        IConfiguration configuration,
        IWebHostEnvironment environment,
        ILogger<AdminController> logger)
    {
        _userRepository = userRepository;
        _configuration = configuration;
        _environment = environment;
        _logger = logger;
    }

    /// <summary>
    /// List all users (paginated). 
    /// Access: Development environment OR valid admin key.
    /// </summary>
    [HttpGet("users")]
    public async Task<ActionResult<AdminUsersResponse>> GetUsers(
        [FromQuery] int limit = 20,
        [FromQuery] Guid? cursor = null)
    {
        if (!IsAuthorized())
        {
            _logger.LogWarning("Unauthorized admin access attempt from {IP}", 
                HttpContext.Connection.RemoteIpAddress);
            return Unauthorized(new { message = "Admin access required" });
        }

        try
        {
            var (users, totalCount) = await _userRepository.GetAllPaginatedAsync(limit, cursor);
            
            var response = new AdminUsersResponse
            {
                Users = users.Select(u => new AdminUserDto
                {
                    Id = u.Id,
                    GoogleSub = u.GoogleId,
                    Email = u.Email,
                    Name = u.DisplayName,
                    AvatarUrl = u.PhotoUrl,
                    CreatedAt = u.CreatedAt,
                    LastLoginAt = u.LastLoginAt,
                    Plan = u.Plan.ToString().ToLower(),
                    OnboardingCompleted = u.OnboardingCompleted,
                    TacticalUsedPeriod = u.TacticalUsedPeriod,
                    TacticalPeriodStart = u.TacticalPeriodStart
                }).ToList(),
                TotalCount = totalCount,
                NextCursor = users.Count > 0 ? users.Last().Id : null,
                HasMore = users.Count == limit
            };

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching users for admin");
            return StatusCode(500, new { message = "Failed to fetch users", requestId = Guid.NewGuid().ToString("N")[..8] });
        }
    }

    /// <summary>
    /// Get stats summary for admin dashboard
    /// </summary>
    [HttpGet("stats")]
    public async Task<ActionResult<AdminStatsResponse>> GetStats()
    {
        if (!IsAuthorized())
        {
            return Unauthorized(new { message = "Admin access required" });
        }

        try
        {
            var totalUsers = await _userRepository.GetTotalUserCountAsync();
            
            return Ok(new AdminStatsResponse
            {
                TotalUsers = totalUsers,
                Environment = _environment.EnvironmentName
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching admin stats");
            return StatusCode(500, new { message = "Failed to fetch stats" });
        }
    }

    private bool IsAuthorized()
    {
        // Allow in development environment
        if (_environment.IsDevelopment())
        {
            return true;
        }

        // Check for admin key in header
        var adminKey = _configuration["Admin:Key"];
        if (string.IsNullOrEmpty(adminKey))
        {
            return false; // No admin key configured = no access in production
        }

        var providedKey = Request.Headers["X-Admin-Key"].FirstOrDefault();
        return !string.IsNullOrEmpty(providedKey) && providedKey == adminKey;
    }
}

// DTOs for admin endpoints
public class AdminUsersResponse
{
    public List<AdminUserDto> Users { get; set; } = [];
    public int TotalCount { get; set; }
    public Guid? NextCursor { get; set; }
    public bool HasMore { get; set; }
}

public class AdminUserDto
{
    public Guid Id { get; set; }
    public string GoogleSub { get; set; } = "";
    public string Email { get; set; } = "";
    public string? Name { get; set; }
    public string? AvatarUrl { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }
    public string Plan { get; set; } = "free";
    public bool OnboardingCompleted { get; set; }
    public int TacticalUsedPeriod { get; set; }
    public DateTime? TacticalPeriodStart { get; set; }
}

public class AdminStatsResponse
{
    public int TotalUsers { get; set; }
    public string Environment { get; set; } = "";
}

