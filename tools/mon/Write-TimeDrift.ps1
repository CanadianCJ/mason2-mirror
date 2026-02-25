$Base = $env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base = Split-Path -Parent $PSCommandPath }
$rep  = Join-Path $Base "reports"; New-Item -ItemType Directory -Force $rep | Out-Null
$out  = Join-Path $rep "timedrift.jsonl"
$offset = $null
try {
  $txt = w32tm /query /status 2>$null
  if($txt -match 'Offset:\s*([+-]?[0-9]+\.[0-9]+)s'){
    $offset = [double]$Matches[1]
  }
} catch { }
$rec = @{ ts=(Get-Date).ToString('s'); offset_s=$offset }
($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $out -Encoding utf8
