# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$rel = Join-Path $Base 'dist\releases'
New-Item -ItemType Directory -Force -Path $rel | Out-Null
$latestTxt = Join-Path $rel 'LATEST.txt'
$bundle = if (Test-Path $latestTxt) { (Get-Content $latestTxt -Raw).Trim() } else { "Mason2_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip" }

# collect files (skip logs/reports/releases)
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\reports\\|\\logs\\telemetry\\|\\dist\\releases\\|\\archive\\' }

$items = @()
foreach ($f in $files) {
  try { $h = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 } catch { continue }
  $items += [pscustomobject]@{
    path   = $f.FullName.Substring($Base.Length+1)
    bytes  = $f.Length
    sha256 = $h.Hash
  }
}
$manifest = [pscustomobject]@{
  generated = (Get-Date).ToString('s')
  base      = $Base
  bundle    = $bundle
  count     = $items.Count
  files     = $items
}
$mf = Join-Path $rel 'manifest.json'
($manifest | ConvertTo-Json -Depth 6) | Out-File -FilePath $mf -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\manifest_events.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='manifest'; file='dist/releases/manifest.json'; count=$items.Count }

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$rel = Join-Path $Base 'dist\releases'
New-Item -ItemType Directory -Force -Path $rel | Out-Null
$latestTxt = Join-Path $rel 'LATEST.txt'
$bundle = if (Test-Path $latestTxt) { (Get-Content $latestTxt -Raw).Trim() } else { "Mason2_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip" }

# collect files (skip logs/reports/releases)
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\reports\\|\\logs\\telemetry\\|\\dist\\releases\\|\\archive\\' }

$items = @()
foreach ($f in $files) {
  try { $h = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 } catch { continue }
  $items += [pscustomobject]@{
    path   = $f.FullName.Substring($Base.Length+1)
    bytes  = $f.Length
    sha256 = $h.Hash
  }
}
$manifest = [pscustomobject]@{
  generated = (Get-Date).ToString('s')
  base      = $Base
  bundle    = $bundle
  count     = $items.Count
  files     = $items
}
$mf = Join-Path $rel 'manifest.json'
($manifest | ConvertTo-Json -Depth 6) | Out-File -FilePath $mf -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\manifest_events.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='manifest'; file='dist/releases/manifest.json'; count=$items.Count }

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$rel = Join-Path $Base 'dist\releases'
New-Item -ItemType Directory -Force -Path $rel | Out-Null
$latestTxt = Join-Path $rel 'LATEST.txt'
$bundle = if (Test-Path $latestTxt) { (Get-Content $latestTxt -Raw).Trim() } else { "Mason2_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip" }

# collect files (skip logs/reports/releases)
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\reports\\|\\logs\\telemetry\\|\\dist\\releases\\|\\archive\\' }

$items = @()
foreach ($f in $files) {
  try { $h = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 } catch { continue }
  $items += [pscustomobject]@{
    path   = $f.FullName.Substring($Base.Length+1)
    bytes  = $f.Length
    sha256 = $h.Hash
  }
}
$manifest = [pscustomobject]@{
  generated = (Get-Date).ToString('s')
  base      = $Base
  bundle    = $bundle
  count     = $items.Count
  files     = $items
}
$mf = Join-Path $rel 'manifest.json'
($manifest | ConvertTo-Json -Depth 6) | Out-File -FilePath $mf -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\manifest_events.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='manifest'; file='dist/releases/manifest.json'; count=$items.Count }

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$rel = Join-Path $Base 'dist\releases'
New-Item -ItemType Directory -Force -Path $rel | Out-Null
$latestTxt = Join-Path $rel 'LATEST.txt'
$bundle = if (Test-Path $latestTxt) { (Get-Content $latestTxt -Raw).Trim() } else { "Mason2_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip" }

# collect files (skip logs/reports/releases)
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\reports\\|\\logs\\telemetry\\|\\dist\\releases\\|\\archive\\' }

$items = @()
foreach ($f in $files) {
  try { $h = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 } catch { continue }
  $items += [pscustomobject]@{
    path   = $f.FullName.Substring($Base.Length+1)
    bytes  = $f.Length
    sha256 = $h.Hash
  }
}
$manifest = [pscustomobject]@{
  generated = (Get-Date).ToString('s')
  base      = $Base
  bundle    = $bundle
  count     = $items.Count
  files     = $items
}
$mf = Join-Path $rel 'manifest.json'
($manifest | ConvertTo-Json -Depth 6) | Out-File -FilePath $mf -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\manifest_events.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='manifest'; file='dist/releases/manifest.json'; count=$items.Count }

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$rel = Join-Path $Base 'dist\releases'
New-Item -ItemType Directory -Force -Path $rel | Out-Null
$latestTxt = Join-Path $rel 'LATEST.txt'
$bundle = if (Test-Path $latestTxt) { (Get-Content $latestTxt -Raw).Trim() } else { "Mason2_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip" }

