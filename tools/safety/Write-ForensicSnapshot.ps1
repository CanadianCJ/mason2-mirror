param([string]$Reason='manual')
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$dir = Join-Path $Base 'forensics'
$stamp = Get-Date -Format yyyyMMdd_HHmmss
$out   = Join-Path $dir $stamp
New-Item -ItemType Directory -Force $out | Out-Null
function dump($name,$script){ try{ & $script | Out-File -Encoding UTF8 (Join-Path $out $name) }catch{} }
dump 'sysinfo.txt'         { systeminfo }
dump 'processes.txt'       { Get-Process | Sort-Object CPU -Descending | Select Name,Id,CPU,WS,StartTime -ErrorAction SilentlyContinue | Format-Table -AutoSize | Out-String }
dump 'tcp.txt'             { Get-NetTCPConnection -ErrorAction SilentlyContinue | Sort-Object LocalPort | Format-Table -AutoSize | Out-String }
dump 'tasks.txt'           { Get-ScheduledTask | Select TaskName,State,LastRunTime,NextRunTime -ErrorAction SilentlyContinue | Sort-Object TaskName | Format-Table -AutoSize | Out-String }
dump 'services.txt'        { Get-Service | Sort-Object Status,DisplayName | Format-Table -AutoSize | Out-String }
dump 'events_system.txt'   { Get-WinEvent -LogName System -MaxEvents 200 -ErrorAction SilentlyContinue | Format-Table TimeCreated,Id,LevelDisplayName,ProviderName,Message -AutoSize | Out-String }
dump 'events_app.txt'      { Get-WinEvent -LogName Application -MaxEvents 200 -ErrorAction SilentlyContinue | Format-Table TimeCreated,Id,LevelDisplayName,ProviderName,Message -AutoSize | Out-String }
try{ . (Join-Path $Base 'tools\common\Breadcrumb.ps1') 2>$null; Write-Breadcrumb -action 'forensic.snapshot' -meta @{ reason=$Reason; path=$out } }catch{}
Write-Output $out
