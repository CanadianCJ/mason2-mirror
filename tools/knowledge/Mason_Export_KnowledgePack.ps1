[CmdletBinding()]
param(
    [string]$RootPath = "",
    [ValidateRange(1, 200)][int]$LatestRuns = 25
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
        [int]$Depth = 20
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

function Test-TokenLike {
    param([string]$Text)
    if (-not $Text) { return $false }
    return (
        $Text -match "(?i)\bsk-proj-[A-Za-z0-9_\-]{8,}\b" -or
        $Text -match "(?i)\bsk-[A-Za-z0-9_\-]{8,}\b" -or
        $Text -match "(?i)\b(?:ghp|gho|ghu|ghs)_[A-Za-z0-9_]{20,}\b" -or
        $Text -match "(?i)\bgithub_pat_[A-Za-z0-9_]{20,}\b" -or
        $Text -match "(?is)-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----" -or
        $Text -match "(?i)\bAKIA[0-9A-Z]{16}\b"
    )
}

function Remove-TokenLikeLines {
    param([string]$Text)
    if (-not $Text) { return "" }
    $lines = $Text -split "`r?`n"
    $safe = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if (Test-TokenLike -Text $line) { continue }
        $safe.Add($line)
    }
    return ($safe.ToArray() -join " ")
}

function Sanitize-String {
    param($Value)
    if ($null -eq $Value) { return "" }
    $text = [string]$Value
    if (-not $text.Trim()) { return "" }
    $text = Remove-TokenLikeLines -Text $text
    if (-not $text.Trim()) { return "" }

    $text = [regex]::Replace($text, "(?i)\bsk-proj-[A-Za-z0-9_\-]{8,}\b", "[REDACTED_OPENAI_KEY]")
    $text = [regex]::Replace($text, "(?i)\bsk-[A-Za-z0-9_\-]{8,}\b", "[REDACTED_OPENAI_KEY]")
    $text = [regex]::Replace($text, "(?i)\b(?:ghp|gho|ghu|ghs)_[A-Za-z0-9_]{20,}\b", "[REDACTED_GITHUB_TOKEN]")
    $text = [regex]::Replace($text, "(?i)\bgithub_pat_[A-Za-z0-9_]{20,}\b", "[REDACTED_GITHUB_TOKEN]")
    $text = [regex]::Replace(
        $text,
        "(?is)-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----.*?-----END [A-Z0-9 ]*PRIVATE KEY-----",
        "[REDACTED_PRIVATE_KEY_BLOCK]"
    )
    $text = ($text -replace "\s+", " ").Trim()
    return $text
}

function Sanitize-StringArray {
    param($Values)
    $out = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    foreach ($entry in To-Array $Values) {
        $safe = Sanitize-String -Value $entry
        if (-not $safe) { continue }
        $key = $safe.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        $out.Add($safe) | Out-Null
    }
    return @($out.ToArray())
}

function Count-RedactionHits {
    param($Object)
    if ($null -eq $Object) { return 0 }
    $json = $Object | ConvertTo-Json -Depth 12
    $matches = [regex]::Matches($json, "\[REDACTED_[A-Z_]+\]")
    return [int]$matches.Count
}

function Sanitize-Object {
    param($Value)
    if ($null -eq $Value) { return $null }

    if ($Value -is [string]) {
        return (Sanitize-String -Value $Value)
    }

    if ($Value -is [System.Array]) {
        $arr = New-Object System.Collections.Generic.List[object]
        foreach ($entry in $Value) {
            $san = Sanitize-Object -Value $entry
            if ($null -ne $san -and -not ($san -is [string] -and -not $san)) {
                $arr.Add($san) | Out-Null
            }
        }
        return @($arr.ToArray())
    }

    if ($Value -is [hashtable]) {
        $out = [ordered]@{}
        foreach ($k in $Value.Keys) {
            $keyName = [string]$k
            if ($keyName -match "^(?i)(content|content_redacted|raw|raw_text|text|body)$") {
                continue
            }
            $san = Sanitize-Object -Value $Value[$k]
            if ($null -eq $san) { continue }
            if ($san -is [string] -and -not $san) { continue }
            $out[$keyName] = $san
        }
        return [pscustomobject]$out
    }

    if ($Value.PSObject) {
        $out = [ordered]@{}
        foreach ($prop in $Value.PSObject.Properties) {
            $keyName = [string]$prop.Name
            if ($keyName -match "^(?i)(content|content_redacted|raw|raw_text|text|body)$") {
                continue
            }
            $san = Sanitize-Object -Value $prop.Value
            if ($null -eq $san) { continue }
            if ($san -is [string] -and -not $san) { continue }
            $out[$keyName] = $san
        }
        return [pscustomobject]$out
    }

    return $Value
}

