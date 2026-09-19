using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.SignalR;
using NotificationService.Data;
using NotificationService.Hubs;
using NotificationService.Models;
using NotificationService.Services;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using SharedKernel.Events;

namespace NotificationService.Consumers;

public class TicketEventConsumer : BackgroundService
{
    private readonly IChannel _channel;
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IHubContext<NotificationHub> _hub;
    private const string Exchange = "support.events";

    public TicketEventConsumer(
        IConnection connection,
        IServiceScopeFactory scopeFactory,
        IHubContext<NotificationHub> hub)
    {
        _scopeFactory = scopeFactory;
        _hub          = hub;
        _channel      = connection.CreateChannelAsync().GetAwaiter().GetResult();
        _channel.ExchangeDeclareAsync(Exchange, ExchangeType.Topic, durable: true).GetAwaiter().GetResult();

        DeclareAndBind("notif.ticket.created",  "ticket.created");
        DeclareAndBind("notif.ticket.updated",  "ticket.updated");
        DeclareAndBind("notif.ticket.assigned", "ticket.assigned");
        DeclareAndBind("notif.response.added",  "response.added");
    }

    private void DeclareAndBind(string queue, string routingKey)
    {
        _channel.QueueDeclareAsync(queue, durable: true, exclusive: false, autoDelete: false).GetAwaiter().GetResult();
        _channel.QueueBindAsync(queue, Exchange, routingKey).GetAwaiter().GetResult();
    }

    protected override Task ExecuteAsync(CancellationToken ct)
    {
        ConsumeQueue<TicketCreatedEvent>("notif.ticket.created",  HandleTicketCreated,  ct);
        ConsumeQueue<TicketUpdatedEvent>("notif.ticket.updated",  HandleTicketUpdated,  ct);
        ConsumeQueue<TicketAssignedEvent>("notif.ticket.assigned", HandleTicketAssigned, ct);
        ConsumeQueue<ResponseAddedEvent>("notif.response.added",  HandleResponseAdded,  ct);
        return Task.CompletedTask;
    }

    private void ConsumeQueue<T>(string queue, Func<T, Task> handler, CancellationToken ct)
    {
        var consumer = new AsyncEventingBasicConsumer(_channel);
        consumer.ReceivedAsync += async (_, ea) =>
        {
            try
            {
                var msg = JsonSerializer.Deserialize<T>(ea.Body.Span);
                if (msg is not null) await handler(msg);
                await _channel.BasicAckAsync(ea.DeliveryTag, false);
            }
            catch
            {
                await _channel.BasicNackAsync(ea.DeliveryTag, false, requeue: false);
            }
        };
        _channel.BasicConsumeAsync(queue, false, consumer).GetAwaiter().GetResult();
    }

    private async Task HandleTicketCreated(TicketCreatedEvent evt)
    {
        var subject = $"[{evt.TicketNumber}] Your ticket has been received";
        var body    = $@"<p>Dear {evt.CustomerName},</p>
<p>Your support ticket <strong>{evt.TicketNumber}</strong> — <em>{evt.Title}</em> has been created successfully.</p>
<p>Priority: <strong>{evt.Priority}</strong></p>
<p>We will respond as soon as possible.</p><p>— Support Team</p>";

        await SendEmailAndLog(evt.CustomerEmail, subject, body, "ticket.created", evt.TicketId);
        await _hub.Clients.Group("agents").SendAsync("TicketCreated", evt);
    }

    private async Task HandleTicketUpdated(TicketUpdatedEvent evt)
    {
        var subject = $"[{evt.TicketNumber}] Ticket status updated to {evt.NewStatus}";
        var body    = $@"<p>Ticket <strong>{evt.TicketNumber}</strong> status changed from 
<em>{evt.OldStatus}</em> to <strong>{evt.NewStatus}</strong>.</p>
{(string.IsNullOrEmpty(evt.Note) ? "" : $"<p>Note: {evt.Note}</p>")}
<p>— Support Team</p>";

        await _hub.Clients.Group($"ticket-{evt.TicketId}").SendAsync("TicketUpdated", evt);
        await LogNotification("", subject, body, "ticket.updated", evt.TicketId);
    }

    private async Task HandleTicketAssigned(TicketAssignedEvent evt)
    {
        var subject = $"[{evt.TicketNumber}] A ticket has been assigned to you";
        var body    = $@"<p>Dear {evt.AgentName},</p>
<p>Ticket <strong>{evt.TicketNumber}</strong> — <em>{evt.Title}</em> has been assigned to you.</p>
<p>Please review and respond at your earliest convenience.</p><p>— Support System</p>";

        await SendEmailAndLog(evt.AgentEmail, subject, body, "ticket.assigned", evt.TicketId);
        await _hub.Clients.Group("agents").SendAsync("TicketAssigned", evt);
    }

    private async Task HandleResponseAdded(ResponseAddedEvent evt)
    {
        await _hub.Clients.Group($"ticket-{evt.TicketId}").SendAsync("ResponseAdded", evt);
        await LogNotification("", $"New response on ticket", evt.Body, "response.added", evt.TicketId);
    }

    private async Task SendEmailAndLog(string to, string subject, string body, string eventType, Guid ticketId)
    {
        using var scope    = _scopeFactory.CreateScope();
        var emailService   = scope.ServiceProvider.GetRequiredService<IEmailService>();
        var db             = scope.ServiceProvider.GetRequiredService<NotificationDbContext>();

        var delivered = false;
        try
        {
            await emailService.SendAsync(to, subject, body);
            delivered = true;
        }
        catch { /* log and continue */ }

        db.NotificationLogs.Add(new NotificationLog
        {
            RecipientEmail = to,
            Subject        = subject,
            Body           = body,
            Channel        = "Email",
            EventType      = eventType,
            TicketId       = ticketId,
            IsDelivered    = delivered,
            DeliveredAt    = delivered ? DateTime.UtcNow : null
        });
        await db.SaveChangesAsync();
    }

    private async Task LogNotification(string to, string subject, string body, string eventType, Guid ticketId)
    {
        using var scope = _scopeFactory.CreateScope();
        var db          = scope.ServiceProvider.GetRequiredService<NotificationDbContext>();

        db.NotificationLogs.Add(new NotificationLog
        {
            RecipientEmail = to,
            Subject        = subject,
            Body           = body,
            Channel        = "InApp",
            EventType      = eventType,
            TicketId       = ticketId,
            IsDelivered    = true,
            DeliveredAt    = DateTime.UtcNow
        });
        await db.SaveChangesAsync();
    }

    public override void Dispose()
    {
        _channel?.CloseAsync().GetAwaiter().GetResult();
        _channel?.Dispose();
        base.Dispose();
    }
}
