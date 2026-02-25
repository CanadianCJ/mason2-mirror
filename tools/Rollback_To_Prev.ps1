# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath (Join-Path $Base 'dist') -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if(-not $backs){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='skip';reason='no_backups'}; exit 0 }
$pick = $backs | Select-Object -First 1
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
Rename-Item -LiteralPath $curr -NewName ("current.bad-"+$stamp) -ErrorAction SilentlyContinue
Rename-Item -LiteralPath $pick.FullName -NewName 'current'
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='ok';from=$pick.Name}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath (Join-Path $Base 'dist') -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if(-not $backs){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='skip';reason='no_backups'}; exit 0 }
$pick = $backs | Select-Object -First 1
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
Rename-Item -LiteralPath $curr -NewName ("current.bad-"+$stamp) -ErrorAction SilentlyContinue
Rename-Item -LiteralPath $pick.FullName -NewName 'current'
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='ok';from=$pick.Name}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath (Join-Path $Base 'dist') -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if(-not $backs){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='skip';reason='no_backups'}; exit 0 }
$pick = $backs | Select-Object -First 1
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
Rename-Item -LiteralPath $curr -NewName ("current.bad-"+$stamp) -ErrorAction SilentlyContinue
Rename-Item -LiteralPath $pick.FullName -NewName 'current'
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='ok';from=$pick.Name}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath (Join-Path $Base 'dist') -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if(-not $backs){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='skip';reason='no_backups'}; exit 0 }
$pick = $backs | Select-Object -First 1
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
Rename-Item -LiteralPath $curr -NewName ("current.bad-"+$stamp) -ErrorAction SilentlyContinue
Rename-Item -LiteralPath $pick.FullName -NewName 'current'
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='ok';from=$pick.Name}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath (Join-Path $Base 'dist') -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if(-not $backs){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='skip';reason='no_backups'}; exit 0 }
$pick = $backs | Select-Object -First 1
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
Rename-Item -LiteralPath $curr -NewName ("current.bad-"+$stamp) -ErrorAction SilentlyContinue
Rename-Item -LiteralPath $pick.FullName -NewName 'current'
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='ok';from=$pick.Name}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath (Join-Path $Base 'dist') -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if(-not $backs){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='skip';reason='no_backups'}; exit 0 }
$pick = $backs | Select-Object -First 1
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
Rename-Item -LiteralPath $curr -NewName ("current.bad-"+$stamp) -ErrorAction SilentlyContinue
Rename-Item -LiteralPath $pick.FullName -NewName 'current'
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='ok';from=$pick.Name}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath (Join-Path $Base 'dist') -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if(-not $backs){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='skip';reason='no_backups'}; exit 0 }
$pick = $backs | Select-Object -First 1
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
Rename-Item -LiteralPath $curr -NewName ("current.bad-"+$stamp) -ErrorAction SilentlyContinue
Rename-Item -LiteralPath $pick.FullName -NewName 'current'
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='ok';from=$pick.Name}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath (Join-Path $Base 'dist') -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if(-not $backs){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='skip';reason='no_backups'}; exit 0 }
$pick = $backs | Select-Object -First 1
$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
Rename-Item -LiteralPath $curr -NewName ("current.bad-"+$stamp) -ErrorAction SilentlyContinue
Rename-Item -LiteralPath $pick.FullName -NewName 'current'
Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='rollback';status='ok';from=$pick.Name}

