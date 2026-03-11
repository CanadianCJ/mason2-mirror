# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\tools\Install_Logger.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
New-Item $Rep -ItemType Directory -ea SilentlyContinue | Out-Null

$drive = Get-PSDrive -Name (Split-Path $Base -Qualifier).TrimEnd(':')
$freePct = 0
try { $freePct = [math]::Round(100 * ($drive.Free / ($drive.Used + $drive.Free)), 2) } catch {}

$tasks = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
           "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard")
$present = 0
foreach($t in $tasks){
  $c = & schtasks.exe /Query /TN $t /FO CSV 2>$null
  if($c){ $present++ }
}

$status = [ordered]@{
  ts = (Get-Date).ToString('o')
  user = $env:USERNAME
  ps_version = $PSVersionTable.PSVersion.ToString()
  os = (Get-CimInstance Win32_OperatingSystem).Caption
  disk_free_pct = $freePct
  tasks_present = $present
}
($status | ConvertTo-Json -Depth 4) | Set-Content (Join-Path $Rep "last_install_status.json") -Encoding UTF8
Write-InstallLog -Message "install_status" -Props @{ disk_free_pct="$freePct"; tasks_present="$present"; ps="$($status.ps_version)" } | Out-Null
"OK"

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\tools\Install_Logger.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
New-Item $Rep -ItemType Directory -ea SilentlyContinue | Out-Null

$drive = Get-PSDrive -Name (Split-Path $Base -Qualifier).TrimEnd(':')
$freePct = 0
try { $freePct = [math]::Round(100 * ($drive.Free / ($drive.Used + $drive.Free)), 2) } catch {}

$tasks = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
           "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard")
$present = 0
foreach($t in $tasks){
  $c = & schtasks.exe /Query /TN $t /FO CSV 2>$null
  if($c){ $present++ }
}

$status = [ordered]@{
  ts = (Get-Date).ToString('o')
  user = $env:USERNAME
  ps_version = $PSVersionTable.PSVersion.ToString()
  os = (Get-CimInstance Win32_OperatingSystem).Caption
  disk_free_pct = $freePct
  tasks_present = $present
}
($status | ConvertTo-Json -Depth 4) | Set-Content (Join-Path $Rep "last_install_status.json") -Encoding UTF8
Write-InstallLog -Message "install_status" -Props @{ disk_free_pct="$freePct"; tasks_present="$present"; ps="$($status.ps_version)" } | Out-Null
"OK"

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\tools\Install_Logger.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
New-Item $Rep -ItemType Directory -ea SilentlyContinue | Out-Null

$drive = Get-PSDrive -Name (Split-Path $Base -Qualifier).TrimEnd(':')
$freePct = 0
try { $freePct = [math]::Round(100 * ($drive.Free / ($drive.Used + $drive.Free)), 2) } catch {}

$tasks = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
           "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard")
$present = 0
foreach($t in $tasks){
  $c = & schtasks.exe /Query /TN $t /FO CSV 2>$null
  if($c){ $present++ }
}

$status = [ordered]@{
  ts = (Get-Date).ToString('o')
  user = $env:USERNAME
  ps_version = $PSVersionTable.PSVersion.ToString()
  os = (Get-CimInstance Win32_OperatingSystem).Caption
  disk_free_pct = $freePct
  tasks_present = $present
}
($status | ConvertTo-Json -Depth 4) | Set-Content (Join-Path $Rep "last_install_status.json") -Encoding UTF8
Write-InstallLog -Message "install_status" -Props @{ disk_free_pct="$freePct"; tasks_present="$present"; ps="$($status.ps_version)" } | Out-Null
"OK"

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\tools\Install_Logger.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
New-Item $Rep -ItemType Directory -ea SilentlyContinue | Out-Null

$drive = Get-PSDrive -Name (Split-Path $Base -Qualifier).TrimEnd(':')
$freePct = 0
try { $freePct = [math]::Round(100 * ($drive.Free / ($drive.Used + $drive.Free)), 2) } catch {}

$tasks = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
           "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard")
$present = 0
foreach($t in $tasks){
  $c = & schtasks.exe /Query /TN $t /FO CSV 2>$null
  if($c){ $present++ }
}

$status = [ordered]@{
  ts = (Get-Date).ToString('o')
  user = $env:USERNAME
  ps_version = $PSVersionTable.PSVersion.ToString()
  os = (Get-CimInstance Win32_OperatingSystem).Caption
  disk_free_pct = $freePct
  tasks_present = $present
}
($status | ConvertTo-Json -Depth 4) | Set-Content (Join-Path $Rep "last_install_status.json") -Encoding UTF8
Write-InstallLog -Message "install_status" -Props @{ disk_free_pct="$freePct"; tasks_present="$present"; ps="$($status.ps_version)" } | Out-Null
"OK"

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\tools\Install_Logger.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
New-Item $Rep -ItemType Directory -ea SilentlyContinue | Out-Null

