[CmdletBinding()]
param(
    [string]$RootPath = "",
    [int]$ContentReadMaxBytes = 262144,
    [int]$HashMaxBytes = 8388608,
    [int]$UnknownReviewAgeDays = 60
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

function Ensure-ParentDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Read-JsonSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        $Default = $null
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $Default
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if (-not $raw.Trim()) {
            return $Default
        }
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
        [int]$Depth = 18
    )

    Ensure-ParentDirectory -Path $Path
    $Object | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function To-Array {
    param($Value)

    if ($null -eq $Value) { return ,([object[]]@()) }
    if ($Value -is [System.Array]) { return ,([object[]]$Value) }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $items = New-Object System.Collections.ArrayList
        foreach ($item in $Value) {
            [void]$items.Add($item)
        }
        return ,([object[]]$items.ToArray())
    }
    return ,([object[]]@($Value))
}

function Convert-MapToPsObject {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Map
    )

    $record = New-Object psobject
    foreach ($key in $Map.Keys) {
        Add-Member -InputObject $record -NotePropertyName ([string]$key) -NotePropertyValue $Map[$key] -Force
    }
    return $record
}

function Normalize-Text {
    param($Value)

    return ([string]$Value).Trim()
}

function Get-RelativePathSafe {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$FullPath
    )

    try {
        $baseResolved = (Resolve-Path -LiteralPath $BasePath -ErrorAction Stop).Path.TrimEnd([char[]]@([char]'\'))
        $fullResolved = (Resolve-Path -LiteralPath $FullPath -ErrorAction Stop).Path
        if ($fullResolved.StartsWith($baseResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $fullResolved.Substring($baseResolved.Length).TrimStart([char[]]@([char]'\', [char]'/'))
        }
        return $fullResolved
    }
    catch {
        return $FullPath
    }
}

function Convert-ToUtcIso {
    param($DateValue)

    if ($null -eq $DateValue) {
        return ""
    }

    try {
        return ([datetime]$DateValue).ToUniversalTime().ToString("o")
    }
    catch {
        return ""
    }
}

function New-StringSet {
    return ,([System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase))
}

function Add-SetItem {
    param(
        [Parameter(Mandatory = $true)]$Set,
        [string]$Value
    )

    $text = Normalize-Text $Value
    if ($text) {
        [void]$Set.Add($text)
    }
}

function Test-SecretLikePath {
    param([string]$RelativePath)

    $pathText = Normalize-Text $RelativePath
    if (-not $pathText) {
        return $false
    }

    return [bool]($pathText -match '(?i)(^|[\\/])(\.env($|[.-])|secrets?[\\/]|secret[s._-]|credential|token|apikey|api_key|private[_-]?key|license[_-]?key)')
}

function Test-ArchiveLikePath {
    param([string]$RelativePath)

    $pathText = Normalize-Text $RelativePath
    return [bool]($pathText -match '(?i)(^|[\\/])(archive|archives|backups?|snapshots?|old|legacy|deprecated|quarantine|state_samples)([\\/]|$)|(\.bak($|[._-]))|(backup|copy|legacy|old|tmp|temp)(\.[^.]+)?$|\.zip$')
}

function Test-DangerousName {
    param([string]$RelativePath)

    $pathText = Normalize-Text $RelativePath
    return [bool]($pathText -match '(?i)(^|[\\/])(stop[_-].*deep|uninstall|disable|reset|wipe|purge|cleanup|kill|destroy|nuke|remove|delete)([^\\/]*?)\.ps1$')
}

function Test-VendoredDependencyPath {
    param([string]$RelativePath)

    $pathText = Normalize-Text $RelativePath
    if (-not $pathText) {
        return $false
    }

    $normalized = $pathText -replace '/', '\'
    if (-not $normalized.StartsWith("Component - Onyx App\", [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
    }

    if ($normalized -match '^(?i)Component - Onyx App\\(onyx_business_manager|onyx-web|mason-live|reviews)(\\|$)') {
        return $false
    }

    $remainder = $normalized.Substring("Component - Onyx App\".Length)
    return ($remainder -like "*\*") -or ($remainder -match '^(?i)(@|\.bin\\)')
}

function Test-ContentDangerous {
    param([string]$PreviewText)

    $content = Normalize-Text $PreviewText
    if (-not $content) {
        return $false
    }

    return [bool]($content -match '(?i)Remove-Item\s+.+-Recurse|Stop-Process\s+.+-Force|taskkill\s|git\s+reset\s+--hard|sc\.exe\s+delete|Format-Volume|Remove-Service|rd\s+/s\s+/q')
}

function Get-TopLevelDomain {
    param([string]$RelativePath)

    $pathText = Normalize-Text $RelativePath
    if (-not $pathText) {
        return "root"
    }

    $normalized = $pathText -replace '/', '\'
    $separatorIndex = $normalized.IndexOf('\')
    $first = if ($separatorIndex -ge 0) { $normalized.Substring(0, $separatorIndex) } else { $normalized }

    switch -Regex ($first) {
        '^tools$' { return "mason" }
        '^services$' { return "services" }
        '^MasonConsole$' { return "athena" }
        '^Component - Onyx App$' { return "onyx" }
        '^bridge$' { return "bridge" }
        '^config$' { return "config" }
        '^state$' { return "state" }
        '^roadmap$|^roadmaps$|^plans$|^specs$' { return "roadmap" }
        '^knowledge$|^ingest$' { return "knowledge" }
        '^reports$' { return "reports" }
        '^archive$|^archives$|^backups$|^snapshots$|^Mason1$|^Mason$' { return "archive" }
        default { return $first }
    }
}

function Get-ModuleClassification {
    param(
        [string]$RelativePath,
        [bool]$RecursiveScan,
        [bool]$MetadataOnly
    )

    $pathText = Normalize-Text $RelativePath
    if ($MetadataOnly) {
        return "active"
    }
    if (Test-ArchiveLikePath -RelativePath $pathText) {
        return "archive"
    }
    if (Test-DangerousName -RelativePath ($pathText + ".ps1")) {
        return "dangerous"
    }
    if ($RecursiveScan) {
        return "active"
    }
    return "unknown"
}

function Get-ScannableExtensionSet {
    $set = New-StringSet
    foreach ($ext in @(".ps1", ".psm1", ".psd1", ".py", ".json", ".jsonl", ".html", ".js", ".css", ".dart", ".yaml", ".yml", ".toml", ".md", ".txt", ".bat", ".cmd", ".csv")) {
        Add-SetItem -Set $set -Value $ext
    }
    return $set
}

function Get-RecursiveRootMap {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $rootMap = [ordered]@{}

    foreach ($relative in @(
        "tools",
        "services",
        "MasonConsole",
        "config",
        "state",
        "roadmap",
        "Component - Onyx App",
        "bridge"
    )) {
        $absolute = Join-Path $RepoRoot $relative
        if (Test-Path -LiteralPath $absolute) {
            $rootMap[$relative] = $absolute
        }
    }

    return $rootMap
}

function Get-ModuleOnlyRootMap {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)]$RecursiveRoots
    )

    $recursiveNameSet = New-StringSet
    foreach ($name in $RecursiveRoots.Keys) {
        Add-SetItem -Set $recursiveNameSet -Value $name
    }

    $moduleMap = [ordered]@{}
    foreach ($item in Get-ChildItem -LiteralPath $RepoRoot -Force -Directory | Sort-Object Name) {
        if ($recursiveNameSet.Contains($item.Name)) {
            continue
        }
        if ($item.Name -ieq ".git") {
            continue
        }
        if ($item.Name -match '^(?i)__pycache__$') {
            continue
        }
        $moduleMap[$item.Name] = $item.FullName
    }

    return $moduleMap
}

function Get-ExcludedDirectoryNames {
    $set = New-StringSet
    foreach ($name in @(
        ".git",
        "__pycache__",
        ".venv",
        "node_modules",
        ".dart_tool",
        "build",
        "dist",
        "artifacts",
        "bundles",
        "drop",
        "dumps",
        "logs",
        "reports",
        "bin",
        "obj"
    )) {
        Add-SetItem -Set $set -Value $name
    }
    return $set
}

function Test-PathContainsExcludedDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$FullPath,
        [Parameter(Mandatory = $true)]$ExcludedDirectoryNames
    )

    $parts = ($FullPath -replace '/', '\').Split([char[]]@([char]'\'), [System.StringSplitOptions]::RemoveEmptyEntries)
    foreach ($part in $parts) {
        if ($ExcludedDirectoryNames.Contains($part)) {
            return $true
        }
    }
    return $false
}

function Get-HashInfo {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$MaxBytes,
        [bool]$SkipForSecrets
    )

    $file = Get-Item -LiteralPath $Path -Force
    if ($SkipForSecrets) {
        return @{ hash_sha256 = ""; hash_status = "skipped"; hash_reason = "secret_like_path" }
    }
    if ($file.Length -gt $MaxBytes) {
        return @{ hash_sha256 = ""; hash_status = "skipped"; hash_reason = "too_large" }
    }
    try {
        $hash = Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop
        return @{ hash_sha256 = [string]$hash.Hash.ToLowerInvariant(); hash_status = "ok"; hash_reason = "" }
    }
    catch {
        return @{ hash_sha256 = ""; hash_status = "error"; hash_reason = $_.Exception.Message }
    }
}

function Get-ContentPreviewInfo {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyString()][string]$Extension = "",
        [int]$MaxBytes,
        [bool]$SkipForSecrets,
        [Parameter(Mandatory = $true)]$InspectableExtensions
    )

    if ($SkipForSecrets) {
        return @{ preview = ""; content_status = "skipped"; content_reason = "secret_like_path"; content_markers = @() }
    }
    if (-not $InspectableExtensions.Contains($Extension)) {
        return @{ preview = ""; content_status = "skipped"; content_reason = "non_text_extension"; content_markers = @() }
    }

    $file = Get-Item -LiteralPath $Path -Force
    if ($file.Length -gt $MaxBytes) {
        return @{ preview = ""; content_status = "skipped"; content_reason = "too_large"; content_markers = @() }
    }

    try {
        $preview = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
        $markers = New-Object System.Collections.Generic.List[object]
        foreach ($marker in @("TODO", "FIXME", "TBD", "placeholder", "coming soon", "stub", "wip")) {
            if ($preview -match [regex]::Escape($marker)) {
                $markers.Add($marker) | Out-Null
            }
        }
        return @{
            preview         = $preview
            content_status  = "ok"
            content_reason  = ""
            content_markers = To-Array $markers
        }
    }
    catch {
        return @{ preview = ""; content_status = "error"; content_reason = $_.Exception.Message; content_markers = @() }
    }
}

