# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function LastRunMins([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  $o = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  if($o.'Last Run Time' -and $o.'Last Run Time' -notmatch 'Never'){
    return [int]([datetime]::Now - [datetime]::Parse($o.'Last Run Time')).TotalMinutes
  }
  return $null
}
# expected cadence (minutes)
$expect = @{
  "Mason2 Heartbeat"=1; "Mason2 Watchdog"=1; "Mason2 Governor"=2;
  "Mason2 AnomalyDetector"=5; "Mason2 RetrySweeper"=5; "Mason2 StuckJobDetector"=10;
  "Mason2 ScheduleDriftAlarms"=60
}
$bad=@()
foreach($k in $expect.Keys){
  $m = LastRunMins $k
  if($m -ne $null -and $m -gt ($expect[$k]*3)){ $bad += [pscustomobject]@{ name=$k; mins=$m; expect=$expect[$k] } }
}
if($bad.Count -gt 0){
  Write-JsonLog -Component "scheduler" -Level "WARN" -Message "schedule drift" -Props @{ items=($bad | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "scheduler" -Level "INFO" -Message "on cadence"
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function LastRunMins([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  $o = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  if($o.'Last Run Time' -and $o.'Last Run Time' -notmatch 'Never'){
    return [int]([datetime]::Now - [datetime]::Parse($o.'Last Run Time')).TotalMinutes
  }
  return $null
}
# expected cadence (minutes)
$expect = @{
  "Mason2 Heartbeat"=1; "Mason2 Watchdog"=1; "Mason2 Governor"=2;
  "Mason2 AnomalyDetector"=5; "Mason2 RetrySweeper"=5; "Mason2 StuckJobDetector"=10;
  "Mason2 ScheduleDriftAlarms"=60
}
$bad=@()
foreach($k in $expect.Keys){
  $m = LastRunMins $k
  if($m -ne $null -and $m -gt ($expect[$k]*3)){ $bad += [pscustomobject]@{ name=$k; mins=$m; expect=$expect[$k] } }
}
if($bad.Count -gt 0){
  Write-JsonLog -Component "scheduler" -Level "WARN" -Message "schedule drift" -Props @{ items=($bad | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "scheduler" -Level "INFO" -Message "on cadence"
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function LastRunMins([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  $o = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  if($o.'Last Run Time' -and $o.'Last Run Time' -notmatch 'Never'){
    return [int]([datetime]::Now - [datetime]::Parse($o.'Last Run Time')).TotalMinutes
  }
  return $null
}
# expected cadence (minutes)
$expect = @{
  "Mason2 Heartbeat"=1; "Mason2 Watchdog"=1; "Mason2 Governor"=2;
  "Mason2 AnomalyDetector"=5; "Mason2 RetrySweeper"=5; "Mason2 StuckJobDetector"=10;
  "Mason2 ScheduleDriftAlarms"=60
}
$bad=@()
foreach($k in $expect.Keys){
  $m = LastRunMins $k
  if($m -ne $null -and $m -gt ($expect[$k]*3)){ $bad += [pscustomobject]@{ name=$k; mins=$m; expect=$expect[$k] } }
}
if($bad.Count -gt 0){
  Write-JsonLog -Component "scheduler" -Level "WARN" -Message "schedule drift" -Props @{ items=($bad | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "scheduler" -Level "INFO" -Message "on cadence"
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function LastRunMins([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  $o = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  if($o.'Last Run Time' -and $o.'Last Run Time' -notmatch 'Never'){
    return [int]([datetime]::Now - [datetime]::Parse($o.'Last Run Time')).TotalMinutes
  }
  return $null
}
# expected cadence (minutes)
$expect = @{
  "Mason2 Heartbeat"=1; "Mason2 Watchdog"=1; "Mason2 Governor"=2;
  "Mason2 AnomalyDetector"=5; "Mason2 RetrySweeper"=5; "Mason2 StuckJobDetector"=10;
  "Mason2 ScheduleDriftAlarms"=60
}
$bad=@()
foreach($k in $expect.Keys){
  $m = LastRunMins $k
  if($m -ne $null -and $m -gt ($expect[$k]*3)){ $bad += [pscustomobject]@{ name=$k; mins=$m; expect=$expect[$k] } }
}
if($bad.Count -gt 0){
  Write-JsonLog -Component "scheduler" -Level "WARN" -Message "schedule drift" -Props @{ items=($bad | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "scheduler" -Level "INFO" -Message "on cadence"
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function LastRunMins([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  $o = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  if($o.'Last Run Time' -and $o.'Last Run Time' -notmatch 'Never'){
    return [int]([datetime]::Now - [datetime]::Parse($o.'Last Run Time')).TotalMinutes
  }
  return $null
}
# expected cadence (minutes)
$expect = @{
  "Mason2 Heartbeat"=1; "Mason2 Watchdog"=1; "Mason2 Governor"=2;
  "Mason2 AnomalyDetector"=5; "Mason2 RetrySweeper"=5; "Mason2 StuckJobDetector"=10;
  "Mason2 ScheduleDriftAlarms"=60
}
$bad=@()
foreach($k in $expect.Keys){
  $m = LastRunMins $k
  if($m -ne $null -and $m -gt ($expect[$k]*3)){ $bad += [pscustomobject]@{ name=$k; mins=$m; expect=$expect[$k] } }
}
if($bad.Count -gt 0){
  Write-JsonLog -Component "scheduler" -Level "WARN" -Message "schedule drift" -Props @{ items=($bad | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "scheduler" -Level "INFO" -Message "on cadence"
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function LastRunMins([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  $o = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  if($o.'Last Run Time' -and $o.'Last Run Time' -notmatch 'Never'){
    return [int]([datetime]::Now - [datetime]::Parse($o.'Last Run Time')).TotalMinutes
  }
  return $null
}
# expected cadence (minutes)
$expect = @{
  "Mason2 Heartbeat"=1; "Mason2 Watchdog"=1; "Mason2 Governor"=2;
  "Mason2 AnomalyDetector"=5; "Mason2 RetrySweeper"=5; "Mason2 StuckJobDetector"=10;
  "Mason2 ScheduleDriftAlarms"=60
}
$bad=@()
foreach($k in $expect.Keys){
  $m = LastRunMins $k
  if($m -ne $null -and $m -gt ($expect[$k]*3)){ $bad += [pscustomobject]@{ name=$k; mins=$m; expect=$expect[$k] } }
}
if($bad.Count -gt 0){
  Write-JsonLog -Component "scheduler" -Level "WARN" -Message "schedule drift" -Props @{ items=($bad | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "scheduler" -Level "INFO" -Message "on cadence"
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function LastRunMins([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  $o = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  if($o.'Last Run Time' -and $o.'Last Run Time' -notmatch 'Never'){
    return [int]([datetime]::Now - [datetime]::Parse($o.'Last Run Time')).TotalMinutes
  }
  return $null
}
# expected cadence (minutes)
$expect = @{
  "Mason2 Heartbeat"=1; "Mason2 Watchdog"=1; "Mason2 Governor"=2;
  "Mason2 AnomalyDetector"=5; "Mason2 RetrySweeper"=5; "Mason2 StuckJobDetector"=10;
  "Mason2 ScheduleDriftAlarms"=60
}
$bad=@()
foreach($k in $expect.Keys){
  $m = LastRunMins $k
  if($m -ne $null -and $m -gt ($expect[$k]*3)){ $bad += [pscustomobject]@{ name=$k; mins=$m; expect=$expect[$k] } }
}
if($bad.Count -gt 0){
  Write-JsonLog -Component "scheduler" -Level "WARN" -Message "schedule drift" -Props @{ items=($bad | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "scheduler" -Level "INFO" -Message "on cadence"
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking
function LastRunMins([string]$name){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return $null }
  $o = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  if($o.'Last Run Time' -and $o.'Last Run Time' -notmatch 'Never'){
    return [int]([datetime]::Now - [datetime]::Parse($o.'Last Run Time')).TotalMinutes
  }
  return $null
}
# expected cadence (minutes)
$expect = @{
  "Mason2 Heartbeat"=1; "Mason2 Watchdog"=1; "Mason2 Governor"=2;
  "Mason2 AnomalyDetector"=5; "Mason2 RetrySweeper"=5; "Mason2 StuckJobDetector"=10;
  "Mason2 ScheduleDriftAlarms"=60
}
$bad=@()
foreach($k in $expect.Keys){
  $m = LastRunMins $k
  if($m -ne $null -and $m -gt ($expect[$k]*3)){ $bad += [pscustomobject]@{ name=$k; mins=$m; expect=$expect[$k] } }
}
if($bad.Count -gt 0){
  Write-JsonLog -Component "scheduler" -Level "WARN" -Message "schedule drift" -Props @{ items=($bad | ConvertTo-Json -Compress) }
}else{
  Write-JsonLog -Component "scheduler" -Level "INFO" -Message "on cadence"
}

