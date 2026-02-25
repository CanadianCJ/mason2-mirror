[CmdletBinding()]
param(
    [switch]$NoWatcher
)

$ErrorActionPreference = "Stop"

function Write-CoreStartLog {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Mason_Start_Core_NoApps] $Message"
}

function Start-CoreScript {
    param(
        [Parameter(Mandatory = $true)][string]$ToolsDir,
        [Parameter(Mandatory = $true)][string]$ScriptName
    )

    $path = Join-Path $ToolsDir $ScriptName
    if (-not (Test-Path -LiteralPath $path)) {
        Write-CoreStartLog "Missing script (skipped): $ScriptName"
        return $null
    }

    $proc = Start-Process powershell.exe -ArgumentList @(
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $path
    ) -WorkingDirectory $ToolsDir -WindowStyle Minimized -PassThru

    Write-CoreStartLog ("Started {0} (PID {1})" -f $ScriptName, $proc.Id)
    return $proc
}

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$base = Split-Path -Parent $toolsDir
$stateDir = Join-Path $base "state\knowledge"
$stackPidPath = Join-Path $stateDir "stack_pids.json"

New-Item -ItemType Directory -Path $stateDir -Force | Out-Null

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
    $proc = Start-CoreScript -ToolsDir $toolsDir -ScriptName $scriptName
    if ($proc) {
        $started.Add([pscustomobject]@{
            script = $scriptName
            pid    = [int]$proc.Id
        })
    }
}

$existing = @{}
if (Test-Path -LiteralPath $stackPidPath) {
    try {
        $parsed = Get-Content -LiteralPath $stackPidPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($p in $parsed.PSObject.Properties) {
            $existing[$p.Name] = $p.Value
        }
    }
    catch {
        $existing = @{}
    }
}

$existing["core_noapps_launched_at"] = (Get-Date).ToUniversalTime().ToString("o")
$existing["core_noapps_processes"] = @($started)

$existing | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $stackPidPath -Encoding UTF8

Write-CoreStartLog "Core launch complete."
Write-CoreStartLog "Updated PID state: $stackPidPath"
