$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$root = $env:TEMP
$removed=0
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -lt $cut } | ForEach-Object {
    try{ Remove-Item -LiteralPath $_.FullName -Force; $removed++ }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\temp_clean.jsonl') -Obj @{ ts=$now.ToString('s'); kind='temp_clean'; removed=$removed; days=$Days; root=$root }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=7)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$root = $env:TEMP
$removed=0
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -lt $cut } | ForEach-Object {
    try{ Remove-Item -LiteralPath $_.FullName -Force; $removed++ }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\temp_clean.jsonl') -Obj @{ ts=$now.ToString('s'); kind='temp_clean'; removed=$removed; days=$Days; root=$root }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=7)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$root = $env:TEMP
$removed=0
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -lt $cut } | ForEach-Object {
    try{ Remove-Item -LiteralPath $_.FullName -Force; $removed++ }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\temp_clean.jsonl') -Obj @{ ts=$now.ToString('s'); kind='temp_clean'; removed=$removed; days=$Days; root=$root }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=7)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$root = $env:TEMP
$removed=0
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -lt $cut } | ForEach-Object {
    try{ Remove-Item -LiteralPath $_.FullName -Force; $removed++ }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\temp_clean.jsonl') -Obj @{ ts=$now.ToString('s'); kind='temp_clean'; removed=$removed; days=$Days; root=$root }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=7)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$root = $env:TEMP
$removed=0
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -lt $cut } | ForEach-Object {
    try{ Remove-Item -LiteralPath $_.FullName -Force; $removed++ }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\temp_clean.jsonl') -Obj @{ ts=$now.ToString('s'); kind='temp_clean'; removed=$removed; days=$Days; root=$root }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=7)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$root = $env:TEMP
$removed=0
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -lt $cut } | ForEach-Object {
    try{ Remove-Item -LiteralPath $_.FullName -Force; $removed++ }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\temp_clean.jsonl') -Obj @{ ts=$now.ToString('s'); kind='temp_clean'; removed=$removed; days=$Days; root=$root }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=7)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$root = $env:TEMP
$removed=0
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -lt $cut } | ForEach-Object {
    try{ Remove-Item -LiteralPath $_.FullName -Force; $removed++ }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\temp_clean.jsonl') -Obj @{ ts=$now.ToString('s'); kind='temp_clean'; removed=$removed; days=$Days; root=$root }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $cut=$now.AddDays(-$Days)
$root = $env:TEMP
$removed=0
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -lt $cut } | ForEach-Object {
    try{ Remove-Item -LiteralPath $_.FullName -Force; $removed++ }catch{}
  }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\temp_clean.jsonl') -Obj @{ ts=$now.ToString('s'); kind='temp_clean'; removed=$removed; days=$Days; root=$root }
