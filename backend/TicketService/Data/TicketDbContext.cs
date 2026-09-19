using Microsoft.EntityFrameworkCore;
using TicketService.Models;

namespace TicketService.Data;

public class TicketDbContext : DbContext
{
    public TicketDbContext(DbContextOptions<TicketDbContext> options) : base(options) { }

    public DbSet<Ticket> Tickets => Set<Ticket>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Ticket>(e =>
        {
            e.HasKey(x => x.Id);
            e.Property(x => x.TicketNumber).HasMaxLength(20).IsRequired();
            e.HasIndex(x => x.TicketNumber).IsUnique();
            e.Property(x => x.Title).HasMaxLength(200).IsRequired();
            e.Property(x => x.Status).HasMaxLength(20).IsRequired();
            e.Property(x => x.Priority).HasMaxLength(10).IsRequired();
            e.Property(x => x.Category).HasMaxLength(50).IsRequired();
            e.Property(x => x.CustomerName).HasMaxLength(150);
            e.Property(x => x.CustomerEmail).HasMaxLength(200);
            e.Property(x => x.AssignedToName).HasMaxLength(150);
            e.ToTable(t =>
            {
                t.HasCheckConstraint("CK_Status",   $"Status   IN ('{string.Join("','", TicketStatus.All)}')");
                t.HasCheckConstraint("CK_Priority", $"Priority IN ('{string.Join("','", TicketPriority.All)}')");
                t.UseSqlOutputClause(false);
            });
        });
    }
}
