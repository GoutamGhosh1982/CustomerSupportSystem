using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UserService.DTOs;
using UserService.Services;

namespace UserService.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly IUserRepository _repo;
    public UsersController(IUserRepository repo) => _repo = repo;

    [HttpGet]
    [Authorize(Policy = "AgentOrAbove")]
    public async Task<IActionResult> GetAll()
    {
        var users = await _repo.GetAllAsync();
        var dtos  = users.Select(u => new UserDto(u.Id, u.FullName, u.Email, u.Role, u.IsActive, u.CreatedAt));
        return Ok(dtos);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var user = await _repo.GetByIdAsync(id);
        if (user is null) return NotFound();
        return Ok(new UserDto(user.Id, user.FullName, user.Email, user.Role, user.IsActive, user.CreatedAt));
    }

    [HttpPatch("{id:guid}/role")]
    [Authorize(Policy = "SupervisorOrAbove")]
    public async Task<IActionResult> UpdateRole(Guid id, [FromBody] UpdateRoleRequest request)
    {
        var user = await _repo.GetByIdAsync(id);
        if (user is null) return NotFound();

        var allowed = new[] { "Customer", "Agent", "Supervisor", "Admin" };
        if (!allowed.Contains(request.Role)) return BadRequest(new { message = "Invalid role." });

        user.Role = request.Role;
        await _repo.UpdateAsync(user);
        return Ok(new UserDto(user.Id, user.FullName, user.Email, user.Role, user.IsActive, user.CreatedAt));
    }

    [HttpPatch("{id:guid}/deactivate")]
    [Authorize(Policy = "SupervisorOrAbove")]
    public async Task<IActionResult> Deactivate(Guid id)
    {
        var user = await _repo.GetByIdAsync(id);
        if (user is null) return NotFound();
        user.IsActive = false;
        await _repo.UpdateAsync(user);
        return NoContent();
    }
}
