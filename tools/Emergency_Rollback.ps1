# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rel  = Join-Path $Base "dist\releases"
$last = Get-ChildItem $Rel -Filter "*.zip" | Sort-Object LastWriteTime -desc | Select-Object -First 1
if(-not $last){ Write-Host "No release found."; exit 1 }
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Atomic_Deploy.ps1") -Bundle $last.FullName

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rel  = Join-Path $Base "dist\releases"
$last = Get-ChildItem $Rel -Filter "*.zip" | Sort-Object LastWriteTime -desc | Select-Object -First 1
if(-not $last){ Write-Host "No release found."; exit 1 }
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Atomic_Deploy.ps1") -Bundle $last.FullName

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rel  = Join-Path $Base "dist\releases"
$last = Get-ChildItem $Rel -Filter "*.zip" | Sort-Object LastWriteTime -desc | Select-Object -First 1
if(-not $last){ Write-Host "No release found."; exit 1 }
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Atomic_Deploy.ps1") -Bundle $last.FullName

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rel  = Join-Path $Base "dist\releases"
$last = Get-ChildItem $Rel -Filter "*.zip" | Sort-Object LastWriteTime -desc | Select-Object -First 1
if(-not $last){ Write-Host "No release found."; exit 1 }
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Atomic_Deploy.ps1") -Bundle $last.FullName

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rel  = Join-Path $Base "dist\releases"
$last = Get-ChildItem $Rel -Filter "*.zip" | Sort-Object LastWriteTime -desc | Select-Object -First 1
if(-not $last){ Write-Host "No release found."; exit 1 }
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Atomic_Deploy.ps1") -Bundle $last.FullName

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rel  = Join-Path $Base "dist\releases"
$last = Get-ChildItem $Rel -Filter "*.zip" | Sort-Object LastWriteTime -desc | Select-Object -First 1
if(-not $last){ Write-Host "No release found."; exit 1 }
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Atomic_Deploy.ps1") -Bundle $last.FullName

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rel  = Join-Path $Base "dist\releases"
$last = Get-ChildItem $Rel -Filter "*.zip" | Sort-Object LastWriteTime -desc | Select-Object -First 1
if(-not $last){ Write-Host "No release found."; exit 1 }
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Atomic_Deploy.ps1") -Bundle $last.FullName

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rel  = Join-Path $Base "dist\releases"
$last = Get-ChildItem $Rel -Filter "*.zip" | Sort-Object LastWriteTime -desc | Select-Object -First 1
if(-not $last){ Write-Host "No release found."; exit 1 }
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Atomic_Deploy.ps1") -Bundle $last.FullName

