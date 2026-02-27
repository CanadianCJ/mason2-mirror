[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$CommitMessage = "",
    [switch]$NoPush
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-PushLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$stamp] [MIRROR_Push] [$Level] $Message"
}

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $RootPath) {
    $RootPath = Split-Path -Parent $scriptRoot
}

$secretGatePath = Join-Path $RootPath "tools\MIRROR_SecretGate.ps1"
if (-not (Test-Path -LiteralPath $secretGatePath)) {
    throw "Secret gate script not found: $secretGatePath"
}

$psExe = (Get-Command powershell.exe -ErrorAction SilentlyContinue).Source
if (-not $psExe) {
    $psExe = "powershell.exe"
}

$sourceRoot = Join-Path (Split-Path -Parent $RootPath) "Mason2"
$mirrorManifestScript = Join-Path $sourceRoot "tools\Write_MirrorManifest.ps1"

Push-Location $RootPath
try {
    if (Test-Path -LiteralPath $mirrorManifestScript) {
        Write-PushLog "Refreshing source mirror manifest..."
        & $psExe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $mirrorManifestScript -RootPath $sourceRoot -MirrorPath $RootPath
        if ($LASTEXITCODE -ne 0) {
            throw "Write_MirrorManifest.ps1 failed."
        }
    }
    else {
        Write-PushLog "Write_MirrorManifest.ps1 not found; continuing without manifest refresh." "WARN"
    }

    & git rev-parse --is-inside-work-tree *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Not a git repository: $RootPath"
    }

    Write-PushLog "Staging changes (git add -A)..."
    & git add -A
    if ($LASTEXITCODE -ne 0) {
        throw "git add failed."
    }

    Write-PushLog "Running MIRROR_SecretGate against staged content..."
    & $psExe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $secretGatePath -RootPath $RootPath -Cached
    $gateExit = $LASTEXITCODE
    if ($gateExit -ne 0) {
        Write-PushLog "Push blocked by secret gate." "ERROR"
        exit 1
    }

    & git diff --cached --quiet --exit-code
    $diffExit = $LASTEXITCODE
    if ($diffExit -gt 1) {
        throw "git diff --cached failed."
    }
    $hasStagedChanges = ($diffExit -eq 1)

    if ($hasStagedChanges) {
        if (-not $CommitMessage) {
            $CommitMessage = "mirror guardrails update $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        }
        Write-PushLog ("Committing staged changes: {0}" -f $CommitMessage)
        & git commit -m $CommitMessage
        if ($LASTEXITCODE -ne 0) {
            throw "git commit failed."
        }
    }
    else {
        Write-PushLog "No staged changes to commit."
    }

    if ($NoPush) {
        Write-PushLog "NoPush set; skipping git push."
        exit 0
    }

    Write-PushLog "Pushing..."
    & git push
    if ($LASTEXITCODE -ne 0) {
        throw "git push failed."
    }

    Write-PushLog "Push complete."
    exit 0
}
finally {
    Pop-Location
}
