# Stamped: 2025-11-05T17:02:01
# Ensure a newline after the Preflight gate so "try{" isn't stuck to it.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Normalize any `}try{` glued to the preflight gate line.
$src = $src -replace '(\)\s*\{\s*return\s*\}\s*)try\s*\{', '$1' + "`r`n    try{"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Fixed Preflight gate newline. Backup: $bak"

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Ensure a newline after the Preflight gate so "try{" isn't stuck to it.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Normalize any `}try{` glued to the preflight gate line.
$src = $src -replace '(\)\s*\{\s*return\s*\}\s*)try\s*\{', '$1' + "`r`n    try{"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Fixed Preflight gate newline. Backup: $bak"

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Ensure a newline after the Preflight gate so "try{" isn't stuck to it.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Normalize any `}try{` glued to the preflight gate line.
$src = $src -replace '(\)\s*\{\s*return\s*\}\s*)try\s*\{', '$1' + "`r`n    try{"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Fixed Preflight gate newline. Backup: $bak"

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Ensure a newline after the Preflight gate so "try{" isn't stuck to it.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Normalize any `}try{` glued to the preflight gate line.
$src = $src -replace '(\)\s*\{\s*return\s*\}\s*)try\s*\{', '$1' + "`r`n    try{"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Fixed Preflight gate newline. Backup: $bak"

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Ensure a newline after the Preflight gate so "try{" isn't stuck to it.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Normalize any `}try{` glued to the preflight gate line.
$src = $src -replace '(\)\s*\{\s*return\s*\}\s*)try\s*\{', '$1' + "`r`n    try{"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Fixed Preflight gate newline. Backup: $bak"

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Ensure a newline after the Preflight gate so "try{" isn't stuck to it.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Normalize any `}try{` glued to the preflight gate line.
$src = $src -replace '(\)\s*\{\s*return\s*\}\s*)try\s*\{', '$1' + "`r`n    try{"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Fixed Preflight gate newline. Backup: $bak"

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Ensure a newline after the Preflight gate so "try{" isn't stuck to it.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Normalize any `}try{` glued to the preflight gate line.
$src = $src -replace '(\)\s*\{\s*return\s*\}\s*)try\s*\{', '$1' + "`r`n    try{"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Fixed Preflight gate newline. Backup: $bak"

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Ensure a newline after the Preflight gate so "try{" isn't stuck to it.
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
$dash = Join-Path $Base 'tools\Start_DashboardWindow.ps1'
if(!(Test-Path $dash)){ throw "Dashboard not found: $dash" }

$src = Get-Content -Raw -LiteralPath $dash
$bak = "$dash.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item -LiteralPath $dash -Destination $bak -Force

# Normalize any `}try{` glued to the preflight gate line.
$src = $src -replace '(\)\s*\{\s*return\s*\}\s*)try\s*\{', '$1' + "`r`n    try{"

Set-Content -LiteralPath $dash -Value $src -Encoding UTF8
Write-Host "Fixed Preflight gate newline. Backup: $bak"

