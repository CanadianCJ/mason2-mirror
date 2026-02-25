<# 
    Fix_Mason2_Tasks_Hidden.ps1  (COM version)

    Purpose:
      - Find all scheduled tasks under \Mason2
      - Ensure they:
          * Have Settings.Hidden = $true
          * Use "-WindowStyle Hidden" when calling powershell.exe / pwsh.exe
      - Log all changes to logs\task_windowstyle_fix.log

    Run:
      - Open an elevated PowerShell (Run as administrator)
      - cd C:\Users\Chris\Desktop\Mason2\tools
      - .\Fix_Mason2_Tasks_Hidden.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Resolve Mason2 root based on this script location
$masonTools = Split-Path -Parent $PSCommandPath
$masonRoot  = Split-Path -Parent $masonTools

$logsDir = Join-Path $masonRoot 'logs'
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

$logFile = Join-Path $logsDir 'task_windowstyle_fix.log'

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[{0}] [{1}] {2}" -f $ts, $Level, $Message
    $line | Out-File -FilePath $logFile -Encoding UTF8 -Append
    Write-Host $line
}

Write-Log "=== Fix_Mason2_Tasks_Hidden (COM version) started ==="

try {
    # Use Task Scheduler COM API directly (supports Settings.Hidden)
    $service = New-Object -ComObject "Schedule.Service"
    $service.Connect()

    $folderPath = "\Mason2"
    $folder = $service.GetFolder($folderPath)

    $tasks = $folder.GetTasks(0)
    if (-not $tasks -or $tasks.Count -eq 0) {
        Write-Log "No tasks found under $folderPath. Nothing to do." "WARN"
        return
    }

    Write-Log ("Found {0} tasks under {1}" -f $tasks.Count, $folderPath)

    $totalChanged = 0

    foreach ($task in $tasks) {
        $name = $task.Name
        Write-Log ("Processing task {0}{1}" -f $folderPath, $name)

        $definition = $task.Definition
        $settings   = $definition.Settings

        $settingsChanged = $false
        $actionsChanged  = $false

        # 1) Ensure the task is hidden
        if (-not $settings.Hidden) {
            $settings.Hidden = $true
            $settingsChanged = $true
            Write-Log ("  -> Settings.Hidden set to true for {0}{1}" -f $folderPath, $name)
        }

        # 2) Ensure PowerShell exec actions use -WindowStyle Hidden
        foreach ($action in $definition.Actions) {
            # Type 0 = Exec action
            if ($action.Type -ne 0) { continue }

            $exe  = $action.Path
            $args = $action.Arguments

            if (-not $exe) { continue }

            $isPwsh = ($exe -like '*powershell.exe') -or ($exe -like '*pwsh.exe')
            if (-not $isPwsh) { continue }

            if ($args -notmatch '(?i)-WindowStyle\s+Hidden') {
                if ([string]::IsNullOrWhiteSpace($args)) {
                    $action.Arguments = '-WindowStyle Hidden'
                }
                else {
                    $action.Arguments = "-WindowStyle Hidden $args"
                }

                $actionsChanged = $true
                Write-Log ("  -> Added -WindowStyle Hidden to PowerShell action for {0}{1}" -f $folderPath, $name)
                Write-Log ("     New arguments: {0}" -f $action.Arguments)
            }
        }

        if ($settingsChanged -or $actionsChanged) {
            # Re-register the task with updated definition,
            # keeping the same principal/logon type.
            $logonType = $definition.Principal.LogonType
            $userId    = $definition.Principal.UserId

            # TASK_CREATE_OR_UPDATE = 6
            $folder.RegisterTaskDefinition(
                $name,
                $definition,
                6,
                $null,
                $null,
                $logonType,
                $null
            ) | Out-Null

            $totalChanged++
            Write-Log ("  -> Task {0}{1} re-registered with updated settings/actions" -f $folderPath, $name)
        }
        else {
            Write-Log ("  -> No changes needed for {0}{1}" -f $folderPath, $name)
        }
    }

    Write-Log ("=== Completed. {0} task(s) updated. ===" -f $totalChanged)
}
catch {
    Write-Log ("ERROR: {0}" -f $_.Exception.Message) "ERROR"
    throw
}
