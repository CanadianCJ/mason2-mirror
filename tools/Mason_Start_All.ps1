# Mason_Start_All.ps1
# Launch the full Mason stack (core loops, self-improvement, UE loop, and app controllers)
$ErrorActionPreference = 'Stop'

# Figure out paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir   = Split-Path -Parent $scriptDir

Write-Host "[StartAll] RootDir = $rootDir"

# Resolve the Windows PowerShell executable (powershell.exe)
$psExe = (Get-Command 'powershell.exe').Source

function Start-MasonTool {
    param(
        [Parameter(Mandatory)] [string]$ScriptName,
        [string]$WindowTitle = $null
    )

    $path = Join-Path $scriptDir $ScriptName

    if (-not (Test-Path $path)) {
        Write-Warning "[StartAll] $ScriptName not found, skipping."
        return
    }

    $title = if ($WindowTitle) { $WindowTitle } else { $ScriptName }

    Write-Host "[StartAll] Launching $ScriptName ..."
    Start-Process $psExe -ArgumentList @(
        '-NoLogo',
        '-ExecutionPolicy', 'Bypass',
        '-File', "`"$path`""
    ) -WorkingDirectory $scriptDir -WindowStyle Normal
}

function Open-UrlIfSet {
    param([string]$Url)

    if ([string]::IsNullOrWhiteSpace($Url)) {
        return
    }

    Write-Host "[StartAll] Opening $Url ..."
    Start-Process $Url | Out-Null
}

# -----------------------------
# Core Mason runtime & health
# -----------------------------
Start-MasonTool -ScriptName 'Mason_AutoLoop.ps1'          -WindowTitle 'Mason AutoLoop'
Start-MasonTool -ScriptName 'Mason_Executor_Watcher.ps1'  -WindowTitle 'Mason Executor Watcher'
Start-MasonTool -ScriptName 'Mason_Watchdog.ps1'          -WindowTitle 'Mason Watchdog'
Start-MasonTool -ScriptName 'Mason_DiskGuard.ps1'         -WindowTitle 'Mason DiskGuard'
Start-MasonTool -ScriptName 'Mason_Health_Aggregator.ps1' -WindowTitle 'Mason Health Aggregator'
Start-MasonTool -ScriptName 'Mason_Learner.ps1'           -WindowTitle 'Mason Learner'
Start-MasonTool -ScriptName 'Mason_TaskGovernor.ps1'      -WindowTitle 'Mason Task Governor'

# -----------------------------
# Mason UE loop (user experience loop)
# -----------------------------
Start-MasonTool -ScriptName 'Mason_UE_Loop_Mason.ps1'     -WindowTitle 'Mason UE Loop'

# -----------------------------
# Onyx controller (business app)
# -----------------------------
Start-MasonTool -ScriptName 'Mason_Onyx_AutoLoop.ps1'     -WindowTitle 'Onyx AutoLoop'

# -----------------------------
# Mason self-improvement loop
# (Teacher + SelfOps + guardrails up to R2)
# -----------------------------
Start-MasonTool -ScriptName 'Mason_SelfImprove_Loop.ps1'  -WindowTitle 'Mason SelfImprove Loop'

# -----------------------------
# Athena controller (placeholder)
# This will only run once you actually have Mason_Athena_AutoLoop.ps1.
# -----------------------------
Start-MasonTool -ScriptName 'Mason_Athena_AutoLoop.ps1'   -WindowTitle 'Athena AutoLoop'

# -----------------------------
# Browser windows for Onyx / Athena UIs
# (Fill in the URLs you actually use)
# -----------------------------
# Example: $onyxUrl   = 'http://localhost:5173'
# Example: $athenaUrl = 'http://localhost:7000'

$onyxUrl   = ''   # TODO: put your real Onyx URL here
$athenaUrl = ''   # TODO: put your real Athena URL here

Open-UrlIfSet -Url $onyxUrl
Open-UrlIfSet -Url $athenaUrl

Write-Host "[StartAll] Mason stack launch complete. Child windows will keep running even if you close this one."
