#Requires -Version 5.1
<#
.SYNOPSIS
    Customer Support System - Prerequisites Checker and Auto-Installer
.DESCRIPTION
    Checks every tool, SDK, and runtime required to run the full application
    (5 x .NET 10 backend microservices + React/Vite frontend).
    For each missing item it attempts a silent install via winget or npm,
    then re-validates. A final report is printed at the end.

    Run from the repo root:
        .\Check-Prerequisites.ps1

    Report-only mode (no installs):
        .\Check-Prerequisites.ps1 -Fix:$false
.PARAMETER Fix
    When $true (default) the script will attempt to install any missing
    prerequisites automatically. Set to $false for a dry-run / audit only.
#>
param(
    [bool]$Fix = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# ============================================================
# Colour helpers
# ============================================================
function Write-Ok   ($msg) { Write-Host "  [OK]   $msg" -ForegroundColor Green  }
function Write-Fail ($msg) { Write-Host "  [MISS] $msg" -ForegroundColor Red    }
function Write-Warn ($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Info ($msg) { Write-Host "  [INFO] $msg" -ForegroundColor Cyan   }
function Write-Head ($msg) { Write-Host "`n$msg"        -ForegroundColor White  }

# ============================================================
# Result tracking
# ============================================================
$script:results = [System.Collections.Generic.List[PSCustomObject]]::new()

function Add-Result {
    param([string]$Name, [bool]$Passed, [string]$Note = '')
    $script:results.Add([PSCustomObject]@{
        Name   = $Name
        Passed = $Passed
        Note   = $Note
    })
}

# ============================================================
# Helper: try to install via winget
# ============================================================
function Install-Winget {
    param([string]$PackageId, [string]$Label)
    if (-not $Fix) {
        Write-Warn "Skipping install of $Label (re-run without -Fix:`$false to auto-install)"
        return $false
    }
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Fail "winget not found - please install $Label manually."
        return $false
    }
    Write-Info "Installing $Label via winget..."
    winget install --id $PackageId --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    # Refresh PATH in the current session
    $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' +
                [System.Environment]::GetEnvironmentVariable('Path','User')
    return $true
}

# ============================================================
# SECTION 1 - CORE RUNTIMES AND SDKS
# ============================================================
Write-Head '======================================================'
Write-Head ' SECTION 1 : Core Runtimes and SDKs'
Write-Head '======================================================'

# ----------------------------------------------------------
# 1a. .NET 10 SDK
# ----------------------------------------------------------
Write-Host "`n[1a] .NET SDK (need 10.x)" -ForegroundColor Cyan
$dotnetOk = $false
try {
    $sdks = (dotnet --list-sdks 2>$null) -join "`n"
    if ($sdks -match '10\.\d+\.\d+') {
        $ver = ($sdks | Select-String '10\.\d+\.\d+' | Select-Object -First 1).Matches[0].Value
        Write-Ok ".NET SDK $ver found"
        $dotnetOk = $true
    } else {
        Write-Fail ".NET 10 SDK not found (installed SDKs: $($sdks.Trim()))"
    }
} catch {
    Write-Fail "'dotnet' command not found"
}
if (-not $dotnetOk) {
    $installed = Install-Winget 'Microsoft.DotNet.SDK.10' '.NET 10 SDK'
    if ($installed) {
        $sdks = (dotnet --list-sdks 2>$null) -join "`n"
        $dotnetOk = $sdks -match '10\.\d+'
        if ($dotnetOk) { Write-Ok '.NET 10 SDK installed successfully' }
        else { Write-Fail '.NET 10 SDK install could not be verified - install manually from https://dotnet.microsoft.com/download' }
    }
}
Add-Result '.NET 10 SDK' $dotnetOk 'Required for all 5 backend microservices (TargetFramework=net10.0)'

# ----------------------------------------------------------
# 1b. ASP.NET Core Runtime 10.x
# ----------------------------------------------------------
Write-Host "`n[1b] ASP.NET Core Runtime (need 10.x)" -ForegroundColor Cyan
$aspnetOk = $false
try {
    $runtimes = (dotnet --list-runtimes 2>$null) -join "`n"
    if ($runtimes -match 'Microsoft\.AspNetCore\.App 10\.\d+') {
        Write-Ok "ASP.NET Core Runtime 10.x found"
        $aspnetOk = $true
    } else {
        # SDK bundles the runtime - treat as OK when SDK is present
        $aspnetOk = $dotnetOk
        if ($aspnetOk) { Write-Ok 'Bundled with .NET 10 SDK - OK' }
        else { Write-Warn 'ASP.NET Core Runtime 10.x not listed' }
    }
} catch {
    $aspnetOk = $dotnetOk
}
Add-Result 'ASP.NET Core Runtime 10.x' $aspnetOk 'Bundled with .NET 10 SDK install'

# ----------------------------------------------------------
# 1c. Node.js >= 20
# ----------------------------------------------------------
Write-Host "`n[1c] Node.js (need >= 20)" -ForegroundColor Cyan
$nodeOk = $false
try {
    $nodeVer = node --version 2>$null   # e.g. v22.3.0
    if ($nodeVer -match 'v(\d+)\.') {
        $major = [int]$Matches[1]
        if ($major -ge 20) {
            Write-Ok "Node.js $nodeVer found"
            $nodeOk = $true
        } else {
            Write-Fail "Node.js $nodeVer is too old (need >= 20)"
        }
    }
} catch {
    Write-Fail "'node' command not found"
}
if (-not $nodeOk) {
    $installed = Install-Winget 'OpenJS.NodeJS.LTS' 'Node.js LTS'
    if ($installed) {
        $nodeVer = node --version 2>$null
        if ($nodeVer -match 'v(\d+)\.' -and [int]$Matches[1] -ge 20) {
            Write-Ok "Node.js $nodeVer installed successfully"
            $nodeOk = $true
        } else {
            Write-Fail 'Node.js install could not be verified - install from https://nodejs.org'
        }
    }
}
Add-Result 'Node.js >= 20' $nodeOk 'Required for React/Vite frontend (npm run dev / build)'

# ----------------------------------------------------------
# 1d. npm >= 9
# ----------------------------------------------------------
Write-Host "`n[1d] npm (need >= 9)" -ForegroundColor Cyan
$npmOk = $false
try {
    $npmVer = npm --version 2>$null   # e.g. 10.2.4
    if ($npmVer -match '^(\d+)\.') {
        $major = [int]$Matches[1]
        if ($major -ge 9) {
            Write-Ok "npm $npmVer found"
            $npmOk = $true
        } else {
            Write-Warn "npm $npmVer is outdated - upgrading..."
            if ($Fix) {
                npm install -g npm@latest 2>&1 | Out-Null
                $npmVer = npm --version 2>$null
                $npmOk  = $npmVer -match '^(\d+)\.' -and [int]$Matches[1] -ge 9
                if ($npmOk) { Write-Ok "npm upgraded to $npmVer" }
            }
        }
    }
} catch {
    Write-Fail "'npm' command not found (install Node.js first)"
}
Add-Result 'npm >= 9' $npmOk 'Bundled with Node.js LTS'

# ============================================================
# SECTION 2 - .NET GLOBAL TOOLS
# ============================================================
Write-Head '======================================================'
Write-Head ' SECTION 2 : .NET Global Tools'
Write-Head '======================================================'

function Get-DotnetGlobalTools {
    try { return (dotnet tool list -g 2>$null) -join "`n" } catch { return '' }
}

# ----------------------------------------------------------
# 2a. dotnet-ef (EF Core CLI)
# ----------------------------------------------------------
Write-Host "`n[2a] dotnet-ef (EF Core CLI)" -ForegroundColor Cyan
$efOk = $false
$toolList = Get-DotnetGlobalTools
if ($toolList -match 'dotnet-ef') {
    $verMatch = [regex]::Match($toolList, 'dotnet-ef\s+(\S+)')
    $efVer = if ($verMatch.Success) { $verMatch.Groups[1].Value } else { '(version unknown)' }
    Write-Ok "dotnet-ef $efVer found"
    $efOk = $true
} else {
    Write-Fail 'dotnet-ef not installed'
    if ($Fix -and $dotnetOk) {
        Write-Info 'Installing dotnet-ef...'
        dotnet tool install --global dotnet-ef 2>&1 | Out-Null
        $toolList = Get-DotnetGlobalTools
        $efOk = $toolList -match 'dotnet-ef'
        if ($efOk) { Write-Ok 'dotnet-ef installed successfully' }
        else { Write-Fail 'dotnet-ef install failed - run: dotnet tool install --global dotnet-ef' }
    }
}
Add-Result 'dotnet-ef (EF Core CLI)' $efOk 'Used to create/run EF Core migrations'

# ============================================================
# SECTION 3 - INFRASTRUCTURE SERVICES
# ============================================================
Write-Head '======================================================'
Write-Head ' SECTION 3 : Infrastructure Services'
Write-Head '======================================================'

# ----------------------------------------------------------
# 3a. SQL Server on :1433
# ----------------------------------------------------------
Write-Host "`n[3a] SQL Server on localhost:1433" -ForegroundColor Cyan
$sqlOk = $false
$tcp = New-Object System.Net.Sockets.TcpClient
try {
    $tcp.Connect('localhost', 1433)
    if ($tcp.Connected) {
        Write-Ok 'SQL Server reachable on localhost:1433'
        $sqlOk = $true
    }
} catch {
    Write-Fail 'SQL Server NOT reachable on localhost:1433'
    Write-Info 'Resolution options:'
    Write-Info '  A) Install: winget install Microsoft.SQLServer.2022.Express'
    Write-Info '  B) Docker:  docker-compose up -d sqlserver'
    Write-Info '  C) Start service: Start-Service MSSQLSERVER  (or MSSQL$SQLEXPRESS)'
    if ($Fix) {
        $svc = Get-Service -Name 'MSSQLSERVER','MSSQL$SQLEXPRESS' -ErrorAction SilentlyContinue |
               Where-Object { $_.Status -ne 'Running' } |
               Select-Object -First 1
        if ($svc) {
            Write-Info "Starting service '$($svc.Name)'..."
            Start-Service $svc.Name -ErrorAction SilentlyContinue
            Start-Sleep 4
            $tcp2 = New-Object System.Net.Sockets.TcpClient
            try { $tcp2.Connect('localhost',1433); $sqlOk = $tcp2.Connected } catch {}
            $tcp2.Close()
            if ($sqlOk) { Write-Ok 'SQL Server started successfully' }
        }
    }
} finally {
    $tcp.Close()
}
Add-Result 'SQL Server :1433' $sqlOk 'Required: UserDB / TicketDB / ResponseDB / NotificationDB'

# ----------------------------------------------------------
# 3b. RabbitMQ on :5672
# ----------------------------------------------------------
Write-Host "`n[3b] RabbitMQ on localhost:5672" -ForegroundColor Cyan
$mqOk = $false
$tcp = New-Object System.Net.Sockets.TcpClient
try {
    $tcp.Connect('localhost', 5672)
    if ($tcp.Connected) {
        Write-Ok 'RabbitMQ reachable on localhost:5672'
        $mqOk = $true
    }
} catch {
    Write-Fail 'RabbitMQ NOT reachable on localhost:5672'
    Write-Info 'Resolution options:'
    Write-Info '  A) Install Erlang: winget install ErlangSolutions.Erlang'
    Write-Info '     Then RabbitMQ:  winget install RabbitMQ.RabbitMQ'
    Write-Info '  B) Docker:  docker-compose up -d rabbitmq'
    Write-Info '  C) Start:   Start-Service RabbitMQ'
    if ($Fix) {
        $svc = Get-Service -Name 'RabbitMQ' -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -ne 'Running') {
            Write-Info 'Starting RabbitMQ service...'
            Start-Service 'RabbitMQ' -ErrorAction SilentlyContinue
            Start-Sleep 5
            $tcp2 = New-Object System.Net.Sockets.TcpClient
            try { $tcp2.Connect('localhost',5672); $mqOk = $tcp2.Connected } catch {}
            $tcp2.Close()
            if ($mqOk) { Write-Ok 'RabbitMQ started successfully' }
        }
    }
} finally {
    $tcp.Close()
}
Add-Result 'RabbitMQ :5672' $mqOk 'Required by TicketService, ResponseService, NotificationService'

