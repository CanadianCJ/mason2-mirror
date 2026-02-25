# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
param(
  [switch]$WhatIf,
  [switch]$ReallyDoIt,
  [string]$Pin = ""
)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
New-Item $Sig -ItemType Directory -ea SilentlyContinue | Out-Null

function Test-PIN([string]$Pin){
  $pol = Join-Path (Join-Path $Base "config") "policy.json"
  if(-not (Test-Path $pol)){ return $false }
  $p = Get-Content $pol -Raw | ConvertFrom-Json
  if([string]::IsNullOrWhiteSpace($p.operator_pin_hash)){ return $false }
  $hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
  return ($hash -eq $p.operator_pin_hash)
}

# plan
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard"
)
$plan = @()
$plan += "Disable & end scheduled tasks"
$plan += "Set kill.switch and freeze.on"
$plan += "Rename Mason2 folder to Mason2._removed_$(Get-Date -Format yyyyMMdd_HHmmss)"
$planPath = Join-Path $Rep "uninstall_plan.txt"
$plan | Set-Content $planPath -Encoding UTF8
"Plan -> $planPath"

if($WhatIf -and -not $ReallyDoIt){ "WHATIF: no changes."; exit 0 }

if(-not $ReallyDoIt){
  Write-Host "DENY: pass -ReallyDoIt to execute. Use -WhatIf to preview." -ForegroundColor Yellow
  exit 2
}
if(-not (Test-PIN $Pin)){
  Write-Host "DENY: invalid PIN." -ForegroundColor Red
  exit 3
}

# execute
"kill"   | Set-Content (Join-Path $Sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $Sig "freeze.on")    -Encoding ASCII
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
$parent = Split-Path $Base -Parent
$target = Join-Path $parent ("Mason2._removed_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
try{
  Rename-Item -LiteralPath $Base -NewName (Split-Path $target -Leaf) -Force
  "OK: renamed to $target"
}catch{
  "WARN: rename failed: $($_.Exception.Message)"
}
"Uninstall actions executed."

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
param(
  [switch]$WhatIf,
  [switch]$ReallyDoIt,
  [string]$Pin = ""
)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
New-Item $Sig -ItemType Directory -ea SilentlyContinue | Out-Null

function Test-PIN([string]$Pin){
  $pol = Join-Path (Join-Path $Base "config") "policy.json"
  if(-not (Test-Path $pol)){ return $false }
  $p = Get-Content $pol -Raw | ConvertFrom-Json
  if([string]::IsNullOrWhiteSpace($p.operator_pin_hash)){ return $false }
  $hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
  return ($hash -eq $p.operator_pin_hash)
}

# plan
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard"
)
$plan = @()
$plan += "Disable & end scheduled tasks"
$plan += "Set kill.switch and freeze.on"
$plan += "Rename Mason2 folder to Mason2._removed_$(Get-Date -Format yyyyMMdd_HHmmss)"
$planPath = Join-Path $Rep "uninstall_plan.txt"
$plan | Set-Content $planPath -Encoding UTF8
"Plan -> $planPath"

if($WhatIf -and -not $ReallyDoIt){ "WHATIF: no changes."; exit 0 }

if(-not $ReallyDoIt){
  Write-Host "DENY: pass -ReallyDoIt to execute. Use -WhatIf to preview." -ForegroundColor Yellow
  exit 2
}
if(-not (Test-PIN $Pin)){
  Write-Host "DENY: invalid PIN." -ForegroundColor Red
  exit 3
}

