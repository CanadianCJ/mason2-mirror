<#
    Mason_Teacher_Import_Plan.ps1

    Import the latest teacher plan and merge validated steps into:
      state\knowledge\mason_teacher_suggestions.json

    Supported teacher plan shapes:
      1) { "steps": [...] }
      2) { "plan": { "steps": [...] } }
#>

param()

$ErrorActionPreference = 'Stop'

# --- Paths -------------------------------------------------------------

$rootDir       = Split-Path -Path $PSScriptRoot -Parent
$stateDir      = Join-Path $rootDir 'state\knowledge'
$reportsDir    = Join-Path $rootDir 'reports'
$planPath      = Join-Path $stateDir 'mason_teacher_plan_latest.json'
$suggPath      = Join-Path $stateDir 'mason_teacher_suggestions.json'
$approvalsPath = Join-Path $stateDir 'pending_patch_runs.json'
$importLogPath = Join-Path $reportsDir 'mason_teacher_import.log'

New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null

function Write-ImportLog {
    param(
        [string]$Level,
        [string]$Message,
        [hashtable]$Data = @{}
    )

    $entry = [pscustomobject]@{
        ts_utc  = (Get-Date).ToUniversalTime().ToString('o')
        level   = $Level
        message = $Message
        data    = $Data
    }

    $line = $entry | ConvertTo-Json -Depth 6 -Compress
    Add-Content -Path $importLogPath -Value $line -Encoding UTF8

    if ($Level -eq 'WARN' -or $Level -eq 'ERROR') {
        Write-Warning "[TeacherImport] $Message"
    }
    else {
        Write-Host "[TeacherImport] $Message"
    }
}

function Normalize-Token {
    param([string]$Value)
    if (-not $Value) { return '' }
    return ($Value.Trim().ToLowerInvariant() -replace '[\s\-]+', '_')
}

function Normalize-DedupeTitle {
    param([string]$Title)
    if (-not $Title) { return '' }
    return ($Title.Trim().ToLowerInvariant() -replace '\s+', ' ')
}

function Get-DedupeKey {
    param(
        [string]$TeacherDomain,
        [string]$TeacherArea,
        [string]$Title
    )
    $domainKey = Normalize-Token $TeacherDomain
    $areaKey   = Normalize-Token $TeacherArea
    $titleKey  = Normalize-DedupeTitle $Title
    return "$domainKey|$areaKey|$titleKey"
}

function Get-ItemTimestampUtc {
    param($Item)

    if (-not $Item) { return $null }

    $candidateFields = @('created_at', 'decision_at', 'queued_at', 'updated_at', 'ts_utc')
    foreach ($field in $candidateFields) {
        $raw = $Item.$field
        if (-not $raw) { continue }

        $dto = [DateTimeOffset]::MinValue
        if ([DateTimeOffset]::TryParse([string]$raw, [ref]$dto)) {
            return $dto.UtcDateTime
        }
    }

    return $null
}

function Get-StepOperatorSummary {
    param(
        [string]$Summary,
        [string]$Description,
        [string]$TeacherDomain,
        [string]$TeacherArea
    )

    $candidate = if ($Summary) { [string]$Summary } else { '' }
    if (-not $candidate -and $Description -and ($Description -match '(?is)why\s+this\s+helps\s*:\s*(.+)$')) {
        $candidate = [string]$Matches[1]
    }
    if (-not $candidate) {
        $candidate = "Improves $TeacherDomain/$TeacherArea in a safer, clearer way for operators."
    }

    $candidate = ($candidate -replace '\s+', ' ').Trim()
    if ($candidate.Length -gt 160) {
        $candidate = $candidate.Substring(0, 157).TrimEnd() + '...'
    }
    return $candidate
}

function Convert-ToArray {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return $Value }
    return @($Value)
}

function Get-PlanSteps {
    param($Plan)

    if ($Plan -and $Plan.steps) {
        return Convert-ToArray $Plan.steps
    }

    if ($Plan -and $Plan.plan -and $Plan.plan.steps) {
        return Convert-ToArray $Plan.plan.steps
    }

    return @()
}

