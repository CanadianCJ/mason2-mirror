# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=2)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$per = Join-Path $Base 'logs\per'
New-Item -ItemType Directory -Force -Path $per | Out-Null
if(-not (Test-Path $src)){ exit 0 }
Get-Content $src -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $k = if($j.file){ $j.file } else { 'unknown' }
  $safe = ($k -replace '[^\w\.-]','_')
  $out = Join-Path $per ($safe + '.jsonl')
  Write-JsonLineSafe -Path $out -Obj $j
  try{
    $mb = [math]::Round((Get-Item $out).Length/1MB,2)
    if($mb -ge $MaxMB){
      $stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item $out (Join-Path $per ($safe + "." + $stamp + ".jsonl")) -Force
    }
  }catch{}
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=2)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$per = Join-Path $Base 'logs\per'
New-Item -ItemType Directory -Force -Path $per | Out-Null
if(-not (Test-Path $src)){ exit 0 }
Get-Content $src -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $k = if($j.file){ $j.file } else { 'unknown' }
  $safe = ($k -replace '[^\w\.-]','_')
  $out = Join-Path $per ($safe + '.jsonl')
  Write-JsonLineSafe -Path $out -Obj $j
  try{
    $mb = [math]::Round((Get-Item $out).Length/1MB,2)
    if($mb -ge $MaxMB){
      $stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item $out (Join-Path $per ($safe + "." + $stamp + ".jsonl")) -Force
    }
  }catch{}
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=2)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$per = Join-Path $Base 'logs\per'
New-Item -ItemType Directory -Force -Path $per | Out-Null
if(-not (Test-Path $src)){ exit 0 }
Get-Content $src -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $k = if($j.file){ $j.file } else { 'unknown' }
  $safe = ($k -replace '[^\w\.-]','_')
  $out = Join-Path $per ($safe + '.jsonl')
  Write-JsonLineSafe -Path $out -Obj $j
  try{
    $mb = [math]::Round((Get-Item $out).Length/1MB,2)
    if($mb -ge $MaxMB){
      $stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item $out (Join-Path $per ($safe + "." + $stamp + ".jsonl")) -Force
    }
  }catch{}
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=2)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$per = Join-Path $Base 'logs\per'
New-Item -ItemType Directory -Force -Path $per | Out-Null
if(-not (Test-Path $src)){ exit 0 }
Get-Content $src -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $k = if($j.file){ $j.file } else { 'unknown' }
  $safe = ($k -replace '[^\w\.-]','_')
  $out = Join-Path $per ($safe + '.jsonl')
  Write-JsonLineSafe -Path $out -Obj $j
  try{
    $mb = [math]::Round((Get-Item $out).Length/1MB,2)
    if($mb -ge $MaxMB){
      $stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item $out (Join-Path $per ($safe + "." + $stamp + ".jsonl")) -Force
    }
  }catch{}
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=2)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$per = Join-Path $Base 'logs\per'
New-Item -ItemType Directory -Force -Path $per | Out-Null
if(-not (Test-Path $src)){ exit 0 }
Get-Content $src -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $k = if($j.file){ $j.file } else { 'unknown' }
  $safe = ($k -replace '[^\w\.-]','_')
  $out = Join-Path $per ($safe + '.jsonl')
  Write-JsonLineSafe -Path $out -Obj $j
  try{
    $mb = [math]::Round((Get-Item $out).Length/1MB,2)
    if($mb -ge $MaxMB){
      $stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item $out (Join-Path $per ($safe + "." + $stamp + ".jsonl")) -Force
    }
  }catch{}
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=2)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$per = Join-Path $Base 'logs\per'
New-Item -ItemType Directory -Force -Path $per | Out-Null
if(-not (Test-Path $src)){ exit 0 }
Get-Content $src -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $k = if($j.file){ $j.file } else { 'unknown' }
  $safe = ($k -replace '[^\w\.-]','_')
  $out = Join-Path $per ($safe + '.jsonl')
  Write-JsonLineSafe -Path $out -Obj $j
  try{
    $mb = [math]::Round((Get-Item $out).Length/1MB,2)
    if($mb -ge $MaxMB){
      $stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item $out (Join-Path $per ($safe + "." + $stamp + ".jsonl")) -Force
    }
  }catch{}
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=2)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$per = Join-Path $Base 'logs\per'
New-Item -ItemType Directory -Force -Path $per | Out-Null
if(-not (Test-Path $src)){ exit 0 }
Get-Content $src -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $k = if($j.file){ $j.file } else { 'unknown' }
  $safe = ($k -replace '[^\w\.-]','_')
  $out = Join-Path $per ($safe + '.jsonl')
  Write-JsonLineSafe -Path $out -Obj $j
  try{
    $mb = [math]::Round((Get-Item $out).Length/1MB,2)
    if($mb -ge $MaxMB){
      $stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item $out (Join-Path $per ($safe + "." + $stamp + ".jsonl")) -Force
    }
  }catch{}
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=2)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$per = Join-Path $Base 'logs\per'
New-Item -ItemType Directory -Force -Path $per | Out-Null
if(-not (Test-Path $src)){ exit 0 }
Get-Content $src -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $k = if($j.file){ $j.file } else { 'unknown' }
  $safe = ($k -replace '[^\w\.-]','_')
  $out = Join-Path $per ($safe + '.jsonl')
  Write-JsonLineSafe -Path $out -Obj $j
  try{
    $mb = [math]::Round((Get-Item $out).Length/1MB,2)
    if($mb -ge $MaxMB){
      $stamp=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item $out (Join-Path $per ($safe + "." + $stamp + ".jsonl")) -Force
    }
  }catch{}
}

