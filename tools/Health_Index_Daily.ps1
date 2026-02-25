# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$disk = Get-DiskFreePct $Base
$errors = 0; $driftWarn=0
$errLog = Join-Path $Base 'reports\exec_log.jsonl'
if(Test-Path $errLog){
  $today = $now.ToString('yyyy-MM-dd')
  $errors = (Select-String -Path $errLog -SimpleMatch $today | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count
}
$driftLog = Join-Path $Base 'reports\schedule_drift.jsonl'
if(Test-Path $driftLog){
  $driftWarn = (Get-Content $driftLog -Tail 200 -ErrorAction SilentlyContinue | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.severity -eq 'warn' } | Measure-Object).Count
}
$score = 100
if($disk -lt 20){ $score -= 25 } elseif($disk -lt 10){ $score -= 50 }
$score -= [math]::Min($errors*3,30)
$score -= [math]::Min($driftWarn*2,20)
if($score -lt 0){ $score = 0 }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\health_index.jsonl') -Obj @{ ts=$now.ToString('s'); kind='health_index'; score=$score; disk_free_pct=$disk; errors=$errors; drift_warn=$driftWarn }

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$disk = Get-DiskFreePct $Base
$errors = 0; $driftWarn=0
$errLog = Join-Path $Base 'reports\exec_log.jsonl'
if(Test-Path $errLog){
  $today = $now.ToString('yyyy-MM-dd')
  $errors = (Select-String -Path $errLog -SimpleMatch $today | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count
}
$driftLog = Join-Path $Base 'reports\schedule_drift.jsonl'
if(Test-Path $driftLog){
  $driftWarn = (Get-Content $driftLog -Tail 200 -ErrorAction SilentlyContinue | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.severity -eq 'warn' } | Measure-Object).Count
}
$score = 100
if($disk -lt 20){ $score -= 25 } elseif($disk -lt 10){ $score -= 50 }
$score -= [math]::Min($errors*3,30)
$score -= [math]::Min($driftWarn*2,20)
if($score -lt 0){ $score = 0 }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\health_index.jsonl') -Obj @{ ts=$now.ToString('s'); kind='health_index'; score=$score; disk_free_pct=$disk; errors=$errors; drift_warn=$driftWarn }

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$disk = Get-DiskFreePct $Base
$errors = 0; $driftWarn=0
$errLog = Join-Path $Base 'reports\exec_log.jsonl'
if(Test-Path $errLog){
  $today = $now.ToString('yyyy-MM-dd')
  $errors = (Select-String -Path $errLog -SimpleMatch $today | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count
}
$driftLog = Join-Path $Base 'reports\schedule_drift.jsonl'
if(Test-Path $driftLog){
  $driftWarn = (Get-Content $driftLog -Tail 200 -ErrorAction SilentlyContinue | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.severity -eq 'warn' } | Measure-Object).Count
}
$score = 100
if($disk -lt 20){ $score -= 25 } elseif($disk -lt 10){ $score -= 50 }
$score -= [math]::Min($errors*3,30)
$score -= [math]::Min($driftWarn*2,20)
if($score -lt 0){ $score = 0 }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\health_index.jsonl') -Obj @{ ts=$now.ToString('s'); kind='health_index'; score=$score; disk_free_pct=$disk; errors=$errors; drift_warn=$driftWarn }

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$disk = Get-DiskFreePct $Base
$errors = 0; $driftWarn=0
$errLog = Join-Path $Base 'reports\exec_log.jsonl'
if(Test-Path $errLog){
  $today = $now.ToString('yyyy-MM-dd')
  $errors = (Select-String -Path $errLog -SimpleMatch $today | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count
}
$driftLog = Join-Path $Base 'reports\schedule_drift.jsonl'
if(Test-Path $driftLog){
  $driftWarn = (Get-Content $driftLog -Tail 200 -ErrorAction SilentlyContinue | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.severity -eq 'warn' } | Measure-Object).Count
}
$score = 100
if($disk -lt 20){ $score -= 25 } elseif($disk -lt 10){ $score -= 50 }
$score -= [math]::Min($errors*3,30)
$score -= [math]::Min($driftWarn*2,20)
if($score -lt 0){ $score = 0 }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\health_index.jsonl') -Obj @{ ts=$now.ToString('s'); kind='health_index'; score=$score; disk_free_pct=$disk; errors=$errors; drift_warn=$driftWarn }

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$disk = Get-DiskFreePct $Base
$errors = 0; $driftWarn=0
$errLog = Join-Path $Base 'reports\exec_log.jsonl'
if(Test-Path $errLog){
  $today = $now.ToString('yyyy-MM-dd')
  $errors = (Select-String -Path $errLog -SimpleMatch $today | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count
}
$driftLog = Join-Path $Base 'reports\schedule_drift.jsonl'
if(Test-Path $driftLog){
  $driftWarn = (Get-Content $driftLog -Tail 200 -ErrorAction SilentlyContinue | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.severity -eq 'warn' } | Measure-Object).Count
}
$score = 100
if($disk -lt 20){ $score -= 25 } elseif($disk -lt 10){ $score -= 50 }
$score -= [math]::Min($errors*3,30)
$score -= [math]::Min($driftWarn*2,20)
if($score -lt 0){ $score = 0 }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\health_index.jsonl') -Obj @{ ts=$now.ToString('s'); kind='health_index'; score=$score; disk_free_pct=$disk; errors=$errors; drift_warn=$driftWarn }

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$disk = Get-DiskFreePct $Base
$errors = 0; $driftWarn=0
$errLog = Join-Path $Base 'reports\exec_log.jsonl'
if(Test-Path $errLog){
  $today = $now.ToString('yyyy-MM-dd')
  $errors = (Select-String -Path $errLog -SimpleMatch $today | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count
}
$driftLog = Join-Path $Base 'reports\schedule_drift.jsonl'
if(Test-Path $driftLog){
  $driftWarn = (Get-Content $driftLog -Tail 200 -ErrorAction SilentlyContinue | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.severity -eq 'warn' } | Measure-Object).Count
}
$score = 100
if($disk -lt 20){ $score -= 25 } elseif($disk -lt 10){ $score -= 50 }
$score -= [math]::Min($errors*3,30)
$score -= [math]::Min($driftWarn*2,20)
if($score -lt 0){ $score = 0 }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\health_index.jsonl') -Obj @{ ts=$now.ToString('s'); kind='health_index'; score=$score; disk_free_pct=$disk; errors=$errors; drift_warn=$driftWarn }

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$disk = Get-DiskFreePct $Base
$errors = 0; $driftWarn=0
$errLog = Join-Path $Base 'reports\exec_log.jsonl'
if(Test-Path $errLog){
  $today = $now.ToString('yyyy-MM-dd')
  $errors = (Select-String -Path $errLog -SimpleMatch $today | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count
}
$driftLog = Join-Path $Base 'reports\schedule_drift.jsonl'
if(Test-Path $driftLog){
  $driftWarn = (Get-Content $driftLog -Tail 200 -ErrorAction SilentlyContinue | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.severity -eq 'warn' } | Measure-Object).Count
}
$score = 100
if($disk -lt 20){ $score -= 25 } elseif($disk -lt 10){ $score -= 50 }
$score -= [math]::Min($errors*3,30)
$score -= [math]::Min($driftWarn*2,20)
if($score -lt 0){ $score = 0 }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\health_index.jsonl') -Obj @{ ts=$now.ToString('s'); kind='health_index'; score=$score; disk_free_pct=$disk; errors=$errors; drift_warn=$driftWarn }

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$disk = Get-DiskFreePct $Base
$errors = 0; $driftWarn=0
$errLog = Join-Path $Base 'reports\exec_log.jsonl'
if(Test-Path $errLog){
  $today = $now.ToString('yyyy-MM-dd')
  $errors = (Select-String -Path $errLog -SimpleMatch $today | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count
}
$driftLog = Join-Path $Base 'reports\schedule_drift.jsonl'
if(Test-Path $driftLog){
  $driftWarn = (Get-Content $driftLog -Tail 200 -ErrorAction SilentlyContinue | ForEach-Object {
    try{ ($_ -as [string])|ConvertFrom-Json }catch{ $null }
  } | Where-Object { $_ -and $_.severity -eq 'warn' } | Measure-Object).Count
}
$score = 100
if($disk -lt 20){ $score -= 25 } elseif($disk -lt 10){ $score -= 50 }
$score -= [math]::Min($errors*3,30)
$score -= [math]::Min($driftWarn*2,20)
if($score -lt 0){ $score = 0 }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\health_index.jsonl') -Obj @{ ts=$now.ToString('s'); kind='health_index'; score=$score; disk_free_pct=$disk; errors=$errors; drift_warn=$driftWarn }

