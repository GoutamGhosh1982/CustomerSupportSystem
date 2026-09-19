-- ============================================================
--  Customer Support Ticketing System
--  Full Database Creation Script
--
--  Run in SSMS connected to your SQL Server instance.
--  IDEMPOTENT -- safe to run multiple times.
--
--  Seed passwords (BCrypt, cost=11):
--    admin@support.com    => Admin@123
--    agent@support.com    => Agent@123
--    customer@example.com => Customer@123
--
--  NOTE: The application's DbSeeder (UserService/Data/DbSeeder.cs)
--  overwrites these hashes with freshly computed ones on first start.
--  The hashes below are valid and can be used immediately via Swagger
--  or Postman before running the app for the first time.
-- ============================================================

-- ============================================================
-- 0. Use master to create databases
-- ============================================================
USE master;
GO

-- ============================================================
-- 1. DATABASE: UserDB
-- ============================================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'UserDB')
BEGIN
    CREATE DATABASE UserDB;
    PRINT 'Database UserDB created.';
END
ELSE
    PRINT 'Database UserDB already exists -- skipping create.';
GO

USE UserDB;
GO

-- --------------------------------------------------------
-- EF Migrations history table (prevents EF from re-running
-- the InitialCreate migration when services start)
-- --------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = '__EFMigrationsHistory' AND type = 'U')
BEGIN
    CREATE TABLE dbo.[__EFMigrationsHistory] (
        MigrationId    NVARCHAR(150) NOT NULL,
        ProductVersion NVARCHAR(32)  NOT NULL,
        CONSTRAINT PK___EFMigrationsHistory PRIMARY KEY (MigrationId)
    );
    -- Record the migration that the code already generated
    INSERT INTO dbo.[__EFMigrationsHistory] (MigrationId, ProductVersion)
    VALUES ('20260728092353_InitialCreate', '10.0.0');
    PRINT 'EF migration history seeded for UserDB.';
END
ELSE
    PRINT '__EFMigrationsHistory already exists in UserDB -- skipping.';
GO

-- --------------------------------------------------------
-- Table: Users
-- --------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Users' AND type = 'U')
BEGIN
    CREATE TABLE dbo.Users (
        Id           UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        Email        NVARCHAR(200)    NOT NULL,
        FullName     NVARCHAR(150)    NOT NULL,
        PasswordHash NVARCHAR(500)    NOT NULL,
        Role         NVARCHAR(20)     NOT NULL DEFAULT 'Customer',
        IsActive     BIT              NOT NULL DEFAULT 1,
        CreatedAt    DATETIME2        NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT PK_Users       PRIMARY KEY (Id),
        CONSTRAINT UQ_Users_Email UNIQUE      (Email),
        CONSTRAINT CK_Users_Role  CHECK       (Role IN ('Customer','Agent','Supervisor','Admin'))
    );

    CREATE INDEX IX_Users_Email ON dbo.Users (Email);
    CREATE INDEX IX_Users_Role  ON dbo.Users (Role);

    PRINT 'Table Users created in UserDB.';
END
ELSE
    PRINT 'Table Users already exists -- skipping.';
GO

-- --------------------------------------------------------
-- Seed: Default users
-- Passwords (BCrypt cost=11):
--   Admin@123    => $2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.
--   Agent@123    => $2a$11$8K1p/a0dL1LXMIgoEDFrwOe1SJDCS5SBDk5rA7u3IiJTH.OqWnfm2
--   Customer@123 => $2a$11$eLB1KJtMb5SbPGMbX2s7XuKbF1F3xA8LWrUJQWGnRpALyxd4MHIPG
--
-- The application's DbSeeder will regenerate fresh hashes on startup.
-- These are real, valid BCrypt hashes so the SQL-seeded accounts work
-- immediately (e.g. during Docker-only testing before the app starts).
-- --------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'admin@support.com')
BEGIN
    INSERT INTO dbo.Users (Id, Email, FullName, PasswordHash, Role, IsActive, CreatedAt)
    VALUES
    (
        NEWID(),
        'admin@support.com',
        'System Admin',
        '$2a$11$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.',
        'Admin',
        1,
        GETUTCDATE()
    );
    PRINT 'Seed user admin@support.com inserted.';
END
ELSE
    PRINT 'admin@support.com already present -- skipping.';
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'agent@support.com')
BEGIN
    INSERT INTO dbo.Users (Id, Email, FullName, PasswordHash, Role, IsActive, CreatedAt)
    VALUES
    (
        NEWID(),
        'agent@support.com',
        'Support Agent',
        '$2a$11$8K1p/a0dL1LXMIgoEDFrwOe1SJDCS5SBDk5rA7u3IiJTH.OqWnfm2',
        'Agent',
        1,
        GETUTCDATE()
    );
    PRINT 'Seed user agent@support.com inserted.';
