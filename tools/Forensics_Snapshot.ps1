# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Out = "")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
ni $Snap -ItemType Directory -ea SilentlyContinue | Out-Null
if([string]::IsNullOrWhiteSpace($Out)){ $Out = Join-Path $Snap ("forensics-"+(Get-Date -Format 'yyyyMMdd-HHmmss')+".zip") }
$tmp = Join-Path $Snap ("tmp-"+([guid]::NewGuid()))
ni $tmp -ItemType Directory | Out-Null
Copy-Item (Join-Path $Base "logs") -Destination $tmp -Recurse -ea SilentlyContinue
Copy-Item (Join-Path $Base "config") -Destination $tmp -Recurse -ea SilentlyContinue
Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $Out -Force
Remove-Item $tmp -Recurse -Force -ea SilentlyContinue


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Out = "")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
ni $Snap -ItemType Directory -ea SilentlyContinue | Out-Null
if([string]::IsNullOrWhiteSpace($Out)){ $Out = Join-Path $Snap ("forensics-"+(Get-Date -Format 'yyyyMMdd-HHmmss')+".zip") }
$tmp = Join-Path $Snap ("tmp-"+([guid]::NewGuid()))
ni $tmp -ItemType Directory | Out-Null
Copy-Item (Join-Path $Base "logs") -Destination $tmp -Recurse -ea SilentlyContinue
Copy-Item (Join-Path $Base "config") -Destination $tmp -Recurse -ea SilentlyContinue
Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $Out -Force
Remove-Item $tmp -Recurse -Force -ea SilentlyContinue


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Out = "")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
ni $Snap -ItemType Directory -ea SilentlyContinue | Out-Null
if([string]::IsNullOrWhiteSpace($Out)){ $Out = Join-Path $Snap ("forensics-"+(Get-Date -Format 'yyyyMMdd-HHmmss')+".zip") }
$tmp = Join-Path $Snap ("tmp-"+([guid]::NewGuid()))
ni $tmp -ItemType Directory | Out-Null
Copy-Item (Join-Path $Base "logs") -Destination $tmp -Recurse -ea SilentlyContinue
Copy-Item (Join-Path $Base "config") -Destination $tmp -Recurse -ea SilentlyContinue
Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $Out -Force
Remove-Item $tmp -Recurse -Force -ea SilentlyContinue


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Out = "")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
ni $Snap -ItemType Directory -ea SilentlyContinue | Out-Null
if([string]::IsNullOrWhiteSpace($Out)){ $Out = Join-Path $Snap ("forensics-"+(Get-Date -Format 'yyyyMMdd-HHmmss')+".zip") }
$tmp = Join-Path $Snap ("tmp-"+([guid]::NewGuid()))
ni $tmp -ItemType Directory | Out-Null
Copy-Item (Join-Path $Base "logs") -Destination $tmp -Recurse -ea SilentlyContinue
Copy-Item (Join-Path $Base "config") -Destination $tmp -Recurse -ea SilentlyContinue
Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $Out -Force
Remove-Item $tmp -Recurse -Force -ea SilentlyContinue


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Out = "")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
ni $Snap -ItemType Directory -ea SilentlyContinue | Out-Null
if([string]::IsNullOrWhiteSpace($Out)){ $Out = Join-Path $Snap ("forensics-"+(Get-Date -Format 'yyyyMMdd-HHmmss')+".zip") }
$tmp = Join-Path $Snap ("tmp-"+([guid]::NewGuid()))
ni $tmp -ItemType Directory | Out-Null
Copy-Item (Join-Path $Base "logs") -Destination $tmp -Recurse -ea SilentlyContinue
Copy-Item (Join-Path $Base "config") -Destination $tmp -Recurse -ea SilentlyContinue
Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $Out -Force
Remove-Item $tmp -Recurse -Force -ea SilentlyContinue


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Out = "")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
ni $Snap -ItemType Directory -ea SilentlyContinue | Out-Null
if([string]::IsNullOrWhiteSpace($Out)){ $Out = Join-Path $Snap ("forensics-"+(Get-Date -Format 'yyyyMMdd-HHmmss')+".zip") }
$tmp = Join-Path $Snap ("tmp-"+([guid]::NewGuid()))
ni $tmp -ItemType Directory | Out-Null
Copy-Item (Join-Path $Base "logs") -Destination $tmp -Recurse -ea SilentlyContinue
Copy-Item (Join-Path $Base "config") -Destination $tmp -Recurse -ea SilentlyContinue
Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $Out -Force
Remove-Item $tmp -Recurse -Force -ea SilentlyContinue


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Out = "")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
ni $Snap -ItemType Directory -ea SilentlyContinue | Out-Null
if([string]::IsNullOrWhiteSpace($Out)){ $Out = Join-Path $Snap ("forensics-"+(Get-Date -Format 'yyyyMMdd-HHmmss')+".zip") }
$tmp = Join-Path $Snap ("tmp-"+([guid]::NewGuid()))
ni $tmp -ItemType Directory | Out-Null
Copy-Item (Join-Path $Base "logs") -Destination $tmp -Recurse -ea SilentlyContinue
Copy-Item (Join-Path $Base "config") -Destination $tmp -Recurse -ea SilentlyContinue
Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $Out -Force
Remove-Item $tmp -Recurse -Force -ea SilentlyContinue


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Out = "")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
ni $Snap -ItemType Directory -ea SilentlyContinue | Out-Null
if([string]::IsNullOrWhiteSpace($Out)){ $Out = Join-Path $Snap ("forensics-"+(Get-Date -Format 'yyyyMMdd-HHmmss')+".zip") }
$tmp = Join-Path $Snap ("tmp-"+([guid]::NewGuid()))
ni $tmp -ItemType Directory | Out-Null
Copy-Item (Join-Path $Base "logs") -Destination $tmp -Recurse -ea SilentlyContinue
Copy-Item (Join-Path $Base "config") -Destination $tmp -Recurse -ea SilentlyContinue
Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $Out -Force
Remove-Item $tmp -Recurse -Force -ea SilentlyContinue


