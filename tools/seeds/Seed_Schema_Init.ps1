# Mason2-File: Seed_Schema_Init.ps1
# Purpose:
#   Define a canonical JSON schema for Mason "seeds" and create
#   base folders for seed states. Writes an .ok signal on success.
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
$SchemaFile = Join-Path $SeedsDir 'schema_v1.json'
$SchemaDoc  = Join-Path $SeedsDir 'schema_v1.md'
$SignalsDir = Join-Path $Base 'reports\signals'

$QueueDir   = Join-Path $Base 'queue'
$InboxDir   = Join-Path $QueueDir 'seeds_inbox'
$ReviewDir  = Join-Path $QueueDir 'seeds_in_review'
$CanaryDir  = Join-Path $QueueDir 'seeds_canary'
$AppliedDir = Join-Path $QueueDir 'seeds_applied'
$RolledDir  = Join-Path $QueueDir 'seeds_rolled_back'
$ArchiveDir = Join-Path $SeedsDir 'archive'

# Ensure directories exist
$dirs = @(
    $SeedsDir,
    $SignalsDir,
    $QueueDir,
    $InboxDir,
    $ReviewDir,
    $CanaryDir,
    $AppliedDir,
    $RolledDir,
    $ArchiveDir
)

foreach ($d in $dirs) {
    if (-not (Test-Path -LiteralPath $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Info "Created directory: $d"
    }
}

$utcNow = (Get-Date).ToUniversalTime().ToString("s") + "Z"

# Build schema object
$schema = @{
    version     = '1.0'
    updated_utc = $utcNow
    description = 'Mason2 Phase-1 seed schema (metadata, source, trust)'
    id_pattern  = 'seed-{yyyyMMddHHmmss}-{rand4}'

    required_fields = @(
        'id',
        'created_utc',
        'source',
        'metadata',
        'trust',
        'content'
    )

    source = @{
        description = 'Where this seed came from'
        required    = @('type')
        optional    = @('path','url','note','chat_id')
        type_enum   = @('chat_export','note','log','manual','system')
    }

    metadata = @{
        description = 'Tags and human-readable context'
        fields      = @('title','tags','topic','author')
        tags_hint   = 'Array of labels like [watchdog,disk]'
    }

    trust = @{
        description   = 'How much Mason should trust this seed'
        level_enum    = @('system','user','external','low','unknown')
        score_range   = @{ min = 0.0; max = 1.0 }
        default_level = 'user'
        default_score = 0.6
    }

    content = @{
        description = 'The actual knowledge'
        fields      = @('summary','raw')
        max_raw_len = 16000
    }
}

$schema | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $SchemaFile -Encoding UTF8

# Simple markdown description
$docLines = @(
    '# Mason2 Seed Schema v1',
    '',
    ('Generated: {0}' -f $utcNow),
    '',
    'Required top-level fields:',
    '',
    '  id           : unique seed identifier',
    '  created_utc  : ISO8601 UTC timestamp',
    '  source       : { type, path|url, note }',
    '  metadata     : { title, tags[], topic[], author }',
    '  trust        : { level, score }',
    '  content      : { summary, raw }',
    '',
    'Trust levels: system | user | external | low | unknown',
    'Trust score: 0.0 - 1.0 (default 0.6 for user seeds)'
)

$docLines | Set-Content -LiteralPath $SchemaDoc -Encoding UTF8

# Write signal
$signalName = 'learner-seeds-seed-schema-metadata-source-trust.ok'
$signalPath = Join-Path $SignalsDir $signalName
$signalText = 'Seed schema initialized at {0}' -f $utcNow
Set-Content -LiteralPath $signalPath -Value $signalText -Encoding UTF8

Ok "Seed schema initialized."
Ok "Schema file -> $SchemaFile"
Ok "Docs file   -> $SchemaDoc"
Ok "Signal      -> $signalPath"
