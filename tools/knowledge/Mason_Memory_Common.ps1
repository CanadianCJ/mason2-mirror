Set-StrictMode -Version Latest

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

function Convert-ToArray {
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
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object -is [hashtable]) {
            if ($Object.ContainsKey($Name)) { return $Object[$Name] }
        }
        elseif ($Object.Contains($Name)) {
            return $Object[$Name]
        }
        return $Default
    }

    if ($Object.PSObject -and ($Object.PSObject.Properties.Name -contains $Name)) {
        return $Object.$Name
    }

    return $Default
}

function ConvertTo-OrderedDictionary {
    param($Object)

    $out = [ordered]@{}

    if ($null -eq $Object) {
        return $out
    }

    if ($Object -is [System.Collections.IDictionary]) {
        foreach ($key in $Object.Keys) {
            $out[[string]$key] = $Object[$key]
        }
        return $out
    }

    if ($Object.PSObject) {
        foreach ($prop in $Object.PSObject.Properties) {
            $out[[string]$prop.Name] = $prop.Value
        }
    }

    return $out
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

function Resolve-PathInsideRepo {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return (Join-Path $RepoRoot ($Path -replace "/", "\"))
}

function Get-UtcNowIso {
    return (Get-Date).ToUniversalTime().ToString("o")
}

function Convert-ToRedactedText {
    param([string]$Text)

    if ($null -eq $Text) { return "" }

    $redacted = [string]$Text
    $redacted = [regex]::Replace($redacted, "(?i)\bsk-proj-[A-Za-z0-9_\-]{8,}\b", "[REDACTED_OPENAI_KEY]")
    $redacted = [regex]::Replace($redacted, "(?i)\bsk-[A-Za-z0-9_\-]{8,}\b", "[REDACTED_OPENAI_KEY]")
    $redacted = [regex]::Replace($redacted, "(?i)\b(?:ghp|gho|ghu|ghs)_[A-Za-z0-9_]{20,}\b", "[REDACTED_GITHUB_TOKEN]")
    $redacted = [regex]::Replace($redacted, "(?i)\bgithub_pat_[A-Za-z0-9_]{20,}\b", "[REDACTED_GITHUB_TOKEN]")
    $redacted = [regex]::Replace($redacted, "(?i)\bAKIA[0-9A-Z]{16}\b", "[REDACTED_AWS_KEY]")
    $redacted = [regex]::Replace($redacted, "(?im)^\s*(password|token|secret|api[_-]?key)\s*[:=].*$", "[REDACTED_SECRET_LINE]")
    $redacted = [regex]::Replace($redacted, "(?is)-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----.*?-----END [A-Z0-9 ]*PRIVATE KEY-----", "[REDACTED_PRIVATE_KEY_BLOCK]")
    return $redacted
}

function Normalize-MemoryText {
    param([string]$Text)

    $safe = Convert-ToRedactedText -Text $Text
    if (-not $safe) { return "" }
    return ([regex]::Replace($safe, "\s+", " ")).Trim()
}

function Get-StringSha256 {
    param([string]$Text)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes([string]$Text)
        $hash = $sha.ComputeHash($bytes)
        return (-join ($hash | ForEach-Object { $_.ToString("x2") }))
    }
    finally {
        if ($sha) { $sha.Dispose() }
    }
}

function Get-FileSha256Safe {
    param([string]$Path)

    try {
        return ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash).ToLowerInvariant()
    }
    catch {
        return ""
    }
}

function Normalize-TagArray {
    param($Values)

    $seen = @{}
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($entry in Convert-ToArray $Values) {
        if ($null -eq $entry) { continue }
        $tag = ([string]$entry).Trim().ToLowerInvariant()
        if (-not $tag) { continue }
        $tag = ($tag -replace "[^a-z0-9_\-]+", "-").Trim("-")
        if (-not $tag) { continue }
        if ($seen.ContainsKey($tag)) { continue }
        $seen[$tag] = $true
        $out.Add($tag) | Out-Null
    }
    return @($out.ToArray())
}

function Get-MemorySummary {
    param([string]$Text)

    $normalized = Normalize-MemoryText -Text $Text
    if (-not $normalized) { return "" }
    if ($normalized.Length -le 280) { return $normalized }
    return ($normalized.Substring(0, 277) + "...")
}

function Get-MemoryStorePaths {
    param([string]$RepoRoot)

    $memoryRoot = Join-Path $RepoRoot "state\knowledge\memory"
    return [ordered]@{
        memory_root     = $memoryRoot
        records_dir     = Join-Path $memoryRoot "records"
        hot_dir         = Join-Path $memoryRoot "hot"
        cold_dir        = Join-Path $memoryRoot "cold"
        ingest_runs_dir = Join-Path $memoryRoot "ingest_runs"
        catalog_path    = Join-Path $memoryRoot "catalog.json"
        hot_index_path  = Join-Path $memoryRoot "hot\index.json"
        cold_index_path = Join-Path $memoryRoot "cold\index.json"
    }
}

function New-EmptyMemoryCatalog {
    return [ordered]@{
        schema         = "mason-memory-catalog-v1"
        updated_at_utc = Get-UtcNowIso
        items          = [ordered]@{}
    }
}

function New-EmptyMemoryIndex {
    param([Parameter(Mandatory = $true)][string]$Tier)

    return [ordered]@{
        schema         = "mason-memory-index-v1"
        tier           = $Tier
        updated_at_utc = Get-UtcNowIso
        items          = [ordered]@{}
    }
}

function Ensure-MemoryStore {
    param([string]$RepoRoot)

    $paths = Get-MemoryStorePaths -RepoRoot $RepoRoot
    foreach ($dirPath in @($paths.memory_root, $paths.records_dir, $paths.hot_dir, $paths.cold_dir, $paths.ingest_runs_dir)) {
        if (-not (Test-Path -LiteralPath $dirPath)) {
            New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
        }
    }

    if (-not (Test-Path -LiteralPath $paths.catalog_path)) {
        Write-JsonFile -Path $paths.catalog_path -Object (New-EmptyMemoryCatalog)
    }
    if (-not (Test-Path -LiteralPath $paths.hot_index_path)) {
        Write-JsonFile -Path $paths.hot_index_path -Object (New-EmptyMemoryIndex -Tier "hot")
    }
    if (-not (Test-Path -LiteralPath $paths.cold_index_path)) {
        Write-JsonFile -Path $paths.cold_index_path -Object (New-EmptyMemoryIndex -Tier "cold")
    }

    return [pscustomobject]$paths
}

function Load-MemoryCatalog {
    param([string]$RepoRoot)

    $paths = Ensure-MemoryStore -RepoRoot $RepoRoot
    $data = Read-JsonSafe -Path $paths.catalog_path -Default $null
    $catalog = New-EmptyMemoryCatalog

    if ($data) {
        $catalog.schema = [string](Get-PropertyValue -Object $data -Name "schema" -Default $catalog.schema)
        $catalog.updated_at_utc = [string](Get-PropertyValue -Object $data -Name "updated_at_utc" -Default $catalog.updated_at_utc)
        $catalog.items = ConvertTo-OrderedDictionary -Object (Get-PropertyValue -Object $data -Name "items" -Default ([ordered]@{}))
    }

    return $catalog
}

function Save-MemoryCatalog {
    param(
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]$Catalog
    )

    $paths = Ensure-MemoryStore -RepoRoot $RepoRoot
    $Catalog.updated_at_utc = Get-UtcNowIso
    Write-JsonFile -Path $paths.catalog_path -Object $Catalog
}

