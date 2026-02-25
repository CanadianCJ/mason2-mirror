# Mason2-File: Seed_Move.ps1
# Purpose:
#   Move a seed JSON file between learner states:
#     inbox -> in-review -> canary -> applied -> rolled-back
#   and log the move. Writes a Phase-1 signal once used.

param(
    [string]$Base,
    [string]$Seed,
    [string]$FromState,
    [string]$ToState
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

# Map states -> subfolder names
$stateMap = @{
    'inbox'       = 'seeds_inbox'
    'in-review'   = 'seeds_in_review'
    'review'      = 'seeds_in_review'
    'canary'      = 'seeds_canary'
    'applied'     = 'seeds_applied'
    'rolled-back' = 'seeds_rolled_back'
    'rolled_back' = 'seeds_rolled_back'
}

if ([string]::IsNullOrWhiteSpace($FromState) -or
    [string]::IsNullOrWhiteSpace($ToState)   -or
    [string]::IsNullOrWhiteSpace($Seed)) {
    Err "Usage: Seed_Move.ps1 -Seed <id-or-file> -FromState <state> -ToState <state>"
    Err "States: inbox, in-review, canary, applied, rolled-back"
    exit 1
}

$fromKey = $FromState.ToLower()
$toKey   = $ToState.ToLower()

if (-not $stateMap.ContainsKey($fromKey)) {
    Err ("Unknown FromState: {0}" -f $FromState)
    exit 1
}
if (-not $stateMap.ContainsKey($toKey)) {
    Err ("Unknown ToState: {0}" -f $ToState)
    exit 1
}

$queueRoot = Join-Path $Base 'queue'
$fromDir   = Join-Path $queueRoot $stateMap[$fromKey]
$toDir     = Join-Path $queueRoot $stateMap[$toKey]

if (-not (Test-Path -LiteralPath $fromDir)) {
    Err ("Source state folder not found: {0}" -f $fromDir)
    exit 1
}
if (-not (Test-Path -LiteralPath $toDir)) {
    New-Item -ItemType Directory -Path $toDir -Force | Out-Null
    Info ("Created state folder: {0}" -f $toDir)
}

# Normalize seed argument (allow id, filename, full path)
$seedFileName = $Seed
if (-not $seedFileName.ToLower().EndsWith('.json')) {
    $seedFileName = $seedFileName + '.json'
}
try {
    $seedFileName = [System.IO.Path]::GetFileName($seedFileName)
} catch { }

$sourcePath = Join-Path $fromDir $seedFileName

if (-not (Test-Path -LiteralPath $sourcePath)) {
    Err ("Seed not found in {0}: {1}" -f $fromDir,$seedFileName)
    exit 1
}

$destPath = Join-Path $toDir $seedFileName

# Log file
$reportsDir = Join-Path $Base 'reports'
$seedsDir   = Join-Path $reportsDir 'seeds'
if (-not (Test-Path -LiteralPath $seedsDir)) {
    New-Item -ItemType Directory -Path $seedsDir -Force | Out-Null
}
$logPath = Join-Path $seedsDir 'moves_log.txt'

$now   = Get-Date
$entry = "{0} | {1} -> {2} | {3}" -f $now.ToString('s'),$FromState,$ToState,$seedFileName

try {
    Move-Item -LiteralPath $sourcePath -Destination $destPath -Force
} catch {
    Err ("Failed to move seed: {0}" -f $_.Exception.Message)
    exit 1
}

Add-Content -LiteralPath $logPath -Value $entry

Ok ("Moved seed: {0} -> {1}" -f $fromDir,$toDir)
Info ("Log entry: {0}" -f $entry)

# Phase-1 signal for state machine
$signalsDir = Join-Path $reportsDir 'signals'
if (-not (Test-Path -LiteralPath $signalsDir)) {
    New-Item -ItemType Directory -Path $signalsDir -Force | Out-Null
}
$signalName = 'learner-seeds-seed-states-inbox-review-canary-applied-rolledback.ok'
$signalPath = Join-Path $signalsDir $signalName
$signalText = "Seed_Move.ps1 used at {0}" -f $now.ToString('s')
Set-Content -LiteralPath $signalPath -Value $signalText -Encoding UTF8
Ok ("Signal      -> {0}" -f $signalPath)
