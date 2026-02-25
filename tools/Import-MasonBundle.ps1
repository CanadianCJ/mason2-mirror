param(
  [Parameter(Mandatory)] [string] $BundleZip,
  [string] $Target = $env:MASON2_BASE
)

$work = Join-Path ([IO.Path]::GetDirectoryName($BundleZip)) ("unpack_" + [IO.Path]::GetFileNameWithoutExtension($BundleZip))
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Force $work | Out-Null

Expand-Archive -Path $BundleZip -DestinationPath $work -Force
$man = Get-Content (Join-Path $work 'manifest.json') -Raw | ConvertFrom-Json

$bad = @()
foreach($f in $man.files){
  $p = Join-Path $work $f.path
  if(-not (Test-Path $p)){ $bad += "missing: $($f.path)"; continue }
  $sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLower()
  if($sha -ne $f.sha256){ $bad += "hash mismatch: $($f.path)" }
}
if($bad.Count -gt 0){
  Write-Error "Integrity check failed:`n$($bad -join "`n")"
  exit 1
}

# Atomic-ish swap: copy on top (leaves logs/reports)
Get-ChildItem -LiteralPath $work -Recurse -File | ForEach-Object {
  $rel = $_.FullName -replace [regex]::Escape($work + '\'), ''
  $dst = Join-Path $Target $rel
  New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($dst)) | Out-Null
  Copy-Item $_.FullName $dst -Force
}
Write-Host "Deployed bundle version: $($man.mason_version)"
