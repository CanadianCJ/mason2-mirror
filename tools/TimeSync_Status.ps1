# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $src=$null; $offset=$null; $ok=$true
try{
  $out = (& w32tm /query /status 2>$null) -as [string[]]
  if($out){
    foreach($ln in $out){
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $offset=[double]$Matches[1] }
    }
  }
}catch{ $ok=$false }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timesync.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timesync'; source=$src; offset_s=$offset; ok=$ok }

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $src=$null; $offset=$null; $ok=$true
try{
  $out = (& w32tm /query /status 2>$null) -as [string[]]
  if($out){
    foreach($ln in $out){
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $offset=[double]$Matches[1] }
    }
  }
}catch{ $ok=$false }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timesync.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timesync'; source=$src; offset_s=$offset; ok=$ok }

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $src=$null; $offset=$null; $ok=$true
try{
  $out = (& w32tm /query /status 2>$null) -as [string[]]
  if($out){
    foreach($ln in $out){
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $offset=[double]$Matches[1] }
    }
  }
}catch{ $ok=$false }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timesync.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timesync'; source=$src; offset_s=$offset; ok=$ok }

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $src=$null; $offset=$null; $ok=$true
try{
  $out = (& w32tm /query /status 2>$null) -as [string[]]
  if($out){
    foreach($ln in $out){
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $offset=[double]$Matches[1] }
    }
  }
}catch{ $ok=$false }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timesync.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timesync'; source=$src; offset_s=$offset; ok=$ok }

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $src=$null; $offset=$null; $ok=$true
try{
  $out = (& w32tm /query /status 2>$null) -as [string[]]
  if($out){
    foreach($ln in $out){
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $offset=[double]$Matches[1] }
    }
  }
}catch{ $ok=$false }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timesync.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timesync'; source=$src; offset_s=$offset; ok=$ok }

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $src=$null; $offset=$null; $ok=$true
try{
  $out = (& w32tm /query /status 2>$null) -as [string[]]
  if($out){
    foreach($ln in $out){
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $offset=[double]$Matches[1] }
    }
  }
}catch{ $ok=$false }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timesync.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timesync'; source=$src; offset_s=$offset; ok=$ok }

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $src=$null; $offset=$null; $ok=$true
try{
  $out = (& w32tm /query /status 2>$null) -as [string[]]
  if($out){
    foreach($ln in $out){
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $offset=[double]$Matches[1] }
    }
  }
}catch{ $ok=$false }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timesync.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timesync'; source=$src; offset_s=$offset; ok=$ok }

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $src=$null; $offset=$null; $ok=$true
try{
  $out = (& w32tm /query /status 2>$null) -as [string[]]
  if($out){
    foreach($ln in $out){
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $offset=[double]$Matches[1] }
    }
  }
}catch{ $ok=$false }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timesync.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timesync'; source=$src; offset_s=$offset; ok=$ok }