function Get-ParseState {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyString()][string]$Extension = "",
        [int]$MaxBytes,
        [bool]$SkipForSecrets
    )

    if ($SkipForSecrets) {
        return @{ parse_checked = $false; parse_ok = $null; parse_errors = @(); parse_reason = "secret_like_path" }
    }

    $file = Get-Item -LiteralPath $Path -Force
    if ($file.Length -gt $MaxBytes) {
        return @{ parse_checked = $false; parse_ok = $null; parse_errors = @(); parse_reason = "too_large" }
    }

    switch ($Extension) {
        ".json" {
            try {
                $null = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                return @{ parse_checked = $true; parse_ok = $true; parse_errors = @(); parse_reason = "" }
            }
            catch {
                return @{ parse_checked = $true; parse_ok = $false; parse_errors = @($_.Exception.Message); parse_reason = "json_parse_error" }
            }
        }
        ".jsonl" {
            try {
                $errors = New-Object System.Collections.Generic.List[object]
                $lineNumber = 0
                foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
                    $lineNumber++
                    $trimmed = Normalize-Text $line
                    if (-not $trimmed) { continue }
                    try {
                        $null = $trimmed | ConvertFrom-Json -ErrorAction Stop
                    }
                    catch {
                        $errors.Add("line ${lineNumber}: $($_.Exception.Message)") | Out-Null
                        if ($errors.Count -ge 3) {
                            break
                        }
                    }
                }
                if ($errors.Count -gt 0) {
                    return @{ parse_checked = $true; parse_ok = $false; parse_errors = To-Array $errors; parse_reason = "jsonl_parse_error" }
                }
                return @{ parse_checked = $true; parse_ok = $true; parse_errors = @(); parse_reason = "" }
            }
            catch {
                return @{ parse_checked = $true; parse_ok = $false; parse_errors = @($_.Exception.Message); parse_reason = "jsonl_parse_error" }
            }
        }
        { $_ -in @(".ps1", ".psm1", ".psd1") } {
            try {
                $tokens = $null
                $errors = $null
                [void][System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)
                if ($errors -and $errors.Count -gt 0) {
                    $messages = @($errors | Select-Object -First 5 | ForEach-Object { $_.Message })
                    return @{ parse_checked = $true; parse_ok = $false; parse_errors = $messages; parse_reason = "powershell_parse_error" }
                }
                return @{ parse_checked = $true; parse_ok = $true; parse_errors = @(); parse_reason = "" }
            }
            catch {
                return @{ parse_checked = $true; parse_ok = $false; parse_errors = @($_.Exception.Message); parse_reason = "powershell_parse_error" }
            }
        }
        default {
            return @{ parse_checked = $false; parse_ok = $null; parse_errors = @(); parse_reason = "not_supported" }
        }
    }
}

function New-ReferenceMap {
    return @{}
}

