param(
  [string]$Drive = "C:",
  [int]$CpuSamples = 3,
  [int]$CpuSampleSec = 1
)

$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base = Split-Path -Parent $PSCommandPath }
$rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$csv = Join-Path $rep 'metrics.csv'

function Ensure-Header {
  if(-not (Test-Path $csv) -or (Get-Content $csv -TotalCount 1) -notmatch '^ts,cpu_pct,mem_free_pct,mem_used_gb,mem_free_gb,mem_total_gb,drive,drive_free_pct,drive_used_gb,drive_free_gb,drive_total_gb$'){
    'ts,cpu_pct,mem_free_pct,mem_used_gb,mem_free_gb,mem_total_gb,drive,drive_free_pct,drive_used_gb,drive_free_gb,drive_total_gb' | Set-Content -Encoding UTF8 $csv
  }
}

try{
  # CPU (avg over N samples)
  $cpuVals = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval $CpuSampleSec -MaxSamples $CpuSamples).CounterSamples | Select-Object -ExpandProperty CookedValue
  $cpu = [math]::Round( ($cpuVals | Measure-Object -Average).Average, 2 )

  # Memory (GB + % free)
  $os = Get-CimInstance Win32_OperatingSystem
  $totGB  = [math]::Round( ([double]$os.TotalVisibleMemorySize)/1024/1024, 2 )
  $freeGB = [math]::Round( ([double]$os.FreePhysicalMemory)/1024/1024, 2 )
  $usedGB = [math]::Round($totGB - $freeGB, 2)
  $memFreePct = if($totGB -gt 0){ [math]::Round(($freeGB/$totGB)*100, 2) } else { $null }

  # Drive snapshot (optional)
  $driveOut = '','', '', '', ''
  try{
    $dl = $Drive.TrimEnd(':')
    $vol = Get-Volume -DriveLetter $dl -ErrorAction Stop
    $dTot = [math]::Round($vol.Size/1GB,2)
    $dFree= [math]::Round($vol.SizeRemaining/1GB,2)
    $dUsed= [math]::Round($dTot - $dFree,2)
    $dPct = if($dTot -gt 0){ [math]::Round(($dFree/$dTot)*100,2) } else { $null }
    $driveOut = @($Drive.ToUpper(), $dPct, $dUsed, $dFree, $dTot)
  }catch{}

  Ensure-Header
  $row = '{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}' -f (Get-Date).ToString('s'), $cpu, $memFreePct, $usedGB, $freeGB, $totGB, $driveOut[0], $driveOut[1], $driveOut[2], $driveOut[3], $driveOut[4]
  Add-Content -LiteralPath $csv -Value $row -Encoding UTF8
}catch{}
