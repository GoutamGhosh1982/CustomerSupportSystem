namespace NotificationService.Config;

public class SmtpSettings
{
    public string Host      { get; set; } = "smtp.mailtrap.io";
    public int    Port      { get; set; } = 587;
    public string Username  { get; set; } = string.Empty;
    public string Password  { get; set; } = string.Empty;
    public string From      { get; set; } = "noreply@support.com";
    public bool   EnableSsl { get; set; } = true;
}
