$ErrorActionPreference='SilentlyContinue'
Write-Host "== Tasks =="
Get-ScheduledTask | Where-Object { $_.TaskName -like 'Mason-*' } |
  Select-Object TaskName, State | Sort-Object TaskName | Format-Table -AutoSize

Write-Host "`n== Port 7001 =="
Get-NetTCPConnection -State Listen -LocalPort 7001 -ErrorAction SilentlyContinue | ft LocalAddress,LocalPort,State

Write-Host "`n== Health =="
try{ (Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 -Uri 'http://127.0.0.1:7001/metrics.json').Content }catch{ $_.Exception.Message }
