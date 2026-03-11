[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$MirrorPath = "C:\Mason2_MIRROR",
    [string]$Reason = "manual",
    [switch]$AutoGenerateSecretGateTemplate = $true,
    [switch]$DisableSecretGateAutogen
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

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 10
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value ($Object | ConvertTo-Json -Depth $Depth) -Encoding UTF8
}

function Add-JsonLine {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Add-Content -LiteralPath $Path -Value ($Object | ConvertTo-Json -Compress -Depth 10) -Encoding UTF8
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

function Invoke-GitCapture {
    param(
        [Parameter(Mandatory = $true)][string]$RepoPath,
        [Parameter(Mandatory = $true)][string[]]$Args
    )
    try {
        $output = & git -C $RepoPath @Args 2>&1
        $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
        return [pscustomobject]@{
            ok      = ($exitCode -eq 0)
            exit    = $exitCode
            lines   = @($output | ForEach-Object { [string]$_ })
            joined  = ((@($output) -join "`n").Trim())
        }
    }
    catch {
        return [pscustomobject]@{
            ok      = $false
            exit    = 1
            lines   = @($_.Exception.Message)
            joined  = [string]$_.Exception.Message
        }
    }
}

function Get-MirrorDeltaSummary {
    param(
        [Parameter(Mandatory = $true)][string]$MirrorRoot,
        [string]$HeadBefore = "",
        [string]$HeadAfter = ""
    )

    $added = 0
    $modified = 0
    $removed = 0
    $topChanged = New-Object System.Collections.Generic.List[string]

    if ($HeadAfter -and $HeadBefore -and $HeadAfter -ne $HeadBefore) {
        $show = Invoke-GitCapture -RepoPath $MirrorRoot -Args @("show", "--name-status", "--pretty=", $HeadAfter)
        if ($show.ok) {
            foreach ($line in $show.lines) {
                $trim = ([string]$line).Trim()
                if (-not $trim) { continue }
                $parts = $trim -split "\s+", 2
                if ($parts.Count -lt 2) { continue }
                $status = $parts[0].ToUpperInvariant()
                $path = $parts[1]
                if ($topChanged.Count -lt 20) {
                    $topChanged.Add($path) | Out-Null
                }
                if ($status.StartsWith("A")) { $added++ ; continue }
                if ($status.StartsWith("D")) { $removed++ ; continue }
                if ($status.StartsWith("M") -or $status.StartsWith("R") -or $status.StartsWith("C")) { $modified++ ; continue }
            }
        }
    }
    else {
        $status = Invoke-GitCapture -RepoPath $MirrorRoot -Args @("status", "--porcelain")
        if ($status.ok) {
            foreach ($line in $status.lines) {
                $trim = ([string]$line)
                if (-not $trim.Trim()) { continue }
                $code = $trim.Substring(0, [Math]::Min(2, $trim.Length)).Trim()
                $path = $trim.Substring([Math]::Min(3, $trim.Length)).Trim()
                if ($topChanged.Count -lt 20 -and $path) {
                    $topChanged.Add($path) | Out-Null
                }
                if ($code -eq "??") { $added++ ; continue }
                if ($code.Contains("A")) { $added++ ; continue }
                if ($code.Contains("D")) { $removed++ ; continue }
                $modified++
            }
        }
    }

    return [ordered]@{
        generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        mirror_root      = $MirrorRoot
        changed_count    = [int]($added + $modified + $removed)
        added_count      = [int]$added
        modified_count   = [int]$modified
        removed_count    = [int]$removed
        top_changed_paths = @($topChanged.ToArray())
        head_before      = $HeadBefore
        head_after       = $HeadAfter
    }
}

function Normalize-Reason {
    param([string]$Value)

    $reason = ([string]$Value).Trim().ToLowerInvariant()
    if (-not $reason) {
        return "manual"
    }

    switch ($reason) {
        "postingest" { $reason = "post-ingest"; break }
        "postapply" { $reason = "post-apply"; break }
        default { }
    }

    $reason = [regex]::Replace($reason, "[^a-z0-9._-]+", "-")
    $reason = [regex]::Replace($reason, "-{2,}", "-").Trim("-", "_", ".")
    if (-not $reason) {
        return "manual"
    }

    if ($reason.Length -gt 64) {
        $reason = $reason.Substring(0, 64).TrimEnd("-", "_", ".")
        if (-not $reason) {
            return "manual"
        }
    }

    return $reason
}

function Get-MissingAllowlistNames {
    param($Manifest)

    if (-not $Manifest) {
        return @()
    }
    if (-not ($Manifest.PSObject.Properties.Name -contains "missing_from_mirror") -or -not $Manifest.missing_from_mirror) {
        return @()
    }

    $missing = $Manifest.missing_from_mirror
    if (-not ($missing.PSObject.Properties.Name -contains "allowlist_names_absent_in_mirror")) {
        return @()
    }

    return @($missing.allowlist_names_absent_in_mirror | ForEach-Object { [string]$_ } | Where-Object { $_ } | Sort-Object -Unique)
}

function New-MirrorAllowlistedDirectories {
    param(
        [Parameter(Mandatory = $true)][string]$MirrorRoot,
        [Parameter(Mandatory = $true)][string[]]$Names
    )

    $created = New-Object System.Collections.Generic.List[string]
    foreach ($name in @($Names | Sort-Object -Unique)) {
        if (-not $name) { continue }
        if ($name.Contains("..") -or $name.Contains("\") -or $name.Contains("/") -or $name.Contains(":")) {
            continue
        }

        $dirPath = Join-Path $MirrorRoot $name
        if (-not (Test-Path -LiteralPath $dirPath)) {
            New-Item -ItemType Directory -Path $dirPath -Force | Out-Null
            $created.Add($name) | Out-Null
        }
        $gitkeepPath = Join-Path $dirPath ".gitkeep"
        if (-not (Test-Path -LiteralPath $gitkeepPath)) {
            Set-Content -LiteralPath $gitkeepPath -Value "" -Encoding UTF8
        }
    }

    return @($created.ToArray())
}

function Write-SecretGateTemplate {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $template = @'
[CmdletBinding()]
param(
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not $RootPath) {
    $RootPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
if (-not (Test-Path -LiteralPath $RootPath)) {
    Write-Host "[MIRROR_SecretGate] RootPath missing: $RootPath"
    exit 1
}

$filenameViolations = New-Object System.Collections.Generic.List[string]
$contentViolations = New-Object System.Collections.Generic.List[string]
$textExtensions = @(".ps1", ".py", ".json", ".yaml", ".yml", ".toml", ".ini", ".cfg", ".env", ".txt", ".md", ".js", ".ts", ".tsx", ".jsx", ".csv")
$contentPatterns = @(
    '(?i)ghp_[a-z0-9]{20,}',
    '(?i)sk-[a-z0-9]{20,}',
    '(?i)(api[_-]?key|access[_-]?token|secret|password)\s*[:=]\s*["'']?[a-z0-9_/\-+=]{10,}'
)

$files = Get-ChildItem -LiteralPath $RootPath -Recurse -File -ErrorAction SilentlyContinue
foreach ($file in @($files)) {
    $full = [string]$file.FullName
    $rel = $full
    if ($full.StartsWith($RootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        $rel = $full.Substring($RootPath.Length).TrimStart("\", "/")
    }
    $name = [string]$file.Name
    $nameLower = $name.ToLowerInvariant()

    if ($nameLower -like ".env*" -or $nameLower -like "secrets*.json") {
        $filenameViolations.Add($rel) | Out-Null
        continue
    }

    $ext = ([System.IO.Path]::GetExtension($name)).ToLowerInvariant()
    if (-not ($textExtensions -contains $ext)) {
        continue
    }
    if ($file.Length -gt 2097152) {
        continue
    }

    $raw = $null
    try {
        $raw = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        continue
    }
    if (-not $raw) {
        continue
    }

    foreach ($pattern in $contentPatterns) {
        if ([regex]::IsMatch($raw, $pattern)) {
            $contentViolations.Add($rel) | Out-Null
            break
        }
    }
}

$violations = @($filenameViolations.ToArray() + $contentViolations.ToArray() | Sort-Object -Unique)
if ($violations.Count -gt 0) {
    Write-Host ("[MIRROR_SecretGate] blocked potential secrets in {0} file(s)." -f $violations.Count)
    foreach ($item in @($violations | Select-Object -First 40)) {
        Write-Host (" - {0}" -f $item)
    }
    exit 1
}
exit 0
'@

    Set-Content -LiteralPath $Path -Value $template -Encoding UTF8
}

function Invoke-MirrorPushFallback {
    param(
        [Parameter(Mandatory = $true)][string]$MirrorRoot,
        [Parameter(Mandatory = $true)][string]$CommitMessage
    )

    $null = Invoke-GitCapture -RepoPath $MirrorRoot -Args @("config", "core.longpaths", "true")

    $status = Invoke-GitCapture -RepoPath $MirrorRoot -Args @("-c", "core.longpaths=true", "status", "--porcelain")
    if (-not $status.ok) {
        return [ordered]@{
            ok        = $false
            result    = "git_status_failed"
            exit_code = [int]$status.exit
            output    = @($status.lines | Select-Object -Last 20)
        }
    }

    $statusLines = @($status.lines | ForEach-Object { [string]$_ } | Where-Object { $_.Trim() })
    if (@($statusLines).Count -eq 0) {
        return [ordered]@{
            ok        = $true
            result    = "noop"
            exit_code = 0
            output    = @("nothing to commit")
        }
    }

    $add = $null
    foreach ($attempt in 1..2) {
        $add = Invoke-GitCapture -RepoPath $MirrorRoot -Args @("-c", "core.longpaths=true", "add", "--all", "--", ".")
        if ($add.ok) {
            break
        }
        Start-Sleep -Milliseconds 750
    }
    if (-not $add.ok) {
        return [ordered]@{
            ok        = $false
            result    = "git_add_failed"
            exit_code = [int]$add.exit
            output    = @($add.lines | Select-Object -Last 20)
        }
    }

    $commit = Invoke-GitCapture -RepoPath $MirrorRoot -Args @("commit", "-m", $CommitMessage)
    $commitOutput = @($commit.lines | ForEach-Object { [string]$_ })
    $commitJoined = ((@($commitOutput) -join "`n").ToLowerInvariant())
    if (-not $commit.ok -and $commitJoined -notmatch "nothing to commit") {
        return [ordered]@{
            ok        = $false
            result    = "git_commit_failed"
            exit_code = [int]$commit.exit
            output    = @($commitOutput | Select-Object -Last 20)
        }
    }

    $remote = Invoke-GitCapture -RepoPath $MirrorRoot -Args @("remote")
    if (-not $remote.ok) {
        return [ordered]@{
            ok        = $true
            result    = "local_commit_only_remote_probe_failed"
            exit_code = [int]$remote.exit
            output    = @($remote.lines | Select-Object -Last 20)
        }
    }

    $remoteNames = @($remote.lines | ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ })
    if (@($remoteNames).Count -eq 0) {
        return [ordered]@{
            ok        = $true
            result    = "local_commit_only"
            exit_code = 0
            output    = @($commitOutput | Select-Object -Last 20)
        }
    }

    $push = Invoke-GitCapture -RepoPath $MirrorRoot -Args @("push")
    if ($push.ok) {
        return [ordered]@{
            ok        = $true
            result    = "pushed"
            exit_code = [int]$push.exit
            output    = @($push.lines | Select-Object -Last 20)
        }
    }

    return [ordered]@{
        ok        = $true
        result    = "local_commit_only_remote_push_failed"
        exit_code = [int]$push.exit
        output    = @($push.lines | Select-Object -Last 20)
    }
}

function To-NormalizedPath {
    param([string]$Path)
    if (-not $Path) { return "" }
    return (($Path -replace "\\", "/").TrimStart("./")).ToLowerInvariant()
}

function Test-PathMatchesAnyPattern {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Patterns
    )

    $normalizedPath = To-NormalizedPath -Path $Path
    foreach ($pattern in @($Patterns)) {
        if (-not $pattern) { continue }
        $normalizedPattern = To-NormalizedPath -Path ([string]$pattern)
        if ($normalizedPath -like $normalizedPattern) {
            return $true
        }
    }
    return $false
}

function Remove-MirrorExcludedContent {
    param(
        [Parameter(Mandatory = $true)][string]$MirrorRoot
    )

    $removed = New-Object System.Collections.Generic.List[string]
    $failed = New-Object System.Collections.Generic.List[string]

    $reviewDirs = @(
        Get-ChildItem -LiteralPath $MirrorRoot -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ieq "reviews" } |
        Sort-Object FullName -Descending
    )
    foreach ($dir in $reviewDirs) {
        $removeResult = Remove-PathWithMirrorFallback -Path $dir.FullName
        if ($removeResult.ok) {
            $removed.Add([string]$dir.FullName) | Out-Null
        }
        else {
            $failed.Add(("{0} :: {1}" -f [string]$dir.FullName, [string]$removeResult.detail)) | Out-Null
        }
    }

    $excludedFiles = @(
        Get-ChildItem -LiteralPath $MirrorRoot -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            $name = ([string]$_.Name).ToLowerInvariant()
            $name -like ".env*" -or $name -like "secrets*.json"
        }
    )
    foreach ($file in $excludedFiles) {
        $removeResult = Remove-PathWithMirrorFallback -Path $file.FullName
        if ($removeResult.ok) {
            $removed.Add([string]$file.FullName) | Out-Null
        }
        else {
            $failed.Add(("{0} :: {1}" -f [string]$file.FullName, [string]$removeResult.detail)) | Out-Null
        }
    }

    return [ordered]@{
        removed_count = @($removed).Count
        failed_count  = @($failed).Count
        removed_items = @($removed | Select-Object -First 40)
        failed_items  = @($failed | Select-Object -First 40)
    }
}

function Remove-MirrorReportsOutsidePolicy {
    param(
        [Parameter(Mandatory = $true)][string]$MirrorRoot,
        $ReportsPolicy
    )

    $patterns = @()
    $maxBytes = 2097152
    if ($ReportsPolicy) {
        if ($ReportsPolicy.PSObject.Properties.Name -contains "allowlist_patterns" -and $ReportsPolicy.allowlist_patterns) {
            $patterns = @($ReportsPolicy.allowlist_patterns | ForEach-Object { [string]$_ } | Where-Object { $_ })
        }
        if ($ReportsPolicy.PSObject.Properties.Name -contains "max_file_bytes") {
            $tmp = 0
            if ([int]::TryParse([string]$ReportsPolicy.max_file_bytes, [ref]$tmp) -and $tmp -gt 0) {
                $maxBytes = [int]$tmp
            }
        }
    }
    if (@($patterns).Count -eq 0) {
        return [ordered]@{
            policy_applied = $false
            removed_count  = 0
            failed_count   = 0
            removed_items  = @()
            failed_items   = @()
        }
    }

    $reportsRoot = Join-Path $MirrorRoot "reports"
    if (-not (Test-Path -LiteralPath $reportsRoot)) {
        return [ordered]@{
            policy_applied = $true
            removed_count  = 0
            failed_count   = 0
            removed_items  = @()
            failed_items   = @()
        }
    }

    # Fail fast if reports root is not writable; avoid long per-file failure loops.
    $probeName = ".codex_write_probe_{0}.tmp" -f ([guid]::NewGuid().ToString("N"))
    $probePath = Join-Path $reportsRoot $probeName
    try {
        Set-Content -LiteralPath $probePath -Value "probe" -Encoding UTF8 -ErrorAction Stop
        Remove-Item -LiteralPath $probePath -Force -ErrorAction SilentlyContinue
    }
    catch {
        return [ordered]@{
            policy_applied = $true
            removed_count  = 0
            failed_count   = 1
            removed_items  = @()
            failed_items   = @("reports (write access denied)")
        }
    }

    $removed = New-Object System.Collections.Generic.List[string]
    $failed = New-Object System.Collections.Generic.List[string]
    $stopOnPermissionFailure = $false
    $files = @(Get-ChildItem -LiteralPath $reportsRoot -File -Recurse -ErrorAction SilentlyContinue)
    foreach ($file in $files) {
        if ($stopOnPermissionFailure) { break }
        $relative = [string]$file.FullName
        if ($relative.StartsWith($MirrorRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relative = $relative.Substring($MirrorRoot.Length).TrimStart("\", "/")
        }
        $isJson = ([System.IO.Path]::GetExtension([string]$file.Name)).ToLowerInvariant() -eq ".json"
        $isAllowedPattern = Test-PathMatchesAnyPattern -Path $relative -Patterns $patterns
        $isAllowedSize = ([int64]$file.Length -le [int64]$maxBytes)
        $keep = ($isJson -and $isAllowedPattern -and $isAllowedSize)
        if ($keep) { continue }

        try {
            $removeResult = Remove-PathWithMirrorFallback -Path $file.FullName
            if (-not $removeResult.ok) {
                throw $removeResult.detail
            }
            $removed.Add($relative) | Out-Null
        }
        catch {
            $failed.Add(("{0} :: {1}" -f $relative, [string]$_.Exception.Message)) | Out-Null
            $stopOnPermissionFailure = $true
        }
    }

    return [ordered]@{
        policy_applied = $true
        removed_count  = @($removed).Count
        failed_count   = @($failed).Count
        removed_items  = @($removed | Select-Object -First 40)
        failed_items   = @($failed | Select-Object -First 40)
    }
}

function Ensure-ParentDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Get-AllowlistTopology {
    param(
        [Parameter(Mandatory = $true)][string[]]$Allowlist
    )

    $topNames = New-Object System.Collections.Generic.List[string]
    $wholeTopNames = New-Object System.Collections.Generic.List[string]
    $childMap = [ordered]@{}

    foreach ($entry in $Allowlist) {
        $normalized = (([string]$entry).Trim() -replace "/", "\").Trim("\")
        if (-not $normalized) {
            continue
        }

        $parts = $normalized -split "[\\/]", 2
        $topName = [string]$parts[0]
        if (-not $topName) {
            continue
        }

        if ($topNames -notcontains $topName) {
            $topNames.Add($topName) | Out-Null
        }

        if ($parts.Count -eq 1) {
            if ($wholeTopNames -notcontains $topName) {
                $wholeTopNames.Add($topName) | Out-Null
            }
            continue
        }

        $childName = (($parts[1] -split "[\\/]", 2)[0]).Trim()
        if (-not $childName) {
            continue
        }

        if (-not $childMap.Contains($topName)) {
            $childMap[$topName] = New-Object System.Collections.Generic.List[string]
        }
        if ($childMap[$topName] -notcontains $childName) {
            $childMap[$topName].Add($childName) | Out-Null
        }
    }

    $normalizedChildMap = [ordered]@{}
    foreach ($key in $childMap.Keys) {
        $normalizedChildMap[$key] = @($childMap[$key] | Sort-Object -Unique)
    }

    return [ordered]@{
        top_level_names       = @($topNames | Sort-Object -Unique)
        whole_top_level_names = @($wholeTopNames | Sort-Object -Unique)
        child_map             = $normalizedChildMap
    }
}

function Invoke-RobocopyMirrorDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [Parameter(Mandatory = $true)][string]$DestinationDir,
        [string[]]$ExcludeDirectories = @(),
        [string[]]$ExcludeFiles = @()
    )

    if (-not (Test-Path -LiteralPath $DestinationDir)) {
        New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    }

    $args = @(
        $SourceDir,
        $DestinationDir,
        "/MIR",
        "/R:1",
        "/W:1",
        "/MT:16",
        "/XJ",
        "/FFT",
        "/NFL",
        "/NDL",
        "/NJH",
        "/NJS",
        "/NP"
    )

    if (@($ExcludeDirectories).Count -gt 0) {
        $args += "/XD"
        $args += $ExcludeDirectories
    }
    if (@($ExcludeFiles).Count -gt 0) {
        $args += "/XF"
        $args += $ExcludeFiles
    }

    $output = @(& robocopy @args 2>&1 | ForEach-Object { [string]$_ })
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }

    return [ordered]@{
        ok        = ($exitCode -le 7)
        exit_code = $exitCode
        output    = @($output | Select-Object -Last 20)
    }
}

function Remove-PathWithMirrorFallback {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [ordered]@{
            ok     = $true
            method = "absent"
            detail = "path already absent"
        }
    }

    $removeItemError = $null
    try {
        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        return [ordered]@{
            ok     = $true
            method = "remove_item"
            detail = "removed with Remove-Item"
        }
    }
    catch {
        $removeItemError = [string]$_.Exception.Message
    }

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $item -or -not $item.PSIsContainer) {
        return [ordered]@{
            ok     = $false
            method = "remove_item_failed"
            detail = $removeItemError
        }
    }

    $emptyDir = Join-Path ([System.IO.Path]::GetTempPath()) ("mason_mirror_empty_{0}" -f ([guid]::NewGuid().ToString("N")))
    try {
        New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
        $wipeResult = Invoke-RobocopyMirrorDirectory -SourceDir $emptyDir -DestinationDir $Path
        if (-not $wipeResult.ok) {
            return [ordered]@{
                ok     = $false
                method = "robocopy_empty_mirror_failed"
                detail = "Remove-Item failed: $removeItemError | robocopy exit $($wipeResult.exit_code)"
            }
        }

        Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
        if (Test-Path -LiteralPath $Path) {
            return [ordered]@{
                ok     = $false
                method = "robocopy_empty_mirror_failed"
                detail = "Remove-Item failed: $removeItemError | target still present after robocopy cleanup"
            }
        }

        return [ordered]@{
            ok     = $true
            method = "robocopy_empty_mirror"
            detail = "removed after robocopy empty-directory mirror"
        }
    }
    catch {
        return [ordered]@{
            ok     = $false
            method = "robocopy_empty_mirror_failed"
            detail = "Remove-Item failed: $removeItemError | fallback failed: $([string]$_.Exception.Message)"
        }
    }
    finally {
        if (Test-Path -LiteralPath $emptyDir) {
            Remove-Item -LiteralPath $emptyDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Sync-AllowlistedReportArtifacts {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$MirrorRoot,
        $ReportsPolicy
    )

    $patterns = @()
    $maxBytes = 2097152
    if ($ReportsPolicy) {
        if ($ReportsPolicy.PSObject.Properties.Name -contains "allowlist_patterns" -and $ReportsPolicy.allowlist_patterns) {
            $patterns = @($ReportsPolicy.allowlist_patterns | ForEach-Object { [string]$_ } | Where-Object { $_ })
        }
        if ($ReportsPolicy.PSObject.Properties.Name -contains "max_file_bytes") {
            $tmp = 0
            if ([int]::TryParse([string]$ReportsPolicy.max_file_bytes, [ref]$tmp) -and $tmp -gt 0) {
                $maxBytes = [int]$tmp
            }
        }
    }

    $reportsRoot = Join-Path $RepoRoot "reports"
    $summary = [ordered]@{
        status                 = "ok"
        allowlist_patterns     = @($patterns)
        max_file_bytes         = [int]$maxBytes
        candidate_count        = 0
        matched_allowlist_count = 0
        eligible_count         = 0
        skipped_large_count    = 0
        copied_count           = 0
        copied_files           = @()
        skipped_large_files    = @()
        failed_items           = @()
    }

    if (-not (Test-Path -LiteralPath $reportsRoot) -or @($patterns).Count -eq 0) {
        return $summary
    }

    $candidateFiles = @(Get-ChildItem -LiteralPath $reportsRoot -File -Recurse -Filter *.json -ErrorAction SilentlyContinue)
    $summary.candidate_count = @($candidateFiles).Count

    $matchedFiles = @(
        $candidateFiles | Where-Object {
            $relative = Get-RelativePathSafe -BasePath $RepoRoot -FullPath $_.FullName
            Test-PathMatchesAnyPattern -Path $relative -Patterns $patterns
        }
    )
    $summary.matched_allowlist_count = @($matchedFiles).Count

    foreach ($file in $matchedFiles) {
        $relative = Get-RelativePathSafe -BasePath $RepoRoot -FullPath $file.FullName
        if ([int64]$file.Length -gt [int64]$maxBytes) {
            $summary.skipped_large_count = [int]$summary.skipped_large_count + 1
            if (@($summary.skipped_large_files).Count -lt 20) {
                $summary.skipped_large_files += $relative
            }
            continue
        }

        $summary.eligible_count = [int]$summary.eligible_count + 1
        $destination = Join-Path $MirrorRoot $relative
        try {
            Ensure-ParentDirectory -Path $destination
            Copy-Item -LiteralPath $file.FullName -Destination $destination -Force -ErrorAction Stop
            $summary.copied_count = [int]$summary.copied_count + 1
            if (@($summary.copied_files).Count -lt 40) {
                $summary.copied_files += $relative
            }
        }
        catch {
            $summary.status = "failed"
            $summary.failed_items += ("{0} :: {1}" -f $relative, $_.Exception.Message)
        }
    }

    $summary.failed_items = @($summary.failed_items | Select-Object -First 20)
    return $summary
}

function Sync-AllowlistedContent {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$MirrorRoot,
        [Parameter(Mandatory = $true)][string[]]$Allowlist,
        $ReportsPolicy
    )

    $excludeDirectoryNames = @(
        ".git",
        ".venv",
        "__pycache__",
        "node_modules",
        ".dart_tool",
        "build",
        "dist",
        "artifacts",
        "bundles",
        "drop",
        "dumps",
        "logs",
        "uploads",
        "quarantine",
        "archives",
        "backups",
        "snapshots",
        "caches",
        "reviews"
    )
    $excludeFilePatterns = @(
        ".env",
        ".env.*",
        "secrets*.json",
        "*.log",
        "desktop.ini"
    )

    $itemResults = New-Object System.Collections.Generic.List[object]
    $missingSourceItems = New-Object System.Collections.Generic.List[string]
    $failedItems = New-Object System.Collections.Generic.List[string]
    $syncedCount = 0

    foreach ($entry in @($Allowlist | Where-Object { $_ })) {
        $normalizedEntry = (([string]$entry).Trim() -replace "/", "\")
        if (-not $normalizedEntry) {
            continue
        }
        if ($normalizedEntry -ieq "reports") {
            continue
        }

        $sourcePath = Join-Path $RepoRoot $normalizedEntry
        $destinationPath = Join-Path $MirrorRoot $normalizedEntry
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            $missingSourceItems.Add($normalizedEntry) | Out-Null
            $itemResults.Add([pscustomobject]@{
                    path = $normalizedEntry
                    type = "missing"
                    status = "missing"
                    detail = "source missing"
                    exit_code = $null
                }) | Out-Null
            continue
        }

        $item = Get-Item -LiteralPath $sourcePath -Force -ErrorAction Stop
        if ($item.PSIsContainer) {
            $syncResult = Invoke-RobocopyMirrorDirectory -SourceDir $item.FullName -DestinationDir $destinationPath -ExcludeDirectories $excludeDirectoryNames -ExcludeFiles $excludeFilePatterns
            $status = if ($syncResult.ok) { "ok" } else { "failed" }
            if ($syncResult.ok) {
                $syncedCount++
            }
            else {
                $failedItems.Add(("{0} :: robocopy exit {1}" -f $normalizedEntry, $syncResult.exit_code)) | Out-Null
            }
            $itemResults.Add([pscustomobject]@{
                    path = $normalizedEntry
                    type = "directory"
                    status = $status
                    detail = if ($syncResult.ok) { "mirrored" } else { "robocopy_failed" }
                    exit_code = $syncResult.exit_code
                }) | Out-Null
        }
        else {
            try {
                Ensure-ParentDirectory -Path $destinationPath
                Copy-Item -LiteralPath $item.FullName -Destination $destinationPath -Force -ErrorAction Stop
                $syncedCount++
                $itemResults.Add([pscustomobject]@{
                        path = $normalizedEntry
                        type = "file"
                        status = "ok"
                        detail = "copied"
                        exit_code = 0
                    }) | Out-Null
            }
            catch {
                $failedItems.Add(("{0} :: {1}" -f $normalizedEntry, $_.Exception.Message)) | Out-Null
                $itemResults.Add([pscustomobject]@{
                        path = $normalizedEntry
                        type = "file"
                        status = "failed"
                        detail = $_.Exception.Message
                        exit_code = 1
                    }) | Out-Null
            }
        }
    }

    $reportSync = Sync-AllowlistedReportArtifacts -RepoRoot $RepoRoot -MirrorRoot $MirrorRoot -ReportsPolicy $ReportsPolicy
    if ($reportSync.status -eq "failed") {
        foreach ($failed in @($reportSync.failed_items)) {
            $failedItems.Add([string]$failed) | Out-Null
        }
    }

    return [ordered]@{
        synced_count         = [int]$syncedCount
        missing_count        = @($missingSourceItems).Count
        failed_count         = @($failedItems).Count
        items                = @($itemResults.ToArray())
        missing_source_items = @($missingSourceItems | Select-Object -First 40)
        failed_items         = @($failedItems | Select-Object -First 40)
        reports_sync         = $reportSync
    }
}

