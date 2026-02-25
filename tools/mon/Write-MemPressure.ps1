$Base = $env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base = Split-Path -Parent $PSCommandPath }
$rep  = Join-Path $Base "reports"; New-Item -ItemType Directory -Force $rep | Out-Null
$out  = Join-Path $rep "mem_pressure.jsonl"
$pct  = $null
try {
  $c = (Get-Counter '\Memory\% Committed Bytes In Use' -ErrorAction Stop).CounterSamples.CookedValue
  $pct = [math]::Round($c,2)
} catch { }
$rec = @{ ts=(Get-Date).ToString('s'); pct=$pct }
($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $out -Encoding utf8
