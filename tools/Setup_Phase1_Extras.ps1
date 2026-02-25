# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
function New-LoggedAction([string]$Tool,[string[]]$Args){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  New-ScheduledTaskAction -Execute "powershell.exe" -Argument @(
    "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$wrap`"","-Base","`"$Base`"","-File","`"$Tool`""
  ) + $(if($Args){ @(" -Args",'"' + ($Args -join '","') + '"') } else { @() }) -WorkingDirectory $Base
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
  $start=(Get-Date).AddMinutes(2); $int=New-TimeSpan -Minutes $m; $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
# Extras (logged)
Register-Or-Update "Mason2-LogMaintenance" (New-LoggedAction (Join-Path $Base 'tools\Log_Maintenance.ps1') @()) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-RetrySweeper"  (New-LoggedAction (Join-Path $Base 'tools\Retry_Sweeper.ps1') @())   (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-StuckDetector" (New-LoggedAction (Join-Path $Base 'tools\Stuck_Job_Detector.ps1') @()) (RepeatTriggerMinutes 15)
Register-Or-Update "Mason2-TelemetrySummaryDaily" (New-LoggedAction (Join-Path $Base 'tools\Telemetry_Summary_Daily.ps1') @()) (DailyAt '03:40')
Register-Or-Update "Mason2-RoadmapCheckDaily"    (New-LoggedAction (Join-Path $Base 'tools\Roadmap_Check.ps1') @())            (DailyAt '03:05')

# Snapshot
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{ TaskName=$_.TaskName; State=$_.State; LastRunTime=$i.LastRunTime; LastTaskResult=$i.LastTaskResult; NextRunTime=$i.NextRunTime }
} | Sort-Object TaskName | Format-Table -Auto

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
function New-LoggedAction([string]$Tool,[string[]]$Args){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  New-ScheduledTaskAction -Execute "powershell.exe" -Argument @(
    "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$wrap`"","-Base","`"$Base`"","-File","`"$Tool`""
  ) + $(if($Args){ @(" -Args",'"' + ($Args -join '","') + '"') } else { @() }) -WorkingDirectory $Base
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
  $start=(Get-Date).AddMinutes(2); $int=New-TimeSpan -Minutes $m; $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
# Extras (logged)
Register-Or-Update "Mason2-LogMaintenance" (New-LoggedAction (Join-Path $Base 'tools\Log_Maintenance.ps1') @()) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-RetrySweeper"  (New-LoggedAction (Join-Path $Base 'tools\Retry_Sweeper.ps1') @())   (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-StuckDetector" (New-LoggedAction (Join-Path $Base 'tools\Stuck_Job_Detector.ps1') @()) (RepeatTriggerMinutes 15)
Register-Or-Update "Mason2-TelemetrySummaryDaily" (New-LoggedAction (Join-Path $Base 'tools\Telemetry_Summary_Daily.ps1') @()) (DailyAt '03:40')
Register-Or-Update "Mason2-RoadmapCheckDaily"    (New-LoggedAction (Join-Path $Base 'tools\Roadmap_Check.ps1') @())            (DailyAt '03:05')

# Snapshot
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{ TaskName=$_.TaskName; State=$_.State; LastRunTime=$i.LastRunTime; LastTaskResult=$i.LastTaskResult; NextRunTime=$i.NextRunTime }
} | Sort-Object TaskName | Format-Table -Auto

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
function New-LoggedAction([string]$Tool,[string[]]$Args){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  New-ScheduledTaskAction -Execute "powershell.exe" -Argument @(
    "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$wrap`"","-Base","`"$Base`"","-File","`"$Tool`""
  ) + $(if($Args){ @(" -Args",'"' + ($Args -join '","') + '"') } else { @() }) -WorkingDirectory $Base
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
  $start=(Get-Date).AddMinutes(2); $int=New-TimeSpan -Minutes $m; $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
# Extras (logged)
Register-Or-Update "Mason2-LogMaintenance" (New-LoggedAction (Join-Path $Base 'tools\Log_Maintenance.ps1') @()) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-RetrySweeper"  (New-LoggedAction (Join-Path $Base 'tools\Retry_Sweeper.ps1') @())   (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-StuckDetector" (New-LoggedAction (Join-Path $Base 'tools\Stuck_Job_Detector.ps1') @()) (RepeatTriggerMinutes 15)
Register-Or-Update "Mason2-TelemetrySummaryDaily" (New-LoggedAction (Join-Path $Base 'tools\Telemetry_Summary_Daily.ps1') @()) (DailyAt '03:40')
Register-Or-Update "Mason2-RoadmapCheckDaily"    (New-LoggedAction (Join-Path $Base 'tools\Roadmap_Check.ps1') @())            (DailyAt '03:05')

# Snapshot
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{ TaskName=$_.TaskName; State=$_.State; LastRunTime=$i.LastRunTime; LastTaskResult=$i.LastTaskResult; NextRunTime=$i.NextRunTime }
} | Sort-Object TaskName | Format-Table -Auto

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
function New-LoggedAction([string]$Tool,[string[]]$Args){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  New-ScheduledTaskAction -Execute "powershell.exe" -Argument @(
    "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$wrap`"","-Base","`"$Base`"","-File","`"$Tool`""
  ) + $(if($Args){ @(" -Args",'"' + ($Args -join '","') + '"') } else { @() }) -WorkingDirectory $Base
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
  $start=(Get-Date).AddMinutes(2); $int=New-TimeSpan -Minutes $m; $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
# Extras (logged)
Register-Or-Update "Mason2-LogMaintenance" (New-LoggedAction (Join-Path $Base 'tools\Log_Maintenance.ps1') @()) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-RetrySweeper"  (New-LoggedAction (Join-Path $Base 'tools\Retry_Sweeper.ps1') @())   (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-StuckDetector" (New-LoggedAction (Join-Path $Base 'tools\Stuck_Job_Detector.ps1') @()) (RepeatTriggerMinutes 15)
Register-Or-Update "Mason2-TelemetrySummaryDaily" (New-LoggedAction (Join-Path $Base 'tools\Telemetry_Summary_Daily.ps1') @()) (DailyAt '03:40')
Register-Or-Update "Mason2-RoadmapCheckDaily"    (New-LoggedAction (Join-Path $Base 'tools\Roadmap_Check.ps1') @())            (DailyAt '03:05')

# Snapshot
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{ TaskName=$_.TaskName; State=$_.State; LastRunTime=$i.LastRunTime; LastTaskResult=$i.LastTaskResult; NextRunTime=$i.NextRunTime }
} | Sort-Object TaskName | Format-Table -Auto

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
function New-LoggedAction([string]$Tool,[string[]]$Args){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  New-ScheduledTaskAction -Execute "powershell.exe" -Argument @(
    "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$wrap`"","-Base","`"$Base`"","-File","`"$Tool`""
  ) + $(if($Args){ @(" -Args",'"' + ($Args -join '","') + '"') } else { @() }) -WorkingDirectory $Base
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
  $start=(Get-Date).AddMinutes(2); $int=New-TimeSpan -Minutes $m; $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
# Extras (logged)
Register-Or-Update "Mason2-LogMaintenance" (New-LoggedAction (Join-Path $Base 'tools\Log_Maintenance.ps1') @()) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-RetrySweeper"  (New-LoggedAction (Join-Path $Base 'tools\Retry_Sweeper.ps1') @())   (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-StuckDetector" (New-LoggedAction (Join-Path $Base 'tools\Stuck_Job_Detector.ps1') @()) (RepeatTriggerMinutes 15)
Register-Or-Update "Mason2-TelemetrySummaryDaily" (New-LoggedAction (Join-Path $Base 'tools\Telemetry_Summary_Daily.ps1') @()) (DailyAt '03:40')
Register-Or-Update "Mason2-RoadmapCheckDaily"    (New-LoggedAction (Join-Path $Base 'tools\Roadmap_Check.ps1') @())            (DailyAt '03:05')

# Snapshot
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{ TaskName=$_.TaskName; State=$_.State; LastRunTime=$i.LastRunTime; LastTaskResult=$i.LastTaskResult; NextRunTime=$i.NextRunTime }
} | Sort-Object TaskName | Format-Table -Auto

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
function New-LoggedAction([string]$Tool,[string[]]$Args){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  New-ScheduledTaskAction -Execute "powershell.exe" -Argument @(
    "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$wrap`"","-Base","`"$Base`"","-File","`"$Tool`""
  ) + $(if($Args){ @(" -Args",'"' + ($Args -join '","') + '"') } else { @() }) -WorkingDirectory $Base
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
  $start=(Get-Date).AddMinutes(2); $int=New-TimeSpan -Minutes $m; $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
# Extras (logged)
Register-Or-Update "Mason2-LogMaintenance" (New-LoggedAction (Join-Path $Base 'tools\Log_Maintenance.ps1') @()) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-RetrySweeper"  (New-LoggedAction (Join-Path $Base 'tools\Retry_Sweeper.ps1') @())   (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-StuckDetector" (New-LoggedAction (Join-Path $Base 'tools\Stuck_Job_Detector.ps1') @()) (RepeatTriggerMinutes 15)
Register-Or-Update "Mason2-TelemetrySummaryDaily" (New-LoggedAction (Join-Path $Base 'tools\Telemetry_Summary_Daily.ps1') @()) (DailyAt '03:40')
Register-Or-Update "Mason2-RoadmapCheckDaily"    (New-LoggedAction (Join-Path $Base 'tools\Roadmap_Check.ps1') @())            (DailyAt '03:05')

# Snapshot
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{ TaskName=$_.TaskName; State=$_.State; LastRunTime=$i.LastRunTime; LastTaskResult=$i.LastTaskResult; NextRunTime=$i.NextRunTime }
} | Sort-Object TaskName | Format-Table -Auto

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
function New-LoggedAction([string]$Tool,[string[]]$Args){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  New-ScheduledTaskAction -Execute "powershell.exe" -Argument @(
    "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$wrap`"","-Base","`"$Base`"","-File","`"$Tool`""
  ) + $(if($Args){ @(" -Args",'"' + ($Args -join '","') + '"') } else { @() }) -WorkingDirectory $Base
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
  $start=(Get-Date).AddMinutes(2); $int=New-TimeSpan -Minutes $m; $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
# Extras (logged)
Register-Or-Update "Mason2-LogMaintenance" (New-LoggedAction (Join-Path $Base 'tools\Log_Maintenance.ps1') @()) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-RetrySweeper"  (New-LoggedAction (Join-Path $Base 'tools\Retry_Sweeper.ps1') @())   (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-StuckDetector" (New-LoggedAction (Join-Path $Base 'tools\Stuck_Job_Detector.ps1') @()) (RepeatTriggerMinutes 15)
Register-Or-Update "Mason2-TelemetrySummaryDaily" (New-LoggedAction (Join-Path $Base 'tools\Telemetry_Summary_Daily.ps1') @()) (DailyAt '03:40')
Register-Or-Update "Mason2-RoadmapCheckDaily"    (New-LoggedAction (Join-Path $Base 'tools\Roadmap_Check.ps1') @())            (DailyAt '03:05')

# Snapshot
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{ TaskName=$_.TaskName; State=$_.State; LastRunTime=$i.LastRunTime; LastTaskResult=$i.LastTaskResult; NextRunTime=$i.NextRunTime }
} | Sort-Object TaskName | Format-Table -Auto

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
function New-LoggedAction([string]$Tool,[string[]]$Args){
  if(!(Test-Path $Tool)){ return $null }
  $wrap = Join-Path $Base 'tools\Run_With_Logging.ps1'
  New-ScheduledTaskAction -Execute "powershell.exe" -Argument @(
    "-NoProfile","-ExecutionPolicy","Bypass","-File","`"$wrap`"","-Base","`"$Base`"","-File","`"$Tool`""
  ) + $(if($Args){ @(" -Args",'"' + ($Args -join '","') + '"') } else { @() }) -WorkingDirectory $Base
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
  $start=(Get-Date).AddMinutes(2); $int=New-TimeSpan -Minutes $m; $dur=New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $int -RepetitionDuration $dur
}
function DailyAt($hhmm){
  $t=[datetime]::ParseExact($hhmm,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
# Extras (logged)
Register-Or-Update "Mason2-LogMaintenance" (New-LoggedAction (Join-Path $Base 'tools\Log_Maintenance.ps1') @()) (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-RetrySweeper"  (New-LoggedAction (Join-Path $Base 'tools\Retry_Sweeper.ps1') @())   (RepeatTriggerMinutes 60)
Register-Or-Update "Mason2-StuckDetector" (New-LoggedAction (Join-Path $Base 'tools\Stuck_Job_Detector.ps1') @()) (RepeatTriggerMinutes 15)
Register-Or-Update "Mason2-TelemetrySummaryDaily" (New-LoggedAction (Join-Path $Base 'tools\Telemetry_Summary_Daily.ps1') @()) (DailyAt '03:40')
Register-Or-Update "Mason2-RoadmapCheckDaily"    (New-LoggedAction (Join-Path $Base 'tools\Roadmap_Check.ps1') @())            (DailyAt '03:05')

# Snapshot
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{ TaskName=$_.TaskName; State=$_.State; LastRunTime=$i.LastRunTime; LastTaskResult=$i.LastTaskResult; NextRunTime=$i.NextRunTime }
} | Sort-Object TaskName | Format-Table -Auto