function Load-MemoryIndex {
    param(
        [string]$RepoRoot,
        [ValidateSet("hot", "cold")][string]$Tier
    )

    $paths = Ensure-MemoryStore -RepoRoot $RepoRoot
    $indexPath = if ($Tier -eq "hot") { $paths.hot_index_path } else { $paths.cold_index_path }
    $data = Read-JsonSafe -Path $indexPath -Default $null
    $index = New-EmptyMemoryIndex -Tier $Tier

    if ($data) {
        $index.schema = [string](Get-PropertyValue -Object $data -Name "schema" -Default $index.schema)
        $index.tier = [string](Get-PropertyValue -Object $data -Name "tier" -Default $Tier)
        $index.updated_at_utc = [string](Get-PropertyValue -Object $data -Name "updated_at_utc" -Default $index.updated_at_utc)
        $index.items = ConvertTo-OrderedDictionary -Object (Get-PropertyValue -Object $data -Name "items" -Default ([ordered]@{}))
    }

    return $index
}

function Save-MemoryIndex {
    param(
        [string]$RepoRoot,
        [ValidateSet("hot", "cold")][string]$Tier,
        [Parameter(Mandatory = $true)]$Index
    )

    $paths = Ensure-MemoryStore -RepoRoot $RepoRoot
    $Index.updated_at_utc = Get-UtcNowIso
    $path = if ($Tier -eq "hot") { $paths.hot_index_path } else { $paths.cold_index_path }
    Write-JsonFile -Path $path -Object $Index
}

