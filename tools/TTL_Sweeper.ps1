# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$targets = @((Join-Path $Base 'dist\temp'), (Join-Path $Base 'logs\telemetry'))
foreach($t in $targets){
  if(Test-Path $t){
    Get-ChildItem -LiteralPath $t -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cut } | ForEach-Object {
      try{ Remove-Item -LiteralPath $_.FullName -Force }catch{}
    }
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\ttl_sweeper.jsonl') -Obj @{ ts=$now.ToString('s'); kind='ttl_sweeper'; days=$Days }

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$targets = @((Join-Path $Base 'dist\temp'), (Join-Path $Base 'logs\telemetry'))
foreach($t in $targets){
  if(Test-Path $t){
    Get-ChildItem -LiteralPath $t -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cut } | ForEach-Object {
      try{ Remove-Item -LiteralPath $_.FullName -Force }catch{}
    }
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\ttl_sweeper.jsonl') -Obj @{ ts=$now.ToString('s'); kind='ttl_sweeper'; days=$Days }

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$targets = @((Join-Path $Base 'dist\temp'), (Join-Path $Base 'logs\telemetry'))
foreach($t in $targets){
  if(Test-Path $t){
    Get-ChildItem -LiteralPath $t -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cut } | ForEach-Object {
      try{ Remove-Item -LiteralPath $_.FullName -Force }catch{}
    }
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\ttl_sweeper.jsonl') -Obj @{ ts=$now.ToString('s'); kind='ttl_sweeper'; days=$Days }

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$targets = @((Join-Path $Base 'dist\temp'), (Join-Path $Base 'logs\telemetry'))
foreach($t in $targets){
  if(Test-Path $t){
    Get-ChildItem -LiteralPath $t -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cut } | ForEach-Object {
      try{ Remove-Item -LiteralPath $_.FullName -Force }catch{}
    }
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\ttl_sweeper.jsonl') -Obj @{ ts=$now.ToString('s'); kind='ttl_sweeper'; days=$Days }

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$targets = @((Join-Path $Base 'dist\temp'), (Join-Path $Base 'logs\telemetry'))
foreach($t in $targets){
  if(Test-Path $t){
    Get-ChildItem -LiteralPath $t -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cut } | ForEach-Object {
      try{ Remove-Item -LiteralPath $_.FullName -Force }catch{}
    }
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\ttl_sweeper.jsonl') -Obj @{ ts=$now.ToString('s'); kind='ttl_sweeper'; days=$Days }

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$targets = @((Join-Path $Base 'dist\temp'), (Join-Path $Base 'logs\telemetry'))
foreach($t in $targets){
  if(Test-Path $t){
    Get-ChildItem -LiteralPath $t -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cut } | ForEach-Object {
      try{ Remove-Item -LiteralPath $_.FullName -Force }catch{}
    }
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\ttl_sweeper.jsonl') -Obj @{ ts=$now.ToString('s'); kind='ttl_sweeper'; days=$Days }

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$targets = @((Join-Path $Base 'dist\temp'), (Join-Path $Base 'logs\telemetry'))
foreach($t in $targets){
  if(Test-Path $t){
    Get-ChildItem -LiteralPath $t -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cut } | ForEach-Object {
      try{ Remove-Item -LiteralPath $_.FullName -Force }catch{}
    }
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\ttl_sweeper.jsonl') -Obj @{ ts=$now.ToString('s'); kind='ttl_sweeper'; days=$Days }

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$targets = @((Join-Path $Base 'dist\temp'), (Join-Path $Base 'logs\telemetry'))
foreach($t in $targets){
  if(Test-Path $t){
    Get-ChildItem -LiteralPath $t -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $cut } | ForEach-Object {
      try{ Remove-Item -LiteralPath $_.FullName -Force }catch{}
    }
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\ttl_sweeper.jsonl') -Obj @{ ts=$now.ToString('s'); kind='ttl_sweeper'; days=$Days }

