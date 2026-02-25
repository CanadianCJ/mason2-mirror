param([string]$Drive='C:')
$ErrorActionPreference='Stop'
$base="$env:MASON2_BASE"
$ctrl=Join-Path $base 'control'
New-Item -ItemType Directory -Force $ctrl | Out-Null

# threshold from env (default 10)
$minPct = [int]$env:MASON_DISK_MIN_FREE_PCT
if(-not $minPct){ $minPct = 10 }

# Normalize drive name for Get-PSDrive
$drv = ($Drive -replace ':$','')
$fs = Get-PSDrive -PSProvider FileSystem -Name $drv -ErrorAction Stop
$total = [double]($fs.Used + $fs.Free)
$freePct = if($total -le 0){ 100 } else { [math]::Floor(($fs.Free / $total) * 100) }

$flag = Join-Path $ctrl 'THROTTLE.on'
if($freePct -lt $minPct){ New-Item -ItemType File -Force $flag | Out-Null }
else{ if(Test-Path $flag){ Remove-Item $flag -Force } }

# breadcrumb
$rep = Join-Path $base 'reports'
New-Item -ItemType Directory -Force $rep | Out-Null
@{ts=(Get-Date).ToString('s'); kind='disk_guard'; free_pct=$freePct; min_pct=$minPct; flag=(Test-Path $flag)} |
  ConvertTo-Json -Compress | Add-Content (Join-Path $rep 'alerts.jsonl')
exit 0