[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$InputPath = "",
    [string[]]$InputPaths = @(),
    [string]$Text = "",
    [string]$SourceLabel = "",
    [string]$Label = "manual",
    [ValidateSet("auto", "hot", "cold")][string]$Tier = "auto",
    [string[]]$Tags = @(),
    [bool]$Recurse = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "..\knowledge\Mason_Memory_Common.ps1")

function Get-TextPayloadFromFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$MaxStoredChars
    )

    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    $sourceType = Get-SourceTypeFromPath -Path $Path
    $sourceModifiedUtc = $item.LastWriteTimeUtc.ToString("o")
    $sourceSizeBytes = [long]$item.Length

    switch ($sourceType) {
        "txt" { $rawText = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 }
        "md" { $rawText = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 }
        "json" { $rawText = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 }
        "csv" { $rawText = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 }
        "pdf_metadata" {
            $fileSha = Get-FileSha256Safe -Path $Path
            if (-not $fileSha) {
                return [pscustomobject]@{
                    ok     = $false
                    reason = "pdf_hash_unavailable"
                }
            }

            $metadataText = Normalize-MemoryText -Text (
                "pdf metadata reference name {0} size_bytes {1} modified_utc {2} file_sha256 {3}" -f
                $item.Name,
                $item.Length,
                $sourceModifiedUtc,
                $fileSha
            )

            return [pscustomobject]@{
                ok                  = $true
                content_sha256      = $fileSha
                hash_basis          = "file_sha256"
                stored_text         = $metadataText
                text_length         = $metadataText.Length
                text_truncated      = $false
                source_kind         = "file"
                source_type         = $sourceType
                content_type        = $sourceType
                source_path         = $Path
                source_label        = ""
                source_modified_utc = $sourceModifiedUtc
                source_size_bytes   = $sourceSizeBytes
            }
        }
        default {
            return [pscustomobject]@{
                ok     = $false
                reason = "unsupported_type"
            }
        }
    }

    $normalizedText = Normalize-MemoryText -Text $rawText
    if (-not $normalizedText) {
        return [pscustomobject]@{
            ok     = $false
            reason = "empty_after_redaction"
        }
    }

    $storedText = $normalizedText
    $textTruncated = $false
    if ($storedText.Length -gt $MaxStoredChars) {
        $storedText = $storedText.Substring(0, $MaxStoredChars)
        $textTruncated = $true
    }

    return [pscustomobject]@{
        ok                  = $true
        content_sha256      = Get-StringSha256 -Text $normalizedText
        hash_basis          = "normalized_text"
        stored_text         = $storedText
        text_length         = $normalizedText.Length
        text_truncated      = $textTruncated
        source_kind         = "file"
        source_type         = $sourceType
        content_type        = $sourceType
        source_path         = $Path
        source_label        = ""
        source_modified_utc = $sourceModifiedUtc
        source_size_bytes   = $sourceSizeBytes
    }
}

function Get-InlineTextPayload {
    param(
        [Parameter(Mandatory = $true)][string]$InlineText,
        [Parameter(Mandatory = $true)][string]$InlineLabel,
        [Parameter(Mandatory = $true)][int]$MaxStoredChars
    )

    $normalizedText = Normalize-MemoryText -Text $InlineText
    if (-not $normalizedText) {
        return [pscustomobject]@{
            ok     = $false
            reason = "empty_after_redaction"
        }
    }

    $storedText = $normalizedText
    $textTruncated = $false
    if ($storedText.Length -gt $MaxStoredChars) {
        $storedText = $storedText.Substring(0, $MaxStoredChars)
        $textTruncated = $true
    }

    return [pscustomobject]@{
        ok                  = $true
        content_sha256      = Get-StringSha256 -Text $normalizedText
        hash_basis          = "normalized_text"
        stored_text         = $storedText
        text_length         = $normalizedText.Length
        text_truncated      = $textTruncated
        source_kind         = "inline"
        source_type         = "txt"
        content_type        = "txt"
        source_path         = ""
        source_label        = $InlineLabel
        source_modified_utc = Get-UtcNowIso
        source_size_bytes   = $InlineText.Length
    }
}

