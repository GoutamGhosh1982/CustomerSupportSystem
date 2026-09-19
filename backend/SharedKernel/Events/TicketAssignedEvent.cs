namespace SharedKernel.Events;

public record TicketAssignedEvent(
    Guid TicketId,
    string TicketNumber,
    string Title,
    Guid AgentId,
    string AgentEmail,
    string AgentName,
    Guid CustomerId,
    string CustomerEmail,
    DateTime AssignedAt
);
