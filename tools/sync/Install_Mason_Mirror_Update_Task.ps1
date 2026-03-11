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

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 10
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value ($Object | ConvertTo-Json -Depth $Depth) -Encoding UTF8
}

function Write-InstallFailure {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Phase,
        [Parameter(Mandatory = $true)][string]$ErrorMessage
    )
    $payload = [ordered]@{
        ok            = $false
        phase         = [string]$Phase
        error         = [string]$ErrorMessage
        timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    }
    try {
        Write-JsonFile -Path $Path -Object $payload -Depth 8
    }
    catch {
        # Best effort only.
    }
}

$phase = "init"
$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
if (-not (Test-Path -LiteralPath $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}
$mirrorUpdateLastPath = Join-Path $reportsDir "mirror_update_last.json"

$taskName = "Mason2 Mirror Update"
$scriptPath = Join-Path $repoRoot "tools\sync\Mason_Mirror_Update.ps1"
$stdoutLog = Join-Path $reportsDir "mirror_update_stdout.log"
$stderrLog = Join-Path $reportsDir "mirror_update_stderr.log"

try {
    $phase = "validate_paths"
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "Missing script: $scriptPath"
    }

    $phase = "build_action"
    $arguments = "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" -RootPath `"$repoRoot`" -Reason `"hourly`" 1>> `"$stdoutLog`" 2>> `"$stderrLog`""
    $actionParams = @{
        Execute     = "powershell.exe"
        Argument    = $arguments
        ErrorAction = "Stop"
    }
    $actionCmd = Get-Command New-ScheduledTaskAction -ErrorAction Stop
    if ($actionCmd.Parameters.ContainsKey("WorkingDirectory")) {
        $actionParams["WorkingDirectory"] = $repoRoot
    }
    $action = New-ScheduledTaskAction @actionParams

    $phase = "build_trigger"
    $anchor = (Get-Date).Date.AddMinutes(2)
    $trigger = New-ScheduledTaskTrigger -Daily -At $anchor -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration (New-TimeSpan -Days 3650) -ErrorAction Stop
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden -ErrorAction Stop

    $phase = "register_task"
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

    $phase = "read_task_info"
    $info = Get-ScheduledTaskInfo -TaskName $taskName -TaskPath $registered.task_path -ErrorAction Stop
    [pscustomobject]@{
        task_name     = ("{0}{1}" -f $registered.task_path, $taskName)
        task_path     = $registered.task_path
        run_level     = $registered.run_level
        script_path   = $scriptPath
        start_in      = $repoRoot
        stdout_log    = $stdoutLog
        stderr_log    = $stderrLog
        next_run_time = $info.NextRunTime
        last_run_time = $info.LastRunTime
    } | ConvertTo-Json -Depth 6
}
catch {
    Write-InstallFailure -Path $mirrorUpdateLastPath -Phase $phase -ErrorMessage $_.Exception.Message
    throw
}
