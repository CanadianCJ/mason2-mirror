$rep = Join-Path $env:MASON2_BASE 'reports'
$f = Join-Path $rep 'alerts.jsonl'
$mark = Join-Path $env:MASON2_BASE 'state\forensic.mark'
$last = if(Test-Path $mark){ Get-Content $mark -Raw } else { "" }
$lines = if(Test-Path $f){ Get-Content $f -Tail 400 } else { @() }
$trig = $false
foreach($ln in $lines){
  if($ln -match '"subtype"\s*:\s*"(sensitive_data|moderation_violation)"'){ $trig=$true; break }
}
if($trig -and $last -ne (Get-Date).ToString('yyyyMMddHH')){
  & (Join-Path $env:MASON2_BASE 'tools\safety\Forensic-Snapshot.ps1') | Out-Null
  (Get-Date).ToString('yyyyMMddHH') | Out-File $mark -Encoding ascii
}