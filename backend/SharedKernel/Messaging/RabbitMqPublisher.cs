using System.Text;
using System.Text.Json;
using RabbitMQ.Client;

namespace SharedKernel.Messaging;

public class RabbitMqPublisher : IRabbitMqPublisher, IDisposable
{
    private readonly IChannel _channel;
    private const string Exchange = "support.events";

    public RabbitMqPublisher(IConnection connection)
    {
        _channel = connection.CreateChannelAsync().GetAwaiter().GetResult();
        _channel.ExchangeDeclareAsync(Exchange, ExchangeType.Topic, durable: true).GetAwaiter().GetResult();
    }

    public void Publish<T>(T message, string routingKey) where T : class
    {
        var json = JsonSerializer.Serialize(message);
        var body = Encoding.UTF8.GetBytes(json);

        var props = new BasicProperties
        {
            Persistent  = true,
            ContentType = "application/json",
            Timestamp   = new AmqpTimestamp(DateTimeOffset.UtcNow.ToUnixTimeSeconds())
        };

        _channel.BasicPublishAsync(
            exchange:   Exchange,
            routingKey: routingKey,
            mandatory:  false,
            basicProperties: props,
            body:       body).GetAwaiter().GetResult();
    }

    public void Dispose()
    {
        _channel?.CloseAsync().GetAwaiter().GetResult();
        _channel?.Dispose();
    }
}
