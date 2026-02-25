param(
    [string]$RootDir = ""
)

# ====================================================================
# Mason_Teacher_Execute_R1_SelfOps.ps1
#
# Executes Mason self-ops patches for teacher-sourced approvals
# at risk levels R1–R2 (Mason + later Athena components).
#
# Flow:
#   1. Load pending_patch_runs.json (approvals) and filter to Mason/Athena R1–R2 items with status=approve.
#   2. Build a self-ops patch request and call OpenAI to generate patch plan.
#   3. Apply patches to target files (creating them if they don't exist yet).
#   4. Mark approvals + suggestions as executed with executed_at timestamp.
#
# ====================================================================

if (-not $RootDir -or $RootDir.Trim() -eq "") {
    $RootDir = (Split-Path -Parent $PSScriptRoot)
}

Write-Host "[ExecR1] Mason_Teacher_Execute_R1_SelfOps starting..."
Write-Host "[ExecR1] Root: $RootDir"

$stateDir   = Join-Path $RootDir "state\knowledge"
$toolsDir   = Join-Path $RootDir "tools"
$reportsDir = Join-Path $RootDir "reports"

if (-not (Test-Path $stateDir))   { throw "[ExecR1] State dir not found: $stateDir" }
if (-not (Test-Path $toolsDir))   { throw "[ExecR1] Tools dir not found: $toolsDir" }
if (-not (Test-Path $reportsDir)) { New-Item -ItemType Directory -Path $reportsDir | Out-Null }

