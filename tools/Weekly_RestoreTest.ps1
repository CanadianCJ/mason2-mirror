# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\weekly_restore_test.jsonl'
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath $curr -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$evt = @{
  ts        = (Get-Date).ToString('s')
  kind      = 'restore_test'
  backup_ok = [bool]($backs -and $backs.Count -gt 0)
  latest    = ($backs | Select-Object -First 1 | ForEach-Object { $_.Name })
  action    = 'dry-run'
}
Write-JsonLineSafe -Path $log -Obj $evt

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\weekly_restore_test.jsonl'
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath $curr -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$evt = @{
  ts        = (Get-Date).ToString('s')
  kind      = 'restore_test'
  backup_ok = [bool]($backs -and $backs.Count -gt 0)
  latest    = ($backs | Select-Object -First 1 | ForEach-Object { $_.Name })
  action    = 'dry-run'
}
Write-JsonLineSafe -Path $log -Obj $evt

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\weekly_restore_test.jsonl'
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath $curr -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$evt = @{
  ts        = (Get-Date).ToString('s')
  kind      = 'restore_test'
  backup_ok = [bool]($backs -and $backs.Count -gt 0)
  latest    = ($backs | Select-Object -First 1 | ForEach-Object { $_.Name })
  action    = 'dry-run'
}
Write-JsonLineSafe -Path $log -Obj $evt

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\weekly_restore_test.jsonl'
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath $curr -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$evt = @{
  ts        = (Get-Date).ToString('s')
  kind      = 'restore_test'
  backup_ok = [bool]($backs -and $backs.Count -gt 0)
  latest    = ($backs | Select-Object -First 1 | ForEach-Object { $_.Name })
  action    = 'dry-run'
}
Write-JsonLineSafe -Path $log -Obj $evt

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\weekly_restore_test.jsonl'
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath $curr -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$evt = @{
  ts        = (Get-Date).ToString('s')
  kind      = 'restore_test'
  backup_ok = [bool]($backs -and $backs.Count -gt 0)
  latest    = ($backs | Select-Object -First 1 | ForEach-Object { $_.Name })
  action    = 'dry-run'
}
Write-JsonLineSafe -Path $log -Obj $evt

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\weekly_restore_test.jsonl'
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath $curr -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$evt = @{
  ts        = (Get-Date).ToString('s')
  kind      = 'restore_test'
  backup_ok = [bool]($backs -and $backs.Count -gt 0)
  latest    = ($backs | Select-Object -First 1 | ForEach-Object { $_.Name })
  action    = 'dry-run'
}
Write-JsonLineSafe -Path $log -Obj $evt

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\weekly_restore_test.jsonl'
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath $curr -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$evt = @{
  ts        = (Get-Date).ToString('s')
  kind      = 'restore_test'
  backup_ok = [bool]($backs -and $backs.Count -gt 0)
  latest    = ($backs | Select-Object -First 1 | ForEach-Object { $_.Name })
  action    = 'dry-run'
}
Write-JsonLineSafe -Path $log -Obj $evt

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "C:\Users\Chris\Desktop\Mason2")
$ErrorActionPreference = 'Stop'
if (Test-Path (Join-Path $Base 'tools\Common.ps1')) { . (Join-Path $Base 'tools\Common.ps1') }
. (Join-Path $Base 'tools\Common_Compat.ps1')

New-Item -ItemType Directory -Force -Path (Join-Path $Base 'reports') | Out-Null
$log = Join-Path $Base 'reports\weekly_restore_test.jsonl'
$curr = Join-Path $Base 'dist\current'
$backs = Get-ChildItem -LiteralPath $curr -Directory -Filter 'current.bak-*' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
$evt = @{
  ts        = (Get-Date).ToString('s')
  kind      = 'restore_test'
  backup_ok = [bool]($backs -and $backs.Count -gt 0)
  latest    = ($backs | Select-Object -First 1 | ForEach-Object { $_.Name })
  action    = 'dry-run'
}
Write-JsonLineSafe -Path $log -Obj $evt

