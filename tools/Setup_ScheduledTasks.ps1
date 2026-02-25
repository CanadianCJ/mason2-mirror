# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

function New-PwshAction { param([string]$File)
  if(!(Test-Path $File)){ return $null }
  New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$File`"`"") `
    -WorkingDirectory $Base
}
function New-RepeatTriggerHours { param([int]$Hours)
  $start = (Get-Date).AddMinutes(2)
  $interval = New-TimeSpan -Hours $Hours
  $duration = New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $interval -RepetitionDuration $duration
}
function New-DailyAt { param([string]$HHmm)
  $t = [datetime]::ParseExact($HHmm, "HH:mm", [Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function Set-Or-RegisterTask { param($Name,$Action,$Trigger)
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }else{
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

# Read config
$cfgPath = Join-Path $Base 'config\mason2.config.json'
$cfg = $null; $auto = $null
if(Test-Path $cfgPath){ try{ $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json; $auto = $cfg.Auto }catch{} }

$VerifyEveryHours   = if($auto.VerifyEveryHours){ [int]$auto.VerifyEveryHours } else { 4 }
$CleanupEveryHours  = if($auto.CleanupEveryHours){ [int]$auto.CleanupEveryHours } else { 1 }
$NightlyTrimAt      = if($auto.NightlyTrimAt){ [string]$auto.NightlyTrimAt } else { "03:30" }
$NightlyApplyAt     = if($auto.NightlyApplyAt){ [string]$auto.NightlyApplyAt } else { "03:45" }
$DiskHealthAt       = if($auto.PSObject.Properties.Name -contains 'DiskHealthAt' -and $auto.DiskHealthAt){
                        [string]$auto.DiskHealthAt } else { "03:30" }

# Resolve tool paths
$Tool_VerifyTighten = Join-Path $Base 'tools\Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Base 'tools\Verify_And_Unpack.ps1'
$Tool_TrimReleases  = Join-Path $Base 'tools\Trim_Releases.ps1'
$Tool_VerifyApply   = Join-Path $Base 'tools\Nightly_VerifyApply.ps1'
$Tool_Cleanup       = Join-Path $Base 'tools\Cleanup_Stages.ps1'
$Tool_DiskHealth    = Join-Path $Base 'tools\Disk_Health.ps1'

# Tasks (idempotent)
Set-Or-RegisterTask -Name 'Mason2-CleanupStages' `
  -Action  (New-PwshAction $Tool_Cleanup) `
  -Trigger (New-RepeatTriggerHours $CleanupEveryHours)

Set-Or-RegisterTask -Name 'Mason2-VerifyLatest' `
  -Action  (New-PwshAction $Tool_VerifyTighten) `
  -Trigger (New-RepeatTriggerHours $VerifyEveryHours)

Set-Or-RegisterTask -Name 'Mason2-TrimReleases' `
  -Action  (New-PwshAction $Tool_TrimReleases) `
  -Trigger (New-DailyAt $NightlyTrimAt)

Set-Or-RegisterTask -Name 'Mason2-VerifyApply' `
  -Action  (New-PwshAction $Tool_VerifyApply) `
  -Trigger (New-DailyAt $NightlyApplyAt)

Set-Or-RegisterTask -Name 'Mason2-DiskHealthDaily' `
  -Action  (New-PwshAction $Tool_DiskHealth) `
  -Trigger (New-DailyAt $DiskHealthAt)

# Snapshot to console
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{
    TaskName       = $_.TaskName
    State          = $_.State
    LastRunTime    = $i.LastRunTime
    LastTaskResult = $i.LastTaskResult
    NextRunTime    = $i.NextRunTime
  }
} | Sort-Object TaskName | Format-Table -Auto

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

function New-PwshAction { param([string]$File)
  if(!(Test-Path $File)){ return $null }
  New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$File`"`"") `
    -WorkingDirectory $Base
}
function New-RepeatTriggerHours { param([int]$Hours)
  $start = (Get-Date).AddMinutes(2)
  $interval = New-TimeSpan -Hours $Hours
  $duration = New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $interval -RepetitionDuration $duration
}
function New-DailyAt { param([string]$HHmm)
  $t = [datetime]::ParseExact($HHmm, "HH:mm", [Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function Set-Or-RegisterTask { param($Name,$Action,$Trigger)
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }else{
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

# Read config
$cfgPath = Join-Path $Base 'config\mason2.config.json'
$cfg = $null; $auto = $null
if(Test-Path $cfgPath){ try{ $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json; $auto = $cfg.Auto }catch{} }

$VerifyEveryHours   = if($auto.VerifyEveryHours){ [int]$auto.VerifyEveryHours } else { 4 }
$CleanupEveryHours  = if($auto.CleanupEveryHours){ [int]$auto.CleanupEveryHours } else { 1 }
$NightlyTrimAt      = if($auto.NightlyTrimAt){ [string]$auto.NightlyTrimAt } else { "03:30" }
$NightlyApplyAt     = if($auto.NightlyApplyAt){ [string]$auto.NightlyApplyAt } else { "03:45" }
$DiskHealthAt       = if($auto.PSObject.Properties.Name -contains 'DiskHealthAt' -and $auto.DiskHealthAt){
                        [string]$auto.DiskHealthAt } else { "03:30" }

# Resolve tool paths
$Tool_VerifyTighten = Join-Path $Base 'tools\Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Base 'tools\Verify_And_Unpack.ps1'
$Tool_TrimReleases  = Join-Path $Base 'tools\Trim_Releases.ps1'
$Tool_VerifyApply   = Join-Path $Base 'tools\Nightly_VerifyApply.ps1'
$Tool_Cleanup       = Join-Path $Base 'tools\Cleanup_Stages.ps1'
$Tool_DiskHealth    = Join-Path $Base 'tools\Disk_Health.ps1'

# Tasks (idempotent)
Set-Or-RegisterTask -Name 'Mason2-CleanupStages' `
  -Action  (New-PwshAction $Tool_Cleanup) `
  -Trigger (New-RepeatTriggerHours $CleanupEveryHours)

Set-Or-RegisterTask -Name 'Mason2-VerifyLatest' `
  -Action  (New-PwshAction $Tool_VerifyTighten) `
  -Trigger (New-RepeatTriggerHours $VerifyEveryHours)

Set-Or-RegisterTask -Name 'Mason2-TrimReleases' `
  -Action  (New-PwshAction $Tool_TrimReleases) `
  -Trigger (New-DailyAt $NightlyTrimAt)

Set-Or-RegisterTask -Name 'Mason2-VerifyApply' `
  -Action  (New-PwshAction $Tool_VerifyApply) `
  -Trigger (New-DailyAt $NightlyApplyAt)

Set-Or-RegisterTask -Name 'Mason2-DiskHealthDaily' `
  -Action  (New-PwshAction $Tool_DiskHealth) `
  -Trigger (New-DailyAt $DiskHealthAt)

# Snapshot to console
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{
    TaskName       = $_.TaskName
    State          = $_.State
    LastRunTime    = $i.LastRunTime
    LastTaskResult = $i.LastTaskResult
    NextRunTime    = $i.NextRunTime
  }
} | Sort-Object TaskName | Format-Table -Auto

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

function New-PwshAction { param([string]$File)
  if(!(Test-Path $File)){ return $null }
  New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$File`"`"") `
    -WorkingDirectory $Base
}
function New-RepeatTriggerHours { param([int]$Hours)
  $start = (Get-Date).AddMinutes(2)
  $interval = New-TimeSpan -Hours $Hours
  $duration = New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $interval -RepetitionDuration $duration
}
function New-DailyAt { param([string]$HHmm)
  $t = [datetime]::ParseExact($HHmm, "HH:mm", [Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function Set-Or-RegisterTask { param($Name,$Action,$Trigger)
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }else{
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

# Read config
$cfgPath = Join-Path $Base 'config\mason2.config.json'
$cfg = $null; $auto = $null
if(Test-Path $cfgPath){ try{ $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json; $auto = $cfg.Auto }catch{} }

$VerifyEveryHours   = if($auto.VerifyEveryHours){ [int]$auto.VerifyEveryHours } else { 4 }
$CleanupEveryHours  = if($auto.CleanupEveryHours){ [int]$auto.CleanupEveryHours } else { 1 }
$NightlyTrimAt      = if($auto.NightlyTrimAt){ [string]$auto.NightlyTrimAt } else { "03:30" }
$NightlyApplyAt     = if($auto.NightlyApplyAt){ [string]$auto.NightlyApplyAt } else { "03:45" }
$DiskHealthAt       = if($auto.PSObject.Properties.Name -contains 'DiskHealthAt' -and $auto.DiskHealthAt){
                        [string]$auto.DiskHealthAt } else { "03:30" }

# Resolve tool paths
$Tool_VerifyTighten = Join-Path $Base 'tools\Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Base 'tools\Verify_And_Unpack.ps1'
$Tool_TrimReleases  = Join-Path $Base 'tools\Trim_Releases.ps1'
$Tool_VerifyApply   = Join-Path $Base 'tools\Nightly_VerifyApply.ps1'
$Tool_Cleanup       = Join-Path $Base 'tools\Cleanup_Stages.ps1'
$Tool_DiskHealth    = Join-Path $Base 'tools\Disk_Health.ps1'

# Tasks (idempotent)
Set-Or-RegisterTask -Name 'Mason2-CleanupStages' `
  -Action  (New-PwshAction $Tool_Cleanup) `
  -Trigger (New-RepeatTriggerHours $CleanupEveryHours)

Set-Or-RegisterTask -Name 'Mason2-VerifyLatest' `
  -Action  (New-PwshAction $Tool_VerifyTighten) `
  -Trigger (New-RepeatTriggerHours $VerifyEveryHours)

Set-Or-RegisterTask -Name 'Mason2-TrimReleases' `
  -Action  (New-PwshAction $Tool_TrimReleases) `
  -Trigger (New-DailyAt $NightlyTrimAt)

Set-Or-RegisterTask -Name 'Mason2-VerifyApply' `
  -Action  (New-PwshAction $Tool_VerifyApply) `
  -Trigger (New-DailyAt $NightlyApplyAt)

Set-Or-RegisterTask -Name 'Mason2-DiskHealthDaily' `
  -Action  (New-PwshAction $Tool_DiskHealth) `
  -Trigger (New-DailyAt $DiskHealthAt)

# Snapshot to console
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{
    TaskName       = $_.TaskName
    State          = $_.State
    LastRunTime    = $i.LastRunTime
    LastTaskResult = $i.LastTaskResult
    NextRunTime    = $i.NextRunTime
  }
} | Sort-Object TaskName | Format-Table -Auto

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

function New-PwshAction { param([string]$File)
  if(!(Test-Path $File)){ return $null }
  New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$File`"`"") `
    -WorkingDirectory $Base
}
function New-RepeatTriggerHours { param([int]$Hours)
  $start = (Get-Date).AddMinutes(2)
  $interval = New-TimeSpan -Hours $Hours
  $duration = New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $interval -RepetitionDuration $duration
}
function New-DailyAt { param([string]$HHmm)
  $t = [datetime]::ParseExact($HHmm, "HH:mm", [Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function Set-Or-RegisterTask { param($Name,$Action,$Trigger)
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }else{
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

# Read config
$cfgPath = Join-Path $Base 'config\mason2.config.json'
$cfg = $null; $auto = $null
if(Test-Path $cfgPath){ try{ $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json; $auto = $cfg.Auto }catch{} }

$VerifyEveryHours   = if($auto.VerifyEveryHours){ [int]$auto.VerifyEveryHours } else { 4 }
$CleanupEveryHours  = if($auto.CleanupEveryHours){ [int]$auto.CleanupEveryHours } else { 1 }
$NightlyTrimAt      = if($auto.NightlyTrimAt){ [string]$auto.NightlyTrimAt } else { "03:30" }
$NightlyApplyAt     = if($auto.NightlyApplyAt){ [string]$auto.NightlyApplyAt } else { "03:45" }
$DiskHealthAt       = if($auto.PSObject.Properties.Name -contains 'DiskHealthAt' -and $auto.DiskHealthAt){
                        [string]$auto.DiskHealthAt } else { "03:30" }

# Resolve tool paths
$Tool_VerifyTighten = Join-Path $Base 'tools\Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Base 'tools\Verify_And_Unpack.ps1'
$Tool_TrimReleases  = Join-Path $Base 'tools\Trim_Releases.ps1'
$Tool_VerifyApply   = Join-Path $Base 'tools\Nightly_VerifyApply.ps1'
$Tool_Cleanup       = Join-Path $Base 'tools\Cleanup_Stages.ps1'
$Tool_DiskHealth    = Join-Path $Base 'tools\Disk_Health.ps1'

# Tasks (idempotent)
Set-Or-RegisterTask -Name 'Mason2-CleanupStages' `
  -Action  (New-PwshAction $Tool_Cleanup) `
  -Trigger (New-RepeatTriggerHours $CleanupEveryHours)

Set-Or-RegisterTask -Name 'Mason2-VerifyLatest' `
  -Action  (New-PwshAction $Tool_VerifyTighten) `
  -Trigger (New-RepeatTriggerHours $VerifyEveryHours)

Set-Or-RegisterTask -Name 'Mason2-TrimReleases' `
  -Action  (New-PwshAction $Tool_TrimReleases) `
  -Trigger (New-DailyAt $NightlyTrimAt)

Set-Or-RegisterTask -Name 'Mason2-VerifyApply' `
  -Action  (New-PwshAction $Tool_VerifyApply) `
  -Trigger (New-DailyAt $NightlyApplyAt)

Set-Or-RegisterTask -Name 'Mason2-DiskHealthDaily' `
  -Action  (New-PwshAction $Tool_DiskHealth) `
  -Trigger (New-DailyAt $DiskHealthAt)

# Snapshot to console
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{
    TaskName       = $_.TaskName
    State          = $_.State
    LastRunTime    = $i.LastRunTime
    LastTaskResult = $i.LastTaskResult
    NextRunTime    = $i.NextRunTime
  }
} | Sort-Object TaskName | Format-Table -Auto

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

function New-PwshAction { param([string]$File)
  if(!(Test-Path $File)){ return $null }
  New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$File`"`"") `
    -WorkingDirectory $Base
}
function New-RepeatTriggerHours { param([int]$Hours)
  $start = (Get-Date).AddMinutes(2)
  $interval = New-TimeSpan -Hours $Hours
  $duration = New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $interval -RepetitionDuration $duration
}
function New-DailyAt { param([string]$HHmm)
  $t = [datetime]::ParseExact($HHmm, "HH:mm", [Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function Set-Or-RegisterTask { param($Name,$Action,$Trigger)
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }else{
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

# Read config
$cfgPath = Join-Path $Base 'config\mason2.config.json'
$cfg = $null; $auto = $null
if(Test-Path $cfgPath){ try{ $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json; $auto = $cfg.Auto }catch{} }

$VerifyEveryHours   = if($auto.VerifyEveryHours){ [int]$auto.VerifyEveryHours } else { 4 }
$CleanupEveryHours  = if($auto.CleanupEveryHours){ [int]$auto.CleanupEveryHours } else { 1 }
$NightlyTrimAt      = if($auto.NightlyTrimAt){ [string]$auto.NightlyTrimAt } else { "03:30" }
$NightlyApplyAt     = if($auto.NightlyApplyAt){ [string]$auto.NightlyApplyAt } else { "03:45" }
$DiskHealthAt       = if($auto.PSObject.Properties.Name -contains 'DiskHealthAt' -and $auto.DiskHealthAt){
                        [string]$auto.DiskHealthAt } else { "03:30" }

# Resolve tool paths
$Tool_VerifyTighten = Join-Path $Base 'tools\Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Base 'tools\Verify_And_Unpack.ps1'
$Tool_TrimReleases  = Join-Path $Base 'tools\Trim_Releases.ps1'
$Tool_VerifyApply   = Join-Path $Base 'tools\Nightly_VerifyApply.ps1'
$Tool_Cleanup       = Join-Path $Base 'tools\Cleanup_Stages.ps1'
$Tool_DiskHealth    = Join-Path $Base 'tools\Disk_Health.ps1'

# Tasks (idempotent)
Set-Or-RegisterTask -Name 'Mason2-CleanupStages' `
  -Action  (New-PwshAction $Tool_Cleanup) `
  -Trigger (New-RepeatTriggerHours $CleanupEveryHours)

Set-Or-RegisterTask -Name 'Mason2-VerifyLatest' `
  -Action  (New-PwshAction $Tool_VerifyTighten) `
  -Trigger (New-RepeatTriggerHours $VerifyEveryHours)

Set-Or-RegisterTask -Name 'Mason2-TrimReleases' `
  -Action  (New-PwshAction $Tool_TrimReleases) `
  -Trigger (New-DailyAt $NightlyTrimAt)

Set-Or-RegisterTask -Name 'Mason2-VerifyApply' `
  -Action  (New-PwshAction $Tool_VerifyApply) `
  -Trigger (New-DailyAt $NightlyApplyAt)

Set-Or-RegisterTask -Name 'Mason2-DiskHealthDaily' `
  -Action  (New-PwshAction $Tool_DiskHealth) `
  -Trigger (New-DailyAt $DiskHealthAt)

# Snapshot to console
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{
    TaskName       = $_.TaskName
    State          = $_.State
    LastRunTime    = $i.LastRunTime
    LastTaskResult = $i.LastTaskResult
    NextRunTime    = $i.NextRunTime
  }
} | Sort-Object TaskName | Format-Table -Auto

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

function New-PwshAction { param([string]$File)
  if(!(Test-Path $File)){ return $null }
  New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$File`"`"") `
    -WorkingDirectory $Base
}
function New-RepeatTriggerHours { param([int]$Hours)
  $start = (Get-Date).AddMinutes(2)
  $interval = New-TimeSpan -Hours $Hours
  $duration = New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $interval -RepetitionDuration $duration
}
function New-DailyAt { param([string]$HHmm)
  $t = [datetime]::ParseExact($HHmm, "HH:mm", [Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function Set-Or-RegisterTask { param($Name,$Action,$Trigger)
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }else{
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

# Read config
$cfgPath = Join-Path $Base 'config\mason2.config.json'
$cfg = $null; $auto = $null
if(Test-Path $cfgPath){ try{ $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json; $auto = $cfg.Auto }catch{} }

$VerifyEveryHours   = if($auto.VerifyEveryHours){ [int]$auto.VerifyEveryHours } else { 4 }
$CleanupEveryHours  = if($auto.CleanupEveryHours){ [int]$auto.CleanupEveryHours } else { 1 }
$NightlyTrimAt      = if($auto.NightlyTrimAt){ [string]$auto.NightlyTrimAt } else { "03:30" }
$NightlyApplyAt     = if($auto.NightlyApplyAt){ [string]$auto.NightlyApplyAt } else { "03:45" }
$DiskHealthAt       = if($auto.PSObject.Properties.Name -contains 'DiskHealthAt' -and $auto.DiskHealthAt){
                        [string]$auto.DiskHealthAt } else { "03:30" }

# Resolve tool paths
$Tool_VerifyTighten = Join-Path $Base 'tools\Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Base 'tools\Verify_And_Unpack.ps1'
$Tool_TrimReleases  = Join-Path $Base 'tools\Trim_Releases.ps1'
$Tool_VerifyApply   = Join-Path $Base 'tools\Nightly_VerifyApply.ps1'
$Tool_Cleanup       = Join-Path $Base 'tools\Cleanup_Stages.ps1'
$Tool_DiskHealth    = Join-Path $Base 'tools\Disk_Health.ps1'

# Tasks (idempotent)
Set-Or-RegisterTask -Name 'Mason2-CleanupStages' `
  -Action  (New-PwshAction $Tool_Cleanup) `
  -Trigger (New-RepeatTriggerHours $CleanupEveryHours)

Set-Or-RegisterTask -Name 'Mason2-VerifyLatest' `
  -Action  (New-PwshAction $Tool_VerifyTighten) `
  -Trigger (New-RepeatTriggerHours $VerifyEveryHours)

Set-Or-RegisterTask -Name 'Mason2-TrimReleases' `
  -Action  (New-PwshAction $Tool_TrimReleases) `
  -Trigger (New-DailyAt $NightlyTrimAt)

Set-Or-RegisterTask -Name 'Mason2-VerifyApply' `
  -Action  (New-PwshAction $Tool_VerifyApply) `
  -Trigger (New-DailyAt $NightlyApplyAt)

Set-Or-RegisterTask -Name 'Mason2-DiskHealthDaily' `
  -Action  (New-PwshAction $Tool_DiskHealth) `
  -Trigger (New-DailyAt $DiskHealthAt)

# Snapshot to console
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{
    TaskName       = $_.TaskName
    State          = $_.State
    LastRunTime    = $i.LastRunTime
    LastTaskResult = $i.LastTaskResult
    NextRunTime    = $i.NextRunTime
  }
} | Sort-Object TaskName | Format-Table -Auto

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

function New-PwshAction { param([string]$File)
  if(!(Test-Path $File)){ return $null }
  New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$File`"`"") `
    -WorkingDirectory $Base
}
function New-RepeatTriggerHours { param([int]$Hours)
  $start = (Get-Date).AddMinutes(2)
  $interval = New-TimeSpan -Hours $Hours
  $duration = New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $interval -RepetitionDuration $duration
}
function New-DailyAt { param([string]$HHmm)
  $t = [datetime]::ParseExact($HHmm, "HH:mm", [Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function Set-Or-RegisterTask { param($Name,$Action,$Trigger)
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }else{
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

# Read config
$cfgPath = Join-Path $Base 'config\mason2.config.json'
$cfg = $null; $auto = $null
if(Test-Path $cfgPath){ try{ $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json; $auto = $cfg.Auto }catch{} }

$VerifyEveryHours   = if($auto.VerifyEveryHours){ [int]$auto.VerifyEveryHours } else { 4 }
$CleanupEveryHours  = if($auto.CleanupEveryHours){ [int]$auto.CleanupEveryHours } else { 1 }
$NightlyTrimAt      = if($auto.NightlyTrimAt){ [string]$auto.NightlyTrimAt } else { "03:30" }
$NightlyApplyAt     = if($auto.NightlyApplyAt){ [string]$auto.NightlyApplyAt } else { "03:45" }
$DiskHealthAt       = if($auto.PSObject.Properties.Name -contains 'DiskHealthAt' -and $auto.DiskHealthAt){
                        [string]$auto.DiskHealthAt } else { "03:30" }

# Resolve tool paths
$Tool_VerifyTighten = Join-Path $Base 'tools\Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Base 'tools\Verify_And_Unpack.ps1'
$Tool_TrimReleases  = Join-Path $Base 'tools\Trim_Releases.ps1'
$Tool_VerifyApply   = Join-Path $Base 'tools\Nightly_VerifyApply.ps1'
$Tool_Cleanup       = Join-Path $Base 'tools\Cleanup_Stages.ps1'
$Tool_DiskHealth    = Join-Path $Base 'tools\Disk_Health.ps1'

# Tasks (idempotent)
Set-Or-RegisterTask -Name 'Mason2-CleanupStages' `
  -Action  (New-PwshAction $Tool_Cleanup) `
  -Trigger (New-RepeatTriggerHours $CleanupEveryHours)

Set-Or-RegisterTask -Name 'Mason2-VerifyLatest' `
  -Action  (New-PwshAction $Tool_VerifyTighten) `
  -Trigger (New-RepeatTriggerHours $VerifyEveryHours)

Set-Or-RegisterTask -Name 'Mason2-TrimReleases' `
  -Action  (New-PwshAction $Tool_TrimReleases) `
  -Trigger (New-DailyAt $NightlyTrimAt)

Set-Or-RegisterTask -Name 'Mason2-VerifyApply' `
  -Action  (New-PwshAction $Tool_VerifyApply) `
  -Trigger (New-DailyAt $NightlyApplyAt)

Set-Or-RegisterTask -Name 'Mason2-DiskHealthDaily' `
  -Action  (New-PwshAction $Tool_DiskHealth) `
  -Trigger (New-DailyAt $DiskHealthAt)

# Snapshot to console
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{
    TaskName       = $_.TaskName
    State          = $_.State
    LastRunTime    = $i.LastRunTime
    LastTaskResult = $i.LastTaskResult
    NextRunTime    = $i.NextRunTime
  }
} | Sort-Object TaskName | Format-Table -Auto

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

function New-PwshAction { param([string]$File)
  if(!(Test-Path $File)){ return $null }
  New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$File`"`"") `
    -WorkingDirectory $Base
}
function New-RepeatTriggerHours { param([int]$Hours)
  $start = (Get-Date).AddMinutes(2)
  $interval = New-TimeSpan -Hours $Hours
  $duration = New-TimeSpan -Days 365
  New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $interval -RepetitionDuration $duration
}
function New-DailyAt { param([string]$HHmm)
  $t = [datetime]::ParseExact($HHmm, "HH:mm", [Globalization.CultureInfo]::InvariantCulture)
  New-ScheduledTaskTrigger -Daily -At $t
}
function Set-Or-RegisterTask { param($Name,$Action,$Trigger)
  if(-not $Action -or -not $Trigger){ return }
  $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
  if(Get-ScheduledTask -TaskName $Name -ErrorAction SilentlyContinue){
    Set-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }else{
    Register-ScheduledTask -TaskName $Name -Action $Action -Trigger $Trigger -Principal $principal | Out-Null
  }
}

# Read config
$cfgPath = Join-Path $Base 'config\mason2.config.json'
$cfg = $null; $auto = $null
if(Test-Path $cfgPath){ try{ $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json; $auto = $cfg.Auto }catch{} }

$VerifyEveryHours   = if($auto.VerifyEveryHours){ [int]$auto.VerifyEveryHours } else { 4 }
$CleanupEveryHours  = if($auto.CleanupEveryHours){ [int]$auto.CleanupEveryHours } else { 1 }
$NightlyTrimAt      = if($auto.NightlyTrimAt){ [string]$auto.NightlyTrimAt } else { "03:30" }
$NightlyApplyAt     = if($auto.NightlyApplyAt){ [string]$auto.NightlyApplyAt } else { "03:45" }
$DiskHealthAt       = if($auto.PSObject.Properties.Name -contains 'DiskHealthAt' -and $auto.DiskHealthAt){
                        [string]$auto.DiskHealthAt } else { "03:30" }

# Resolve tool paths
$Tool_VerifyTighten = Join-Path $Base 'tools\Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Base 'tools\Verify_And_Unpack.ps1'
$Tool_TrimReleases  = Join-Path $Base 'tools\Trim_Releases.ps1'
$Tool_VerifyApply   = Join-Path $Base 'tools\Nightly_VerifyApply.ps1'
$Tool_Cleanup       = Join-Path $Base 'tools\Cleanup_Stages.ps1'
$Tool_DiskHealth    = Join-Path $Base 'tools\Disk_Health.ps1'

# Tasks (idempotent)
Set-Or-RegisterTask -Name 'Mason2-CleanupStages' `
  -Action  (New-PwshAction $Tool_Cleanup) `
  -Trigger (New-RepeatTriggerHours $CleanupEveryHours)

Set-Or-RegisterTask -Name 'Mason2-VerifyLatest' `
  -Action  (New-PwshAction $Tool_VerifyTighten) `
  -Trigger (New-RepeatTriggerHours $VerifyEveryHours)

Set-Or-RegisterTask -Name 'Mason2-TrimReleases' `
  -Action  (New-PwshAction $Tool_TrimReleases) `
  -Trigger (New-DailyAt $NightlyTrimAt)

Set-Or-RegisterTask -Name 'Mason2-VerifyApply' `
  -Action  (New-PwshAction $Tool_VerifyApply) `
  -Trigger (New-DailyAt $NightlyApplyAt)

Set-Or-RegisterTask -Name 'Mason2-DiskHealthDaily' `
  -Action  (New-PwshAction $Tool_DiskHealth) `
  -Trigger (New-DailyAt $DiskHealthAt)

# Snapshot to console
Get-ScheduledTask 'Mason2-*' | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  [pscustomobject]@{
    TaskName       = $_.TaskName
    State          = $_.State
    LastRunTime    = $i.LastRunTime
    LastTaskResult = $i.LastTaskResult
    NextRunTime    = $i.NextRunTime
  }
} | Sort-Object TaskName | Format-Table -Auto

