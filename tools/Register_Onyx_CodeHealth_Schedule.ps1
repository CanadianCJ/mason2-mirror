param(
    [string]$MasonBase = "C:\Users\Chris\Desktop\Mason2"
)

$ErrorActionPreference = "Stop"

Write-Host "[INFO] Registering scheduled task: \Mason2\Mason2-OnyxCodeHealth-Daily"

$scriptPath = Join-Path $MasonBase "tools\Onyx_Code_Health_Report.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Host "[ERROR] Onyx_Code_Health_Report.ps1 not found at $scriptPath" -ForegroundColor Red
    exit 1
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument (
    '-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "' + $scriptPath + '"'
)

# Run daily at 03:15
$trigger = New-ScheduledTaskTrigger -Daily -At 03:15

# Match the working SelfReview schedule (RunLevel = Limited)
$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Limited

$taskName = "Mason2-OnyxCodeHealth-Daily"
$taskPath = "\Mason2"

Register-ScheduledTask -TaskName $taskName `
    -TaskPath $taskPath `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Force | Out-Null

Write-Host "[INFO] Task \Mason2\Mason2-OnyxCodeHealth-Daily registered to run daily at 03:15."
Write-Host "[INFO] Command: powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
