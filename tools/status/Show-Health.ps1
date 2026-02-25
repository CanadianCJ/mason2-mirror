param([int]$WindowMin=60)

$Base = $env:MASON2_BASE
if ([string]::IsNullOrWhiteSpace($Base)) { $Base = Split-Path -Parent $PSCommandPath }
$rep  = Join-Path $Base 'reports'
$alerts = Join-Path $rep 'alerts.jsonl'
$crumbs = Join-Path $rep 'breadcrumbs.jsonl'
$disk   = Join-Path $rep 'disk.csv'

$since = (Get-Date).AddMinutes(-$WindowMin)

$drifts = @()
if (Test-Path $alerts) {
  $drifts = Get-Content $alerts -Tail 500 |
    ForEach-Object { try{$_|ConvertFrom-Json}catch{} } |
    Where-Object { $_ -and $_.subtype -eq 'schedule_drift' -and ([datetime]$_.ts) -ge $since }
}

$diskRow = $null
if (Test-Path $disk) { $diskRow = Get-Content $disk -Tail 1 | ConvertFrom-Csv }

$tasks = 'Mason-Alert-Silence','Mason-Alert-ErrorRate','Mason-Alert-ScheduleDrift',
         'Mason-LogRotate','Mason-LogRotate-HTTP','Mason-LogRotate-Alerts',
         'Mason-SweepTemp','Mason-DiskCsv'

$status = foreach ($n in $tasks) {
  try {
    $i = Get-ScheduledTaskInfo -TaskName $n -ErrorAction Stop
    [pscustomobject]@{ Task=$n; LastRun=$i.LastRunTime; Next=$i.NextRunTime; LastResult=$i.LastTaskResult }
  } catch {}
}

Write-Host "=== Mason Health (last $WindowMin min) ==="
if ($diskRow) { "{0}: C: free {1}% ({2} GB free / {3} GB total)" -f $diskRow.ts,$diskRow.free_pct,$diskRow.free_gb,$diskRow.total_gb | Write-Host }
("{0} schedule_drift alerts" -f $drifts.Count) | Write-Host
$status | Sort-Object Task | Format-Table -AutoSize
