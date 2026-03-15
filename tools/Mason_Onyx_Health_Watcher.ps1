[CmdletBinding()]
param(
    [string]$OnyxUrl = "http://localhost:5353"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $PSCommandPath
$basePath = Split-Path -Parent $scriptDir

$logsDir = Join-Path $basePath "logs"
$reportsDir = Join-Path $basePath "reports"

foreach ($dir in @($logsDir, $reportsDir)) {
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
    }
}

$onyxLogPath = Join-Path $logsDir "onyx_health.log"
$athenaLogPath = Join-Path $logsDir "athena_status.log"
$statusJsonPath = Join-Path $reportsDir "onyx_health_status.json"
$stackHealthPath = Join-Path $reportsDir "onyx_stack_health.json"

function Write-OnyxHealthLog {
    param([string]$Message)

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[${timestamp}][OnyxHealth] $Message"
    Add-Content -Path $onyxLogPath -Value $line

    try {
        Add-Content -Path $athenaLogPath -Value $line
    }
    catch {
    }
}

function Invoke-OnyxProbe {
    param([Parameter(Mandatory = $true)][string]$Url)

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        $timer.Stop()
        return [pscustomobject]@{
            ok = ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400)
            status_code = [int]$response.StatusCode
            elapsed_ms = [int]$timer.ElapsedMilliseconds
            error = $null
        }
    }
    catch {
        $timer.Stop()
        $statusCode = $null
        try { $statusCode = [int]$_.Exception.Response.StatusCode.value__ } catch { }
        return [pscustomobject]@{
            ok = $false
            status_code = $statusCode
            elapsed_ms = [int]$timer.ElapsedMilliseconds
            error = [string]$_.Exception.Message
        }
    }
}

Write-OnyxHealthLog "Starting Onyx health check for URL: $OnyxUrl"

$rootProbe = Invoke-OnyxProbe -Url $OnyxUrl
$bundleProbe = Invoke-OnyxProbe -Url (($OnyxUrl.TrimEnd('/')) + "/main.dart.js")

if ($rootProbe.ok) {
    Write-OnyxHealthLog "OK - root StatusCode=$($rootProbe.status_code); ElapsedMs=$($rootProbe.elapsed_ms)"
}
else {
    Write-OnyxHealthLog "WARN - root StatusCode=$($rootProbe.status_code); ElapsedMs=$($rootProbe.elapsed_ms); Message=$($rootProbe.error)"
}

if ($bundleProbe.ok) {
    Write-OnyxHealthLog "OK - bundle StatusCode=$($bundleProbe.status_code); ElapsedMs=$($bundleProbe.elapsed_ms)"
}
else {
    Write-OnyxHealthLog "WARN - bundle StatusCode=$($bundleProbe.status_code); ElapsedMs=$($bundleProbe.elapsed_ms); Message=$($bundleProbe.error)"
}

try {
    $timestampUtc = (Get-Date).ToUniversalTime().ToString("o")
    $statusObject = [ordered]@{
        timestamp_utc = $timestampUtc
        url = $OnyxUrl
        ok = [bool]$rootProbe.ok
        statusCode = $rootProbe.status_code
        elapsedMs = $rootProbe.elapsed_ms
        error = $rootProbe.error
        bundle_ok = [bool]$bundleProbe.ok
        bundle_status_code = $bundleProbe.status_code
        bundle_elapsed_ms = $bundleProbe.elapsed_ms
        bundle_error = $bundleProbe.error
    }
    $stackHealth = [ordered]@{
        timestamp_utc = $timestampUtc
        overall_status = $(if ($rootProbe.ok -and $bundleProbe.ok) { "PASS" } elseif ($rootProbe.ok) { "WARN" } else { "FAIL" })
        app_reachable = [bool]$rootProbe.ok
        bundle_reachable = [bool]$bundleProbe.ok
        http_status = $rootProbe.status_code
        bundle_http_status = $bundleProbe.status_code
        latency_ms = $rootProbe.elapsed_ms
        bundle_latency_ms = $bundleProbe.elapsed_ms
        recommended_next_action = $(if ($rootProbe.ok -and $bundleProbe.ok) { "No action required." } else { "Restore the Onyx web runtime before trusting owner flows." })
    }

    $statusObject | ConvertTo-Json -Depth 6 | Set-Content -Path $statusJsonPath -Encoding UTF8
    $stackHealth | ConvertTo-Json -Depth 6 | Set-Content -Path $stackHealthPath -Encoding UTF8
}
catch {
    Write-OnyxHealthLog "ERROR - Failed to write status JSON: $($_.Exception.Message)"
}

Write-OnyxHealthLog "Completed Onyx health check."
