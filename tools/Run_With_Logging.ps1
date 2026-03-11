# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [Parameter(Mandatory=$true)][string]$File,
  [string[]]$Args,
  [int]$SlowMs = 30000,
  [string]$CorrId
)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

if (-not $CorrId) { $CorrId = [guid]::NewGuid().ToString("N") }
$start = Get-Date
try {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $File @Args
  $rc = $LASTEXITCODE
} catch { $rc = 1 }
$end = Get-Date
$durMs = [int]((New-TimeSpan -Start $start -End $end).TotalMilliseconds)

Write-JsonLineSafe -Path (Join-Path  'reports\exec_log.jsonl') -Obj @{ schema_version = 1;
  ts_start = $start.ToString('s')
  ts_end   = $end.ToString('s')
  ms       = $durMs
  file     = $File
  args     = $Args
  rc       = $rc
  host     = $env:COMPUTERNAME
  corr_id  = $CorrId
  slow     = ($durMs -ge $SlowMs)
}
exit $rc


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [Parameter(Mandatory=$true)][string]$File,
  [string[]]$Args,
  [int]$SlowMs = 30000,
  [string]$CorrId
)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

if (-not $CorrId) { $CorrId = [guid]::NewGuid().ToString("N") }
$start = Get-Date
try {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $File @Args
  $rc = $LASTEXITCODE
} catch { $rc = 1 }
$end = Get-Date
$durMs = [int]((New-TimeSpan -Start $start -End $end).TotalMilliseconds)

Write-JsonLineSafe -Path (Join-Path  'reports\exec_log.jsonl') -Obj @{ schema_version = 1;
  ts_start = $start.ToString('s')
  ts_end   = $end.ToString('s')
  ms       = $durMs
  file     = $File
  args     = $Args
  rc       = $rc
  host     = $env:COMPUTERNAME
  corr_id  = $CorrId
  slow     = ($durMs -ge $SlowMs)
}
exit $rc


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [Parameter(Mandatory=$true)][string]$File,
  [string[]]$Args,
  [int]$SlowMs = 30000,
  [string]$CorrId
)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

if (-not $CorrId) { $CorrId = [guid]::NewGuid().ToString("N") }
$start = Get-Date
try {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $File @Args
  $rc = $LASTEXITCODE
} catch { $rc = 1 }
$end = Get-Date
$durMs = [int]((New-TimeSpan -Start $start -End $end).TotalMilliseconds)

Write-JsonLineSafe -Path (Join-Path  'reports\exec_log.jsonl') -Obj @{ schema_version = 1;
  ts_start = $start.ToString('s')
  ts_end   = $end.ToString('s')
  ms       = $durMs
  file     = $File
  args     = $Args
  rc       = $rc
  host     = $env:COMPUTERNAME
  corr_id  = $CorrId
  slow     = ($durMs -ge $SlowMs)
}
exit $rc


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [Parameter(Mandatory=$true)][string]$File,
  [string[]]$Args,
  [int]$SlowMs = 30000,
  [string]$CorrId
)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

if (-not $CorrId) { $CorrId = [guid]::NewGuid().ToString("N") }
$start = Get-Date
try {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $File @Args
  $rc = $LASTEXITCODE
} catch { $rc = 1 }
$end = Get-Date
$durMs = [int]((New-TimeSpan -Start $start -End $end).TotalMilliseconds)

Write-JsonLineSafe -Path (Join-Path  'reports\exec_log.jsonl') -Obj @{ schema_version = 1;
  ts_start = $start.ToString('s')
  ts_end   = $end.ToString('s')
  ms       = $durMs
  file     = $File
  args     = $Args
  rc       = $rc
  host     = $env:COMPUTERNAME
  corr_id  = $CorrId
  slow     = ($durMs -ge $SlowMs)
}
exit $rc


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [Parameter(Mandatory=$true)][string]$File,
  [string[]]$Args,
  [int]$SlowMs = 30000,
  [string]$CorrId
)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

if (-not $CorrId) { $CorrId = [guid]::NewGuid().ToString("N") }
$start = Get-Date
try {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $File @Args
  $rc = $LASTEXITCODE
} catch { $rc = 1 }
$end = Get-Date
$durMs = [int]((New-TimeSpan -Start $start -End $end).TotalMilliseconds)

Write-JsonLineSafe -Path (Join-Path  'reports\exec_log.jsonl') -Obj @{ schema_version = 1;
  ts_start = $start.ToString('s')
  ts_end   = $end.ToString('s')
  ms       = $durMs
  file     = $File
  args     = $Args
  rc       = $rc
  host     = $env:COMPUTERNAME
  corr_id  = $CorrId
  slow     = ($durMs -ge $SlowMs)
}
exit $rc


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [Parameter(Mandatory=$true)][string]$File,
  [string[]]$Args,
  [int]$SlowMs = 30000,
  [string]$CorrId
)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

if (-not $CorrId) { $CorrId = [guid]::NewGuid().ToString("N") }
$start = Get-Date
try {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $File @Args
  $rc = $LASTEXITCODE
} catch { $rc = 1 }
$end = Get-Date
$durMs = [int]((New-TimeSpan -Start $start -End $end).TotalMilliseconds)

Write-JsonLineSafe -Path (Join-Path  'reports\exec_log.jsonl') -Obj @{ schema_version = 1;
  ts_start = $start.ToString('s')
  ts_end   = $end.ToString('s')
  ms       = $durMs
  file     = $File
  args     = $Args
  rc       = $rc
  host     = $env:COMPUTERNAME
  corr_id  = $CorrId
  slow     = ($durMs -ge $SlowMs)
}
exit $rc


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [Parameter(Mandatory=$true)][string]$File,
  [string[]]$Args,
  [int]$SlowMs = 30000,
  [string]$CorrId
)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

if (-not $CorrId) { $CorrId = [guid]::NewGuid().ToString("N") }
$start = Get-Date
try {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $File @Args
  $rc = $LASTEXITCODE
} catch { $rc = 1 }
$end = Get-Date
$durMs = [int]((New-TimeSpan -Start $start -End $end).TotalMilliseconds)

Write-JsonLineSafe -Path (Join-Path  'reports\exec_log.jsonl') -Obj @{ schema_version = 1;
  ts_start = $start.ToString('s')
  ts_end   = $end.ToString('s')
  ms       = $durMs
  file     = $File
  args     = $Args
  rc       = $rc
  host     = $env:COMPUTERNAME
  corr_id  = $CorrId
  slow     = ($durMs -ge $SlowMs)
}
exit $rc


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [Parameter(Mandatory=$true)][string]$File,
  [string[]]$Args,
  [int]$SlowMs = 30000,
  [string]$CorrId
)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

if (-not $CorrId) { $CorrId = [guid]::NewGuid().ToString("N") }
$start = Get-Date
try {
  & powershell -NoProfile -ExecutionPolicy Bypass -File $File @Args
  $rc = $LASTEXITCODE
} catch { $rc = 1 }
$end = Get-Date
$durMs = [int]((New-TimeSpan -Start $start -End $end).TotalMilliseconds)

Write-JsonLineSafe -Path (Join-Path  'reports\exec_log.jsonl') -Obj @{ schema_version = 1;
  ts_start = $start.ToString('s')
  ts_end   = $end.ToString('s')
  ms       = $durMs
  file     = $File
  args     = $Args
  rc       = $rc
  host     = $env:COMPUTERNAME
  corr_id  = $CorrId
  slow     = ($durMs -ge $SlowMs)
}
exit $rc


