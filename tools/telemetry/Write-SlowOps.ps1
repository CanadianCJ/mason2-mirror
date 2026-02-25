param(
  [int]$ThresholdMs = 500,
  [int]$WindowLines = 2000
)
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$src = Join-Path $rep 'http7001.jsonl'
$sum = Join-Path $rep 'latency_summary.jsonl'
$slo = Join-Path $rep 'slowops.jsonl'
if(-not (Test-Path $src)){ return }

# read tail
$chunk = Get-Content -LiteralPath $src -Tail $WindowLines -ErrorAction SilentlyContinue
$recs = @()
foreach($line in $chunk){
  $o=$null; try{ $o = $line | ConvertFrom-Json }catch{}
  if($o -and $o.kind -eq 'http7001' -and $o.ms -ne $null -and $o.status -ne $null){ $recs += $o }
}

if($recs.Count -gt 0){
  $ms = $recs | ForEach-Object { [int]$_.ms }
  $msSorted = $ms | Sort-Object
  function pct($arr,$p){ if($arr.Count -eq 0){return $null}; $idx=[math]::Floor(($p/100)*($arr.Count-1)); return $arr[$idx] }
  $p50 = pct $msSorted 50
  $p95 = pct $msSorted 95
  $p99 = pct $msSorted 99
  $avg = [int]([math]::Round(($ms | Measure-Object -Average).Average))
  (@{ ts=(Get-Date).ToString('s'); kind='latency_summary'; count=$recs.Count; p50=$p50; p95=$p95; p99=$p99; avg=$avg; thresh=$ThresholdMs } |
    ConvertTo-Json -Compress) | Add-Content -LiteralPath $sum -Encoding UTF8

  $slow = $recs | Where-Object { $_.ms -ge $ThresholdMs } | Sort-Object ms -Descending | Select-Object -First 25
  foreach($s in $slow){
    (@{ ts=(Get-Date).ToString('s'); kind='slowop'; path=$s.path; status=$s.status; ms=[int]$s.ms; corr=$s.corr } |
      ConvertTo-Json -Compress) | Add-Content -LiteralPath $slo -Encoding UTF8
  }
}
