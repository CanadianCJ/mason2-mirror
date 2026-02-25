# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Paths = [ordered]@{
  Base     = (Resolve-Path -LiteralPath $Base).Path
}
$script:Paths.Tools    = Join-Path $script:Paths.Base 'tools'
$script:Paths.Dist     = Join-Path $script:Paths.Base 'dist'
$script:Paths.Releases = Join-Path $script:Paths.Dist 'releases'
$script:Paths.Reports  = Join-Path $script:Paths.Base 'reports'
$script:Paths.Deploys  = Join-Path $script:Paths.Dist 'deploys'
$script:Paths.Current  = Join-Path $script:Paths.Dist 'current'

New-Item -ItemType Directory -Force -Path $script:Paths.Tools,$script:Paths.Dist,$script:Paths.Releases,$script:Paths.Reports,$script:Paths.Deploys | Out-Null

function Read-Config {
  $cfg = Join-Path $script:Paths.Base 'config\mason2.config.json'
  if(Test-Path $cfg){ Get-Content $cfg -Raw | ConvertFrom-Json } else {
    [pscustomobject]@{
      Env = 'dev'; CleanupDays = 2; UseFolderTime = $true; KeepTopN = 10; VerifyMode='strict'
      Auto = [pscustomobject]@{ VerifyEveryHours=4; CleanupEveryHours=1; NightlyTrimAt='03:30'; NightlyApplyAt='03:45' }
    }
  }
}

function Write-JsonLine([string]$file,[object]$obj){
  New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($file)) | Out-Null
  $line = ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine
  [IO.File]::AppendAllText($file,$line,[Text.Encoding]::UTF8)
}

function Get-LatestBundle {
  if(!(Test-Path $script:Paths.Releases)){ return $null }
  $latest = Get-ChildItem $script:Paths.Releases -File -Filter 'Mason2_*.zip' |
            Sort-Object LastWriteTime -Desc | Select-Object -First 1
  $latest?.FullName
}

