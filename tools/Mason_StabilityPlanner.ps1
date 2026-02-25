# Mason_StabilityPlanner.ps1
# Builds a simple stability work plan from tasks in tasks\pending\**\*.json

$ErrorActionPreference = "Stop"

# Work out Mason base + key folders
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$base       = Split-Path $scriptRoot -Parent

$tasksRoot  = Join-Path $base "tasks\pending"
$reportsDir = Join-Path $base "reports"

if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir | Out-Null
}

$planPath = Join-Path $reportsDir "mason_stability_plan.json"

# If there is no pending folder at all, write a "no tasks" plan
if (-not (Test-Path $tasksRoot)) {
    $plan = [pscustomobject]@{
        generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        mason_base       = $base
        total_tasks      = 0
        notes            = @("No tasks\pending folder found. Nothing to plan yet.")
        by_area          = @{}
        tasks            = @()
    }

    $plan | ConvertTo-Json -Depth 6 | Set-Content -Path $planPath -Encoding UTF8
    Write-Host "Stability plan written (no tasks): $planPath"
    return
}

# Collect all JSON task files under tasks\pending
$taskFiles = Get-ChildItem -Path $tasksRoot -Filter *.json -Recurse -ErrorAction SilentlyContinue

$tasks = @()
foreach ($f in $taskFiles) {
    try {
        $raw  = Get-Content $f.FullName -Raw -ErrorAction Stop
        if (-not $raw.Trim()) { continue }

        $obj = $raw | ConvertFrom-Json -ErrorAction Stop

        $area = if ($obj.area) { $obj.area } else { "unknown" }
        $risk = if ($obj.risk) { $obj.risk } else { "unknown" }

        $tasks += [pscustomobject]@{
            id         = $obj.id
            area       = $area
            risk       = $risk
            auto_apply = $obj.auto_apply
            file       = $f.FullName
            title      = $obj.title
            summary    = $obj.summary
        }
    }
    catch {
        # skip bad JSON files
        continue
    }
}

# Build summary by area/risk
$byArea = @{}

foreach ($t in $tasks) {
    if (-not $byArea.ContainsKey($t.area)) {
        $byArea[$t.area] = [ordered]@{
            total    = 0
            by_risk  = @{}
            samples  = @()
        }
    }

    $areaEntry = $byArea[$t.area]
    $areaEntry.total++

    if (-not $areaEntry.by_risk.ContainsKey($t.risk)) {
        $areaEntry.by_risk[$t.risk] = 0
    }
    $areaEntry.by_risk[$t.risk]++

    if ($areaEntry.samples.Count -lt 5) {
        $areaEntry.samples += $t.id
    }

    $byArea[$t.area] = $areaEntry
}

$notes = @()
if ($tasks.Count -eq 0) {
    $notes += "No pending JSON tasks found under tasks\\pending."
} else {
    $notes += "Planner scanned tasks\\pending and grouped tasks by area and risk."
    $notes += "Use this file to decide which tasks Mason is allowed to run next."
}

$planOut = [pscustomobject]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    mason_base       = $base
    total_tasks      = $tasks.Count
    notes            = $notes
    by_area          = $byArea
    tasks            = $tasks
}

$planOut | ConvertTo-Json -Depth 6 | Set-Content -Path $planPath -Encoding UTF8

Write-Host "Stability plan written: $planPath"
Write-Host "Total tasks found: $($tasks.Count)"
