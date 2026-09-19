namespace TicketService.Models;

public class Ticket
{
    public Guid     Id           { get; set; } = Guid.NewGuid();
    public string   TicketNumber { get; set; } = string.Empty;
    public string   Title        { get; set; } = string.Empty;
    public string   Description  { get; set; } = string.Empty;
    public string   Status       { get; set; } = TicketStatus.Open;
    public string   Priority     { get; set; } = TicketPriority.Medium;
    public string   Category     { get; set; } = string.Empty;
    public Guid     CustomerId   { get; set; }
    public string   CustomerName { get; set; } = string.Empty;
    public string   CustomerEmail{ get; set; } = string.Empty;
    public Guid?    AssignedToId { get; set; }
    public string?  AssignedToName { get; set; }
    public DateTime? SlaDeadline { get; set; }
    public DateTime CreatedAt    { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt    { get; set; } = DateTime.UtcNow;
    public DateTime? ClosedAt   { get; set; }
}

public static class TicketStatus
{
    public const string Open       = "Open";
    public const string InProgress = "InProgress";
    public const string Escalated  = "Escalated";
    public const string Closed     = "Closed";

    public static readonly string[] All = { Open, InProgress, Escalated, Closed };
}

public static class TicketPriority
{
    public const string Low      = "Low";
    public const string Medium   = "Medium";
    public const string High     = "High";
    public const string Critical = "Critical";

    public static readonly string[] All = { Low, Medium, High, Critical };
}
