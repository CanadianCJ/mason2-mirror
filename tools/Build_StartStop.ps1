# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_StartStop.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$SOut = @"
# Start_All.ps1
`$Base = Join-Path `$env:USERPROFILE 'Desktop\Mason2'
Write-Host '[INFO] Starting Mason2 services...'
# UI (native)
`$wpf = Join-Path `$Base 'tools\Start_DashboardWindow.ps1'
if(Test-Path `$wpf){ Start-Process powershell -ArgumentList '-NoProfile','-Sta','-ExecutionPolicy','Bypass','-File',"`"`$wpf`"" }
# Legacy launcher (optional)
`$act = Join-Path `$Base 'ActivateAndOpenDashboard.ps1'
if(Test-Path `$act){ powershell -NoProfile -ExecutionPolicy Bypass -File "`$act" | Out-Null }
Write-Host '[ OK ] Start_All done.'
"@
$POut = @"
# Stop_All.ps1
Write-Host '[INFO] Stopping Mason2 services...'
Get-Process esbuild -ea SilentlyContinue | Stop-Process -Force -ea SilentlyContinue
# (Add more processes to stop here if/when they exist)
Write-Host '[ OK ] Stop_All done.'
"@
$StartPath = Join-Path $Base 'Start_All.ps1'
$StopPath  = Join-Path $Base 'Stop_All.ps1'
$SOut | Set-Content $StartPath -Encoding UTF8
$POut | Set-Content $StopPath  -Encoding UTF8
"ok" | Set-Content (Join-Path (Join-Path $Base 'reports\signals') 'system-structure-startstop.ok') -Encoding ASCII
Write-Host "[ OK ] Start/Stop scripts written"


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_StartStop.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$SOut = @"
# Start_All.ps1
`$Base = Join-Path `$env:USERPROFILE 'Desktop\Mason2'
Write-Host '[INFO] Starting Mason2 services...'
# UI (native)
`$wpf = Join-Path `$Base 'tools\Start_DashboardWindow.ps1'
if(Test-Path `$wpf){ Start-Process powershell -ArgumentList '-NoProfile','-Sta','-ExecutionPolicy','Bypass','-File',"`"`$wpf`"" }
# Legacy launcher (optional)
`$act = Join-Path `$Base 'ActivateAndOpenDashboard.ps1'
if(Test-Path `$act){ powershell -NoProfile -ExecutionPolicy Bypass -File "`$act" | Out-Null }
Write-Host '[ OK ] Start_All done.'
"@
$POut = @"
# Stop_All.ps1
Write-Host '[INFO] Stopping Mason2 services...'
Get-Process esbuild -ea SilentlyContinue | Stop-Process -Force -ea SilentlyContinue
# (Add more processes to stop here if/when they exist)
Write-Host '[ OK ] Stop_All done.'
"@
$StartPath = Join-Path $Base 'Start_All.ps1'
$StopPath  = Join-Path $Base 'Stop_All.ps1'
$SOut | Set-Content $StartPath -Encoding UTF8
$POut | Set-Content $StopPath  -Encoding UTF8
"ok" | Set-Content (Join-Path (Join-Path $Base 'reports\signals') 'system-structure-startstop.ok') -Encoding ASCII
Write-Host "[ OK ] Start/Stop scripts written"


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_StartStop.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$SOut = @"
# Start_All.ps1
`$Base = Join-Path `$env:USERPROFILE 'Desktop\Mason2'
Write-Host '[INFO] Starting Mason2 services...'
# UI (native)
`$wpf = Join-Path `$Base 'tools\Start_DashboardWindow.ps1'
if(Test-Path `$wpf){ Start-Process powershell -ArgumentList '-NoProfile','-Sta','-ExecutionPolicy','Bypass','-File',"`"`$wpf`"" }
# Legacy launcher (optional)
`$act = Join-Path `$Base 'ActivateAndOpenDashboard.ps1'
if(Test-Path `$act){ powershell -NoProfile -ExecutionPolicy Bypass -File "`$act" | Out-Null }
Write-Host '[ OK ] Start_All done.'
"@
$POut = @"
# Stop_All.ps1
Write-Host '[INFO] Stopping Mason2 services...'
Get-Process esbuild -ea SilentlyContinue | Stop-Process -Force -ea SilentlyContinue
# (Add more processes to stop here if/when they exist)
Write-Host '[ OK ] Stop_All done.'
"@
$StartPath = Join-Path $Base 'Start_All.ps1'
$StopPath  = Join-Path $Base 'Stop_All.ps1'
$SOut | Set-Content $StartPath -Encoding UTF8
$POut | Set-Content $StopPath  -Encoding UTF8
"ok" | Set-Content (Join-Path (Join-Path $Base 'reports\signals') 'system-structure-startstop.ok') -Encoding ASCII
Write-Host "[ OK ] Start/Stop scripts written"


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_StartStop.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$SOut = @"
# Start_All.ps1
`$Base = Join-Path `$env:USERPROFILE 'Desktop\Mason2'
Write-Host '[INFO] Starting Mason2 services...'
# UI (native)
`$wpf = Join-Path `$Base 'tools\Start_DashboardWindow.ps1'
if(Test-Path `$wpf){ Start-Process powershell -ArgumentList '-NoProfile','-Sta','-ExecutionPolicy','Bypass','-File',"`"`$wpf`"" }
# Legacy launcher (optional)
`$act = Join-Path `$Base 'ActivateAndOpenDashboard.ps1'
if(Test-Path `$act){ powershell -NoProfile -ExecutionPolicy Bypass -File "`$act" | Out-Null }
Write-Host '[ OK ] Start_All done.'
"@
$POut = @"
# Stop_All.ps1
Write-Host '[INFO] Stopping Mason2 services...'
Get-Process esbuild -ea SilentlyContinue | Stop-Process -Force -ea SilentlyContinue
# (Add more processes to stop here if/when they exist)
Write-Host '[ OK ] Stop_All done.'
"@
$StartPath = Join-Path $Base 'Start_All.ps1'
$StopPath  = Join-Path $Base 'Stop_All.ps1'
$SOut | Set-Content $StartPath -Encoding UTF8
$POut | Set-Content $StopPath  -Encoding UTF8
"ok" | Set-Content (Join-Path (Join-Path $Base 'reports\signals') 'system-structure-startstop.ok') -Encoding ASCII
Write-Host "[ OK ] Start/Stop scripts written"


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_StartStop.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$SOut = @"
# Start_All.ps1
`$Base = Join-Path `$env:USERPROFILE 'Desktop\Mason2'
Write-Host '[INFO] Starting Mason2 services...'
# UI (native)
`$wpf = Join-Path `$Base 'tools\Start_DashboardWindow.ps1'
if(Test-Path `$wpf){ Start-Process powershell -ArgumentList '-NoProfile','-Sta','-ExecutionPolicy','Bypass','-File',"`"`$wpf`"" }
# Legacy launcher (optional)
`$act = Join-Path `$Base 'ActivateAndOpenDashboard.ps1'
if(Test-Path `$act){ powershell -NoProfile -ExecutionPolicy Bypass -File "`$act" | Out-Null }
Write-Host '[ OK ] Start_All done.'
"@
$POut = @"
# Stop_All.ps1
Write-Host '[INFO] Stopping Mason2 services...'
Get-Process esbuild -ea SilentlyContinue | Stop-Process -Force -ea SilentlyContinue
# (Add more processes to stop here if/when they exist)
Write-Host '[ OK ] Stop_All done.'
"@
$StartPath = Join-Path $Base 'Start_All.ps1'
$StopPath  = Join-Path $Base 'Stop_All.ps1'
$SOut | Set-Content $StartPath -Encoding UTF8
$POut | Set-Content $StopPath  -Encoding UTF8
"ok" | Set-Content (Join-Path (Join-Path $Base 'reports\signals') 'system-structure-startstop.ok') -Encoding ASCII
Write-Host "[ OK ] Start/Stop scripts written"


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_StartStop.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$SOut = @"
# Start_All.ps1
`$Base = Join-Path `$env:USERPROFILE 'Desktop\Mason2'
Write-Host '[INFO] Starting Mason2 services...'
# UI (native)
`$wpf = Join-Path `$Base 'tools\Start_DashboardWindow.ps1'
if(Test-Path `$wpf){ Start-Process powershell -ArgumentList '-NoProfile','-Sta','-ExecutionPolicy','Bypass','-File',"`"`$wpf`"" }
# Legacy launcher (optional)
`$act = Join-Path `$Base 'ActivateAndOpenDashboard.ps1'
if(Test-Path `$act){ powershell -NoProfile -ExecutionPolicy Bypass -File "`$act" | Out-Null }
Write-Host '[ OK ] Start_All done.'
"@
$POut = @"
# Stop_All.ps1
Write-Host '[INFO] Stopping Mason2 services...'
Get-Process esbuild -ea SilentlyContinue | Stop-Process -Force -ea SilentlyContinue
# (Add more processes to stop here if/when they exist)
Write-Host '[ OK ] Stop_All done.'
"@
$StartPath = Join-Path $Base 'Start_All.ps1'
$StopPath  = Join-Path $Base 'Stop_All.ps1'
$SOut | Set-Content $StartPath -Encoding UTF8
$POut | Set-Content $StopPath  -Encoding UTF8
"ok" | Set-Content (Join-Path (Join-Path $Base 'reports\signals') 'system-structure-startstop.ok') -Encoding ASCII
Write-Host "[ OK ] Start/Stop scripts written"


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_StartStop.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$SOut = @"
# Start_All.ps1
`$Base = Join-Path `$env:USERPROFILE 'Desktop\Mason2'
Write-Host '[INFO] Starting Mason2 services...'
# UI (native)
`$wpf = Join-Path `$Base 'tools\Start_DashboardWindow.ps1'
if(Test-Path `$wpf){ Start-Process powershell -ArgumentList '-NoProfile','-Sta','-ExecutionPolicy','Bypass','-File',"`"`$wpf`"" }
# Legacy launcher (optional)
`$act = Join-Path `$Base 'ActivateAndOpenDashboard.ps1'
if(Test-Path `$act){ powershell -NoProfile -ExecutionPolicy Bypass -File "`$act" | Out-Null }
Write-Host '[ OK ] Start_All done.'
"@
$POut = @"
# Stop_All.ps1
Write-Host '[INFO] Stopping Mason2 services...'
Get-Process esbuild -ea SilentlyContinue | Stop-Process -Force -ea SilentlyContinue
# (Add more processes to stop here if/when they exist)
Write-Host '[ OK ] Stop_All done.'
"@
$StartPath = Join-Path $Base 'Start_All.ps1'
$StopPath  = Join-Path $Base 'Stop_All.ps1'
$SOut | Set-Content $StartPath -Encoding UTF8
$POut | Set-Content $StopPath  -Encoding UTF8
"ok" | Set-Content (Join-Path (Join-Path $Base 'reports\signals') 'system-structure-startstop.ok') -Encoding ASCII
Write-Host "[ OK ] Start/Stop scripts written"


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_StartStop.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$SOut = @"
# Start_All.ps1
`$Base = Join-Path `$env:USERPROFILE 'Desktop\Mason2'
Write-Host '[INFO] Starting Mason2 services...'
# UI (native)
`$wpf = Join-Path `$Base 'tools\Start_DashboardWindow.ps1'
if(Test-Path `$wpf){ Start-Process powershell -ArgumentList '-NoProfile','-Sta','-ExecutionPolicy','Bypass','-File',"`"`$wpf`"" }
# Legacy launcher (optional)
`$act = Join-Path `$Base 'ActivateAndOpenDashboard.ps1'
if(Test-Path `$act){ powershell -NoProfile -ExecutionPolicy Bypass -File "`$act" | Out-Null }
Write-Host '[ OK ] Start_All done.'
"@
$POut = @"
# Stop_All.ps1
Write-Host '[INFO] Stopping Mason2 services...'
Get-Process esbuild -ea SilentlyContinue | Stop-Process -Force -ea SilentlyContinue
# (Add more processes to stop here if/when they exist)
Write-Host '[ OK ] Stop_All done.'
"@
$StartPath = Join-Path $Base 'Start_All.ps1'
$StopPath  = Join-Path $Base 'Stop_All.ps1'
$SOut | Set-Content $StartPath -Encoding UTF8
$POut | Set-Content $StopPath  -Encoding UTF8
"ok" | Set-Content (Join-Path (Join-Path $Base 'reports\signals') 'system-structure-startstop.ok') -Encoding ASCII
Write-Host "[ OK ] Start/Stop scripts written"


