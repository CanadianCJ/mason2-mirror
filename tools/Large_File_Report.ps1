# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=20)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\dist\\releases\\|\\reports\\|\\logs\\telemetry\\' } |
  Sort-Object Length -Descending | Select-Object -First $Top
$rows = @()
foreach($f in $files){ $rows += @{ path=$f.FullName.Substring($Base.Length+1); mb=[math]::Round($f.Length/1MB,2) } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\large_files.jsonl') -Obj @{ ts=$now.ToString('s'); kind='large_files'; top=$rows }

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=20)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\dist\\releases\\|\\reports\\|\\logs\\telemetry\\' } |
  Sort-Object Length -Descending | Select-Object -First $Top
$rows = @()
foreach($f in $files){ $rows += @{ path=$f.FullName.Substring($Base.Length+1); mb=[math]::Round($f.Length/1MB,2) } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\large_files.jsonl') -Obj @{ ts=$now.ToString('s'); kind='large_files'; top=$rows }

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=20)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\dist\\releases\\|\\reports\\|\\logs\\telemetry\\' } |
  Sort-Object Length -Descending | Select-Object -First $Top
$rows = @()
foreach($f in $files){ $rows += @{ path=$f.FullName.Substring($Base.Length+1); mb=[math]::Round($f.Length/1MB,2) } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\large_files.jsonl') -Obj @{ ts=$now.ToString('s'); kind='large_files'; top=$rows }

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=20)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\dist\\releases\\|\\reports\\|\\logs\\telemetry\\' } |
  Sort-Object Length -Descending | Select-Object -First $Top
$rows = @()
foreach($f in $files){ $rows += @{ path=$f.FullName.Substring($Base.Length+1); mb=[math]::Round($f.Length/1MB,2) } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\large_files.jsonl') -Obj @{ ts=$now.ToString('s'); kind='large_files'; top=$rows }

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=20)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\dist\\releases\\|\\reports\\|\\logs\\telemetry\\' } |
  Sort-Object Length -Descending | Select-Object -First $Top
$rows = @()
foreach($f in $files){ $rows += @{ path=$f.FullName.Substring($Base.Length+1); mb=[math]::Round($f.Length/1MB,2) } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\large_files.jsonl') -Obj @{ ts=$now.ToString('s'); kind='large_files'; top=$rows }

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=20)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\dist\\releases\\|\\reports\\|\\logs\\telemetry\\' } |
  Sort-Object Length -Descending | Select-Object -First $Top
$rows = @()
foreach($f in $files){ $rows += @{ path=$f.FullName.Substring($Base.Length+1); mb=[math]::Round($f.Length/1MB,2) } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\large_files.jsonl') -Obj @{ ts=$now.ToString('s'); kind='large_files'; top=$rows }

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=20)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\dist\\releases\\|\\reports\\|\\logs\\telemetry\\' } |
  Sort-Object Length -Descending | Select-Object -First $Top
$rows = @()
foreach($f in $files){ $rows += @{ path=$f.FullName.Substring($Base.Length+1); mb=[math]::Round($f.Length/1MB,2) } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\large_files.jsonl') -Obj @{ ts=$now.ToString('s'); kind='large_files'; top=$rows }

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=20)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\dist\\releases\\|\\reports\\|\\logs\\telemetry\\' } |
  Sort-Object Length -Descending | Select-Object -First $Top
$rows = @()
foreach($f in $files){ $rows += @{ path=$f.FullName.Substring($Base.Length+1); mb=[math]::Round($f.Length/1MB,2) } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\large_files.jsonl') -Obj @{ ts=$now.ToString('s'); kind='large_files'; top=$rows }

