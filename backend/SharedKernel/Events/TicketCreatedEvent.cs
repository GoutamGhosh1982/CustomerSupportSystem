namespace SharedKernel.Events;

public record TicketCreatedEvent(
    Guid TicketId,
    string TicketNumber,
    string Title,
    string Priority,
    string Category,
    Guid CustomerId,
    string CustomerEmail,
    string CustomerName,
    DateTime CreatedAt
);
