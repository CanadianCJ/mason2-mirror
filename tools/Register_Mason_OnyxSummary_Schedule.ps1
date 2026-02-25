[CmdletBinding()]
param()

<#
    Register_Mason_OnyxSummary_Schedule.ps1

    Purpose:
      - Create/update a scheduled task that runs:
            Mason_Onyx_Health_Summary.ps1
        every 60 minutes.

    Task name (internal only, in Task Scheduler):
      \Mason2\Mason2-OnyxHealthSummary-1h

    This is 100% internal to Mason. Onyx users never see it.
#>

# Resolve Mason2 base path and summary script
$scriptDir    = Split-Path -Parent $PSCommandPath
$basePath     = Split-Path -Parent $scriptDir
$summaryScript = Join-Path (Join-Path $basePath "tools") "Mason_Onyx_Health_Summary.ps1"

if (-not (Test-Path $summaryScript)) {
    Write-Error "Mason_Onyx_Health_Summary.ps1 not found at: $summaryScript"
    exit 1
}

Write-Host "Summary script: $summaryScript" -ForegroundColor Cyan

# Task name (as it appears in Task Scheduler)
$taskName = "\Mason2\Mason2-OnyxHealthSummary-1h"

# Command to run (PowerShell)
$psCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$summaryScript`""

# Build schtasks arguments
$schtasksArgs = @(
    "/Create",
    "/TN", $taskName,
    "/SC", "HOURLY",
    "/MO", "1",
    "/TR", $psCmd,
    "/RL", "LIMITED",
    "/F"
)

Write-Host "Registering scheduled task $taskName..." -ForegroundColor Cyan
schtasks.exe @schtasksArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "schtasks.exe /Create failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "Task created/updated. Starting it once now..." -ForegroundColor Yellow
schtasks.exe /Run /TN $taskName | Out-Null

Write-Host "Done. Mason will now refresh Onyx health summary every hour." -ForegroundColor Green
