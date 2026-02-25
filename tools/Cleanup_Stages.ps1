# Stamped: 2025-11-05T17:02:01
param(
  [int]$Days = 2,
  [string]$Dist = (Join-Path $env:USERPROFILE 'Desktop\Mason2\dist'),
  [switch]$DryRun,
  [switch]$Log,
  [switch]$UseFolderTime
)

if (-not (Test-Path -LiteralPath $Dist -PathType Container)) {
  throw "Dist path not found: $Dist"
}
$distResolved = (Resolve-Path -LiteralPath $Dist).Path
$rep = Join-Path (Split-Path $distResolved -Parent) 'reports'
New-Item -ItemType Directory -Path $rep -Force | Out-Null
$logFile = Join-Path $rep 'cleanup_stages.jsonl'

function Write-Log([Parameter(Mandatory=$true)][object]$Obj){
  if(-not $Log){ return }
  try{
    $line = ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($logFile)) | Out-Null
    [IO.File]::AppendAllText($logFile, $line, [Text.Encoding]::UTF8)
  }catch{ Write-Warning ("Log write failed: " + $_.Exception.Message) }
}

$cutoff = (Get-Date).AddDays(-$Days)
Write-Log @{ Event='Start'; Dist=$distResolved; Days=$Days; DryRun=$DryRun.IsPresent; Timestamp=(Get-Date).ToString('o') }

# Enumerate only immediate children of /dist whose names match stage_* or strict_stage_*
$targets =
  Get-ChildItem -LiteralPath $distResolved -Directory -Force |
  Where-Object { $_.Name -like 'stage_*' -or $_.Name -like 'strict_stage_*' } |
  ForEach-Object {
    $latestFileTime = Get-ChildItem -LiteralPath $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue |
                      Sort-Object LastWriteTime -Desc | Select-Object -First 1 -ExpandProperty LastWriteTime
    $ageRef = if ($UseFolderTime) { $_.LastWriteTime } elseif ($latestFileTime) { $latestFileTime } else { $_.LastWriteTime }
    $_ | Add-Member -NotePropertyName AgeRef -NotePropertyValue ([datetime]$ageRef) -PassThru
  } |
  Where-Object { $_.AgeRef -lt $cutoff } |
  Sort-Object AgeRef

if ($DryRun) {
  Write-Log @{ Event='DryRun'; Dist=$distResolved; Days=$Days; Found=$targets.Count; Timestamp=(Get-Date).ToString('o'); Items=($targets | ForEach-Object FullName) }
  if ($targets.Count) {
    $targets | Select-Object FullName, AgeRef, LastWriteTime
  } else {
    Write-Host "No stage folders older than $Days day(s) under $distResolved"
  }
  return
}

$deleted = @()
foreach ($d in $targets) {
  try {
    Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction Stop
    $deleted += $d.FullName
  } catch {
    Write-Warning "Failed to remove $($d.FullName): $($_.Exception.Message)"
  }
}

$report = [pscustomobject]@{
  Event     = 'Finish'
  Dist      = $distResolved
  Days      = $Days
  Deleted   = $deleted.Count
  Timestamp = (Get-Date).ToString('o')
  Items     = $deleted
}
Write-Log $report
$report | Format-List

exit 0


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [int]$Days = 2,
  [string]$Dist = (Join-Path $env:USERPROFILE 'Desktop\Mason2\dist'),
  [switch]$DryRun,
  [switch]$Log,
  [switch]$UseFolderTime
)

if (-not (Test-Path -LiteralPath $Dist -PathType Container)) {
  throw "Dist path not found: $Dist"
}
$distResolved = (Resolve-Path -LiteralPath $Dist).Path
$rep = Join-Path (Split-Path $distResolved -Parent) 'reports'
New-Item -ItemType Directory -Path $rep -Force | Out-Null
$logFile = Join-Path $rep 'cleanup_stages.jsonl'

function Write-Log([Parameter(Mandatory=$true)][object]$Obj){
  if(-not $Log){ return }
  try{
    $line = ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($logFile)) | Out-Null
    [IO.File]::AppendAllText($logFile, $line, [Text.Encoding]::UTF8)
  }catch{ Write-Warning ("Log write failed: " + $_.Exception.Message) }
}

