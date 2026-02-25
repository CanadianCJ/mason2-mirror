Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$token = Join-Path $Base 'reports\stop7001.flag'
"1" | Set-Content -Path $token -Encoding ASCII
Out-MasonJsonl -Kind server7001 -Event 'stop_requested' -Level 'INFO'
$deadline = (Get-Date).AddSeconds($TimeoutSec)
$ok = $false
while((Get-Date) -lt $deadline){
  try{ $c = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri 'http://127.0.0.1:7001/healthz' -Proxy $null).Content.Trim() }catch{$c=''}
  if ($c -ne 'ok'){ $ok=$true; break } ; Start-Sleep 1
}
if (-not $ok){
  schtasks /End /TN "Mason2-FileServer-7001" | Out-Null
  Out-MasonJsonl -Kind server7001 -Event 'stop_forced' -Level 'WARN' -Data @{timeout=$TimeoutSec}
}else{
  Out-MasonJsonl -Kind server7001 -Event 'stop_graceful' -Level 'INFO'
}
Remove-Item $token -ErrorAction SilentlyContinue
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([int]$TimeoutSec=20)
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$token = Join-Path $Base 'reports\stop7001.flag'
"1" | Set-Content -Path $token -Encoding ASCII
Out-MasonJsonl -Kind server7001 -Event 'stop_requested' -Level 'INFO'
$deadline = (Get-Date).AddSeconds($TimeoutSec)
$ok = $false
while((Get-Date) -lt $deadline){
  try{ $c = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri 'http://127.0.0.1:7001/healthz' -Proxy $null).Content.Trim() }catch{$c=''}
  if ($c -ne 'ok'){ $ok=$true; break } ; Start-Sleep 1
}
if (-not $ok){
  schtasks /End /TN "Mason2-FileServer-7001" | Out-Null
  Out-MasonJsonl -Kind server7001 -Event 'stop_forced' -Level 'WARN' -Data @{timeout=$TimeoutSec}
}else{
  Out-MasonJsonl -Kind server7001 -Event 'stop_graceful' -Level 'INFO'
}
Remove-Item $token -ErrorAction SilentlyContinue
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([int]$TimeoutSec=20)
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$token = Join-Path $Base 'reports\stop7001.flag'
"1" | Set-Content -Path $token -Encoding ASCII
Out-MasonJsonl -Kind server7001 -Event 'stop_requested' -Level 'INFO'
$deadline = (Get-Date).AddSeconds($TimeoutSec)
$ok = $false
while((Get-Date) -lt $deadline){
  try{ $c = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri 'http://127.0.0.1:7001/healthz' -Proxy $null).Content.Trim() }catch{$c=''}
  if ($c -ne 'ok'){ $ok=$true; break } ; Start-Sleep 1
}
if (-not $ok){
  schtasks /End /TN "Mason2-FileServer-7001" | Out-Null
  Out-MasonJsonl -Kind server7001 -Event 'stop_forced' -Level 'WARN' -Data @{timeout=$TimeoutSec}
}else{
  Out-MasonJsonl -Kind server7001 -Event 'stop_graceful' -Level 'INFO'
}
Remove-Item $token -ErrorAction SilentlyContinue
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([int]$TimeoutSec=20)
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$token = Join-Path $Base 'reports\stop7001.flag'
"1" | Set-Content -Path $token -Encoding ASCII
Out-MasonJsonl -Kind server7001 -Event 'stop_requested' -Level 'INFO'
$deadline = (Get-Date).AddSeconds($TimeoutSec)
$ok = $false
while((Get-Date) -lt $deadline){
  try{ $c = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri 'http://127.0.0.1:7001/healthz' -Proxy $null).Content.Trim() }catch{$c=''}
  if ($c -ne 'ok'){ $ok=$true; break } ; Start-Sleep 1
}
if (-not $ok){
  schtasks /End /TN "Mason2-FileServer-7001" | Out-Null
  Out-MasonJsonl -Kind server7001 -Event 'stop_forced' -Level 'WARN' -Data @{timeout=$TimeoutSec}
}else{
  Out-MasonJsonl -Kind server7001 -Event 'stop_graceful' -Level 'INFO'
}
Remove-Item $token -ErrorAction SilentlyContinue
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([int]$TimeoutSec=20)
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$token = Join-Path $Base 'reports\stop7001.flag'
"1" | Set-Content -Path $token -Encoding ASCII
Out-MasonJsonl -Kind server7001 -Event 'stop_requested' -Level 'INFO'
$deadline = (Get-Date).AddSeconds($TimeoutSec)
$ok = $false
while((Get-Date) -lt $deadline){
  try{ $c = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri 'http://127.0.0.1:7001/healthz' -Proxy $null).Content.Trim() }catch{$c=''}
  if ($c -ne 'ok'){ $ok=$true; break } ; Start-Sleep 1
}
if (-not $ok){
  schtasks /End /TN "Mason2-FileServer-7001" | Out-Null
  Out-MasonJsonl -Kind server7001 -Event 'stop_forced' -Level 'WARN' -Data @{timeout=$TimeoutSec}
}else{
  Out-MasonJsonl -Kind server7001 -Event 'stop_graceful' -Level 'INFO'
}
Remove-Item $token -ErrorAction SilentlyContinue
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([int]$TimeoutSec=20)
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$token = Join-Path $Base 'reports\stop7001.flag'
"1" | Set-Content -Path $token -Encoding ASCII
Out-MasonJsonl -Kind server7001 -Event 'stop_requested' -Level 'INFO'
$deadline = (Get-Date).AddSeconds($TimeoutSec)
$ok = $false
while((Get-Date) -lt $deadline){
  try{ $c = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri 'http://127.0.0.1:7001/healthz' -Proxy $null).Content.Trim() }catch{$c=''}
  if ($c -ne 'ok'){ $ok=$true; break } ; Start-Sleep 1
}
if (-not $ok){
  schtasks /End /TN "Mason2-FileServer-7001" | Out-Null
  Out-MasonJsonl -Kind server7001 -Event 'stop_forced' -Level 'WARN' -Data @{timeout=$TimeoutSec}
}else{
  Out-MasonJsonl -Kind server7001 -Event 'stop_graceful' -Level 'INFO'
}
Remove-Item $token -ErrorAction SilentlyContinue
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([int]$TimeoutSec=20)
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$token = Join-Path $Base 'reports\stop7001.flag'
"1" | Set-Content -Path $token -Encoding ASCII
Out-MasonJsonl -Kind server7001 -Event 'stop_requested' -Level 'INFO'
$deadline = (Get-Date).AddSeconds($TimeoutSec)
$ok = $false
while((Get-Date) -lt $deadline){
  try{ $c = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri 'http://127.0.0.1:7001/healthz' -Proxy $null).Content.Trim() }catch{$c=''}
  if ($c -ne 'ok'){ $ok=$true; break } ; Start-Sleep 1
}
if (-not $ok){
  schtasks /End /TN "Mason2-FileServer-7001" | Out-Null
  Out-MasonJsonl -Kind server7001 -Event 'stop_forced' -Level 'WARN' -Data @{timeout=$TimeoutSec}
}else{
  Out-MasonJsonl -Kind server7001 -Event 'stop_graceful' -Level 'INFO'
}
Remove-Item $token -ErrorAction SilentlyContinue
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = "$env:USERPROFILE\Desktop\Mason2"
$token = Join-Path $Base 'reports\stop7001.flag'
"1" | Set-Content -Path $token -Encoding ASCII
Out-MasonJsonl -Kind server7001 -Event 'stop_requested' -Level 'INFO'
$deadline = (Get-Date).AddSeconds($TimeoutSec)
$ok = $false
while((Get-Date) -lt $deadline){
  try{ $c = (Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 -Uri 'http://127.0.0.1:7001/healthz' -Proxy $null).Content.Trim() }catch{$c=''}
  if ($c -ne 'ok'){ $ok=$true; break } ; Start-Sleep 1
}
if (-not $ok){
  schtasks /End /TN "Mason2-FileServer-7001" | Out-Null
  Out-MasonJsonl -Kind server7001 -Event 'stop_forced' -Level 'WARN' -Data @{timeout=$TimeoutSec}
}else{
  Out-MasonJsonl -Kind server7001 -Event 'stop_graceful' -Level 'INFO'
}
Remove-Item $token -ErrorAction SilentlyContinue