function Add-UniquePath {
    param(
        [Parameter(Mandatory = $true)]$List,
        [Parameter(Mandatory = $true)]$Seen,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $key = $Path.ToLowerInvariant()
    if ($Seen.ContainsKey($key)) {
        return
    }
    $Seen[$key] = $true
    $List.Add($Path) | Out-Null
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$memoryPaths = Ensure-MemoryStore -RepoRoot $repoRoot
$runId = (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss_fff")
$runReportPath = Join-Path $reportsDir ("memory_ingest_{0}.json" -f $runId)
$runLastPath = Join-Path $reportsDir "memory_ingest_last.json"
$stateRunPath = Join-Path $memoryPaths.ingest_runs_dir ("{0}.json" -f $runId)
$maxStoredChars = 60000

$inputTargets = New-Object System.Collections.Generic.List[string]
foreach ($candidate in @($InputPath) + @(Convert-ToArray $InputPaths)) {
    $target = ([string]$candidate).Trim()
    if ($target) {
        $inputTargets.Add($target) | Out-Null
    }
}

if ((-not $Text) -and ($inputTargets.Count -eq 0)) {
    throw "Provide -Text or at least one input path."
}

$filesToIngest = New-Object System.Collections.Generic.List[string]
$seenPaths = @{}
$itemResults = New-Object System.Collections.Generic.List[object]

foreach ($target in $inputTargets) {
    $candidatePath = if ([System.IO.Path]::IsPathRooted($target)) { $target } else { Join-Path $repoRoot $target }
    if (-not (Test-Path -LiteralPath $candidatePath)) {
        $itemResults.Add([pscustomobject]@{
            source = $target
            status = "skipped"
            reason = "missing_path"
        }) | Out-Null
        continue
    }

    $resolvedTarget = (Resolve-Path -LiteralPath $candidatePath).Path
    $item = Get-Item -LiteralPath $resolvedTarget -ErrorAction Stop
    if ($item.PSIsContainer) {
        $children = if ($Recurse) {
            Get-ChildItem -LiteralPath $resolvedTarget -File -Recurse -ErrorAction Stop
        }
        else {
            Get-ChildItem -LiteralPath $resolvedTarget -File -ErrorAction Stop
        }

        foreach ($child in $children) {
            Add-UniquePath -List $filesToIngest -Seen $seenPaths -Path $child.FullName
        }
    }
    else {
        Add-UniquePath -List $filesToIngest -Seen $seenPaths -Path $resolvedTarget
    }
}

$ingestedCount = 0
$duplicateCount = 0
$skippedCount = 0

if ($Text) {
    $inlineLabel = if ($SourceLabel) { $SourceLabel } else { "inline:{0}" -f $Label }
    $payload = Get-InlineTextPayload -InlineText $Text -InlineLabel $inlineLabel -MaxStoredChars $maxStoredChars
    if ($payload.ok) {
        $result = Upsert-MemoryRecord -RepoRoot $repoRoot `
            -ContentSha256 $payload.content_sha256 `
            -HashBasis $payload.hash_basis `
            -StoredText $payload.stored_text `
            -TextLength $payload.text_length `
            -TextTruncated ([bool]$payload.text_truncated) `
            -SourceKind $payload.source_kind `
            -SourceLabel $payload.source_label `
            -SourceType $payload.source_type `
            -ContentType $payload.content_type `
            -SourceModifiedUtc $payload.source_modified_utc `
            -SourceSizeBytes ([long]$payload.source_size_bytes) `
            -Tier $Tier `
            -Tags @($Tags + @("inline", $Label))

        if ($result.was_duplicate) { $duplicateCount++ } else { $ingestedCount++ }
        $itemResults.Add([pscustomobject]@{
            source         = $inlineLabel
            status         = if ($result.was_duplicate) { "duplicate" } else { "ingested" }
            tier           = $result.tier
            content_sha256 = $result.content_sha256
            record_path    = $result.record_path
            summary        = $result.summary
        }) | Out-Null
    }
    else {
        $skippedCount++
        $itemResults.Add([pscustomobject]@{
            source = $inlineLabel
            status = "skipped"
            reason = $payload.reason
        }) | Out-Null
    }
}

foreach ($path in $filesToIngest) {
    $payload = Get-TextPayloadFromFile -Path $path -MaxStoredChars $maxStoredChars
    if (-not $payload.ok) {
        $skippedCount++
        $itemResults.Add([pscustomobject]@{
            source = $path
            status = "skipped"
            reason = $payload.reason
        }) | Out-Null
        continue
    }

    $result = Upsert-MemoryRecord -RepoRoot $repoRoot `
        -ContentSha256 $payload.content_sha256 `
        -HashBasis $payload.hash_basis `
        -StoredText $payload.stored_text `
        -TextLength $payload.text_length `
        -TextTruncated ([bool]$payload.text_truncated) `
        -SourceKind $payload.source_kind `
        -SourcePath $payload.source_path `
        -SourceLabel $payload.source_label `
        -SourceType $payload.source_type `
        -ContentType $payload.content_type `
        -SourceModifiedUtc $payload.source_modified_utc `
        -SourceSizeBytes ([long]$payload.source_size_bytes) `
        -Tier $Tier `
        -Tags @($Tags + @($Label))

    if ($result.was_duplicate) { $duplicateCount++ } else { $ingestedCount++ }
    $itemResults.Add([pscustomobject]@{
        source         = $path
        status         = if ($result.was_duplicate) { "duplicate" } else { "ingested" }
        tier           = $result.tier
        content_sha256 = $result.content_sha256
        record_path    = $result.record_path
        summary        = $result.summary
    }) | Out-Null
}

$payload = [ordered]@{
    schema              = "mason-memory-ingest-run-v1"
    run_id              = $runId
    label               = $Label
    timestamp_utc       = Get-UtcNowIso
    repo_root           = $repoRoot
    requested_tier      = $Tier
    recurse             = [bool]$Recurse
    source_count        = $itemResults.Count
    file_count          = $filesToIngest.Count
    ingested_count      = $ingestedCount
    duplicate_count     = $duplicateCount
    skipped_count       = $skippedCount
    memory_catalog_path = $memoryPaths.catalog_path
    hot_index_path      = $memoryPaths.hot_index_path
    cold_index_path     = $memoryPaths.cold_index_path
    items               = @($itemResults.ToArray())
}

Write-JsonFile -Path $runReportPath -Object $payload
Write-JsonFile -Path $runLastPath -Object $payload
Write-JsonFile -Path $stateRunPath -Object $payload

$payload | ConvertTo-Json -Depth 20
