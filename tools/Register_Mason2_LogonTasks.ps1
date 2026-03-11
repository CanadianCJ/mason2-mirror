<#
    Register_Mason2_LogonTasks.ps1

    Purpose:
      - Ensure the core Mason / Athena logon tasks exist under "\" (root path).
      - ONLY creates tasks that are missing.
      - Leaves existing tasks unchanged.

    Tasks covered (run as your user on logon):
      - Mason2-Startup           -> Athena_Launcher.ps1 (hidden)
      - Mason-DashboardUI        -> Mason-DashboardWindow.ps1 (normal)
      - Mason-VoiceShell         -> VoiceShell-Min.ps1 (hidden)
      - Mason-KillSwitchHotkey   -> KillSwitch-Hotkey.ps1 (hidden)
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$masonRoot = "C:\Users\Chris\Desktop\Mason2"
$toolsDir  = Join-Path $masonRoot "tools"
$logDir    = Join-Path $masonRoot "logs"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logFile   = Join-Path $logDir "register_mason2_logon_tasks.log"

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "s"
    $line = "[$ts] $Message"
    $line | Out-File -FilePath $logFile -Encoding UTF8 -Append
    Write-Host $line
}

Write-Log "=== Register_Mason2_LogonTasks.ps1 started ==="

# Principal: your user, interactive logon, highest available
$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType InteractiveToken `
    -RunLevel Highest

$commonSettings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable

# Helper: create logon task only if missing
function Ensure-LogonTask {
    param(
        [string]$TaskName,
        [string]$ScriptPath,
        [switch]$Hidden,
        [string]$Description = ""
    )

    $taskPath = "\"  # root

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

    $winStyle = $Hidden.IsPresent ? "-WindowStyle Hidden" : ""
    $psArgs   = "$winStyle -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"".Trim()

    $action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $psArgs
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

    # Clone base settings to tweak Hidden per task if needed
    $settings = $commonSettings.Clone()
    if ($Hidden) {
        $settings.Hidden = $true
    }

    Write-Log "Creating logon task: $taskPath$TaskName"
    Write-Log "  Script: $ScriptPath"

    try {
        Register-ScheduledTask `
            -TaskName $TaskName `
            -TaskPath $taskPath `
            -Action  $action `
            -Trigger $trigger `
            -Description $Description `
            -Principal $principal `
            -Settings $settings `
            -ErrorAction Stop | Out-Null

        Write-Log "  -> Created successfully."
    }
    catch {
        Write-Log "ERROR creating $taskPath$TaskName : $($_.Exception.Message)"
    }
}

# Script paths from your current setup
$athenaLauncher = Join-Path $masonRoot "Athena_Launcher.ps1"
$dashboardWin   = Join-Path $toolsDir  "status\Mason-DashboardWindow.ps1"
$voiceShell     = Join-Path $toolsDir  "voice\VoiceShell-Min.ps1"
$killSwitch     = Join-Path $toolsDir  "safety\KillSwitch-Hotkey.ps1"

# Mason2-Startup (hidden, background)
Ensure-LogonTask `
    -TaskName "Mason2-Startup" `
    -ScriptPath $athenaLauncher `
    -Hidden `
    -Description "Start Mason2 (Athena + background services) when Chris logs in."

# Dashboard window (visible)
Ensure-LogonTask `
    -TaskName "Mason-DashboardUI" `
    -ScriptPath $dashboardWin `
    -Description "Show Mason dashboard window on logon."

# Voice shell (hidden)
Ensure-LogonTask `
    -TaskName "Mason-VoiceShell" `
    -ScriptPath $voiceShell `
    -Hidden `
    -Description "Start Mason voice shell on logon."

# Kill switch hotkey (hidden)
Ensure-LogonTask `
    -TaskName "Mason-KillSwitchHotkey" `
    -ScriptPath $killSwitch `
    -Hidden `
    -Description "Start Mason kill-switch hotkey listener on logon."

Write-Log "=== Register_Mason2_LogonTasks.ps1 completed ==="

