param(
    [string]$RootPath = "C:\Users\Chris\Desktop\Mason2"
)

$ErrorActionPreference = "Stop"

$reportsDir = Join-Path $RootPath "reports"
if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

$patchPlanPath = Join-Path $reportsDir "mason_patch_plan.json"
$logFile       = Join-Path $reportsDir "mason_patch_request_log.txt"

function Write-ReqLog {
    param([string]$Message)
    $line = "$(Get-Date -Format o) `t $Message"
    Add-Content -LiteralPath $logFile -Value $line
    Write-Host $Message
}

Write-ReqLog "=== Mason Request PatchPlan START ==="
Write-ReqLog "RootPath = $RootPath"

# NOTE: use ONLY plain ASCII characters here (no fancy dashes / smart quotes)
$prompt = @"
Mason, propose 1-4 LOW-RISK self-improvement patches inside Mason2.

You have, via your system prompt, summaries of:
- reports\self_index.json
- reports\mason_health_aggregated.json
- reports\mason_self_state.json (or self_state.json)
- reports\athena_dashboard_status.json
- reports\mason_legacy_index.json (legacy, read-only)
- persistent_memory.json

Goal: create or refresh HUMAN-READABLE docs and notes that explain:
- your mission and UE loop,
- my money goals,
- the roles of Athena and Onyx,
- your current self-state and guardrails.

RULES (very strict):
- ONLY use mode = "create_or_replace".
- ONLY target these exact paths (relative to Mason2 root):
  - docs\\mason2_overview.txt
  - docs\\ue_loop_vision.txt
  - docs\\athena_and_onyx_roles.txt
  - reports\\mason_self_state_notes.txt
- Do NOT target any other file.
- area MUST be "mason".
- risk_level MUST be 0.
- auto_apply MUST be true.
- new_content MUST contain the full desired file content (plain text).
- match and replacement can be empty strings for create_or_replace.
- Do NOT design or enable any real money or billing flows.
- Do NOT delete anything.

OUTPUT FORMAT:
Return VALID JSON ONLY (no markdown, no ``` fences) with this shape:

{
  "patches": [
    {
      "id": "short_snake_case_id",
      "area": "mason",
      "risk_level": 0,
      "auto_apply": true,
      "target_relative": "one_of_the_allowed_paths_above",
      "mode": "create_or_replace",
      "match": "",
      "replacement": "",
      "new_content": "full file content here"
    }
  ]
}
"@

# Build JSON body (PowerShell object -> JSON string)
$payload = @{
    message = $prompt
    mode    = "smart"
}

$body = $payload | ConvertTo-Json -Depth 5

Write-ReqLog "Request body JSON preview (first 300 chars):"
if ($body.Length -gt 300) {
    Write-ReqLog ($body.Substring(0,300) + " ...")
} else {
    Write-ReqLog $body
}

Write-ReqLog "POSTing to Mason /api/chat for patch plan..."

# IMPORTANT: send UTF-8 bytes so Mason's API can parse correctly
$utf8  = [System.Text.Encoding]::UTF8
$bytes = $utf8.GetBytes($body)

$response = Invoke-WebRequest `
    -Uri "http://127.0.0.1:8484/api/chat" `
    -Method POST `
    -ContentType "application/json; charset=utf-8" `
    -Body $bytes

$json = $response.Content | ConvertFrom-Json
$replyText = $json.reply

# Mason's reply SHOULD already be a raw JSON string.
$replyJson = $replyText

# Strip markdown ``` fences if Mason adds them
if ($replyJson -match '(?s)```json\s*(?<inner>{.*})\s*```') {
    $replyJson = $Matches.inner
} elseif ($replyJson -match '(?s)```\s*(?<inner>{.*})\s*```') {
    $replyJson = $Matches.inner
}

# Validate that what we got is valid JSON
try {
    $null = $replyJson | ConvertFrom-Json
} catch {
    Write-ReqLog "ERROR: Mason reply is not valid JSON: $($_.Exception.Message)"
    Write-ReqLog "Raw reply:"
    Write-ReqLog $replyText
    throw
}

$replyJson | Set-Content -LiteralPath $patchPlanPath -Encoding UTF8

Write-ReqLog "Wrote patch plan to $patchPlanPath"
Write-ReqLog "=== Mason Request PatchPlan END ==="
Write-Host "Patch plan saved to $patchPlanPath"
