# Stamped: 2025-11-05T17:02:01
# Self-contained helpers (safe on PS 5.1)
function Write-JsonLineSafe {
  param([string]$Path, $Obj)
  try{
    if([string]::IsNullOrWhiteSpace($Path)){ return }
    $dir = Split-Path -Parent $Path
    if($dir -and -not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
      Out-File -FilePath $Path -Encoding UTF8 -Append
  }catch{
    # last-ditch fallback to a local file under reports\
    try{
      $base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
      $fb = Join-Path $base 'reports\_fallback.jsonl'
      ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
        Out-File -FilePath $fb -Encoding UTF8 -Append
    }catch{}
  }
}
if (-not (Get-Command -Name Get-DiskFreePct -ErrorAction SilentlyContinue)) {
  function Get-DiskFreePct([string]$TargetBase){
    try{
      $root = [IO.Path]::GetPathRoot($TargetBase).TrimEnd('\')
      $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
      if(-not $d -or -not $d.Size){ return $null }
      [math]::Round(($d.FreeSpace*100.0/$d.Size),2)
    }catch{ $null }
  }
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Self-contained helpers (safe on PS 5.1)
function Write-JsonLineSafe {
  param([string]$Path, $Obj)
  try{
    if([string]::IsNullOrWhiteSpace($Path)){ return }
    $dir = Split-Path -Parent $Path
    if($dir -and -not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
      Out-File -FilePath $Path -Encoding UTF8 -Append
  }catch{
    # last-ditch fallback to a local file under reports\
    try{
      $base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
      $fb = Join-Path $base 'reports\_fallback.jsonl'
      ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
        Out-File -FilePath $fb -Encoding UTF8 -Append
    }catch{}
  }
}
if (-not (Get-Command -Name Get-DiskFreePct -ErrorAction SilentlyContinue)) {
  function Get-DiskFreePct([string]$TargetBase){
    try{
      $root = [IO.Path]::GetPathRoot($TargetBase).TrimEnd('\')
      $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
      if(-not $d -or -not $d.Size){ return $null }
      [math]::Round(($d.FreeSpace*100.0/$d.Size),2)
    }catch{ $null }
  }
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Self-contained helpers (safe on PS 5.1)
function Write-JsonLineSafe {
  param([string]$Path, $Obj)
  try{
    if([string]::IsNullOrWhiteSpace($Path)){ return }
    $dir = Split-Path -Parent $Path
    if($dir -and -not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
      Out-File -FilePath $Path -Encoding UTF8 -Append
  }catch{
    # last-ditch fallback to a local file under reports\
    try{
      $base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
      $fb = Join-Path $base 'reports\_fallback.jsonl'
      ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
        Out-File -FilePath $fb -Encoding UTF8 -Append
    }catch{}
  }
}
if (-not (Get-Command -Name Get-DiskFreePct -ErrorAction SilentlyContinue)) {
  function Get-DiskFreePct([string]$TargetBase){
    try{
      $root = [IO.Path]::GetPathRoot($TargetBase).TrimEnd('\')
      $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
      if(-not $d -or -not $d.Size){ return $null }
      [math]::Round(($d.FreeSpace*100.0/$d.Size),2)
    }catch{ $null }
  }
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Self-contained helpers (safe on PS 5.1)
function Write-JsonLineSafe {
  param([string]$Path, $Obj)
  try{
    if([string]::IsNullOrWhiteSpace($Path)){ return }
    $dir = Split-Path -Parent $Path
    if($dir -and -not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
      Out-File -FilePath $Path -Encoding UTF8 -Append
  }catch{
    # last-ditch fallback to a local file under reports\
    try{
      $base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
      $fb = Join-Path $base 'reports\_fallback.jsonl'
      ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
        Out-File -FilePath $fb -Encoding UTF8 -Append
    }catch{}
  }
}
if (-not (Get-Command -Name Get-DiskFreePct -ErrorAction SilentlyContinue)) {
  function Get-DiskFreePct([string]$TargetBase){
    try{
      $root = [IO.Path]::GetPathRoot($TargetBase).TrimEnd('\')
      $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
      if(-not $d -or -not $d.Size){ return $null }
      [math]::Round(($d.FreeSpace*100.0/$d.Size),2)
    }catch{ $null }
  }
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Self-contained helpers (safe on PS 5.1)
function Write-JsonLineSafe {
  param([string]$Path, $Obj)
  try{
    if([string]::IsNullOrWhiteSpace($Path)){ return }
    $dir = Split-Path -Parent $Path
    if($dir -and -not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
      Out-File -FilePath $Path -Encoding UTF8 -Append
  }catch{
    # last-ditch fallback to a local file under reports\
    try{
      $base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
      $fb = Join-Path $base 'reports\_fallback.jsonl'
      ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
        Out-File -FilePath $fb -Encoding UTF8 -Append
    }catch{}
  }
}
if (-not (Get-Command -Name Get-DiskFreePct -ErrorAction SilentlyContinue)) {
  function Get-DiskFreePct([string]$TargetBase){
    try{
      $root = [IO.Path]::GetPathRoot($TargetBase).TrimEnd('\')
      $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
      if(-not $d -or -not $d.Size){ return $null }
      [math]::Round(($d.FreeSpace*100.0/$d.Size),2)
    }catch{ $null }
  }
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Self-contained helpers (safe on PS 5.1)
function Write-JsonLineSafe {
  param([string]$Path, $Obj)
  try{
    if([string]::IsNullOrWhiteSpace($Path)){ return }
    $dir = Split-Path -Parent $Path
    if($dir -and -not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
      Out-File -FilePath $Path -Encoding UTF8 -Append
  }catch{
    # last-ditch fallback to a local file under reports\
    try{
      $base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
      $fb = Join-Path $base 'reports\_fallback.jsonl'
      ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
        Out-File -FilePath $fb -Encoding UTF8 -Append
    }catch{}
  }
}
if (-not (Get-Command -Name Get-DiskFreePct -ErrorAction SilentlyContinue)) {
  function Get-DiskFreePct([string]$TargetBase){
    try{
      $root = [IO.Path]::GetPathRoot($TargetBase).TrimEnd('\')
      $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
      if(-not $d -or -not $d.Size){ return $null }
      [math]::Round(($d.FreeSpace*100.0/$d.Size),2)
    }catch{ $null }
  }
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Self-contained helpers (safe on PS 5.1)
function Write-JsonLineSafe {
  param([string]$Path, $Obj)
  try{
    if([string]::IsNullOrWhiteSpace($Path)){ return }
    $dir = Split-Path -Parent $Path
    if($dir -and -not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
      Out-File -FilePath $Path -Encoding UTF8 -Append
  }catch{
    # last-ditch fallback to a local file under reports\
    try{
      $base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
      $fb = Join-Path $base 'reports\_fallback.jsonl'
      ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
        Out-File -FilePath $fb -Encoding UTF8 -Append
    }catch{}
  }
}
if (-not (Get-Command -Name Get-DiskFreePct -ErrorAction SilentlyContinue)) {
  function Get-DiskFreePct([string]$TargetBase){
    try{
      $root = [IO.Path]::GetPathRoot($TargetBase).TrimEnd('\')
      $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
      if(-not $d -or -not $d.Size){ return $null }
      [math]::Round(($d.FreeSpace*100.0/$d.Size),2)
    }catch{ $null }
  }
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Self-contained helpers (safe on PS 5.1)
function Write-JsonLineSafe {
  param([string]$Path, $Obj)
  try{
    if([string]::IsNullOrWhiteSpace($Path)){ return }
    $dir = Split-Path -Parent $Path
    if($dir -and -not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
      Out-File -FilePath $Path -Encoding UTF8 -Append
  }catch{
    # last-ditch fallback to a local file under reports\
    try{
      $base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
      $fb = Join-Path $base 'reports\_fallback.jsonl'
      ($Obj | ConvertTo-Json -Depth 6 -Compress) + [Environment]::NewLine |
        Out-File -FilePath $fb -Encoding UTF8 -Append
    }catch{}
  }
}
if (-not (Get-Command -Name Get-DiskFreePct -ErrorAction SilentlyContinue)) {
  function Get-DiskFreePct([string]$TargetBase){
    try{
      $root = [IO.Path]::GetPathRoot($TargetBase).TrimEnd('\')
      $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
      if(-not $d -or -not $d.Size){ return $null }
      [math]::Round(($d.FreeSpace*100.0/$d.Size),2)
    }catch{ $null }
  }
}

