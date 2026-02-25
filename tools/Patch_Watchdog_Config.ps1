$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ return }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  $want = @('Mason2-UIStatus-1m','Mason2-ProcHealth-5m','Mason2-HttpHealthz-5m','Mason2-ServiceHealth-15m','Mason2-Heartbeat-1m','Mason2-WatchdogLiveness-2m','Mason2-SafeModeLowDisk-5m','Mason2-Sidecar7000-1m')
  $curr = @(); if($j.tasks_expected){ $curr = @($j.tasks_expected) }
  $merged = @($curr + $want) | Select-Object -Unique
  $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue $merged -Force
  ($j | ConvertTo-Json -Depth 8) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ return }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  $want = @('Mason2-UIStatus-1m','Mason2-ProcHealth-5m','Mason2-HttpHealthz-5m','Mason2-ServiceHealth-15m','Mason2-Heartbeat-1m','Mason2-WatchdogLiveness-2m','Mason2-SafeModeLowDisk-5m','Mason2-Sidecar7000-1m')
  $curr = @(); if($j.tasks_expected){ $curr = @($j.tasks_expected) }
  $merged = @($curr + $want) | Select-Object -Unique
  $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue $merged -Force
  ($j | ConvertTo-Json -Depth 8) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ return }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  $want = @('Mason2-UIStatus-1m','Mason2-ProcHealth-5m','Mason2-HttpHealthz-5m','Mason2-ServiceHealth-15m','Mason2-Heartbeat-1m','Mason2-WatchdogLiveness-2m','Mason2-SafeModeLowDisk-5m','Mason2-Sidecar7000-1m')
  $curr = @(); if($j.tasks_expected){ $curr = @($j.tasks_expected) }
  $merged = @($curr + $want) | Select-Object -Unique
  $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue $merged -Force
  ($j | ConvertTo-Json -Depth 8) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ return }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  $want = @('Mason2-UIStatus-1m','Mason2-ProcHealth-5m','Mason2-HttpHealthz-5m','Mason2-ServiceHealth-15m','Mason2-Heartbeat-1m','Mason2-WatchdogLiveness-2m','Mason2-SafeModeLowDisk-5m','Mason2-Sidecar7000-1m')
  $curr = @(); if($j.tasks_expected){ $curr = @($j.tasks_expected) }
  $merged = @($curr + $want) | Select-Object -Unique
  $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue $merged -Force
  ($j | ConvertTo-Json -Depth 8) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ return }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  $want = @('Mason2-UIStatus-1m','Mason2-ProcHealth-5m','Mason2-HttpHealthz-5m','Mason2-ServiceHealth-15m','Mason2-Heartbeat-1m','Mason2-WatchdogLiveness-2m','Mason2-SafeModeLowDisk-5m','Mason2-Sidecar7000-1m')
  $curr = @(); if($j.tasks_expected){ $curr = @($j.tasks_expected) }
  $merged = @($curr + $want) | Select-Object -Unique
  $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue $merged -Force
  ($j | ConvertTo-Json -Depth 8) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ return }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  $want = @('Mason2-UIStatus-1m','Mason2-ProcHealth-5m','Mason2-HttpHealthz-5m','Mason2-ServiceHealth-15m','Mason2-Heartbeat-1m','Mason2-WatchdogLiveness-2m','Mason2-SafeModeLowDisk-5m','Mason2-Sidecar7000-1m')
  $curr = @(); if($j.tasks_expected){ $curr = @($j.tasks_expected) }
  $merged = @($curr + $want) | Select-Object -Unique
  $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue $merged -Force
  ($j | ConvertTo-Json -Depth 8) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ return }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  $want = @('Mason2-UIStatus-1m','Mason2-ProcHealth-5m','Mason2-HttpHealthz-5m','Mason2-ServiceHealth-15m','Mason2-Heartbeat-1m','Mason2-WatchdogLiveness-2m','Mason2-SafeModeLowDisk-5m','Mason2-Sidecar7000-1m')
  $curr = @(); if($j.tasks_expected){ $curr = @($j.tasks_expected) }
  $merged = @($curr + $want) | Select-Object -Unique
  $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue $merged -Force
  ($j | ConvertTo-Json -Depth 8) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ return }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  $want = @('Mason2-UIStatus-1m','Mason2-ProcHealth-5m','Mason2-HttpHealthz-5m','Mason2-ServiceHealth-15m','Mason2-Heartbeat-1m','Mason2-WatchdogLiveness-2m','Mason2-SafeModeLowDisk-5m','Mason2-Sidecar7000-1m')
  $curr = @(); if($j.tasks_expected){ $curr = @($j.tasks_expected) }
  $merged = @($curr + $want) | Select-Object -Unique
  $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue $merged -Force
  ($j | ConvertTo-Json -Depth 8) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
