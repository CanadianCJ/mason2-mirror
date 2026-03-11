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

function To-NormalizedPath {
    param([string]$Path)
    if (-not $Path) { return "" }
    return (($Path -replace "\\", "/").TrimStart("./")).ToLowerInvariant()
}

function Test-PathMatchesAnyPattern {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Patterns
    )

    $normalizedPath = To-NormalizedPath -Path $Path
    foreach ($pattern in @($Patterns)) {
        if (-not $pattern) { continue }
        $normalizedPattern = To-NormalizedPath -Path ([string]$pattern)
        if ($normalizedPath -like $normalizedPattern) {
            return $true
        }
    }
    return $false
}

function Get-AllowlistTopLevelNames {
    param(
        [Parameter(Mandatory = $true)][string[]]$Allowlist
    )

    $topNames = New-Object System.Collections.Generic.List[string]
    foreach ($entry in $Allowlist) {
        $normalized = (([string]$entry).Trim() -replace "/", "\")
        if (-not $normalized) {
            continue
        }
        $topName = ($normalized -split "[\\/]", 2)[0]
        if (-not $topName) {
            continue
        }
        if ($topNames -notcontains $topName) {
            $topNames.Add($topName) | Out-Null
        }
    }

    return @($topNames | Sort-Object -Unique)
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
$defaultSlimReportJsonAllowlist = @(
    "reports/mirror_update_last.json",
    "reports/mason2_core_status.json",
    "reports/bridge_status.json",
    "reports/component_inventory.json",
    "reports/drift_manifest.json",
    "reports/risk_normalize_report.json",
    "reports/approvals_posture.json",
    "reports/ingest_autopilot_status.json",
    "reports/stack_reset_last.json",
    "reports/start/start_run_last.json",
    "reports/start/last_failure.json",
    "reports/launcher/last_fullstack.json",
    "reports/launcher/last_coreonly.json"
)
$reportJsonAllowlist = @($defaultSlimReportJsonAllowlist)
$maxMirroredFileBytes = 2097152
if ($mirrorPolicy -and ($mirrorPolicy.PSObject.Properties.Name -contains "report_json_allowlist")) {
    $rawPatterns = @($mirrorPolicy.report_json_allowlist | ForEach-Object { [string]$_ } | Where-Object { $_ })
    $unsafeBroad = @($rawPatterns | Where-Object {
            $p = To-NormalizedPath -Path ([string]$_)
            $p -eq "reports/*.json" -or
            $p -eq "reports/**/*.json" -or
            $p -eq "reports/**" -or
            $p -eq "reports/*" -or
            $p -eq "**/*.json" -or
            $p -eq "*.json"
        })
    if (@($unsafeBroad).Count -eq 0 -and @($rawPatterns).Count -gt 0) {
        $reportJsonAllowlist = @($rawPatterns)
    }
}
if ($mirrorPolicy -and ($mirrorPolicy.PSObject.Properties.Name -contains "allowlist")) {
    $allowlist = @($mirrorPolicy.allowlist | ForEach-Object { [string]$_ } | Where-Object { $_ })
}
if ($mirrorPolicy -and ($mirrorPolicy.PSObject.Properties.Name -contains "denylist")) {
    $denylist = @($mirrorPolicy.denylist | ForEach-Object { [string]$_ } | Where-Object { $_ })
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
$allowlistedTopLevelNames = @(Get-AllowlistTopLevelNames -Allowlist $allowlist)
foreach ($name in $allowlistedTopLevelNames) { $allowHash[$name.ToLowerInvariant()] = $true }
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
$reportJsonPatternMatched = @(
    $reportJsonFiles | Where-Object {
        $rel = To-RelativeName -Base $RootPath -Path $_.FullName
        Test-PathMatchesAnyPattern -Path $rel -Patterns $reportJsonAllowlist
    }
)
$reportJsonExcludedPattern = @(
    $reportJsonFiles | Where-Object {
        $rel = To-RelativeName -Base $RootPath -Path $_.FullName
        -not (Test-PathMatchesAnyPattern -Path $rel -Patterns $reportJsonAllowlist)
    }
)
$reportJsonEligible = @($reportJsonPatternMatched | Where-Object { [int64]$_.Length -le [int64]$maxMirroredFileBytes })
$reportJsonExcludedLarge = @($reportJsonPatternMatched | Where-Object { [int64]$_.Length -gt [int64]$maxMirroredFileBytes })

$manifest = [ordered]@{}
$manifest["generated_at_utc"] = (Get-Date).ToUniversalTime().ToString("o")
$manifest["source_root"] = $RootPath
$manifest["mirror_root"] = $mirrorRootValue
$manifest["policy_path"] = if (Test-Path -LiteralPath $mirrorPolicyPath) { $mirrorPolicyPath } else { $null }
$manifest["allowlist"] = $allowlist
$manifest["allowlisted_top_level_names"] = $allowlistedTopLevelNames
$manifest["denylist"] = $denylist
$manifest["last_sync_timestamp_utc"] = (Get-Date).ToUniversalTime().ToString("o")
$manifest["counts_per_folder"] = @($folderCounts)
$manifest["policy_summary"] = [ordered]@{
    allowlist_count = @($allowlist).Count
    denylist_count = @($denylist).Count
    top_level_allowlist_count = @($allowlistedTopLevelNames).Count
    source_top_level_review_count = @($sourceNotAllowlisted).Count
    source_top_level_review_items = @($sourceNotAllowlisted | Sort-Object -Unique | Select-Object -First 40)
}
$manifest["reports_json_policy"] = [ordered]@{
    allowlist_patterns = $reportJsonAllowlist
    max_file_bytes = [int]$maxMirroredFileBytes
    candidate_count = @($reportJsonFiles).Count
    matched_allowlist_count = @($reportJsonPatternMatched).Count
    excluded_pattern_count = @($reportJsonExcludedPattern).Count
    eligible_count = @($reportJsonEligible).Count
    excluded_large_count = @($reportJsonExcludedLarge).Count
    eligible_files = @($reportJsonEligible | Sort-Object Length -Descending | Select-Object -First 40 | ForEach-Object { To-RelativeName -Base $RootPath -Path $_.FullName })
    excluded_pattern_files = @($reportJsonExcludedPattern | Sort-Object Length -Descending | Select-Object -First 20 | ForEach-Object { To-RelativeName -Base $RootPath -Path $_.FullName })
    excluded_large_files = @($reportJsonExcludedLarge | Sort-Object Length -Descending | Select-Object -First 20 | ForEach-Object { To-RelativeName -Base $RootPath -Path $_.FullName })
}
$manifest["missing_from_mirror"] = $missing

$manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
Write-Host ("Mirror manifest written: {0}" -f $manifestPath)
