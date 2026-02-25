# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([ValidateSet("dev","prod")][string]$Mode="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$modeFile = Join-Path $Cfg "mode.txt"
$polFile  = Join-Path $Cfg "policy.json"
$Mode | Set-Content $modeFile -Encoding ASCII
if(Test-Path $polFile){
  $p = Get-Content $polFile -Raw | ConvertFrom-Json
  if($Mode -eq "prod"){
    $p.safe_mode = $true
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "low"; $p.risk_budget.max_size_mb = 10
  } else {
    $p.safe_mode = $false
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "medium"; $p.risk_budget.max_size_mb = 50
  }
  ($p | ConvertTo-Json -Depth 6) | Set-Content $polFile -Encoding UTF8
}
"Mode set to $Mode"

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([ValidateSet("dev","prod")][string]$Mode="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$modeFile = Join-Path $Cfg "mode.txt"
$polFile  = Join-Path $Cfg "policy.json"
$Mode | Set-Content $modeFile -Encoding ASCII
if(Test-Path $polFile){
  $p = Get-Content $polFile -Raw | ConvertFrom-Json
  if($Mode -eq "prod"){
    $p.safe_mode = $true
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "low"; $p.risk_budget.max_size_mb = 10
  } else {
    $p.safe_mode = $false
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "medium"; $p.risk_budget.max_size_mb = 50
  }
  ($p | ConvertTo-Json -Depth 6) | Set-Content $polFile -Encoding UTF8
}
"Mode set to $Mode"

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([ValidateSet("dev","prod")][string]$Mode="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$modeFile = Join-Path $Cfg "mode.txt"
$polFile  = Join-Path $Cfg "policy.json"
$Mode | Set-Content $modeFile -Encoding ASCII
if(Test-Path $polFile){
  $p = Get-Content $polFile -Raw | ConvertFrom-Json
  if($Mode -eq "prod"){
    $p.safe_mode = $true
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "low"; $p.risk_budget.max_size_mb = 10
  } else {
    $p.safe_mode = $false
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "medium"; $p.risk_budget.max_size_mb = 50
  }
  ($p | ConvertTo-Json -Depth 6) | Set-Content $polFile -Encoding UTF8
}
"Mode set to $Mode"

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([ValidateSet("dev","prod")][string]$Mode="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$modeFile = Join-Path $Cfg "mode.txt"
$polFile  = Join-Path $Cfg "policy.json"
$Mode | Set-Content $modeFile -Encoding ASCII
if(Test-Path $polFile){
  $p = Get-Content $polFile -Raw | ConvertFrom-Json
  if($Mode -eq "prod"){
    $p.safe_mode = $true
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "low"; $p.risk_budget.max_size_mb = 10
  } else {
    $p.safe_mode = $false
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "medium"; $p.risk_budget.max_size_mb = 50
  }
  ($p | ConvertTo-Json -Depth 6) | Set-Content $polFile -Encoding UTF8
}
"Mode set to $Mode"

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([ValidateSet("dev","prod")][string]$Mode="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$modeFile = Join-Path $Cfg "mode.txt"
$polFile  = Join-Path $Cfg "policy.json"
$Mode | Set-Content $modeFile -Encoding ASCII
if(Test-Path $polFile){
  $p = Get-Content $polFile -Raw | ConvertFrom-Json
  if($Mode -eq "prod"){
    $p.safe_mode = $true
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "low"; $p.risk_budget.max_size_mb = 10
  } else {
    $p.safe_mode = $false
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "medium"; $p.risk_budget.max_size_mb = 50
  }
  ($p | ConvertTo-Json -Depth 6) | Set-Content $polFile -Encoding UTF8
}
"Mode set to $Mode"

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([ValidateSet("dev","prod")][string]$Mode="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$modeFile = Join-Path $Cfg "mode.txt"
$polFile  = Join-Path $Cfg "policy.json"
$Mode | Set-Content $modeFile -Encoding ASCII
if(Test-Path $polFile){
  $p = Get-Content $polFile -Raw | ConvertFrom-Json
  if($Mode -eq "prod"){
    $p.safe_mode = $true
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "low"; $p.risk_budget.max_size_mb = 10
  } else {
    $p.safe_mode = $false
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "medium"; $p.risk_budget.max_size_mb = 50
  }
  ($p | ConvertTo-Json -Depth 6) | Set-Content $polFile -Encoding UTF8
}
"Mode set to $Mode"

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([ValidateSet("dev","prod")][string]$Mode="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$modeFile = Join-Path $Cfg "mode.txt"
$polFile  = Join-Path $Cfg "policy.json"
$Mode | Set-Content $modeFile -Encoding ASCII
if(Test-Path $polFile){
  $p = Get-Content $polFile -Raw | ConvertFrom-Json
  if($Mode -eq "prod"){
    $p.safe_mode = $true
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "low"; $p.risk_budget.max_size_mb = 10
  } else {
    $p.safe_mode = $false
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "medium"; $p.risk_budget.max_size_mb = 50
  }
  ($p | ConvertTo-Json -Depth 6) | Set-Content $polFile -Encoding UTF8
}
"Mode set to $Mode"

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([ValidateSet("dev","prod")][string]$Mode="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$modeFile = Join-Path $Cfg "mode.txt"
$polFile  = Join-Path $Cfg "policy.json"
$Mode | Set-Content $modeFile -Encoding ASCII
if(Test-Path $polFile){
  $p = Get-Content $polFile -Raw | ConvertFrom-Json
  if($Mode -eq "prod"){
    $p.safe_mode = $true
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "low"; $p.risk_budget.max_size_mb = 10
  } else {
    $p.safe_mode = $false
    if(-not $p.risk_budget){ $p | Add-Member -NotePropertyName risk_budget -NotePropertyValue (@{}) -Force }
    $p.risk_budget.max_blast = "medium"; $p.risk_budget.max_size_mb = 50
  }
  ($p | ConvertTo-Json -Depth 6) | Set-Content $polFile -Encoding UTF8
}
"Mode set to $Mode"

