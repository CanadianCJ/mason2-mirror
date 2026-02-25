# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
$dst  = Join-Path $Snap ("snap-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
ni $dst -ItemType Directory -ea SilentlyContinue | Out-Null
robocopy (Join-Path $Base "config") (Join-Path $dst "config") /E | Out-Null
robocopy (Join-Path $Base "reports") (Join-Path $dst "reports") /E | Out-Null
# keep 14 days
Get-ChildItem $Snap -Directory | Sort-Object CreationTime -desc | Select-Object -Skip 14 | Remove-Item -Recurse -Force -ea SilentlyContinue

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
$dst  = Join-Path $Snap ("snap-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
ni $dst -ItemType Directory -ea SilentlyContinue | Out-Null
robocopy (Join-Path $Base "config") (Join-Path $dst "config") /E | Out-Null
robocopy (Join-Path $Base "reports") (Join-Path $dst "reports") /E | Out-Null
# keep 14 days
Get-ChildItem $Snap -Directory | Sort-Object CreationTime -desc | Select-Object -Skip 14 | Remove-Item -Recurse -Force -ea SilentlyContinue

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
$dst  = Join-Path $Snap ("snap-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
ni $dst -ItemType Directory -ea SilentlyContinue | Out-Null
robocopy (Join-Path $Base "config") (Join-Path $dst "config") /E | Out-Null
robocopy (Join-Path $Base "reports") (Join-Path $dst "reports") /E | Out-Null
# keep 14 days
Get-ChildItem $Snap -Directory | Sort-Object CreationTime -desc | Select-Object -Skip 14 | Remove-Item -Recurse -Force -ea SilentlyContinue

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
$dst  = Join-Path $Snap ("snap-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
ni $dst -ItemType Directory -ea SilentlyContinue | Out-Null
robocopy (Join-Path $Base "config") (Join-Path $dst "config") /E | Out-Null
robocopy (Join-Path $Base "reports") (Join-Path $dst "reports") /E | Out-Null
# keep 14 days
Get-ChildItem $Snap -Directory | Sort-Object CreationTime -desc | Select-Object -Skip 14 | Remove-Item -Recurse -Force -ea SilentlyContinue

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
$dst  = Join-Path $Snap ("snap-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
ni $dst -ItemType Directory -ea SilentlyContinue | Out-Null
robocopy (Join-Path $Base "config") (Join-Path $dst "config") /E | Out-Null
robocopy (Join-Path $Base "reports") (Join-Path $dst "reports") /E | Out-Null
# keep 14 days
Get-ChildItem $Snap -Directory | Sort-Object CreationTime -desc | Select-Object -Skip 14 | Remove-Item -Recurse -Force -ea SilentlyContinue

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
$dst  = Join-Path $Snap ("snap-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
ni $dst -ItemType Directory -ea SilentlyContinue | Out-Null
robocopy (Join-Path $Base "config") (Join-Path $dst "config") /E | Out-Null
robocopy (Join-Path $Base "reports") (Join-Path $dst "reports") /E | Out-Null
# keep 14 days
Get-ChildItem $Snap -Directory | Sort-Object CreationTime -desc | Select-Object -Skip 14 | Remove-Item -Recurse -Force -ea SilentlyContinue

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
$dst  = Join-Path $Snap ("snap-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
ni $dst -ItemType Directory -ea SilentlyContinue | Out-Null
robocopy (Join-Path $Base "config") (Join-Path $dst "config") /E | Out-Null
robocopy (Join-Path $Base "reports") (Join-Path $dst "reports") /E | Out-Null
# keep 14 days
Get-ChildItem $Snap -Directory | Sort-Object CreationTime -desc | Select-Object -Skip 14 | Remove-Item -Recurse -Force -ea SilentlyContinue

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Snap = Join-Path $Base "snapshots"
$dst  = Join-Path $Snap ("snap-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
ni $dst -ItemType Directory -ea SilentlyContinue | Out-Null
robocopy (Join-Path $Base "config") (Join-Path $dst "config") /E | Out-Null
robocopy (Join-Path $Base "reports") (Join-Path $dst "reports") /E | Out-Null
# keep 14 days
Get-ChildItem $Snap -Directory | Sort-Object CreationTime -desc | Select-Object -Skip 14 | Remove-Item -Recurse -Force -ea SilentlyContinue

