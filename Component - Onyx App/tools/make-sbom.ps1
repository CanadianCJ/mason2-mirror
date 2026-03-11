$ErrorActionPreference="Stop"
$ROOT = Join-Path $env:USERPROFILE "Desktop\ONYX"
$OUT  = Join-Path $ROOT "security\sbom"
New-Item -ItemType Directory -Path $OUT -EA SilentlyContinue | Out-Null

# Syft: SPDX JSON for workspace
try {
  syft dir:$ROOT -o spdx-json > (Join-Path $OUT "workspace.spdx.json")
  Write-Host "SBOM written: $($OUT)\workspace.spdx.json"
} catch { Write-Warning "Syft failed (install via scoop syft)"; }

# Trivy: vuln + secret + config scan
try {
  trivy fs --scanners vuln,secret,config --severity HIGH,CRITICAL --exit-code 0 $ROOT `
    | Tee-Object -FilePath (Join-Path $OUT "trivy_fs_latest.txt") | Out-Null
  Write-Host "Trivy report: $($OUT)\trivy_fs_latest.txt"
} catch { Write-Warning "Trivy failed (install via scoop trivy)"; }
