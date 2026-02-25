$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\services.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{ $j=Get-Content $cfg -Raw | ConvertFrom-Json }catch{ exit 0 }
$now=Get-Date
foreach($e in $j.expect){
  try{
    $s = Get-Service -Name $e.name -ErrorAction SilentlyContinue
    if(-not $s){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{ ts=$now.ToString('s'); kind='service'; name=$e.name; present=$false; expected=$e.status; optional=[bool]$e.optional }
      continue
    }
    $ok = ($s.Status.ToString() -eq $e.status)
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='service'; name=$e.name; present=$true; status=$s.Status.ToString(); expected=$e.status; ok=$ok; optional=[bool]$e.optional
    }
  }catch{}
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\services.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{ $j=Get-Content $cfg -Raw | ConvertFrom-Json }catch{ exit 0 }
$now=Get-Date
foreach($e in $j.expect){
  try{
    $s = Get-Service -Name $e.name -ErrorAction SilentlyContinue
    if(-not $s){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{ ts=$now.ToString('s'); kind='service'; name=$e.name; present=$false; expected=$e.status; optional=[bool]$e.optional }
      continue
    }
    $ok = ($s.Status.ToString() -eq $e.status)
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='service'; name=$e.name; present=$true; status=$s.Status.ToString(); expected=$e.status; ok=$ok; optional=[bool]$e.optional
    }
  }catch{}
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\services.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{ $j=Get-Content $cfg -Raw | ConvertFrom-Json }catch{ exit 0 }
$now=Get-Date
foreach($e in $j.expect){
  try{
    $s = Get-Service -Name $e.name -ErrorAction SilentlyContinue
    if(-not $s){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{ ts=$now.ToString('s'); kind='service'; name=$e.name; present=$false; expected=$e.status; optional=[bool]$e.optional }
      continue
    }
    $ok = ($s.Status.ToString() -eq $e.status)
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='service'; name=$e.name; present=$true; status=$s.Status.ToString(); expected=$e.status; ok=$ok; optional=[bool]$e.optional
    }
  }catch{}
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\services.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{ $j=Get-Content $cfg -Raw | ConvertFrom-Json }catch{ exit 0 }
$now=Get-Date
foreach($e in $j.expect){
  try{
    $s = Get-Service -Name $e.name -ErrorAction SilentlyContinue
    if(-not $s){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{ ts=$now.ToString('s'); kind='service'; name=$e.name; present=$false; expected=$e.status; optional=[bool]$e.optional }
      continue
    }
    $ok = ($s.Status.ToString() -eq $e.status)
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='service'; name=$e.name; present=$true; status=$s.Status.ToString(); expected=$e.status; ok=$ok; optional=[bool]$e.optional
    }
  }catch{}
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\services.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{ $j=Get-Content $cfg -Raw | ConvertFrom-Json }catch{ exit 0 }
$now=Get-Date
foreach($e in $j.expect){
  try{
    $s = Get-Service -Name $e.name -ErrorAction SilentlyContinue
    if(-not $s){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{ ts=$now.ToString('s'); kind='service'; name=$e.name; present=$false; expected=$e.status; optional=[bool]$e.optional }
      continue
    }
    $ok = ($s.Status.ToString() -eq $e.status)
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='service'; name=$e.name; present=$true; status=$s.Status.ToString(); expected=$e.status; ok=$ok; optional=[bool]$e.optional
    }
  }catch{}
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\services.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{ $j=Get-Content $cfg -Raw | ConvertFrom-Json }catch{ exit 0 }
$now=Get-Date
foreach($e in $j.expect){
  try{
    $s = Get-Service -Name $e.name -ErrorAction SilentlyContinue
    if(-not $s){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{ ts=$now.ToString('s'); kind='service'; name=$e.name; present=$false; expected=$e.status; optional=[bool]$e.optional }
      continue
    }
    $ok = ($s.Status.ToString() -eq $e.status)
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='service'; name=$e.name; present=$true; status=$s.Status.ToString(); expected=$e.status; ok=$ok; optional=[bool]$e.optional
    }
  }catch{}
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\services.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{ $j=Get-Content $cfg -Raw | ConvertFrom-Json }catch{ exit 0 }
$now=Get-Date
foreach($e in $j.expect){
  try{
    $s = Get-Service -Name $e.name -ErrorAction SilentlyContinue
    if(-not $s){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{ ts=$now.ToString('s'); kind='service'; name=$e.name; present=$false; expected=$e.status; optional=[bool]$e.optional }
      continue
    }
    $ok = ($s.Status.ToString() -eq $e.status)
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='service'; name=$e.name; present=$true; status=$s.Status.ToString(); expected=$e.status; ok=$ok; optional=[bool]$e.optional
    }
  }catch{}
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\services.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{ $j=Get-Content $cfg -Raw | ConvertFrom-Json }catch{ exit 0 }
$now=Get-Date
foreach($e in $j.expect){
  try{
    $s = Get-Service -Name $e.name -ErrorAction SilentlyContinue
    if(-not $s){
      Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{ ts=$now.ToString('s'); kind='service'; name=$e.name; present=$false; expected=$e.status; optional=[bool]$e.optional }
      continue
    }
    $ok = ($s.Status.ToString() -eq $e.status)
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\service_health.jsonl') -Obj @{
      ts=$now.ToString('s'); kind='service'; name=$e.name; present=$true; status=$s.Status.ToString(); expected=$e.status; ok=$ok; optional=[bool]$e.optional
    }
  }catch{}
}
