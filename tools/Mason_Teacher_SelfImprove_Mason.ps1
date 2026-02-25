param(
    # Root of Mason2; default = parent folder of \tools
    [string]$RootDir = $(Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = "Stop"

function Load-JsonSafe {
    param(
        [string]$Path
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    }
    catch {
        # IMPORTANT: avoid "$Path:" which confuses PowerShell
        $msg = "[Teacher] Failed to parse JSON at $Path -> $($_.Exception.Message)"
        Write-Warning $msg
        return $null
    }
}

# --- Paths ---

$reportsDir   = Join-Path $RootDir "reports"
$stateDir     = Join-Path $RootDir "state\knowledge"
$learnDir     = Join-Path $RootDir "learn"
$knowledgeDir = Join-Path $RootDir "knowledge\mason"
$configDir    = Join-Path $RootDir "config"
$secretsPath  = Join-Path $configDir "secrets_mason.json"

New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
New-Item -ItemType Directory -Path $stateDir   -Force | Out-Null

Write-Host "[Teacher] Mason_Teacher_SelfImprove_Mason starting..."
Write-Host ("          Root: {0}" -f $RootDir)

# --- Load context JSONs ---

$selfMap      = Load-JsonSafe (Join-Path $reportsDir "mason_self_map.json")
$riskState    = Load-JsonSafe (Join-Path $reportsDir "risk_state.json")
$ueStatus     = Load-JsonSafe (Join-Path $reportsDir "mason_ue_status.json")
$healthAgg    = Load-JsonSafe (Join-Path $reportsDir "mason_health_aggregated.json")
$topicsConfig = Load-JsonSafe (Join-Path $learnDir   "learn_topics_mason.json")
$autonomyMode = Load-JsonSafe (Join-Path $configDir  "mason_autonomy_mode.json")

# --- Summarize topics ---

$topicIds = @()
if ($topicsConfig -and $topicsConfig.topics) {
    foreach ($t in $topicsConfig.topics) {
        if ($t.id) {
            $topicIds += $t.id
        }
    }
}
$topicsSummary = if ($topicIds.Count -gt 0) { ($topicIds -join ", ") } else { "(no topics found)" }

# --- Sample knowledge files ---

$knowledgeFiles = @()
if (Test-Path -LiteralPath $knowledgeDir) {
    $knowledgeFiles = Get-ChildItem $knowledgeDir -File |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 20 |
        Select-Object FullName, Length, LastWriteTime
}

# --- Build teacher input object ---

$inputObj = @{
    generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    rootDir        = $RootDir
    selfMap        = $selfMap
    riskState      = $riskState
    ueStatus       = $ueStatus
    health         = $healthAgg
    autonomyMode   = $autonomyMode
    topics         = $topicsConfig
    knowledgeFiles = $knowledgeFiles
}

$ts        = Get-Date -Format "yyyyMMdd_HHmmss"
$inputPath = Join-Path $reportsDir ("mason_teacher_input_{0}.json" -f $ts)

$inputObj | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $inputPath -Encoding UTF8

Write-Host "[Teacher] Wrote teacher input snapshot to:"
Write-Host ("          {0}" -f $inputPath)

# --- Load OpenAI API key ---

$apiKey = $null

if (Test-Path -LiteralPath $secretsPath) {
    try {
        $secrets = Get-Content -LiteralPath $secretsPath -Raw | ConvertFrom-Json

        if ($secrets.openai_api_key) {
            $apiKey = $secrets.openai_api_key
            Write-Host "[Teacher] Loaded OpenAI key from secrets_mason.json (openai_api_key)"
        }
        elseif ($secrets.openai -and $secrets.openai.api_key) {
            $apiKey = $secrets.openai.api_key
            Write-Host "[Teacher] Loaded OpenAI key from secrets_mason.json (openai.api_key)"
        }
        else {
            Write-Warning "[Teacher] secrets_mason.json exists but has no openai_api_key field."
        }
    }
    catch {
        Write-Warning ("[Teacher] Failed to parse secrets_mason.json -> {0}" -f $_.Exception.Message)
    }
}

if (-not $apiKey) {
    $apiKey = $env:OPENAI_API_KEY
    if ($apiKey) {
        Write-Host "[Teacher] Loaded OpenAI key from environment variable OPENAI_API_KEY"
    }
}

if (-not $apiKey) {
    throw "[Teacher] No OpenAI API key found. Set config\secrets_mason.json or environment variable OPENAI_API_KEY."
}

# --- Build teacher prompt ---

$prompt = @"
You are an expert AI infrastructure and agent safety architect acting as a "teacher" for a local Windows automation agent called Mason.

You are given Mason's current self-state, including:
- A self-map of his files and components (Mason core, Athena console, Onyx app)
- Current risk policy and autonomy mode
- Recent health and self-heal summaries
- Universal Evolution (UE) status
- Configured learning topics for Mason (self-ops, watchdog, resource guard, security, autonomy, AI infra)
- A sample of recent web-learned knowledge files for Mason

Mason's core mission:
- Keep himself stable, safe, and efficient on Chris's PC.
- Gradually take over more self-maintenance and self-improvement.
- Eventually manage Athena (console/UI) and Onyx (business manager app), always with strong guardrails.

Configured learning topics (IDs): ${topicsSummary}

Your task:
1. Analyze Mason's current state and learning coverage.
2. Propose a concrete, SAFE self-improvement plan that Mason can execute in small steps.
3. Focus on:
   - Stability and safety first (R0/R1)
   - Then performance and efficiency
   - Then deeper AI infra knowledge that helps Mason understand and improve himself

Very important constraints:
- Mason runs on a personal Windows PC with limited resources.
- Mason must NOT make high-risk OS changes, install random system software, or touch user data outside his own folder.
- All changes must be explainable, reversible, and logged.
- When in doubt, downgrade risk or require explicit human approval.

You MUST respond in STRICT JSON ONLY, with this exact top-level shape:

{
  "summary": "<short natural language summary>",
  "steps": [
    {
      "id": "teacher-20260224074530-001",
      "domain": "mason",
      "area": "watchdog",
      "title": "<short step title>",
      "operator_summary": "<plain-English operator summary, max 160 chars>",
      "description": "<what to do>. Why this helps: <explicit user/system value>",
      "risk_level": "R1",
      "requires_human_approval": true,
      "actions": [
        "EDIT tools\\SomeFile.ps1: concrete change details.",
        "TEST powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\\tools\\SomeTest.ps1"
      ]
    }
  ]
}

Hard requirements:
- Return 6 to 10 steps.
- Include at least one step for each domain: mason, athena, onyx.
- id values must be unique in this run and MUST match: teacher-<UTC yyyymmddHHMMSS>-NNN.
- domain must be one of: mason, athena, onyx.
- area must be one of:
  stack, watchdog, ui, security, performance, reliability, logging, approvals,
  notifications, trust_meter, dashboard, tasks, invoices, crm, observability,
  governance, selfops, resource_guard, network, testing.
- risk_level must be one of: R0, R1, R2, R3.
- operator_summary must be non-technical plain English and <= 160 characters.
- description must contain the exact phrase "Why this helps:" with plain-English wording.
- actions must be concrete file edits/tests; no vague items like "improve things".
- Do not include markdown or any non-JSON text.
"@

# --- Build OpenAI request ---

$body = @{
    model    = "gpt-4.1-mini"
    messages = @(
        @{
            role    = "system"
            content = "You are a careful, safety-first AI architect helping a local agent called Mason safely improve himself."
        },
        @{
            role    = "user"
            content = $prompt
        },
        @{
            role    = "user"
            content = ($inputObj | ConvertTo-Json -Depth 8)
        }
    )
    temperature = 0.1
}

$jsonBody = $body | ConvertTo-Json -Depth 8

$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type"  = "application/json"
}

Write-Host "[Teacher] Calling OpenAI teacher API..."

try {
    $response = Invoke-RestMethod -Method Post -Uri "https://api.openai.com/v1/chat/completions" -Headers $headers -Body $jsonBody
}
catch {
    $errTs   = Get-Date -Format "yyyyMMdd_HHmmss"
    $errPath = Join-Path $reportsDir ("mason_teacher_error_{0}.txt" -f $errTs)
    $_ | Out-String | Set-Content -LiteralPath $errPath -Encoding UTF8
    Write-Error "[Teacher] OpenAI API call failed. See error details in: $errPath"
    exit 1
}

# --- Save raw response ---

$rawTs   = Get-Date -Format "yyyyMMdd_HHmmss"
$rawPath = Join-Path $reportsDir ("mason_teacher_output_raw_{0}.json" -f $rawTs)

$response | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $rawPath -Encoding UTF8

Write-Host "[Teacher] Wrote full teacher raw response to:"
Write-Host ("          {0}" -f $rawPath)

# --- Extract JSON content from the model ---

$content = $response.choices[0].message.content

$firstBrace = $content.IndexOf("{")
$lastBrace  = $content.LastIndexOf("}")

if ($firstBrace -ge 0 -and $lastBrace -gt $firstBrace) {
    $jsonText = $content.Substring($firstBrace, $lastBrace - $firstBrace + 1)
}
else {
    $jsonText = $content
}

# --- Parse teacher plan JSON ---

try {
    $planObj = $jsonText | ConvertFrom-Json
}
catch {
    $planErrPath = Join-Path $reportsDir ("mason_teacher_plan_parse_error_{0}.txt" -f $rawTs)
    $jsonText | Set-Content -LiteralPath $planErrPath -Encoding UTF8
    Write-Error "[Teacher] Failed to parse teacher JSON. See raw content in: $planErrPath"
    exit 1
}

# --- Normalise teacher plan schema ---

function Normalize-Token {
    param(
        [string]$Value
    )
    if (-not $Value) { return "" }
    return ($Value.Trim().ToLowerInvariant() -replace '[\s\-]+', '_')
}

function Convert-ActionToText {
    param(
        $Action
    )

    if ($null -eq $Action) { return $null }

    if ($Action -is [string]) {
        $txt = $Action.Trim()
        if (-not $txt) { return $null }
        return $txt
    }

    $desc = if ($Action.description) { [string]$Action.description } else { "" }
    $type = if ($Action.type) { [string]$Action.type } else { "edit" }

    $fileText = ""
    if ($Action.files_touched) {
        $files = @()
        foreach ($f in @($Action.files_touched)) {
            if ($f) { $files += [string]$f }
        }
        if ($files.Count -gt 0) {
            $fileText = (" files={0}" -f ($files -join ","))
        }
    }

    $base = ($desc + $fileText).Trim()
    if (-not $base) { return $null }

    if ($type -match 'test|validate|verification') {
        return "TEST $base"
    }

    return "EDIT $base"
}

function Convert-OperatorSummary {
    param(
        [string]$Summary,
        [string]$Domain,
        [string]$Area,
        [string]$Title,
        [string]$Description
    )

    $candidate = ""
    if ($Summary) {
        $candidate = [string]$Summary
    }
    elseif ($Description -and ($Description -match '(?is)why\s+this\s+helps\s*:\s*(.+)$')) {
        $candidate = [string]$Matches[1]
    }
    elseif ($Title) {
        $candidate = "Improves $Domain/$Area by making '$Title' easier and safer for operators."
    }
    else {
        $candidate = "Improves $Domain/$Area reliability with small, reversible changes."
    }

    $candidate = ($candidate -replace '\s+', ' ').Trim()
    if (-not $candidate) {
        $candidate = "Improves $Domain/$Area reliability with small, reversible changes."
    }

    if ($candidate.Length -gt 160) {
        $candidate = $candidate.Substring(0, 157).TrimEnd() + "..."
    }

    return $candidate
}

function New-DefaultStep {
    param(
        [string]$StepId,
        [string]$Domain,
        [string]$Area
    )

    $title = switch ($Domain) {
        "athena" { "Tighten Athena approvals and trust visibility" }
        "onyx"   { "Stabilize Onyx core business flow performance" }
        default  { "Harden Mason watchdog and safety checks" }
    }

    $desc = switch ($Domain) {
        "athena" {
            "Implement scoped operator-console approval checks and clearer trust meter status. Why this helps: reduces accidental approvals and improves operator confidence."
        }
        "onyx" {
            "Improve dashboard/task/invoice flow responsiveness and error handling with measurable latency checks. Why this helps: speeds up core user workflows and lowers failure rates."
        }
        default {
            "Add bounded restart logic and deterministic health checks in Mason self-ops scripts. Why this helps: reduces restart storms and keeps self-maintenance reliable."
        }
    }

    $operatorSummary = switch ($Domain) {
        "athena" { "Makes Athena approvals clearer and safer for operators." }
        "onyx"   { "Makes core Onyx screens faster and less error-prone for daily use." }
        default  { "Strengthens Mason stability checks so self-maintenance is safer and more reliable." }
    }

    return [pscustomobject]@{
        id                      = $StepId
        domain                  = $Domain
        area                    = $Area
        title                   = $title
        operator_summary        = $operatorSummary
        description             = $desc
        risk_level              = "R1"
        requires_human_approval = $true
        actions                 = @(
            "EDIT tools\\${Domain}_plan_step.ps1: implement scoped change for ${Area}.",
            "TEST powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command `"Write-Host '[TeacherPlan] validate ${Domain}/${Area}'`""
        )
    }
}

$allowedDomains = @("mason", "athena", "onyx")
$allowedAreas   = @(
    "stack", "watchdog", "ui", "security", "performance", "reliability", "logging",
    "approvals", "notifications", "trust_meter", "dashboard", "tasks", "invoices",
    "crm", "observability", "governance", "selfops", "resource_guard", "network", "testing"
)

$rawSteps = @()
if ($planObj -and $planObj.steps) {
    $rawSteps = @($planObj.steps)
}
elseif ($planObj -and $planObj.plan -and $planObj.plan.steps) {
    $rawSteps = @($planObj.plan.steps)
}

$idPrefix = ("teacher-{0}" -f ((Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")))
$stepIndex = 0
$normalizedSteps = @()

foreach ($step in $rawSteps) {
    if (-not $step) { continue }

    $stepIndex++

    $rawDomain = Normalize-Token $step.domain
    $rawArea   = Normalize-Token $step.area

    $domain = if ($allowedDomains -contains $rawDomain) { $rawDomain } elseif ($allowedDomains -contains $rawArea) { $rawArea } else { "mason" }

    $area = $rawArea
    if ($allowedDomains -contains $area) {
        $domainAreaFallback = Normalize-Token $step.domain
        if ($allowedAreas -contains $domainAreaFallback) {
            $area = $domainAreaFallback
        }
        else {
            $area = "stack"
        }
    }
    if (-not ($allowedAreas -contains $area)) {
        $area = "stack"
    }

    $title = if ($step.title) { [string]$step.title } else { "Teacher step $stepIndex" }
    $desc  = if ($step.description) { [string]$step.description } else { "" }
    if (-not ($desc -match '(?i)why\s+this\s+helps\s*:')) {
        if ($desc.Trim().Length -gt 0) {
            $desc = ($desc.TrimEnd('.') + ". Why this helps: this change gives operators clearer, safer, and more reliable behavior.")
        }
        else {
            $desc = "Implement a scoped, low-risk improvement for $domain/$area. Why this helps: this gives operators clearer, safer, and more reliable behavior."
        }
    }
    $operatorSummary = Convert-OperatorSummary -Summary ([string]$step.operator_summary) -Domain $domain -Area $area -Title $title -Description $desc

    $risk = if ($step.risk_level) { ([string]$step.risk_level).ToUpperInvariant() } else { "R1" }
    if ($risk -notin @("R0", "R1", "R2", "R3")) {
        $risk = "R1"
    }

    $requiresApproval = $true
    if ($null -ne $step.requires_human_approval) {
        $requiresApproval = [bool]$step.requires_human_approval
    }
    elseif ($risk -eq "R0") {
        $requiresApproval = $false
    }

    $actions = @()
    foreach ($a in @($step.actions)) {
        $actionText = Convert-ActionToText $a
        if (-not $actionText) { continue }
        if ($actionText -notmatch '^(EDIT|TEST)\s') {
            $actionText = "EDIT $actionText"
        }
        $actions += $actionText
    }
    if ($actions.Count -lt 2) {
        $actions += "EDIT tools\\${domain}_plan_step_$stepIndex.ps1: apply scoped update in $area."
        $actions += "TEST powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command `"Write-Host '[TeacherPlan] verify step $stepIndex'`""
    }

    $stepId = "$idPrefix-{0:000}" -f $stepIndex

    $normalizedSteps += [pscustomobject]@{
        id                      = $stepId
        domain                  = $domain
        area                    = $area
        title                   = $title
        operator_summary        = $operatorSummary
        description             = $desc
        risk_level              = $risk
        requires_human_approval = $requiresApproval
        actions                 = $actions
    }
}

# Ensure at least one step for each domain
$existingDomains = @{}
foreach ($s in $normalizedSteps) {
    if ($s.domain) { $existingDomains[$s.domain] = $true }
}
foreach ($requiredDomain in $allowedDomains) {
    if (-not $existingDomains.ContainsKey($requiredDomain)) {
        $stepIndex++
        $defaultArea = switch ($requiredDomain) {
            "athena" { "approvals" }
            "onyx"   { "dashboard" }
            default  { "watchdog" }
        }
        $normalizedSteps += New-DefaultStep -StepId ("$idPrefix-{0:000}" -f $stepIndex) -Domain $requiredDomain -Area $defaultArea
    }
}

# Ensure minimum of 6 steps
while ($normalizedSteps.Count -lt 6) {
    $stepIndex++
    $domainForFill = $allowedDomains[($stepIndex - 1) % $allowedDomains.Count]
    $areaForFill   = switch ($domainForFill) {
        "athena" { "notifications" }
        "onyx"   { "performance" }
        default  { "reliability" }
    }
    $normalizedSteps += New-DefaultStep -StepId ("$idPrefix-{0:000}" -f $stepIndex) -Domain $domainForFill -Area $areaForFill
}

if ($normalizedSteps.Count -gt 10) {
    $trimmed = @()
    $selectedIds = @{}

    foreach ($requiredDomain in $allowedDomains) {
        $pick = $normalizedSteps | Where-Object { $_.domain -eq $requiredDomain } | Select-Object -First 1
        if ($pick -and -not $selectedIds.ContainsKey($pick.id)) {
            $trimmed += $pick
            $selectedIds[$pick.id] = $true
        }
    }

    foreach ($step in $normalizedSteps) {
        if ($trimmed.Count -ge 10) { break }
        if ($selectedIds.ContainsKey($step.id)) { continue }
        $trimmed += $step
        $selectedIds[$step.id] = $true
    }

    $normalizedSteps = @($trimmed | Select-Object -First 10)
}

$summary = if ($planObj -and $planObj.summary) { [string]$planObj.summary } else { "Teacher-generated scoped self-improvement plan for Mason, Athena, and Onyx." }

$planObj = [pscustomobject]@{
    summary = $summary
    steps   = $normalizedSteps
}

# --- Save plan ---

$planPath   = Join-Path $reportsDir ("mason_teacher_plan_{0}.json" -f $rawTs)
$latestPath = Join-Path $stateDir  "mason_teacher_plan_latest.json"

$planObj | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $planPath   -Encoding UTF8
$planObj | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $latestPath -Encoding UTF8

Write-Host "[Teacher] Wrote teacher plan JSON to:"
Write-Host ("          {0}" -f $planPath)
Write-Host "[Teacher] Updated latest teacher plan at:"
Write-Host ("          {0}" -f $latestPath)
