[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Write-HealthLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

Write-HealthLog "[OnyxPrelaunch] Mason Onyx prelaunch healthcheck starting..."

# Figure out Mason root from this script's location
$ToolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Base     = Split-Path -Parent $ToolsDir

Write-HealthLog "[OnyxPrelaunch] Base : $Base"

$ReportsDir = Join-Path $Base "reports"
if (-not (Test-Path -LiteralPath $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir | Out-Null
}

# Onyx Flutter app root
$OnyxDir = Join-Path $Base "Component - Onyx App\onyx_business_manager"
Write-HealthLog "[OnyxPrelaunch] OnyxDir: $OnyxDir"

$report = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    base_path        = $Base
    onyx_dir         = $OnyxDir
    exists           = (Test-Path -LiteralPath $OnyxDir)
    checks           = @{}
    notes            = @()
}

$checks = [ordered]@{}

if (-not $report.exists) {
    Write-HealthLog "[OnyxPrelaunch] Onyx directory does NOT exist. Healthcheck is limited." "WARN"
}
else {
    # Basic structure checks
    $checks.pubspec_yaml          = Test-Path (Join-Path $OnyxDir "pubspec.yaml")
    $checks.main_dart             = Test-Path (Join-Path $OnyxDir "lib\main.dart")
    $checks.android_build_gradle  = Test-Path (Join-Path $OnyxDir "android\app\build.gradle")
    $checks.ios_runner            = Test-Path (Join-Path $OnyxDir "ios\Runner.xcodeproj")
    $checks.web_index             = Test-Path (Join-Path $OnyxDir "web\index.html")

    # High-level lib structure (top-level files only, to keep it light)
    $libDir = Join-Path $OnyxDir "lib"
    if (Test-Path -LiteralPath $libDir) {
        try {
            $topFiles = Get-ChildItem -Path $libDir -File -ErrorAction SilentlyContinue |
                Select-Object -First 50 |
                ForEach-Object { $_.Name }
            $checks.lib_top_files = $topFiles
        }
        catch {
            Write-HealthLog "[OnyxPrelaunch] Error listing lib top files: $($_.Exception.Message)" "WARN"
        }
    }

    # Optional: refresh the feature index report if the script exists
    $featureScript = Join-Path $ToolsDir "Mason_Onyx_FeatureIndex_Report.ps1"
    if (Test-Path -LiteralPath $featureScript) {
        Write-HealthLog "[OnyxPrelaunch] Refreshing Onyx feature index report via Mason_Onyx_FeatureIndex_Report.ps1..."
        try {
            & $featureScript
            $checks.feature_index_refreshed = $true
        }
        catch {
            Write-HealthLog "[OnyxPrelaunch] Failed to run Mason_Onyx_FeatureIndex_Report.ps1: $($_.Exception.Message)" "WARN"
            $checks.feature_index_refreshed = $false
        }
    }
    else {
        $checks.feature_index_refreshed = $false
        $report.notes += "Mason_Onyx_FeatureIndex_Report.ps1 not found in tools; feature index not refreshed."
    }

    # Check for previous feature index report
    $featureReportPath = Join-Path $ReportsDir "onyx_feature_index_report.json"
    $checks.feature_index_report_exists = Test-Path -LiteralPath $featureReportPath
}

$report.checks = $checks

# Simple overall summary
$summary = @()

if (-not $report.exists) {
    $summary += "Onyx directory missing at expected path."
}
else {
    if (-not $checks.pubspec_yaml)         { $summary += "pubspec.yaml missing." }
    if (-not $checks.main_dart)            { $summary += "lib/main.dart missing." }
    if (-not $checks.android_build_gradle) { $summary += "android/app/build.gradle missing." }
    if (-not $checks.web_index)            { $summary += "web/index.html missing - Flutter web entry not found." }

    if (-not $summary) {
        $summary += "Onyx core Flutter structure looks present."
    }

    if ($checks.feature_index_report_exists) {
        $summary += "Feature index report present - Mason can reason about Onyx screens and sections."
    }
    else {
        $summary += "Feature index report missing - Mason has less detail about Onyx UI structure."
    }
}

$report.summary = $summary

$stamp   = Get-Date -Format "yyyyMMdd_HHmmss"
$outPath = Join-Path $ReportsDir ("onyx_prelaunch_health_{0}.json" -f $stamp)

$report | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $outPath -Encoding UTF8

Write-HealthLog "[OnyxPrelaunch] Wrote prelaunch health report to:"
Write-HealthLog "  $outPath"
Write-HealthLog "[OnyxPrelaunch] Done."
