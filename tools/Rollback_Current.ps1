# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = $script:Paths

$cur = $paths.Current
$dir = Split-Path $cur
$baseName = [IO.Path]::GetFileName($cur)

if(!(Test-Path $cur -PathType Container)){ throw "Current folder not found: $cur" }

$bak = Get-ChildItem -LiteralPath $dir -Directory -Filter ($baseName + '.bak-*') |
       Sort-Object LastWriteTime -Desc | Select-Object -First 1
if(-not $bak){ throw "No backups found: $dir\$baseName.bak-*" }

# Swap back atomically: backup -> current; current becomes a new bak-* (via Atomic-Swap)
Atomic-Swap -newDir $bak.FullName -currentDir $cur
Write-Output ("Rolled back to: {0}" -f $cur)

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = $script:Paths

$cur = $paths.Current
$dir = Split-Path $cur
$baseName = [IO.Path]::GetFileName($cur)

if(!(Test-Path $cur -PathType Container)){ throw "Current folder not found: $cur" }

$bak = Get-ChildItem -LiteralPath $dir -Directory -Filter ($baseName + '.bak-*') |
       Sort-Object LastWriteTime -Desc | Select-Object -First 1
if(-not $bak){ throw "No backups found: $dir\$baseName.bak-*" }

# Swap back atomically: backup -> current; current becomes a new bak-* (via Atomic-Swap)
Atomic-Swap -newDir $bak.FullName -currentDir $cur
Write-Output ("Rolled back to: {0}" -f $cur)

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = $script:Paths

$cur = $paths.Current
$dir = Split-Path $cur
$baseName = [IO.Path]::GetFileName($cur)

if(!(Test-Path $cur -PathType Container)){ throw "Current folder not found: $cur" }

$bak = Get-ChildItem -LiteralPath $dir -Directory -Filter ($baseName + '.bak-*') |
       Sort-Object LastWriteTime -Desc | Select-Object -First 1
if(-not $bak){ throw "No backups found: $dir\$baseName.bak-*" }

# Swap back atomically: backup -> current; current becomes a new bak-* (via Atomic-Swap)
Atomic-Swap -newDir $bak.FullName -currentDir $cur
Write-Output ("Rolled back to: {0}" -f $cur)

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = $script:Paths

$cur = $paths.Current
$dir = Split-Path $cur
$baseName = [IO.Path]::GetFileName($cur)

if(!(Test-Path $cur -PathType Container)){ throw "Current folder not found: $cur" }

$bak = Get-ChildItem -LiteralPath $dir -Directory -Filter ($baseName + '.bak-*') |
       Sort-Object LastWriteTime -Desc | Select-Object -First 1
if(-not $bak){ throw "No backups found: $dir\$baseName.bak-*" }

# Swap back atomically: backup -> current; current becomes a new bak-* (via Atomic-Swap)
Atomic-Swap -newDir $bak.FullName -currentDir $cur
Write-Output ("Rolled back to: {0}" -f $cur)

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = $script:Paths

$cur = $paths.Current
$dir = Split-Path $cur
$baseName = [IO.Path]::GetFileName($cur)

if(!(Test-Path $cur -PathType Container)){ throw "Current folder not found: $cur" }

$bak = Get-ChildItem -LiteralPath $dir -Directory -Filter ($baseName + '.bak-*') |
       Sort-Object LastWriteTime -Desc | Select-Object -First 1
if(-not $bak){ throw "No backups found: $dir\$baseName.bak-*" }

# Swap back atomically: backup -> current; current becomes a new bak-* (via Atomic-Swap)
Atomic-Swap -newDir $bak.FullName -currentDir $cur
Write-Output ("Rolled back to: {0}" -f $cur)

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = $script:Paths

$cur = $paths.Current
$dir = Split-Path $cur
$baseName = [IO.Path]::GetFileName($cur)

if(!(Test-Path $cur -PathType Container)){ throw "Current folder not found: $cur" }

$bak = Get-ChildItem -LiteralPath $dir -Directory -Filter ($baseName + '.bak-*') |
       Sort-Object LastWriteTime -Desc | Select-Object -First 1
if(-not $bak){ throw "No backups found: $dir\$baseName.bak-*" }

# Swap back atomically: backup -> current; current becomes a new bak-* (via Atomic-Swap)
Atomic-Swap -newDir $bak.FullName -currentDir $cur
Write-Output ("Rolled back to: {0}" -f $cur)

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = $script:Paths

$cur = $paths.Current
$dir = Split-Path $cur
$baseName = [IO.Path]::GetFileName($cur)

if(!(Test-Path $cur -PathType Container)){ throw "Current folder not found: $cur" }

$bak = Get-ChildItem -LiteralPath $dir -Directory -Filter ($baseName + '.bak-*') |
       Sort-Object LastWriteTime -Desc | Select-Object -First 1
if(-not $bak){ throw "No backups found: $dir\$baseName.bak-*" }

# Swap back atomically: backup -> current; current becomes a new bak-* (via Atomic-Swap)
Atomic-Swap -newDir $bak.FullName -currentDir $cur
Write-Output ("Rolled back to: {0}" -f $cur)

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = $script:Paths

$cur = $paths.Current
$dir = Split-Path $cur
$baseName = [IO.Path]::GetFileName($cur)

if(!(Test-Path $cur -PathType Container)){ throw "Current folder not found: $cur" }

$bak = Get-ChildItem -LiteralPath $dir -Directory -Filter ($baseName + '.bak-*') |
       Sort-Object LastWriteTime -Desc | Select-Object -First 1
if(-not $bak){ throw "No backups found: $dir\$baseName.bak-*" }

# Swap back atomically: backup -> current; current becomes a new bak-* (via Atomic-Swap)
Atomic-Swap -newDir $bak.FullName -currentDir $cur
Write-Output ("Rolled back to: {0}" -f $cur)

