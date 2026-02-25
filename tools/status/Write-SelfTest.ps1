param([int]$BudgetSec=30)
$ErrorActionPreference='SilentlyContinue'
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$out = Join-Path $rep 'selftest.json'
function Write-Utf8NoBom([string]$p,[string]$t){ $enc=New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($p,$t,$enc) }
$now = Get-Date
$ok  = @()
$bad = @()

# Check HUD recency (<= 10s old)
$hudPath = Join-Path $rep 'hud.json'
if(Test-Path $hudPath){
  try{
    $hud = Get-Content -LiteralPath $hudPath -Tail 1 | ConvertFrom-Json
    if($hud -and $hud.ts){
      $age = [int]($now - [datetime]$hud.ts).TotalSeconds
      if($age -le 10){ $ok += "HUD fresh (${age}s)" } else { $bad += "HUD stale (${age}s)" }
    } else { $bad += 'HUD parse failed' }
  }catch{ $bad += 'HUD read failed' }
}else{ $bad += 'HUD missing' }

# Check dashboard file exists
$dash = Join-Path $rep 'dashboard.json'
if(Test-Path $dash){ $ok += 'dashboard.json present' } else { $bad += 'dashboard.json missing' }

# Check key tasks exist
$need = 'Mason-Heartbeat','Mason-DashboardSnapshot','Mason-DashboardExtras'
foreach($t in $need){
  try{ Get-ScheduledTaskInfo -TaskName $t -ErrorAction Stop | Out-Null; $ok += "Task ok: $t" }catch{ $bad += "Task missing: $t" }
}

$result = @{ ts=$now.ToString('s'); ok=$ok; bad=$bad }
Write-Utf8NoBom $out ($result | ConvertTo-Json -Depth 6)
Write-Output $out
