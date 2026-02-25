$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$dir = Join-Path $Base 'crashdumps'
$now=Get-Date
$cnt=0; $latest=$null; $latestMB=$null
if(Test-Path $dir){
  $f = Get-ChildItem -LiteralPath $dir -Filter *.dmp -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  $cnt = ($f | Measure-Object).Count
  if($cnt -gt 0){ $latest=$f[0].LastWriteTime; $latestMB=[math]::Round($f[0].Length/1MB,2) }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\crashdumps.jsonl') -Obj @{ ts=$now.ToString('s'); kind='crashdumps'; count=$cnt; latest=$latest; latest_mb=$latestMB }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$dir = Join-Path $Base 'crashdumps'
$now=Get-Date
$cnt=0; $latest=$null; $latestMB=$null
if(Test-Path $dir){
  $f = Get-ChildItem -LiteralPath $dir -Filter *.dmp -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  $cnt = ($f | Measure-Object).Count
  if($cnt -gt 0){ $latest=$f[0].LastWriteTime; $latestMB=[math]::Round($f[0].Length/1MB,2) }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\crashdumps.jsonl') -Obj @{ ts=$now.ToString('s'); kind='crashdumps'; count=$cnt; latest=$latest; latest_mb=$latestMB }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$dir = Join-Path $Base 'crashdumps'
$now=Get-Date
$cnt=0; $latest=$null; $latestMB=$null
if(Test-Path $dir){
  $f = Get-ChildItem -LiteralPath $dir -Filter *.dmp -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  $cnt = ($f | Measure-Object).Count
  if($cnt -gt 0){ $latest=$f[0].LastWriteTime; $latestMB=[math]::Round($f[0].Length/1MB,2) }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\crashdumps.jsonl') -Obj @{ ts=$now.ToString('s'); kind='crashdumps'; count=$cnt; latest=$latest; latest_mb=$latestMB }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$dir = Join-Path $Base 'crashdumps'
$now=Get-Date
$cnt=0; $latest=$null; $latestMB=$null
if(Test-Path $dir){
  $f = Get-ChildItem -LiteralPath $dir -Filter *.dmp -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  $cnt = ($f | Measure-Object).Count
  if($cnt -gt 0){ $latest=$f[0].LastWriteTime; $latestMB=[math]::Round($f[0].Length/1MB,2) }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\crashdumps.jsonl') -Obj @{ ts=$now.ToString('s'); kind='crashdumps'; count=$cnt; latest=$latest; latest_mb=$latestMB }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$dir = Join-Path $Base 'crashdumps'
$now=Get-Date
$cnt=0; $latest=$null; $latestMB=$null
if(Test-Path $dir){
  $f = Get-ChildItem -LiteralPath $dir -Filter *.dmp -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  $cnt = ($f | Measure-Object).Count
  if($cnt -gt 0){ $latest=$f[0].LastWriteTime; $latestMB=[math]::Round($f[0].Length/1MB,2) }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\crashdumps.jsonl') -Obj @{ ts=$now.ToString('s'); kind='crashdumps'; count=$cnt; latest=$latest; latest_mb=$latestMB }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$dir = Join-Path $Base 'crashdumps'
$now=Get-Date
$cnt=0; $latest=$null; $latestMB=$null
if(Test-Path $dir){
  $f = Get-ChildItem -LiteralPath $dir -Filter *.dmp -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  $cnt = ($f | Measure-Object).Count
  if($cnt -gt 0){ $latest=$f[0].LastWriteTime; $latestMB=[math]::Round($f[0].Length/1MB,2) }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\crashdumps.jsonl') -Obj @{ ts=$now.ToString('s'); kind='crashdumps'; count=$cnt; latest=$latest; latest_mb=$latestMB }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$dir = Join-Path $Base 'crashdumps'
$now=Get-Date
$cnt=0; $latest=$null; $latestMB=$null
if(Test-Path $dir){
  $f = Get-ChildItem -LiteralPath $dir -Filter *.dmp -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  $cnt = ($f | Measure-Object).Count
  if($cnt -gt 0){ $latest=$f[0].LastWriteTime; $latestMB=[math]::Round($f[0].Length/1MB,2) }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\crashdumps.jsonl') -Obj @{ ts=$now.ToString('s'); kind='crashdumps'; count=$cnt; latest=$latest; latest_mb=$latestMB }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$dir = Join-Path $Base 'crashdumps'
$now=Get-Date
$cnt=0; $latest=$null; $latestMB=$null
if(Test-Path $dir){
  $f = Get-ChildItem -LiteralPath $dir -Filter *.dmp -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  $cnt = ($f | Measure-Object).Count
  if($cnt -gt 0){ $latest=$f[0].LastWriteTime; $latestMB=[math]::Round($f[0].Length/1MB,2) }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\crashdumps.jsonl') -Obj @{ ts=$now.ToString('s'); kind='crashdumps'; count=$cnt; latest=$latest; latest_mb=$latestMB }
