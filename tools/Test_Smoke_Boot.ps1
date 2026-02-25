$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok = (Test-Path (Join-Path $Base 'dist\current')) -and (Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\smoke.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='smoke'; ok=([bool]$ok) }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok = (Test-Path (Join-Path $Base 'dist\current')) -and (Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\smoke.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='smoke'; ok=([bool]$ok) }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok = (Test-Path (Join-Path $Base 'dist\current')) -and (Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\smoke.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='smoke'; ok=([bool]$ok) }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok = (Test-Path (Join-Path $Base 'dist\current')) -and (Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\smoke.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='smoke'; ok=([bool]$ok) }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok = (Test-Path (Join-Path $Base 'dist\current')) -and (Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\smoke.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='smoke'; ok=([bool]$ok) }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok = (Test-Path (Join-Path $Base 'dist\current')) -and (Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\smoke.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='smoke'; ok=([bool]$ok) }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok = (Test-Path (Join-Path $Base 'dist\current')) -and (Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\smoke.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='smoke'; ok=([bool]$ok) }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok = (Test-Path (Join-Path $Base 'dist\current')) -and (Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\smoke.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='smoke'; ok=([bool]$ok) }