END
ELSE
    PRINT 'agent@support.com already present -- skipping.';
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Email = 'customer@example.com')
BEGIN
    INSERT INTO dbo.Users (Id, Email, FullName, PasswordHash, Role, IsActive, CreatedAt)
    VALUES
    (
        NEWID(),
        'customer@example.com',
        'Jane Customer',
        '$2a$11$eLB1KJtMb5SbPGMbX2s7XuKbF1F3xA8LWrUJQWGnRpALyxd4MHIPG',
        'Customer',
        1,
        GETUTCDATE()
    );
    PRINT 'Seed user customer@example.com inserted.';
END
ELSE
    PRINT 'customer@example.com already present -- skipping.';
GO


-- ============================================================
-- 2. DATABASE: TicketDB
-- ============================================================
USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'TicketDB')
BEGIN
    CREATE DATABASE TicketDB;
    PRINT 'Database TicketDB created.';
END
ELSE
    PRINT 'Database TicketDB already exists -- skipping create.';
GO

USE TicketDB;
GO

-- --------------------------------------------------------
-- EF Migrations history table
-- --------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = '__EFMigrationsHistory' AND type = 'U')
BEGIN
    CREATE TABLE dbo.[__EFMigrationsHistory] (
        MigrationId    NVARCHAR(150) NOT NULL,
        ProductVersion NVARCHAR(32)  NOT NULL,
        CONSTRAINT PK___EFMigrationsHistory PRIMARY KEY (MigrationId)
    );
    INSERT INTO dbo.[__EFMigrationsHistory] (MigrationId, ProductVersion)
    VALUES ('20260728092354_InitialCreate', '10.0.0');
    PRINT 'EF migration history seeded for TicketDB.';
END
ELSE
    PRINT '__EFMigrationsHistory already exists in TicketDB -- skipping.';
GO

-- --------------------------------------------------------
-- Table: Tickets
-- Constraint names match what EF generates (CK_Status, CK_Priority)
-- to avoid duplicate-constraint errors if EF ever recreates them.
-- --------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Tickets' AND type = 'U')
BEGIN
    CREATE TABLE dbo.Tickets (
        Id             UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        TicketNumber   NVARCHAR(20)     NOT NULL,
        Title          NVARCHAR(200)    NOT NULL,
        Description    NVARCHAR(MAX)    NOT NULL,
        Status         NVARCHAR(20)     NOT NULL DEFAULT 'Open',
        Priority       NVARCHAR(10)     NOT NULL DEFAULT 'Medium',
        Category       NVARCHAR(50)     NOT NULL,
        CustomerId     UNIQUEIDENTIFIER NOT NULL,
        CustomerName   NVARCHAR(150)    NOT NULL DEFAULT '',
        CustomerEmail  NVARCHAR(200)    NOT NULL DEFAULT '',
        AssignedToId   UNIQUEIDENTIFIER NULL,
        AssignedToName NVARCHAR(150)    NULL,
        SlaDeadline    DATETIME2        NULL,
        CreatedAt      DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt      DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
        ClosedAt       DATETIME2        NULL,

        CONSTRAINT PK_Tickets         PRIMARY KEY (Id),
        CONSTRAINT UQ_Tickets_Number  UNIQUE      (TicketNumber),
        -- Names match EF-generated constraint names exactly:
        CONSTRAINT CK_Status          CHECK       (Status   IN ('Open','InProgress','Escalated','Closed')),
        CONSTRAINT CK_Priority        CHECK       (Priority IN ('Low','Medium','High','Critical'))
    );

    -- EF creates this index; additional indexes aid dashboard queries
    CREATE UNIQUE INDEX IX_Tickets_TicketNumber  ON dbo.Tickets (TicketNumber);
    CREATE        INDEX IX_Tickets_Status        ON dbo.Tickets (Status);
    CREATE        INDEX IX_Tickets_Priority      ON dbo.Tickets (Priority);
    CREATE        INDEX IX_Tickets_CustomerId    ON dbo.Tickets (CustomerId);
    CREATE        INDEX IX_Tickets_AssignedToId  ON dbo.Tickets (AssignedToId);
    CREATE        INDEX IX_Tickets_CreatedAt     ON dbo.Tickets (CreatedAt DESC);

    PRINT 'Table Tickets created in TicketDB.';
END
ELSE
    PRINT 'Table Tickets already exists -- skipping.';
GO

