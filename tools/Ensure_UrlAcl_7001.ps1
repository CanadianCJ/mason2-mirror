$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$ok=$true; $out=$null; $rc=$null
try{
  $out = (& netsh http add urlacl url=http://+:7001/ user=Everyone 2>&1) -join "`n"
  $rc  = $LASTEXITCODE
  if($rc -ne 0 -and $out -notmatch 'already exists'){ $ok=$false }
}catch{
  $ok=$false; $out=$_.Exception.Message
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\http7001.jsonl') -Obj @{ ts=$now.ToString('s'); kind='urlacl7001'; ok=$ok; rc=$rc; out=$out }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$ok=$true; $out=$null; $rc=$null
try{
  $out = (& netsh http add urlacl url=http://+:7001/ user=Everyone 2>&1) -join "`n"
  $rc  = $LASTEXITCODE
  if($rc -ne 0 -and $out -notmatch 'already exists'){ $ok=$false }
}catch{
  $ok=$false; $out=$_.Exception.Message
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\http7001.jsonl') -Obj @{ ts=$now.ToString('s'); kind='urlacl7001'; ok=$ok; rc=$rc; out=$out }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$ok=$true; $out=$null; $rc=$null
try{
  $out = (& netsh http add urlacl url=http://+:7001/ user=Everyone 2>&1) -join "`n"
  $rc  = $LASTEXITCODE
  if($rc -ne 0 -and $out -notmatch 'already exists'){ $ok=$false }
}catch{
  $ok=$false; $out=$_.Exception.Message
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\http7001.jsonl') -Obj @{ ts=$now.ToString('s'); kind='urlacl7001'; ok=$ok; rc=$rc; out=$out }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$ok=$true; $out=$null; $rc=$null
try{
  $out = (& netsh http add urlacl url=http://+:7001/ user=Everyone 2>&1) -join "`n"
  $rc  = $LASTEXITCODE
  if($rc -ne 0 -and $out -notmatch 'already exists'){ $ok=$false }
}catch{
  $ok=$false; $out=$_.Exception.Message
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\http7001.jsonl') -Obj @{ ts=$now.ToString('s'); kind='urlacl7001'; ok=$ok; rc=$rc; out=$out }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$ok=$true; $out=$null; $rc=$null
try{
  $out = (& netsh http add urlacl url=http://+:7001/ user=Everyone 2>&1) -join "`n"
  $rc  = $LASTEXITCODE
  if($rc -ne 0 -and $out -notmatch 'already exists'){ $ok=$false }
}catch{
  $ok=$false; $out=$_.Exception.Message
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\http7001.jsonl') -Obj @{ ts=$now.ToString('s'); kind='urlacl7001'; ok=$ok; rc=$rc; out=$out }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$ok=$true; $out=$null; $rc=$null
try{
  $out = (& netsh http add urlacl url=http://+:7001/ user=Everyone 2>&1) -join "`n"
  $rc  = $LASTEXITCODE
  if($rc -ne 0 -and $out -notmatch 'already exists'){ $ok=$false }
}catch{
  $ok=$false; $out=$_.Exception.Message
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\http7001.jsonl') -Obj @{ ts=$now.ToString('s'); kind='urlacl7001'; ok=$ok; rc=$rc; out=$out }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$ok=$true; $out=$null; $rc=$null
try{
  $out = (& netsh http add urlacl url=http://+:7001/ user=Everyone 2>&1) -join "`n"
  $rc  = $LASTEXITCODE
  if($rc -ne 0 -and $out -notmatch 'already exists'){ $ok=$false }
}catch{
  $ok=$false; $out=$_.Exception.Message
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\http7001.jsonl') -Obj @{ ts=$now.ToString('s'); kind='urlacl7001'; ok=$ok; rc=$rc; out=$out }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$ok=$true; $out=$null; $rc=$null
try{
  $out = (& netsh http add urlacl url=http://+:7001/ user=Everyone 2>&1) -join "`n"
  $rc  = $LASTEXITCODE
  if($rc -ne 0 -and $out -notmatch 'already exists'){ $ok=$false }
}catch{
  $ok=$false; $out=$_.Exception.Message
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\http7001.jsonl') -Obj @{ ts=$now.ToString('s'); kind='urlacl7001'; ok=$ok; rc=$rc; out=$out }
