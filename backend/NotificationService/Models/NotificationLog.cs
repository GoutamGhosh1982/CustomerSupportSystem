namespace NotificationService.Models;

public class NotificationLog
{
    public Guid     Id             { get; set; } = Guid.NewGuid();
    public string   RecipientEmail { get; set; } = string.Empty;
    public string   Subject        { get; set; } = string.Empty;
    public string   Body           { get; set; } = string.Empty;
    public string   Channel        { get; set; } = "Email"; // Email | InApp
    public string   EventType      { get; set; } = string.Empty;
    public Guid     TicketId       { get; set; }
    public bool     IsDelivered    { get; set; } = false;
    public DateTime CreatedAt      { get; set; } = DateTime.UtcNow;
    public DateTime? DeliveredAt   { get; set; }
}
