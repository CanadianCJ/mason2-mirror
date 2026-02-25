param([int]$WindowMin=10)
$ErrorActionPreference='SilentlyContinue'
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$alerts = Join-Path $rep 'alerts.jsonl'
# budgets (minutes)
$map = @{
  'Mason-Heartbeat'          = 1
  'Mason-ModerationScan'     = 20
  'Mason-DashboardSnapshot'  = 3
  'Mason-DashboardExtras'    = 3
  'Mason-MetricsCsv'         = 5
  'Mason-DiskCsv'            = 15
}
function Append-JsonLine([string]$Path,[hashtable]$Obj){ $line = ($Obj | ConvertTo-Json -Compress); Add-Content -LiteralPath $Path -Encoding UTF8 $line }
$now = Get-Date
foreach($name in $map.Keys){
  try{
    $i = Get-ScheduledTaskInfo -TaskName $name -ErrorAction Stop
    if($i.LastRunTime){
      $ageMin = [int]($now - $i.LastRunTime).TotalMinutes
      $budget = [int]$map[$name]
      if($ageMin -gt $budget){
        Append-JsonLine $alerts @{ ts=$now.ToString('s'); kind='alert'; subtype='schedule_drift'; source=$name; message=("Last run {0} min ago; budget {1} min" -f $ageMin,$budget) }
      }
    }else{
      Append-JsonLine $alerts @{ ts=$now.ToString('s'); kind='alert'; subtype='schedule_drift'; source=$name; message='Never ran' }
    }
  }catch{
    # Task missing = drift candidate too
    Append-JsonLine $alerts @{ ts=$now.ToString('s'); kind='alert'; subtype='schedule_drift'; source=$name; message='Task not found' }
  }
}