# ----------------------------------------------------------
# 3c. Docker Desktop (optional - for docker-compose mode)
# ----------------------------------------------------------
Write-Host "`n[3c] Docker Desktop (optional - for docker-compose mode)" -ForegroundColor Cyan
$dockerOk = $false
try {
    $dockerVer = docker --version 2>$null
    if ($dockerVer) {
        Write-Ok $dockerVer
        $info = docker info 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warn 'Docker daemon is not running - start Docker Desktop before using docker-compose'
        } else {
            Write-Ok 'Docker daemon is running'
            $dockerOk = $true
        }
    } else {
        Write-Warn 'Docker not found - only needed if running via docker-compose'
        Write-Info 'Install: winget install Docker.DockerDesktop'
    }
} catch {
    Write-Warn 'Docker not found (optional)'
}
Add-Result 'Docker Desktop' $dockerOk '(Optional) Only needed for docker-compose up mode'

# ============================================================
# SECTION 4 - FRONTEND DEPENDENCIES (React / Vite)
# ============================================================
Write-Head '======================================================'
Write-Head ' SECTION 4 : Frontend Dependencies (React / Vite)'
Write-Head '======================================================'

$root        = Split-Path -Parent $MyInvocation.MyCommand.Path
$frontendDir = Join-Path $root 'frontend'

