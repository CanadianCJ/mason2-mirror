param(
    [string]$OnyxUrl = "http://localhost:5353"
)

$scriptPath = Join-Path $PSScriptRoot "Mason_Onyx_Health_Watcher.ps1"
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Mason_Onyx_Health_Watcher.ps1 not found at $scriptPath"
}

& powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $scriptPath -OnyxUrl $OnyxUrl
exit $LASTEXITCODE
