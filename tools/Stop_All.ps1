$ErrorActionPreference='Stop'
$ts = Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -ne 'Mason2-Agent' }
foreach($t in $ts){ try{ Disable-ScheduledTask -TaskName $t.TaskName -ErrorAction SilentlyContinue | Out-Null }catch{} }
Write-Host "[OK] Disabled $($ts.Count) tasks."
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$ts = Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -ne 'Mason2-Agent' }
foreach($t in $ts){ try{ Disable-ScheduledTask -TaskName $t.TaskName -ErrorAction SilentlyContinue | Out-Null }catch{} }
Write-Host "[OK] Disabled $($ts.Count) tasks."
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$ts = Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -ne 'Mason2-Agent' }
foreach($t in $ts){ try{ Disable-ScheduledTask -TaskName $t.TaskName -ErrorAction SilentlyContinue | Out-Null }catch{} }
Write-Host "[OK] Disabled $($ts.Count) tasks."
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$ts = Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -ne 'Mason2-Agent' }
foreach($t in $ts){ try{ Disable-ScheduledTask -TaskName $t.TaskName -ErrorAction SilentlyContinue | Out-Null }catch{} }
Write-Host "[OK] Disabled $($ts.Count) tasks."
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$ts = Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -ne 'Mason2-Agent' }
foreach($t in $ts){ try{ Disable-ScheduledTask -TaskName $t.TaskName -ErrorAction SilentlyContinue | Out-Null }catch{} }
Write-Host "[OK] Disabled $($ts.Count) tasks."
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$ts = Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -ne 'Mason2-Agent' }
foreach($t in $ts){ try{ Disable-ScheduledTask -TaskName $t.TaskName -ErrorAction SilentlyContinue | Out-Null }catch{} }
Write-Host "[OK] Disabled $($ts.Count) tasks."
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$ts = Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -ne 'Mason2-Agent' }
foreach($t in $ts){ try{ Disable-ScheduledTask -TaskName $t.TaskName -ErrorAction SilentlyContinue | Out-Null }catch{} }
Write-Host "[OK] Disabled $($ts.Count) tasks."
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
$ts = Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -ne 'Mason2-Agent' }
foreach($t in $ts){ try{ Disable-ScheduledTask -TaskName $t.TaskName -ErrorAction SilentlyContinue | Out-Null }catch{} }
Write-Host "[OK] Disabled $($ts.Count) tasks."