$cutoff = (Get-Date).AddDays(-$Days)
Write-Log @{ Event='Start'; Dist=$distResolved; Days=$Days; DryRun=$DryRun.IsPresent; Timestamp=(Get-Date).ToString('o') }

# Enumerate only immediate children of /dist whose names match stage_* or strict_stage_*
$targets =
  Get-ChildItem -LiteralPath $distResolved -Directory -Force |
  Where-Object { $_.Name -like 'stage_*' -or $_.Name -like 'strict_stage_*' } |
  ForEach-Object {
    $latestFileTime = Get-ChildItem -LiteralPath $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue |
                      Sort-Object LastWriteTime -Desc | Select-Object -First 1 -ExpandProperty LastWriteTime
    $ageRef = if ($UseFolderTime) { $_.LastWriteTime } elseif ($latestFileTime) { $latestFileTime } else { $_.LastWriteTime }
    $_ | Add-Member -NotePropertyName AgeRef -NotePropertyValue ([datetime]$ageRef) -PassThru
  } |
  Where-Object { $_.AgeRef -lt $cutoff } |
  Sort-Object AgeRef

if ($DryRun) {
  Write-Log @{ Event='DryRun'; Dist=$distResolved; Days=$Days; Found=$targets.Count; Timestamp=(Get-Date).ToString('o'); Items=($targets | ForEach-Object FullName) }
  if ($targets.Count) {
    $targets | Select-Object FullName, AgeRef, LastWriteTime
  } else {
    Write-Host "No stage folders older than $Days day(s) under $distResolved"
  }
  return
}

$deleted = @()
foreach ($d in $targets) {
  try {
    Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction Stop
    $deleted += $d.FullName
  } catch {
    Write-Warning "Failed to remove $($d.FullName): $($_.Exception.Message)"
  }
}

$report = [pscustomobject]@{
  Event     = 'Finish'
  Dist      = $distResolved
  Days      = $Days
  Deleted   = $deleted.Count
  Timestamp = (Get-Date).ToString('o')
  Items     = $deleted
}
Write-Log $report
$report | Format-List

exit 0


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [int]$Days = 2,
  [string]$Dist = (Join-Path $env:USERPROFILE 'Desktop\Mason2\dist'),
  [switch]$DryRun,
  [switch]$Log,
  [switch]$UseFolderTime
)

if (-not (Test-Path -LiteralPath $Dist -PathType Container)) {
  throw "Dist path not found: $Dist"
}
$distResolved = (Resolve-Path -LiteralPath $Dist).Path
$rep = Join-Path (Split-Path $distResolved -Parent) 'reports'
New-Item -ItemType Directory -Path $rep -Force | Out-Null
$logFile = Join-Path $rep 'cleanup_stages.jsonl'

function Write-Log([Parameter(Mandatory=$true)][object]$Obj){
  if(-not $Log){ return }
  try{
    $line = ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($logFile)) | Out-Null
    [IO.File]::AppendAllText($logFile, $line, [Text.Encoding]::UTF8)
  }catch{ Write-Warning ("Log write failed: " + $_.Exception.Message) }
}

$cutoff = (Get-Date).AddDays(-$Days)
Write-Log @{ Event='Start'; Dist=$distResolved; Days=$Days; DryRun=$DryRun.IsPresent; Timestamp=(Get-Date).ToString('o') }

# Enumerate only immediate children of /dist whose names match stage_* or strict_stage_*
$targets =
  Get-ChildItem -LiteralPath $distResolved -Directory -Force |
  Where-Object { $_.Name -like 'stage_*' -or $_.Name -like 'strict_stage_*' } |
  ForEach-Object {
    $latestFileTime = Get-ChildItem -LiteralPath $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue |
                      Sort-Object LastWriteTime -Desc | Select-Object -First 1 -ExpandProperty LastWriteTime
    $ageRef = if ($UseFolderTime) { $_.LastWriteTime } elseif ($latestFileTime) { $latestFileTime } else { $_.LastWriteTime }
    $_ | Add-Member -NotePropertyName AgeRef -NotePropertyValue ([datetime]$ageRef) -PassThru
  } |
  Where-Object { $_.AgeRef -lt $cutoff } |
  Sort-Object AgeRef

