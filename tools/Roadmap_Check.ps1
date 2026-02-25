# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root=$Base; $rep=Join-Path $Base 'reports'
$files = Get-ChildItem -LiteralPath $root -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $clean = ($f.Name -replace '^\s+|\s+$','')
  if($clean -ne $f.Name){
    $dest = Join-Path $f.DirectoryName $clean
    Move-Item -LiteralPath $f.FullName -Destination $dest -Force
    $f = Get-Item $dest
  }
  try{ $h=Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 }catch{ continue }
  Write-JsonLineSafe -Path (Join-Path $rep 'roadmap_hash.jsonl') -Obj @{
    ts=(Get-Date).ToString('s'); file=$f.FullName; sha256=$h.Hash; size=$f.Length
  }
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root=$Base; $rep=Join-Path $Base 'reports'
$files = Get-ChildItem -LiteralPath $root -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $clean = ($f.Name -replace '^\s+|\s+$','')
  if($clean -ne $f.Name){
    $dest = Join-Path $f.DirectoryName $clean
    Move-Item -LiteralPath $f.FullName -Destination $dest -Force
    $f = Get-Item $dest
  }
  try{ $h=Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 }catch{ continue }
  Write-JsonLineSafe -Path (Join-Path $rep 'roadmap_hash.jsonl') -Obj @{
    ts=(Get-Date).ToString('s'); file=$f.FullName; sha256=$h.Hash; size=$f.Length
  }
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root=$Base; $rep=Join-Path $Base 'reports'
$files = Get-ChildItem -LiteralPath $root -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $clean = ($f.Name -replace '^\s+|\s+$','')
  if($clean -ne $f.Name){
    $dest = Join-Path $f.DirectoryName $clean
    Move-Item -LiteralPath $f.FullName -Destination $dest -Force
    $f = Get-Item $dest
  }
  try{ $h=Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 }catch{ continue }
  Write-JsonLineSafe -Path (Join-Path $rep 'roadmap_hash.jsonl') -Obj @{
    ts=(Get-Date).ToString('s'); file=$f.FullName; sha256=$h.Hash; size=$f.Length
  }
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root=$Base; $rep=Join-Path $Base 'reports'
$files = Get-ChildItem -LiteralPath $root -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $clean = ($f.Name -replace '^\s+|\s+$','')
  if($clean -ne $f.Name){
    $dest = Join-Path $f.DirectoryName $clean
    Move-Item -LiteralPath $f.FullName -Destination $dest -Force
    $f = Get-Item $dest
  }
  try{ $h=Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 }catch{ continue }
  Write-JsonLineSafe -Path (Join-Path $rep 'roadmap_hash.jsonl') -Obj @{
    ts=(Get-Date).ToString('s'); file=$f.FullName; sha256=$h.Hash; size=$f.Length
  }
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root=$Base; $rep=Join-Path $Base 'reports'
$files = Get-ChildItem -LiteralPath $root -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $clean = ($f.Name -replace '^\s+|\s+$','')
  if($clean -ne $f.Name){
    $dest = Join-Path $f.DirectoryName $clean
    Move-Item -LiteralPath $f.FullName -Destination $dest -Force
    $f = Get-Item $dest
  }
  try{ $h=Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 }catch{ continue }
  Write-JsonLineSafe -Path (Join-Path $rep 'roadmap_hash.jsonl') -Obj @{
    ts=(Get-Date).ToString('s'); file=$f.FullName; sha256=$h.Hash; size=$f.Length
  }
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root=$Base; $rep=Join-Path $Base 'reports'
$files = Get-ChildItem -LiteralPath $root -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $clean = ($f.Name -replace '^\s+|\s+$','')
  if($clean -ne $f.Name){
    $dest = Join-Path $f.DirectoryName $clean
    Move-Item -LiteralPath $f.FullName -Destination $dest -Force
    $f = Get-Item $dest
  }
  try{ $h=Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 }catch{ continue }
  Write-JsonLineSafe -Path (Join-Path $rep 'roadmap_hash.jsonl') -Obj @{
    ts=(Get-Date).ToString('s'); file=$f.FullName; sha256=$h.Hash; size=$f.Length
  }
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root=$Base; $rep=Join-Path $Base 'reports'
$files = Get-ChildItem -LiteralPath $root -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $clean = ($f.Name -replace '^\s+|\s+$','')
  if($clean -ne $f.Name){
    $dest = Join-Path $f.DirectoryName $clean
    Move-Item -LiteralPath $f.FullName -Destination $dest -Force
    $f = Get-Item $dest
  }
  try{ $h=Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 }catch{ continue }
  Write-JsonLineSafe -Path (Join-Path $rep 'roadmap_hash.jsonl') -Obj @{
    ts=(Get-Date).ToString('s'); file=$f.FullName; sha256=$h.Hash; size=$f.Length
  }
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root=$Base; $rep=Join-Path $Base 'reports'
$files = Get-ChildItem -LiteralPath $root -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $clean = ($f.Name -replace '^\s+|\s+$','')
  if($clean -ne $f.Name){
    $dest = Join-Path $f.DirectoryName $clean
    Move-Item -LiteralPath $f.FullName -Destination $dest -Force
    $f = Get-Item $dest
  }
  try{ $h=Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 }catch{ continue }
  Write-JsonLineSafe -Path (Join-Path $rep 'roadmap_hash.jsonl') -Obj @{
    ts=(Get-Date).ToString('s'); file=$f.FullName; sha256=$h.Hash; size=$f.Length
  }
}

