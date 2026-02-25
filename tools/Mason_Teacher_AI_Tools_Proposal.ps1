param(
    [string]$RootDir = $(Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = "Stop"

Write-Host "[AITools] Mason_Teacher_AI_Tools_Proposal starting..."
Write-Host "         Root: $RootDir"

# --- Paths ---
$reportsDir   = Join-Path $RootDir "reports"
$stateDir     = Join-Path $RootDir "state\knowledge"
$configDir    = Join-Path $RootDir "config"
$secretsPath  = Join-Path $configDir "secrets_mason.json"
$catalogPath  = Join-Path $stateDir  "mason_ai_tools_catalog.json"

# Make sure directories exist
New-Item -ItemType Directory -Path $reportsDir -Force   | Out-Null
New-Item -ItemType Directory -Path $stateDir  -Force   | Out-Null

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
        $msg = $_.Exception.Message
        Write-Warning ("[AITools] Failed to parse JSON at {0}: {1}" -f $Path, $msg)
        return $null
    }
}

# --- Load some context (self map + topics) ---
$selfMapPath   = Join-Path $reportsDir "mason_self_map.json"
$topicsPath    = Join-Path $RootDir   "learn\learn_topics_mason.json"

$selfMap       = Load-JsonSafe $selfMapPath
$topicsConfig  = Load-JsonSafe $topicsPath

$topicIds = @()
if ($topicsConfig -and $topicsConfig.topics) {
    foreach ($t in $topicsConfig.topics) {
        if ($t.id) { $topicIds += $t.id }
    }
}
$topicsSummary = if ($topicIds.Count -gt 0) { ($topicIds -join ", ") } else { "(no topics found)" }

# --- Load OpenAI key ---
$apiKey = $null

if (Test-Path $secretsPath) {
    try {
        $secrets = Get-Content $secretsPath -Raw | ConvertFrom-Json
        if ($secrets.openai_api_key) {
            $apiKey = $secrets.openai_api_key
            Write-Host "[AITools] Loaded OpenAI key from secrets_mason.json"
        }
        elseif ($secrets.openai.api_key) {
            # Back-compat with nested format
            $apiKey = $secrets.openai.api_key
            Write-Host "[AITools] Loaded OpenAI key from secrets_mason.json (openai.api_key)"
        }
    }
    catch {
        $msg = $_.Exception.Message
        Write-Warning ("[AITools] Failed to parse secrets_mason.json: {0}" -f $msg)
    }
}

if (-not $apiKey) {
    $apiKey = $env:OPENAI_API_KEY
    if ($apiKey) {
        Write-Host "[AITools] Loaded OpenAI key from environment variable OPENAI_API_KEY"
    }
}

if (-not $apiKey) {
    throw "[AITools] No OpenAI API key found. Set config\secrets_mason.json or environment variable OPENAI_API_KEY."
}

# --- Build prompt for tools catalog ---
$prompt = @"
You are an expert AI tools architect helping a local Windows agent called Mason.

Mason runs at: $RootDir

You are given high-level context:
- Self map (paths, components): summarized in INPUT JSON.
- Configured learning topics: $topicsSummary

Mason's mission for AI tools:
- Discover existing, production-ready AI services, libraries, and CLIs he can call FROM WINDOWS to improve:
  - his own stability and self-healing,
  - his own code quality and refactoring,
  - his own monitoring and logging,
  - safe use of external AI models (including OpenAI) for planning and code review.
- Only tools that can be driven non-interactively (CLI, HTTP APIs, or local libraries) and are safe for a personal PC.

You MUST respond in STRICT JSON with this exact shape (NO extra text):

{
  "summary": "<short natural language summary>",
  "priority": "<low|medium|high>",
  "categories": [
    {
      "id": "core_self_ops",
      "label": "Core self-ops & health",
      "description": "Tools that help Mason observe, log, and heal himself."
    },
    {
      "id": "code_quality",
      "label": "Code review & refactoring",
      "description": "Tools that help Mason analyze and upgrade his own scripts."
    },
    {
      "id": "ai_infra",
      "label": "AI infrastructure",
      "description": "Tools and services for model usage, evaluation, and orchestration."
    }
  ],
  "tools": [
    {
      "id": "tool-001",
      "name": "<tool name>",
      "category_id": "<one of: core_self_ops | code_quality | ai_infra>",
      "kind": "<cli|service|library>",
      "risk_level": "<R0|R1>",
      "description": "<what the tool does and why it's useful for Mason>",
      "integration_idea": "<how Mason could realistically call this tool from Windows PowerShell>",
      "notes": "<constraints, limits, or safety considerations>"
    }
  ]
}
"@

# --- Build OpenAI request body (same pattern as working Teacher script) ---
$inputObj = @{
    generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    rootDir        = $RootDir
    selfMap        = $selfMap
    topics         = $topicsConfig
}

$body = @{
    model    = "gpt-4.1-mini"
    messages = @(
        @{
            role    = "system"
            content = "You are a careful, safety-first AI tools architect helping Mason discover external tools."
        },
        @{
            role    = "user"
            content = $prompt
        },
        @{
            role    = "user"
            content = ($inputObj | ConvertTo-Json -Depth 6)
        }
    )
    temperature = 0.15
}

$jsonBody = $body | ConvertTo-Json -Depth 8

$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Content-Type"  = "application/json"
}

Write-Host "[AITools] Calling OpenAI API for tools catalog..."

try {
    $response = Invoke-RestMethod -Method Post -Uri "https://api.openai.com/v1/chat/completions" -Headers $headers -Body $jsonBody
}
catch {
    $errTs   = Get-Date -Format "yyyyMMdd_HHmmss"
    $errPath = Join-Path $reportsDir ("mason_ai_tools_error_{0}.txt" -f $errTs)
    $_ | Out-String | Set-Content $errPath -Encoding UTF8
    Write-Error "[AITools] OpenAI API call failed. See error details in: $errPath"
    exit 1
}

# --- Save raw response ---
$rawTs   = Get-Date -Format "yyyyMMdd_HHmmss"
$rawPath = Join-Path $reportsDir ("mason_ai_tools_output_raw_{0}.json" -f $rawTs)
$response | ConvertTo-Json -Depth 8 | Set-Content $rawPath -Encoding UTF8
Write-Host "[AITools] Wrote full AI tools raw response to:"
Write-Host "         $rawPath"

# --- Extract JSON from content ---
$content = $response.choices[0].message.content
$firstBrace = $content.IndexOf("{")
$lastBrace  = $content.LastIndexOf("}")

if ($firstBrace -ge 0 -and $lastBrace -gt $firstBrace) {
    $jsonText = $content.Substring($firstBrace, $lastBrace - $firstBrace + 1)
}
else {
    $jsonText = $content
}

try {
    $catalog = $jsonText | ConvertFrom-Json
}
catch {
    $errPath = Join-Path $reportsDir ("mason_ai_tools_catalog_parse_error_{0}.txt" -f $rawTs)
    $jsonText | Set-Content $errPath -Encoding UTF8
    Write-Error "[AITools] Failed to parse AI tools JSON. See raw content in: $errPath"
    exit 1
}

# --- Save catalog into state so Mason can use it later ---
$catalog | ConvertTo-Json -Depth 8 | Set-Content $catalogPath -Encoding UTF8
Write-Host "[AITools] Saved AI tools catalog to:"
Write-Host "         $catalogPath"
Write-Host "[AITools] Done."
