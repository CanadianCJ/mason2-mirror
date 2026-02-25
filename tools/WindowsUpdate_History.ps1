$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date

# Last success detect time
$lastDetect=$null
try{
  $rk='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect'
  if(Test-Path $rk){
    $v = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).LastSuccessTime
    if($v){ $lastDetect = $v }
  }
}catch{}

# COM history
$items=@()
try{
  $searcher = New-Object -ComObject Microsoft.Update.Searcher
  $count = $searcher.GetTotalHistoryCount()
  $n = [math]::Min([int]$Max,[int]$count)
  if($n -gt 0){
    $hist = $searcher.QueryHistory(0,$n)
    foreach($h in $hist){
      $items += [pscustomobject]@{
        Date=$h.Date; Title=$h.Title; HResult=$h.HResult; Operation=$h.Operation; ResultCode=$h.ResultCode
      }
    }
  }
}catch{}

# Service status
$svc=$null
try{ $svc = (Get-Service -Name wuauserv -ErrorAction SilentlyContinue).Status.ToString() }catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\wu_history.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='wu_history'; last_detect=$lastDetect; service=$svc; items=$items
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Max=30)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date

# Last success detect time
$lastDetect=$null
try{
  $rk='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect'
  if(Test-Path $rk){
    $v = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).LastSuccessTime
    if($v){ $lastDetect = $v }
  }
}catch{}

# COM history
$items=@()
try{
  $searcher = New-Object -ComObject Microsoft.Update.Searcher
  $count = $searcher.GetTotalHistoryCount()
  $n = [math]::Min([int]$Max,[int]$count)
  if($n -gt 0){
    $hist = $searcher.QueryHistory(0,$n)
    foreach($h in $hist){
      $items += [pscustomobject]@{
        Date=$h.Date; Title=$h.Title; HResult=$h.HResult; Operation=$h.Operation; ResultCode=$h.ResultCode
      }
    }
  }
}catch{}

# Service status
$svc=$null
try{ $svc = (Get-Service -Name wuauserv -ErrorAction SilentlyContinue).Status.ToString() }catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\wu_history.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='wu_history'; last_detect=$lastDetect; service=$svc; items=$items
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Max=30)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date

# Last success detect time
$lastDetect=$null
try{
  $rk='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect'
  if(Test-Path $rk){
    $v = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).LastSuccessTime
    if($v){ $lastDetect = $v }
  }
}catch{}

# COM history
$items=@()
try{
  $searcher = New-Object -ComObject Microsoft.Update.Searcher
  $count = $searcher.GetTotalHistoryCount()
  $n = [math]::Min([int]$Max,[int]$count)
  if($n -gt 0){
    $hist = $searcher.QueryHistory(0,$n)
    foreach($h in $hist){
      $items += [pscustomobject]@{
        Date=$h.Date; Title=$h.Title; HResult=$h.HResult; Operation=$h.Operation; ResultCode=$h.ResultCode
      }
    }
  }
}catch{}

# Service status
$svc=$null
try{ $svc = (Get-Service -Name wuauserv -ErrorAction SilentlyContinue).Status.ToString() }catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\wu_history.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='wu_history'; last_detect=$lastDetect; service=$svc; items=$items
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Max=30)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date

# Last success detect time
$lastDetect=$null
try{
  $rk='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect'
  if(Test-Path $rk){
    $v = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).LastSuccessTime
    if($v){ $lastDetect = $v }
  }
}catch{}

# COM history
$items=@()
try{
  $searcher = New-Object -ComObject Microsoft.Update.Searcher
  $count = $searcher.GetTotalHistoryCount()
  $n = [math]::Min([int]$Max,[int]$count)
  if($n -gt 0){
    $hist = $searcher.QueryHistory(0,$n)
    foreach($h in $hist){
      $items += [pscustomobject]@{
        Date=$h.Date; Title=$h.Title; HResult=$h.HResult; Operation=$h.Operation; ResultCode=$h.ResultCode
      }
    }
  }
}catch{}

# Service status
$svc=$null
try{ $svc = (Get-Service -Name wuauserv -ErrorAction SilentlyContinue).Status.ToString() }catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\wu_history.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='wu_history'; last_detect=$lastDetect; service=$svc; items=$items
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Max=30)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date