if ($DryRun) {
  Write-Log @{ Event='DryRun'; Dist=$distResolved; Days=$Days; Found=$targets.Count; Timestamp=(Get-Date).ToString('o'); Items=($targets | ForEach-Object FullName) }
  if ($targets.Count) {
    $targets | Select-Object FullName, AgeRef, LastWriteTime
  } else {
    Write-Host "No stage folders older than $Days day(s) under $distResolved"
  }
  return
}

$deleted = @()
foreach ($d in $targets) {
  try {
    Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction Stop
    $deleted += $d.FullName
  } catch {
    Write-Warning "Failed to remove $($d.FullName): $($_.Exception.Message)"
  }
}

$report = [pscustomobject]@{
  Event     = 'Finish'
  Dist      = $distResolved
  Days      = $Days
  Deleted   = $deleted.Count
  Timestamp = (Get-Date).ToString('o')
  Items     = $deleted
}
Write-Log $report
$report | Format-List

exit 0


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [int]$Days = 2,
  [string]$Dist = (Join-Path $env:USERPROFILE 'Desktop\Mason2\dist'),
  [switch]$DryRun,
  [switch]$Log,
  [switch]$UseFolderTime
)

if (-not (Test-Path -LiteralPath $Dist -PathType Container)) {
  throw "Dist path not found: $Dist"
}
$distResolved = (Resolve-Path -LiteralPath $Dist).Path
$rep = Join-Path (Split-Path $distResolved -Parent) 'reports'
New-Item -ItemType Directory -Path $rep -Force | Out-Null
$logFile = Join-Path $rep 'cleanup_stages.jsonl'

function Write-Log([Parameter(Mandatory=$true)][object]$Obj){
  if(-not $Log){ return }
  try{
    $line = ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($logFile)) | Out-Null
    [IO.File]::AppendAllText($logFile, $line, [Text.Encoding]::UTF8)
  }catch{ Write-Warning ("Log write failed: " + $_.Exception.Message) }
}

$cutoff = (Get-Date).AddDays(-$Days)
Write-Log @{ Event='Start'; Dist=$distResolved; Days=$Days; DryRun=$DryRun.IsPresent; Timestamp=(Get-Date).ToString('o') }

# Enumerate only immediate children of /dist whose names match stage_* or strict_stage_*
$targets =
  Get-ChildItem -LiteralPath $distResolved -Directory -Force |
  Where-Object { $_.Name -like 'stage_*' -or $_.Name -like 'strict_stage_*' } |
  ForEach-Object {
    $latestFileTime = Get-ChildItem -LiteralPath $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue |
                      Sort-Object LastWriteTime -Desc | Select-Object -First 1 -ExpandProperty LastWriteTime
    $ageRef = if ($UseFolderTime) { $_.LastWriteTime } elseif ($latestFileTime) { $latestFileTime } else { $_.LastWriteTime }
    $_ | Add-Member -NotePropertyName AgeRef -NotePropertyValue ([datetime]$ageRef) -PassThru
  } |
  Where-Object { $_.AgeRef -lt $cutoff } |
  Sort-Object AgeRef

if ($DryRun) {
  Write-Log @{ Event='DryRun'; Dist=$distResolved; Days=$Days; Found=$targets.Count; Timestamp=(Get-Date).ToString('o'); Items=($targets | ForEach-Object FullName) }
  if ($targets.Count) {
    $targets | Select-Object FullName, AgeRef, LastWriteTime
  } else {
    Write-Host "No stage folders older than $Days day(s) under $distResolved"
  }
  return
}

$deleted = @()
foreach ($d in $targets) {
  try {
    Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction Stop
    $deleted += $d.FullName
  } catch {
    Write-Warning "Failed to remove $($d.FullName): $($_.Exception.Message)"
  }
}

$report = [pscustomobject]@{
  Event     = 'Finish'
  Dist      = $distResolved
  Days      = $Days
  Deleted   = $deleted.Count
  Timestamp = (Get-Date).ToString('o')
  Items     = $deleted
}
Write-Log $report
$report | Format-List