function Convert-ActionToText {
    param($Action)

    if ($null -eq $Action) { return $null }

    if ($Action -is [string]) {
        $text = $Action.Trim()
        if (-not $text) { return $null }
        return $text
    }

    $type = if ($Action.type) { [string]$Action.type } else { 'edit' }
    $desc = if ($Action.description) { [string]$Action.description } else { '' }

    $files = @()
    foreach ($f in Convert-ToArray $Action.files_touched) {
        if ($f) { $files += [string]$f }
    }

    $suffix = if ($files.Count -gt 0) { " (files: $($files -join ', '))" } else { '' }
    $line   = ($desc + $suffix).Trim()
    if (-not $line) { return $null }

    if ($type -match 'test|validate|verification') {
        return "TEST $line"
    }
    return "EDIT $line"
}

function Test-IsConcreteAction {
    param([string]$ActionText)

    if (-not $ActionText) { return $false }
    $txt = $ActionText.Trim()
    if ($txt.Length -lt 12) { return $false }

    if ($txt -match '(?i)\b(edit|test)\b' -and $txt -match '(\\|/|\.ps1|\.json|powershell|\-File|\-Command)') {
        return $true
    }

    return $false
}

function Write-EmptySuggestionsWithReason {
    param(
        [string]$Reason,
        [int]$RejectedCount = 0
    )

    $payload = [pscustomobject]@{
        generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
        reason           = $Reason
        rejected_count   = $RejectedCount
        suggestions      = @()
    }

    $payload | ConvertTo-Json -Depth 10 | Set-Content -Path $suggPath -Encoding UTF8
    Write-ImportLog -Level 'WARN' -Message $Reason -Data @{ suggestions_path = $suggPath; rejected_count = $RejectedCount }
}

Write-ImportLog -Level 'INFO' -Message 'Mason_Teacher_Import_Plan starting.' -Data @{
    root      = $rootDir
    plan_path = $planPath
    out_path  = $suggPath
    log_path  = $importLogPath
}

if (-not (Test-Path -Path $planPath)) {
    Write-ImportLog -Level 'ERROR' -Message "Plan file not found: $planPath"
    exit 1
}

# --- Load latest plan --------------------------------------------------

try {
    $planJson = Get-Content -Path $planPath -Raw
    $plan     = $planJson | ConvertFrom-Json
}
catch {
    Write-ImportLog -Level 'ERROR' -Message 'Failed to parse plan JSON.' -Data @{ error = $_.Exception.Message }
    exit 1
}

$steps = Get-PlanSteps $plan
if (-not $steps -or $steps.Count -eq 0) {
    Write-EmptySuggestionsWithReason -Reason 'Teacher plan contains no importable steps (expected steps[] or plan.steps[]).'
    exit 0
}

Write-ImportLog -Level 'INFO' -Message "Found $($steps.Count) step(s) in teacher plan."

# --- Load existing suggestions (if any) --------------------------------

$existingSuggestions = @()
if (Test-Path -Path $suggPath) {
    try {
        $existingRaw = Get-Content -Path $suggPath -Raw | ConvertFrom-Json
        if ($existingRaw -is [System.Array]) {
            $existingSuggestions = $existingRaw
        }
        elseif ($existingRaw -and $existingRaw.suggestions) {
            $existingSuggestions = Convert-ToArray $existingRaw.suggestions
        }
    }
    catch {
        Write-ImportLog -Level 'WARN' -Message 'Failed to parse existing suggestions; continuing with empty baseline.' -Data @{ error = $_.Exception.Message }
        $existingSuggestions = @()
    }
}

# --- Load approvals just to prevent duplicate IDs ----------------------

$existingApprovals = @()
if (Test-Path -Path $approvalsPath) {
    try {
        $existingApprovals = Convert-ToArray (Get-Content -Path $approvalsPath -Raw | ConvertFrom-Json)
    }
    catch {
        Write-ImportLog -Level 'WARN' -Message 'Failed to parse approvals for ID scan.' -Data @{ error = $_.Exception.Message }
        $existingApprovals = @()
    }
}

