# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.2
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"

$sum    = Join-Path $Rep  "telemetry_summary.csv"
$today  = Get-Date -Format "yyyy-MM-dd"
$counts = @{}

# Count today's lines per component (PS 5.1-safe)
$pattern = "$today.jsonl"
$files = Get-ChildItem $Logs -Recurse -Filter $pattern -ErrorAction SilentlyContinue
foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $n    = (Get-Content $f.FullName -TotalCount 200000 | Measure-Object).Count
  if(-not $counts.ContainsKey($comp)) { $counts[$comp] = 0 }
  $counts[$comp] = $counts[$comp] + $n
}

# Ensure header, and avoid duplicate day rows by rewriting without today's entries
if(-not (Test-Path $sum)) { "date,component,count" | Set-Content $sum -Encoding UTF8 }
try{
  $existing = Import-Csv $sum
  $existing | Where-Object { $_.date -ne $today } | Export-Csv $sum -NoTypeInformation -Encoding UTF8
}catch{
  "date,component,count" | Set-Content $sum -Encoding UTF8
}

# Append today's totals
foreach($k in $counts.Keys){
  Add-Content $sum "$today,$k,$($counts[$k])"
}

Write-JsonLog -Component "maintenance" -Level "INFO" -Message "Log maintenance complete" -Props @{ total_components = $($counts.Keys.Count) }

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.2
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"

$sum    = Join-Path $Rep  "telemetry_summary.csv"
$today  = Get-Date -Format "yyyy-MM-dd"
$counts = @{}

# Count today's lines per component (PS 5.1-safe)
$pattern = "$today.jsonl"
$files = Get-ChildItem $Logs -Recurse -Filter $pattern -ErrorAction SilentlyContinue
foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $n    = (Get-Content $f.FullName -TotalCount 200000 | Measure-Object).Count
  if(-not $counts.ContainsKey($comp)) { $counts[$comp] = 0 }
  $counts[$comp] = $counts[$comp] + $n
}

# Ensure header, and avoid duplicate day rows by rewriting without today's entries
if(-not (Test-Path $sum)) { "date,component,count" | Set-Content $sum -Encoding UTF8 }
try{
  $existing = Import-Csv $sum
  $existing | Where-Object { $_.date -ne $today } | Export-Csv $sum -NoTypeInformation -Encoding UTF8
}catch{
  "date,component,count" | Set-Content $sum -Encoding UTF8
}

# Append today's totals
foreach($k in $counts.Keys){
  Add-Content $sum "$today,$k,$($counts[$k])"
}

Write-JsonLog -Component "maintenance" -Level "INFO" -Message "Log maintenance complete" -Props @{ total_components = $($counts.Keys.Count) }

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.2
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"

$sum    = Join-Path $Rep  "telemetry_summary.csv"
$today  = Get-Date -Format "yyyy-MM-dd"
$counts = @{}

# Count today's lines per component (PS 5.1-safe)
$pattern = "$today.jsonl"
$files = Get-ChildItem $Logs -Recurse -Filter $pattern -ErrorAction SilentlyContinue
foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $n    = (Get-Content $f.FullName -TotalCount 200000 | Measure-Object).Count
  if(-not $counts.ContainsKey($comp)) { $counts[$comp] = 0 }
  $counts[$comp] = $counts[$comp] + $n
}

# Ensure header, and avoid duplicate day rows by rewriting without today's entries
if(-not (Test-Path $sum)) { "date,component,count" | Set-Content $sum -Encoding UTF8 }
try{
  $existing = Import-Csv $sum
  $existing | Where-Object { $_.date -ne $today } | Export-Csv $sum -NoTypeInformation -Encoding UTF8
}catch{
  "date,component,count" | Set-Content $sum -Encoding UTF8
}

# Append today's totals
foreach($k in $counts.Keys){
  Add-Content $sum "$today,$k,$($counts[$k])"
}

Write-JsonLog -Component "maintenance" -Level "INFO" -Message "Log maintenance complete" -Props @{ total_components = $($counts.Keys.Count) }

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.2
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"

$sum    = Join-Path $Rep  "telemetry_summary.csv"
$today  = Get-Date -Format "yyyy-MM-dd"
$counts = @{}

# Count today's lines per component (PS 5.1-safe)
$pattern = "$today.jsonl"
$files = Get-ChildItem $Logs -Recurse -Filter $pattern -ErrorAction SilentlyContinue
foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $n    = (Get-Content $f.FullName -TotalCount 200000 | Measure-Object).Count
  if(-not $counts.ContainsKey($comp)) { $counts[$comp] = 0 }
  $counts[$comp] = $counts[$comp] + $n
}

# Ensure header, and avoid duplicate day rows by rewriting without today's entries
if(-not (Test-Path $sum)) { "date,component,count" | Set-Content $sum -Encoding UTF8 }
try{
  $existing = Import-Csv $sum
  $existing | Where-Object { $_.date -ne $today } | Export-Csv $sum -NoTypeInformation -Encoding UTF8
}catch{
  "date,component,count" | Set-Content $sum -Encoding UTF8
}

# Append today's totals
foreach($k in $counts.Keys){
  Add-Content $sum "$today,$k,$($counts[$k])"
}

Write-JsonLog -Component "maintenance" -Level "INFO" -Message "Log maintenance complete" -Props @{ total_components = $($counts.Keys.Count) }

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.2
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"