$approvalsPath     = Join-Path $stateDir   "pending_patch_runs.json"
$selfOpsPatchesOut = Join-Path $stateDir   "mason_teacher_selfops_patches_latest.json"
$inputSnapshotPath = Join-Path $reportsDir ("mason_teacher_selfops_input_{0}.json" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$outputRawPath     = Join-Path $reportsDir ("mason_teacher_selfops_output_raw_{0}.json" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

if (-not (Test-Path $approvalsPath)) {
    Write-Host "[ExecR1] No pending_patch_runs.json found. Nothing to do."
    return
}

# --------------------------------------------------------------------
# Load approvals and select teacher-sourced Mason/Athena R1–R2 items
# --------------------------------------------------------------------
$approvalsRaw = Get-Content $approvalsPath -Raw
if (-not $approvalsRaw) {
    Write-Host "[ExecR1] pending_patch_runs.json is empty. Nothing to do."
    return
}

$approvals = $approvalsRaw | ConvertFrom-Json
if (-not $approvals) {
    Write-Host "[ExecR1] No approvals parsed from pending_patch_runs.json. Nothing to do."
    return
}

# Filter to teacher-sourced Mason/Athena approvals at R1–R2 that are marked approve
$r1Approvals = $approvals | Where-Object {
    $_.source       -eq "teacher" -and
    ($_.component_id -eq "mason" -or $_.component_id -eq "athena") -and
    $_.risk_level      -in @("R1","R2") -and
    $_.status       -eq "approve" -and
    $_.kind         -eq "patch_run"
}

if (-not $r1Approvals -or $r1Approvals.Count -eq 0) {
    Write-Host "[ExecR1] No Mason approvals at R1-R2 with status=approve. Nothing to execute."
    return
}

Write-Host ("[ExecR1] Found {0} Mason approval(s) at R1-R2 ready:" -f $r1Approvals.Count)
foreach ($a in $r1Approvals) {
    Write-Host ("  {0} - {1}" -f $a.id, $a.title)
}

# --------------------------------------------------------------------
# Build teacher self-ops input
# --------------------------------------------------------------------
$teacherInput = [pscustomobject]@{
    root_dir     = $RootDir
    timestamp    = (Get-Date).ToUniversalTime().ToString("o")
    component_id = "mason"
    approvals    = @()
}

foreach ($a in $r1Approvals) {
    $teacherInput.approvals += [pscustomobject]@{
        id           = $a.id
        title        = $a.title
        area         = $a.area
        domain       = $a.domain
        risk_level   = $a.risk_level
        status       = $a.status
        kind         = $a.kind
        component_id = $a.component_id
    }
}

$teacherInput | ConvertTo-Json -Depth 8 | Set-Content $inputSnapshotPath -Encoding UTF8
Write-Host "[ExecR1] Wrote raw self-ops input snapshot to:"
Write-Host "         $inputSnapshotPath"

# --------------------------------------------------------------------
# Load OpenAI key
# --------------------------------------------------------------------
$secretsPath = Join-Path $RootDir "secrets_mason.json"
if (-not (Test-Path $secretsPath)) {
    throw "[ExecR1] secrets_mason.json not found at $secretsPath"
}

$secrets = Get-Content $secretsPath -Raw | ConvertFrom-Json
$openaiKey = $secrets.openai_api_key
if (-not $openaiKey) {
    throw "[ExecR1] openai_api_key missing in secrets_mason.json"
}

Write-Host "[ExecR1] Loaded OpenAI key from secrets_mason.json"
Write-Host "[ExecR1] Calling OpenAI API for self-ops patches..."

# --------------------------------------------------------------------
# Build OpenAI request body
# --------------------------------------------------------------------
$systemPrompt = @"
You are Mason's self-ops patch planner.

Context:
- Mason is a local AI "brain" running on Chris's PC.
- You are only allowed to propose low-to-medium risk (R1–R2) self-ops changes for Mason itself (and Athena later).
- Chris wants Mason to autonomously upgrade and harden his own operations, watchdogs, resource guards, and security,
  while staying safe and reversible.

Your task:
- You are given teacher-approved R1-R2 patch_run approvals from pending_patch_runs.json.
- For each approval, propose one or more file-level patches that Mason can apply to his own PowerShell tools.
- Each patch must reference an existing or new target file under the Mason tools directory.
- Patches should be self-contained and idempotent (running more than once is safe).
- Prefer additive changes (new functions, small wrappers) over huge rewrites.

Output JSON format:
{
  "patches": [
    {
      "id": "patch-001",
      "approval_id": "teacher-mason-plan-002",
      "description": "Short human description",
      "target_file": "tools\\Mason_Watchdog.ps1",
      "patch_type": "append_or_create",
      "patch_body": "<PowerShell code to append or create>"
    }
  ]
}
"@

$userPrompt = @"
Mason has the following R1-R2 teacher-approved self-ops tasks (patch_run approvals):

$($r1Approvals | ConvertTo-Json -Depth 6)

Please propose concrete, safe, incremental PowerShell patches that implement these tasks. Focus on:
- watchdog improvements (prevent restart storms, better health checks),
- resource guard and log rotation,
- security and isolation (within process, no destructive actions),
- config ergonomics for future tuning.

Remember:
- Only affect Mason's own files (tools\\*.ps1).
- Do NOT modify Windows system files.
- Prefer creating or appending helper scripts (e.g., Mason_Watchdog.ps1, Mason_ResourceGuard.ps1, Mason_Config.ps1).
"@

$body = @{
    model    = "gpt-4.1-mini"
    messages = @(
        @{ role = "system"; content = $systemPrompt },
        @{ role = "user";   content = $userPrompt }
    )
    response_format = @{ type = "json_object" }
} | ConvertTo-Json -Depth 8

# --------------------------------------------------------------------
# Call OpenAI
# --------------------------------------------------------------------
$headers = @{
    "Authorization" = "Bearer $openaiKey"
    "Content-Type"  = "application/json"
}

try {
    $response = Invoke-RestMethod -Method Post -Uri "https://api.openai.com/v1/chat/completions" -Headers $headers -Body $body
} catch {
    $_ | Out-String | Set-Content (Join-Path $reportsDir ("mason_teacher_selfops_error_{0}.txt" -f (Get-Date -Format "yyyyMMdd_HHmmss")))
    throw "[ExecR1] OpenAI API call failed. See error file in reports."
}

# Save raw response
$response | ConvertTo-Json -Depth 10 | Set-Content $outputRawPath -Encoding UTF8
Write-Host "[ExecR1] Wrote raw self-ops response to:"
Write-Host "          $outputRawPath"

# Extract patches
if (-not $response.choices -or -not $response.choices[0].message.content) {
    throw "[ExecR1] Unexpected OpenAI response; no choices[0].message.content"
}

$patchPayload = $response.choices[0].message.content | ConvertFrom-Json
if (-not $patchPayload -or -not $patchPayload.patches) {
    throw "[ExecR1] No 'patches' array returned by teacher."
}

$patches = $patchPayload.patches
$patches | ConvertTo-Json -Depth 8 | Set-Content $selfOpsPatchesOut -Encoding UTF8
Write-Host "[ExecR1] Saved self-ops patch plan to:"
Write-Host "         $selfOpsPatchesOut"

# --------------------------------------------------------------------
# Apply patches
# --------------------------------------------------------------------
foreach ($p in $patches) {
    $targetRel = $p.target_file
    if (-not $targetRel) {
        Write-Warning "[ExecR1] Patch missing target_file: $($p.id). Skipping."
        continue
    }

    $targetPath = Join-Path $RootDir $targetRel

    if (-not (Test-Path (Split-Path $targetPath -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path $targetPath -Parent) -Force | Out-Null
    }

    if (-not (Test-Path $targetPath)) {
        Write-Host ("[ExecR1] Target file did not exist; creating new file: {0} (patch {1}, plan {2})..." -f $targetPath, $p.id, $p.approval_id)
        $p.patch_body | Set-Content $targetPath -Encoding UTF8
    }
    else {
        Write-Host ("[ExecR1] Appending patch {0} (plan {1}) to {2}..." -f $p.id, $p.approval_id, $targetPath)
        Add-Content -Path $targetPath -Value "`n`n# === Mason teacher patch {0} (plan {1}) ===`n" -f $p.id, $p.approval_id
        Add-Content -Path $targetPath -Value $p.patch_body
        Add-Content -Path $targetPath -Value "`n# === end Mason teacher patch {0} ===`n" -f $p.id
    }
}

# --------------------------------------------------------------------
# Mark approvals & suggestions as executed
# --------------------------------------------------------------------
$nowUtc = (Get-Date).ToUniversalTime().ToString("o")

# 1) Update approvals
foreach ($a in $approvals) {
    if ($a.source -eq "teacher" -and
        ($a.component_id -eq "mason" -or $a.component_id -eq "athena") -and
        $a.risk_level -in @("R1","R2") -and
        $a.status -eq "approve") {

        $a.status = "executed"

        # Ensure executed_at property exists before setting
        if (-not ($a.PSObject.Properties.Name -contains "executed_at")) {
            $a | Add-Member -NotePropertyName "executed_at" -NotePropertyValue $nowUtc
        }
        else {
            $a.executed_at = $nowUtc
        }
    }
}

$approvals | ConvertTo-Json -Depth 8 | Set-Content $approvalsPath -Encoding UTF8
Write-Host "[ExecR1] Updated approvals file with executed status."

# 2) Update mason_teacher_suggestions.json
$suggestionsPath = Join-Path $stateDir "mason_teacher_suggestions.json"
if (Test-Path $suggestionsPath) {
    $suggestionsRaw = Get-Content $suggestionsPath -Raw
    if ($suggestionsRaw) {
        $suggestions = $suggestionsRaw | ConvertFrom-Json
        foreach ($s in $suggestions) {
            if ($s.id -and $r1Approvals.id -contains $s.id) {
                $s.status = "executed"
                if (-not ($s.PSObject.Properties.Name -contains "executed_at")) {
                    $s | Add-Member -NotePropertyName "executed_at" -NotePropertyValue $nowUtc
                }
                else {
                    $s.executed_at = $nowUtc
                }
            }
        }
        $suggestions | ConvertTo-Json -Depth 8 | Set-Content $suggestionsPath -Encoding UTF8
        Write-Host "[ExecR1] Updated mason_teacher_suggestions.json for executed plans."
    }
}

Write-Host ("[ExecR1] Applied {0} patch(es) and finished R1-R2 self-ops execution." -f $patches.Count)
