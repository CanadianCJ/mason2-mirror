param()

$ErrorActionPreference = "Stop"

# Paths
$basePath   = Split-Path $PSScriptRoot -Parent
$reportsDir = Join-Path $basePath "reports"
$specsDir   = Join-Path $basePath "specs"
$tasksDir   = Join-Path $basePath "tasks\pending\onyx"

$masonBrainContextPath = Join-Path $reportsDir "mason_brain_context.json"
$specPath              = Join-Path $specsDir "onyx-analyzer-to-tasks-001.json"

if (-not (Test-Path $masonBrainContextPath)) {
    Write-Host "[ERROR] mason_brain_context.json not found at $masonBrainContextPath"
    exit 1
}

if (-not (Test-Path $specPath)) {
    Write-Host "[ERROR] onyx-analyzer-to-tasks-001.json not found at $specPath"
    exit 1
}

if (-not (Test-Path $tasksDir)) {
    New-Item -ItemType Directory -Path $tasksDir -Force | Out-Null
}

Write-Host "[INFO] Loading Mason brain context..."
$ctxJson = Get-Content $masonBrainContextPath -Raw | ConvertFrom-Json

Write-Host "[INFO] Loading analyzer-to-tasks spec..."
$spec = Get-Content $specPath -Raw | ConvertFrom-Json

# Get the raw analyzer stdout text
$analyzeStdout = $ctxJson.context.onyx_health.analyze_stdout
if (-not $analyzeStdout) {
    Write-Host "[WARN] No analyze_stdout found in mason_brain_context.json"
    exit 0
}

Write-Host "[INFO] Parsing analyzer output into simple groups..."

# Very simple grouping: we just look for a few known patterns and write one task per group
$lines = $analyzeStdout -split "`r?`n"

$groups = @{
    "deprecated_value" = @{
        Pattern = "deprecated_member_use.*'value'.*initialValue"
        Lines   = @()
    }
    "withOpacity" = @{
        Pattern = "deprecated_member_use.*withOpacity"
        Lines   = @()
    }
    "use_build_context_synchronously" = @{
        Pattern = "use_build_context_synchronously"
        Lines   = @()
    }
    "unused_variable" = @{
        Pattern = "unused_local_variable"
        Lines   = @()
    }
    "prefer_const" = @{
        Pattern = "prefer_const_"
        Lines   = @()
    }
}

# Collect lines for each group
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    foreach ($key in $groups.Keys) {
        $pattern = $groups[$key].Pattern
        if ($line -match $pattern) {
            $groups[$key].Lines += $line
        }
    }
}

# Helper to create a task file
function New-OnyxFixTask {
    param(
        [string]$suffix,
        [string]$summary,
        [string]$patternKey,
        [string[]]$rawLines
    )

    if (-not $rawLines -or $rawLines.Count -eq 0) {
        return
    }

    $taskId = "onyx-fix-$suffix-001"
    $taskPath = Join-Path $tasksDir "$taskId.json"

    $taskObject = [ordered]@{
        id              = $taskId
        source_task_id  = $spec.id
        area            = "onyx"
        domain          = "stability"
        risk            = "low"
        auto_apply      = $false
        status          = "pending"
        summary         = $summary
        analyzer_group  = $patternKey
        raw_messages    = $rawLines
        proposed_changes = @(
            @{
                kind        = "manual_review"
                description = "Review the listed analyzer messages for this group and prepare a concrete code-change plan (e.g. replace 'value' with 'initialValue')."
                safe_rollback = "Ensure Dart files are under version control (git) before applying any edits."
            }
        )
    }

    ($taskObject | ConvertTo-Json -Depth 6) | Set-Content -Path $taskPath -Encoding UTF8

    Write-Host "[INFO] Wrote fix task: $taskPath"
}

# Create tasks for each non-empty group
New-OnyxFixTask -suffix "deprecated-value" `
    -summary "Handle deprecated 'value' -> 'initialValue' form field parameters." `
    -patternKey "deprecated_value" `
    -rawLines $groups["deprecated_value"].Lines

New-OnyxFixTask -suffix "withOpacity" `
    -summary "Handle deprecated withOpacity usages." `
    -patternKey "withOpacity" `
    -rawLines $groups["withOpacity"].Lines

New-OnyxFixTask -suffix "use-build-context-sync" `
    -summary "Handle use_build_context_synchronously warnings." `
    -patternKey "use_build_context_synchronously" `
    -rawLines $groups["use_build_context_synchronously"].Lines

New-OnyxFixTask -suffix "unused-variable" `
    -summary "Handle unused local variables reported by analyzer." `
    -patternKey "unused_variable" `
    -rawLines $groups["unused_variable"].Lines

New-OnyxFixTask -suffix "prefer-const" `
    -summary "Handle prefer_const_* suggestions (const constructors/decls)." `
    -patternKey "prefer_const" `
    -rawLines $groups["prefer_const"].Lines

Write-Host "[INFO] Done. Check tasks in: $tasksDir"