function Get-MemoryRecordPath {
    param(
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$ContentSha256
    )

    $paths = Ensure-MemoryStore -RepoRoot $RepoRoot
    return (Join-Path $paths.records_dir ("{0}.json" -f $ContentSha256))
}

function Load-MemoryRecord {
    param(
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$ContentSha256
    )

    $recordPath = Get-MemoryRecordPath -RepoRoot $RepoRoot -ContentSha256 $ContentSha256
    return (Read-JsonSafe -Path $recordPath -Default $null)
}

function Save-MemoryRecord {
    param(
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]$Record
    )

    $contentSha256 = [string](Get-PropertyValue -Object $Record -Name "content_sha256" -Default "")
    if (-not $contentSha256) {
        throw "Record is missing content_sha256."
    }

    $recordPath = Get-MemoryRecordPath -RepoRoot $RepoRoot -ContentSha256 $contentSha256
    Write-JsonFile -Path $recordPath -Object $Record
    return $recordPath
}

function Get-MemoryPrimarySourcePath {
    param($Record)

    foreach ($sourceRef in Convert-ToArray (Get-PropertyValue -Object $Record -Name "source_refs" -Default @())) {
        $sourcePath = [string](Get-PropertyValue -Object $sourceRef -Name "source_path" -Default "")
        if ($sourcePath) { return $sourcePath }
        $sourceLabel = [string](Get-PropertyValue -Object $sourceRef -Name "source_label" -Default "")
        if ($sourceLabel) { return $sourceLabel }
    }
    return ""
}

function Resolve-MemoryTier {
    param(
        [ValidateSet("auto", "hot", "cold")][string]$Tier,
        [string]$RepoRoot,
        [string]$SourcePath,
        [string]$SourceKind,
        [string]$SourceModifiedUtc
    )

    if ($Tier -ne "auto") {
        return $Tier
    }

    if ($SourceKind -eq "inline") {
        return "hot"
    }

    $relativePath = ""
    if ($SourcePath) {
        $relativePath = (Get-RelativePathSafe -BasePath $RepoRoot -FullPath $SourcePath) -replace "\\", "/"
    }

    if ($relativePath -match "^(reports|state/knowledge|roadmap|roadmaps|tasks|plans|control|docs/knowledge_pack|knowledge/inbox)/") {
        return "hot"
    }

    if ($relativePath -match "^(archive|archives|backups|snapshots|quarantine)/") {
        return "cold"
    }

    if ($SourceModifiedUtc) {
        try {
            $modified = [DateTime]::Parse($SourceModifiedUtc).ToUniversalTime()
            if ($modified -ge (Get-Date).ToUniversalTime().AddDays(-30)) {
                return "hot"
            }
        }
        catch {
        }
    }

    return "cold"
}

function Get-SourceTypeFromPath {
    param([string]$Path)

    if (-not $Path) { return "txt" }
    switch (([System.IO.Path]::GetExtension($Path)).ToLowerInvariant()) {
        ".txt" { return "txt" }
        ".md" { return "md" }
        ".markdown" { return "md" }
        ".json" { return "json" }
        ".csv" { return "csv" }
        ".pdf" { return "pdf_metadata" }
        default { return "unknown" }
    }
}

