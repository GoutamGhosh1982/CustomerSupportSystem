using SharedKernel.Events;
using SharedKernel.Messaging;
using TicketService.DTOs;
using TicketService.Models;
using TicketService.Services;

namespace TicketService.Services;

public interface ITicketService
{
    Task<TicketDto> CreateAsync(CreateTicketRequest req, Guid customerId, string customerName, string customerEmail);
    Task<TicketDto?> GetByIdAsync(Guid id);
    Task<PagedResult<TicketDto>> GetAllAsync(TicketFilter filter);
    Task<List<TicketDto>> GetMyTicketsAsync(Guid customerId);
    Task<TicketDto> UpdateStatusAsync(Guid id, UpdateStatusRequest req, Guid userId, string userName);
    Task<TicketDto> AssignAsync(Guid id, AssignTicketRequest req);
}

public class TicketAppService : ITicketService
{
    private readonly ITicketRepository  _repo;
    private readonly IRabbitMqPublisher _publisher;

    public TicketAppService(ITicketRepository repo, IRabbitMqPublisher publisher)
    {
        _repo      = repo;
        _publisher = publisher;
    }

    public async Task<TicketDto> CreateAsync(
        CreateTicketRequest req,
        Guid customerId, string customerName, string customerEmail)
    {
        var count  = await _repo.GetCountAsync();
        var number = $"TKT-{(count + 1):D4}";

        var slaHours = req.Priority switch
        {
            "Critical" => 4,
            "High"     => 8,
            "Medium"   => 24,
            _          => 48
        };

        var ticket = new Ticket
        {
            TicketNumber  = number,
            Title         = req.Title,
            Description   = req.Description,
            Priority      = req.Priority,
            Category      = req.Category,
            CustomerId    = customerId,
            CustomerName  = customerName,
            CustomerEmail = customerEmail,
            SlaDeadline   = DateTime.UtcNow.AddHours(slaHours)
        };

        await _repo.CreateAsync(ticket);

        // RabbitMQ is optional — don't crash ticket creation if it's unavailable
        try
        {
            _publisher.Publish(new TicketCreatedEvent(
                ticket.Id, ticket.TicketNumber, ticket.Title,
                ticket.Priority, ticket.Category,
                customerId, customerEmail, customerName, ticket.CreatedAt),
                "ticket.created");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[WARN] RabbitMQ publish failed (ticket.created): {ex.Message}");
        }

        return ToDto(ticket);
    }

    public async Task<TicketDto?> GetByIdAsync(Guid id)
    {
        var ticket = await _repo.GetByIdAsync(id);
        return ticket is null ? null : ToDto(ticket);
    }

    public async Task<PagedResult<TicketDto>> GetAllAsync(TicketFilter filter)
    {
        var (items, total) = await _repo.GetAllAsync(filter);
        return new PagedResult<TicketDto>(items.Select(ToDto).ToList(), total, filter.Page, filter.PageSize);
    }

    public async Task<List<TicketDto>> GetMyTicketsAsync(Guid customerId)
    {
        var items = await _repo.GetByCustomerAsync(customerId);
        return items.Select(ToDto).ToList();
    }

    public async Task<TicketDto> UpdateStatusAsync(
        Guid id, UpdateStatusRequest req, Guid userId, string userName)
    {
        var ticket = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException($"Ticket {id} not found.");

        if (!TicketStatus.All.Contains(req.Status))
            throw new ArgumentException("Invalid status.");

        var oldStatus = ticket.Status;
        ticket.Status = req.Status;

        if (req.Status == TicketStatus.Closed)
            ticket.ClosedAt = DateTime.UtcNow;

        await _repo.UpdateAsync(ticket);

        try
        {
            _publisher.Publish(new TicketUpdatedEvent(
                ticket.Id, ticket.TicketNumber,
                oldStatus, ticket.Status,
                userId, userName, req.Note, DateTime.UtcNow),
                "ticket.updated");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[WARN] RabbitMQ publish failed (ticket.updated): {ex.Message}");
        }

        return ToDto(ticket);
    }

    public async Task<TicketDto> AssignAsync(Guid id, AssignTicketRequest req)
    {
        var ticket = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException($"Ticket {id} not found.");

        ticket.AssignedToId   = req.AgentId;
        ticket.AssignedToName = req.AgentName;

        if (ticket.Status == TicketStatus.Open)
            ticket.Status = TicketStatus.InProgress;

        await _repo.UpdateAsync(ticket);

        try
        {
            _publisher.Publish(new TicketAssignedEvent(
                ticket.Id, ticket.TicketNumber, ticket.Title,
                req.AgentId, req.AgentEmail, req.AgentName,
                ticket.CustomerId, ticket.CustomerEmail, DateTime.UtcNow),
                "ticket.assigned");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[WARN] RabbitMQ publish failed (ticket.assigned): {ex.Message}");
        }

        return ToDto(ticket);
    }

    private static TicketDto ToDto(Ticket t) => new(
        t.Id, t.TicketNumber, t.Title, t.Description,
        t.Status, t.Priority, t.Category,
        t.CustomerId, t.CustomerName, t.CustomerEmail,
        t.AssignedToId, t.AssignedToName,
        t.SlaDeadline, t.CreatedAt, t.UpdatedAt, t.ClosedAt);
}
