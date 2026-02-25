[CmdletBinding()]
param()

<#
    Register_Mason_OnyxHealth_Schedule.ps1

    Uses schtasks.exe to create/update a scheduled task that runs:
      Mason_Onyx_Health_Watcher.ps1

    Every 10 minutes.

    Task name (internal only):
      \Mason2\Mason2-OnyxHealth-10m

    This is all invisible to Onyx users. Only you + Windows see it.
#>

# Resolve the health watcher script path
$scriptDir    = Split-Path -Parent $PSCommandPath
$healthScript = Join-Path $scriptDir "Mason_Onyx_Health_Watcher.ps1"

if (-not (Test-Path $healthScript)) {
    Write-Error "Mason_Onyx_Health_Watcher.ps1 not found at: $healthScript"
    exit 1
}

Write-Host "Health watcher script: $healthScript" -ForegroundColor Cyan

# Scheduled task name (shown only in Task Scheduler)
$taskName = "\Mason2\Mason2-OnyxHealth-10m"

# Command to run
$psCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$healthScript`""

# Build schtasks arguments
$schtasksArgs = @(
    "/Create",
    "/TN", $taskName,
    "/SC", "MINUTE",
    "/MO", "10",
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

Write-Host "Done. Mason will now check Onyx every 10 minutes." -ForegroundColor Green
