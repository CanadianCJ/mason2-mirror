$want = @(
  'Mason-7001','Mason-NodeAgent',
  'Mason-Heartbeat','Mason-HealthIndex','Mason-Watchdog',
  'Mason-Mon-Net','Mason-Mon-Time','Mason-Mon-CPU','Mason-Mon-MEM','Mason-Mon-Disk',
  'Mason-LogRotate','Mason-SweepTemp','Mason-DailySnapshot','Mason-MetricsCsv'
) | Select-Object -Unique

$got = Get-ScheduledTask | Where-Object { $_.TaskName -like 'Mason-*' }
$rep = Join-Path $env:MASON2_BASE 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$out = Join-Path $rep 'tasks_verify.jsonl'

$summary = foreach($n in $want){
  $t = $got | Where-Object TaskName -EQ $n
  [pscustomobject]@{
    task = $n
    present = [bool]$t
    state   = if($t){ $t.State } else { $null }
    triggers= if($t){ $t.Triggers | ForEach-Object { $_.ToString() } } else { $null }
  }
}

# Print
$missing = $summary | Where-Object { -not $_.present }
if($missing){ Write-Warning ("Missing tasks:`n - " + ($missing.task -join "`n - ")) } else { Write-Host "[ OK ] All required tasks present." }

# Persist
foreach($row in $summary){
  (@{ ts=(Get-Date).ToString('s'); kind='tasks_verify'; row=$row } | ConvertTo-Json -Compress) |
    Add-Content -LiteralPath $out -Encoding UTF8
}
