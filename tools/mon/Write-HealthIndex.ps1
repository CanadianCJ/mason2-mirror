function _tailJson($path){
  if(Test-Path -LiteralPath $path){
    try{ return (Get-Content -LiteralPath $path -Tail 1 | % { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  $null
}

$Base = $env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base = Split-Path -Parent $PSCommandPath }
$rep  = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null

$net       = _tailJson (Join-Path $rep 'net_external.jsonl')
$cpu       = _tailJson (Join-Path $rep 'cpu_pressure.jsonl')
$mem       = _tailJson (Join-Path $rep 'mem_pressure.jsonl')
$timedrift = _tailJson (Join-Path $rep 'timedrift.jsonl')

# Component scores (0..100)
$scoreNet = 50
if($net){
  $up = ($net.dns -and $net.https)
  $base = if($up){100}else{20}
  $latPen = if($net.ms -gt 0){ [Math]::Min([int]($net.ms/10),30) } else { 0 }
  $scoreNet = [Math]::Max(0, $base - $latPen)
}

$scoreCPU = if($cpu -and $cpu.pct -ne $null){ [Math]::Max(0, 100 - [int]$cpu.pct) } else { 80 }
$scoreMEM = if($mem -and $mem.pct -ne $null){ [Math]::Max(0, 100 - [int]$mem.pct) } else { 80 }

$scoreTime = 80
if($timedrift -and $timedrift.offset_s -ne $null){
  $off = [Math]::Abs([double]$timedrift.offset_s)
  $scoreTime = if($off -le 1){100} elseif($off -le 5){80} else {60}
}

# Weights
$wNet=0.30; $wCPU=0.25; $wMEM=0.25; $wTime=0.20
$idx = [Math]::Round(($scoreNet*$wNet)+($scoreCPU*$wCPU)+($scoreMEM*$wMEM)+($scoreTime*$wTime))

$color = if($idx -ge 85){'GREEN'} elseif($idx -ge 70){'AMBER'} else {'RED'}

$out = Join-Path $rep 'health_index.jsonl'
$rec = @{
  ts   = (Get-Date).ToString('s')
  idx  = $idx
  band = $color
  parts = @{
    net=$scoreNet; cpu=$scoreCPU; mem=$scoreMEM; time=$scoreTime
  }
}
($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $out -Encoding utf8
