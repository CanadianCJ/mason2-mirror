# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$ZipPath)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
if(-not $ZipPath){
  $latest = Join-Path $rel 'LATEST.txt'
  if(Test-Path $latest){ $ZipPath = Join-Path $rel ((Get-Content $latest -Raw).Trim()) }
}
if(-not $ZipPath -or -not (Test-Path $ZipPath)){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='skip';reason='no_zip'}; exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$stage = Join-Path $Base ("dist\stage_" + $stamp)
$current = Join-Path $Base 'dist\current'
$new = Join-Path $Base 'dist\current_new'
$bak = Join-Path $Base ("dist\current.bak-" + $stamp)

New-Item -ItemType Directory -Force -Path $stage | Out-Null
try{
  Expand-Archive -LiteralPath $ZipPath -DestinationPath $stage -Force
}catch{ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='fail';step='expand'}; exit 1 }

if(Test-Path $new){ Remove-Item -Recurse -Force -LiteralPath $new }
Rename-Item -LiteralPath $stage -NewName (Split-Path -Leaf $new)
if(Test-Path $current){ Rename-Item -LiteralPath $current -NewName (Split-Path -Leaf $bak) }
Rename-Item -LiteralPath $new -NewName (Split-Path -Leaf $current)

Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='ok';zip=[IO.Path]::GetFileName($ZipPath); backup=[IO.Path]::GetFileName($bak)}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$ZipPath)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
if(-not $ZipPath){
  $latest = Join-Path $rel 'LATEST.txt'
  if(Test-Path $latest){ $ZipPath = Join-Path $rel ((Get-Content $latest -Raw).Trim()) }
}
if(-not $ZipPath -or -not (Test-Path $ZipPath)){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='skip';reason='no_zip'}; exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$stage = Join-Path $Base ("dist\stage_" + $stamp)
$current = Join-Path $Base 'dist\current'
$new = Join-Path $Base 'dist\current_new'
$bak = Join-Path $Base ("dist\current.bak-" + $stamp)

New-Item -ItemType Directory -Force -Path $stage | Out-Null
try{
  Expand-Archive -LiteralPath $ZipPath -DestinationPath $stage -Force
}catch{ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='fail';step='expand'}; exit 1 }

if(Test-Path $new){ Remove-Item -Recurse -Force -LiteralPath $new }
Rename-Item -LiteralPath $stage -NewName (Split-Path -Leaf $new)
if(Test-Path $current){ Rename-Item -LiteralPath $current -NewName (Split-Path -Leaf $bak) }
Rename-Item -LiteralPath $new -NewName (Split-Path -Leaf $current)

Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='ok';zip=[IO.Path]::GetFileName($ZipPath); backup=[IO.Path]::GetFileName($bak)}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$ZipPath)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
if(-not $ZipPath){
  $latest = Join-Path $rel 'LATEST.txt'
  if(Test-Path $latest){ $ZipPath = Join-Path $rel ((Get-Content $latest -Raw).Trim()) }
}
if(-not $ZipPath -or -not (Test-Path $ZipPath)){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='skip';reason='no_zip'}; exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$stage = Join-Path $Base ("dist\stage_" + $stamp)
$current = Join-Path $Base 'dist\current'
$new = Join-Path $Base 'dist\current_new'
$bak = Join-Path $Base ("dist\current.bak-" + $stamp)

New-Item -ItemType Directory -Force -Path $stage | Out-Null
try{
  Expand-Archive -LiteralPath $ZipPath -DestinationPath $stage -Force
}catch{ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='fail';step='expand'}; exit 1 }

if(Test-Path $new){ Remove-Item -Recurse -Force -LiteralPath $new }
Rename-Item -LiteralPath $stage -NewName (Split-Path -Leaf $new)
if(Test-Path $current){ Rename-Item -LiteralPath $current -NewName (Split-Path -Leaf $bak) }
Rename-Item -LiteralPath $new -NewName (Split-Path -Leaf $current)

Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='ok';zip=[IO.Path]::GetFileName($ZipPath); backup=[IO.Path]::GetFileName($bak)}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$ZipPath)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
if(-not $ZipPath){
  $latest = Join-Path $rel 'LATEST.txt'
  if(Test-Path $latest){ $ZipPath = Join-Path $rel ((Get-Content $latest -Raw).Trim()) }
}
if(-not $ZipPath -or -not (Test-Path $ZipPath)){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='skip';reason='no_zip'}; exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$stage = Join-Path $Base ("dist\stage_" + $stamp)
$current = Join-Path $Base 'dist\current'
$new = Join-Path $Base 'dist\current_new'
$bak = Join-Path $Base ("dist\current.bak-" + $stamp)

New-Item -ItemType Directory -Force -Path $stage | Out-Null
try{
  Expand-Archive -LiteralPath $ZipPath -DestinationPath $stage -Force
}catch{ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='fail';step='expand'}; exit 1 }

