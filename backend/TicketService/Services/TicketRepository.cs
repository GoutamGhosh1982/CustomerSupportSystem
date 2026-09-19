using Microsoft.EntityFrameworkCore;
using TicketService.Data;
using TicketService.Models;

namespace TicketService.Services;

public interface ITicketRepository
{
    Task<Ticket?> GetByIdAsync(Guid id);
    Task<Ticket?> GetByNumberAsync(string number);
    Task<(List<Ticket> Items, int Total)> GetAllAsync(TicketFilter filter);
    Task<List<Ticket>> GetByCustomerAsync(Guid customerId);
    Task<Ticket> CreateAsync(Ticket ticket);
    Task<Ticket> UpdateAsync(Ticket ticket);
    Task<int> GetCountAsync();
}

public record TicketFilter(
    string? Status    = null,
    string? Priority  = null,
    string? Category  = null,
    Guid?   AgentId   = null,
    int     Page      = 1,
    int     PageSize  = 20
);

public class TicketRepository : ITicketRepository
{
    private readonly TicketDbContext _db;
    public TicketRepository(TicketDbContext db) => _db = db;

    public Task<Ticket?> GetByIdAsync(Guid id) => _db.Tickets.FindAsync(id).AsTask();

    public Task<Ticket?> GetByNumberAsync(string number) =>
        _db.Tickets.FirstOrDefaultAsync(t => t.TicketNumber == number);

    public async Task<(List<Ticket> Items, int Total)> GetAllAsync(TicketFilter filter)
    {
        var q = _db.Tickets.AsQueryable();

        if (!string.IsNullOrEmpty(filter.Status))   q = q.Where(t => t.Status   == filter.Status);
        if (!string.IsNullOrEmpty(filter.Priority)) q = q.Where(t => t.Priority == filter.Priority);
        if (!string.IsNullOrEmpty(filter.Category)) q = q.Where(t => t.Category == filter.Category);
        if (filter.AgentId.HasValue)                q = q.Where(t => t.AssignedToId == filter.AgentId);

        var total = await q.CountAsync();
        var items = await q.OrderByDescending(t => t.CreatedAt)
                           .Skip((filter.Page - 1) * filter.PageSize)
                           .Take(filter.PageSize)
                           .ToListAsync();

        return (items, total);
    }

    public Task<List<Ticket>> GetByCustomerAsync(Guid customerId) =>
        _db.Tickets.Where(t => t.CustomerId == customerId)
                   .OrderByDescending(t => t.CreatedAt)
                   .ToListAsync();

    public async Task<Ticket> CreateAsync(Ticket ticket)
    {
        _db.Tickets.Add(ticket);
        await _db.SaveChangesAsync();
        return ticket;
    }

    public async Task<Ticket> UpdateAsync(Ticket ticket)
    {
        ticket.UpdatedAt = DateTime.UtcNow;
        _db.Tickets.Update(ticket);
        await _db.SaveChangesAsync();
        return ticket;
    }

    public Task<int> GetCountAsync() => _db.Tickets.CountAsync();
}