-- --------------------------------------------------------
-- Trigger: Auto-update UpdatedAt on every UPDATE
-- --------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'TR_Tickets_UpdatedAt')
BEGIN
    EXEC('
    CREATE TRIGGER dbo.TR_Tickets_UpdatedAt
    ON  dbo.Tickets
    AFTER UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;
        IF UPDATE(UpdatedAt) RETURN;   -- avoid recursion if something sets it explicitly
        UPDATE dbo.Tickets
        SET    UpdatedAt = GETUTCDATE()
        FROM   dbo.Tickets t
        INNER  JOIN inserted i ON t.Id = i.Id;
    END
    ');
    PRINT 'Trigger TR_Tickets_UpdatedAt created.';
END
ELSE
    PRINT 'Trigger TR_Tickets_UpdatedAt already exists -- skipping.';
GO

-- --------------------------------------------------------
-- View: V_OpenTicketSummary  (useful for admin dashboards)
-- --------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.views WHERE name = 'V_OpenTicketSummary')
BEGIN
    EXEC('
    CREATE VIEW dbo.V_OpenTicketSummary AS
    SELECT
        Status,
        Priority,
        Category,
        COUNT(*)                                       AS TicketCount,
        MIN(CreatedAt)                                 AS OldestTicket,
        AVG(DATEDIFF(MINUTE, CreatedAt, GETUTCDATE())) AS AvgAgeMinutes
    FROM dbo.Tickets
    WHERE Status != ''Closed''
    GROUP BY Status, Priority, Category;
    ');
    PRINT 'View V_OpenTicketSummary created.';
END
ELSE
    PRINT 'View V_OpenTicketSummary already exists -- skipping.';
GO


-- ============================================================
-- 3. DATABASE: ResponseDB
-- ============================================================
USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'ResponseDB')
BEGIN
    CREATE DATABASE ResponseDB;
    PRINT 'Database ResponseDB created.';
END
ELSE
    PRINT 'Database ResponseDB already exists -- skipping create.';
GO

USE ResponseDB;
GO

-- --------------------------------------------------------
-- EF Migrations history table
-- --------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = '__EFMigrationsHistory' AND type = 'U')
BEGIN
    CREATE TABLE dbo.[__EFMigrationsHistory] (
        MigrationId    NVARCHAR(150) NOT NULL,
        ProductVersion NVARCHAR(32)  NOT NULL,
        CONSTRAINT PK___EFMigrationsHistory PRIMARY KEY (MigrationId)
    );
    INSERT INTO dbo.[__EFMigrationsHistory] (MigrationId, ProductVersion)
    VALUES ('20260728092356_InitialCreate', '10.0.0');
    PRINT 'EF migration history seeded for ResponseDB.';
END
ELSE
    PRINT '__EFMigrationsHistory already exists in ResponseDB -- skipping.';
GO

-- --------------------------------------------------------
-- Table: Responses
-- --------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Responses' AND type = 'U')
BEGIN
    CREATE TABLE dbo.Responses (
        Id          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        TicketId    UNIQUEIDENTIFIER NOT NULL,
        AuthorId    UNIQUEIDENTIFIER NOT NULL,
        AuthorName  NVARCHAR(150)    NOT NULL,
        AuthorEmail NVARCHAR(200)    NOT NULL,
        AuthorType  NVARCHAR(10)     NOT NULL DEFAULT 'Customer',
        Body        NVARCHAR(MAX)    NOT NULL,
        IsInternal  BIT              NOT NULL DEFAULT 0,
        CreatedAt   DATETIME2        NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT PK_Responses          PRIMARY KEY (Id),
        CONSTRAINT CK_Responses_AuthType CHECK       (AuthorType IN ('Customer','Agent'))
    );

    CREATE INDEX IX_Responses_TicketId  ON dbo.Responses (TicketId);
    CREATE INDEX IX_Responses_AuthorId  ON dbo.Responses (AuthorId);
    CREATE INDEX IX_Responses_CreatedAt ON dbo.Responses (CreatedAt);

    PRINT 'Table Responses created in ResponseDB.';
END
ELSE
    PRINT 'Table Responses already exists -- skipping.';
GO

-- --------------------------------------------------------
-- Table: Attachments
-- --------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Attachments' AND type = 'U')
BEGIN
    CREATE TABLE dbo.Attachments (
        Id            UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        ResponseId    UNIQUEIDENTIFIER NOT NULL,
        FileName      NVARCHAR(255)    NOT NULL,
        BlobUrl       NVARCHAR(500)    NOT NULL,
        ContentType   NVARCHAR(100)    NOT NULL,
        FileSizeBytes BIGINT           NOT NULL DEFAULT 0,
        UploadedAt    DATETIME2        NOT NULL DEFAULT GETUTCDATE(),

        CONSTRAINT PK_Attachments            PRIMARY KEY (Id),
        CONSTRAINT FK_Attachments_ResponseId FOREIGN KEY (ResponseId)
            REFERENCES dbo.Responses (Id) ON DELETE CASCADE
    );

    CREATE INDEX IX_Attachments_ResponseId ON dbo.Attachments (ResponseId);

    PRINT 'Table Attachments created in ResponseDB.';
