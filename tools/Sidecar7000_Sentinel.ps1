$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$bound = Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue
$ok = $bound -eq $null
Write-JsonLineSafe -Path (Join-Path $Base 'reports\sidecar7000.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port7000'; free=$ok }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$bound = Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue
$ok = $bound -eq $null
Write-JsonLineSafe -Path (Join-Path $Base 'reports\sidecar7000.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port7000'; free=$ok }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$bound = Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue
$ok = $bound -eq $null
Write-JsonLineSafe -Path (Join-Path $Base 'reports\sidecar7000.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port7000'; free=$ok }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$bound = Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue
$ok = $bound -eq $null
Write-JsonLineSafe -Path (Join-Path $Base 'reports\sidecar7000.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port7000'; free=$ok }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$bound = Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue
$ok = $bound -eq $null
Write-JsonLineSafe -Path (Join-Path $Base 'reports\sidecar7000.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port7000'; free=$ok }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$bound = Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue
$ok = $bound -eq $null
Write-JsonLineSafe -Path (Join-Path $Base 'reports\sidecar7000.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port7000'; free=$ok }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$bound = Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue
$ok = $bound -eq $null
Write-JsonLineSafe -Path (Join-Path $Base 'reports\sidecar7000.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port7000'; free=$ok }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$bound = Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue
$ok = $bound -eq $null
Write-JsonLineSafe -Path (Join-Path $Base 'reports\sidecar7000.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port7000'; free=$ok }
