[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$RoadmapChunkId = "",
    [string]$Topic = "",
    [ValidateRange(1, 20)][int]$MemoryItems = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Mason_Memory_Common.ps1")

function Get-RecentPendingApprovals {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [ValidateRange(1, 50)][int]$Top = 10
    )

    $data = Read-JsonSafe -Path $Path -Default @()
    $pending = @(
        foreach ($item in Convert-ToArray $data) {
            $status = [string](Get-PropertyValue -Object $item -Name "status" -Default "")
            if ($status -notin @("pending", "approved")) { continue }
            [pscustomobject]@{
                id           = [string](Get-PropertyValue -Object $item -Name "id" -Default "")
                title        = [string](Get-PropertyValue -Object $item -Name "title" -Default "")
                component_id = [string](Get-PropertyValue -Object $item -Name "component_id" -Default "")
                status       = $status
                created_at   = [string](Get-PropertyValue -Object $item -Name "created_at" -Default "")
                source       = [string](Get-PropertyValue -Object $item -Name "source" -Default "")
                risk_level   = [int](Get-PropertyValue -Object $item -Name "risk_level" -Default 0)
            }
        }
    )

    return @(
        $pending |
        Sort-Object -Property `
            @{ Expression = { $_.created_at }; Descending = $true }, `
            @{ Expression = { $_.id }; Descending = $false } |
        Select-Object -First $Top
    )
}

