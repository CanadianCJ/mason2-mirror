[CmdletBinding()]
param(
    [string]$RootPath = ""
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

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$appendScript = Join-Path $repoRoot "tools\knowledge\Mason_Knowledge_Append.ps1"
if (-not (Test-Path -LiteralPath $appendScript)) {
    throw "Missing dependency: $appendScript"
}

$artifacts = @(
    Get-ChildItem -Path $reportsDir -Filter "onyx_*.json" -File -ErrorAction SilentlyContinue |
    Sort-Object -Property LastWriteTimeUtc -Descending |
    Select-Object -First 25
)

$artifactNames = @($artifacts | ForEach-Object { $_.Name })
$summary = if ($artifactNames.Count -gt 0) {
    "Onyx collector stub captured artifact names: {0}" -f ($artifactNames -join ", ")
}
else {
    "Onyx collector stub found no onyx_*.json artifacts."
}

& $appendScript `
    -RootPath $repoRoot `
    -Source "onyx_collector_stub" `
    -Kind "onyx_artifact_index" `
    -Text $summary `
    -Tags @("onyx", "collector", "stub") `
    -Priority 3
