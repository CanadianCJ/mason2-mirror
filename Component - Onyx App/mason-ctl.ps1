# mason-ctl.ps1 — Signal command listener for Mason (no params)
# Owner + account are prefilled to your number (Canada E.164).

$ErrorActionPreference = "Stop"

# ---- CONFIG (prefilled) ----
$Account  = "+12264480522"              # signal-cli account on this PC
$Owners   = @("+12264480522")           # allowlist (you can add more later)
$Store    = "$env:USERPROFILE\Desktop\ONYX\signal-store"
$SignalCliCandidates = @(
  "$env:USERPROFILE\scoop\apps\signal-cli\current\bin\signal-cli.bat",
  "$env:USERPROFILE\scoop\apps\signal-cli\current\signal-cli.bat",
  (Get-Command signal-cli -ErrorAction SilentlyContinue | ForEach-Object Source)
) | Where-Object { $_ -and (Test-Path $_) }

if(-not (Test-Path $Store)){ New-Item -ItemType Directory -Path $Store | Out-Null }
if(-not $SignalCliCandidates){ throw "signal-cli not found. Install & link, then re-run." }
$SignalCli = $SignalCliCandidates | Select-Object -First 1

# ---- Paths ----
$Base     = "$env:USERPROFILE\Desktop\ONYX"
$ApiRoot  = Join-Path $Base "onyx-backend"
$WebRoot  = Join-Path $Base "onyx-web"
$SideRoot = Join-Path $Base "mason-sidecar"
$Audit    = Join-Path $SideRoot "logs\bridge_audit.jsonl"
$KillFlag = Join-Path $SideRoot "kill_switch.flag"

# ---- Helpers ----
function Send-Signal([string]$msg){
  & $SignalCli --config $Store -u $Account send -m $msg $Owners | Out-Null
}

function PortPid([int]$p){
  (Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty OwningProcess)
}

function Health(){
  $api  = $null; $web = $null; $side = $null; $props = $null; $last = ""
  try { $api  = (Invoke-WebRequest "http://10.0.0.174:8000/docs" -UseBasicParsing -TimeoutSec 2).StatusCode } catch {}
  try { $web  = (Invoke-WebRequest "http://10.0.0.174:5175" -UseBasicParsing -TimeoutSec 2).StatusCode } catch {}
  try {
    $h    = Invoke-RestMethod "http://127.0.0.1:7000/health" -TimeoutSec 2
    $side = "ok"
    $props = (Invoke-RestMethod "http://127.0.0.1:7000/proposals" -TimeoutSec 2).Count
  } catch { $side = $null }
  try { $last = (Get-Item $Audit -ErrorAction SilentlyContinue).LastWriteTime.ToString("yyyy-MM-dd HH:mm") } catch {}
  return @{
    api  = if($api){ "API:$api(pid $(PortPid 8000))" } else { "API:down" }
    web  = if($web){ "Web:$web(pid $(PortPid 5175))" } else { "Web:down" }
    side = if($side){ "Sidecar:ok(pid $(PortPid 7000)) props:$props last_audit:$last" } else { "Sidecar:down" }
  }
}

function Start-Detached($file,$args,$cwd){
  Start-Process -FilePath $file -ArgumentList $args -WorkingDirectory $cwd -WindowStyle Minimized | Out-Null
}

