$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $ok=$false; $reason=$null
$cmd = Get-Command -Name Start-MpScan -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue | Out-Null
    $ok=$true
  }catch{ $reason='scan_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_quickscan.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender_quickscan'; ok=$ok; reason=$reason }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $ok=$false; $reason=$null
$cmd = Get-Command -Name Start-MpScan -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue | Out-Null
    $ok=$true
  }catch{ $reason='scan_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_quickscan.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender_quickscan'; ok=$ok; reason=$reason }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $ok=$false; $reason=$null
$cmd = Get-Command -Name Start-MpScan -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue | Out-Null
    $ok=$true
  }catch{ $reason='scan_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_quickscan.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender_quickscan'; ok=$ok; reason=$reason }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $ok=$false; $reason=$null
$cmd = Get-Command -Name Start-MpScan -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue | Out-Null
    $ok=$true
  }catch{ $reason='scan_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_quickscan.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender_quickscan'; ok=$ok; reason=$reason }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $ok=$false; $reason=$null
$cmd = Get-Command -Name Start-MpScan -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue | Out-Null
    $ok=$true
  }catch{ $reason='scan_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_quickscan.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender_quickscan'; ok=$ok; reason=$reason }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $ok=$false; $reason=$null
$cmd = Get-Command -Name Start-MpScan -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue | Out-Null
    $ok=$true
  }catch{ $reason='scan_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_quickscan.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender_quickscan'; ok=$ok; reason=$reason }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $ok=$false; $reason=$null
$cmd = Get-Command -Name Start-MpScan -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue | Out-Null
    $ok=$true
  }catch{ $reason='scan_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_quickscan.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender_quickscan'; ok=$ok; reason=$reason }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $ok=$false; $reason=$null
$cmd = Get-Command -Name Start-MpScan -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue | Out-Null
    $ok=$true
  }catch{ $reason='scan_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_quickscan.jsonl') -Obj @{ ts=$now.ToString('s'); kind='defender_quickscan'; ok=$ok; reason=$reason }