function Get-ActiveTasks {
    param(
        [Parameter(Mandatory = $true)][string]$TasksRoot,
        [ValidateRange(1, 50)][int]$Top = 10
    )

    if (-not (Test-Path -LiteralPath $TasksRoot)) {
        return @()
    }

    $files = @(
        Get-ChildItem -LiteralPath $TasksRoot -Recurse -File -Filter *.json -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTimeUtc -Descending |
        Select-Object -First $Top
    )

    $items = New-Object System.Collections.Generic.List[object]
    foreach ($file in $files) {
        $task = Read-JsonSafe -Path $file.FullName -Default $null
        if (-not $task) { continue }
        $items.Add([pscustomobject]@{
            id            = [string](Get-PropertyValue -Object $task -Name "id" -Default $file.BaseName)
            status        = [string](Get-PropertyValue -Object $task -Name "status" -Default "")
            summary       = [string](Get-PropertyValue -Object $task -Name "summary" -Default "")
            title         = [string](Get-PropertyValue -Object $task -Name "title" -Default "")
            source        = [string](Get-PropertyValue -Object $task -Name "source" -Default "")
            updated_at    = [string](Get-PropertyValue -Object $task -Name "updated_at" -Default $file.LastWriteTimeUtc.ToString("o"))
            evidence_files = @(Convert-ToArray (Get-PropertyValue -Object $task -Name "evidence_files" -Default @()))
            task_path     = $file.FullName
        }) | Out-Null
    }

    return @($items.ToArray())
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$contextPackPath = Join-Path $reportsDir "context_pack.json"

$startRunPath = Join-Path $reportsDir "start\start_run_last.json"
$verifyPath = Join-Path $reportsDir "verify_last.json"
$mirrorPath = Join-Path $reportsDir "mirror_update_last.json"
$oneClickPath = Join-Path $reportsDir "launcher\oneclick_last.json"
$approvalsApplyPath = Join-Path $reportsDir "approvals_apply_latest.json"
$pendingApprovalsPath = Join-Path $repoRoot "state\knowledge\pending_patch_runs.json"
$taskRoot = Join-Path $repoRoot "tasks\pending"
$activePhasePath = Join-Path $repoRoot "roadmap\active_phase.json"
$masterRoadmapPath = Join-Path $repoRoot "roadmaps\master_roadmap.json"

$startRun = Read-JsonSafe -Path $startRunPath -Default @{}
$verify = Read-JsonSafe -Path $verifyPath -Default @{}
$mirror = Read-JsonSafe -Path $mirrorPath -Default @{}
$oneClick = Read-JsonSafe -Path $oneClickPath -Default @{}
$approvalsApply = Read-JsonSafe -Path $approvalsApplyPath -Default @{}
$activePhase = Read-JsonSafe -Path $activePhasePath -Default @{}
$masterRoadmap = Read-JsonSafe -Path $masterRoadmapPath -Default @{}

$launchResults = @(Convert-ToArray (Get-PropertyValue -Object $startRun -Name "launch_results" -Default @()))
$readiness = @(Convert-ToArray (Get-PropertyValue -Object $startRun -Name "readiness" -Default @()))
$ports = @(Convert-ToArray (Get-PropertyValue -Object $startRun -Name "ports" -Default @()))

$failures = New-Object System.Collections.Generic.List[object]
if ($verify -and (-not [bool](Get-PropertyValue -Object $verify -Name "ok" -Default $true))) {
    $failures.Add([pscustomobject]@{
        kind                    = "verify"
        status                  = [string](Get-PropertyValue -Object $verify -Name "status" -Default "")
        failing_component       = [string](Get-PropertyValue -Object $verify -Name "failing_component" -Default "")
        failing_log_path        = [string](Get-PropertyValue -Object $verify -Name "failing_log_path" -Default "")
        recommended_next_action = [string](Get-PropertyValue -Object $verify -Name "recommended_next_action" -Default "")
        source_path             = $verifyPath
    }) | Out-Null
}

foreach ($probe in $readiness) {
    if ([bool](Get-PropertyValue -Object $probe -Name "ready" -Default $true)) { continue }
    $lastProbe = Get-PropertyValue -Object $probe -Name "last_probe" -Default @{}
    $failures.Add([pscustomobject]@{
        kind                    = "readiness"
        status                  = "FAIL"
        failing_component       = [string](Get-PropertyValue -Object $probe -Name "name" -Default "")
        failing_log_path        = ""
        recommended_next_action = [string](Get-PropertyValue -Object $lastProbe -Name "error" -Default "")
        source_path             = $startRunPath
    }) | Out-Null
}

if (([string](Get-PropertyValue -Object $startRun -Name "overall_status" -Default "") -and ([string](Get-PropertyValue -Object $startRun -Name "overall_status" -Default "") -ne "PASS"))) {
    $failures.Add([pscustomobject]@{
        kind                    = "stack_start"
        status                  = [string](Get-PropertyValue -Object $startRun -Name "overall_status" -Default "")
        failing_component       = "fullstack_start"
        failing_log_path        = [string](Get-PropertyValue -Object $startRun -Name "start_failure_artifact" -Default "")
        recommended_next_action = "Inspect the latest start artifact and readiness probes."
        source_path             = $startRunPath
    }) | Out-Null
}

foreach ($warning in Convert-ToArray (Get-PropertyValue -Object $oneClick -Name "warnings" -Default @())) {
    $failures.Add([pscustomobject]@{
        kind                    = "launcher_warning"
        status                  = "WARN"
        failing_component       = "launcher"
        failing_log_path        = [string](Get-PropertyValue -Object $oneClick -Name "log_path" -Default "")
        recommended_next_action = [string]$warning
        source_path             = $oneClickPath
    }) | Out-Null
}

$pendingApprovals = Get-RecentPendingApprovals -Path $pendingApprovalsPath -Top 10
$activeTasks = Get-ActiveTasks -TasksRoot $taskRoot -Top 10

$topicParts = New-Object System.Collections.Generic.List[string]
foreach ($part in @(
    $Topic,
    $RoadmapChunkId,
    [string](Get-PropertyValue -Object $verify -Name "failing_component" -Default ""),
    [string](Get-PropertyValue -Object $activePhase -Name "phase" -Default ""),
    [string](Get-PropertyValue -Object $activePhase -Name "status" -Default "")
)) {
    if ($part) {
        $topicParts.Add($part) | Out-Null
    }
}
foreach ($task in $activeTasks | Select-Object -First 3) {
    foreach ($part in @($task.title, $task.summary)) {
        if ($part) {
            $topicParts.Add([string]$part) | Out-Null
        }
    }
}
foreach ($approval in $pendingApprovals | Select-Object -First 3) {
    if ($approval.title) {
        $topicParts.Add([string]$approval.title) | Out-Null
    }
}

$memoryQuery = (($topicParts.ToArray() -join " ").Trim())
$memorySelection = if ($memoryQuery) {
    Search-MemoryRecords -RepoRoot $repoRoot -QueryText $memoryQuery -Tier "hot" -Top $MemoryItems
}
else {
    @()
}

if (@($memorySelection).Count -eq 0) {
    $memorySelection = Get-RecentMemoryItems -RepoRoot $repoRoot -Tier "hot" -Top $MemoryItems
}

$services = @(
    foreach ($launchResult in $launchResults) {
        [pscustomobject]@{
            component     = [string](Get-PropertyValue -Object $launchResult -Name "component" -Default "")
            started       = [bool](Get-PropertyValue -Object $launchResult -Name "started" -Default $false)
            process_alive = [bool](Get-PropertyValue -Object $launchResult -Name "process_alive" -Default $false)
            pid           = Get-PropertyValue -Object $launchResult -Name "pid" -Default $null
            message       = [string](Get-PropertyValue -Object $launchResult -Name "message" -Default "")
            stdout_log    = [string](Get-PropertyValue -Object $launchResult -Name "stdout_log" -Default "")
            stderr_log    = [string](Get-PropertyValue -Object $launchResult -Name "stderr_log" -Default "")
        }
    }
)

$roadmapChunk = [ordered]@{
    requested_chunk_id   = $RoadmapChunkId
    active_phase         = Get-PropertyValue -Object $activePhase -Name "phase" -Default $null
    active_phase_status  = [string](Get-PropertyValue -Object $activePhase -Name "status" -Default "")
    active_phase_source  = if ($activePhase) { $activePhasePath } else { "" }
    roadmap_generated_at = [string](Get-PropertyValue -Object $masterRoadmap -Name "generated_at_utc" -Default "")
}

$payload = [ordered]@{
    schema = "mason-context-pack-v1"
    generated_at_utc = Get-UtcNowIso
    current_stack_state = [ordered]@{
        overall_status      = [string](Get-PropertyValue -Object $startRun -Name "overall_status" -Default "")
        mode                = [string](Get-PropertyValue -Object $startRun -Name "mode" -Default "")
        run_id              = [string](Get-PropertyValue -Object $startRun -Name "run_id" -Default "")
        generated_at_utc    = [string](Get-PropertyValue -Object $startRun -Name "generated_at_utc" -Default "")
        verify_status       = [string](Get-PropertyValue -Object $verify -Name "status" -Default "")
        verify_ok           = [bool](Get-PropertyValue -Object $verify -Name "ok" -Default $false)
        ready_count         = @($readiness | Where-Object { [bool](Get-PropertyValue -Object $_ -Name "ready" -Default $false) }).Count
        not_ready_count     = @($readiness | Where-Object { -not [bool](Get-PropertyValue -Object $_ -Name "ready" -Default $true) }).Count
        launched_components = $services.Count
    }
    latest_failures = @($failures.ToArray())
    current_ports_services = [ordered]@{
        ports    = @($ports)
        services = $services
    }
    latest_mirror_status = [ordered]@{
        timestamp_utc = [string](Get-PropertyValue -Object $mirror -Name "timestamp_utc" -Default "")
        ok            = [bool](Get-PropertyValue -Object $mirror -Name "ok" -Default $false)
        phase         = [string](Get-PropertyValue -Object $mirror -Name "phase" -Default "")
        next_action   = [string](Get-PropertyValue -Object $mirror -Name "next_action" -Default "")
        source_path   = $mirrorPath
    }
    important_recent_memory_items = @($memorySelection)
    current_roadmap_chunk = $roadmapChunk
    active_tasks = @($activeTasks)
    pending_approvals = [ordered]@{
        apply_summary = [ordered]@{
            generated_at        = [string](Get-PropertyValue -Object $approvalsApply -Name "generated_at" -Default "")
            approved_candidates = [int](Get-PropertyValue -Object $approvalsApply -Name "approved_candidates" -Default 0)
            applied_count       = [int](Get-PropertyValue -Object $approvalsApply -Name "applied_count" -Default 0)
            skipped_count       = [int](Get-PropertyValue -Object $approvalsApply -Name "skipped_count" -Default 0)
        }
        items = @($pendingApprovals)
    }
    sources = [ordered]@{
        start_run_last          = $startRunPath
        verify_last             = $verifyPath
        mirror_update_last      = $mirrorPath
        launcher_oneclick_last  = $oneClickPath
        approvals_apply_latest  = $approvalsApplyPath
        pending_patch_runs      = $pendingApprovalsPath
        active_phase            = $activePhasePath
        master_roadmap          = $masterRoadmapPath
    }
}

Write-JsonFile -Path $contextPackPath -Object $payload
$payload | ConvertTo-Json -Depth 20
