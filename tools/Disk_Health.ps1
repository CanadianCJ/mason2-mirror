# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

$logDir = Join-Path $Base 'logs\telemetry'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$csv   = Join-Path $logDir 'disk_health.csv'
$jsonl = Join-Path $logDir 'disk_health.jsonl'

function Get-FreePct {
  param([string]$Path)
  $root = [IO.Path]::GetPathRoot($Path).TrimEnd('\')
  $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
  if(-not $d -or -not $d.Size){ return $null }
  [math]::Round(($d.FreeSpace * 100.0 / $d.Size), 2)
}

$pct = Get-FreePct -Path $Base
$now = Get-Date

if(!(Test-Path $csv)){ "timestamp,free_pct" | Out-File -FilePath $csv -Encoding UTF8 }
("{0:s},{1}" -f $now, $(if($null -eq $pct){''} else {$pct})) | Add-Content -Path $csv -Encoding UTF8

$record = [pscustomobject]@{ ts = $now.ToString('s'); free_pct = $pct }
($record | ConvertTo-Json -Compress) | Add-Content -Path $jsonl -Encoding UTF8

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

$logDir = Join-Path $Base 'logs\telemetry'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$csv   = Join-Path $logDir 'disk_health.csv'
$jsonl = Join-Path $logDir 'disk_health.jsonl'

function Get-FreePct {
  param([string]$Path)
  $root = [IO.Path]::GetPathRoot($Path).TrimEnd('\')
  $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
  if(-not $d -or -not $d.Size){ return $null }
  [math]::Round(($d.FreeSpace * 100.0 / $d.Size), 2)
}

$pct = Get-FreePct -Path $Base
$now = Get-Date

if(!(Test-Path $csv)){ "timestamp,free_pct" | Out-File -FilePath $csv -Encoding UTF8 }
("{0:s},{1}" -f $now, $(if($null -eq $pct){''} else {$pct})) | Add-Content -Path $csv -Encoding UTF8

$record = [pscustomobject]@{ ts = $now.ToString('s'); free_pct = $pct }
($record | ConvertTo-Json -Compress) | Add-Content -Path $jsonl -Encoding UTF8

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

$logDir = Join-Path $Base 'logs\telemetry'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$csv   = Join-Path $logDir 'disk_health.csv'
$jsonl = Join-Path $logDir 'disk_health.jsonl'

function Get-FreePct {
  param([string]$Path)
  $root = [IO.Path]::GetPathRoot($Path).TrimEnd('\')
  $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
  if(-not $d -or -not $d.Size){ return $null }
  [math]::Round(($d.FreeSpace * 100.0 / $d.Size), 2)
}

$pct = Get-FreePct -Path $Base
$now = Get-Date

if(!(Test-Path $csv)){ "timestamp,free_pct" | Out-File -FilePath $csv -Encoding UTF8 }
("{0:s},{1}" -f $now, $(if($null -eq $pct){''} else {$pct})) | Add-Content -Path $csv -Encoding UTF8

$record = [pscustomobject]@{ ts = $now.ToString('s'); free_pct = $pct }
($record | ConvertTo-Json -Compress) | Add-Content -Path $jsonl -Encoding UTF8

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

$logDir = Join-Path $Base 'logs\telemetry'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$csv   = Join-Path $logDir 'disk_health.csv'
$jsonl = Join-Path $logDir 'disk_health.jsonl'

function Get-FreePct {
  param([string]$Path)
  $root = [IO.Path]::GetPathRoot($Path).TrimEnd('\')
  $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
  if(-not $d -or -not $d.Size){ return $null }
  [math]::Round(($d.FreeSpace * 100.0 / $d.Size), 2)
}

$pct = Get-FreePct -Path $Base
$now = Get-Date

if(!(Test-Path $csv)){ "timestamp,free_pct" | Out-File -FilePath $csv -Encoding UTF8 }
("{0:s},{1}" -f $now, $(if($null -eq $pct){''} else {$pct})) | Add-Content -Path $csv -Encoding UTF8

$record = [pscustomobject]@{ ts = $now.ToString('s'); free_pct = $pct }
($record | ConvertTo-Json -Compress) | Add-Content -Path $jsonl -Encoding UTF8

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

$logDir = Join-Path $Base 'logs\telemetry'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$csv   = Join-Path $logDir 'disk_health.csv'
$jsonl = Join-Path $logDir 'disk_health.jsonl'

function Get-FreePct {
  param([string]$Path)
  $root = [IO.Path]::GetPathRoot($Path).TrimEnd('\')
  $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
  if(-not $d -or -not $d.Size){ return $null }
  [math]::Round(($d.FreeSpace * 100.0 / $d.Size), 2)
}

$pct = Get-FreePct -Path $Base
$now = Get-Date

if(!(Test-Path $csv)){ "timestamp,free_pct" | Out-File -FilePath $csv -Encoding UTF8 }
("{0:s},{1}" -f $now, $(if($null -eq $pct){''} else {$pct})) | Add-Content -Path $csv -Encoding UTF8

$record = [pscustomobject]@{ ts = $now.ToString('s'); free_pct = $pct }
($record | ConvertTo-Json -Compress) | Add-Content -Path $jsonl -Encoding UTF8

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

$logDir = Join-Path $Base 'logs\telemetry'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$csv   = Join-Path $logDir 'disk_health.csv'
$jsonl = Join-Path $logDir 'disk_health.jsonl'

function Get-FreePct {
  param([string]$Path)
  $root = [IO.Path]::GetPathRoot($Path).TrimEnd('\')
  $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
  if(-not $d -or -not $d.Size){ return $null }
  [math]::Round(($d.FreeSpace * 100.0 / $d.Size), 2)
}

$pct = Get-FreePct -Path $Base
$now = Get-Date

if(!(Test-Path $csv)){ "timestamp,free_pct" | Out-File -FilePath $csv -Encoding UTF8 }
("{0:s},{1}" -f $now, $(if($null -eq $pct){''} else {$pct})) | Add-Content -Path $csv -Encoding UTF8

$record = [pscustomobject]@{ ts = $now.ToString('s'); free_pct = $pct }
($record | ConvertTo-Json -Compress) | Add-Content -Path $jsonl -Encoding UTF8

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

$logDir = Join-Path $Base 'logs\telemetry'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$csv   = Join-Path $logDir 'disk_health.csv'
$jsonl = Join-Path $logDir 'disk_health.jsonl'

function Get-FreePct {
  param([string]$Path)
  $root = [IO.Path]::GetPathRoot($Path).TrimEnd('\')
  $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
  if(-not $d -or -not $d.Size){ return $null }
  [math]::Round(($d.FreeSpace * 100.0 / $d.Size), 2)
}

$pct = Get-FreePct -Path $Base
$now = Get-Date

if(!(Test-Path $csv)){ "timestamp,free_pct" | Out-File -FilePath $csv -Encoding UTF8 }
("{0:s},{1}" -f $now, $(if($null -eq $pct){''} else {$pct})) | Add-Content -Path $csv -Encoding UTF8

$record = [pscustomobject]@{ ts = $now.ToString('s'); free_pct = $pct }
($record | ConvertTo-Json -Compress) | Add-Content -Path $jsonl -Encoding UTF8

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'

$logDir = Join-Path $Base 'logs\telemetry'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$csv   = Join-Path $logDir 'disk_health.csv'
$jsonl = Join-Path $logDir 'disk_health.jsonl'

function Get-FreePct {
  param([string]$Path)
  $root = [IO.Path]::GetPathRoot($Path).TrimEnd('\')
  $d = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $root)
  if(-not $d -or -not $d.Size){ return $null }
  [math]::Round(($d.FreeSpace * 100.0 / $d.Size), 2)
}

$pct = Get-FreePct -Path $Base
$now = Get-Date

if(!(Test-Path $csv)){ "timestamp,free_pct" | Out-File -FilePath $csv -Encoding UTF8 }
("{0:s},{1}" -f $now, $(if($null -eq $pct){''} else {$pct})) | Add-Content -Path $csv -Encoding UTF8

$record = [pscustomobject]@{ ts = $now.ToString('s'); free_pct = $pct }
($record | ConvertTo-Json -Compress) | Add-Content -Path $jsonl -Encoding UTF8

