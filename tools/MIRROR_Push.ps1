[CmdletBinding()]
param(
  [string]$CommitMessage = "mirror: manual-sync"
)

$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

# Stage
git add -A | Out-Null

# No changes -> ok
$dirty = git status --porcelain
if (-not $dirty) {
  Write-Host "[MIRROR_Push] OK: nothing to push."
  exit 0
}

# Gate (must pass)
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "$root\tools\MIRROR_SecretGate.ps1"
if ($LASTEXITCODE -ne 0) {
  Write-Host "[MIRROR_Push] FAIL: SecretGate blocked."
  exit 2
}

# Commit + push
git commit -m $CommitMessage | Out-Null
git push origin main
if ($LASTEXITCODE -ne 0) { exit 3 }

Write-Host "[MIRROR_Push] OK: pushed."
exit 0
