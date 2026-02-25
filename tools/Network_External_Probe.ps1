$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $dns=$false; $http=$false; $ms=$null
try{ Resolve-DnsName $TargetHost -ErrorAction Stop | Out-Null; $dns=$true }catch{}
$t0=Get-Date
try{
  $r = Invoke-WebRequest -Uri ("https://" + $TargetHost) -UseBasicParsing -TimeoutSec $TimeoutS
  if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $http=$true }
}catch{}
$ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_external.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_external'; host=$TargetHost; dns=$dns; https=$http; ms=$ms }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$TargetHost="www.microsoft.com",[int]$TimeoutS=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $dns=$false; $http=$false; $ms=$null
try{ Resolve-DnsName $TargetHost -ErrorAction Stop | Out-Null; $dns=$true }catch{}
$t0=Get-Date
try{
  $r = Invoke-WebRequest -Uri ("https://" + $TargetHost) -UseBasicParsing -TimeoutSec $TimeoutS
  if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $http=$true }
}catch{}
$ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_external.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_external'; host=$TargetHost; dns=$dns; https=$http; ms=$ms }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$TargetHost="www.microsoft.com",[int]$TimeoutS=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $dns=$false; $http=$false; $ms=$null
try{ Resolve-DnsName $TargetHost -ErrorAction Stop | Out-Null; $dns=$true }catch{}
$t0=Get-Date
try{
  $r = Invoke-WebRequest -Uri ("https://" + $TargetHost) -UseBasicParsing -TimeoutSec $TimeoutS
  if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $http=$true }
}catch{}
$ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_external.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_external'; host=$TargetHost; dns=$dns; https=$http; ms=$ms }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$TargetHost="www.microsoft.com",[int]$TimeoutS=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $dns=$false; $http=$false; $ms=$null
try{ Resolve-DnsName $TargetHost -ErrorAction Stop | Out-Null; $dns=$true }catch{}
$t0=Get-Date
try{
  $r = Invoke-WebRequest -Uri ("https://" + $TargetHost) -UseBasicParsing -TimeoutSec $TimeoutS
  if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $http=$true }
}catch{}
$ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_external.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_external'; host=$TargetHost; dns=$dns; https=$http; ms=$ms }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$TargetHost="www.microsoft.com",[int]$TimeoutS=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $dns=$false; $http=$false; $ms=$null
try{ Resolve-DnsName $TargetHost -ErrorAction Stop | Out-Null; $dns=$true }catch{}
$t0=Get-Date
try{
  $r = Invoke-WebRequest -Uri ("https://" + $TargetHost) -UseBasicParsing -TimeoutSec $TimeoutS
  if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $http=$true }
}catch{}
$ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_external.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_external'; host=$TargetHost; dns=$dns; https=$http; ms=$ms }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$TargetHost="www.microsoft.com",[int]$TimeoutS=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $dns=$false; $http=$false; $ms=$null
try{ Resolve-DnsName $TargetHost -ErrorAction Stop | Out-Null; $dns=$true }catch{}
$t0=Get-Date
try{
  $r = Invoke-WebRequest -Uri ("https://" + $TargetHost) -UseBasicParsing -TimeoutSec $TimeoutS
  if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $http=$true }
}catch{}
$ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_external.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_external'; host=$TargetHost; dns=$dns; https=$http; ms=$ms }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[string]$TargetHost="www.microsoft.com",[int]$TimeoutS=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $dns=$false; $http=$false; $ms=$null
try{ Resolve-DnsName $TargetHost -ErrorAction Stop | Out-Null; $dns=$true }catch{}
$t0=Get-Date
try{
  $r = Invoke-WebRequest -Uri ("https://" + $TargetHost) -UseBasicParsing -TimeoutSec $TimeoutS
  if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $http=$true }
}catch{}
$ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_external.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_external'; host=$TargetHost; dns=$dns; https=$http; ms=$ms }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $dns=$false; $http=$false; $ms=$null
try{ Resolve-DnsName $TargetHost -ErrorAction Stop | Out-Null; $dns=$true }catch{}
$t0=Get-Date
try{
  $r = Invoke-WebRequest -Uri ("https://" + $TargetHost) -UseBasicParsing -TimeoutSec $TimeoutS
  if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $http=$true }
}catch{}
$ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_external.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_external'; host=$TargetHost; dns=$dns; https=$http; ms=$ms }