# execute
"kill"   | Set-Content (Join-Path $Sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $Sig "freeze.on")    -Encoding ASCII
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
$parent = Split-Path $Base -Parent
$target = Join-Path $parent ("Mason2._removed_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
try{
  Rename-Item -LiteralPath $Base -NewName (Split-Path $target -Leaf) -Force
  "OK: renamed to $target"
}catch{
  "WARN: rename failed: $($_.Exception.Message)"
}
"Uninstall actions executed."

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
param(
  [switch]$WhatIf,
  [switch]$ReallyDoIt,
  [string]$Pin = ""
)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
New-Item $Sig -ItemType Directory -ea SilentlyContinue | Out-Null

function Test-PIN([string]$Pin){
  $pol = Join-Path (Join-Path $Base "config") "policy.json"
  if(-not (Test-Path $pol)){ return $false }
  $p = Get-Content $pol -Raw | ConvertFrom-Json
  if([string]::IsNullOrWhiteSpace($p.operator_pin_hash)){ return $false }
  $hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
  return ($hash -eq $p.operator_pin_hash)
}

# plan
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard"
)
$plan = @()
$plan += "Disable & end scheduled tasks"
$plan += "Set kill.switch and freeze.on"
$plan += "Rename Mason2 folder to Mason2._removed_$(Get-Date -Format yyyyMMdd_HHmmss)"
$planPath = Join-Path $Rep "uninstall_plan.txt"
$plan | Set-Content $planPath -Encoding UTF8
"Plan -> $planPath"

if($WhatIf -and -not $ReallyDoIt){ "WHATIF: no changes."; exit 0 }

if(-not $ReallyDoIt){
  Write-Host "DENY: pass -ReallyDoIt to execute. Use -WhatIf to preview." -ForegroundColor Yellow
  exit 2
}
if(-not (Test-PIN $Pin)){
  Write-Host "DENY: invalid PIN." -ForegroundColor Red
  exit 3
}

# execute
"kill"   | Set-Content (Join-Path $Sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $Sig "freeze.on")    -Encoding ASCII
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
$parent = Split-Path $Base -Parent
$target = Join-Path $parent ("Mason2._removed_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
try{
  Rename-Item -LiteralPath $Base -NewName (Split-Path $target -Leaf) -Force
  "OK: renamed to $target"
}catch{
  "WARN: rename failed: $($_.Exception.Message)"
}
"Uninstall actions executed."

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
param(
  [switch]$WhatIf,
  [switch]$ReallyDoIt,
  [string]$Pin = ""
)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
New-Item $Sig -ItemType Directory -ea SilentlyContinue | Out-Null

function Test-PIN([string]$Pin){
  $pol = Join-Path (Join-Path $Base "config") "policy.json"
  if(-not (Test-Path $pol)){ return $false }
  $p = Get-Content $pol -Raw | ConvertFrom-Json
  if([string]::IsNullOrWhiteSpace($p.operator_pin_hash)){ return $false }
  $hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
  return ($hash -eq $p.operator_pin_hash)
}

# plan
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard"
)
$plan = @()
$plan += "Disable & end scheduled tasks"
$plan += "Set kill.switch and freeze.on"
$plan += "Rename Mason2 folder to Mason2._removed_$(Get-Date -Format yyyyMMdd_HHmmss)"
$planPath = Join-Path $Rep "uninstall_plan.txt"
$plan | Set-Content $planPath -Encoding UTF8
"Plan -> $planPath"

if($WhatIf -and -not $ReallyDoIt){ "WHATIF: no changes."; exit 0 }

if(-not $ReallyDoIt){
  Write-Host "DENY: pass -ReallyDoIt to execute. Use -WhatIf to preview." -ForegroundColor Yellow
  exit 2
}
if(-not (Test-PIN $Pin)){
  Write-Host "DENY: invalid PIN." -ForegroundColor Red
  exit 3
}