function Remove-MirrorTopLevelOutsideAllowlist {
    param(
        [Parameter(Mandatory = $true)][string]$MirrorRoot,
        [Parameter(Mandatory = $true)]$AllowlistTopology
    )

    $allowedTopNames = @($AllowlistTopology.top_level_names)
    $protectedTopNames = @(".git")
    $removed = New-Object System.Collections.Generic.List[string]
    $failed = New-Object System.Collections.Generic.List[string]

    foreach ($item in @(Get-ChildItem -LiteralPath $MirrorRoot -Force -ErrorAction SilentlyContinue)) {
        if (($allowedTopNames -contains [string]$item.Name) -or ($protectedTopNames -contains [string]$item.Name)) {
            continue
        }

        try {
            $removeResult = Remove-PathWithMirrorFallback -Path $item.FullName
            if (-not $removeResult.ok) {
                throw $removeResult.detail
            }
            $removed.Add([string]$item.Name) | Out-Null
        }
        catch {
            $failed.Add(("{0} :: {1}" -f [string]$item.Name, [string]$_.Exception.Message)) | Out-Null
        }
    }

    return [ordered]@{
        removed_count = @($removed).Count
        failed_count  = @($failed).Count
        removed_items = @($removed | Select-Object -First 40)
        failed_items  = @($failed | Select-Object -First 40)
    }
}

