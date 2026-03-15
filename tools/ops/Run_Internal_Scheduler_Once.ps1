[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string[]]$TaskIds = @(),
    [switch]$ForceRun,
    [switch]$AllowHostPrimary,
    [string]$TriggerSource = "manual"
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

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Read-JsonSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        $Default = $null
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $Default
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $Default
        }
        return ($raw | ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        return $Default
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 18
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        Ensure-Directory -Path $parent
    }
    $Object | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function To-Array {
    param($Value)

    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return @($Value) }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        return @($Value)
    }
    return @($Value)
}

function Get-PropValue {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Default = $null
    )

    if ($null -eq $Object) { return $Default }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $Default
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($property) { return $property.Value }
    return $Default
}

function Normalize-Text {
    param($Value)
    if ($null -eq $Value) { return "" }
    return ([string]$Value).Trim()
}

function Convert-ToBool {
    param($Value)

    if ($Value -is [bool]) { return $Value }
    $text = Normalize-Text $Value
    if (-not $text) { return $false }
    return ($text.ToLowerInvariant() -in @("true", "1", "yes", "y", "on"))
}

function Convert-ToUtcIso {
    param($Value)

    if ($null -eq $Value) { return "" }
    try { return ([datetime]$Value).ToUniversalTime().ToString("o") } catch { return "" }
}

function Invoke-Script {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string[]]$Arguments = @()
    )

    $output = @(& powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $Path @Arguments 2>&1 | ForEach-Object { [string]$_ })
    $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
    return [pscustomobject]@{
        ok = ($exitCode -eq 0)
        exit_code = $exitCode
        output = @($output | Select-Object -Last 40)
        command_run = ("powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}{1}" -f $Path, $(if (@($Arguments).Count -gt 0) { " " + (@($Arguments) -join " ") } else { "" }))
    }
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$configDir = Join-Path $repoRoot "config"
$reportsDir = Join-Path $repoRoot "reports"
$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"

$policyPath = Join-Path $configDir "internal_scheduler_policy.json"
$registryPath = Join-Path $stateKnowledgeDir "internal_scheduler_registry.json"
$historyPath = Join-Path $stateKnowledgeDir "internal_scheduler_history.json"
$executionPath = Join-Path $reportsDir "internal_scheduler_execution_last.json"

$policy = Read-JsonSafe -Path $policyPath -Default @{}
if (-not $policy) {
    throw "internal_scheduler_policy.json is missing or unreadable at $policyPath"
}

$historyPolicy = Get-PropValue -Object $policy -Name "history" -Default @{}
$maxEntriesPerTask = [int](Get-PropValue -Object $historyPolicy -Name "max_entries_per_task" -Default 25)
$maxRunRecords = [int](Get-PropValue -Object $historyPolicy -Name "max_run_records" -Default 60)

$registry = Read-JsonSafe -Path $registryPath -Default @{}
$historyState = Read-JsonSafe -Path $historyPath -Default @{ run_records = @() }

$priorTasksById = @{}
foreach ($task in @(To-Array (Get-PropValue -Object $registry -Name "tasks" -Default @()))) {
    $taskId = Normalize-Text (Get-PropValue -Object $task -Name "task_id" -Default "")
    if ($taskId) {
        $priorTasksById[$taskId] = $task
    }
}

$tasks = @(To-Array (Get-PropValue -Object $policy -Name "foundation_tasks" -Default @()))
$nowUtc = (Get-Date).ToUniversalTime()
$selectedTaskIds = @($TaskIds | ForEach-Object { Normalize-Text $_ } | Where-Object { $_ })

$runRecords = New-Object System.Collections.Generic.List[object]
$updatedRegistryTasks = New-Object System.Collections.Generic.List[object]
$executedCount = 0
$successCount = 0
$warningCount = 0
$skippedCount = 0

