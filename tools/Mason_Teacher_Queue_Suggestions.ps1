param(
    [string]$RootDir = $(Split-Path -Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = "Stop"

function Convert-ToArray {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return $Value }
    return @($Value)
}

# --- Paths ---
$stateDir        = Join-Path -Path $RootDir -ChildPath "state\knowledge"
$suggestionsPath = Join-Path -Path $stateDir -ChildPath "mason_teacher_suggestions.json"
$approvalsPath   = Join-Path -Path $stateDir -ChildPath "pending_patch_runs.json"

Write-Host "[TeacherQueue] Mason_Teacher_Queue_Suggestions starting..."
Write-Host "  Root        : $RootDir"
Write-Host "  Suggestions : $suggestionsPath"
Write-Host "  Approvals   : $approvalsPath"

if (-not (Test-Path -Path $suggestionsPath)) {
    Write-Warning "[TeacherQueue] No mason_teacher_suggestions.json found. Nothing to queue."
    exit 0
}

# --- Load suggestions ---
try {
    $suggestionsRaw = Get-Content -Path $suggestionsPath -Raw | ConvertFrom-Json
}
catch {
    Write-Error ("[TeacherQueue] Failed to parse suggestions JSON: {0}" -f $_.Exception.Message)
    exit 1
}

$suggestions = @()
$emptyReason = $null

if ($suggestionsRaw -is [System.Array]) {
    $suggestions = $suggestionsRaw
}
elseif ($suggestionsRaw -and $suggestionsRaw.suggestions) {
    $suggestions = Convert-ToArray $suggestionsRaw.suggestions
    if ($suggestionsRaw.reason) {
        $emptyReason = [string]$suggestionsRaw.reason
    }
}
elseif ($suggestionsRaw -and $suggestionsRaw.id) {
    $suggestions = @($suggestionsRaw)
}

if (-not $suggestions -or $suggestions.Count -eq 0) {
    if ($emptyReason) {
        Write-Warning "[TeacherQueue] Suggestions are empty: $emptyReason"
        # Normalize to [] so downstream scripts do not treat metadata as a queue item.
        @() | ConvertTo-Json -Depth 4 | Set-Content -Path $suggestionsPath -Encoding UTF8
    }
    else {
        Write-Host "[TeacherQueue] Suggestions file is empty. Nothing to queue."
    }
    exit 0
}

# --- Load existing approvals (may not exist yet) ---
$approvals = @()
if (Test-Path -Path $approvalsPath) {
    try {
        $existing = Get-Content -Path $approvalsPath -Raw | ConvertFrom-Json
        if ($existing) {
            if ($existing -is [System.Array]) {
                $approvals = $existing
            }
            else {
                $approvals = @($existing)
            }
        }
    }
    catch {
        Write-Warning ("[TeacherQueue] Failed to parse existing approvals JSON: {0}" -f $_.Exception.Message)
    }
}

# Build a quick lookup of existing approval IDs so we don't duplicate
$existingIds = @{}
foreach ($ap in $approvals) {
    if ($ap.id) {
        $existingIds[$ap.id] = $true
    }
}

$pendingSuggestionsCount = 0
foreach ($s in $suggestions) {
    if (-not $s -or -not $s.id) { continue }
    $statusText = if ($s.status) { ([string]$s.status).ToLowerInvariant() } else { "pending" }
    if ($statusText -eq "pending") {
        $pendingSuggestionsCount++
    }
}

$queueBudget = 20
if ($pendingSuggestionsCount -gt 200) {
    $queueBudget = 5
    Write-Warning "[TeacherQueue] Pending suggestions exceed 200 ($pendingSuggestionsCount). Queue budget reduced to 5 for this run."
}

$nowUtc              = (Get-Date).ToUniversalTime().ToString("o")
$queuedCount         = 0
$updatedSuggestions  = @()

foreach ($s in $suggestions) {

    # Keep non-object entries as-is
    if (-not $s.id) {
        $updatedSuggestions += $s
        continue
    }

    $statusText = if ($s.status) { ([string]$s.status).ToLowerInvariant() } else { "pending" }

    # Do not queue already-finalized items.
    if ($statusText -eq "executed" -or $statusText -eq "rejected") {
        $updatedSuggestions += $s
        continue
    }

    $approvalId = "teacher-" + $s.id

    if ($existingIds.ContainsKey($approvalId)) {
        # Never re-queue entries that already exist in approvals by id.
        $s.status = "queued"
        try {
            if (-not $s.queued_at) {
                $s | Add-Member -NotePropertyName "queued_at" -NotePropertyValue $nowUtc -Force
            }
        } catch {}
        $updatedSuggestions += $s
        continue
    }

    # Keep already-queued items untouched if approval was removed externally.
    if ($statusText -eq "queued") {
        $updatedSuggestions += $s
        continue
    }

    # Respect queue budget. Remaining items stay pending.
    if ($queuedCount -ge $queueBudget) {
        $s.status = "pending"
        $updatedSuggestions += $s
        continue
    }

    $component = if ($s.area) { $s.area } else { "mason" }
    $risk      = if ($s.risk_level) { $s.risk_level } else { "R1" }

    $approval = [pscustomobject]@{
        id           = $approvalId
        component_id = $component
        title        = $s.title
        operator_summary = $s.operator_summary
        description  = $s.description
        risk_level   = $risk
        status       = "pending"
        area         = $component
        domain       = $s.domain
        teacher_domain = $s.teacher_domain
        teacher_area = $s.teacher_area
        dedupe_key   = $s.dedupe_key
        created_at   = $nowUtc
        kind         = "teacher_plan_step"
        source_step  = $s.id
        source       = "teacher"
    }

    $approvals += $approval
    $existingIds[$approvalId] = $true
    $queuedCount++

    # Mark suggestion as queued; use Add-Member so we can add a new property safely
    $s.status = "queued"
    try {
        $s | Add-Member -NotePropertyName "queued_at" -NotePropertyValue $nowUtc -Force
    } catch {
        # if Add-Member somehow fails, we still keep status change
    }

    $updatedSuggestions += $s
}

# --- Save back approvals + updated suggestions ---
$approvals          | ConvertTo-Json -Depth 8 | Set-Content -Path $approvalsPath   -Encoding UTF8
$updatedSuggestions | ConvertTo-Json -Depth 8 | Set-Content -Path $suggestionsPath -Encoding UTF8

Write-Host "[TeacherQueue] Queued $queuedCount teacher suggestion(s) into approvals (budget: $queueBudget, pending input: $pendingSuggestionsCount)."
Write-Host "[TeacherQueue] Updated approvals file:"
Write-Host "  $approvalsPath"
Write-Host "[TeacherQueue] Updated suggestions file:"
Write-Host "  $suggestionsPath"
Write-Host "[TeacherQueue] Done."
