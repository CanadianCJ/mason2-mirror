$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$mb = 0
try{ $mb = [int](Get-Counter "\Memory\Available MBytes").CounterSamples.CookedValue }catch{}
$now=Get-Date
if($mb -lt $MinMB){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\mem_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='mem_pressure'; avail_mb=$mb; min_mb=$MinMB }
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MinMB=800)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$mb = 0
try{ $mb = [int](Get-Counter "\Memory\Available MBytes").CounterSamples.CookedValue }catch{}
$now=Get-Date
if($mb -lt $MinMB){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\mem_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='mem_pressure'; avail_mb=$mb; min_mb=$MinMB }
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MinMB=800)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$mb = 0
try{ $mb = [int](Get-Counter "\Memory\Available MBytes").CounterSamples.CookedValue }catch{}
$now=Get-Date
if($mb -lt $MinMB){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\mem_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='mem_pressure'; avail_mb=$mb; min_mb=$MinMB }
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MinMB=800)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$mb = 0
try{ $mb = [int](Get-Counter "\Memory\Available MBytes").CounterSamples.CookedValue }catch{}
$now=Get-Date
if($mb -lt $MinMB){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\mem_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='mem_pressure'; avail_mb=$mb; min_mb=$MinMB }
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MinMB=800)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$mb = 0
try{ $mb = [int](Get-Counter "\Memory\Available MBytes").CounterSamples.CookedValue }catch{}
$now=Get-Date
if($mb -lt $MinMB){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\mem_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='mem_pressure'; avail_mb=$mb; min_mb=$MinMB }
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MinMB=800)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$mb = 0
try{ $mb = [int](Get-Counter "\Memory\Available MBytes").CounterSamples.CookedValue }catch{}
$now=Get-Date
if($mb -lt $MinMB){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\mem_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='mem_pressure'; avail_mb=$mb; min_mb=$MinMB }
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$MinMB=800)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$mb = 0
try{ $mb = [int](Get-Counter "\Memory\Available MBytes").CounterSamples.CookedValue }catch{}
$now=Get-Date
if($mb -lt $MinMB){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\mem_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='mem_pressure'; avail_mb=$mb; min_mb=$MinMB }
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$mb = 0
try{ $mb = [int](Get-Counter "\Memory\Available MBytes").CounterSamples.CookedValue }catch{}
$now=Get-Date
if($mb -lt $MinMB){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\mem_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='mem_pressure'; avail_mb=$mb; min_mb=$MinMB }
}
