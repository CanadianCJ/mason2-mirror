param([int]$WindowMin = 120)
$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base = Split-Path -Parent $PSCommandPath }
$rep = Join-Path $Base 'reports'
if(-not (Test-Path $rep)){ New-Item -ItemType Directory -Force $rep | Out-Null }
$out = Join-Path $rep 'dashboard.json'

function Read-Jsonl { param([string]$path,[int]$tail=800)
  if(-not (Test-Path $path)){ return @() }
  Get-Content -LiteralPath $path -Tail $tail |
    ForEach-Object { try{ $_ | ConvertFrom-Json }catch{} } |
    Where-Object { $_ }
}
function Last-CsvRow { param([string]$path,[string]$header)
  if(-not (Test-Path $path)){ return $null }
  $line = Get-Content -LiteralPath $path -Tail 1
  if(-not $line -or $line -match '^ts,'){ return $null }
  return ($header + "`n" + $line) | ConvertFrom-Csv
}

try{
  $hud=$null; $metrics=$null; $disk=$null
  $hudFile    = Join-Path $rep 'hud.json'
  $alertsFile = Join-Path $rep 'alerts.jsonl'
  $metricsCsv = Join-Path $rep 'metrics.csv'
  $diskCsv    = Join-Path $rep 'disk.csv'
  $since = (Get-Date).AddMinutes(-$WindowMin)

  if(Test-Path $hudFile){ $hud = Get-Content -LiteralPath $hudFile -Tail 1 | ConvertFrom-Json }

  $metricsHdr = 'ts,cpu_pct,mem_free_pct,mem_used_gb,mem_free_gb,mem_total_gb,drive,drive_free_pct,drive_used_gb,drive_free_gb,drive_total_gb'
  $metrics = Last-CsvRow $metricsCsv $metricsHdr

  if(Test-Path $diskCsv){
    $diskHdr = (Get-Content -LiteralPath $diskCsv -TotalCount 1)
    if($diskHdr){ $disk = Last-CsvRow $diskCsv $diskHdr }
  }

  $al = Read-Jsonl $alertsFile 800 | Where-Object { $_.kind -eq 'alert' -and ([datetime]$_.ts) -ge $since }
  $counts = @{
    schedule_drift = ($al | Where-Object { $_.subtype -eq 'schedule_drift' } | Measure-Object).Count
    net_down       = ($al | Where-Object { $_.subtype -eq 'net_down' }       | Measure-Object).Count
    time_skew      = ($al | Where-Object { $_.subtype -eq 'time_skew' }      | Measure-Object).Count
    silence        = ($al | Where-Object { $_.subtype -eq 'silence' }        | Measure-Object).Count
    sensitive_data = ($al | Where-Object { $_.subtype -eq 'sensitive_data' } | Measure-Object).Count
  }

  $taskNames = @(
    'Mason-Heartbeat','Mason-ModerationScan','Mason-MetricsCsv','Mason-Mon-Net','Mason-Mon-Time','Mason-DiskCsv',
    'Mason-Alert-Silence','Mason-Alert-ErrorRate','Mason-Alert-ScheduleDrift',
    'Mason-LogRotate','Mason-LogRotate-HTTP','Mason-LogRotate-Alerts','Mason-SweepTemp','Mason-DashboardSnapshot'
  )

  $tasks = foreach($n in $taskNames){
    try{
      $i = Get-ScheduledTaskInfo -TaskName $n -ErrorAction Stop
      [pscustomobject]@{ name=$n; last=$i.LastRunTime; next=$i.NextRunTime; last_result=$i.LastTaskResult }
    }catch{}
  }

  # PS 5.1-safe date normalization (no ?:)
  $taskOut = @(
    $tasks | Sort-Object name | ForEach-Object {
      $lastStr = $null; $nextStr = $null
      if ($_.last) { try { $lastStr = ($_.last).ToString('s') } catch {} }
      if ($_.next) { try { $nextStr = ($_.next).ToString('s') } catch {} }
      @{ name = $_.name; last = $lastStr; next = $nextStr; last_result = $_.last_result }
    }
  )

  $doc = [ordered]@{
    ts=(Get-Date).ToString('s')
    window_min=$WindowMin
    hud=$hud
    metrics=$metrics
    disk=$disk
    alert_counts=$counts
    tasks = $taskOut
  }

  ($doc | ConvertTo-Json -Depth 6) | Set-Content -Encoding UTF8 -Force $out
  Write-Output $out
}
catch{
  @{ ts=(Get-Date).ToString('s'); error=$_.ToString() } |
    ConvertTo-Json | Set-Content -Encoding UTF8 -Force $out
  Write-Output $out
}
# ---- Force BOM-less UTF-8 (post-write) ----
try {
  $utf8NoBOM = New-Object System.Text.UTF8Encoding($false)
  if (Test-Path $out) {
    $txt = Get-Content -LiteralPath $out -Raw
    [IO.File]::WriteAllText($out, $txt, $utf8NoBOM)
  }
} catch {}
