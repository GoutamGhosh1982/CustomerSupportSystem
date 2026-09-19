namespace SharedKernel.Events;

public record TicketUpdatedEvent(
    Guid TicketId,
    string TicketNumber,
    string OldStatus,
    string NewStatus,
    Guid UpdatedByUserId,
    string UpdatedByUserName,
    string? Note,
    DateTime UpdatedAt
);
