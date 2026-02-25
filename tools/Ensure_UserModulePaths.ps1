# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Missing Log.psm1 at $src" }
$dest = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\Log\Log.psm1"
New-Item (Split-Path $dest) -ItemType Directory -ea SilentlyContinue | Out-Null
Copy-Item $src $dest -Force
# try import from module path
try{
  Import-Module Log -Force -DisableNameChecking
  "OK: Log module available in user scope -> $dest"
}catch{
  "WARN: Import-Module Log failed; using direct path." | Write-Host
  Import-Module $src -Force -DisableNameChecking
  "OK: Log module loaded from services path."
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Missing Log.psm1 at $src" }
$dest = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\Log\Log.psm1"
New-Item (Split-Path $dest) -ItemType Directory -ea SilentlyContinue | Out-Null
Copy-Item $src $dest -Force
# try import from module path
try{
  Import-Module Log -Force -DisableNameChecking
  "OK: Log module available in user scope -> $dest"
}catch{
  "WARN: Import-Module Log failed; using direct path." | Write-Host
  Import-Module $src -Force -DisableNameChecking
  "OK: Log module loaded from services path."
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Missing Log.psm1 at $src" }
$dest = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\Log\Log.psm1"
New-Item (Split-Path $dest) -ItemType Directory -ea SilentlyContinue | Out-Null
Copy-Item $src $dest -Force
# try import from module path
try{
  Import-Module Log -Force -DisableNameChecking
  "OK: Log module available in user scope -> $dest"
}catch{
  "WARN: Import-Module Log failed; using direct path." | Write-Host
  Import-Module $src -Force -DisableNameChecking
  "OK: Log module loaded from services path."
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Missing Log.psm1 at $src" }
$dest = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\Log\Log.psm1"
New-Item (Split-Path $dest) -ItemType Directory -ea SilentlyContinue | Out-Null
Copy-Item $src $dest -Force
# try import from module path
try{
  Import-Module Log -Force -DisableNameChecking
  "OK: Log module available in user scope -> $dest"
}catch{
  "WARN: Import-Module Log failed; using direct path." | Write-Host
  Import-Module $src -Force -DisableNameChecking
  "OK: Log module loaded from services path."
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Missing Log.psm1 at $src" }
$dest = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\Log\Log.psm1"
New-Item (Split-Path $dest) -ItemType Directory -ea SilentlyContinue | Out-Null
Copy-Item $src $dest -Force
# try import from module path
try{
  Import-Module Log -Force -DisableNameChecking
  "OK: Log module available in user scope -> $dest"
}catch{
  "WARN: Import-Module Log failed; using direct path." | Write-Host
  Import-Module $src -Force -DisableNameChecking
  "OK: Log module loaded from services path."
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Missing Log.psm1 at $src" }
$dest = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\Log\Log.psm1"
New-Item (Split-Path $dest) -ItemType Directory -ea SilentlyContinue | Out-Null
Copy-Item $src $dest -Force
# try import from module path
try{
  Import-Module Log -Force -DisableNameChecking
  "OK: Log module available in user scope -> $dest"
}catch{
  "WARN: Import-Module Log failed; using direct path." | Write-Host
  Import-Module $src -Force -DisableNameChecking
  "OK: Log module loaded from services path."
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Missing Log.psm1 at $src" }
$dest = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\Log\Log.psm1"
New-Item (Split-Path $dest) -ItemType Directory -ea SilentlyContinue | Out-Null
Copy-Item $src $dest -Force
# try import from module path
try{
  Import-Module Log -Force -DisableNameChecking
  "OK: Log module available in user scope -> $dest"
}catch{
  "WARN: Import-Module Log failed; using direct path." | Write-Host
  Import-Module $src -Force -DisableNameChecking
  "OK: Log module loaded from services path."
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Missing Log.psm1 at $src" }
$dest = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules\Log\Log.psm1"
New-Item (Split-Path $dest) -ItemType Directory -ea SilentlyContinue | Out-Null
Copy-Item $src $dest -Force
# try import from module path
try{
  Import-Module Log -Force -DisableNameChecking
  "OK: Log module available in user scope -> $dest"
}catch{
  "WARN: Import-Module Log failed; using direct path." | Write-Host
  Import-Module $src -Force -DisableNameChecking
  "OK: Log module loaded from services path."
}