# execute
"kill"   | Set-Content (Join-Path $Sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $Sig "freeze.on")    -Encoding ASCII
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
$parent = Split-Path $Base -Parent
$target = Join-Path $parent ("Mason2._removed_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
try{
  Rename-Item -LiteralPath $Base -NewName (Split-Path $target -Leaf) -Force
  "OK: renamed to $target"
}catch{
  "WARN: rename failed: $($_.Exception.Message)"
}
"Uninstall actions executed."

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
param(
  [switch]$WhatIf,
  [switch]$ReallyDoIt,
  [string]$Pin = ""
)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
New-Item $Sig -ItemType Directory -ea SilentlyContinue | Out-Null

function Test-PIN([string]$Pin){
  $pol = Join-Path (Join-Path $Base "config") "policy.json"
  if(-not (Test-Path $pol)){ return $false }
  $p = Get-Content $pol -Raw | ConvertFrom-Json
  if([string]::IsNullOrWhiteSpace($p.operator_pin_hash)){ return $false }
  $hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
  return ($hash -eq $p.operator_pin_hash)
}

# plan
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard"
)
$plan = @()
$plan += "Disable & end scheduled tasks"
$plan += "Set kill.switch and freeze.on"
$plan += "Rename Mason2 folder to Mason2._removed_$(Get-Date -Format yyyyMMdd_HHmmss)"
$planPath = Join-Path $Rep "uninstall_plan.txt"
$plan | Set-Content $planPath -Encoding UTF8
"Plan -> $planPath"

if($WhatIf -and -not $ReallyDoIt){ "WHATIF: no changes."; exit 0 }

if(-not $ReallyDoIt){
  Write-Host "DENY: pass -ReallyDoIt to execute. Use -WhatIf to preview." -ForegroundColor Yellow
  exit 2
}
if(-not (Test-PIN $Pin)){
  Write-Host "DENY: invalid PIN." -ForegroundColor Red
  exit 3
}

# execute
"kill"   | Set-Content (Join-Path $Sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $Sig "freeze.on")    -Encoding ASCII
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
$parent = Split-Path $Base -Parent
$target = Join-Path $parent ("Mason2._removed_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
try{
  Rename-Item -LiteralPath $Base -NewName (Split-Path $target -Leaf) -Force
  "OK: renamed to $target"
}catch{
  "WARN: rename failed: $($_.Exception.Message)"
}
"Uninstall actions executed."

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
param(
  [switch]$WhatIf,
  [switch]$ReallyDoIt,
  [string]$Pin = ""
)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
New-Item $Sig -ItemType Directory -ea SilentlyContinue | Out-Null

function Test-PIN([string]$Pin){
  $pol = Join-Path (Join-Path $Base "config") "policy.json"
  if(-not (Test-Path $pol)){ return $false }
  $p = Get-Content $pol -Raw | ConvertFrom-Json
  if([string]::IsNullOrWhiteSpace($p.operator_pin_hash)){ return $false }
  $hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
  return ($hash -eq $p.operator_pin_hash)
}

# plan
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard"
)
$plan = @()
$plan += "Disable & end scheduled tasks"
$plan += "Set kill.switch and freeze.on"
$plan += "Rename Mason2 folder to Mason2._removed_$(Get-Date -Format yyyyMMdd_HHmmss)"
$planPath = Join-Path $Rep "uninstall_plan.txt"
$plan | Set-Content $planPath -Encoding UTF8
"Plan -> $planPath"

if($WhatIf -and -not $ReallyDoIt){ "WHATIF: no changes."; exit 0 }

if(-not $ReallyDoIt){
  Write-Host "DENY: pass -ReallyDoIt to execute. Use -WhatIf to preview." -ForegroundColor Yellow
  exit 2
}
if(-not (Test-PIN $Pin)){
  Write-Host "DENY: invalid PIN." -ForegroundColor Red
  exit 3
}

