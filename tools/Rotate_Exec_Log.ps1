$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$arc = Join-Path $rep 'archive'; New-Item -ItemType Directory -Force -Path $arc | Out-Null
$src = Join-Path $rep 'exec_log.jsonl'
if(Test-Path $src){
  try{
    $mb=[math]::Round((Get-Item $src).Length/1MB,2)
    if($mb -ge $MaxMB){
      $ts=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item -LiteralPath $src -Destination (Join-Path $arc ("exec_log."+ $ts + ".jsonl")) -Force
      Write-JsonLineSafe -Path (Join-Path $rep 'log_rotate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='rotate'; file='exec_log.jsonl'; mb=$mb; action='archived' }
    }
  }catch{}
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=10)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$arc = Join-Path $rep 'archive'; New-Item -ItemType Directory -Force -Path $arc | Out-Null
$src = Join-Path $rep 'exec_log.jsonl'
if(Test-Path $src){
  try{
    $mb=[math]::Round((Get-Item $src).Length/1MB,2)
    if($mb -ge $MaxMB){
      $ts=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item -LiteralPath $src -Destination (Join-Path $arc ("exec_log."+ $ts + ".jsonl")) -Force
      Write-JsonLineSafe -Path (Join-Path $rep 'log_rotate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='rotate'; file='exec_log.jsonl'; mb=$mb; action='archived' }
    }
  }catch{}
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=10)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$arc = Join-Path $rep 'archive'; New-Item -ItemType Directory -Force -Path $arc | Out-Null
$src = Join-Path $rep 'exec_log.jsonl'
if(Test-Path $src){
  try{
    $mb=[math]::Round((Get-Item $src).Length/1MB,2)
    if($mb -ge $MaxMB){
      $ts=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item -LiteralPath $src -Destination (Join-Path $arc ("exec_log."+ $ts + ".jsonl")) -Force
      Write-JsonLineSafe -Path (Join-Path $rep 'log_rotate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='rotate'; file='exec_log.jsonl'; mb=$mb; action='archived' }
    }
  }catch{}
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=10)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$arc = Join-Path $rep 'archive'; New-Item -ItemType Directory -Force -Path $arc | Out-Null
$src = Join-Path $rep 'exec_log.jsonl'
if(Test-Path $src){
  try{
    $mb=[math]::Round((Get-Item $src).Length/1MB,2)
    if($mb -ge $MaxMB){
      $ts=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item -LiteralPath $src -Destination (Join-Path $arc ("exec_log."+ $ts + ".jsonl")) -Force
      Write-JsonLineSafe -Path (Join-Path $rep 'log_rotate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='rotate'; file='exec_log.jsonl'; mb=$mb; action='archived' }
    }
  }catch{}
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=10)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$arc = Join-Path $rep 'archive'; New-Item -ItemType Directory -Force -Path $arc | Out-Null
$src = Join-Path $rep 'exec_log.jsonl'
if(Test-Path $src){
  try{
    $mb=[math]::Round((Get-Item $src).Length/1MB,2)
    if($mb -ge $MaxMB){
      $ts=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item -LiteralPath $src -Destination (Join-Path $arc ("exec_log."+ $ts + ".jsonl")) -Force
      Write-JsonLineSafe -Path (Join-Path $rep 'log_rotate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='rotate'; file='exec_log.jsonl'; mb=$mb; action='archived' }
    }
  }catch{}
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=10)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$arc = Join-Path $rep 'archive'; New-Item -ItemType Directory -Force -Path $arc | Out-Null
$src = Join-Path $rep 'exec_log.jsonl'
if(Test-Path $src){
  try{
    $mb=[math]::Round((Get-Item $src).Length/1MB,2)
    if($mb -ge $MaxMB){
      $ts=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item -LiteralPath $src -Destination (Join-Path $arc ("exec_log."+ $ts + ".jsonl")) -Force
      Write-JsonLineSafe -Path (Join-Path $rep 'log_rotate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='rotate'; file='exec_log.jsonl'; mb=$mb; action='archived' }
    }
  }catch{}
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MaxMB=10)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$arc = Join-Path $rep 'archive'; New-Item -ItemType Directory -Force -Path $arc | Out-Null
$src = Join-Path $rep 'exec_log.jsonl'
if(Test-Path $src){
  try{
    $mb=[math]::Round((Get-Item $src).Length/1MB,2)
    if($mb -ge $MaxMB){
      $ts=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item -LiteralPath $src -Destination (Join-Path $arc ("exec_log."+ $ts + ".jsonl")) -Force
      Write-JsonLineSafe -Path (Join-Path $rep 'log_rotate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='rotate'; file='exec_log.jsonl'; mb=$mb; action='archived' }
    }
  }catch{}
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$arc = Join-Path $rep 'archive'; New-Item -ItemType Directory -Force -Path $arc | Out-Null
$src = Join-Path $rep 'exec_log.jsonl'
if(Test-Path $src){
  try{
    $mb=[math]::Round((Get-Item $src).Length/1MB,2)
    if($mb -ge $MaxMB){
      $ts=(Get-Date).ToString('yyyyMMdd-HHmmss')
      Move-Item -LiteralPath $src -Destination (Join-Path $arc ("exec_log."+ $ts + ".jsonl")) -Force
      Write-JsonLineSafe -Path (Join-Path $rep 'log_rotate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='rotate'; file='exec_log.jsonl'; mb=$mb; action='archived' }
    }
  }catch{}
}