function Get-DerivedMemoryTags {
    param(
        [string]$RepoRoot,
        [string]$SourcePath,
        [string]$ContentType,
        [string[]]$Tags,
        [string]$Tier
    )

    $combined = New-Object System.Collections.Generic.List[string]
    foreach ($tag in Normalize-TagArray -Values $Tags) {
        $combined.Add($tag) | Out-Null
    }

    if ($ContentType) {
        $combined.Add($ContentType) | Out-Null
    }

    if ($Tier) {
        $combined.Add(("tier-{0}" -f $Tier)) | Out-Null
    }

    if ($SourcePath) {
        $relativePath = (Get-RelativePathSafe -BasePath $RepoRoot -FullPath $SourcePath) -replace "\\", "/"
        if (-not [System.IO.Path]::IsPathRooted($relativePath)) {
            foreach ($segment in ($relativePath -split "/")) {
                if (-not $segment) { continue }
                $cleanSegment = (($segment -replace "\.[A-Za-z0-9]+$", "") -replace "[^A-Za-z0-9_\-]+", "-").Trim("-").ToLowerInvariant()
                if (-not $cleanSegment) { continue }
                $combined.Add($cleanSegment) | Out-Null
                if ($combined.Count -ge 8) { break }
            }
        }
    }

    return (Normalize-TagArray -Values $combined.ToArray())
}

function Update-MemoryCatalogAndIndexes {
    param(
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)]$Record
    )

    $contentSha256 = [string](Get-PropertyValue -Object $Record -Name "content_sha256" -Default "")
    if (-not $contentSha256) {
        throw "Memory record is missing content_sha256."
    }

    $catalog = Load-MemoryCatalog -RepoRoot $RepoRoot
    $hotIndex = Load-MemoryIndex -RepoRoot $RepoRoot -Tier "hot"
    $coldIndex = Load-MemoryIndex -RepoRoot $RepoRoot -Tier "cold"
    $recordPath = Save-MemoryRecord -RepoRoot $RepoRoot -Record $Record
    $relativeRecordPath = (Get-RelativePathSafe -BasePath $RepoRoot -FullPath $recordPath) -replace "\\", "/"
    $sourceRefs = @(Convert-ToArray (Get-PropertyValue -Object $Record -Name "source_refs" -Default @()))

    $meta = [ordered]@{
        record_path            = $relativeRecordPath
        tier                   = [string](Get-PropertyValue -Object $Record -Name "tier" -Default "cold")
        source_type            = [string](Get-PropertyValue -Object $Record -Name "source_type" -Default "")
        content_type           = [string](Get-PropertyValue -Object $Record -Name "content_type" -Default "")
        summary                = [string](Get-PropertyValue -Object $Record -Name "summary" -Default "")
        tags                   = @(Normalize-TagArray -Values (Get-PropertyValue -Object $Record -Name "tags" -Default @()))
        first_seen_utc         = [string](Get-PropertyValue -Object $Record -Name "first_seen_utc" -Default "")
        last_seen_utc          = [string](Get-PropertyValue -Object $Record -Name "last_seen_utc" -Default "")
        updated_at_utc         = [string](Get-PropertyValue -Object $Record -Name "updated_at_utc" -Default (Get-UtcNowIso))
        primary_source_path    = Get-MemoryPrimarySourcePath -Record $Record
        source_ref_count       = $sourceRefs.Count
        duplicate_source_count = [Math]::Max(0, $sourceRefs.Count - 1)
    }

    $catalog.items[$contentSha256] = $meta
    $hotIndex.items.Remove($contentSha256) | Out-Null
    $coldIndex.items.Remove($contentSha256) | Out-Null

    if ($meta.tier -eq "hot") {
        $hotIndex.items[$contentSha256] = $meta
    }
    else {
        $coldIndex.items[$contentSha256] = $meta
    }

    Save-MemoryCatalog -RepoRoot $RepoRoot -Catalog $catalog
    Save-MemoryIndex -RepoRoot $RepoRoot -Tier "hot" -Index $hotIndex
    Save-MemoryIndex -RepoRoot $RepoRoot -Tier "cold" -Index $coldIndex
    return $recordPath
}

