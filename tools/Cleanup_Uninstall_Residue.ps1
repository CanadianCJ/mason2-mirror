# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
param(
  [int]$Days=14,
  [switch]$Zip,
  [switch]$Purge
)
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Parent = Split-Path $Base -Parent
$Removed = Get-ChildItem $Parent -Directory -Filter "Mason2._removed_*" -ea SilentlyContinue
$OutDir = Join-Path $Base "dist\removed"
New-Item $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
$cutoff = (Get-Date).AddDays(-1 * $Days)
$done = @()
foreach($d in $Removed){
  if($d.LastWriteTime -gt $cutoff){ continue }
  if($Zip){
    $zip = Join-Path $OutDir ($d.Name + ".zip")
    if(Test-Path $zip){ Remove-Item $zip -Force }
    try{
      Compress-Archive -Path (Join-Path $d.FullName '*') -DestinationPath $zip -Force
      Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue
      $done += "zipped+removed:$($d.Name)"
    }catch{
      $done += "zip_failed:$($d.Name)"
    }
  } elseif($Purge){
    try{ Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue; $done += "purged:$($d.Name)" }catch{ $done += "purge_failed:$($d.Name)" }
  } else {
    $done += "eligible:$($d.Name)"
  }
}
if(Get-Command Write-JsonLog -ea SilentlyContinue){
  Write-JsonLog -Component "cleanup" -Level "INFO" -Message "uninstall residue check" -Props @{ actions=($done -join ',') }
}
$done -join "`n"

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
param(
  [int]$Days=14,
  [switch]$Zip,
  [switch]$Purge
)
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Parent = Split-Path $Base -Parent
$Removed = Get-ChildItem $Parent -Directory -Filter "Mason2._removed_*" -ea SilentlyContinue
$OutDir = Join-Path $Base "dist\removed"
New-Item $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
$cutoff = (Get-Date).AddDays(-1 * $Days)
$done = @()
foreach($d in $Removed){
  if($d.LastWriteTime -gt $cutoff){ continue }
  if($Zip){
    $zip = Join-Path $OutDir ($d.Name + ".zip")
    if(Test-Path $zip){ Remove-Item $zip -Force }
    try{
      Compress-Archive -Path (Join-Path $d.FullName '*') -DestinationPath $zip -Force
      Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue
      $done += "zipped+removed:$($d.Name)"
    }catch{
      $done += "zip_failed:$($d.Name)"
    }
  } elseif($Purge){
    try{ Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue; $done += "purged:$($d.Name)" }catch{ $done += "purge_failed:$($d.Name)" }
  } else {
    $done += "eligible:$($d.Name)"
  }
}
if(Get-Command Write-JsonLog -ea SilentlyContinue){
  Write-JsonLog -Component "cleanup" -Level "INFO" -Message "uninstall residue check" -Props @{ actions=($done -join ',') }
}
$done -join "`n"

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
param(
  [int]$Days=14,
  [switch]$Zip,
  [switch]$Purge
)
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Parent = Split-Path $Base -Parent
$Removed = Get-ChildItem $Parent -Directory -Filter "Mason2._removed_*" -ea SilentlyContinue
$OutDir = Join-Path $Base "dist\removed"
New-Item $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
$cutoff = (Get-Date).AddDays(-1 * $Days)
$done = @()
foreach($d in $Removed){
  if($d.LastWriteTime -gt $cutoff){ continue }
  if($Zip){
    $zip = Join-Path $OutDir ($d.Name + ".zip")
    if(Test-Path $zip){ Remove-Item $zip -Force }
    try{
      Compress-Archive -Path (Join-Path $d.FullName '*') -DestinationPath $zip -Force
      Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue
      $done += "zipped+removed:$($d.Name)"
    }catch{
      $done += "zip_failed:$($d.Name)"
    }
  } elseif($Purge){
    try{ Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue; $done += "purged:$($d.Name)" }catch{ $done += "purge_failed:$($d.Name)" }
  } else {
    $done += "eligible:$($d.Name)"
  }
}
if(Get-Command Write-JsonLog -ea SilentlyContinue){
  Write-JsonLog -Component "cleanup" -Level "INFO" -Message "uninstall residue check" -Props @{ actions=($done -join ',') }
}
$done -join "`n"

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
param(
  [int]$Days=14,
  [switch]$Zip,
  [switch]$Purge
)
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Parent = Split-Path $Base -Parent
$Removed = Get-ChildItem $Parent -Directory -Filter "Mason2._removed_*" -ea SilentlyContinue
$OutDir = Join-Path $Base "dist\removed"
New-Item $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
$cutoff = (Get-Date).AddDays(-1 * $Days)
$done = @()
foreach($d in $Removed){
  if($d.LastWriteTime -gt $cutoff){ continue }
  if($Zip){
    $zip = Join-Path $OutDir ($d.Name + ".zip")
    if(Test-Path $zip){ Remove-Item $zip -Force }
    try{
      Compress-Archive -Path (Join-Path $d.FullName '*') -DestinationPath $zip -Force
      Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue
      $done += "zipped+removed:$($d.Name)"
    }catch{
      $done += "zip_failed:$($d.Name)"
    }
  } elseif($Purge){
    try{ Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue; $done += "purged:$($d.Name)" }catch{ $done += "purge_failed:$($d.Name)" }
  } else {
    $done += "eligible:$($d.Name)"
  }
}
if(Get-Command Write-JsonLog -ea SilentlyContinue){
  Write-JsonLog -Component "cleanup" -Level "INFO" -Message "uninstall residue check" -Props @{ actions=($done -join ',') }
}
$done -join "`n"

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
param(
  [int]$Days=14,
  [switch]$Zip,
  [switch]$Purge
)
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Parent = Split-Path $Base -Parent
$Removed = Get-ChildItem $Parent -Directory -Filter "Mason2._removed_*" -ea SilentlyContinue
$OutDir = Join-Path $Base "dist\removed"
New-Item $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
$cutoff = (Get-Date).AddDays(-1 * $Days)
$done = @()
foreach($d in $Removed){
  if($d.LastWriteTime -gt $cutoff){ continue }
  if($Zip){
    $zip = Join-Path $OutDir ($d.Name + ".zip")
    if(Test-Path $zip){ Remove-Item $zip -Force }
    try{
      Compress-Archive -Path (Join-Path $d.FullName '*') -DestinationPath $zip -Force
      Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue
      $done += "zipped+removed:$($d.Name)"
    }catch{
      $done += "zip_failed:$($d.Name)"
    }
  } elseif($Purge){
    try{ Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue; $done += "purged:$($d.Name)" }catch{ $done += "purge_failed:$($d.Name)" }
  } else {
    $done += "eligible:$($d.Name)"
  }
}
if(Get-Command Write-JsonLog -ea SilentlyContinue){
  Write-JsonLog -Component "cleanup" -Level "INFO" -Message "uninstall residue check" -Props @{ actions=($done -join ',') }
}
$done -join "`n"

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
param(
  [int]$Days=14,
  [switch]$Zip,
  [switch]$Purge
)
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Parent = Split-Path $Base -Parent
$Removed = Get-ChildItem $Parent -Directory -Filter "Mason2._removed_*" -ea SilentlyContinue
$OutDir = Join-Path $Base "dist\removed"
New-Item $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
$cutoff = (Get-Date).AddDays(-1 * $Days)
$done = @()
foreach($d in $Removed){
  if($d.LastWriteTime -gt $cutoff){ continue }
  if($Zip){
    $zip = Join-Path $OutDir ($d.Name + ".zip")
    if(Test-Path $zip){ Remove-Item $zip -Force }
    try{
      Compress-Archive -Path (Join-Path $d.FullName '*') -DestinationPath $zip -Force
      Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue
      $done += "zipped+removed:$($d.Name)"
    }catch{
      $done += "zip_failed:$($d.Name)"
    }
  } elseif($Purge){
    try{ Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue; $done += "purged:$($d.Name)" }catch{ $done += "purge_failed:$($d.Name)" }
  } else {
    $done += "eligible:$($d.Name)"
  }
}
if(Get-Command Write-JsonLog -ea SilentlyContinue){
  Write-JsonLog -Component "cleanup" -Level "INFO" -Message "uninstall residue check" -Props @{ actions=($done -join ',') }
}
$done -join "`n"

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
param(
  [int]$Days=14,
  [switch]$Zip,
  [switch]$Purge
)
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Parent = Split-Path $Base -Parent
$Removed = Get-ChildItem $Parent -Directory -Filter "Mason2._removed_*" -ea SilentlyContinue
$OutDir = Join-Path $Base "dist\removed"
New-Item $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
$cutoff = (Get-Date).AddDays(-1 * $Days)
$done = @()
foreach($d in $Removed){
  if($d.LastWriteTime -gt $cutoff){ continue }
  if($Zip){
    $zip = Join-Path $OutDir ($d.Name + ".zip")
    if(Test-Path $zip){ Remove-Item $zip -Force }
    try{
      Compress-Archive -Path (Join-Path $d.FullName '*') -DestinationPath $zip -Force
      Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue
      $done += "zipped+removed:$($d.Name)"
    }catch{
      $done += "zip_failed:$($d.Name)"
    }
  } elseif($Purge){
    try{ Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue; $done += "purged:$($d.Name)" }catch{ $done += "purge_failed:$($d.Name)" }
  } else {
    $done += "eligible:$($d.Name)"
  }
}
if(Get-Command Write-JsonLog -ea SilentlyContinue){
  Write-JsonLog -Component "cleanup" -Level "INFO" -Message "uninstall residue check" -Props @{ actions=($done -join ',') }
}
$done -join "`n"

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
param(
  [int]$Days=14,
  [switch]$Zip,
  [switch]$Purge
)
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Parent = Split-Path $Base -Parent
$Removed = Get-ChildItem $Parent -Directory -Filter "Mason2._removed_*" -ea SilentlyContinue
$OutDir = Join-Path $Base "dist\removed"
New-Item $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
$cutoff = (Get-Date).AddDays(-1 * $Days)
$done = @()
foreach($d in $Removed){
  if($d.LastWriteTime -gt $cutoff){ continue }
  if($Zip){
    $zip = Join-Path $OutDir ($d.Name + ".zip")
    if(Test-Path $zip){ Remove-Item $zip -Force }
    try{
      Compress-Archive -Path (Join-Path $d.FullName '*') -DestinationPath $zip -Force
      Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue
      $done += "zipped+removed:$($d.Name)"
    }catch{
      $done += "zip_failed:$($d.Name)"
    }
  } elseif($Purge){
    try{ Remove-Item $d.FullName -Recurse -Force -ea SilentlyContinue; $done += "purged:$($d.Name)" }catch{ $done += "purge_failed:$($d.Name)" }
  } else {
    $done += "eligible:$($d.Name)"
  }
}
if(Get-Command Write-JsonLog -ea SilentlyContinue){
  Write-JsonLog -Component "cleanup" -Level "INFO" -Message "uninstall residue check" -Props @{ actions=($done -join ',') }
}
$done -join "`n"

