# tools\common\Log.ps1
# Log levels: debug(10) < info(20) < warn(30) < error(40)
function Get-LogLevelValue([string]$lvl){
  $l = if([string]::IsNullOrWhiteSpace($lvl)){'info'}else{$lvl}
  switch ($l.ToLower()) {
    'debug' { 10 } 'info' { 20 } 'warn' { 30 } 'error' { 40 } default { 20 }
  }
}
function Get-CurrentLogThreshold(){
  $envLvl = $env:MASON_LOG_LEVEL; if([string]::IsNullOrWhiteSpace($envLvl)){ $envLvl='info' }
  return (Get-LogLevelValue $envLvl)
}
function Should-Log([string]$lvl,[hashtable]$kv){
  $l = if([string]::IsNullOrWhiteSpace($lvl)){'info'}else{$lvl}
  $sev = Get-LogLevelValue $l
  if($sev -lt (Get-CurrentLogThreshold)){ return $false }
  # sampling for info/debug
  if($sev -lt 30){
    $pct = ($env:MASON_LOG_SAMPLE_PCT -as [int]); if(-not $pct){ $pct = 100 }
    if($pct -lt 100){ $r = Get-Random -Minimum 1 -Maximum 101; if($r -gt $pct){ return $false } }
  }
  return $true
}
function Write-Jsonl([string]$Path,[hashtable]$kv,[string]$lvl='info'){
  try{
    if(-not (Should-Log $lvl $kv)){ return }
    $kv['v']=1; $kv['lvl']=($lvl.ToLower())
    New-Item -ItemType Directory -Force (Split-Path $Path) | Out-Null
    $kv = Redact-PII $kv`r`n($kv | ConvertTo-Json -Compress) | Add-Content -LiteralPath $Path -Encoding UTF8
  }catch{}
}
