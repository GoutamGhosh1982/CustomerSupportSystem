# Start-All.ps1
# Launches all backend services + React frontend in separate windows, then opens the browser.

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Starting Customer Support System..." -ForegroundColor Cyan

# UserService - port 5004
Start-Process powershell -ArgumentList "-NoExit","-Command",
    "cd '$root\backend\UserService'; `$env:ASPNETCORE_URLS='http://localhost:5004'; dotnet run --no-build" `
    -WindowStyle Normal

Start-Sleep -Seconds 1

# TicketService - port 5001
Start-Process powershell -ArgumentList "-NoExit","-Command",
    "cd '$root\backend\TicketService'; `$env:ASPNETCORE_URLS='http://localhost:5001'; dotnet run --no-build" `
    -WindowStyle Normal

Start-Sleep -Seconds 1

# ResponseService - port 5002
Start-Process powershell -ArgumentList "-NoExit","-Command",
    "cd '$root\backend\ResponseService'; `$env:ASPNETCORE_URLS='http://localhost:5002'; dotnet run --no-build" `
    -WindowStyle Normal

Start-Sleep -Seconds 1

# NotificationService - port 5003
Start-Process powershell -ArgumentList "-NoExit","-Command",
    "cd '$root\backend\NotificationService'; `$env:ASPNETCORE_URLS='http://localhost:5003'; dotnet run --no-build" `
    -WindowStyle Normal

Start-Sleep -Seconds 1

# Gateway - port 5000
Start-Process powershell -ArgumentList "-NoExit","-Command",
    "cd '$root\backend\Gateway'; `$env:ASPNETCORE_URLS='http://localhost:5000'; dotnet run --no-build" `
    -WindowStyle Normal

Start-Sleep -Seconds 1

# React Frontend - port 3000
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
Start-Process powershell -ArgumentList "-NoExit","-Command",
    "cd '$root\frontend'; npm run dev" `
    -WindowStyle Normal

Write-Host ""
Write-Host "All services launching..." -ForegroundColor Green
Write-Host "Waiting 12 seconds for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 12

Write-Host ""
Write-Host "Service URLs:" -ForegroundColor Cyan
Write-Host "  Frontend   -> http://localhost:3000" -ForegroundColor White
Write-Host "  Gateway    -> http://localhost:5000" -ForegroundColor White
Write-Host "  User API   -> http://localhost:5004/swagger" -ForegroundColor White
Write-Host "  Ticket API -> http://localhost:5001/swagger" -ForegroundColor White

Start-Process "http://localhost:3000"
Write-Host ""
Write-Host "Browser opened at http://localhost:3000" -ForegroundColor Green
