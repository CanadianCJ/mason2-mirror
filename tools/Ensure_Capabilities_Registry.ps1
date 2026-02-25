$ErrorActionPreference='Stop'
$cap = Join-Path $Base 'config\capabilities.json'
if(!(Test-Path $cap)){
  @"{`"devices`":[{`"id`":"local`,`"type`":"desktop`,`"permissions`":["mic","speaker","disk"],`"evidence`":"seed:default"}]}"@ | Out-File -FilePath $cap -Encoding UTF8
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cap = Join-Path $Base 'config\capabilities.json'
if(!(Test-Path $cap)){
  @"{`"devices`":[{`"id`":"local`,`"type`":"desktop`,`"permissions`":["mic","speaker","disk"],`"evidence`":"seed:default"}]}"@ | Out-File -FilePath $cap -Encoding UTF8
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cap = Join-Path $Base 'config\capabilities.json'
if(!(Test-Path $cap)){
  @"{`"devices`":[{`"id`":"local`,`"type`":"desktop`,`"permissions`":["mic","speaker","disk"],`"evidence`":"seed:default"}]}"@ | Out-File -FilePath $cap -Encoding UTF8
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cap = Join-Path $Base 'config\capabilities.json'
if(!(Test-Path $cap)){
  @"{`"devices`":[{`"id`":"local`,`"type`":"desktop`,`"permissions`":["mic","speaker","disk"],`"evidence`":"seed:default"}]}"@ | Out-File -FilePath $cap -Encoding UTF8
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cap = Join-Path $Base 'config\capabilities.json'
if(!(Test-Path $cap)){
  @"{`"devices`":[{`"id`":"local`,`"type`":"desktop`,`"permissions`":["mic","speaker","disk"],`"evidence`":"seed:default"}]}"@ | Out-File -FilePath $cap -Encoding UTF8
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cap = Join-Path $Base 'config\capabilities.json'
if(!(Test-Path $cap)){
  @"{`"devices`":[{`"id`":"local`,`"type`":"desktop`,`"permissions`":["mic","speaker","disk"],`"evidence`":"seed:default"}]}"@ | Out-File -FilePath $cap -Encoding UTF8
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cap = Join-Path $Base 'config\capabilities.json'
if(!(Test-Path $cap)){
  @"{`"devices`":[{`"id`":"local`,`"type`":"desktop`,`"permissions`":["mic","speaker","disk"],`"evidence`":"seed:default"}]}"@ | Out-File -FilePath $cap -Encoding UTF8
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
$cap = Join-Path $Base 'config\capabilities.json'
if(!(Test-Path $cap)){
  @"{`"devices`":[{`"id`":"local`,`"type`":"desktop`,`"permissions`":["mic","speaker","disk"],`"evidence`":"seed:default"}]}"@ | Out-File -FilePath $cap -Encoding UTF8
}