function Add-ReferenceEvidence {
    param(
        [Parameter(Mandatory = $true)][hashtable]$ReferenceMap,
        [string]$RelativePath,
        [string]$Evidence
    )

    $pathText = Normalize-Text $RelativePath
    $evidenceText = Normalize-Text $Evidence
    if (-not $pathText -or -not $evidenceText) {
        return
    }

    $existing = if ($ReferenceMap.ContainsKey($pathText)) { To-Array $ReferenceMap[$pathText] } else { To-Array $null }
    if ($existing -notcontains $evidenceText) {
        $updated = New-Object System.Collections.ArrayList
        foreach ($item in $existing) {
            [void]$updated.Add([string]$item)
        }
        [void]$updated.Add($evidenceText)
        $ReferenceMap[$pathText] = To-Array $updated
    }
}

function Resolve-RepoRelativeFromToken {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$SeedRelativePath,
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][hashtable]$PathIndex,
        [Parameter(Mandatory = $true)][hashtable]$BasenameIndex
    )

    $trimmed = ([string]$Token).Trim([char[]]@(
            [char]'"',
            [char]"'",
            [char]' ',
            [char]"`t",
            [char]"`r",
            [char]"`n",
            [char]'(',
            [char]')',
            [char]'[',
            [char]']',
            [char]'{',
            [char]'}',
            [char]',',
            [char]';'
        ))
    if (-not $trimmed) {
        return ""
    }

    $normalized = $trimmed -replace '/', '\'
    if ($normalized -match '^[A-Za-z]:\\') {
        if ($normalized.StartsWith($RepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $normalized.Substring($RepoRoot.Length).TrimStart([char[]]@([char]'\'))
        }
        return ""
    }

    $seedDirectory = Split-Path -Parent (Join-Path $RepoRoot $SeedRelativePath)
    $candidatePaths = New-Object System.Collections.Generic.List[object]

    if ($normalized.StartsWith(".\") -or $normalized.StartsWith("..\")) {
        $candidatePaths.Add((Join-Path $seedDirectory $normalized)) | Out-Null
    }
    elseif ($normalized.Contains("\")) {
        $candidatePaths.Add((Join-Path $RepoRoot $normalized)) | Out-Null
        $candidatePaths.Add((Join-Path $seedDirectory $normalized)) | Out-Null
    }
    else {
        $basename = [System.IO.Path]::GetFileName($normalized)
        if ($BasenameIndex.ContainsKey($basename) -and @($BasenameIndex[$basename]).Count -eq 1) {
            return [string]$BasenameIndex[$basename][0]
        }
    }

    foreach ($candidate in (To-Array $candidatePaths)) {
        if (Test-Path -LiteralPath $candidate) {
            $relative = Get-RelativePathSafe -BasePath $RepoRoot -FullPath $candidate
            if ($PathIndex.ContainsKey($relative)) {
                return $relative
            }
        }
    }

    return ""
}

function Add-ReferencedPathsFromText {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$SeedRelativePath,
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][hashtable]$PathIndex,
        [Parameter(Mandatory = $true)][hashtable]$BasenameIndex,
        [Parameter(Mandatory = $true)][hashtable]$ReferenceMap
    )

    $matches = New-Object System.Collections.Generic.List[object]
    foreach ($pattern in @(
        '(?i)(?:\.{1,2}[\\/])?[\w .-]+(?:[\\/][\w .-]+)+\.(?:ps1|psm1|psd1|py|json|jsonl|html|js|css|dart|yaml|yml|toml|txt|md|csv|bat|cmd)',
        '(?i)\b[\w .-]+\.(?:ps1|psm1|psd1|py|json|jsonl|html|js|css|dart|yaml|yml|toml|txt|md|csv|bat|cmd)\b'
    )) {
        foreach ($match in [regex]::Matches($Text, $pattern)) {
            $matches.Add($match.Value) | Out-Null
        }
    }

    foreach ($token in @($matches | Sort-Object -Unique)) {
        $resolved = Resolve-RepoRelativeFromToken -RepoRoot $RepoRoot -SeedRelativePath $SeedRelativePath -Token ([string]$token) -PathIndex $PathIndex -BasenameIndex $BasenameIndex
        if ($resolved) {
            Add-ReferenceEvidence -ReferenceMap $ReferenceMap -RelativePath $resolved -Evidence ("parsed_reference:" + $SeedRelativePath)
        }
    }
}

function Get-FamilyKey {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [string]$Extension = ""
    )

    $leaf = [System.IO.Path]::GetFileNameWithoutExtension($RelativePath).ToLowerInvariant()
    $normalized = $leaf
    $normalized = [regex]::Replace($normalized, '(\.|_|-)?\d{8,14}$', '')
    $normalized = [regex]::Replace($normalized, '(\.|_|-)?(copy|backup|bak|old|legacy|tmp|temp|fix|draft|v\d+)$', '')
    $normalized = [regex]::Replace($normalized, '[^a-z0-9]+', '_').Trim([char[]]@([char]'_'))
    if (-not $normalized) {
        $normalized = $leaf
    }
    return "$Extension|$normalized"
}

function Get-CanonicalRecordFromCluster {
    param(
        [Parameter(Mandatory = $true)]$Records
    )

    $scored = foreach ($record in $Records) {
        $score = 0
        if ($record.strong_active) { $score += 100 }
        $score += [int]$record.reference_count * 10
        if ($record.in_start_flow) { $score += 25 }
        if ($record.in_component_inventory) { $score += 15 }
        if ($record.recently_touched) { $score += 5 }
        if ($record.archive_signal) { $score -= 20 }
        if ($record.secret_like) { $score -= 5 }
        [pscustomobject]@{
            relative_path = $record.relative_path
            score         = $score
            path_length   = ([string]$record.relative_path).Length
        }
    }

    return ($scored | Sort-Object @{ Expression = "score"; Descending = $true }, @{ Expression = "path_length"; Descending = $false }, @{ Expression = "relative_path"; Descending = $false } | Select-Object -First 1).relative_path
}

function Get-GroupedDirectorySummary {
    param(
        [Parameter(Mandatory = $true)]$Records,
        [int]$MaxItems = 10
    )

    $rows = foreach ($group in ($Records | Group-Object directory)) {
        [pscustomobject]@{
            directory = if ($group.Name) { $group.Name } else { "." }
            count     = $group.Count
            samples   = @($group.Group | Select-Object -First 3 | ForEach-Object { $_.relative_path })
        }
    }

    return @($rows | Sort-Object @{ Expression = "count"; Descending = $true }, directory | Select-Object -First $MaxItems)
}

function New-SalvageItemId {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Action
    )

    $seed = [string]::Join("|", @($Action, $Path))
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($seed)
    $hash = [System.Security.Cryptography.SHA1]::Create().ComputeHash($bytes)
    $short = ([System.BitConverter]::ToString($hash)).Replace("-", "").Substring(0, 12).ToLowerInvariant()
    return "salv_{0}" -f $short
}

