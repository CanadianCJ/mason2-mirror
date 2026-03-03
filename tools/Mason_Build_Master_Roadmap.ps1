[CmdletBinding()]
param(
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param([string]$CandidateRoot)
    if ($CandidateRoot -and (Test-Path -LiteralPath $CandidateRoot)) {
        return (Resolve-Path -LiteralPath $CandidateRoot).Path
    }
    return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
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

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 16
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value ($Object | ConvertTo-Json -Depth $Depth) -Encoding UTF8
}

function To-Array {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return $Value }
    return @($Value)
}

function Get-PropertyValue {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Default = $null
    )
    if ($null -eq $Object) { return $Default }
    if ($Object -is [hashtable]) {
        if ($Object.ContainsKey($Name)) { return $Object[$Name] }
        return $Default
    }
    if ($Object.PSObject -and ($Object.PSObject.Properties.Name -contains $Name)) {
        return $Object.$Name
    }
    return $Default
}

function Add-UniqueText {
    param(
        [Parameter(Mandatory = $true)]$List,
        [Parameter(Mandatory = $true)]$Seen,
        $Value
    )

    if ($null -eq $Value) { return }
    $text = ""
    if ($Value -is [string]) {
        $text = $Value
    }
    elseif ($Value.PSObject -and $Value.PSObject.Properties.Name -contains "text") {
        $text = [string]$Value.text
    }
    else {
        $text = [string]$Value
    }

    $text = $text.Trim()
    if (-not $text) { return }

    $key = $text.ToLowerInvariant()
    if ($Seen.ContainsKey($key)) { return }
    $Seen[$key] = $true
    $List.Add($text) | Out-Null
}