# ----------------------------------------------------------
# 4a. node_modules present
# ----------------------------------------------------------
Write-Host "`n[4a] frontend/node_modules" -ForegroundColor Cyan
$nmOk = Test-Path (Join-Path $frontendDir 'node_modules')
if ($nmOk) {
    Write-Ok 'node_modules directory exists'
} else {
    Write-Fail 'node_modules not found'
    if ($Fix -and $nodeOk) {
        Write-Info 'Running npm install in frontend/...'
        Push-Location $frontendDir
        npm install 2>&1 | Select-Object -Last 5 | ForEach-Object { Write-Info $_ }
        Pop-Location
        $nmOk = Test-Path (Join-Path $frontendDir 'node_modules')
        if ($nmOk) { Write-Ok 'npm install completed successfully' }
        else       { Write-Fail 'npm install failed - check the output above' }
    }
}
Add-Result 'frontend/node_modules' $nmOk 'Run: cd frontend; npm install'

# ----------------------------------------------------------
# 4b. Key npm packages spot-check (all 20 from package.json)
# ----------------------------------------------------------
Write-Host "`n[4b] npm packages spot-check" -ForegroundColor Cyan

$packages = @(
    @{ name = 'react';                dir = 'react'                 }
    @{ name = 'react-dom';            dir = 'react-dom'             }
    @{ name = 'react-router-dom';     dir = 'react-router-dom'      }
    @{ name = 'vite';                 dir = 'vite'                  }
    @{ name = 'typescript';           dir = 'typescript'            }
    @{ name = '@vitejs/plugin-react'; dir = '@vitejs\plugin-react'  }
    @{ name = 'tailwindcss';          dir = 'tailwindcss'           }
    @{ name = '@tanstack/react-query';dir = '@tanstack\react-query' }
    @{ name = 'axios';                dir = 'axios'                 }
    @{ name = 'zustand';              dir = 'zustand'               }
    @{ name = 'zod';                  dir = 'zod'                   }
    @{ name = 'react-hook-form';      dir = 'react-hook-form'       }
    @{ name = '@hookform/resolvers';  dir = '@hookform\resolvers'   }
    @{ name = '@microsoft/signalr';   dir = '@microsoft\signalr'    }
    @{ name = 'recharts';             dir = 'recharts'              }
    @{ name = 'react-hot-toast';      dir = 'react-hot-toast'       }
    @{ name = 'date-fns';             dir = 'date-fns'              }
    @{ name = 'clsx';                 dir = 'clsx'                  }
    @{ name = 'postcss';              dir = 'postcss'               }
    @{ name = 'autoprefixer';         dir = 'autoprefixer'          }
)

