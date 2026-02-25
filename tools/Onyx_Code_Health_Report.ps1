Param()

# ============================================================
# Onyx_Code_Health_Report.ps1
#
# Read-only: runs `flutter analyze` against Onyx and writes a
# JSON report Mason can use to understand why Onyx might be
# blank / unhealthy.
#
# No schema changes, no code edits, no restarts.
# ============================================================

$ErrorActionPreference = "Stop"

$OnyxRoot  = "C:\Users\Chris\Desktop\Mason2\Component - Onyx App\onyx_business_manager"
$ReportsDir = "C:\Users\Chris\Desktop\Mason2\reports"
$LogsDir    = "C:\Users\Chris\Desktop\Mason2\logs"

if (!(Test-Path $ReportsDir)) { New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null }
if (!(Test-Path $LogsDir))    { New-Item -ItemType Directory -Path $LogsDir    -Force | Out-Null }

$ReportPath = Join-Path $ReportsDir "onyx_code_health.json"
$LogPath    = Join-Path $LogsDir    "onyx_code_health.log"

function Write-HealthLog {
    Param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogPath -Value "[$ts] $Message"
}

Write-HealthLog "=== Onyx_Code_Health_Report.ps1 started ==="

if (!(Test-Path $OnyxRoot)) {
    Write-HealthLog "ERROR: Onyx root not found at $OnyxRoot"
    $fallback = @{
        generated_at      = (Get-Date).ToUniversalTime().ToString("o")
        onyx_root         = $OnyxRoot
        flutter_available = $false
        analyze_exit_code = $null
        analyze_stdout    = ""
        analyze_stderr    = "Onyx root not found"
        notes             = @(
            "Onyx folder is missing or moved.",
            "This is a read-only diagnostic; nothing was changed."
        )
    }
    $fallback | ConvertTo-Json -Depth 6 | Set-Content -Path $ReportPath -Encoding UTF8
    Write-HealthLog "Report written with error (missing Onyx root)."
    Write-HealthLog "=== Completed with errors ==="
    exit 1
}

# ------------------------------------------------------------
# Locate flutter via Get-Command so we have the REAL path
# ------------------------------------------------------------
Write-HealthLog "Checking for 'flutter' with Get-Command..."
$flutterCmdInfo = $null
try {
    $flutterCmdInfo = Get-Command "flutter" -ErrorAction SilentlyContinue
}
catch {
    $flutterCmdInfo = $null
}

if (-not $flutterCmdInfo) {
    $report = @{
        generated_at      = (Get-Date).ToUniversalTime().ToString("o")
        onyx_root         = $OnyxRoot
        flutter_available = $false
        analyze_exit_code = $null
        analyze_stdout    = ""
        analyze_stderr    = "flutter command not found. Install Flutter or add it to PATH."
        notes             = @(
            "Run this script again after Flutter is installed and on PATH.",
            "Read-only diagnostic; no changes were made."
        )
    }
    $report | ConvertTo-Json -Depth 6 | Set-Content -Path $ReportPath -Encoding UTF8
    Write-HealthLog "flutter not found via Get-Command; report written and exiting."
    Write-HealthLog "=== Completed (flutter missing) ==="
    exit 0
}

$flutterPath = $flutterCmdInfo.Source
Write-HealthLog "flutter resolved to: $flutterPath"

# Quick sanity check by asking for flutter --version
try {
    $versionOutput = & $flutterPath --version 2>$null
    Write-HealthLog "flutter --version succeeded."
}
catch {
    Write-HealthLog "flutter --version failed: $($_.Exception.Message)"
    $report = @{
        generated_at      = (Get-Date).ToUniversalTime().ToString("o")
        onyx_root         = $OnyxRoot
        flutter_available = $false
        analyze_exit_code = $null
        analyze_stdout    = ""
        analyze_stderr    = "flutter exists at '$flutterPath' but could not run --version: $($_.Exception.Message)"
        notes             = @(
            "Check that Flutter is correctly installed and runnable from this account.",
            "Read-only diagnostic; no changes were made."
        )
    }
    $report | ConvertTo-Json -Depth 6 | Set-Content -Path $ReportPath -Encoding UTF8
    Write-HealthLog "Report written with flutter run error; exiting."
    Write-HealthLog "=== Completed (flutter run error) ==="
    exit 0
}

# ------------------------------------------------------------
# Helper to trim large stdout/stderr
# ------------------------------------------------------------
function Trim-Lines {
    Param(
        [string]$Text,
        [int]$MaxLines = 200
    )
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }
    $lines = $Text -split "`r?`n"
    if ($lines.Count -le $MaxLines) {
        return ($lines -join "`n")
    }
    $head = $lines[0..($MaxLines-1)]
    return (($head -join "`n") + "`n... (truncated, total lines: $($lines.Count))")
}

# ------------------------------------------------------------
# Run flutter analyze in the Onyx root
# ------------------------------------------------------------
Write-HealthLog "Running 'flutter analyze' in $OnyxRoot ..."
try {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $flutterPath
    $psi.Arguments              = "analyze"
    $psi.WorkingDirectory       = $OnyxRoot
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute        = $false
    $psi.CreateNoWindow         = $true

    $proc   = [System.Diagnostics.Process]::Start($psi)
    $stdOut = $proc.StandardOutput.ReadToEnd()
    $stdErr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode

    Write-HealthLog "flutter analyze exit code: $exitCode"

    $reportObj = @{
        generated_at      = (Get-Date).ToUniversalTime().ToString("o")
        onyx_root         = $OnyxRoot
        flutter_available = $true
        analyze_exit_code = $exitCode
        analyze_stdout    = Trim-Lines -Text $stdOut -MaxLines 200
        analyze_stderr    = Trim-Lines -Text $stdErr -MaxLines 200
        notes             = @(
            "Read-only diagnostic run by Mason.",
            "Non-zero exit code or analyzer errors likely explain blank screen / unhealthy status.",
            "Future steps: convert common analyzer errors into specific Onyx-fix tasks."
        )
    }

    $reportObj | ConvertTo-Json -Depth 6 | Set-Content -Path $ReportPath -Encoding UTF8
    Write-HealthLog "Report written to $ReportPath"
    Write-HealthLog "=== Onyx_Code_Health_Report.ps1 completed successfully ==="
}
catch {
    Write-HealthLog "ERROR while running flutter analyze: $($_.Exception.Message)"
    $fallbackError = @{
        generated_at      = (Get-Date).ToUniversalTime().ToString("o")
        onyx_root         = $OnyxRoot
        flutter_available = $true
        analyze_exit_code = $null
        analyze_stdout    = ""
        analyze_stderr    = "Exception when starting or running flutter analyze: $($_.Exception.Message)"
        notes             = @(
            "Check flutter installation, permissions, and PATH.",
            "This script stayed read-only; no Onyx code or configs were changed."
        )
    }
    $fallbackError | ConvertTo-Json -Depth 6 | Set-Content -Path $ReportPath -Encoding UTF8
    Write-HealthLog "Fallback error report written."
    Write-HealthLog "=== Onyx_Code_Health_Report.ps1 completed with exception ==="
}

