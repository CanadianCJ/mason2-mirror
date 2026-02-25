# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Tools = Join-Path $Base "tools"

function Check-Task([string]$name,[int]$ageMin=0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return @{name=$name; ok=$false; msg="not found"} }
  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  $ok  = @('0','267009','267011') -contains ($obj.'Last Result'+'')
  $msg = ""
  if($ageMin -gt 0 -and $obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($obj.'Last Run Time')).TotalMinutes
    if($mins -gt $ageMin){ $ok=$false; $msg="stale ${mins}m" }
  }
  return @{name=$name; ok=$ok; msg=$msg}
}

$results = @(
  Check-Task "Mason2 Heartbeat" 3
  Check-Task "Mason2 Watchdog"  5
  Check-Task "Mason2 Governor"  7
)
$bad = $results | Where-Object { -not $_.ok }
if($bad){ Write-JsonLog -Component "governor" -Level "WARN" -Message "scheduler issues" -Props @{ problems=($bad | ConvertTo-Json -Compress) } }
else     { Write-JsonLog -Component "governor" -Level "INFO" -Message "scheduler OK" }

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Tools = Join-Path $Base "tools"

function Check-Task([string]$name,[int]$ageMin=0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return @{name=$name; ok=$false; msg="not found"} }
  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  $ok  = @('0','267009','267011') -contains ($obj.'Last Result'+'')
  $msg = ""
  if($ageMin -gt 0 -and $obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($obj.'Last Run Time')).TotalMinutes
    if($mins -gt $ageMin){ $ok=$false; $msg="stale ${mins}m" }
  }
  return @{name=$name; ok=$ok; msg=$msg}
}

$results = @(
  Check-Task "Mason2 Heartbeat" 3
  Check-Task "Mason2 Watchdog"  5
  Check-Task "Mason2 Governor"  7
)
$bad = $results | Where-Object { -not $_.ok }
if($bad){ Write-JsonLog -Component "governor" -Level "WARN" -Message "scheduler issues" -Props @{ problems=($bad | ConvertTo-Json -Compress) } }
else     { Write-JsonLog -Component "governor" -Level "INFO" -Message "scheduler OK" }

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Tools = Join-Path $Base "tools"

function Check-Task([string]$name,[int]$ageMin=0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return @{name=$name; ok=$false; msg="not found"} }
  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  $ok  = @('0','267009','267011') -contains ($obj.'Last Result'+'')
  $msg = ""
  if($ageMin -gt 0 -and $obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($obj.'Last Run Time')).TotalMinutes
    if($mins -gt $ageMin){ $ok=$false; $msg="stale ${mins}m" }
  }
  return @{name=$name; ok=$ok; msg=$msg}
}

$results = @(
  Check-Task "Mason2 Heartbeat" 3
  Check-Task "Mason2 Watchdog"  5
  Check-Task "Mason2 Governor"  7
)
$bad = $results | Where-Object { -not $_.ok }
if($bad){ Write-JsonLog -Component "governor" -Level "WARN" -Message "scheduler issues" -Props @{ problems=($bad | ConvertTo-Json -Compress) } }
else     { Write-JsonLog -Component "governor" -Level "INFO" -Message "scheduler OK" }

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Tools = Join-Path $Base "tools"

function Check-Task([string]$name,[int]$ageMin=0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return @{name=$name; ok=$false; msg="not found"} }
  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  $ok  = @('0','267009','267011') -contains ($obj.'Last Result'+'')
  $msg = ""
  if($ageMin -gt 0 -and $obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($obj.'Last Run Time')).TotalMinutes
    if($mins -gt $ageMin){ $ok=$false; $msg="stale ${mins}m" }
  }
  return @{name=$name; ok=$ok; msg=$msg}
}

$results = @(
  Check-Task "Mason2 Heartbeat" 3
  Check-Task "Mason2 Watchdog"  5
  Check-Task "Mason2 Governor"  7
)
$bad = $results | Where-Object { -not $_.ok }
if($bad){ Write-JsonLog -Component "governor" -Level "WARN" -Message "scheduler issues" -Props @{ problems=($bad | ConvertTo-Json -Compress) } }
else     { Write-JsonLog -Component "governor" -Level "INFO" -Message "scheduler OK" }

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Tools = Join-Path $Base "tools"

