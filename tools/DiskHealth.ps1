Import-Module (Join-Path $env:MASON2_BASE 'lib\Mason.Config.psm1') -Force
$cfg = Get-MasonEnv
$minPct = [int]$cfg.MASON_DISK_MIN_FREE_PCT

$Base = $env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base = Split-Path -Parent $PSCommandPath }
$rep  = Join-Path $Base "reports"; New-Item -ItemType Directory -Force $rep | Out-Null
$out  = Join-Path $rep "diskhealth.jsonl"

$vol = Get-PSDrive -Name C
$freePct = [math]::Round(($vol.Free/$vol.Used) * 100,2)
$rec = @{ ts=(Get-Date).ToString('s'); free_pct=$freePct; min_pct=$minPct; drive=$vol.Name }
($rec | ConvertTo-Json -Compress) | Add-Content -LiteralPath $out -Encoding utf8

if($freePct -lt $minPct){
  # soft action: emit a warning file (no destructive cleanup by default)
  $flag = Join-Path $Base "reports\ACTION_LOW_DISK.txt"
  "Low disk free: $freePct% on $($vol.Name). Threshold: $minPct%" | Set-Content -Encoding UTF8 $flag
}
