param([int]$MaxMinutes=10)

$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
. (Join-Path $Base 'tools\common\Alert.ps1') 2>$null

$rep  = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$http = Join-Path $rep 'http7001.jsonl'

$now = Get-Date
$lastTs = $null

if(Test-Path $http){
  $tail = Get-Content -LiteralPath $http -Tail 500 -ErrorAction SilentlyContinue
  $arr = @($tail); [array]::Reverse($arr)
  foreach($line in $arr){
    $o=$null; try{ $o = $line | ConvertFrom-Json }catch{}
    if($o -and $o.kind -eq 'http7001' -and $o.ts){ $lastTs = [datetime]$o.ts; break }
  }
}

$minutes = $null
if($lastTs){ $minutes = [int](($now - $lastTs).TotalMinutes) }

if(-not $lastTs -or $minutes -ge $MaxMinutes){
  $minsOut = -1
  if($minutes -ne $null){ $minsOut = $minutes }
  $lastSeenStr = $null
  if($lastTs){ $lastSeenStr = $lastTs.ToString('s') }

  $obj = @{
    ts=(Get-Date).ToString('s')
    kind='alert'
    subtype='silence'
    message=("No HTTP activity for {0} min (>= {1})" -f $minsOut, $MaxMinutes)
    threshold_min=$MaxMinutes
  }
  $obj['last_seen'] = $lastSeenStr

  Write-Alert -obj $obj -DedupMinutes 10 -DedupKey 'silence'
}
