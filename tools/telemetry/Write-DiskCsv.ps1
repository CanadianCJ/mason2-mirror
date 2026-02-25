param([string]$Drive='C:')
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base = Split-Path -Parent $PSCommandPath }
$rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$csv = Join-Path $rep 'disk.csv'

function Ensure-Header{
  if(-not (Test-Path $csv) -or (Get-Content $csv -TotalCount 1) -notmatch '^ts,drive,free_pct,used_gb,free_gb,total_gb$'){
    'ts,drive,free_pct,used_gb,free_gb,total_gb' | Set-Content -Encoding UTF8 $csv
  }
}

try{
  $vol = Get-Volume -DriveLetter ($Drive.TrimEnd(':') ) -ErrorAction Stop
  $total = [math]::Round($vol.Size/1GB,2)
  $free  = [math]::Round($vol.SizeRemaining/1GB,2)
  $used  = [math]::Round($total - $free,2)
  $pct   = if($total -gt 0){ [math]::Round(($free/$total)*100,2) } else { $null }
  Ensure-Header
  $row = '{0},{1},{2},{3},{4},{5}' -f (Get-Date).ToString('s'), $Drive.ToUpper(), $pct, $used, $free, $total
  Add-Content -LiteralPath $csv -Value $row -Encoding UTF8
}catch{}
