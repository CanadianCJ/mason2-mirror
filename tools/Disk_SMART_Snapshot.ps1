$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$items=@()
$avail=$true
try{
  $pd = Get-PhysicalDisk -ErrorAction Stop
  foreach($d in $pd){
    $rel = $null
    try{ $rel = Get-StorageReliabilityCounter -PhysicalDisk $d -ErrorAction SilentlyContinue }catch{}
    $items += [pscustomobject]@{
      friendly=$d.FriendlyName; media=$d.MediaType.ToString(); health=$d.HealthStatus.ToString(); size_gb=[math]::Round($d.Size/1GB,1)
      wear=($rel.Wear); reallocated=($rel.ReallocatedSectors)
    }
  }
}catch{
  $avail=$false
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_smart.jsonl') -Obj @{ ts=$now.ToString('s'); kind='disk_smart'; available=$avail; items=$items }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$items=@()
$avail=$true
try{
  $pd = Get-PhysicalDisk -ErrorAction Stop
  foreach($d in $pd){
    $rel = $null
    try{ $rel = Get-StorageReliabilityCounter -PhysicalDisk $d -ErrorAction SilentlyContinue }catch{}
    $items += [pscustomobject]@{
      friendly=$d.FriendlyName; media=$d.MediaType.ToString(); health=$d.HealthStatus.ToString(); size_gb=[math]::Round($d.Size/1GB,1)
      wear=($rel.Wear); reallocated=($rel.ReallocatedSectors)
    }
  }
}catch{
  $avail=$false
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_smart.jsonl') -Obj @{ ts=$now.ToString('s'); kind='disk_smart'; available=$avail; items=$items }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$items=@()
$avail=$true
try{
  $pd = Get-PhysicalDisk -ErrorAction Stop
  foreach($d in $pd){
    $rel = $null
    try{ $rel = Get-StorageReliabilityCounter -PhysicalDisk $d -ErrorAction SilentlyContinue }catch{}
    $items += [pscustomobject]@{
      friendly=$d.FriendlyName; media=$d.MediaType.ToString(); health=$d.HealthStatus.ToString(); size_gb=[math]::Round($d.Size/1GB,1)
      wear=($rel.Wear); reallocated=($rel.ReallocatedSectors)
    }
  }
}catch{
  $avail=$false
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_smart.jsonl') -Obj @{ ts=$now.ToString('s'); kind='disk_smart'; available=$avail; items=$items }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$items=@()
$avail=$true
try{
  $pd = Get-PhysicalDisk -ErrorAction Stop
  foreach($d in $pd){
    $rel = $null
    try{ $rel = Get-StorageReliabilityCounter -PhysicalDisk $d -ErrorAction SilentlyContinue }catch{}
    $items += [pscustomobject]@{
      friendly=$d.FriendlyName; media=$d.MediaType.ToString(); health=$d.HealthStatus.ToString(); size_gb=[math]::Round($d.Size/1GB,1)
      wear=($rel.Wear); reallocated=($rel.ReallocatedSectors)
    }
  }
}catch{
  $avail=$false
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_smart.jsonl') -Obj @{ ts=$now.ToString('s'); kind='disk_smart'; available=$avail; items=$items }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$items=@()
$avail=$true
try{
  $pd = Get-PhysicalDisk -ErrorAction Stop
  foreach($d in $pd){
    $rel = $null
    try{ $rel = Get-StorageReliabilityCounter -PhysicalDisk $d -ErrorAction SilentlyContinue }catch{}
    $items += [pscustomobject]@{
      friendly=$d.FriendlyName; media=$d.MediaType.ToString(); health=$d.HealthStatus.ToString(); size_gb=[math]::Round($d.Size/1GB,1)
      wear=($rel.Wear); reallocated=($rel.ReallocatedSectors)
    }
  }
}catch{
  $avail=$false
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_smart.jsonl') -Obj @{ ts=$now.ToString('s'); kind='disk_smart'; available=$avail; items=$items }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$items=@()
$avail=$true
try{
  $pd = Get-PhysicalDisk -ErrorAction Stop
  foreach($d in $pd){
    $rel = $null
    try{ $rel = Get-StorageReliabilityCounter -PhysicalDisk $d -ErrorAction SilentlyContinue }catch{}
    $items += [pscustomobject]@{
      friendly=$d.FriendlyName; media=$d.MediaType.ToString(); health=$d.HealthStatus.ToString(); size_gb=[math]::Round($d.Size/1GB,1)
      wear=($rel.Wear); reallocated=($rel.ReallocatedSectors)
    }
  }
}catch{
  $avail=$false
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_smart.jsonl') -Obj @{ ts=$now.ToString('s'); kind='disk_smart'; available=$avail; items=$items }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$items=@()
$avail=$true
try{
  $pd = Get-PhysicalDisk -ErrorAction Stop
  foreach($d in $pd){
    $rel = $null
    try{ $rel = Get-StorageReliabilityCounter -PhysicalDisk $d -ErrorAction SilentlyContinue }catch{}
    $items += [pscustomobject]@{
      friendly=$d.FriendlyName; media=$d.MediaType.ToString(); health=$d.HealthStatus.ToString(); size_gb=[math]::Round($d.Size/1GB,1)
      wear=($rel.Wear); reallocated=($rel.ReallocatedSectors)
    }
  }
}catch{
  $avail=$false
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_smart.jsonl') -Obj @{ ts=$now.ToString('s'); kind='disk_smart'; available=$avail; items=$items }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$items=@()
$avail=$true
try{
  $pd = Get-PhysicalDisk -ErrorAction Stop
  foreach($d in $pd){
    $rel = $null
    try{ $rel = Get-StorageReliabilityCounter -PhysicalDisk $d -ErrorAction SilentlyContinue }catch{}
    $items += [pscustomobject]@{
      friendly=$d.FriendlyName; media=$d.MediaType.ToString(); health=$d.HealthStatus.ToString(); size_gb=[math]::Round($d.Size/1GB,1)
      wear=($rel.Wear); reallocated=($rel.ReallocatedSectors)
    }
  }
}catch{
  $avail=$false
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_smart.jsonl') -Obj @{ ts=$now.ToString('s'); kind='disk_smart'; available=$avail; items=$items }
