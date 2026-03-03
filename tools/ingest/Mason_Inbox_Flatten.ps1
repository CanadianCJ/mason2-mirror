[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$SourceDir = "",
    [string]$TargetDir = ""
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
        [int]$Depth = 16
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value ($Object | ConvertTo-Json -Depth $Depth) -Encoding UTF8
}

function Get-RelativePathSafe {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$FullPath
    )
    try {
        $base = [IO.Path]::GetFullPath($BasePath)
        $full = [IO.Path]::GetFullPath($FullPath)
        $rel = [IO.Path]::GetRelativePath($base, $full)
        if (-not $rel -or $rel.StartsWith("..")) {
            return [IO.Path]::GetFileName($full)
        }
        return $rel
    }
    catch {
        return [IO.Path]::GetFileName($FullPath)
    }
}

function ConvertTo-SafeSegment {
    param([string]$Value)
    $raw = ([string]$Value).Trim()
    if (-not $raw) { return "item" }
    $safe = ($raw -replace "[<>:""/\\|?*\x00-\x1f]+", "_").Trim()
    if (-not $safe) { return "item" }
    return $safe
}

function Collapse-RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$RepeatToken
    )

    $token = ([string]$RepeatToken).Trim()
    if (-not $token) { $token = "Chat GPT old chats" }
    $tokenLower = $token.ToLowerInvariant()

    $parts = @([regex]::Split($RelativePath.Replace("/", "\"), "\\+") | Where-Object { $_ -and $_.Trim() })
    $collapsed = New-Object System.Collections.Generic.List[string]
    $lastWasToken = $false
    foreach ($partRaw in $parts) {
        $part = ConvertTo-SafeSegment -Value $partRaw
        $isToken = ($part.ToLowerInvariant() -eq $tokenLower)
        if ($isToken -and $lastWasToken) {
            continue
        }
        $collapsed.Add($part) | Out-Null
        $lastWasToken = $isToken
    }

    if ($collapsed.Count -eq 0) {
        return "item.txt"
    }
    return ($collapsed.ToArray() -join "\")
}

function Redact-Secrets {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    $redacted = [string]$Text
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

function Normalize-TextForHash {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    $t = [string]$Text
    $t = $t -replace "`r`n", "`n"
    $t = $t -replace "`r", "`n"
    $t = [regex]::Replace($t, "\s+", " ").Trim()
    return $t
}

function Get-Sha256Hex {
    param([Parameter(Mandatory = $true)][string]$Text)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }
    return (-join ($hash | ForEach-Object { $_.ToString("x2") }))
}

function Read-TextFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    try {
        return Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        try {
            return Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        }
        catch {
            return $null
        }
    }
}

function Test-TextLikeFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
    }
    catch {
        return $false
    }

    if (-not $bytes -or $bytes.Length -eq 0) {
        return $false
    }

    $sampleLen = [Math]::Min(8192, $bytes.Length)
    $printable = 0
    $nulFound = $false
    for ($i = 0; $i -lt $sampleLen; $i++) {
        $b = [int]$bytes[$i]
        if ($b -eq 0) {
            $nulFound = $true
            break
        }
        if (
            ($b -eq 9) -or ($b -eq 10) -or ($b -eq 13) -or
            ($b -ge 32 -and $b -le 126) -or
            ($b -ge 160)
        ) {
            $printable++
        }
    }

    if ($nulFound) {
        return $false
    }

    $ratio = $printable / [double]$sampleLen
    return ($ratio -ge 0.85)
}

function Resolve-MasonConsolePython {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)
    $consoleDir = Join-Path $RepoRoot "MasonConsole"
    $candidates = @(
        (Join-Path $consoleDir ".venv\Scripts\python.exe"),
        (Join-Path $consoleDir "venv\Scripts\python.exe"),
        (Join-Path $RepoRoot ".venv\Scripts\python.exe"),
        (Join-Path $RepoRoot "venv\Scripts\python.exe")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }
    return "python"
}

