[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$logsDir = Join-Path $repoRoot 'logs'
$reportsDir = Join-Path $repoRoot 'reports'
$tmpDir = Join-Path $repoRoot 'tmp'

New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$zipPath = Join-Path $reportsDir ("support_bundle_{0}.zip" -f $timestamp)
$latestPath = Join-Path $reportsDir 'support_bundle_latest.txt'
$stageDir = Join-Path $tmpDir ("support_bundle_stage_{0}" -f $timestamp)

if (Test-Path -LiteralPath $stageDir) {
    Remove-Item -LiteralPath $stageDir -Recurse -Force
}
New-Item -Path $stageDir -ItemType Directory -Force | Out-Null

$selectedFiles = New-Object System.Collections.Generic.List[string]
$included = New-Object System.Collections.Generic.List[string]
$excluded = New-Object System.Collections.Generic.List[string]
$seen = @{}

function Add-LatestByPattern {
    param(
        [Parameter(Mandatory = $true)][string]$Dir,
        [Parameter(Mandatory = $true)][string]$Pattern
    )

    if (-not (Test-Path -LiteralPath $Dir)) {
        return
    }

    $latest = Get-ChildItem -LiteralPath $Dir -Filter $Pattern -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -ne $latest) {
        $selectedFiles.Add($latest.FullName)
    }
}

function Is-SecretPath {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $normalized = $RelativePath -replace '\\', '/'
    if ($normalized -match '(?i)(^|/)\.env$') { return $true }
    if ($normalized -match '(?i)(^|/)secrets_mason\.json$') { return $true }
    if ($normalized -match '(?i)secret') { return $true }
    if ($normalized -match '(?i)key') { return $true }
    return $false
}

function Get-RelativePathSafe {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$TargetPath
    )

    try {
        return [System.IO.Path]::GetRelativePath($BasePath, $TargetPath)
    }
    catch {
        $baseResolved = (Resolve-Path -LiteralPath $BasePath).Path.TrimEnd('\') + '\'
        $targetResolved = (Resolve-Path -LiteralPath $TargetPath).Path
        $baseUri = [System.Uri]$baseResolved
        $targetUri = [System.Uri]$targetResolved
        $relativeUri = $baseUri.MakeRelativeUri($targetUri).ToString()
        return [System.Uri]::UnescapeDataString($relativeUri).Replace('/', '\')
    }
}

Add-LatestByPattern -Dir $logsDir -Pattern 'stack_start_*.txt'
Add-LatestByPattern -Dir $logsDir -Pattern 'athena_stdout_*.log'
Add-LatestByPattern -Dir $logsDir -Pattern 'athena_stderr_*.log'
Add-LatestByPattern -Dir $logsDir -Pattern 'onyx_stdout_*.log'
Add-LatestByPattern -Dir $logsDir -Pattern 'onyx_stderr_*.log'

$statusSummaryPath = Join-Path $reportsDir 'status_summary.md'
if (Test-Path -LiteralPath $statusSummaryPath) {
    $selectedFiles.Add($statusSummaryPath)
}

$smokeLatestPath = Join-Path $reportsDir 'smoke_test_latest.json'
if (Test-Path -LiteralPath $smokeLatestPath) {
    $selectedFiles.Add($smokeLatestPath)
}

foreach ($fullPath in $selectedFiles) {
    if (-not $fullPath) {
        continue
    }
    if ($seen.ContainsKey($fullPath)) {
        continue
    }
    $seen[$fullPath] = $true

    if (-not (Test-Path -LiteralPath $fullPath)) {
        continue
    }

    $relativePath = Get-RelativePathSafe -BasePath ([string]$repoRoot) -TargetPath ([string]$fullPath)
    if (Is-SecretPath -RelativePath $relativePath) {
        $excluded.Add($relativePath)
        continue
    }

    $destinationPath = Join-Path $stageDir $relativePath
    $destinationDir = Split-Path -Parent $destinationPath
    if ($destinationDir -and -not (Test-Path -LiteralPath $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
    }

    Copy-Item -LiteralPath $fullPath -Destination $destinationPath -Force
    $included.Add($relativePath)
}

$manifestPath = Join-Path $stageDir 'bundle_manifest.txt'
$manifest = @(
    'Mason2 Support Bundle'
    ("Created: {0}" -f (Get-Date -Format 'o'))
    ("Root: {0}" -f $repoRoot)
    ''
    'Included files:'
)

if ($included.Count -eq 0) {
    $manifest += '(none)'
} else {
    $manifest += $included
}

if ($excluded.Count -gt 0) {
    $manifest += ''
    $manifest += 'Excluded files (secret filters):'
    $manifest += $excluded
}

$manifest | Set-Content -LiteralPath $manifestPath -Encoding UTF8

if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -Path (Join-Path $stageDir '*') -DestinationPath $zipPath -Force
$zipPath | Set-Content -LiteralPath $latestPath -Encoding UTF8

Remove-Item -LiteralPath $stageDir -Recurse -Force

Write-Host ("Support bundle created: {0}" -f $zipPath)
Write-Host ("Latest pointer written: {0}" -f $latestPath)
