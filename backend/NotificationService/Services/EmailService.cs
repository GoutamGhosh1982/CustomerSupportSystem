using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Options;
using NotificationService.Config;

namespace NotificationService.Services;

public interface IEmailService
{
    Task SendAsync(string to, string subject, string htmlBody);
}

public class SmtpEmailService : IEmailService
{
    private readonly SmtpSettings _settings;

    public SmtpEmailService(IOptions<SmtpSettings> options)
        => _settings = options.Value;

    public async Task SendAsync(string to, string subject, string htmlBody)
    {
        using var client = new SmtpClient(_settings.Host, _settings.Port)
        {
            Credentials = new NetworkCredential(_settings.Username, _settings.Password),
            EnableSsl   = _settings.EnableSsl
        };

        var mail = new MailMessage
        {
            From       = new MailAddress(_settings.From, "Customer Support"),
            Subject    = subject,
            Body       = htmlBody,
            IsBodyHtml = true
        };
        mail.To.Add(to);

        await client.SendMailAsync(mail);
    }
}