function Upsert-MemoryRecord {
    param(
        [string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$ContentSha256,
        [Parameter(Mandatory = $true)][string]$HashBasis,
        [Parameter(Mandatory = $true)][string]$StoredText,
        [Parameter(Mandatory = $true)][int]$TextLength,
        [Parameter(Mandatory = $true)][bool]$TextTruncated,
        [Parameter(Mandatory = $true)][string]$SourceKind,
        [string]$SourcePath = "",
        [string]$SourceLabel = "",
        [Parameter(Mandatory = $true)][string]$SourceType,
        [Parameter(Mandatory = $true)][string]$ContentType,
        [string]$SourceModifiedUtc = "",
        [long]$SourceSizeBytes = -1,
        [ValidateSet("auto", "hot", "cold")][string]$Tier = "auto",
        [string[]]$Tags = @()
    )

    $now = Get-UtcNowIso
    $resolvedTier = Resolve-MemoryTier -Tier $Tier -RepoRoot $RepoRoot -SourcePath $SourcePath -SourceKind $SourceKind -SourceModifiedUtc $SourceModifiedUtc
    $existing = Load-MemoryRecord -RepoRoot $RepoRoot -ContentSha256 $ContentSha256
    $record = $null
    $wasDuplicate = $false

    if ($existing) {
        $record = [ordered]@{
            schema                  = [string](Get-PropertyValue -Object $existing -Name "schema" -Default "mason-memory-record-v1")
            content_sha256          = $ContentSha256
            content_hash_basis      = [string](Get-PropertyValue -Object $existing -Name "content_hash_basis" -Default $HashBasis)
            source_kind             = [string](Get-PropertyValue -Object $existing -Name "source_kind" -Default $SourceKind)
            source_type             = [string](Get-PropertyValue -Object $existing -Name "source_type" -Default $SourceType)
            content_type            = [string](Get-PropertyValue -Object $existing -Name "content_type" -Default $ContentType)
            tier                    = [string](Get-PropertyValue -Object $existing -Name "tier" -Default $resolvedTier)
            summary                 = [string](Get-PropertyValue -Object $existing -Name "summary" -Default "")
            normalized_text_excerpt = [string](Get-PropertyValue -Object $existing -Name "normalized_text_excerpt" -Default "")
            normalized_text_length  = [int](Get-PropertyValue -Object $existing -Name "normalized_text_length" -Default 0)
            text_truncated          = [bool](Get-PropertyValue -Object $existing -Name "text_truncated" -Default $false)
            input_tags              = @(Convert-ToArray (Get-PropertyValue -Object $existing -Name "input_tags" -Default @()))
            tags                    = @(Convert-ToArray (Get-PropertyValue -Object $existing -Name "tags" -Default @()))
            source_refs             = @(Convert-ToArray (Get-PropertyValue -Object $existing -Name "source_refs" -Default @()))
            first_seen_utc          = [string](Get-PropertyValue -Object $existing -Name "first_seen_utc" -Default $now)
            last_seen_utc           = [string](Get-PropertyValue -Object $existing -Name "last_seen_utc" -Default $now)
            created_at_utc          = [string](Get-PropertyValue -Object $existing -Name "created_at_utc" -Default $now)
            updated_at_utc          = [string](Get-PropertyValue -Object $existing -Name "updated_at_utc" -Default $now)
        }
        $wasDuplicate = $true
    }
    else {
        $record = [ordered]@{
            schema                  = "mason-memory-record-v1"
            content_sha256          = $ContentSha256
            content_hash_basis      = $HashBasis
            source_kind             = $SourceKind
            source_type             = $SourceType
            content_type            = $ContentType
            tier                    = $resolvedTier
            summary                 = Get-MemorySummary -Text $StoredText
            normalized_text_excerpt = $StoredText
            normalized_text_length  = [int][Math]::Max(0, $TextLength)
            text_truncated          = [bool]$TextTruncated
            input_tags              = @()
            tags                    = @()
            source_refs             = @()
            first_seen_utc          = $now
            last_seen_utc           = $now
            created_at_utc          = $now
            updated_at_utc          = $now
        }
    }

    if ($resolvedTier -eq "hot") {
        $record.tier = "hot"
    }
    elseif (-not $record.tier) {
        $record.tier = $resolvedTier
    }

    if ((-not $record.summary) -and $StoredText) {
        $record.summary = Get-MemorySummary -Text $StoredText
    }

    if (($TextLength -gt [int](Get-PropertyValue -Object $record -Name "normalized_text_length" -Default 0)) -and $StoredText) {
        $record.normalized_text_excerpt = $StoredText
        $record.normalized_text_length = [int][Math]::Max(0, $TextLength)
        $record.text_truncated = [bool]$TextTruncated
    }

    $record.input_tags = Normalize-TagArray -Values @(
        @(Convert-ToArray $record.input_tags) +
        @(Convert-ToArray $Tags)
    )

    $record.tags = Get-DerivedMemoryTags -RepoRoot $RepoRoot -SourcePath $SourcePath -ContentType $ContentType -Tags $record.input_tags -Tier $record.tier

    $refMatchKey = if ($SourcePath) { $SourcePath } else { $SourceLabel }
    $sourceRefs = New-Object System.Collections.Generic.List[object]
    $matched = $false

    foreach ($sourceRef in Convert-ToArray $record.source_refs) {
        if (-not $sourceRef) { continue }

        $ref = [ordered]@{
            source_kind          = [string](Get-PropertyValue -Object $sourceRef -Name "source_kind" -Default $SourceKind)
            source_type          = [string](Get-PropertyValue -Object $sourceRef -Name "source_type" -Default $SourceType)
            source_path          = [string](Get-PropertyValue -Object $sourceRef -Name "source_path" -Default "")
            source_path_relative = [string](Get-PropertyValue -Object $sourceRef -Name "source_path_relative" -Default "")
            source_label         = [string](Get-PropertyValue -Object $sourceRef -Name "source_label" -Default "")
            source_modified_utc  = [string](Get-PropertyValue -Object $sourceRef -Name "source_modified_utc" -Default "")
            source_size_bytes    = [long](Get-PropertyValue -Object $sourceRef -Name "source_size_bytes" -Default -1)
            first_ingested_utc   = [string](Get-PropertyValue -Object $sourceRef -Name "first_ingested_utc" -Default $now)
            last_ingested_utc    = [string](Get-PropertyValue -Object $sourceRef -Name "last_ingested_utc" -Default $now)
            seen_count           = [int](Get-PropertyValue -Object $sourceRef -Name "seen_count" -Default 1)
        }

        $candidateKey = if ($ref.source_path) { $ref.source_path } else { $ref.source_label }
        if (($candidateKey -eq $refMatchKey) -and (-not $matched)) {
            $ref.source_kind = $SourceKind
            $ref.source_type = $SourceType
            if ($SourcePath) {
                $ref.source_path = $SourcePath
                $ref.source_path_relative = Get-RelativePathSafe -BasePath $RepoRoot -FullPath $SourcePath
            }
            if ($SourceLabel) {
                $ref.source_label = $SourceLabel
            }
            if ($SourceModifiedUtc) {
                $ref.source_modified_utc = $SourceModifiedUtc
            }
            if ($SourceSizeBytes -ge 0) {
                $ref.source_size_bytes = $SourceSizeBytes
            }
            $ref.last_ingested_utc = $now
            $ref.seen_count = [int]$ref.seen_count + 1
            $matched = $true
        }

        $sourceRefs.Add([pscustomobject]$ref) | Out-Null
    }

    if (-not $matched) {
        $sourceRefs.Add([pscustomobject]([ordered]@{
            source_kind          = $SourceKind
            source_type          = $SourceType
            source_path          = $SourcePath
            source_path_relative = if ($SourcePath) { Get-RelativePathSafe -BasePath $RepoRoot -FullPath $SourcePath } else { "" }
            source_label         = $SourceLabel
            source_modified_utc  = $SourceModifiedUtc
            source_size_bytes    = $SourceSizeBytes
            first_ingested_utc   = $now
            last_ingested_utc    = $now
            seen_count           = 1
        })) | Out-Null
    }

    $record.source_refs = @($sourceRefs.ToArray())
    $record.last_seen_utc = $now
    $record.updated_at_utc = $now

    $recordPath = Update-MemoryCatalogAndIndexes -RepoRoot $RepoRoot -Record $record

    return [pscustomobject]@{
        content_sha256   = $ContentSha256
        tier             = $record.tier
        was_duplicate    = $wasDuplicate
        record_path      = $recordPath
        summary          = $record.summary
        source_ref_count = @($record.source_refs).Count
    }
}

function Get-MemoryQueryTokens {
    param([string]$Text)

    $normalized = Normalize-MemoryText -Text $Text
    if (-not $normalized) { return @() }

    $out = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    foreach ($match in [regex]::Matches($normalized.ToLowerInvariant(), "[a-z0-9]{3,}")) {
        $token = [string]$match.Value
        if ($seen.ContainsKey($token)) { continue }
        $seen[$token] = $true
        $out.Add($token) | Out-Null
    }

    return @($out.ToArray())
}

function Get-MemorySearchText {
    param($Record)

    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($value in @(
        (Get-PropertyValue -Object $Record -Name "summary" -Default ""),
        (Get-PropertyValue -Object $Record -Name "normalized_text_excerpt" -Default "")
    )) {
        $text = Normalize-MemoryText -Text ([string]$value)
        if ($text) {
            $parts.Add($text) | Out-Null
        }
    }

    foreach ($tag in Convert-ToArray (Get-PropertyValue -Object $Record -Name "tags" -Default @())) {
        $text = Normalize-MemoryText -Text ([string]$tag)
        if ($text) {
            $parts.Add($text) | Out-Null
        }
    }

    foreach ($sourceRef in Convert-ToArray (Get-PropertyValue -Object $Record -Name "source_refs" -Default @())) {
        foreach ($field in @("source_path", "source_path_relative", "source_label")) {
            $text = Normalize-MemoryText -Text ([string](Get-PropertyValue -Object $sourceRef -Name $field -Default ""))
            if ($text) {
                $parts.Add($text) | Out-Null
            }
        }
    }

    return ($parts.ToArray() -join " ")
}

function Get-MemoryOverlapScore {
    param(
        [string[]]$QueryTokens,
        [string]$CandidateText
    )

    if (@($QueryTokens).Count -eq 0) { return 0.0 }

    $candidateTokens = Get-MemoryQueryTokens -Text $CandidateText
    if (@($candidateTokens).Count -eq 0) { return 0.0 }

    $candidateMap = @{}
    foreach ($token in $candidateTokens) {
        $candidateMap[$token] = $true
    }

    $overlap = 0
    foreach ($queryToken in $QueryTokens) {
        if ($candidateMap.ContainsKey($queryToken)) {
            $overlap++
        }
    }

    return [Math]::Round(($overlap / [double][Math]::Max(1, @($QueryTokens).Count)), 6)
}

function Get-MemoryRecordList {
    param(
        [string]$RepoRoot,
        [ValidateSet("all", "hot", "cold")][string]$Tier = "all"
    )

    $catalog = Load-MemoryCatalog -RepoRoot $RepoRoot
    $records = New-Object System.Collections.Generic.List[object]

    foreach ($contentSha256 in $catalog.items.Keys) {
        $meta = $catalog.items[$contentSha256]
        if (-not $meta) { continue }

        $metaTier = [string](Get-PropertyValue -Object $meta -Name "tier" -Default "")
        if (($Tier -ne "all") -and ($metaTier -ne $Tier)) {
            continue
        }

        $recordPathRaw = [string](Get-PropertyValue -Object $meta -Name "record_path" -Default "")
        if (-not $recordPathRaw) {
            $recordPathRaw = (Get-RelativePathSafe -BasePath $RepoRoot -FullPath (Get-MemoryRecordPath -RepoRoot $RepoRoot -ContentSha256 $contentSha256))
        }

        $recordPath = Resolve-PathInsideRepo -RepoRoot $RepoRoot -Path $recordPathRaw
        $record = Read-JsonSafe -Path $recordPath -Default $null
        if (-not $record) { continue }
        $records.Add($record) | Out-Null
    }

    return @($records.ToArray())
}

function Search-MemoryRecords {
    param(
        [string]$RepoRoot,
        [string]$QueryText,
        [ValidateSet("all", "hot", "cold")][string]$Tier = "all",
        [ValidateRange(1, 100)][int]$Top = 10
    )

    $queryTokens = Get-MemoryQueryTokens -Text $QueryText
    $matches = New-Object System.Collections.Generic.List[object]

    foreach ($record in Get-MemoryRecordList -RepoRoot $RepoRoot -Tier $Tier) {
        $score = Get-MemoryOverlapScore -QueryTokens $queryTokens -CandidateText (Get-MemorySearchText -Record $record)
        if ($score -le 0.0) { continue }

        $recordTier = [string](Get-PropertyValue -Object $record -Name "tier" -Default "cold")
        $matches.Add([pscustomobject]@{
            content_sha256      = [string](Get-PropertyValue -Object $record -Name "content_sha256" -Default "")
            score               = [double]$score
            tier                = $recordTier
            tier_rank           = if ($recordTier -eq "hot") { 0 } else { 1 }
            summary             = [string](Get-PropertyValue -Object $record -Name "summary" -Default "")
            tags                = @(Convert-ToArray (Get-PropertyValue -Object $record -Name "tags" -Default @()))
            updated_at_utc      = [string](Get-PropertyValue -Object $record -Name "updated_at_utc" -Default "")
            primary_source_path = Get-MemoryPrimarySourcePath -Record $record
            content_type        = [string](Get-PropertyValue -Object $record -Name "content_type" -Default "")
            source_refs         = @(Convert-ToArray (Get-PropertyValue -Object $record -Name "source_refs" -Default @()))
        }) | Out-Null
    }

    $sorted = @(
        $matches.ToArray() |
        Sort-Object -Property `
            @{ Expression = { $_.score }; Descending = $true }, `
            @{ Expression = { $_.tier_rank }; Descending = $false }, `
            @{ Expression = { $_.primary_source_path }; Descending = $false }, `
            @{ Expression = { $_.content_sha256 }; Descending = $false }
    )

    return @($sorted | Select-Object -First $Top)
}

function Get-RecentMemoryItems {
    param(
        [string]$RepoRoot,
        [ValidateSet("all", "hot", "cold")][string]$Tier = "all",
        [ValidateRange(1, 100)][int]$Top = 10
    )

    $records = New-Object System.Collections.Generic.List[object]
    foreach ($record in Get-MemoryRecordList -RepoRoot $RepoRoot -Tier $Tier) {
        $recordTier = [string](Get-PropertyValue -Object $record -Name "tier" -Default "cold")
        $records.Add([pscustomobject]@{
            content_sha256      = [string](Get-PropertyValue -Object $record -Name "content_sha256" -Default "")
            tier                = $recordTier
            tier_rank           = if ($recordTier -eq "hot") { 0 } else { 1 }
            summary             = [string](Get-PropertyValue -Object $record -Name "summary" -Default "")
            tags                = @(Convert-ToArray (Get-PropertyValue -Object $record -Name "tags" -Default @()))
            updated_at_utc      = [string](Get-PropertyValue -Object $record -Name "updated_at_utc" -Default "")
            primary_source_path = Get-MemoryPrimarySourcePath -Record $record
            content_type        = [string](Get-PropertyValue -Object $record -Name "content_type" -Default "")
            source_refs         = @(Convert-ToArray (Get-PropertyValue -Object $record -Name "source_refs" -Default @()))
        }) | Out-Null
    }

    $sorted = @(
        $records.ToArray() |
        Sort-Object -Property `
            @{ Expression = { $_.tier_rank }; Descending = $false }, `
            @{ Expression = { $_.updated_at_utc }; Descending = $true }, `
            @{ Expression = { $_.primary_source_path }; Descending = $false }, `
            @{ Expression = { $_.content_sha256 }; Descending = $false }
    )

    return @($sorted | Select-Object -First $Top)
}
