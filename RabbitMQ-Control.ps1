# ==============================================================================
#  RabbitMQ Full Control Script — Customer Support System
#  Automatically detects, installs, configures and manages RabbitMQ + Erlang.
#
#  USAGE  (open PowerShell as Administrator, cd to project root):
#
#    .\RabbitMQ-Control.ps1              -> Auto-install if needed, then START
#    .\RabbitMQ-Control.ps1 install      -> Install Erlang + RabbitMQ only
#    .\RabbitMQ-Control.ps1 start        -> Start RabbitMQ service
#    .\RabbitMQ-Control.ps1 stop         -> Stop  RabbitMQ service
#    .\RabbitMQ-Control.ps1 restart      -> Restart RabbitMQ service
#    .\RabbitMQ-Control.ps1 status       -> Show service + port status
#    .\RabbitMQ-Control.ps1 enable-ui    -> Enable Management UI plugin (once)
#    .\RabbitMQ-Control.ps1 open-ui      -> Open Management UI in browser
#    .\RabbitMQ-Control.ps1 check        -> Full health check
#    .\RabbitMQ-Control.ps1 uninstall    -> Remove RabbitMQ + Erlang
# ==============================================================================

param(
    [ValidateSet("install","start","stop","restart","status","enable-ui","open-ui","check","uninstall")]
    [string]$Action = "start"
)

Set-StrictMode -Off
$ErrorActionPreference = "Stop"

# ── Version constants ──────────────────────────────────────────────────────────
$ERLANG_VERSION   = "29.0.4"
$RABBITMQ_VERSION = "4.0.9"
$ERLANG_ID        = "Erlang.ErlangOTP"
$RABBITMQ_URL     = "https://github.com/rabbitmq/rabbitmq-server/releases/download/v$RABBITMQ_VERSION/rabbitmq-server-$RABBITMQ_VERSION.exe"
$SERVICE_NAME     = "RabbitMQ"

# ── Resolve install paths dynamically ─────────────────────────────────────────
function Get-RabbitPaths {
    $rabbitBase = Get-ChildItem "C:\Program Files\RabbitMQ Server" -ErrorAction SilentlyContinue |
                  Where-Object { $_.PSIsContainer } |
                  Sort-Object Name -Descending |
                  Select-Object -First 1

    $erlangErtsBin = Get-ChildItem "C:\Program Files\Erlang OTP" -Filter "erts-*" -ErrorAction SilentlyContinue |
                     Sort-Object Name -Descending |
                     Select-Object -First 1

    return @{
        RabbitSbin  = if ($rabbitBase) { "$($rabbitBase.FullName)\sbin" } else { $null }
        ErlSrv      = if ($erlangErtsBin) { "$($erlangErtsBin.FullName)\bin\erlsrv.exe" } else { $null }
        Plugins     = if ($rabbitBase)  { "$($rabbitBase.FullName)\sbin\rabbitmq-plugins.bat" } else { $null }
        RabbitCtl   = if ($rabbitBase)  { "$($rabbitBase.FullName)\sbin\rabbitmqctl.bat" } else { $null }
    }
}

# ── Helpers ────────────────────────────────────────────────────────────────────
function Write-Banner {
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor DarkCyan
    Write-Host "   RabbitMQ Control — Customer Support System  " -ForegroundColor Cyan
    Write-Host "  =============================================" -ForegroundColor DarkCyan
    Write-Host ""
}

function Write-Step($msg) {
    Write-Host "  >> $msg" -ForegroundColor Cyan
}

function Write-OK($msg)   { Write-Host "  [OK]   $msg" -ForegroundColor Green  }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  [ERR]  $msg" -ForegroundColor Red    }
function Write-Info($msg) { Write-Host "         $msg" -ForegroundColor White   }

function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
                 [Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Err "This script must be run AS ADMINISTRATOR."
        Write-Warn "Right-click PowerShell  →  'Run as Administrator'  →  retry."
        exit 1
    }
}

function Get-ServiceStatus {
    return (Get-Service -Name $SERVICE_NAME -ErrorAction SilentlyContinue)?.Status
}

