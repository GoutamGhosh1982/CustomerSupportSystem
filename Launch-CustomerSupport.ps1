# ==============================================================================
#  Launch-CustomerSupport.ps1
#  ONE script — Customer Support System full-stack launcher
#
#  Does everything automatically:
#    1. Checks Administrator rights
#    2. Checks pre-requisites  (dotnet, node, npm)
#    3. Installs Erlang + RabbitMQ if missing
#    4. Starts RabbitMQ service + enables Management UI
#    5. Builds entire .NET solution
#    6. Runs npm install if needed
#    7. Launches 5 .NET microservices + React frontend in separate windows
#    8. Opens browser at http://localhost:3000
#
#  USAGE (open PowerShell AS ADMINISTRATOR, cd to project root):
#    .\Launch-CustomerSupport.ps1              -- start everything
#    .\Launch-CustomerSupport.ps1 -Action stop -- stop everything
#    .\Launch-CustomerSupport.ps1 -Action status -- check ports
# ==============================================================================

param(
    [ValidateSet("start","stop","status")]
    [string]$Action = "start"
)

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

$ROOT         = $PSScriptRoot
$SLN          = "$ROOT\backend\CustomerSupportSystem.sln"
$FRONTEND     = "$ROOT\frontend"
$SERVICE_NAME = "RabbitMQ"

# RabbitMQ version constants
$ERLANG_VERSION   = "29.0.4"
$RABBITMQ_VERSION = "4.0.9"
$ERLANG_ID        = "Erlang.ErlangOTP"
$RABBITMQ_URL     = "https://github.com/rabbitmq/rabbitmq-server/releases/download/v$RABBITMQ_VERSION/rabbitmq-server-$RABBITMQ_VERSION.exe"

# Services list
$SERVICES = @(
    @{ Name="UserService";         Dir="$ROOT\backend\UserService";         Port=5004 },
    @{ Name="TicketService";       Dir="$ROOT\backend\TicketService";       Port=5001 },
    @{ Name="ResponseService";     Dir="$ROOT\backend\ResponseService";     Port=5002 },
    @{ Name="NotificationService"; Dir="$ROOT\backend\NotificationService"; Port=5003 },
    @{ Name="Gateway";             Dir="$ROOT\backend\Gateway";             Port=5000 }
)

# ==============================================================================
# Helpers
# ==============================================================================
function Write-Banner {
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host "   Customer Support System  --  Full-Stack Launcher               " -ForegroundColor Cyan
    Write-Host "  ================================================================" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-Step ($n, $msg) { Write-Host "  [$n] $msg" -ForegroundColor Cyan    }
function Write-OK   ($msg)     { Write-Host "      [OK]   $msg" -ForegroundColor Green  }
function Write-Warn ($msg)     { Write-Host "      [WARN] $msg" -ForegroundColor Yellow }
function Write-Err  ($msg)     { Write-Host "      [ERR]  $msg" -ForegroundColor Red    }
function Write-Info ($msg)     { Write-Host "             $msg" -ForegroundColor White   }
function Write-Sep             { Write-Host "  ----------------------------------------------------------------" -ForegroundColor DarkGray }

# ==============================================================================
# Assert Administrator
# ==============================================================================
function Assert-Admin {
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    $isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Err  "This script requires Administrator privileges."
        Write-Warn "Right-click the script -> Run as Administrator, then retry."
        Write-Host ""
        Read-Host "Press ENTER to exit"
        exit 1
    }
    Write-OK "Running as Administrator."
}

# ==============================================================================
# STEP 1 -- Pre-requisite checks
# ==============================================================================
function Test-Prerequisites {
    Write-Step 1 "Checking pre-requisites (dotnet, node, npm)..."
    $allOk = $true

    $dotnetVer = (dotnet --version 2>&1)
    if ($LASTEXITCODE -eq 0 -and $dotnetVer) {
        Write-OK "dotnet $dotnetVer"
    } else {
        Write-Err "dotnet SDK not found. Install from https://dotnet.microsoft.com/download"
        $allOk = $false
    }

    $nodeVer = (node --version 2>&1)
    if ($LASTEXITCODE -eq 0 -and $nodeVer) {
        Write-OK "node $nodeVer"
    } else {
        Write-Err "node not found. Install from https://nodejs.org"
        $allOk = $false
    }

    $npmVer = (npm --version 2>&1)
    if ($LASTEXITCODE -eq 0 -and $npmVer) {
        Write-OK "npm $npmVer"
    } else {
        Write-Err "npm not found. It ships with Node.js -- reinstall Node."
        $allOk = $false
    }

    if (-not $allOk) {
        Write-Host ""
        Write-Err "One or more pre-requisites are missing. Fix them and re-run."
        Read-Host "Press ENTER to exit"
        exit 1
    }
}

