$base="$env:MASON2_BASE"; $cfg=Join-Path $base 'config\freeze.json'; $ctrl=Join-Path $base 'control'
New-Item -ItemType Directory -Force $ctrl | Out-Null
$on = $false
if(Test-Path $cfg){
  try{
    $r = Get-Content $cfg -Raw | ConvertFrom-Json
    $today = (Get-Date).Date
    foreach($w in $r.windows){
      $s = Get-Date $w.start
      $e = Get-Date $w.end
      if($today -ge $s.Date -and $today -le $e.Date){ $on=$true; break }
    }
  }catch{}
}
$flag = Join-Path $ctrl 'FREEZE.on'
if($on){ New-Item -ItemType File -Force $flag | Out-Null }
else     { if(Test-Path $flag){ Remove-Item $flag -Force } }