[CmdletBinding()]
param(
    # Optional override: if empty, we use logs\onyx_health.log (Mason watcher).
    # You can point this at logs\onyx\onyx_health.log later if you want.
    [string]$LogPath = ""
)

<#
    Mason_Onyx_Health_Summary.ps1

    Purpose:
      - Let Mason summarize how Onyx has been behaving.
      - Reads an Onyx health log (default: logs\onyx_health.log).
      - Produces reports\onyx_health_summary.json with:
          * totalChecks
          * ok / warn / error counts
          * lastOkTime
          * lastErrorTime + raw message
          * avgElapsedMs
          * healthOpinion: no_data | stable | stable_with_warnings | degraded | unhealthy

    Internal only – not exposed to Onyx users. This is for Mason, Athena, and you.
#>

# Resolve Mason2 base path
$scriptDir = Split-Path -Parent $PSCommandPath
$basePath  = Split-Path -Parent $scriptDir

$logsDir    = Join-Path $basePath "logs"
$reportsDir = Join-Path $basePath "reports"

if (-not (Test-Path $logsDir)) {
    Write-Error "logs directory not found at $logsDir"
    exit 1
}
if (-not (Test-Path $reportsDir)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

# Default to Mason watcher log if nothing passed in
if ([string]::IsNullOrWhiteSpace($LogPath)) {
    $LogPath = Join-Path $logsDir "onyx_health.log"
}

if (-not (Test-Path $LogPath)) {
    Write-Error "Onyx health log not found at $LogPath"
    exit 1
}

$summaryPath = Join-Path $reportsDir "onyx_health_summary.json"

# -------------------------------
# Parse log
# -------------------------------

$totalChecks   = 0
$okCount       = 0
$warnCount     = 0
$errorCount    = 0
$responseTimes = New-Object System.Collections.Generic.List[int]

$lastOkTime    = $null
$lastErrorTime = $null
$lastErrorMsg  = $null

Get-Content $LogPath | ForEach-Object {
    $line = $_

    # Expect lines like:
    # [2025-12-02 01:58:39][OnyxHealth] OK - StatusCode=200; ElapsedMs=2056
    if ($line -notmatch "^\[(?<ts>[\d\- :]+)\]\[OnyxHealth\]\s+(?<msg>.+)$") {
        return
    }

    $tsString = $Matches["ts"]
    $msg      = $Matches["msg"]

    $timestamp = $null
    try {
    $timestamp = [datetime]::Parse($tsString)
}
catch {
    $timestamp = $null
}


    if ($msg -like "Starting Onyx health check*") {
        # just a start marker
        return
    }

    if ($msg -like "OK -*") {
        $totalChecks++
        $okCount++
        if ($timestamp) { $lastOkTime = $timestamp }

        if ($msg -match "ElapsedMs=(?<ms>\d+)") {
            $ms = [int]$Matches["ms"]
            $responseTimes.Add($ms)
        }
    }
    elseif ($msg -like "WARN -*") {
        $totalChecks++
        $warnCount++
        if ($msg -match "ElapsedMs=(?<ms>\d+)") {
            $ms = [int]$Matches["ms"]
            $responseTimes.Add($ms)
        }
    }
    elseif ($msg -like "ERROR -*") {
        $totalChecks++
        $errorCount++
        if ($timestamp) { $lastErrorTime = $timestamp }
        $lastErrorMsg = $msg

        if ($msg -match "ElapsedMs=(?<ms>\d+)") {
            $ms = [int]$Matches["ms"]
            $responseTimes.Add($ms)
        }
    }
}

$avgMs = 0
if ($responseTimes.Count -gt 0) {
    $avgMs = [int]($responseTimes | Measure-Object -Average).Average
}

# Convert DateTime to strings for JSON (no ? : operator)
$lastOkTimeStr = $null
if ($lastOkTime) {
    $lastOkTimeStr = $lastOkTime.ToString("o")
}

$lastErrorTimeStr = $null
if ($lastErrorTime) {
    $lastErrorTimeStr = $lastErrorTime.ToString("o")
}

$summary = [ordered]@{
    generatedAt   = (Get-Date).ToString("o")
    logPath       = $LogPath
    totalChecks   = $totalChecks
    okCount       = $okCount
    warnCount     = $warnCount
    errorCount    = $errorCount
    avgElapsedMs  = $avgMs
    lastOkTime    = $lastOkTimeStr
    lastErrorTime = $lastErrorTimeStr
    lastErrorRaw  = $lastErrorMsg
    healthOpinion = $null
}

# Simple opinion Mason can use later
if ($totalChecks -eq 0) {
    $summary["healthOpinion"] = "no_data"
}
elseif ($errorCount -eq 0 -and $warnCount -eq 0) {
    $summary["healthOpinion"] = "stable"
}
elseif ($errorCount -eq 0 -and $warnCount -gt 0) {
    $summary["healthOpinion"] = "stable_with_warnings"
}
elseif ($errorCount -gt 0 -and ($errorCount / [double]$totalChecks) -gt 0.3) {
    $summary["healthOpinion"] = "unhealthy"
}
else {
    $summary["healthOpinion"] = "degraded"
}

# Write JSON
$summaryJson = $summary | ConvertTo-Json -Depth 5
Set-Content -Path $summaryPath -Value $summaryJson -Encoding UTF8

Write-Host "Onyx health summary written to $summaryPath" -ForegroundColor Green
