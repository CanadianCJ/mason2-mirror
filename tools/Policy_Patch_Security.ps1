$ErrorActionPreference='Stop'
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){
@"
{
  "security": { "defender_sig_max_age_hours": 48 },
  "recycle":  { "max_gb": 5, "auto_empty": false }
}
"@ | Out-File -FilePath $pol -Encoding UTF8
exit 0
}
try{
  $j = Get-Content $pol -Raw | ConvertFrom-Json
  if(-not $j.PSObject.Properties['security']){ $j | Add-Member -NotePropertyName security -NotePropertyValue (@{}) -Force }
  if(-not $j.security.PSObject.Properties['defender_sig_max_age_hours']){ $j.security.defender_sig_max_age_hours = 48 }
  if(-not $j.PSObject.Properties['recycle']){ $j | Add-Member -NotePropertyName recycle -NotePropertyValue (@{}) -Force }
  if(-not $j.recycle.PSObject.Properties['max_gb']){ $j.recycle.max_gb = 5 }
  if(-not $j.recycle.PSObject.Properties['auto_empty']){ $j.recycle.auto_empty = $false }
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $pol -Encoding UTF8
}catch{}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){
@"
{
  "security": { "defender_sig_max_age_hours": 48 },
  "recycle":  { "max_gb": 5, "auto_empty": false }
}
"@ | Out-File -FilePath $pol -Encoding UTF8
exit 0
}
try{
  $j = Get-Content $pol -Raw | ConvertFrom-Json
  if(-not $j.PSObject.Properties['security']){ $j | Add-Member -NotePropertyName security -NotePropertyValue (@{}) -Force }
  if(-not $j.security.PSObject.Properties['defender_sig_max_age_hours']){ $j.security.defender_sig_max_age_hours = 48 }
  if(-not $j.PSObject.Properties['recycle']){ $j | Add-Member -NotePropertyName recycle -NotePropertyValue (@{}) -Force }
  if(-not $j.recycle.PSObject.Properties['max_gb']){ $j.recycle.max_gb = 5 }
  if(-not $j.recycle.PSObject.Properties['auto_empty']){ $j.recycle.auto_empty = $false }
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $pol -Encoding UTF8
}catch{}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){
@"
{
  "security": { "defender_sig_max_age_hours": 48 },
  "recycle":  { "max_gb": 5, "auto_empty": false }
}
"@ | Out-File -FilePath $pol -Encoding UTF8
exit 0
}
try{
  $j = Get-Content $pol -Raw | ConvertFrom-Json
  if(-not $j.PSObject.Properties['security']){ $j | Add-Member -NotePropertyName security -NotePropertyValue (@{}) -Force }
  if(-not $j.security.PSObject.Properties['defender_sig_max_age_hours']){ $j.security.defender_sig_max_age_hours = 48 }
  if(-not $j.PSObject.Properties['recycle']){ $j | Add-Member -NotePropertyName recycle -NotePropertyValue (@{}) -Force }
  if(-not $j.recycle.PSObject.Properties['max_gb']){ $j.recycle.max_gb = 5 }
  if(-not $j.recycle.PSObject.Properties['auto_empty']){ $j.recycle.auto_empty = $false }
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $pol -Encoding UTF8
}catch{}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){
@"
{
  "security": { "defender_sig_max_age_hours": 48 },
  "recycle":  { "max_gb": 5, "auto_empty": false }
}
"@ | Out-File -FilePath $pol -Encoding UTF8
exit 0
}
try{
  $j = Get-Content $pol -Raw | ConvertFrom-Json
  if(-not $j.PSObject.Properties['security']){ $j | Add-Member -NotePropertyName security -NotePropertyValue (@{}) -Force }
  if(-not $j.security.PSObject.Properties['defender_sig_max_age_hours']){ $j.security.defender_sig_max_age_hours = 48 }
  if(-not $j.PSObject.Properties['recycle']){ $j | Add-Member -NotePropertyName recycle -NotePropertyValue (@{}) -Force }
  if(-not $j.recycle.PSObject.Properties['max_gb']){ $j.recycle.max_gb = 5 }
  if(-not $j.recycle.PSObject.Properties['auto_empty']){ $j.recycle.auto_empty = $false }
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $pol -Encoding UTF8
}catch{}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){
@"
{
  "security": { "defender_sig_max_age_hours": 48 },
  "recycle":  { "max_gb": 5, "auto_empty": false }
}
"@ | Out-File -FilePath $pol -Encoding UTF8
exit 0
}
try{
  $j = Get-Content $pol -Raw | ConvertFrom-Json
  if(-not $j.PSObject.Properties['security']){ $j | Add-Member -NotePropertyName security -NotePropertyValue (@{}) -Force }
  if(-not $j.security.PSObject.Properties['defender_sig_max_age_hours']){ $j.security.defender_sig_max_age_hours = 48 }
  if(-not $j.PSObject.Properties['recycle']){ $j | Add-Member -NotePropertyName recycle -NotePropertyValue (@{}) -Force }
  if(-not $j.recycle.PSObject.Properties['max_gb']){ $j.recycle.max_gb = 5 }
  if(-not $j.recycle.PSObject.Properties['auto_empty']){ $j.recycle.auto_empty = $false }
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $pol -Encoding UTF8
}catch{}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){
@"
{
  "security": { "defender_sig_max_age_hours": 48 },
  "recycle":  { "max_gb": 5, "auto_empty": false }
}
"@ | Out-File -FilePath $pol -Encoding UTF8
exit 0
}
try{
  $j = Get-Content $pol -Raw | ConvertFrom-Json
  if(-not $j.PSObject.Properties['security']){ $j | Add-Member -NotePropertyName security -NotePropertyValue (@{}) -Force }
  if(-not $j.security.PSObject.Properties['defender_sig_max_age_hours']){ $j.security.defender_sig_max_age_hours = 48 }
  if(-not $j.PSObject.Properties['recycle']){ $j | Add-Member -NotePropertyName recycle -NotePropertyValue (@{}) -Force }
  if(-not $j.recycle.PSObject.Properties['max_gb']){ $j.recycle.max_gb = 5 }
  if(-not $j.recycle.PSObject.Properties['auto_empty']){ $j.recycle.auto_empty = $false }
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $pol -Encoding UTF8
}catch{}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){
@"
{
  "security": { "defender_sig_max_age_hours": 48 },
  "recycle":  { "max_gb": 5, "auto_empty": false }
}
"@ | Out-File -FilePath $pol -Encoding UTF8
exit 0
}
try{
  $j = Get-Content $pol -Raw | ConvertFrom-Json
  if(-not $j.PSObject.Properties['security']){ $j | Add-Member -NotePropertyName security -NotePropertyValue (@{}) -Force }
  if(-not $j.security.PSObject.Properties['defender_sig_max_age_hours']){ $j.security.defender_sig_max_age_hours = 48 }
  if(-not $j.PSObject.Properties['recycle']){ $j | Add-Member -NotePropertyName recycle -NotePropertyValue (@{}) -Force }
  if(-not $j.recycle.PSObject.Properties['max_gb']){ $j.recycle.max_gb = 5 }
  if(-not $j.recycle.PSObject.Properties['auto_empty']){ $j.recycle.auto_empty = $false }
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $pol -Encoding UTF8
}catch{}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
$pol = Join-Path $Base 'config\policy.json'
if(-not (Test-Path $pol)){
@"
{
  "security": { "defender_sig_max_age_hours": 48 },
  "recycle":  { "max_gb": 5, "auto_empty": false }
}
"@ | Out-File -FilePath $pol -Encoding UTF8
exit 0
}
try{
  $j = Get-Content $pol -Raw | ConvertFrom-Json
  if(-not $j.PSObject.Properties['security']){ $j | Add-Member -NotePropertyName security -NotePropertyValue (@{}) -Force }
  if(-not $j.security.PSObject.Properties['defender_sig_max_age_hours']){ $j.security.defender_sig_max_age_hours = 48 }
  if(-not $j.PSObject.Properties['recycle']){ $j | Add-Member -NotePropertyName recycle -NotePropertyValue (@{}) -Force }
  if(-not $j.recycle.PSObject.Properties['max_gb']){ $j.recycle.max_gb = 5 }
  if(-not $j.recycle.PSObject.Properties['auto_empty']){ $j.recycle.auto_empty = $false }
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $pol -Encoding UTF8
}catch{}
