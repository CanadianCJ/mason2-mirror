param()

$ErrorActionPreference = "Stop"

$toolsPath = $PSScriptRoot
$basePath  = Split-Path $toolsPath -Parent

# Simple task name with no custom folder to avoid permission issues
$taskName  = "Mason2-MasonSelfReview-Daily"
$script    = Join-Path $toolsPath "Mason_SelfReview_Report.ps1"

if (-not (Test-Path $script)) {
    Write-Host "[ERROR] Mason_SelfReview_Report.ps1 not found at $script"
    exit 1
}

Write-Host "[INFO] Registering scheduled task (user-level): $taskName"

# Run daily at 03:05
$time    = "03:05"
$trigger = New-ScheduledTaskTrigger -Daily -At $time

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$script`""

# No explicit principal: use current user context to avoid access denied
$task = New-ScheduledTask -Action $action -Trigger $trigger

try {
    Register-ScheduledTask -TaskName $taskName -InputObject $task -Force | Out-Null
    Write-Host "[INFO] Task $taskName registered to run daily at $time."
    Write-Host "[INFO] Command: powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$script`""
}
catch {
    Write-Host "[ERROR] Failed to register task: $($_.Exception.Message)"
    throw
}
