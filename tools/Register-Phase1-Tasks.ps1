$ps = "powershell.exe"

function New-Task {
  param(
    [Parameter(Mandatory)] [string] $Name,
    [Parameter(Mandatory)] [string] $Execute,
    [Parameter(Mandatory)] [string] $Arguments,
    [Parameter(Mandatory)]          $Trigger
  )
  try { Unregister-ScheduledTask -TaskName $Name -Confirm:$false -ErrorAction SilentlyContinue } catch {}
  $act = New-ScheduledTaskAction -Execute $Execute -Argument $Arguments
  Register-ScheduledTask -TaskName $Name -Action $act -Trigger $Trigger -Description $Name -Force | Out-Null
  Write-Host "[ OK ] Task ready: $Name"
}

# ---- Triggers ----
# Logon (for NodeAgent)
$trgLogon = New-ScheduledTaskTrigger -AtLogOn

# 1-minute repeating
$start1m = (Get-Date).AddMinutes(1)
$trg1m = New-ScheduledTaskTrigger -Once -At $start1m `
  -RepetitionInterval (New-TimeSpan -Minutes 1) `
  -RepetitionDuration (New-TimeSpan -Days 3650)

# 5-minute repeating
$start5m = (Get-Date).AddMinutes(1)
$trg5m = New-ScheduledTaskTrigger -Once -At $start5m `
  -RepetitionInterval (New-TimeSpan -Minutes 5) `
  -RepetitionDuration (New-TimeSpan -Days 3650)

# Daily 03:30 / 03:40
$trgDaily0330 = New-ScheduledTaskTrigger -Daily -At 03:30
$trgDaily0340 = New-ScheduledTaskTrigger -Daily -At 03:40

# ---- Tasks ----
# NodeAgent (runs on logon for 30 mins, auto-relaunches next logon)
New-Task -Name "Mason-NodeAgent" -Execute $ps -Arguments `
  "-NoProfile -ExecutionPolicy Bypass -File `"$env:MASON2_BASE\tools\NodeAgent.ps1`" -RunSeconds 1800" `
  -Trigger $trgLogon

# Monitors
New-Task -Name "Mason-Mon-Net"  -Execute $ps -Arguments `
  "-NoProfile -ExecutionPolicy Bypass -File `"$env:MASON2_BASE\tools\mon\Write-NetExternal.ps1`"" `
  -Trigger $trg1m

New-Task -Name "Mason-Mon-Time" -Execute $ps -Arguments `
  "-NoProfile -ExecutionPolicy Bypass -File `"$env:MASON2_BASE\tools\mon\Write-TimeDrift.ps1`"" `
  -Trigger $trg5m

New-Task -Name "Mason-Mon-CPU"  -Execute $ps -Arguments `
  "-NoProfile -ExecutionPolicy Bypass -File `"$env:MASON2_BASE\tools\mon\Write-CpuPressure.ps1`"" `
  -Trigger $trg1m

New-Task -Name "Mason-Mon-MEM"  -Execute $ps -Arguments `
  "-NoProfile -ExecutionPolicy Bypass -File `"$env:MASON2_BASE\tools\mon\Write-MemPressure.ps1`"" `
  -Trigger $trg1m

# Disk health + daily snapshot
New-Task -Name "Mason-DiskHealth" -Execute $ps -Arguments `
  "-NoProfile -ExecutionPolicy Bypass -File `"$env:MASON2_BASE\tools\DiskHealth.ps1`"" `
  -Trigger $trgDaily0330

New-Task -Name "Mason-DailySnapshot" -Execute $ps -Arguments `
  "-NoProfile -ExecutionPolicy Bypass -File `"$env:MASON2_BASE\tools\Export-MasonBundle.ps1`"" `
  -Trigger $trgDaily0340

Write-Host "[ DONE ] Phase-1 scheduled tasks registered."
