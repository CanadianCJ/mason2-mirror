$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try {
  $b = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
  if($b){
    foreach($x in $b){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{
        ts=$now.ToString('s'); kind='battery'; present=$true; est_pct=$x.EstimatedChargeRemaining; status=$x.BatteryStatus
      }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{ ts=$now.ToString('s'); kind='battery'; present=$false }
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
  $b = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
  if($b){
    foreach($x in $b){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{
        ts=$now.ToString('s'); kind='battery'; present=$true; est_pct=$x.EstimatedChargeRemaining; status=$x.BatteryStatus
      }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{ ts=$now.ToString('s'); kind='battery'; present=$false }
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
  $b = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
  if($b){
    foreach($x in $b){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{
        ts=$now.ToString('s'); kind='battery'; present=$true; est_pct=$x.EstimatedChargeRemaining; status=$x.BatteryStatus
      }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{ ts=$now.ToString('s'); kind='battery'; present=$false }
  }
} catch {}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try {
  $b = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
  if($b){
    foreach($x in $b){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{
        ts=$now.ToString('s'); kind='battery'; present=$true; est_pct=$x.EstimatedChargeRemaining; status=$x.BatteryStatus
      }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{ ts=$now.ToString('s'); kind='battery'; present=$false }
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
  $b = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
  if($b){
    foreach($x in $b){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{
        ts=$now.ToString('s'); kind='battery'; present=$true; est_pct=$x.EstimatedChargeRemaining; status=$x.BatteryStatus
      }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{ ts=$now.ToString('s'); kind='battery'; present=$false }
  }
} catch {}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try {
  $b = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
  if($b){
    foreach($x in $b){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{
        ts=$now.ToString('s'); kind='battery'; present=$true; est_pct=$x.EstimatedChargeRemaining; status=$x.BatteryStatus
      }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{ ts=$now.ToString('s'); kind='battery'; present=$false }
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
  $b = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
  if($b){
    foreach($x in $b){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{
        ts=$now.ToString('s'); kind='battery'; present=$true; est_pct=$x.EstimatedChargeRemaining; status=$x.BatteryStatus
      }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{ ts=$now.ToString('s'); kind='battery'; present=$false }
  }
} catch {}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
try {
  $b = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
  if($b){
    foreach($x in $b){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{
        ts=$now.ToString('s'); kind='battery'; present=$true; est_pct=$x.EstimatedChargeRemaining; status=$x.BatteryStatus
      }
    }
  } else {
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\battery.jsonl') -Obj @{ ts=$now.ToString('s'); kind='battery'; present=$false }
  }
} catch {}