# execute
"kill"   | Set-Content (Join-Path $Sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $Sig "freeze.on")    -Encoding ASCII
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
$parent = Split-Path $Base -Parent
$target = Join-Path $parent ("Mason2._removed_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
try{
  Rename-Item -LiteralPath $Base -NewName (Split-Path $target -Leaf) -Force
  "OK: renamed to $target"
}catch{
  "WARN: rename failed: $($_.Exception.Message)"
}
"Uninstall actions executed."

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
param(
  [switch]$WhatIf,
  [switch]$ReallyDoIt,
  [string]$Pin = ""
)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
New-Item $Sig -ItemType Directory -ea SilentlyContinue | Out-Null

function Test-PIN([string]$Pin){
  $pol = Join-Path (Join-Path $Base "config") "policy.json"
  if(-not (Test-Path $pol)){ return $false }
  $p = Get-Content $pol -Raw | ConvertFrom-Json
  if([string]::IsNullOrWhiteSpace($p.operator_pin_hash)){ return $false }
  $hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
  return ($hash -eq $p.operator_pin_hash)
}

# plan
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard"
)
$plan = @()
$plan += "Disable & end scheduled tasks"
$plan += "Set kill.switch and freeze.on"
$plan += "Rename Mason2 folder to Mason2._removed_$(Get-Date -Format yyyyMMdd_HHmmss)"
$planPath = Join-Path $Rep "uninstall_plan.txt"
$plan | Set-Content $planPath -Encoding UTF8
"Plan -> $planPath"

if($WhatIf -and -not $ReallyDoIt){ "WHATIF: no changes."; exit 0 }

if(-not $ReallyDoIt){
  Write-Host "DENY: pass -ReallyDoIt to execute. Use -WhatIf to preview." -ForegroundColor Yellow
  exit 2
}
if(-not (Test-PIN $Pin)){
  Write-Host "DENY: invalid PIN." -ForegroundColor Red
  exit 3
}

# execute
"kill"   | Set-Content (Join-Path $Sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $Sig "freeze.on")    -Encoding ASCII
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
$parent = Split-Path $Base -Parent
$target = Join-Path $parent ("Mason2._removed_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
try{
  Rename-Item -LiteralPath $Base -NewName (Split-Path $target -Leaf) -Force
  "OK: renamed to $target"
}catch{
  "WARN: rename failed: $($_.Exception.Message)"
}
"Uninstall actions executed."

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
param(
  [switch]$WhatIf,
  [switch]$ReallyDoIt,
  [string]$Pin = ""
)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
New-Item $Sig -ItemType Directory -ea SilentlyContinue | Out-Null

function Test-PIN([string]$Pin){
  $pol = Join-Path (Join-Path $Base "config") "policy.json"
  if(-not (Test-Path $pol)){ return $false }
  $p = Get-Content $pol -Raw | ConvertFrom-Json
  if([string]::IsNullOrWhiteSpace($p.operator_pin_hash)){ return $false }
  $hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
  return ($hash -eq $p.operator_pin_hash)
}

# plan
$tasks = @(
 "Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer",
 "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 TopicSync","Mason2 Dashboard"
)
$plan = @()
$plan += "Disable & end scheduled tasks"
$plan += "Set kill.switch and freeze.on"
$plan += "Rename Mason2 folder to Mason2._removed_$(Get-Date -Format yyyyMMdd_HHmmss)"
$planPath = Join-Path $Rep "uninstall_plan.txt"
$plan | Set-Content $planPath -Encoding UTF8
"Plan -> $planPath"

if($WhatIf -and -not $ReallyDoIt){ "WHATIF: no changes."; exit 0 }

if(-not $ReallyDoIt){
  Write-Host "DENY: pass -ReallyDoIt to execute. Use -WhatIf to preview." -ForegroundColor Yellow
  exit 2
}
if(-not (Test-PIN $Pin)){
  Write-Host "DENY: invalid PIN." -ForegroundColor Red
  exit 3
}

# execute
"kill"   | Set-Content (Join-Path $Sig "kill.switch") -Encoding ASCII
"freeze" | Set-Content (Join-Path $Sig "freeze.on")    -Encoding ASCII
foreach($t in $tasks){ schtasks /End /TN $t 2>$null | Out-Null }
foreach($t in $tasks){ schtasks /Change /TN $t /DISABLE 2>$null | Out-Null }
$parent = Split-Path $Base -Parent
$target = Join-Path $parent ("Mason2._removed_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
try{
  Rename-Item -LiteralPath $Base -NewName (Split-Path $target -Leaf) -Force
  "OK: renamed to $target"
}catch{
  "WARN: rename failed: $($_.Exception.Message)"
}
"Uninstall actions executed."

