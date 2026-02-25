# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$roots = @('reports','roadmap','config')
$patterns = @('sk-[A-Za-z0-9]{20,}','AKIA[0-9A-Z]{16}','QT_[A-Z_]+','xox[baprs]-[A-Za-z0-9-]{10,}')
$now=Get-Date
foreach($r in $roots){
  $root = Join-Path $Base $r
  if(-not (Test-Path $root)){ continue }
  Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $hit = $false
    try{
      $i=0
      Get-Content $_.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        $i++
        foreach($p in $patterns){
          if($_ -match $p){ $hit=$true; Write-JsonLineSafe -Path (Join-Path $Base 'reports\secret_leaks.jsonl') -Obj @{ ts=$now.ToString('s'); kind='secret_scan'; file=$_.PSPath; line=$i; pattern=$p } }
        }
      }
    }catch{}
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
$roots = @('reports','roadmap','config')
$patterns = @('sk-[A-Za-z0-9]{20,}','AKIA[0-9A-Z]{16}','QT_[A-Z_]+','xox[baprs]-[A-Za-z0-9-]{10,}')
$now=Get-Date
foreach($r in $roots){
  $root = Join-Path $Base $r
  if(-not (Test-Path $root)){ continue }
  Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $hit = $false
    try{
      $i=0
      Get-Content $_.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        $i++
        foreach($p in $patterns){
          if($_ -match $p){ $hit=$true; Write-JsonLineSafe -Path (Join-Path $Base 'reports\secret_leaks.jsonl') -Obj @{ ts=$now.ToString('s'); kind='secret_scan'; file=$_.PSPath; line=$i; pattern=$p } }
        }
      }
    }catch{}
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
$roots = @('reports','roadmap','config')
$patterns = @('sk-[A-Za-z0-9]{20,}','AKIA[0-9A-Z]{16}','QT_[A-Z_]+','xox[baprs]-[A-Za-z0-9-]{10,}')
$now=Get-Date
foreach($r in $roots){
  $root = Join-Path $Base $r
  if(-not (Test-Path $root)){ continue }
  Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $hit = $false
    try{
      $i=0
      Get-Content $_.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        $i++
        foreach($p in $patterns){
          if($_ -match $p){ $hit=$true; Write-JsonLineSafe -Path (Join-Path $Base 'reports\secret_leaks.jsonl') -Obj @{ ts=$now.ToString('s'); kind='secret_scan'; file=$_.PSPath; line=$i; pattern=$p } }
        }
      }
    }catch{}
  }
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$roots = @('reports','roadmap','config')
$patterns = @('sk-[A-Za-z0-9]{20,}','AKIA[0-9A-Z]{16}','QT_[A-Z_]+','xox[baprs]-[A-Za-z0-9-]{10,}')
$now=Get-Date
foreach($r in $roots){
  $root = Join-Path $Base $r
  if(-not (Test-Path $root)){ continue }
  Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $hit = $false
    try{
      $i=0
      Get-Content $_.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        $i++
        foreach($p in $patterns){
          if($_ -match $p){ $hit=$true; Write-JsonLineSafe -Path (Join-Path $Base 'reports\secret_leaks.jsonl') -Obj @{ ts=$now.ToString('s'); kind='secret_scan'; file=$_.PSPath; line=$i; pattern=$p } }
        }
      }
    }catch{}
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
$roots = @('reports','roadmap','config')
$patterns = @('sk-[A-Za-z0-9]{20,}','AKIA[0-9A-Z]{16}','QT_[A-Z_]+','xox[baprs]-[A-Za-z0-9-]{10,}')
$now=Get-Date
foreach($r in $roots){
  $root = Join-Path $Base $r
  if(-not (Test-Path $root)){ continue }
  Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $hit = $false
    try{
      $i=0
      Get-Content $_.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        $i++
        foreach($p in $patterns){
          if($_ -match $p){ $hit=$true; Write-JsonLineSafe -Path (Join-Path $Base 'reports\secret_leaks.jsonl') -Obj @{ ts=$now.ToString('s'); kind='secret_scan'; file=$_.PSPath; line=$i; pattern=$p } }
        }
      }
    }catch{}
  }
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$roots = @('reports','roadmap','config')
$patterns = @('sk-[A-Za-z0-9]{20,}','AKIA[0-9A-Z]{16}','QT_[A-Z_]+','xox[baprs]-[A-Za-z0-9-]{10,}')
$now=Get-Date
foreach($r in $roots){
  $root = Join-Path $Base $r
  if(-not (Test-Path $root)){ continue }
  Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $hit = $false
    try{
      $i=0
      Get-Content $_.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        $i++
        foreach($p in $patterns){
          if($_ -match $p){ $hit=$true; Write-JsonLineSafe -Path (Join-Path $Base 'reports\secret_leaks.jsonl') -Obj @{ ts=$now.ToString('s'); kind='secret_scan'; file=$_.PSPath; line=$i; pattern=$p } }
        }
      }
    }catch{}
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
$roots = @('reports','roadmap','config')
$patterns = @('sk-[A-Za-z0-9]{20,}','AKIA[0-9A-Z]{16}','QT_[A-Z_]+','xox[baprs]-[A-Za-z0-9-]{10,}')
$now=Get-Date
foreach($r in $roots){
  $root = Join-Path $Base $r
  if(-not (Test-Path $root)){ continue }
  Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $hit = $false
    try{
      $i=0
      Get-Content $_.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        $i++
        foreach($p in $patterns){
          if($_ -match $p){ $hit=$true; Write-JsonLineSafe -Path (Join-Path $Base 'reports\secret_leaks.jsonl') -Obj @{ ts=$now.ToString('s'); kind='secret_scan'; file=$_.PSPath; line=$i; pattern=$p } }
        }
      }
    }catch{}
  }
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$roots = @('reports','roadmap','config')
$patterns = @('sk-[A-Za-z0-9]{20,}','AKIA[0-9A-Z]{16}','QT_[A-Z_]+','xox[baprs]-[A-Za-z0-9-]{10,}')
$now=Get-Date
foreach($r in $roots){
  $root = Join-Path $Base $r
  if(-not (Test-Path $root)){ continue }
  Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
    $hit = $false
    try{
      $i=0
      Get-Content $_.FullName -ErrorAction SilentlyContinue | ForEach-Object {
        $i++
        foreach($p in $patterns){
          if($_ -match $p){ $hit=$true; Write-JsonLineSafe -Path (Join-Path $Base 'reports\secret_leaks.jsonl') -Obj @{ ts=$now.ToString('s'); kind='secret_scan'; file=$_.PSPath; line=$i; pattern=$p } }
        }
      }
    }catch{}
  }
}

