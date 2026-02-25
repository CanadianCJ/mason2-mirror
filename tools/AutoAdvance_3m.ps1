# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\cadence.jsonl'
$evt = @{
  ts      = (Get-Date).ToString('s')
  name    = 'AutoAdvance'
  cadence = '3m'
  host    = $env:COMPUTERNAME
  result  = 'ok'
}
Write-JsonLineSafe -Path $log -Obj $evt

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\cadence.jsonl'
$evt = @{
  ts      = (Get-Date).ToString('s')
  name    = 'AutoAdvance'
  cadence = '3m'
  host    = $env:COMPUTERNAME
  result  = 'ok'
}
Write-JsonLineSafe -Path $log -Obj $evt

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\cadence.jsonl'
$evt = @{
  ts      = (Get-Date).ToString('s')
  name    = 'AutoAdvance'
  cadence = '3m'
  host    = $env:COMPUTERNAME
  result  = 'ok'
}
Write-JsonLineSafe -Path $log -Obj $evt

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\cadence.jsonl'
$evt = @{
  ts      = (Get-Date).ToString('s')
  name    = 'AutoAdvance'
  cadence = '3m'
  host    = $env:COMPUTERNAME
  result  = 'ok'
}
Write-JsonLineSafe -Path $log -Obj $evt

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\cadence.jsonl'
$evt = @{
  ts      = (Get-Date).ToString('s')
  name    = 'AutoAdvance'
  cadence = '3m'
  host    = $env:COMPUTERNAME
  result  = 'ok'
}
Write-JsonLineSafe -Path $log -Obj $evt

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\cadence.jsonl'
$evt = @{
  ts      = (Get-Date).ToString('s')
  name    = 'AutoAdvance'
  cadence = '3m'
  host    = $env:COMPUTERNAME
  result  = 'ok'
}
Write-JsonLineSafe -Path $log -Obj $evt

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\cadence.jsonl'
$evt = @{
  ts      = (Get-Date).ToString('s')
  name    = 'AutoAdvance'
  cadence = '3m'
  host    = $env:COMPUTERNAME
  result  = 'ok'
}
Write-JsonLineSafe -Path $log -Obj $evt

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\cadence.jsonl'
$evt = @{
  ts      = (Get-Date).ToString('s')
  name    = 'AutoAdvance'
  cadence = '3m'
  host    = $env:COMPUTERNAME
  result  = 'ok'
}
Write-JsonLineSafe -Path $log -Obj $evt

