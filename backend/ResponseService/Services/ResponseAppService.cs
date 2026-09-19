using Microsoft.EntityFrameworkCore;
using ResponseService.Data;
using ResponseService.DTOs;
using ResponseService.Models;
using SharedKernel.Events;
using SharedKernel.Messaging;

namespace ResponseService.Services;

public interface IResponseService
{
    Task<ResponseDto> AddAsync(AddResponseRequest req, Guid authorId, string authorName, string authorEmail, string authorType);
    Task<List<ResponseDto>> GetByTicketAsync(Guid ticketId, bool includeInternal);
    Task<AttachmentDto> AddAttachmentAsync(Guid responseId, IFormFile file);
}

public class ResponseAppService : IResponseService
{
    private readonly ResponseDbContext  _db;
    private readonly IRabbitMqPublisher _publisher;
    private readonly IWebHostEnvironment _env;

    public ResponseAppService(
        ResponseDbContext db,
        IRabbitMqPublisher publisher,
        IWebHostEnvironment env)
    {
        _db        = db;
        _publisher = publisher;
        _env       = env;
    }

    public async Task<ResponseDto> AddAsync(
        AddResponseRequest req,
        Guid authorId, string authorName, string authorEmail, string authorType)
    {
        var response = new Response
        {
            TicketId    = req.TicketId,
            AuthorId    = authorId,
            AuthorName  = authorName,
            AuthorEmail = authorEmail,
            AuthorType  = authorType,
            Body        = req.Body,
            IsInternal  = req.IsInternal
        };

        _db.Responses.Add(response);
        await _db.SaveChangesAsync();

        try
        {
            _publisher.Publish(new ResponseAddedEvent(
                response.Id, response.TicketId,
                string.Empty,
                authorName, authorEmail, authorType,
                response.Body, response.IsInternal, response.CreatedAt),
                "response.added");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[WARN] RabbitMQ publish failed (response.added): {ex.Message}");
        }

        return ToDto(response);
    }

    public async Task<List<ResponseDto>> GetByTicketAsync(Guid ticketId, bool includeInternal)
    {
        var q = _db.Responses
                   .Include(r => r.Attachments)
                   .Where(r => r.TicketId == ticketId);

        if (!includeInternal)
            q = q.Where(r => !r.IsInternal);

        var items = await q.OrderBy(r => r.CreatedAt).ToListAsync();
        return items.Select(ToDto).ToList();
    }

    public async Task<AttachmentDto> AddAttachmentAsync(Guid responseId, IFormFile file)
    {
        var uploadDir = Path.Combine(_env.WebRootPath ?? "wwwroot", "uploads");
        Directory.CreateDirectory(uploadDir);

        var fileName  = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var filePath  = Path.Combine(uploadDir, fileName);

        await using (var stream = new FileStream(filePath, FileMode.Create))
            await file.CopyToAsync(stream);

        var attachment = new Attachment
        {
            ResponseId    = responseId,
            FileName      = file.FileName,
            BlobUrl       = $"/uploads/{fileName}",
            ContentType   = file.ContentType,
            FileSizeBytes = file.Length
        };

        _db.Attachments.Add(attachment);
        await _db.SaveChangesAsync();

        return new AttachmentDto(
            attachment.Id, attachment.ResponseId,
            attachment.FileName, attachment.BlobUrl,
            attachment.ContentType, attachment.FileSizeBytes, attachment.UploadedAt);
    }

    private static ResponseDto ToDto(Response r) => new(
        r.Id, r.TicketId, r.AuthorId, r.AuthorName, r.AuthorEmail,
        r.AuthorType, r.Body, r.IsInternal, r.CreatedAt,
        r.Attachments.Select(a => new AttachmentDto(
            a.Id, a.ResponseId, a.FileName, a.BlobUrl,
            a.ContentType, a.FileSizeBytes, a.UploadedAt)).ToList());
}
