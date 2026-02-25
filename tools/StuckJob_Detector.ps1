# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function Get-TaskObj([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  return ($csv | ConvertFrom-Csv | Select-Object -First 1)
}
$names = @(
  "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot",
  "Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance",
  "Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
$stuck = @()
foreach($n in $names){
  $o = Get-TaskObj $n
  if(-not $o){ continue }
  $running = ($o.Status + "") -match "Running"
  $last = $o.'Last Run Time' + ''
  if($running -and $last -and $last -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($last)).TotalMinutes
    if($mins -gt 15){ $stuck += [pscustomobject]@{ name=$n; mins=$mins } }
  }
}
if($stuck.Count -gt 0){
  Write-JsonLog -Component "stuck" -Level "WARN" -Message "stuck tasks" -Props @{ tasks=($stuck | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "stuck" -Level "INFO" -Message "no stuck tasks"
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function Get-TaskObj([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  return ($csv | ConvertFrom-Csv | Select-Object -First 1)
}
$names = @(
  "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot",
  "Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance",
  "Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
$stuck = @()
foreach($n in $names){
  $o = Get-TaskObj $n
  if(-not $o){ continue }
  $running = ($o.Status + "") -match "Running"
  $last = $o.'Last Run Time' + ''
  if($running -and $last -and $last -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($last)).TotalMinutes
    if($mins -gt 15){ $stuck += [pscustomobject]@{ name=$n; mins=$mins } }
  }
}
if($stuck.Count -gt 0){
  Write-JsonLog -Component "stuck" -Level "WARN" -Message "stuck tasks" -Props @{ tasks=($stuck | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "stuck" -Level "INFO" -Message "no stuck tasks"
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function Get-TaskObj([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  return ($csv | ConvertFrom-Csv | Select-Object -First 1)
}
$names = @(
  "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot",
  "Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance",
  "Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
$stuck = @()
foreach($n in $names){
  $o = Get-TaskObj $n
  if(-not $o){ continue }
  $running = ($o.Status + "") -match "Running"
  $last = $o.'Last Run Time' + ''
  if($running -and $last -and $last -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($last)).TotalMinutes
    if($mins -gt 15){ $stuck += [pscustomobject]@{ name=$n; mins=$mins } }
  }
}
if($stuck.Count -gt 0){
  Write-JsonLog -Component "stuck" -Level "WARN" -Message "stuck tasks" -Props @{ tasks=($stuck | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "stuck" -Level "INFO" -Message "no stuck tasks"
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function Get-TaskObj([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  return ($csv | ConvertFrom-Csv | Select-Object -First 1)
}
$names = @(
  "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot",
  "Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance",
  "Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
$stuck = @()
foreach($n in $names){
  $o = Get-TaskObj $n
  if(-not $o){ continue }
  $running = ($o.Status + "") -match "Running"
  $last = $o.'Last Run Time' + ''
  if($running -and $last -and $last -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($last)).TotalMinutes
    if($mins -gt 15){ $stuck += [pscustomobject]@{ name=$n; mins=$mins } }
  }
}
if($stuck.Count -gt 0){
  Write-JsonLog -Component "stuck" -Level "WARN" -Message "stuck tasks" -Props @{ tasks=($stuck | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "stuck" -Level "INFO" -Message "no stuck tasks"
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function Get-TaskObj([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  return ($csv | ConvertFrom-Csv | Select-Object -First 1)
}
$names = @(
  "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot",
  "Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance",
  "Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
$stuck = @()
foreach($n in $names){
  $o = Get-TaskObj $n
  if(-not $o){ continue }
  $running = ($o.Status + "") -match "Running"
  $last = $o.'Last Run Time' + ''
  if($running -and $last -and $last -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($last)).TotalMinutes
    if($mins -gt 15){ $stuck += [pscustomobject]@{ name=$n; mins=$mins } }
  }
}
if($stuck.Count -gt 0){
  Write-JsonLog -Component "stuck" -Level "WARN" -Message "stuck tasks" -Props @{ tasks=($stuck | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "stuck" -Level "INFO" -Message "no stuck tasks"
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function Get-TaskObj([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  return ($csv | ConvertFrom-Csv | Select-Object -First 1)
}
$names = @(
  "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot",
  "Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance",
  "Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
$stuck = @()
foreach($n in $names){
  $o = Get-TaskObj $n
  if(-not $o){ continue }
  $running = ($o.Status + "") -match "Running"
  $last = $o.'Last Run Time' + ''
  if($running -and $last -and $last -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($last)).TotalMinutes
    if($mins -gt 15){ $stuck += [pscustomobject]@{ name=$n; mins=$mins } }
  }
}
if($stuck.Count -gt 0){
  Write-JsonLog -Component "stuck" -Level "WARN" -Message "stuck tasks" -Props @{ tasks=($stuck | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "stuck" -Level "INFO" -Message "no stuck tasks"
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function Get-TaskObj([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  return ($csv | ConvertFrom-Csv | Select-Object -First 1)
}
$names = @(
  "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot",
  "Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance",
  "Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
$stuck = @()
foreach($n in $names){
  $o = Get-TaskObj $n
  if(-not $o){ continue }
  $running = ($o.Status + "") -match "Running"
  $last = $o.'Last Run Time' + ''
  if($running -and $last -and $last -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($last)).TotalMinutes
    if($mins -gt 15){ $stuck += [pscustomobject]@{ name=$n; mins=$mins } }
  }
}
if($stuck.Count -gt 0){
  Write-JsonLog -Component "stuck" -Level "WARN" -Message "stuck tasks" -Props @{ tasks=($stuck | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "stuck" -Level "INFO" -Message "no stuck tasks"
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function Get-TaskObj([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  return ($csv | ConvertFrom-Csv | Select-Object -First 1)
}
$names = @(
  "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot",
  "Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance",
  "Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
$stuck = @()
foreach($n in $names){
  $o = Get-TaskObj $n
  if(-not $o){ continue }
  $running = ($o.Status + "") -match "Running"
  $last = $o.'Last Run Time' + ''
  if($running -and $last -and $last -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($last)).TotalMinutes
    if($mins -gt 15){ $stuck += [pscustomobject]@{ name=$n; mins=$mins } }
  }
}
if($stuck.Count -gt 0){
  Write-JsonLog -Component "stuck" -Level "WARN" -Message "stuck tasks" -Props @{ tasks=($stuck | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "stuck" -Level "INFO" -Message "no stuck tasks"
}

