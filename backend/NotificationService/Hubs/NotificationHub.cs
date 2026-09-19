using Microsoft.AspNetCore.SignalR;

namespace NotificationService.Hubs;

public class NotificationHub : Hub
{
    public async Task JoinGroup(string group)
        => await Groups.AddToGroupAsync(Context.ConnectionId, group);

    public async Task LeaveGroup(string group)
        => await Groups.RemoveFromGroupAsync(Context.ConnectionId, group);
}
