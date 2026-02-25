param([int]$CsvHours=24)
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$csv = Join-Path $rep 'metrics.csv'
$lat = Join-Path $rep 'latency_summary.jsonl'
$errsPath = Join-Path $rep ("top_errors_{0}.json" -f (Get-Date -Format yyyyMMdd))

$cpu=$null;$mem=$null;$ms=$null;$up=$null
if(Test-Path $csv){
  $lines = Get-Content -LiteralPath $csv -ErrorAction SilentlyContinue
  $rows = @($lines | Select-Object -Skip 1)
  if($rows.Count -gt 0){
    $guessPerHour = 12  # ~5m cadence
    $take = [int]($CsvHours * $guessPerHour)
    $take = [math]::Min($rows.Count, [math]::Max(1,$take))
    $start = [math]::Max(0, $rows.Count - $take)
    $end   = $rows.Count - 1
    $slice = if($end -ge $start){ $rows[$start..$end] } else { @() }
    $cpu = @($slice | ForEach-Object { ($_ -split ',')[3] -as [double] })
    $mem = @($slice | ForEach-Object { ($_ -split ',')[4] -as [double] })
    $ms  = @($slice | ForEach-Object { ($_ -split ',')[5] -as [double] })
    $up  = @($slice | ForEach-Object { ($_ -split ',')[6] -as [int]    })
  }
}
function Stats($arr){
  if(-not $arr -or $arr.Count -eq 0){ return $null }
  [pscustomobject]@{
    min=($arr | Measure-Object -Minimum).Minimum
    max=($arr | Measure-Object -Maximum).Maximum
    avg=[math]::Round((($arr | Measure-Object -Average).Average),2)
  }
}
$cpuS = Stats $cpu; $memS = Stats $mem; $msS = Stats $ms
$upt  = if($up){ [math]::Round((($up | Measure-Object -Sum).Sum * 100.0) / $up.Count,2) } else { $null }

$latTail=$null
if(Test-Path $lat){ $latTail = Get-Content -LiteralPath $lat -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{} } }

$topRows = $null
if(Test-Path $errsPath){
  try{
    $errs = Get-Content -LiteralPath $errsPath -Raw | ConvertFrom-Json
    if($errs -and $errs.rows){ $topRows = $errs.rows }
  }catch{}
}

$out = @{
  ts = (Get-Date).ToString('s'); kind='daily_summary'
  cpu=$cpuS; mem=$memS; net_ms=$msS; uptime_pct=$upt
  latency = $latTail
  top_errors = $topRows
}
$dest = Join-Path $rep ("daily_summary_{0}.json" -f (Get-Date -Format yyyyMMdd))
$out | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 $dest
