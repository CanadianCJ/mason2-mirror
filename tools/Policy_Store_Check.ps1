$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok=$true; $errs=@()
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){ $ok=$false; $errs+='policy.json missing' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\policy_check.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='policy_check'; ok=$ok; errors=$errs }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok=$true; $errs=@()
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){ $ok=$false; $errs+='policy.json missing' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\policy_check.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='policy_check'; ok=$ok; errors=$errs }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok=$true; $errs=@()
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){ $ok=$false; $errs+='policy.json missing' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\policy_check.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='policy_check'; ok=$ok; errors=$errs }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok=$true; $errs=@()
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){ $ok=$false; $errs+='policy.json missing' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\policy_check.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='policy_check'; ok=$ok; errors=$errs }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok=$true; $errs=@()
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){ $ok=$false; $errs+='policy.json missing' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\policy_check.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='policy_check'; ok=$ok; errors=$errs }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok=$true; $errs=@()
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){ $ok=$false; $errs+='policy.json missing' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\policy_check.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='policy_check'; ok=$ok; errors=$errs }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok=$true; $errs=@()
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){ $ok=$false; $errs+='policy.json missing' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\policy_check.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='policy_check'; ok=$ok; errors=$errs }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$ok=$true; $errs=@()
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){ $ok=$false; $errs+='policy.json missing' }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\policy_check.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='policy_check'; ok=$ok; errors=$errs }
