[CmdletBinding()]
param(
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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
    }
    catch {
    }

    return $FullPath
}

function Test-LiteralLooksSensitive {
    param(
        [Parameter(Mandatory = $true)][string]$Value
    )

    $trimmed = $Value.Trim()
    if (-not $trimmed) {
        return $false
    }

    $placeholderPattern = '^(?i)(replace[-_ ]?me|change[-_ ]?me|changeme|redacted|example|dummy|test|placeholder|sample|your[_-]?.*)$'
    if ($trimmed -match $placeholderPattern) {
        return $false
    }

    if ($trimmed -match '^[A-Z][A-Z0-9_]{10,}$') {
        return $false
    }

    if ($trimmed.Length -lt 16) {
        return $false
    }

    if ($trimmed -notmatch '^[A-Za-z0-9_/\-+=]+$') {
        return $false
    }

    return ($trimmed -match '[a-z]' -or $trimmed -match '\d')
}

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
$tokenPatterns = @(
    '(?i)\bghp_[a-z0-9]{20,}\b',
    '(?i)\bsk-(proj-)?[A-Za-z0-9_\-]{20,}\b'
)
$quotedLiteralPattern = '(?im)\b(api[_-]?key|access[_-]?token|secret|password)\b\s*[:=]\s*["'']([^"''`r`n]{16,})["'']'

$files = @(Get-ChildItem -LiteralPath $RootPath -Recurse -File -ErrorAction SilentlyContinue)
foreach ($file in $files) {
    $full = [string]$file.FullName
    $rel = Get-RelativePathSafe -BasePath $RootPath -FullPath $full
    $nameLower = ([string]$file.Name).ToLowerInvariant()

    if ($nameLower -like ".env*" -or $nameLower -like "secrets*.json") {
        $filenameViolations.Add($rel) | Out-Null
        continue
    }

    $ext = ([System.IO.Path]::GetExtension([string]$file.Name)).ToLowerInvariant()
    if (-not ($textExtensions -contains $ext)) {
        continue
    }
    if ([int64]$file.Length -gt 2097152) {
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

    $matchedToken = $false
    foreach ($pattern in $tokenPatterns) {
        if ([regex]::IsMatch($raw, $pattern)) {
            $contentViolations.Add($rel) | Out-Null
            $matchedToken = $true
            break
        }
    }
    if ($matchedToken) {
        continue
    }

    $literalMatches = [regex]::Matches($raw, $quotedLiteralPattern)
    foreach ($match in $literalMatches) {
        if (-not $match.Success) {
            continue
        }

        $candidateValue = [string]$match.Groups[2].Value
        if (Test-LiteralLooksSensitive -Value $candidateValue) {
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

Write-Host "[MIRROR_SecretGate] no secret violations detected."
exit 0
