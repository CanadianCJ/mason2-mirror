param([int]$RunSeconds=900)

Import-Module (Join-Path $env:MASON2_BASE 'lib\Mason.Log.psm1') -Force
$until = (Get-Date).AddSeconds($RunSeconds)
$failCount = 0

while((Get-Date) -lt $until){
  $ok = $false
  try {
    $tcp = Get-NetTCPConnection -State Listen -LocalPort 7001 -ErrorAction SilentlyContinue
    if($tcp){
      try{
        $r = iwr -UseBasicParsing -Proxy $null -TimeoutSec 3 http://127.0.0.1:7001/healthz
        if($r.Content -match '^ok'){ $ok=$true }
      } catch { $ok=$false }
    }
  } catch { $ok=$false }

  if($ok){
    Write-MasonLog -Component "nodeagent" -Level "INFO" -Data @{health="ok"}
    $failCount = 0
  } else {
    $failCount++
    Write-MasonLog -Component "nodeagent" -Level "WARN" -Data @{health="bad"; fails=$failCount}
    try {
      Restart-ScheduledTask -TaskName "Mason-7001" -ErrorAction SilentlyContinue | Out-Null
      Start-Sleep -Milliseconds 800
    } catch {}
    # backoff: 1s,2s,4s,8s up to 30s
    $sleep = [Math]::Min([int][Math]::Pow(2,$failCount), 30)
    Start-Sleep -Seconds $sleep
  }

  Start-Sleep -Seconds 5
}