foreach ($task in $tasks) {
    $taskId = Normalize-Text (Get-PropValue -Object $task -Name "task_id" -Default "")
    if (-not $taskId) { continue }
    if (@($selectedTaskIds).Count -gt 0 -and $selectedTaskIds -notcontains $taskId) { continue }

    $prior = if ($priorTasksById.ContainsKey($taskId)) { $priorTasksById[$taskId] } else { $null }
    $enabled = Convert-ToBool (Get-PropValue -Object $task -Name "enabled" -Default $false)
    $scheduleOwner = Normalize-Text (Get-PropValue -Object $task -Name "schedule_owner" -Default "internal_primary")
    $cadenceMinutes = [int](Get-PropValue -Object $task -Name "cadence_minutes" -Default 0)
    $scriptRelPath = Normalize-Text (Get-PropValue -Object $task -Name "script_rel_path" -Default "")
    $scriptPath = if ($scriptRelPath) { Join-Path $repoRoot $scriptRelPath } else { "" }
    $auditArtifactRel = Normalize-Text (Get-PropValue -Object $task -Name "audit_artifact" -Default "")
    $auditArtifactPath = if ($auditArtifactRel) { Join-Path $repoRoot $auditArtifactRel } else { "" }
    $executionArguments = @((To-Array (Get-PropValue -Object $task -Name "execution_arguments" -Default @())) | ForEach-Object { [string]$_ })
    $hostTaskName = Normalize-Text (Get-PropValue -Object $task -Name "host_task_name" -Default "")
    $lastRunUtc = Normalize-Text (Get-PropValue -Object $prior -Name "last_run_utc" -Default "")
    $nextRunUtc = Normalize-Text (Get-PropValue -Object $prior -Name "next_run_utc" -Default "")

    $isDue = $ForceRun.IsPresent
    if (-not $isDue) {
        if (-not $lastRunUtc) {
            $isDue = $true
        }
        else {
            try {
                $dueAt = ([datetime]$lastRunUtc).ToUniversalTime().AddMinutes([Math]::Max(1, $cadenceMinutes))
                $isDue = ($nowUtc -ge $dueAt)
            }
            catch {
                $isDue = $true
            }
        }
    }

    $runStatus = "skipped"
    $runDetail = ""
    $exitCode = $null
    $artifactFresh = $false
    $commandRun = ""
    $outputLines = @()

    if (-not $enabled) {
        $runDetail = "task disabled"
        $skippedCount++
    }
    elseif ($scheduleOwner -ne "internal_primary" -and -not $AllowHostPrimary.IsPresent) {
        $runDetail = ("schedule_owner={0}" -f $(if ($scheduleOwner) { $scheduleOwner } else { "unknown" }))
        $skippedCount++
    }
    elseif (-not $isDue) {
        $runDetail = "not due yet"
        $skippedCount++
    }
    elseif (-not $scriptPath -or -not (Test-Path -LiteralPath $scriptPath)) {
        $runStatus = "failed"
        $runDetail = "script missing"
        $exitCode = 1
        $warningCount++
    }
    else {
        $result = Invoke-Script -Path $scriptPath -Arguments $executionArguments
        $commandRun = $result.command_run
        $outputLines = @($result.output)
        $exitCode = [int]$result.exit_code
        $executedCount++

        if ($auditArtifactPath -and (Test-Path -LiteralPath $auditArtifactPath)) {
            try {
                $artifactFresh = ((Get-Item -LiteralPath $auditArtifactPath).LastWriteTimeUtc -ge $nowUtc.AddMinutes(-10))
            }
            catch {
                $artifactFresh = $false
            }
        }

        if ($result.ok -and ($artifactFresh -or -not $auditArtifactPath)) {
            $runStatus = "success"
            $runDetail = $(if ($artifactFresh) { "script executed and audit artifact refreshed" } else { "script executed" })
            $successCount++
            $lastRunUtc = $nowUtc.ToString("o")
            $nextRunUtc = if ($cadenceMinutes -gt 0) { $nowUtc.AddMinutes($cadenceMinutes).ToString("o") } else { "" }
        }
        elseif ($result.ok) {
            $runStatus = "warning"
            $runDetail = "script executed but audit artifact was not refreshed"
            $warningCount++
            $lastRunUtc = $nowUtc.ToString("o")
            $nextRunUtc = if ($cadenceMinutes -gt 0) { $nowUtc.AddMinutes($cadenceMinutes).ToString("o") } else { "" }
        }
        else {
            $runStatus = "failed"
            $runDetail = "script execution failed"
            $warningCount++
        }
    }

    $priorHistory = @((To-Array (Get-PropValue -Object $prior -Name "history" -Default @())) | Select-Object -Last ([Math]::Max(0, $maxEntriesPerTask - 1)))
    $newHistoryEntry = [pscustomobject][ordered]@{
        timestamp_utc = $nowUtc.ToString("o")
        status = $runStatus
        detail = $runDetail
        exit_code = $exitCode
        trigger_source = $TriggerSource
        artifact_fresh = [bool]$artifactFresh
    }
    $updatedHistory = @($priorHistory + @($newHistoryEntry))

    $updatedRegistryTasks.Add([pscustomobject][ordered]@{
        task_id = $taskId
        category = Normalize-Text (Get-PropValue -Object $task -Name "category" -Default "")
        enabled = $enabled
        cadence_minutes = $cadenceMinutes
        risk_class = Normalize-Text (Get-PropValue -Object $task -Name "risk_class" -Default "")
        schedule_owner = $scheduleOwner
        script_rel_path = $scriptRelPath
        script_exists = [bool]($scriptPath -and (Test-Path -LiteralPath $scriptPath))
        host_task_name = $hostTaskName
        audit_artifact = $auditArtifactRel
        last_run_utc = $lastRunUtc
        next_run_utc = $nextRunUtc
        last_result = $(if ($null -ne $exitCode) { $exitCode } else { (Get-PropValue -Object $prior -Name "last_result" -Default "not_run") })
        last_status = $runStatus
        last_detail = $runDetail
        last_command_run = $commandRun
        execution_count = [int](Get-PropValue -Object $prior -Name "execution_count" -Default 0) + $(if ($runStatus -in @("success", "warning", "failed")) { 1 } else { 0 })
        history = @($updatedHistory)
    }) | Out-Null

    $runRecords.Add([pscustomobject][ordered]@{
        task_id = $taskId
        schedule_owner = $scheduleOwner
        status = $runStatus
        detail = $runDetail
        exit_code = $exitCode
        artifact_fresh = [bool]$artifactFresh
        audit_artifact = $auditArtifactRel
        host_task_name = $hostTaskName
        command_run = $commandRun
        output = @($outputLines)
    }) | Out-Null
}

