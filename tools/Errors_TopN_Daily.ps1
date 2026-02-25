# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
$errs = @{}
if(Test-Path $log){
  Get-Content $log -ErrorAction SilentlyContinue | Select-String -SimpleMatch $day | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json }catch{ return }
    if($j.rc -and $j.rc -ne 0){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $errs[$k]){ $errs[$k]=0 }; $errs[$k] += 1
    }
  }
}
$top = $errs.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $Top
Write-JsonLineSafe -Path (Join-Path $Base 'reports\errors_topn.jsonl') -Obj @{ ts=$now.ToString('s'); kind='errors_topn'; day=$day; items=$top }

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
$errs = @{}
if(Test-Path $log){
  Get-Content $log -ErrorAction SilentlyContinue | Select-String -SimpleMatch $day | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json }catch{ return }
    if($j.rc -and $j.rc -ne 0){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $errs[$k]){ $errs[$k]=0 }; $errs[$k] += 1
    }
  }
}
$top = $errs.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $Top
Write-JsonLineSafe -Path (Join-Path $Base 'reports\errors_topn.jsonl') -Obj @{ ts=$now.ToString('s'); kind='errors_topn'; day=$day; items=$top }

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
$errs = @{}
if(Test-Path $log){
  Get-Content $log -ErrorAction SilentlyContinue | Select-String -SimpleMatch $day | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json }catch{ return }
    if($j.rc -and $j.rc -ne 0){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $errs[$k]){ $errs[$k]=0 }; $errs[$k] += 1
    }
  }
}
$top = $errs.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $Top
Write-JsonLineSafe -Path (Join-Path $Base 'reports\errors_topn.jsonl') -Obj @{ ts=$now.ToString('s'); kind='errors_topn'; day=$day; items=$top }

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
$errs = @{}
if(Test-Path $log){
  Get-Content $log -ErrorAction SilentlyContinue | Select-String -SimpleMatch $day | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json }catch{ return }
    if($j.rc -and $j.rc -ne 0){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $errs[$k]){ $errs[$k]=0 }; $errs[$k] += 1
    }
  }
}
$top = $errs.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $Top
Write-JsonLineSafe -Path (Join-Path $Base 'reports\errors_topn.jsonl') -Obj @{ ts=$now.ToString('s'); kind='errors_topn'; day=$day; items=$top }

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
$errs = @{}
if(Test-Path $log){
  Get-Content $log -ErrorAction SilentlyContinue | Select-String -SimpleMatch $day | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json }catch{ return }
    if($j.rc -and $j.rc -ne 0){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $errs[$k]){ $errs[$k]=0 }; $errs[$k] += 1
    }
  }
}
$top = $errs.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $Top
Write-JsonLineSafe -Path (Join-Path $Base 'reports\errors_topn.jsonl') -Obj @{ ts=$now.ToString('s'); kind='errors_topn'; day=$day; items=$top }

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
$errs = @{}
if(Test-Path $log){
  Get-Content $log -ErrorAction SilentlyContinue | Select-String -SimpleMatch $day | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json }catch{ return }
    if($j.rc -and $j.rc -ne 0){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $errs[$k]){ $errs[$k]=0 }; $errs[$k] += 1
    }
  }
}
$top = $errs.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $Top
Write-JsonLineSafe -Path (Join-Path $Base 'reports\errors_topn.jsonl') -Obj @{ ts=$now.ToString('s'); kind='errors_topn'; day=$day; items=$top }

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
$errs = @{}
if(Test-Path $log){
  Get-Content $log -ErrorAction SilentlyContinue | Select-String -SimpleMatch $day | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json }catch{ return }
    if($j.rc -and $j.rc -ne 0){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $errs[$k]){ $errs[$k]=0 }; $errs[$k] += 1
    }
  }
}
$top = $errs.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $Top
Write-JsonLineSafe -Path (Join-Path $Base 'reports\errors_topn.jsonl') -Obj @{ ts=$now.ToString('s'); kind='errors_topn'; day=$day; items=$top }

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$log = Join-Path $Base 'reports\exec_log.jsonl'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
$errs = @{}
if(Test-Path $log){
  Get-Content $log -ErrorAction SilentlyContinue | Select-String -SimpleMatch $day | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json }catch{ return }
    if($j.rc -and $j.rc -ne 0){
      $k = if($j.file){ $j.file } else { 'unknown' }
      if(-not $errs[$k]){ $errs[$k]=0 }; $errs[$k] += 1
    }
  }
}
$top = $errs.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $Top
Write-JsonLineSafe -Path (Join-Path $Base 'reports\errors_topn.jsonl') -Obj @{ ts=$now.ToString('s'); kind='errors_topn'; day=$day; items=$top }

