[CmdletBinding()]
param()

$root = Split-Path $PSScriptRoot -Parent

# Block obvious secret files
$bad = Get-ChildItem $root -Recurse -File -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -match '^\.env' -or $_.Name -match 'secrets.*\.json$' }

if ($bad) {
  Write-Host "[MIRROR_SecretGate] FAIL: Potential secret files detected:"
  $bad.FullName | Sort-Object -Unique | ForEach-Object { Write-Host " - $_" }
  exit 2
}

Write-Host "[MIRROR_SecretGate] OK"
exit 0
