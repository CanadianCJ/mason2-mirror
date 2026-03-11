$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$since = (Get-Date).AddMinutes(-$Minutes)
$logs = @('Application','System')
foreach($lg in $logs){
  try{
    $evs = Get-WinEvent -FilterHashtable @{ LogName=$lg; StartTime=$since } -ErrorAction SilentlyContinue
    foreach($e in $evs){
      try{
        $lvl = $e.LevelDisplayName
        if($lvl -ne 'Error' -and $lvl -ne 'Warning'){ continue }
        $msg = $e.Message
        if($msg -and $msg.Length -gt 400){ $msg = $msg.Substring(0,400) + '...' }
        Write-JsonLineSafe -Path (Join-Path $Base 'reports\eventlog.jsonl') -Obj @{
          ts=$e.TimeCreated.ToString('s'); kind='event'; log=$lg; id=$e.Id; level=$lvl; provider=$e.ProviderName; message=$msg
        }
      }catch{}
    }
  }catch{}
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=60)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$since = (Get-Date).AddMinutes(-$Minutes)
$logs = @('Application','System')
foreach($lg in $logs){
  try{
    $evs = Get-WinEvent -FilterHashtable @{ LogName=$lg; StartTime=$since } -ErrorAction SilentlyContinue
    foreach($e in $evs){
      try{
        $lvl = $e.LevelDisplayName
        if($lvl -ne 'Error' -and $lvl -ne 'Warning'){ continue }
        $msg = $e.Message
        if($msg -and $msg.Length -gt 400){ $msg = $msg.Substring(0,400) + '...' }
        Write-JsonLineSafe -Path (Join-Path $Base 'reports\eventlog.jsonl') -Obj @{
          ts=$e.TimeCreated.ToString('s'); kind='event'; log=$lg; id=$e.Id; level=$lvl; provider=$e.ProviderName; message=$msg
        }
      }catch{}
    }
  }catch{}
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=60)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$since = (Get-Date).AddMinutes(-$Minutes)
$logs = @('Application','System')
foreach($lg in $logs){
  try{
    $evs = Get-WinEvent -FilterHashtable @{ LogName=$lg; StartTime=$since } -ErrorAction SilentlyContinue
    foreach($e in $evs){
      try{
        $lvl = $e.LevelDisplayName
        if($lvl -ne 'Error' -and $lvl -ne 'Warning'){ continue }
        $msg = $e.Message
        if($msg -and $msg.Length -gt 400){ $msg = $msg.Substring(0,400) + '...' }
        Write-JsonLineSafe -Path (Join-Path $Base 'reports\eventlog.jsonl') -Obj @{
          ts=$e.TimeCreated.ToString('s'); kind='event'; log=$lg; id=$e.Id; level=$lvl; provider=$e.ProviderName; message=$msg
        }
      }catch{}
    }
  }catch{}
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=60)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$since = (Get-Date).AddMinutes(-$Minutes)
$logs = @('Application','System')
foreach($lg in $logs){
  try{
    $evs = Get-WinEvent -FilterHashtable @{ LogName=$lg; StartTime=$since } -ErrorAction SilentlyContinue
    foreach($e in $evs){
      try{
        $lvl = $e.LevelDisplayName
        if($lvl -ne 'Error' -and $lvl -ne 'Warning'){ continue }
        $msg = $e.Message
        if($msg -and $msg.Length -gt 400){ $msg = $msg.Substring(0,400) + '...' }
        Write-JsonLineSafe -Path (Join-Path $Base 'reports\eventlog.jsonl') -Obj @{
          ts=$e.TimeCreated.ToString('s'); kind='event'; log=$lg; id=$e.Id; level=$lvl; provider=$e.ProviderName; message=$msg
        }
      }catch{}
    }
  }catch{}
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=60)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$since = (Get-Date).AddMinutes(-$Minutes)
$logs = @('Application','System')
foreach($lg in $logs){
  try{
    $evs = Get-WinEvent -FilterHashtable @{ LogName=$lg; StartTime=$since } -ErrorAction SilentlyContinue
    foreach($e in $evs){
      try{
        $lvl = $e.LevelDisplayName
        if($lvl -ne 'Error' -and $lvl -ne 'Warning'){ continue }
        $msg = $e.Message
        if($msg -and $msg.Length -gt 400){ $msg = $msg.Substring(0,400) + '...' }
        Write-JsonLineSafe -Path (Join-Path $Base 'reports\eventlog.jsonl') -Obj @{
          ts=$e.TimeCreated.ToString('s'); kind='event'; log=$lg; id=$e.Id; level=$lvl; provider=$e.ProviderName; message=$msg
        }
      }catch{}
    }
  }catch{}
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=60)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$since = (Get-Date).AddMinutes(-$Minutes)
$logs = @('Application','System')
foreach($lg in $logs){
  try{
    $evs = Get-WinEvent -FilterHashtable @{ LogName=$lg; StartTime=$since } -ErrorAction SilentlyContinue
    foreach($e in $evs){
      try{
        $lvl = $e.LevelDisplayName
        if($lvl -ne 'Error' -and $lvl -ne 'Warning'){ continue }
        $msg = $e.Message
        if($msg -and $msg.Length -gt 400){ $msg = $msg.Substring(0,400) + '...' }
        Write-JsonLineSafe -Path (Join-Path $Base 'reports\eventlog.jsonl') -Obj @{
          ts=$e.TimeCreated.ToString('s'); kind='event'; log=$lg; id=$e.Id; level=$lvl; provider=$e.ProviderName; message=$msg
        }
      }catch{}
    }
  }catch{}
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=60)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$since = (Get-Date).AddMinutes(-$Minutes)
$logs = @('Application','System')
foreach($lg in $logs){
  try{
    $evs = Get-WinEvent -FilterHashtable @{ LogName=$lg; StartTime=$since } -ErrorAction SilentlyContinue
    foreach($e in $evs){
      try{
        $lvl = $e.LevelDisplayName
        if($lvl -ne 'Error' -and $lvl -ne 'Warning'){ continue }
        $msg = $e.Message
        if($msg -and $msg.Length -gt 400){ $msg = $msg.Substring(0,400) + '...' }
        Write-JsonLineSafe -Path (Join-Path $Base 'reports\eventlog.jsonl') -Obj @{
          ts=$e.TimeCreated.ToString('s'); kind='event'; log=$lg; id=$e.Id; level=$lvl; provider=$e.ProviderName; message=$msg
        }
      }catch{}
    }
  }catch{}
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$since = (Get-Date).AddMinutes(-$Minutes)
$logs = @('Application','System')
foreach($lg in $logs){
  try{
    $evs = Get-WinEvent -FilterHashtable @{ LogName=$lg; StartTime=$since } -ErrorAction SilentlyContinue
    foreach($e in $evs){
      try{
        $lvl = $e.LevelDisplayName
        if($lvl -ne 'Error' -and $lvl -ne 'Warning'){ continue }
        $msg = $e.Message
        if($msg -and $msg.Length -gt 400){ $msg = $msg.Substring(0,400) + '...' }
        Write-JsonLineSafe -Path (Join-Path $Base 'reports\eventlog.jsonl') -Obj @{
          ts=$e.TimeCreated.ToString('s'); kind='event'; log=$lg; id=$e.Id; level=$lvl; provider=$e.ProviderName; message=$msg
        }
      }catch{}
    }
  }catch{}
}
