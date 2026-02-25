<#
    Register_Mason_Forensics_Cleanup_Schedule.ps1

    Purpose:
      - Create a weekly Mason2 forensics cleanup task under \Mason2\
      - Task name: Mason2-Forensics-Cleanup-Weekly
      - Runs as SYSTEM at 03:10 every Sunday (adjust if you like)
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$masonRoot   = "C:\Users\Chris\Desktop\Mason2"
$toolsDir    = Join-Path $masonRoot "tools"
$logDir      = Join-Path $masonRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logFile     = Join-Path $logDir "register_mason_forensics_cleanup.log"

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "s"
    $line = "[$ts] $Message"
    $line | Out-File -FilePath $logFile -Encoding UTF8 -Append
    Write-Host $line
}

Write-Log "=== Register_Mason_Forensics_Cleanup_Schedule.ps1 started ==="

$taskName = "Mason2-Forensics-Cleanup-Weekly"
$taskPath = "\Mason2\"

# Check if it already exists
$existing = $null
try {
    $existing = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction Stop
}
catch {
    $existing = $null
}

if ($existing) {
    Write-Log "Task already exists, skipping: $taskPath$taskName"
    Write-Log "=== Completed (no changes) ==="
    return
}

$cleanupScript = Join-Path $toolsDir "Mason_Forensics_Cleanup.ps1"

if (-not (Test-Path $cleanupScript)) {
    Write-Log "ERROR: Cleanup script not found at $cleanupScript"
    throw "Mason_Forensics_Cleanup.ps1 not found."
}

$psArgs = '-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "' + $cleanupScript + '"'
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psArgs

# Every Sunday at 03:10
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 03:10

$settings = New-ScheduledTaskSettingsSet `
    -Hidden `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

Write-Log "Creating task: $taskPath$taskName"
Write-Log "  Script: $cleanupScript"

try {
    Register-ScheduledTask `
        -TaskName $taskName `
        -TaskPath $taskPath `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Description "Weekly Mason2 forensics/dumps cleanup." `
        -User "SYSTEM" `
        -RunLevel Highest `
        -ErrorAction Stop | Out-Null

    Write-Log "  -> Created successfully."
    Write-Log "=== Completed successfully ==="
}
catch {
    Write-Log "ERROR creating $taskPath$taskName : $($_.Exception.Message)"
    throw
}