# Last success detect time
$lastDetect=$null
try{
  $rk='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect'
  if(Test-Path $rk){
    $v = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).LastSuccessTime
    if($v){ $lastDetect = $v }
  }
}catch{}

# COM history
$items=@()
try{
  $searcher = New-Object -ComObject Microsoft.Update.Searcher
  $count = $searcher.GetTotalHistoryCount()
  $n = [math]::Min([int]$Max,[int]$count)
  if($n -gt 0){
    $hist = $searcher.QueryHistory(0,$n)
    foreach($h in $hist){
      $items += [pscustomobject]@{
        Date=$h.Date; Title=$h.Title; HResult=$h.HResult; Operation=$h.Operation; ResultCode=$h.ResultCode
      }
    }
  }
}catch{}

# Service status
$svc=$null
try{ $svc = (Get-Service -Name wuauserv -ErrorAction SilentlyContinue).Status.ToString() }catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\wu_history.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='wu_history'; last_detect=$lastDetect; service=$svc; items=$items
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Max=30)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date

# Last success detect time
$lastDetect=$null
try{
  $rk='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect'
  if(Test-Path $rk){
    $v = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).LastSuccessTime
    if($v){ $lastDetect = $v }
  }
}catch{}

# COM history
$items=@()
try{
  $searcher = New-Object -ComObject Microsoft.Update.Searcher
  $count = $searcher.GetTotalHistoryCount()
  $n = [math]::Min([int]$Max,[int]$count)
  if($n -gt 0){
    $hist = $searcher.QueryHistory(0,$n)
    foreach($h in $hist){
      $items += [pscustomobject]@{
        Date=$h.Date; Title=$h.Title; HResult=$h.HResult; Operation=$h.Operation; ResultCode=$h.ResultCode
      }
    }
  }
}catch{}

# Service status
$svc=$null
try{ $svc = (Get-Service -Name wuauserv -ErrorAction SilentlyContinue).Status.ToString() }catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\wu_history.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='wu_history'; last_detect=$lastDetect; service=$svc; items=$items
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Max=30)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date

# Last success detect time
$lastDetect=$null
try{
  $rk='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect'
  if(Test-Path $rk){
    $v = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).LastSuccessTime
    if($v){ $lastDetect = $v }
  }
}catch{}

# COM history
$items=@()
try{
  $searcher = New-Object -ComObject Microsoft.Update.Searcher
  $count = $searcher.GetTotalHistoryCount()
  $n = [math]::Min([int]$Max,[int]$count)
  if($n -gt 0){
    $hist = $searcher.QueryHistory(0,$n)
    foreach($h in $hist){
      $items += [pscustomobject]@{
        Date=$h.Date; Title=$h.Title; HResult=$h.HResult; Operation=$h.Operation; ResultCode=$h.ResultCode
      }
    }
  }
}catch{}

# Service status
$svc=$null
try{ $svc = (Get-Service -Name wuauserv -ErrorAction SilentlyContinue).Status.ToString() }catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\wu_history.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='wu_history'; last_detect=$lastDetect; service=$svc; items=$items
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date

# Last success detect time
$lastDetect=$null
try{
  $rk='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Detect'
  if(Test-Path $rk){
    $v = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).LastSuccessTime
    if($v){ $lastDetect = $v }
  }
}catch{}

# COM history
$items=@()
try{
  $searcher = New-Object -ComObject Microsoft.Update.Searcher
  $count = $searcher.GetTotalHistoryCount()
  $n = [math]::Min([int]$Max,[int]$count)
  if($n -gt 0){
    $hist = $searcher.QueryHistory(0,$n)
    foreach($h in $hist){
      $items += [pscustomobject]@{
        Date=$h.Date; Title=$h.Title; HResult=$h.HResult; Operation=$h.Operation; ResultCode=$h.ResultCode
      }
    }
  }
}catch{}

# Service status
$svc=$null
try{ $svc = (Get-Service -Name wuauserv -ErrorAction SilentlyContinue).Status.ToString() }catch{}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\wu_history.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='wu_history'; last_detect=$lastDetect; service=$svc; items=$items
}