function Start-Stack(){
  # 0) Try to pin Node 18 (ignore if nvm not installed)
  try { nvm use 18.20.4 | Out-Null } catch {}
  # 1) API (:8000)
  $apiPy = Join-Path $ApiRoot ".venv\Scripts\python.exe"; if(-not (Test-Path $apiPy)){ $apiPy = "python" }
  Start-Detached $apiPy "-m uvicorn main:app --host 0.0.0.0 --port 8000" $ApiRoot
  # 2) Web (:5175) — serve built dist (build if needed)
  if(-not (Test-Path (Join-Path $WebRoot "dist"))){
    Push-Location $WebRoot; npm install; npm run build; Pop-Location
  }
  Start-Detached "npx" "serve -s dist -l 5175" $WebRoot
  # 3) Sidecar (:7000)
  $sidePy = Join-Path $SideRoot ".venv\Scripts\python.exe"; if(-not (Test-Path $sidePy)){ $sidePy = "python" }
  $entry = if(Test-Path (Join-Path $SideRoot "sidecar.py")) { "sidecar.py" } else { "main.py" }
  Start-Detached $sidePy $entry $SideRoot
  Start-Sleep -Seconds 2
  # 4) Reload bridge config for audit
  try{
    Invoke-RestMethod -Method Post http://127.0.0.1:7000/bridge/config `
      -Body (@{ path = (Join-Path $SideRoot "mason-bridge.yml") } | ConvertTo-Json) `
      -ContentType "application/json" | Out-Null
  } catch {}
}

function Stop-Stack(){
  $ports = 8000,5175,7000
  foreach($p in $ports){
    $pid = (Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty OwningProcess)
    if($pid){ Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue }
  }
}

# ---- Kill-switch & rate-limit ----
$Window   = New-TimeSpan -Minutes 1
$Limit    = 5
$CmdTimes = New-Object System.Collections.Generic.Queue[datetime]

function Allow-Command(){
  $now = Get-Date
  while($CmdTimes.Count -gt 0 -and ($now - $CmdTimes.Peek()) -gt $Window){ [void]$CmdTimes.Dequeue() }
  if($CmdTimes.Count -ge $Limit){ return $false }
  $CmdTimes.Enqueue($now); return $true
}

# ---- Startup banner ----
try { Send-Signal "mason-ctl online ✅ (try: mason on | mason off | status | scan now | tail audit 50 | kill on|off)" } catch { Write-Warning "Signal send failed: $($_.Exception.Message)" }

# ---- Main loop ----
while($true){
  try{
    $lines = & $SignalCli --config $Store -u $Account receive --json 2>$null
    foreach($line in $lines){
      if([string]::IsNullOrWhiteSpace($line)){ continue }
      $evt = $null; try { $evt = $line | ConvertFrom-Json } catch { continue }
      $data = $evt.envelope.dataMessage
      if(-not $data){ continue }

      $from = $evt.envelope.sourceNumber
      $txt  = ($data.message ?? "").Trim()
      if(-not $txt -or ($Owners -notcontains $from)){ continue }

      if(-not (Allow-Command)){ Send-Signal "⛔ rate-limited (max $Limit/min)"; continue }

      # Kill-switch check (blocks risky ops)
      $kill = Test-Path $KillFlag

      switch -Regex ($txt.ToLowerInvariant()) {

        '^kill\s+on$'  { New-Item -ItemType File -Path $KillFlag -Force | Out-Null; Send-Signal "Kill-switch ON 🛑 (read-only mode)"; break }
        '^kill\s+off$' { if(Test-Path $KillFlag){ Remove-Item $KillFlag -Force }; Send-Signal "Kill-switch OFF ✅"; break }

        '^status$' {
          $h = Health
          Send-Signal "STATUS 📊  $($h.api); $($h.web); $($h.side)"
          break
        }

        '^mason\s+on$' {
          if($kill){ Send-Signal "Kill-switch is ON 🛑. Turn off with: kill off"; break }
          Start-Stack
          $h = Health
          Send-Signal "ON ✅  $($h.api); $($h.web); $($h.side)"
          break
        }

        '^mason\s+off$' {
          Stop-Stack
          $h = Health
          Send-Signal "OFF ✅  $($h.api); $($h.web); $($h.side)"
          break
        }

        '^scan\s+now$' {
          try{
            $roots = @("$WebRoot", "$ApiRoot")
            Invoke-RestMethod -Method Post http://127.0.0.1:7000/scan `
              -Body (@{roots=$roots} | ConvertTo-Json) -ContentType "application/json" | Out-Null
            Send-Signal "Scan requested 🔎  roots=$($roots -join ', ')"
          } catch { Send-Signal "Scan failed: $($_.Exception.Message)" }
          break
        }

        '^tail\s+audit\s+(\d+)$' {
          $n = [int]$Matches[1]
          try{
            $resp = Invoke-RestMethod "http://127.0.0.1:7000/audit/tail?lines=$n" -TimeoutSec 3
            $out  = ($resp | Out-String)
            if($out.Length -gt 1200){ $out = $out.Substring(0,1200) + "`n...(truncated)" }
            Send-Signal "Audit (last $n lines) 📜`n$out"
          } catch { Send-Signal "Audit tail failed: $($_.Exception.Message)" }
          break
        }

        default {
          Send-Signal "Unknown cmd. Try: mason on | mason off | status | scan now | tail audit 50 | kill on|off"
        }
      }
    }
  } catch {
    Start-Sleep -Seconds 3
  }
  Start-Sleep -Seconds 3
}