$trimmedRunHistory = @((To-Array (Get-PropValue -Object $historyState -Name "run_records" -Default @())) + @($runRecords.ToArray()))
if ($trimmedRunHistory.Count -gt $maxRunRecords) {
    $trimmedRunHistory = @($trimmedRunHistory | Select-Object -Last $maxRunRecords)
}

$updatedRegistry = [ordered]@{
    generated_at_utc = $nowUtc.ToString("o")
    overall_status = $(if ($warningCount -eq 0) { "PASS" } else { "WARN" })
    execution_posture = "internal_runner_active"
    last_trigger_source = $TriggerSource
    task_count = $updatedRegistryTasks.Count
    enabled_task_count = @($updatedRegistryTasks | Where-Object { $_.enabled }).Count
    ready_task_count = @($updatedRegistryTasks | Where-Object { $_.script_exists }).Count
    last_run_summary = [ordered]@{
        executed_count = $executedCount
        success_count = $successCount
        warning_count = $warningCount
        skipped_count = $skippedCount
    }
    tasks = @($updatedRegistryTasks.ToArray())
}
Write-JsonFile -Path $registryPath -Object $updatedRegistry -Depth 20

$updatedHistoryState = [ordered]@{
    generated_at_utc = $nowUtc.ToString("o")
    last_trigger_source = $TriggerSource
    run_records = @($trimmedRunHistory)
}
Write-JsonFile -Path $historyPath -Object $updatedHistoryState -Depth 20

$executionArtifact = [ordered]@{
    timestamp_utc = $nowUtc.ToString("o")
    overall_status = $(if ($warningCount -eq 0) { "PASS" } else { "WARN" })
    trigger_source = $TriggerSource
    task_filter = @($selectedTaskIds)
    executed_count = $executedCount
    success_count = $successCount
    warning_count = $warningCount
    skipped_count = $skippedCount
    items = @($runRecords.ToArray())
    recommended_next_action = $(if ($warningCount -eq 0) { "Keep the internal scheduler runner as the primary path for migrated low-risk recurring work." } else { "Review tasks that failed or did not refresh their audit artifacts before disabling more host tasks." })
    command_run = ("powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}" -f $PSCommandPath)
    repo_root = $repoRoot
}
Write-JsonFile -Path $executionPath -Object $executionArtifact -Depth 20
