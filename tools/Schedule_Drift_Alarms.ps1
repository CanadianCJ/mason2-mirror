# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\schedule_drift.jsonl'
$now = Get-Date

Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  $sev = 'ok'
  if ($_.State -eq 'Disabled') { $sev = 'warn' }
  elseif ($i.NextRunTime -lt $now) { $sev = 'warn' }
  $evt = @{
    ts       = $now.ToString('s')
    kind     = 'schedule_drift'
    task     = $_.TaskName
    state    = $_.State.ToString()
    last_run = $i.LastRunTime
    next_run = $i.NextRunTime
    severity = $sev
  }
  Write-JsonLineSafe -Path $log -Obj $evt
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\schedule_drift.jsonl'
$now = Get-Date

Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  $sev = 'ok'
  if ($_.State -eq 'Disabled') { $sev = 'warn' }
  elseif ($i.NextRunTime -lt $now) { $sev = 'warn' }
  $evt = @{
    ts       = $now.ToString('s')
    kind     = 'schedule_drift'
    task     = $_.TaskName
    state    = $_.State.ToString()
    last_run = $i.LastRunTime
    next_run = $i.NextRunTime
    severity = $sev
  }
  Write-JsonLineSafe -Path $log -Obj $evt
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\schedule_drift.jsonl'
$now = Get-Date

Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  $sev = 'ok'
  if ($_.State -eq 'Disabled') { $sev = 'warn' }
  elseif ($i.NextRunTime -lt $now) { $sev = 'warn' }
  $evt = @{
    ts       = $now.ToString('s')
    kind     = 'schedule_drift'
    task     = $_.TaskName
    state    = $_.State.ToString()
    last_run = $i.LastRunTime
    next_run = $i.NextRunTime
    severity = $sev
  }
  Write-JsonLineSafe -Path $log -Obj $evt
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\schedule_drift.jsonl'
$now = Get-Date

Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  $sev = 'ok'
  if ($_.State -eq 'Disabled') { $sev = 'warn' }
  elseif ($i.NextRunTime -lt $now) { $sev = 'warn' }
  $evt = @{
    ts       = $now.ToString('s')
    kind     = 'schedule_drift'
    task     = $_.TaskName
    state    = $_.State.ToString()
    last_run = $i.LastRunTime
    next_run = $i.NextRunTime
    severity = $sev
  }
  Write-JsonLineSafe -Path $log -Obj $evt
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\schedule_drift.jsonl'
$now = Get-Date

Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  $sev = 'ok'
  if ($_.State -eq 'Disabled') { $sev = 'warn' }
  elseif ($i.NextRunTime -lt $now) { $sev = 'warn' }
  $evt = @{
    ts       = $now.ToString('s')
    kind     = 'schedule_drift'
    task     = $_.TaskName
    state    = $_.State.ToString()
    last_run = $i.LastRunTime
    next_run = $i.NextRunTime
    severity = $sev
  }
  Write-JsonLineSafe -Path $log -Obj $evt
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\schedule_drift.jsonl'
$now = Get-Date

Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  $sev = 'ok'
  if ($_.State -eq 'Disabled') { $sev = 'warn' }
  elseif ($i.NextRunTime -lt $now) { $sev = 'warn' }
  $evt = @{
    ts       = $now.ToString('s')
    kind     = 'schedule_drift'
    task     = $_.TaskName
    state    = $_.State.ToString()
    last_run = $i.LastRunTime
    next_run = $i.NextRunTime
    severity = $sev
  }
  Write-JsonLineSafe -Path $log -Obj $evt
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\schedule_drift.jsonl'
$now = Get-Date

Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  $sev = 'ok'
  if ($_.State -eq 'Disabled') { $sev = 'warn' }
  elseif ($i.NextRunTime -lt $now) { $sev = 'warn' }
  $evt = @{
    ts       = $now.ToString('s')
    kind     = 'schedule_drift'
    task     = $_.TaskName
    state    = $_.State.ToString()
    last_run = $i.LastRunTime
    next_run = $i.NextRunTime
    severity = $sev
  }
  Write-JsonLineSafe -Path $log -Obj $evt
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\schedule_drift.jsonl'
$now = Get-Date

Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  $i = $_ | Get-ScheduledTaskInfo
  $sev = 'ok'
  if ($_.State -eq 'Disabled') { $sev = 'warn' }
  elseif ($i.NextRunTime -lt $now) { $sev = 'warn' }
  $evt = @{
    ts       = $now.ToString('s')
    kind     = 'schedule_drift'
    task     = $_.TaskName
    state    = $_.State.ToString()
    last_run = $i.LastRunTime
    next_run = $i.NextRunTime
    severity = $sev
  }
  Write-JsonLineSafe -Path $log -Obj $evt
}

