$ErrorActionPreference = "Stop"
$here = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent "$($MyInvocation.MyCommand.Path)" }
Start-Process -FilePath powershell -WorkingDirectory (Join-Path $here 'backend') -ArgumentList @('-NoExit','-File', (Join-Path $here 'backend\Start-Backend.ps1'))
Start-Process -FilePath powershell -WorkingDirectory (Join-Path $here 'mobile')  -ArgumentList @('-NoExit','-File', (Join-Path $here 'mobile\Start-Mobile.ps1'))
