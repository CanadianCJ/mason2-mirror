$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$targets = @(
  @{ p='reports\cadence.jsonl'; max_min=10 },
  @{ p='reports\health_index.jsonl'; max_min=1440 },
  @{ p='reports\exec_log.jsonl'; max_min=240 }
)
foreach($t in $targets){
  $fp = Join-Path $Base $t.p
  if(-not (Test-Path $fp)){ continue }
  try{
    $age = (New-TimeSpan -Start (Get-Item $fp).LastWriteTime -End $now).TotalMinutes
    if($age -gt [int]$t.max_min){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\staleness.jsonl') -Obj @{ ts=$now.ToString('s'); kind='stale'; file=$t.p; age_min=[int]$age; max_min=[int]$t.max_min }
    }
  }catch{}
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$targets = @(
  @{ p='reports\cadence.jsonl'; max_min=10 },
  @{ p='reports\health_index.jsonl'; max_min=1440 },
  @{ p='reports\exec_log.jsonl'; max_min=240 }
)
foreach($t in $targets){
  $fp = Join-Path $Base $t.p
  if(-not (Test-Path $fp)){ continue }
  try{
    $age = (New-TimeSpan -Start (Get-Item $fp).LastWriteTime -End $now).TotalMinutes
    if($age -gt [int]$t.max_min){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\staleness.jsonl') -Obj @{ ts=$now.ToString('s'); kind='stale'; file=$t.p; age_min=[int]$age; max_min=[int]$t.max_min }
    }
  }catch{}
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$targets = @(
  @{ p='reports\cadence.jsonl'; max_min=10 },
  @{ p='reports\health_index.jsonl'; max_min=1440 },
  @{ p='reports\exec_log.jsonl'; max_min=240 }
)
foreach($t in $targets){
  $fp = Join-Path $Base $t.p
  if(-not (Test-Path $fp)){ continue }
  try{
    $age = (New-TimeSpan -Start (Get-Item $fp).LastWriteTime -End $now).TotalMinutes
    if($age -gt [int]$t.max_min){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\staleness.jsonl') -Obj @{ ts=$now.ToString('s'); kind='stale'; file=$t.p; age_min=[int]$age; max_min=[int]$t.max_min }
    }
  }catch{}
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$targets = @(
  @{ p='reports\cadence.jsonl'; max_min=10 },
  @{ p='reports\health_index.jsonl'; max_min=1440 },
  @{ p='reports\exec_log.jsonl'; max_min=240 }
)
foreach($t in $targets){
  $fp = Join-Path $Base $t.p
  if(-not (Test-Path $fp)){ continue }
  try{
    $age = (New-TimeSpan -Start (Get-Item $fp).LastWriteTime -End $now).TotalMinutes
    if($age -gt [int]$t.max_min){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\staleness.jsonl') -Obj @{ ts=$now.ToString('s'); kind='stale'; file=$t.p; age_min=[int]$age; max_min=[int]$t.max_min }
    }
  }catch{}
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$targets = @(
  @{ p='reports\cadence.jsonl'; max_min=10 },
  @{ p='reports\health_index.jsonl'; max_min=1440 },
  @{ p='reports\exec_log.jsonl'; max_min=240 }
)
foreach($t in $targets){
  $fp = Join-Path $Base $t.p
  if(-not (Test-Path $fp)){ continue }
  try{
    $age = (New-TimeSpan -Start (Get-Item $fp).LastWriteTime -End $now).TotalMinutes
    if($age -gt [int]$t.max_min){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\staleness.jsonl') -Obj @{ ts=$now.ToString('s'); kind='stale'; file=$t.p; age_min=[int]$age; max_min=[int]$t.max_min }
    }
  }catch{}
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$targets = @(
  @{ p='reports\cadence.jsonl'; max_min=10 },
  @{ p='reports\health_index.jsonl'; max_min=1440 },
  @{ p='reports\exec_log.jsonl'; max_min=240 }
)
foreach($t in $targets){
  $fp = Join-Path $Base $t.p
  if(-not (Test-Path $fp)){ continue }
  try{
    $age = (New-TimeSpan -Start (Get-Item $fp).LastWriteTime -End $now).TotalMinutes
    if($age -gt [int]$t.max_min){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\staleness.jsonl') -Obj @{ ts=$now.ToString('s'); kind='stale'; file=$t.p; age_min=[int]$age; max_min=[int]$t.max_min }
    }
  }catch{}
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$targets = @(
  @{ p='reports\cadence.jsonl'; max_min=10 },
  @{ p='reports\health_index.jsonl'; max_min=1440 },
  @{ p='reports\exec_log.jsonl'; max_min=240 }
)
foreach($t in $targets){
  $fp = Join-Path $Base $t.p
  if(-not (Test-Path $fp)){ continue }
  try{
    $age = (New-TimeSpan -Start (Get-Item $fp).LastWriteTime -End $now).TotalMinutes
    if($age -gt [int]$t.max_min){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\staleness.jsonl') -Obj @{ ts=$now.ToString('s'); kind='stale'; file=$t.p; age_min=[int]$age; max_min=[int]$t.max_min }
    }
  }catch{}
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$targets = @(
  @{ p='reports\cadence.jsonl'; max_min=10 },
  @{ p='reports\health_index.jsonl'; max_min=1440 },
  @{ p='reports\exec_log.jsonl'; max_min=240 }
)
foreach($t in $targets){
  $fp = Join-Path $Base $t.p
  if(-not (Test-Path $fp)){ continue }
  try{
    $age = (New-TimeSpan -Start (Get-Item $fp).LastWriteTime -End $now).TotalMinutes
    if($age -gt [int]$t.max_min){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\staleness.jsonl') -Obj @{ ts=$now.ToString('s'); kind='stale'; file=$t.p; age_min=[int]$age; max_min=[int]$t.max_min }
    }
  }catch{}
}