$allNpmOk    = $true
$missingPkgs = @()

foreach ($pkg in $packages) {
    $pkgPath = Join-Path $frontendDir "node_modules\$($pkg.dir)"
    if (Test-Path $pkgPath) {
        Write-Ok $pkg.name
    } else {
        Write-Fail "$($pkg.name) - missing"
        $allNpmOk    = $false
        $missingPkgs += $pkg.name
    }
}

if (-not $allNpmOk -and $Fix -and $nodeOk) {
    Write-Info "Installing missing packages: $($missingPkgs -join ', ')"
    Push-Location $frontendDir
    npm install $missingPkgs 2>&1 | Select-Object -Last 5 | ForEach-Object { Write-Info $_ }
    Pop-Location
    # Re-validate
    $allNpmOk = $true
    foreach ($pkg in $packages) {
        $pkgPath = Join-Path $frontendDir "node_modules\$($pkg.dir)"
        if (-not (Test-Path $pkgPath)) { $allNpmOk = $false }
    }
    if ($allNpmOk) { Write-Ok 'All missing packages installed' }
}
Add-Result 'npm packages (20 checked)' $allNpmOk 'All deps from frontend/package.json'

# ----------------------------------------------------------
# 4c. TypeScript compiler (tsc)
# ----------------------------------------------------------
Write-Host "`n[4c] TypeScript compiler (tsc)" -ForegroundColor Cyan
$tscOk   = $false
$tscCmd  = Join-Path $frontendDir 'node_modules\.bin\tsc.cmd'
if (Test-Path $tscCmd) {
    $tscVer = & $tscCmd --version 2>$null
    Write-Ok "tsc $tscVer (local node_modules)"
    $tscOk = $true
} else {
    try {
        $tscVer = tsc --version 2>$null
        if ($tscVer -match 'TypeScript') {
            Write-Ok "tsc $tscVer (global)"
            $tscOk = $true
        } else {
            Write-Fail 'tsc not found - typescript package may be missing'
        }
    } catch {
        Write-Fail 'tsc not found'
    }
}
Add-Result 'TypeScript compiler (tsc)' $tscOk 'Part of devDependencies - bundled in node_modules/.bin/'

