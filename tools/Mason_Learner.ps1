Param(
    [int]$MaxChunks = 50  # kept for compatibility, but not used in safe mode
)

$ErrorActionPreference = "Stop"

# Directories
$ToolsDir   = $PSScriptRoot
$RootDir    = Split-Path $ToolsDir -Parent
$LogsDir    = Join-Path $RootDir "logs"
$ReportsDir = Join-Path $RootDir "reports"
$ConfigDir  = Join-Path $RootDir "config"

if (!(Test-Path $LogsDir))    { New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null }
if (!(Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }
if (!(Test-Path $ConfigDir))  { New-Item -ItemType Directory -Path $ConfigDir  -Force | Out-Null }

$LogPath = Join-Path $LogsDir "Mason_Learner.log"

function Write-LearnLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$Level] $Message"
    Write-Host $line
    try {
        Add-Content -Path $LogPath -Value $line -Encoding UTF8
    }
    catch {
        # If logging fails, don't crash the learner
    }
}

Write-LearnLog "Mason_Learner (SAFE MODE) starting..."
Write-LearnLog "RootDir = $RootDir"
Write-LearnLog "ToolsDir = $ToolsDir"

# ------------------------------------------------------------
# 1) Load learning policy (if present)
# ------------------------------------------------------------

$policyPath = Join-Path $ConfigDir "learn_policy.json"

# Safe defaults:
# - NO auto-ingest (no background API cost)
# - NO auto-web
# - DO run aggregator (cheap + local)
$policy = @{
    auto_ingest_enabled = $false
    auto_web_enabled    = $false
    run_aggregator      = $true
}

if (Test-Path $policyPath) {
    try {
        $json = Get-Content $policyPath -Raw | ConvertFrom-Json

        if ($null -ne $json.auto_ingest_enabled) {
            $policy.auto_ingest_enabled = [bool]$json.auto_ingest_enabled
        }
        if ($null -ne $json.auto_web_enabled) {
            $policy.auto_web_enabled = [bool]$json.auto_web_enabled
        }
        if ($null -ne $json.run_aggregator) {
            $policy.run_aggregator = [bool]$json.run_aggregator
        }

        Write-LearnLog ("Loaded learn_policy.json (auto_ingest_enabled={0}, auto_web_enabled={1}, run_aggregator={2})" -f `
            $policy.auto_ingest_enabled, $policy.auto_web_enabled, $policy.run_aggregator)
    }
    catch {
        Write-LearnLog ("Failed to parse learn_policy.json: {0}" -f $_.Exception.Message) "WARN"
        Write-LearnLog "Using safe defaults: auto_ingest_enabled=false, auto_web_enabled=false, run_aggregator=true" "WARN"
    }
}
else {
    Write-LearnLog "No learn_policy.json found. Using safe defaults: auto_ingest_enabled=false, auto_web_enabled=false, run_aggregator=true"
}

# ------------------------------------------------------------
# 2) Cheap step: refresh aggregated brain (NO API calls)
# ------------------------------------------------------------

if ($policy.run_aggregator) {
    $aggPath = Join-Path $ToolsDir "Mason_Brain_Aggregate.ps1"
    if (Test-Path $aggPath) {
        Write-LearnLog "Running Mason_Brain_Aggregate.ps1 (local aggregation only, no OpenAI cost)"
        try {
            & $aggPath -Base $RootDir
        }
        catch {
            Write-LearnLog ("Mason_Brain_Aggregate.ps1 failed: {0}" -f $_.Exception.Message) "WARN"
        }
    }
    else {
        Write-LearnLog "Aggregator script not found at $aggPath" "WARN"
    }
}
else {
    Write-LearnLog "run_aggregator = false in learn_policy.json. Skipping brain aggregation."
}

# ------------------------------------------------------------
# 3) Auto-ingest learning (DISABLED by default)
# ------------------------------------------------------------

if ($policy.auto_ingest_enabled) {
    $ingestScript = Join-Path $ToolsDir "Mason_LearnFromIngest.ps1"
    if (Test-Path $ingestScript) {
        Write-LearnLog "auto_ingest_enabled = true -> running Mason_LearnFromIngest.ps1 (this WILL use the API)."
        try {
            # We keep MaxChunks available if the ingest script accepts it
            & $ingestScript -MaxChunks $MaxChunks
            $exitCode = $LASTEXITCODE
            Write-LearnLog ("Mason_LearnFromIngest.ps1 finished with exit code {0}" -f $exitCode)
        }
        catch {
            Write-LearnLog ("Mason_LearnFromIngest.ps1 failed: {0}" -f $_.Exception.Message) "ERROR"
        }
    }
    else {
        Write-LearnLog "Mason_LearnFromIngest.ps1 not found at $ingestScript" "WARN"
    }
}
else {
    Write-LearnLog "Auto-ingest learning is DISABLED (auto_ingest_enabled=false). No ingest learning will run in this loop."
}

# ------------------------------------------------------------
# 4) Auto web-learning (DISABLED by default)
# ------------------------------------------------------------

if ($policy.auto_web_enabled) {
    $webScript = Join-Path $ToolsDir "Mason_Learn_From_Web.ps1"
    if (Test-Path $webScript) {
        Write-LearnLog "auto_web_enabled = true -> running Mason_Learn_From_Web.ps1 (this WILL use the API and may be interactive)."
        try {
            & $webScript
            $exitCode = $LASTEXITCODE
            Write-LearnLog ("Mason_Learn_From_Web.ps1 finished with exit code {0}" -f $exitCode)
        }
        catch {
            Write-LearnLog ("Mason_Learn_From_Web.ps1 failed: {0}" -f $_.Exception.Message) "ERROR"
        }
    }
    else {
        Write-LearnLog "Mason_Learn_From_Web.ps1 not found at $webScript" "WARN"
    }
}
else {
    Write-LearnLog "Auto web-learning is DISABLED (auto_web_enabled=false)."
}

Write-LearnLog "Mason_Learner (SAFE MODE) completed."
exit 0
