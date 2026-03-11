[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$MirrorPath = "C:\Mason2_MIRROR",
    [int]$WaitTimeoutSeconds = 300
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = if ($RootPath -and (Test-Path -LiteralPath $RootPath)) {
    (Resolve-Path -LiteralPath $RootPath).Path
}
else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

$targetScript = Join-Path $repoRoot "tools\launch\Start_FullStack_OneClick.ps1"
if (-not (Test-Path -LiteralPath $targetScript)) {
    throw "Missing one-click launcher: $targetScript"
}

& $targetScript -RootPath $repoRoot -MirrorPath $MirrorPath -WaitTimeoutSeconds $WaitTimeoutSeconds
exit $LASTEXITCODE
