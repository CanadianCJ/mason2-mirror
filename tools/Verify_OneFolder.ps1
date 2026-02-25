# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Verify_OneFolder.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$mf = Join-Path $Base "reports\portable_manifest.json"
if(-not (Test-Path $mf)){ throw "Missing manifest: $mf" }
$manifest = Get-Content $mf -Raw | ConvertFrom-Json
$bad = @()
foreach($f in $manifest.files){
  $rel = [string]$f.rel
  if($rel -match '^[A-Za-z]:\\'){ $bad += $rel }
}
$SigDir = Join-Path $Base 'reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($bad.Count -eq 0){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-onefolder.ok') -Encoding ASCII
  Write-Host "[ OK ] One-folder check passed"
}else{
  Write-Host "[WARN] Absolute paths found:" -ForegroundColor Yellow
  $bad | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
}


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Verify_OneFolder.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$mf = Join-Path $Base "reports\portable_manifest.json"
if(-not (Test-Path $mf)){ throw "Missing manifest: $mf" }
$manifest = Get-Content $mf -Raw | ConvertFrom-Json
$bad = @()
foreach($f in $manifest.files){
  $rel = [string]$f.rel
  if($rel -match '^[A-Za-z]:\\'){ $bad += $rel }
}
$SigDir = Join-Path $Base 'reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($bad.Count -eq 0){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-onefolder.ok') -Encoding ASCII
  Write-Host "[ OK ] One-folder check passed"
}else{
  Write-Host "[WARN] Absolute paths found:" -ForegroundColor Yellow
  $bad | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
}


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Verify_OneFolder.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$mf = Join-Path $Base "reports\portable_manifest.json"
if(-not (Test-Path $mf)){ throw "Missing manifest: $mf" }
$manifest = Get-Content $mf -Raw | ConvertFrom-Json
$bad = @()
foreach($f in $manifest.files){
  $rel = [string]$f.rel
  if($rel -match '^[A-Za-z]:\\'){ $bad += $rel }
}
$SigDir = Join-Path $Base 'reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($bad.Count -eq 0){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-onefolder.ok') -Encoding ASCII
  Write-Host "[ OK ] One-folder check passed"
}else{
  Write-Host "[WARN] Absolute paths found:" -ForegroundColor Yellow
  $bad | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
}


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Verify_OneFolder.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$mf = Join-Path $Base "reports\portable_manifest.json"
if(-not (Test-Path $mf)){ throw "Missing manifest: $mf" }
$manifest = Get-Content $mf -Raw | ConvertFrom-Json
$bad = @()
foreach($f in $manifest.files){
  $rel = [string]$f.rel
  if($rel -match '^[A-Za-z]:\\'){ $bad += $rel }
}
$SigDir = Join-Path $Base 'reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($bad.Count -eq 0){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-onefolder.ok') -Encoding ASCII
  Write-Host "[ OK ] One-folder check passed"
}else{
  Write-Host "[WARN] Absolute paths found:" -ForegroundColor Yellow
  $bad | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
}


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Verify_OneFolder.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$mf = Join-Path $Base "reports\portable_manifest.json"
if(-not (Test-Path $mf)){ throw "Missing manifest: $mf" }
$manifest = Get-Content $mf -Raw | ConvertFrom-Json
$bad = @()
foreach($f in $manifest.files){
  $rel = [string]$f.rel
  if($rel -match '^[A-Za-z]:\\'){ $bad += $rel }
}
$SigDir = Join-Path $Base 'reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($bad.Count -eq 0){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-onefolder.ok') -Encoding ASCII
  Write-Host "[ OK ] One-folder check passed"
}else{
  Write-Host "[WARN] Absolute paths found:" -ForegroundColor Yellow
  $bad | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
}


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Verify_OneFolder.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$mf = Join-Path $Base "reports\portable_manifest.json"
if(-not (Test-Path $mf)){ throw "Missing manifest: $mf" }
$manifest = Get-Content $mf -Raw | ConvertFrom-Json
$bad = @()
foreach($f in $manifest.files){
  $rel = [string]$f.rel
  if($rel -match '^[A-Za-z]:\\'){ $bad += $rel }
}
$SigDir = Join-Path $Base 'reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($bad.Count -eq 0){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-onefolder.ok') -Encoding ASCII
  Write-Host "[ OK ] One-folder check passed"
}else{
  Write-Host "[WARN] Absolute paths found:" -ForegroundColor Yellow
  $bad | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
}


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Verify_OneFolder.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$mf = Join-Path $Base "reports\portable_manifest.json"
if(-not (Test-Path $mf)){ throw "Missing manifest: $mf" }
$manifest = Get-Content $mf -Raw | ConvertFrom-Json
$bad = @()
foreach($f in $manifest.files){
  $rel = [string]$f.rel
  if($rel -match '^[A-Za-z]:\\'){ $bad += $rel }
}
$SigDir = Join-Path $Base 'reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($bad.Count -eq 0){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-onefolder.ok') -Encoding ASCII
  Write-Host "[ OK ] One-folder check passed"
}else{
  Write-Host "[WARN] Absolute paths found:" -ForegroundColor Yellow
  $bad | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
}


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Verify_OneFolder.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$mf = Join-Path $Base "reports\portable_manifest.json"
if(-not (Test-Path $mf)){ throw "Missing manifest: $mf" }
$manifest = Get-Content $mf -Raw | ConvertFrom-Json
$bad = @()
foreach($f in $manifest.files){
  $rel = [string]$f.rel
  if($rel -match '^[A-Za-z]:\\'){ $bad += $rel }
}
$SigDir = Join-Path $Base 'reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($bad.Count -eq 0){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-onefolder.ok') -Encoding ASCII
  Write-Host "[ OK ] One-folder check passed"
}else{
  Write-Host "[WARN] Absolute paths found:" -ForegroundColor Yellow
  $bad | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
}


