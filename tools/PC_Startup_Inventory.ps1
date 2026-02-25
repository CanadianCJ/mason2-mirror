<#
    PC_Startup_Inventory.ps1

    Purpose:
      - Read-only snapshot of:
          * Startup commands (Startup folder, registry Run keys, etc.)
          * Non-Microsoft scheduled tasks
      - Writes a JSON report Mason can read:
          C:\Users\Chris\Desktop\Mason2\reports\pc_startup_inventory.json

    NOTE:
      - This does NOT enable/disable or delete anything.
      - Safe to run anytime.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Resolve Mason2 root from script location
$masonTools = Split-Path -Parent $PSCommandPath
$masonRoot  = Split-Path -Parent $masonTools

$reportsDir = Join-Path $masonRoot 'reports'
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

$outFile = Join-Path $reportsDir 'pc_startup_inventory.json'

Write-Host "Collecting startup items and scheduled tasks..."

# 1) Startup commands (Startup folders + Run keys, etc.)
$startupCommands = Get-CimInstance Win32_StartupCommand |
    Select-Object Name, Command, Location, User, Caption

# 2) Non-Microsoft scheduled tasks (user-level + app stuff)
$allTasks = Get-ScheduledTask
$nonMsTasks = $allTasks | Where-Object {
    $_.TaskPath -notlike '\Microsoft*'
}

$taskInfo = $nonMsTasks | ForEach-Object {
    # Flatten actions/triggers for readability
    $actions = @()
    foreach ($a in $_.Actions) {
        $actions += ("{0} {1}" -f $a.Execute, $a.Arguments).Trim()
    }

    $triggers = @()
    foreach ($t in $_.Triggers) {
        $triggers += $t.ToString()
    }

    [PSCustomObject]@{
        TaskName   = $_.TaskName
        TaskPath   = $_.TaskPath
        State      = $_.State
        Description= $_.Description
        Actions    = $actions
        Triggers   = $triggers
    }
}

$result = [PSCustomObject]@{
    generated_at      = (Get-Date).ToString("s")
    computer_name     = $env:COMPUTERNAME
    startup_commands  = $startupCommands
    scheduled_tasks   = $taskInfo
}

$result | ConvertTo-Json -Depth 6 | Out-File -FilePath $outFile -Encoding UTF8

Write-Host "Startup inventory written to: $outFile"