# ==============================================================================
# RabbitMQ helpers
# ==============================================================================
function Get-RabbitPaths {
    $rabbitBase = Get-ChildItem "C:\Program Files\RabbitMQ Server" -ErrorAction SilentlyContinue |
                  Where-Object { $_.PSIsContainer } |
                  Sort-Object Name -Descending |
                  Select-Object -First 1

    $erlangErtsBin = Get-ChildItem "C:\Program Files\Erlang OTP" -Filter "erts-*" -ErrorAction SilentlyContinue |
                     Sort-Object Name -Descending |
                     Select-Object -First 1

    $erlSrv  = if ($erlangErtsBin) { "$($erlangErtsBin.FullName)\bin\erlsrv.exe" } else { $null }
    $plugins = if ($rabbitBase)    { "$($rabbitBase.FullName)\sbin\rabbitmq-plugins.bat" } else { $null }

    return @{ ErlSrv = $erlSrv; Plugins = $plugins }
}

function Test-ErlangInstalled {
    $reg = Get-ChildItem "HKLM:\SOFTWARE\Ericsson\Erlang" -ErrorAction SilentlyContinue
    if ($reg) { return $true }
    return (Test-Path "C:\Program Files\Erlang OTP")
}

function Test-RabbitMQInstalled {
    $svc = Get-Service -Name $SERVICE_NAME -ErrorAction SilentlyContinue
    if ($svc) { return $true }
    return (Test-Path "C:\Program Files\RabbitMQ Server")
}

function Get-RabbitStatus {
    $svc = Get-Service -Name $SERVICE_NAME -ErrorAction SilentlyContinue
    if ($svc) { return $svc.Status } else { return $null }
}

