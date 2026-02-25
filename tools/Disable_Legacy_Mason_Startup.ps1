<# 
    Disable_Legacy_Mason_Startup.ps1

    - Removes old Mason v1 shortcuts from your user Startup folder
    - Disables scheduled tasks that point to:
        * C:\Users\Chris\Desktop\Mason\
        * C:\Users\Chris\Desktop\Connectra\
        * C:\Connectra\

    It leaves:
        - Mason2 tasks (C:\Users\Chris\Desktop\Mason2\...)
        - Windows / vendor tasks (Edge, Google, NVIDIA, etc.)
#>

[CmdletBinding()]
param()

$base   = "C:\Users\Chris\Desktop\Mason2"
$logDir = Join-Path $base "logs"
$logPath = Join-Path $logDir "pc_startup_cleanup.log"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format "s"
    $line = "[$ts] $Message"
    Add-Content -Path $logPath -Value $line
    Write-Host $line
}

Write-Log "=== Disable_Legacy_Mason_Startup.ps1 started ==="

# ---------------------------------------------------------
# 1) Remove old Mason v1 shortcuts from Startup folder
# ---------------------------------------------------------
$startupPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"

# These are from your startup inventory JSON
$legacyShortcutNames = @(
    "Mason Paper Trading Engine.lnk",
    "Mason Signal Listener.lnk",
    "Mason StudyOrchestrator.lnk",
    "MasonWatchdog.lnk",
    "Mason_Governor.lnk",
    "Mason_SeedAPI.lnk",
    "Mason_SelfScan.lnk"
)

Write-Log "Cleaning legacy Mason shortcuts from: $startupPath"

foreach ($name in $legacyShortcutNames) {
    $full = Join-Path $startupPath $name
    if (Test-Path $full) {
        Write-Log "Removing legacy Startup shortcut: $full"
        try {
            Remove-Item -LiteralPath $full -ErrorAction Stop
        }
        catch {
            Write-Log "ERROR removing $full : $($_.Exception.Message)"
        }
    }
    else {
        Write-Log "Startup shortcut not present (ok): $full"
    }
}

# ---------------------------------------------------------
# 2) Disable scheduled tasks for old Mason / Connectra
# ---------------------------------------------------------

# Any scheduled task whose action points at these roots is considered legacy
$legacyRoots = @(
    "C:\Users\Chris\Desktop\Mason\",
    "C:\Users\Chris\Desktop\Connectra\",
    "C:\Connectra\"
)

Write-Log "Scanning scheduled tasks for legacy roots..."
$allTasks = Get-ScheduledTask | Where-Object { $_.State -ne "Disabled" }

$disabledCount = 0

foreach ($task in $allTasks) {
    $hasLegacy = $false

    foreach ($action in $task.Actions) {
        # Build a simple string representation of the action
        $actionString = ("{0} {1}" -f $action.Execute, $action.Arguments)

        foreach ($root in $legacyRoots) {
            if ($actionString -like "*$root*") {
                $hasLegacy = $true
                break
            }
        }

        if ($hasLegacy) { break }
    }

    if ($hasLegacy) {
        $fqName = "$($task.TaskPath)$($task.TaskName)"
        try {
            Write-Log "Disabling legacy scheduled task: $fqName"
            Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop | Out-Null
            $disabledCount++
        }
        catch {
            Write-Log "ERROR disabling $fqName : $($_.Exception.Message)"
        }
    }
}

Write-Log "Disabled legacy scheduled tasks: $disabledCount"
Write-Log "=== Completed Disable_Legacy_Mason_Startup.ps1 ==="
