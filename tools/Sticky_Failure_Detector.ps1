# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60,[int]$MinCount=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $log)){ exit 0 }
$now=Get-Date; $cut=$now.AddMinutes(-$WindowMin)
$fail = @{}
Get-Content $log -Tail 2000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  if($j.rc -and $j.rc -ne 0 -and $j.ts_end){
    try{ $t=[datetime]$j.ts_end }catch{ return }
    if($t -ge $cut){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $fail[$k]){ $fail[$k]=@() }
      $fail[$k] += $t
    }
  }
}
$fail.Keys | ForEach-Object {
  $k = $_; $c = ($fail[$k] | Measure-Object).Count
  if($c -ge $MinCount){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\sticky_failures.jsonl') -Obj @{ ts=$now.ToString('s'); kind='sticky_failure'; file=$k; count=$c; window_min=$WindowMin }
  }
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60,[int]$MinCount=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $log)){ exit 0 }
$now=Get-Date; $cut=$now.AddMinutes(-$WindowMin)
$fail = @{}
Get-Content $log -Tail 2000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  if($j.rc -and $j.rc -ne 0 -and $j.ts_end){
    try{ $t=[datetime]$j.ts_end }catch{ return }
    if($t -ge $cut){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $fail[$k]){ $fail[$k]=@() }
      $fail[$k] += $t
    }
  }
}
$fail.Keys | ForEach-Object {
  $k = $_; $c = ($fail[$k] | Measure-Object).Count
  if($c -ge $MinCount){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\sticky_failures.jsonl') -Obj @{ ts=$now.ToString('s'); kind='sticky_failure'; file=$k; count=$c; window_min=$WindowMin }
  }
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60,[int]$MinCount=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $log)){ exit 0 }
$now=Get-Date; $cut=$now.AddMinutes(-$WindowMin)
$fail = @{}
Get-Content $log -Tail 2000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  if($j.rc -and $j.rc -ne 0 -and $j.ts_end){
    try{ $t=[datetime]$j.ts_end }catch{ return }
    if($t -ge $cut){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $fail[$k]){ $fail[$k]=@() }
      $fail[$k] += $t
    }
  }
}
$fail.Keys | ForEach-Object {
  $k = $_; $c = ($fail[$k] | Measure-Object).Count
  if($c -ge $MinCount){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\sticky_failures.jsonl') -Obj @{ ts=$now.ToString('s'); kind='sticky_failure'; file=$k; count=$c; window_min=$WindowMin }
  }
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60,[int]$MinCount=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $log)){ exit 0 }
$now=Get-Date; $cut=$now.AddMinutes(-$WindowMin)
$fail = @{}
Get-Content $log -Tail 2000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  if($j.rc -and $j.rc -ne 0 -and $j.ts_end){
    try{ $t=[datetime]$j.ts_end }catch{ return }
    if($t -ge $cut){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $fail[$k]){ $fail[$k]=@() }
      $fail[$k] += $t
    }
  }
}
$fail.Keys | ForEach-Object {
  $k = $_; $c = ($fail[$k] | Measure-Object).Count
  if($c -ge $MinCount){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\sticky_failures.jsonl') -Obj @{ ts=$now.ToString('s'); kind='sticky_failure'; file=$k; count=$c; window_min=$WindowMin }
  }
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60,[int]$MinCount=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $log)){ exit 0 }
$now=Get-Date; $cut=$now.AddMinutes(-$WindowMin)
$fail = @{}
Get-Content $log -Tail 2000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  if($j.rc -and $j.rc -ne 0 -and $j.ts_end){
    try{ $t=[datetime]$j.ts_end }catch{ return }
    if($t -ge $cut){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $fail[$k]){ $fail[$k]=@() }
      $fail[$k] += $t
    }
  }
}
$fail.Keys | ForEach-Object {
  $k = $_; $c = ($fail[$k] | Measure-Object).Count
  if($c -ge $MinCount){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\sticky_failures.jsonl') -Obj @{ ts=$now.ToString('s'); kind='sticky_failure'; file=$k; count=$c; window_min=$WindowMin }
  }
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60,[int]$MinCount=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $log)){ exit 0 }
$now=Get-Date; $cut=$now.AddMinutes(-$WindowMin)
$fail = @{}
Get-Content $log -Tail 2000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  if($j.rc -and $j.rc -ne 0 -and $j.ts_end){
    try{ $t=[datetime]$j.ts_end }catch{ return }
    if($t -ge $cut){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $fail[$k]){ $fail[$k]=@() }
      $fail[$k] += $t
    }
  }
}
$fail.Keys | ForEach-Object {
  $k = $_; $c = ($fail[$k] | Measure-Object).Count
  if($c -ge $MinCount){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\sticky_failures.jsonl') -Obj @{ ts=$now.ToString('s'); kind='sticky_failure'; file=$k; count=$c; window_min=$WindowMin }
  }
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60,[int]$MinCount=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $log)){ exit 0 }
$now=Get-Date; $cut=$now.AddMinutes(-$WindowMin)
$fail = @{}
Get-Content $log -Tail 2000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  if($j.rc -and $j.rc -ne 0 -and $j.ts_end){
    try{ $t=[datetime]$j.ts_end }catch{ return }
    if($t -ge $cut){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $fail[$k]){ $fail[$k]=@() }
      $fail[$k] += $t
    }
  }
}
$fail.Keys | ForEach-Object {
  $k = $_; $c = ($fail[$k] | Measure-Object).Count
  if($c -ge $MinCount){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\sticky_failures.jsonl') -Obj @{ ts=$now.ToString('s'); kind='sticky_failure'; file=$k; count=$c; window_min=$WindowMin }
  }
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60,[int]$MinCount=3)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $log)){ exit 0 }
$now=Get-Date; $cut=$now.AddMinutes(-$WindowMin)
$fail = @{}
Get-Content $log -Tail 2000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  if($j.rc -and $j.rc -ne 0 -and $j.ts_end){
    try{ $t=[datetime]$j.ts_end }catch{ return }
    if($t -ge $cut){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $fail[$k]){ $fail[$k]=@() }
      $fail[$k] += $t
    }
  }
}
$fail.Keys | ForEach-Object {
  $k = $_; $c = ($fail[$k] | Measure-Object).Count
  if($c -ge $MinCount){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\sticky_failures.jsonl') -Obj @{ ts=$now.ToString('s'); kind='sticky_failure'; file=$k; count=$c; window_min=$WindowMin }
  }
}

