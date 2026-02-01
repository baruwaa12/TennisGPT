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
                    TacticalPeriodStart = u.TacticalPeriodStart,
                    IsComped = u.IsComped
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
    
    /// <summary>
    /// Set a user as comped (lifetime free access).
    /// Use for special users like Nicholas.
    /// </summary>
    [HttpPost("users/{userId}/comp")]
    public async Task<ActionResult> CompUser(Guid userId, [FromBody] CompUserRequest request)
    {
        if (!IsAuthorized())
        {
            return Unauthorized(new { message = "Admin access required" });
        }

        try
        {
            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null)
            {
                return NotFound(new { message = "User not found" });
            }

            user.IsComped = request.IsComped;
            await _userRepository.UpdateAsync(user);
            
            _logger.LogInformation("User {UserId} ({Email}) comped status set to {IsComped}", 
                userId, user.Email, request.IsComped);

            return Ok(new { 
                message = request.IsComped 
                    ? "User now has lifetime free access" 
                    : "User comped status removed",
                userId = user.Id,
                email = user.Email,
                isComped = user.IsComped
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting comp status for user {UserId}", userId);
            return StatusCode(500, new { message = "Failed to update user" });
        }
    }
    
    /// <summary>
    /// Comp a user by email address.
    /// </summary>
    [HttpPost("users/comp-by-email")]
    public async Task<ActionResult> CompUserByEmail([FromBody] CompUserByEmailRequest request)
    {
        if (!IsAuthorized())
        {
            return Unauthorized(new { message = "Admin access required" });
        }

        try
        {
            var user = await _userRepository.GetByEmailAsync(request.Email);
            if (user == null)
            {
                return NotFound(new { message = $"User with email '{request.Email}' not found" });
            }

            user.IsComped = request.IsComped;
            await _userRepository.UpdateAsync(user);
            
            _logger.LogInformation("User {UserId} ({Email}) comped status set to {IsComped}", 
                user.Id, user.Email, request.IsComped);

            return Ok(new { 
                message = request.IsComped 
                    ? "User now has lifetime free access" 
                    : "User comped status removed",
                userId = user.Id,
                email = user.Email,
                isComped = user.IsComped
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting comp status for user {Email}", request.Email);
            return StatusCode(500, new { message = "Failed to update user" });
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
    public bool IsComped { get; set; }
}

public class AdminStatsResponse
{
    public int TotalUsers { get; set; }
    public string Environment { get; set; } = "";
}

public class CompUserRequest
{
    public bool IsComped { get; set; } = true;
}

public class CompUserByEmailRequest
{
    public required string Email { get; set; }
    public bool IsComped { get; set; } = true;
}


