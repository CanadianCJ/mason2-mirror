param([string]$Drive = $env:SystemDrive)
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$out = Join-Path $rep  'disk_usage.jsonl'

try{
  $d = Get-PSDrive -Name ($Drive.TrimEnd('\').TrimEnd(':')) -ErrorAction Stop
  $total = [double]$d.Used + [double]$d.Free
  $pct   = if($total -gt 0){ [Math]::Round(($d.Used / $total) * 100,2) } else { 0 }
  $rec = @{
    ts    = (Get-Date).ToString('s')
    drive = $d.Root
    used  = [int64]$d.Used
    free  = [int64]$d.Free
    pct   = $pct
  }
  ($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $out -Encoding utf8
}catch{}
