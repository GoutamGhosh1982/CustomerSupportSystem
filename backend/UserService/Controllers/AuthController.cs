using Microsoft.AspNetCore.Mvc;
using UserService.DTOs;
using UserService.Models;
using UserService.Services;

namespace UserService.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IUserRepository _repo;
    private readonly IAuthService    _authService;

    public AuthController(IUserRepository repo, IAuthService authService)
    {
        _repo        = repo;
        _authService = authService;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        var existing = await _repo.GetByEmailAsync(request.Email);
        if (existing is not null)
            return Conflict(new { message = "Email already registered." });

        var allowed = new[] { "Customer", "Agent", "Supervisor", "Admin" };
        var role    = allowed.Contains(request.Role) ? request.Role : "Customer";

        var user = new User
        {
            FullName     = request.FullName,
            Email        = request.Email,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role         = role
        };

        await _repo.CreateAsync(user);

        var token = _authService.GenerateToken(user);
        return Ok(new AuthResponse(token, user.Id.ToString(), user.FullName, user.Email, user.Role));
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        var user = await _repo.GetByEmailAsync(request.Email);
        if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            return Unauthorized(new { message = "Invalid credentials." });

        if (!user.IsActive)
            return Forbid();

        var token = _authService.GenerateToken(user);
        return Ok(new AuthResponse(token, user.Id.ToString(), user.FullName, user.Email, user.Role));
    }
}
