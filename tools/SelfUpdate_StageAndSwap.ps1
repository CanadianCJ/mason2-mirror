# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Stg  = Join-Path $Base "dist\stage"
$Rel  = Join-Path $Base "dist\releases"
$Rb   = Join-Path $Base "dist\rollback"
ni $Stg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rb  -ItemType Directory -ea SilentlyContinue | Out-Null
# demo: copy current tools as "bundle"
$tag = Get-Date -Format 'yyyyMMdd-HHmmss'
$zip = Join-Path $Rel ("mason2-"+$tag+".zip")
if(!(Test-Path $zip)){ Compress-Archive -Path (Join-Path $Base '*') -DestinationPath $zip -Force -CompressionLevel Optimal }
# "atomic" swap would be directory rename; here we just record intent
Add-Content (Join-Path $Base 'logs\watchdog\watchdog_log.txt') ("[{0}] SelfUpdate: prepared bundle {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $zip)


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Stg  = Join-Path $Base "dist\stage"
$Rel  = Join-Path $Base "dist\releases"
$Rb   = Join-Path $Base "dist\rollback"
ni $Stg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rb  -ItemType Directory -ea SilentlyContinue | Out-Null
# demo: copy current tools as "bundle"
$tag = Get-Date -Format 'yyyyMMdd-HHmmss'
$zip = Join-Path $Rel ("mason2-"+$tag+".zip")
if(!(Test-Path $zip)){ Compress-Archive -Path (Join-Path $Base '*') -DestinationPath $zip -Force -CompressionLevel Optimal }
# "atomic" swap would be directory rename; here we just record intent
Add-Content (Join-Path $Base 'logs\watchdog\watchdog_log.txt') ("[{0}] SelfUpdate: prepared bundle {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $zip)


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Stg  = Join-Path $Base "dist\stage"
$Rel  = Join-Path $Base "dist\releases"
$Rb   = Join-Path $Base "dist\rollback"
ni $Stg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rb  -ItemType Directory -ea SilentlyContinue | Out-Null
# demo: copy current tools as "bundle"
$tag = Get-Date -Format 'yyyyMMdd-HHmmss'
$zip = Join-Path $Rel ("mason2-"+$tag+".zip")
if(!(Test-Path $zip)){ Compress-Archive -Path (Join-Path $Base '*') -DestinationPath $zip -Force -CompressionLevel Optimal }
# "atomic" swap would be directory rename; here we just record intent
Add-Content (Join-Path $Base 'logs\watchdog\watchdog_log.txt') ("[{0}] SelfUpdate: prepared bundle {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $zip)


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Stg  = Join-Path $Base "dist\stage"
$Rel  = Join-Path $Base "dist\releases"
$Rb   = Join-Path $Base "dist\rollback"
ni $Stg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rb  -ItemType Directory -ea SilentlyContinue | Out-Null
# demo: copy current tools as "bundle"
$tag = Get-Date -Format 'yyyyMMdd-HHmmss'
$zip = Join-Path $Rel ("mason2-"+$tag+".zip")
if(!(Test-Path $zip)){ Compress-Archive -Path (Join-Path $Base '*') -DestinationPath $zip -Force -CompressionLevel Optimal }
# "atomic" swap would be directory rename; here we just record intent
Add-Content (Join-Path $Base 'logs\watchdog\watchdog_log.txt') ("[{0}] SelfUpdate: prepared bundle {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $zip)


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Stg  = Join-Path $Base "dist\stage"
$Rel  = Join-Path $Base "dist\releases"
$Rb   = Join-Path $Base "dist\rollback"
ni $Stg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rb  -ItemType Directory -ea SilentlyContinue | Out-Null
# demo: copy current tools as "bundle"
$tag = Get-Date -Format 'yyyyMMdd-HHmmss'
$zip = Join-Path $Rel ("mason2-"+$tag+".zip")
if(!(Test-Path $zip)){ Compress-Archive -Path (Join-Path $Base '*') -DestinationPath $zip -Force -CompressionLevel Optimal }
# "atomic" swap would be directory rename; here we just record intent
Add-Content (Join-Path $Base 'logs\watchdog\watchdog_log.txt') ("[{0}] SelfUpdate: prepared bundle {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $zip)


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Stg  = Join-Path $Base "dist\stage"
$Rel  = Join-Path $Base "dist\releases"
$Rb   = Join-Path $Base "dist\rollback"
ni $Stg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rb  -ItemType Directory -ea SilentlyContinue | Out-Null
# demo: copy current tools as "bundle"
$tag = Get-Date -Format 'yyyyMMdd-HHmmss'
$zip = Join-Path $Rel ("mason2-"+$tag+".zip")
if(!(Test-Path $zip)){ Compress-Archive -Path (Join-Path $Base '*') -DestinationPath $zip -Force -CompressionLevel Optimal }
# "atomic" swap would be directory rename; here we just record intent
Add-Content (Join-Path $Base 'logs\watchdog\watchdog_log.txt') ("[{0}] SelfUpdate: prepared bundle {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $zip)


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Stg  = Join-Path $Base "dist\stage"
$Rel  = Join-Path $Base "dist\releases"
$Rb   = Join-Path $Base "dist\rollback"
ni $Stg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rb  -ItemType Directory -ea SilentlyContinue | Out-Null
# demo: copy current tools as "bundle"
$tag = Get-Date -Format 'yyyyMMdd-HHmmss'
$zip = Join-Path $Rel ("mason2-"+$tag+".zip")
if(!(Test-Path $zip)){ Compress-Archive -Path (Join-Path $Base '*') -DestinationPath $zip -Force -CompressionLevel Optimal }
# "atomic" swap would be directory rename; here we just record intent
Add-Content (Join-Path $Base 'logs\watchdog\watchdog_log.txt') ("[{0}] SelfUpdate: prepared bundle {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $zip)


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Stg  = Join-Path $Base "dist\stage"
$Rel  = Join-Path $Base "dist\releases"
$Rb   = Join-Path $Base "dist\rollback"
ni $Stg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Rb  -ItemType Directory -ea SilentlyContinue | Out-Null
# demo: copy current tools as "bundle"
$tag = Get-Date -Format 'yyyyMMdd-HHmmss'
$zip = Join-Path $Rel ("mason2-"+$tag+".zip")
if(!(Test-Path $zip)){ Compress-Archive -Path (Join-Path $Base '*') -DestinationPath $zip -Force -CompressionLevel Optimal }
# "atomic" swap would be directory rename; here we just record intent
Add-Content (Join-Path $Base 'logs\watchdog\watchdog_log.txt') ("[{0}] SelfUpdate: prepared bundle {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $zip)


