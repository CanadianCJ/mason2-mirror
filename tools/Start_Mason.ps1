# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$pwsh  = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$tools = Join-Path $base "tools"
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard"
)
foreach($t in $tasks){ schtasks /Change /TN $t /ENABLE 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Run /TN $t 2>$null | Out-Null }
# Clear kill.switch & freeze
$kill = Join-Path (Join-Path $base "reports") "signals\kill.switch"
$freeze = Join-Path (Join-Path $base "reports") "signals\freeze.on"
Remove-Item $kill,$freeze -Force -ea SilentlyContinue
"Started Mason scheduled tasks."

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$pwsh  = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$tools = Join-Path $base "tools"
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard"
)
foreach($t in $tasks){ schtasks /Change /TN $t /ENABLE 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Run /TN $t 2>$null | Out-Null }
# Clear kill.switch & freeze
$kill = Join-Path (Join-Path $base "reports") "signals\kill.switch"
$freeze = Join-Path (Join-Path $base "reports") "signals\freeze.on"
Remove-Item $kill,$freeze -Force -ea SilentlyContinue
"Started Mason scheduled tasks."

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$pwsh  = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$tools = Join-Path $base "tools"
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard"
)
foreach($t in $tasks){ schtasks /Change /TN $t /ENABLE 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Run /TN $t 2>$null | Out-Null }
# Clear kill.switch & freeze
$kill = Join-Path (Join-Path $base "reports") "signals\kill.switch"
$freeze = Join-Path (Join-Path $base "reports") "signals\freeze.on"
Remove-Item $kill,$freeze -Force -ea SilentlyContinue
"Started Mason scheduled tasks."

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$pwsh  = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$tools = Join-Path $base "tools"
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard"
)
foreach($t in $tasks){ schtasks /Change /TN $t /ENABLE 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Run /TN $t 2>$null | Out-Null }
# Clear kill.switch & freeze
$kill = Join-Path (Join-Path $base "reports") "signals\kill.switch"
$freeze = Join-Path (Join-Path $base "reports") "signals\freeze.on"
Remove-Item $kill,$freeze -Force -ea SilentlyContinue
"Started Mason scheduled tasks."

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$pwsh  = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$tools = Join-Path $base "tools"
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard"
)
foreach($t in $tasks){ schtasks /Change /TN $t /ENABLE 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Run /TN $t 2>$null | Out-Null }
# Clear kill.switch & freeze
$kill = Join-Path (Join-Path $base "reports") "signals\kill.switch"
$freeze = Join-Path (Join-Path $base "reports") "signals\freeze.on"
Remove-Item $kill,$freeze -Force -ea SilentlyContinue
"Started Mason scheduled tasks."

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$pwsh  = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$tools = Join-Path $base "tools"
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard"
)
foreach($t in $tasks){ schtasks /Change /TN $t /ENABLE 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Run /TN $t 2>$null | Out-Null }
# Clear kill.switch & freeze
$kill = Join-Path (Join-Path $base "reports") "signals\kill.switch"
$freeze = Join-Path (Join-Path $base "reports") "signals\freeze.on"
Remove-Item $kill,$freeze -Force -ea SilentlyContinue
"Started Mason scheduled tasks."

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$pwsh  = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$tools = Join-Path $base "tools"
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard"
)
foreach($t in $tasks){ schtasks /Change /TN $t /ENABLE 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Run /TN $t 2>$null | Out-Null }
# Clear kill.switch & freeze
$kill = Join-Path (Join-Path $base "reports") "signals\kill.switch"
$freeze = Join-Path (Join-Path $base "reports") "signals\freeze.on"
Remove-Item $kill,$freeze -Force -ea SilentlyContinue
"Started Mason scheduled tasks."

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$pwsh  = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$tools = Join-Path $base "tools"
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard"
)
foreach($t in $tasks){ schtasks /Change /TN $t /ENABLE 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Run /TN $t 2>$null | Out-Null }
# Clear kill.switch & freeze
$kill = Join-Path (Join-Path $base "reports") "signals\kill.switch"
$freeze = Join-Path (Join-Path $base "reports") "signals\freeze.on"
Remove-Item $kill,$freeze -Force -ea SilentlyContinue
"Started Mason scheduled tasks."

