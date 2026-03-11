[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $repoRoot) {
    $repoRoot = (Get-Location).Path
}

$logsDir = Join-Path $repoRoot 'logs'
New-Item -Path $logsDir -ItemType Directory -Force | Out-Null

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$transcriptPath = Join-Path $logsDir ("stop_stack_{0}.txt" -f $timestamp)
$stopScript = Join-Path $repoRoot 'tools\Stop_All.ps1'
if (-not (Test-Path -LiteralPath $stopScript)) {
    $legacyStopScript = Join-Path $repoRoot 'Stop_All.ps1'
    if (Test-Path -LiteralPath $legacyStopScript) {
        $stopScript = $legacyStopScript
    }
}
$pidStatePath = Join-Path $repoRoot 'state\knowledge\stack_pids.json'
$stopExit = 0

function Stop-TrackedProcessForce {
    param(
        [Parameter(Mandatory = $true)][int]$TargetPid,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ($TargetPid -le 0) {
        return
    }

    $process = Get-Process -Id $TargetPid -ErrorAction SilentlyContinue
    if (-not $process) {
        Write-Host "[Stop_Stack] $Label PID $TargetPid already stopped."
        return
    }

    try {
        Write-Host "[Stop_Stack] Forcing stop for $Label PID $TargetPid."
        Stop-Process -Id $TargetPid -Force -ErrorAction Stop
        Write-Host "[Stop_Stack] $Label PID $TargetPid stopped."
    }
    catch {
        Write-Warning "[Stop_Stack] Force stop failed for $Label PID ${TargetPid}: $($_.Exception.Message)"
    }
}

function Get-ListeningPortOwners {
    param([int[]]$Ports)

    $ownersByPort = @{}
    foreach ($port in $Ports) {
        $ownersByPort[$port] = [System.Collections.Generic.HashSet[int]]::new()
    }

    $usedMethod = $null
    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        try {
            $tcpConnections = Get-NetTCPConnection -State Listen -ErrorAction Stop | Where-Object {
                $Ports -contains [int]$_.LocalPort
            }

            foreach ($conn in $tcpConnections) {
                $port = [int]$conn.LocalPort
                $ownerPid = [int]$conn.OwningProcess
                if ($ownersByPort.ContainsKey($port) -and $ownerPid -gt 0) {
                    [void]$ownersByPort[$port].Add($ownerPid)
                }
            }
            $usedMethod = "Get-NetTCPConnection"
        }
        catch {
            Write-Warning "[Stop_Stack] Get-NetTCPConnection lookup failed: $($_.Exception.Message)"
        }
    }

    if (-not $usedMethod) {
        $lines = & netstat -ano -p tcp 2>$null
        foreach ($line in $lines) {
            if ($line -match '^\s*TCP\s+\S+:(\d+)\s+\S+\s+LISTENING\s+(\d+)\s*$') {
                $port = [int]$Matches[1]
                $ownerPid = [int]$Matches[2]
                if ($ownersByPort.ContainsKey($port) -and $ownerPid -gt 0) {
                    [void]$ownersByPort[$port].Add($ownerPid)
                }
            }
        }
        $usedMethod = "netstat -ano"
    }

    Write-Host "[Stop_Stack] Port owner lookup method: $usedMethod"
    return $ownersByPort
}

function Stop-ByListeningPorts {
    param([int[]]$Ports)

    $ownersByPort = Get-ListeningPortOwners -Ports $Ports
    foreach ($port in $Ports) {
        $ownerPids = @($ownersByPort[$port])
        if ($ownerPids.Count -eq 0) {
            Write-Host "[Stop_Stack] No listeners found on port $port."
            continue
        }

        foreach ($ownerPid in ($ownerPids | Sort-Object -Unique)) {
            Stop-TrackedProcessForce -TargetPid ([int]$ownerPid) -Label "port_$port"
        }
    }
}

Start-Transcript -Path $transcriptPath -Force | Out-Null
try {
    if (Test-Path -LiteralPath $stopScript) {
        Write-Host "[Stop_Stack] Launching $stopScript"
        & powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $stopScript
        if ($null -ne $LASTEXITCODE) {
            $stopExit = [int]$LASTEXITCODE
        }
    } else {
        Write-Warning "[Stop_Stack] Missing script: $stopScript"
        $stopExit = 1
    }

    if (Test-Path -LiteralPath $pidStatePath) {
        try {
            $pidStateRaw = Get-Content -LiteralPath $pidStatePath -Raw -ErrorAction Stop
            $pidState = $pidStateRaw | ConvertFrom-Json -ErrorAction Stop

            if ($pidState) {
                Write-Host "[Stop_Stack] Using PID registry: $pidStatePath"
                $pidKeys = @(
                    'mason_core_pid',
                    'self_improve_pid',
                    'core_launcher_pid',
                    'watcher_pid',
                    'bridge_pid',
                    'athena_pid',
                    'onyx_pid',
                    'mason_api_pid',
                    'seed_api_pid'
                )

                foreach ($key in $pidKeys) {
                    $rawPid = $pidState.$key
                    $parsedPid = 0
                    if ([int]::TryParse([string]$rawPid, [ref]$parsedPid) -and $parsedPid -gt 0) {
                        Stop-TrackedProcessForce -TargetPid $parsedPid -Label $key
                    } else {
                        Write-Host "[Stop_Stack] $key missing or invalid in PID registry."
                    }
                }
            }
        }
        catch {
            Write-Warning "[Stop_Stack] Could not read PID state file ${pidStatePath}: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "[Stop_Stack] PID registry not found: $pidStatePath"
    }

    Write-Host "[Stop_Stack] Running fallback stop by listening ports 8383, 8109, 8484, 8000, 5353."
    Stop-ByListeningPorts -Ports @(8383, 8109, 8484, 8000, 5353)
}
finally {
    Stop-Transcript | Out-Null
}

if ($stopExit -eq 0) {
    Write-Host "[Stop_Stack] Completed." -ForegroundColor Green
} else {
    Write-Warning "[Stop_Stack] Stop script exited with code $stopExit."
}

exit $stopExit
