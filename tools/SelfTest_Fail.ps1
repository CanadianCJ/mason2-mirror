Write-Host "[Mason2] Intentional failure self-test."
exit 21
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference="Stop"
Write-Host "[Mason2] Intentional failure self-test."
exit 21
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference="Stop"
Write-Host "[Mason2] Intentional failure self-test."
exit 21
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference="Stop"
Write-Host "[Mason2] Intentional failure self-test."
exit 21
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference="Stop"
Write-Host "[Mason2] Intentional failure self-test."
exit 21
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference="Stop"
Write-Host "[Mason2] Intentional failure self-test."
exit 21
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference="Stop"
Write-Host "[Mason2] Intentional failure self-test."
exit 21
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
Write-Host "[Mason2] Intentional failure self-test."
exit 21
