# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$Dist = Join-Path $Base "dist"; ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$skip = @("\.git\", "\node_modules\", "\dist\", "\logs\", "\cache\", "\.cache\")
function ShouldSkip([string]$p){ foreach($s in $skip){ if($p -like "*$s*"){ return $true } }; $false }

$files = Get-ChildItem $Base -Recurse -File -ea SilentlyContinue | Where-Object { -not (ShouldSkip $_.FullName) }
$name  = "mason2-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$zip   = Join-Path $Dist ($name + ".zip")
if($files.Count -gt 0){
  if(Test-Path $zip){ Remove-Item $zip -Force -ea SilentlyContinue }
  Compress-Archive -Path ($files | % FullName) -DestinationPath $zip -Force
  $h = (Get-FileHash -Algorithm SHA256 -Path $zip).Hash
  $sha = $zip + ".sha256"
  "{0}  {1}" -f $h, (Split-Path $zip -Leaf) | Set-Content $sha -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-package.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-pack-unpack.ok") -Encoding ASCII
  Write-Host "[ OK ] Packed -> $zip"
}


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$Dist = Join-Path $Base "dist"; ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$skip = @("\.git\", "\node_modules\", "\dist\", "\logs\", "\cache\", "\.cache\")
function ShouldSkip([string]$p){ foreach($s in $skip){ if($p -like "*$s*"){ return $true } }; $false }

$files = Get-ChildItem $Base -Recurse -File -ea SilentlyContinue | Where-Object { -not (ShouldSkip $_.FullName) }
$name  = "mason2-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$zip   = Join-Path $Dist ($name + ".zip")
if($files.Count -gt 0){
  if(Test-Path $zip){ Remove-Item $zip -Force -ea SilentlyContinue }
  Compress-Archive -Path ($files | % FullName) -DestinationPath $zip -Force
  $h = (Get-FileHash -Algorithm SHA256 -Path $zip).Hash
  $sha = $zip + ".sha256"
  "{0}  {1}" -f $h, (Split-Path $zip -Leaf) | Set-Content $sha -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-package.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-pack-unpack.ok") -Encoding ASCII
  Write-Host "[ OK ] Packed -> $zip"
}


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$Dist = Join-Path $Base "dist"; ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$skip = @("\.git\", "\node_modules\", "\dist\", "\logs\", "\cache\", "\.cache\")
function ShouldSkip([string]$p){ foreach($s in $skip){ if($p -like "*$s*"){ return $true } }; $false }

$files = Get-ChildItem $Base -Recurse -File -ea SilentlyContinue | Where-Object { -not (ShouldSkip $_.FullName) }
$name  = "mason2-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$zip   = Join-Path $Dist ($name + ".zip")
if($files.Count -gt 0){
  if(Test-Path $zip){ Remove-Item $zip -Force -ea SilentlyContinue }
  Compress-Archive -Path ($files | % FullName) -DestinationPath $zip -Force
  $h = (Get-FileHash -Algorithm SHA256 -Path $zip).Hash
  $sha = $zip + ".sha256"
  "{0}  {1}" -f $h, (Split-Path $zip -Leaf) | Set-Content $sha -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-package.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-pack-unpack.ok") -Encoding ASCII
  Write-Host "[ OK ] Packed -> $zip"
}


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$Dist = Join-Path $Base "dist"; ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$skip = @("\.git\", "\node_modules\", "\dist\", "\logs\", "\cache\", "\.cache\")
function ShouldSkip([string]$p){ foreach($s in $skip){ if($p -like "*$s*"){ return $true } }; $false }

$files = Get-ChildItem $Base -Recurse -File -ea SilentlyContinue | Where-Object { -not (ShouldSkip $_.FullName) }
$name  = "mason2-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$zip   = Join-Path $Dist ($name + ".zip")
if($files.Count -gt 0){
  if(Test-Path $zip){ Remove-Item $zip -Force -ea SilentlyContinue }
  Compress-Archive -Path ($files | % FullName) -DestinationPath $zip -Force
  $h = (Get-FileHash -Algorithm SHA256 -Path $zip).Hash
  $sha = $zip + ".sha256"
  "{0}  {1}" -f $h, (Split-Path $zip -Leaf) | Set-Content $sha -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-package.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-pack-unpack.ok") -Encoding ASCII
  Write-Host "[ OK ] Packed -> $zip"
}


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$Dist = Join-Path $Base "dist"; ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$skip = @("\.git\", "\node_modules\", "\dist\", "\logs\", "\cache\", "\.cache\")
function ShouldSkip([string]$p){ foreach($s in $skip){ if($p -like "*$s*"){ return $true } }; $false }

$files = Get-ChildItem $Base -Recurse -File -ea SilentlyContinue | Where-Object { -not (ShouldSkip $_.FullName) }
$name  = "mason2-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$zip   = Join-Path $Dist ($name + ".zip")
if($files.Count -gt 0){
  if(Test-Path $zip){ Remove-Item $zip -Force -ea SilentlyContinue }
  Compress-Archive -Path ($files | % FullName) -DestinationPath $zip -Force
  $h = (Get-FileHash -Algorithm SHA256 -Path $zip).Hash
  $sha = $zip + ".sha256"
  "{0}  {1}" -f $h, (Split-Path $zip -Leaf) | Set-Content $sha -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-package.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-pack-unpack.ok") -Encoding ASCII
  Write-Host "[ OK ] Packed -> $zip"
}


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$Dist = Join-Path $Base "dist"; ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$skip = @("\.git\", "\node_modules\", "\dist\", "\logs\", "\cache\", "\.cache\")
function ShouldSkip([string]$p){ foreach($s in $skip){ if($p -like "*$s*"){ return $true } }; $false }

$files = Get-ChildItem $Base -Recurse -File -ea SilentlyContinue | Where-Object { -not (ShouldSkip $_.FullName) }
$name  = "mason2-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$zip   = Join-Path $Dist ($name + ".zip")
if($files.Count -gt 0){
  if(Test-Path $zip){ Remove-Item $zip -Force -ea SilentlyContinue }
  Compress-Archive -Path ($files | % FullName) -DestinationPath $zip -Force
  $h = (Get-FileHash -Algorithm SHA256 -Path $zip).Hash
  $sha = $zip + ".sha256"
  "{0}  {1}" -f $h, (Split-Path $zip -Leaf) | Set-Content $sha -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-package.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-pack-unpack.ok") -Encoding ASCII
  Write-Host "[ OK ] Packed -> $zip"
}


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$Dist = Join-Path $Base "dist"; ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$skip = @("\.git\", "\node_modules\", "\dist\", "\logs\", "\cache\", "\.cache\")
function ShouldSkip([string]$p){ foreach($s in $skip){ if($p -like "*$s*"){ return $true } }; $false }

$files = Get-ChildItem $Base -Recurse -File -ea SilentlyContinue | Where-Object { -not (ShouldSkip $_.FullName) }
$name  = "mason2-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$zip   = Join-Path $Dist ($name + ".zip")
if($files.Count -gt 0){
  if(Test-Path $zip){ Remove-Item $zip -Force -ea SilentlyContinue }
  Compress-Archive -Path ($files | % FullName) -DestinationPath $zip -Force
  $h = (Get-FileHash -Algorithm SHA256 -Path $zip).Hash
  $sha = $zip + ".sha256"
  "{0}  {1}" -f $h, (Split-Path $zip -Leaf) | Set-Content $sha -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-package.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-pack-unpack.ok") -Encoding ASCII
  Write-Host "[ OK ] Packed -> $zip"
}


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$Dist = Join-Path $Base "dist"; ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$skip = @("\.git\", "\node_modules\", "\dist\", "\logs\", "\cache\", "\.cache\")
function ShouldSkip([string]$p){ foreach($s in $skip){ if($p -like "*$s*"){ return $true } }; $false }

$files = Get-ChildItem $Base -Recurse -File -ea SilentlyContinue | Where-Object { -not (ShouldSkip $_.FullName) }
$name  = "mason2-" + (Get-Date -Format "yyyyMMdd-HHmmss")
$zip   = Join-Path $Dist ($name + ".zip")
if($files.Count -gt 0){
  if(Test-Path $zip){ Remove-Item $zip -Force -ea SilentlyContinue }
  Compress-Archive -Path ($files | % FullName) -DestinationPath $zip -Force
  $h = (Get-FileHash -Algorithm SHA256 -Path $zip).Hash
  $sha = $zip + ".sha256"
  "{0}  {1}" -f $h, (Split-Path $zip -Leaf) | Set-Content $sha -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-package.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-pack-unpack.ok") -Encoding ASCII
  Write-Host "[ OK ] Packed -> $zip"
}


