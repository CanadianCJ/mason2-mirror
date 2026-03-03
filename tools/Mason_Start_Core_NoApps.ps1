[CmdletBinding()]
param(
    [switch]$NoWatcher
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-CoreStartLog {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Mason_Start_Core_NoApps] $Message"
}

function Start-CoreScript {
    param(
        [Parameter(Mandatory = $true)][string]$ToolsDir,
        [Parameter(Mandatory = $true)][string]$ScriptName,
        [Parameter(Mandatory = $true)][string]$StartReportsDir,
        [Parameter(Mandatory = $true)][string]$StartRunId
    )

    $path = Join-Path $ToolsDir $ScriptName
    if (-not (Test-Path -LiteralPath $path)) {
        Write-CoreStartLog "Missing script (skipped): $ScriptName"
        return $null
    }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeName = [regex]::Replace($ScriptName.ToLowerInvariant(), "[^a-z0-9._-]+", "_")
    $stdoutLog = Join-Path $StartReportsDir ("{0}_{1}_{2}_stdout.log" -f $StartRunId, $safeName, $stamp)
    $stderrLog = Join-Path $StartReportsDir ("{0}_{1}_{2}_stderr.log" -f $StartRunId, $safeName, $stamp)

    $proc = Start-Process powershell.exe -ArgumentList @(
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $path
    ) -WorkingDirectory $ToolsDir -WindowStyle Minimized -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog -PassThru

    Write-CoreStartLog ("Started {0} (PID {1}) -> stdout={2}; stderr={3}" -f $ScriptName, $proc.Id, $stdoutLog, $stderrLog)
    return $proc
}

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$base = Split-Path -Parent $toolsDir
$stateDir = Join-Path $base "state\knowledge"
$stackPidPath = Join-Path $stateDir "stack_pids.json"
$reportsDir = Join-Path $base "reports"
$startReportsDir = Join-Path $reportsDir "start"
$startRunId = if ($env:MASON_START_RUN_ID) { [string]$env:MASON_START_RUN_ID } else { (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss_fff") }

New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
New-Item -ItemType Directory -Path $startReportsDir -Force | Out-Null

Write-CoreStartLog "Starting core loops (no Athena/Onyx app launch)."

$coreScripts = @(
    "Mason_AutoLoop.ps1",
    "Mason_Watchdog.ps1",
    "Mason_DiskGuard.ps1",
    "Mason_Health_Aggregator.ps1",
    "Mason_Learner.ps1",
    "Mason_TaskGovernor.ps1",
    "Mason_UE_Loop_Mason.ps1",
    "Mason_SelfImprove_Loop.ps1"
)

if (-not $NoWatcher) {
    $coreScripts = @("Mason_Executor_Watcher.ps1") + $coreScripts
}

$started = New-Object System.Collections.Generic.List[object]
foreach ($scriptName in $coreScripts) {
    $proc = Start-CoreScript -ToolsDir $toolsDir -ScriptName $scriptName -StartReportsDir $startReportsDir -StartRunId $startRunId
    if ($proc) {
        $started.Add([pscustomobject]@{
            script = $scriptName
            pid    = [int]$proc.Id
        })
    }
}

$startedState = @(
    $started | ForEach-Object {
        [ordered]@{
            script = [string]$_.script
            pid    = [int]$_.pid
        }
    }
)

$existing = [ordered]@{}
if (Test-Path -LiteralPath $stackPidPath) {
    try {
        $parsed = Get-Content -LiteralPath $stackPidPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($parsed -is [System.Collections.IDictionary]) {
            foreach ($entry in $parsed.GetEnumerator()) {
                $existing[[string]$entry.Key] = $entry.Value
            }
        }
        elseif ($parsed) {
            foreach ($p in @($parsed.PSObject.Properties)) {
                $existing[$p.Name] = $p.Value
            }
        }
    }
    catch {
        $existing = [ordered]@{}
    }
}

$existing["core_noapps_launched_at"] = (Get-Date).ToUniversalTime().ToString("o")
$existing["core_noapps_processes"] = @($startedState)

try {
    $existing | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $stackPidPath -Encoding UTF8
    Write-CoreStartLog "Updated PID state: $stackPidPath"
}
catch {
    Write-CoreStartLog "WARN: Could not update PID state at $stackPidPath : $($_.Exception.Message)"
}

Write-CoreStartLog "Core launch complete."
