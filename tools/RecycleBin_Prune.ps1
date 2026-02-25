$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxGB=5; $auto=$false
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw | ConvertFrom-Json; if($p.recycle){ if($p.recycle.max_gb){ $maxGB=[int]$p.recycle.max_gb }; if($p.recycle.auto_empty -ne $null){ $auto=[bool]$p.recycle.auto_empty } } } }catch{}
$now=Get-Date
# Measure
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object { try{ $bytes += $_.Length }catch{} }
  }catch{}
}
$over = ($bytes -gt ($maxGB*1GB))
$did=$false; $rc=$null; $reason=$null
if($over -and $auto){
  try{ Clear-RecycleBin -Force -ErrorAction Stop; $did=$true; $rc=0 }catch{ $rc=1; $reason='clear_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin_prune.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin_prune'; size_mb=[math]::Round($bytes/1MB,2); max_gb=$maxGB; auto=$auto; pruned=$did; rc=$rc; reason=$reason
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxGB=5; $auto=$false
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw | ConvertFrom-Json; if($p.recycle){ if($p.recycle.max_gb){ $maxGB=[int]$p.recycle.max_gb }; if($p.recycle.auto_empty -ne $null){ $auto=[bool]$p.recycle.auto_empty } } } }catch{}
$now=Get-Date
# Measure
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object { try{ $bytes += $_.Length }catch{} }
  }catch{}
}
$over = ($bytes -gt ($maxGB*1GB))
$did=$false; $rc=$null; $reason=$null
if($over -and $auto){
  try{ Clear-RecycleBin -Force -ErrorAction Stop; $did=$true; $rc=0 }catch{ $rc=1; $reason='clear_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin_prune.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin_prune'; size_mb=[math]::Round($bytes/1MB,2); max_gb=$maxGB; auto=$auto; pruned=$did; rc=$rc; reason=$reason
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxGB=5; $auto=$false
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw | ConvertFrom-Json; if($p.recycle){ if($p.recycle.max_gb){ $maxGB=[int]$p.recycle.max_gb }; if($p.recycle.auto_empty -ne $null){ $auto=[bool]$p.recycle.auto_empty } } } }catch{}
$now=Get-Date
# Measure
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object { try{ $bytes += $_.Length }catch{} }
  }catch{}
}
$over = ($bytes -gt ($maxGB*1GB))
$did=$false; $rc=$null; $reason=$null
if($over -and $auto){
  try{ Clear-RecycleBin -Force -ErrorAction Stop; $did=$true; $rc=0 }catch{ $rc=1; $reason='clear_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin_prune.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin_prune'; size_mb=[math]::Round($bytes/1MB,2); max_gb=$maxGB; auto=$auto; pruned=$did; rc=$rc; reason=$reason
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxGB=5; $auto=$false
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw | ConvertFrom-Json; if($p.recycle){ if($p.recycle.max_gb){ $maxGB=[int]$p.recycle.max_gb }; if($p.recycle.auto_empty -ne $null){ $auto=[bool]$p.recycle.auto_empty } } } }catch{}
$now=Get-Date
# Measure
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object { try{ $bytes += $_.Length }catch{} }
  }catch{}
}
$over = ($bytes -gt ($maxGB*1GB))
$did=$false; $rc=$null; $reason=$null
if($over -and $auto){
  try{ Clear-RecycleBin -Force -ErrorAction Stop; $did=$true; $rc=0 }catch{ $rc=1; $reason='clear_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin_prune.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin_prune'; size_mb=[math]::Round($bytes/1MB,2); max_gb=$maxGB; auto=$auto; pruned=$did; rc=$rc; reason=$reason
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxGB=5; $auto=$false
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw | ConvertFrom-Json; if($p.recycle){ if($p.recycle.max_gb){ $maxGB=[int]$p.recycle.max_gb }; if($p.recycle.auto_empty -ne $null){ $auto=[bool]$p.recycle.auto_empty } } } }catch{}
$now=Get-Date
# Measure
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object { try{ $bytes += $_.Length }catch{} }
  }catch{}
}
$over = ($bytes -gt ($maxGB*1GB))
$did=$false; $rc=$null; $reason=$null
if($over -and $auto){
  try{ Clear-RecycleBin -Force -ErrorAction Stop; $did=$true; $rc=0 }catch{ $rc=1; $reason='clear_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin_prune.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin_prune'; size_mb=[math]::Round($bytes/1MB,2); max_gb=$maxGB; auto=$auto; pruned=$did; rc=$rc; reason=$reason
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxGB=5; $auto=$false
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw | ConvertFrom-Json; if($p.recycle){ if($p.recycle.max_gb){ $maxGB=[int]$p.recycle.max_gb }; if($p.recycle.auto_empty -ne $null){ $auto=[bool]$p.recycle.auto_empty } } } }catch{}
$now=Get-Date
# Measure
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object { try{ $bytes += $_.Length }catch{} }
  }catch{}
}
$over = ($bytes -gt ($maxGB*1GB))
$did=$false; $rc=$null; $reason=$null
if($over -and $auto){
  try{ Clear-RecycleBin -Force -ErrorAction Stop; $did=$true; $rc=0 }catch{ $rc=1; $reason='clear_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin_prune.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin_prune'; size_mb=[math]::Round($bytes/1MB,2); max_gb=$maxGB; auto=$auto; pruned=$did; rc=$rc; reason=$reason
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxGB=5; $auto=$false
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw | ConvertFrom-Json; if($p.recycle){ if($p.recycle.max_gb){ $maxGB=[int]$p.recycle.max_gb }; if($p.recycle.auto_empty -ne $null){ $auto=[bool]$p.recycle.auto_empty } } } }catch{}
$now=Get-Date
# Measure
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object { try{ $bytes += $_.Length }catch{} }
  }catch{}
}
$over = ($bytes -gt ($maxGB*1GB))
$did=$false; $rc=$null; $reason=$null
if($over -and $auto){
  try{ Clear-RecycleBin -Force -ErrorAction Stop; $did=$true; $rc=0 }catch{ $rc=1; $reason='clear_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin_prune.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin_prune'; size_mb=[math]::Round($bytes/1MB,2); max_gb=$maxGB; auto=$auto; pruned=$did; rc=$rc; reason=$reason
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxGB=5; $auto=$false
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw | ConvertFrom-Json; if($p.recycle){ if($p.recycle.max_gb){ $maxGB=[int]$p.recycle.max_gb }; if($p.recycle.auto_empty -ne $null){ $auto=[bool]$p.recycle.auto_empty } } } }catch{}
$now=Get-Date
# Measure
$root = Join-Path $env:SystemDrive '$Recycle.Bin'
$bytes=0
if(Test-Path $root){
  try{
    Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object { try{ $bytes += $_.Length }catch{} }
  }catch{}
}
$over = ($bytes -gt ($maxGB*1GB))
$did=$false; $rc=$null; $reason=$null
if($over -and $auto){
  try{ Clear-RecycleBin -Force -ErrorAction Stop; $did=$true; $rc=0 }catch{ $rc=1; $reason='clear_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\recycle_bin_prune.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='recycle_bin_prune'; size_mb=[math]::Round($bytes/1MB,2); max_gb=$maxGB; auto=$auto; pruned=$did; rc=$rc; reason=$reason
}