function Get-RelativePathSafe {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$FullPath
    )
    try {
        $baseResolved = (Resolve-Path -LiteralPath $BasePath -ErrorAction Stop).Path
        $fullResolved = (Resolve-Path -LiteralPath $FullPath -ErrorAction Stop).Path
        if ($fullResolved.StartsWith($baseResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $fullResolved.Substring($baseResolved.Length).TrimStart("\", "/")
        }
        return $fullResolved
    }
    catch {
        return $FullPath
    }
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$roadmapsDir = Join-Path $repoRoot "roadmaps"
$packDir = Join-Path $repoRoot "docs\knowledge_pack"

if (-not (Test-Path -LiteralPath $packDir)) {
    New-Item -ItemType Directory -Path $packDir -Force | Out-Null
}

$indexOutPath = Join-Path $packDir "index.json"
$roadmapOutPath = Join-Path $packDir "roadmap.json"
$statsOutPath = Join-Path $packDir "stats.json"

$ingestFiles = @(
    Get-ChildItem -Path $reportsDir -Filter "ingest_index_*.json" -File -ErrorAction SilentlyContinue |
    Sort-Object -Property LastWriteTimeUtc -Descending |
    Select-Object -First $LatestRuns
)

$records = New-Object System.Collections.Generic.List[object]
$latestRunId = ""
$recordCount = 0
$chunkCount = 0
$fileCount = 0

foreach ($ingestFile in $ingestFiles) {
    $indexObj = Read-JsonSafe -Path $ingestFile.FullName -Default $null
    if (-not $indexObj) { continue }

    $runId = [string](Get-PropertyValue -Object $indexObj -Name "run_id" -Default "")
    if (-not $latestRunId -and $runId) { $latestRunId = $runId }
    $label = [string](Get-PropertyValue -Object $indexObj -Name "label" -Default "")
    $createdAt = [string](Get-PropertyValue -Object $indexObj -Name "created_at_utc" -Default $ingestFile.LastWriteTimeUtc.ToString("o"))
    $indexRel = Get-RelativePathSafe -BasePath $repoRoot -FullPath $ingestFile.FullName

    $chunks = @(To-Array (Get-PropertyValue -Object $indexObj -Name "chunks" -Default @()))
    if ($chunks.Count -gt 0) {
        foreach ($chunk in $chunks) {
            if (-not $chunk) { continue }
            $sourceFile = [string](Get-PropertyValue -Object $chunk -Name "source_file" -Default "")
            $chunkLabel = [string](Get-PropertyValue -Object $chunk -Name "label" -Default $label)
            $chunkTs = [string](Get-PropertyValue -Object $chunk -Name "created_at_utc" -Default $createdAt)
            $summary = Sanitize-String -Value (Get-PropertyValue -Object $chunk -Name "summary" -Default "")
            $decisions = Sanitize-StringArray -Values (Get-PropertyValue -Object $chunk -Name "decisions" -Default @())
            $rules = Sanitize-StringArray -Values (Get-PropertyValue -Object $chunk -Name "rules" -Default @())
            $openItems = Sanitize-StringArray -Values (Get-PropertyValue -Object $chunk -Name "open_items" -Default @())
            $tags = Sanitize-StringArray -Values (Get-PropertyValue -Object $chunk -Name "tags" -Default @())

            $truncated = $false
            $chunkChars = [int](Get-PropertyValue -Object $chunk -Name "chunk_chars" -Default 0)
            if ($chunkChars -ge 6000) { $truncated = $true }
            $chunkTruncated = Get-PropertyValue -Object $chunk -Name "truncated" -Default $null
            if ($null -ne $chunkTruncated) {
                $truncated = [bool]$chunkTruncated
            }

            $record = [ordered]@{
                run_id          = $runId
                ingest_index    = $indexRel
                file            = $sourceFile
                label           = $chunkLabel
                ts              = $chunkTs
                summary         = $summary
                decisions       = $decisions
                rules           = $rules
                open_items      = $openItems
                tags            = $tags
                redaction_hits  = 0
                truncated       = [bool]$truncated
            }
            $record.redaction_hits = Count-RedactionHits -Object $record
            $records.Add([pscustomobject]$record) | Out-Null
            $recordCount++
            $chunkCount++
        }
    }
    else {
        foreach ($fileEntry in To-Array (Get-PropertyValue -Object $indexObj -Name "files" -Default @())) {
            if (-not $fileEntry) { continue }
            $record = [ordered]@{
                run_id          = $runId
                ingest_index    = $indexRel
                file            = [string](Get-PropertyValue -Object $fileEntry -Name "path" -Default "")
                label           = $label
                ts              = $createdAt
                summary         = ""
                decisions       = @()
                rules           = @()
                open_items      = @()
                tags            = Sanitize-StringArray -Values (Get-PropertyValue -Object $indexObj -Name "tags" -Default @())
                redaction_hits  = 0
                truncated       = $false
            }
            $record.redaction_hits = Count-RedactionHits -Object $record
            $records.Add([pscustomobject]$record) | Out-Null
            $recordCount++
            $fileCount++
        }
    }
}

$roadmapSourcePath = Join-Path $roadmapsDir "master_roadmap.json"
$roadmapBuildPath = Join-Path $reportsDir "master_roadmap_build.json"
$taskgenLastPath = Join-Path $reportsDir "taskgen_last.json"

$roadmapSource = Read-JsonSafe -Path $roadmapSourcePath -Default ([ordered]@{})
$roadmapSanitized = Sanitize-Object -Value $roadmapSource
if (-not $roadmapSanitized) {
    $roadmapSanitized = [ordered]@{}
}
Write-JsonFile -Path $roadmapOutPath -Object $roadmapSanitized -Depth 24

$masterRoadmapBuild = Read-JsonSafe -Path $roadmapBuildPath -Default $null
$taskgenLast = Read-JsonSafe -Path $taskgenLastPath -Default $null

$indexPayload = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    records = @($records.ToArray())
}
Write-JsonFile -Path $indexOutPath -Object $indexPayload -Depth 24

$stats = [ordered]@{
    generated_at_utc      = (Get-Date).ToUniversalTime().ToString("o")
    last_run_id           = $latestRunId
    ingest_indexes_count  = $ingestFiles.Count
    source_records_count  = $recordCount
    chunk_records_count   = $chunkCount
    file_records_count    = $fileCount
    roadmap_present       = (Test-Path -LiteralPath $roadmapSourcePath)
    roadmap_build_present = ($null -ne $masterRoadmapBuild)
    taskgen_last_present  = ($null -ne $taskgenLast)
    taskgen_counts        = if ($taskgenLast -and (Get-PropertyValue -Object $taskgenLast -Name "counts" -Default $null)) {
        Sanitize-Object -Value (Get-PropertyValue -Object $taskgenLast -Name "counts" -Default $null)
    }
    else {
        $null
    }
}
Write-JsonFile -Path $statsOutPath -Object $stats -Depth 24

[pscustomobject]@{
    ok            = $true
    knowledge_pack = [ordered]@{
        index   = $indexOutPath
        roadmap = $roadmapOutPath
        stats   = $statsOutPath
    }
    counts = [ordered]@{
        ingest_indexes = $ingestFiles.Count
        records        = $recordCount
        chunks         = $chunkCount
        files          = $fileCount
    }
} | ConvertTo-Json -Depth 10
