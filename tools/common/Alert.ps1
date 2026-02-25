# tools\common\Alert.ps1
function Write-Alert {
  param([hashtable]$obj, [int]$DedupMinutes = 15, [string]$DedupKey = '')
  try{
    $Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
    $rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
    $path = Join-Path $rep 'alerts.jsonl'

    if([string]::IsNullOrWhiteSpace($DedupKey)){
      # default: subtype only
      if($obj.ContainsKey('subtype')){ $DedupKey = [string]$obj['subtype'] } else { $DedupKey = 'generic' }
      # if 'task' exists, include it
      if($obj.ContainsKey('task') -and -not [string]::IsNullOrWhiteSpace($obj['task'])){ $DedupKey += '|' + [string]$obj['task'] }
    }

    $obj['dedup'] = $DedupKey
    if(-not $obj.ContainsKey('ts')){ $obj['ts'] = (Get-Date).ToString('s') }
    if(-not $obj.ContainsKey('kind')){ $obj['kind'] = 'alert' }

    $now = Get-Date
    if(Test-Path $path){
      $tail = Get-Content -LiteralPath $path -Tail 300 -ErrorAction SilentlyContinue
      foreach($line in $tail){
        if($line -notmatch '"kind":"alert"'){ continue }
        $o=$null; try{ $o = $line | ConvertFrom-Json }catch{}
        if($o -and $o.kind -eq 'alert' -and $o.dedup -eq $DedupKey){
          $ots=$null; try{ $ots=[datetime]$o.ts }catch{}
          if($ots -and (($now - $ots).TotalMinutes -lt $DedupMinutes)){ return }
        }
      }
    }

    ($obj | ConvertTo-Json -Compress) | Add-Content -LiteralPath $path -Encoding UTF8
  }catch{}
}
