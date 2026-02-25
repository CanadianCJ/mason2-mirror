$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$names = @(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $names=@($j.processes|%{$_.name}) }catch{} }
if(-not $names -or $names.Count -eq 0){ $names=@('powershell') }
$now=Get-Date
foreach($n in $names){
  Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\proc_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='proc'; name=$_.ProcessName; id=$_.Id; ws_mb=[math]::Round($_.WorkingSet64/1MB,2); handles=$_.HandleCount
    }
  }
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$names = @(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $names=@($j.processes|%{$_.name}) }catch{} }
if(-not $names -or $names.Count -eq 0){ $names=@('powershell') }
$now=Get-Date
foreach($n in $names){
  Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\proc_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='proc'; name=$_.ProcessName; id=$_.Id; ws_mb=[math]::Round($_.WorkingSet64/1MB,2); handles=$_.HandleCount
    }
  }
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$names = @(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $names=@($j.processes|%{$_.name}) }catch{} }
if(-not $names -or $names.Count -eq 0){ $names=@('powershell') }
$now=Get-Date
foreach($n in $names){
  Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\proc_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='proc'; name=$_.ProcessName; id=$_.Id; ws_mb=[math]::Round($_.WorkingSet64/1MB,2); handles=$_.HandleCount
    }
  }
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$names = @(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $names=@($j.processes|%{$_.name}) }catch{} }
if(-not $names -or $names.Count -eq 0){ $names=@('powershell') }
$now=Get-Date
foreach($n in $names){
  Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\proc_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='proc'; name=$_.ProcessName; id=$_.Id; ws_mb=[math]::Round($_.WorkingSet64/1MB,2); handles=$_.HandleCount
    }
  }
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$names = @(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $names=@($j.processes|%{$_.name}) }catch{} }
if(-not $names -or $names.Count -eq 0){ $names=@('powershell') }
$now=Get-Date
foreach($n in $names){
  Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\proc_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='proc'; name=$_.ProcessName; id=$_.Id; ws_mb=[math]::Round($_.WorkingSet64/1MB,2); handles=$_.HandleCount
    }
  }
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$names = @(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $names=@($j.processes|%{$_.name}) }catch{} }
if(-not $names -or $names.Count -eq 0){ $names=@('powershell') }
$now=Get-Date
foreach($n in $names){
  Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\proc_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='proc'; name=$_.ProcessName; id=$_.Id; ws_mb=[math]::Round($_.WorkingSet64/1MB,2); handles=$_.HandleCount
    }
  }
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$names = @(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $names=@($j.processes|%{$_.name}) }catch{} }
if(-not $names -or $names.Count -eq 0){ $names=@('powershell') }
$now=Get-Date
foreach($n in $names){
  Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\proc_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='proc'; name=$_.ProcessName; id=$_.Id; ws_mb=[math]::Round($_.WorkingSet64/1MB,2); handles=$_.HandleCount
    }
  }
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$names = @(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $names=@($j.processes|%{$_.name}) }catch{} }
if(-not $names -or $names.Count -eq 0){ $names=@('powershell') }
$now=Get-Date
foreach($n in $names){
  Get-Process -Name $n -ErrorAction SilentlyContinue | ForEach-Object {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\proc_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='proc'; name=$_.ProcessName; id=$_.Id; ws_mb=[math]::Round($_.WorkingSet64/1MB,2); handles=$_.HandleCount
    }
  }
}
