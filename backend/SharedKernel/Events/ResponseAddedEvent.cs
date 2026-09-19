namespace SharedKernel.Events;

public record ResponseAddedEvent(
    Guid ResponseId,
    Guid TicketId,
    string TicketNumber,
    string AuthorName,
    string AuthorEmail,
    string AuthorType,
    string Body,
    bool IsInternal,
    DateTime CreatedAt
);
