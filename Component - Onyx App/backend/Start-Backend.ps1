$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$here = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent "$($MyInvocation.MyCommand.Path)" }
Set-Location $here

function Ensure-ApiKey {
  if (-not $env:ONYX_API_KEY) {
    $existing = [Environment]::GetEnvironmentVariable("ONYX_API_KEY","User")
    if ($existing) { $env:ONYX_API_KEY = $existing }
    else {
      $env:ONYX_API_KEY = [guid]::NewGuid().ToString("N")
      [Environment]::SetEnvironmentVariable("ONYX_API_KEY", $env:ONYX_API_KEY, "User")
      Write-Host "Generated ONYX_API_KEY (saved to User env): $($env:ONYX_API_KEY)" -ForegroundColor Yellow
    }
  } else {
    [Environment]::SetEnvironmentVariable("ONYX_API_KEY", $env:ONYX_API_KEY, "User")
  }
}

function Try-Run-InVenv {
  # Create venv (try py -3 first)
  if (!(Test-Path .venv\Scripts\python.exe)) {
    try { & py -3 -m venv .venv --upgrade-deps } catch { python -m venv .venv --upgrade-deps }
  }
  $py = Join-Path $here '.venv\Scripts\python.exe'

  # Ensure pip
  $havePip = $false
  try { & $py -m pip --version | Out-Null; $havePip = $true } catch {}
  if (-not $havePip) {
    try {
      & $py -m ensurepip --default-pip
      & $py -m pip --version | Out-Null
      $havePip = $true
    } catch {
      try {
        Write-Host "ensurepip not available; downloading get-pip.py..." -ForegroundColor Yellow
        $gpp = Join-Path $env:TEMP 'get-pip.py'
        Invoke-WebRequest -UseBasicParsing -Uri https://bootstrap.pypa.io/get-pip.py -OutFile $gpp
        & $py $gpp
        & $py -m pip --version | Out-Null
        $havePip = $true
      } catch {
        $havePip = $false
      }
    }
  }
  if (-not $havePip) { return $false }

  # Install deps
  & $py -m pip install --upgrade pip setuptools wheel
  & $py -m pip install -r requirements.txt

  # Sanity import
  try {
    & $py -c "import importlib; [importlib.import_module(m) for m in ('fastapi','uvicorn','pydantic','starlette')]" | Out-Null
  } catch { return $false }

  Ensure-ApiKey
  Write-Host "Starting backend at http://127.0.0.1:8000  (KEY: $($env:ONYX_API_KEY)) [venv]" -ForegroundColor Green
  & $py -m uvicorn api:app --reload --port 8000 --host 127.0.0.1
  return $true
}

function Run-GlobalPython {
  # Resolve a global interpreter
  $globalPy = $null
  try { $globalPy = & py -3 -c "import sys;print(sys.executable)" } catch {}
  if (-not $globalPy) {
    try { $globalPy = & python -c "import sys;print(sys.executable)" } catch {}
  }
  if (-not $globalPy) { throw "No global Python found (py/python)." }

  # Ensure pip & deps on the global interpreter (installs to user site if needed)
  try { & $globalPy -m pip --version | Out-Null } catch { & $globalPy -m ensurepip --default-pip }
  & $globalPy -m pip install --user --upgrade pip setuptools wheel
  & $globalPy -m pip install --user fastapi uvicorn pydantic starlette

  # Sanity import
  & $globalPy -c "import importlib; [importlib.import_module(m) for m in ('fastapi','uvicorn','pydantic','starlette')]" | Out-Null

  Ensure-ApiKey
  Write-Host "Starting backend at http://127.0.0.1:8000  (KEY: $($env:ONYX_API_KEY)) [global]" -ForegroundColor Green
  & $globalPy -m uvicorn api:app --reload --port 8000 --host 127.0.0.1
}

# Try venv first; fallback to global Python if venv cannot be used
if (-not (Try-Run-InVenv)) {
  Write-Host "Venv unavailable; falling back to global Python…" -ForegroundColor Yellow
  Run-GlobalPython
}
