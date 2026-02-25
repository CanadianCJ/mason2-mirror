$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$ports=@(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $ports=@($j.ports) }catch{} }
foreach($p in $ports){
  $ok = (Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue) -ne $null
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\port_probe.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port'; port=$p; listening=$ok }
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$ports=@(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $ports=@($j.ports) }catch{} }
foreach($p in $ports){
  $ok = (Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue) -ne $null
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\port_probe.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port'; port=$p; listening=$ok }
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$ports=@(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $ports=@($j.ports) }catch{} }
foreach($p in $ports){
  $ok = (Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue) -ne $null
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\port_probe.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port'; port=$p; listening=$ok }
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$ports=@(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $ports=@($j.ports) }catch{} }
foreach($p in $ports){
  $ok = (Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue) -ne $null
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\port_probe.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port'; port=$p; listening=$ok }
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$ports=@(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $ports=@($j.ports) }catch{} }
foreach($p in $ports){
  $ok = (Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue) -ne $null
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\port_probe.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port'; port=$p; listening=$ok }
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$ports=@(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $ports=@($j.ports) }catch{} }
foreach($p in $ports){
  $ok = (Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue) -ne $null
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\port_probe.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port'; port=$p; listening=$ok }
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$ports=@(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $ports=@($j.ports) }catch{} }
foreach($p in $ports){
  $ok = (Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue) -ne $null
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\port_probe.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port'; port=$p; listening=$ok }
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$ports=@(); if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $ports=@($j.ports) }catch{} }
foreach($p in $ports){
  $ok = (Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue) -ne $null
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\port_probe.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='port'; port=$p; listening=$ok }
}
