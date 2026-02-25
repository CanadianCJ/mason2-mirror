$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
$items = @()

# Run keys (HKLM/HKCU)
$runKeys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
)
foreach($rk in $runKeys){
  try{
    if(Test-Path $rk){
      $k = Get-Item $rk
      $k.GetValueNames() | ForEach-Object {
        try{
          $items += [pscustomobject]@{ kind='RunKey'; root=$rk; name=$_; value=$k.GetValue($_) }
        }catch{}
      }
    }
  }catch{}
}

# Startup folders
$folders = @(
  "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
  "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
)
foreach($f in $folders){
  try{
    if(Test-Path $f){
      Get-ChildItem -LiteralPath $f -File -ErrorAction SilentlyContinue | ForEach-Object {
        $items += [pscustomobject]@{ kind='StartupFolder'; path=$_.FullName; bytes=$_.Length }
      }
    }
  }catch{}
}

# Logon-triggered tasks (best effort)
try{
  Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.Triggers -and ($_.Triggers | Where-Object { $_.TriggerType -match 'Logon' })
  } | ForEach-Object {
    $items += [pscustomobject]@{ kind='LogonTask'; name=$_.TaskName; path=$_.TaskPath }
  }
}catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\startup.jsonl') -Obj @{ ts=$now.ToString('s'); kind='startup_audit'; items=$items }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
$items = @()

# Run keys (HKLM/HKCU)
$runKeys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
)
foreach($rk in $runKeys){
  try{
    if(Test-Path $rk){
      $k = Get-Item $rk
      $k.GetValueNames() | ForEach-Object {
        try{
          $items += [pscustomobject]@{ kind='RunKey'; root=$rk; name=$_; value=$k.GetValue($_) }
        }catch{}
      }
    }
  }catch{}
}

# Startup folders
$folders = @(
  "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
  "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
)
foreach($f in $folders){
  try{
    if(Test-Path $f){
      Get-ChildItem -LiteralPath $f -File -ErrorAction SilentlyContinue | ForEach-Object {
        $items += [pscustomobject]@{ kind='StartupFolder'; path=$_.FullName; bytes=$_.Length }
      }
    }
  }catch{}
}

# Logon-triggered tasks (best effort)
try{
  Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.Triggers -and ($_.Triggers | Where-Object { $_.TriggerType -match 'Logon' })
  } | ForEach-Object {
    $items += [pscustomobject]@{ kind='LogonTask'; name=$_.TaskName; path=$_.TaskPath }
  }
}catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\startup.jsonl') -Obj @{ ts=$now.ToString('s'); kind='startup_audit'; items=$items }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
$items = @()

# Run keys (HKLM/HKCU)
$runKeys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
)
foreach($rk in $runKeys){
  try{
    if(Test-Path $rk){
      $k = Get-Item $rk
      $k.GetValueNames() | ForEach-Object {
        try{
          $items += [pscustomobject]@{ kind='RunKey'; root=$rk; name=$_; value=$k.GetValue($_) }
        }catch{}
      }
    }
  }catch{}
}

# Startup folders
$folders = @(
  "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
  "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
)
foreach($f in $folders){
  try{
    if(Test-Path $f){
      Get-ChildItem -LiteralPath $f -File -ErrorAction SilentlyContinue | ForEach-Object {
        $items += [pscustomobject]@{ kind='StartupFolder'; path=$_.FullName; bytes=$_.Length }
      }
    }
  }catch{}
}

# Logon-triggered tasks (best effort)
try{
  Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.Triggers -and ($_.Triggers | Where-Object { $_.TriggerType -match 'Logon' })
  } | ForEach-Object {
    $items += [pscustomobject]@{ kind='LogonTask'; name=$_.TaskName; path=$_.TaskPath }
  }
}catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\startup.jsonl') -Obj @{ ts=$now.ToString('s'); kind='startup_audit'; items=$items }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
$items = @()

# Run keys (HKLM/HKCU)
$runKeys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
)
foreach($rk in $runKeys){
  try{
    if(Test-Path $rk){
      $k = Get-Item $rk
      $k.GetValueNames() | ForEach-Object {
        try{
          $items += [pscustomobject]@{ kind='RunKey'; root=$rk; name=$_; value=$k.GetValue($_) }
        }catch{}
      }
    }
  }catch{}
}

# Startup folders
$folders = @(
  "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
  "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
)
foreach($f in $folders){
  try{
    if(Test-Path $f){
      Get-ChildItem -LiteralPath $f -File -ErrorAction SilentlyContinue | ForEach-Object {
        $items += [pscustomobject]@{ kind='StartupFolder'; path=$_.FullName; bytes=$_.Length }
      }
    }
  }catch{}
}

# Logon-triggered tasks (best effort)
try{
  Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.Triggers -and ($_.Triggers | Where-Object { $_.TriggerType -match 'Logon' })
  } | ForEach-Object {
    $items += [pscustomobject]@{ kind='LogonTask'; name=$_.TaskName; path=$_.TaskPath }
  }
}catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\startup.jsonl') -Obj @{ ts=$now.ToString('s'); kind='startup_audit'; items=$items }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
$items = @()

