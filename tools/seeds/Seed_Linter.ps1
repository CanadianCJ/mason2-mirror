# Mason2-File: Seed_Linter.ps1
# Purpose:
#   Scan all seed JSON files and:
#     - validate required fields
#     - enforce simple trust rules
#     - detect duplicates (by id and content hash)
#     - flag oversize seeds
#   Writes a lint report and an .ok/.pending signal.
# Notes:
#   - PS 5.1-safe, ASCII only

param(
    [string]$Base
)

function Ok  ($m){ Write-Host "[ OK ] $m"   -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m"  -ForegroundColor Cyan  }
function Warn($m){ Write-Host "[WARN] $m"  -ForegroundColor Yellow }
function Err ($m){ Write-Host "[ERR ] $m"  -ForegroundColor Red }

# Default base if not provided
if ([string]::IsNullOrWhiteSpace($Base)) {
    $Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
}

if (-not (Test-Path -LiteralPath $Base)) {
    Err "Base folder not found: $Base"
    exit 1
}

$Base       = (Resolve-Path $Base).Path
$SeedsDir   = Join-Path $Base 'seeds'
$ArchiveDir = Join-Path $SeedsDir 'archive'
$QueueDir   = Join-Path $Base 'queue'
$InboxDir   = Join-Path $QueueDir 'seeds_inbox'
$ReviewDir  = Join-Path $QueueDir 'seeds_in_review'
$CanaryDir  = Join-Path $QueueDir 'seeds_canary'
$AppliedDir = Join-Path $QueueDir 'seeds_applied'
$RolledDir  = Join-Path $QueueDir 'seeds_rolled_back'

$ReportsRoot = Join-Path $Base 'reports'
$SeedsReport = Join-Path $ReportsRoot 'seeds'
$SignalsDir  = Join-Path $ReportsRoot 'signals'

$SchemaFile = Join-Path $SeedsDir 'schema_v1.json'

# Ensure directories
$dirs = @(
    $SeedsDir,
    $ArchiveDir,
    $QueueDir,
    $InboxDir,
    $ReviewDir,
    $CanaryDir,
    $AppliedDir,
    $RolledDir,
    $ReportsRoot,
    $SeedsReport,
    $SignalsDir
)
foreach ($d in $dirs) {
    if (-not (Test-Path -LiteralPath $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Info ("Created directory: {0}" -f $d)
    }
}

$maxSizeBytes = 512KB

# Try to load schema (soft)
$schema = $null
if (Test-Path -LiteralPath $SchemaFile) {
    try {
        $schemaJson = Get-Content -LiteralPath $SchemaFile -Raw -Encoding UTF8
        $schema = $schemaJson | ConvertFrom-Json
        Info ("Loaded schema: {0}" -f $SchemaFile)
    } catch {
        Warn ("Failed to load schema_v1.json: {0}" -f $_.Exception.Message)
    }
} else {
    Warn "Seed schema not found (seeds\schema_v1.json). Run Seed_Schema_Init.ps1 first."
}

# Collect seed files
$seedFiles = @()
$foldersToScan = @($InboxDir,$ReviewDir,$CanaryDir,$AppliedDir,$RolledDir,$ArchiveDir)
foreach ($f in $foldersToScan) {
    if (Test-Path -LiteralPath $f) {
        $seedFiles += Get-ChildItem -LiteralPath $f -Filter '*.json' -File -ErrorAction SilentlyContinue
    }
}
$seedFiles = $seedFiles | Sort-Object FullName -Unique

if ($seedFiles.Count -eq 0) {
    Warn "No seed JSON files found."
}

$results   = @()
$idIndex   = @{}
$hashIndex = @{}

function Get-ContentHash([string]$s) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($s)
    $sha   = [System.Security.Cryptography.SHA256]::Create()
    $hash  = $sha.ComputeHash($bytes)
    return ([System.BitConverter]::ToString($hash) -replace '-','').ToLower()
}

foreach ($file in $seedFiles) {
    $issues   = @()
    $warnings = @()
    $jsonText = ''
    $obj      = $null

    try {
        $jsonText = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    } catch {
        $issues += ('read-failed:{0}' -f $_.Exception.Message)
    }

    if (-not [string]::IsNullOrWhiteSpace($jsonText)) {
        try {
            $obj = $jsonText | ConvertFrom-Json
        } catch {
            $issues += ('json-invalid:{0}' -f $_.Exception.Message)
        }
    }

    if ($obj -ne $null) {
        # Required fields
        $required = @('id','created_utc','source','metadata','trust','content')
        foreach ($field in $required) {
            if (-not ($obj.PSObject.Properties.Name -contains $field)) {
                $issues += ('missing-field:{0}' -f $field)
            }
        }

        # ID index
        if ($obj.id) {
            if (-not $idIndex.ContainsKey($obj.id)) {
                $idIndex[$obj.id] = @()
            }
            $idIndex[$obj.id] += $file.FullName
        } else {
            $issues += 'id-empty'
        }

        # Trust checks
        if ($obj.trust) {
            $lvl   = $obj.trust.level
            $score = $obj.trust.score
            $allowedLevels = @('system','user','external','low','unknown')

            if ($lvl -and -not ($allowedLevels -contains $lvl)) {
                $issues += ('trust-level-invalid:{0}' -f $lvl)
            }
            if ($score -ne $null) {
                if ($score -lt 0.0 -or $score -gt 1.0) {
                    $issues += ('trust-score-out-of-range:{0}' -f $score)
                }
            }
        }

        # Content hash for duplicate detection
        if ($obj.content -and $obj.content.raw) {
            $hash = Get-ContentHash $obj.content.raw
            if (-not $hashIndex.ContainsKey($hash)) {
                $hashIndex[$hash] = @()
            }
            $hashIndex[$hash] += $file.FullName
        }
    }

    # Size check
    $sizeBytes = $file.Length
    if ($sizeBytes -gt $maxSizeBytes) {
        $warnings += ('oversize:{0}' -f $sizeBytes)
    }

    $results += [pscustomobject]@{
        Path     = $file.FullName
        Issues   = $issues
        Warnings = $warnings
    }
}

# Duplicate IDs
foreach ($kv in $idIndex.GetEnumerator()) {
    if ($kv.Value.Count -gt 1) {
        foreach ($path in $kv.Value) {
            $hit = $results | Where-Object { $_.Path -eq $path }
            if ($hit) {
                $hit.Issues += ('duplicate-id:{0}' -f $kv.Key)
            }
        }
    }
}

# Duplicate content hashes
foreach ($kv in $hashIndex.GetEnumerator()) {
    if ($kv.Value.Count -gt 1) {
        foreach ($path in $kv.Value) {
            $hit = $results | Where-Object { $_.Path -eq $path }
            if ($hit) {
                $hit.Warnings += 'duplicate-content'
            }
        }
    }
}

# Build report
$reportPath = Join-Path $SeedsReport 'lint_report_latest.txt'
$lines = @()
$lines += '# Mason2 Seed Lint Report'
$lines += ''
$lines += ('Base: {0}' -f $Base)
$lines += ('Generated: {0}' -f (Get-Date).ToString('s'))
$lines += ''
$lines += ('Total seed files: {0}' -f $results.Count)
$lines += ''

$errorsCount   = 0
$warningsCount = 0

foreach ($r in $results) {
    $hasErrors = $r.Issues.Count   -gt 0
    $hasWarns  = $r.Warnings.Count -gt 0
    if ($hasErrors) { $errorsCount++ }
    if ($hasWarns)  { $warningsCount++ }

    $lines += ('## {0}' -f $r.Path)
    if ($hasErrors) {
        $lines += ('- Errors   : {0}' -f ($r.Issues   -join ', '))
    } else {
        $lines += '- Errors   : (none)'
    }
    if ($hasWarns) {
        $lines += ('- Warnings : {0}' -f ($r.Warnings -join ', '))
    } else {
        $lines += '- Warnings : (none)'
    }
    $lines += ''
}

$lines += ''
$lines += 'Summary:'
$lines += ('- Files with errors  : {0}' -f $errorsCount)
$lines += ('- Files with warnings: {0}' -f $warningsCount)

$lines | Set-Content -LiteralPath $reportPath -Encoding UTF8

Info ("Lint report -> {0}" -f $reportPath)

# Signals
$okSignal      = Join-Path $SignalsDir 'learner-seeds-seed-linter-size-format-dup.ok'
$pendingSignal = Join-Path $SignalsDir 'learner-seeds-seed-linter-size-format-dup.pending'

if ($errorsCount -eq 0) {
    if (Test-Path -LiteralPath $pendingSignal) { Remove-Item -LiteralPath $pendingSignal -Force }
    $msg = 'Seed linter: all files pass hard validation.'
    Set-Content -LiteralPath $okSignal -Value $msg -Encoding UTF8
    Ok ('Seed linter OK (no hard errors). Signal -> {0}' -f $okSignal)
} else {
    if (Test-Path -LiteralPath $okSignal) { Remove-Item -LiteralPath $okSignal -Force }
    $msg = 'Seed linter: {0} files with errors.' -f $errorsCount
    Set-Content -LiteralPath $pendingSignal -Value $msg -Encoding UTF8
    Warn ('Seed linter found {0} files with errors. Signal -> {1}' -f $errorsCount,$pendingSignal)
}