function Add-StringArray {
    param(
        [Parameter(Mandatory = $true)]$List,
        [Parameter(Mandatory = $true)]$Seen,
        $Values
    )
    foreach ($entry in To-Array $Values) {
        Add-UniqueText -List $List -Seen $Seen -Value $entry
    }
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$pendingDir = Join-Path $repoRoot "knowledge\pending_llm"
$roadmapsDir = Join-Path $repoRoot "roadmaps"

if (-not (Test-Path -LiteralPath $roadmapsDir)) {
    New-Item -ItemType Directory -Path $roadmapsDir -Force | Out-Null
}

$roadmapPath = Join-Path $roadmapsDir "master_roadmap.json"
$buildReportPath = Join-Path $reportsDir "master_roadmap_build.json"

$indexFiles = @(
    Get-ChildItem -Path $reportsDir -Filter "ingest_index_*.json" -File -ErrorAction SilentlyContinue |
    Sort-Object -Property LastWriteTimeUtc -Descending
)

$openItems = New-Object System.Collections.Generic.List[string]
$doneItems = New-Object System.Collections.Generic.List[string]
$decisions = New-Object System.Collections.Generic.List[string]
$rules = New-Object System.Collections.Generic.List[string]
$tags = New-Object System.Collections.Generic.List[string]

$openSeen = @{}
$doneSeen = @{}
$decisionSeen = @{}
$rulesSeen = @{}
$tagsSeen = @{}

$ingestSources = New-Object System.Collections.Generic.List[object]

foreach ($file in $indexFiles) {
    $data = Read-JsonSafe -Path $file.FullName -Default $null
    if (-not $data) { continue }

    $runId = ""
    $runValue = Get-PropertyValue -Object $data -Name "run_id" -Default ""
    if ($runValue) { $runId = [string]$runValue }
    $chunksProp = Get-PropertyValue -Object $data -Name "chunks" -Default @()
    $filesProp = Get-PropertyValue -Object $data -Name "files" -Default @()
    $ingestSources.Add([ordered]@{
            run_id           = $runId
            file             = $file.FullName
            last_write_utc   = $file.LastWriteTimeUtc.ToString("o")
            chunks           = @((To-Array $chunksProp)).Count
            files            = @((To-Array $filesProp)).Count
        }) | Out-Null

    Add-StringArray -List $openItems -Seen $openSeen -Values (Get-PropertyValue -Object $data -Name "open_items" -Default @())
    Add-StringArray -List $doneItems -Seen $doneSeen -Values (Get-PropertyValue -Object $data -Name "done_items" -Default @())
    Add-StringArray -List $decisions -Seen $decisionSeen -Values (Get-PropertyValue -Object $data -Name "decisions" -Default @())
    Add-StringArray -List $rules -Seen $rulesSeen -Values (Get-PropertyValue -Object $data -Name "rules" -Default @())
    Add-StringArray -List $tags -Seen $tagsSeen -Values (Get-PropertyValue -Object $data -Name "tags" -Default @())

    foreach ($chunk in To-Array $chunksProp) {
        if (-not $chunk) { continue }
        Add-StringArray -List $openItems -Seen $openSeen -Values (Get-PropertyValue -Object $chunk -Name "open_items" -Default @())
        Add-StringArray -List $doneItems -Seen $doneSeen -Values (Get-PropertyValue -Object $chunk -Name "done_items" -Default @())
        Add-StringArray -List $decisions -Seen $decisionSeen -Values (Get-PropertyValue -Object $chunk -Name "decisions" -Default @())
        Add-StringArray -List $rules -Seen $rulesSeen -Values (Get-PropertyValue -Object $chunk -Name "rules" -Default @())
        Add-StringArray -List $tags -Seen $tagsSeen -Values (Get-PropertyValue -Object $chunk -Name "tags" -Default @())
    }
}

$pendingFiles = @(
    Get-ChildItem -Path $pendingDir -Recurse -Filter "*.json" -File -ErrorAction SilentlyContinue |
    Sort-Object -Property LastWriteTimeUtc -Descending
)

$pendingQueueSummary = New-Object System.Collections.Generic.List[object]
foreach ($pf in $pendingFiles) {
    $parsed = Read-JsonSafe -Path $pf.FullName -Default $null
    $pendingQueueSummary.Add([ordered]@{
            file            = $pf.FullName
            queued_at_utc   = if ($parsed -and $parsed.queued_at_utc) { [string]$parsed.queued_at_utc } else { $pf.LastWriteTimeUtc.ToString("o") }
            run_id          = if ($parsed -and $parsed.run_id) { [string]$parsed.run_id } else { "" }
            source_file     = if ($parsed -and $parsed.source_file) { [string]$parsed.source_file } else { "" }
            chunk_index     = if ($parsed -and $parsed.chunk_index) { [int]$parsed.chunk_index } else { $null }
            reason          = if ($parsed -and $parsed.reason) { [string]$parsed.reason } else { "" }
        }) | Out-Null
}

$roadmap = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    sources = [ordered]@{
        ingest_indexes = @($ingestSources.ToArray())
        pending_llm_queue = @($pendingQueueSummary.ToArray())
    }
    open_items = @($openItems.ToArray())
    done_items = @($doneItems.ToArray())
    decisions = @($decisions.ToArray())
    rules = @($rules.ToArray())
    tags = @($tags.ToArray())
    totals = [ordered]@{
        ingest_indexes_count = $ingestSources.Count
        pending_llm_count    = $pendingQueueSummary.Count
        open_items_count     = $openItems.Count
        done_items_count     = $doneItems.Count
        decisions_count      = $decisions.Count
        rules_count          = $rules.Count
        tags_count           = $tags.Count
    }
}

$buildReport = [ordered]@{
    generated_at_utc = $roadmap.generated_at_utc
    roadmap_path     = $roadmapPath
    inputs = [ordered]@{
        ingest_files_used = $ingestSources.Count
        pending_queue_files_used = $pendingQueueSummary.Count
    }
    totals = $roadmap.totals
}

Write-JsonFile -Path $roadmapPath -Object $roadmap -Depth 20
Write-JsonFile -Path $buildReportPath -Object $buildReport -Depth 12

[pscustomobject]@{
    ok              = $true
    roadmap_path    = $roadmapPath
    build_report    = $buildReportPath
    totals          = $roadmap.totals
} | ConvertTo-Json -Depth 8
