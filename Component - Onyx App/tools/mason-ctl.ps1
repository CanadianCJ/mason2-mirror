param([ValidateSet("start","stop","restart","status","logs")]$cmd="status")

$ErrorActionPreference = "SilentlyContinue"
$root     = Join-Path $env:USERPROFILE "Desktop\ONYX"
$apiRoot  = Join-Path $root "onyx-backend"
$webRoot  = Join-Path $root "onyx-web"
$sideRoot = Join-Path $root "mason-sidecar"

function PortOpen([int]$p){ [bool](Get-NetTCPConnection -LocalPort $p -EA SilentlyContinue | Select-Object -First 1) }

function SidecarAlive {
  $slog = Join-Path $sideRoot "logs"
  if (Test-Path $slog) {
    $last = Get-ChildItem $slog -File -EA SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($last -and (((Get-Date) - $last.LastWriteTime).TotalSeconds -lt 120)) { return $true }
  }
  [bool](Get-Process python,python3 -EA SilentlyContinue | Where-Object { $_.Path -like "$sideRoot*" })
}

switch ($cmd) {
  "start"   { & (Join-Path $root "start-all.ps1") ; break }
  "stop"    { & (Join-Path $root "stop-all.ps1")  ; break }
  "restart" { & (Join-Path $root "stop-all.ps1") ; Start-Sleep -Seconds 1 ; & (Join-Path $root "start-all.ps1") ; break }
  "status"  {
    $api  = PortOpen 8000
    $web  = PortOpen 5175
    $side = SidecarAlive
    $apiS  = if($api){'up'}  else{'down'}
    $webS  = if($web){'up'}  else{'down'}
    $sideS = if($side){'up'} else{'down'}
    Write-Host ("API:{0}  Web:{1}  Sidecar:{2}" -f $apiS,$webS,$sideS)
    break
  }
  "logs" {
    $ld = Join-Path $sideRoot "logs"
    if(Test-Path $ld){
      Get-ChildItem $ld -File -EA SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1 |
        ForEach-Object { Get-Content $_.FullName -Tail 200 }
    } else { Write-Host "No sidecar logs yet." }
    break
  }
}
