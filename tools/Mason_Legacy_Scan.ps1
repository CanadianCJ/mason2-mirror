param(
    [string]$RootPath = "C:\Users\Chris\Desktop\Mason2"
)

$ErrorActionPreference = "Stop"

$reportsDir        = Join-Path $RootPath "reports"
$legacyIndexFile   = Join-Path $reportsDir "mason_legacy_index.json"
$logFile           = Join-Path $reportsDir "mason_legacy_scan_log.txt"

if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

function Write-ScanLog {
    param([string]$Message)
    $line = "$(Get-Date -Format o) `t $Message"
    Add-Content -LiteralPath $logFile -Value $line
    Write-Host $Message
}

function Get-FileCategory {
    param([string]$Extension)

    if (-not $Extension) { return "other" }

    $e = $Extension.ToLowerInvariant()

    switch ($e) {
        ".ps1" { return "script" }
        ".psm1" { return "script" }
        ".py" { return "script" }
        ".js" { return "script" }
        ".ts" { return "script" }
        ".cs" { return "script" }
        ".dart" { return "script" }
        ".sh" { return "script" }
        ".bat" { return "script" }
        ".cmd" { return "script" }

        ".json" { return "config" }
        ".yaml" { return "config" }
        ".yml"  { return "config" }
        ".toml" { return "config" }
        ".ini"  { return "config" }

        ".md"   { return "doc" }
        ".txt"  { return "doc" }

        ".zip"  { return "archive" }
        ".7z"   { return "archive" }
        ".rar"  { return "archive" }

        ".exe"    { return "binary" }
        ".dll"    { return "binary" }
        ".pdb"    { return "binary" }
        ".db"     { return "binary" }
        ".sqlite" { return "binary" }

        default { return "other" }
    }
}

Write-ScanLog "=== Mason Legacy Scan START ==="
Write-ScanLog "RootPath = $RootPath"

# Look for likely legacy folders inside Mason2
$possibleNames = @(
    "Mason1",
    "Mason 1",
    "mason1",
    "mason broken uploads",
    "mason_broken_uploads",
    "Mason broken uploads",
    "Mason_Broken_Uploads"
)

$legacyFolders = @()
foreach ($name in $possibleNames) {
    $candidate = Join-Path $RootPath $name
    if (Test-Path $candidate -PathType Container) {
        $legacyFolders += $candidate
    }
}

if ($legacyFolders.Count -eq 0) {
    Write-ScanLog "No legacy folders found under $RootPath. Nothing to index."
    Write-Host "No Mason1 / mason broken uploads folders found. Exiting."
    exit 0
}

Write-ScanLog ("Found legacy folders:" + [Environment]::NewLine + ($legacyFolders -join [Environment]::NewLine))

# Collect all files under those folders
$files = @()
foreach ($folder in $legacyFolders) {
    Write-ScanLog "Scanning legacy folder: $folder"
    $files += Get-ChildItem -Path $folder -Recurse -File -ErrorAction SilentlyContinue
}

if ($files.Count -eq 0) {
    Write-ScanLog "No files found under legacy folders."
    $resultEmpty = [PSCustomObject]@{
        root_path      = $RootPath
        generated_utc  = (Get-Date).ToUniversalTime().ToString("o")
        legacy_folders = $legacyFolders
        file_count     = 0
        files          = @()
    }
    $resultEmpty | ConvertTo-Json -Depth 6 |
        Set-Content -LiteralPath $legacyIndexFile -Encoding UTF8
    Write-Host "Legacy index written (empty) to $legacyIndexFile"
    exit 0
}

$entries = foreach ($f in $files) {
    $cat = Get-FileCategory $f.Extension
    $rel = $f.FullName.Substring($RootPath.Length).TrimStart('\')

    [PSCustomObject]@{
        full_path        = $f.FullName
        rel_path         = $rel
        name             = $f.Name
        ext              = $f.Extension
        size_bytes       = $f.Length
        last_write_utc   = $f.LastWriteTimeUtc.ToString("o")
        category         = $cat
    }
}

# Some summary stats
$byCat = $entries | Group-Object category | Sort-Object Name
foreach ($g in $byCat) {
    Write-ScanLog ("Category {0}: {1} files" -f $g.Name, $g.Count)
}

$result = [PSCustomObject]@{
    root_path      = $RootPath
    generated_utc  = (Get-Date).ToUniversalTime().ToString("o")
    legacy_folders = $legacyFolders
    file_count     = $entries.Count
    files          = $entries
}

$result | ConvertTo-Json -Depth 6 |
    Set-Content -LiteralPath $legacyIndexFile -Encoding UTF8

Write-ScanLog "Wrote legacy index to $legacyIndexFile (file_count=$($entries.Count))"
Write-Host "Legacy index written to $legacyIndexFile"
Write-ScanLog "=== Mason Legacy Scan END ==="