function Test-Port ($port) {
    return (Test-NetConnection -ComputerName localhost -Port $port `
            -InformationLevel Quiet -WarningAction SilentlyContinue)
}

function Install-Erlang {
    Write-Info "Installing Erlang OTP $ERLANG_VERSION via winget..."
    winget install $ERLANG_ID --version $ERLANG_VERSION --silent `
        --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    if (Test-ErlangInstalled) {
        Write-OK "Erlang OTP installed."
        return $true
    }
    Write-Err "Erlang install failed. Download from https://www.erlang.org/downloads"
    return $false
}

function Install-RabbitMQ {
    Write-Info "Downloading RabbitMQ $RABBITMQ_VERSION..."
    $installer = "$env:TEMP\rabbitmq-$RABBITMQ_VERSION-setup.exe"
    try {
        Invoke-WebRequest -Uri $RABBITMQ_URL -OutFile $installer -UseBasicParsing
    } catch {
        Write-Err "Download failed: $_"
        return $false
    }
    Write-Info "Installing RabbitMQ silently (may take ~60s)..."
    Start-Process -FilePath $installer -ArgumentList "/S" -Wait -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 10
    Remove-Item $installer -ErrorAction SilentlyContinue
    if (Test-RabbitMQInstalled) {
        Write-OK "RabbitMQ installed."
        return $true
    }
    Write-Err "RabbitMQ install failed."
    return $false
}

# ==============================================================================
# STEP 2 -- RabbitMQ: install + start + enable management UI
# ==============================================================================
function Start-RabbitMQ {
    Write-Step 2 "RabbitMQ -- install / start / management UI..."
    $paths = Get-RabbitPaths

    if (-not (Test-ErlangInstalled)) {
        Write-Warn "Erlang not found -- installing..."
        if (-not (Install-Erlang)) { exit 1 }
        $paths = Get-RabbitPaths
    } else {
        Write-OK "Erlang already installed."
    }

    if (-not (Test-RabbitMQInstalled)) {
        Write-Warn "RabbitMQ not found -- installing..."
        if (-not (Install-RabbitMQ)) { exit 1 }
        $paths = Get-RabbitPaths
    } else {
        Write-OK "RabbitMQ already installed."
    }

    $status = Get-RabbitStatus
    if ($status -eq "Running") {
        Write-OK "RabbitMQ service already running."
    } else {
        Write-Info "Starting RabbitMQ service..."
        if ($paths.ErlSrv -and (Test-Path $paths.ErlSrv)) {
            & $paths.ErlSrv start $SERVICE_NAME 2>&1 | Out-Null
        } else {
            net start $SERVICE_NAME 2>&1 | Out-Null
        }
        Start-Sleep -Seconds 8
        if ((Get-RabbitStatus) -eq "Running") {
            Write-OK "RabbitMQ service started."
        } else {
            Write-Err "RabbitMQ service failed to start. Check Windows Event Viewer."
            exit 1
        }
    }

    if ($paths.Plugins -and (Test-Path $paths.Plugins)) {
        Write-Info "Enabling rabbitmq_management plugin..."
        & $paths.Plugins enable rabbitmq_management 2>&1 | Out-Null
        Write-OK "Management plugin enabled."
    }

    Write-OK "RabbitMQ AMQP  -> amqp://guest:guest@localhost:5672"
    Write-OK "Management UI  -> http://localhost:15672  (guest / guest)"
}

# ==============================================================================
# STEP 3 -- Build .NET solution
# ==============================================================================
function Build-DotNet {
    Write-Step 3 "Building .NET solution (this may take a moment)..."
    $output = dotnet build $SLN --configuration Debug --nologo 2>&1
    $output | ForEach-Object { Write-Host "             $_" -ForegroundColor DarkGray }
    if ($LASTEXITCODE -ne 0) {
        Write-Err "dotnet build FAILED. See output above."
        Read-Host "Press ENTER to exit"
        exit 1
    }
    Write-OK "Solution built successfully."
}

# ==============================================================================
# STEP 4 -- npm install (if node_modules/vite missing)
# ==============================================================================
function Install-Frontend {
    Write-Step 4 "Frontend -- checking npm packages..."
    if (-not (Test-Path "$FRONTEND\node_modules\vite")) {
        Write-Info "node_modules incomplete -- running npm install..."
        Push-Location $FRONTEND
        npm install 2>&1 | Out-Null
        Pop-Location
        if ($LASTEXITCODE -ne 0) {
            Write-Err "npm install failed."
            exit 1
        }
        Write-OK "npm packages installed."
    } else {
        Write-OK "node_modules already up-to-date."
    }
}

# ==============================================================================
# STEP 5 -- Launch all services in separate windows
# ==============================================================================
function Start-AllServices {
    Write-Step 5 "Launching .NET microservices..."

    foreach ($svc in $SERVICES) {
        $svcName = $svc.Name
        $svcDir  = $svc.Dir
        $svcPort = $svc.Port
        Write-Info "Starting $svcName on port $svcPort..."
        $cmd = "cd '$svcDir'; `$env:ASPNETCORE_URLS='http://localhost:$svcPort'; dotnet run --no-build"
        Start-Process powershell -ArgumentList "-NoExit", "-Command", $cmd -WindowStyle Normal
        Start-Sleep -Seconds 1
    }

    Write-OK "All 5 .NET service windows launched."

    Write-Step 6 "Launching React frontend (Vite dev server)..."
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path","User")
    $fCmd = "cd '$FRONTEND'; npm run dev"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $fCmd -WindowStyle Normal
    Write-OK "Frontend window launched."
}

# ==============================================================================
# STEP 6 -- Wait then show endpoints + open browser
# ==============================================================================
function Open-Browser {
    Write-Sep
    Write-Host ""
    Write-Host "  Waiting 15 seconds for all services to boot..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15

    Write-Host ""
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "  |                   Service Endpoints                      |" -ForegroundColor Cyan
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host "  |  React Frontend       -> http://localhost:3000           |" -ForegroundColor White
    Write-Host "  |  API Gateway          -> http://localhost:5000           |" -ForegroundColor White
    Write-Host "  |  UserService Swagger  -> http://localhost:5004/swagger   |" -ForegroundColor White
    Write-Host "  |  TicketService Swagger-> http://localhost:5001/swagger   |" -ForegroundColor White
    Write-Host "  |  ResponseService      -> http://localhost:5002/swagger   |" -ForegroundColor White
    Write-Host "  |  NotificationService  -> http://localhost:5003/swagger   |" -ForegroundColor White
    Write-Host "  |  RabbitMQ Mgmt UI     -> http://localhost:15672          |" -ForegroundColor White
    Write-Host "  +----------------------------------------------------------+" -ForegroundColor DarkCyan
    Write-Host ""

    Start-Process "http://localhost:3000"
    Write-OK "Browser opened at http://localhost:3000"
    Write-Host ""
}

# ==============================================================================
# STOP -- kill all service processes by port
# ==============================================================================
function Stop-AllServices {
    Write-Banner
    Write-Step "STOP" "Stopping all Customer Support System services..."

    $ports = @(3000, 5000, 5001, 5002, 5003, 5004)
    foreach ($port in $ports) {
        $lines = netstat -ano 2>$null | Select-String ":$port\s"
        foreach ($line in $lines) {
            $parts = ($line -split '\s+') | Where-Object { $_ -ne "" }
            $pidVal = $parts[-1]
            if ($pidVal -match '^\d+$' -and $pidVal -ne '0') {
                try {
                    Stop-Process -Id ([int]$pidVal) -Force -ErrorAction SilentlyContinue
                    Write-OK "Stopped process on port $port (PID $pidVal)"
                } catch { }
            }
        }
    }

    $paths = Get-RabbitPaths
    if ((Get-RabbitStatus) -eq "Running") {
        Write-Info "Stopping RabbitMQ service..."
        if ($paths.ErlSrv -and (Test-Path $paths.ErlSrv)) {
            & $paths.ErlSrv stop $SERVICE_NAME 2>&1 | Out-Null
        } else {
            net stop $SERVICE_NAME 2>&1 | Out-Null
        }
        Start-Sleep -Seconds 3
        Write-OK "RabbitMQ stopped."
    } else {
        Write-OK "RabbitMQ was not running."
    }

    Write-Host ""
    Write-OK "All services stopped."
    Write-Host ""
}

# ==============================================================================
# STATUS -- check ports
# ==============================================================================
function Show-Status {
    Write-Host ""
    Write-Host "  Service Status" -ForegroundColor Cyan
    Write-Sep

    foreach ($svc in $SERVICES) {
        $open  = Test-Port $svc.Port
        $color = if ($open) { "Green" } else { "Red" }
        $mark  = if ($open) { "RUNNING  [OK]" } else { "STOPPED  [--]" }
        $label = $svc.Name.PadRight(24)
        Write-Host "  $label :$($svc.Port)  " -NoNewline
        Write-Host $mark -ForegroundColor $color
    }

    $feOpen  = Test-Port 3000
    $feColor = if ($feOpen) { "Green" } else { "Red" }
    $feMark  = if ($feOpen) { "RUNNING  [OK]" } else { "STOPPED  [--]" }
    Write-Host "  $("React Frontend".PadRight(24)) :3000  " -NoNewline
    Write-Host $feMark -ForegroundColor $feColor

    $rabStat  = Get-RabbitStatus
    $rabColor = if ($rabStat -eq "Running") { "Green" } elseif ($rabStat) { "Yellow" } else { "Red" }
    $rabLabel = if ($rabStat) { "$rabStat" } else { "Not found" }
    Write-Host "  $("RabbitMQ Service".PadRight(24))        " -NoNewline
    Write-Host $rabLabel -ForegroundColor $rabColor
    Write-Host ""
}

# ==============================================================================
# MAIN
# ==============================================================================
Write-Banner

if ($Action -eq "stop") {
    Assert-Admin
    Stop-AllServices
    exit 0
}

if ($Action -eq "status") {
    Show-Status
    exit 0
}

# -- Full start flow --
Assert-Admin
Write-Sep

Test-Prerequisites
Write-Sep

Start-RabbitMQ
Write-Sep

Build-DotNet
Write-Sep

Install-Frontend
Write-Sep

Start-AllServices

Open-Browser

Show-Status
