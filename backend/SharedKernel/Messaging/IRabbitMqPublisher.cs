namespace SharedKernel.Messaging;

public interface IRabbitMqPublisher
{
    void Publish<T>(T message, string routingKey) where T : class;
}
