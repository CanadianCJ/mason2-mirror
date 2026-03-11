[CmdletBinding()]
param(
    [string]$RootPath = "",
    [Parameter(Mandatory = $true)][string]$Query,
    [ValidateSet("all", "hot", "cold")][string]$Tier = "all",
    [ValidateRange(1, 50)][int]$Top = 10,
    [switch]$WriteReport
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "Mason_Memory_Common.ps1")

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$results = Search-MemoryRecords -RepoRoot $repoRoot -QueryText $Query -Tier $Tier -Top $Top

if (@($results).Count -eq 0) {
    $results = Get-RecentMemoryItems -RepoRoot $repoRoot -Tier $Tier -Top $Top
}

$payload = [ordered]@{
    schema         = "mason-memory-retrieve-v1"
    generated_at_utc = Get-UtcNowIso
    repo_root      = $repoRoot
    query          = $Query
    tier           = $Tier
    top            = $Top
    matched_count  = @($results).Count
    items          = @($results)
}

if ($WriteReport) {
    Write-JsonFile -Path (Join-Path $reportsDir "memory_retrieve_last.json") -Object $payload
}

$payload | ConvertTo-Json -Depth 20
