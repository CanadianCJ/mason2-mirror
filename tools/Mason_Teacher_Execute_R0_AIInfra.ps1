param(
    [string]$RootDir = $(Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = "Stop"

function Load-JsonSafe {
    param(
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        return $null
    }
    try {
        return Get-Content $Path -Raw | ConvertFrom-Json
    }
    catch {
        Write-Error "[ExecR0] Failed to parse JSON at $Path - $($_.Exception.Message)"
        return $null
    }
}

Write-Host "[ExecR0] Mason_Teacher_Execute_R0_AIInfra starting..."
Write-Host "         Root: $RootDir"

# --- Paths ---
$stateDir     = Join-Path $RootDir "state\knowledge"
$learnDir     = Join-Path $RootDir "learn"
$knowledgeDir = Join-Path $RootDir "knowledge\mason"
$reportsDir   = Join-Path $RootDir "reports"

New-Item -ItemType Directory -Path $stateDir     -Force | Out-Null
New-Item -ItemType Directory -Path $learnDir     -Force | Out-Null
New-Item -ItemType Directory -Path $knowledgeDir -Force | Out-Null
New-Item -ItemType Directory -Path $reportsDir   -Force | Out-Null

$approvalsPath   = Join-Path $stateDir "pending_patch_runs.json"
$suggestionsPath = Join-Path $stateDir "mason_teacher_suggestions.json"
$topicsPath      = Join-Path $learnDir "learn_topics_mason.json"

# --- Load JSON state ---
$suggestions = Load-JsonSafe $suggestionsPath
$approvals   = Load-JsonSafe $approvalsPath
$topicsCfg   = Load-JsonSafe $topicsPath

if (-not $suggestions) {
    Write-Error "[ExecR0] No mason_teacher_suggestions.json found or it is invalid."
    exit 1
}
if (-not $approvals) {
    Write-Error "[ExecR0] No pending_patch_runs.json found or it is invalid."
    exit 1
}
if (-not $topicsCfg) {
    Write-Error "[ExecR0] No learn_topics_mason.json found or it is invalid."
    exit 1
}

# --- Find the approved AI infra R0 plan (teacher-mason-plan-005) ---
$aiApproval = $null
foreach ($a in $approvals) {
    if ($a.id -eq "teacher-mason-plan-005") {
        $aiApproval = $a
        break
    }
}

if (-not $aiApproval) {
    Write-Host "[ExecR0] No approval entry found for teacher-mason-plan-005. Nothing to do."
    exit 0
}

if ($aiApproval.status -eq "executed") {
    Write-Host "[ExecR0] teacher-mason-plan-005 is already executed. Nothing to do."
    exit 0
}

if ($aiApproval.status -ne "approve") {
    Write-Host "[ExecR0] teacher-mason-plan-005 is not approved (status=$($aiApproval.status)). Nothing to do."
    exit 0
}

# Map to suggestion id mason-plan-005
$aiSuggestion = $suggestions | Where-Object { $_.id -eq "mason-plan-005" }

if (-not $aiSuggestion) {
    Write-Error "[ExecR0] Could not find suggestion with id mason-plan-005 in mason_teacher_suggestions.json."
    exit 1
}

Write-Host "[ExecR0] Found AI infra suggestion:"
Write-Host "         $($aiSuggestion.id) - $($aiSuggestion.title)"
Write-Host "         risk_level=$($aiSuggestion.risk_level), status=$($aiSuggestion.status)"

# --- Ensure AI infra topics are enabled ---
$topicIdsToEnable = @("mason_ai_infra_basics", "mason_ai_tools_discovery")
$topicsChanged = $false

if ($topicsCfg.topics) {
    foreach ($t in $topicsCfg.topics) {
        if ($topicIdsToEnable -contains $t.id) {
            if (-not $t.enabled) {
                $t.enabled = $true
                $topicsChanged = $true
                Write-Host "[ExecR0] Enabled topic $($t.id) in learn_topics_mason.json"
            }
        }
    }

    if ($topicsChanged) {
        $topicsCfg | ConvertTo-Json -Depth 8 | Set-Content $topicsPath -Encoding UTF8
        Write-Host "[ExecR0] Saved updated learn_topics_mason.json"
    }
    else {
        Write-Host "[ExecR0] AI infra topics already enabled."
    }
}
else {
    Write-Warning "[ExecR0] topicsCfg has no 'topics' array."
}

# --- Trigger fresh learning for the AI infra topics ---
$learnScript = Join-Path $RootDir "tools\Mason_Learn_From_Web.ps1"

if (-not (Test-Path $learnScript)) {
    Write-Warning "[ExecR0] Mason_Learn_From_Web.ps1 not found at $learnScript. Skipping web learn calls."
}
else {
    foreach ($tid in $topicIdsToEnable) {
        Write-Host "[ExecR0] Triggering Mason_Learn_From_Web for topic $tid..."
        & $learnScript -Topic $tid -Area "mason"
    }
}

# --- Mark plan as executed (safely add properties if missing) ---
$nowUtc = (Get-Date).ToUniversalTime().ToString("o")

# Update approval object
$aiApproval.status = "executed"

if ($aiApproval.PSObject.Properties.Name -contains 'executed_at') {
    $aiApproval.executed_at = $nowUtc
}
else {
    $aiApproval | Add-Member -NotePropertyName 'executed_at' -NotePropertyValue $nowUtc
}

if ($aiApproval.PSObject.Properties.Name -contains 'decision_by') {
    if (-not $aiApproval.decision_by) {
        $aiApproval.decision_by = "owner"
    }
}
else {
    $aiApproval | Add-Member -NotePropertyName 'decision_by' -NotePropertyValue "owner"
}

$approvals | ConvertTo-Json -Depth 8 | Set-Content $approvalsPath -Encoding UTF8
Write-Host "[ExecR0] Updated pending_patch_runs.json for teacher-mason-plan-005 (status=executed)."

# Update suggestion object
$aiSuggestion.status = "executed"

if ($aiSuggestion.PSObject.Properties.Name -contains 'executed_at') {
    $aiSuggestion.executed_at = $nowUtc
}
else {
    $aiSuggestion | Add-Member -NotePropertyName 'executed_at' -NotePropertyValue $nowUtc
}

$suggestions | ConvertTo-Json -Depth 8 | Set-Content $suggestionsPath -Encoding UTF8
Write-Host "[ExecR0] Updated mason_teacher_suggestions.json for mason-plan-005 (status=executed)."

Write-Host "[ExecR0] AI infra R0 execution completed."
