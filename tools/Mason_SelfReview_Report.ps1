param()

$ErrorActionPreference = "Stop"

# Infer base paths
$toolsPath    = $PSScriptRoot
$basePath     = Split-Path $toolsPath -Parent
$logsPath     = Join-Path $basePath "logs"
$reportsPath  = Join-Path $basePath "reports"

# Make sure reports exists
if (-not (Test-Path $reportsPath)) {
    New-Item -ItemType Directory -Path $reportsPath -ErrorAction SilentlyContinue | Out-Null
}

$reviewLog = Join-Path $logsPath "mason_self_review.log"

function Write-ReviewLog {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    Add-Content -Path $reviewLog -Value "[$ts] $Message"
}

Write-ReviewLog "=== Mason_SelfReview_Report started ==="

function Read-JsonSafe {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try {
        $raw = Get-Content $Path -Raw
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        return $raw | ConvertFrom-Json
    }
    catch {
        Write-ReviewLog ("WARNING: Failed to parse JSON at " + $Path + ": " + $_.Exception.Message)
        return $null
    }
}

# 1) Stability history (what tasks actually ran)
$stabilityHistoryPath = Join-Path $reportsPath "stability_history.json"
$stabilityHistory     = Read-JsonSafe -Path $stabilityHistoryPath

$appliedSummary = $null
if ($stabilityHistory -and $stabilityHistory.tasks) {
    $total = $stabilityHistory.totalAppliedTasks
    $tasks = $stabilityHistory.tasks

    # Group by area and risk for a quick overview
    $byArea = @{}
    foreach ($t in $tasks) {
        $area = if ($t.area) { $t.area } else { "unknown" }
        $risk = if ($t.risk) { $t.risk } else { "unknown" }

        if (-not $byArea.ContainsKey($area)) {
            $byArea[$area] = @{}
        }
        if (-not $byArea[$area].ContainsKey($risk)) {
            $byArea[$area][$risk] = 0
        }
        $byArea[$area][$risk] += 1
    }

    $latestTasks = $tasks | Sort-Object { $_.applied_at } -Descending | Select-Object -First 10

    $appliedSummary = [ordered]@{
        totalAppliedTasks = $total
        byAreaAndRisk     = $byArea
        latestTasks       = $latestTasks
    }

    Write-ReviewLog ("Loaded stability history with " + $total + " applied tasks.")
}
else {
    Write-ReviewLog "No stability_history.json found or no tasks present."
}

# 2) Onyx health investigation
$onyxInvestigationPath = Join-Path $reportsPath "onyx_health_investigation.json"
$onyxInvestigation     = Read-JsonSafe -Path $onyxInvestigationPath

$onyxSummary = $null
if ($onyxInvestigation) {
    $onyxSummary = [ordered]@{
        generated_at  = $onyxInvestigation.generated_at
        healthOpinion = $onyxInvestigation.healthOpinion
        avgElapsedMs  = $onyxInvestigation.avgElapsedMs
        errorCount    = $onyxInvestigation.errorCount
        warnCount     = $onyxInvestigation.warnCount
        notes         = $onyxInvestigation.notes
    }
    Write-ReviewLog ("Loaded Onyx health investigation from " + $onyxInvestigationPath)
}
else {
    Write-ReviewLog "No Onyx health investigation report found."
}

# 3) PC high RAM analysis
$pcHighRamPath = Join-Path $reportsPath "pc_high_ram_analysis.json"
$pcHighRam     = Read-JsonSafe -Path $pcHighRamPath

$pcSummary = $null
if ($pcHighRam) {
    # Take top 5 processes by WorkingSetMB
    $topProcs = $pcHighRam.top_processes | Sort-Object { $_.WorkingSetMB } -Descending | Select-Object -First 5

    $pcSummary = [ordered]@{
        generated_at         = $pcHighRam.generated_at
        high_ram_alerts_seen = $pcHighRam.high_ram_alerts_seen
        top_processes_sample = $topProcs
        notes                = $pcHighRam.notes
    }
    Write-ReviewLog ("Loaded PC high RAM analysis from " + $pcHighRamPath)
}
else {
    Write-ReviewLog "No PC high RAM analysis report found."
}

# 4) Build combined self-review
$selfReview = [ordered]@{
    generated_at       = (Get-Date).ToUniversalTime().ToString("o")
    summary            = "Mason self-review of recent stability experiments and observations."
    stability_history  = $appliedSummary
    onyx_health        = $onyxSummary
    pc_high_ram        = $pcSummary
}

$outPath = Join-Path $reportsPath "mason_self_review.json"
$selfReview | ConvertTo-Json -Depth 6 | Out-File -FilePath $outPath -Encoding UTF8

Write-ReviewLog ("Wrote self review report to " + $outPath)
Write-ReviewLog "=== Mason_SelfReview_Report completed ==="
