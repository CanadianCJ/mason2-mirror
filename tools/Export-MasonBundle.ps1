param(
  [string]$OutDir = (Join-Path $env:MASON2_BASE "bundles"),
  [string]$Version = (Get-Date -Format "yyyy.MM.dd.HHmm")
)

$Base=$env:MASON2_BASE
New-Item -ItemType Directory -Force $OutDir | Out-Null
$stg = Join-Path $OutDir ("stage_" + $Version)
$zip = Join-Path $OutDir ("Mason2_" + $Version + ".zip")
Remove-Item $stg,$zip -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Force $stg | Out-Null

# copy core tree (exclude logs/reports/bundles)
$ex = @('logs','reports','bundles')
Get-ChildItem -LiteralPath $Base -Recurse | Where-Object {
  -not ($_.PSIsContainer -and $ex -contains $_.Name) -and
  ($_.FullName -notlike "*\logs\*") -and
  ($_.FullName -notlike "*\reports\*") -and
  ($_.FullName -notlike "*\bundles\*")
} | Copy-Item -Destination { $_.FullName -replace [regex]::Escape($Base), $stg } -Force

# build manifest (sha256)
$manifest = @()
Get-ChildItem -LiteralPath $stg -Recurse -File | ForEach-Object {
  $rel = $_.FullName -replace [regex]::Escape($stg + '\'), ''
  $sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLower()
  $manifest += [pscustomobject]@{ path=$rel; sha256=$sha; bytes=$_.Length }
}
$meta = [pscustomobject]@{
  mason_version = $Version
  created_utc   = [DateTime]::UtcNow.ToString("s")
  files         = $manifest
}
$meta | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $stg 'manifest.json')

Compress-Archive -Path (Join-Path $stg '*') -DestinationPath $zip -Force
Write-Host "Bundle created: $zip"
