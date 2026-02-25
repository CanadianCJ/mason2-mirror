$Base = $env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base = Split-Path -Parent $PSCommandPath }
$rep  = Join-Path $Base "reports"; New-Item -ItemType Directory -Force $rep | Out-Null
$out  = Join-Path $rep "cpu_pressure.jsonl"
$pct  = $null
try {
  $c = (Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop).CounterSamples.CookedValue
  $pct = [math]::Round($c,2)
} catch { }
$rec = @{ ts=(Get-Date).ToString('s'); pct=$pct }
($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $out -Encoding utf8