exit 0


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [int]$Days = 2,
  [string]$Dist = (Join-Path $env:USERPROFILE 'Desktop\Mason2\dist'),
  [switch]$DryRun,
  [switch]$Log,
  [switch]$UseFolderTime
)

if (-not (Test-Path -LiteralPath $Dist -PathType Container)) {
  throw "Dist path not found: $Dist"
}
$distResolved = (Resolve-Path -LiteralPath $Dist).Path
$rep = Join-Path (Split-Path $distResolved -Parent) 'reports'
New-Item -ItemType Directory -Path $rep -Force | Out-Null
$logFile = Join-Path $rep 'cleanup_stages.jsonl'

function Write-Log([Parameter(Mandatory=$true)][object]$Obj){
  if(-not $Log){ return }
  try{
    $line = ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($logFile)) | Out-Null
    [IO.File]::AppendAllText($logFile, $line, [Text.Encoding]::UTF8)
  }catch{ Write-Warning ("Log write failed: " + $_.Exception.Message) }
}

$cutoff = (Get-Date).AddDays(-$Days)
Write-Log @{ Event='Start'; Dist=$distResolved; Days=$Days; DryRun=$DryRun.IsPresent; Timestamp=(Get-Date).ToString('o') }

# Enumerate only immediate children of /dist whose names match stage_* or strict_stage_*
$targets =
  Get-ChildItem -LiteralPath $distResolved -Directory -Force |
  Where-Object { $_.Name -like 'stage_*' -or $_.Name -like 'strict_stage_*' } |
  ForEach-Object {
    $latestFileTime = Get-ChildItem -LiteralPath $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue |
                      Sort-Object LastWriteTime -Desc | Select-Object -First 1 -ExpandProperty LastWriteTime
    $ageRef = if ($UseFolderTime) { $_.LastWriteTime } elseif ($latestFileTime) { $latestFileTime } else { $_.LastWriteTime }
    $_ | Add-Member -NotePropertyName AgeRef -NotePropertyValue ([datetime]$ageRef) -PassThru
  } |
  Where-Object { $_.AgeRef -lt $cutoff } |
  Sort-Object AgeRef

if ($DryRun) {
  Write-Log @{ Event='DryRun'; Dist=$distResolved; Days=$Days; Found=$targets.Count; Timestamp=(Get-Date).ToString('o'); Items=($targets | ForEach-Object FullName) }
  if ($targets.Count) {
    $targets | Select-Object FullName, AgeRef, LastWriteTime
  } else {
    Write-Host "No stage folders older than $Days day(s) under $distResolved"
  }
  return
}

$deleted = @()
foreach ($d in $targets) {
  try {
    Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction Stop
    $deleted += $d.FullName
  } catch {
    Write-Warning "Failed to remove $($d.FullName): $($_.Exception.Message)"
  }
}

$report = [pscustomobject]@{
  Event     = 'Finish'
  Dist      = $distResolved
  Days      = $Days
  Deleted   = $deleted.Count
  Timestamp = (Get-Date).ToString('o')
  Items     = $deleted
}
Write-Log $report
$report | Format-List

exit 0


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [int]$Days = 2,
  [string]$Dist = (Join-Path $env:USERPROFILE 'Desktop\Mason2\dist'),
  [switch]$DryRun,
  [switch]$Log,
  [switch]$UseFolderTime
)

if (-not (Test-Path -LiteralPath $Dist -PathType Container)) {
  throw "Dist path not found: $Dist"
}
$distResolved = (Resolve-Path -LiteralPath $Dist).Path
$rep = Join-Path (Split-Path $distResolved -Parent) 'reports'
New-Item -ItemType Directory -Path $rep -Force | Out-Null
$logFile = Join-Path $rep 'cleanup_stages.jsonl'

function Write-Log([Parameter(Mandatory=$true)][object]$Obj){
  if(-not $Log){ return }
  try{
    $line = ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($logFile)) | Out-Null
    [IO.File]::AppendAllText($logFile, $line, [Text.Encoding]::UTF8)
  }catch{ Write-Warning ("Log write failed: " + $_.Exception.Message) }
}

