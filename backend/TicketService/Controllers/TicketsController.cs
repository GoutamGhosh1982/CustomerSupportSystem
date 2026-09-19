using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TicketService.DTOs;
using TicketService.Services;

namespace TicketService.Controllers;

[ApiController]
[Route("api/tickets")]
[Authorize]
public class TicketsController : ControllerBase
{
    private readonly ITicketService _svc;
    public TicketsController(ITicketService svc) => _svc = svc;

    private Guid   CurrentUserId   => Guid.Parse(User.FindFirstValue("userId")!);
    private string CurrentUserName => User.FindFirstValue("fullName") ?? string.Empty;
    private string CurrentEmail    => User.FindFirstValue(ClaimTypes.Email) ?? string.Empty;

    [HttpPost]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> Create([FromBody] CreateTicketRequest req)
    {
        var dto = await _svc.CreateAsync(req, CurrentUserId, CurrentUserName, CurrentEmail);
        return CreatedAtAction(nameof(GetById), new { id = dto.Id }, dto);
    }

    [HttpGet]
    [Authorize(Policy = "AgentOrAbove")]
    public async Task<IActionResult> GetAll(
        [FromQuery] string? status,
        [FromQuery] string? priority,
        [FromQuery] string? category,
        [FromQuery] Guid?   agentId,
        [FromQuery] int     page     = 1,
        [FromQuery] int     pageSize = 20)
    {
        var filter = new TicketFilter(status, priority, category, agentId, page, pageSize);
        var result = await _svc.GetAllAsync(filter);
        return Ok(result);
    }

    [HttpGet("my")]
    [Authorize(Roles = "Customer")]
    public async Task<IActionResult> GetMyTickets()
    {
        var tickets = await _svc.GetMyTicketsAsync(CurrentUserId);
        return Ok(tickets);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var dto = await _svc.GetByIdAsync(id);
        if (dto is null) return NotFound();
        return Ok(dto);
    }

    [HttpPatch("{id:guid}/status")]
    [Authorize(Policy = "AgentOrAbove")]
    public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateStatusRequest req)
    {
        try
        {
            var dto = await _svc.UpdateStatusAsync(id, req, CurrentUserId, CurrentUserName);
            return Ok(dto);
        }
        catch (KeyNotFoundException) { return NotFound(); }
        catch (ArgumentException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpPatch("{id:guid}/assign")]
    [Authorize(Policy = "SupervisorOrAbove")]
    public async Task<IActionResult> Assign(Guid id, [FromBody] AssignTicketRequest req)
    {
        try
        {
            var dto = await _svc.AssignAsync(id, req);
            return Ok(dto);
        }
        catch (KeyNotFoundException) { return NotFound(); }
    }
}