function Remove-MirrorUnallowlistedSubpathNoise {
    param(
        [Parameter(Mandatory = $true)][string]$MirrorRoot,
        [Parameter(Mandatory = $true)]$AllowlistTopology
    )

    $wholeTopNames = @($AllowlistTopology.whole_top_level_names)
    $childMap = if ($AllowlistTopology.child_map) { $AllowlistTopology.child_map } else { [ordered]@{} }
    $removed = New-Object System.Collections.Generic.List[string]
    $failed = New-Object System.Collections.Generic.List[string]

    foreach ($topName in $childMap.Keys) {
        if ($wholeTopNames -contains [string]$topName) {
            continue
        }

        $topPath = Join-Path $MirrorRoot ([string]$topName)
        if (-not (Test-Path -LiteralPath $topPath)) {
            continue
        }

        $topItem = Get-Item -LiteralPath $topPath -Force -ErrorAction SilentlyContinue
        if (-not $topItem -or -not $topItem.PSIsContainer) {
            continue
        }

        $allowedChildren = @($childMap[$topName])
        foreach ($child in @(Get-ChildItem -LiteralPath $topPath -Force -ErrorAction SilentlyContinue)) {
            if (($allowedChildren -contains [string]$child.Name) -or ($child.Name -ieq ".gitkeep")) {
                continue
            }

            $relative = Get-RelativePathSafe -BasePath $MirrorRoot -FullPath $child.FullName
            try {
                $removeResult = Remove-PathWithMirrorFallback -Path $child.FullName
                if (-not $removeResult.ok) {
                    throw $removeResult.detail
                }
                $removed.Add($relative) | Out-Null
            }
            catch {
                $failed.Add(("{0} :: {1}" -f $relative, [string]$_.Exception.Message)) | Out-Null
            }
        }
    }

    return [ordered]@{
        removed_count = @($removed).Count
        failed_count  = @($failed).Count
        removed_items = @($removed | Select-Object -First 40)
        failed_items  = @($failed | Select-Object -First 40)
    }
}

