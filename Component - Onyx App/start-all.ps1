$ErrorActionPreference = "Stop"
$Base     = "$env:USERPROFILE\Desktop\ONYX"
$ApiRoot  = Join-Path $Base "onyx-backend"
$WebRoot  = Join-Path $Base "onyx-web"
$SideRoot = Join-Path $Base "mason-sidecar"

# Safer launcher: only passes -ArgumentList when it's non-empty
function Start-Detached {
  param(
    [Parameter(Mandatory=$true)][string]$file,
    [string]$args,
    [string]$cwd = (Get-Location).Path
  )
  # allow either a path or a command on PATH
  if(-not (Test-Path $file) -and -not (Get-Command $file -EA SilentlyContinue)){
    throw "Missing executable or command: $file"
  }
  $psi = @{
    FilePath         = $file
    WorkingDirectory = $cwd
    WindowStyle      = 'Minimized'
  }
  if($args -and $args.Trim()){ $psi.ArgumentList = $args }
  Start-Process @psi | Out-Null
}

try { nvm use 18.20.4 | Out-Null } catch {}

# Optional: open Windows Firewall for local (Private) network once
foreach($p in 8000,5175,7000){
  netsh advfirewall firewall add rule name="Mason_$p" dir=in action=allow protocol=TCP localport=$p profile=private 2>$null | Out-Null
}

# API (:8000)
$apiPy = Join-Path $ApiRoot ".venv\Scripts\python.exe"; if(-not (Test-Path $apiPy)){ $apiPy = "python" }
Start-Detached $apiPy "-m uvicorn main:app --host 0.0.0.0 --port 8000" $ApiRoot

# Web (:5175)
if(-not (Test-Path (Join-Path $WebRoot "dist"))){
  Push-Location $WebRoot; npm install; npm run build; Pop-Location
}
Start-Detached "npx" "serve -s dist -l 5175" $WebRoot

# Sidecar (:7000)
$sidePy = Join-Path $SideRoot ".venv\Scripts\python.exe"; if(-not (Test-Path $sidePy)){ $sidePy = "python" }
$entry  = if(Test-Path (Join-Path $SideRoot "sidecar.py")) { "sidecar.py" }
          elseif(Test-Path (Join-Path $SideRoot "main.py")){ "main.py" } else { "" }
if($entry){
  Start-Detached $sidePy $entry $SideRoot
} else {
  Write-Warning "No sidecar entry file found (sidecar.py/main.py) — skipping sidecar."
}

Start-Sleep -Seconds 2

# Audit reload (best-effort)
try{
  Invoke-RestMethod -Method Post http://127.0.0.1:7000/bridge/config `
    -Body (@{ path = (Join-Path $SideRoot "mason-bridge.yml") } | ConvertTo-Json) `
    -ContentType "application/json" | Out-Null
} catch {}

function PortPid($p){ (Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty OwningProcess) }
"Started API(:8000 pid $(PortPid 8000)), Web(:5175 pid $(PortPid 5175)), Sidecar(:7000 pid $(PortPid 7000))."
