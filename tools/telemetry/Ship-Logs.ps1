# tools\telemetry\Ship-Logs.ps1
param([string]$OutDir)
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
if(($env:MASON_LOG_SHIP -as [int]) -ne 1){ return }  # Phase 1: toggle only, disabled by default
$rep = Join-Path $Base 'reports'
$OutDir = if([string]::IsNullOrWhiteSpace($OutDir)){ Join-Path $Base 'snapshots\ship' } else { $OutDir }
New-Item -ItemType Directory -Force $OutDir | Out-Null
$zip = Join-Path $OutDir ("logs_{0}.zip" -f (Get-Date -Format yyyyMMdd_HHmmss))
if(Test-Path $zip){ Remove-Item $zip -Force }
try{
  $files = Get-ChildItem $rep -File -ErrorAction SilentlyContinue
  if($files){ Compress-Archive -Path $files.FullName -DestinationPath $zip -ErrorAction SilentlyContinue }
}catch{}