function Remove-MirrorPolicyDeniedContent {
    param(
        [Parameter(Mandatory = $true)][string]$MirrorRoot,
        [Parameter(Mandatory = $true)][string[]]$Denylist
    )

    $removed = New-Object System.Collections.Generic.List[string]
    $failed = New-Object System.Collections.Generic.List[string]

    $items = @(
        Get-ChildItem -LiteralPath $MirrorRoot -Force -Recurse -ErrorAction SilentlyContinue |
        Sort-Object { $_.FullName.Length } -Descending
    )
    foreach ($item in $items) {
        if (-not (Test-Path -LiteralPath $item.FullName)) {
            continue
        }
        $relative = Get-RelativePathSafe -BasePath $MirrorRoot -FullPath $item.FullName
        if (-not $relative) {
            continue
        }
        if ($relative -match '^(?i)\.git([\\/]|$)') {
            continue
        }
        if (-not (Test-PathMatchesAnyPattern -Path $relative -Patterns $Denylist)) {
            continue
        }

        try {
            $removeResult = Remove-PathWithMirrorFallback -Path $item.FullName
            if (-not $removeResult.ok) {
                throw $removeResult.detail
            }
            $removed.Add($relative) | Out-Null
        }
        catch {
            $failed.Add(("{0} :: {1}" -f $relative, [string]$_.Exception.Message)) | Out-Null
        }
    }

    return [ordered]@{
        removed_count = @($removed).Count
        failed_count  = @($failed).Count
        removed_items = @($removed | Select-Object -First 40)
        failed_items  = @($failed | Select-Object -First 40)
    }
}

