$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
Write-JsonLineSafe -Path (Join-Path $Base 'reports\cadence.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='heartbeat'; name='UI' }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
Write-JsonLineSafe -Path (Join-Path $Base 'reports\cadence.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='heartbeat'; name='UI' }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
Write-JsonLineSafe -Path (Join-Path $Base 'reports\cadence.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='heartbeat'; name='UI' }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
Write-JsonLineSafe -Path (Join-Path $Base 'reports\cadence.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='heartbeat'; name='UI' }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
Write-JsonLineSafe -Path (Join-Path $Base 'reports\cadence.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='heartbeat'; name='UI' }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
Write-JsonLineSafe -Path (Join-Path $Base 'reports\cadence.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='heartbeat'; name='UI' }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
Write-JsonLineSafe -Path (Join-Path $Base 'reports\cadence.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='heartbeat'; name='UI' }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
Write-JsonLineSafe -Path (Join-Path $Base 'reports\cadence.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='heartbeat'; name='UI' }