if(Test-Path $new){ Remove-Item -Recurse -Force -LiteralPath $new }
Rename-Item -LiteralPath $stage -NewName (Split-Path -Leaf $new)
if(Test-Path $current){ Rename-Item -LiteralPath $current -NewName (Split-Path -Leaf $bak) }
Rename-Item -LiteralPath $new -NewName (Split-Path -Leaf $current)

Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='ok';zip=[IO.Path]::GetFileName($ZipPath); backup=[IO.Path]::GetFileName($bak)}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$ZipPath)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
if(-not $ZipPath){
  $latest = Join-Path $rel 'LATEST.txt'
  if(Test-Path $latest){ $ZipPath = Join-Path $rel ((Get-Content $latest -Raw).Trim()) }
}
if(-not $ZipPath -or -not (Test-Path $ZipPath)){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='skip';reason='no_zip'}; exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$stage = Join-Path $Base ("dist\stage_" + $stamp)
$current = Join-Path $Base 'dist\current'
$new = Join-Path $Base 'dist\current_new'
$bak = Join-Path $Base ("dist\current.bak-" + $stamp)

New-Item -ItemType Directory -Force -Path $stage | Out-Null
try{
  Expand-Archive -LiteralPath $ZipPath -DestinationPath $stage -Force
}catch{ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='fail';step='expand'}; exit 1 }

if(Test-Path $new){ Remove-Item -Recurse -Force -LiteralPath $new }
Rename-Item -LiteralPath $stage -NewName (Split-Path -Leaf $new)
if(Test-Path $current){ Rename-Item -LiteralPath $current -NewName (Split-Path -Leaf $bak) }
Rename-Item -LiteralPath $new -NewName (Split-Path -Leaf $current)

Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='ok';zip=[IO.Path]::GetFileName($ZipPath); backup=[IO.Path]::GetFileName($bak)}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$ZipPath)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
if(-not $ZipPath){
  $latest = Join-Path $rel 'LATEST.txt'
  if(Test-Path $latest){ $ZipPath = Join-Path $rel ((Get-Content $latest -Raw).Trim()) }
}
if(-not $ZipPath -or -not (Test-Path $ZipPath)){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='skip';reason='no_zip'}; exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$stage = Join-Path $Base ("dist\stage_" + $stamp)
$current = Join-Path $Base 'dist\current'
$new = Join-Path $Base 'dist\current_new'
$bak = Join-Path $Base ("dist\current.bak-" + $stamp)

New-Item -ItemType Directory -Force -Path $stage | Out-Null
try{
  Expand-Archive -LiteralPath $ZipPath -DestinationPath $stage -Force
}catch{ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='fail';step='expand'}; exit 1 }

if(Test-Path $new){ Remove-Item -Recurse -Force -LiteralPath $new }
Rename-Item -LiteralPath $stage -NewName (Split-Path -Leaf $new)
if(Test-Path $current){ Rename-Item -LiteralPath $current -NewName (Split-Path -Leaf $bak) }
Rename-Item -LiteralPath $new -NewName (Split-Path -Leaf $current)

Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='ok';zip=[IO.Path]::GetFileName($ZipPath); backup=[IO.Path]::GetFileName($bak)}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$ZipPath)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
if(-not $ZipPath){
  $latest = Join-Path $rel 'LATEST.txt'
  if(Test-Path $latest){ $ZipPath = Join-Path $rel ((Get-Content $latest -Raw).Trim()) }
}
if(-not $ZipPath -or -not (Test-Path $ZipPath)){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='skip';reason='no_zip'}; exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$stage = Join-Path $Base ("dist\stage_" + $stamp)
$current = Join-Path $Base 'dist\current'
$new = Join-Path $Base 'dist\current_new'
$bak = Join-Path $Base ("dist\current.bak-" + $stamp)

New-Item -ItemType Directory -Force -Path $stage | Out-Null
try{
  Expand-Archive -LiteralPath $ZipPath -DestinationPath $stage -Force
}catch{ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='fail';step='expand'}; exit 1 }

if(Test-Path $new){ Remove-Item -Recurse -Force -LiteralPath $new }
Rename-Item -LiteralPath $stage -NewName (Split-Path -Leaf $new)
if(Test-Path $current){ Rename-Item -LiteralPath $current -NewName (Split-Path -Leaf $bak) }
Rename-Item -LiteralPath $new -NewName (Split-Path -Leaf $current)

Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='ok';zip=[IO.Path]::GetFileName($ZipPath); backup=[IO.Path]::GetFileName($bak)}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$ZipPath)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
if(-not $ZipPath){
  $latest = Join-Path $rel 'LATEST.txt'
  if(Test-Path $latest){ $ZipPath = Join-Path $rel ((Get-Content $latest -Raw).Trim()) }
}
if(-not $ZipPath -or -not (Test-Path $ZipPath)){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='skip';reason='no_zip'}; exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
$stage = Join-Path $Base ("dist\stage_" + $stamp)
$current = Join-Path $Base 'dist\current'
$new = Join-Path $Base 'dist\current_new'
$bak = Join-Path $Base ("dist\current.bak-" + $stamp)

New-Item -ItemType Directory -Force -Path $stage | Out-Null
try{
  Expand-Archive -LiteralPath $ZipPath -DestinationPath $stage -Force
}catch{ Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='fail';step='expand'}; exit 1 }

if(Test-Path $new){ Remove-Item -Recurse -Force -LiteralPath $new }
Rename-Item -LiteralPath $stage -NewName (Split-Path -Leaf $new)
if(Test-Path $current){ Rename-Item -LiteralPath $current -NewName (Split-Path -Leaf $bak) }
Rename-Item -LiteralPath $new -NewName (Split-Path -Leaf $current)

Write-JsonLineSafe -Path (Join-Path $Base 'reports\deploy.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='deploy';status='ok';zip=[IO.Path]::GetFileName($ZipPath); backup=[IO.Path]::GetFileName($bak)}

