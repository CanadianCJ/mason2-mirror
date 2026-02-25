[CmdletBinding()]
param(
    [string]$TaskName = 'Mason2-KeepAlive-Stack',
    [string]$TaskPath = '\Mason2\',
    [switch]$StartNow
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logsDir = Join-Path $repoRoot 'logs'
if (-not (Test-Path -LiteralPath $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

$stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmmss')
$logPath = Join-Path $logsDir ("keepalive_task_install_{0}.log" -f $stamp)
$keepAliveScript = Join-Path $PSScriptRoot 'KeepAlive_Stack.ps1'

function Write-InstallLog {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = '[{0}] [{1}] {2}' -f (Get-Date).ToUniversalTime().ToString('o'), $Level, $Message
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
    Write-Host $line
}

Write-InstallLog -Message 'Install_KeepAliveTask started.'

if (-not (Test-Path -LiteralPath $keepAliveScript)) {
    Write-InstallLog -Level 'ERROR' -Message ("KeepAlive script not found: {0}" -f $keepAliveScript)
    exit 1
}

$actionArgs = '-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}" -RunOnce' -f $keepAliveScript
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $actionArgs
$logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$repeatTrigger = New-ScheduledTaskTrigger -Daily -At 12:00AM -RepetitionInterval (New-TimeSpan -Minutes 10) -RepetitionDuration (New-TimeSpan -Days 1)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
$settings.ExecutionTimeLimit = 'PT0S'
$principal = New-ScheduledTaskPrincipal -UserId ('{0}\{1}' -f $env:USERDOMAIN, $env:USERNAME) -LogonType InteractiveToken -RunLevel LeastPrivilege

$description = 'Runs KeepAlive_Stack at logon and every 10 minutes. KeepAlive performs smoke checks and restarts stack when unhealthy.'

Register-ScheduledTask `
    -TaskName $TaskName `
    -TaskPath $TaskPath `
    -Action $action `
    -Trigger @($logonTrigger, $repeatTrigger) `
    -Settings $settings `
    -Principal $principal `
    -Description $description `
    -Force | Out-Null

$taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -TaskPath $TaskPath

Write-InstallLog -Message ("Task registered: {0}{1}" -f $TaskPath, $TaskName)
Write-InstallLog -Message ("Action: powershell.exe {0}" -f $actionArgs)
Write-InstallLog -Message 'Triggers: AtLogOn + Daily(00:00) repeated every 10 minutes for 24h.'
Write-InstallLog -Message ("NextRunTime: {0}" -f $taskInfo.NextRunTime)
Write-InstallLog -Message ("LastRunTime: {0}" -f $taskInfo.LastRunTime)
Write-InstallLog -Message 'KeepAlive cadence: task runs every 10 minutes; script executes one cycle per run (-RunOnce).'

if ($StartNow) {
    Start-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
    Write-InstallLog -Message 'Task started immediately.'
}

Write-InstallLog -Message ("Install log path: {0}" -f $logPath)
exit 0