# ----------------------------------------------------------
# 4d. Vite CLI
# ----------------------------------------------------------
Write-Host "`n[4d] Vite CLI" -ForegroundColor Cyan
$viteOk  = $false
$viteCmd = Join-Path $frontendDir 'node_modules\.bin\vite.cmd'
if (Test-Path $viteCmd) {
    $viteVer = & $viteCmd --version 2>$null
    Write-Ok "vite $viteVer"
    $viteOk = $true
} else {
    Write-Fail 'vite not found in node_modules/.bin/'
}
Add-Result 'Vite CLI' $viteOk 'Used by npm run dev and npm run build'

# ============================================================
# SECTION 5 - BACKEND NUGET RESTORE AND BUILD
# ============================================================
Write-Head '======================================================'
Write-Head ' SECTION 5 : Backend NuGet Packages (dotnet restore + build)'
Write-Head '======================================================'

$slnPath = Join-Path $root 'backend\CustomerSupportSystem.sln'

if ($dotnetOk -and (Test-Path $slnPath)) {

    # 5a. dotnet restore
    Write-Host "`n[5a] dotnet restore" -ForegroundColor Cyan
    Write-Info "Restoring NuGet packages for $slnPath ..."
    $restoreOutput = dotnet restore $slnPath 2>&1
    $restoreOk     = $LASTEXITCODE -eq 0
    if ($restoreOk) {
        Write-Ok 'dotnet restore succeeded - all NuGet packages resolved'
    } else {
        Write-Fail 'dotnet restore reported errors:'
        $restoreOutput | Where-Object { $_ -match 'error' } |
            Select-Object -First 10 | ForEach-Object { Write-Warn "    $_" }
    }
    Add-Result 'NuGet restore' $restoreOk 'All 5 services + SharedKernel'

    # 5b. dotnet build smoke-test
    Write-Host "`n[5b] dotnet build smoke-test (Release, no-restore)" -ForegroundColor Cyan
    Write-Info 'Building solution in Release mode...'
    $buildOutput = dotnet build $slnPath -c Release --no-restore --nologo 2>&1
    $buildOk     = $LASTEXITCODE -eq 0
    if ($buildOk) {
        Write-Ok 'dotnet build succeeded - all projects compile cleanly'
    } else {
        Write-Fail 'dotnet build reported errors:'
        $buildOutput | Where-Object { $_ -match ' error ' } |
            Select-Object -First 10 | ForEach-Object { Write-Warn "    $_" }
    }
    Add-Result 'dotnet build (all services)' $buildOk 'Verifies NuGet packages and compilation'

} else {
    $reason = if (-not $dotnetOk) { '.NET 10 SDK not available' } else { 'solution file not found' }
    Write-Warn "[5] Skipping dotnet restore/build - $reason"
    Add-Result 'NuGet restore'               $false "Skipped: $reason"
    Add-Result 'dotnet build (all services)' $false "Skipped: $reason"
}

