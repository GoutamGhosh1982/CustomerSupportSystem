using RabbitMQ.Client;
using SharedKernel.Messaging;

namespace SharedKernel.Messaging;

/// <summary>
/// A no-op publisher used when RabbitMQ is unavailable at startup.
/// All publish calls are silently swallowed so the rest of the app keeps working.
/// </summary>
public class NullRabbitMqPublisher : IRabbitMqPublisher
{
    public void Publish<T>(T message, string routingKey) where T : class
    {
        // intentionally empty — RabbitMQ not available
    }
}

/// <summary>
/// Factory helper: tries to create a real RabbitMQ connection;
/// returns null if the broker is unreachable so the service can fall back gracefully.
/// </summary>
public static class RabbitMqConnectionFactory
{
    public static IConnection? TryCreate(RabbitMqSettings settings)
    {
        try
        {
            var factory = new ConnectionFactory
            {
                HostName    = settings.Host,
                Port        = settings.Port,
                UserName    = settings.Username,
                Password    = settings.Password,
                VirtualHost = settings.VirtualHost,
                RequestedConnectionTimeout = TimeSpan.FromSeconds(5)
            };
            return factory.CreateConnectionAsync().GetAwaiter().GetResult();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[WARN] RabbitMQ unavailable ({settings.Host}:{settings.Port}): {ex.Message}");
            Console.WriteLine("[WARN] Messaging events will be disabled until RabbitMQ is reachable.");
            return null;
        }
    }
}
