# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function Get-Percentile($arr,[double]$p){
  if(-not $arr -or $arr.Count -eq 0){ return $null }
  $s = $arr | Sort-Object
  $n = $s.Count
  $rank = ($p/100.0)*($n-1)+1
  $k = [math]::Floor($rank); $d=$rank-$k
  if($k -le 1){ return $s[0] }
  if($k -ge $n){ return $s[$n-1] }
  return [int]([math]::Round($s[$k-1]*(1-$d) + $s[$k]*$d))
}
$log = Join-Path $Base 'reports\exec_log.jsonl'
$today = (Get-Date).ToString('yyyy-MM-dd')
$ms = @()
if(Test-Path $log){
  Select-String -Path $log -SimpleMatch $today -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json; if($j.ms){ $ms += [int]$j.ms } }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\latency_buckets.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='latency_buckets'; day=$today; p50=(Get-Percentile $ms 50); p95=(Get-Percentile $ms 95); p99=(Get-Percentile $ms 99); n=$ms.Count
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function Get-Percentile($arr,[double]$p){
  if(-not $arr -or $arr.Count -eq 0){ return $null }
  $s = $arr | Sort-Object
  $n = $s.Count
  $rank = ($p/100.0)*($n-1)+1
  $k = [math]::Floor($rank); $d=$rank-$k
  if($k -le 1){ return $s[0] }
  if($k -ge $n){ return $s[$n-1] }
  return [int]([math]::Round($s[$k-1]*(1-$d) + $s[$k]*$d))
}
$log = Join-Path $Base 'reports\exec_log.jsonl'
$today = (Get-Date).ToString('yyyy-MM-dd')
$ms = @()
if(Test-Path $log){
  Select-String -Path $log -SimpleMatch $today -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json; if($j.ms){ $ms += [int]$j.ms } }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\latency_buckets.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='latency_buckets'; day=$today; p50=(Get-Percentile $ms 50); p95=(Get-Percentile $ms 95); p99=(Get-Percentile $ms 99); n=$ms.Count
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function Get-Percentile($arr,[double]$p){
  if(-not $arr -or $arr.Count -eq 0){ return $null }
  $s = $arr | Sort-Object
  $n = $s.Count
  $rank = ($p/100.0)*($n-1)+1
  $k = [math]::Floor($rank); $d=$rank-$k
  if($k -le 1){ return $s[0] }
  if($k -ge $n){ return $s[$n-1] }
  return [int]([math]::Round($s[$k-1]*(1-$d) + $s[$k]*$d))
}
$log = Join-Path $Base 'reports\exec_log.jsonl'
$today = (Get-Date).ToString('yyyy-MM-dd')
$ms = @()
if(Test-Path $log){
  Select-String -Path $log -SimpleMatch $today -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json; if($j.ms){ $ms += [int]$j.ms } }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\latency_buckets.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='latency_buckets'; day=$today; p50=(Get-Percentile $ms 50); p95=(Get-Percentile $ms 95); p99=(Get-Percentile $ms 99); n=$ms.Count
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function Get-Percentile($arr,[double]$p){
  if(-not $arr -or $arr.Count -eq 0){ return $null }
  $s = $arr | Sort-Object
  $n = $s.Count
  $rank = ($p/100.0)*($n-1)+1
  $k = [math]::Floor($rank); $d=$rank-$k
  if($k -le 1){ return $s[0] }
  if($k -ge $n){ return $s[$n-1] }
  return [int]([math]::Round($s[$k-1]*(1-$d) + $s[$k]*$d))
}
$log = Join-Path $Base 'reports\exec_log.jsonl'
$today = (Get-Date).ToString('yyyy-MM-dd')
$ms = @()
if(Test-Path $log){
  Select-String -Path $log -SimpleMatch $today -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json; if($j.ms){ $ms += [int]$j.ms } }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\latency_buckets.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='latency_buckets'; day=$today; p50=(Get-Percentile $ms 50); p95=(Get-Percentile $ms 95); p99=(Get-Percentile $ms 99); n=$ms.Count
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function Get-Percentile($arr,[double]$p){
  if(-not $arr -or $arr.Count -eq 0){ return $null }
  $s = $arr | Sort-Object
  $n = $s.Count
  $rank = ($p/100.0)*($n-1)+1
  $k = [math]::Floor($rank); $d=$rank-$k
  if($k -le 1){ return $s[0] }
  if($k -ge $n){ return $s[$n-1] }
  return [int]([math]::Round($s[$k-1]*(1-$d) + $s[$k]*$d))
}
$log = Join-Path $Base 'reports\exec_log.jsonl'
$today = (Get-Date).ToString('yyyy-MM-dd')
$ms = @()
if(Test-Path $log){
  Select-String -Path $log -SimpleMatch $today -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json; if($j.ms){ $ms += [int]$j.ms } }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\latency_buckets.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='latency_buckets'; day=$today; p50=(Get-Percentile $ms 50); p95=(Get-Percentile $ms 95); p99=(Get-Percentile $ms 99); n=$ms.Count
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function Get-Percentile($arr,[double]$p){
  if(-not $arr -or $arr.Count -eq 0){ return $null }
  $s = $arr | Sort-Object
  $n = $s.Count
  $rank = ($p/100.0)*($n-1)+1
  $k = [math]::Floor($rank); $d=$rank-$k
  if($k -le 1){ return $s[0] }
  if($k -ge $n){ return $s[$n-1] }
  return [int]([math]::Round($s[$k-1]*(1-$d) + $s[$k]*$d))
}
$log = Join-Path $Base 'reports\exec_log.jsonl'
$today = (Get-Date).ToString('yyyy-MM-dd')
$ms = @()
if(Test-Path $log){
  Select-String -Path $log -SimpleMatch $today -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json; if($j.ms){ $ms += [int]$j.ms } }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\latency_buckets.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='latency_buckets'; day=$today; p50=(Get-Percentile $ms 50); p95=(Get-Percentile $ms 95); p99=(Get-Percentile $ms 99); n=$ms.Count
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function Get-Percentile($arr,[double]$p){
  if(-not $arr -or $arr.Count -eq 0){ return $null }
  $s = $arr | Sort-Object
  $n = $s.Count
  $rank = ($p/100.0)*($n-1)+1
  $k = [math]::Floor($rank); $d=$rank-$k
  if($k -le 1){ return $s[0] }
  if($k -ge $n){ return $s[$n-1] }
  return [int]([math]::Round($s[$k-1]*(1-$d) + $s[$k]*$d))
}
$log = Join-Path $Base 'reports\exec_log.jsonl'
$today = (Get-Date).ToString('yyyy-MM-dd')
$ms = @()
if(Test-Path $log){
  Select-String -Path $log -SimpleMatch $today -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json; if($j.ms){ $ms += [int]$j.ms } }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\latency_buckets.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='latency_buckets'; day=$today; p50=(Get-Percentile $ms 50); p95=(Get-Percentile $ms 95); p99=(Get-Percentile $ms 99); n=$ms.Count
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function Get-Percentile($arr,[double]$p){
  if(-not $arr -or $arr.Count -eq 0){ return $null }
  $s = $arr | Sort-Object
  $n = $s.Count
  $rank = ($p/100.0)*($n-1)+1
  $k = [math]::Floor($rank); $d=$rank-$k
  if($k -le 1){ return $s[0] }
  if($k -ge $n){ return $s[$n-1] }
  return [int]([math]::Round($s[$k-1]*(1-$d) + $s[$k]*$d))
}
$log = Join-Path $Base 'reports\exec_log.jsonl'
$today = (Get-Date).ToString('yyyy-MM-dd')
$ms = @()
if(Test-Path $log){
  Select-String -Path $log -SimpleMatch $today -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $j = $_.ToString() | ConvertFrom-Json; if($j.ms){ $ms += [int]$j.ms } }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\latency_buckets.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='latency_buckets'; day=$today; p50=(Get-Percentile $ms 50); p95=(Get-Percentile $ms 95); p99=(Get-Percentile $ms 99); n=$ms.Count
}

