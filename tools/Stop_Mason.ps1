# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$sig   = Join-Path (Join-Path $base "reports") "signals"
ni $sig -ItemType Directory -ea SilentlyContinue | Out-Null
# Set kill switch & freeze ON
"kill" | Set-Content (Join-Path $sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $sig "freeze.on") -Encoding ASCII
# End & disable tasks
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
"Stopped Mason scheduled tasks (freeze ON)."

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$sig   = Join-Path (Join-Path $base "reports") "signals"
ni $sig -ItemType Directory -ea SilentlyContinue | Out-Null
# Set kill switch & freeze ON
"kill" | Set-Content (Join-Path $sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $sig "freeze.on") -Encoding ASCII
# End & disable tasks
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
"Stopped Mason scheduled tasks (freeze ON)."

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$sig   = Join-Path (Join-Path $base "reports") "signals"
ni $sig -ItemType Directory -ea SilentlyContinue | Out-Null
# Set kill switch & freeze ON
"kill" | Set-Content (Join-Path $sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $sig "freeze.on") -Encoding ASCII
# End & disable tasks
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
"Stopped Mason scheduled tasks (freeze ON)."

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$sig   = Join-Path (Join-Path $base "reports") "signals"
ni $sig -ItemType Directory -ea SilentlyContinue | Out-Null
# Set kill switch & freeze ON
"kill" | Set-Content (Join-Path $sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $sig "freeze.on") -Encoding ASCII
# End & disable tasks
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
"Stopped Mason scheduled tasks (freeze ON)."

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$sig   = Join-Path (Join-Path $base "reports") "signals"
ni $sig -ItemType Directory -ea SilentlyContinue | Out-Null
# Set kill switch & freeze ON
"kill" | Set-Content (Join-Path $sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $sig "freeze.on") -Encoding ASCII
# End & disable tasks
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
"Stopped Mason scheduled tasks (freeze ON)."

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$sig   = Join-Path (Join-Path $base "reports") "signals"
ni $sig -ItemType Directory -ea SilentlyContinue | Out-Null
# Set kill switch & freeze ON
"kill" | Set-Content (Join-Path $sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $sig "freeze.on") -Encoding ASCII
# End & disable tasks
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
"Stopped Mason scheduled tasks (freeze ON)."

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$sig   = Join-Path (Join-Path $base "reports") "signals"
ni $sig -ItemType Directory -ea SilentlyContinue | Out-Null
# Set kill switch & freeze ON
"kill" | Set-Content (Join-Path $sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $sig "freeze.on") -Encoding ASCII
# End & disable tasks
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
"Stopped Mason scheduled tasks (freeze ON)."

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param()
$base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$sig   = Join-Path (Join-Path $base "reports") "signals"
ni $sig -ItemType Directory -ea SilentlyContinue | Out-Null
# Set kill switch & freeze ON
"kill" | Set-Content (Join-Path $sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $sig "freeze.on") -Encoding ASCII
# End & disable tasks
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms"
)
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
"Stopped Mason scheduled tasks (freeze ON)."

