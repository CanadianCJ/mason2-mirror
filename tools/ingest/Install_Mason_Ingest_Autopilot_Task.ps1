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

$stdoutLog = Join-Path $reportsDir "ingest_autopilot_stdout.log"
$stderrLog = Join-Path $reportsDir "ingest_autopilot_stderr.log"
$scriptPath = Join-Path $repoRoot "tools\ingest\Mason_IngestDrop_Once.ps1"

if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Missing script: $scriptPath"
}

$taskName = "Mason2 Ingest Autopilot"
$command = "Set-Location -LiteralPath '{0}'; & '{1}' 1>> '{2}' 2>> '{3}'" -f $repoRoot, $scriptPath, $stdoutLog, $stderrLog
$arguments = "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command `"$command`""

try {
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $arguments -ErrorAction Stop
    $triggerLogon = New-ScheduledTaskTrigger -AtLogOn -ErrorAction Stop
    $triggerEvery5m = New-ScheduledTaskTrigger -Once -At ((Get-Date).Date.AddMinutes(1)) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650) -ErrorAction Stop
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
            -Trigger @($triggerLogon, $triggerEvery5m) `
            -Settings $settings `
            -Principal $principal `
            -Description "Mason2 ingest autopilot: scans drop/inbox, ingests, and queues pending LLM chunks when needed." `
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
    task_name      = ("{0}{1}" -f $registered.task_path, $taskName)
    task_path      = $registered.task_path
    run_level      = $registered.run_level
    script_path    = $scriptPath
    stdout_log     = $stdoutLog
    stderr_log     = $stderrLog
    next_run_time  = $info.NextRunTime
    last_run_time  = $info.LastRunTime
} | ConvertTo-Json -Depth 6
