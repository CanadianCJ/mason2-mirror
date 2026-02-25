param(
    # Optional: skip flutter clean if you want faster rebuilds
    [switch]$NoClean
)

$ErrorActionPreference = "Stop"

# Resolve Mason2 base and key paths
$ToolsDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$Base       = Split-Path -Parent $ToolsDir

$OnyxDir    = Join-Path $Base "Component - Onyx App\onyx_business_manager"
$Artifacts  = Join-Path $Base "artifacts\onyx"
$ReportsDir = Join-Path $Base "reports"

# Ensure output folders exist
foreach ($d in @($Artifacts, $ReportsDir)) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
}

$startTime = Get-Date

Write-Host "[OnyxRelease] Mason Onyx Android RELEASE bundle build starting..." -ForegroundColor Cyan
Write-Host "[OnyxRelease] Base     : $Base"
Write-Host "[OnyxRelease] OnyxDir  : $OnyxDir"
Write-Host "[OnyxRelease] Artifacts: $Artifacts"
Write-Host ""

if (-not (Test-Path $OnyxDir)) {
    $msg = "Onyx project folder not found at $OnyxDir"
    Write-Error $msg
    $result = [pscustomobject]@{
        kind        = "onyx_android_release_bundle"
        success     = $false
        started     = $startTime.ToString("o")
        finished    = (Get-Date).ToString("o")
        bundle_path = $null
        message     = $msg
    }
    $result | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 -Path (Join-Path $ReportsDir "onyx_android_release_build.json")
    return
}

Push-Location $OnyxDir
try {
    if (-not $NoClean) {
        Write-Host "[OnyxRelease] flutter clean" -ForegroundColor DarkCyan
        flutter clean
    }

    Write-Host "[OnyxRelease] flutter pub get" -ForegroundColor DarkCyan
    flutter pub get

    Write-Host "[OnyxRelease] flutter build appbundle --release" -ForegroundColor DarkCyan
    flutter build appbundle --release

    $bundleSource = Join-Path $OnyxDir "build\app\outputs\bundle\release\app-release.aab"
    if (-not (Test-Path $bundleSource)) {
        throw "Release bundle not found at expected path: $bundleSource"
    }

    $stamp       = $startTime.ToString("yyyyMMdd_HHmmss")
    $bundleTarget = Join-Path $Artifacts "onyx-app-release-$stamp.aab"

    Copy-Item $bundleSource $bundleTarget -Force

    $result = [pscustomobject]@{
        kind        = "onyx_android_release_bundle"
        success     = $true
        started     = $startTime.ToString("o")
        finished    = (Get-Date).ToString("o")
        bundle_path = $bundleTarget
        message     = "Release bundle build succeeded."
    }

    Write-Host "[OnyxRelease] SUCCESS. Bundle: $bundleTarget" -ForegroundColor Green
}
catch {
    $err = $_.Exception.Message
    Write-Host "[OnyxRelease] FAILED: $err" -ForegroundColor Red

    $result = [pscustomobject]@{
        kind        = "onyx_android_release_bundle"
        success     = $false
        started     = $startTime.ToString("o")
        finished    = (Get-Date).ToString("o")
        bundle_path = $null
        message     = $err
    }
}
finally {
    Pop-Location
}

# Write JSON report for Mason / Athena to read later
$reportPath = Join-Path $ReportsDir "onyx_android_release_build.json"
$result | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 -Path $reportPath

Write-Host "[OnyxRelease] Report written to $reportPath" -ForegroundColor DarkCyan
