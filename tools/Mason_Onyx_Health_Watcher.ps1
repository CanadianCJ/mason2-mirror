[CmdletBinding()]
param(
    # Onyx web URL – for now we assume localhost:5353 (your tester/dev Onyx)
    [string]$OnyxUrl = "http://localhost:5353"
)

# ---------------------------------------------
# Mason_Onyx_Health_Watcher.ps1
# Purpose:
#   - Let Mason "see" whether Onyx is healthy.
#   - Log results to onyx_health.log and athena_status.log.
#   - Write a small JSON status file Athena can show later.
# ---------------------------------------------

# Resolve Mason2 base path from this script location:
# Script lives in: C:\Users\Chris\Desktop\Mason2\tools
# Base folder is:  C:\Users\Chris\Desktop\Mason2
$scriptDir = Split-Path -Parent $PSCommandPath
$basePath  = Split-Path -Parent $scriptDir

$logsDir    = Join-Path $basePath "logs"
$reportsDir = Join-Path $basePath "reports"

if (-not (Test-Path $logsDir)) {
    New-Item -Path $logsDir -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path $reportsDir)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

$onyxLogPath    = Join-Path $logsDir "onyx_health.log"
$athenaLogPath  = Join-Path $logsDir "athena_status.log"
$statusJsonPath = Join-Path $reportsDir "onyx_health_status.json"

function Write-OnyxHealthLog {
    param(
        [string]$Message
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line      = "[${timestamp}][OnyxHealth] $Message"

    # Main Onyx health log
    Add-Content -Path $onyxLogPath -Value $line

    # Also mirror into athena_status.log so Athena has a single stream to read from
    try {
        Add-Content -Path $athenaLogPath -Value $line
    } catch {
        # If athena_status.log doesn't exist yet, just ignore
    }
}

Write-OnyxHealthLog "Starting Onyx health check for URL: $OnyxUrl"

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$ok          = $false
$statusCode  = $null
$errorText   = $null

try {
    # We only care that the server responds; root HTML is fine for now
    $response = Invoke-WebRequest -Uri $OnyxUrl -UseBasicParsing -TimeoutSec 5
    $stopwatch.Stop()
    $statusCode = $response.StatusCode
    $ok         = ($statusCode -ge 200 -and $statusCode -lt 400)

    if ($ok) {
        Write-OnyxHealthLog "OK - StatusCode=$statusCode; ElapsedMs=$($stopwatch.ElapsedMilliseconds)"
    } else {
        Write-OnyxHealthLog "WARN - Non-success StatusCode=$statusCode; ElapsedMs=$($stopwatch.ElapsedMilliseconds)"
    }
}
catch {
    $stopwatch.Stop()
    $errorText = $_.Exception.Message
    Write-OnyxHealthLog "ERROR - ElapsedMs=$($stopwatch.ElapsedMilliseconds); Message=$errorText"
}

# Write a JSON status snapshot for Athena/Mason to read
$statusObject = [ordered]@{
    timestamp   = (Get-Date).ToString("o")
    url         = $OnyxUrl
    ok          = $ok
    statusCode  = $statusCode
    elapsedMs   = $stopwatch.ElapsedMilliseconds
    error       = $errorText
}

try {
    $json = $statusObject | ConvertTo-Json -Depth 4
    Set-Content -Path $statusJsonPath -Value $json -Encoding UTF8
} catch {
    Write-OnyxHealthLog "ERROR - Failed to write status JSON: $($_.Exception.Message)"
}

Write-OnyxHealthLog "Completed Onyx health check."