$knownIds = @{}
foreach ($item in @(Convert-ToArray $existingSuggestions) + @(Convert-ToArray $existingApprovals)) {
    if ($item -and $item.id) {
        $knownIds[[string]$item.id] = $true
    }
}

$allowedDomains = @('mason', 'athena', 'onyx')
$allowedAreas   = @(
    'stack', 'watchdog', 'ui', 'security', 'performance', 'reliability', 'logging',
    'approvals', 'notifications', 'trust_meter', 'dashboard', 'tasks', 'invoices', 'crm',
    'observability', 'governance', 'selfops', 'resource_guard', 'network', 'testing'
)

$existingSuggestionDedupeKeys = @{}
foreach ($item in Convert-ToArray $existingSuggestions) {
    if (-not $item) { continue }
    $td = if ($item.teacher_domain) { [string]$item.teacher_domain } elseif ($item.area) { [string]$item.area } else { '' }
    $ta = if ($item.teacher_area) { [string]$item.teacher_area } elseif ($item.domain) { [string]$item.domain } else { '' }
    $tt = if ($item.title) { [string]$item.title } else { '' }
    if (-not $td -or -not $ta -or -not $tt) { continue }
    $key = Get-DedupeKey -TeacherDomain $td -TeacherArea $ta -Title $tt
    if ($key) { $existingSuggestionDedupeKeys[$key] = $true }
}

$approvalCutoffUtc = (Get-Date).ToUniversalTime().AddDays(-7)
$recentApprovalDedupeKeys = @{}
foreach ($item in Convert-ToArray $existingApprovals) {
    if (-not $item) { continue }

    $itemTs = Get-ItemTimestampUtc $item
    if ($itemTs -and $itemTs -lt $approvalCutoffUtc) {
        continue
    }

    $td = if ($item.teacher_domain) { [string]$item.teacher_domain } elseif ($item.area) { [string]$item.area } elseif ($item.component_id) { [string]$item.component_id } else { '' }
    $ta = if ($item.teacher_area) { [string]$item.teacher_area } elseif ($item.domain) { [string]$item.domain } else { '' }
    $tt = if ($item.title) { [string]$item.title } else { '' }
    if (-not $td -or -not $ta -or -not $tt) { continue }
    $key = Get-DedupeKey -TeacherDomain $td -TeacherArea $ta -Title $tt
    if ($key) { $recentApprovalDedupeKeys[$key] = $true }
}

$nowUtc         = (Get-Date).ToUniversalTime().ToString('o')
$generatedStamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss')
$stepSeq        = 0
$accepted       = @()
$rejected       = @()
$batchDedupeKeys = @{}