# Run keys (HKLM/HKCU)
$runKeys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
)
foreach($rk in $runKeys){
  try{
    if(Test-Path $rk){
      $k = Get-Item $rk
      $k.GetValueNames() | ForEach-Object {
        try{
          $items += [pscustomobject]@{ kind='RunKey'; root=$rk; name=$_; value=$k.GetValue($_) }
        }catch{}
      }
    }
  }catch{}
}

# Startup folders
$folders = @(
  "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
  "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
)
foreach($f in $folders){
  try{
    if(Test-Path $f){
      Get-ChildItem -LiteralPath $f -File -ErrorAction SilentlyContinue | ForEach-Object {
        $items += [pscustomobject]@{ kind='StartupFolder'; path=$_.FullName; bytes=$_.Length }
      }
    }
  }catch{}
}

# Logon-triggered tasks (best effort)
try{
  Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.Triggers -and ($_.Triggers | Where-Object { $_.TriggerType -match 'Logon' })
  } | ForEach-Object {
    $items += [pscustomobject]@{ kind='LogonTask'; name=$_.TaskName; path=$_.TaskPath }
  }
}catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\startup.jsonl') -Obj @{ ts=$now.ToString('s'); kind='startup_audit'; items=$items }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
$items = @()

# Run keys (HKLM/HKCU)
$runKeys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
)
foreach($rk in $runKeys){
  try{
    if(Test-Path $rk){
      $k = Get-Item $rk
      $k.GetValueNames() | ForEach-Object {
        try{
          $items += [pscustomobject]@{ kind='RunKey'; root=$rk; name=$_; value=$k.GetValue($_) }
        }catch{}
      }
    }
  }catch{}
}

# Startup folders
$folders = @(
  "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
  "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
)
foreach($f in $folders){
  try{
    if(Test-Path $f){
      Get-ChildItem -LiteralPath $f -File -ErrorAction SilentlyContinue | ForEach-Object {
        $items += [pscustomobject]@{ kind='StartupFolder'; path=$_.FullName; bytes=$_.Length }
      }
    }
  }catch{}
}

# Logon-triggered tasks (best effort)
try{
  Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.Triggers -and ($_.Triggers | Where-Object { $_.TriggerType -match 'Logon' })
  } | ForEach-Object {
    $items += [pscustomobject]@{ kind='LogonTask'; name=$_.TaskName; path=$_.TaskPath }
  }
}catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\startup.jsonl') -Obj @{ ts=$now.ToString('s'); kind='startup_audit'; items=$items }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
$items = @()

# Run keys (HKLM/HKCU)
$runKeys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
)
foreach($rk in $runKeys){
  try{
    if(Test-Path $rk){
      $k = Get-Item $rk
      $k.GetValueNames() | ForEach-Object {
        try{
          $items += [pscustomobject]@{ kind='RunKey'; root=$rk; name=$_; value=$k.GetValue($_) }
        }catch{}
      }
    }
  }catch{}
}

# Startup folders
$folders = @(
  "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
  "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
)
foreach($f in $folders){
  try{
    if(Test-Path $f){
      Get-ChildItem -LiteralPath $f -File -ErrorAction SilentlyContinue | ForEach-Object {
        $items += [pscustomobject]@{ kind='StartupFolder'; path=$_.FullName; bytes=$_.Length }
      }
    }
  }catch{}
}

# Logon-triggered tasks (best effort)
try{
  Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.Triggers -and ($_.Triggers | Where-Object { $_.TriggerType -match 'Logon' })
  } | ForEach-Object {
    $items += [pscustomobject]@{ kind='LogonTask'; name=$_.TaskName; path=$_.TaskPath }
  }
}catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\startup.jsonl') -Obj @{ ts=$now.ToString('s'); kind='startup_audit'; items=$items }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$now = Get-Date
$items = @()

# Run keys (HKLM/HKCU)
$runKeys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
)
foreach($rk in $runKeys){
  try{
    if(Test-Path $rk){
      $k = Get-Item $rk
      $k.GetValueNames() | ForEach-Object {
        try{
          $items += [pscustomobject]@{ kind='RunKey'; root=$rk; name=$_; value=$k.GetValue($_) }
        }catch{}
      }
    }
  }catch{}
}

# Startup folders
$folders = @(
  "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
  "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
)
foreach($f in $folders){
  try{
    if(Test-Path $f){
      Get-ChildItem -LiteralPath $f -File -ErrorAction SilentlyContinue | ForEach-Object {
        $items += [pscustomobject]@{ kind='StartupFolder'; path=$_.FullName; bytes=$_.Length }
      }
    }
  }catch{}
}

# Logon-triggered tasks (best effort)
try{
  Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.Triggers -and ($_.Triggers | Where-Object { $_.TriggerType -match 'Logon' })
  } | ForEach-Object {
    $items += [pscustomobject]@{ kind='LogonTask'; name=$_.TaskName; path=$_.TaskPath }
  }
}catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\startup.jsonl') -Obj @{ ts=$now.ToString('s'); kind='startup_audit'; items=$items }
