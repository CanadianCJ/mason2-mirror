param()
$ErrorActionPreference = "Stop"

function Normalize-PwshArgs([string]$arg) {
  $out = $arg
  if ($out -notmatch '(?i)-NoProfile')            { $out = "-NoProfile $out" }
  if ($out -notmatch '(?i)-ExecutionPolicy\s+\w+') { $out = "-ExecutionPolicy Bypass $out" }
  if ($out -notmatch '(?i)-WindowStyle\s+Hidden')  { $out = "-WindowStyle Hidden $out" }
  return $out
}

$tasks = Get-ScheduledTask -TaskName 'Mason-*' -ErrorAction SilentlyContinue
if (-not $tasks) {
  # Manual run with no tasks? treat as success.
  if ($env:USERNAME -eq 'SYSTEM') { exit 0 } else { return }
}

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings  = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew

foreach ($t in $tasks) {
  try {
    if (-not $t.Actions -or $t.Actions.Count -lt 1) { continue }
    $name = $t.TaskName
    $desc = $t.Description
    $trg  = $t.Triggers
    $a0   = $t.Actions[0]
    $exe  = $a0.Execute
    $arg  = [string]$a0.Arguments
    $wd   = $a0.WorkingDirectory

    $newExe = $exe
    $newArg = $arg
    if ($exe -match '(?i)(powershell|pwsh)\.exe$') { $newArg = Normalize-PwshArgs $newArg }

    $action = New-ScheduledTaskAction -Execute $newExe -Argument $newArg
    if ($wd) { $action.WorkingDirectory = $wd }

    Register-ScheduledTask -TaskName $name -Action $action -Trigger $trg -Principal $principal -Settings $settings -Description $desc -Force | Out-Null
  } catch {
    # continue
  }
}

# If running under SYSTEM (scheduler), exit 0; if manual, just return
if ($env:USERNAME -eq 'SYSTEM') { exit 0 } else { return }