function Test-PythonDocxModule {
    param([Parameter(Mandatory = $true)][string]$PythonExe)
    try {
        & $PythonExe -c "import docx" 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
}

function Try-InstallPythonDocx {
    param([Parameter(Mandatory = $true)][string]$PythonExe)
    try {
        & $PythonExe -m pip install python-docx --disable-pip-version-check --quiet 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
}

function Convert-DocxTextPython {
    param(
        [Parameter(Mandatory = $true)][string]$PythonExe,
        [Parameter(Mandatory = $true)][string]$DocxPath
    )

    $tmpScript = Join-Path ([IO.Path]::GetTempPath()) ("mason_docx_extract_{0}.py" -f ([guid]::NewGuid().ToString("N")))
    $script = @'
import sys
from docx import Document

path = sys.argv[1]
doc = Document(path)
parts = []
for p in doc.paragraphs:
    t = (p.text or "").strip()
    if t:
        parts.append(t)
sys.stdout.write("\n".join(parts))
'@
    try {
        Set-Content -LiteralPath $tmpScript -Value $script -Encoding UTF8
        $output = & $PythonExe $tmpScript $DocxPath 2>$null
        if ($LASTEXITCODE -ne 0) {
            return $null
        }
        return (($output -join "`n").Trim())
    }
    catch {
        return $null
    }
    finally {
        if (Test-Path -LiteralPath $tmpScript) {
            Remove-Item -LiteralPath $tmpScript -Force -ErrorAction SilentlyContinue
        }
    }
}

function Convert-DocxTextXmlFallback {
    param([Parameter(Mandatory = $true)][string]$DocxPath)
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
        $zip = [System.IO.Compression.ZipFile]::OpenRead($DocxPath)
        try {
            $entry = $zip.GetEntry("word/document.xml")
            if (-not $entry) {
                return $null
            }
            $stream = $entry.Open()
            try {
                $reader = New-Object System.IO.StreamReader($stream)
                $xmlText = $reader.ReadToEnd()
                $reader.Dispose()
            }
            finally {
                $stream.Dispose()
            }
        }
        finally {
            $zip.Dispose()
        }
        if (-not $xmlText) {
            return $null
        }
        $text = $xmlText -replace "(?i)</w:p>", "`n"
        $text = $text -replace "<[^>]+>", ""
        $text = [System.Net.WebUtility]::HtmlDecode($text)
        return $text.Trim()
    }
    catch {
        return $null
    }
}

function Get-DocxText {
    param(
        [Parameter(Mandatory = $true)][string]$DocxPath,
        [Parameter(Mandatory = $true)]$PythonDocxState
    )

    if ($PythonDocxState.available -and $PythonDocxState.python) {
        $text = Convert-DocxTextPython -PythonExe $PythonDocxState.python -DocxPath $DocxPath
        if ($text) {
            return $text
        }
    }
    return (Convert-DocxTextXmlFallback -DocxPath $DocxPath)
}

function Ensure-PythonDocx {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)
    $python = Resolve-MasonConsolePython -RepoRoot $RepoRoot
    $has = Test-PythonDocxModule -PythonExe $python
    $attempted = $false
    $installed = $false
    if (-not $has) {
        $attempted = $true
        $installed = Try-InstallPythonDocx -PythonExe $python
        if ($installed) {
            $has = Test-PythonDocxModule -PythonExe $python
        }
    }
    return [pscustomobject]@{
        python            = $python
        available         = [bool]$has
        install_attempted = [bool]$attempted
        install_succeeded = [bool]$installed
    }
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
if (-not $SourceDir) {
    $SourceDir = "C:\Users\Chris\Desktop\Chat GPT old chats"
}
if (-not $TargetDir) {
    $TargetDir = Join-Path $repoRoot "knowledge\inbox_flat"
}
$reportsDir = Join-Path $repoRoot "reports"
$manifestPath = Join-Path $TargetDir "_manifest.json"
$lastReportPath = Join-Path $reportsDir "inbox_flatten_last.json"
$startedAtUtc = (Get-Date).ToUniversalTime().ToString("o")

if (-not (Test-Path -LiteralPath $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $SourceDir)) {
    throw "Flatten source folder not found: $SourceDir"
}

New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
Get-ChildItem -LiteralPath $TargetDir -Force -ErrorAction SilentlyContinue | ForEach-Object {
    Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$sourceRootName = [IO.Path]::GetFileName((Resolve-Path -LiteralPath $SourceDir).Path)
$pythonDocxState = Ensure-PythonDocx -RepoRoot $repoRoot

$hashIndex = @{}
$entries = New-Object System.Collections.Generic.List[object]
$counts = [ordered]@{
    files_scanned          = 0
    files_written          = 0
    files_duplicated       = 0
    extensionless_converted = 0
    docx_converted         = 0
    textlike_converted     = 0
    quarantined            = 0
    errors                 = 0
    skipped                = 0
}
$knownTextExtensions = @(
    ".txt", ".md", ".log", ".json", ".yaml", ".yml", ".ini", ".cfg", ".toml",
    ".xml", ".csv", ".ps1", ".py", ".js", ".ts", ".tsx", ".jsx", ".html", ".htm",
    ".sql", ".bat", ".cmd"
)
$quarantineDir = Join-Path $TargetDir "_quarantine"
New-Item -ItemType Directory -Path $quarantineDir -Force | Out-Null

$sourceFiles = @(Get-ChildItem -LiteralPath $SourceDir -Recurse -File -ErrorAction SilentlyContinue | Sort-Object FullName)
foreach ($file in $sourceFiles) {
    $counts.files_scanned = [int]$counts.files_scanned + 1
    $ext = ([string]$file.Extension).ToLowerInvariant()
    $kind = "text"
    $text = $null

    if ($ext -eq ".docx") {
        $kind = "docx"
        $text = Get-DocxText -DocxPath $file.FullName -PythonDocxState $pythonDocxState
        if ($text) {
            $counts.docx_converted = [int]$counts.docx_converted + 1
        }
    }
    else {
        if (-not $ext) {
            $kind = "extensionless"
            $text = Read-TextFile -Path $file.FullName
            if ($text) {
                $counts.extensionless_converted = [int]$counts.extensionless_converted + 1
            }
        }
        elseif ($knownTextExtensions -contains $ext) {
            $text = Read-TextFile -Path $file.FullName
        }
        elseif (Test-TextLikeFile -Path $file.FullName) {
            $kind = "unknown_textlike"
            $text = Read-TextFile -Path $file.FullName
            if ($text) {
                $counts.textlike_converted = [int]$counts.textlike_converted + 1
            }
        }
        else {
            $kind = "unknown_binary"
            $relative = Get-RelativePathSafe -BasePath $SourceDir -FullPath $file.FullName
            $collapsedRelative = Collapse-RelativePath -RelativePath $relative -RepeatToken $sourceRootName
            $quarantinePath = Join-Path $quarantineDir $collapsedRelative
            try {
                $qParent = Split-Path -Parent $quarantinePath
                if ($qParent -and -not (Test-Path -LiteralPath $qParent)) {
                    New-Item -ItemType Directory -Path $qParent -Force | Out-Null
                }
                Copy-Item -LiteralPath $file.FullName -Destination $quarantinePath -Force
                $counts.quarantined = [int]$counts.quarantined + 1
                $entries.Add([ordered]@{
                        source_path     = $file.FullName
                        relative_source = $relative
                        target_path     = $quarantinePath
                        status          = "quarantined"
                        kind            = $kind
                        error           = "non_textlike_unknown_extension"
                    }) | Out-Null
            }
            catch {
                $counts.errors = [int]$counts.errors + 1
                $entries.Add([ordered]@{
                        source_path     = $file.FullName
                        relative_source = $relative
                        target_path     = $quarantinePath
                        status          = "error"
                        kind            = $kind
                        error           = $_.Exception.Message
                    }) | Out-Null
            }
            continue
        }
    }

    if (-not $text) {
        $counts.skipped = [int]$counts.skipped + 1
        $entries.Add([ordered]@{
                source_path     = $file.FullName
                relative_source = (Get-RelativePathSafe -BasePath $SourceDir -FullPath $file.FullName)
                target_path     = $null
                status          = "skipped"
                kind            = $kind
                error           = "unreadable_or_empty"
            }) | Out-Null
        continue
    }

    $redacted = Redact-Secrets -Text $text
    $normalized = Normalize-TextForHash -Text $redacted
    if (-not $normalized) {
        $counts.skipped = [int]$counts.skipped + 1
        $entries.Add([ordered]@{
                source_path     = $file.FullName
                relative_source = (Get-RelativePathSafe -BasePath $SourceDir -FullPath $file.FullName)
                target_path     = $null
                status          = "skipped"
                kind            = $kind
                error           = "empty_after_normalize"
            }) | Out-Null
        continue
    }

    $hash = Get-Sha256Hex -Text $normalized
    $relative = Get-RelativePathSafe -BasePath $SourceDir -FullPath $file.FullName
    $collapsedRelative = Collapse-RelativePath -RelativePath $relative -RepeatToken $sourceRootName
    $collapsedNoExt = [IO.Path]::ChangeExtension($collapsedRelative, $null)
    if (-not $collapsedNoExt) {
        $collapsedNoExt = [IO.Path]::GetFileNameWithoutExtension($file.Name)
    }
    $targetRelative = ($collapsedNoExt.TrimEnd("\", "/")) + ".txt"
    $targetPath = Join-Path $TargetDir $targetRelative

    if ($hashIndex.ContainsKey($hash)) {
        $counts.files_duplicated = [int]$counts.files_duplicated + 1
        $entries.Add([ordered]@{
                source_path      = $file.FullName
                relative_source  = $relative
                target_path      = $null
                status           = "duplicate"
                kind             = $kind
                normalized_sha256 = $hash
                duplicate_of     = [string]$hashIndex[$hash]
            }) | Out-Null
        continue
    }

    try {
        $targetParent = Split-Path -Parent $targetPath
        if ($targetParent -and -not (Test-Path -LiteralPath $targetParent)) {
            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
        }
        Set-Content -LiteralPath $targetPath -Value $redacted -Encoding UTF8
        $hashIndex[$hash] = $targetPath
        $counts.files_written = [int]$counts.files_written + 1
        $entries.Add([ordered]@{
                source_path      = $file.FullName
                relative_source  = $relative
                target_path      = $targetPath
                status           = "written"
                kind             = $kind
                normalized_sha256 = $hash
            }) | Out-Null
    }
    catch {
        $counts.errors = [int]$counts.errors + 1
        $entries.Add([ordered]@{
                source_path     = $file.FullName
                relative_source = $relative
                target_path     = $targetPath
                status          = "error"
                kind            = $kind
                error           = $_.Exception.Message
            }) | Out-Null
    }
}

$finishedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
$manifest = [ordered]@{
    generated_at_utc = $finishedAtUtc
    started_at_utc   = $startedAtUtc
    source_dir       = $SourceDir
    target_dir       = $TargetDir
    quarantine_dir   = $quarantineDir
    source_root_name = $sourceRootName
    python_docx      = $pythonDocxState
    counts           = $counts
    entries          = @($entries.ToArray())
}
Write-JsonFile -Path $manifestPath -Object $manifest -Depth 24

$last = [ordered]@{
    generated_at_utc = $finishedAtUtc
    source_dir       = $SourceDir
    target_dir       = $TargetDir
    quarantine_dir   = $quarantineDir
    manifest_path    = $manifestPath
    counts           = $counts
    python_docx      = $pythonDocxState
}
Write-JsonFile -Path $lastReportPath -Object $last -Depth 12

[pscustomobject]$last | ConvertTo-Json -Depth 12