function Convert-MapToPsObject {
    param([Parameter(Mandatory = $true)]$Map)

    $obj = New-Object PSObject
    foreach ($key in $Map.Keys) {
        Add-Member -InputObject $obj -NotePropertyName ([string]$key) -NotePropertyValue $Map[$key] -Force
    }
    return $obj
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$inventoryPath = Join-Path $reportsDir "codebase_inventory_last.json"
$salvageQueuePath = Join-Path $reportsDir "codebase_salvage_queue.json"
$cleanupPlanPath = Join-Path $reportsDir "codebase_cleanup_plan.json"
$componentInventoryPath = Join-Path $reportsDir "component_inventory.json"
$startRunPath = Join-Path $reportsDir "start\start_run_last.json"
$validatorPath = Join-Path $reportsDir "system_validation_last.json"
$toolRegistryPath = Join-Path $repoRoot "config\tool_registry.json"
$componentRegistryPath = Join-Path $repoRoot "config\component_registry.json"

$excludedDirectoryNames = Get-ExcludedDirectoryNames
$inspectableExtensions = Get-ScannableExtensionSet
$recursiveRootMap = Get-RecursiveRootMap -RepoRoot $repoRoot
$moduleOnlyRootMap = Get-ModuleOnlyRootMap -RepoRoot $repoRoot -RecursiveRoots $recursiveRootMap

$moduleRecords = New-Object System.Collections.Generic.List[object]
foreach ($entry in $recursiveRootMap.GetEnumerator() | Sort-Object Name) {
    $relative = [string]$entry.Key
    $absolute = [string]$entry.Value
    $dirInfo = Get-Item -LiteralPath $absolute -Force
    $moduleRecords.Add([pscustomobject]@{
            record_type    = "module"
            relative_path  = $relative
            absolute_path  = $absolute
            classification = (Get-ModuleClassification -RelativePath $relative -RecursiveScan $true -MetadataOnly $false)
            metadata_only  = $false
            recursive_scan = $true
            last_write_utc = Convert-ToUtcIso $dirInfo.LastWriteTimeUtc
            domain         = Get-TopLevelDomain -RelativePath $relative
            reason         = "recursive_scan_root"
        }) | Out-Null
}

foreach ($entry in $moduleOnlyRootMap.GetEnumerator() | Sort-Object Name) {
    $relative = [string]$entry.Key
    $absolute = [string]$entry.Value
    $dirInfo = Get-Item -LiteralPath $absolute -Force
    $metadataOnly = $relative -ieq "reports"
    $moduleRecords.Add([pscustomobject]@{
            record_type    = "module"
            relative_path  = $relative
            absolute_path  = $absolute
            classification = (Get-ModuleClassification -RelativePath $relative -RecursiveScan $false -MetadataOnly $metadataOnly)
            metadata_only  = $metadataOnly
            recursive_scan = $false
            last_write_utc = Convert-ToUtcIso $dirInfo.LastWriteTimeUtc
            domain         = Get-TopLevelDomain -RelativePath $relative
            reason         = if ($metadataOnly) { "metadata_only_root" } else { "module_only_root" }
        }) | Out-Null
}

$files = New-Object System.Collections.Generic.List[object]
$seenRelativePaths = New-StringSet

foreach ($file in Get-ChildItem -LiteralPath $repoRoot -Force -File | Sort-Object FullName) {
    $relative = Get-RelativePathSafe -BasePath $repoRoot -FullPath $file.FullName
    if ($seenRelativePaths.Add($relative)) {
        $files.Add([pscustomobject]@{
                absolute_path = $file.FullName
                relative_path = $relative
        }) | Out-Null
    }
}

foreach ($entry in $recursiveRootMap.GetEnumerator()) {
    foreach ($file in Get-ChildItem -LiteralPath $entry.Value -Force -File -Recurse | Sort-Object FullName) {
        if (Test-PathContainsExcludedDirectory -FullPath $file.FullName -ExcludedDirectoryNames $excludedDirectoryNames) {
            continue
        }
        $relative = Get-RelativePathSafe -BasePath $repoRoot -FullPath $file.FullName
        if ($seenRelativePaths.Add($relative)) {
            $files.Add([pscustomobject]@{
                    absolute_path = $file.FullName
                    relative_path = $relative
                }) | Out-Null
        }
    }
}

$pathIndex = @{}
$basenameIndex = @{}
foreach ($file in $files) {
    $pathIndex[$file.relative_path] = $file.absolute_path
    $basename = [System.IO.Path]::GetFileName($file.relative_path)
    if (-not $basenameIndex.ContainsKey($basename)) {
        $basenameIndex[$basename] = New-Object System.Collections.Generic.List[object]
    }
    $basenameIndex[$basename].Add($file.relative_path) | Out-Null
}

$referenceMap = New-ReferenceMap
$strongReferenceSet = New-StringSet

foreach ($relative in @(
    "Start_Mason2.ps1",
    "Stop_Stack.ps1",
    "Start-Athena.ps1",
    "Start_FullStack_OneClick.ps1",
    "tools\launch\Start_FullStack_OneClick.ps1",
    "tools\ops\Stack_Reset_And_Start.ps1",
    "tools\ops\Validate_Whole_System.ps1",
    "MasonConsole\server.py",
    "MasonConsole\static\athena\index.html",
    "Component - Onyx App\onyx_business_manager\Start-Onyx5353.ps1",
    "config\component_registry.json",
    "config\tool_registry.json",
    "config\ports.json",
    "config\tiers.json",
    "config\addons.json",
    "config\billing_provider.json",
    "config\rbac_policy.json",
    "config\data_governance_policy.json",
    "tools\platform\ToolRunner.ps1",
    "tools\knowledge\Mason_Generate_ContextPack.ps1",
    "tools\ingest\Mason_Memory_Ingest.ps1",
    "tools\knowledge\Mason_Memory_Retrieve.ps1"
)) {
    if ($pathIndex.ContainsKey($relative)) {
        Add-ReferenceEvidence -ReferenceMap $referenceMap -RelativePath $relative -Evidence "core_flow_anchor"
        Add-SetItem -Set $strongReferenceSet -Value $relative
    }
}

$componentInventory = Read-JsonSafe -Path $componentInventoryPath -Default @{}
if ($componentInventory -and $componentInventory.components) {
    foreach ($component in @($componentInventory.components)) {
        foreach ($keyFile in @($component.key_files)) {
            $pathValue = Normalize-Text $keyFile.path
            if (-not $pathValue) {
                continue
            }
            if ([System.IO.Path]::IsPathRooted($pathValue)) {
                if ($pathValue.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $pathValue = $pathValue.Substring($repoRoot.Length).TrimStart([char[]]@([char]'\'))
                }
                else {
                    continue
                }
            }
            if ($pathIndex.ContainsKey($pathValue)) {
                Add-ReferenceEvidence -ReferenceMap $referenceMap -RelativePath $pathValue -Evidence ("component_inventory:" + (Normalize-Text $component.component_id))
                Add-SetItem -Set $strongReferenceSet -Value $pathValue
            }
        }
    }
}

$startRun = Read-JsonSafe -Path $startRunPath -Default @{}
if ($startRun -and $startRun.launch_results) {
    foreach ($launch in @($startRun.launch_results)) {
        $scriptPath = Normalize-Text $launch.script
        if (-not $scriptPath) {
            continue
        }
        if ($scriptPath.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relative = $scriptPath.Substring($repoRoot.Length).TrimStart([char[]]@([char]'\'))
            if ($pathIndex.ContainsKey($relative)) {
                Add-ReferenceEvidence -ReferenceMap $referenceMap -RelativePath $relative -Evidence ("start_run:" + (Normalize-Text $launch.component))
                Add-SetItem -Set $strongReferenceSet -Value $relative
            }
        }
    }
}

$validator = Read-JsonSafe -Path $validatorPath -Default @{}
foreach ($pathValue in @($validator.relevant_paths)) {
    $text = Normalize-Text $pathValue
    if (-not $text) {
        continue
    }
    if ($text.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $text.Substring($repoRoot.Length).TrimStart([char[]]@([char]'\'))
        if ($pathIndex.ContainsKey($relative)) {
            Add-ReferenceEvidence -ReferenceMap $referenceMap -RelativePath $relative -Evidence "system_validation"
            Add-SetItem -Set $strongReferenceSet -Value $relative
        }
    }
}

$seedFiles = @(
    "Start_Mason2.ps1",
    "Stop_Stack.ps1",
    "Start-Athena.ps1",
    "Start_FullStack_OneClick.ps1",
    "tools\launch\Start_FullStack_OneClick.ps1",
    "tools\ops\Stack_Reset_And_Start.ps1",
    "tools\ops\Validate_Whole_System.ps1",
    "MasonConsole\server.py",
    "MasonConsole\static\athena\index.html",
    "Component - Onyx App\onyx_business_manager\Start-Onyx5353.ps1",
    "config\component_registry.json",
    "config\tool_registry.json"
)

foreach ($seedRelative in $seedFiles) {
    if (-not $pathIndex.ContainsKey($seedRelative)) {
        continue
    }
    $absolute = [string]$pathIndex[$seedRelative]
    try {
        $content = Get-Content -LiteralPath $absolute -Raw -Encoding UTF8 -ErrorAction Stop
        Add-ReferencedPathsFromText -RepoRoot $repoRoot -SeedRelativePath $seedRelative -Text $content -PathIndex $pathIndex -BasenameIndex $basenameIndex -ReferenceMap $referenceMap
    }
    catch {
        continue
    }
}

$records = [System.Collections.ArrayList]::new()
foreach ($item in $files | Sort-Object relative_path) {
    $absolutePath = [string]$item.absolute_path
    $relativePath = [string]$item.relative_path
    $fileInfo = Get-Item -LiteralPath $absolutePath -Force
    $extension = [System.IO.Path]::GetExtension($relativePath).ToLowerInvariant()
    $directory = Split-Path -Parent $relativePath
    $referenceEvidence = if ($referenceMap.ContainsKey($relativePath)) { @($referenceMap[$relativePath]) } else { @() }
    $secretLike = Test-SecretLikePath -RelativePath $relativePath
    $archiveSignal = Test-ArchiveLikePath -RelativePath $relativePath
    $strongActive = $strongReferenceSet.Contains($relativePath)
    $recentlyTouched = ($fileInfo.LastWriteTimeUtc -ge (Get-Date).ToUniversalTime().AddDays(-21))
    $inStartFlow = @($referenceEvidence | Where-Object { $_ -like "start_run:*" }).Count -gt 0
    $inComponentInventory = @($referenceEvidence | Where-Object { $_ -like "component_inventory:*" }).Count -gt 0
    $vendoredDependency = Test-VendoredDependencyPath -RelativePath $relativePath

    try {
        $buildStage = "hash"
        $hashInfo = Get-HashInfo -Path $absolutePath -MaxBytes $HashMaxBytes -SkipForSecrets $secretLike
        $buildStage = "content"
        $contentInfo = Get-ContentPreviewInfo -Path $absolutePath -Extension $extension -MaxBytes $ContentReadMaxBytes -SkipForSecrets $secretLike -InspectableExtensions $inspectableExtensions
        $buildStage = "parse"
        $parseInfo = Get-ParseState -Path $absolutePath -Extension $extension -MaxBytes $ContentReadMaxBytes -SkipForSecrets $secretLike
        $buildStage = "danger_flags"
        $dangerousByName = Test-DangerousName -RelativePath $relativePath
        $dangerousByContent = (($extension -in @(".ps1", ".psm1", ".psd1", ".bat", ".cmd", ".py")) -and (Test-ContentDangerous -PreviewText ([string]$contentInfo.preview)))
        $contentMarkers = To-Array $contentInfo.content_markers
        $buildStage = "candidate_signals"
        $candidateSignals = New-Object System.Collections.Generic.List[object]
        if ((-not $vendoredDependency) -and $contentMarkers.Count -gt 0) {
            $candidateSignals.Add(("content_markers:" + ([string]::Join(",", $contentMarkers)))) | Out-Null
        }
        if ((-not $vendoredDependency) -and ($relativePath -match '(?i)(draft|prototype|experiment|spec|plan|todo|wip)')) {
            $candidateSignals.Add("name_signal:unfinished_variant") | Out-Null
        }

        $buildStage = "record_object"
        $referenceEvidenceArray = To-Array $referenceEvidence
        $contentMarkersArray = To-Array $contentMarkers
        $parseErrorsArray = To-Array $parseInfo.parse_errors
        $candidateSignalsArray = To-Array $candidateSignals
        $recordBag = [ordered]@{}
        $recordBag["record_type"] = "file"
        $recordBag["relative_path"] = $relativePath
        $recordBag["absolute_path"] = $absolutePath
        $recordBag["directory"] = if ($directory) { $directory } else { "." }
        $recordBag["name"] = [System.IO.Path]::GetFileName($relativePath)
        $recordBag["extension"] = $extension
        $recordBag["size_bytes"] = [int64]$fileInfo.Length
        $recordBag["last_write_utc"] = Convert-ToUtcIso $fileInfo.LastWriteTimeUtc
        $recordBag["domain"] = Get-TopLevelDomain -RelativePath $relativePath
        $recordBag["secret_like"] = [bool]$secretLike
        $recordBag["archive_signal"] = [bool]$archiveSignal
        $recordBag["dangerous_signal"] = [bool]($dangerousByName -or $dangerousByContent)
        $recordBag["dangerous_name"] = [bool]$dangerousByName
        $recordBag["dangerous_content"] = [bool]$dangerousByContent
        $recordBag["strong_active"] = [bool]$strongActive
        $recordBag["in_start_flow"] = [bool]$inStartFlow
        $recordBag["in_component_inventory"] = [bool]$inComponentInventory
        $recordBag["recently_touched"] = [bool]$recentlyTouched
        $recordBag["reference_count"] = $referenceEvidenceArray.Count
        $recordBag["reference_evidence"] = $referenceEvidenceArray
        $recordBag["hash_sha256"] = [string]$hashInfo.hash_sha256
        $recordBag["hash_status"] = [string]$hashInfo.hash_status
        $recordBag["hash_reason"] = [string]$hashInfo.hash_reason
        $recordBag["family_key"] = Get-FamilyKey -RelativePath $relativePath -Extension $extension
        $recordBag["content_status"] = [string]$contentInfo.content_status
        $recordBag["content_reason"] = [string]$contentInfo.content_reason
        $recordBag["content_markers"] = $contentMarkersArray
        $recordBag["parse_checked"] = [bool]$parseInfo.parse_checked
        $recordBag["parse_ok"] = $parseInfo.parse_ok
        $recordBag["parse_errors"] = $parseErrorsArray
        $recordBag["parse_reason"] = [string]$parseInfo.parse_reason
        $recordBag["candidate_signals"] = $candidateSignalsArray
        $recordBag["build_error"] = ""
        [void]$records.Add((Convert-MapToPsObject -Map $recordBag))
        $buildStage = "record_complete"
    }
    catch {
        $referenceEvidenceArray = To-Array $referenceEvidence
        $recordBag = [ordered]@{}
        $recordBag["record_type"] = "file"
        $recordBag["relative_path"] = $relativePath
        $recordBag["absolute_path"] = $absolutePath
        $recordBag["directory"] = if ($directory) { $directory } else { "." }
        $recordBag["name"] = [System.IO.Path]::GetFileName($relativePath)
        $recordBag["extension"] = $extension
        $recordBag["size_bytes"] = [int64]$fileInfo.Length
        $recordBag["last_write_utc"] = Convert-ToUtcIso $fileInfo.LastWriteTimeUtc
        $recordBag["domain"] = Get-TopLevelDomain -RelativePath $relativePath
        $recordBag["secret_like"] = [bool]$secretLike
        $recordBag["archive_signal"] = [bool]$archiveSignal
        $recordBag["dangerous_signal"] = $false
        $recordBag["dangerous_name"] = $false
        $recordBag["dangerous_content"] = $false
        $recordBag["strong_active"] = [bool]$strongActive
        $recordBag["in_start_flow"] = [bool]$inStartFlow
        $recordBag["in_component_inventory"] = [bool]$inComponentInventory
        $recordBag["recently_touched"] = [bool]$recentlyTouched
        $recordBag["reference_count"] = $referenceEvidenceArray.Count
        $recordBag["reference_evidence"] = $referenceEvidenceArray
        $recordBag["hash_sha256"] = ""
        $recordBag["hash_status"] = "error"
        $recordBag["hash_reason"] = ($buildStage + ": " + $_.Exception.Message)
        $recordBag["family_key"] = Get-FamilyKey -RelativePath $relativePath -Extension $extension
        $recordBag["content_status"] = "error"
        $recordBag["content_reason"] = ($buildStage + ": " + $_.Exception.Message)
        $recordBag["content_markers"] = @()
        $recordBag["parse_checked"] = $true
        $recordBag["parse_ok"] = $false
        $recordBag["parse_errors"] = @($buildStage + ": " + $_.Exception.Message)
        $recordBag["parse_reason"] = "record_build_error"
        $recordBag["candidate_signals"] = @("record_build_error")
        $recordBag["build_error"] = ($buildStage + ": " + $_.Exception.Message)
        [void]$records.Add((Convert-MapToPsObject -Map $recordBag))
    }
}

$exactDuplicateClusters = New-Object System.Collections.Generic.List[object]
foreach ($group in ($records | Where-Object { $_.hash_status -eq "ok" -and $_.hash_sha256 } | Group-Object hash_sha256 | Where-Object { $_.Count -gt 1 })) {
    $canonical = Get-CanonicalRecordFromCluster -Records $group.Group
    $exactDuplicateClusters.Add([pscustomobject]@{
            cluster_id      = "dup_" + $group.Name.Substring(0, [Math]::Min(12, $group.Name.Length))
            hash_sha256     = $group.Name
            canonical_path  = $canonical
            duplicate_paths = @($group.Group | Where-Object { $_.relative_path -ne $canonical } | ForEach-Object { $_.relative_path } | Sort-Object)
            count           = $group.Count
        }) | Out-Null
}

$duplicateByPath = @{}
foreach ($cluster in $exactDuplicateClusters) {
    foreach ($dupPath in @($cluster.duplicate_paths)) {
        $duplicateByPath[$dupPath] = $cluster.canonical_path
    }
}

$nearDuplicateClusters = New-Object System.Collections.Generic.List[object]
foreach ($group in ($records | Group-Object family_key | Where-Object { $_.Count -gt 1 })) {
    $hashCount = @($group.Group | Where-Object { $_.hash_sha256 } | Select-Object -ExpandProperty hash_sha256 -Unique).Count
    $canonical = Get-CanonicalRecordFromCluster -Records $group.Group
    $nearDuplicateClusters.Add([pscustomobject]@{
            family_key     = $group.Name
            canonical_path = $canonical
            paths          = @($group.Group | ForEach-Object { $_.relative_path } | Sort-Object)
            count          = $group.Count
            mixed_content  = [bool]($hashCount -gt 1)
        }) | Out-Null
}

$nearDuplicateByPath = @{}
foreach ($cluster in $nearDuplicateClusters) {
    foreach ($clusterPath in @($cluster.paths)) {
        if (-not $nearDuplicateByPath.ContainsKey($clusterPath)) {
            $nearDuplicateByPath[$clusterPath] = $cluster.canonical_path
        }
    }
}

$classifiedRecords = [System.Collections.ArrayList]::new()
foreach ($record in $records) {
    try {
        $classification = "unknown"
        $classificationEvidence = @()

        if ($duplicateByPath.ContainsKey($record.relative_path)) {
            $classification = "duplicate"
            $classificationEvidence += @("exact_duplicate_of:" + $duplicateByPath[$record.relative_path])
        }
        elseif ($record.parse_checked -and $record.parse_ok -eq $false) {
            $classification = "broken"
            $classificationEvidence += @("parse_error:" + ([string]::Join(" | ", (To-Array $record.parse_errors))))
        }
        elseif ($record.archive_signal -and -not $record.strong_active) {
            $classification = "archive"
            $classificationEvidence += @("archive_path_signal")
        }
        elseif ($record.strong_active -or $record.in_start_flow -or $record.in_component_inventory) {
            $classification = "active"
            $classificationEvidence += @($record.reference_evidence)
        }
        elseif ($record.dangerous_signal) {
            $classification = "dangerous"
            if ($record.dangerous_name) { $classificationEvidence += @("dangerous_name_signal") }
            if ($record.dangerous_content) { $classificationEvidence += @("dangerous_content_signal") }
        }
        elseif ((To-Array $record.candidate_signals).Count -gt 0) {
            $classification = "candidate"
            $classificationEvidence += To-Array $record.candidate_signals
        }
        elseif ($record.archive_signal) {
            $classification = "archive"
            $classificationEvidence += @("archive_path_signal")
        }
        else {
            $classification = "unknown"
            if ($record.reference_count -eq 0) {
                $classificationEvidence += @("no_explicit_reference_found")
            }
            if (-not $record.recently_touched) {
                $classificationEvidence += @("stale_last_write_signal")
            }
        }

        if ($nearDuplicateByPath.ContainsKey($record.relative_path) -and $classification -in @("candidate", "unknown")) {
            $classificationEvidence += @("near_duplicate_family:" + $nearDuplicateByPath[$record.relative_path])
        }

        $recordBag = [ordered]@{}
        foreach ($property in $record.PSObject.Properties) {
            $recordBag[$property.Name] = $property.Value
        }
        $recordBag["classification"] = $classification
        $recordBag["classification_evidence"] = To-Array $classificationEvidence
        $recordBag["duplicate_of"] = if ($duplicateByPath.ContainsKey($record.relative_path)) { $duplicateByPath[$record.relative_path] } else { "" }
        [void]$classifiedRecords.Add((Convert-MapToPsObject -Map $recordBag))
    }
    catch {
        $recordBag = [ordered]@{}
        foreach ($property in $record.PSObject.Properties) {
            $recordBag[$property.Name] = $property.Value
        }
        $recordBag["classification"] = "broken"
        $recordBag["classification_evidence"] = @("classification_error:" + $_.Exception.Message)
        $recordBag["duplicate_of"] = ""
        [void]$classifiedRecords.Add((Convert-MapToPsObject -Map $recordBag))
    }
}
$records = $classifiedRecords

$classificationCounts = [ordered]@{
    active    = 0
    candidate = 0
    archive   = 0
    duplicate = 0
    broken    = 0
    unknown   = 0
    dangerous = 0
}

foreach ($record in $records) {
    $classificationCounts[$record.classification] = [int]$classificationCounts[$record.classification] + 1
}

$salvageQueue = New-Object System.Collections.Generic.List[object]
foreach ($record in ($records | Sort-Object classification, relative_path)) {
    $ageDays = [int]([datetime]::UtcNow - ([datetime]$record.last_write_utc)).TotalDays
    $queueType = ""
    $recommendedAction = ""
    $riskLevel = "R1"
    $include = $false

    switch ($record.classification) {
        "candidate" {
            $queueType = "salvage and wire"
            $recommendedAction = "Review wiring and either connect this file into a governed flow or archive it after diff review."
            $riskLevel = "R2"
            $include = $true
        }
        "archive" {
            if ($record.relative_path -match '(?i)(\.bak|backup|copy|legacy|old|zip|Mason2-code-export|Mason2-code-slice)') {
                $queueType = "archive candidate"
                $recommendedAction = "Confirm the canonical replacement, then move this backup/archive candidate behind a single documented archive boundary."
                $riskLevel = "R1"
                $include = $true
            }
        }
        "duplicate" {
            $queueType = "duplicate review"
            $recommendedAction = "Diff this duplicate against the canonical file before any archive or move decision."
            $riskLevel = "R1"
            $include = $true
        }
        "dangerous" {
            $queueType = "dangerous review"
            $recommendedAction = "Review guardrails and invocation paths before this script is used again."
            $riskLevel = "R3"
            $include = $true
        }
        "broken" {
            $queueType = "salvage and wire"
            $recommendedAction = "Repair the parse structure or explicitly retire this broken file."
            $riskLevel = "R2"
            $include = $true
        }
        "unknown" {
            if ($record.reference_count -eq 0 -and $ageDays -ge $UnknownReviewAgeDays) {
                $queueType = "unknown/manual review"
                $recommendedAction = "Manually confirm whether this unreferenced file has ongoing value before archiving."
                $riskLevel = "R1"
                $include = $true
            }
            elseif ($record.reference_count -eq 0 -and $record.directory -eq ".") {
                $queueType = "orphan check"
                $recommendedAction = "Check whether this top-level orphan still belongs in the root or should be archived or documented."
                $riskLevel = "R2"
                $include = $true
            }
        }
    }

    if (-not $include) {
        continue
    }

    $salvageQueue.Add([pscustomobject]@{
            item_id                    = New-SalvageItemId -Path $record.relative_path -Action $queueType
            path                       = $record.relative_path
            current_classification     = $record.classification
            queue_type                 = $queueType
            reason                     = if ((To-Array $record.classification_evidence).Count -gt 0) { [string]$record.classification_evidence[0] } else { $record.classification }
            evidence                   = To-Array ($record.classification_evidence + $record.reference_evidence)
            recommended_action         = $recommendedAction
            risk_level                 = $riskLevel
            linked_component_or_domain = $record.domain
        }) | Out-Null
}

foreach ($module in $moduleRecords) {
    if ($module.classification -eq "archive" -or $module.classification -eq "unknown") {
        $queueType = if ($module.classification -eq "archive") { "archive candidate" } else { "unknown/manual review" }
        $salvageQueue.Add([pscustomobject]@{
                item_id                    = New-SalvageItemId -Path $module.relative_path -Action $queueType
                path                       = $module.relative_path
                current_classification     = $module.classification
                queue_type                 = $queueType
                reason                     = $module.reason
                evidence                   = To-Array $module.reason
                recommended_action         = if ($module.classification -eq "archive") { "Keep this module outside the live baseline and only salvage specific assets after manual review." } else { "Determine whether this module should be scanned recursively in a later cleanup pass or archived as historical material." }
                risk_level                 = if ($module.classification -eq "archive") { "R1" } else { "R2" }
                linked_component_or_domain = $module.domain
            }) | Out-Null
    }
}

$topDuplicateClusters = @($exactDuplicateClusters | Sort-Object @{ Expression = "count"; Descending = $true }, canonical_path | Select-Object -First 12)
$topUnknownClusters = Get-GroupedDirectorySummary -Records @($records | Where-Object { $_.classification -eq "unknown" }) -MaxItems 12
$topDangerousCandidates = @($records | Where-Object { $_.classification -eq "dangerous" } | Sort-Object relative_path | Select-Object -First 12)
$topLikelySalvageCandidates = @(
    $records |
    Where-Object { $_.classification -in @("candidate", "broken") -and -not (Test-VendoredDependencyPath -RelativePath $_.relative_path) } |
    Sort-Object -Property @(
        @{
            Expression = {
                $score = 0
                if ($_.reference_count -gt 0) { $score += 100 }
                if ($_.strong_active) { $score += 50 }
                if ($_.in_start_flow) { $score += 40 }
                if ($_.in_component_inventory) { $score += 30 }
                if ($_.classification -eq "candidate") { $score += 20 }
                if ($_.relative_path -match '(?i)(draft|prototype|experiment|spec|plan|todo|wip|legacy|backup|copy|old)') { $score += 10 }
                $score
            }
            Descending = $true
        },
        @{
            Expression = "reference_count"
            Descending = $true
        },
        @{
            Expression = "relative_path"
            Descending = $false
        }
    ) |
    Select-Object -First 12
)

$recordCount = [int]$records.Count
$moduleCount = [int]$moduleRecords.Count
$exactDuplicateClusterCount = [int]$exactDuplicateClusters.Count
$nearDuplicateClusterCount = [int]$nearDuplicateClusters.Count
$referencedFileCount = @($records | Where-Object { $_.reference_count -gt 0 }).Count
$unreferencedFileCount = @($records | Where-Object { $_.reference_count -eq 0 }).Count
$parseBrokenFileCount = @($records | Where-Object { $_.classification -eq "broken" }).Count
$dangerousReviewCount = @($records | Where-Object { $_.classification -eq "dangerous" }).Count
$secretLikeFileCount = @($records | Where-Object { $_.secret_like }).Count
$salvageQueueCount = [int]$salvageQueue.Count

$inventorySummary = [ordered]@{
    total_scanned                 = $recordCount + $moduleCount
    file_count                    = $recordCount
    module_count                  = $moduleCount
    classification_counts         = $classificationCounts
    exact_duplicate_cluster_count = $exactDuplicateClusterCount
    near_duplicate_cluster_count  = $nearDuplicateClusterCount
    referenced_file_count         = $referencedFileCount
    unreferenced_file_count       = $unreferencedFileCount
    parse_broken_file_count       = $parseBrokenFileCount
    dangerous_review_count        = $dangerousReviewCount
    secret_like_file_count        = $secretLikeFileCount
    salvage_queue_count           = $salvageQueueCount
}

$sortedRecursiveRoots = To-Array $recursiveRootMap.Keys
$sortedModuleOnlyRoots = To-Array $moduleOnlyRootMap.Keys
$sortedExcludedDirectoryNames = To-Array $excludedDirectoryNames
$sortedModules = @($moduleRecords.ToArray() | Sort-Object relative_path)
$sortedDuplicateClusters = @($exactDuplicateClusters.ToArray())
$sortedNearDuplicateClusters = @($nearDuplicateClusters.ToArray() | Sort-Object @{ Expression = "count"; Descending = $true }, canonical_path)
$sortedRecords = @($records.ToArray() | Sort-Object relative_path)

$inventoryArtifact = [ordered]@{
    timestamp_utc          = (Get-Date).ToUniversalTime().ToString("o")
    root_path              = $repoRoot
    baseline_status        = Normalize-Text $validator.overall_status
    baseline_artifact_path = $validatorPath
    reports_policy         = "reports/** used as metadata/reference only"
    scan_scope             = [ordered]@{
        recursive_roots                  = $sortedRecursiveRoots
        module_only_roots                = $sortedModuleOnlyRoots
        excluded_nested_directory_names  = $sortedExcludedDirectoryNames
    }
    sources                = [ordered]@{
        component_inventory = $componentInventoryPath
        start_run_last      = $startRunPath
        system_validation   = $validatorPath
        component_registry  = $componentRegistryPath
        tool_registry       = $toolRegistryPath
    }
    summary                = $inventorySummary
    modules                = $sortedModules
    duplicate_clusters     = $sortedDuplicateClusters
    near_duplicate_clusters = $sortedNearDuplicateClusters
    files                  = $sortedRecords
}

$cleanupPlanArtifact = [ordered]@{
    timestamp_utc                 = (Get-Date).ToUniversalTime().ToString("o")
    root_path                     = $repoRoot
    baseline_status               = Normalize-Text $validator.overall_status
    summary                       = $inventorySummary
    top_duplicate_clusters        = @($topDuplicateClusters)
    top_unknown_clusters          = @($topUnknownClusters)
    top_dangerous_candidates      = @($topDangerousCandidates | ForEach-Object {
            [pscustomobject]@{
                path            = $_.relative_path
                evidence        = To-Array $_.classification_evidence
                reference_count = $_.reference_count
                domain          = $_.domain
            }
        })
    top_likely_salvage_candidates = @($topLikelySalvageCandidates | ForEach-Object {
            [pscustomobject]@{
                path            = $_.relative_path
                classification  = $_.classification
                evidence        = To-Array $_.classification_evidence
                reference_count = $_.reference_count
                domain          = $_.domain
            }
        })
    suggested_safe_next_actions   = @(
        "Review exact-duplicate clusters and choose one canonical file before archiving any siblings.",
        "Review dangerous scripts for guardrails and remove them from casual launch paths before any cleanup.",
        "Diff candidate and broken files with their nearest canonical family before deciding whether to wire or archive them.",
        "Keep reports, logs, and secret-like files metadata-only during cleanup planning.",
        "Do not delete anything until the duplicate, dangerous, and unknown/manual review items are resolved."
    )
}

$salvageQueueArtifact = [ordered]@{
    timestamp_utc   = (Get-Date).ToUniversalTime().ToString("o")
    root_path       = $repoRoot
    baseline_status = Normalize-Text $validator.overall_status
    total_items     = [int]$salvageQueue.Count
    items           = @($salvageQueue.ToArray() | Sort-Object queue_type, path)
}

Write-JsonFile -Path $inventoryPath -Object $inventoryArtifact -Depth 24
Write-JsonFile -Path $salvageQueuePath -Object $salvageQueueArtifact -Depth 20
Write-JsonFile -Path $cleanupPlanPath -Object $cleanupPlanArtifact -Depth 20

Write-Output ("Codebase salvage inventory written to {0}" -f $inventoryPath)
Write-Output ("Codebase salvage queue written to {0}" -f $salvageQueuePath)
Write-Output ("Codebase cleanup plan written to {0}" -f $cleanupPlanPath)
