# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
# Expected (superset; it's OK if some are still missing)
$expect = @(
  'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply',
  'Mason2-DiskHealthDaily','Mason2-Learner-10m','Mason2-Governor-2m','Mason2-Watchdog-1m',
  'Mason2-TopicSync-1m','Mason2-AutoAdvance-3m','Mason2-ScheduleDrift','Mason2-WeeklyRestoreTest',
  'Mason2-LogMaintenance','Mason2-RetrySweeper','Mason2-StuckDetector',
  'Mason2-TelemetrySummaryDaily','Mason2-RoadmapCheckDaily',
  'Mason2-PortableManifestDaily','Mason2-ErrorAggDaily','Mason2-SilenceAlert-5m',
  'Mason2-NetworkProbe-1h','Mason2-TimeSyncDaily','Mason2-TTLSweeperDaily',
  'Mason2-LargeFileWeekly','Mason2-VerifySchedulerHourly','Mason2-HealthIndexDaily'
)
$have = @{}
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $have[$_.TaskName]=$_.State.ToString() }
$missing = @(); $disabled = @()
foreach($e in $expect){
  if(-not $have.ContainsKey($e)){ $missing += $e }
  elseif($have[$e] -eq 'Disabled'){ $disabled += $e }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\scheduler_verify.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='sched_verify'; missing=$missing; disabled=$disabled
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
# Expected (superset; it's OK if some are still missing)
$expect = @(
  'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply',
  'Mason2-DiskHealthDaily','Mason2-Learner-10m','Mason2-Governor-2m','Mason2-Watchdog-1m',
  'Mason2-TopicSync-1m','Mason2-AutoAdvance-3m','Mason2-ScheduleDrift','Mason2-WeeklyRestoreTest',
  'Mason2-LogMaintenance','Mason2-RetrySweeper','Mason2-StuckDetector',
  'Mason2-TelemetrySummaryDaily','Mason2-RoadmapCheckDaily',
  'Mason2-PortableManifestDaily','Mason2-ErrorAggDaily','Mason2-SilenceAlert-5m',
  'Mason2-NetworkProbe-1h','Mason2-TimeSyncDaily','Mason2-TTLSweeperDaily',
  'Mason2-LargeFileWeekly','Mason2-VerifySchedulerHourly','Mason2-HealthIndexDaily'
)
$have = @{}
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $have[$_.TaskName]=$_.State.ToString() }
$missing = @(); $disabled = @()
foreach($e in $expect){
  if(-not $have.ContainsKey($e)){ $missing += $e }
  elseif($have[$e] -eq 'Disabled'){ $disabled += $e }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\scheduler_verify.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='sched_verify'; missing=$missing; disabled=$disabled
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
# Expected (superset; it's OK if some are still missing)
$expect = @(
  'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply',
  'Mason2-DiskHealthDaily','Mason2-Learner-10m','Mason2-Governor-2m','Mason2-Watchdog-1m',
  'Mason2-TopicSync-1m','Mason2-AutoAdvance-3m','Mason2-ScheduleDrift','Mason2-WeeklyRestoreTest',
  'Mason2-LogMaintenance','Mason2-RetrySweeper','Mason2-StuckDetector',
  'Mason2-TelemetrySummaryDaily','Mason2-RoadmapCheckDaily',
  'Mason2-PortableManifestDaily','Mason2-ErrorAggDaily','Mason2-SilenceAlert-5m',
  'Mason2-NetworkProbe-1h','Mason2-TimeSyncDaily','Mason2-TTLSweeperDaily',
  'Mason2-LargeFileWeekly','Mason2-VerifySchedulerHourly','Mason2-HealthIndexDaily'
)
$have = @{}
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $have[$_.TaskName]=$_.State.ToString() }
$missing = @(); $disabled = @()
foreach($e in $expect){
  if(-not $have.ContainsKey($e)){ $missing += $e }
  elseif($have[$e] -eq 'Disabled'){ $disabled += $e }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\scheduler_verify.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='sched_verify'; missing=$missing; disabled=$disabled
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
# Expected (superset; it's OK if some are still missing)
$expect = @(
  'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply',
  'Mason2-DiskHealthDaily','Mason2-Learner-10m','Mason2-Governor-2m','Mason2-Watchdog-1m',
  'Mason2-TopicSync-1m','Mason2-AutoAdvance-3m','Mason2-ScheduleDrift','Mason2-WeeklyRestoreTest',
  'Mason2-LogMaintenance','Mason2-RetrySweeper','Mason2-StuckDetector',
  'Mason2-TelemetrySummaryDaily','Mason2-RoadmapCheckDaily',
  'Mason2-PortableManifestDaily','Mason2-ErrorAggDaily','Mason2-SilenceAlert-5m',
  'Mason2-NetworkProbe-1h','Mason2-TimeSyncDaily','Mason2-TTLSweeperDaily',
  'Mason2-LargeFileWeekly','Mason2-VerifySchedulerHourly','Mason2-HealthIndexDaily'
)
$have = @{}
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $have[$_.TaskName]=$_.State.ToString() }
$missing = @(); $disabled = @()
foreach($e in $expect){
  if(-not $have.ContainsKey($e)){ $missing += $e }
  elseif($have[$e] -eq 'Disabled'){ $disabled += $e }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\scheduler_verify.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='sched_verify'; missing=$missing; disabled=$disabled
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

$now = Get-Date
# Expected (superset; it's OK if some are still missing)
$expect = @(
  'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply',
  'Mason2-DiskHealthDaily','Mason2-Learner-10m','Mason2-Governor-2m','Mason2-Watchdog-1m',
  'Mason2-TopicSync-1m','Mason2-AutoAdvance-3m','Mason2-ScheduleDrift','Mason2-WeeklyRestoreTest',
  'Mason2-LogMaintenance','Mason2-RetrySweeper','Mason2-StuckDetector',
  'Mason2-TelemetrySummaryDaily','Mason2-RoadmapCheckDaily',
  'Mason2-PortableManifestDaily','Mason2-ErrorAggDaily','Mason2-SilenceAlert-5m',
  'Mason2-NetworkProbe-1h','Mason2-TimeSyncDaily','Mason2-TTLSweeperDaily',
  'Mason2-LargeFileWeekly','Mason2-VerifySchedulerHourly','Mason2-HealthIndexDaily'
)
$have = @{}
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $have[$_.TaskName]=$_.State.ToString() }
$missing = @(); $disabled = @()
foreach($e in $expect){
  if(-not $have.ContainsKey($e)){ $missing += $e }
  elseif($have[$e] -eq 'Disabled'){ $disabled += $e }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\scheduler_verify.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='sched_verify'; missing=$missing; disabled=$disabled
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
# Expected (superset; it's OK if some are still missing)
$expect = @(
  'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply',
  'Mason2-DiskHealthDaily','Mason2-Learner-10m','Mason2-Governor-2m','Mason2-Watchdog-1m',
  'Mason2-TopicSync-1m','Mason2-AutoAdvance-3m','Mason2-ScheduleDrift','Mason2-WeeklyRestoreTest',
  'Mason2-LogMaintenance','Mason2-RetrySweeper','Mason2-StuckDetector',
  'Mason2-TelemetrySummaryDaily','Mason2-RoadmapCheckDaily',
  'Mason2-PortableManifestDaily','Mason2-ErrorAggDaily','Mason2-SilenceAlert-5m',
  'Mason2-NetworkProbe-1h','Mason2-TimeSyncDaily','Mason2-TTLSweeperDaily',
  'Mason2-LargeFileWeekly','Mason2-VerifySchedulerHourly','Mason2-HealthIndexDaily'
)
$have = @{}
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $have[$_.TaskName]=$_.State.ToString() }
$missing = @(); $disabled = @()
foreach($e in $expect){
  if(-not $have.ContainsKey($e)){ $missing += $e }
  elseif($have[$e] -eq 'Disabled'){ $disabled += $e }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\scheduler_verify.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='sched_verify'; missing=$missing; disabled=$disabled
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
# Expected (superset; it's OK if some are still missing)
$expect = @(
  'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply',
  'Mason2-DiskHealthDaily','Mason2-Learner-10m','Mason2-Governor-2m','Mason2-Watchdog-1m',
  'Mason2-TopicSync-1m','Mason2-AutoAdvance-3m','Mason2-ScheduleDrift','Mason2-WeeklyRestoreTest',
  'Mason2-LogMaintenance','Mason2-RetrySweeper','Mason2-StuckDetector',
  'Mason2-TelemetrySummaryDaily','Mason2-RoadmapCheckDaily',
  'Mason2-PortableManifestDaily','Mason2-ErrorAggDaily','Mason2-SilenceAlert-5m',
  'Mason2-NetworkProbe-1h','Mason2-TimeSyncDaily','Mason2-TTLSweeperDaily',
  'Mason2-LargeFileWeekly','Mason2-VerifySchedulerHourly','Mason2-HealthIndexDaily'
)
$have = @{}
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $have[$_.TaskName]=$_.State.ToString() }
$missing = @(); $disabled = @()
foreach($e in $expect){
  if(-not $have.ContainsKey($e)){ $missing += $e }
  elseif($have[$e] -eq 'Disabled'){ $disabled += $e }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\scheduler_verify.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='sched_verify'; missing=$missing; disabled=$disabled
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
# Expected (superset; it's OK if some are still missing)
$expect = @(
  'Mason2-CleanupStages','Mason2-VerifyLatest','Mason2-TrimReleases','Mason2-VerifyApply',
  'Mason2-DiskHealthDaily','Mason2-Learner-10m','Mason2-Governor-2m','Mason2-Watchdog-1m',
  'Mason2-TopicSync-1m','Mason2-AutoAdvance-3m','Mason2-ScheduleDrift','Mason2-WeeklyRestoreTest',
  'Mason2-LogMaintenance','Mason2-RetrySweeper','Mason2-StuckDetector',
  'Mason2-TelemetrySummaryDaily','Mason2-RoadmapCheckDaily',
  'Mason2-PortableManifestDaily','Mason2-ErrorAggDaily','Mason2-SilenceAlert-5m',
  'Mason2-NetworkProbe-1h','Mason2-TimeSyncDaily','Mason2-TTLSweeperDaily',
  'Mason2-LargeFileWeekly','Mason2-VerifySchedulerHourly','Mason2-HealthIndexDaily'
)
$have = @{}
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $have[$_.TaskName]=$_.State.ToString() }
$missing = @(); $disabled = @()
foreach($e in $expect){
  if(-not $have.ContainsKey($e)){ $missing += $e }
  elseif($have[$e] -eq 'Disabled'){ $disabled += $e }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\scheduler_verify.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='sched_verify'; missing=$missing; disabled=$disabled
}

