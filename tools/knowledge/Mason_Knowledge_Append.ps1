[CmdletBinding()]
param(
    [string]$RootPath = "",
    [Parameter(Mandatory = $true)][string]$Source,
    [string]$Kind = "note",
    [Parameter(Mandatory = $true)][string]$Text,
    [string[]]$Tags = @(),
    [ValidateRange(0, 10)][int]$Priority = 5
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

function Convert-ToRedactedText {
    param([Parameter(Mandatory = $true)][string]$InputText)

    $redacted = $InputText
    $redacted = [regex]::Replace($redacted, "(?i)\bsk-proj-[A-Za-z0-9_\-]{8,}\b", "[REDACTED_OPENAI_KEY]")
    $redacted = [regex]::Replace($redacted, "(?i)\bsk-[A-Za-z0-9_\-]{8,}\b", "[REDACTED_OPENAI_KEY]")
    $redacted = [regex]::Replace($redacted, "(?i)\b(?:ghp|gho|ghu|ghs)_[A-Za-z0-9_]{20,}\b", "[REDACTED_GITHUB_TOKEN]")
    $redacted = [regex]::Replace($redacted, "(?i)\bgithub_pat_[A-Za-z0-9_]{20,}\b", "[REDACTED_GITHUB_TOKEN]")
    $redacted = [regex]::Replace(
        $redacted,
        "(?is)-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----.*?-----END [A-Z0-9 ]*PRIVATE KEY-----",
        "[REDACTED_PRIVATE_KEY_BLOCK]"
    )
    return $redacted
}

function Append-JsonLine {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object
    )
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Add-Content -LiteralPath $Path -Value (($Object | ConvertTo-Json -Depth 8 -Compress)) -Encoding UTF8
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$inboxDir = Join-Path $repoRoot "knowledge\inbox"
if (-not (Test-Path -LiteralPath $inboxDir)) {
    New-Item -ItemType Directory -Path $inboxDir -Force | Out-Null
}

$record = [ordered]@{
    ts       = (Get-Date).ToUniversalTime().ToString("o")
    source   = $Source
    kind     = $Kind
    text     = Convert-ToRedactedText -InputText $Text
    tags     = @($Tags | Where-Object { $_ } | ForEach-Object { [string]$_ } | Select-Object -Unique)
    priority = [int]$Priority
}

$dailyPath = Join-Path $inboxDir ("knowledge_inbox_{0}.jsonl" -f (Get-Date -Format "yyyyMMdd"))
$latestPath = Join-Path $inboxDir "knowledge_inbox_latest.jsonl"

Append-JsonLine -Path $dailyPath -Object $record
Append-JsonLine -Path $latestPath -Object $record

[pscustomobject]@{
    ok          = $true
    inbox_daily = $dailyPath
    inbox_latest = $latestPath
    appended_at = $record.ts
} | ConvertTo-Json -Depth 6
