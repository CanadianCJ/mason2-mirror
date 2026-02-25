$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0; $files=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
      $files++
      try{ $bytes += $_.Length }catch{}
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin'; files=$files; size_mb=[math]::Round($bytes/1MB,2)
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0; $files=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
      $files++
      try{ $bytes += $_.Length }catch{}
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin'; files=$files; size_mb=[math]::Round($bytes/1MB,2)
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0; $files=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
      $files++
      try{ $bytes += $_.Length }catch{}
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin'; files=$files; size_mb=[math]::Round($bytes/1MB,2)
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0; $files=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
      $files++
      try{ $bytes += $_.Length }catch{}
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin'; files=$files; size_mb=[math]::Round($bytes/1MB,2)
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0; $files=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
      $files++
      try{ $bytes += $_.Length }catch{}
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin'; files=$files; size_mb=[math]::Round($bytes/1MB,2)
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0; $files=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
      $files++
      try{ $bytes += $_.Length }catch{}
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin'; files=$files; size_mb=[math]::Round($bytes/1MB,2)
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0; $files=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
      $files++
      try{ $bytes += $_.Length }catch{}
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin'; files=$files; size_mb=[math]::Round($bytes/1MB,2)
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0; $files=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
      $files++
      try{ $bytes += $_.Length }catch{}
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin'; files=$files; size_mb=[math]::Round($bytes/1MB,2)
}
