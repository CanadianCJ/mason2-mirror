$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$avg = 0
try{
  $vals = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue
  $avg = [math]::Round((($vals | Measure-Object -Average).Average),1)
}catch{}
$now=Get-Date
if($avg -ge $Threshold){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\cpu_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='cpu_pressure'; avg_pct=$avg; threshold=$Threshold }
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Threshold=85)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$avg = 0
try{
  $vals = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue
  $avg = [math]::Round((($vals | Measure-Object -Average).Average),1)
}catch{}
$now=Get-Date
if($avg -ge $Threshold){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\cpu_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='cpu_pressure'; avg_pct=$avg; threshold=$Threshold }
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Threshold=85)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$avg = 0
try{
  $vals = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue
  $avg = [math]::Round((($vals | Measure-Object -Average).Average),1)
}catch{}
$now=Get-Date
if($avg -ge $Threshold){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\cpu_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='cpu_pressure'; avg_pct=$avg; threshold=$Threshold }
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Threshold=85)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$avg = 0
try{
  $vals = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue
  $avg = [math]::Round((($vals | Measure-Object -Average).Average),1)
}catch{}
$now=Get-Date
if($avg -ge $Threshold){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\cpu_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='cpu_pressure'; avg_pct=$avg; threshold=$Threshold }
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Threshold=85)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$avg = 0
try{
  $vals = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue
  $avg = [math]::Round((($vals | Measure-Object -Average).Average),1)
}catch{}
$now=Get-Date
if($avg -ge $Threshold){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\cpu_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='cpu_pressure'; avg_pct=$avg; threshold=$Threshold }
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Threshold=85)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$avg = 0
try{
  $vals = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue
  $avg = [math]::Round((($vals | Measure-Object -Average).Average),1)
}catch{}
$now=Get-Date
if($avg -ge $Threshold){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\cpu_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='cpu_pressure'; avg_pct=$avg; threshold=$Threshold }
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Threshold=85)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$avg = 0
try{
  $vals = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue
  $avg = [math]::Round((($vals | Measure-Object -Average).Average),1)
}catch{}
$now=Get-Date
if($avg -ge $Threshold){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\cpu_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='cpu_pressure'; avg_pct=$avg; threshold=$Threshold }
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$avg = 0
try{
  $vals = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples.CookedValue
  $avg = [math]::Round((($vals | Measure-Object -Average).Average),1)
}catch{}
$now=Get-Date
if($avg -ge $Threshold){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\cpu_pressure.jsonl') -Obj @{ ts=$now.ToString('s'); kind='cpu_pressure'; avg_pct=$avg; threshold=$Threshold }
}
