# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'

function New-LoggedAction([string]$Tool){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  # Build a single -Argument string (PS 5.1-safe)
  $argString = '-NoProfile -ExecutionPolicy Bypass -File "' + $wrap + '" -Base "' + $Base + '" -File "' + $Tool + '"'
  New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argString -WorkingDirectory $Base
}

function Register-Or-Update($Name,$Action,$Trigger){
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

function RepeatTriggerMinutes($m){
  $start=(Get-Date).AddMinutes(2)
  $int=New-TimeSpan -Minutes $m
  $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function WeeklyAt($dow,$hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dow -At $t
}

Register-Or-Update "Mason2-PortableManifestDaily" (New-LoggedAction (Join-Path $Base 'tools\Portable_Manifest.ps1')) (DailyAt '03:50')
Register-Or-Update "Mason2-ErrorAggDaily"       (New-LoggedAction (Join-Path $Base 'tools\Errors_TopN_Daily.ps1')) (DailyAt '03:41')
Register-Or-Update "Mason2-SilenceAlert-5m"     (New-LoggedAction (Join-Path $Base 'tools\Silence_Alert_5m.ps1'))  (RepeatTriggerMinutes 5)
Register-Or-Update "Mason2-NetworkProbe-1h"     (New-LoggedAction (Join-Path $Base 'tools\Network_Probe.ps1'))     (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-TimeSyncDaily"       (New-LoggedAction (Join-Path $Base 'tools\TimeSync_Status.ps1'))   (DailyAt '03:20')
Register-Or-Update "Mason2-TTLSweeperDaily"     (New-LoggedAction (Join-Path $Base 'tools\TTL_Sweeper.ps1'))       (DailyAt '03:35')
Register-Or-Update "Mason2-LargeFileWeekly"     (New-LoggedAction (Join-Path $Base 'tools\Large_File_Report.ps1')) (WeeklyAt 'Sunday' '04:10')
Register-Or-Update "Mason2-VerifySchedulerHourly" (New-LoggedAction (Join-Path $Base 'tools\Verify_Scheduler_Entries.ps1')) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-HealthIndexDaily"    (New-LoggedAction (Join-Path $Base 'tools\Health_Index_Daily.ps1')) (DailyAt '03:42')

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'

function New-LoggedAction([string]$Tool){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  # Build a single -Argument string (PS 5.1-safe)
  $argString = '-NoProfile -ExecutionPolicy Bypass -File "' + $wrap + '" -Base "' + $Base + '" -File "' + $Tool + '"'
  New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argString -WorkingDirectory $Base
}

function Register-Or-Update($Name,$Action,$Trigger){
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

function RepeatTriggerMinutes($m){
  $start=(Get-Date).AddMinutes(2)
  $int=New-TimeSpan -Minutes $m
  $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function WeeklyAt($dow,$hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dow -At $t
}

Register-Or-Update "Mason2-PortableManifestDaily" (New-LoggedAction (Join-Path $Base 'tools\Portable_Manifest.ps1')) (DailyAt '03:50')
Register-Or-Update "Mason2-ErrorAggDaily"       (New-LoggedAction (Join-Path $Base 'tools\Errors_TopN_Daily.ps1')) (DailyAt '03:41')
Register-Or-Update "Mason2-SilenceAlert-5m"     (New-LoggedAction (Join-Path $Base 'tools\Silence_Alert_5m.ps1'))  (RepeatTriggerMinutes 5)
Register-Or-Update "Mason2-NetworkProbe-1h"     (New-LoggedAction (Join-Path $Base 'tools\Network_Probe.ps1'))     (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-TimeSyncDaily"       (New-LoggedAction (Join-Path $Base 'tools\TimeSync_Status.ps1'))   (DailyAt '03:20')
Register-Or-Update "Mason2-TTLSweeperDaily"     (New-LoggedAction (Join-Path $Base 'tools\TTL_Sweeper.ps1'))       (DailyAt '03:35')
Register-Or-Update "Mason2-LargeFileWeekly"     (New-LoggedAction (Join-Path $Base 'tools\Large_File_Report.ps1')) (WeeklyAt 'Sunday' '04:10')
Register-Or-Update "Mason2-VerifySchedulerHourly" (New-LoggedAction (Join-Path $Base 'tools\Verify_Scheduler_Entries.ps1')) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-HealthIndexDaily"    (New-LoggedAction (Join-Path $Base 'tools\Health_Index_Daily.ps1')) (DailyAt '03:42')

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'

function New-LoggedAction([string]$Tool){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  # Build a single -Argument string (PS 5.1-safe)
  $argString = '-NoProfile -ExecutionPolicy Bypass -File "' + $wrap + '" -Base "' + $Base + '" -File "' + $Tool + '"'
  New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argString -WorkingDirectory $Base
}

function Register-Or-Update($Name,$Action,$Trigger){
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

function RepeatTriggerMinutes($m){
  $start=(Get-Date).AddMinutes(2)
  $int=New-TimeSpan -Minutes $m
  $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function WeeklyAt($dow,$hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dow -At $t
}

Register-Or-Update "Mason2-PortableManifestDaily" (New-LoggedAction (Join-Path $Base 'tools\Portable_Manifest.ps1')) (DailyAt '03:50')
Register-Or-Update "Mason2-ErrorAggDaily"       (New-LoggedAction (Join-Path $Base 'tools\Errors_TopN_Daily.ps1')) (DailyAt '03:41')
Register-Or-Update "Mason2-SilenceAlert-5m"     (New-LoggedAction (Join-Path $Base 'tools\Silence_Alert_5m.ps1'))  (RepeatTriggerMinutes 5)
Register-Or-Update "Mason2-NetworkProbe-1h"     (New-LoggedAction (Join-Path $Base 'tools\Network_Probe.ps1'))     (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-TimeSyncDaily"       (New-LoggedAction (Join-Path $Base 'tools\TimeSync_Status.ps1'))   (DailyAt '03:20')
Register-Or-Update "Mason2-TTLSweeperDaily"     (New-LoggedAction (Join-Path $Base 'tools\TTL_Sweeper.ps1'))       (DailyAt '03:35')
Register-Or-Update "Mason2-LargeFileWeekly"     (New-LoggedAction (Join-Path $Base 'tools\Large_File_Report.ps1')) (WeeklyAt 'Sunday' '04:10')
Register-Or-Update "Mason2-VerifySchedulerHourly" (New-LoggedAction (Join-Path $Base 'tools\Verify_Scheduler_Entries.ps1')) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-HealthIndexDaily"    (New-LoggedAction (Join-Path $Base 'tools\Health_Index_Daily.ps1')) (DailyAt '03:42')

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'

function New-LoggedAction([string]$Tool){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  # Build a single -Argument string (PS 5.1-safe)
  $argString = '-NoProfile -ExecutionPolicy Bypass -File "' + $wrap + '" -Base "' + $Base + '" -File "' + $Tool + '"'
  New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argString -WorkingDirectory $Base
}

function Register-Or-Update($Name,$Action,$Trigger){
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

function RepeatTriggerMinutes($m){
  $start=(Get-Date).AddMinutes(2)
  $int=New-TimeSpan -Minutes $m
  $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function WeeklyAt($dow,$hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dow -At $t
}

Register-Or-Update "Mason2-PortableManifestDaily" (New-LoggedAction (Join-Path $Base 'tools\Portable_Manifest.ps1')) (DailyAt '03:50')
Register-Or-Update "Mason2-ErrorAggDaily"       (New-LoggedAction (Join-Path $Base 'tools\Errors_TopN_Daily.ps1')) (DailyAt '03:41')
Register-Or-Update "Mason2-SilenceAlert-5m"     (New-LoggedAction (Join-Path $Base 'tools\Silence_Alert_5m.ps1'))  (RepeatTriggerMinutes 5)
Register-Or-Update "Mason2-NetworkProbe-1h"     (New-LoggedAction (Join-Path $Base 'tools\Network_Probe.ps1'))     (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-TimeSyncDaily"       (New-LoggedAction (Join-Path $Base 'tools\TimeSync_Status.ps1'))   (DailyAt '03:20')
Register-Or-Update "Mason2-TTLSweeperDaily"     (New-LoggedAction (Join-Path $Base 'tools\TTL_Sweeper.ps1'))       (DailyAt '03:35')
Register-Or-Update "Mason2-LargeFileWeekly"     (New-LoggedAction (Join-Path $Base 'tools\Large_File_Report.ps1')) (WeeklyAt 'Sunday' '04:10')
Register-Or-Update "Mason2-VerifySchedulerHourly" (New-LoggedAction (Join-Path $Base 'tools\Verify_Scheduler_Entries.ps1')) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-HealthIndexDaily"    (New-LoggedAction (Join-Path $Base 'tools\Health_Index_Daily.ps1')) (DailyAt '03:42')

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'

function New-LoggedAction([string]$Tool){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  # Build a single -Argument string (PS 5.1-safe)
  $argString = '-NoProfile -ExecutionPolicy Bypass -File "' + $wrap + '" -Base "' + $Base + '" -File "' + $Tool + '"'
  New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argString -WorkingDirectory $Base
}

function Register-Or-Update($Name,$Action,$Trigger){
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

function RepeatTriggerMinutes($m){
  $start=(Get-Date).AddMinutes(2)
  $int=New-TimeSpan -Minutes $m
  $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function WeeklyAt($dow,$hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dow -At $t
}

Register-Or-Update "Mason2-PortableManifestDaily" (New-LoggedAction (Join-Path $Base 'tools\Portable_Manifest.ps1')) (DailyAt '03:50')
Register-Or-Update "Mason2-ErrorAggDaily"       (New-LoggedAction (Join-Path $Base 'tools\Errors_TopN_Daily.ps1')) (DailyAt '03:41')
Register-Or-Update "Mason2-SilenceAlert-5m"     (New-LoggedAction (Join-Path $Base 'tools\Silence_Alert_5m.ps1'))  (RepeatTriggerMinutes 5)
Register-Or-Update "Mason2-NetworkProbe-1h"     (New-LoggedAction (Join-Path $Base 'tools\Network_Probe.ps1'))     (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-TimeSyncDaily"       (New-LoggedAction (Join-Path $Base 'tools\TimeSync_Status.ps1'))   (DailyAt '03:20')
Register-Or-Update "Mason2-TTLSweeperDaily"     (New-LoggedAction (Join-Path $Base 'tools\TTL_Sweeper.ps1'))       (DailyAt '03:35')
Register-Or-Update "Mason2-LargeFileWeekly"     (New-LoggedAction (Join-Path $Base 'tools\Large_File_Report.ps1')) (WeeklyAt 'Sunday' '04:10')
Register-Or-Update "Mason2-VerifySchedulerHourly" (New-LoggedAction (Join-Path $Base 'tools\Verify_Scheduler_Entries.ps1')) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-HealthIndexDaily"    (New-LoggedAction (Join-Path $Base 'tools\Health_Index_Daily.ps1')) (DailyAt '03:42')

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'

function New-LoggedAction([string]$Tool){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  # Build a single -Argument string (PS 5.1-safe)
  $argString = '-NoProfile -ExecutionPolicy Bypass -File "' + $wrap + '" -Base "' + $Base + '" -File "' + $Tool + '"'
  New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argString -WorkingDirectory $Base
}

function Register-Or-Update($Name,$Action,$Trigger){
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

function RepeatTriggerMinutes($m){
  $start=(Get-Date).AddMinutes(2)
  $int=New-TimeSpan -Minutes $m
  $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function WeeklyAt($dow,$hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dow -At $t
}

Register-Or-Update "Mason2-PortableManifestDaily" (New-LoggedAction (Join-Path $Base 'tools\Portable_Manifest.ps1')) (DailyAt '03:50')
Register-Or-Update "Mason2-ErrorAggDaily"       (New-LoggedAction (Join-Path $Base 'tools\Errors_TopN_Daily.ps1')) (DailyAt '03:41')
Register-Or-Update "Mason2-SilenceAlert-5m"     (New-LoggedAction (Join-Path $Base 'tools\Silence_Alert_5m.ps1'))  (RepeatTriggerMinutes 5)
Register-Or-Update "Mason2-NetworkProbe-1h"     (New-LoggedAction (Join-Path $Base 'tools\Network_Probe.ps1'))     (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-TimeSyncDaily"       (New-LoggedAction (Join-Path $Base 'tools\TimeSync_Status.ps1'))   (DailyAt '03:20')
Register-Or-Update "Mason2-TTLSweeperDaily"     (New-LoggedAction (Join-Path $Base 'tools\TTL_Sweeper.ps1'))       (DailyAt '03:35')
Register-Or-Update "Mason2-LargeFileWeekly"     (New-LoggedAction (Join-Path $Base 'tools\Large_File_Report.ps1')) (WeeklyAt 'Sunday' '04:10')
Register-Or-Update "Mason2-VerifySchedulerHourly" (New-LoggedAction (Join-Path $Base 'tools\Verify_Scheduler_Entries.ps1')) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-HealthIndexDaily"    (New-LoggedAction (Join-Path $Base 'tools\Health_Index_Daily.ps1')) (DailyAt '03:42')

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'

function New-LoggedAction([string]$Tool){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  # Build a single -Argument string (PS 5.1-safe)
  $argString = '-NoProfile -ExecutionPolicy Bypass -File "' + $wrap + '" -Base "' + $Base + '" -File "' + $Tool + '"'
  New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argString -WorkingDirectory $Base
}

function Register-Or-Update($Name,$Action,$Trigger){
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

function RepeatTriggerMinutes($m){
  $start=(Get-Date).AddMinutes(2)
  $int=New-TimeSpan -Minutes $m
  $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function WeeklyAt($dow,$hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dow -At $t
}

Register-Or-Update "Mason2-PortableManifestDaily" (New-LoggedAction (Join-Path $Base 'tools\Portable_Manifest.ps1')) (DailyAt '03:50')
Register-Or-Update "Mason2-ErrorAggDaily"       (New-LoggedAction (Join-Path $Base 'tools\Errors_TopN_Daily.ps1')) (DailyAt '03:41')
Register-Or-Update "Mason2-SilenceAlert-5m"     (New-LoggedAction (Join-Path $Base 'tools\Silence_Alert_5m.ps1'))  (RepeatTriggerMinutes 5)
Register-Or-Update "Mason2-NetworkProbe-1h"     (New-LoggedAction (Join-Path $Base 'tools\Network_Probe.ps1'))     (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-TimeSyncDaily"       (New-LoggedAction (Join-Path $Base 'tools\TimeSync_Status.ps1'))   (DailyAt '03:20')
Register-Or-Update "Mason2-TTLSweeperDaily"     (New-LoggedAction (Join-Path $Base 'tools\TTL_Sweeper.ps1'))       (DailyAt '03:35')
Register-Or-Update "Mason2-LargeFileWeekly"     (New-LoggedAction (Join-Path $Base 'tools\Large_File_Report.ps1')) (WeeklyAt 'Sunday' '04:10')
Register-Or-Update "Mason2-VerifySchedulerHourly" (New-LoggedAction (Join-Path $Base 'tools\Verify_Scheduler_Entries.ps1')) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-HealthIndexDaily"    (New-LoggedAction (Join-Path $Base 'tools\Health_Index_Daily.ps1')) (DailyAt '03:42')

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'

function New-LoggedAction([string]$Tool){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  # Build a single -Argument string (PS 5.1-safe)
  $argString = '-NoProfile -ExecutionPolicy Bypass -File "' + $wrap + '" -Base "' + $Base + '" -File "' + $Tool + '"'
  New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $argString -WorkingDirectory $Base
}

function Register-Or-Update($Name,$Action,$Trigger){
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

function RepeatTriggerMinutes($m){
  $start=(Get-Date).AddMinutes(2)
  $int=New-TimeSpan -Minutes $m
  $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function WeeklyAt($dow,$hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dow -At $t
}

Register-Or-Update "Mason2-PortableManifestDaily" (New-LoggedAction (Join-Path $Base 'tools\Portable_Manifest.ps1')) (DailyAt '03:50')
Register-Or-Update "Mason2-ErrorAggDaily"       (New-LoggedAction (Join-Path $Base 'tools\Errors_TopN_Daily.ps1')) (DailyAt '03:41')
Register-Or-Update "Mason2-SilenceAlert-5m"     (New-LoggedAction (Join-Path $Base 'tools\Silence_Alert_5m.ps1'))  (RepeatTriggerMinutes 5)
Register-Or-Update "Mason2-NetworkProbe-1h"     (New-LoggedAction (Join-Path $Base 'tools\Network_Probe.ps1'))     (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-TimeSyncDaily"       (New-LoggedAction (Join-Path $Base 'tools\TimeSync_Status.ps1'))   (DailyAt '03:20')
Register-Or-Update "Mason2-TTLSweeperDaily"     (New-LoggedAction (Join-Path $Base 'tools\TTL_Sweeper.ps1'))       (DailyAt '03:35')
Register-Or-Update "Mason2-LargeFileWeekly"     (New-LoggedAction (Join-Path $Base 'tools\Large_File_Report.ps1')) (WeeklyAt 'Sunday' '04:10')
Register-Or-Update "Mason2-VerifySchedulerHourly" (New-LoggedAction (Join-Path $Base 'tools\Verify_Scheduler_Entries.ps1')) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-HealthIndexDaily"    (New-LoggedAction (Join-Path $Base 'tools\Health_Index_Daily.ps1')) (DailyAt '03:42')

