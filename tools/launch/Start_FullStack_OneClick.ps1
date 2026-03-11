[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$MirrorPath = "C:\Mason2_MIRROR",
    [int]$WaitTimeoutSeconds = 300
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param([string]$CandidateRoot)
    if ($CandidateRoot -and (Test-Path -LiteralPath $CandidateRoot)) {
        return (Resolve-Path -LiteralPath $CandidateRoot).Path
    }
    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Write-OneClickLog {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")][string]$Level = "INFO"
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format "o"), $Level, $Message
    Write-Host $line
    Add-Content -LiteralPath $script:OneClickLogPath -Value $line -Encoding UTF8
}

function Write-OneClickStatus {
    param([Parameter(Mandatory = $true)]$State)

    $State | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $script:OneClickStatusPath -Encoding UTF8
}

function Test-HttpReady {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSec = 3
    )
    try {
        $req = @{
            Uri         = $Url
            Method      = "Get"
            TimeoutSec  = $TimeoutSec
            ErrorAction = "Stop"
        }
        if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey("UseBasicParsing")) {
            $req["UseBasicParsing"] = $true
        }
        $resp = Invoke-WebRequest @req
        return ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400)
    }
    catch {
        return $false
    }
}

function Wait-ForGreen {
    param(
        [Parameter(Mandatory = $true)][object[]]$Checks,
        [int]$TimeoutSeconds = 300
    )

    $deadline = (Get-Date).AddSeconds([Math]::Max(10, $TimeoutSeconds))
    while ((Get-Date) -lt $deadline) {
        $allReady = $true
        foreach ($check in $Checks) {
            if (-not (Test-HttpReady -Url ([string]$check.url) -TimeoutSec 3)) {
                $allReady = $false
                break
            }
        }
        if ($allReady) {
            return $true
        }
        Start-Sleep -Seconds 2
    }
    return $false
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsStartDir = Join-Path $repoRoot "reports\start"
$launcherDir = Join-Path $repoRoot "reports\launcher"
New-Item -ItemType Directory -Path $reportsStartDir -Force | Out-Null
New-Item -ItemType Directory -Path $launcherDir -Force | Out-Null
$script:OneClickLogPath = Join-Path $reportsStartDir ("oneclick_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
$script:OneClickStatusPath = Join-Path $launcherDir "oneclick_last.json"

$athenaHealthUrl = "http://127.0.0.1:8000/api/health"
$athenaUiUrl = "http://127.0.0.1:8000/athena/"
$onyxUiUrl = "http://127.0.0.1:5353/"
$oneClickState = [ordered]@{
    started_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    finished_at_utc = ""
    success = $false
    log_path = $script:OneClickLogPath
    athena_health_url = $athenaHealthUrl
    athena_ui_url = $athenaUiUrl
    onyx_ui_url = $onyxUiUrl
    warnings = @()
    opened_urls = @()
    error_summary = ""
}
Write-OneClickStatus -State $oneClickState

Write-OneClickLog ("Repo root: {0}" -f $repoRoot)
Set-Location -LiteralPath $repoRoot

$stackResetPath = Join-Path $repoRoot "tools\ops\Stack_Reset_And_Start.ps1"
if (-not (Test-Path -LiteralPath $stackResetPath)) {
    Write-OneClickLog ("Missing stack reset/start script: {0}" -f $stackResetPath) "ERROR"
    $oneClickState.error_summary = "Missing stack reset/start script: $stackResetPath"
    $oneClickState.finished_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    Write-OneClickStatus -State $oneClickState
    exit 1
}

Write-OneClickLog ("Starting stack via {0}" -f $stackResetPath)
& powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $stackResetPath -RootPath $repoRoot
$stackExit = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
if ($stackExit -ne 0) {
    Write-OneClickLog ("Stack reset/start failed with exit code {0}" -f $stackExit) "ERROR"
    $oneClickState.error_summary = "Stack reset/start failed with exit code $stackExit"
    $oneClickState.finished_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    Write-OneClickStatus -State $oneClickState
    exit 1
}

$checks = @(
    [pscustomobject]@{ name = "mason_api_health"; url = "http://127.0.0.1:8383/health" }
    [pscustomobject]@{ name = "seed_api_health"; url = "http://127.0.0.1:8109/health" }
    [pscustomobject]@{ name = "bridge_health"; url = "http://127.0.0.1:8484/health" }
    [pscustomobject]@{ name = "athena_health"; url = $athenaHealthUrl }
    [pscustomobject]@{ name = "onyx_main_dart_js"; url = "http://127.0.0.1:5353/main.dart.js" }
)
Write-OneClickLog ("Waiting for GREEN across {0} endpoints (timeout={1}s)" -f $checks.Count, $WaitTimeoutSeconds)
$green = Wait-ForGreen -Checks $checks -TimeoutSeconds $WaitTimeoutSeconds
if (-not $green) {
    Write-OneClickLog "Stack did not reach GREEN before timeout." "ERROR"
    $oneClickState.error_summary = "Stack did not reach GREEN before timeout."
    $oneClickState.finished_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    Write-OneClickStatus -State $oneClickState
    exit 1
}

Write-OneClickLog "Stack GREEN. Opening Athena and Onyx."
$athenaUiReady = Test-HttpReady -Url $athenaUiUrl -TimeoutSec 3
if (-not $athenaUiReady) {
    $warning = "Athena health is OK but the UI route $athenaUiUrl did not respond. Browser will still open the UI URL."
    Write-OneClickLog $warning "WARN"
    $oneClickState.warnings = @($oneClickState.warnings) + $warning
    Write-OneClickStatus -State $oneClickState
}
try {
    Start-Process $athenaUiUrl | Out-Null
    $oneClickState.opened_urls = @($oneClickState.opened_urls) + $athenaUiUrl
} catch {
    $warning = "Could not open Athena URL: $($_.Exception.Message)"
    Write-OneClickLog $warning "WARN"
    $oneClickState.warnings = @($oneClickState.warnings) + $warning
}
try {
    Start-Process $onyxUiUrl | Out-Null
    $oneClickState.opened_urls = @($oneClickState.opened_urls) + $onyxUiUrl
} catch {
    $warning = "Could not open Onyx URL: $($_.Exception.Message)"
    Write-OneClickLog $warning "WARN"
    $oneClickState.warnings = @($oneClickState.warnings) + $warning
}
Write-OneClickStatus -State $oneClickState

$mirrorUpdatePath = Join-Path $repoRoot "tools\sync\Mason_Mirror_Update.ps1"
if (-not (Test-Path -LiteralPath $mirrorUpdatePath)) {
    Write-OneClickLog ("Missing mirror update script: {0}" -f $mirrorUpdatePath) "ERROR"
    $oneClickState.error_summary = "Missing mirror update script: $mirrorUpdatePath"
    $oneClickState.finished_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    Write-OneClickStatus -State $oneClickState
    exit 1
}

Write-OneClickLog ("Running mirror update (reason=oneclick-fullstack, mirror={0})" -f $MirrorPath)
& powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $mirrorUpdatePath -RootPath $repoRoot -Reason "oneclick-fullstack" -MirrorPath $MirrorPath
$mirrorExit = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
if ($mirrorExit -ne 0) {
    Write-OneClickLog ("Mirror update failed with exit code {0}" -f $mirrorExit) "ERROR"
    $oneClickState.error_summary = "Mirror update failed with exit code $mirrorExit"
    $oneClickState.finished_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    Write-OneClickStatus -State $oneClickState
    exit 1
}

Write-OneClickLog "One-click FullStack completed successfully."
$oneClickState.success = $true
$oneClickState.finished_at_utc = (Get-Date).ToUniversalTime().ToString("o")
Write-OneClickStatus -State $oneClickState
exit 0
