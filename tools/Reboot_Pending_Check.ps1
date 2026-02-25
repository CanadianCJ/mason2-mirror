$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$keys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\UpdateExeVolatile'
)
$pending = $false; $hits=@()
foreach($k in $keys){
  try{ if(Test-Path $k){ $pending=$true; $hits += $k } }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\reboot_pending.jsonl') -Obj @{ ts=$now.ToString('s'); kind='reboot_pending'; pending=$pending; keys=$hits }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$keys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\UpdateExeVolatile'
)
$pending = $false; $hits=@()
foreach($k in $keys){
  try{ if(Test-Path $k){ $pending=$true; $hits += $k } }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\reboot_pending.jsonl') -Obj @{ ts=$now.ToString('s'); kind='reboot_pending'; pending=$pending; keys=$hits }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$keys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\UpdateExeVolatile'
)
$pending = $false; $hits=@()
foreach($k in $keys){
  try{ if(Test-Path $k){ $pending=$true; $hits += $k } }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\reboot_pending.jsonl') -Obj @{ ts=$now.ToString('s'); kind='reboot_pending'; pending=$pending; keys=$hits }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$keys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\UpdateExeVolatile'
)
$pending = $false; $hits=@()
foreach($k in $keys){
  try{ if(Test-Path $k){ $pending=$true; $hits += $k } }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\reboot_pending.jsonl') -Obj @{ ts=$now.ToString('s'); kind='reboot_pending'; pending=$pending; keys=$hits }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$keys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\UpdateExeVolatile'
)
$pending = $false; $hits=@()
foreach($k in $keys){
  try{ if(Test-Path $k){ $pending=$true; $hits += $k } }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\reboot_pending.jsonl') -Obj @{ ts=$now.ToString('s'); kind='reboot_pending'; pending=$pending; keys=$hits }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$keys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\UpdateExeVolatile'
)
$pending = $false; $hits=@()
foreach($k in $keys){
  try{ if(Test-Path $k){ $pending=$true; $hits += $k } }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\reboot_pending.jsonl') -Obj @{ ts=$now.ToString('s'); kind='reboot_pending'; pending=$pending; keys=$hits }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$keys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\UpdateExeVolatile'
)
$pending = $false; $hits=@()
foreach($k in $keys){
  try{ if(Test-Path $k){ $pending=$true; $hits += $k } }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\reboot_pending.jsonl') -Obj @{ ts=$now.ToString('s'); kind='reboot_pending'; pending=$pending; keys=$hits }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$keys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\UpdateExeVolatile'
)
$pending = $false; $hits=@()
foreach($k in $keys){
  try{ if(Test-Path $k){ $pending=$true; $hits += $k } }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\reboot_pending.jsonl') -Obj @{ ts=$now.ToString('s'); kind='reboot_pending'; pending=$pending; keys=$hits }