# ============================================================
# SECTION 6 - PORT AVAILABILITY
# ============================================================
Write-Head '======================================================'
Write-Head ' SECTION 6 : Required Port Availability'
Write-Head '======================================================'
Write-Info 'App ports should be FREE; infrastructure ports (1433, 5672) must be LISTENING.'

$ports = @(
    @{ port = 3000;  label = 'Frontend (Vite dev server)';         infra = $false }
    @{ port = 5000;  label = 'Gateway';                            infra = $false }
    @{ port = 5001;  label = 'TicketService';                      infra = $false }
    @{ port = 5002;  label = 'ResponseService';                    infra = $false }
    @{ port = 5003;  label = 'NotificationService / SignalR';      infra = $false }
    @{ port = 5004;  label = 'UserService';                        infra = $false }
    @{ port = 1433;  label = 'SQL Server';                         infra = $true  }
    @{ port = 5672;  label = 'RabbitMQ AMQP';                      infra = $true  }
    @{ port = 15672; label = 'RabbitMQ Management UI';             infra = $true  }
)

$allPortsOk = $true
$ipProps    = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
$listening  = $ipProps.GetActiveTcpListeners() | Select-Object -ExpandProperty Port

foreach ($p in $ports) {
    $inUse = $listening -contains $p.port
    if ($p.infra) {
        # Infrastructure: port must be listening
        if ($inUse) { Write-Ok "Port $($p.port) ($($p.label)) - listening [OK]" }
        else        { Write-Fail "Port $($p.port) ($($p.label)) - NOT listening (service may be down)" }
    } else {
        # App ports: must be free
        if ($inUse) {
            Write-Warn "Port $($p.port) ($($p.label)) - already in use (conflict risk)"
            $allPortsOk = $false
        } else {
            Write-Ok "Port $($p.port) ($($p.label)) - free"
        }
    }
}
Add-Result 'Application ports (3000,5000-5004 free)' $allPortsOk 'Ports must be free before launching services'

# ============================================================
# SECTION 7 - OPTIONAL / RECOMMENDED TOOLS
# ============================================================
Write-Head '======================================================'
Write-Head ' SECTION 7 : Optional / Recommended Tools'
Write-Head '======================================================'

