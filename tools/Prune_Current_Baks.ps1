$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $root=Join-Path $Base 'dist'
$dirs = Get-ChildItem -LiteralPath $root -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$rm = @()
if($dirs.Count -gt $Keep){
  $rm = $dirs | Select-Object -Skip $Keep
  foreach($d in $rm){ try{ Remove-Item -Recurse -Force -LiteralPath $d.FullName }catch{} }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ ts=$now.ToString('s'); kind='prune_current_baks'; kept=[int]([math]::Min($dirs.Count,$Keep)); removed=$rm.Count }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Keep=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $root=Join-Path $Base 'dist'
$dirs = Get-ChildItem -LiteralPath $root -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$rm = @()
if($dirs.Count -gt $Keep){
  $rm = $dirs | Select-Object -Skip $Keep
  foreach($d in $rm){ try{ Remove-Item -Recurse -Force -LiteralPath $d.FullName }catch{} }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ ts=$now.ToString('s'); kind='prune_current_baks'; kept=[int]([math]::Min($dirs.Count,$Keep)); removed=$rm.Count }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Keep=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $root=Join-Path $Base 'dist'
$dirs = Get-ChildItem -LiteralPath $root -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$rm = @()
if($dirs.Count -gt $Keep){
  $rm = $dirs | Select-Object -Skip $Keep
  foreach($d in $rm){ try{ Remove-Item -Recurse -Force -LiteralPath $d.FullName }catch{} }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ ts=$now.ToString('s'); kind='prune_current_baks'; kept=[int]([math]::Min($dirs.Count,$Keep)); removed=$rm.Count }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Keep=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $root=Join-Path $Base 'dist'
$dirs = Get-ChildItem -LiteralPath $root -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$rm = @()
if($dirs.Count -gt $Keep){
  $rm = $dirs | Select-Object -Skip $Keep
  foreach($d in $rm){ try{ Remove-Item -Recurse -Force -LiteralPath $d.FullName }catch{} }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ ts=$now.ToString('s'); kind='prune_current_baks'; kept=[int]([math]::Min($dirs.Count,$Keep)); removed=$rm.Count }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Keep=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $root=Join-Path $Base 'dist'
$dirs = Get-ChildItem -LiteralPath $root -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$rm = @()
if($dirs.Count -gt $Keep){
  $rm = $dirs | Select-Object -Skip $Keep
  foreach($d in $rm){ try{ Remove-Item -Recurse -Force -LiteralPath $d.FullName }catch{} }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ ts=$now.ToString('s'); kind='prune_current_baks'; kept=[int]([math]::Min($dirs.Count,$Keep)); removed=$rm.Count }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Keep=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $root=Join-Path $Base 'dist'
$dirs = Get-ChildItem -LiteralPath $root -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$rm = @()
if($dirs.Count -gt $Keep){
  $rm = $dirs | Select-Object -Skip $Keep
  foreach($d in $rm){ try{ Remove-Item -Recurse -Force -LiteralPath $d.FullName }catch{} }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ ts=$now.ToString('s'); kind='prune_current_baks'; kept=[int]([math]::Min($dirs.Count,$Keep)); removed=$rm.Count }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Keep=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $root=Join-Path $Base 'dist'
$dirs = Get-ChildItem -LiteralPath $root -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$rm = @()
if($dirs.Count -gt $Keep){
  $rm = $dirs | Select-Object -Skip $Keep
  foreach($d in $rm){ try{ Remove-Item -Recurse -Force -LiteralPath $d.FullName }catch{} }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ ts=$now.ToString('s'); kind='prune_current_baks'; kept=[int]([math]::Min($dirs.Count,$Keep)); removed=$rm.Count }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $root=Join-Path $Base 'dist'
$dirs = Get-ChildItem -LiteralPath $root -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$rm = @()
if($dirs.Count -gt $Keep){
  $rm = $dirs | Select-Object -Skip $Keep
  foreach($d in $rm){ try{ Remove-Item -Recurse -Force -LiteralPath $d.FullName }catch{} }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ ts=$now.ToString('s'); kind='prune_current_baks'; kept=[int]([math]::Min($dirs.Count,$Keep)); removed=$rm.Count }
