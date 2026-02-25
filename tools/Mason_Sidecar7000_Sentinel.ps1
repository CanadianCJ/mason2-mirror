$bound = @(Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue)
if($bound -and $bound.Count -gt 0){
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_bound' -Level 'WARN' -Data @{ count=$bound.Count }
}else{
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_free' -Level 'INFO'
}_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$bound = @(Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue)
if($bound -and $bound.Count -gt 0){
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_bound' -Level 'WARN' -Data @{ count=$bound.Count }
}else{
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_free' -Level 'INFO'
}_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$bound = @(Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue)
if($bound -and $bound.Count -gt 0){
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_bound' -Level 'WARN' -Data @{ count=$bound.Count }
}else{
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_free' -Level 'INFO'
}_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$bound = @(Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue)
if($bound -and $bound.Count -gt 0){
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_bound' -Level 'WARN' -Data @{ count=$bound.Count }
}else{
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_free' -Level 'INFO'
}_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$bound = @(Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue)
if($bound -and $bound.Count -gt 0){
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_bound' -Level 'WARN' -Data @{ count=$bound.Count }
}else{
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_free' -Level 'INFO'
}_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$bound = @(Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue)
if($bound -and $bound.Count -gt 0){
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_bound' -Level 'WARN' -Data @{ count=$bound.Count }
}else{
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_free' -Level 'INFO'
}_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$bound = @(Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue)
if($bound -and $bound.Count -gt 0){
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_bound' -Level 'WARN' -Data @{ count=$bound.Count }
}else{
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_free' -Level 'INFO'
}_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$bound = @(Get-NetTCPConnection -State Listen -LocalPort 7000 -ErrorAction SilentlyContinue)
if($bound -and $bound.Count -gt 0){
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_bound' -Level 'WARN' -Data @{ count=$bound.Count }
}else{
  Out-MasonJsonl -Kind 'sentinel7000' -Event 'port_free' -Level 'INFO'
}