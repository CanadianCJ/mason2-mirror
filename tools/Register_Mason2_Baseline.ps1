<#
    Register_Mason2_Baseline.ps1

    Purpose:
      - Ensure the core Mason2 background tasks exist under \Mason2\
      - ONLY creates tasks that are missing.
      - Leaves existing tasks unchanged.

    Tasks covered (all as SYSTEM, hidden, background only):
      - Mason2-ApplyStability-10m
      - Mason2-ApplyStability-NightlyWindow
      - Mason2-AthenaStatus-10m
      - Mason2-PCResource-10m
      - Mason2-StabilityPlanner-1h
      - Mason2-OnyxHealth-10m
      - Mason2-OnyxHealthSummary-1h
      - SyncChecklist
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Mason2 root + logs
$masonRoot = "C:\Users\Chris\Desktop\Mason2"
$toolsDir  = Join-Path $masonRoot "tools"
$logDir    = Join-Path $masonRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logFile   = Join-Path $logDir "register_mason2_baseline.log"

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "s"
    $line = "[$ts] $Message"
    $line | Out-File -FilePath $logFile -Encoding UTF8 -Append
    Write-Host $line
}

Write-Log "=== Register_Mason2_Baseline.ps1 started ==="

# Common settings: run hidden, don't stop on battery, etc.
$commonSettings = New-ScheduledTaskSettingsSet `
    -Hidden `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

# Helper: create a task only if missing
function Ensure-M2Task {
    param(
        [string]$TaskName,
        [string]$ScriptPath,
        $Trigger,
        [string]$Description = ""
    )

    $taskPath = "\Mason2\"

    # Check if it already exists
    $existing = $null
    try {
        $existing = Get-ScheduledTask -TaskName $TaskName -TaskPath $taskPath -ErrorAction Stop
    }
    catch {
        $existing = $null
    }

    if ($existing) {
        Write-Log "Task already exists, skipping: $taskPath$TaskName"
        return
    }

    if (-not (Test-Path $ScriptPath)) {
        Write-Log "WARNING: Script not found, skipping task $TaskName -> $ScriptPath"
        return
    }

    $psArgs = '-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "' + $ScriptPath + '"'
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psArgs

    Write-Log "Creating task: $taskPath$TaskName"
    Write-Log "  Script: $ScriptPath"

    try {
        # Run as SYSTEM (no password prompt, background-only)
        Register-ScheduledTask `
            -TaskName $TaskName `
            -TaskPath $taskPath `
            -Action $action `
            -Trigger $Trigger `
            -Settings $commonSettings `
            -Description $Description `
            -User "SYSTEM" `
            -RunLevel Highest `
            -ErrorAction Stop | Out-Null

        Write-Log "  -> Created successfully."
    }
    catch {
        Write-Log "ERROR creating $taskPath$TaskName : $($_.Exception.Message)"
    }
}

# -----------------------------------------------------------------
# Define script paths
# -----------------------------------------------------------------
$applyStability     = Join-Path $toolsDir "Apply_Mason_StabilityTasks.ps1"
$athenaStatus       = Join-Path $toolsDir "Athena_Status_Snapshot.ps1"
$pcResource         = Join-Path $toolsDir "PC_Resource_Monitor.ps1"
$stabilityPlanner   = Join-Path $toolsDir "Mason_StabilityPlanner.ps1"
$onyxHealth         = Join-Path $toolsDir "Mason_Onyx_Health_Watcher.ps1"
$onyxHealthSummary  = Join-Path $toolsDir "Mason_Onyx_Health_Summary.ps1"
$syncChecklist      = Join-Path $masonRoot "Phase1_SyncSignalsToChecklist_v3.ps1"

# -----------------------------------------------------------------
# Define triggers using built-in repetition parameters
# -----------------------------------------------------------------

# Every 10 minutes (starting ~1 minute from now)
$start10m   = (Get-Date).AddMinutes(1)
$trigger10m = New-ScheduledTaskTrigger `
    -Once `
    -At $start10m `
    -RepetitionInterval (New-TimeSpan -Minutes 10) `
    -RepetitionDuration (New-TimeSpan -Days 3650)

# Every 1 hour (starting ~5 minutes from now)
$start1h   = (Get-Date).AddMinutes(5)
$trigger1h = New-ScheduledTaskTrigger `
    -Once `
    -At $start1h `
    -RepetitionInterval (New-TimeSpan -Hours 1) `
    -RepetitionDuration (New-TimeSpan -Days 3650)

# Nightly at 03:30
$triggerNightly = New-ScheduledTaskTrigger -Daily -At 03:30

# SyncChecklist – every 10 minutes (starting ~2 minutes from now)
$startSync   = (Get-Date).AddMinutes(2)
$triggerSync = New-ScheduledTaskTrigger `
    -Once `
    -At $startSync `
    -RepetitionInterval (New-TimeSpan -Minutes 10) `
    -RepetitionDuration (New-TimeSpan -Days 3650)

# -----------------------------------------------------------------
# Ensure each core Mason2 background task exists
# -----------------------------------------------------------------

Ensure-M2Task `
    -TaskName "Mason2-ApplyStability-10m" `
    -ScriptPath $applyStability `
    -Trigger $trigger10m `
    -Description "Apply low-risk Mason2 stability tasks every 10 minutes."

Ensure-M2Task `
    -TaskName "Mason2-ApplyStability-NightlyWindow" `
    -ScriptPath $applyStability `
    -Trigger $triggerNightly `
    -Description "Nightly extra window to apply low-risk Mason2 stability tasks."

Ensure-M2Task `
    -TaskName "Mason2-AthenaStatus-10m" `
    -ScriptPath $athenaStatus `
    -Trigger $trigger10m `
    -Description "Capture Athena + Onyx status snapshots every 10 minutes."

Ensure-M2Task `
    -TaskName "Mason2-PCResource-10m" `
    -ScriptPath $pcResource `
    -Trigger $trigger10m `
    -Description "Monitor PC CPU/RAM every 10 minutes."

Ensure-M2Task `
    -TaskName "Mason2-StabilityPlanner-1h" `
    -ScriptPath $stabilityPlanner `
    -Trigger $trigger1h `
    -Description "Propose new Mason2 stability tasks every hour."

Ensure-M2Task `
    -TaskName "Mason2-OnyxHealth-10m" `
    -ScriptPath $onyxHealth `
    -Trigger $trigger10m `
    -Description "Check Onyx HTTP health every 10 minutes."

Ensure-M2Task `
    -TaskName "Mason2-OnyxHealthSummary-1h" `
    -ScriptPath $onyxHealthSummary `
    -Trigger $trigger1h `
    -Description "Summarize Onyx health logs every hour."

Ensure-M2Task `
    -TaskName "SyncChecklist" `
    -ScriptPath $syncChecklist `
    -Trigger $triggerSync `
    -Description "Sync Mason signals into checklist every 10 minutes."

Write-Log "=== Register_Mason2_Baseline.ps1 completed ==="
