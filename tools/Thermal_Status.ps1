$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try {
  $t = Get-WmiObject -Namespace root\wmi -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
  if($t){
    foreach($z in $t){
      $c = $null
      try { $c = [math]::Round(($z.CurrentTemperature/10)-273.15,1) } catch {}
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; instance=$z.InstanceName; celsius=$c }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; available=$false }
  }
} catch {}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try {
  $t = Get-WmiObject -Namespace root\wmi -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
  if($t){
    foreach($z in $t){
      $c = $null
      try { $c = [math]::Round(($z.CurrentTemperature/10)-273.15,1) } catch {}
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; instance=$z.InstanceName; celsius=$c }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; available=$false }
  }
} catch {}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try {
  $t = Get-WmiObject -Namespace root\wmi -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
  if($t){
    foreach($z in $t){
      $c = $null
      try { $c = [math]::Round(($z.CurrentTemperature/10)-273.15,1) } catch {}
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; instance=$z.InstanceName; celsius=$c }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; available=$false }
  }
} catch {}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try {
  $t = Get-WmiObject -Namespace root\wmi -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
  if($t){
    foreach($z in $t){
      $c = $null
      try { $c = [math]::Round(($z.CurrentTemperature/10)-273.15,1) } catch {}
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; instance=$z.InstanceName; celsius=$c }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; available=$false }
  }
} catch {}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try {
  $t = Get-WmiObject -Namespace root\wmi -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
  if($t){
    foreach($z in $t){
      $c = $null
      try { $c = [math]::Round(($z.CurrentTemperature/10)-273.15,1) } catch {}
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; instance=$z.InstanceName; celsius=$c }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; available=$false }
  }
} catch {}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try {
  $t = Get-WmiObject -Namespace root\wmi -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
  if($t){
    foreach($z in $t){
      $c = $null
      try { $c = [math]::Round(($z.CurrentTemperature/10)-273.15,1) } catch {}
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; instance=$z.InstanceName; celsius=$c }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; available=$false }
  }
} catch {}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try {
  $t = Get-WmiObject -Namespace root\wmi -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
  if($t){
    foreach($z in $t){
      $c = $null
      try { $c = [math]::Round(($z.CurrentTemperature/10)-273.15,1) } catch {}
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; instance=$z.InstanceName; celsius=$c }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; available=$false }
  }
} catch {}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try {
  $t = Get-WmiObject -Namespace root\wmi -Class MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
  if($t){
    foreach($z in $t){
      $c = $null
      try { $c = [math]::Round(($z.CurrentTemperature/10)-273.15,1) } catch {}
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; instance=$z.InstanceName; celsius=$c }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\thermal.jsonl') -Obj @{ ts=$now.ToString('s'); kind='thermal'; available=$false }
  }
} catch {}
