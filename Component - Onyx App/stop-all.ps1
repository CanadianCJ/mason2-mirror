$ErrorActionPreference = "SilentlyContinue"
$ports = 8000,5175,7000
foreach($p in $ports){
  $pid = (Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty OwningProcess)
  if($pid){ Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue }
}
"Stopped ports 8000, 5175, 7000 (if running)."
