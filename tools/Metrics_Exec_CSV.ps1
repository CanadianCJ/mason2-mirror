# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$csv = Join-Path $Base 'metrics\exec_times.csv'
if(-not (Test-Path $src)){ exit 0 }
$rows = @()
Get-Content $src -Tail 1000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $rows += [pscustomobject]@{ ts=$j.ts_end; file=$j.file; ms=$j.ms; rc=$j.rc }
}
$rows | Export-Csv -Path $csv -Append -NoTypeInformation

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$csv = Join-Path $Base 'metrics\exec_times.csv'
if(-not (Test-Path $src)){ exit 0 }
$rows = @()
Get-Content $src -Tail 1000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $rows += [pscustomobject]@{ ts=$j.ts_end; file=$j.file; ms=$j.ms; rc=$j.rc }
}
$rows | Export-Csv -Path $csv -Append -NoTypeInformation

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$csv = Join-Path $Base 'metrics\exec_times.csv'
if(-not (Test-Path $src)){ exit 0 }
$rows = @()
Get-Content $src -Tail 1000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $rows += [pscustomobject]@{ ts=$j.ts_end; file=$j.file; ms=$j.ms; rc=$j.rc }
}
$rows | Export-Csv -Path $csv -Append -NoTypeInformation

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$csv = Join-Path $Base 'metrics\exec_times.csv'
if(-not (Test-Path $src)){ exit 0 }
$rows = @()
Get-Content $src -Tail 1000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $rows += [pscustomobject]@{ ts=$j.ts_end; file=$j.file; ms=$j.ms; rc=$j.rc }
}
$rows | Export-Csv -Path $csv -Append -NoTypeInformation

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$csv = Join-Path $Base 'metrics\exec_times.csv'
if(-not (Test-Path $src)){ exit 0 }
$rows = @()
Get-Content $src -Tail 1000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $rows += [pscustomobject]@{ ts=$j.ts_end; file=$j.file; ms=$j.ms; rc=$j.rc }
}
$rows | Export-Csv -Path $csv -Append -NoTypeInformation

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$csv = Join-Path $Base 'metrics\exec_times.csv'
if(-not (Test-Path $src)){ exit 0 }
$rows = @()
Get-Content $src -Tail 1000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $rows += [pscustomobject]@{ ts=$j.ts_end; file=$j.file; ms=$j.ms; rc=$j.rc }
}
$rows | Export-Csv -Path $csv -Append -NoTypeInformation

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$csv = Join-Path $Base 'metrics\exec_times.csv'
if(-not (Test-Path $src)){ exit 0 }
$rows = @()
Get-Content $src -Tail 1000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $rows += [pscustomobject]@{ ts=$j.ts_end; file=$j.file; ms=$j.ms; rc=$j.rc }
}
$rows | Export-Csv -Path $csv -Append -NoTypeInformation

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$src = Join-Path $Base 'reports\exec_log.jsonl'
$csv = Join-Path $Base 'metrics\exec_times.csv'
if(-not (Test-Path $src)){ exit 0 }
$rows = @()
Get-Content $src -Tail 1000 -ErrorAction SilentlyContinue | ForEach-Object {
  try{ $j = $_ | ConvertFrom-Json }catch{ return }
  $rows += [pscustomobject]@{ ts=$j.ts_end; file=$j.file; ms=$j.ms; rc=$j.rc }
}
$rows | Export-Csv -Path $csv -Append -NoTypeInformation

