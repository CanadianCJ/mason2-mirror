[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logsDir = Join-Path $repoRoot 'logs'
if (-not (Test-Path -LiteralPath $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

$timestampUtc = (Get-Date).ToUniversalTime()
$timestampFile = $timestampUtc.ToString('yyyyMMdd_HHmmss')
$logPath = Join-Path $logsDir ('codex_autopilot_task_install_{0}.log' -f $timestampFile)

function Write-InstallLog {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [string]$Level = 'INFO'
    )

    $stamp = (Get-Date).ToUniversalTime().ToString('o')
    $line = '[{0}] [{1}] {2}' -f $stamp, $Level.ToUpperInvariant(), $Message
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
    Write-Host $line
}

Write-InstallLog -Message 'Installing/updating Codex Autopilot scheduled task.'

$taskName = 'Mason2-Codex-Autopilot-Nightly'
$taskPath = '\Mason2\'
$scriptPath = 'C:\Users\Chris\Desktop\Mason2\tools\Codex_Autopilot_RunOnce.ps1'
$actionArgs = '-NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Chris\Desktop\Mason2\tools\Codex_Autopilot_RunOnce.ps1" -Mode proposal -MaxSteps 3'

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $actionArgs
$trigger = New-ScheduledTaskTrigger -Daily -At 3:30AM
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId ('{0}\{1}' -f $env:USERDOMAIN, $env:USERNAME) -LogonType InteractiveToken -RunLevel LeastPrivilege

$description = 'Runs Codex Autopilot in proposal mode nightly at 3:30 AM.'

Register-ScheduledTask `
    -TaskName $taskName `
    -TaskPath $taskPath `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description $description `
    -Force | Out-Null

$taskInfo = Get-ScheduledTaskInfo -TaskName $taskName -TaskPath $taskPath

Write-InstallLog -Message ('Task registered/updated: {0}{1}' -f $taskPath, $taskName)
Write-InstallLog -Message ('Action: powershell.exe {0}' -f $actionArgs)
Write-InstallLog -Message ('NextRunTime: {0}' -f $taskInfo.NextRunTime)
Write-InstallLog -Message ('LastRunTime: {0}' -f $taskInfo.LastRunTime)
Write-InstallLog -Message ('LogPath: {0}' -f $logPath)

exit 0