function Test-Port($port) {
    return (Test-NetConnection -ComputerName localhost -Port $port `
            -InformationLevel Quiet -WarningAction SilentlyContinue)
}

# ── CHECK: Is Erlang installed? ────────────────────────────────────────────────
function Test-ErlangInstalled {
    $reg = Get-ChildItem "HKLM:\SOFTWARE\Ericsson\Erlang" -ErrorAction SilentlyContinue
    if ($reg) { return $true }
    return (Test-Path "C:\Program Files\Erlang OTP")
}

# ── CHECK: Is RabbitMQ installed? ─────────────────────────────────────────────
function Test-RabbitMQInstalled {
    $svc = Get-Service -Name $SERVICE_NAME -ErrorAction SilentlyContinue
    if ($svc) { return $true }
    return (Test-Path "C:\Program Files\RabbitMQ Server")
}

# ── INSTALL Erlang via winget ──────────────────────────────────────────────────
function Install-Erlang {
    Write-Step "Installing Erlang OTP $ERLANG_VERSION via winget..."
    try {
        winget install $ERLANG_ID `
            --version $ERLANG_VERSION `
            --silent `
            --accept-package-agreements `
            --accept-source-agreements 2>&1 | ForEach-Object { Write-Host "         $_" }

        if (Test-ErlangInstalled) {
            Write-OK "Erlang OTP installed successfully."
            return $true
        } else {
            Write-Err "Erlang install may not have completed. Please install manually:"
            Write-Info "https://www.erlang.org/downloads"
            return $false
        }
    } catch {
        Write-Err "winget install failed: $_"
        Write-Warn "Download Erlang manually: https://www.erlang.org/downloads"
        return $false
    }
}

# ── INSTALL RabbitMQ via direct download ──────────────────────────────────────
function Install-RabbitMQ {
    Write-Step "Downloading RabbitMQ $RABBITMQ_VERSION..."
    $installer = "$env:TEMP\rabbitmq-$RABBITMQ_VERSION-setup.exe"

    try {
        Invoke-WebRequest -Uri $RABBITMQ_URL -OutFile $installer -UseBasicParsing
        $sizeMB = [math]::Round((Get-Item $installer).Length / 1MB, 1)
        Write-OK "Downloaded ($sizeMB MB)"
    } catch {
        Write-Err "Download failed: $_"
        Write-Warn "Download manually from: https://www.rabbitmq.com/install-windows.html"
        return $false
    }

    Write-Step "Installing RabbitMQ $RABBITMQ_VERSION silently (may take 60s)..."
    try {
        $proc = Start-Process -FilePath $installer -ArgumentList "/S" -PassThru -Wait -ErrorAction Stop
        Start-Sleep -Seconds 5  # let service registration settle

        if (Test-RabbitMQInstalled) {
            Write-OK "RabbitMQ installed successfully."
            Remove-Item $installer -ErrorAction SilentlyContinue
            return $true
        } else {
            Write-Warn "Installer ran but service not detected yet. Waiting 15 more seconds..."
            Start-Sleep -Seconds 15
            if (Test-RabbitMQInstalled) {
                Write-OK "RabbitMQ service detected."
                return $true
            }
            Write-Err "RabbitMQ service still not found after installation."
            return $false
        }
    } catch {
        Write-Err "Installation failed: $_"
        return $false
    }
}

# ── ENSURE both are installed (idempotent) ────────────────────────────────────
function Invoke-EnsureInstalled {
    Assert-Admin
    $didInstall = $false

    Write-Step "Checking Erlang..."
    if (Test-ErlangInstalled) {
        $ver = (Get-ChildItem "HKLM:\SOFTWARE\Ericsson\Erlang" -ErrorAction SilentlyContinue |
                Select-Object -Last 1)?.PSChildName
        Write-OK "Erlang already installed$(if ($ver) {" (OTP $ver)"} else {''}). Skipping."
    } else {
        Write-Warn "Erlang not found. Installing..."
        $ok = Install-Erlang
        if (-not $ok) {
            Write-Err "Cannot continue without Erlang."
            exit 1
        }
        $didInstall = $true
    }

    Write-Step "Checking RabbitMQ..."
    if (Test-RabbitMQInstalled) {
        Write-OK "RabbitMQ already installed. Skipping."
    } else {
        Write-Warn "RabbitMQ not found. Installing..."
        $ok = Install-RabbitMQ
        if (-not $ok) {
            Write-Err "RabbitMQ installation failed. See messages above."
            exit 1
        }
        $didInstall = $true
    }

    return $didInstall
}

# ── START service ─────────────────────────────────────────────────────────────
function Invoke-Start {
    $paths = Get-RabbitPaths
    if (-not $paths.ErlSrv -or -not (Test-Path $paths.ErlSrv)) {
        Write-Err "erlsrv.exe not found at: $($paths.ErlSrv)"
        Write-Warn "Run:  .\RabbitMQ-Control.ps1 install"
        return
    }

    if ((Get-ServiceStatus) -eq "Running") {
        Write-OK "RabbitMQ is already running."
        Write-Info "AMQP -> amqp://guest:guest@localhost:5672"
        Write-Info "UI   -> http://localhost:15672  (guest / guest)"
        return
    }

    Write-Step "Starting RabbitMQ Windows service..."
    & $paths.ErlSrv start $SERVICE_NAME 2>&1 | Out-Null
    Start-Sleep -Seconds 7

    if ((Get-ServiceStatus) -eq "Running") {
        Write-OK "RabbitMQ started."
        Write-Info "AMQP -> amqp://guest:guest@localhost:5672"
        Write-Info "UI   -> http://localhost:15672  (guest / guest)"
    } else {
        # Try net start as fallback
        Write-Warn "erlsrv start returned non-running state. Trying net start..."
        net start $SERVICE_NAME 2>&1 | Out-Null
        Start-Sleep -Seconds 5
        $s = Get-ServiceStatus
        if ($s -eq "Running") {
            Write-OK "RabbitMQ started (via net start)."
        } else {
            Write-Err "Service status: $s. Check Windows Event Viewer for details."
        }
    }
}

# ── STOP service ──────────────────────────────────────────────────────────────
function Invoke-Stop {
    $paths = Get-RabbitPaths
    if ((Get-ServiceStatus) -eq "Stopped") {
        Write-OK "RabbitMQ is already stopped."
        return
    }
    Write-Step "Stopping RabbitMQ..."
    if ($paths.ErlSrv -and (Test-Path $paths.ErlSrv)) {
        & $paths.ErlSrv stop $SERVICE_NAME 2>&1 | Out-Null
    } else {
        net stop $SERVICE_NAME 2>&1 | Out-Null
    }
    Start-Sleep -Seconds 4
    Write-OK "RabbitMQ stopped."
}

# ── ENABLE Management UI ──────────────────────────────────────────────────────
function Invoke-EnableUI {
    $paths = Get-RabbitPaths
    if (-not $paths.Plugins -or -not (Test-Path $paths.Plugins)) {
        Write-Err "rabbitmq-plugins.bat not found. Is RabbitMQ installed?"
        return
    }

    # Must be running to enable plugin
    if ((Get-ServiceStatus) -ne "Running") {
        Write-Step "Starting RabbitMQ first..."
        Invoke-Start
        Start-Sleep -Seconds 3
    }

    Write-Step "Enabling rabbitmq_management plugin..."
    & $paths.Plugins enable rabbitmq_management 2>&1 | ForEach-Object { Write-Host "         $_" }

    Write-Step "Restarting to activate plugin..."
    Invoke-Stop
    Invoke-Start

    if (Test-Port 15672) {
        Write-OK "Management UI is live!"
        Write-Info "URL      -> http://localhost:15672"
        Write-Info "Username -> guest"
        Write-Info "Password -> guest"
    } else {
        Write-Warn "Port 15672 not yet open — allow a few more seconds, then try: .\RabbitMQ-Control.ps1 open-ui"
    }
}

# ── STATUS ────────────────────────────────────────────────────────────────────
function Invoke-Status {
    $erlOK    = Test-ErlangInstalled
    $rabOK    = Test-RabbitMQInstalled
    $svcStat  = Get-ServiceStatus
    $p5672    = Test-Port 5672
    $p15672   = Test-Port 15672

    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "  │          RabbitMQ Status Report              │" -ForegroundColor Cyan
    Write-Host "  └─────────────────────────────────────────────┘" -ForegroundColor DarkCyan
    Write-Host ""

    $erlColor = if ($erlOK)  {"Green"} else {"Red"}
    $rabColor = if ($rabOK)  {"Green"} else {"Red"}
    $svcColor = if ($svcStat -eq "Running") {"Green"} elseif ($svcStat) {"Yellow"} else {"Red"}
    $p1Color  = if ($p5672)  {"Green"} else {"Red"}
    $p2Color  = if ($p15672) {"Green"} else {"Yellow"}

    Write-Host "  Erlang OTP installed   : " -NoNewline; Write-Host $(if ($erlOK) {"Yes"} else {"NO — run install"}) -ForegroundColor $erlColor
    Write-Host "  RabbitMQ installed     : " -NoNewline; Write-Host $(if ($rabOK) {"Yes"} else {"NO — run install"}) -ForegroundColor $rabColor
    Write-Host "  Windows service        : " -NoNewline; Write-Host $(if ($svcStat) {$svcStat} else {"Not found"}) -ForegroundColor $svcColor
    Write-Host "  AMQP port  :5672       : " -NoNewline; Write-Host $(if ($p5672) {"OPEN  ✔"} else {"CLOSED ✘"}) -ForegroundColor $p1Color
    Write-Host "  Mgmt port  :15672      : " -NoNewline; Write-Host $(if ($p15672) {"OPEN  ✔  → http://localhost:15672"} else {"CLOSED  (run enable-ui to activate)"}) -ForegroundColor $p2Color
    Write-Host ""

    # Derive next recommended action
    if (-not $erlOK -or -not $rabOK) {
        Write-Host "  → Next step: " -NoNewline; Write-Host ".\RabbitMQ-Control.ps1 install" -ForegroundColor Yellow
    } elseif ($svcStat -ne "Running") {
        Write-Host "  → Next step: " -NoNewline; Write-Host ".\RabbitMQ-Control.ps1 start" -ForegroundColor Yellow
    } elseif (-not $p15672) {
        Write-Host "  → Next step: " -NoNewline; Write-Host ".\RabbitMQ-Control.ps1 enable-ui" -ForegroundColor Yellow
    } else {
        Write-Host "  → Status: " -NoNewline; Write-Host "All systems GO  🟢" -ForegroundColor Green
    }
    Write-Host ""
}

# ── FULL HEALTH CHECK ─────────────────────────────────────────────────────────
function Invoke-Check {
    $paths = Get-RabbitPaths
    Write-Host ""
    Write-Host "  ┌─────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "  │         Full Health Check Report             │" -ForegroundColor Cyan
    Write-Host "  └─────────────────────────────────────────────┘" -ForegroundColor DarkCyan
    Write-Host ""

    $checks = @()

    # 1 Erlang
    $erlOK = Test-ErlangInstalled
    $checks += [pscustomobject]@{ Check="Erlang OTP installed";    Pass=$erlOK;    Detail=if($erlOK){"Found"}else{"NOT found — run install"} }

    # 2 RabbitMQ files
    $rabOK = Test-RabbitMQInstalled
    $checks += [pscustomobject]@{ Check="RabbitMQ installed";      Pass=$rabOK;    Detail=if($rabOK){"Found"}else{"NOT found — run install"} }

    # 3 erlsrv.exe
    $erlsrvOK = $paths.ErlSrv -and (Test-Path $paths.ErlSrv)
    $checks += [pscustomobject]@{ Check="erlsrv.exe reachable";    Pass=$erlsrvOK; Detail=if($erlsrvOK){$paths.ErlSrv}else{"Not found"} }

    # 4 Windows service
    $svcStat = Get-ServiceStatus
    $svcOK   = $svcStat -eq "Running"
    $checks += [pscustomobject]@{ Check="Windows service Running"; Pass=$svcOK;    Detail=if($svcStat){$svcStat}else{"Service not found"} }

    # 5 AMQP port
    $p1 = Test-Port 5672
    $checks += [pscustomobject]@{ Check="AMQP port 5672 open";     Pass=$p1;       Detail=if($p1){"OPEN"}else{"CLOSED"} }

    # 6 Management port
    $p2 = Test-Port 15672
    $checks += [pscustomobject]@{ Check="Mgmt port 15672 open";    Pass=$p2;       Detail=if($p2){"OPEN — http://localhost:15672"}else{"CLOSED — run enable-ui"} }

    # 7 App connection string
    $checks += [pscustomobject]@{ Check="App connection string";   Pass=$true;     Detail="amqp://guest:guest@localhost:5672" }

    foreach ($c in $checks) {
        $icon  = if ($c.Pass) {"[PASS]"} else {"[FAIL]"}
        $color = if ($c.Pass) {"Green"}  else {"Red"}
        if ($c.Check -eq "App connection string") { $color = "White"; $icon = "[INFO]" }
        Write-Host "  $icon  $($c.Check.PadRight(30)) : " -NoNewline -ForegroundColor $color
        Write-Host $c.Detail -ForegroundColor White
    }

    $allPassed = ($checks | Where-Object { -not $_.Pass } | Measure-Object).Count -eq 0
    Write-Host ""
    if ($allPassed) {
        Write-Host "  OVERALL: RabbitMQ is fully operational. Application ready." -ForegroundColor Green
    } else {
        Write-Host "  OVERALL: Issues found. Recommended fix:" -ForegroundColor Red
        if (-not $erlOK -or -not $rabOK) {
            Write-Host "           .\RabbitMQ-Control.ps1 install" -ForegroundColor Yellow
        } elseif (-not $svcOK) {
            Write-Host "           .\RabbitMQ-Control.ps1 start" -ForegroundColor Yellow
        } elseif (-not $p2) {
            Write-Host "           .\RabbitMQ-Control.ps1 enable-ui" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# ── UNINSTALL ─────────────────────────────────────────────────────────────────
function Invoke-Uninstall {
    Assert-Admin
    Write-Step "Stopping RabbitMQ service if running..."
    Invoke-Stop

    Write-Step "Uninstalling RabbitMQ via winget..."
    winget uninstall --name "RabbitMQ" --silent 2>&1 | Out-Null

    Write-Step "Removing RabbitMQ files..."
    Remove-Item "C:\Program Files\RabbitMQ Server" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Step "Uninstalling Erlang OTP via winget..."
    winget uninstall $ERLANG_ID --silent 2>&1 | Out-Null

    Write-OK "RabbitMQ and Erlang have been removed."
    Write-Info "Run '.\RabbitMQ-Control.ps1 install' to reinstall."
}

# ==============================================================================
#  MAIN — entry point
# ==============================================================================
Write-Banner

# Default action (no param) = smart bootstrap: install if needed, then start
if ($Action -eq "start" -or $PSBoundParameters.Count -eq 0) {
    Assert-Admin

    # Auto-install if not present
    $justInstalled = $false
    if (-not (Test-ErlangInstalled) -or -not (Test-RabbitMQInstalled)) {
        Write-Warn "One or more dependencies missing. Running auto-install..."
        $justInstalled = Invoke-EnsureInstalled
        Write-Host ""
    }

    # Enable management UI after a fresh install automatically
    if ($justInstalled) {
        Write-Step "First-time setup: enabling Management UI plugin..."
        Invoke-EnableUI
    } else {
        Invoke-Start
    }

    Write-Host ""
    Invoke-Status
}

elseif ($Action -eq "install") {
    Assert-Admin
    Invoke-EnsureInstalled | Out-Null
    Write-Host ""
    Write-Step "Running first-time setup: enabling Management UI..."
    Invoke-EnableUI
    Write-Host ""
    Invoke-Status
}

elseif ($Action -eq "stop")      { Assert-Admin; Invoke-Stop    }
elseif ($Action -eq "restart")   { Assert-Admin; Invoke-Stop; Start-Sleep 2; Invoke-Start }
elseif ($Action -eq "status")    { Invoke-Status  }
elseif ($Action -eq "enable-ui") { Assert-Admin; Invoke-EnableUI }
elseif ($Action -eq "open-ui")   {
    if (Test-Port 15672) {
        Write-Step "Opening Management UI in browser..."
        Start-Process "http://localhost:15672"
    } else {
        Write-Err "Port 15672 not open. Start RabbitMQ first:"
        Write-Info ".\RabbitMQ-Control.ps1 start"
        Write-Info ".\RabbitMQ-Control.ps1 enable-ui"
    }
}
elseif ($Action -eq "check")     { Invoke-Check     }
elseif ($Action -eq "uninstall") { Invoke-Uninstall }
