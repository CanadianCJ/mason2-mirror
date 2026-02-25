$Base = $env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base = Split-Path -Parent $PSCommandPath }
$rep  = Join-Path $Base 'reports'
New-Item -ItemType Directory -Force $rep | Out-Null
$out  = Join-Path $rep 'heartbeat.jsonl'

$rec = @{ ts=(Get-Date).ToString('s'); kind='heartbeat'; ver='1' }
($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $out -Encoding utf8
