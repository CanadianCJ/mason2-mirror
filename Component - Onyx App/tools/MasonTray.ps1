# MasonTray.ps1  (ASCII only) ? PowerShell 5.1 compatible

$ErrorActionPreference = "SilentlyContinue"

# Relaunch in STA if needed
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
  $self = $PSCommandPath
  Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$self`""
  exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Paths
$root     = Join-Path $env:USERPROFILE 'Desktop\ONYX'
$apiRoot  = Join-Path $root 'onyx-backend'
$webRoot  = Join-Path $root 'onyx-web'
$sideRoot = Join-Path $root 'mason-sidecar'
$startAll = Join-Path $root 'start-all.ps1'
$stopAll  = Join-Path $root 'stop-all.ps1'

function PortPid([int]$p){
  Get-NetTCPConnection -LocalPort $p -EA SilentlyContinue |
    Select-Object -First 1 -ExpandProperty OwningProcess
}
function StatusText {
  $a = if (PortPid 8000) { 'up' } else { 'down' }
  $w = if (PortPid 5175) { 'up' } else { 'down' }
  $s = if (PortPid 7000) { 'up' } else { 'down' }
  "API: $a  Web: $w  Sidecar: $s"
}
function StartAll {
  try {
    if (Test-Path $startAll) {
      Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$startAll`"" -WorkingDirectory $root | Out-Null
      return
    }
    $pyApi  = Join-Path $apiRoot  ".venv\Scripts\python.exe"; if(-not (Test-Path $pyApi )){ $pyApi  = "python" }
    $pySide = Join-Path $sideRoot ".venv\Scripts\python.exe"; if(-not (Test-Path $pySide)){ $pySide = "python" }

    Start-Process $pyApi  "-m uvicorn main:app --host 0.0.0.0 --port 8000" -WorkingDirectory $apiRoot  | Out-Null
    if (Test-Path (Join-Path $webRoot 'dist')) {
      Start-Process "$env:APPDATA\npm\npx.cmd" "serve -s dist -l 5175" -WorkingDirectory $webRoot | Out-Null
    } else {
      Start-Process "$env:APPDATA\npm\npm.cmd" "run dev" -WorkingDirectory $webRoot | Out-Null
    }
    $entry = if (Test-Path (Join-Path $sideRoot "sidecar.py")) { "sidecar.py" } else { "main.py" }
    Start-Process $pySide $entry -WorkingDirectory $sideRoot | Out-Null
  } catch {}
}
function StopAll {
  try {
    if (Test-Path $stopAll) {
      Start-Process -FilePath "$PSHOME\powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$stopAll`"" -WorkingDirectory $root | Out-Null
    }
    Get-Process -ErrorAction SilentlyContinue | Where-Object {
      ($_.Name -in @('node','python','python3')) -and ($_.Path -like "$root*")
    } | Stop-Process -Force
  } catch {}
}
function ShowStatus {
  $msg = StatusText
  $ni.BalloonTipTitle = "Mason status"
  $ni.BalloonTipText  = $msg
  $ni.ShowBalloonTip(2000)
  $ni.Text = "Mason Tray - $msg"
}

# Notify icon + menu
$ni = New-Object System.Windows.Forms.NotifyIcon
$ni.Icon    = [System.Drawing.SystemIcons]::Application
$ni.Visible = $true
$ni.Text    = "Mason Tray - starting..."

$cm = New-Object System.Windows.Forms.ContextMenuStrip
$miStart   = $cm.Items.Add("Start")
$miStop    = $cm.Items.Add("Stop")
$miRestart = $cm.Items.Add("Restart")
$miStatus  = $cm.Items.Add("Status")
$cm.Items.Add("-") | Out-Null
$miExit    = $cm.Items.Add("Exit")

$miStart.add_Click({ StartAll; Start-Sleep -Milliseconds 800; ShowStatus })
$miStop.add_Click({  StopAll; Start-Sleep -Milliseconds 800; ShowStatus })
$miRestart.add_Click({ StopAll; Start-Sleep -Seconds 1; StartAll; Start-Sleep -Milliseconds 800; ShowStatus })
$miStatus.add_Click({ ShowStatus })
$miExit.add_Click({ $ni.Visible = $false; [System.Windows.Forms.Application]::Exit() })

$ni.ContextMenuStrip = $cm
$ni.add_DoubleClick({ ShowStatus })

# Periodic tooltip refresh
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 8000
$timer.add_Tick({ $ni.Text = "Mason Tray - " + (StatusText) })
$timer.Start()

[System.Windows.Forms.Application]::Run()
