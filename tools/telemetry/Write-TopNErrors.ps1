param([int]$N=10,[int]$WindowLines=5000)

function _redact([string]$s){
  if([string]::IsNullOrWhiteSpace($s)){ return $s }
  $r=$s
  $r = [regex]::Replace($r,'(?i)\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b','<email>')
  $r = [regex]::Replace($r,'(?i)\b(?:\+?\d{1,3}[\s-]?)?(?:\(?\d{3}\)?[\s-]?)?\d{3}[\s-]?\d{4}\b','<phone>')
  $r = [regex]::Replace($r,'\b(?:\d[ -]*?){13,19}\b','<card>')
  return $r
}

$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$out = Join-Path $rep ("top_errors_{0}.json" -f (Get-Date -Format yyyyMMdd))

$errs = @{}
Get-ChildItem $rep -Filter *.jsonl -File -ErrorAction SilentlyContinue | ForEach-Object {
  $lines = Get-Content -LiteralPath $_.FullName -Tail $WindowLines -ErrorAction SilentlyContinue
  foreach($line in $lines){
    $o=$null; try{ $o=$line | ConvertFrom-Json }catch{}
    if(-not $o){ continue }
    $sig=$null
    if($o.kind -eq 'http7001'){
      if(($o.status -as [int]) -ge 500 -or $o.err){ $sig = ("HTTP {0} {1}" -f $o.status, $o.path) }
    } elseif($o.err){
      $sig = ("{0} {1}" -f ($o.kind -as [string]), ($o.err -as [string]))
    }
    if($sig){
      $k = _redact([string]$sig)
      if(-not $errs.ContainsKey($k)){ $errs[$k]=0 }
      $errs[$k]++
    }
  }
}

$topRows = $errs.GetEnumerator() |
  Sort-Object Value -Descending |
  Select-Object -First $N |
  ForEach-Object { [pscustomobject]@{ sig=$_.Key; count=$_.Value } }

@{ ts=(Get-Date).ToString('s'); kind='top_errors'; rows=$topRows } |
  ConvertTo-Json -Depth 5 | Set-Content -Encoding UTF8 $out