$cutoff = (Get-Date).AddDays(-$Days)
Write-Log @{ Event='Start'; Dist=$distResolved; Days=$Days; DryRun=$DryRun.IsPresent; Timestamp=(Get-Date).ToString('o') }

# Enumerate only immediate children of /dist whose names match stage_* or strict_stage_*
$targets =
  Get-ChildItem -LiteralPath $distResolved -Directory -Force |
  Where-Object { $_.Name -like 'stage_*' -or $_.Name -like 'strict_stage_*' } |
  ForEach-Object {
    $latestFileTime = Get-ChildItem -LiteralPath $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue |
                      Sort-Object LastWriteTime -Desc | Select-Object -First 1 -ExpandProperty LastWriteTime
    $ageRef = if ($UseFolderTime) { $_.LastWriteTime } elseif ($latestFileTime) { $latestFileTime } else { $_.LastWriteTime }
    $_ | Add-Member -NotePropertyName AgeRef -NotePropertyValue ([datetime]$ageRef) -PassThru
  } |
  Where-Object { $_.AgeRef -lt $cutoff } |
  Sort-Object AgeRef

if ($DryRun) {
  Write-Log @{ Event='DryRun'; Dist=$distResolved; Days=$Days; Found=$targets.Count; Timestamp=(Get-Date).ToString('o'); Items=($targets | ForEach-Object FullName) }
  if ($targets.Count) {
    $targets | Select-Object FullName, AgeRef, LastWriteTime
  } else {
    Write-Host "No stage folders older than $Days day(s) under $distResolved"
  }
  return
}

$deleted = @()
foreach ($d in $targets) {
  try {
    Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction Stop
    $deleted += $d.FullName
  } catch {
    Write-Warning "Failed to remove $($d.FullName): $($_.Exception.Message)"
  }
}

$report = [pscustomobject]@{
  Event     = 'Finish'
  Dist      = $distResolved
  Days      = $Days
  Deleted   = $deleted.Count
  Timestamp = (Get-Date).ToString('o')
  Items     = $deleted
}
Write-Log $report
$report | Format-List

exit 0


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [int]$Days = 2,
  [string]$Dist = (Join-Path $env:USERPROFILE 'Desktop\Mason2\dist'),
  [switch]$DryRun,
  [switch]$Log,
  [switch]$UseFolderTime
)

if (-not (Test-Path -LiteralPath $Dist -PathType Container)) {
  throw "Dist path not found: $Dist"
}
$distResolved = (Resolve-Path -LiteralPath $Dist).Path
$rep = Join-Path (Split-Path $distResolved -Parent) 'reports'
New-Item -ItemType Directory -Path $rep -Force | Out-Null
$logFile = Join-Path $rep 'cleanup_stages.jsonl'

function Write-Log([Parameter(Mandatory=$true)][object]$Obj){
  if(-not $Log){ return }
  try{
    $line = ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($logFile)) | Out-Null
    [IO.File]::AppendAllText($logFile, $line, [Text.Encoding]::UTF8)
  }catch{ Write-Warning ("Log write failed: " + $_.Exception.Message) }
}

$cutoff = (Get-Date).AddDays(-$Days)
Write-Log @{ Event='Start'; Dist=$distResolved; Days=$Days; DryRun=$DryRun.IsPresent; Timestamp=(Get-Date).ToString('o') }

# Enumerate only immediate children of /dist whose names match stage_* or strict_stage_*
$targets =
  Get-ChildItem -LiteralPath $distResolved -Directory -Force |
  Where-Object { $_.Name -like 'stage_*' -or $_.Name -like 'strict_stage_*' } |
  ForEach-Object {
    $latestFileTime = Get-ChildItem -LiteralPath $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue |
                      Sort-Object LastWriteTime -Desc | Select-Object -First 1 -ExpandProperty LastWriteTime
    $ageRef = if ($UseFolderTime) { $_.LastWriteTime } elseif ($latestFileTime) { $latestFileTime } else { $_.LastWriteTime }
    $_ | Add-Member -NotePropertyName AgeRef -NotePropertyValue ([datetime]$ageRef) -PassThru
  } |
  Where-Object { $_.AgeRef -lt $cutoff } |
  Sort-Object AgeRef

