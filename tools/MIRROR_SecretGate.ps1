[CmdletBinding()]
param(
    [string]$RootPath = "",
    [switch]$Cached
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-GateLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$stamp] [MIRROR_SecretGate] [$Level] $Message"
}

function Normalize-HitLine {
    param([string]$Line)

    if (-not $Line) {
        return $null
    }
    if ($Line -match "^(.*?):([0-9]+):") {
        return ("{0}:{1}" -f $Matches[1], $Matches[2])
    }
    return $null
}

function Invoke-PatternScan {
    param(
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string[]]$ExcludeSpecs,
        [switch]$Cached
    )

    $args = @("grep")
    if ($Cached) {
        $args += "--cached"
    }
    $args += @("-n", "-I", "-E", "--", $Pattern, "--", ".")
    $args += $ExcludeSpecs

    $lines = & git @args 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 1) {
        return @()
    }
    if ($exitCode -ne 0) {
        throw ("git grep failed for pattern [{0}] with exit code {1}" -f $Pattern, $exitCode)
    }

    return @($lines)
}

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $RootPath) {
    $RootPath = Split-Path -Parent $scriptRoot
}

if (-not (Test-Path -LiteralPath $RootPath)) {
    throw "Root path not found: $RootPath"
}

$excludeSpecs = @(
    ":(exclude)tools/MIRROR_SecretGate.ps1",
    ":(exclude)tools/MIRROR_Push.ps1",
    ":(exclude)tools/Mason_Secrets_Scan.ps1",
    ":(exclude)tools/Secret_Leak_Scan.ps1"
)

$patterns = @(
    "sk-proj-",
    "sk-[A-Za-z0-9]{20,}",
    "BEGIN( RSA| EC| OPENSSH| DSA)? PRIVATE KEY",
    "(ghp_|gho_|ghu_|ghs_|github_pat_)"
)

Push-Location $RootPath
try {
    & git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Not a git repository: $RootPath"
    }

    $hits = @{}
    foreach ($pattern in $patterns) {
        $resultLines = Invoke-PatternScan -Pattern $pattern -ExcludeSpecs $excludeSpecs -Cached:$Cached
        foreach ($line in $resultLines) {
            $hit = Normalize-HitLine -Line ([string]$line)
            if ($hit) {
                $hits[$hit] = $true
            }
        }
    }

    if ($hits.Count -gt 0) {
        Write-GateLog "BLOCKED: secret-like patterns detected in tracked files." "ERROR"
        foreach ($entry in @($hits.Keys | Sort-Object)) {
            Write-Host $entry
        }
        exit 1
    }

    Write-GateLog "PASS: no secret-like patterns found."
    exit 0
}
finally {
    Pop-Location
}