# 7a. Git
Write-Host "`n[7a] Git" -ForegroundColor Cyan
try {
    $gitVer = git --version 2>$null
    if ($gitVer) { Write-Ok $gitVer }
    else         { Write-Warn 'git not found - install: winget install Git.Git' }
} catch { Write-Warn 'git not found' }

# 7b. winget
Write-Host "`n[7b] winget (Windows Package Manager)" -ForegroundColor Cyan
try {
    $wgVer = winget --version 2>$null
    if ($wgVer) { Write-Ok "winget $wgVer" }
    else        { Write-Warn 'winget not available - update Windows or install from the Microsoft Store' }
} catch { Write-Warn 'winget not available' }

# 7c. docker compose v2
Write-Host "`n[7c] docker compose (v2 plugin)" -ForegroundColor Cyan
try {
    $dcVer = docker compose version 2>$null
    if ($dcVer) { Write-Ok $dcVer }
    else        { Write-Warn 'docker compose v2 not found (bundled with Docker Desktop)' }
} catch { Write-Warn 'docker compose not found' }

# 7d. sqlcmd
Write-Host "`n[7d] sqlcmd (SQL Server command-line)" -ForegroundColor Cyan
$scFound = $false
try {
    $null = sqlcmd -? 2>&1
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1) {
        Write-Ok 'sqlcmd found'
        $scFound = $true
    }
} catch {}
if (-not $scFound) {
    Write-Warn 'sqlcmd not found - install: winget install Microsoft.SqlCmd'
    Write-Info 'Alternatively use SSMS to run database\CreateAllDatabases.sql'
}

# ============================================================
# FINAL REPORT
# ============================================================
Write-Host ''
Write-Host '======================================================' -ForegroundColor White
Write-Host '  FINAL REPORT' -ForegroundColor White
Write-Host '======================================================' -ForegroundColor White
Write-Host ''

$passed = @($script:results | Where-Object { $_.Passed })
$failed = @($script:results | Where-Object { -not $_.Passed })

foreach ($r in $script:results) {
    $icon   = if ($r.Passed) { '[PASS]' } else { '[FAIL]' }
    $colour = if ($r.Passed) { 'Green'  } else { 'Red'    }
    Write-Host ("  {0,-7} {1,-42} {2}" -f $icon, $r.Name, $r.Note) -ForegroundColor $colour
}

Write-Host ''
Write-Host ("  Passed : {0}/{1}" -f $passed.Count, $script:results.Count) -ForegroundColor Green

if ($failed.Count -gt 0) {
    Write-Host ("  Failed : {0}/{1}" -f $failed.Count, $script:results.Count) -ForegroundColor Red
    Write-Host ''
    Write-Host '  Next steps:' -ForegroundColor Yellow
    foreach ($f in $failed) {
        Write-Host "    * $($f.Name) -- $($f.Note)" -ForegroundColor Yellow
    }
} else {
    Write-Host ''
    Write-Host '  All prerequisites satisfied.' -ForegroundColor Green
    Write-Host '  Run .\Start-All.ps1 to launch the application.' -ForegroundColor Green
}

Write-Host ''
Write-Host '  Software download links:' -ForegroundColor Cyan
Write-Host '    .NET 10 SDK        https://dotnet.microsoft.com/download/dotnet/10.0'
Write-Host '    Node.js LTS        https://nodejs.org'
Write-Host '    SQL Server Express https://www.microsoft.com/en-us/sql-server/sql-server-downloads'
Write-Host '    RabbitMQ           https://www.rabbitmq.com/install-windows.html'
Write-Host '    Erlang/OTP         https://www.erlang.org/downloads  (RabbitMQ dependency)'
Write-Host '    Docker Desktop     https://www.docker.com/products/docker-desktop'
Write-Host '    SSMS               https://aka.ms/ssms'
Write-Host '    sqlcmd             https://aka.ms/sqlcmd'
Write-Host ''
