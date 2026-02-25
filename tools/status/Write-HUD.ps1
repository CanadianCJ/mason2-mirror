param([int]$LoopSec=3)
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$hud = Join-Path $rep 'hud.json'
$stop= Join-Path $Base 'control\heartbeat.stop'
$start = Get-Date
while($true){
  $now = Get-Date
  $uptime = [int]($now - $start).TotalSeconds
  $ping = @{ ts=$now.ToString('s'); kind='hud'; alive=1; uptime_s=$uptime }
  ($ping | ConvertTo-Json -Compress) | Set-Content -Encoding UTF8 $hud
  if(Test-Path $stop){ Remove-Item $stop -Force -ErrorAction SilentlyContinue; break }
  Start-Sleep -Seconds $LoopSec
}
