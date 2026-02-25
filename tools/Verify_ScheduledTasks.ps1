# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms")
$miss = @(); foreach($n in $need){ if(-not (schtasks.exe /Query /TN $n 2>$null)){ $miss += $n } }
$rep = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals\automation-schedules-task-scheduler-verifier.ok'
"ok" | Set-Content $rep -Encoding ASCII
if($miss.Count -gt 0){ Write-Host "[WARN] Missing tasks: $($miss -join ', ')" -ForegroundColor Yellow }


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms")
$miss = @(); foreach($n in $need){ if(-not (schtasks.exe /Query /TN $n 2>$null)){ $miss += $n } }
$rep = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals\automation-schedules-task-scheduler-verifier.ok'
"ok" | Set-Content $rep -Encoding ASCII
if($miss.Count -gt 0){ Write-Host "[WARN] Missing tasks: $($miss -join ', ')" -ForegroundColor Yellow }


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms")
$miss = @(); foreach($n in $need){ if(-not (schtasks.exe /Query /TN $n 2>$null)){ $miss += $n } }
$rep = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals\automation-schedules-task-scheduler-verifier.ok'
"ok" | Set-Content $rep -Encoding ASCII
if($miss.Count -gt 0){ Write-Host "[WARN] Missing tasks: $($miss -join ', ')" -ForegroundColor Yellow }


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms")
$miss = @(); foreach($n in $need){ if(-not (schtasks.exe /Query /TN $n 2>$null)){ $miss += $n } }
$rep = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals\automation-schedules-task-scheduler-verifier.ok'
"ok" | Set-Content $rep -Encoding ASCII
if($miss.Count -gt 0){ Write-Host "[WARN] Missing tasks: $($miss -join ', ')" -ForegroundColor Yellow }


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms")
$miss = @(); foreach($n in $need){ if(-not (schtasks.exe /Query /TN $n 2>$null)){ $miss += $n } }
$rep = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals\automation-schedules-task-scheduler-verifier.ok'
"ok" | Set-Content $rep -Encoding ASCII
if($miss.Count -gt 0){ Write-Host "[WARN] Missing tasks: $($miss -join ', ')" -ForegroundColor Yellow }


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms")
$miss = @(); foreach($n in $need){ if(-not (schtasks.exe /Query /TN $n 2>$null)){ $miss += $n } }
$rep = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals\automation-schedules-task-scheduler-verifier.ok'
"ok" | Set-Content $rep -Encoding ASCII
if($miss.Count -gt 0){ Write-Host "[WARN] Missing tasks: $($miss -join ', ')" -ForegroundColor Yellow }


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms")
$miss = @(); foreach($n in $need){ if(-not (schtasks.exe /Query /TN $n 2>$null)){ $miss += $n } }
$rep = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals\automation-schedules-task-scheduler-verifier.ok'
"ok" | Set-Content $rep -Encoding ASCII
if($miss.Count -gt 0){ Write-Host "[WARN] Missing tasks: $($miss -join ', ')" -ForegroundColor Yellow }


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance","Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms")
$miss = @(); foreach($n in $need){ if(-not (schtasks.exe /Query /TN $n 2>$null)){ $miss += $n } }
$rep = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals\automation-schedules-task-scheduler-verifier.ok'
"ok" | Set-Content $rep -Encoding ASCII
if($miss.Count -gt 0){ Write-Host "[WARN] Missing tasks: $($miss -join ', ')" -ForegroundColor Yellow }


