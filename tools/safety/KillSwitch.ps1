param([switch]$Rollback)
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
. (Join-Path $Base 'tools\common\Breadcrumb.ps1') 2>$null
$ctrl = Join-Path $Base 'control'; New-Item -ItemType Directory -Force $ctrl | Out-Null
$safeFlag = Join-Path $ctrl 'safemode.on'
try{ '1' | Set-Content -Encoding ASCII $safeFlag }catch{}
try{ Write-Breadcrumb -action 'killswitch' -meta @{ reason='manual'; safemode='on' } }catch{}

# Snapshot
$snap = $null; try{ $snap = & (Join-Path $Base 'tools\safety\Write-ForensicSnapshot.ps1') -Reason 'killswitch' }catch{}

# Quiesce Mason tasks
try{
  Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object TaskName -like 'Mason-*' | ForEach-Object {
    try{ Stop-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue }catch{}
  }
}catch{}

# Optional config-only rollback helper
if($Rollback){
  $rb = Join-Path $Base 'tools\safety\Emergency-Rollback.ps1'
  if(Test-Path $rb){ try{ & $rb }catch{} }
}

"[KillSwitch] SafeMode ON. Snapshot: $snap"
