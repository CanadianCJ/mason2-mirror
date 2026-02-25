# Mason2-File: ChatToSeed_Ingest.ps1
# Purpose:
#   Convert chat/notes text files into Mason seed JSON files in
#   queue\seeds_inbox, using the seed schema.
#   Writes an .ok signal if at least one seed is created.
# Notes:
#   - PS 5.1-safe, ASCII only

param(
    [string]$Base,
    [string]$InputPath
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

$Base       = (Resolve-Path $Base).Path
$QueueDir   = Join-Path $Base 'queue'
$InboxDir   = Join-Path $QueueDir 'seeds_inbox'
$ReportsDir = Join-Path $Base 'reports'
$SignalsDir = Join-Path $ReportsDir 'signals'

# Ensure directories exist
$dirs = @($QueueDir,$InboxDir,$ReportsDir,$SignalsDir)
foreach ($d in $dirs) {
    if (-not (Test-Path -LiteralPath $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Info ("Created directory: {0}" -f $d)
    }
}

# Default input path if not provided
if ([string]::IsNullOrWhiteSpace($InputPath)) {
    $InputPath = Join-Path $QueueDir 'chat_ingest'
    if (-not (Test-Path -LiteralPath $InputPath)) {
        New-Item -ItemType Directory -Path $InputPath -Force | Out-Null
        Warn "No InputPath specified."
        Warn ("Created default input folder: {0}" -f $InputPath)
        Warn "Put chat/notes .txt/.md/.log files there and run this script again."
        exit 0
    }
}

if (-not (Test-Path -LiteralPath $InputPath)) {
    Err ("InputPath not found: {0}" -f $InputPath)
    exit 1
}

$InputPath = (Resolve-Path $InputPath).Path

Info ("Base      = {0}" -f $Base)
Info ("InputPath = {0}" -f $InputPath)
Info ("InboxDir  = {0}" -f $InboxDir)

# Helpers
function Get-Summary {
    param([string]$text)

    if ([string]::IsNullOrWhiteSpace($text)) { return "" }
    $lines    = $text -split "`r?`n"
    $nonEmpty = $lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    if ($nonEmpty.Count -eq 0) { return "" }
    $head = $nonEmpty[0]
    if ($head.Length -gt 200) {
        return ($head.Substring(0,197) + "...")
    }
    return $head
}

function New-SeedId {
    $ts   = Get-Date -Format 'yyyyMMddHHmmss'
    $rand = Get-Random -Minimum 1000 -Maximum 9999
    return ('seed-{0}-{1}' -f $ts,$rand)
}

# Collect input files
$files = Get-ChildItem -LiteralPath $InputPath -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in @('.txt','.md','.log') } |
    Sort-Object FullName

$maxFiles   = 50
$files      = $files | Select-Object -First $maxFiles
$maxRawLen  = 16000
$created    = 0

if ($files.Count -eq 0) {
    Warn ("No .txt/.md/.log files found in {0}" -f $InputPath)
    exit 0
}

foreach ($f in $files) {
    Info ("Ingesting: {0}" -f $f.FullName)

    $raw = ""
    try {
        $raw = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
    } catch {
        Warn ("Failed to read: {0} - {1}" -f $f.FullName,$_.Exception.Message)
        continue
    }

    if ([string]::IsNullOrWhiteSpace($raw)) {
        Warn ("Skipping empty file: {0}" -f $f.FullName)
        continue
    }

    if ($raw.Length -gt $maxRawLen) {
        $raw = $raw.Substring(0,$maxRawLen)
    }

    $summary = Get-Summary -text $raw
    $seedId  = New-SeedId
    $utcNow  = (Get-Date).ToUniversalTime().ToString('s') + 'Z'

    $seed = @{
        id          = $seedId
        created_utc = $utcNow
        source      = @{
            type = 'chat_export'
            path = $f.FullName
        }
        metadata    = @{
            title  = $f.Name
            tags   = @('chat','ingested')
            topic  = @()
            author = 'Chris'
        }
        trust       = @{
            level = 'user'
            score = 0.6
        }
        content     = @{
            summary = $summary
            raw     = $raw
        }
    }

    $outFile = Join-Path $InboxDir ($seedId + '.json')
    $seed | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outFile -Encoding UTF8
    $created++
}

$signalName = 'learner-seeds-chat-to-seed-ingestor-convert-past-chats-notes-to-seed-stubs-in-queue.ok'
$signalPath = Join-Path $SignalsDir $signalName

if ($created -gt 0) {
    $msg = 'ChatToSeed_Ingest: created {0} seeds at {1}' -f $created,(Get-Date).ToString('s')
    Set-Content -LiteralPath $signalPath -Value $msg -Encoding UTF8
    Ok ("Ingest complete: {0} seed(s) created. Signal -> {1}" -f $created,$signalPath)
} else {
    Warn "No seeds created (no non-empty files)."
}
