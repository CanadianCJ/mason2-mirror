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

Write-Host "[OnyxBuild] Mason Onyx Android debug build starting..." -ForegroundColor Cyan
Write-Host "[OnyxBuild] Base     : $Base"
Write-Host "[OnyxBuild] OnyxDir  : $OnyxDir"
Write-Host "[OnyxBuild] Artifacts: $Artifacts"
Write-Host ""

if (-not (Test-Path $OnyxDir)) {
    $msg = "Onyx project folder not found at $OnyxDir"
    Write-Error $msg
    $result = [pscustomobject]@{
        kind     = "onyx_android_debug"
        success  = $false
        started  = $startTime.ToString("o")
        finished = (Get-Date).ToString("o")
        apk_path = $null
        message  = $msg
    }
    $result | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 -Path (Join-Path $ReportsDir "onyx_android_debug_build.json")
    return
}

Push-Location $OnyxDir
try {
    if (-not $NoClean) {
        Write-Host "[OnyxBuild] flutter clean" -ForegroundColor DarkCyan
        flutter clean
    }

    Write-Host "[OnyxBuild] flutter pub get" -ForegroundColor DarkCyan
    flutter pub get

    Write-Host "[OnyxBuild] flutter build apk --debug" -ForegroundColor DarkCyan
    flutter build apk --debug

    $apkSource = Join-Path $OnyxDir "build\app\outputs\flutter-apk\app-debug.apk"
    if (-not (Test-Path $apkSource)) {
        throw "APK not found at expected path: $apkSource"
    }

    $stamp     = $startTime.ToString("yyyyMMdd_HHmmss")
    $apkTarget = Join-Path $Artifacts "onyx-app-debug-$stamp.apk"

    Copy-Item $apkSource $apkTarget -Force

    $result = [pscustomobject]@{
        kind     = "onyx_android_debug"
        success  = $true
        started  = $startTime.ToString("o")
        finished = (Get-Date).ToString("o")
        apk_path = $apkTarget
        message  = "Debug APK build succeeded."
    }

    Write-Host "[OnyxBuild] SUCCESS. APK: $apkTarget" -ForegroundColor Green
}
catch {
    $err = $_.Exception.Message
    Write-Host "[OnyxBuild] FAILED: $err" -ForegroundColor Red

    $result = [pscustomobject]@{
        kind     = "onyx_android_debug"
        success  = $false
        started  = $startTime.ToString("o")
        finished = (Get-Date).ToString("o")
        apk_path = $null
        message  = $err
    }
}
finally {
    Pop-Location
}

# Write JSON report for Mason / Athena to read later
$reportPath = Join-Path $ReportsDir "onyx_android_debug_build.json"
$result | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 -Path $reportPath

Write-Host "[OnyxBuild] Report written to $reportPath" -ForegroundColor DarkCyan
