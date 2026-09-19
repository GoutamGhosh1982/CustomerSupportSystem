# Customer Support Ticketing System

A full-stack microservices application for managing customer support tickets.

## Technology Stack

| Layer         | Technology                                   |
|---------------|----------------------------------------------|
| Frontend      | React 18 · TypeScript · Vite · Tailwind CSS  |
| API Gateway   | .NET 8 · YARP Reverse Proxy                  |
| Ticket Svc    | .NET 8 Web API · EF Core · SQL Server        |
| Response Svc  | .NET 8 Web API · EF Core · SQL Server        |
| User Svc      | .NET 8 Web API · EF Core · SQL Server        |
| Notification  | .NET 8 · SignalR · RabbitMQ Consumer · SMTP  |
| Messaging     | RabbitMQ (Topic Exchange)                    |
| Containers    | Docker · Docker Compose                      |

---

## Quick Start (Docker Compose)

```bash
# From the workspace root
docker-compose up --build
```

| Service           | URL                              |
|-------------------|----------------------------------|
| React Frontend    | http://localhost:3000            |
| API Gateway       | http://localhost:5000            |
| RabbitMQ UI       | http://localhost:15672 (guest/guest) |

---

## Quick Start (Local Development)

### Prerequisites
- .NET 8 SDK
- Node.js 20+
- SQL Server (local or Docker)
- RabbitMQ (local or Docker)

### 1. Start infrastructure only

```bash
docker-compose up sqlserver rabbitmq -d
```

### 2. Run backend services

```bash
# Terminal 1 - User Service (port 5004)
cd backend/UserService
dotnet run

# Terminal 2 - Ticket Service (port 5001)
cd backend/TicketService
dotnet run

# Terminal 3 - Response Service (port 5002)
cd backend/ResponseService
dotnet run

# Terminal 4 - Notification Service (port 5003)
cd backend/NotificationService
dotnet run

# Terminal 5 - Gateway (port 5000)
cd backend/Gateway
dotnet run
```

### 3. Run frontend

```bash
cd frontend
npm install
npm run dev
# → http://localhost:3000
```

---

## Default Seed Accounts

| Role       | Email                    | Password       |
|------------|--------------------------|----------------|
| Admin      | admin@support.com        | Admin@123      |
| Agent      | agent@support.com        | Agent@123      |
| Customer   | customer@example.com     | Customer@123   |

---

## Project Structure

```
CustomerSupportSystem/
├── backend/
│   ├── SharedKernel/          ← Shared events & RabbitMQ publisher
│   ├── UserService/           ← Auth, JWT, user management
│   ├── TicketService/         ← Ticket CRUD, state machine
│   ├── ResponseService/       ← Threaded responses, attachments
│   ├── NotificationService/   ← Email, SignalR push, event consumers
│   └── Gateway/               ← YARP reverse proxy
├── frontend/
│   └── src/
│       ├── api/               ← Axios clients (auth, tickets, responses)
│       ├── features/          ← auth, tickets, dashboard, analytics, admin
│       ├── hooks/             ← useTickets, useResponses, useSignalR
│       ├── store/             ← Zustand auth store
│       └── types/             ← TypeScript interfaces
├── docker-compose.yml
└── README.md
```

---

## API Swagger UIs (when running locally)

| Service            | Swagger URL                          |
|--------------------|--------------------------------------|
| User Service       | http://localhost:5004/swagger        |
| Ticket Service     | http://localhost:5001/swagger        |
| Response Service   | http://localhost:5002/swagger        |
| Notification Svc   | http://localhost:5003/swagger        |

---

## EF Core Migrations

Run these once per service to create the database schema:

```bash
cd backend/UserService
dotnet ef migrations add InitialCreate
dotnet ef database update

cd backend/TicketService
dotnet ef migrations add InitialCreate
dotnet ef database update

cd backend/ResponseService
dotnet ef migrations add InitialCreate
dotnet ef database update

cd backend/NotificationService
dotnet ef migrations add InitialCreate
dotnet ef database update
```

> The services also auto-migrate on startup via `db.Database.Migrate()`.
