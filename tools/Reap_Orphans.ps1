$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root = Join-Path $Base 'dist\current'
if(-not (Test-Path $root)){ exit 0 }
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
  try{ $_.Path -and $_.Path -like (Join-Path $root '*') }catch{ $false }
}
foreach($p in $procs){
  $act = if($Kill){ 'kill' } else { 'report' }
  if($Kill){ try{ Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }catch{} }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\orphans.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='orphan'; pid=$p.Id; name=$p.ProcessName; path=$p.Path; action=$act }
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[switch]$Kill)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root = Join-Path $Base 'dist\current'
if(-not (Test-Path $root)){ exit 0 }
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
  try{ $_.Path -and $_.Path -like (Join-Path $root '*') }catch{ $false }
}
foreach($p in $procs){
  $act = if($Kill){ 'kill' } else { 'report' }
  if($Kill){ try{ Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }catch{} }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\orphans.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='orphan'; pid=$p.Id; name=$p.ProcessName; path=$p.Path; action=$act }
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[switch]$Kill)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root = Join-Path $Base 'dist\current'
if(-not (Test-Path $root)){ exit 0 }
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
  try{ $_.Path -and $_.Path -like (Join-Path $root '*') }catch{ $false }
}
foreach($p in $procs){
  $act = if($Kill){ 'kill' } else { 'report' }
  if($Kill){ try{ Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }catch{} }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\orphans.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='orphan'; pid=$p.Id; name=$p.ProcessName; path=$p.Path; action=$act }
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[switch]$Kill)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root = Join-Path $Base 'dist\current'
if(-not (Test-Path $root)){ exit 0 }
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
  try{ $_.Path -and $_.Path -like (Join-Path $root '*') }catch{ $false }
}
foreach($p in $procs){
  $act = if($Kill){ 'kill' } else { 'report' }
  if($Kill){ try{ Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }catch{} }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\orphans.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='orphan'; pid=$p.Id; name=$p.ProcessName; path=$p.Path; action=$act }
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[switch]$Kill)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root = Join-Path $Base 'dist\current'
if(-not (Test-Path $root)){ exit 0 }
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
  try{ $_.Path -and $_.Path -like (Join-Path $root '*') }catch{ $false }
}
foreach($p in $procs){
  $act = if($Kill){ 'kill' } else { 'report' }
  if($Kill){ try{ Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }catch{} }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\orphans.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='orphan'; pid=$p.Id; name=$p.ProcessName; path=$p.Path; action=$act }
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[switch]$Kill)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root = Join-Path $Base 'dist\current'
if(-not (Test-Path $root)){ exit 0 }
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
  try{ $_.Path -and $_.Path -like (Join-Path $root '*') }catch{ $false }
}
foreach($p in $procs){
  $act = if($Kill){ 'kill' } else { 'report' }
  if($Kill){ try{ Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }catch{} }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\orphans.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='orphan'; pid=$p.Id; name=$p.ProcessName; path=$p.Path; action=$act }
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[switch]$Kill)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root = Join-Path $Base 'dist\current'
if(-not (Test-Path $root)){ exit 0 }
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
  try{ $_.Path -and $_.Path -like (Join-Path $root '*') }catch{ $false }
}
foreach($p in $procs){
  $act = if($Kill){ 'kill' } else { 'report' }
  if($Kill){ try{ Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }catch{} }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\orphans.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='orphan'; pid=$p.Id; name=$p.ProcessName; path=$p.Path; action=$act }
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$root = Join-Path $Base 'dist\current'
if(-not (Test-Path $root)){ exit 0 }
$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
  try{ $_.Path -and $_.Path -like (Join-Path $root '*') }catch{ $false }
}
foreach($p in $procs){
  $act = if($Kill){ 'kill' } else { 'report' }
  if($Kill){ try{ Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }catch{} }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\orphans.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='orphan'; pid=$p.Id; name=$p.ProcessName; path=$p.Path; action=$act }
}
