# Mason2-File: Seed_QueuePrioritize.ps1
# Purpose:
#   Build a prioritized view of seed queue based on recency and
#   simple novelty (duplicate content detection).
#   Writes:
#     - reports\seeds\queue_priority.txt
#     - Phase-1 signal for "Queue prioritization (novelty/recency)".

param(
    [string]$Base,
    [string]$States = "inbox,in-review,canary"
)

function Ok  { param($m) Write-Host "[ OK ] $m"   -ForegroundColor Green }
function Info{ param($m) Write-Host "[INFO] $m"  -ForegroundColor Cyan  }
function Warn{ param($m) Write-Host "[WARN] $m"  -ForegroundColor Yellow }
function Err { param($m) Write-Host "[ERR ] $m"  -ForegroundColor Red }

# Default base if not provided
if ([string]::IsNullOrWhiteSpace($Base)) {
    $Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
}

if (-not (Test-Path -LiteralPath $Base)) {
    Err ("Base folder not found: {0}" -f $Base)
    exit 1
}

$Base = (Resolve-Path $Base).Path

# State -> folder mapping
$stateMap = @{
    'inbox'       = 'seeds_inbox'
    'in-review'   = 'seeds_in_review'
    'review'      = 'seeds_in_review'
    'canary'      = 'seeds_canary'
    'applied'     = 'seeds_applied'
    'rolled-back' = 'seeds_rolled_back'
    'rolled_back' = 'seeds_rolled_back'
}

$queueRoot  = Join-Path $Base 'queue'
$reportsDir = Join-Path $Base 'reports'
$seedsDir   = Join-Path $reportsDir 'seeds'
$signalsDir = Join-Path $reportsDir 'signals'

foreach ($d in @($reportsDir,$seedsDir,$signalsDir)) {
    if (-not (Test-Path -LiteralPath $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
}

# Parse states list
$stateNames = @()
foreach ($s in ($States -split ',')) {
    $t = $s.Trim()
    if (-not [string]::IsNullOrWhiteSpace($t)) {
        $stateNames += $t.ToLower()
    }
}

if ($stateNames.Count -eq 0) {
    $stateNames = @('inbox','in-review','canary')
}

# Helper: SHA256 hash of content
function Get-ContentHash {
    param([string]$text)

    if ($null -eq $text) { return "" }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $sha   = [System.Security.Cryptography.SHA256]::Create()
    $hash  = $sha.ComputeHash($bytes)
    return ([System.BitConverter]::ToString($hash) -replace '-','').ToLower()
}

$items       = @()
$hashIndex   = @{}

foreach ($state in $stateNames) {
    if (-not $stateMap.ContainsKey($state)) {
        Warn ("Unknown state in list: {0}" -f $state)
        continue
    }

    $sub = $stateMap[$state]
    $dir = Join-Path $queueRoot $sub

    if (-not (Test-Path -LiteralPath $dir)) {
        continue
    }

    $files = Get-ChildItem -LiteralPath $dir -Filter '*.json' -File -ErrorAction SilentlyContinue
    foreach ($f in $files) {
        $rawJson = ""
        $obj     = $null
        $id      = $f.Name
        $created = $null
        $summary = ""
        $hash    = ""

        try {
            $rawJson = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
            $obj     = $rawJson | ConvertFrom-Json
        } catch {
            # leave obj null; still include file in list
        }

        if ($obj -ne $null) {
            if ($obj.PSObject.Properties.Name -contains 'id') {
                $id = $obj.id
            }
            if ($obj.PSObject.Properties.Name -contains 'created_utc') {
                $created = $obj.created_utc
            }
            if ($obj.PSObject.Properties.Name -contains 'content') {
                $c = $obj.content
                if ($c -and $c.summary) {
                    $summary = $c.summary
                } elseif ($c -and $c.raw) {
                    $summary = $c.raw
                }
                if ($c -and $c.raw) {
                    $hash = Get-ContentHash -text $c.raw
                }
            }
        }

        if ([string]::IsNullOrWhiteSpace($summary)) {
            $summary = "(no summary)"
        }

        if ([string]::IsNullOrWhiteSpace($hash) -and -not [string]::IsNullOrWhiteSpace($rawJson)) {
            $hash = Get-ContentHash -text $rawJson
        }

        if (-not [string]::IsNullOrWhiteSpace($hash)) {
            if (-not $hashIndex.ContainsKey($hash)) {
                $hashIndex[$hash] = @()
            }
            $hashIndex[$hash] += $id
        }

        # Convert created_utc to DateTime if possible
        $createdDt = $null
        if ($created) {
            try {
                $createdDt = [datetime]::Parse($created)
            } catch { }
        }
        if (-not $createdDt) {
            $createdDt = $f.LastWriteTime
        }

        $items += [pscustomobject]@{
            Id        = $id
            Path      = $f.FullName
            State     = $state
            Created   = $createdDt
            Hash      = $hash
            Summary   = $summary
        }
    }
}

if ($items.Count -eq 0) {
    Warn "No seeds found in requested states."
    $out = Join-Path $seedsDir 'queue_priority.txt'
    "No seeds found." | Set-Content -LiteralPath $out -Encoding UTF8
    exit 0
}

# Mark duplicates
$dupSet = @{}
foreach ($kv in $hashIndex.GetEnumerator()) {
    if ($kv.Key -and $kv.Value.Count -gt 1) {
        foreach ($id in $kv.Value) {
            $dupSet[$id] = $true
        }
    }
}

# Compute a simple priority score:
#   newer = higher; duplicates get penalty
$now = Get-Date
foreach ($item in $items) {
    $ageHours = ($now - $item.Created).TotalHours
    if ($ageHours -lt 0) { $ageHours = 0 }

    # Base score: recency (younger = higher)
    $score = 1000 - [math]::Min([math]::Round($ageHours), 1000)

    if ($dupSet.ContainsKey($item.Id)) {
        $score = $score - 200
    }

    $item | Add-Member -NotePropertyName "Priority" -NotePropertyValue $score
    $item | Add-Member -NotePropertyName "IsDuplicate" -NotePropertyValue ($dupSet.ContainsKey($item.Id))
}

# Sort by Priority desc, then Created desc
$sorted = $items | Sort-Object Priority, Created -Descending

$outPath = Join-Path $seedsDir 'queue_priority.txt'
$lines = @()
$lines += "# Mason2 Seed Queue Priority"
$lines += ""
$lines += ("Generated: {0}" -f $now.ToString('s'))
$lines += ""
$lines += "Id | State | Priority | CreatedUtc | Duplicate | Summary"
$lines += "-------------------------------------------------------------------"

foreach ($item in $sorted) {
    $dupFlag = if ($item.IsDuplicate) { "yes" } else { "no" }
    $line = "{0} | {1} | {2} | {3} | {4} | {5}" -f `
        $item.Id, `
        $item.State, `
        $item.Priority, `
        $item.Created.ToString("s"), `
        $dupFlag, `
        ($item.Summary.Replace("`r"," ").Replace("`n"," "))
    $lines += $line
}

$lines | Set-Content -LiteralPath $outPath -Encoding UTF8

Info ("Priority report -> {0}" -f $outPath)

# Phase-1 signal
$signalName = 'learner-seeds-queue-prioritization-novelty-recency.ok'
$signalPath = Join-Path $signalsDir $signalName
$signalText = "Seed_QueuePrioritize.ps1 ran at {0}" -f $now.ToString('s')
Set-Content -LiteralPath $signalPath -Value $signalText -Encoding UTF8
Ok ("Signal      -> {0}" -f $signalPath)
Ok "Queue prioritization complete."
