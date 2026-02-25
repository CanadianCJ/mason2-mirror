$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseP = Join-Path $Base 'config\tasks_baseline.json'
if(-not (Test-Path $baseP)){ exit 0 }
try{ $base = Get-Content $baseP -Raw | ConvertFrom-Json }catch{ exit 0 }
$baseNames = @($base | ForEach-Object { $_.TaskName })
$nowNames  = @(Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $_.TaskName })
$added   = @($nowNames | Where-Object { $_ -notin $baseNames })
$removed = @($baseNames | Where-Object { $_ -notin $nowNames })
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_diff'; added=$added; removed=$removed }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseP = Join-Path $Base 'config\tasks_baseline.json'
if(-not (Test-Path $baseP)){ exit 0 }
try{ $base = Get-Content $baseP -Raw | ConvertFrom-Json }catch{ exit 0 }
$baseNames = @($base | ForEach-Object { $_.TaskName })
$nowNames  = @(Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $_.TaskName })
$added   = @($nowNames | Where-Object { $_ -notin $baseNames })
$removed = @($baseNames | Where-Object { $_ -notin $nowNames })
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_diff'; added=$added; removed=$removed }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseP = Join-Path $Base 'config\tasks_baseline.json'
if(-not (Test-Path $baseP)){ exit 0 }
try{ $base = Get-Content $baseP -Raw | ConvertFrom-Json }catch{ exit 0 }
$baseNames = @($base | ForEach-Object { $_.TaskName })
$nowNames  = @(Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $_.TaskName })
$added   = @($nowNames | Where-Object { $_ -notin $baseNames })
$removed = @($baseNames | Where-Object { $_ -notin $nowNames })
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_diff'; added=$added; removed=$removed }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseP = Join-Path $Base 'config\tasks_baseline.json'
if(-not (Test-Path $baseP)){ exit 0 }
try{ $base = Get-Content $baseP -Raw | ConvertFrom-Json }catch{ exit 0 }
$baseNames = @($base | ForEach-Object { $_.TaskName })
$nowNames  = @(Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $_.TaskName })
$added   = @($nowNames | Where-Object { $_ -notin $baseNames })
$removed = @($baseNames | Where-Object { $_ -notin $nowNames })
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_diff'; added=$added; removed=$removed }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseP = Join-Path $Base 'config\tasks_baseline.json'
if(-not (Test-Path $baseP)){ exit 0 }
try{ $base = Get-Content $baseP -Raw | ConvertFrom-Json }catch{ exit 0 }
$baseNames = @($base | ForEach-Object { $_.TaskName })
$nowNames  = @(Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $_.TaskName })
$added   = @($nowNames | Where-Object { $_ -notin $baseNames })
$removed = @($baseNames | Where-Object { $_ -notin $nowNames })
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_diff'; added=$added; removed=$removed }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseP = Join-Path $Base 'config\tasks_baseline.json'
if(-not (Test-Path $baseP)){ exit 0 }
try{ $base = Get-Content $baseP -Raw | ConvertFrom-Json }catch{ exit 0 }
$baseNames = @($base | ForEach-Object { $_.TaskName })
$nowNames  = @(Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $_.TaskName })
$added   = @($nowNames | Where-Object { $_ -notin $baseNames })
$removed = @($baseNames | Where-Object { $_ -notin $nowNames })
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_diff'; added=$added; removed=$removed }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseP = Join-Path $Base 'config\tasks_baseline.json'
if(-not (Test-Path $baseP)){ exit 0 }
try{ $base = Get-Content $baseP -Raw | ConvertFrom-Json }catch{ exit 0 }
$baseNames = @($base | ForEach-Object { $_.TaskName })
$nowNames  = @(Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $_.TaskName })
$added   = @($nowNames | Where-Object { $_ -notin $baseNames })
$removed = @($baseNames | Where-Object { $_ -notin $nowNames })
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_diff'; added=$added; removed=$removed }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseP = Join-Path $Base 'config\tasks_baseline.json'
if(-not (Test-Path $baseP)){ exit 0 }
try{ $base = Get-Content $baseP -Raw | ConvertFrom-Json }catch{ exit 0 }
$baseNames = @($base | ForEach-Object { $_.TaskName })
$nowNames  = @(Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object { $_.TaskName })
$added   = @($nowNames | Where-Object { $_ -notin $baseNames })
$removed = @($baseNames | Where-Object { $_ -notin $nowNames })
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_diff'; added=$added; removed=$removed }