function Test-KnowledgePackNoSecrets {
    param(
        [Parameter(Mandatory = $true)][string]$PackRoot
    )

    if (-not (Test-Path -LiteralPath $PackRoot)) {
        return [ordered]@{
            ok    = $false
            items = @($PackRoot)
        }
    }

    $patterns = @(
        '(?i)ghp_[a-z0-9]{20,}',
        '(?i)sk-[a-z0-9]{20,}',
        '(?i)(api[_-]?key|access[_-]?token|secret|password)\s*[:=]\s*["'']?[a-z0-9_/\-+=]{10,}'
    )
    $violations = New-Object System.Collections.Generic.List[string]
    $files = @(Get-ChildItem -LiteralPath $PackRoot -File -Recurse -ErrorAction SilentlyContinue)
    foreach ($file in $files) {
        $name = ([string]$file.Name).ToLowerInvariant()
        $full = [string]$file.FullName

        if ($name -like ".env*" -or $name -like "secrets*.json" -or $full -match '(?i)[\\/](reviews)[\\/]') {
            $violations.Add($full) | Out-Null
            continue
        }

        if ($file.Length -gt 2097152) {
            continue
        }
        $raw = ""
        try {
            $raw = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
        }
        catch {
            continue
        }
        if (-not $raw) {
            continue
        }

        foreach ($pattern in $patterns) {
            if ([regex]::IsMatch($raw, $pattern)) {
                $violations.Add($full) | Out-Null
                break
            }
        }
    }

    $unique = @($violations.ToArray() | Sort-Object -Unique)
    return [ordered]@{
        ok    = (@($unique).Count -eq 0)
        items = @($unique | Select-Object -First 40)
    }
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
if (-not (Test-Path -LiteralPath $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

$effectiveMirrorCandidate = [string]$MirrorPath
if (-not $effectiveMirrorCandidate) {
    throw "MirrorPath is required."
}
if (-not (Test-Path -LiteralPath $effectiveMirrorCandidate)) {
    New-Item -ItemType Directory -Path $effectiveMirrorCandidate -Force | Out-Null
}
$EffectiveMirrorRoot = (Resolve-Path -LiteralPath $effectiveMirrorCandidate).Path
$MirrorPath = $EffectiveMirrorRoot
Write-Output ("Using mirror_root={0}." -f $EffectiveMirrorRoot)

$mirrorManifestScript = Join-Path $repoRoot "tools\Write_MirrorManifest.ps1"
$knowledgePackScript = Join-Path $repoRoot "tools\knowledge\Mason_Export_KnowledgePack.ps1"
$mirrorPushScript = Join-Path $MirrorPath "tools\MIRROR_Push.ps1"
$mirrorSecretGateScript = Join-Path $MirrorPath "tools\MIRROR_SecretGate.ps1"
$lastReportPath = Join-Path $reportsDir "mirror_update_last.json"
$logPath = Join-Path $reportsDir "mirror_update_log.jsonl"
$eventsPath = Join-Path $reportsDir "events.jsonl"
$mirrorDeltaPath = Join-Path $repoRoot "docs\mirror_delta.json"
$mirrorManifestPath = Join-Path $repoRoot "docs\mirror_manifest.json"

$reasonNormalized = Normalize-Reason -Value $Reason
$commitMessage = "mirror: $reasonNormalized"
$secretGateAutogenEnabled = ([bool]$AutoGenerateSecretGateTemplate -and -not [bool]$DisableSecretGateAutogen)
$manifestForRun = $null
$allowlistForRun = @()
$denylistForRun = @()
$allowlistTopology = $null

$result = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    reason_requested = $Reason
    reason        = $reasonNormalized
    commit_message = $commitMessage
    repo_root     = $repoRoot
    mirror_root   = $EffectiveMirrorRoot
    effective_mirror_root = $EffectiveMirrorRoot
    manifest_path = $mirrorManifestPath
    mirror_delta_path = $mirrorDeltaPath
    steps         = [ordered]@{
        write_mirror_manifest = "pending"
        verify_mirror_state   = "pending"
        export_knowledge_pack = "pending"
        sync_allowlisted_content = "pending"
        run_secret_gate       = "pending"
        mirror_push           = "pending"
    }
    ok            = $false
    phase         = $null
    missing_items = @()
    next_action   = $null
    secret_gate_autogen_enabled = [bool]$secretGateAutogenEnabled
    secret_gate_autogen_status = "pending"
    secret_gate_autogen_skipped_reason = $null
    exclude_patterns = @(".env*", "secrets*.json", "**/reviews/**")
    policy_summary = $null
    sync_summary = $null
    top_level_cleanup = $null
    scoped_cleanup = $null
    policy_cleanup = $null
    manual_review_items = @()
    exclude_cleanup = $null
    reports_slim_policy = $null
    reports_slim_cleanup = $null
    mirror_push_result = $null
    mirror_push_exit_code = $null
    error         = $null
}

$headBefore = ""
if (Test-Path -LiteralPath $MirrorPath) {
    $headBeforeResult = Invoke-GitCapture -RepoPath $MirrorPath -Args @("rev-parse", "HEAD")
    if ($headBeforeResult.ok) {
        $headBefore = [string]$headBeforeResult.joined
    }
}

try {
    $result.phase = "write_mirror_manifest"
    if (-not (Test-Path -LiteralPath $mirrorManifestScript)) {
        throw "Missing script: $mirrorManifestScript"
    }
    & $mirrorManifestScript -RootPath $repoRoot -MirrorPath $MirrorPath | Out-Null
    $result.steps.write_mirror_manifest = "ok"

    $result.phase = "verify_mirror_state"
    $manifest = Read-JsonSafe -Path $mirrorManifestPath -Default $null
    if (-not $manifest) {
        throw "Mirror manifest missing or invalid after generation: $mirrorManifestPath"
    }
    $missingAllowlist = @(Get-MissingAllowlistNames -Manifest $manifest)
    $result.missing_items = @($missingAllowlist)
    $manifestForRun = $manifest
    $reportsPolicy = $null
    if ($manifestForRun -and ($manifestForRun.PSObject.Properties.Name -contains "reports_json_policy")) {
        $reportsPolicy = $manifestForRun.reports_json_policy
    }
    if ($manifestForRun -and ($manifestForRun.PSObject.Properties.Name -contains "allowlist")) {
        $allowlistForRun = @($manifestForRun.allowlist | ForEach-Object { [string]$_ } | Where-Object { $_ })
    }
    if ($manifestForRun -and ($manifestForRun.PSObject.Properties.Name -contains "denylist")) {
        $denylistForRun = @($manifestForRun.denylist | ForEach-Object { [string]$_ } | Where-Object { $_ })
    }
    $allowlistTopology = Get-AllowlistTopology -Allowlist $allowlistForRun
    if ($reportsPolicy) {
        $result.reports_slim_policy = [ordered]@{
            allowlist_patterns = @($reportsPolicy.allowlist_patterns)
            max_file_bytes     = $reportsPolicy.max_file_bytes
        }
    }
    $manualReviewItems = @()
    if ($manifestForRun -and ($manifestForRun.PSObject.Properties.Name -contains "missing_from_mirror") -and $manifestForRun.missing_from_mirror) {
        $missingFromMirror = $manifestForRun.missing_from_mirror
        if ($missingFromMirror.PSObject.Properties.Name -contains "source_top_level_not_allowlisted") {
            $manualReviewItems = @($missingFromMirror.source_top_level_not_allowlisted | ForEach-Object { [string]$_ } | Where-Object { $_ } | Select-Object -First 40)
        }
    }
    $result.manual_review_items = $manualReviewItems
    $result.policy_summary = [ordered]@{
        manifest_path = $mirrorManifestPath
        allowlist = @($allowlistForRun)
        allowlisted_top_level_names = if ($allowlistTopology) { @($allowlistTopology.top_level_names) } else { @() }
        denylist = @($denylistForRun)
        reports_allowlist_patterns = if ($reportsPolicy) { @($reportsPolicy.allowlist_patterns) } else { @() }
        reports_max_file_bytes = if ($reportsPolicy) { [int]($reportsPolicy.max_file_bytes) } else { 0 }
        pre_sync_missing_allowlist_top_level = @($missingAllowlist)
    }
    $result.steps.verify_mirror_state = "ok"

    $result.phase = "export_knowledge_pack"
    if (-not (Test-Path -LiteralPath $knowledgePackScript)) {
        throw "Missing script: $knowledgePackScript"
    }
    & $knowledgePackScript -RootPath $repoRoot | Out-Null

    $packRoot = Join-Path $repoRoot "docs\knowledge_pack"
    $packCheck = Test-KnowledgePackNoSecrets -PackRoot $packRoot
    if (-not [bool]$packCheck.ok) {
        $result.steps.export_knowledge_pack = "failed"
        $result.missing_items = @($packCheck.items)
        $result.next_action = "Remove secrets from docs\\knowledge_pack output and rerun tools\\sync\\Mason_Mirror_Update.ps1"
        throw "Knowledge pack contains excluded or secret-like content."
    }
    $result.steps.export_knowledge_pack = "ok"

    $result.phase = "sync_allowlisted_content"
    $result.sync_summary = Sync-AllowlistedContent -RepoRoot $repoRoot -MirrorRoot $MirrorPath -Allowlist $allowlistForRun -ReportsPolicy $reportsPolicy
    if ($result.sync_summary.failed_count -gt 0) {
        $result.steps.sync_allowlisted_content = "failed"
        $result.missing_items = @($result.sync_summary.failed_items)
        $result.next_action = "Inspect the mirror sync summary and rerun tools\\sync\\Mason_Mirror_Update.ps1."
        throw "Failed to sync one or more allowlisted mirror items."
    }

    $result.top_level_cleanup = Remove-MirrorTopLevelOutsideAllowlist -MirrorRoot $MirrorPath -AllowlistTopology $allowlistTopology
    if ($result.top_level_cleanup.failed_count -gt 0) {
        $result.steps.sync_allowlisted_content = "failed"
        $result.missing_items = @($result.top_level_cleanup.failed_items)
        $result.next_action = "Review top-level mirror cleanup failures and rerun tools\\sync\\Mason_Mirror_Update.ps1."
        throw "Failed to clean non-allowlisted top-level mirror content."
    }

    $result.scoped_cleanup = Remove-MirrorUnallowlistedSubpathNoise -MirrorRoot $MirrorPath -AllowlistTopology $allowlistTopology
    if ($result.scoped_cleanup.failed_count -gt 0) {
        $result.steps.sync_allowlisted_content = "failed"
        $result.missing_items = @($result.scoped_cleanup.failed_items)
        $result.next_action = "Review scoped mirror cleanup failures and rerun tools\\sync\\Mason_Mirror_Update.ps1."
        throw "Failed to clean unallowlisted mirror subpaths."
    }

    $result.policy_cleanup = Remove-MirrorPolicyDeniedContent -MirrorRoot $MirrorPath -Denylist $denylistForRun
    if ($result.policy_cleanup.failed_count -gt 0) {
        $result.steps.sync_allowlisted_content = "failed"
        $result.missing_items = @($result.policy_cleanup.failed_items)
        $result.next_action = "Review mirror denylist cleanup failures and rerun tools\\sync\\Mason_Mirror_Update.ps1."
        throw "Failed to remove denylisted mirror content."
    }

    $result.exclude_cleanup = Remove-MirrorExcludedContent -MirrorRoot $MirrorPath
    $result.reports_slim_cleanup = Remove-MirrorReportsOutsidePolicy -MirrorRoot $MirrorPath -ReportsPolicy $reportsPolicy
    if ($result.reports_slim_cleanup.failed_count -gt 0) {
        $result.steps.sync_allowlisted_content = "failed"
        $result.missing_items = @($result.reports_slim_cleanup.failed_items)
        $result.next_action = "Fix permissions and rerun to enforce reports slim policy."
        throw "Failed to apply reports slim policy cleanup in mirror root."
    }

    & $mirrorManifestScript -RootPath $repoRoot -MirrorPath $MirrorPath | Out-Null
    $manifestPostSync = Read-JsonSafe -Path $mirrorManifestPath -Default $null
    if (-not $manifestPostSync) {
        $result.steps.sync_allowlisted_content = "failed"
        $result.next_action = "Inspect tools\\Write_MirrorManifest.ps1 output and rerun tools\\sync\\Mason_Mirror_Update.ps1."
        throw "Mirror manifest missing or invalid after sync."
    }
    $missingAllowlistPostSync = @(Get-MissingAllowlistNames -Manifest $manifestPostSync)
    if ($missingAllowlistPostSync.Count -gt 0) {
        $result.steps.sync_allowlisted_content = "failed"
        $result.missing_items = @($missingAllowlistPostSync)
        $result.next_action = "Verify mirror filesystem permissions and rerun tools\\sync\\Mason_Mirror_Update.ps1."
        throw ("Mirror missing allowlisted top-level items after sync: {0}" -f (($missingAllowlistPostSync | Sort-Object -Unique) -join ", "))
    }
    $result.missing_items = @()
    $result.steps.sync_allowlisted_content = "ok"

    $result.phase = "run_secret_gate"
    $gateExists = Test-Path -LiteralPath $mirrorSecretGateScript
    if ($gateExists) {
        $result.secret_gate_autogen_status = "skipped"
        $result.secret_gate_autogen_skipped_reason = "gate_exists"
    }
    else {
        $result.steps.run_secret_gate = "failed"
        $result.missing_items = @("tools\MIRROR_SecretGate.ps1")
        $result.next_action = "Create tools\MIRROR_SecretGate.ps1 in mirror repo (template)"
        if ($DisableSecretGateAutogen) {
            $result.secret_gate_autogen_status = "skipped"
            $result.secret_gate_autogen_skipped_reason = "disabled_by_switch"
            throw "Missing mirror secret gate script: $mirrorSecretGateScript"
        }
        elseif ($AutoGenerateSecretGateTemplate) {
            Write-SecretGateTemplate -Path $mirrorSecretGateScript
            $result.missing_items = @()
            $result.next_action = "Review auto-generated tools\\MIRROR_SecretGate.ps1 template and re-run if policy needs tightening"
            $result.secret_gate_autogen_status = "generated"
            $result.secret_gate_autogen_skipped_reason = $null
        }
        else {
            $result.secret_gate_autogen_status = "skipped"
            $result.secret_gate_autogen_skipped_reason = "autogen_flag_off"
            throw "Missing mirror secret gate script: $mirrorSecretGateScript"
        }
        if (-not (Test-Path -LiteralPath $mirrorSecretGateScript)) {
            $result.steps.run_secret_gate = "failed"
            $result.next_action = "Create tools\MIRROR_SecretGate.ps1 in mirror repo (template)"
            throw "Missing mirror secret gate script: $mirrorSecretGateScript"
        }
    }
    try {
        & $mirrorSecretGateScript -RootPath $MirrorPath | Out-Null
    }
    catch {
        $gateError = [string]$_.Exception.Message
        if ($gateError -match "parameter name ['`"]RootPath['`"]") {
            & $mirrorSecretGateScript | Out-Null
        }
        else {
            throw
        }
    }
    if ($LASTEXITCODE -ne 0) {
        $result.steps.run_secret_gate = "failed"
        throw "Mirror secret gate failed."
    }
    $result.steps.run_secret_gate = "ok"

    $result.phase = "mirror_push"
    $pushOutput = @()
    $pushExitCode = 0
    $pushResultValue = ""
    if (Test-Path -LiteralPath $mirrorPushScript) {
        try {
            $pushOutput = @(& $mirrorPushScript -RootPath $MirrorPath -CommitMessage $commitMessage 2>&1 | ForEach-Object { [string]$_ })
        }
        catch {
            $pushError = [string]$_.Exception.Message
            if ($pushError -match "parameter name ['`"]RootPath['`"]") {
                $pushOutput = @(& $mirrorPushScript -CommitMessage $commitMessage 2>&1 | ForEach-Object { [string]$_ })
            }
            else {
                throw
            }
        }
        $pushExitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
        if ($pushExitCode -eq 0) {
            $pushJoined = ((@($pushOutput) -join "`n").ToLowerInvariant())
            if ($pushJoined -match "nothing to push") {
                $pushResultValue = "noop"
            }
            else {
                $pushResultValue = "pushed"
            }
        }
    }

    if (-not $pushResultValue) {
        $fallbackPush = Invoke-MirrorPushFallback -MirrorRoot $MirrorPath -CommitMessage $commitMessage
        $pushOutput = @($fallbackPush.output)
        $pushExitCode = [int]$fallbackPush.exit_code
        $pushResultValue = [string]$fallbackPush.result
        if (-not [bool]$fallbackPush.ok) {
            throw ("Mirror push fallback failed: {0}" -f $pushResultValue)
        }
        if ($pushResultValue -eq "local_commit_only_remote_push_failed" -or $pushResultValue -eq "local_commit_only_remote_probe_failed") {
            $result.next_action = "Review mirror remote connectivity if off-box replication is required; the local checkpoint was committed successfully."
        }
    }

    $result.mirror_push_exit_code = [int]$pushExitCode
    $result.steps.mirror_push = "ok"
    $result.mirror_push_result = $pushResultValue
    $result.ok = $true
    $result.phase = "done"
}
catch {
    $result.error = $_.Exception.Message
    if (-not $result.phase) {
        $result.phase = "unknown"
    }
    if ($null -eq $result.missing_items) {
        $result.missing_items = @()
    }
    if (-not $result.next_action) {
        $result.next_action = "inspect reports\\mirror_update_last.json and rerun tools\\sync\\Mason_Mirror_Update.ps1"
    }
    if ($result.phase -eq "run_secret_gate" -and $result.steps.run_secret_gate -eq "pending") {
        $result.steps.run_secret_gate = "failed"
    }
    if ($result.phase -eq "sync_allowlisted_content" -and $result.steps.sync_allowlisted_content -eq "pending") {
        $result.steps.sync_allowlisted_content = "failed"
    }
    if ($result.phase -eq "export_knowledge_pack" -and $result.steps.sync_allowlisted_content -eq "pending") {
        $result.steps.sync_allowlisted_content = "skipped"
    }
    if ($result.phase -eq "run_secret_gate" -and $result.steps.mirror_push -eq "pending") {
        $result.steps.mirror_push = "skipped"
    }
    if ($result.phase -eq "mirror_push" -and $result.steps.mirror_push -eq "pending") {
        $result.steps.mirror_push = "failed"
        if ($null -eq $result.mirror_push_exit_code) {
            if ($null -ne $LASTEXITCODE -and [int]$LASTEXITCODE -ne 0) {
                $result.mirror_push_exit_code = [int]$LASTEXITCODE
            }
            else {
                $result.mirror_push_exit_code = 1
            }
        }
    }
}

$headAfter = ""
if (Test-Path -LiteralPath $MirrorPath) {
    $headAfterResult = Invoke-GitCapture -RepoPath $MirrorPath -Args @("rev-parse", "HEAD")
    if ($headAfterResult.ok) {
        $headAfter = [string]$headAfterResult.joined
    }
}
$delta = Get-MirrorDeltaSummary -MirrorRoot $MirrorPath -HeadBefore $headBefore -HeadAfter $headAfter
Write-JsonFile -Path $mirrorDeltaPath -Object $delta -Depth 12

if ($result.steps.mirror_push -eq "ok") {
    if (-not $result.mirror_push_result) {
        if ($headBefore -and $headAfter -and $headBefore -eq $headAfter) {
            $result.mirror_push_result = "noop"
        }
        else {
            $result.mirror_push_result = "pushed"
        }
    }
    elseif ($result.mirror_push_result -eq "pushed" -and $headBefore -and $headAfter -and $headBefore -eq $headAfter) {
        $result.mirror_push_result = "noop"
    }
}

$result.timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
Write-JsonFile -Path $lastReportPath -Object $result -Depth 16
Add-JsonLine -Path $logPath -Object $result
Add-JsonLine -Path $eventsPath -Object ([ordered]@{
        ts_utc         = (Get-Date).ToUniversalTime().ToString("o")
        kind           = "mirror_update"
        status         = if ($result.ok) { "completed" } else { "failed" }
        component      = "mirror"
        correlation_id = ("mirror-{0}" -f ((Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")))
        details        = [ordered]@{
            reason         = $reasonNormalized
            commit_message = $commitMessage
            error          = $result.error
            delta_path     = $mirrorDeltaPath
            changed_count  = $delta.changed_count
            added_count    = $delta.added_count
            modified_count = $delta.modified_count
            removed_count  = $delta.removed_count
        }
    })

$result | ConvertTo-Json -Depth 12

if (-not $result.ok) {
    exit 1
}

exit 0
