$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$ks  = Join-Path $Base 'tools\safety\KillSwitch.ps1'
$wsh = New-Object -ComObject WScript.Shell
$desk= [Environment]::GetFolderPath('Desktop')
$lnk = Join-Path $desk 'Mason Kill Switch.lnk'
$sc  = $wsh.CreateShortcut($lnk)
$sc.TargetPath   = 'powershell.exe'
$sc.Arguments    = "-NoProfile -ExecutionPolicy Bypass -File `"$ks`""
$sc.WorkingDirectory = $Base
$sc.WindowStyle  = 7
$sc.IconLocation = "$env:SystemRoot\System32\imageres.dll,76"
$sc.Hotkey       = 'CTRL+ALT+K'
$sc.Save()
Write-Host "Kill Switch shortcut created on Desktop with hotkey Ctrl+Alt+K."
