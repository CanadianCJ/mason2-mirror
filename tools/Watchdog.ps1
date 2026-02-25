$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base = Split-Path -Parent $PSCommandPath }
$rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$out = Join-Path $rep  'watchdog.jsonl'

function _log($o){ ($o|ConvertTo-Json -Compress) | Add-Content -LiteralPath $out -Encoding utf8 }

# 1) Port 7001 listening?
$listen = $false
try { $listen = [bool](Get-NetTCPConnection -State Listen -LocalPort 7001 -ErrorAction SilentlyContinue) } catch {}
if(-not $listen){
  try { Start-ScheduledTask -TaskName 'Mason-7001' -ErrorAction SilentlyContinue } catch {}
  _log @{ ts=(Get-Date).ToString('s'); kind='watchdog'; action='start_7001'; result=([string]$listen) }
}

# 2) Heartbeat fresh?
$hbPath = Join-Path $rep 'heartbeat.jsonl'
$fresh = $false
try{
  if(Test-Path $hbPath){
    $hb = Get-Content -LiteralPath $hbPath -Tail 1 | % { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1
    if($hb -and $hb.ts){
      $dt=[DateTime]::Parse($hb.ts); $fresh = ((Get-Date)-$dt).TotalMinutes -lt 3
    }
  }
}catch{}
if(-not $fresh){
  # give NodeAgent a nudge (non-fatal)
  try { Start-ScheduledTask -TaskName 'Mason-NodeAgent' -ErrorAction SilentlyContinue } catch {}
  _log @{ ts=(Get-Date).ToString('s'); kind='watchdog'; action='heartbeat_stale'; stale=(!$fresh) }
}