$drive = Get-PSDrive -Name (Split-Path $Base -Qualifier).TrimEnd(':')
$freePct = 0
try { $freePct = [math]::Round(100 * ($drive.Free / ($drive.Used + $drive.Free)), 2) } catch {}

$tasks = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
           "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard")
$present = 0
foreach($t in $tasks){
  $c = & schtasks.exe /Query /TN $t /FO CSV 2>$null
  if($c){ $present++ }
}

$status = [ordered]@{
  ts = (Get-Date).ToString('o')
  user = $env:USERNAME
  ps_version = $PSVersionTable.PSVersion.ToString()
  os = (Get-CimInstance Win32_OperatingSystem).Caption
  disk_free_pct = $freePct
  tasks_present = $present
}
($status | ConvertTo-Json -Depth 4) | Set-Content (Join-Path $Rep "last_install_status.json") -Encoding UTF8
Write-InstallLog -Message "install_status" -Props @{ disk_free_pct="$freePct"; tasks_present="$present"; ps="$($status.ps_version)" } | Out-Null
"OK"

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\tools\Install_Logger.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
New-Item $Rep -ItemType Directory -ea SilentlyContinue | Out-Null

$drive = Get-PSDrive -Name (Split-Path $Base -Qualifier).TrimEnd(':')
$freePct = 0
try { $freePct = [math]::Round(100 * ($drive.Free / ($drive.Used + $drive.Free)), 2) } catch {}

$tasks = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
           "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard")
$present = 0
foreach($t in $tasks){
  $c = & schtasks.exe /Query /TN $t /FO CSV 2>$null
  if($c){ $present++ }
}

$status = [ordered]@{
  ts = (Get-Date).ToString('o')
  user = $env:USERNAME
  ps_version = $PSVersionTable.PSVersion.ToString()
  os = (Get-CimInstance Win32_OperatingSystem).Caption
  disk_free_pct = $freePct
  tasks_present = $present
}
($status | ConvertTo-Json -Depth 4) | Set-Content (Join-Path $Rep "last_install_status.json") -Encoding UTF8
Write-InstallLog -Message "install_status" -Props @{ disk_free_pct="$freePct"; tasks_present="$present"; ps="$($status.ps_version)" } | Out-Null
"OK"

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\tools\Install_Logger.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
New-Item $Rep -ItemType Directory -ea SilentlyContinue | Out-Null

$drive = Get-PSDrive -Name (Split-Path $Base -Qualifier).TrimEnd(':')
$freePct = 0
try { $freePct = [math]::Round(100 * ($drive.Free / ($drive.Used + $drive.Free)), 2) } catch {}

$tasks = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
           "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard")
$present = 0
foreach($t in $tasks){
  $c = & schtasks.exe /Query /TN $t /FO CSV 2>$null
  if($c){ $present++ }
}

$status = [ordered]@{
  ts = (Get-Date).ToString('o')
  user = $env:USERNAME
  ps_version = $PSVersionTable.PSVersion.ToString()
  os = (Get-CimInstance Win32_OperatingSystem).Caption
  disk_free_pct = $freePct
  tasks_present = $present
}
($status | ConvertTo-Json -Depth 4) | Set-Content (Join-Path $Rep "last_install_status.json") -Encoding UTF8
Write-InstallLog -Message "install_status" -Props @{ disk_free_pct="$freePct"; tasks_present="$present"; ps="$($status.ps_version)" } | Out-Null
"OK"

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\tools\Install_Logger.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
New-Item $Rep -ItemType Directory -ea SilentlyContinue | Out-Null

$drive = Get-PSDrive -Name (Split-Path $Base -Qualifier).TrimEnd(':')
$freePct = 0
try { $freePct = [math]::Round(100 * ($drive.Free / ($drive.Used + $drive.Free)), 2) } catch {}

$tasks = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
           "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard")
$present = 0
foreach($t in $tasks){
  $c = & schtasks.exe /Query /TN $t /FO CSV 2>$null
  if($c){ $present++ }
}

$status = [ordered]@{
  ts = (Get-Date).ToString('o')
  user = $env:USERNAME
  ps_version = $PSVersionTable.PSVersion.ToString()
  os = (Get-CimInstance Win32_OperatingSystem).Caption
  disk_free_pct = $freePct
  tasks_present = $present
}
($status | ConvertTo-Json -Depth 4) | Set-Content (Join-Path $Rep "last_install_status.json") -Encoding UTF8
Write-InstallLog -Message "install_status" -Props @{ disk_free_pct="$freePct"; tasks_present="$present"; ps="$($status.ps_version)" } | Out-Null
"OK"