$sum    = Join-Path $Rep  "telemetry_summary.csv"
$today  = Get-Date -Format "yyyy-MM-dd"
$counts = @{}

# Count today's lines per component (PS 5.1-safe)
$pattern = "$today.jsonl"
$files = Get-ChildItem $Logs -Recurse -Filter $pattern -ErrorAction SilentlyContinue
foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $n    = (Get-Content $f.FullName -TotalCount 200000 | Measure-Object).Count
  if(-not $counts.ContainsKey($comp)) { $counts[$comp] = 0 }
  $counts[$comp] = $counts[$comp] + $n
}

# Ensure header, and avoid duplicate day rows by rewriting without today's entries
if(-not (Test-Path $sum)) { "date,component,count" | Set-Content $sum -Encoding UTF8 }
try{
  $existing = Import-Csv $sum
  $existing | Where-Object { $_.date -ne $today } | Export-Csv $sum -NoTypeInformation -Encoding UTF8
}catch{
  "date,component,count" | Set-Content $sum -Encoding UTF8
}

# Append today's totals
foreach($k in $counts.Keys){
  Add-Content $sum "$today,$k,$($counts[$k])"
}

Write-JsonLog -Component "maintenance" -Level "INFO" -Message "Log maintenance complete" -Props @{ total_components = $($counts.Keys.Count) }

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.2
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"

$sum    = Join-Path $Rep  "telemetry_summary.csv"
$today  = Get-Date -Format "yyyy-MM-dd"
$counts = @{}

# Count today's lines per component (PS 5.1-safe)
$pattern = "$today.jsonl"
$files = Get-ChildItem $Logs -Recurse -Filter $pattern -ErrorAction SilentlyContinue
foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $n    = (Get-Content $f.FullName -TotalCount 200000 | Measure-Object).Count
  if(-not $counts.ContainsKey($comp)) { $counts[$comp] = 0 }
  $counts[$comp] = $counts[$comp] + $n
}

# Ensure header, and avoid duplicate day rows by rewriting without today's entries
if(-not (Test-Path $sum)) { "date,component,count" | Set-Content $sum -Encoding UTF8 }
try{
  $existing = Import-Csv $sum
  $existing | Where-Object { $_.date -ne $today } | Export-Csv $sum -NoTypeInformation -Encoding UTF8
}catch{
  "date,component,count" | Set-Content $sum -Encoding UTF8
}

# Append today's totals
foreach($k in $counts.Keys){
  Add-Content $sum "$today,$k,$($counts[$k])"
}

Write-JsonLog -Component "maintenance" -Level "INFO" -Message "Log maintenance complete" -Props @{ total_components = $($counts.Keys.Count) }

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.2
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"

$sum    = Join-Path $Rep  "telemetry_summary.csv"
$today  = Get-Date -Format "yyyy-MM-dd"
$counts = @{}

# Count today's lines per component (PS 5.1-safe)
$pattern = "$today.jsonl"
$files = Get-ChildItem $Logs -Recurse -Filter $pattern -ErrorAction SilentlyContinue
foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $n    = (Get-Content $f.FullName -TotalCount 200000 | Measure-Object).Count
  if(-not $counts.ContainsKey($comp)) { $counts[$comp] = 0 }
  $counts[$comp] = $counts[$comp] + $n
}

# Ensure header, and avoid duplicate day rows by rewriting without today's entries
if(-not (Test-Path $sum)) { "date,component,count" | Set-Content $sum -Encoding UTF8 }
try{
  $existing = Import-Csv $sum
  $existing | Where-Object { $_.date -ne $today } | Export-Csv $sum -NoTypeInformation -Encoding UTF8
}catch{
  "date,component,count" | Set-Content $sum -Encoding UTF8
}

# Append today's totals
foreach($k in $counts.Keys){
  Add-Content $sum "$today,$k,$($counts[$k])"
}

Write-JsonLog -Component "maintenance" -Level "INFO" -Message "Log maintenance complete" -Props @{ total_components = $($counts.Keys.Count) }

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.2
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Logs = Join-Path $Base "logs"
$Rep  = Join-Path $Base "reports"

$sum    = Join-Path $Rep  "telemetry_summary.csv"
$today  = Get-Date -Format "yyyy-MM-dd"
$counts = @{}

# Count today's lines per component (PS 5.1-safe)
$pattern = "$today.jsonl"
$files = Get-ChildItem $Logs -Recurse -Filter $pattern -ErrorAction SilentlyContinue
foreach($f in $files){
  $comp = Split-Path $f.DirectoryName -Leaf
  $n    = (Get-Content $f.FullName -TotalCount 200000 | Measure-Object).Count
  if(-not $counts.ContainsKey($comp)) { $counts[$comp] = 0 }
  $counts[$comp] = $counts[$comp] + $n
}

# Ensure header, and avoid duplicate day rows by rewriting without today's entries
if(-not (Test-Path $sum)) { "date,component,count" | Set-Content $sum -Encoding UTF8 }
try{
  $existing = Import-Csv $sum
  $existing | Where-Object { $_.date -ne $today } | Export-Csv $sum -NoTypeInformation -Encoding UTF8
}catch{
  "date,component,count" | Set-Content $sum -Encoding UTF8
}

# Append today's totals
foreach($k in $counts.Keys){
  Add-Content $sum "$today,$k,$($counts[$k])"
}

Write-JsonLog -Component "maintenance" -Level "INFO" -Message "Log maintenance complete" -Props @{ total_components = $($counts.Keys.Count) }

