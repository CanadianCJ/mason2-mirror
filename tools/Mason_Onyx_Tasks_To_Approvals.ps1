param(
    # Mason2 root. Default is your real Mason2 path.
    [string]$RootPath = "C:\Users\Chris\Desktop\Mason2"
)

$ErrorActionPreference = "Stop"

# -------------------------------------------------------------------
# Paths inside Mason2 (NOT inside the Onyx repo)
# -------------------------------------------------------------------
$stateKnowledgeDir = Join-Path $RootPath "state\knowledge"
$pendingPath       = Join-Path $stateKnowledgeDir "pending_patch_runs.json"

$tasksDir          = Join-Path $RootPath "tasks\pending\onyx"

if (-not (Test-Path $tasksDir)) {
    Write-Warning "Onyx tasks directory not found: $tasksDir"
    return
}

# -------------------------------------------------------------------
# Load existing approvals (pending_patch_runs.json)
# -------------------------------------------------------------------
$pending = @()
if (Test-Path $pendingPath) {
    $raw = (Get-Content $pendingPath -Raw).Trim()
    if ($raw) {
        try {
            $pending = $raw | ConvertFrom-Json
        }
        catch {
            Write-Warning "Could not parse existing pending approvals JSON. Starting fresh."
            $pending = @()
        }
    }
}

if (-not ($pending -is [System.Collections.IEnumerable])) {
    $pending = @()
}

# Track existing IDs to avoid duplicates
$existingIds = @{}
foreach ($item in $pending) {
    if ($null -ne $item.id) {
        $existingIds[$item.id] = $true
    }
}

# -------------------------------------------------------------------
# Risk mapping from Onyx task -> Approvals ladder
# -------------------------------------------------------------------
$riskMap = @{
    "low"      = "R0"
    "medium"   = "R1"
    "high"     = "R2"
    "critical" = "R3"
}

# -------------------------------------------------------------------
# Convert each pending Onyx task into an approval item
# -------------------------------------------------------------------
Get-ChildItem $tasksDir -Filter '*.json' -ErrorAction SilentlyContinue | ForEach-Object {
    $taskFile = $_.FullName
    $taskRaw  = (Get-Content $taskFile -Raw).Trim()
    if (-not $taskRaw) { return }

    $task = $taskRaw | ConvertFrom-Json

    # Only consider tasks that are still pending
    if (-not $task.status -or $task.status -ne "pending") {
        return
    }

    # Build a unique approval id derived from the task id
    $approvalId = "onyx-task-{0}" -f $task.id
    if ($existingIds.ContainsKey($approvalId)) {
        return
    }

    # Map risk -> risk_level for Approvals
    $risk = $null
    if ($task.PSObject.Properties.Name -contains "risk") {
        $risk = $riskMap[$task.risk]
    }
    if (-not $risk) {
        $risk = "R1"  # conservative default if missing
    }

    # Human-readable title
    $summary = $task.summary
    if (-not $summary) {
        $summary = "Onyx task: $($task.id)"
    }

    $title = "Onyx: {0}" -f $summary
    if ($title.Length -gt 120) {
        $title = $title.Substring(0, 117) + "..."
    }

    $approval = [pscustomobject]@{
        id           = $approvalId
        component_id = "onyx"
        title        = $title
        risk_level   = $risk    # R0/R1/R2/R3
        status       = "pending"
        source_task  = $task.id
        area         = "onyx"
        domain       = $task.domain
        created_at   = (Get-Date).ToUniversalTime().ToString("o")
        kind         = "patch_run"
    }

    $pending += $approval
    $existingIds[$approvalId] = $true
    Write-Host "Added approval for Onyx task '$($task.id)' as '$approvalId'."
}

# -------------------------------------------------------------------
# Write back pending_patch_runs.json
# -------------------------------------------------------------------
$pending | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $pendingPath -Encoding UTF8

Write-Host ""
Write-Host "Updated approvals file:" $pendingPath -ForegroundColor Cyan
Write-Host "Total approvals now: $($pending.Count)"
