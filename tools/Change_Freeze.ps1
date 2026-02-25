# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
param([ValidateSet("on","off")][string]$State="on")
$Sig = Join-Path (Join-Path $env:USERPROFILE "Desktop\Mason2\reports") "signals"
$flag = Join-Path $Sig "freeze.on"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
if($State -eq "on"){ "freeze" | Set-Content $flag -Encoding ASCII; "FREEZE ON" }
else{ Remove-Item $flag -Force -ea SilentlyContinue; "FREEZE OFF" }

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
param([ValidateSet("on","off")][string]$State="on")
$Sig = Join-Path (Join-Path $env:USERPROFILE "Desktop\Mason2\reports") "signals"
$flag = Join-Path $Sig "freeze.on"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
if($State -eq "on"){ "freeze" | Set-Content $flag -Encoding ASCII; "FREEZE ON" }
else{ Remove-Item $flag -Force -ea SilentlyContinue; "FREEZE OFF" }

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
param([ValidateSet("on","off")][string]$State="on")
$Sig = Join-Path (Join-Path $env:USERPROFILE "Desktop\Mason2\reports") "signals"
$flag = Join-Path $Sig "freeze.on"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
if($State -eq "on"){ "freeze" | Set-Content $flag -Encoding ASCII; "FREEZE ON" }
else{ Remove-Item $flag -Force -ea SilentlyContinue; "FREEZE OFF" }

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
param([ValidateSet("on","off")][string]$State="on")
$Sig = Join-Path (Join-Path $env:USERPROFILE "Desktop\Mason2\reports") "signals"
$flag = Join-Path $Sig "freeze.on"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
if($State -eq "on"){ "freeze" | Set-Content $flag -Encoding ASCII; "FREEZE ON" }
else{ Remove-Item $flag -Force -ea SilentlyContinue; "FREEZE OFF" }

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
param([ValidateSet("on","off")][string]$State="on")
$Sig = Join-Path (Join-Path $env:USERPROFILE "Desktop\Mason2\reports") "signals"
$flag = Join-Path $Sig "freeze.on"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
if($State -eq "on"){ "freeze" | Set-Content $flag -Encoding ASCII; "FREEZE ON" }
else{ Remove-Item $flag -Force -ea SilentlyContinue; "FREEZE OFF" }

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
param([ValidateSet("on","off")][string]$State="on")
$Sig = Join-Path (Join-Path $env:USERPROFILE "Desktop\Mason2\reports") "signals"
$flag = Join-Path $Sig "freeze.on"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
if($State -eq "on"){ "freeze" | Set-Content $flag -Encoding ASCII; "FREEZE ON" }
else{ Remove-Item $flag -Force -ea SilentlyContinue; "FREEZE OFF" }

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
param([ValidateSet("on","off")][string]$State="on")
$Sig = Join-Path (Join-Path $env:USERPROFILE "Desktop\Mason2\reports") "signals"
$flag = Join-Path $Sig "freeze.on"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
if($State -eq "on"){ "freeze" | Set-Content $flag -Encoding ASCII; "FREEZE ON" }
else{ Remove-Item $flag -Force -ea SilentlyContinue; "FREEZE OFF" }

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.3
param([ValidateSet("on","off")][string]$State="on")
$Sig = Join-Path (Join-Path $env:USERPROFILE "Desktop\Mason2\reports") "signals"
$flag = Join-Path $Sig "freeze.on"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
if($State -eq "on"){ "freeze" | Set-Content $flag -Encoding ASCII; "FREEZE ON" }
else{ Remove-Item $flag -Force -ea SilentlyContinue; "FREEZE OFF" }

