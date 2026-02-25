$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try{ $cfg = Get-MasonConfig $Base }catch{ $cfg=$null }
if($cfg -and $cfg.guard -and $cfg.guard.safe_disk_pct){ $GuardPct = [int]$cfg.guard.safe_disk_pct }
$free = Get-DiskFreePct $Base
$flag = Join-Path $Base 'flags\safe_mode.on'
$on = Test-Path $flag
$changed = $false
if($free -lt $GuardPct -and -not $on){ 'ON' | Set-Content -LiteralPath $flag -Encoding ASCII; $changed=$true }
elseif($free -ge $GuardPct -and $on){ Remove-Item -LiteralPath $flag -Force; $changed=$true }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\safe_mode.jsonl') -Obj @{ ts=$now.ToString('s'); kind='safe_mode'; guard_pct=$GuardPct; free_pct=$free; active=(Test-Path $flag); changed=$changed }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$GuardPct=15)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try{ $cfg = Get-MasonConfig $Base }catch{ $cfg=$null }
if($cfg -and $cfg.guard -and $cfg.guard.safe_disk_pct){ $GuardPct = [int]$cfg.guard.safe_disk_pct }
$free = Get-DiskFreePct $Base
$flag = Join-Path $Base 'flags\safe_mode.on'
$on = Test-Path $flag
$changed = $false
if($free -lt $GuardPct -and -not $on){ 'ON' | Set-Content -LiteralPath $flag -Encoding ASCII; $changed=$true }
elseif($free -ge $GuardPct -and $on){ Remove-Item -LiteralPath $flag -Force; $changed=$true }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\safe_mode.jsonl') -Obj @{ ts=$now.ToString('s'); kind='safe_mode'; guard_pct=$GuardPct; free_pct=$free; active=(Test-Path $flag); changed=$changed }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$GuardPct=15)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try{ $cfg = Get-MasonConfig $Base }catch{ $cfg=$null }
if($cfg -and $cfg.guard -and $cfg.guard.safe_disk_pct){ $GuardPct = [int]$cfg.guard.safe_disk_pct }
$free = Get-DiskFreePct $Base
$flag = Join-Path $Base 'flags\safe_mode.on'
$on = Test-Path $flag
$changed = $false
if($free -lt $GuardPct -and -not $on){ 'ON' | Set-Content -LiteralPath $flag -Encoding ASCII; $changed=$true }
elseif($free -ge $GuardPct -and $on){ Remove-Item -LiteralPath $flag -Force; $changed=$true }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\safe_mode.jsonl') -Obj @{ ts=$now.ToString('s'); kind='safe_mode'; guard_pct=$GuardPct; free_pct=$free; active=(Test-Path $flag); changed=$changed }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$GuardPct=15)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try{ $cfg = Get-MasonConfig $Base }catch{ $cfg=$null }
if($cfg -and $cfg.guard -and $cfg.guard.safe_disk_pct){ $GuardPct = [int]$cfg.guard.safe_disk_pct }
$free = Get-DiskFreePct $Base
$flag = Join-Path $Base 'flags\safe_mode.on'
$on = Test-Path $flag
$changed = $false
if($free -lt $GuardPct -and -not $on){ 'ON' | Set-Content -LiteralPath $flag -Encoding ASCII; $changed=$true }
elseif($free -ge $GuardPct -and $on){ Remove-Item -LiteralPath $flag -Force; $changed=$true }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\safe_mode.jsonl') -Obj @{ ts=$now.ToString('s'); kind='safe_mode'; guard_pct=$GuardPct; free_pct=$free; active=(Test-Path $flag); changed=$changed }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$GuardPct=15)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try{ $cfg = Get-MasonConfig $Base }catch{ $cfg=$null }
if($cfg -and $cfg.guard -and $cfg.guard.safe_disk_pct){ $GuardPct = [int]$cfg.guard.safe_disk_pct }
$free = Get-DiskFreePct $Base
$flag = Join-Path $Base 'flags\safe_mode.on'
$on = Test-Path $flag
$changed = $false
if($free -lt $GuardPct -and -not $on){ 'ON' | Set-Content -LiteralPath $flag -Encoding ASCII; $changed=$true }
elseif($free -ge $GuardPct -and $on){ Remove-Item -LiteralPath $flag -Force; $changed=$true }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\safe_mode.jsonl') -Obj @{ ts=$now.ToString('s'); kind='safe_mode'; guard_pct=$GuardPct; free_pct=$free; active=(Test-Path $flag); changed=$changed }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$GuardPct=15)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try{ $cfg = Get-MasonConfig $Base }catch{ $cfg=$null }
if($cfg -and $cfg.guard -and $cfg.guard.safe_disk_pct){ $GuardPct = [int]$cfg.guard.safe_disk_pct }
$free = Get-DiskFreePct $Base
$flag = Join-Path $Base 'flags\safe_mode.on'
$on = Test-Path $flag
$changed = $false
if($free -lt $GuardPct -and -not $on){ 'ON' | Set-Content -LiteralPath $flag -Encoding ASCII; $changed=$true }
elseif($free -ge $GuardPct -and $on){ Remove-Item -LiteralPath $flag -Force; $changed=$true }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\safe_mode.jsonl') -Obj @{ ts=$now.ToString('s'); kind='safe_mode'; guard_pct=$GuardPct; free_pct=$free; active=(Test-Path $flag); changed=$changed }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$GuardPct=15)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try{ $cfg = Get-MasonConfig $Base }catch{ $cfg=$null }
if($cfg -and $cfg.guard -and $cfg.guard.safe_disk_pct){ $GuardPct = [int]$cfg.guard.safe_disk_pct }
$free = Get-DiskFreePct $Base
$flag = Join-Path $Base 'flags\safe_mode.on'
$on = Test-Path $flag
$changed = $false
if($free -lt $GuardPct -and -not $on){ 'ON' | Set-Content -LiteralPath $flag -Encoding ASCII; $changed=$true }
elseif($free -ge $GuardPct -and $on){ Remove-Item -LiteralPath $flag -Force; $changed=$true }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\safe_mode.jsonl') -Obj @{ ts=$now.ToString('s'); kind='safe_mode'; guard_pct=$GuardPct; free_pct=$free; active=(Test-Path $flag); changed=$changed }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try{ $cfg = Get-MasonConfig $Base }catch{ $cfg=$null }
if($cfg -and $cfg.guard -and $cfg.guard.safe_disk_pct){ $GuardPct = [int]$cfg.guard.safe_disk_pct }
$free = Get-DiskFreePct $Base
$flag = Join-Path $Base 'flags\safe_mode.on'
$on = Test-Path $flag
$changed = $false
if($free -lt $GuardPct -and -not $on){ 'ON' | Set-Content -LiteralPath $flag -Encoding ASCII; $changed=$true }
elseif($free -ge $GuardPct -and $on){ Remove-Item -LiteralPath $flag -Force; $changed=$true }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\safe_mode.jsonl') -Obj @{ ts=$now.ToString('s'); kind='safe_mode'; guard_pct=$GuardPct; free_pct=$free; active=(Test-Path $flag); changed=$changed }
