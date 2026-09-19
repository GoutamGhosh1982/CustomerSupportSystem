using Microsoft.EntityFrameworkCore;
using UserService.Models;

namespace UserService.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(UserDbContext context)
    {
        // Upsert each seed user so real BCrypt hashes always get written,
        // even if placeholder rows were inserted by the SQL script earlier.
        await UpsertUser(context, "admin@support.com",    "System Admin",    "Admin@123",    "Admin");
        await UpsertUser(context, "agent@support.com",    "Support Agent",   "Agent@123",    "Agent");
        await UpsertUser(context, "customer@example.com", "Jane Customer",   "Customer@123", "Customer");
        await context.SaveChangesAsync();
    }

    private static async Task UpsertUser(
        UserDbContext context, string email, string fullName, string password, string role)
    {
        var existing = await context.Users.FirstOrDefaultAsync(u => u.Email == email.ToLower());

        var realHash = BCrypt.Net.BCrypt.HashPassword(password);

        if (existing is null)
        {
            context.Users.Add(new User
            {
                Email        = email.ToLower(),
                FullName     = fullName,
                PasswordHash = realHash,
                Role         = role,
                IsActive     = true,
                CreatedAt    = DateTime.UtcNow
            });
        }
        else
        {
            // Always overwrite — ensures seed credentials are always valid
            existing.PasswordHash = realHash;
            existing.FullName     = fullName;
            existing.Role         = role;
            existing.IsActive     = true;
        }
    }
}
