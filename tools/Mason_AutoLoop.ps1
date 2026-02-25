param(
    # How often Mason should do a health / UE / self-heal cycle (in seconds)
    [int]$IntervalSeconds = 300
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Figure out Mason base folder (parent of \tools)
# ------------------------------------------------------------
$scriptDir = $PSScriptRoot
if (-not $scriptDir -or $scriptDir -eq "") {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# If this script lives in ...\Mason2\tools, Base = ...\Mason2
$Base    = Split-Path -Parent $scriptDir
$Tools   = Join-Path $Base "tools"
$Reports = Join-Path $Base "reports"

Write-Host "[AutoLoop] Mason auto loop starting..." -ForegroundColor Cyan
Write-Host "  Base    : $Base"
Write-Host "  Tools   : $Tools"
Write-Host "  Reports : $Reports"
Write-Host "  Interval: $IntervalSeconds seconds"
Write-Host ""
Write-Host "[AutoLoop] Press Ctrl+C in this window to stop."
Write-Host ""

# ------------------------------------------------------------
# Script paths Mason will call each tick
# ------------------------------------------------------------
$healthScript       = Join-Path $Tools "Mason_Health_Aggregate.ps1"
$onyxHealthScript   = Join-Path $Tools "Mason_Onyx_Health_Summary.ps1"
$ueSnapshotScript   = Join-Path $Tools "Mason_UE_Snapshot.ps1"
$selfHealScript     = Join-Path $Tools "Mason_SelfHeal_From_Analyzer.ps1"
$riskGovernorScript = Join-Path $Tools "Mason_Risk_Governor.ps1"
$dailyReportScript  = Join-Path $Tools "Mason_Daily_Report.ps1"
$statusScript       = Join-Path $Tools "Mason_Write_Status_Snapshot.ps1"  # your newer status script

while ($true) {
    $now = Get-Date
    $ts  = $now.ToString("MM/dd/yyyy HH:mm:ss")
    Write-Host "[AutoLoop] === Tick @ $ts ==="

    # 1) Mason health aggregation
    if (Test-Path $healthScript) {
        & $healthScript
        Write-Host "Mason health aggregated to:"
        Write-Host "  $(Join-Path $Reports 'mason_health_aggregated.json')"
    }
    else {
        Write-Host "[AutoLoop] WARN: Mason_Health_Aggregate.ps1 not found at $healthScript" -ForegroundColor Yellow
    }

    # 2) Onyx health summary (so tasks keep getting generated)
    if (Test-Path $onyxHealthScript) {
        & $onyxHealthScript
        Write-Host "Onyx health summary written to $(Join-Path $Reports 'onyx_health_summary.json')"
    }
    else {
        Write-Host "[AutoLoop] WARN: Mason_Onyx_Health_Summary.ps1 not found at $onyxHealthScript" -ForegroundColor Yellow
    }

    # 3) UE snapshot (universal evolution state)
    if (Test-Path $ueSnapshotScript) {
        & $ueSnapshotScript
        Write-Host "Mason UE snapshot written to:"
        Write-Host "  $(Join-Path $Reports 'mason_ue_status.json')"
    }
    else {
        Write-Host "[AutoLoop] WARN: Mason_UE_Snapshot.ps1 not found at $ueSnapshotScript" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Reminder: risk 0 = observe/plan only, no changes."

    # 4) Self-heal from analyzer -> tasks -> patch runs (Onyx mode for now)
    if (Test-Path $selfHealScript) {
        & $selfHealScript -Mode "onyx_tasks"
        Write-Host "Mason self-heal summary written to $(Join-Path $Reports 'mason_selfheal_summary.json')"
    }
    else {
        Write-Host "[AutoLoop] WARN: Mason_SelfHeal_From_Analyzer.ps1 not found at $selfHealScript" -ForegroundColor Yellow
    }

    # 5) Risk governor (keeps risk levels + auto limits in sync)
    if (Test-Path $riskGovernorScript) {
        & $riskGovernorScript
        Write-Host "Mason_Risk_Governor: updated $(Join-Path $Reports 'risk_state.json')"
    }
    else {
        Write-Host "[AutoLoop] WARN: Mason_Risk_Governor.ps1 not found at $riskGovernorScript" -ForegroundColor Yellow
    }

    # 6) Daily master report (if present)
    if (Test-Path $dailyReportScript) {
        & $dailyReportScript
    }
    else {
        Write-Host "[AutoLoop] WARN: Mason_Daily_Report.ps1 not found at $dailyReportScript" -ForegroundColor Yellow
    }

    # 7) Status snapshot (this writes Mason_Status_Latest.txt)
    if (Test-Path $statusScript) {
        $statusText = & $statusScript 2>&1 | Out-String
        $statusFile = Join-Path $Reports "Mason_Status_Latest.txt"
        $statusText | Set-Content $statusFile -Encoding UTF8
        Write-Host "[AutoLoop] Updated status file: $statusFile"
    }
    else {
        Write-Host "[AutoLoop] WARN: Mason_Write_Status_Snapshot.ps1 not found at $statusScript" -ForegroundColor Yellow
    }

    Write-Host "[AutoLoop] Sleep $IntervalSeconds seconds..."
    Start-Sleep -Seconds $IntervalSeconds
    Write-Host ""
}
