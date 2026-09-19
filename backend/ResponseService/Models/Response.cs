namespace ResponseService.Models;

public class Response
{
    public Guid     Id         { get; set; } = Guid.NewGuid();
    public Guid     TicketId   { get; set; }
    public Guid     AuthorId   { get; set; }
    public string   AuthorName { get; set; } = string.Empty;
    public string   AuthorEmail{ get; set; } = string.Empty;
    public string   AuthorType { get; set; } = "Customer"; // Customer | Agent
    public string   Body       { get; set; } = string.Empty;
    public bool     IsInternal { get; set; } = false;
    public DateTime CreatedAt  { get; set; } = DateTime.UtcNow;

    public List<Attachment> Attachments { get; set; } = new();
}

public class Attachment
{
    public Guid     Id          { get; set; } = Guid.NewGuid();
    public Guid     ResponseId  { get; set; }
    public string   FileName    { get; set; } = string.Empty;
    public string   BlobUrl     { get; set; } = string.Empty;
    public string   ContentType { get; set; } = string.Empty;
    public long     FileSizeBytes { get; set; }
    public DateTime UploadedAt  { get; set; } = DateTime.UtcNow;
}