# collect files (skip logs/reports/releases)
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\reports\\|\\logs\\telemetry\\|\\dist\\releases\\|\\archive\\' }

$items = @()
foreach ($f in $files) {
  try { $h = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 } catch { continue }
  $items += [pscustomobject]@{
    path   = $f.FullName.Substring($Base.Length+1)
    bytes  = $f.Length
    sha256 = $h.Hash
  }
}
$manifest = [pscustomobject]@{
  generated = (Get-Date).ToString('s')
  base      = $Base
  bundle    = $bundle
  count     = $items.Count
  files     = $items
}
$mf = Join-Path $rel 'manifest.json'
($manifest | ConvertTo-Json -Depth 6) | Out-File -FilePath $mf -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\manifest_events.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='manifest'; file='dist/releases/manifest.json'; count=$items.Count }

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$rel = Join-Path $Base 'dist\releases'
New-Item -ItemType Directory -Force -Path $rel | Out-Null
$latestTxt = Join-Path $rel 'LATEST.txt'
$bundle = if (Test-Path $latestTxt) { (Get-Content $latestTxt -Raw).Trim() } else { "Mason2_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip" }

# collect files (skip logs/reports/releases)
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\reports\\|\\logs\\telemetry\\|\\dist\\releases\\|\\archive\\' }

$items = @()
foreach ($f in $files) {
  try { $h = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 } catch { continue }
  $items += [pscustomobject]@{
    path   = $f.FullName.Substring($Base.Length+1)
    bytes  = $f.Length
    sha256 = $h.Hash
  }
}
$manifest = [pscustomobject]@{
  generated = (Get-Date).ToString('s')
  base      = $Base
  bundle    = $bundle
  count     = $items.Count
  files     = $items
}
$mf = Join-Path $rel 'manifest.json'
($manifest | ConvertTo-Json -Depth 6) | Out-File -FilePath $mf -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\manifest_events.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='manifest'; file='dist/releases/manifest.json'; count=$items.Count }

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$rel = Join-Path $Base 'dist\releases'
New-Item -ItemType Directory -Force -Path $rel | Out-Null
$latestTxt = Join-Path $rel 'LATEST.txt'
$bundle = if (Test-Path $latestTxt) { (Get-Content $latestTxt -Raw).Trim() } else { "Mason2_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip" }

# collect files (skip logs/reports/releases)
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\reports\\|\\logs\\telemetry\\|\\dist\\releases\\|\\archive\\' }

$items = @()
foreach ($f in $files) {
  try { $h = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 } catch { continue }
  $items += [pscustomobject]@{
    path   = $f.FullName.Substring($Base.Length+1)
    bytes  = $f.Length
    sha256 = $h.Hash
  }
}
$manifest = [pscustomobject]@{
  generated = (Get-Date).ToString('s')
  base      = $Base
  bundle    = $bundle
  count     = $items.Count
  files     = $items
}
$mf = Join-Path $rel 'manifest.json'
($manifest | ConvertTo-Json -Depth 6) | Out-File -FilePath $mf -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\manifest_events.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='manifest'; file='dist/releases/manifest.json'; count=$items.Count }

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$rel = Join-Path $Base 'dist\releases'
New-Item -ItemType Directory -Force -Path $rel | Out-Null
$latestTxt = Join-Path $rel 'LATEST.txt'
$bundle = if (Test-Path $latestTxt) { (Get-Content $latestTxt -Raw).Trim() } else { "Mason2_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip" }

# collect files (skip logs/reports/releases)
$files = Get-ChildItem -LiteralPath $Base -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\reports\\|\\logs\\telemetry\\|\\dist\\releases\\|\\archive\\' }

$items = @()
foreach ($f in $files) {
  try { $h = Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 } catch { continue }
  $items += [pscustomobject]@{
    path   = $f.FullName.Substring($Base.Length+1)
    bytes  = $f.Length
    sha256 = $h.Hash
  }
}
$manifest = [pscustomobject]@{
  generated = (Get-Date).ToString('s')
  base      = $Base
  bundle    = $bundle
  count     = $items.Count
  files     = $items
}
$mf = Join-Path $rel 'manifest.json'
($manifest | ConvertTo-Json -Depth 6) | Out-File -FilePath $mf -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\manifest_events.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='manifest'; file='dist/releases/manifest.json'; count=$items.Count }

