# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep=Join-Path $Base 'reports'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
function CountLinesLike($p,$s){ if(-not(Test-Path $p)){return 0}; try{ (Select-String -Path $p -SimpleMatch $s -ErrorAction SilentlyContinue | Measure-Object).Count }catch{0} }
$cad=CountLinesLike (Join-Path $rep 'cadence.jsonl') $day
$unpack=CountLinesLike (Join-Path $rep 'verify_unpack.jsonl') $day
$drift=CountLinesLike (Join-Path $rep 'schedule_drift.jsonl') $day
$gates=CountLinesLike (Join-Path $rep 'ops_gates.jsonl') $day
$diskPct=$null; $dh=Join-Path $Base 'logs\telemetry\disk_health.jsonl'
if(Test-Path $dh){ try{ $diskPct = (Get-Content $dh -Tail 1 | ConvertFrom-Json).free_pct }catch{} }
Write-JsonLineSafe -Path (Join-Path $rep 'telemetry_daily.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='daily_summary'; date=$day; cadence=$cad; unpack=$unpack; drift=$drift; gates=$gates; disk_free_pct=$diskPct
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep=Join-Path $Base 'reports'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
function CountLinesLike($p,$s){ if(-not(Test-Path $p)){return 0}; try{ (Select-String -Path $p -SimpleMatch $s -ErrorAction SilentlyContinue | Measure-Object).Count }catch{0} }
$cad=CountLinesLike (Join-Path $rep 'cadence.jsonl') $day
$unpack=CountLinesLike (Join-Path $rep 'verify_unpack.jsonl') $day
$drift=CountLinesLike (Join-Path $rep 'schedule_drift.jsonl') $day
$gates=CountLinesLike (Join-Path $rep 'ops_gates.jsonl') $day
$diskPct=$null; $dh=Join-Path $Base 'logs\telemetry\disk_health.jsonl'
if(Test-Path $dh){ try{ $diskPct = (Get-Content $dh -Tail 1 | ConvertFrom-Json).free_pct }catch{} }
Write-JsonLineSafe -Path (Join-Path $rep 'telemetry_daily.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='daily_summary'; date=$day; cadence=$cad; unpack=$unpack; drift=$drift; gates=$gates; disk_free_pct=$diskPct
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep=Join-Path $Base 'reports'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
function CountLinesLike($p,$s){ if(-not(Test-Path $p)){return 0}; try{ (Select-String -Path $p -SimpleMatch $s -ErrorAction SilentlyContinue | Measure-Object).Count }catch{0} }
$cad=CountLinesLike (Join-Path $rep 'cadence.jsonl') $day
$unpack=CountLinesLike (Join-Path $rep 'verify_unpack.jsonl') $day
$drift=CountLinesLike (Join-Path $rep 'schedule_drift.jsonl') $day
$gates=CountLinesLike (Join-Path $rep 'ops_gates.jsonl') $day
$diskPct=$null; $dh=Join-Path $Base 'logs\telemetry\disk_health.jsonl'
if(Test-Path $dh){ try{ $diskPct = (Get-Content $dh -Tail 1 | ConvertFrom-Json).free_pct }catch{} }
Write-JsonLineSafe -Path (Join-Path $rep 'telemetry_daily.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='daily_summary'; date=$day; cadence=$cad; unpack=$unpack; drift=$drift; gates=$gates; disk_free_pct=$diskPct
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep=Join-Path $Base 'reports'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
function CountLinesLike($p,$s){ if(-not(Test-Path $p)){return 0}; try{ (Select-String -Path $p -SimpleMatch $s -ErrorAction SilentlyContinue | Measure-Object).Count }catch{0} }
$cad=CountLinesLike (Join-Path $rep 'cadence.jsonl') $day
$unpack=CountLinesLike (Join-Path $rep 'verify_unpack.jsonl') $day
$drift=CountLinesLike (Join-Path $rep 'schedule_drift.jsonl') $day
$gates=CountLinesLike (Join-Path $rep 'ops_gates.jsonl') $day
$diskPct=$null; $dh=Join-Path $Base 'logs\telemetry\disk_health.jsonl'
if(Test-Path $dh){ try{ $diskPct = (Get-Content $dh -Tail 1 | ConvertFrom-Json).free_pct }catch{} }
Write-JsonLineSafe -Path (Join-Path $rep 'telemetry_daily.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='daily_summary'; date=$day; cadence=$cad; unpack=$unpack; drift=$drift; gates=$gates; disk_free_pct=$diskPct
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep=Join-Path $Base 'reports'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
function CountLinesLike($p,$s){ if(-not(Test-Path $p)){return 0}; try{ (Select-String -Path $p -SimpleMatch $s -ErrorAction SilentlyContinue | Measure-Object).Count }catch{0} }
$cad=CountLinesLike (Join-Path $rep 'cadence.jsonl') $day
$unpack=CountLinesLike (Join-Path $rep 'verify_unpack.jsonl') $day
$drift=CountLinesLike (Join-Path $rep 'schedule_drift.jsonl') $day
$gates=CountLinesLike (Join-Path $rep 'ops_gates.jsonl') $day
$diskPct=$null; $dh=Join-Path $Base 'logs\telemetry\disk_health.jsonl'
if(Test-Path $dh){ try{ $diskPct = (Get-Content $dh -Tail 1 | ConvertFrom-Json).free_pct }catch{} }
Write-JsonLineSafe -Path (Join-Path $rep 'telemetry_daily.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='daily_summary'; date=$day; cadence=$cad; unpack=$unpack; drift=$drift; gates=$gates; disk_free_pct=$diskPct
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep=Join-Path $Base 'reports'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
function CountLinesLike($p,$s){ if(-not(Test-Path $p)){return 0}; try{ (Select-String -Path $p -SimpleMatch $s -ErrorAction SilentlyContinue | Measure-Object).Count }catch{0} }
$cad=CountLinesLike (Join-Path $rep 'cadence.jsonl') $day
$unpack=CountLinesLike (Join-Path $rep 'verify_unpack.jsonl') $day
$drift=CountLinesLike (Join-Path $rep 'schedule_drift.jsonl') $day
$gates=CountLinesLike (Join-Path $rep 'ops_gates.jsonl') $day
$diskPct=$null; $dh=Join-Path $Base 'logs\telemetry\disk_health.jsonl'
if(Test-Path $dh){ try{ $diskPct = (Get-Content $dh -Tail 1 | ConvertFrom-Json).free_pct }catch{} }
Write-JsonLineSafe -Path (Join-Path $rep 'telemetry_daily.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='daily_summary'; date=$day; cadence=$cad; unpack=$unpack; drift=$drift; gates=$gates; disk_free_pct=$diskPct
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep=Join-Path $Base 'reports'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
function CountLinesLike($p,$s){ if(-not(Test-Path $p)){return 0}; try{ (Select-String -Path $p -SimpleMatch $s -ErrorAction SilentlyContinue | Measure-Object).Count }catch{0} }
$cad=CountLinesLike (Join-Path $rep 'cadence.jsonl') $day
$unpack=CountLinesLike (Join-Path $rep 'verify_unpack.jsonl') $day
$drift=CountLinesLike (Join-Path $rep 'schedule_drift.jsonl') $day
$gates=CountLinesLike (Join-Path $rep 'ops_gates.jsonl') $day
$diskPct=$null; $dh=Join-Path $Base 'logs\telemetry\disk_health.jsonl'
if(Test-Path $dh){ try{ $diskPct = (Get-Content $dh -Tail 1 | ConvertFrom-Json).free_pct }catch{} }
Write-JsonLineSafe -Path (Join-Path $rep 'telemetry_daily.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='daily_summary'; date=$day; cadence=$cad; unpack=$unpack; drift=$drift; gates=$gates; disk_free_pct=$diskPct
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep=Join-Path $Base 'reports'
$now=Get-Date; $day=$now.ToString('yyyy-MM-dd')
function CountLinesLike($p,$s){ if(-not(Test-Path $p)){return 0}; try{ (Select-String -Path $p -SimpleMatch $s -ErrorAction SilentlyContinue | Measure-Object).Count }catch{0} }
$cad=CountLinesLike (Join-Path $rep 'cadence.jsonl') $day
$unpack=CountLinesLike (Join-Path $rep 'verify_unpack.jsonl') $day
$drift=CountLinesLike (Join-Path $rep 'schedule_drift.jsonl') $day
$gates=CountLinesLike (Join-Path $rep 'ops_gates.jsonl') $day
$diskPct=$null; $dh=Join-Path $Base 'logs\telemetry\disk_health.jsonl'
if(Test-Path $dh){ try{ $diskPct = (Get-Content $dh -Tail 1 | ConvertFrom-Json).free_pct }catch{} }
Write-JsonLineSafe -Path (Join-Path $rep 'telemetry_daily.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='daily_summary'; date=$day; cadence=$cad; unpack=$unpack; drift=$drift; gates=$gates; disk_free_pct=$diskPct
}

