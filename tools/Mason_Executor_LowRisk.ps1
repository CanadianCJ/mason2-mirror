param(
    [string]$BasePath = $(Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

function Write-ExecLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Write-Host "[$timestamp] [$Level] $Message"
}

Write-ExecLog "Mason_Executor_LowRisk starting..."
Write-ExecLog "BasePath = $BasePath"

# --- 1) Fetch approved proposals (risk 0–1) ---

$proposalsUrl = "http://127.0.0.1:8000/api/proposals?status=approved"

try {
    $resp = Invoke-RestMethod -Uri $proposalsUrl -Method Get -ErrorAction Stop
} catch {
    Write-ExecLog "Failed to fetch approved proposals from $proposalsUrl : $($_.Exception.Message)" "ERROR"
    exit 1
}

if (-not $resp -or -not $resp.proposals) {
    Write-ExecLog "No approved proposals found. Nothing to do."
    exit 0
}

$approved = @($resp.proposals) | Where-Object {
    $_.risk_level -le 1
}

if (-not $approved -or $approved.Count -eq 0) {
    Write-ExecLog "No approved low-risk (<=1) proposals. Nothing to do."
    exit 0
}

Write-ExecLog "Found $($approved.Count) approved low-risk proposals."

# --- 2) Prepare tasks file and de-dup by proposal_id ---

$reportsDir = Join-Path $BasePath "reports"
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

$tasksFile = Join-Path $reportsDir "mason_tasks.jsonl"

$existingIds = @()
if (Test-Path $tasksFile) {
    Write-ExecLog "Reading existing tasks from $tasksFile"
    try {
        $existingIds = Get-Content $tasksFile | Where-Object { $_.Trim() -ne "" } | ForEach-Object {
            try {
                ($_.Trim() | ConvertFrom-Json).proposal_id
            } catch {
                $null
            }
        } | Where-Object { $_ -ne $null }
    } catch {
        Write-ExecLog "Warning: failed to read existing tasks ($($_.Exception.Message)). Continuing with empty list." "WARN"
        $existingIds = @()
    }
}

# --- 3) Build action-plan tasks for each proposal ---

$newTasks = @()
foreach ($p in $approved) {
    if ($existingIds -contains $p.id) {
        Write-ExecLog "Proposal $($p.id) already has a task. Skipping."
        continue
    }

    $area = $p.area
    $title = $p.title
    $summary = $p.summary
    $details = $p.details
    $notes = $p.notes

    # Default generic steps
    $steps = @(
        "Gather relevant context for proposal $($p.id) in area '$area'.",
        "Review current health / status / logs for area '$area'.",
        "Break the proposal into concrete, low-risk sub-tasks.",
        "Prepare a suggested remediation or improvement plan for human review.",
        "Optionally, create follow-up proposals for any higher-risk or code-level changes."
    )

    # Slightly more specific plan for Onyx proposals
    if ($area -eq "onyx") {
        $steps = @(
            "Collect Onyx health metrics from reports\\onyx_health_summary.json and any related logs.",
            "Identify the most frequent or severe error patterns affecting Onyx.",
            "Draft a remediation plan focused on low-risk changes (config, retries, logging, restarts).",
            "Propose specific follow-up tasks (e.g., improve error handling, add warning thresholds, adjust timeouts).",
            "Prepare a short summary for Chris describing impact and recommended next steps."
        )
    }

    # Slightly more specific plan for Mason proposals
    if ($area -eq "mason") {
        $steps = @(
            "Review Mason self-state from reports\\mason_self_state.json and mason_health_aggregated.json.",
            "Check recent stability tasks and logs for failures or skipped work.",
            "Identify any obvious self-maintenance tasks (cleanup, log rotation, report freshness).",
            "Draft a prioritized set of low-risk improvements for Mason core.",
            "Prepare a summary for Chris with suggested next actions and any approvals needed."
        )
    }

    $task = [ordered]@{
        id           = [Guid]::NewGuid().ToString()
        created_at   = (Get-Date).ToUniversalTime().ToString("o")
        status       = "planned"              # planned | in_progress | done | blocked
        source       = "mason-executor-lowrisk"
        proposal_id  = $p.id
        area         = $area
        risk_level   = $p.risk_level
        title        = "Plan: $title"
        summary      = $summary
        steps        = $steps
        context      = [ordered]@{
            suggested_actions = $details.suggested_actions
            metrics           = $details.metrics
            notes             = $notes
        }
    }

    $newTasks += $task
}

if ($newTasks.Count -eq 0) {
    Write-ExecLog "No new tasks to write (all proposals already converted)."
    exit 0
}

Write-ExecLog "Writing $($newTasks.Count) new tasks to $tasksFile"

foreach ($t in $newTasks) {
    ($t | ConvertTo-Json -Depth 6) | Add-Content -Path $tasksFile -Encoding UTF8
}

Write-ExecLog "Mason_Executor_LowRisk completed."
