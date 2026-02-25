# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
$today = Get-Date -Format 'yyyy-MM-dd'
$files = Get-ChildItem $Logs -Recurse -Filter "$today.jsonl" -ea SilentlyContinue
$rows = foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $counts = @{TRACE=0;DEBUG=0;INFO=0;WARN=0;ERROR=0}
  foreach($line in Get-Content $f.FullName){
    try{ $j = $line | ConvertFrom-Json; $lvl = ($j.level + "").ToUpper() }catch{ $lvl = "" }
    if($counts.ContainsKey($lvl)){ $counts[$lvl]++ }
  }
  [pscustomobject]@{ date=$today; component=$comp; TRACE=$counts.TRACE; DEBUG=$counts.DEBUG; INFO=$counts.INFO; WARN=$counts.WARN; ERROR=$counts.ERROR }
}
$csv = Join-Path $Rep "telemetry_levels_$today.csv"
$rows | Export-Csv $csv -NoTypeInformation -Encoding UTF8

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
$today = Get-Date -Format 'yyyy-MM-dd'
$files = Get-ChildItem $Logs -Recurse -Filter "$today.jsonl" -ea SilentlyContinue
$rows = foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $counts = @{TRACE=0;DEBUG=0;INFO=0;WARN=0;ERROR=0}
  foreach($line in Get-Content $f.FullName){
    try{ $j = $line | ConvertFrom-Json; $lvl = ($j.level + "").ToUpper() }catch{ $lvl = "" }
    if($counts.ContainsKey($lvl)){ $counts[$lvl]++ }
  }
  [pscustomobject]@{ date=$today; component=$comp; TRACE=$counts.TRACE; DEBUG=$counts.DEBUG; INFO=$counts.INFO; WARN=$counts.WARN; ERROR=$counts.ERROR }
}
$csv = Join-Path $Rep "telemetry_levels_$today.csv"
$rows | Export-Csv $csv -NoTypeInformation -Encoding UTF8

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
$today = Get-Date -Format 'yyyy-MM-dd'
$files = Get-ChildItem $Logs -Recurse -Filter "$today.jsonl" -ea SilentlyContinue
$rows = foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $counts = @{TRACE=0;DEBUG=0;INFO=0;WARN=0;ERROR=0}
  foreach($line in Get-Content $f.FullName){
    try{ $j = $line | ConvertFrom-Json; $lvl = ($j.level + "").ToUpper() }catch{ $lvl = "" }
    if($counts.ContainsKey($lvl)){ $counts[$lvl]++ }
  }
  [pscustomobject]@{ date=$today; component=$comp; TRACE=$counts.TRACE; DEBUG=$counts.DEBUG; INFO=$counts.INFO; WARN=$counts.WARN; ERROR=$counts.ERROR }
}
$csv = Join-Path $Rep "telemetry_levels_$today.csv"
$rows | Export-Csv $csv -NoTypeInformation -Encoding UTF8

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
$today = Get-Date -Format 'yyyy-MM-dd'
$files = Get-ChildItem $Logs -Recurse -Filter "$today.jsonl" -ea SilentlyContinue
$rows = foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $counts = @{TRACE=0;DEBUG=0;INFO=0;WARN=0;ERROR=0}
  foreach($line in Get-Content $f.FullName){
    try{ $j = $line | ConvertFrom-Json; $lvl = ($j.level + "").ToUpper() }catch{ $lvl = "" }
    if($counts.ContainsKey($lvl)){ $counts[$lvl]++ }
  }
  [pscustomobject]@{ date=$today; component=$comp; TRACE=$counts.TRACE; DEBUG=$counts.DEBUG; INFO=$counts.INFO; WARN=$counts.WARN; ERROR=$counts.ERROR }
}
$csv = Join-Path $Rep "telemetry_levels_$today.csv"
$rows | Export-Csv $csv -NoTypeInformation -Encoding UTF8

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
$today = Get-Date -Format 'yyyy-MM-dd'
$files = Get-ChildItem $Logs -Recurse -Filter "$today.jsonl" -ea SilentlyContinue
$rows = foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $counts = @{TRACE=0;DEBUG=0;INFO=0;WARN=0;ERROR=0}
  foreach($line in Get-Content $f.FullName){
    try{ $j = $line | ConvertFrom-Json; $lvl = ($j.level + "").ToUpper() }catch{ $lvl = "" }
    if($counts.ContainsKey($lvl)){ $counts[$lvl]++ }
  }
  [pscustomobject]@{ date=$today; component=$comp; TRACE=$counts.TRACE; DEBUG=$counts.DEBUG; INFO=$counts.INFO; WARN=$counts.WARN; ERROR=$counts.ERROR }
}
$csv = Join-Path $Rep "telemetry_levels_$today.csv"
$rows | Export-Csv $csv -NoTypeInformation -Encoding UTF8

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
$today = Get-Date -Format 'yyyy-MM-dd'
$files = Get-ChildItem $Logs -Recurse -Filter "$today.jsonl" -ea SilentlyContinue
$rows = foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $counts = @{TRACE=0;DEBUG=0;INFO=0;WARN=0;ERROR=0}
  foreach($line in Get-Content $f.FullName){
    try{ $j = $line | ConvertFrom-Json; $lvl = ($j.level + "").ToUpper() }catch{ $lvl = "" }
    if($counts.ContainsKey($lvl)){ $counts[$lvl]++ }
  }
  [pscustomobject]@{ date=$today; component=$comp; TRACE=$counts.TRACE; DEBUG=$counts.DEBUG; INFO=$counts.INFO; WARN=$counts.WARN; ERROR=$counts.ERROR }
}
$csv = Join-Path $Rep "telemetry_levels_$today.csv"
$rows | Export-Csv $csv -NoTypeInformation -Encoding UTF8

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
$today = Get-Date -Format 'yyyy-MM-dd'
$files = Get-ChildItem $Logs -Recurse -Filter "$today.jsonl" -ea SilentlyContinue
$rows = foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $counts = @{TRACE=0;DEBUG=0;INFO=0;WARN=0;ERROR=0}
  foreach($line in Get-Content $f.FullName){
    try{ $j = $line | ConvertFrom-Json; $lvl = ($j.level + "").ToUpper() }catch{ $lvl = "" }
    if($counts.ContainsKey($lvl)){ $counts[$lvl]++ }
  }
  [pscustomobject]@{ date=$today; component=$comp; TRACE=$counts.TRACE; DEBUG=$counts.DEBUG; INFO=$counts.INFO; WARN=$counts.WARN; ERROR=$counts.ERROR }
}
$csv = Join-Path $Rep "telemetry_levels_$today.csv"
$rows | Export-Csv $csv -NoTypeInformation -Encoding UTF8

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"
$today = Get-Date -Format 'yyyy-MM-dd'
$files = Get-ChildItem $Logs -Recurse -Filter "$today.jsonl" -ea SilentlyContinue
$rows = foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $counts = @{TRACE=0;DEBUG=0;INFO=0;WARN=0;ERROR=0}
  foreach($line in Get-Content $f.FullName){
    try{ $j = $line | ConvertFrom-Json; $lvl = ($j.level + "").ToUpper() }catch{ $lvl = "" }
    if($counts.ContainsKey($lvl)){ $counts[$lvl]++ }
  }
  [pscustomobject]@{ date=$today; component=$comp; TRACE=$counts.TRACE; DEBUG=$counts.DEBUG; INFO=$counts.INFO; WARN=$counts.WARN; ERROR=$counts.ERROR }
}
$csv = Join-Path $Rep "telemetry_levels_$today.csv"
$rows | Export-Csv $csv -NoTypeInformation -Encoding UTF8