function Atomic-Swap([string]$newDir,[string]$currentDir){
  # newDir must exist and not be currentDir
  if(!(Test-Path $newDir -PathType Container)){ throw "Atomic-Swap: newDir not found: $newDir" }
  if($newDir -eq $currentDir){ throw "Atomic-Swap: newDir equals currentDir" }

  $ts   = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak  = "$currentDir.bak-$ts"
  $temp = "$currentDir.new-$ts"

  # We rename new -> temp (so its final parent is same as current)
  Rename-Item -LiteralPath $newDir -NewName ([IO.Path]::GetFileName($temp))

  if(Test-Path $currentDir){ Rename-Item -LiteralPath $currentDir -NewName ([IO.Path]::GetFileName($bak)) }
  Rename-Item -LiteralPath $temp -NewName ([IO.Path]::GetFileName($currentDir))

  # keep only 3 most recent backups
  Get-ChildItem -LiteralPath ([IO.Path]::GetDirectoryName($currentDir)) -Directory -Filter (([IO.Path]::GetFileName($currentDir))+'.bak-*') |
    Sort-Object LastWriteTime -Desc | Select-Object -Skip 3 | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

function Open-Zip([string]$zipPath){
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::OpenRead($zipPath)
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Paths = [ordered]@{
  Base     = (Resolve-Path -LiteralPath $Base).Path
}
$script:Paths.Tools    = Join-Path $script:Paths.Base 'tools'
$script:Paths.Dist     = Join-Path $script:Paths.Base 'dist'
$script:Paths.Releases = Join-Path $script:Paths.Dist 'releases'
$script:Paths.Reports  = Join-Path $script:Paths.Base 'reports'
$script:Paths.Deploys  = Join-Path $script:Paths.Dist 'deploys'
$script:Paths.Current  = Join-Path $script:Paths.Dist 'current'

New-Item -ItemType Directory -Force -Path $script:Paths.Tools,$script:Paths.Dist,$script:Paths.Releases,$script:Paths.Reports,$script:Paths.Deploys | Out-Null

function Read-Config {
  $cfg = Join-Path $script:Paths.Base 'config\mason2.config.json'
  if(Test-Path $cfg){ Get-Content $cfg -Raw | ConvertFrom-Json } else {
    [pscustomobject]@{
      Env = 'dev'; CleanupDays = 2; UseFolderTime = $true; KeepTopN = 10; VerifyMode='strict'
      Auto = [pscustomobject]@{ VerifyEveryHours=4; CleanupEveryHours=1; NightlyTrimAt='03:30'; NightlyApplyAt='03:45' }
    }
  }
}

function Write-JsonLine([string]$file,[object]$obj){
  New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($file)) | Out-Null
  $line = ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine
  [IO.File]::AppendAllText($file,$line,[Text.Encoding]::UTF8)
}

function Get-LatestBundle {
  if(!(Test-Path $script:Paths.Releases)){ return $null }
  $latest = Get-ChildItem $script:Paths.Releases -File -Filter 'Mason2_*.zip' |
            Sort-Object LastWriteTime -Desc | Select-Object -First 1
  $latest?.FullName
}

function Atomic-Swap([string]$newDir,[string]$currentDir){
  # newDir must exist and not be currentDir
  if(!(Test-Path $newDir -PathType Container)){ throw "Atomic-Swap: newDir not found: $newDir" }
  if($newDir -eq $currentDir){ throw "Atomic-Swap: newDir equals currentDir" }

  $ts   = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak  = "$currentDir.bak-$ts"
  $temp = "$currentDir.new-$ts"

  # We rename new -> temp (so its final parent is same as current)
  Rename-Item -LiteralPath $newDir -NewName ([IO.Path]::GetFileName($temp))

  if(Test-Path $currentDir){ Rename-Item -LiteralPath $currentDir -NewName ([IO.Path]::GetFileName($bak)) }
  Rename-Item -LiteralPath $temp -NewName ([IO.Path]::GetFileName($currentDir))

  # keep only 3 most recent backups
  Get-ChildItem -LiteralPath ([IO.Path]::GetDirectoryName($currentDir)) -Directory -Filter (([IO.Path]::GetFileName($currentDir))+'.bak-*') |
    Sort-Object LastWriteTime -Desc | Select-Object -Skip 3 | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

function Open-Zip([string]$zipPath){
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::OpenRead($zipPath)
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Paths = [ordered]@{
  Base     = (Resolve-Path -LiteralPath $Base).Path
}
$script:Paths.Tools    = Join-Path $script:Paths.Base 'tools'
$script:Paths.Dist     = Join-Path $script:Paths.Base 'dist'
$script:Paths.Releases = Join-Path $script:Paths.Dist 'releases'
$script:Paths.Reports  = Join-Path $script:Paths.Base 'reports'
$script:Paths.Deploys  = Join-Path $script:Paths.Dist 'deploys'
$script:Paths.Current  = Join-Path $script:Paths.Dist 'current'

New-Item -ItemType Directory -Force -Path $script:Paths.Tools,$script:Paths.Dist,$script:Paths.Releases,$script:Paths.Reports,$script:Paths.Deploys | Out-Null

function Read-Config {
  $cfg = Join-Path $script:Paths.Base 'config\mason2.config.json'
  if(Test-Path $cfg){ Get-Content $cfg -Raw | ConvertFrom-Json } else {
    [pscustomobject]@{
      Env = 'dev'; CleanupDays = 2; UseFolderTime = $true; KeepTopN = 10; VerifyMode='strict'
      Auto = [pscustomobject]@{ VerifyEveryHours=4; CleanupEveryHours=1; NightlyTrimAt='03:30'; NightlyApplyAt='03:45' }
    }
  }
}

function Write-JsonLine([string]$file,[object]$obj){
  New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($file)) | Out-Null
  $line = ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine
  [IO.File]::AppendAllText($file,$line,[Text.Encoding]::UTF8)
}

function Get-LatestBundle {
  if(!(Test-Path $script:Paths.Releases)){ return $null }
  $latest = Get-ChildItem $script:Paths.Releases -File -Filter 'Mason2_*.zip' |
            Sort-Object LastWriteTime -Desc | Select-Object -First 1
  $latest?.FullName
}

function Atomic-Swap([string]$newDir,[string]$currentDir){
  # newDir must exist and not be currentDir
  if(!(Test-Path $newDir -PathType Container)){ throw "Atomic-Swap: newDir not found: $newDir" }
  if($newDir -eq $currentDir){ throw "Atomic-Swap: newDir equals currentDir" }

  $ts   = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak  = "$currentDir.bak-$ts"
  $temp = "$currentDir.new-$ts"

  # We rename new -> temp (so its final parent is same as current)
  Rename-Item -LiteralPath $newDir -NewName ([IO.Path]::GetFileName($temp))

  if(Test-Path $currentDir){ Rename-Item -LiteralPath $currentDir -NewName ([IO.Path]::GetFileName($bak)) }
  Rename-Item -LiteralPath $temp -NewName ([IO.Path]::GetFileName($currentDir))

  # keep only 3 most recent backups
  Get-ChildItem -LiteralPath ([IO.Path]::GetDirectoryName($currentDir)) -Directory -Filter (([IO.Path]::GetFileName($currentDir))+'.bak-*') |
    Sort-Object LastWriteTime -Desc | Select-Object -Skip 3 | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

function Open-Zip([string]$zipPath){
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::OpenRead($zipPath)
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Paths = [ordered]@{
  Base     = (Resolve-Path -LiteralPath $Base).Path
}
$script:Paths.Tools    = Join-Path $script:Paths.Base 'tools'
$script:Paths.Dist     = Join-Path $script:Paths.Base 'dist'
$script:Paths.Releases = Join-Path $script:Paths.Dist 'releases'
$script:Paths.Reports  = Join-Path $script:Paths.Base 'reports'
$script:Paths.Deploys  = Join-Path $script:Paths.Dist 'deploys'
$script:Paths.Current  = Join-Path $script:Paths.Dist 'current'

New-Item -ItemType Directory -Force -Path $script:Paths.Tools,$script:Paths.Dist,$script:Paths.Releases,$script:Paths.Reports,$script:Paths.Deploys | Out-Null

function Read-Config {
  $cfg = Join-Path $script:Paths.Base 'config\mason2.config.json'
  if(Test-Path $cfg){ Get-Content $cfg -Raw | ConvertFrom-Json } else {
    [pscustomobject]@{
      Env = 'dev'; CleanupDays = 2; UseFolderTime = $true; KeepTopN = 10; VerifyMode='strict'
      Auto = [pscustomobject]@{ VerifyEveryHours=4; CleanupEveryHours=1; NightlyTrimAt='03:30'; NightlyApplyAt='03:45' }
    }
  }
}

function Write-JsonLine([string]$file,[object]$obj){
  New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($file)) | Out-Null
  $line = ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine
  [IO.File]::AppendAllText($file,$line,[Text.Encoding]::UTF8)
}

function Get-LatestBundle {
  if(!(Test-Path $script:Paths.Releases)){ return $null }
  $latest = Get-ChildItem $script:Paths.Releases -File -Filter 'Mason2_*.zip' |
            Sort-Object LastWriteTime -Desc | Select-Object -First 1
  $latest?.FullName
}

function Atomic-Swap([string]$newDir,[string]$currentDir){
  # newDir must exist and not be currentDir
  if(!(Test-Path $newDir -PathType Container)){ throw "Atomic-Swap: newDir not found: $newDir" }
  if($newDir -eq $currentDir){ throw "Atomic-Swap: newDir equals currentDir" }

  $ts   = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak  = "$currentDir.bak-$ts"
  $temp = "$currentDir.new-$ts"

  # We rename new -> temp (so its final parent is same as current)
  Rename-Item -LiteralPath $newDir -NewName ([IO.Path]::GetFileName($temp))

  if(Test-Path $currentDir){ Rename-Item -LiteralPath $currentDir -NewName ([IO.Path]::GetFileName($bak)) }
  Rename-Item -LiteralPath $temp -NewName ([IO.Path]::GetFileName($currentDir))

  # keep only 3 most recent backups
  Get-ChildItem -LiteralPath ([IO.Path]::GetDirectoryName($currentDir)) -Directory -Filter (([IO.Path]::GetFileName($currentDir))+'.bak-*') |
    Sort-Object LastWriteTime -Desc | Select-Object -Skip 3 | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

function Open-Zip([string]$zipPath){
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::OpenRead($zipPath)
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Paths = [ordered]@{
  Base     = (Resolve-Path -LiteralPath $Base).Path
}
$script:Paths.Tools    = Join-Path $script:Paths.Base 'tools'
$script:Paths.Dist     = Join-Path $script:Paths.Base 'dist'
$script:Paths.Releases = Join-Path $script:Paths.Dist 'releases'
$script:Paths.Reports  = Join-Path $script:Paths.Base 'reports'
$script:Paths.Deploys  = Join-Path $script:Paths.Dist 'deploys'
$script:Paths.Current  = Join-Path $script:Paths.Dist 'current'

New-Item -ItemType Directory -Force -Path $script:Paths.Tools,$script:Paths.Dist,$script:Paths.Releases,$script:Paths.Reports,$script:Paths.Deploys | Out-Null

function Read-Config {
  $cfg = Join-Path $script:Paths.Base 'config\mason2.config.json'
  if(Test-Path $cfg){ Get-Content $cfg -Raw | ConvertFrom-Json } else {
    [pscustomobject]@{
      Env = 'dev'; CleanupDays = 2; UseFolderTime = $true; KeepTopN = 10; VerifyMode='strict'
      Auto = [pscustomobject]@{ VerifyEveryHours=4; CleanupEveryHours=1; NightlyTrimAt='03:30'; NightlyApplyAt='03:45' }
    }
  }
}

function Write-JsonLine([string]$file,[object]$obj){
  New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($file)) | Out-Null
  $line = ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine
  [IO.File]::AppendAllText($file,$line,[Text.Encoding]::UTF8)
}

function Get-LatestBundle {
  if(!(Test-Path $script:Paths.Releases)){ return $null }
  $latest = Get-ChildItem $script:Paths.Releases -File -Filter 'Mason2_*.zip' |
            Sort-Object LastWriteTime -Desc | Select-Object -First 1
  $latest?.FullName
}

function Atomic-Swap([string]$newDir,[string]$currentDir){
  # newDir must exist and not be currentDir
  if(!(Test-Path $newDir -PathType Container)){ throw "Atomic-Swap: newDir not found: $newDir" }
  if($newDir -eq $currentDir){ throw "Atomic-Swap: newDir equals currentDir" }

  $ts   = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak  = "$currentDir.bak-$ts"
  $temp = "$currentDir.new-$ts"

  # We rename new -> temp (so its final parent is same as current)
  Rename-Item -LiteralPath $newDir -NewName ([IO.Path]::GetFileName($temp))

  if(Test-Path $currentDir){ Rename-Item -LiteralPath $currentDir -NewName ([IO.Path]::GetFileName($bak)) }
  Rename-Item -LiteralPath $temp -NewName ([IO.Path]::GetFileName($currentDir))

  # keep only 3 most recent backups
  Get-ChildItem -LiteralPath ([IO.Path]::GetDirectoryName($currentDir)) -Directory -Filter (([IO.Path]::GetFileName($currentDir))+'.bak-*') |
    Sort-Object LastWriteTime -Desc | Select-Object -Skip 3 | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

function Open-Zip([string]$zipPath){
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::OpenRead($zipPath)
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Paths = [ordered]@{
  Base     = (Resolve-Path -LiteralPath $Base).Path
}
$script:Paths.Tools    = Join-Path $script:Paths.Base 'tools'
$script:Paths.Dist     = Join-Path $script:Paths.Base 'dist'
$script:Paths.Releases = Join-Path $script:Paths.Dist 'releases'
$script:Paths.Reports  = Join-Path $script:Paths.Base 'reports'
$script:Paths.Deploys  = Join-Path $script:Paths.Dist 'deploys'
$script:Paths.Current  = Join-Path $script:Paths.Dist 'current'

New-Item -ItemType Directory -Force -Path $script:Paths.Tools,$script:Paths.Dist,$script:Paths.Releases,$script:Paths.Reports,$script:Paths.Deploys | Out-Null

function Read-Config {
  $cfg = Join-Path $script:Paths.Base 'config\mason2.config.json'
  if(Test-Path $cfg){ Get-Content $cfg -Raw | ConvertFrom-Json } else {
    [pscustomobject]@{
      Env = 'dev'; CleanupDays = 2; UseFolderTime = $true; KeepTopN = 10; VerifyMode='strict'
      Auto = [pscustomobject]@{ VerifyEveryHours=4; CleanupEveryHours=1; NightlyTrimAt='03:30'; NightlyApplyAt='03:45' }
    }
  }
}

function Write-JsonLine([string]$file,[object]$obj){
  New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($file)) | Out-Null
  $line = ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine
  [IO.File]::AppendAllText($file,$line,[Text.Encoding]::UTF8)
}

function Get-LatestBundle {
  if(!(Test-Path $script:Paths.Releases)){ return $null }
  $latest = Get-ChildItem $script:Paths.Releases -File -Filter 'Mason2_*.zip' |
            Sort-Object LastWriteTime -Desc | Select-Object -First 1
  $latest?.FullName
}

function Atomic-Swap([string]$newDir,[string]$currentDir){
  # newDir must exist and not be currentDir
  if(!(Test-Path $newDir -PathType Container)){ throw "Atomic-Swap: newDir not found: $newDir" }
  if($newDir -eq $currentDir){ throw "Atomic-Swap: newDir equals currentDir" }

  $ts   = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak  = "$currentDir.bak-$ts"
  $temp = "$currentDir.new-$ts"

  # We rename new -> temp (so its final parent is same as current)
  Rename-Item -LiteralPath $newDir -NewName ([IO.Path]::GetFileName($temp))

  if(Test-Path $currentDir){ Rename-Item -LiteralPath $currentDir -NewName ([IO.Path]::GetFileName($bak)) }
  Rename-Item -LiteralPath $temp -NewName ([IO.Path]::GetFileName($currentDir))

  # keep only 3 most recent backups
  Get-ChildItem -LiteralPath ([IO.Path]::GetDirectoryName($currentDir)) -Directory -Filter (([IO.Path]::GetFileName($currentDir))+'.bak-*') |
    Sort-Object LastWriteTime -Desc | Select-Object -Skip 3 | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

function Open-Zip([string]$zipPath){
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::OpenRead($zipPath)
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Paths = [ordered]@{
  Base     = (Resolve-Path -LiteralPath $Base).Path
}
$script:Paths.Tools    = Join-Path $script:Paths.Base 'tools'
$script:Paths.Dist     = Join-Path $script:Paths.Base 'dist'
$script:Paths.Releases = Join-Path $script:Paths.Dist 'releases'
$script:Paths.Reports  = Join-Path $script:Paths.Base 'reports'
$script:Paths.Deploys  = Join-Path $script:Paths.Dist 'deploys'
$script:Paths.Current  = Join-Path $script:Paths.Dist 'current'

New-Item -ItemType Directory -Force -Path $script:Paths.Tools,$script:Paths.Dist,$script:Paths.Releases,$script:Paths.Reports,$script:Paths.Deploys | Out-Null

function Read-Config {
  $cfg = Join-Path $script:Paths.Base 'config\mason2.config.json'
  if(Test-Path $cfg){ Get-Content $cfg -Raw | ConvertFrom-Json } else {
    [pscustomobject]@{
      Env = 'dev'; CleanupDays = 2; UseFolderTime = $true; KeepTopN = 10; VerifyMode='strict'
      Auto = [pscustomobject]@{ VerifyEveryHours=4; CleanupEveryHours=1; NightlyTrimAt='03:30'; NightlyApplyAt='03:45' }
    }
  }
}

function Write-JsonLine([string]$file,[object]$obj){
  New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($file)) | Out-Null
  $line = ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine
  [IO.File]::AppendAllText($file,$line,[Text.Encoding]::UTF8)
}

function Get-LatestBundle {
  if(!(Test-Path $script:Paths.Releases)){ return $null }
  $latest = Get-ChildItem $script:Paths.Releases -File -Filter 'Mason2_*.zip' |
            Sort-Object LastWriteTime -Desc | Select-Object -First 1
  $latest?.FullName
}

function Atomic-Swap([string]$newDir,[string]$currentDir){
  # newDir must exist and not be currentDir
  if(!(Test-Path $newDir -PathType Container)){ throw "Atomic-Swap: newDir not found: $newDir" }
  if($newDir -eq $currentDir){ throw "Atomic-Swap: newDir equals currentDir" }

  $ts   = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak  = "$currentDir.bak-$ts"
  $temp = "$currentDir.new-$ts"

  # We rename new -> temp (so its final parent is same as current)
  Rename-Item -LiteralPath $newDir -NewName ([IO.Path]::GetFileName($temp))

  if(Test-Path $currentDir){ Rename-Item -LiteralPath $currentDir -NewName ([IO.Path]::GetFileName($bak)) }
  Rename-Item -LiteralPath $temp -NewName ([IO.Path]::GetFileName($currentDir))

  # keep only 3 most recent backups
  Get-ChildItem -LiteralPath ([IO.Path]::GetDirectoryName($currentDir)) -Directory -Filter (([IO.Path]::GetFileName($currentDir))+'.bak-*') |
    Sort-Object LastWriteTime -Desc | Select-Object -Skip 3 | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

function Open-Zip([string]$zipPath){
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::OpenRead($zipPath)
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Paths = [ordered]@{
  Base     = (Resolve-Path -LiteralPath $Base).Path
}
$script:Paths.Tools    = Join-Path $script:Paths.Base 'tools'
$script:Paths.Dist     = Join-Path $script:Paths.Base 'dist'
$script:Paths.Releases = Join-Path $script:Paths.Dist 'releases'
$script:Paths.Reports  = Join-Path $script:Paths.Base 'reports'
$script:Paths.Deploys  = Join-Path $script:Paths.Dist 'deploys'
$script:Paths.Current  = Join-Path $script:Paths.Dist 'current'

New-Item -ItemType Directory -Force -Path $script:Paths.Tools,$script:Paths.Dist,$script:Paths.Releases,$script:Paths.Reports,$script:Paths.Deploys | Out-Null

function Read-Config {
  $cfg = Join-Path $script:Paths.Base 'config\mason2.config.json'
  if(Test-Path $cfg){ Get-Content $cfg -Raw | ConvertFrom-Json } else {
    [pscustomobject]@{
      Env = 'dev'; CleanupDays = 2; UseFolderTime = $true; KeepTopN = 10; VerifyMode='strict'
      Auto = [pscustomobject]@{ VerifyEveryHours=4; CleanupEveryHours=1; NightlyTrimAt='03:30'; NightlyApplyAt='03:45' }
    }
  }
}

function Write-JsonLine([string]$file,[object]$obj){
  New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($file)) | Out-Null
  $line = ($obj | ConvertTo-Json -Depth 8 -Compress) + [Environment]::NewLine
  [IO.File]::AppendAllText($file,$line,[Text.Encoding]::UTF8)
}

function Get-LatestBundle {
  if(!(Test-Path $script:Paths.Releases)){ return $null }
  $latest = Get-ChildItem $script:Paths.Releases -File -Filter 'Mason2_*.zip' |
            Sort-Object LastWriteTime -Desc | Select-Object -First 1
  $latest?.FullName
}

function Atomic-Swap([string]$newDir,[string]$currentDir){
  # newDir must exist and not be currentDir
  if(!(Test-Path $newDir -PathType Container)){ throw "Atomic-Swap: newDir not found: $newDir" }
  if($newDir -eq $currentDir){ throw "Atomic-Swap: newDir equals currentDir" }

  $ts   = Get-Date -Format 'yyyyMMdd-HHmmss'
  $bak  = "$currentDir.bak-$ts"
  $temp = "$currentDir.new-$ts"

  # We rename new -> temp (so its final parent is same as current)
  Rename-Item -LiteralPath $newDir -NewName ([IO.Path]::GetFileName($temp))

  if(Test-Path $currentDir){ Rename-Item -LiteralPath $currentDir -NewName ([IO.Path]::GetFileName($bak)) }
  Rename-Item -LiteralPath $temp -NewName ([IO.Path]::GetFileName($currentDir))

  # keep only 3 most recent backups
  Get-ChildItem -LiteralPath ([IO.Path]::GetDirectoryName($currentDir)) -Directory -Filter (([IO.Path]::GetFileName($currentDir))+'.bak-*') |
    Sort-Object LastWriteTime -Desc | Select-Object -Skip 3 | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

function Open-Zip([string]$zipPath){
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::OpenRead($zipPath)
}

