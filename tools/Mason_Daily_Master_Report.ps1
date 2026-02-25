Param(
    [switch]$Open  # If set, open the report in Notepad at the end
)

$ErrorActionPreference = "Stop"

# Figure out Mason root from this script location
$toolsDir  = $PSScriptRoot
$Base      = Split-Path $toolsDir -Parent   # C:\Users\Chris\Desktop\Mason2
$reportDir = Join-Path $Base "reports"

if (-not (Test-Path $reportDir)) {
    New-Item -Path $reportDir -ItemType Directory -Force | Out-Null
}

$now       = Get-Date
$timestamp = $now.ToString("yyyy-MM-ddTHH:mm:ss")
$outName   = ("Mason_Master_Report_{0:yyyy-MM-dd_HHmm}.txt" -f $now)
$outPath   = Join-Path $reportDir $outName

$lines = @()
$lines += "=== MASON DAILY MASTER REPORT ==="
$lines += ("GeneratedAt:  {0}" -f $timestamp)
$lines += ("Base:         {0}" -f $Base)
$lines += ""

# --- RISK GATES ---
$lines += "=== RISK GATES ==="
$lines += ""

$riskPath = Join-Path $reportDir "risk_state.json"
if (Test-Path $riskPath) {
    $risk = Get-Content $riskPath -Raw | ConvertFrom-Json
    foreach ($area in $risk.areas) {
        $lines += ("- {0}: allowed_risk={1}, start_risk={2}, max_auto_risk={3}" -f `
            $area.area, $area.allowed_risk, $area.start_risk, $area.max_auto_risk)
    }
} else {
    $lines += "No risk_state.json yet."
}

$lines += ""
$lines += "=== UNIVERSAL EVOLUTION STATUS ==="
$lines += ""

$uePath = Join-Path $reportDir "mason_ue_status.json"
if (Test-Path $uePath) {
    $ue = Get-Content $uePath -Raw | ConvertFrom-Json
    $lines += ("UE snapshot: {0}" -f $uePath)
    if ($ue.status) {
        $lines += ("Status:      {0}" -f $ue.status)
    }
} else {
    $lines += "No mason_ue_status.json yet."
}

$lines += ""
$lines += "=== HEALTH AGGREGATE (RAW JSON) ==="
$lines += ""

$healthPath = Join-Path $reportDir "mason_health_aggregated.json"
if (Test-Path $healthPath) {
    $lines += ("Health aggregate: {0}" -f $healthPath)
} else {
    $lines += "No mason_health_aggregated.json yet."
}

$lines += ""
$lines += "=== ONYX HEALTH SUMMARY (RAW JSON) ==="
$lines += ""

$onyxPath = Join-Path $reportDir "onyx_health_summary.json"
if (Test-Path $onyxPath) {
    $lines += ("Onyx health summary: {0}" -f $onyxPath)
} else {
    $lines += "No onyx_health_summary.json yet."
}

$lines += ""
$lines += "=== SELF STATE (RAW JSON) ==="
$lines += ""

$selfPath = Join-Path $reportDir "mason_self_state.json"
if (Test-Path $selfPath) {
    $lines += ("Self state: {0}" -f $selfPath)
} else {
    $lines += "No mason_self_state.json yet."
}

# Write file
Set-Content -Path $outPath -Value $lines -Encoding utf8

Write-Host "[DailyReport] Master report written to:"
Write-Host "  $outPath"

if ($Open) {
    Start-Process notepad.exe $outPath | Out-Null
}
