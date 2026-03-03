[CmdletBinding()]
param(
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param([string]$CandidateRoot)
    if ($CandidateRoot -and (Test-Path -LiteralPath $CandidateRoot)) {
        return (Resolve-Path -LiteralPath $CandidateRoot).Path
    }
    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
if (-not (Test-Path -LiteralPath $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

$scriptPath = Join-Path $repoRoot "tools\sync\Mason_Mirror_Update.ps1"
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Missing script: $scriptPath"
}

$stdoutLog = Join-Path $reportsDir "mirror_update_stdout.log"
$stderrLog = Join-Path $reportsDir "mirror_update_stderr.log"

$taskName = "Mason2 Mirror Update"
$command = "Set-Location -LiteralPath '{0}'; & '{1}' -RootPath '{0}' -Reason 'hourly' 1>> '{2}' 2>> '{3}'" -f $repoRoot, $scriptPath, $stdoutLog, $stderrLog
$arguments = "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command `"$command`""

try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments -ErrorAction Stop
    $trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).Date.AddMinutes(2)) -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 3650) -ErrorAction Stop
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden -ErrorAction Stop
}
catch {
    throw ("Unable to initialize scheduled task definitions for '{0}': {1}" -f $taskName, $_.Exception.Message)
}
$userId = "{0}\{1}" -f $env:USERDOMAIN, $env:USERNAME
$attempts = @(
    [pscustomobject]@{ task_path = "\Mason2\"; run_level = "Highest" },
    [pscustomobject]@{ task_path = "\Mason2\"; run_level = "Limited" },
    [pscustomobject]@{ task_path = "\"; run_level = "Limited" }
)

$registered = $null
$attemptErrors = New-Object System.Collections.Generic.List[string]
foreach ($attempt in $attempts) {
    $taskPath = [string]$attempt.task_path
    $runLevel = [string]$attempt.run_level
    try {
        $principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel $runLevel -ErrorAction Stop
        Register-ScheduledTask `
            -TaskName $taskName `
            -TaskPath $taskPath `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Principal $principal `
            -Description "Hourly Mason2 mirror update with secret gate and sanitized knowledge pack export." `
            -ErrorAction Stop `
            -Force | Out-Null

        $registered = [ordered]@{
            task_path = $taskPath
            run_level = $runLevel
        }
        break
    }
    catch {
        $attemptErrors.Add(("path={0};run_level={1};error={2}" -f $taskPath, $runLevel, $_.Exception.Message)) | Out-Null
    }
}

if (-not $registered) {
    throw ("Unable to register scheduled task '{0}'. Attempts: {1}" -f $taskName, ($attemptErrors -join " | "))
}

$info = Get-ScheduledTaskInfo -TaskName $taskName -TaskPath $registered.task_path -ErrorAction Stop
[pscustomobject]@{
    task_name     = ("{0}{1}" -f $registered.task_path, $taskName)
    task_path     = $registered.task_path
    run_level     = $registered.run_level
    script_path   = $scriptPath
    stdout_log    = $stdoutLog
    stderr_log    = $stderrLog
    next_run_time = $info.NextRunTime
    last_run_time = $info.LastRunTime
} | ConvertTo-Json -Depth 6
