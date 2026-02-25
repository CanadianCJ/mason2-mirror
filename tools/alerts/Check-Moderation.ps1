param([int]$Tail=400)
$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
. (Join-Path $Base 'tools\common\Moderation.ps1') 2>$null
$rep = Join-Path $Base 'reports'; New-Item -ItemType Directory -Force $rep | Out-Null
$f = Join-Path $rep 'http7001.jsonl'
if(-not (Test-Path $f)){ return }
$lines = Get-Content -LiteralPath $f -Tail $Tail -ErrorAction SilentlyContinue
foreach($line in $lines){
  $o=$null; try{ $o=$line | ConvertFrom-Json }catch{}
  if(-not $o){ continue }
  $candidates = @()
  foreach($k in @('prompt','text','body','cmd','message')){ if($o.PSObject.Properties[$k]){ $candidates += [string]$o.$k } }
  foreach($t in $candidates){ Moderate-Text -Text $t -Source 'http7001' }
}
