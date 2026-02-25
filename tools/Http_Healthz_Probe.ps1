$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$eps=@()
if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $eps=@($j.http) }catch{} }
foreach($e in $eps){
  Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 800)
  $ok=$false; $ms=$null
  $timeout = 3
  try{ if($e -and $e.PSObject.Properties['timeout_s'] -and $e.timeout_s){ $timeout = [int]$e.timeout_s } }catch{}
  $t0=Get-Date
  try{
    $r = Invoke-WebRequest -Uri $e.url -UseBasicParsing -TimeoutSec $timeout
    if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $ok=$true }
  }catch{}
  $ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\http_healthz.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='httpz'; url=$e.url; ok=$ok; ms=$ms; timeout_s=$timeout }
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$eps=@()
if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $eps=@($j.http) }catch{} }
foreach($e in $eps){
  Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 800)
  $ok=$false; $ms=$null
  $timeout = 3
  try{ if($e -and $e.PSObject.Properties['timeout_s'] -and $e.timeout_s){ $timeout = [int]$e.timeout_s } }catch{}
  $t0=Get-Date
  try{
    $r = Invoke-WebRequest -Uri $e.url -UseBasicParsing -TimeoutSec $timeout
    if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $ok=$true }
  }catch{}
  $ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\http_healthz.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='httpz'; url=$e.url; ok=$ok; ms=$ms; timeout_s=$timeout }
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$eps=@()
if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $eps=@($j.http) }catch{} }
foreach($e in $eps){
  Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 800)
  $ok=$false; $ms=$null
  $timeout = 3
  try{ if($e -and $e.PSObject.Properties['timeout_s'] -and $e.timeout_s){ $timeout = [int]$e.timeout_s } }catch{}
  $t0=Get-Date
  try{
    $r = Invoke-WebRequest -Uri $e.url -UseBasicParsing -TimeoutSec $timeout
    if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $ok=$true }
  }catch{}
  $ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\http_healthz.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='httpz'; url=$e.url; ok=$ok; ms=$ms; timeout_s=$timeout }
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$eps=@()
if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $eps=@($j.http) }catch{} }
foreach($e in $eps){
  Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 800)
  $ok=$false; $ms=$null
  $timeout = 3
  try{ if($e -and $e.PSObject.Properties['timeout_s'] -and $e.timeout_s){ $timeout = [int]$e.timeout_s } }catch{}
  $t0=Get-Date
  try{
    $r = Invoke-WebRequest -Uri $e.url -UseBasicParsing -TimeoutSec $timeout
    if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $ok=$true }
  }catch{}
  $ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\http_healthz.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='httpz'; url=$e.url; ok=$ok; ms=$ms; timeout_s=$timeout }
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$eps=@()
if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $eps=@($j.http) }catch{} }
foreach($e in $eps){
  Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 800)
  $ok=$false; $ms=$null
  $timeout = 3
  try{ if($e -and $e.PSObject.Properties['timeout_s'] -and $e.timeout_s){ $timeout = [int]$e.timeout_s } }catch{}
  $t0=Get-Date
  try{
    $r = Invoke-WebRequest -Uri $e.url -UseBasicParsing -TimeoutSec $timeout
    if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $ok=$true }
  }catch{}
  $ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\http_healthz.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='httpz'; url=$e.url; ok=$ok; ms=$ms; timeout_s=$timeout }
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$eps=@()
if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $eps=@($j.http) }catch{} }
foreach($e in $eps){
  Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 800)
  $ok=$false; $ms=$null
  $timeout = 3
  try{ if($e -and $e.PSObject.Properties['timeout_s'] -and $e.timeout_s){ $timeout = [int]$e.timeout_s } }catch{}
  $t0=Get-Date
  try{
    $r = Invoke-WebRequest -Uri $e.url -UseBasicParsing -TimeoutSec $timeout
    if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $ok=$true }
  }catch{}
  $ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\http_healthz.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='httpz'; url=$e.url; ok=$ok; ms=$ms; timeout_s=$timeout }
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$eps=@()
if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $eps=@($j.http) }catch{} }
foreach($e in $eps){
  Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 800)
  $ok=$false; $ms=$null
  $timeout = 3
  try{ if($e -and $e.PSObject.Properties['timeout_s'] -and $e.timeout_s){ $timeout = [int]$e.timeout_s } }catch{}
  $t0=Get-Date
  try{
    $r = Invoke-WebRequest -Uri $e.url -UseBasicParsing -TimeoutSec $timeout
    if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $ok=$true }
  }catch{}
  $ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\http_healthz.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='httpz'; url=$e.url; ok=$ok; ms=$ms; timeout_s=$timeout }
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$eps=@()
if(Test-Path $cfg){ try{ $j=Get-Content $cfg -Raw|ConvertFrom-Json; $eps=@($j.http) }catch{} }
foreach($e in $eps){
  Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 800)
  $ok=$false; $ms=$null
  $timeout = 3
  try{ if($e -and $e.PSObject.Properties['timeout_s'] -and $e.timeout_s){ $timeout = [int]$e.timeout_s } }catch{}
  $t0=Get-Date
  try{
    $r = Invoke-WebRequest -Uri $e.url -UseBasicParsing -TimeoutSec $timeout
    if($r.StatusCode -ge 200 -and $r.StatusCode -lt 400){ $ok=$true }
  }catch{}
  $ms=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalMilliseconds)
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\http_healthz.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='httpz'; url=$e.url; ok=$ok; ms=$ms; timeout_s=$timeout }
}
