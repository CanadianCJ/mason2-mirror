$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
# DISM /CheckHealth (fast)
$dism='unknown'
try{
  $out = (& DISM /Online /Cleanup-Image /CheckHealth 2>&1) -as [string[]]
  if($out){
    $joined = ($out -join "`n")
    if($joined -match 'No component store corruption detected'){ $dism='healthy' }
    elseif($joined -match 'The component store is repairable'){ $dism='repairable' }
    elseif($joined -match 'The component store is not repairable'){ $dism='nonrepairable' }
  }
}catch{ $dism='check_failed' }
# CHKDSK dirty bit
$dirty=$null
try{
  $fs = (& fsutil dirty query C: 2>&1) -as [string[]]
  if($fs){ $dirty = (($fs -join ' ') -match 'is dirty') }
}catch{}
$advice=@()
if($dism -eq 'repairable'){ $advice += 'Consider: DISM /Online /Cleanup-Image /RestoreHealth' }
if($dirty){ $advice += 'Volume dirty; consider scheduled chkdsk on reboot' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\os_health_advisory.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='os_health'; dism=$dism; volume_dirty=$dirty; advice=$advice
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
# DISM /CheckHealth (fast)
$dism='unknown'
try{
  $out = (& DISM /Online /Cleanup-Image /CheckHealth 2>&1) -as [string[]]
  if($out){
    $joined = ($out -join "`n")
    if($joined -match 'No component store corruption detected'){ $dism='healthy' }
    elseif($joined -match 'The component store is repairable'){ $dism='repairable' }
    elseif($joined -match 'The component store is not repairable'){ $dism='nonrepairable' }
  }
}catch{ $dism='check_failed' }
# CHKDSK dirty bit
$dirty=$null
try{
  $fs = (& fsutil dirty query C: 2>&1) -as [string[]]
  if($fs){ $dirty = (($fs -join ' ') -match 'is dirty') }
}catch{}
$advice=@()
if($dism -eq 'repairable'){ $advice += 'Consider: DISM /Online /Cleanup-Image /RestoreHealth' }
if($dirty){ $advice += 'Volume dirty; consider scheduled chkdsk on reboot' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\os_health_advisory.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='os_health'; dism=$dism; volume_dirty=$dirty; advice=$advice
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
# DISM /CheckHealth (fast)
$dism='unknown'
try{
  $out = (& DISM /Online /Cleanup-Image /CheckHealth 2>&1) -as [string[]]
  if($out){
    $joined = ($out -join "`n")
    if($joined -match 'No component store corruption detected'){ $dism='healthy' }
    elseif($joined -match 'The component store is repairable'){ $dism='repairable' }
    elseif($joined -match 'The component store is not repairable'){ $dism='nonrepairable' }
  }
}catch{ $dism='check_failed' }
# CHKDSK dirty bit
$dirty=$null
try{
  $fs = (& fsutil dirty query C: 2>&1) -as [string[]]
  if($fs){ $dirty = (($fs -join ' ') -match 'is dirty') }
}catch{}
$advice=@()
if($dism -eq 'repairable'){ $advice += 'Consider: DISM /Online /Cleanup-Image /RestoreHealth' }
if($dirty){ $advice += 'Volume dirty; consider scheduled chkdsk on reboot' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\os_health_advisory.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='os_health'; dism=$dism; volume_dirty=$dirty; advice=$advice
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
# DISM /CheckHealth (fast)
$dism='unknown'
try{
  $out = (& DISM /Online /Cleanup-Image /CheckHealth 2>&1) -as [string[]]
  if($out){
    $joined = ($out -join "`n")
    if($joined -match 'No component store corruption detected'){ $dism='healthy' }
    elseif($joined -match 'The component store is repairable'){ $dism='repairable' }
    elseif($joined -match 'The component store is not repairable'){ $dism='nonrepairable' }
  }
}catch{ $dism='check_failed' }
# CHKDSK dirty bit
$dirty=$null
try{
  $fs = (& fsutil dirty query C: 2>&1) -as [string[]]
  if($fs){ $dirty = (($fs -join ' ') -match 'is dirty') }
}catch{}
$advice=@()
if($dism -eq 'repairable'){ $advice += 'Consider: DISM /Online /Cleanup-Image /RestoreHealth' }
if($dirty){ $advice += 'Volume dirty; consider scheduled chkdsk on reboot' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\os_health_advisory.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='os_health'; dism=$dism; volume_dirty=$dirty; advice=$advice
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
# DISM /CheckHealth (fast)
$dism='unknown'
try{
  $out = (& DISM /Online /Cleanup-Image /CheckHealth 2>&1) -as [string[]]
  if($out){
    $joined = ($out -join "`n")
    if($joined -match 'No component store corruption detected'){ $dism='healthy' }
    elseif($joined -match 'The component store is repairable'){ $dism='repairable' }
    elseif($joined -match 'The component store is not repairable'){ $dism='nonrepairable' }
  }
}catch{ $dism='check_failed' }
# CHKDSK dirty bit
$dirty=$null
try{
  $fs = (& fsutil dirty query C: 2>&1) -as [string[]]
  if($fs){ $dirty = (($fs -join ' ') -match 'is dirty') }
}catch{}
$advice=@()
if($dism -eq 'repairable'){ $advice += 'Consider: DISM /Online /Cleanup-Image /RestoreHealth' }
if($dirty){ $advice += 'Volume dirty; consider scheduled chkdsk on reboot' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\os_health_advisory.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='os_health'; dism=$dism; volume_dirty=$dirty; advice=$advice
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
# DISM /CheckHealth (fast)
$dism='unknown'
try{
  $out = (& DISM /Online /Cleanup-Image /CheckHealth 2>&1) -as [string[]]
  if($out){
    $joined = ($out -join "`n")
    if($joined -match 'No component store corruption detected'){ $dism='healthy' }
    elseif($joined -match 'The component store is repairable'){ $dism='repairable' }
    elseif($joined -match 'The component store is not repairable'){ $dism='nonrepairable' }
  }
}catch{ $dism='check_failed' }
# CHKDSK dirty bit
$dirty=$null
try{
  $fs = (& fsutil dirty query C: 2>&1) -as [string[]]
  if($fs){ $dirty = (($fs -join ' ') -match 'is dirty') }
}catch{}
$advice=@()
if($dism -eq 'repairable'){ $advice += 'Consider: DISM /Online /Cleanup-Image /RestoreHealth' }
if($dirty){ $advice += 'Volume dirty; consider scheduled chkdsk on reboot' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\os_health_advisory.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='os_health'; dism=$dism; volume_dirty=$dirty; advice=$advice
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
# DISM /CheckHealth (fast)
$dism='unknown'
try{
  $out = (& DISM /Online /Cleanup-Image /CheckHealth 2>&1) -as [string[]]
  if($out){
    $joined = ($out -join "`n")
    if($joined -match 'No component store corruption detected'){ $dism='healthy' }
    elseif($joined -match 'The component store is repairable'){ $dism='repairable' }
    elseif($joined -match 'The component store is not repairable'){ $dism='nonrepairable' }
  }
}catch{ $dism='check_failed' }
# CHKDSK dirty bit
$dirty=$null
try{
  $fs = (& fsutil dirty query C: 2>&1) -as [string[]]
  if($fs){ $dirty = (($fs -join ' ') -match 'is dirty') }
}catch{}
$advice=@()
if($dism -eq 'repairable'){ $advice += 'Consider: DISM /Online /Cleanup-Image /RestoreHealth' }
if($dirty){ $advice += 'Volume dirty; consider scheduled chkdsk on reboot' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\os_health_advisory.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='os_health'; dism=$dism; volume_dirty=$dirty; advice=$advice
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
# DISM /CheckHealth (fast)
$dism='unknown'
try{
  $out = (& DISM /Online /Cleanup-Image /CheckHealth 2>&1) -as [string[]]
  if($out){
    $joined = ($out -join "`n")
    if($joined -match 'No component store corruption detected'){ $dism='healthy' }
    elseif($joined -match 'The component store is repairable'){ $dism='repairable' }
    elseif($joined -match 'The component store is not repairable'){ $dism='nonrepairable' }
  }
}catch{ $dism='check_failed' }
# CHKDSK dirty bit
$dirty=$null
try{
  $fs = (& fsutil dirty query C: 2>&1) -as [string[]]
  if($fs){ $dirty = (($fs -join ' ') -match 'is dirty') }
}catch{}
$advice=@()
if($dism -eq 'repairable'){ $advice += 'Consider: DISM /Online /Cleanup-Image /RestoreHealth' }
if($dirty){ $advice += 'Volume dirty; consider scheduled chkdsk on reboot' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\os_health_advisory.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='os_health'; dism=$dism; volume_dirty=$dirty; advice=$advice
}
