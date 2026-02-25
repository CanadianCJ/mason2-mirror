$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$out = Join-Path $Base 'reports\ui_status.json'
$disk = $null
try{
  $ld = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
  if($ld -and $ld.Size){ $disk = [math]::Round(($ld.FreeSpace*100.0)/$ld.Size,2) }
}catch{}
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$hb = $null; if(Test-Path (Join-Path $Base 'reports\cadence.jsonl')){ try{ $hb=(Get-Content (Join-Path $Base 'reports\cadence.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$st = [pscustomobject]@{
  ts = (Get-Date).ToString('s')
  disk_free_pct = $disk
  health = $hi
  last_heartbeat = $hb
}
($st | ConvertTo-Json -Depth 6) | Out-File -FilePath $out -Encoding UTF8
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$out = Join-Path $Base 'reports\ui_status.json'
$disk = $null
try{
  $ld = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
  if($ld -and $ld.Size){ $disk = [math]::Round(($ld.FreeSpace*100.0)/$ld.Size,2) }
}catch{}
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$hb = $null; if(Test-Path (Join-Path $Base 'reports\cadence.jsonl')){ try{ $hb=(Get-Content (Join-Path $Base 'reports\cadence.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$st = [pscustomobject]@{
  ts = (Get-Date).ToString('s')
  disk_free_pct = $disk
  health = $hi
  last_heartbeat = $hb
}
($st | ConvertTo-Json -Depth 6) | Out-File -FilePath $out -Encoding UTF8
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$out = Join-Path $Base 'reports\ui_status.json'
$disk = $null
try{
  $ld = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
  if($ld -and $ld.Size){ $disk = [math]::Round(($ld.FreeSpace*100.0)/$ld.Size,2) }
}catch{}
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$hb = $null; if(Test-Path (Join-Path $Base 'reports\cadence.jsonl')){ try{ $hb=(Get-Content (Join-Path $Base 'reports\cadence.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$st = [pscustomobject]@{
  ts = (Get-Date).ToString('s')
  disk_free_pct = $disk
  health = $hi
  last_heartbeat = $hb
}
($st | ConvertTo-Json -Depth 6) | Out-File -FilePath $out -Encoding UTF8
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$out = Join-Path $Base 'reports\ui_status.json'
$disk = $null
try{
  $ld = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
  if($ld -and $ld.Size){ $disk = [math]::Round(($ld.FreeSpace*100.0)/$ld.Size,2) }
}catch{}
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$hb = $null; if(Test-Path (Join-Path $Base 'reports\cadence.jsonl')){ try{ $hb=(Get-Content (Join-Path $Base 'reports\cadence.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$st = [pscustomobject]@{
  ts = (Get-Date).ToString('s')
  disk_free_pct = $disk
  health = $hi
  last_heartbeat = $hb
}
($st | ConvertTo-Json -Depth 6) | Out-File -FilePath $out -Encoding UTF8
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$out = Join-Path $Base 'reports\ui_status.json'
$disk = $null
try{
  $ld = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
  if($ld -and $ld.Size){ $disk = [math]::Round(($ld.FreeSpace*100.0)/$ld.Size,2) }
}catch{}
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$hb = $null; if(Test-Path (Join-Path $Base 'reports\cadence.jsonl')){ try{ $hb=(Get-Content (Join-Path $Base 'reports\cadence.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$st = [pscustomobject]@{
  ts = (Get-Date).ToString('s')
  disk_free_pct = $disk
  health = $hi
  last_heartbeat = $hb
}
($st | ConvertTo-Json -Depth 6) | Out-File -FilePath $out -Encoding UTF8
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$out = Join-Path $Base 'reports\ui_status.json'
$disk = $null
try{
  $ld = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
  if($ld -and $ld.Size){ $disk = [math]::Round(($ld.FreeSpace*100.0)/$ld.Size,2) }
}catch{}
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$hb = $null; if(Test-Path (Join-Path $Base 'reports\cadence.jsonl')){ try{ $hb=(Get-Content (Join-Path $Base 'reports\cadence.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$st = [pscustomobject]@{
  ts = (Get-Date).ToString('s')
  disk_free_pct = $disk
  health = $hi
  last_heartbeat = $hb
}
($st | ConvertTo-Json -Depth 6) | Out-File -FilePath $out -Encoding UTF8
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$out = Join-Path $Base 'reports\ui_status.json'
$disk = $null
try{
  $ld = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
  if($ld -and $ld.Size){ $disk = [math]::Round(($ld.FreeSpace*100.0)/$ld.Size,2) }
}catch{}
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$hb = $null; if(Test-Path (Join-Path $Base 'reports\cadence.jsonl')){ try{ $hb=(Get-Content (Join-Path $Base 'reports\cadence.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$st = [pscustomobject]@{
  ts = (Get-Date).ToString('s')
  disk_free_pct = $disk
  health = $hi
  last_heartbeat = $hb
}
($st | ConvertTo-Json -Depth 6) | Out-File -FilePath $out -Encoding UTF8
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$out = Join-Path $Base 'reports\ui_status.json'
$disk = $null
try{
  $ld = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
  if($ld -and $ld.Size){ $disk = [math]::Round(($ld.FreeSpace*100.0)/$ld.Size,2) }
}catch{}
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$hb = $null; if(Test-Path (Join-Path $Base 'reports\cadence.jsonl')){ try{ $hb=(Get-Content (Join-Path $Base 'reports\cadence.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$st = [pscustomobject]@{
  ts = (Get-Date).ToString('s')
  disk_free_pct = $disk
  health = $hi
  last_heartbeat = $hb
}
($st | ConvertTo-Json -Depth 6) | Out-File -FilePath $out -Encoding UTF8
