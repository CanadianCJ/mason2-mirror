[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-LauncherMessage {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [string]$Level = 'INFO'
    )

    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$stamp] [Start_Mason_FullStack] [$Level] $Message"
}

function Get-LastExitCodeSafe {
    $exitVar = Get-Variable -Name LASTEXITCODE -Scope Global -ErrorAction SilentlyContinue
    if ($null -ne $exitVar) {
        return [int]$exitVar.Value
    }
    return $null
}

function Read-JsonSafe {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if (-not $raw.Trim()) {
            return $null
        }
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $null
    }
}

function Get-ExpectedPorts {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)
    $defaults = @(8383, 8109, 8484, 8000, 5353)
    $portsPath = Join-Path $RepoRoot 'config\ports.json'
    $cfg = Read-JsonSafe -Path $portsPath
    if (-not $cfg -or -not ($cfg.PSObject.Properties.Name -contains 'ports') -or -not $cfg.ports) {
        return $defaults
    }

    $found = New-Object System.Collections.Generic.List[int]
    foreach ($name in @('mason_api', 'seed_api', 'bridge', 'athena', 'onyx')) {
        if ($cfg.ports.PSObject.Properties.Name -contains $name) {
            $tmp = 0
            if ([int]::TryParse([string]$cfg.ports.$name, [ref]$tmp) -and $tmp -gt 0 -and $tmp -le 65535) {
                if (-not $found.Contains($tmp)) {
                    $found.Add($tmp) | Out-Null
                }
            }
        }
    }
    if ($found.Count -eq 0) {
        return $defaults
    }
    return @($found.ToArray())
}

function Get-PortListenersSnapshot {
    param([int[]]$Ports)
    $rows = @()
    foreach ($port in @($Ports | Sort-Object -Unique)) {
        $listeners = @()
        try {
            $netRows = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
            foreach ($row in @($netRows)) {
                $listeners += [pscustomobject]@{
                    local_address = [string]$row.LocalAddress
                    owning_pid    = [int]$row.OwningProcess
                }
            }
        }
        catch {
            $listeners = @()
        }
        $rows += [pscustomobject]@{
            port           = [int]$port
            listener_count = @($listeners).Count
            listeners      = @($listeners)
        }
    }
    return @($rows)
}

function Write-LauncherMarker {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$StartedAt,
        [string]$FinishedAt,
        [bool]$Success = $false,
        [Parameter(Mandatory = $true)][string]$LogPath,
        [string]$ErrorSummary,
        [int]$ExitCode = 0,
        $PortsListening = $null,
        $Pids = $null
    )

    $marker = [ordered]@{
        started_at      = $StartedAt
        finished_at     = $FinishedAt
        success         = [bool]$Success
        log_path        = $LogPath
        error_summary   = $ErrorSummary
        exit_code       = [int]$ExitCode
        ports_listening = $PortsListening
        pids            = $Pids
    }
    $marker | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptDir '..\..'))
Set-Location -LiteralPath $repoRoot

$launcherDir = Join-Path $repoRoot 'reports\launcher'
New-Item -ItemType Directory -Path $launcherDir -Force | Out-Null

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logPath = Join-Path $launcherDir ("fullstack_{0}.log" -f $timestamp)
$markerPath = Join-Path $launcherDir 'last_fullstack.json'
$startedAt = (Get-Date).ToUniversalTime().ToString('o')
Write-LauncherMarker -Path $markerPath -StartedAt $startedAt -FinishedAt $null -Success $false -LogPath $logPath -ErrorSummary "in_progress" -ExitCode 0

$success = $false
$errorSummary = $null
$exitCode = 0
$transcriptStarted = $false

try {
    Start-Transcript -Path $logPath -Force | Out-Null
    $transcriptStarted = $true

    Write-LauncherMessage "Repo root: $repoRoot"
    Write-LauncherMessage 'Invoking Start_Mason2.ps1 -FullStack'

    & (Join-Path $repoRoot 'Start_Mason2.ps1') -FullStack

    $lastExit = Get-LastExitCodeSafe
    if ($null -ne $lastExit) {
        $exitCode = [int]$lastExit
    }
    if ($exitCode -ne 0) {
        throw "Start_Mason2.ps1 returned non-zero exit code: $exitCode"
    }

    $success = $true
    Write-LauncherMessage 'Start_Mason2.ps1 completed.'
}
catch {
    $errorSummary = $_.Exception.Message
    $lastExit = Get-LastExitCodeSafe
    if ($null -ne $lastExit -and [int]$lastExit -ne 0) {
        $exitCode = [int]$lastExit
    }
    elseif ($exitCode -eq 0) {
        $exitCode = 1
    }

    $errorStamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $errorLine = "[{0}] [Start_Mason_FullStack] [ERROR] ExitCode={1}; Exception={2}" -f $errorStamp, $exitCode, $errorSummary
    if ($transcriptStarted) {
        Write-Host $errorLine
    }
    else {
        try {
            Add-Content -LiteralPath $logPath -Value $errorLine -Encoding UTF8
        }
        catch {
            # Best effort log write when transcript is unavailable.
        }
    }

    Write-Host "Start Mason FullStack failed. See log: $logPath"
    Write-Host "Error summary: $errorSummary"
}
finally {
    $lastFailure = $null
    $lastFailurePath = Join-Path $repoRoot 'reports\start\last_failure.json'
    if (-not $success -and (Test-Path -LiteralPath $lastFailurePath)) {
        $lastFailure = Read-JsonSafe -Path $lastFailurePath
        if ($lastFailure) {
            $failureLine = "last_failure.json -> component={0}; exit_code={1}; stderr_path={2}; hint={3}" -f `
                [string]$lastFailure.component, `
                [string]$lastFailure.exit_code, `
                [string]$lastFailure.stderr_path, `
                [string]$lastFailure.hint
            Write-LauncherMessage $failureLine "ERROR"
            if ($errorSummary) {
                $errorSummary = ("{0} | {1}" -f $errorSummary, $failureLine)
            }
            else {
                $errorSummary = $failureLine
            }
        }
    }

    $portList = Get-ExpectedPorts -RepoRoot $repoRoot
    $portsListening = Get-PortListenersSnapshot -Ports $portList
    $stackPidsPath = Join-Path $repoRoot 'state\knowledge\stack_pids.json'
    $stackPids = Read-JsonSafe -Path $stackPidsPath
    Write-LauncherMarker -Path $markerPath -StartedAt $startedAt -FinishedAt (Get-Date).ToUniversalTime().ToString('o') -Success $success -LogPath $logPath -ErrorSummary $errorSummary -ExitCode $exitCode -PortsListening $portsListening -Pids $stackPids

    if ($transcriptStarted) {
        try {
            Stop-Transcript | Out-Null
        }
        catch {
            # Ignore transcript shutdown issues; marker has already been written.
        }
    }

    if (-not $success) {
        [System.Environment]::ExitCode = [int]$exitCode
    }
}
