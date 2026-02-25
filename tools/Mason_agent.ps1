# Stamped: 2025-11-05T17:02:01
param(
  [string]$Mode            = 'strict',      # dev | strict (what Tighten Verify uses)
  [string]$BundleFilter    = 'dev',         # dev | strict (which file-set we pack)
  [int]   $KeepReleases    = 10,            # keep top-N Mason2_*.zip (+ .sha256)
  [int]   $CleanupDays     = 2,             # delete stage_* older than N days
  [int]   $MinFreePct      = 15,            # if disk free < this, do emergency trim/cleanup
  [string]$NightWindow     = '02:00-05:30', # heavy work window; still builds on change anytime
  [switch]$ApplyUnpack,                     # also Extract latest after verify
  [switch]$Quiet                             
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- constants/paths ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools= Join-Path $Base 'tools'
$Dist = Join-Path $Base 'dist'
$Rel  = Join-Path $Dist 'releases'
$Rep  = Join-Path $Base 'reports'
$Cfg  = Join-Path $Base 'config'
$StateFile  = Join-Path $Rep 'agent_state.json'
$AgentLog   = Join-Path $Rep 'agent.log.jsonl'

$Tool_VerifyTighten = Join-Path $Tools 'Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Tools 'Verify_And_Unpack.ps1'
$Tool_Cleanup       = Join-Path $Tools 'Cleanup_Stages.ps1'

# --- ensure folders ---
New-Item -ItemType Directory -Force -Path $Dist,$Rel,$Rep,$Cfg | Out-Null

# --- load config override if present ---
$cfgPath = Join-Path $Cfg 'agent.json'
if (Test-Path $cfgPath) {
  try {
    $j = Get-Content $cfgPath -Raw | ConvertFrom-Json
    if ($j.mode)           { $Mode         = $j.mode }
    if ($j.bundleFilter)   { $BundleFilter = $j.bundleFilter }
    if ($j.keepReleases)   { $KeepReleases = [int]$j.keepReleases }
    if ($j.cleanupDays)    { $CleanupDays  = [int]$j.cleanupDays }
    if ($j.minFreePct)     { $MinFreePct   = [int]$j.minFreePct }
    if ($j.nightWindow)    { $NightWindow  = $j.nightWindow }
    if ($j.applyUnpack)    { $ApplyUnpack  = [bool]$j.applyUnpack }
  } catch { }
}

# --- helpers ---
function Log([string]$event, [hashtable]$data) {
  $obj = [ordered]@{
    ts    = (Get-Date).ToString('o')
    event = $event
  }
  foreach ($k in $data.Keys) { $obj[$k] = $data[$k] }
  ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine | 
    Out-File -FilePath $AgentLog -Append -Encoding utf8
  if (-not $Quiet) { Write-Host "[$($obj.ts)] $event" }
}

function DiskFreePct() {
  try {
    $root = [IO.Path]::GetPathRoot($Base)
    $di   = [IO.DriveInfo]::new($root)
    if (-not $di.TotalSize) { return 0 }
    [math]::Round(($di.AvailableFreeSpace/$di.TotalSize)*100,1)
  } catch { 0 }
}

function Normalize([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return '' }
  $t = $s -replace '/', '\'
  while($t.StartsWith('.\')){ $t = $t.Substring(2) }
  $t.Trim()
}

$devRoot    = '^(config|services|tools|seeds|ui|roadmap|learn|logs|reports|dist|cache|snapshots)\\|^[^\\]+\.(ps1|txt|md|json)(?:\.bak-\d{8}-\d{6})?$|^\.env\.sample$'
$strictRoot = '^(config|services|tools|seeds)\\'
function IsAllowed([string]$rel,[string]$modeSel){
  $p = Normalize $rel
  if($modeSel -eq 'dev'){ return ($p -match $devRoot) }
  return ($p -match $strictRoot)
}

function LatestBundle() {
  if (-not (Test-Path $Rel)) { return $null }
  Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc | Select-Object -First 1
}

# fingerprint = max LastWriteTime across allowed files + count
function ComputeFingerprint([string]$sel) {
  $all = Get-ChildItem $Base -Recurse -File -Force
  $acc = @()
  foreach ($f in $all) {
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if (IsAllowed $rel $sel) { $acc += $f }
  }
  if ($acc.Count -eq 0) { return @{ count=0; max=([datetime]'2000-01-01') } }
  $max = ($acc | Sort-Object LastWriteTime -Desc | Select-Object -First 1).LastWriteTime
  return @{ count=$acc.Count; max=$max }
}

function BuildBundle([string]$modeSel) {
  $sel = $modeSel
  $fprint = ComputeFingerprint $sel
  $state  = @{ lastMax = '2000-01-01T00:00:00Z'; lastCount = 0 }
  if (Test-Path $StateFile) {
    try { $state = Get-Content $StateFile -Raw | ConvertFrom-Json } catch { }
  }
  $lastMax   = [datetime]$state.lastMax
  $lastCount = [int]$state.lastCount

  $should = $false
  if ($fprint.max -gt $lastMax -or $fprint.count -ne $lastCount) { $should = $true }

  if (-not $should) {
    Log 'bundle.skip' @{ reason='no-change'; selection=$sel; max=$fprint.max; count=$fprint.count }
    return $null
  }

  # Stage and zip (same as dashboard)
  $all = Get-ChildItem $Base -Recurse -File -Force
  $files = foreach($f in $all){
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if(IsAllowed $rel $sel){ $rel }
  }
  $man = [ordered]@{ version=(Get-Date -Format 'yyyy.MM.dd.HHmmss'); mode=$sel; ts=(Get-Date).ToString('o'); files=@() }
  foreach($rel in $files){
    $full = Join-Path $Base $rel
    $man.files += [ordered]@{ path=$rel; bytes=(Get-Item $full).Length; sha256=(Get-FileHash $full -Algorithm SHA256).Hash }
  }
  $stage = Join-Path $Dist ("stage_" + [guid]::NewGuid().ToString('N'))
  New-Item $stage -ItemType Directory -Force | Out-Null
  foreach($rel in $files){
    $src = Join-Path $Base $rel
    $dst = Join-Path $stage $rel
    New-Item (Split-Path $dst -Parent) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
  }
  $man | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $stage 'manifest.json') -Encoding UTF8
  $zipName = 'Mason2_{0}.zip' -f (Get-Date -Format 'yyyyMMdd_HHmmss')
  $zipPath = Join-Path $Rel $zipName
  if(Test-Path $zipPath){ Remove-Item $zipPath -Force }
  [IO.Compression.ZipFile]::CreateFromDirectory($stage,$zipPath)
  Remove-Item $stage -Recurse -Force -EA SilentlyContinue
  (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash | Set-Content -Encoding ascii ($zipPath + '.sha256')
  Set-Content -Encoding ascii (Join-Path $Rel 'LATEST.txt') ([IO.Path]::GetFileName($zipPath))

  # update state
  $outState = @{ lastMax = $fprint.max.ToString('o'); lastCount = $fprint.count }
  $outState | ConvertTo-Json | Set-Content -Encoding UTF8 $StateFile

  Log 'bundle.built' @{ selection=$sel; zip=$zipPath; count=$fprint.count; max=$fprint.max }
  return $zipPath
}

function TightenVerify([string]$bundle,[string]$mode) {
  if (-not (Test-Path $Tool_VerifyTighten)) { Log 'verify.skip' @{ reason='missing Verify_Tighten.ps1' }; return }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyTighten -Bundle $bundle -Mode $mode 2>&1 | Out-String
  Log 'verify.tighten' @{ bundle=$bundle; mode=$mode; output=$out.Trim() }
}

function VerifyAndUnpack([string]$bundle,[bool]$apply) {
  if (-not (Test-Path $Tool_VerifyUnpack)) { Log 'verify_unpack.skip' @{ reason='missing Verify_And_Unpack.ps1' }; return }
  $args = @('-Bundle',$bundle)
  if ($apply) { $args += '-Apply' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyUnpack @args 2>&1 | Out-String
  Log 'verify.unpack' @{ bundle=$bundle; apply=$apply; output=$out.Trim() }
}

function TrimReleases([int]$n) {
  $z = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc
  $h = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip.sha256' | Sort-Object LastWriteTime -Desc
  $z | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  $h | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  Log 'releases.trim' @{ keep=$n; totalZip=$z.Count }
}

function CleanupStages([int]$days,[switch]$useFolderTime,[switch]$log) {
  if (-not (Test-Path $Tool_Cleanup)) { Log 'cleanup.skip' @{ reason='missing Cleanup_Stages.ps1' }; return }
  $args = @('-Days',$days,'-Dist',$Dist)
  if ($useFolderTime) { $args += '-UseFolderTime' }
  if ($log)          { $args += '-Log' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_Cleanup @args 2>&1 | Out-String
  Log 'cleanup.run' @{ days=$days; output=$out.Trim() }
}

function InNightWindow([string]$win) {
  if ([string]::IsNullOrWhiteSpace($win)) { return $true }
  $parts = $win -split '\s*-\s*'
  if ($parts.Count -ne 2) { return $true }
  $d = Get-Date
  $start = Get-Date $parts[0]
  $end   = Get-Date $parts[1]
  return ($d.TimeOfDay -ge $start.TimeOfDay -and $d.TimeOfDay -le $end.TimeOfDay)
}

# --- single-instance mutex ---
$mtx = New-Object System.Threading.Mutex($false, 'Global\Mason2Agent')
if (-not $mtx.WaitOne(0,$false)) {
  if (-not $Quiet) { Write-Host "Agent already running." }
  return
}
try {
  Log 'agent.start' @{ mode=$Mode; filter=$BundleFilter }

  # 1) Emergency disk guard first
  $free = DiskFreePct
  if ($free -lt $MinFreePct) {
    Log 'guard.lowdisk' @{ freePct=$free; min=$MinFreePct }
    TrimReleases 3
    CleanupStages $CleanupDays -useFolderTime -log
  }

  # 2) Build if files changed (anytime)
  $zip = BuildBundle $BundleFilter
  if (-not $zip) { $zip = (LatestBundle)?.FullName }

  # 3) Heavy stuff (verify / unpack) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â prefer night window
  $okToRunHeavy = InNightWindow $NightWindow
  if (-not $okToRunHeavy) {
    Log 'heavy.defer' @{ window=$NightWindow }
  } else {
    if ($zip) {
      TightenVerify $zip $Mode
      VerifyAndUnpack $zip $ApplyUnpack.IsPresent
    }
  }

  # 4) Routine housekeeping (lightweight)
  TrimReleases $KeepReleases
  CleanupStages $CleanupDays -useFolderTime -log

  Log 'agent.done' @{ freePct=DiskFreePct }

} finally {
  $mtx.ReleaseMutex() | Out-Null
  $mtx.Dispose()
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Mode            = 'strict',      # dev | strict (what Tighten Verify uses)
  [string]$BundleFilter    = 'dev',         # dev | strict (which file-set we pack)
  [int]   $KeepReleases    = 10,            # keep top-N Mason2_*.zip (+ .sha256)
  [int]   $CleanupDays     = 2,             # delete stage_* older than N days
  [int]   $MinFreePct      = 15,            # if disk free < this, do emergency trim/cleanup
  [string]$NightWindow     = '02:00-05:30', # heavy work window; still builds on change anytime
  [switch]$ApplyUnpack,                     # also Extract latest after verify
  [switch]$Quiet                             
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- constants/paths ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools= Join-Path $Base 'tools'
$Dist = Join-Path $Base 'dist'
$Rel  = Join-Path $Dist 'releases'
$Rep  = Join-Path $Base 'reports'
$Cfg  = Join-Path $Base 'config'
$StateFile  = Join-Path $Rep 'agent_state.json'
$AgentLog   = Join-Path $Rep 'agent.log.jsonl'

$Tool_VerifyTighten = Join-Path $Tools 'Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Tools 'Verify_And_Unpack.ps1'
$Tool_Cleanup       = Join-Path $Tools 'Cleanup_Stages.ps1'

# --- ensure folders ---
New-Item -ItemType Directory -Force -Path $Dist,$Rel,$Rep,$Cfg | Out-Null

# --- load config override if present ---
$cfgPath = Join-Path $Cfg 'agent.json'
if (Test-Path $cfgPath) {
  try {
    $j = Get-Content $cfgPath -Raw | ConvertFrom-Json
    if ($j.mode)           { $Mode         = $j.mode }
    if ($j.bundleFilter)   { $BundleFilter = $j.bundleFilter }
    if ($j.keepReleases)   { $KeepReleases = [int]$j.keepReleases }
    if ($j.cleanupDays)    { $CleanupDays  = [int]$j.cleanupDays }
    if ($j.minFreePct)     { $MinFreePct   = [int]$j.minFreePct }
    if ($j.nightWindow)    { $NightWindow  = $j.nightWindow }
    if ($j.applyUnpack)    { $ApplyUnpack  = [bool]$j.applyUnpack }
  } catch { }
}

# --- helpers ---
function Log([string]$event, [hashtable]$data) {
  $obj = [ordered]@{
    ts    = (Get-Date).ToString('o')
    event = $event
  }
  foreach ($k in $data.Keys) { $obj[$k] = $data[$k] }
  ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine | 
    Out-File -FilePath $AgentLog -Append -Encoding utf8
  if (-not $Quiet) { Write-Host "[$($obj.ts)] $event" }
}

function DiskFreePct() {
  try {
    $root = [IO.Path]::GetPathRoot($Base)
    $di   = [IO.DriveInfo]::new($root)
    if (-not $di.TotalSize) { return 0 }
    [math]::Round(($di.AvailableFreeSpace/$di.TotalSize)*100,1)
  } catch { 0 }
}

function Normalize([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return '' }
  $t = $s -replace '/', '\'
  while($t.StartsWith('.\')){ $t = $t.Substring(2) }
  $t.Trim()
}

$devRoot    = '^(config|services|tools|seeds|ui|roadmap|learn|logs|reports|dist|cache|snapshots)\\|^[^\\]+\.(ps1|txt|md|json)(?:\.bak-\d{8}-\d{6})?$|^\.env\.sample$'
$strictRoot = '^(config|services|tools|seeds)\\'
function IsAllowed([string]$rel,[string]$modeSel){
  $p = Normalize $rel
  if($modeSel -eq 'dev'){ return ($p -match $devRoot) }
  return ($p -match $strictRoot)
}

function LatestBundle() {
  if (-not (Test-Path $Rel)) { return $null }
  Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc | Select-Object -First 1
}

# fingerprint = max LastWriteTime across allowed files + count
function ComputeFingerprint([string]$sel) {
  $all = Get-ChildItem $Base -Recurse -File -Force
  $acc = @()
  foreach ($f in $all) {
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if (IsAllowed $rel $sel) { $acc += $f }
  }
  if ($acc.Count -eq 0) { return @{ count=0; max=([datetime]'2000-01-01') } }
  $max = ($acc | Sort-Object LastWriteTime -Desc | Select-Object -First 1).LastWriteTime
  return @{ count=$acc.Count; max=$max }
}

function BuildBundle([string]$modeSel) {
  $sel = $modeSel
  $fprint = ComputeFingerprint $sel
  $state  = @{ lastMax = '2000-01-01T00:00:00Z'; lastCount = 0 }
  if (Test-Path $StateFile) {
    try { $state = Get-Content $StateFile -Raw | ConvertFrom-Json } catch { }
  }
  $lastMax   = [datetime]$state.lastMax
  $lastCount = [int]$state.lastCount

  $should = $false
  if ($fprint.max -gt $lastMax -or $fprint.count -ne $lastCount) { $should = $true }

  if (-not $should) {
    Log 'bundle.skip' @{ reason='no-change'; selection=$sel; max=$fprint.max; count=$fprint.count }
    return $null
  }

  # Stage and zip (same as dashboard)
  $all = Get-ChildItem $Base -Recurse -File -Force
  $files = foreach($f in $all){
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if(IsAllowed $rel $sel){ $rel }
  }
  $man = [ordered]@{ version=(Get-Date -Format 'yyyy.MM.dd.HHmmss'); mode=$sel; ts=(Get-Date).ToString('o'); files=@() }
  foreach($rel in $files){
    $full = Join-Path $Base $rel
    $man.files += [ordered]@{ path=$rel; bytes=(Get-Item $full).Length; sha256=(Get-FileHash $full -Algorithm SHA256).Hash }
  }
  $stage = Join-Path $Dist ("stage_" + [guid]::NewGuid().ToString('N'))
  New-Item $stage -ItemType Directory -Force | Out-Null
  foreach($rel in $files){
    $src = Join-Path $Base $rel
    $dst = Join-Path $stage $rel
    New-Item (Split-Path $dst -Parent) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
  }
  $man | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $stage 'manifest.json') -Encoding UTF8
  $zipName = 'Mason2_{0}.zip' -f (Get-Date -Format 'yyyyMMdd_HHmmss')
  $zipPath = Join-Path $Rel $zipName
  if(Test-Path $zipPath){ Remove-Item $zipPath -Force }
  [IO.Compression.ZipFile]::CreateFromDirectory($stage,$zipPath)
  Remove-Item $stage -Recurse -Force -EA SilentlyContinue
  (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash | Set-Content -Encoding ascii ($zipPath + '.sha256')
  Set-Content -Encoding ascii (Join-Path $Rel 'LATEST.txt') ([IO.Path]::GetFileName($zipPath))

  # update state
  $outState = @{ lastMax = $fprint.max.ToString('o'); lastCount = $fprint.count }
  $outState | ConvertTo-Json | Set-Content -Encoding UTF8 $StateFile

  Log 'bundle.built' @{ selection=$sel; zip=$zipPath; count=$fprint.count; max=$fprint.max }
  return $zipPath
}

function TightenVerify([string]$bundle,[string]$mode) {
  if (-not (Test-Path $Tool_VerifyTighten)) { Log 'verify.skip' @{ reason='missing Verify_Tighten.ps1' }; return }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyTighten -Bundle $bundle -Mode $mode 2>&1 | Out-String
  Log 'verify.tighten' @{ bundle=$bundle; mode=$mode; output=$out.Trim() }
}

function VerifyAndUnpack([string]$bundle,[bool]$apply) {
  if (-not (Test-Path $Tool_VerifyUnpack)) { Log 'verify_unpack.skip' @{ reason='missing Verify_And_Unpack.ps1' }; return }
  $args = @('-Bundle',$bundle)
  if ($apply) { $args += '-Apply' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyUnpack @args 2>&1 | Out-String
  Log 'verify.unpack' @{ bundle=$bundle; apply=$apply; output=$out.Trim() }
}

function TrimReleases([int]$n) {
  $z = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc
  $h = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip.sha256' | Sort-Object LastWriteTime -Desc
  $z | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  $h | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  Log 'releases.trim' @{ keep=$n; totalZip=$z.Count }
}

function CleanupStages([int]$days,[switch]$useFolderTime,[switch]$log) {
  if (-not (Test-Path $Tool_Cleanup)) { Log 'cleanup.skip' @{ reason='missing Cleanup_Stages.ps1' }; return }
  $args = @('-Days',$days,'-Dist',$Dist)
  if ($useFolderTime) { $args += '-UseFolderTime' }
  if ($log)          { $args += '-Log' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_Cleanup @args 2>&1 | Out-String
  Log 'cleanup.run' @{ days=$days; output=$out.Trim() }
}

function InNightWindow([string]$win) {
  if ([string]::IsNullOrWhiteSpace($win)) { return $true }
  $parts = $win -split '\s*-\s*'
  if ($parts.Count -ne 2) { return $true }
  $d = Get-Date
  $start = Get-Date $parts[0]
  $end   = Get-Date $parts[1]
  return ($d.TimeOfDay -ge $start.TimeOfDay -and $d.TimeOfDay -le $end.TimeOfDay)
}

# --- single-instance mutex ---
$mtx = New-Object System.Threading.Mutex($false, 'Global\Mason2Agent')
if (-not $mtx.WaitOne(0,$false)) {
  if (-not $Quiet) { Write-Host "Agent already running." }
  return
}
try {
  Log 'agent.start' @{ mode=$Mode; filter=$BundleFilter }

  # 1) Emergency disk guard first
  $free = DiskFreePct
  if ($free -lt $MinFreePct) {
    Log 'guard.lowdisk' @{ freePct=$free; min=$MinFreePct }
    TrimReleases 3
    CleanupStages $CleanupDays -useFolderTime -log
  }

  # 2) Build if files changed (anytime)
  $zip = BuildBundle $BundleFilter
  if (-not $zip) { $zip = (LatestBundle)?.FullName }

  # 3) Heavy stuff (verify / unpack) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â prefer night window
  $okToRunHeavy = InNightWindow $NightWindow
  if (-not $okToRunHeavy) {
    Log 'heavy.defer' @{ window=$NightWindow }
  } else {
    if ($zip) {
      TightenVerify $zip $Mode
      VerifyAndUnpack $zip $ApplyUnpack.IsPresent
    }
  }

  # 4) Routine housekeeping (lightweight)
  TrimReleases $KeepReleases
  CleanupStages $CleanupDays -useFolderTime -log

  Log 'agent.done' @{ freePct=DiskFreePct }

} finally {
  $mtx.ReleaseMutex() | Out-Null
  $mtx.Dispose()
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Mode            = 'strict',      # dev | strict (what Tighten Verify uses)
  [string]$BundleFilter    = 'dev',         # dev | strict (which file-set we pack)
  [int]   $KeepReleases    = 10,            # keep top-N Mason2_*.zip (+ .sha256)
  [int]   $CleanupDays     = 2,             # delete stage_* older than N days
  [int]   $MinFreePct      = 15,            # if disk free < this, do emergency trim/cleanup
  [string]$NightWindow     = '02:00-05:30', # heavy work window; still builds on change anytime
  [switch]$ApplyUnpack,                     # also Extract latest after verify
  [switch]$Quiet                             
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- constants/paths ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools= Join-Path $Base 'tools'
$Dist = Join-Path $Base 'dist'
$Rel  = Join-Path $Dist 'releases'
$Rep  = Join-Path $Base 'reports'
$Cfg  = Join-Path $Base 'config'
$StateFile  = Join-Path $Rep 'agent_state.json'
$AgentLog   = Join-Path $Rep 'agent.log.jsonl'

$Tool_VerifyTighten = Join-Path $Tools 'Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Tools 'Verify_And_Unpack.ps1'
$Tool_Cleanup       = Join-Path $Tools 'Cleanup_Stages.ps1'

# --- ensure folders ---
New-Item -ItemType Directory -Force -Path $Dist,$Rel,$Rep,$Cfg | Out-Null

# --- load config override if present ---
$cfgPath = Join-Path $Cfg 'agent.json'
if (Test-Path $cfgPath) {
  try {
    $j = Get-Content $cfgPath -Raw | ConvertFrom-Json
    if ($j.mode)           { $Mode         = $j.mode }
    if ($j.bundleFilter)   { $BundleFilter = $j.bundleFilter }
    if ($j.keepReleases)   { $KeepReleases = [int]$j.keepReleases }
    if ($j.cleanupDays)    { $CleanupDays  = [int]$j.cleanupDays }
    if ($j.minFreePct)     { $MinFreePct   = [int]$j.minFreePct }
    if ($j.nightWindow)    { $NightWindow  = $j.nightWindow }
    if ($j.applyUnpack)    { $ApplyUnpack  = [bool]$j.applyUnpack }
  } catch { }
}

# --- helpers ---
function Log([string]$event, [hashtable]$data) {
  $obj = [ordered]@{
    ts    = (Get-Date).ToString('o')
    event = $event
  }
  foreach ($k in $data.Keys) { $obj[$k] = $data[$k] }
  ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine | 
    Out-File -FilePath $AgentLog -Append -Encoding utf8
  if (-not $Quiet) { Write-Host "[$($obj.ts)] $event" }
}

function DiskFreePct() {
  try {
    $root = [IO.Path]::GetPathRoot($Base)
    $di   = [IO.DriveInfo]::new($root)
    if (-not $di.TotalSize) { return 0 }
    [math]::Round(($di.AvailableFreeSpace/$di.TotalSize)*100,1)
  } catch { 0 }
}

function Normalize([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return '' }
  $t = $s -replace '/', '\'
  while($t.StartsWith('.\')){ $t = $t.Substring(2) }
  $t.Trim()
}

$devRoot    = '^(config|services|tools|seeds|ui|roadmap|learn|logs|reports|dist|cache|snapshots)\\|^[^\\]+\.(ps1|txt|md|json)(?:\.bak-\d{8}-\d{6})?$|^\.env\.sample$'
$strictRoot = '^(config|services|tools|seeds)\\'
function IsAllowed([string]$rel,[string]$modeSel){
  $p = Normalize $rel
  if($modeSel -eq 'dev'){ return ($p -match $devRoot) }
  return ($p -match $strictRoot)
}

function LatestBundle() {
  if (-not (Test-Path $Rel)) { return $null }
  Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc | Select-Object -First 1
}

# fingerprint = max LastWriteTime across allowed files + count
function ComputeFingerprint([string]$sel) {
  $all = Get-ChildItem $Base -Recurse -File -Force
  $acc = @()
  foreach ($f in $all) {
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if (IsAllowed $rel $sel) { $acc += $f }
  }
  if ($acc.Count -eq 0) { return @{ count=0; max=([datetime]'2000-01-01') } }
  $max = ($acc | Sort-Object LastWriteTime -Desc | Select-Object -First 1).LastWriteTime
  return @{ count=$acc.Count; max=$max }
}

function BuildBundle([string]$modeSel) {
  $sel = $modeSel
  $fprint = ComputeFingerprint $sel
  $state  = @{ lastMax = '2000-01-01T00:00:00Z'; lastCount = 0 }
  if (Test-Path $StateFile) {
    try { $state = Get-Content $StateFile -Raw | ConvertFrom-Json } catch { }
  }
  $lastMax   = [datetime]$state.lastMax
  $lastCount = [int]$state.lastCount

  $should = $false
  if ($fprint.max -gt $lastMax -or $fprint.count -ne $lastCount) { $should = $true }

  if (-not $should) {
    Log 'bundle.skip' @{ reason='no-change'; selection=$sel; max=$fprint.max; count=$fprint.count }
    return $null
  }

  # Stage and zip (same as dashboard)
  $all = Get-ChildItem $Base -Recurse -File -Force
  $files = foreach($f in $all){
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if(IsAllowed $rel $sel){ $rel }
  }
  $man = [ordered]@{ version=(Get-Date -Format 'yyyy.MM.dd.HHmmss'); mode=$sel; ts=(Get-Date).ToString('o'); files=@() }
  foreach($rel in $files){
    $full = Join-Path $Base $rel
    $man.files += [ordered]@{ path=$rel; bytes=(Get-Item $full).Length; sha256=(Get-FileHash $full -Algorithm SHA256).Hash }
  }
  $stage = Join-Path $Dist ("stage_" + [guid]::NewGuid().ToString('N'))
  New-Item $stage -ItemType Directory -Force | Out-Null
  foreach($rel in $files){
    $src = Join-Path $Base $rel
    $dst = Join-Path $stage $rel
    New-Item (Split-Path $dst -Parent) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
  }
  $man | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $stage 'manifest.json') -Encoding UTF8
  $zipName = 'Mason2_{0}.zip' -f (Get-Date -Format 'yyyyMMdd_HHmmss')
  $zipPath = Join-Path $Rel $zipName
  if(Test-Path $zipPath){ Remove-Item $zipPath -Force }
  [IO.Compression.ZipFile]::CreateFromDirectory($stage,$zipPath)
  Remove-Item $stage -Recurse -Force -EA SilentlyContinue
  (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash | Set-Content -Encoding ascii ($zipPath + '.sha256')
  Set-Content -Encoding ascii (Join-Path $Rel 'LATEST.txt') ([IO.Path]::GetFileName($zipPath))

  # update state
  $outState = @{ lastMax = $fprint.max.ToString('o'); lastCount = $fprint.count }
  $outState | ConvertTo-Json | Set-Content -Encoding UTF8 $StateFile

  Log 'bundle.built' @{ selection=$sel; zip=$zipPath; count=$fprint.count; max=$fprint.max }
  return $zipPath
}

function TightenVerify([string]$bundle,[string]$mode) {
  if (-not (Test-Path $Tool_VerifyTighten)) { Log 'verify.skip' @{ reason='missing Verify_Tighten.ps1' }; return }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyTighten -Bundle $bundle -Mode $mode 2>&1 | Out-String
  Log 'verify.tighten' @{ bundle=$bundle; mode=$mode; output=$out.Trim() }
}

function VerifyAndUnpack([string]$bundle,[bool]$apply) {
  if (-not (Test-Path $Tool_VerifyUnpack)) { Log 'verify_unpack.skip' @{ reason='missing Verify_And_Unpack.ps1' }; return }
  $args = @('-Bundle',$bundle)
  if ($apply) { $args += '-Apply' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyUnpack @args 2>&1 | Out-String
  Log 'verify.unpack' @{ bundle=$bundle; apply=$apply; output=$out.Trim() }
}

function TrimReleases([int]$n) {
  $z = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc
  $h = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip.sha256' | Sort-Object LastWriteTime -Desc
  $z | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  $h | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  Log 'releases.trim' @{ keep=$n; totalZip=$z.Count }
}

function CleanupStages([int]$days,[switch]$useFolderTime,[switch]$log) {
  if (-not (Test-Path $Tool_Cleanup)) { Log 'cleanup.skip' @{ reason='missing Cleanup_Stages.ps1' }; return }
  $args = @('-Days',$days,'-Dist',$Dist)
  if ($useFolderTime) { $args += '-UseFolderTime' }
  if ($log)          { $args += '-Log' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_Cleanup @args 2>&1 | Out-String
  Log 'cleanup.run' @{ days=$days; output=$out.Trim() }
}

function InNightWindow([string]$win) {
  if ([string]::IsNullOrWhiteSpace($win)) { return $true }
  $parts = $win -split '\s*-\s*'
  if ($parts.Count -ne 2) { return $true }
  $d = Get-Date
  $start = Get-Date $parts[0]
  $end   = Get-Date $parts[1]
  return ($d.TimeOfDay -ge $start.TimeOfDay -and $d.TimeOfDay -le $end.TimeOfDay)
}

# --- single-instance mutex ---
$mtx = New-Object System.Threading.Mutex($false, 'Global\Mason2Agent')
if (-not $mtx.WaitOne(0,$false)) {
  if (-not $Quiet) { Write-Host "Agent already running." }
  return
}
try {
  Log 'agent.start' @{ mode=$Mode; filter=$BundleFilter }

  # 1) Emergency disk guard first
  $free = DiskFreePct
  if ($free -lt $MinFreePct) {
    Log 'guard.lowdisk' @{ freePct=$free; min=$MinFreePct }
    TrimReleases 3
    CleanupStages $CleanupDays -useFolderTime -log
  }

  # 2) Build if files changed (anytime)
  $zip = BuildBundle $BundleFilter
  if (-not $zip) { $zip = (LatestBundle)?.FullName }

  # 3) Heavy stuff (verify / unpack) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â prefer night window
  $okToRunHeavy = InNightWindow $NightWindow
  if (-not $okToRunHeavy) {
    Log 'heavy.defer' @{ window=$NightWindow }
  } else {
    if ($zip) {
      TightenVerify $zip $Mode
      VerifyAndUnpack $zip $ApplyUnpack.IsPresent
    }
  }

  # 4) Routine housekeeping (lightweight)
  TrimReleases $KeepReleases
  CleanupStages $CleanupDays -useFolderTime -log

  Log 'agent.done' @{ freePct=DiskFreePct }

} finally {
  $mtx.ReleaseMutex() | Out-Null
  $mtx.Dispose()
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Mode            = 'strict',      # dev | strict (what Tighten Verify uses)
  [string]$BundleFilter    = 'dev',         # dev | strict (which file-set we pack)
  [int]   $KeepReleases    = 10,            # keep top-N Mason2_*.zip (+ .sha256)
  [int]   $CleanupDays     = 2,             # delete stage_* older than N days
  [int]   $MinFreePct      = 15,            # if disk free < this, do emergency trim/cleanup
  [string]$NightWindow     = '02:00-05:30', # heavy work window; still builds on change anytime
  [switch]$ApplyUnpack,                     # also Extract latest after verify
  [switch]$Quiet                             
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- constants/paths ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools= Join-Path $Base 'tools'
$Dist = Join-Path $Base 'dist'
$Rel  = Join-Path $Dist 'releases'
$Rep  = Join-Path $Base 'reports'
$Cfg  = Join-Path $Base 'config'
$StateFile  = Join-Path $Rep 'agent_state.json'
$AgentLog   = Join-Path $Rep 'agent.log.jsonl'

$Tool_VerifyTighten = Join-Path $Tools 'Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Tools 'Verify_And_Unpack.ps1'
$Tool_Cleanup       = Join-Path $Tools 'Cleanup_Stages.ps1'

# --- ensure folders ---
New-Item -ItemType Directory -Force -Path $Dist,$Rel,$Rep,$Cfg | Out-Null

# --- load config override if present ---
$cfgPath = Join-Path $Cfg 'agent.json'
if (Test-Path $cfgPath) {
  try {
    $j = Get-Content $cfgPath -Raw | ConvertFrom-Json
    if ($j.mode)           { $Mode         = $j.mode }
    if ($j.bundleFilter)   { $BundleFilter = $j.bundleFilter }
    if ($j.keepReleases)   { $KeepReleases = [int]$j.keepReleases }
    if ($j.cleanupDays)    { $CleanupDays  = [int]$j.cleanupDays }
    if ($j.minFreePct)     { $MinFreePct   = [int]$j.minFreePct }
    if ($j.nightWindow)    { $NightWindow  = $j.nightWindow }
    if ($j.applyUnpack)    { $ApplyUnpack  = [bool]$j.applyUnpack }
  } catch { }
}

# --- helpers ---
function Log([string]$event, [hashtable]$data) {
  $obj = [ordered]@{
    ts    = (Get-Date).ToString('o')
    event = $event
  }
  foreach ($k in $data.Keys) { $obj[$k] = $data[$k] }
  ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine | 
    Out-File -FilePath $AgentLog -Append -Encoding utf8
  if (-not $Quiet) { Write-Host "[$($obj.ts)] $event" }
}

function DiskFreePct() {
  try {
    $root = [IO.Path]::GetPathRoot($Base)
    $di   = [IO.DriveInfo]::new($root)
    if (-not $di.TotalSize) { return 0 }
    [math]::Round(($di.AvailableFreeSpace/$di.TotalSize)*100,1)
  } catch { 0 }
}

function Normalize([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return '' }
  $t = $s -replace '/', '\'
  while($t.StartsWith('.\')){ $t = $t.Substring(2) }
  $t.Trim()
}

$devRoot    = '^(config|services|tools|seeds|ui|roadmap|learn|logs|reports|dist|cache|snapshots)\\|^[^\\]+\.(ps1|txt|md|json)(?:\.bak-\d{8}-\d{6})?$|^\.env\.sample$'
$strictRoot = '^(config|services|tools|seeds)\\'
function IsAllowed([string]$rel,[string]$modeSel){
  $p = Normalize $rel
  if($modeSel -eq 'dev'){ return ($p -match $devRoot) }
  return ($p -match $strictRoot)
}

function LatestBundle() {
  if (-not (Test-Path $Rel)) { return $null }
  Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc | Select-Object -First 1
}

# fingerprint = max LastWriteTime across allowed files + count
function ComputeFingerprint([string]$sel) {
  $all = Get-ChildItem $Base -Recurse -File -Force
  $acc = @()
  foreach ($f in $all) {
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if (IsAllowed $rel $sel) { $acc += $f }
  }
  if ($acc.Count -eq 0) { return @{ count=0; max=([datetime]'2000-01-01') } }
  $max = ($acc | Sort-Object LastWriteTime -Desc | Select-Object -First 1).LastWriteTime
  return @{ count=$acc.Count; max=$max }
}

function BuildBundle([string]$modeSel) {
  $sel = $modeSel
  $fprint = ComputeFingerprint $sel
  $state  = @{ lastMax = '2000-01-01T00:00:00Z'; lastCount = 0 }
  if (Test-Path $StateFile) {
    try { $state = Get-Content $StateFile -Raw | ConvertFrom-Json } catch { }
  }
  $lastMax   = [datetime]$state.lastMax
  $lastCount = [int]$state.lastCount

  $should = $false
  if ($fprint.max -gt $lastMax -or $fprint.count -ne $lastCount) { $should = $true }

  if (-not $should) {
    Log 'bundle.skip' @{ reason='no-change'; selection=$sel; max=$fprint.max; count=$fprint.count }
    return $null
  }

  # Stage and zip (same as dashboard)
  $all = Get-ChildItem $Base -Recurse -File -Force
  $files = foreach($f in $all){
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if(IsAllowed $rel $sel){ $rel }
  }
  $man = [ordered]@{ version=(Get-Date -Format 'yyyy.MM.dd.HHmmss'); mode=$sel; ts=(Get-Date).ToString('o'); files=@() }
  foreach($rel in $files){
    $full = Join-Path $Base $rel
    $man.files += [ordered]@{ path=$rel; bytes=(Get-Item $full).Length; sha256=(Get-FileHash $full -Algorithm SHA256).Hash }
  }
  $stage = Join-Path $Dist ("stage_" + [guid]::NewGuid().ToString('N'))
  New-Item $stage -ItemType Directory -Force | Out-Null
  foreach($rel in $files){
    $src = Join-Path $Base $rel
    $dst = Join-Path $stage $rel
    New-Item (Split-Path $dst -Parent) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
  }
  $man | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $stage 'manifest.json') -Encoding UTF8
  $zipName = 'Mason2_{0}.zip' -f (Get-Date -Format 'yyyyMMdd_HHmmss')
  $zipPath = Join-Path $Rel $zipName
  if(Test-Path $zipPath){ Remove-Item $zipPath -Force }
  [IO.Compression.ZipFile]::CreateFromDirectory($stage,$zipPath)
  Remove-Item $stage -Recurse -Force -EA SilentlyContinue
  (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash | Set-Content -Encoding ascii ($zipPath + '.sha256')
  Set-Content -Encoding ascii (Join-Path $Rel 'LATEST.txt') ([IO.Path]::GetFileName($zipPath))

  # update state
  $outState = @{ lastMax = $fprint.max.ToString('o'); lastCount = $fprint.count }
  $outState | ConvertTo-Json | Set-Content -Encoding UTF8 $StateFile

  Log 'bundle.built' @{ selection=$sel; zip=$zipPath; count=$fprint.count; max=$fprint.max }
  return $zipPath
}

function TightenVerify([string]$bundle,[string]$mode) {
  if (-not (Test-Path $Tool_VerifyTighten)) { Log 'verify.skip' @{ reason='missing Verify_Tighten.ps1' }; return }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyTighten -Bundle $bundle -Mode $mode 2>&1 | Out-String
  Log 'verify.tighten' @{ bundle=$bundle; mode=$mode; output=$out.Trim() }
}

function VerifyAndUnpack([string]$bundle,[bool]$apply) {
  if (-not (Test-Path $Tool_VerifyUnpack)) { Log 'verify_unpack.skip' @{ reason='missing Verify_And_Unpack.ps1' }; return }
  $args = @('-Bundle',$bundle)
  if ($apply) { $args += '-Apply' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyUnpack @args 2>&1 | Out-String
  Log 'verify.unpack' @{ bundle=$bundle; apply=$apply; output=$out.Trim() }
}

function TrimReleases([int]$n) {
  $z = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc
  $h = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip.sha256' | Sort-Object LastWriteTime -Desc
  $z | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  $h | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  Log 'releases.trim' @{ keep=$n; totalZip=$z.Count }
}

function CleanupStages([int]$days,[switch]$useFolderTime,[switch]$log) {
  if (-not (Test-Path $Tool_Cleanup)) { Log 'cleanup.skip' @{ reason='missing Cleanup_Stages.ps1' }; return }
  $args = @('-Days',$days,'-Dist',$Dist)
  if ($useFolderTime) { $args += '-UseFolderTime' }
  if ($log)          { $args += '-Log' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_Cleanup @args 2>&1 | Out-String
  Log 'cleanup.run' @{ days=$days; output=$out.Trim() }
}

function InNightWindow([string]$win) {
  if ([string]::IsNullOrWhiteSpace($win)) { return $true }
  $parts = $win -split '\s*-\s*'
  if ($parts.Count -ne 2) { return $true }
  $d = Get-Date
  $start = Get-Date $parts[0]
  $end   = Get-Date $parts[1]
  return ($d.TimeOfDay -ge $start.TimeOfDay -and $d.TimeOfDay -le $end.TimeOfDay)
}

# --- single-instance mutex ---
$mtx = New-Object System.Threading.Mutex($false, 'Global\Mason2Agent')
if (-not $mtx.WaitOne(0,$false)) {
  if (-not $Quiet) { Write-Host "Agent already running." }
  return
}
try {
  Log 'agent.start' @{ mode=$Mode; filter=$BundleFilter }

  # 1) Emergency disk guard first
  $free = DiskFreePct
  if ($free -lt $MinFreePct) {
    Log 'guard.lowdisk' @{ freePct=$free; min=$MinFreePct }
    TrimReleases 3
    CleanupStages $CleanupDays -useFolderTime -log
  }

  # 2) Build if files changed (anytime)
  $zip = BuildBundle $BundleFilter
  if (-not $zip) { $zip = (LatestBundle)?.FullName }

  # 3) Heavy stuff (verify / unpack) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â prefer night window
  $okToRunHeavy = InNightWindow $NightWindow
  if (-not $okToRunHeavy) {
    Log 'heavy.defer' @{ window=$NightWindow }
  } else {
    if ($zip) {
      TightenVerify $zip $Mode
      VerifyAndUnpack $zip $ApplyUnpack.IsPresent
    }
  }

  # 4) Routine housekeeping (lightweight)
  TrimReleases $KeepReleases
  CleanupStages $CleanupDays -useFolderTime -log

  Log 'agent.done' @{ freePct=DiskFreePct }

} finally {
  $mtx.ReleaseMutex() | Out-Null
  $mtx.Dispose()
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Mode            = 'strict',      # dev | strict (what Tighten Verify uses)
  [string]$BundleFilter    = 'dev',         # dev | strict (which file-set we pack)
  [int]   $KeepReleases    = 10,            # keep top-N Mason2_*.zip (+ .sha256)
  [int]   $CleanupDays     = 2,             # delete stage_* older than N days
  [int]   $MinFreePct      = 15,            # if disk free < this, do emergency trim/cleanup
  [string]$NightWindow     = '02:00-05:30', # heavy work window; still builds on change anytime
  [switch]$ApplyUnpack,                     # also Extract latest after verify
  [switch]$Quiet                             
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- constants/paths ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools= Join-Path $Base 'tools'
$Dist = Join-Path $Base 'dist'
$Rel  = Join-Path $Dist 'releases'
$Rep  = Join-Path $Base 'reports'
$Cfg  = Join-Path $Base 'config'
$StateFile  = Join-Path $Rep 'agent_state.json'
$AgentLog   = Join-Path $Rep 'agent.log.jsonl'

$Tool_VerifyTighten = Join-Path $Tools 'Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Tools 'Verify_And_Unpack.ps1'
$Tool_Cleanup       = Join-Path $Tools 'Cleanup_Stages.ps1'

# --- ensure folders ---
New-Item -ItemType Directory -Force -Path $Dist,$Rel,$Rep,$Cfg | Out-Null

# --- load config override if present ---
$cfgPath = Join-Path $Cfg 'agent.json'
if (Test-Path $cfgPath) {
  try {
    $j = Get-Content $cfgPath -Raw | ConvertFrom-Json
    if ($j.mode)           { $Mode         = $j.mode }
    if ($j.bundleFilter)   { $BundleFilter = $j.bundleFilter }
    if ($j.keepReleases)   { $KeepReleases = [int]$j.keepReleases }
    if ($j.cleanupDays)    { $CleanupDays  = [int]$j.cleanupDays }
    if ($j.minFreePct)     { $MinFreePct   = [int]$j.minFreePct }
    if ($j.nightWindow)    { $NightWindow  = $j.nightWindow }
    if ($j.applyUnpack)    { $ApplyUnpack  = [bool]$j.applyUnpack }
  } catch { }
}

# --- helpers ---
function Log([string]$event, [hashtable]$data) {
  $obj = [ordered]@{
    ts    = (Get-Date).ToString('o')
    event = $event
  }
  foreach ($k in $data.Keys) { $obj[$k] = $data[$k] }
  ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine | 
    Out-File -FilePath $AgentLog -Append -Encoding utf8
  if (-not $Quiet) { Write-Host "[$($obj.ts)] $event" }
}

function DiskFreePct() {
  try {
    $root = [IO.Path]::GetPathRoot($Base)
    $di   = [IO.DriveInfo]::new($root)
    if (-not $di.TotalSize) { return 0 }
    [math]::Round(($di.AvailableFreeSpace/$di.TotalSize)*100,1)
  } catch { 0 }
}

function Normalize([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return '' }
  $t = $s -replace '/', '\'
  while($t.StartsWith('.\')){ $t = $t.Substring(2) }
  $t.Trim()
}

$devRoot    = '^(config|services|tools|seeds|ui|roadmap|learn|logs|reports|dist|cache|snapshots)\\|^[^\\]+\.(ps1|txt|md|json)(?:\.bak-\d{8}-\d{6})?$|^\.env\.sample$'
$strictRoot = '^(config|services|tools|seeds)\\'
function IsAllowed([string]$rel,[string]$modeSel){
  $p = Normalize $rel
  if($modeSel -eq 'dev'){ return ($p -match $devRoot) }
  return ($p -match $strictRoot)
}

function LatestBundle() {
  if (-not (Test-Path $Rel)) { return $null }
  Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc | Select-Object -First 1
}

# fingerprint = max LastWriteTime across allowed files + count
function ComputeFingerprint([string]$sel) {
  $all = Get-ChildItem $Base -Recurse -File -Force
  $acc = @()
  foreach ($f in $all) {
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if (IsAllowed $rel $sel) { $acc += $f }
  }
  if ($acc.Count -eq 0) { return @{ count=0; max=([datetime]'2000-01-01') } }
  $max = ($acc | Sort-Object LastWriteTime -Desc | Select-Object -First 1).LastWriteTime
  return @{ count=$acc.Count; max=$max }
}

function BuildBundle([string]$modeSel) {
  $sel = $modeSel
  $fprint = ComputeFingerprint $sel
  $state  = @{ lastMax = '2000-01-01T00:00:00Z'; lastCount = 0 }
  if (Test-Path $StateFile) {
    try { $state = Get-Content $StateFile -Raw | ConvertFrom-Json } catch { }
  }
  $lastMax   = [datetime]$state.lastMax
  $lastCount = [int]$state.lastCount

  $should = $false
  if ($fprint.max -gt $lastMax -or $fprint.count -ne $lastCount) { $should = $true }

  if (-not $should) {
    Log 'bundle.skip' @{ reason='no-change'; selection=$sel; max=$fprint.max; count=$fprint.count }
    return $null
  }

  # Stage and zip (same as dashboard)
  $all = Get-ChildItem $Base -Recurse -File -Force
  $files = foreach($f in $all){
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if(IsAllowed $rel $sel){ $rel }
  }
  $man = [ordered]@{ version=(Get-Date -Format 'yyyy.MM.dd.HHmmss'); mode=$sel; ts=(Get-Date).ToString('o'); files=@() }
  foreach($rel in $files){
    $full = Join-Path $Base $rel
    $man.files += [ordered]@{ path=$rel; bytes=(Get-Item $full).Length; sha256=(Get-FileHash $full -Algorithm SHA256).Hash }
  }
  $stage = Join-Path $Dist ("stage_" + [guid]::NewGuid().ToString('N'))
  New-Item $stage -ItemType Directory -Force | Out-Null
  foreach($rel in $files){
    $src = Join-Path $Base $rel
    $dst = Join-Path $stage $rel
    New-Item (Split-Path $dst -Parent) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
  }
  $man | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $stage 'manifest.json') -Encoding UTF8
  $zipName = 'Mason2_{0}.zip' -f (Get-Date -Format 'yyyyMMdd_HHmmss')
  $zipPath = Join-Path $Rel $zipName
  if(Test-Path $zipPath){ Remove-Item $zipPath -Force }
  [IO.Compression.ZipFile]::CreateFromDirectory($stage,$zipPath)
  Remove-Item $stage -Recurse -Force -EA SilentlyContinue
  (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash | Set-Content -Encoding ascii ($zipPath + '.sha256')
  Set-Content -Encoding ascii (Join-Path $Rel 'LATEST.txt') ([IO.Path]::GetFileName($zipPath))

  # update state
  $outState = @{ lastMax = $fprint.max.ToString('o'); lastCount = $fprint.count }
  $outState | ConvertTo-Json | Set-Content -Encoding UTF8 $StateFile

  Log 'bundle.built' @{ selection=$sel; zip=$zipPath; count=$fprint.count; max=$fprint.max }
  return $zipPath
}

function TightenVerify([string]$bundle,[string]$mode) {
  if (-not (Test-Path $Tool_VerifyTighten)) { Log 'verify.skip' @{ reason='missing Verify_Tighten.ps1' }; return }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyTighten -Bundle $bundle -Mode $mode 2>&1 | Out-String
  Log 'verify.tighten' @{ bundle=$bundle; mode=$mode; output=$out.Trim() }
}

function VerifyAndUnpack([string]$bundle,[bool]$apply) {
  if (-not (Test-Path $Tool_VerifyUnpack)) { Log 'verify_unpack.skip' @{ reason='missing Verify_And_Unpack.ps1' }; return }
  $args = @('-Bundle',$bundle)
  if ($apply) { $args += '-Apply' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyUnpack @args 2>&1 | Out-String
  Log 'verify.unpack' @{ bundle=$bundle; apply=$apply; output=$out.Trim() }
}

function TrimReleases([int]$n) {
  $z = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc
  $h = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip.sha256' | Sort-Object LastWriteTime -Desc
  $z | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  $h | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  Log 'releases.trim' @{ keep=$n; totalZip=$z.Count }
}

function CleanupStages([int]$days,[switch]$useFolderTime,[switch]$log) {
  if (-not (Test-Path $Tool_Cleanup)) { Log 'cleanup.skip' @{ reason='missing Cleanup_Stages.ps1' }; return }
  $args = @('-Days',$days,'-Dist',$Dist)
  if ($useFolderTime) { $args += '-UseFolderTime' }
  if ($log)          { $args += '-Log' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_Cleanup @args 2>&1 | Out-String
  Log 'cleanup.run' @{ days=$days; output=$out.Trim() }
}

function InNightWindow([string]$win) {
  if ([string]::IsNullOrWhiteSpace($win)) { return $true }
  $parts = $win -split '\s*-\s*'
  if ($parts.Count -ne 2) { return $true }
  $d = Get-Date
  $start = Get-Date $parts[0]
  $end   = Get-Date $parts[1]
  return ($d.TimeOfDay -ge $start.TimeOfDay -and $d.TimeOfDay -le $end.TimeOfDay)
}

# --- single-instance mutex ---
$mtx = New-Object System.Threading.Mutex($false, 'Global\Mason2Agent')
if (-not $mtx.WaitOne(0,$false)) {
  if (-not $Quiet) { Write-Host "Agent already running." }
  return
}
try {
  Log 'agent.start' @{ mode=$Mode; filter=$BundleFilter }

  # 1) Emergency disk guard first
  $free = DiskFreePct
  if ($free -lt $MinFreePct) {
    Log 'guard.lowdisk' @{ freePct=$free; min=$MinFreePct }
    TrimReleases 3
    CleanupStages $CleanupDays -useFolderTime -log
  }

  # 2) Build if files changed (anytime)
  $zip = BuildBundle $BundleFilter
  if (-not $zip) { $zip = (LatestBundle)?.FullName }

  # 3) Heavy stuff (verify / unpack) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â prefer night window
  $okToRunHeavy = InNightWindow $NightWindow
  if (-not $okToRunHeavy) {
    Log 'heavy.defer' @{ window=$NightWindow }
  } else {
    if ($zip) {
      TightenVerify $zip $Mode
      VerifyAndUnpack $zip $ApplyUnpack.IsPresent
    }
  }

  # 4) Routine housekeeping (lightweight)
  TrimReleases $KeepReleases
  CleanupStages $CleanupDays -useFolderTime -log

  Log 'agent.done' @{ freePct=DiskFreePct }

} finally {
  $mtx.ReleaseMutex() | Out-Null
  $mtx.Dispose()
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Mode            = 'strict',      # dev | strict (what Tighten Verify uses)
  [string]$BundleFilter    = 'dev',         # dev | strict (which file-set we pack)
  [int]   $KeepReleases    = 10,            # keep top-N Mason2_*.zip (+ .sha256)
  [int]   $CleanupDays     = 2,             # delete stage_* older than N days
  [int]   $MinFreePct      = 15,            # if disk free < this, do emergency trim/cleanup
  [string]$NightWindow     = '02:00-05:30', # heavy work window; still builds on change anytime
  [switch]$ApplyUnpack,                     # also Extract latest after verify
  [switch]$Quiet                             
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- constants/paths ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools= Join-Path $Base 'tools'
$Dist = Join-Path $Base 'dist'
$Rel  = Join-Path $Dist 'releases'
$Rep  = Join-Path $Base 'reports'
$Cfg  = Join-Path $Base 'config'
$StateFile  = Join-Path $Rep 'agent_state.json'
$AgentLog   = Join-Path $Rep 'agent.log.jsonl'

$Tool_VerifyTighten = Join-Path $Tools 'Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Tools 'Verify_And_Unpack.ps1'
$Tool_Cleanup       = Join-Path $Tools 'Cleanup_Stages.ps1'

# --- ensure folders ---
New-Item -ItemType Directory -Force -Path $Dist,$Rel,$Rep,$Cfg | Out-Null

# --- load config override if present ---
$cfgPath = Join-Path $Cfg 'agent.json'
if (Test-Path $cfgPath) {
  try {
    $j = Get-Content $cfgPath -Raw | ConvertFrom-Json
    if ($j.mode)           { $Mode         = $j.mode }
    if ($j.bundleFilter)   { $BundleFilter = $j.bundleFilter }
    if ($j.keepReleases)   { $KeepReleases = [int]$j.keepReleases }
    if ($j.cleanupDays)    { $CleanupDays  = [int]$j.cleanupDays }
    if ($j.minFreePct)     { $MinFreePct   = [int]$j.minFreePct }
    if ($j.nightWindow)    { $NightWindow  = $j.nightWindow }
    if ($j.applyUnpack)    { $ApplyUnpack  = [bool]$j.applyUnpack }
  } catch { }
}

# --- helpers ---
function Log([string]$event, [hashtable]$data) {
  $obj = [ordered]@{
    ts    = (Get-Date).ToString('o')
    event = $event
  }
  foreach ($k in $data.Keys) { $obj[$k] = $data[$k] }
  ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine | 
    Out-File -FilePath $AgentLog -Append -Encoding utf8
  if (-not $Quiet) { Write-Host "[$($obj.ts)] $event" }
}

function DiskFreePct() {
  try {
    $root = [IO.Path]::GetPathRoot($Base)
    $di   = [IO.DriveInfo]::new($root)
    if (-not $di.TotalSize) { return 0 }
    [math]::Round(($di.AvailableFreeSpace/$di.TotalSize)*100,1)
  } catch { 0 }
}

function Normalize([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return '' }
  $t = $s -replace '/', '\'
  while($t.StartsWith('.\')){ $t = $t.Substring(2) }
  $t.Trim()
}

$devRoot    = '^(config|services|tools|seeds|ui|roadmap|learn|logs|reports|dist|cache|snapshots)\\|^[^\\]+\.(ps1|txt|md|json)(?:\.bak-\d{8}-\d{6})?$|^\.env\.sample$'
$strictRoot = '^(config|services|tools|seeds)\\'
function IsAllowed([string]$rel,[string]$modeSel){
  $p = Normalize $rel
  if($modeSel -eq 'dev'){ return ($p -match $devRoot) }
  return ($p -match $strictRoot)
}

function LatestBundle() {
  if (-not (Test-Path $Rel)) { return $null }
  Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc | Select-Object -First 1
}

# fingerprint = max LastWriteTime across allowed files + count
function ComputeFingerprint([string]$sel) {
  $all = Get-ChildItem $Base -Recurse -File -Force
  $acc = @()
  foreach ($f in $all) {
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if (IsAllowed $rel $sel) { $acc += $f }
  }
  if ($acc.Count -eq 0) { return @{ count=0; max=([datetime]'2000-01-01') } }
  $max = ($acc | Sort-Object LastWriteTime -Desc | Select-Object -First 1).LastWriteTime
  return @{ count=$acc.Count; max=$max }
}

function BuildBundle([string]$modeSel) {
  $sel = $modeSel
  $fprint = ComputeFingerprint $sel
  $state  = @{ lastMax = '2000-01-01T00:00:00Z'; lastCount = 0 }
  if (Test-Path $StateFile) {
    try { $state = Get-Content $StateFile -Raw | ConvertFrom-Json } catch { }
  }
  $lastMax   = [datetime]$state.lastMax
  $lastCount = [int]$state.lastCount

  $should = $false
  if ($fprint.max -gt $lastMax -or $fprint.count -ne $lastCount) { $should = $true }

  if (-not $should) {
    Log 'bundle.skip' @{ reason='no-change'; selection=$sel; max=$fprint.max; count=$fprint.count }
    return $null
  }

  # Stage and zip (same as dashboard)
  $all = Get-ChildItem $Base -Recurse -File -Force
  $files = foreach($f in $all){
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if(IsAllowed $rel $sel){ $rel }
  }
  $man = [ordered]@{ version=(Get-Date -Format 'yyyy.MM.dd.HHmmss'); mode=$sel; ts=(Get-Date).ToString('o'); files=@() }
  foreach($rel in $files){
    $full = Join-Path $Base $rel
    $man.files += [ordered]@{ path=$rel; bytes=(Get-Item $full).Length; sha256=(Get-FileHash $full -Algorithm SHA256).Hash }
  }
  $stage = Join-Path $Dist ("stage_" + [guid]::NewGuid().ToString('N'))
  New-Item $stage -ItemType Directory -Force | Out-Null
  foreach($rel in $files){
    $src = Join-Path $Base $rel
    $dst = Join-Path $stage $rel
    New-Item (Split-Path $dst -Parent) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
  }
  $man | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $stage 'manifest.json') -Encoding UTF8
  $zipName = 'Mason2_{0}.zip' -f (Get-Date -Format 'yyyyMMdd_HHmmss')
  $zipPath = Join-Path $Rel $zipName
  if(Test-Path $zipPath){ Remove-Item $zipPath -Force }
  [IO.Compression.ZipFile]::CreateFromDirectory($stage,$zipPath)
  Remove-Item $stage -Recurse -Force -EA SilentlyContinue
  (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash | Set-Content -Encoding ascii ($zipPath + '.sha256')
  Set-Content -Encoding ascii (Join-Path $Rel 'LATEST.txt') ([IO.Path]::GetFileName($zipPath))

  # update state
  $outState = @{ lastMax = $fprint.max.ToString('o'); lastCount = $fprint.count }
  $outState | ConvertTo-Json | Set-Content -Encoding UTF8 $StateFile

  Log 'bundle.built' @{ selection=$sel; zip=$zipPath; count=$fprint.count; max=$fprint.max }
  return $zipPath
}

function TightenVerify([string]$bundle,[string]$mode) {
  if (-not (Test-Path $Tool_VerifyTighten)) { Log 'verify.skip' @{ reason='missing Verify_Tighten.ps1' }; return }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyTighten -Bundle $bundle -Mode $mode 2>&1 | Out-String
  Log 'verify.tighten' @{ bundle=$bundle; mode=$mode; output=$out.Trim() }
}

function VerifyAndUnpack([string]$bundle,[bool]$apply) {
  if (-not (Test-Path $Tool_VerifyUnpack)) { Log 'verify_unpack.skip' @{ reason='missing Verify_And_Unpack.ps1' }; return }
  $args = @('-Bundle',$bundle)
  if ($apply) { $args += '-Apply' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyUnpack @args 2>&1 | Out-String
  Log 'verify.unpack' @{ bundle=$bundle; apply=$apply; output=$out.Trim() }
}

function TrimReleases([int]$n) {
  $z = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc
  $h = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip.sha256' | Sort-Object LastWriteTime -Desc
  $z | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  $h | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  Log 'releases.trim' @{ keep=$n; totalZip=$z.Count }
}

function CleanupStages([int]$days,[switch]$useFolderTime,[switch]$log) {
  if (-not (Test-Path $Tool_Cleanup)) { Log 'cleanup.skip' @{ reason='missing Cleanup_Stages.ps1' }; return }
  $args = @('-Days',$days,'-Dist',$Dist)
  if ($useFolderTime) { $args += '-UseFolderTime' }
  if ($log)          { $args += '-Log' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_Cleanup @args 2>&1 | Out-String
  Log 'cleanup.run' @{ days=$days; output=$out.Trim() }
}

function InNightWindow([string]$win) {
  if ([string]::IsNullOrWhiteSpace($win)) { return $true }
  $parts = $win -split '\s*-\s*'
  if ($parts.Count -ne 2) { return $true }
  $d = Get-Date
  $start = Get-Date $parts[0]
  $end   = Get-Date $parts[1]
  return ($d.TimeOfDay -ge $start.TimeOfDay -and $d.TimeOfDay -le $end.TimeOfDay)
}

# --- single-instance mutex ---
$mtx = New-Object System.Threading.Mutex($false, 'Global\Mason2Agent')
if (-not $mtx.WaitOne(0,$false)) {
  if (-not $Quiet) { Write-Host "Agent already running." }
  return
}
try {
  Log 'agent.start' @{ mode=$Mode; filter=$BundleFilter }

  # 1) Emergency disk guard first
  $free = DiskFreePct
  if ($free -lt $MinFreePct) {
    Log 'guard.lowdisk' @{ freePct=$free; min=$MinFreePct }
    TrimReleases 3
    CleanupStages $CleanupDays -useFolderTime -log
  }

  # 2) Build if files changed (anytime)
  $zip = BuildBundle $BundleFilter
  if (-not $zip) { $zip = (LatestBundle)?.FullName }

  # 3) Heavy stuff (verify / unpack) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â prefer night window
  $okToRunHeavy = InNightWindow $NightWindow
  if (-not $okToRunHeavy) {
    Log 'heavy.defer' @{ window=$NightWindow }
  } else {
    if ($zip) {
      TightenVerify $zip $Mode
      VerifyAndUnpack $zip $ApplyUnpack.IsPresent
    }
  }

  # 4) Routine housekeeping (lightweight)
  TrimReleases $KeepReleases
  CleanupStages $CleanupDays -useFolderTime -log

  Log 'agent.done' @{ freePct=DiskFreePct }

} finally {
  $mtx.ReleaseMutex() | Out-Null
  $mtx.Dispose()
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Mode            = 'strict',      # dev | strict (what Tighten Verify uses)
  [string]$BundleFilter    = 'dev',         # dev | strict (which file-set we pack)
  [int]   $KeepReleases    = 10,            # keep top-N Mason2_*.zip (+ .sha256)
  [int]   $CleanupDays     = 2,             # delete stage_* older than N days
  [int]   $MinFreePct      = 15,            # if disk free < this, do emergency trim/cleanup
  [string]$NightWindow     = '02:00-05:30', # heavy work window; still builds on change anytime
  [switch]$ApplyUnpack,                     # also Extract latest after verify
  [switch]$Quiet                             
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- constants/paths ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools= Join-Path $Base 'tools'
$Dist = Join-Path $Base 'dist'
$Rel  = Join-Path $Dist 'releases'
$Rep  = Join-Path $Base 'reports'
$Cfg  = Join-Path $Base 'config'
$StateFile  = Join-Path $Rep 'agent_state.json'
$AgentLog   = Join-Path $Rep 'agent.log.jsonl'

$Tool_VerifyTighten = Join-Path $Tools 'Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Tools 'Verify_And_Unpack.ps1'
$Tool_Cleanup       = Join-Path $Tools 'Cleanup_Stages.ps1'

# --- ensure folders ---
New-Item -ItemType Directory -Force -Path $Dist,$Rel,$Rep,$Cfg | Out-Null

# --- load config override if present ---
$cfgPath = Join-Path $Cfg 'agent.json'
if (Test-Path $cfgPath) {
  try {
    $j = Get-Content $cfgPath -Raw | ConvertFrom-Json
    if ($j.mode)           { $Mode         = $j.mode }
    if ($j.bundleFilter)   { $BundleFilter = $j.bundleFilter }
    if ($j.keepReleases)   { $KeepReleases = [int]$j.keepReleases }
    if ($j.cleanupDays)    { $CleanupDays  = [int]$j.cleanupDays }
    if ($j.minFreePct)     { $MinFreePct   = [int]$j.minFreePct }
    if ($j.nightWindow)    { $NightWindow  = $j.nightWindow }
    if ($j.applyUnpack)    { $ApplyUnpack  = [bool]$j.applyUnpack }
  } catch { }
}

# --- helpers ---
function Log([string]$event, [hashtable]$data) {
  $obj = [ordered]@{
    ts    = (Get-Date).ToString('o')
    event = $event
  }
  foreach ($k in $data.Keys) { $obj[$k] = $data[$k] }
  ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine | 
    Out-File -FilePath $AgentLog -Append -Encoding utf8
  if (-not $Quiet) { Write-Host "[$($obj.ts)] $event" }
}

function DiskFreePct() {
  try {
    $root = [IO.Path]::GetPathRoot($Base)
    $di   = [IO.DriveInfo]::new($root)
    if (-not $di.TotalSize) { return 0 }
    [math]::Round(($di.AvailableFreeSpace/$di.TotalSize)*100,1)
  } catch { 0 }
}

function Normalize([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return '' }
  $t = $s -replace '/', '\'
  while($t.StartsWith('.\')){ $t = $t.Substring(2) }
  $t.Trim()
}

$devRoot    = '^(config|services|tools|seeds|ui|roadmap|learn|logs|reports|dist|cache|snapshots)\\|^[^\\]+\.(ps1|txt|md|json)(?:\.bak-\d{8}-\d{6})?$|^\.env\.sample$'
$strictRoot = '^(config|services|tools|seeds)\\'
function IsAllowed([string]$rel,[string]$modeSel){
  $p = Normalize $rel
  if($modeSel -eq 'dev'){ return ($p -match $devRoot) }
  return ($p -match $strictRoot)
}

function LatestBundle() {
  if (-not (Test-Path $Rel)) { return $null }
  Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc | Select-Object -First 1
}

# fingerprint = max LastWriteTime across allowed files + count
function ComputeFingerprint([string]$sel) {
  $all = Get-ChildItem $Base -Recurse -File -Force
  $acc = @()
  foreach ($f in $all) {
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if (IsAllowed $rel $sel) { $acc += $f }
  }
  if ($acc.Count -eq 0) { return @{ count=0; max=([datetime]'2000-01-01') } }
  $max = ($acc | Sort-Object LastWriteTime -Desc | Select-Object -First 1).LastWriteTime
  return @{ count=$acc.Count; max=$max }
}

function BuildBundle([string]$modeSel) {
  $sel = $modeSel
  $fprint = ComputeFingerprint $sel
  $state  = @{ lastMax = '2000-01-01T00:00:00Z'; lastCount = 0 }
  if (Test-Path $StateFile) {
    try { $state = Get-Content $StateFile -Raw | ConvertFrom-Json } catch { }
  }
  $lastMax   = [datetime]$state.lastMax
  $lastCount = [int]$state.lastCount

  $should = $false
  if ($fprint.max -gt $lastMax -or $fprint.count -ne $lastCount) { $should = $true }

  if (-not $should) {
    Log 'bundle.skip' @{ reason='no-change'; selection=$sel; max=$fprint.max; count=$fprint.count }
    return $null
  }

  # Stage and zip (same as dashboard)
  $all = Get-ChildItem $Base -Recurse -File -Force
  $files = foreach($f in $all){
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if(IsAllowed $rel $sel){ $rel }
  }
  $man = [ordered]@{ version=(Get-Date -Format 'yyyy.MM.dd.HHmmss'); mode=$sel; ts=(Get-Date).ToString('o'); files=@() }
  foreach($rel in $files){
    $full = Join-Path $Base $rel
    $man.files += [ordered]@{ path=$rel; bytes=(Get-Item $full).Length; sha256=(Get-FileHash $full -Algorithm SHA256).Hash }
  }
  $stage = Join-Path $Dist ("stage_" + [guid]::NewGuid().ToString('N'))
  New-Item $stage -ItemType Directory -Force | Out-Null
  foreach($rel in $files){
    $src = Join-Path $Base $rel
    $dst = Join-Path $stage $rel
    New-Item (Split-Path $dst -Parent) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
  }
  $man | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $stage 'manifest.json') -Encoding UTF8
  $zipName = 'Mason2_{0}.zip' -f (Get-Date -Format 'yyyyMMdd_HHmmss')
  $zipPath = Join-Path $Rel $zipName
  if(Test-Path $zipPath){ Remove-Item $zipPath -Force }
  [IO.Compression.ZipFile]::CreateFromDirectory($stage,$zipPath)
  Remove-Item $stage -Recurse -Force -EA SilentlyContinue
  (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash | Set-Content -Encoding ascii ($zipPath + '.sha256')
  Set-Content -Encoding ascii (Join-Path $Rel 'LATEST.txt') ([IO.Path]::GetFileName($zipPath))

  # update state
  $outState = @{ lastMax = $fprint.max.ToString('o'); lastCount = $fprint.count }
  $outState | ConvertTo-Json | Set-Content -Encoding UTF8 $StateFile

  Log 'bundle.built' @{ selection=$sel; zip=$zipPath; count=$fprint.count; max=$fprint.max }
  return $zipPath
}

function TightenVerify([string]$bundle,[string]$mode) {
  if (-not (Test-Path $Tool_VerifyTighten)) { Log 'verify.skip' @{ reason='missing Verify_Tighten.ps1' }; return }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyTighten -Bundle $bundle -Mode $mode 2>&1 | Out-String
  Log 'verify.tighten' @{ bundle=$bundle; mode=$mode; output=$out.Trim() }
}

function VerifyAndUnpack([string]$bundle,[bool]$apply) {
  if (-not (Test-Path $Tool_VerifyUnpack)) { Log 'verify_unpack.skip' @{ reason='missing Verify_And_Unpack.ps1' }; return }
  $args = @('-Bundle',$bundle)
  if ($apply) { $args += '-Apply' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyUnpack @args 2>&1 | Out-String
  Log 'verify.unpack' @{ bundle=$bundle; apply=$apply; output=$out.Trim() }
}

function TrimReleases([int]$n) {
  $z = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc
  $h = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip.sha256' | Sort-Object LastWriteTime -Desc
  $z | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  $h | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  Log 'releases.trim' @{ keep=$n; totalZip=$z.Count }
}

function CleanupStages([int]$days,[switch]$useFolderTime,[switch]$log) {
  if (-not (Test-Path $Tool_Cleanup)) { Log 'cleanup.skip' @{ reason='missing Cleanup_Stages.ps1' }; return }
  $args = @('-Days',$days,'-Dist',$Dist)
  if ($useFolderTime) { $args += '-UseFolderTime' }
  if ($log)          { $args += '-Log' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_Cleanup @args 2>&1 | Out-String
  Log 'cleanup.run' @{ days=$days; output=$out.Trim() }
}

function InNightWindow([string]$win) {
  if ([string]::IsNullOrWhiteSpace($win)) { return $true }
  $parts = $win -split '\s*-\s*'
  if ($parts.Count -ne 2) { return $true }
  $d = Get-Date
  $start = Get-Date $parts[0]
  $end   = Get-Date $parts[1]
  return ($d.TimeOfDay -ge $start.TimeOfDay -and $d.TimeOfDay -le $end.TimeOfDay)
}

# --- single-instance mutex ---
$mtx = New-Object System.Threading.Mutex($false, 'Global\Mason2Agent')
if (-not $mtx.WaitOne(0,$false)) {
  if (-not $Quiet) { Write-Host "Agent already running." }
  return
}
try {
  Log 'agent.start' @{ mode=$Mode; filter=$BundleFilter }

  # 1) Emergency disk guard first
  $free = DiskFreePct
  if ($free -lt $MinFreePct) {
    Log 'guard.lowdisk' @{ freePct=$free; min=$MinFreePct }
    TrimReleases 3
    CleanupStages $CleanupDays -useFolderTime -log
  }

  # 2) Build if files changed (anytime)
  $zip = BuildBundle $BundleFilter
  if (-not $zip) { $zip = (LatestBundle)?.FullName }

  # 3) Heavy stuff (verify / unpack) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â prefer night window
  $okToRunHeavy = InNightWindow $NightWindow
  if (-not $okToRunHeavy) {
    Log 'heavy.defer' @{ window=$NightWindow }
  } else {
    if ($zip) {
      TightenVerify $zip $Mode
      VerifyAndUnpack $zip $ApplyUnpack.IsPresent
    }
  }

  # 4) Routine housekeeping (lightweight)
  TrimReleases $KeepReleases
  CleanupStages $CleanupDays -useFolderTime -log

  Log 'agent.done' @{ freePct=DiskFreePct }

} finally {
  $mtx.ReleaseMutex() | Out-Null
  $mtx.Dispose()
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Mode            = 'strict',      # dev | strict (what Tighten Verify uses)
  [string]$BundleFilter    = 'dev',         # dev | strict (which file-set we pack)
  [int]   $KeepReleases    = 10,            # keep top-N Mason2_*.zip (+ .sha256)
  [int]   $CleanupDays     = 2,             # delete stage_* older than N days
  [int]   $MinFreePct      = 15,            # if disk free < this, do emergency trim/cleanup
  [string]$NightWindow     = '02:00-05:30', # heavy work window; still builds on change anytime
  [switch]$ApplyUnpack,                     # also Extract latest after verify
  [switch]$Quiet                             
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- constants/paths ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools= Join-Path $Base 'tools'
$Dist = Join-Path $Base 'dist'
$Rel  = Join-Path $Dist 'releases'
$Rep  = Join-Path $Base 'reports'
$Cfg  = Join-Path $Base 'config'
$StateFile  = Join-Path $Rep 'agent_state.json'
$AgentLog   = Join-Path $Rep 'agent.log.jsonl'

$Tool_VerifyTighten = Join-Path $Tools 'Verify_Tighten.ps1'
$Tool_VerifyUnpack  = Join-Path $Tools 'Verify_And_Unpack.ps1'
$Tool_Cleanup       = Join-Path $Tools 'Cleanup_Stages.ps1'

# --- ensure folders ---
New-Item -ItemType Directory -Force -Path $Dist,$Rel,$Rep,$Cfg | Out-Null

# --- load config override if present ---
$cfgPath = Join-Path $Cfg 'agent.json'
if (Test-Path $cfgPath) {
  try {
    $j = Get-Content $cfgPath -Raw | ConvertFrom-Json
    if ($j.mode)           { $Mode         = $j.mode }
    if ($j.bundleFilter)   { $BundleFilter = $j.bundleFilter }
    if ($j.keepReleases)   { $KeepReleases = [int]$j.keepReleases }
    if ($j.cleanupDays)    { $CleanupDays  = [int]$j.cleanupDays }
    if ($j.minFreePct)     { $MinFreePct   = [int]$j.minFreePct }
    if ($j.nightWindow)    { $NightWindow  = $j.nightWindow }
    if ($j.applyUnpack)    { $ApplyUnpack  = [bool]$j.applyUnpack }
  } catch { }
}

# --- helpers ---
function Log([string]$event, [hashtable]$data) {
  $obj = [ordered]@{
    ts    = (Get-Date).ToString('o')
    event = $event
  }
  foreach ($k in $data.Keys) { $obj[$k] = $data[$k] }
  ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine | 
    Out-File -FilePath $AgentLog -Append -Encoding utf8
  if (-not $Quiet) { Write-Host "[$($obj.ts)] $event" }
}

function DiskFreePct() {
  try {
    $root = [IO.Path]::GetPathRoot($Base)
    $di   = [IO.DriveInfo]::new($root)
    if (-not $di.TotalSize) { return 0 }
    [math]::Round(($di.AvailableFreeSpace/$di.TotalSize)*100,1)
  } catch { 0 }
}

function Normalize([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return '' }
  $t = $s -replace '/', '\'
  while($t.StartsWith('.\')){ $t = $t.Substring(2) }
  $t.Trim()
}

$devRoot    = '^(config|services|tools|seeds|ui|roadmap|learn|logs|reports|dist|cache|snapshots)\\|^[^\\]+\.(ps1|txt|md|json)(?:\.bak-\d{8}-\d{6})?$|^\.env\.sample$'
$strictRoot = '^(config|services|tools|seeds)\\'
function IsAllowed([string]$rel,[string]$modeSel){
  $p = Normalize $rel
  if($modeSel -eq 'dev'){ return ($p -match $devRoot) }
  return ($p -match $strictRoot)
}

function LatestBundle() {
  if (-not (Test-Path $Rel)) { return $null }
  Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc | Select-Object -First 1
}

# fingerprint = max LastWriteTime across allowed files + count
function ComputeFingerprint([string]$sel) {
  $all = Get-ChildItem $Base -Recurse -File -Force
  $acc = @()
  foreach ($f in $all) {
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if (IsAllowed $rel $sel) { $acc += $f }
  }
  if ($acc.Count -eq 0) { return @{ count=0; max=([datetime]'2000-01-01') } }
  $max = ($acc | Sort-Object LastWriteTime -Desc | Select-Object -First 1).LastWriteTime
  return @{ count=$acc.Count; max=$max }
}

function BuildBundle([string]$modeSel) {
  $sel = $modeSel
  $fprint = ComputeFingerprint $sel
  $state  = @{ lastMax = '2000-01-01T00:00:00Z'; lastCount = 0 }
  if (Test-Path $StateFile) {
    try { $state = Get-Content $StateFile -Raw | ConvertFrom-Json } catch { }
  }
  $lastMax   = [datetime]$state.lastMax
  $lastCount = [int]$state.lastCount

  $should = $false
  if ($fprint.max -gt $lastMax -or $fprint.count -ne $lastCount) { $should = $true }

  if (-not $should) {
    Log 'bundle.skip' @{ reason='no-change'; selection=$sel; max=$fprint.max; count=$fprint.count }
    return $null
  }

  # Stage and zip (same as dashboard)
  $all = Get-ChildItem $Base -Recurse -File -Force
  $files = foreach($f in $all){
    $rel = Normalize ($f.FullName.Substring($Base.Length+1))
    if(IsAllowed $rel $sel){ $rel }
  }
  $man = [ordered]@{ version=(Get-Date -Format 'yyyy.MM.dd.HHmmss'); mode=$sel; ts=(Get-Date).ToString('o'); files=@() }
  foreach($rel in $files){
    $full = Join-Path $Base $rel
    $man.files += [ordered]@{ path=$rel; bytes=(Get-Item $full).Length; sha256=(Get-FileHash $full -Algorithm SHA256).Hash }
  }
  $stage = Join-Path $Dist ("stage_" + [guid]::NewGuid().ToString('N'))
  New-Item $stage -ItemType Directory -Force | Out-Null
  foreach($rel in $files){
    $src = Join-Path $Base $rel
    $dst = Join-Path $stage $rel
    New-Item (Split-Path $dst -Parent) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $src -Destination $dst -Force
  }
  $man | ConvertTo-Json -Depth 12 | Set-Content (Join-Path $stage 'manifest.json') -Encoding UTF8
  $zipName = 'Mason2_{0}.zip' -f (Get-Date -Format 'yyyyMMdd_HHmmss')
  $zipPath = Join-Path $Rel $zipName
  if(Test-Path $zipPath){ Remove-Item $zipPath -Force }
  [IO.Compression.ZipFile]::CreateFromDirectory($stage,$zipPath)
  Remove-Item $stage -Recurse -Force -EA SilentlyContinue
  (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash | Set-Content -Encoding ascii ($zipPath + '.sha256')
  Set-Content -Encoding ascii (Join-Path $Rel 'LATEST.txt') ([IO.Path]::GetFileName($zipPath))

  # update state
  $outState = @{ lastMax = $fprint.max.ToString('o'); lastCount = $fprint.count }
  $outState | ConvertTo-Json | Set-Content -Encoding UTF8 $StateFile

  Log 'bundle.built' @{ selection=$sel; zip=$zipPath; count=$fprint.count; max=$fprint.max }
  return $zipPath
}

function TightenVerify([string]$bundle,[string]$mode) {
  if (-not (Test-Path $Tool_VerifyTighten)) { Log 'verify.skip' @{ reason='missing Verify_Tighten.ps1' }; return }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyTighten -Bundle $bundle -Mode $mode 2>&1 | Out-String
  Log 'verify.tighten' @{ bundle=$bundle; mode=$mode; output=$out.Trim() }
}

function VerifyAndUnpack([string]$bundle,[bool]$apply) {
  if (-not (Test-Path $Tool_VerifyUnpack)) { Log 'verify_unpack.skip' @{ reason='missing Verify_And_Unpack.ps1' }; return }
  $args = @('-Bundle',$bundle)
  if ($apply) { $args += '-Apply' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_VerifyUnpack @args 2>&1 | Out-String
  Log 'verify.unpack' @{ bundle=$bundle; apply=$apply; output=$out.Trim() }
}

function TrimReleases([int]$n) {
  $z = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip' | Sort-Object LastWriteTime -Desc
  $h = Get-ChildItem $Rel -File -Filter 'Mason2_*.zip.sha256' | Sort-Object LastWriteTime -Desc
  $z | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  $h | Select-Object -Skip $n | Remove-Item -Force -EA SilentlyContinue
  Log 'releases.trim' @{ keep=$n; totalZip=$z.Count }
}

function CleanupStages([int]$days,[switch]$useFolderTime,[switch]$log) {
  if (-not (Test-Path $Tool_Cleanup)) { Log 'cleanup.skip' @{ reason='missing Cleanup_Stages.ps1' }; return }
  $args = @('-Days',$days,'-Dist',$Dist)
  if ($useFolderTime) { $args += '-UseFolderTime' }
  if ($log)          { $args += '-Log' }
  $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $Tool_Cleanup @args 2>&1 | Out-String
  Log 'cleanup.run' @{ days=$days; output=$out.Trim() }
}

function InNightWindow([string]$win) {
  if ([string]::IsNullOrWhiteSpace($win)) { return $true }
  $parts = $win -split '\s*-\s*'
  if ($parts.Count -ne 2) { return $true }
  $d = Get-Date
  $start = Get-Date $parts[0]
  $end   = Get-Date $parts[1]
  return ($d.TimeOfDay -ge $start.TimeOfDay -and $d.TimeOfDay -le $end.TimeOfDay)
}

# --- single-instance mutex ---
$mtx = New-Object System.Threading.Mutex($false, 'Global\Mason2Agent')
if (-not $mtx.WaitOne(0,$false)) {
  if (-not $Quiet) { Write-Host "Agent already running." }
  return
}
try {
  Log 'agent.start' @{ mode=$Mode; filter=$BundleFilter }

  # 1) Emergency disk guard first
  $free = DiskFreePct
  if ($free -lt $MinFreePct) {
    Log 'guard.lowdisk' @{ freePct=$free; min=$MinFreePct }
    TrimReleases 3
    CleanupStages $CleanupDays -useFolderTime -log
  }

  # 2) Build if files changed (anytime)
  $zip = BuildBundle $BundleFilter
  if (-not $zip) { $zip = (LatestBundle)?.FullName }

  # 3) Heavy stuff (verify / unpack) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â prefer night window
  $okToRunHeavy = InNightWindow $NightWindow
  if (-not $okToRunHeavy) {
    Log 'heavy.defer' @{ window=$NightWindow }
  } else {
    if ($zip) {
      TightenVerify $zip $Mode
      VerifyAndUnpack $zip $ApplyUnpack.IsPresent
    }
  }

  # 4) Routine housekeeping (lightweight)
  TrimReleases $KeepReleases
  CleanupStages $CleanupDays -useFolderTime -log

  Log 'agent.done' @{ freePct=DiskFreePct }

} finally {
  $mtx.ReleaseMutex() | Out-Null
  $mtx.Dispose()
}

