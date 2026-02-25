param()

$ErrorActionPreference = "Stop"

$basePath      = "C:\Users\Chris\Desktop\Mason2"
$reportsFolder = Join-Path $basePath "reports"
$policiesFolder = Join-Path $basePath "policies"
$logsFolder    = Join-Path $basePath "logs"

$statePath     = Join-Path $reportsFolder "mason_self_state.json"
$reviewPath    = Join-Path $reportsFolder "mason_self_review.json"
$onyxHealthPath = Join-Path $reportsFolder "onyx_code_health.json"
$policyPath    = Join-Path $policiesFolder "Mason_AutonomyPolicy.json"

$outputPath    = Join-Path $reportsFolder "mason_brain_context.json"
$logPath       = Join-Path $logsFolder "mason_brain_context.log"

if (-not (Test-Path $logsFolder)) {
    New-Item -ItemType Directory -Path $logsFolder -ErrorAction SilentlyContinue | Out-Null
}

function Write-Log {
    param(
        [string]$Message
    )
    $ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    Add-Content -Path $logPath -Value "[$ts] $Message"
}

Write-Log "=== Mason_Brain_Context_Builder started ==="

# Helpers to load JSON safely
function Load-JsonOrNull {
    param(
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        return $null
    }
    try {
        $raw = Get-Content -Path $Path -Raw
        if (-not $raw) { return $null }
        return ($raw | ConvertFrom-Json)
    }
    catch {
        Write-Log "Failed to parse json at $Path : $_"
        return $null
    }
}

# Load pieces
$selfState   = Load-JsonOrNull -Path $statePath
$selfReview  = Load-JsonOrNull -Path $reviewPath
$onyxHealth  = Load-JsonOrNull -Path $onyxHealthPath
$policy      = Load-JsonOrNull -Path $policyPath

# Extract latest N tasks from selfReview
$latestTasks = @()
if ($selfReview -and $selfReview.stability_history -and $selfReview.stability_history.latestTasks) {
    # Take up to last 10
    $all = $selfReview.stability_history.latestTasks
    if ($all.Count -gt 10) {
        $latestTasks = $all | Select-Object -Last 10
    } else {
        $latestTasks = $all
    }
}

# Build a trimmed autonomy policy view (we don't need every note in the brain call)
$policySummary = $null
if ($policy) {
    $policySummary = [PSCustomObject]@{
        version = $policy.version
        levels  = $policy.levels
        areas   = $policy.areas
    }
}

$nowUtc = [DateTime]::UtcNow

$context = [PSCustomObject]@{
    generated_at_utc        = $nowUtc.ToString("o")
    mason_self_state        = $selfState
    stability_history_latest = $latestTasks
    onyx_health             = $onyxHealth
    pc_high_ram             = $(if ($selfReview) { $selfReview.pc_high_ram } else { $null })
    autonomy_policy         = $policySummary
}

# Wrap in a root object ready for brain calls
$root = [PSCustomObject]@{
    type    = "mason_brain_context"
    version = 1
    context = $context
}

try {
    if (-not (Test-Path $reportsFolder)) {
        New-Item -ItemType Directory -Path $reportsFolder -ErrorAction SilentlyContinue | Out-Null
    }

    $json = $root | ConvertTo-Json -Depth 10
    Set-Content -Path $outputPath -Value $json -Encoding UTF8
    Write-Log "Wrote Mason brain context to $outputPath."
}
catch {
    Write-Log "Failed to write mason_brain_context.json: $_"
    exit 1
}

Write-Log "=== Mason_Brain_Context_Builder completed ==="
