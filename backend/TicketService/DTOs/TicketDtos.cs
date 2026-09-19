namespace TicketService.DTOs;

public record CreateTicketRequest(
    string Title,
    string Description,
    string Category,
    string Priority = "Medium"
);

public record UpdateStatusRequest(
    string  Status,
    string? Note = null
);

public record AssignTicketRequest(
    Guid   AgentId,
    string AgentName,
    string AgentEmail
);

public record TicketDto(
    Guid      Id,
    string    TicketNumber,
    string    Title,
    string    Description,
    string    Status,
    string    Priority,
    string    Category,
    Guid      CustomerId,
    string    CustomerName,
    string    CustomerEmail,
    Guid?     AssignedToId,
    string?   AssignedToName,
    DateTime? SlaDeadline,
    DateTime  CreatedAt,
    DateTime  UpdatedAt,
    DateTime? ClosedAt
);

public record PagedResult<T>(
    List<T> Items,
    int     Total,
    int     Page,
    int     PageSize
)
{
    public int TotalPages => (int)Math.Ceiling((double)Total / PageSize);
}
