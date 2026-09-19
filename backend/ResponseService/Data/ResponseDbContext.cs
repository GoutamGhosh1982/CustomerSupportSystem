using Microsoft.EntityFrameworkCore;
using ResponseService.Models;

namespace ResponseService.Data;

public class ResponseDbContext : DbContext
{
    public ResponseDbContext(DbContextOptions<ResponseDbContext> options) : base(options) { }

    public DbSet<Response>   Responses   => Set<Response>();
    public DbSet<Attachment> Attachments => Set<Attachment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Response>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.AuthorName).HasMaxLength(150).IsRequired();
            e.Property(x => x.AuthorEmail).HasMaxLength(200).IsRequired();
            e.Property(x => x.AuthorType).HasMaxLength(10).IsRequired();
            e.HasIndex(x => x.TicketId);
            e.HasMany(x => x.Attachments)
             .WithOne()
             .HasForeignKey(x => x.ResponseId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Attachment>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.FileName).HasMaxLength(255).IsRequired();
            e.Property(x => x.BlobUrl).HasMaxLength(500).IsRequired();
            e.Property(x => x.ContentType).HasMaxLength(100).IsRequired();
        });
    }
}
