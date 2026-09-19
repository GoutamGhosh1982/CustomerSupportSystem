namespace ResponseService.DTOs;

public record AddResponseRequest(
    Guid    TicketId,
    string  Body,
    bool    IsInternal = false
);

public record ResponseDto(
    Guid             Id,
    Guid             TicketId,
    Guid             AuthorId,
    string           AuthorName,
    string           AuthorEmail,
    string           AuthorType,
    string           Body,
    bool             IsInternal,
    DateTime         CreatedAt,
    List<AttachmentDto> Attachments
);

public record AttachmentDto(
    Guid     Id,
    Guid     ResponseId,
    string   FileName,
    string   BlobUrl,
    string   ContentType,
    long     FileSizeBytes,
    DateTime UploadedAt
);
