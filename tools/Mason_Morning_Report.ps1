param(
    [string]$Base
)

# 1) Locate Mason2 base
if (-not $Base) {
    $Base = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
}

$reportsRoot = Join-Path $Base "reports"
$dailyRoot   = Join-Path $reportsRoot "daily"

if (-not (Test-Path $reportsRoot)) {
    New-Item -ItemType Directory -Path $reportsRoot -Force | Out-Null
}
if (-not (Test-Path $dailyRoot)) {
    New-Item -ItemType Directory -Path $dailyRoot -Force | Out-Null
}

# Helper to read JSON safely
function Read-JsonSafe {
    param(
        [string]$Path
    )
    if (-not (Test-Path $Path)) { return $null }
    try {
        return Get-Content $Path -Raw | ConvertFrom-Json
    } catch {
        return $null
    }
}

# 2) Load key JSONs (if they exist)
$masonHealth   = Read-JsonSafe (Join-Path $reportsRoot "mason_health_aggregated.json")
$ueStatus      = Read-JsonSafe (Join-Path $reportsRoot "mason_ue_status.json")
$riskState     = Read-JsonSafe (Join-Path $reportsRoot "risk_state.json")
$onyxHealth    = Read-JsonSafe (Join-Path $reportsRoot "onyx_health_summary.json")
$selfState     = Read-JsonSafe (Join-Path $reportsRoot "mason_self_state.json")

# Helper to format a date/time
function Fmt-Time {
    param([object]$t)
    if (-not $t) { return "(unknown)" }
    try {
        return ([DateTime]$t).ToString("yyyy-MM-dd HH:mm:ss")
    } catch {
        return "$t"
    }
}

# 3) Build report text
$now = Get-Date
$todayStamp = $now.ToString("yyyy-MM-dd")
$outPath = Join-Path $dailyRoot "${todayStamp}_morning_report.txt"
$latestPath = Join-Path $reportsRoot "latest_morning_report.txt"

$lines = @()
$lines += "============================================================"
$lines += "  MASON MORNING REPORT - $($now.ToString("yyyy-MM-dd HH:mm:ss"))"
$lines += "  Base: $Base"
$lines += "============================================================"
$lines += ""

# Section: Mason self-state
$lines += "=== 1. Mason Self-State ===================================="
if ($selfState) {
    $lines += "Mode:         $($selfState.mode  -join ', ')"
    $lines += "LastUpdated:  $(Fmt-Time $selfState.generatedAt)"
    if ($selfState.healthOpinion) {
        $lines += "Health:       $($selfState.healthOpinion)"
    }
    if ($selfState.notes) {
        $lines += ""
        $lines += "Notes:"
        $selfState.notes | ForEach-Object { $lines += "  - $_" }
    }
} else {
    $lines += "No mason_self_state.json found yet."
}
$lines += ""

# Section: Risk & areas
$lines += "=== 2. Risk & Areas ========================================"
if ($riskState) {
    $lines += "GeneratedAt:  $(Fmt-Time $riskState.generatedAt)"
    $lines += ""
    foreach ($area in $riskState.areas) {
        $lines += "Area: $($area.area)"
        $lines += "  Description: $($area.description)"
        $lines += "  Allowed Risk: $($area.allowed_risk) (start: $($area.start_risk), max_auto: $($area.max_auto_risk))"
        $lines += "  Metrics:"
        $lines += "    successful_tasks: $($area.metrics.successful_tasks)"
        $lines += "    failed_tasks:     $($area.metrics.failed_tasks)"
        $lines += "    rollbacks:        $($area.metrics.rollbacks)"
        $lines += "    hours_health_green: $($area.metrics.hours_health_green)"
        $lines += ""
    }
    $lines += "Global money loop enabled: $($riskState.global.money_loop_enabled)"
} else {
    $lines += "No risk_state.json found yet."
}
$lines += ""

# Section: Onyx health
$lines += "=== 3. Onyx Health ========================================="
if ($onyxHealth) {
    $lines += "LogPath:       $($onyxHealth.logPath)"
    $lines += "GeneratedAt:   $(Fmt-Time $onyxHealth.generatedAt)"
    if ($onyxHealth.healthOpinion) {
        $lines += "HealthOpinion: $($onyxHealth.healthOpinion)"
    }
    if ($onyxHealth.lastErrorRaw) {
        $lines += "LastError:     $($onyxHealth.lastErrorRaw)"
    }
    $lines += "TotalChecks:   $($onyxHealth.totalChecks)"
    $lines += "OK / Warn / Error: $($onyxHealth.okCount) / $($onyxHealth.warnCount) / $($onyxHealth.errorCount)"
} else {
    $lines += "No onyx_health_summary.json found yet."
}
$lines += ""

# Section: UE status
$lines += "=== 4. Universal Evolution Status =========================="
if ($ueStatus) {
    $lines += "GeneratedAt: $(Fmt-Time $ueStatus.generatedAt)"
    $lines += ""
    if ($ueStatus.components) {
        foreach ($comp in $ueStatus.components) {
            $lines += "Component: $($comp.name)"
            $lines += "  Enabled: $($comp.enabled)"
            if ($comp.notes) {
                $lines += "  Notes:"
                $comp.notes | ForEach-Object { $lines += "    - $_" }
            }
            $lines += ""
        }
    } else {
        $lines += "UE status JSON present but components list missing."
    }
} else {
    $lines += "No mason_ue_status.json found yet."
}
$lines += ""

# Section: Mason health aggregated (if any extra info)
$lines += "=== 5. Mason Health Aggregated ============================="
if ($masonHealth) {
    $lines += "GeneratedAt: $(Fmt-Time $masonHealth.generatedAt)"
    if ($masonHealth.healthOpinion) {
        $lines += "Overall HealthOpinion: $($masonHealth.healthOpinion)"
    }
    if ($masonHealth.notes) {
        $lines += ""
        $lines += "Notes:"
        $masonHealth.notes | ForEach-Object { $lines += "  - $_" }
    }
} else {
    $lines += "No mason_health_aggregated.json found yet."
}
$lines += ""

$lines += "============================================================"
$lines += "End of report."
$lines += "============================================================"

# 4) Write report files
$lines | Set-Content -Path $outPath -Encoding utf8
$lines | Set-Content -Path $latestPath -Encoding utf8

# 5) Optional: append a small history line (JSONL) for Athena later
$historyPath = Join-Path $reportsRoot "morning_report_history.jsonl"
$historyItem = [pscustomobject]@{
    generatedAt = $now
    file        = $outPath
}
$historyItem | ConvertTo-Json -Compress | Add-Content -Path $historyPath

# 6) Open the latest report for Chris to read
Start-Process -FilePath "notepad.exe" -ArgumentList "`"$latestPath`""

Write-Host "Mason_Morning_Report: wrote $outPath and opened $latestPath"
