param([string]$WhenTag = 'daily')

$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base = Split-Path -Parent $PSCommandPath }
$root = $Base
$rep  = Join-Path $Base 'reports'
$cfg  = Join-Path $Base 'config'
$snaps= Join-Path $Base 'snapshots'
New-Item -ItemType Directory -Force $snaps | Out-Null

$ts = Get-Date -Format yyyyMMdd_HHmmss
$staging = Join-Path $snaps ("staging_" + $ts)
New-Item -ItemType Directory -Force $staging | Out-Null

# Collect state
try {
  # Configs
  if(Test-Path $cfg){ Copy-Item $cfg -Destination (Join-Path $staging 'config') -Recurse -Force }
  # Reports (logs/metrics)
  if(Test-Path $rep){ Copy-Item $rep -Destination (Join-Path $staging 'reports') -Recurse -Force }
  # Manifest if present
  if(Test-Path (Join-Path $Base 'manifest.json')) { Copy-Item (Join-Path $Base 'manifest.json') (Join-Path $staging 'manifest.json') -Force }

  # Task + URLACL metadata
  $meta = @{
    ts = (Get-Date).ToString('s')
    hostname = $env:COMPUTERNAME
    user = $env:USERNAME
    mason_base = $Base
    tasks = (Get-ScheduledTask | Where-Object { $_.TaskName -like 'Mason-*' } | Select-Object TaskName,State,Actions,Triggers)
    urlacl = (netsh http show urlacl)
  }
  $meta | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $staging 'meta.json')

  # Make zip
  $zip = Join-Path $snaps ("Mason_" + $WhenTag + "_" + $ts + ".zip")
  if(Test-Path $zip){ Remove-Item $zip -Force }
  Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $zip
  # Log a breadcrumb
  $breadcrumb = Join-Path $rep 'snapshots.jsonl'
  New-Item -ItemType Directory -Force (Split-Path $breadcrumb) | Out-Null
  (@{ts=(Get-Date).ToString('s'); kind='snapshot'; zip=(Split-Path -Leaf $zip)} | ConvertTo-Json -Compress) |
    Add-Content -LiteralPath $breadcrumb -Encoding UTF8
} catch {
  Write-Warning $_.Exception.Message
} finally {
  # Clean staging
  try { Remove-Item $staging -Recurse -Force -ErrorAction SilentlyContinue } catch {}
}
