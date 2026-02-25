# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param(
  [Parameter(Mandatory=$true)][string]$Zip,
  [Parameter(Mandatory=$true)][string]$OutDir
)
if(-not (Test-Path $Zip)){ throw "Zip not found: $Zip" }
$shaFile = $Zip + ".sha256"
if(-not (Test-Path $shaFile)){ throw "Missing SHA file: $shaFile" }
$expected = (Get-Content $shaFile -Raw).Split() | Select-Object -First 1
$actual   = (Get-FileHash -Algorithm SHA256 -Path $Zip).Hash
if($expected -ne $actual){ throw "SHA256 mismatch: expected $expected, got $actual" }
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
Expand-Archive -Path $Zip -DestinationPath $OutDir -Force
Write-Host "[ OK ] Unpacked (verified) -> $OutDir"


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param(
  [Parameter(Mandatory=$true)][string]$Zip,
  [Parameter(Mandatory=$true)][string]$OutDir
)
if(-not (Test-Path $Zip)){ throw "Zip not found: $Zip" }
$shaFile = $Zip + ".sha256"
if(-not (Test-Path $shaFile)){ throw "Missing SHA file: $shaFile" }
$expected = (Get-Content $shaFile -Raw).Split() | Select-Object -First 1
$actual   = (Get-FileHash -Algorithm SHA256 -Path $Zip).Hash
if($expected -ne $actual){ throw "SHA256 mismatch: expected $expected, got $actual" }
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
Expand-Archive -Path $Zip -DestinationPath $OutDir -Force
Write-Host "[ OK ] Unpacked (verified) -> $OutDir"


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param(
  [Parameter(Mandatory=$true)][string]$Zip,
  [Parameter(Mandatory=$true)][string]$OutDir
)
if(-not (Test-Path $Zip)){ throw "Zip not found: $Zip" }
$shaFile = $Zip + ".sha256"
if(-not (Test-Path $shaFile)){ throw "Missing SHA file: $shaFile" }
$expected = (Get-Content $shaFile -Raw).Split() | Select-Object -First 1
$actual   = (Get-FileHash -Algorithm SHA256 -Path $Zip).Hash
if($expected -ne $actual){ throw "SHA256 mismatch: expected $expected, got $actual" }
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
Expand-Archive -Path $Zip -DestinationPath $OutDir -Force
Write-Host "[ OK ] Unpacked (verified) -> $OutDir"


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param(
  [Parameter(Mandatory=$true)][string]$Zip,
  [Parameter(Mandatory=$true)][string]$OutDir
)
if(-not (Test-Path $Zip)){ throw "Zip not found: $Zip" }
$shaFile = $Zip + ".sha256"
if(-not (Test-Path $shaFile)){ throw "Missing SHA file: $shaFile" }
$expected = (Get-Content $shaFile -Raw).Split() | Select-Object -First 1
$actual   = (Get-FileHash -Algorithm SHA256 -Path $Zip).Hash
if($expected -ne $actual){ throw "SHA256 mismatch: expected $expected, got $actual" }
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
Expand-Archive -Path $Zip -DestinationPath $OutDir -Force
Write-Host "[ OK ] Unpacked (verified) -> $OutDir"


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param(
  [Parameter(Mandatory=$true)][string]$Zip,
  [Parameter(Mandatory=$true)][string]$OutDir
)
if(-not (Test-Path $Zip)){ throw "Zip not found: $Zip" }
$shaFile = $Zip + ".sha256"
if(-not (Test-Path $shaFile)){ throw "Missing SHA file: $shaFile" }
$expected = (Get-Content $shaFile -Raw).Split() | Select-Object -First 1
$actual   = (Get-FileHash -Algorithm SHA256 -Path $Zip).Hash
if($expected -ne $actual){ throw "SHA256 mismatch: expected $expected, got $actual" }
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
Expand-Archive -Path $Zip -DestinationPath $OutDir -Force
Write-Host "[ OK ] Unpacked (verified) -> $OutDir"


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param(
  [Parameter(Mandatory=$true)][string]$Zip,
  [Parameter(Mandatory=$true)][string]$OutDir
)
if(-not (Test-Path $Zip)){ throw "Zip not found: $Zip" }
$shaFile = $Zip + ".sha256"
if(-not (Test-Path $shaFile)){ throw "Missing SHA file: $shaFile" }
$expected = (Get-Content $shaFile -Raw).Split() | Select-Object -First 1
$actual   = (Get-FileHash -Algorithm SHA256 -Path $Zip).Hash
if($expected -ne $actual){ throw "SHA256 mismatch: expected $expected, got $actual" }
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
Expand-Archive -Path $Zip -DestinationPath $OutDir -Force
Write-Host "[ OK ] Unpacked (verified) -> $OutDir"


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param(
  [Parameter(Mandatory=$true)][string]$Zip,
  [Parameter(Mandatory=$true)][string]$OutDir
)
if(-not (Test-Path $Zip)){ throw "Zip not found: $Zip" }
$shaFile = $Zip + ".sha256"
if(-not (Test-Path $shaFile)){ throw "Missing SHA file: $shaFile" }
$expected = (Get-Content $shaFile -Raw).Split() | Select-Object -First 1
$actual   = (Get-FileHash -Algorithm SHA256 -Path $Zip).Hash
if($expected -ne $actual){ throw "SHA256 mismatch: expected $expected, got $actual" }
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
Expand-Archive -Path $Zip -DestinationPath $OutDir -Force
Write-Host "[ OK ] Unpacked (verified) -> $OutDir"


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
param(
  [Parameter(Mandatory=$true)][string]$Zip,
  [Parameter(Mandatory=$true)][string]$OutDir
)
if(-not (Test-Path $Zip)){ throw "Zip not found: $Zip" }
$shaFile = $Zip + ".sha256"
if(-not (Test-Path $shaFile)){ throw "Missing SHA file: $shaFile" }
$expected = (Get-Content $shaFile -Raw).Split() | Select-Object -First 1
$actual   = (Get-FileHash -Algorithm SHA256 -Path $Zip).Hash
if($expected -ne $actual){ throw "SHA256 mismatch: expected $expected, got $actual" }
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
Expand-Archive -Path $Zip -DestinationPath $OutDir -Force
Write-Host "[ OK ] Unpacked (verified) -> $OutDir"


