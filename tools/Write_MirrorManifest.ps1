[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$MirrorPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function To-RelativeName {
    param(
        [Parameter(Mandatory = $true)][string]$Base,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $baseFull = [System.IO.Path]::GetFullPath($Base)
    $pathFull = [System.IO.Path]::GetFullPath($Path)
    if ($pathFull.StartsWith($baseFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $pathFull.Substring($baseFull.Length).TrimStart('\', '/')
        return ($rel -replace '/', '\')
    }
    return $pathFull
}

function Read-JsonSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        $Default = $null
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $Default
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if (-not $raw.Trim()) {
        return $Default
    }

    try {
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $Default
    }
}

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $RootPath) {
    $RootPath = Split-Path -Parent $scriptRoot
}
$RootPath = [System.IO.Path]::GetFullPath($RootPath)

if (-not $MirrorPath) {
    $parent = Split-Path -Parent $RootPath
    $candidate = Join-Path $parent "Mason2_MIRROR"
    if (Test-Path -LiteralPath $candidate) {
        $MirrorPath = $candidate
    }
}
if ($MirrorPath) {
    $MirrorPath = [System.IO.Path]::GetFullPath($MirrorPath)
}

$mirrorPolicyPath = Join-Path $RootPath "config\mirror_policy.json"
$mirrorPolicy = Read-JsonSafe -Path $mirrorPolicyPath -Default $null

$allowlist = @()
$denylist = @()
$reportJsonAllowlist = @("reports/*.json", "reports/**/*.json")
$maxMirroredFileBytes = 2097152
if ($mirrorPolicy -and ($mirrorPolicy.PSObject.Properties.Name -contains "allowlist")) {
    $allowlist = @($mirrorPolicy.allowlist | ForEach-Object { [string]$_ } | Where-Object { $_ })
}
if ($mirrorPolicy -and ($mirrorPolicy.PSObject.Properties.Name -contains "denylist")) {
    $denylist = @($mirrorPolicy.denylist | ForEach-Object { [string]$_ } | Where-Object { $_ })
}
if ($mirrorPolicy -and ($mirrorPolicy.PSObject.Properties.Name -contains "report_json_allowlist")) {
    $reportJsonAllowlist = @($mirrorPolicy.report_json_allowlist | ForEach-Object { [string]$_ } | Where-Object { $_ })
}
if ($mirrorPolicy -and ($mirrorPolicy.PSObject.Properties.Name -contains "max_mirrored_file_bytes")) {
    $tmpSize = 0
    if ([int]::TryParse([string]$mirrorPolicy.max_mirrored_file_bytes, [ref]$tmpSize) -and $tmpSize -gt 0) {
        $maxMirroredFileBytes = [int]$tmpSize
    }
}

if ($allowlist.Count -eq 0) {
    $allowlist = @(
        "Start_Mason2.ps1",
        "Start-Athena.ps1",
        "tools",
        "config",
        "docs",
        "MasonConsole",
        "bridge",
        "reports"
    )
}
if ($denylist.Count -eq 0) {
    $denylist = @(
        ".git",
        ".env",
        ".env.*",
        ".venv",
        "archives",
        "artifacts",
        "backups",
        "bundles",
        "drop",
        "dumps",
        "forensics",
        "ingest",
        "knowledge",
        "logs",
        "mason-sessions",
        "metrics",
        "quarantine",
        "secrets",
        "secrets*",
        "snapshots",
        "state",
        "uploads",
        "config\athena_device_registry.json",
        "reports\**\*.log",
        "reports\**\*.txt",
        "reports\start\**\*.log",
        "reports\launcher\**\*.log"
    )
}

$folderCounts = @()
foreach ($name in $allowlist) {
    $path = Join-Path $RootPath $name
    if (-not (Test-Path -LiteralPath $path)) {
        $folderCounts += [pscustomobject]@{
            name        = $name
            exists      = $false
            type        = "missing"
            file_count  = 0
            total_bytes = 0
        }
        continue
    }

    $item = Get-Item -LiteralPath $path -ErrorAction Stop
    if ($item.PSIsContainer) {
        $files = @(Get-ChildItem -LiteralPath $path -File -Recurse -ErrorAction SilentlyContinue)
        $bytes = 0
        foreach ($f in $files) {
            $bytes += [int64]$f.Length
        }
        $folderCounts += [pscustomobject]@{
            name        = $name
            exists      = $true
            type        = "directory"
            file_count  = $files.Count
            total_bytes = $bytes
        }
    }
    else {
        $folderCounts += [pscustomobject]@{
            name        = $name
            exists      = $true
            type        = "file"
            file_count  = 1
            total_bytes = [int64]$item.Length
        }
    }
}

$topLevelNames = @(
    Get-ChildItem -LiteralPath $RootPath -Force -ErrorAction SilentlyContinue |
    ForEach-Object { [string]$_.Name }
) | Sort-Object -Unique

$allowHash = @{}
foreach ($name in $allowlist) { $allowHash[$name.ToLowerInvariant()] = $true }
$sourceNotAllowlisted = @()
foreach ($name in $topLevelNames) {
    if (-not $allowHash.ContainsKey($name.ToLowerInvariant())) {
        $sourceNotAllowlisted += $name
    }
}

$allowlistAbsentInMirror = @()
$mirrorTopLevel = @()
if ($MirrorPath -and (Test-Path -LiteralPath $MirrorPath)) {
    $mirrorTopLevel = @(
        Get-ChildItem -LiteralPath $MirrorPath -Force -ErrorAction SilentlyContinue |
        ForEach-Object { [string]$_.Name }
    ) | Sort-Object -Unique

    $mirrorHash = @{}
    foreach ($name in $mirrorTopLevel) { $mirrorHash[$name.ToLowerInvariant()] = $true }
    foreach ($name in $allowlist) {
        $topName = ($name -split "[\\/]", 2)[0]
        if (-not $mirrorHash.ContainsKey($topName.ToLowerInvariant())) {
            if ($allowlistAbsentInMirror -notcontains $topName) {
                $allowlistAbsentInMirror += $topName
            }
        }
    }
}

$manifestPath = Join-Path $RootPath "docs\mirror_manifest.json"
$manifestDir = Split-Path -Parent $manifestPath
if (-not (Test-Path -LiteralPath $manifestDir)) {
    New-Item -ItemType Directory -Path $manifestDir -Force | Out-Null
}

$mirrorRootValue = $null
if ($MirrorPath) {
    $mirrorRootValue = $MirrorPath
}

$missing = [ordered]@{}
$missing["source_top_level_not_allowlisted"] = @($sourceNotAllowlisted | Sort-Object -Unique)
$missing["allowlist_names_absent_in_mirror"] = @($allowlistAbsentInMirror | Sort-Object -Unique)

$reportJsonFiles = @()
$reportsRoot = Join-Path $RootPath "reports"
if (Test-Path -LiteralPath $reportsRoot) {
    $reportJsonFiles = @(Get-ChildItem -LiteralPath $reportsRoot -File -Recurse -Filter *.json -ErrorAction SilentlyContinue)
}
$reportJsonEligible = @($reportJsonFiles | Where-Object { [int64]$_.Length -le [int64]$maxMirroredFileBytes })
$reportJsonExcludedLarge = @($reportJsonFiles | Where-Object { [int64]$_.Length -gt [int64]$maxMirroredFileBytes })

$manifest = [ordered]@{}
$manifest["generated_at_utc"] = (Get-Date).ToUniversalTime().ToString("o")
$manifest["source_root"] = $RootPath
$manifest["mirror_root"] = $mirrorRootValue
$manifest["policy_path"] = if (Test-Path -LiteralPath $mirrorPolicyPath) { $mirrorPolicyPath } else { $null }
$manifest["allowlist"] = $allowlist
$manifest["denylist"] = $denylist
$manifest["last_sync_timestamp_utc"] = (Get-Date).ToUniversalTime().ToString("o")
$manifest["counts_per_folder"] = @($folderCounts)
$manifest["reports_json_policy"] = [ordered]@{
    allowlist_patterns = $reportJsonAllowlist
    max_file_bytes = [int]$maxMirroredFileBytes
    candidate_count = @($reportJsonFiles).Count
    eligible_count = @($reportJsonEligible).Count
    excluded_large_count = @($reportJsonExcludedLarge).Count
    excluded_large_files = @($reportJsonExcludedLarge | Sort-Object Length -Descending | Select-Object -First 20 | ForEach-Object { To-RelativeName -Base $RootPath -Path $_.FullName })
}
$manifest["missing_from_mirror"] = $missing

$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Write-Host ("Mirror manifest written: {0}" -f $manifestPath)
