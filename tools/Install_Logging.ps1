# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
# Install_Logging.ps1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â copy Log module to a standard module path (all-users if possible, else current user)
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Log.psm1 not found at $src" }
$targets = @(
  "$env:ProgramFiles\WindowsPowerShell\Modules\Log\Log.psm1",  # all users (admin)
  "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Log\Log.psm1" # current user
)
$done = $false
foreach($t in $targets){
  try{
    $dir = Split-Path $t
    ni $dir -ItemType Directory -Force -ea SilentlyContinue | Out-Null
    Copy-Item $src $t -Force
    $done = $true; Write-Host "Installed to: $t"; break
  }catch{ }
}
if(-not $done){ Write-Host "Could not install to standard module paths. Keeping local module in services." }
try{
  Import-Module Log -Force -DisableNameChecking
  Write-Host "Log module import test OK."
}catch{
  Write-Host "Import-Module Log failed; falling back to direct path."
  Import-Module $src -Force -DisableNameChecking
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
# Install_Logging.ps1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â copy Log module to a standard module path (all-users if possible, else current user)
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Log.psm1 not found at $src" }
$targets = @(
  "$env:ProgramFiles\WindowsPowerShell\Modules\Log\Log.psm1",  # all users (admin)
  "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Log\Log.psm1" # current user
)
$done = $false
foreach($t in $targets){
  try{
    $dir = Split-Path $t
    ni $dir -ItemType Directory -Force -ea SilentlyContinue | Out-Null
    Copy-Item $src $t -Force
    $done = $true; Write-Host "Installed to: $t"; break
  }catch{ }
}
if(-not $done){ Write-Host "Could not install to standard module paths. Keeping local module in services." }
try{
  Import-Module Log -Force -DisableNameChecking
  Write-Host "Log module import test OK."
}catch{
  Write-Host "Import-Module Log failed; falling back to direct path."
  Import-Module $src -Force -DisableNameChecking
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
# Install_Logging.ps1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â copy Log module to a standard module path (all-users if possible, else current user)
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Log.psm1 not found at $src" }
$targets = @(
  "$env:ProgramFiles\WindowsPowerShell\Modules\Log\Log.psm1",  # all users (admin)
  "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Log\Log.psm1" # current user
)
$done = $false
foreach($t in $targets){
  try{
    $dir = Split-Path $t
    ni $dir -ItemType Directory -Force -ea SilentlyContinue | Out-Null
    Copy-Item $src $t -Force
    $done = $true; Write-Host "Installed to: $t"; break
  }catch{ }
}
if(-not $done){ Write-Host "Could not install to standard module paths. Keeping local module in services." }
try{
  Import-Module Log -Force -DisableNameChecking
  Write-Host "Log module import test OK."
}catch{
  Write-Host "Import-Module Log failed; falling back to direct path."
  Import-Module $src -Force -DisableNameChecking
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
# Install_Logging.ps1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â copy Log module to a standard module path (all-users if possible, else current user)
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Log.psm1 not found at $src" }
$targets = @(
  "$env:ProgramFiles\WindowsPowerShell\Modules\Log\Log.psm1",  # all users (admin)
  "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Log\Log.psm1" # current user
)
$done = $false
foreach($t in $targets){
  try{
    $dir = Split-Path $t
    ni $dir -ItemType Directory -Force -ea SilentlyContinue | Out-Null
    Copy-Item $src $t -Force
    $done = $true; Write-Host "Installed to: $t"; break
  }catch{ }
}
if(-not $done){ Write-Host "Could not install to standard module paths. Keeping local module in services." }
try{
  Import-Module Log -Force -DisableNameChecking
  Write-Host "Log module import test OK."
}catch{
  Write-Host "Import-Module Log failed; falling back to direct path."
  Import-Module $src -Force -DisableNameChecking
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
# Install_Logging.ps1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â copy Log module to a standard module path (all-users if possible, else current user)
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Log.psm1 not found at $src" }
$targets = @(
  "$env:ProgramFiles\WindowsPowerShell\Modules\Log\Log.psm1",  # all users (admin)
  "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Log\Log.psm1" # current user
)
$done = $false
foreach($t in $targets){
  try{
    $dir = Split-Path $t
    ni $dir -ItemType Directory -Force -ea SilentlyContinue | Out-Null
    Copy-Item $src $t -Force
    $done = $true; Write-Host "Installed to: $t"; break
  }catch{ }
}
if(-not $done){ Write-Host "Could not install to standard module paths. Keeping local module in services." }
try{
  Import-Module Log -Force -DisableNameChecking
  Write-Host "Log module import test OK."
}catch{
  Write-Host "Import-Module Log failed; falling back to direct path."
  Import-Module $src -Force -DisableNameChecking
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
# Install_Logging.ps1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â copy Log module to a standard module path (all-users if possible, else current user)
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Log.psm1 not found at $src" }
$targets = @(
  "$env:ProgramFiles\WindowsPowerShell\Modules\Log\Log.psm1",  # all users (admin)
  "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Log\Log.psm1" # current user
)
$done = $false
foreach($t in $targets){
  try{
    $dir = Split-Path $t
    ni $dir -ItemType Directory -Force -ea SilentlyContinue | Out-Null
    Copy-Item $src $t -Force
    $done = $true; Write-Host "Installed to: $t"; break
  }catch{ }
}
if(-not $done){ Write-Host "Could not install to standard module paths. Keeping local module in services." }
try{
  Import-Module Log -Force -DisableNameChecking
  Write-Host "Log module import test OK."
}catch{
  Write-Host "Import-Module Log failed; falling back to direct path."
  Import-Module $src -Force -DisableNameChecking
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
# Install_Logging.ps1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â copy Log module to a standard module path (all-users if possible, else current user)
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Log.psm1 not found at $src" }
$targets = @(
  "$env:ProgramFiles\WindowsPowerShell\Modules\Log\Log.psm1",  # all users (admin)
  "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Log\Log.psm1" # current user
)
$done = $false
foreach($t in $targets){
  try{
    $dir = Split-Path $t
    ni $dir -ItemType Directory -Force -ea SilentlyContinue | Out-Null
    Copy-Item $src $t -Force
    $done = $true; Write-Host "Installed to: $t"; break
  }catch{ }
}
if(-not $done){ Write-Host "Could not install to standard module paths. Keeping local module in services." }
try{
  Import-Module Log -Force -DisableNameChecking
  Write-Host "Log module import test OK."
}catch{
  Write-Host "Import-Module Log failed; falling back to direct path."
  Import-Module $src -Force -DisableNameChecking
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
# Install_Logging.ps1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â copy Log module to a standard module path (all-users if possible, else current user)
$src = Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1"
if(-not (Test-Path $src)){ throw "Log.psm1 not found at $src" }
$targets = @(
  "$env:ProgramFiles\WindowsPowerShell\Modules\Log\Log.psm1",  # all users (admin)
  "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Log\Log.psm1" # current user
)
$done = $false
foreach($t in $targets){
  try{
    $dir = Split-Path $t
    ni $dir -ItemType Directory -Force -ea SilentlyContinue | Out-Null
    Copy-Item $src $t -Force
    $done = $true; Write-Host "Installed to: $t"; break
  }catch{ }
}
if(-not $done){ Write-Host "Could not install to standard module paths. Keeping local module in services." }
try{
  Import-Module Log -Force -DisableNameChecking
  Write-Host "Log module import test OK."
}catch{
  Write-Host "Import-Module Log failed; falling back to direct path."
  Import-Module $src -Force -DisableNameChecking
}

