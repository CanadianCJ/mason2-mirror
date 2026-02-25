$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='cmdlet_missing' }
  exit 0
}
try{
  $s = Get-MpComputerStatus
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{
    ts=$now.ToString('s'); kind='defender'; ok=$true; amservice=$s.AMServiceEnabled; real_time=$s.RealTimeProtectionEnabled; sig_age_hours=$s.SignatureAge
  }
}catch{
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='query_failed' }
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='cmdlet_missing' }
  exit 0
}
try{
  $s = Get-MpComputerStatus
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{
    ts=$now.ToString('s'); kind='defender'; ok=$true; amservice=$s.AMServiceEnabled; real_time=$s.RealTimeProtectionEnabled; sig_age_hours=$s.SignatureAge
  }
}catch{
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='query_failed' }
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='cmdlet_missing' }
  exit 0
}
try{
  $s = Get-MpComputerStatus
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{
    ts=$now.ToString('s'); kind='defender'; ok=$true; amservice=$s.AMServiceEnabled; real_time=$s.RealTimeProtectionEnabled; sig_age_hours=$s.SignatureAge
  }
}catch{
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='query_failed' }
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='cmdlet_missing' }
  exit 0
}
try{
  $s = Get-MpComputerStatus
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{
    ts=$now.ToString('s'); kind='defender'; ok=$true; amservice=$s.AMServiceEnabled; real_time=$s.RealTimeProtectionEnabled; sig_age_hours=$s.SignatureAge
  }
}catch{
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='query_failed' }
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='cmdlet_missing' }
  exit 0
}
try{
  $s = Get-MpComputerStatus
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{
    ts=$now.ToString('s'); kind='defender'; ok=$true; amservice=$s.AMServiceEnabled; real_time=$s.RealTimeProtectionEnabled; sig_age_hours=$s.SignatureAge
  }
}catch{
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='query_failed' }
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='cmdlet_missing' }
  exit 0
}
try{
  $s = Get-MpComputerStatus
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{
    ts=$now.ToString('s'); kind='defender'; ok=$true; amservice=$s.AMServiceEnabled; real_time=$s.RealTimeProtectionEnabled; sig_age_hours=$s.SignatureAge
  }
}catch{
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='query_failed' }
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='cmdlet_missing' }
  exit 0
}
try{
  $s = Get-MpComputerStatus
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{
    ts=$now.ToString('s'); kind='defender'; ok=$true; amservice=$s.AMServiceEnabled; real_time=$s.RealTimeProtectionEnabled; sig_age_hours=$s.SignatureAge
  }
}catch{
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='query_failed' }
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='cmdlet_missing' }
  exit 0
}
try{
  $s = Get-MpComputerStatus
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{
    ts=$now.ToString('s'); kind='defender'; ok=$true; amservice=$s.AMServiceEnabled; real_time=$s.RealTimeProtectionEnabled; sig_age_hours=$s.SignatureAge
  }
}catch{
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender'; ok=$false; reason='query_failed' }
}
