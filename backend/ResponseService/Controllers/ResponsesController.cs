using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ResponseService.DTOs;
using ResponseService.Services;

namespace ResponseService.Controllers;

[ApiController]
[Route("api/responses")]
[Authorize]
public class ResponsesController : ControllerBase
{
    private readonly IResponseService _svc;
    public ResponsesController(IResponseService svc) => _svc = svc;

    private Guid   CurrentUserId   => Guid.Parse(User.FindFirstValue("userId")!);
    private string CurrentUserName => User.FindFirstValue("fullName") ?? string.Empty;
    private string CurrentEmail    => User.FindFirstValue(ClaimTypes.Email) ?? string.Empty;
    private string CurrentRole     => User.FindFirstValue(ClaimTypes.Role) ?? "Customer";

    [HttpPost]
    public async Task<IActionResult> Add([FromBody] AddResponseRequest req)
    {
        var authorType = CurrentRole == "Customer" ? "Customer" : "Agent";
        var dto = await _svc.AddAsync(req, CurrentUserId, CurrentUserName, CurrentEmail, authorType);
        return CreatedAtAction(nameof(GetByTicket), new { ticketId = req.TicketId }, dto);
    }

    [HttpGet("{ticketId:guid}")]
    public async Task<IActionResult> GetByTicket(Guid ticketId)
    {
        var includeInternal = User.IsInRole("Agent")
                           || User.IsInRole("Supervisor")
                           || User.IsInRole("Admin");
        var responses = await _svc.GetByTicketAsync(ticketId, includeInternal);
        return Ok(responses);
    }

    [HttpPost("{responseId:guid}/attachments")]
    public async Task<IActionResult> AddAttachment(Guid responseId, IFormFile file)
    {
        if (file is null || file.Length == 0)
            return BadRequest(new { message = "No file provided." });

        if (file.Length > 10 * 1024 * 1024)
            return BadRequest(new { message = "File size must be under 10 MB." });

        var dto = await _svc.AddAttachmentAsync(responseId, file);
        return Ok(dto);
    }
}
