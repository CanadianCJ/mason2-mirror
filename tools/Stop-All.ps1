$ErrorActionPreference='SilentlyContinue'
$tasks = @(
  'Mason-7001',
  'Mason-NodeAgent',
  'Mason-Heartbeat',
  'Mason-HealthIndex',
  'Mason-Watchdog',
  'Mason-Mon-Net',
  'Mason-Mon-Time',
  'Mason-Mon-CPU',
  'Mason-Mon-MEM',
  'Mason-Mon-Disk',
  'Mason-LogRotate',
  'Mason-SweepTemp',
  'Mason-DailySnapshot'
) | Select-Object -Unique

foreach($n in $tasks){
  try{ Stop-ScheduledTask -TaskName $n }catch{}
}
"[ OK ] Stopped core Mason tasks."
