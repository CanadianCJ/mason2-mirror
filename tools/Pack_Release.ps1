# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([string]$Label = $(Get-Date -Format "yyyyMMdd_HHmmss"))
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
$Rel  = Join-Path $Dist "releases"
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
# Ensure manifest
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null
$stage = Join-Path $Dist ("pack_stage_" + [guid]::NewGuid().ToString("N"))
ni $stage -ItemType Directory -ea SilentlyContinue | Out-Null
# Copy wanted subtrees
$inc = @("config","services","tools","seeds")
foreach($i in $inc){ if(Test-Path (Join-Path $Base $i)){ robocopy (Join-Path $Base $i) (Join-Path $stage $i) /E /NFL /NDL /NJH /NJS | Out-Null } }
Copy-Item (Join-Path $Dist "manifest.json") (Join-Path $stage "manifest.json") -Force -ea SilentlyContinue
# ZIP
$out = Join-Path $Rel ("Mason2_" + $Label + ".zip")
if(Test-Path $out){ Remove-Item $out -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $out
# SHA256
$hash = (& certutil -hashfile $out SHA256) 2>$null
if($LASTEXITCODE -eq 0){ ($hash | Select-Object -Skip 1 | Select-Object -First 1).Trim() | Set-Content ($out + ".sha256") -Encoding ASCII }
Remove-Item $stage -Recurse -Force -ea SilentlyContinue
Write-Host $out

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([string]$Label = $(Get-Date -Format "yyyyMMdd_HHmmss"))
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
$Rel  = Join-Path $Dist "releases"
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
# Ensure manifest
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null
$stage = Join-Path $Dist ("pack_stage_" + [guid]::NewGuid().ToString("N"))
ni $stage -ItemType Directory -ea SilentlyContinue | Out-Null
# Copy wanted subtrees
$inc = @("config","services","tools","seeds")
foreach($i in $inc){ if(Test-Path (Join-Path $Base $i)){ robocopy (Join-Path $Base $i) (Join-Path $stage $i) /E /NFL /NDL /NJH /NJS | Out-Null } }
Copy-Item (Join-Path $Dist "manifest.json") (Join-Path $stage "manifest.json") -Force -ea SilentlyContinue
# ZIP
$out = Join-Path $Rel ("Mason2_" + $Label + ".zip")
if(Test-Path $out){ Remove-Item $out -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $out
# SHA256
$hash = (& certutil -hashfile $out SHA256) 2>$null
if($LASTEXITCODE -eq 0){ ($hash | Select-Object -Skip 1 | Select-Object -First 1).Trim() | Set-Content ($out + ".sha256") -Encoding ASCII }
Remove-Item $stage -Recurse -Force -ea SilentlyContinue
Write-Host $out

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([string]$Label = $(Get-Date -Format "yyyyMMdd_HHmmss"))
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
$Rel  = Join-Path $Dist "releases"
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
# Ensure manifest
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null
$stage = Join-Path $Dist ("pack_stage_" + [guid]::NewGuid().ToString("N"))
ni $stage -ItemType Directory -ea SilentlyContinue | Out-Null
# Copy wanted subtrees
$inc = @("config","services","tools","seeds")
foreach($i in $inc){ if(Test-Path (Join-Path $Base $i)){ robocopy (Join-Path $Base $i) (Join-Path $stage $i) /E /NFL /NDL /NJH /NJS | Out-Null } }
Copy-Item (Join-Path $Dist "manifest.json") (Join-Path $stage "manifest.json") -Force -ea SilentlyContinue
# ZIP
$out = Join-Path $Rel ("Mason2_" + $Label + ".zip")
if(Test-Path $out){ Remove-Item $out -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $out
# SHA256
$hash = (& certutil -hashfile $out SHA256) 2>$null
if($LASTEXITCODE -eq 0){ ($hash | Select-Object -Skip 1 | Select-Object -First 1).Trim() | Set-Content ($out + ".sha256") -Encoding ASCII }
Remove-Item $stage -Recurse -Force -ea SilentlyContinue
Write-Host $out

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([string]$Label = $(Get-Date -Format "yyyyMMdd_HHmmss"))
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
$Rel  = Join-Path $Dist "releases"
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
# Ensure manifest
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null
$stage = Join-Path $Dist ("pack_stage_" + [guid]::NewGuid().ToString("N"))
ni $stage -ItemType Directory -ea SilentlyContinue | Out-Null
# Copy wanted subtrees
$inc = @("config","services","tools","seeds")
foreach($i in $inc){ if(Test-Path (Join-Path $Base $i)){ robocopy (Join-Path $Base $i) (Join-Path $stage $i) /E /NFL /NDL /NJH /NJS | Out-Null } }
Copy-Item (Join-Path $Dist "manifest.json") (Join-Path $stage "manifest.json") -Force -ea SilentlyContinue
# ZIP
$out = Join-Path $Rel ("Mason2_" + $Label + ".zip")
if(Test-Path $out){ Remove-Item $out -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $out
# SHA256
$hash = (& certutil -hashfile $out SHA256) 2>$null
if($LASTEXITCODE -eq 0){ ($hash | Select-Object -Skip 1 | Select-Object -First 1).Trim() | Set-Content ($out + ".sha256") -Encoding ASCII }
Remove-Item $stage -Recurse -Force -ea SilentlyContinue
Write-Host $out

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([string]$Label = $(Get-Date -Format "yyyyMMdd_HHmmss"))
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
$Rel  = Join-Path $Dist "releases"
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
# Ensure manifest
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null
$stage = Join-Path $Dist ("pack_stage_" + [guid]::NewGuid().ToString("N"))
ni $stage -ItemType Directory -ea SilentlyContinue | Out-Null
# Copy wanted subtrees
$inc = @("config","services","tools","seeds")
foreach($i in $inc){ if(Test-Path (Join-Path $Base $i)){ robocopy (Join-Path $Base $i) (Join-Path $stage $i) /E /NFL /NDL /NJH /NJS | Out-Null } }
Copy-Item (Join-Path $Dist "manifest.json") (Join-Path $stage "manifest.json") -Force -ea SilentlyContinue
# ZIP
$out = Join-Path $Rel ("Mason2_" + $Label + ".zip")
if(Test-Path $out){ Remove-Item $out -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $out
# SHA256
$hash = (& certutil -hashfile $out SHA256) 2>$null
if($LASTEXITCODE -eq 0){ ($hash | Select-Object -Skip 1 | Select-Object -First 1).Trim() | Set-Content ($out + ".sha256") -Encoding ASCII }
Remove-Item $stage -Recurse -Force -ea SilentlyContinue
Write-Host $out

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([string]$Label = $(Get-Date -Format "yyyyMMdd_HHmmss"))
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
$Rel  = Join-Path $Dist "releases"
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
# Ensure manifest
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null
$stage = Join-Path $Dist ("pack_stage_" + [guid]::NewGuid().ToString("N"))
ni $stage -ItemType Directory -ea SilentlyContinue | Out-Null
# Copy wanted subtrees
$inc = @("config","services","tools","seeds")
foreach($i in $inc){ if(Test-Path (Join-Path $Base $i)){ robocopy (Join-Path $Base $i) (Join-Path $stage $i) /E /NFL /NDL /NJH /NJS | Out-Null } }
Copy-Item (Join-Path $Dist "manifest.json") (Join-Path $stage "manifest.json") -Force -ea SilentlyContinue
# ZIP
$out = Join-Path $Rel ("Mason2_" + $Label + ".zip")
if(Test-Path $out){ Remove-Item $out -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $out
# SHA256
$hash = (& certutil -hashfile $out SHA256) 2>$null
if($LASTEXITCODE -eq 0){ ($hash | Select-Object -Skip 1 | Select-Object -First 1).Trim() | Set-Content ($out + ".sha256") -Encoding ASCII }
Remove-Item $stage -Recurse -Force -ea SilentlyContinue
Write-Host $out

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([string]$Label = $(Get-Date -Format "yyyyMMdd_HHmmss"))
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
$Rel  = Join-Path $Dist "releases"
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
# Ensure manifest
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null
$stage = Join-Path $Dist ("pack_stage_" + [guid]::NewGuid().ToString("N"))
ni $stage -ItemType Directory -ea SilentlyContinue | Out-Null
# Copy wanted subtrees
$inc = @("config","services","tools","seeds")
foreach($i in $inc){ if(Test-Path (Join-Path $Base $i)){ robocopy (Join-Path $Base $i) (Join-Path $stage $i) /E /NFL /NDL /NJH /NJS | Out-Null } }
Copy-Item (Join-Path $Dist "manifest.json") (Join-Path $stage "manifest.json") -Force -ea SilentlyContinue
# ZIP
$out = Join-Path $Rel ("Mason2_" + $Label + ".zip")
if(Test-Path $out){ Remove-Item $out -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $out
# SHA256
$hash = (& certutil -hashfile $out SHA256) 2>$null
if($LASTEXITCODE -eq 0){ ($hash | Select-Object -Skip 1 | Select-Object -First 1).Trim() | Set-Content ($out + ".sha256") -Encoding ASCII }
Remove-Item $stage -Recurse -Force -ea SilentlyContinue
Write-Host $out

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
param([string]$Label = $(Get-Date -Format "yyyyMMdd_HHmmss"))
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
$Rel  = Join-Path $Dist "releases"
ni $Rel -ItemType Directory -ea SilentlyContinue | Out-Null
# Ensure manifest
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null
$stage = Join-Path $Dist ("pack_stage_" + [guid]::NewGuid().ToString("N"))
ni $stage -ItemType Directory -ea SilentlyContinue | Out-Null
# Copy wanted subtrees
$inc = @("config","services","tools","seeds")
foreach($i in $inc){ if(Test-Path (Join-Path $Base $i)){ robocopy (Join-Path $Base $i) (Join-Path $stage $i) /E /NFL /NDL /NJH /NJS | Out-Null } }
Copy-Item (Join-Path $Dist "manifest.json") (Join-Path $stage "manifest.json") -Force -ea SilentlyContinue
# ZIP
$out = Join-Path $Rel ("Mason2_" + $Label + ".zip")
if(Test-Path $out){ Remove-Item $out -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $out
# SHA256
$hash = (& certutil -hashfile $out SHA256) 2>$null
if($LASTEXITCODE -eq 0){ ($hash | Select-Object -Skip 1 | Select-Object -First 1).Trim() | Set-Content ($out + ".sha256") -Encoding ASCII }
Remove-Item $stage -Recurse -Force -ea SilentlyContinue
Write-Host $out

