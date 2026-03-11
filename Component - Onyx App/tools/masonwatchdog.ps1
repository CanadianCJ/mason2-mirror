# MasonWatchdog.ps1 (ASCII) - v2 quiet web start

$ErrorActionPreference = "SilentlyContinue"

# Single-instance guard
try {
  $mutex = New-Object System.Threading.Mutex($false, "Global\MasonWatchdog")
  if (-not $mutex.WaitOne(0)) { return }
} catch { return }

# Paths
$root     = Join-Path $env:USERPROFILE "Desktop\ONYX"; if(-not (Test-Path $root)){ $root = Join-Path $env:USERPROFILE "Desktop\Onyx" }
$apiRoot  = Join-Path $root "onyx-backend"
$webRoot  = Join-Path $root "onyx-web"
$sideRoot = Join-Path $root "mason-sidecar"

# Logging
$logDir = Join-Path $root "logs"; New-Item -ItemType Directory -Path $logDir -EA SilentlyContinue | Out-Null
$log    = Join-Path $logDir "watchdog.log"
function Write-Log([string]$msg){ Add-Content -Path $log -Value ("{0} {1}" -f (Get-Date -Format "s"), $msg) }

function Get-NpxPath {
  $cands = @(
    (Join-Path $env:LOCALAPPDATA 'Programs\nodejs\npx.cmd'),
    (Join-Path $env:ProgramFiles 'nodejs\npx.cmd'),
    (Join-Path ${env:ProgramFiles(x86)} 'nodejs\npx.cmd')
  ) + @((Get-Command npx -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source))
  foreach($p in $cands){
    if($p -and (Test-Path $p)){
      if($p.ToLower().EndsWith('.ps1')){
        $cmd = $p -replace '\.ps1$','.cmd'
        if(Test-Path $cmd){ return $cmd }
      }
      return $p
    }
  }
  return $null
}

function PortOpen([int]$p){ [bool](Get-NetTCPConnection -LocalPort $p -EA SilentlyContinue | Select-Object -First 1) }
function SidecarAlive {
  $slog = Join-Path $sideRoot "logs"
  if (Test-Path $slog) {
    $last = Get-ChildItem $slog -File -EA SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($last -and (((Get-Date) - $last.LastWriteTime).TotalSeconds -lt 120)) { return $true }
  }
  [bool](Get-Process python,python3 -EA SilentlyContinue | Where-Object { $_.Path -like "$sideRoot*" })
}

function Start-API {
  if (PortOpen 8000) { return }
  $py = Join-Path $apiRoot ".venv\Scripts\python.exe"; if (-not (Test-Path $py)) { $py = "python" }
  Write-Log "Starting API :8000"
  Start-Process $py "-m uvicorn main:app --host 0.0.0.0 --port 8000" -WorkingDirectory $apiRoot -WindowStyle Hidden | Out-Null
}
function Start-Web {
  if (PortOpen 5175) { return }
  if (Test-Path (Join-Path $webRoot "dist")) {
    $npx = Get-NpxPath
    if ($npx) {
      Write-Log "Starting Web via $npx"
      Start-Process $npx "serve -s dist -l 5175" -WorkingDirectory $webRoot -WindowStyle Hidden | Out-Null
    } else {
      Write-Log "Starting Web via npm exec serve"
      Start-Process "npm" "exec --yes serve -s dist -l 5175" -WorkingDirectory $webRoot -WindowStyle Hidden | Out-Null
    }
  } else {
    Write-Log "Starting Web via npm run dev"
    Start-Process "npm" "run dev" -WorkingDirectory $webRoot -WindowStyle Hidden | Out-Null
  }
}
function Start-Sidecar {
  if (SidecarAlive) { return }
  $py = Join-Path $sideRoot ".venv\Scripts\python.exe"; if (-not (Test-Path $py)) { $py = "python" }
  $entry = if (Test-Path (Join-Path $sideRoot "sidecar.py")) { "sidecar.py" } else { "main.py" }
  Write-Log "Starting Sidecar: $entry"
  Start-Process $py $entry -WorkingDirectory $sideRoot -WindowStyle Hidden | Out-Null
}

Write-Log "Watchdog started"
while ($true) {
  try {
    Start-API; Start-Web; Start-Sidecar
  } catch { Write-Log ("Error: " + $_.Exception.Message) }
  Start-Sleep -Seconds 20
}
