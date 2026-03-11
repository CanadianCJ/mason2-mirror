param(
  [switch]$Status
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Resolve-Python {
  $py = $null
  try { $py = (& py -3 -c "import sys;print(sys.executable)") } catch {}
  if (-not $py) { try { $py = (& python -c "import sys;print(sys.executable)") } catch {} }
  if (-not $py) { throw "Python not found (need 'py' or 'python' on PATH)." }
  $py.Trim()
}

function Ensure-ApiKey {
  if (-not $env:ONYX_API_KEY) {
    $existing = [Environment]::GetEnvironmentVariable("ONYX_API_KEY","User")
    if ($existing) { $env:ONYX_API_KEY = $existing }
    else {
      $env:ONYX_API_KEY = [guid]::NewGuid().ToString("N")
      [Environment]::SetEnvironmentVariable("ONYX_API_KEY", $env:ONYX_API_KEY, "User")
      Write-Host "Generated ONYX_API_KEY (User): $($env:ONYX_API_KEY)" -ForegroundColor Yellow
    }
  } else {
    [Environment]::SetEnvironmentVariable("ONYX_API_KEY", $env:ONYX_API_KEY, "User")
  }
}

function Start-Backend {
  param([string]$BackendPath, [string]$PyExe)

  Push-Location $BackendPath
  try {
    # Ensure pip & deps
    try { & $PyExe -m pip --version *> $null } catch { & $PyExe -m ensurepip --default-pip }
    & $PyExe -m pip install --user --upgrade pip setuptools wheel
    & $PyExe -m pip install --user fastapi uvicorn pydantic starlette

    Ensure-ApiKey

    # Kill old backend if any
    $pidFile = Join-Path $BackendPath 'backend.pid'
    if (Test-Path $pidFile) {
      try {
        $oldPid = [int](Get-Content $pidFile -Raw)
        if ($oldPid -gt 0) {
          $p = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
          if ($p) { Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue }
        }
      } catch {}
      Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
    }

    # Separate logs
    $logOut = Join-Path $BackendPath 'backend.out.log'
    $logErr = Join-Path $BackendPath 'backend.err.log'
    if (!(Test-Path $logOut)) { New-Item -ItemType File -Path $logOut -Force | Out-Null }
    if (!(Test-Path $logErr)) { New-Item -ItemType File -Path $logErr -Force | Out-Null }

    $psi = @{
      FilePath               = $PyExe
      ArgumentList           = @('-m','uvicorn','api:app','--host','127.0.0.1','--port','8000')
      WorkingDirectory       = $BackendPath
      RedirectStandardOutput = $logOut
      RedirectStandardError  = $logErr
      WindowStyle            = 'Hidden'
      PassThru               = $true
    }
    $proc = Start-Process @psi
    Set-Content -Path $pidFile -Value $proc.Id -Encoding ASCII

    # Wait for health
    $ok = $false
    for ($i=0; $i -lt 60; $i++) {
      Start-Sleep -Milliseconds 300
      try {
        $r = Invoke-RestMethod -Uri 'http://127.0.0.1:8000/health' -TimeoutSec 2
        if ($r.ok -eq $true) { $ok = $true; break }
      } catch {}
      if ($proc.HasExited) { break }
    }

    if (-not $ok) {
      Write-Host "Backend failed to become healthy. Showing last 40 lines:" -ForegroundColor Red
      if (Test-Path $logErr) { Get-Content $logErr -Tail 40 }
      throw "Backend not healthy."
    }

    Write-Host "Backend is UP at http://127.0.0.1:8000   (KEY: $($env:ONYX_API_KEY))" -ForegroundColor Green
  }
  finally { Pop-Location }
}

function Start-Expo {
  param([string]$MobilePath, [string]$ApiBase, [string]$AdminKey)

  $tsLayout = Join-Path $MobilePath 'app\_layout.tsx'
  if (Test-Path $tsLayout) { Remove-Item -Force $tsLayout }

  $env:EXPO_USE_LOCAL_CLI    = '1'
  $env:EXPO_NO_TELEMETRY     = '1'
  $env:EXPO_PUBLIC_API_BASE  = $ApiBase
  if ($AdminKey) { $env:EXPO_PUBLIC_ONYX_KEY = $AdminKey } else { Remove-Item Env:EXPO_PUBLIC_ONYX_KEY -ErrorAction SilentlyContinue }

  Push-Location $MobilePath
  try {
    if (Test-Path (Join-Path $MobilePath 'package-lock.json')) { npm ci } else { npm install }
    npx expo install react-native-safe-area-context react-native-screens expo-updates *> $null
    npm i axios zustand *> $null

    Write-Host ""
    Write-Host "=== Expo controls ===" -ForegroundColor Cyan
    Write-Host "Press 'w' → web · 'a' → Android · 'j' → debugger · 'r' → reload · '?' → help" -ForegroundColor DarkCyan
    Write-Host "API_BASE: $ApiBase" -ForegroundColor Gray
    if ($AdminKey) { Write-Host "Admin key injected into app (writes enabled on this device)" -ForegroundColor Yellow }

    npx expo start -c
  } finally {
    Pop-Location
  }
}

# -------- Main flow --------
$root    = Join-Path ([Environment]::GetFolderPath('Desktop')) 'ONYX'
$backend = Join-Path $root 'backend'
$mobile  = Join-Path $root 'mobile'

if ($Status) {
  try {
    $r = Invoke-RestMethod -Uri "http://127.0.0.1:8000/health" -TimeoutSec 3
    Write-Host "Backend is running. ok=$($r.ok) time=$($r.time)" -ForegroundColor Green
  } catch {
    Write-Host "Backend is NOT running." -ForegroundColor Red
  }
  exit
}

if (!(Test-Path $backend)) { throw "Backend not found: $backend" }
if (!(Test-Path $mobile))  { throw "Mobile not found:  $mobile" }

$py = Resolve-Python

try {
  Start-Backend -BackendPath $backend -PyExe $py
  Start-Expo    -MobilePath $mobile -ApiBase "http://127.0.0.1:8000" -AdminKey $env:ONYX_API_KEY
}
finally {
  $pidFile = Join-Path $backend 'backend.pid'
  if (Test-Path $pidFile) {
    try {
      $pid = [int](Get-Content $pidFile -Raw)
      if ($pid -gt 0) { Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue }
    } catch {}
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
  }
  Write-Host "Backend stopped." -ForegroundColor DarkGray
}