foreach ($step in $steps) {
    if (-not $step) { continue }
    $stepSeq++

    $idRaw       = if ($step.id) { [string]$step.id } else { "teacher-$generatedStamp-$('{0:000}' -f $stepSeq)" }
    $domainRaw   = Normalize-Token $step.domain
    $areaRaw     = Normalize-Token $step.area
    $title       = if ($step.title) { [string]$step.title } else { "Teacher step $stepSeq" }
    $desc        = if ($step.description) { [string]$step.description } else { '' }
    $operatorSummary = Get-StepOperatorSummary -Summary ([string]$step.operator_summary) -Description $desc -TeacherDomain $domainRaw -TeacherArea $areaRaw
    $risk        = if ($step.risk_level) { ([string]$step.risk_level).ToUpperInvariant() } else { 'R1' }
    $needApprove = if ($null -ne $step.requires_human_approval) { [bool]$step.requires_human_approval } else { $true }

    $reasons = @()
    if (-not ($allowedDomains -contains $domainRaw)) {
        $reasons += "domain '$domainRaw' is not allowed"
    }
    if (-not ($allowedAreas -contains $areaRaw)) {
        $reasons += "area '$areaRaw' is not allowed"
    }
    if (-not ($desc -match '(?i)why\s+this\s+helps\s*:')) {
        $reasons += "description missing required 'Why this helps:' rationale"
    }
    $dedupeKey = Get-DedupeKey -TeacherDomain $domainRaw -TeacherArea $areaRaw -Title $title
    if ($dedupeKey -and $existingSuggestionDedupeKeys.ContainsKey($dedupeKey)) {
        $reasons += "duplicate dedupe key already exists in suggestions: $dedupeKey"
    }
    if ($dedupeKey -and $recentApprovalDedupeKeys.ContainsKey($dedupeKey)) {
        $reasons += "duplicate dedupe key already exists in approvals within last 7 days: $dedupeKey"
    }
    if ($dedupeKey -and $batchDedupeKeys.ContainsKey($dedupeKey)) {
        $reasons += "duplicate dedupe key already exists in this import batch: $dedupeKey"
    }

    $actionList = @()
    foreach ($a in Convert-ToArray $step.actions) {
        $txt = Convert-ActionToText $a
        if (-not $txt) { continue }
        if (-not (Test-IsConcreteAction $txt)) {
            $reasons += "non-concrete action '$txt'"
            continue
        }
        $actionList += $txt
    }
    if ($actionList.Count -eq 0) {
        $reasons += 'missing concrete actions'
    }

    if ($risk -notin @('R0', 'R1', 'R2', 'R3')) {
        $risk = 'R1'
    }

    if ($reasons.Count -gt 0) {
        $rejected += [pscustomobject]@{
            id      = $idRaw
            title   = $title
            reasons = $reasons
        }
        Write-ImportLog -Level 'WARN' -Message 'Rejected teacher step by no-randomness policy.' -Data @{
            id      = $idRaw
            title   = $title
            domain  = $domainRaw
            area    = $areaRaw
            dedupe_key = $dedupeKey
            reasons = $reasons
        }
        continue
    }

    $id = $idRaw
    if ($knownIds.ContainsKey($id)) {
        $suffix = 1
        while ($knownIds.ContainsKey("$idRaw-dup$suffix")) { $suffix++ }
        $id = "$idRaw-dup$suffix"
        Write-ImportLog -Level 'WARN' -Message "Duplicate step id '$idRaw' detected. Rewritten to '$id'."
    }
    $knownIds[$id] = $true
    if ($dedupeKey) { $batchDedupeKeys[$dedupeKey] = $true }

    # Keep "area" as component for downstream queue/selfops compatibility.
    # Preserve teacher functional area in "teacher_area".
    $accepted += [pscustomobject]@{
        id                      = $id
        title                   = $title
        operator_summary        = $operatorSummary
        description             = $desc
        area                    = $domainRaw
        domain                  = $areaRaw
        teacher_domain          = $domainRaw
        teacher_area            = $areaRaw
        dedupe_key              = $dedupeKey
        risk_level              = $risk
        requires_human_approval = $needApprove
        actions                 = $actionList
        source                  = 'teacher'
        created_at              = $nowUtc
        status                  = 'pending'
    }
}

Write-ImportLog -Level 'INFO' -Message ("Accepted {0} step(s); rejected {1} step(s)." -f $accepted.Count, $rejected.Count)

if ($accepted.Count -eq 0) {
    Write-EmptySuggestionsWithReason -Reason 'All teacher steps were rejected by no-randomness validation.' -RejectedCount $rejected.Count
    exit 0
}

# Merge existing + newly accepted steps
$merged = @()
if ($existingSuggestions) {
    $merged += Convert-ToArray $existingSuggestions
}
$merged += $accepted

$merged | ConvertTo-Json -Depth 10 | Set-Content -Path $suggPath -Encoding UTF8

Write-ImportLog -Level 'INFO' -Message 'Wrote teacher suggestions.' -Data @{
    suggestions_path = $suggPath
    total_count      = $merged.Count
    imported_count   = $accepted.Count
    rejected_count   = $rejected.Count
}