function Check-Task([string]$name,[int]$ageMin=0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return @{name=$name; ok=$false; msg="not found"} }
  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  $ok  = @('0','267009','267011') -contains ($obj.'Last Result'+'')
  $msg = ""
  if($ageMin -gt 0 -and $obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($obj.'Last Run Time')).TotalMinutes
    if($mins -gt $ageMin){ $ok=$false; $msg="stale ${mins}m" }
  }
  return @{name=$name; ok=$ok; msg=$msg}
}

$results = @(
  Check-Task "Mason2 Heartbeat" 3
  Check-Task "Mason2 Watchdog"  5
  Check-Task "Mason2 Governor"  7
)
$bad = $results | Where-Object { -not $_.ok }
if($bad){ Write-JsonLog -Component "governor" -Level "WARN" -Message "scheduler issues" -Props @{ problems=($bad | ConvertTo-Json -Compress) } }
else     { Write-JsonLog -Component "governor" -Level "INFO" -Message "scheduler OK" }

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Tools = Join-Path $Base "tools"

function Check-Task([string]$name,[int]$ageMin=0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return @{name=$name; ok=$false; msg="not found"} }
  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  $ok  = @('0','267009','267011') -contains ($obj.'Last Result'+'')
  $msg = ""
  if($ageMin -gt 0 -and $obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($obj.'Last Run Time')).TotalMinutes
    if($mins -gt $ageMin){ $ok=$false; $msg="stale ${mins}m" }
  }
  return @{name=$name; ok=$ok; msg=$msg}
}

$results = @(
  Check-Task "Mason2 Heartbeat" 3
  Check-Task "Mason2 Watchdog"  5
  Check-Task "Mason2 Governor"  7
)
$bad = $results | Where-Object { -not $_.ok }
if($bad){ Write-JsonLog -Component "governor" -Level "WARN" -Message "scheduler issues" -Props @{ problems=($bad | ConvertTo-Json -Compress) } }
else     { Write-JsonLog -Component "governor" -Level "INFO" -Message "scheduler OK" }

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Tools = Join-Path $Base "tools"

function Check-Task([string]$name,[int]$ageMin=0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return @{name=$name; ok=$false; msg="not found"} }
  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  $ok  = @('0','267009','267011') -contains ($obj.'Last Result'+'')
  $msg = ""
  if($ageMin -gt 0 -and $obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($obj.'Last Run Time')).TotalMinutes
    if($mins -gt $ageMin){ $ok=$false; $msg="stale ${mins}m" }
  }
  return @{name=$name; ok=$ok; msg=$msg}
}

$results = @(
  Check-Task "Mason2 Heartbeat" 3
  Check-Task "Mason2 Watchdog"  5
  Check-Task "Mason2 Governor"  7
)
$bad = $results | Where-Object { -not $_.ok }
if($bad){ Write-JsonLog -Component "governor" -Level "WARN" -Message "scheduler issues" -Props @{ problems=($bad | ConvertTo-Json -Compress) } }
else     { Write-JsonLog -Component "governor" -Level "INFO" -Message "scheduler OK" }

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Tools = Join-Path $Base "tools"

function Check-Task([string]$name,[int]$ageMin=0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if(-not $csv){ $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if(-not $csv){ return @{name=$name; ok=$false; msg="not found"} }
  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)
  $ok  = @('0','267009','267011') -contains ($obj.'Last Result'+'')
  $msg = ""
  if($ageMin -gt 0 -and $obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){
    $mins = [int]([datetime]::Now - [datetime]::Parse($obj.'Last Run Time')).TotalMinutes
    if($mins -gt $ageMin){ $ok=$false; $msg="stale ${mins}m" }
  }
  return @{name=$name; ok=$ok; msg=$msg}
}

$results = @(
  Check-Task "Mason2 Heartbeat" 3
  Check-Task "Mason2 Watchdog"  5
  Check-Task "Mason2 Governor"  7
)
$bad = $results | Where-Object { -not $_.ok }
if($bad){ Write-JsonLog -Component "governor" -Level "WARN" -Message "scheduler issues" -Props @{ problems=($bad | ConvertTo-Json -Compress) } }
else     { Write-JsonLog -Component "governor" -Level "INFO" -Message "scheduler OK" }

