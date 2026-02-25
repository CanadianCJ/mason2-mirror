param([int]$WindowMin=120)
$ErrorActionPreference='SilentlyContinue'

function Ensure-Dir([string]$path){
  if(-not (Test-Path $path)){ New-Item -ItemType Directory -Force $path | Out-Null }
}

function Write-Utf8NoBom([string]$path,[string]$text){
  $enc = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($path,$text,$enc)
}

function Read-Jsonl([string]$path,[int]$tail=2000){
  if(-not (Test-Path $path)){ return @() }
  $out=@()
  Get-Content -LiteralPath $path -Tail $tail | ForEach-Object {
    try{ $out += ($_ | ConvertFrom-Json) }catch{}
  }
  return $out
}

function Get-Prop([object]$obj,[string]$name){
  if($obj -and $obj.PSObject.Properties[$name]){ return [string]$obj.$name }
  return $null
}

function Tail-Jsonl([string]$path,[int]$tail=200){
  $rows = Read-Jsonl $path $tail
  $rows | ForEach-Object {
    $o = $_
    if($o){
      [pscustomobject]@{
        ts      = (Get-Prop $o 'ts')
        kind    = (Get-Prop $o 'kind')
        subtype = (Get-Prop $o 'subtype')
        source  = (Get-Prop $o 'source')
        message = (Get-Prop $o 'message')
      }
    }
  }
}

$Base = $env:MASON2_BASE
if([string]::IsNullOrWhiteSpace($Base)){ $Base = Split-Path -Parent $PSCommandPath }
$rep = Join-Path $Base 'reports'; Ensure-Dir $rep

$hudPath   = Join-Path $rep 'hud.json'
$dashPath  = Join-Path $rep 'dashboard.json'
$alertsJl  = Join-Path $rep 'alerts.jsonl'
$watchJl   = Join-Path $rep 'watchdog.jsonl'

$now   = Get-Date
$since = $now.AddMinutes(-$WindowMin)

# Read current dashboard (if present)
$dash = $null
if(Test-Path $dashPath){ try{ $dash = Get-Content -LiteralPath $dashPath -Raw | ConvertFrom-Json }catch{} }

# Light metrics from dashboard if available
$memFreePct   = $null
$driveFreePct = $null
$cpuPct       = $null
$hudAlive     = $false

if($dash){
  try{
    if($dash.metrics){
      $memFreePct   = [double]$dash.metrics.mem_free_pct
      $driveFreePct = [double]$dash.metrics.drive_free_pct
      $cpuPct       = [double]$dash.metrics.cpu_pct
    }
  }catch{}
  try{
    if($dash.hud){ $hudAlive = ([int]$dash.hud.alive -eq 1) -or ([bool]$dash.hud.alive -eq $true) }
  }catch{}
}

# Alerts in window
$alerts = Read-Jsonl $alertsJl 2000 | Where-Object { $_.kind -eq 'alert' -and $_.ts -and ([datetime]$_.ts) -ge $since }

# Build counts
$byType = @{ schedule_drift = 0; net_down = 0; time_skew = 0; silence = 0; sensitive_data = 0 }
$alerts | ForEach-Object {
  $st = [string]$_.subtype
  if($byType.ContainsKey($st)){ $byType[$st]++ }
}

# Sparkline (last 60 min)
$start = $now.AddMinutes(-60)
$bins = @{}
for($i=0;$i -lt 60;$i++){ $k = $start.AddMinutes($i).ToString('yyyy-MM-ddTHH:mm'); $bins[$k]=0 }
$alerts | ForEach-Object {
  try{
    $t = [datetime]$_.ts
    $k = $t.ToString('yyyy-MM-ddTHH:mm')
    if($bins.ContainsKey($k)){ $bins[$k] = $bins[$k] + 1 }
  }catch{}
}
$spark = @()
foreach($k in ($bins.Keys | Sort-Object)){
  $spark += [pscustomobject]@{ t=$k; n=$bins[$k] }
}

# Tails
$tailAlerts  = Tail-Jsonl $alertsJl 150
$tailWatch   = Tail-Jsonl $watchJl  150

# Decide status
$reasons = @()
$color = 'GREEN'
if(-not $hudAlive){ $reasons += 'HUD not alive'; $color='RED' }
if($byType.silence -gt 0){ $reasons += 'Silence alerts'; if($color -eq 'GREEN'){ $color='AMBER' } }
if($byType.schedule_drift -gt 10){ $reasons += 'Schedule drift high'; if($color -eq 'GREEN'){ $color='AMBER' } }
if($byType.net_down -gt 0){ $reasons += 'Network down alerts'; if($color -eq 'GREEN'){ $color='AMBER' } }
if($memFreePct -is [double]){
  if($memFreePct -lt 10){ $reasons += 'Low free memory'; $color='RED' }
  elseif($memFreePct -lt 15 -and $color -eq 'GREEN'){ $reasons += 'Memory below comfort'; $color='AMBER' }
}
if($driveFreePct -is [double] -and $driveFreePct -lt 10){ $reasons += 'Low disk free%'; $color='RED' }
if($cpuPct -is [double] -and $cpuPct -gt 85 -and $color -eq 'GREEN'){ $reasons += 'High CPU'; $color='AMBER' }

$status = [pscustomobject]@{
  ts      = $now.ToString('s')
  color   = $color
  reasons = $reasons
  counts  = $byType
}

# Write extras (UTF-8 no BOM)
Write-Utf8NoBom (Join-Path $rep 'status.json')           ($status | ConvertTo-Json -Depth 6)
Write-Utf8NoBom (Join-Path $rep 'sparkline_errors.json') ($spark  | ConvertTo-Json -Depth 6)
Write-Utf8NoBom (Join-Path $rep 'tail_alerts.json')      ($tailAlerts | ConvertTo-Json -Depth 6)
Write-Utf8NoBom (Join-Path $rep 'tail_watchdog.json')    ($tailWatch | ConvertTo-Json -Depth 6)

# Merge into dashboard.json (non-destructive)
if($dash){
  try{
    $dash | Add-Member -NotePropertyName status -NotePropertyValue $status -Force
    $dash | Add-Member -NotePropertyName errors_sparkline -NotePropertyValue $spark -Force
    Write-Utf8NoBom $dashPath ($dash | ConvertTo-Json -Depth 8)
  }catch{}
}
