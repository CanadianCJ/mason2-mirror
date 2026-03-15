param(
    [string]$BridgeStatusUrl = "http://127.0.0.1:8484/api/status",
    [string]$AthenaUrl = "http://127.0.0.1:8000/athena/",
    [string]$StackStatusUrl = "http://127.0.0.1:8000/api/stack_status"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$basePath = Split-Path -Parent $PSScriptRoot
$logsDir = Join-Path $basePath "logs"
$reportsDir = Join-Path $basePath "reports"
$logPath = Join-Path $logsDir "athena_status.log"
$statusPath = Join-Path $reportsDir "athena_widget_status.json"

foreach ($dir in @($logsDir, $reportsDir)) {
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

function Invoke-Probe {
    param([Parameter(Mandatory = $true)][string]$Url)

    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
        $content = ""
        try { $content = [string]$response.Content } catch { }
        return [pscustomobject]@{
            ok = $true
            status_code = [int]$response.StatusCode
            content = $content
            error = $null
        }
    }
    catch {
        $statusCode = 0
        try { $statusCode = [int]$_.Exception.Response.StatusCode.value__ } catch { }
        return [pscustomobject]@{
            ok = $false
            status_code = $statusCode
            content = ""
            error = [string]$_.Exception.Message
        }
    }
}

$timestampUtc = (Get-Date).ToUniversalTime().ToString("o")
$timestampLocal = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$bridgeData = $null
$bridgeError = $null
try {
    $bridgeData = Invoke-RestMethod -Uri $BridgeStatusUrl -Method Get -TimeoutSec 8 -ErrorAction Stop
}
catch {
    $bridgeError = [string]$_.Exception.Message
}

$athenaProbe = Invoke-Probe -Url $AthenaUrl
$stackProbe = Invoke-Probe -Url $StackStatusUrl

$detectedTabs = @()
if ($athenaProbe.content) {
    foreach ($label in @("Operations", "Founder Mode", "Live Docs", "Whole Folder Verification")) {
        if ($athenaProbe.content -like "*$label*" -and $detectedTabs -notcontains $label) {
            $detectedTabs += $label
        }
    }
}

$payload = [ordered]@{
    timestamp_utc = $timestampUtc
    overall_status = $(if ($athenaProbe.ok -and $stackProbe.ok) { "PASS" } else { "WARN" })
    athena_reachable = [bool]$athenaProbe.ok
    stack_status_reachable = [bool]$stackProbe.ok
    http_status = [int]$athenaProbe.status_code
    stack_status_http_status = [int]$stackProbe.status_code
    bridge_status_ok = [bool]$(if ($bridgeData) { $bridgeData.ok } else { $false })
    bridge_status_error = $bridgeError
    detected_tabs = @($detectedTabs)
    widget_card_count = [regex]::Matches([string]$athenaProbe.content, 'class="card').Count
    recommended_next_action = $(if ($athenaProbe.ok -and $stackProbe.ok) { "No action required." } else { "Restore Athena or stack_status reachability before trusting founder widgets." })
}

$logLine = [ordered]@{
    timestamp = $timestampLocal
    athena_ok = [bool]$athenaProbe.ok
    stack_ok = [bool]$stackProbe.ok
    bridge_ok = [bool]$(if ($bridgeData) { $bridgeData.ok } else { $false })
    http_status = [int]$athenaProbe.status_code
    stack_status_http_status = [int]$stackProbe.status_code
}

$payload | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $statusPath -Encoding UTF8
Add-Content -LiteralPath $logPath -Value ($logLine | ConvertTo-Json -Compress)
