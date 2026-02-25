$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$off=$null; $src=$null
# Prefer latest timesync.jsonl
$tsFile = Join-Path $Base 'reports\timesync.jsonl'
if(Test-Path $tsFile){
  try {
    $j = Get-Content $tsFile -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json } catch{$null} } | Select-Object -Last 1
    if($j){ $off=$j.offset_s; $src=$j.source }
  } catch {}
}
# Fallback to w32tm query
if($off -eq $null){
  try {
    $out = (& w32tm /query /status 2>$null) -as [string[]]
    foreach($ln in $out){
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $off=[double]$Matches[1] }
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
    }
  } catch {}
}
$action='skip'
if($off -ne $null -and [math]::Abs($off) -gt $ThresholdS){
  try { & w32tm /resync /nowait | Out-Null; $action='resync' } catch { $action='resync_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timedrift.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timedrift'; offset_s=$off; source=$src; threshold_s=$ThresholdS; action=$action }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[double]$ThresholdS=0.5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$off=$null; $src=$null
# Prefer latest timesync.jsonl
$tsFile = Join-Path $Base 'reports\timesync.jsonl'
if(Test-Path $tsFile){
  try {
    $j = Get-Content $tsFile -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json } catch{$null} } | Select-Object -Last 1
    if($j){ $off=$j.offset_s; $src=$j.source }
  } catch {}
}
# Fallback to w32tm query
if($off -eq $null){
  try {
    $out = (& w32tm /query /status 2>$null) -as [string[]]
    foreach($ln in $out){
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $off=[double]$Matches[1] }
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
    }
  } catch {}
}
$action='skip'
if($off -ne $null -and [math]::Abs($off) -gt $ThresholdS){
  try { & w32tm /resync /nowait | Out-Null; $action='resync' } catch { $action='resync_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timedrift.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timedrift'; offset_s=$off; source=$src; threshold_s=$ThresholdS; action=$action }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[double]$ThresholdS=0.5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$off=$null; $src=$null
# Prefer latest timesync.jsonl
$tsFile = Join-Path $Base 'reports\timesync.jsonl'
if(Test-Path $tsFile){
  try {
    $j = Get-Content $tsFile -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json } catch{$null} } | Select-Object -Last 1
    if($j){ $off=$j.offset_s; $src=$j.source }
  } catch {}
}
# Fallback to w32tm query
if($off -eq $null){
  try {
    $out = (& w32tm /query /status 2>$null) -as [string[]]
    foreach($ln in $out){
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $off=[double]$Matches[1] }
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
    }
  } catch {}
}
$action='skip'
if($off -ne $null -and [math]::Abs($off) -gt $ThresholdS){
  try { & w32tm /resync /nowait | Out-Null; $action='resync' } catch { $action='resync_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timedrift.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timedrift'; offset_s=$off; source=$src; threshold_s=$ThresholdS; action=$action }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[double]$ThresholdS=0.5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$off=$null; $src=$null
# Prefer latest timesync.jsonl
$tsFile = Join-Path $Base 'reports\timesync.jsonl'
if(Test-Path $tsFile){
  try {
    $j = Get-Content $tsFile -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json } catch{$null} } | Select-Object -Last 1
    if($j){ $off=$j.offset_s; $src=$j.source }
  } catch {}
}
# Fallback to w32tm query
if($off -eq $null){
  try {
    $out = (& w32tm /query /status 2>$null) -as [string[]]
    foreach($ln in $out){
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $off=[double]$Matches[1] }
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
    }
  } catch {}
}
$action='skip'
if($off -ne $null -and [math]::Abs($off) -gt $ThresholdS){
  try { & w32tm /resync /nowait | Out-Null; $action='resync' } catch { $action='resync_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timedrift.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timedrift'; offset_s=$off; source=$src; threshold_s=$ThresholdS; action=$action }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[double]$ThresholdS=0.5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$off=$null; $src=$null
# Prefer latest timesync.jsonl
$tsFile = Join-Path $Base 'reports\timesync.jsonl'
if(Test-Path $tsFile){
  try {
    $j = Get-Content $tsFile -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json } catch{$null} } | Select-Object -Last 1
    if($j){ $off=$j.offset_s; $src=$j.source }
  } catch {}
}
# Fallback to w32tm query
if($off -eq $null){
  try {
    $out = (& w32tm /query /status 2>$null) -as [string[]]
    foreach($ln in $out){
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $off=[double]$Matches[1] }
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
    }
  } catch {}
}
$action='skip'
if($off -ne $null -and [math]::Abs($off) -gt $ThresholdS){
  try { & w32tm /resync /nowait | Out-Null; $action='resync' } catch { $action='resync_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timedrift.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timedrift'; offset_s=$off; source=$src; threshold_s=$ThresholdS; action=$action }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[double]$ThresholdS=0.5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$off=$null; $src=$null
# Prefer latest timesync.jsonl
$tsFile = Join-Path $Base 'reports\timesync.jsonl'
if(Test-Path $tsFile){
  try {
    $j = Get-Content $tsFile -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json } catch{$null} } | Select-Object -Last 1
    if($j){ $off=$j.offset_s; $src=$j.source }
  } catch {}
}
# Fallback to w32tm query
if($off -eq $null){
  try {
    $out = (& w32tm /query /status 2>$null) -as [string[]]
    foreach($ln in $out){
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $off=[double]$Matches[1] }
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
    }
  } catch {}
}
$action='skip'
if($off -ne $null -and [math]::Abs($off) -gt $ThresholdS){
  try { & w32tm /resync /nowait | Out-Null; $action='resync' } catch { $action='resync_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timedrift.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timedrift'; offset_s=$off; source=$src; threshold_s=$ThresholdS; action=$action }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[double]$ThresholdS=0.5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$off=$null; $src=$null
# Prefer latest timesync.jsonl
$tsFile = Join-Path $Base 'reports\timesync.jsonl'
if(Test-Path $tsFile){
  try {
    $j = Get-Content $tsFile -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json } catch{$null} } | Select-Object -Last 1
    if($j){ $off=$j.offset_s; $src=$j.source }
  } catch {}
}
# Fallback to w32tm query
if($off -eq $null){
  try {
    $out = (& w32tm /query /status 2>$null) -as [string[]]
    foreach($ln in $out){
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $off=[double]$Matches[1] }
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
    }
  } catch {}
}
$action='skip'
if($off -ne $null -and [math]::Abs($off) -gt $ThresholdS){
  try { & w32tm /resync /nowait | Out-Null; $action='resync' } catch { $action='resync_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timedrift.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timedrift'; offset_s=$off; source=$src; threshold_s=$ThresholdS; action=$action }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$off=$null; $src=$null
# Prefer latest timesync.jsonl
$tsFile = Join-Path $Base 'reports\timesync.jsonl'
if(Test-Path $tsFile){
  try {
    $j = Get-Content $tsFile -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json } catch{$null} } | Select-Object -Last 1
    if($j){ $off=$j.offset_s; $src=$j.source }
  } catch {}
}
# Fallback to w32tm query
if($off -eq $null){
  try {
    $out = (& w32tm /query /status 2>$null) -as [string[]]
    foreach($ln in $out){
      if($ln -match 'Offset:\s*([-\d\.]+)s'){ $off=[double]$Matches[1] }
      if($ln -match 'Source:\s*(.+)$'){ $src=$Matches[1].Trim() }
    }
  } catch {}
}
$action='skip'
if($off -ne $null -and [math]::Abs($off) -gt $ThresholdS){
  try { & w32tm /resync /nowait | Out-Null; $action='resync' } catch { $action='resync_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\timedrift.jsonl') -Obj @{ ts=$now.ToString('s'); kind='timedrift'; offset_s=$off; source=$src; threshold_s=$ThresholdS; action=$action }