if ($DryRun) {
  Write-Log @{ Event='DryRun'; Dist=$distResolved; Days=$Days; Found=$targets.Count; Timestamp=(Get-Date).ToString('o'); Items=($targets | ForEach-Object FullName) }
  if ($targets.Count) {
    $targets | Select-Object FullName, AgeRef, LastWriteTime
  } else {
    Write-Host "No stage folders older than $Days day(s) under $distResolved"
  }
  return
}

$deleted = @()
foreach ($d in $targets) {
  try {
    Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction Stop
    $deleted += $d.FullName
  } catch {
    Write-Warning "Failed to remove $($d.FullName): $($_.Exception.Message)"
  }
}

$report = [pscustomobject]@{
  Event     = 'Finish'
  Dist      = $distResolved
  Days      = $Days
  Deleted   = $deleted.Count
  Timestamp = (Get-Date).ToString('o')
  Items     = $deleted
}
Write-Log $report
$report | Format-List

exit 0


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param(
  [int]$Days = 2,
  [string]$Dist = (Join-Path $env:USERPROFILE 'Desktop\Mason2\dist'),
  [switch]$DryRun,
  [switch]$Log,
  [switch]$UseFolderTime
)

if (-not (Test-Path -LiteralPath $Dist -PathType Container)) {
  throw "Dist path not found: $Dist"
}
$distResolved = (Resolve-Path -LiteralPath $Dist).Path
$rep = Join-Path (Split-Path $distResolved -Parent) 'reports'
New-Item -ItemType Directory -Path $rep -Force | Out-Null
$logFile = Join-Path $rep 'cleanup_stages.jsonl'

function Write-Log([Parameter(Mandatory=$true)][object]$Obj){
  if(-not $Log){ return }
  try{
    $line = ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($logFile)) | Out-Null
    [IO.File]::AppendAllText($logFile, $line, [Text.Encoding]::UTF8)
  }catch{ Write-Warning ("Log write failed: " + $_.Exception.Message) }
}

$cutoff = (Get-Date).AddDays(-$Days)
Write-Log @{ Event='Start'; Dist=$distResolved; Days=$Days; DryRun=$DryRun.IsPresent; Timestamp=(Get-Date).ToString('o') }

# Enumerate only immediate children of /dist whose names match stage_* or strict_stage_*
$targets =
  Get-ChildItem -LiteralPath $distResolved -Directory -Force |
  Where-Object { $_.Name -like 'stage_*' -or $_.Name -like 'strict_stage_*' } |
  ForEach-Object {
    $latestFileTime = Get-ChildItem -LiteralPath $_.FullName -Recurse -Force -File -ErrorAction SilentlyContinue |
                      Sort-Object LastWriteTime -Desc | Select-Object -First 1 -ExpandProperty LastWriteTime
    $ageRef = if ($UseFolderTime) { $_.LastWriteTime } elseif ($latestFileTime) { $latestFileTime } else { $_.LastWriteTime }
    $_ | Add-Member -NotePropertyName AgeRef -NotePropertyValue ([datetime]$ageRef) -PassThru
  } |
  Where-Object { $_.AgeRef -lt $cutoff } |
  Sort-Object AgeRef

if ($DryRun) {
  Write-Log @{ Event='DryRun'; Dist=$distResolved; Days=$Days; Found=$targets.Count; Timestamp=(Get-Date).ToString('o'); Items=($targets | ForEach-Object FullName) }
  if ($targets.Count) {
    $targets | Select-Object FullName, AgeRef, LastWriteTime
  } else {
    Write-Host "No stage folders older than $Days day(s) under $distResolved"
  }
  return
}

$deleted = @()
foreach ($d in $targets) {
  try {
    Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction Stop
    $deleted += $d.FullName
  } catch {
    Write-Warning "Failed to remove $($d.FullName): $($_.Exception.Message)"
  }
}

$report = [pscustomobject]@{
  Event     = 'Finish'
  Dist      = $distResolved
  Days      = $Days
  Deleted   = $deleted.Count
  Timestamp = (Get-Date).ToString('o')
  Items     = $deleted
}
Write-Log $report
$report | Format-List

exit 0


