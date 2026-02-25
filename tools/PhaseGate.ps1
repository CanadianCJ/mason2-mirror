# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param([switch]$RequireApplied,[string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$stat = Join-Path $Base "reports\phase_status.json"
if(-not (Test-Path $stat)){ @{phase1="Applied"} | ConvertTo-Json | Set-Content $stat -Encoding UTF8 }
$p = Get-Content (Join-Path $Base "config\policy.json") -Raw | ConvertFrom-Json
if($RequireApplied){
  $s = Get-Content $stat -Raw | ConvertFrom-Json
  if($s.phase1 -ne "Applied"){
    if(-not $Pin){ Write-Host "DENY: Phase 1 not Applied. Provide -Pin to override."; exit 2 }
    $pinHash  = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
    if($pinHash -ne $p.operator_pin_hash){ Write-Host "DENY: PIN invalid."; exit 3 }
  }
}
Write-Host "OK"

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param([switch]$RequireApplied,[string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$stat = Join-Path $Base "reports\phase_status.json"
if(-not (Test-Path $stat)){ @{phase1="Applied"} | ConvertTo-Json | Set-Content $stat -Encoding UTF8 }
$p = Get-Content (Join-Path $Base "config\policy.json") -Raw | ConvertFrom-Json
if($RequireApplied){
  $s = Get-Content $stat -Raw | ConvertFrom-Json
  if($s.phase1 -ne "Applied"){
    if(-not $Pin){ Write-Host "DENY: Phase 1 not Applied. Provide -Pin to override."; exit 2 }
    $pinHash  = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
    if($pinHash -ne $p.operator_pin_hash){ Write-Host "DENY: PIN invalid."; exit 3 }
  }
}
Write-Host "OK"

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param([switch]$RequireApplied,[string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$stat = Join-Path $Base "reports\phase_status.json"
if(-not (Test-Path $stat)){ @{phase1="Applied"} | ConvertTo-Json | Set-Content $stat -Encoding UTF8 }
$p = Get-Content (Join-Path $Base "config\policy.json") -Raw | ConvertFrom-Json
if($RequireApplied){
  $s = Get-Content $stat -Raw | ConvertFrom-Json
  if($s.phase1 -ne "Applied"){
    if(-not $Pin){ Write-Host "DENY: Phase 1 not Applied. Provide -Pin to override."; exit 2 }
    $pinHash  = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
    if($pinHash -ne $p.operator_pin_hash){ Write-Host "DENY: PIN invalid."; exit 3 }
  }
}
Write-Host "OK"

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param([switch]$RequireApplied,[string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$stat = Join-Path $Base "reports\phase_status.json"
if(-not (Test-Path $stat)){ @{phase1="Applied"} | ConvertTo-Json | Set-Content $stat -Encoding UTF8 }
$p = Get-Content (Join-Path $Base "config\policy.json") -Raw | ConvertFrom-Json
if($RequireApplied){
  $s = Get-Content $stat -Raw | ConvertFrom-Json
  if($s.phase1 -ne "Applied"){
    if(-not $Pin){ Write-Host "DENY: Phase 1 not Applied. Provide -Pin to override."; exit 2 }
    $pinHash  = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
    if($pinHash -ne $p.operator_pin_hash){ Write-Host "DENY: PIN invalid."; exit 3 }
  }
}
Write-Host "OK"

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param([switch]$RequireApplied,[string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$stat = Join-Path $Base "reports\phase_status.json"
if(-not (Test-Path $stat)){ @{phase1="Applied"} | ConvertTo-Json | Set-Content $stat -Encoding UTF8 }
$p = Get-Content (Join-Path $Base "config\policy.json") -Raw | ConvertFrom-Json
if($RequireApplied){
  $s = Get-Content $stat -Raw | ConvertFrom-Json
  if($s.phase1 -ne "Applied"){
    if(-not $Pin){ Write-Host "DENY: Phase 1 not Applied. Provide -Pin to override."; exit 2 }
    $pinHash  = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
    if($pinHash -ne $p.operator_pin_hash){ Write-Host "DENY: PIN invalid."; exit 3 }
  }
}
Write-Host "OK"

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param([switch]$RequireApplied,[string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$stat = Join-Path $Base "reports\phase_status.json"
if(-not (Test-Path $stat)){ @{phase1="Applied"} | ConvertTo-Json | Set-Content $stat -Encoding UTF8 }
$p = Get-Content (Join-Path $Base "config\policy.json") -Raw | ConvertFrom-Json
if($RequireApplied){
  $s = Get-Content $stat -Raw | ConvertFrom-Json
  if($s.phase1 -ne "Applied"){
    if(-not $Pin){ Write-Host "DENY: Phase 1 not Applied. Provide -Pin to override."; exit 2 }
    $pinHash  = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
    if($pinHash -ne $p.operator_pin_hash){ Write-Host "DENY: PIN invalid."; exit 3 }
  }
}
Write-Host "OK"

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param([switch]$RequireApplied,[string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$stat = Join-Path $Base "reports\phase_status.json"
if(-not (Test-Path $stat)){ @{phase1="Applied"} | ConvertTo-Json | Set-Content $stat -Encoding UTF8 }
$p = Get-Content (Join-Path $Base "config\policy.json") -Raw | ConvertFrom-Json
if($RequireApplied){
  $s = Get-Content $stat -Raw | ConvertFrom-Json
  if($s.phase1 -ne "Applied"){
    if(-not $Pin){ Write-Host "DENY: Phase 1 not Applied. Provide -Pin to override."; exit 2 }
    $pinHash  = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
    if($pinHash -ne $p.operator_pin_hash){ Write-Host "DENY: PIN invalid."; exit 3 }
  }
}
Write-Host "OK"

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param([switch]$RequireApplied,[string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$stat = Join-Path $Base "reports\phase_status.json"
if(-not (Test-Path $stat)){ @{phase1="Applied"} | ConvertTo-Json | Set-Content $stat -Encoding UTF8 }
$p = Get-Content (Join-Path $Base "config\policy.json") -Raw | ConvertFrom-Json
if($RequireApplied){
  $s = Get-Content $stat -Raw | ConvertFrom-Json
  if($s.phase1 -ne "Applied"){
    if(-not $Pin){ Write-Host "DENY: Phase 1 not Applied. Provide -Pin to override."; exit 2 }
    $pinHash  = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
    if($pinHash -ne $p.operator_pin_hash){ Write-Host "DENY: PIN invalid."; exit 3 }
  }
}
Write-Host "OK"