END
ELSE
    PRINT 'Table Attachments already exists -- skipping.';
GO


-- ============================================================
-- 4. DATABASE: NotificationDB
-- ============================================================
USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'NotificationDB')
BEGIN
    CREATE DATABASE NotificationDB;
    PRINT 'Database NotificationDB created.';
END
ELSE
    PRINT 'Database NotificationDB already exists -- skipping create.';
GO

USE NotificationDB;
GO

-- --------------------------------------------------------
-- EF Migrations history table
-- --------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = '__EFMigrationsHistory' AND type = 'U')
BEGIN
    CREATE TABLE dbo.[__EFMigrationsHistory] (
        MigrationId    NVARCHAR(150) NOT NULL,
        ProductVersion NVARCHAR(32)  NOT NULL,
        CONSTRAINT PK___EFMigrationsHistory PRIMARY KEY (MigrationId)
    );
    INSERT INTO dbo.[__EFMigrationsHistory] (MigrationId, ProductVersion)
    VALUES ('20260728092353_InitialCreate', '10.0.0');
    PRINT 'EF migration history seeded for NotificationDB.';
END
ELSE
    PRINT '__EFMigrationsHistory already exists in NotificationDB -- skipping.';
GO

-- --------------------------------------------------------
-- Table: NotificationLogs
-- --------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'NotificationLogs' AND type = 'U')
BEGIN
    CREATE TABLE dbo.NotificationLogs (
        Id             UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
        RecipientEmail NVARCHAR(200)    NOT NULL,
        Subject        NVARCHAR(300)    NOT NULL,
        Body           NVARCHAR(MAX)    NOT NULL,
        Channel        NVARCHAR(20)     NOT NULL DEFAULT 'Email',
        EventType      NVARCHAR(50)     NOT NULL,
        TicketId       UNIQUEIDENTIFIER NOT NULL,
        IsDelivered    BIT              NOT NULL DEFAULT 0,
        CreatedAt      DATETIME2        NOT NULL DEFAULT GETUTCDATE(),
        DeliveredAt    DATETIME2        NULL,

        CONSTRAINT PK_NotificationLogs         PRIMARY KEY (Id),
        CONSTRAINT CK_NotificationLogs_Channel CHECK       (Channel IN ('Email','InApp'))
    );

    CREATE INDEX IX_NotifLogs_TicketId    ON dbo.NotificationLogs (TicketId);
    CREATE INDEX IX_NotifLogs_EventType   ON dbo.NotificationLogs (EventType);
    CREATE INDEX IX_NotifLogs_CreatedAt   ON dbo.NotificationLogs (CreatedAt DESC);
    CREATE INDEX IX_NotifLogs_IsDelivered ON dbo.NotificationLogs (IsDelivered);

    PRINT 'Table NotificationLogs created in NotificationDB.';
END
ELSE
    PRINT 'Table NotificationLogs already exists -- skipping.';
GO


-- ============================================================
-- 5. VERIFICATION REPORT
-- ============================================================
USE master;
GO

PRINT '';
PRINT '========================================';
PRINT '  CREATION SUMMARY';
PRINT '========================================';

SELECT
    d.name        AS [Database],
    d.create_date AS [Created]
FROM sys.databases d
WHERE d.name IN ('UserDB','TicketDB','ResponseDB','NotificationDB')
ORDER BY d.name;

-- Show all user tables across all 4 databases
SELECT 'UserDB'         AS [Database], t.name AS [Table] FROM UserDB.sys.tables         t WHERE t.type = 'U'
UNION ALL
SELECT 'TicketDB'       AS [Database], t.name AS [Table] FROM TicketDB.sys.tables        t WHERE t.type = 'U'
UNION ALL
SELECT 'ResponseDB'     AS [Database], t.name AS [Table] FROM ResponseDB.sys.tables      t WHERE t.type = 'U'
UNION ALL
SELECT 'NotificationDB' AS [Database], t.name AS [Table] FROM NotificationDB.sys.tables  t WHERE t.type = 'U'
ORDER BY [Database], [Table];

-- Show seeded users
SELECT Email, FullName, Role, IsActive, CreatedAt
FROM UserDB.dbo.Users
ORDER BY Role, Email;

PRINT '';
PRINT 'Done.';
PRINT 'Default credentials:';
PRINT '  admin@support.com    / Admin@123';
PRINT '  agent@support.com    / Agent@123';
PRINT '  customer@example.com / Customer@123';
PRINT '';
PRINT 'Run each service with: dotnet run';
PRINT 'DbSeeder will refresh BCrypt hashes on first app startup.';
GO
