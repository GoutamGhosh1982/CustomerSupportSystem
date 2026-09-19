namespace UserService.DTOs;

public record RegisterRequest(
    string FullName,
    string Email,
    string Password,
    string Role = "Customer"
);

public record LoginRequest(
    string Email,
    string Password
);

public record AuthResponse(
    string Token,
    string UserId,
    string FullName,
    string Email,
    string Role
);

public record UserDto(
    Guid   Id,
    string FullName,
    string Email,
    string Role,
    bool   IsActive,
    DateTime CreatedAt
);

public record UpdateRoleRequest(string Role);
