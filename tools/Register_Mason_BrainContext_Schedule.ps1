param()

$ErrorActionPreference = "Stop"

$toolsPath = $PSScriptRoot
$basePath  = Split-Path $toolsPath -Parent

$taskName  = "Mason2-MasonBrainContext-Hourly"
$script    = Join-Path $toolsPath "Mason_Brain_Context_Builder.ps1"

if (-not (Test-Path $script)) {
    Write-Host "[ERROR] Mason_Brain_Context_Builder.ps1 not found at $script"
    exit 1
}

Write-Host "[INFO] Registering scheduled task (user-level): $taskName"

# Run every hour
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5)
$trigger.Repetition = New-ScheduledTaskTrigger -Once -At (Get-Date)
$trigger.Repetition.Interval = "PT1H"
$trigger.Repetition.Duration = "P1D"

$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$script`""

$task = New-ScheduledTask -Action $action -Trigger $trigger

try {
    Register-ScheduledTask -TaskName $taskName -InputObject $task -Force | Out-Null
    Write-Host "[INFO] Task $taskName registered to run hourly."
    Write-Host "[INFO] Command: powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$script`""
}
catch {
    Write-Host "[ERROR] Failed to register task: $($_.Exception.Message)"
    throw
}
