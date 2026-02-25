$ErrorActionPreference='Stop'
$k = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps'
if(-not (Test-Path $k)){ New-Item -Path $k -Force | Out-Null }
Set-ItemProperty -Path $k -Name DumpType  -Type DWord -Value $DumpType
Set-ItemProperty -Path $k -Name DumpCount -Type DWord -Value $DumpCount
Set-ItemProperty -Path $k -Name DumpFolder -Type ExpandString -Value (Join-Path $Base 'crashdumps')
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$DumpType=1,[int]$DumpCount=5)
$ErrorActionPreference='Stop'
$k = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps'
if(-not (Test-Path $k)){ New-Item -Path $k -Force | Out-Null }
Set-ItemProperty -Path $k -Name DumpType  -Type DWord -Value $DumpType
Set-ItemProperty -Path $k -Name DumpCount -Type DWord -Value $DumpCount
Set-ItemProperty -Path $k -Name DumpFolder -Type ExpandString -Value (Join-Path $Base 'crashdumps')
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$DumpType=1,[int]$DumpCount=5)
$ErrorActionPreference='Stop'
$k = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps'
if(-not (Test-Path $k)){ New-Item -Path $k -Force | Out-Null }
Set-ItemProperty -Path $k -Name DumpType  -Type DWord -Value $DumpType
Set-ItemProperty -Path $k -Name DumpCount -Type DWord -Value $DumpCount
Set-ItemProperty -Path $k -Name DumpFolder -Type ExpandString -Value (Join-Path $Base 'crashdumps')
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$DumpType=1,[int]$DumpCount=5)
$ErrorActionPreference='Stop'
$k = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps'
if(-not (Test-Path $k)){ New-Item -Path $k -Force | Out-Null }
Set-ItemProperty -Path $k -Name DumpType  -Type DWord -Value $DumpType
Set-ItemProperty -Path $k -Name DumpCount -Type DWord -Value $DumpCount
Set-ItemProperty -Path $k -Name DumpFolder -Type ExpandString -Value (Join-Path $Base 'crashdumps')
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$DumpType=1,[int]$DumpCount=5)
$ErrorActionPreference='Stop'
$k = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps'
if(-not (Test-Path $k)){ New-Item -Path $k -Force | Out-Null }
Set-ItemProperty -Path $k -Name DumpType  -Type DWord -Value $DumpType
Set-ItemProperty -Path $k -Name DumpCount -Type DWord -Value $DumpCount
Set-ItemProperty -Path $k -Name DumpFolder -Type ExpandString -Value (Join-Path $Base 'crashdumps')
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$DumpType=1,[int]$DumpCount=5)
$ErrorActionPreference='Stop'
$k = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps'
if(-not (Test-Path $k)){ New-Item -Path $k -Force | Out-Null }
Set-ItemProperty -Path $k -Name DumpType  -Type DWord -Value $DumpType
Set-ItemProperty -Path $k -Name DumpCount -Type DWord -Value $DumpCount
Set-ItemProperty -Path $k -Name DumpFolder -Type ExpandString -Value (Join-Path $Base 'crashdumps')
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$DumpType=1,[int]$DumpCount=5)
$ErrorActionPreference='Stop'
$k = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps'
if(-not (Test-Path $k)){ New-Item -Path $k -Force | Out-Null }
Set-ItemProperty -Path $k -Name DumpType  -Type DWord -Value $DumpType
Set-ItemProperty -Path $k -Name DumpCount -Type DWord -Value $DumpCount
Set-ItemProperty -Path $k -Name DumpFolder -Type ExpandString -Value (Join-Path $Base 'crashdumps')
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
$k = 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps'
if(-not (Test-Path $k)){ New-Item -Path $k -Force | Out-Null }
Set-ItemProperty -Path $k -Name DumpType  -Type DWord -Value $DumpType
Set-ItemProperty -Path $k -Name DumpCount -Type DWord -Value $DumpCount
Set-ItemProperty -Path $k -Name DumpFolder -Type ExpandString -Value (Join-Path $Base 'crashdumps')
