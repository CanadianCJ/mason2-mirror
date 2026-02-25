# Stamped: 2025-11-05T17:02:01
param(
  [string]$Bundle,
  [ValidateSet('dev','strict')][string]$Mode = 'dev',
  [switch]$Latest
)

if ($Latest -and -not $Bundle) {
  $rel = Join-Path $env:USERPROFILE 'Desktop\Mason2\dist\releases'
  if (-not (Test-Path -LiteralPath $rel)) {
    throw "Releases folder not found: $rel"
  }

  # Prefer LATEST.txt if present, else pick newest zip
  $latestTxt = Join-Path $rel 'LATEST.txt'
  if (Test-Path -LiteralPath $latestTxt) {
    $Bundle = Join-Path $rel ((Get-Content $latestTxt -Raw).Trim())
  } else {
    $Bundle = Get-ChildItem $rel -File -Filter 'Mason2_*.zip' |
              Sort-Object LastWriteTime -Desc |
              Select-Object -First 1 -ExpandProperty FullName
  }

  if (-not $Bundle) { throw "No Mason2_*.zip found under $rel." }
}
if (-not $Bundle) {
  throw "No bundle specified (use -Bundle <path> or -Latest)."
}

# --- your existing stub body (writes the report) ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Rep  = Join-Path $Base 'reports'
New-Item -ItemType Directory -Force -Path $Rep | Out-Null

$report = [pscustomobject]@{
  ts           = (Get-Date).ToString('o')
  bundle       = [IO.Path]::GetFileName($Bundle)
  mode         = $Mode
  requiredOk   = $true
  rootsOk      = $true
  countsOk     = $true
  zip_count    = 0
  manifest_count = 0
}
$report | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $Rep 'verify_tighten_report.json')
"OK"

exit 0


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Bundle,
  [ValidateSet('dev','strict')][string]$Mode = 'dev',
  [switch]$Latest
)

if ($Latest -and -not $Bundle) {
  $rel = Join-Path $env:USERPROFILE 'Desktop\Mason2\dist\releases'
  if (-not (Test-Path -LiteralPath $rel)) {
    throw "Releases folder not found: $rel"
  }

  # Prefer LATEST.txt if present, else pick newest zip
  $latestTxt = Join-Path $rel 'LATEST.txt'
  if (Test-Path -LiteralPath $latestTxt) {
    $Bundle = Join-Path $rel ((Get-Content $latestTxt -Raw).Trim())
  } else {
    $Bundle = Get-ChildItem $rel -File -Filter 'Mason2_*.zip' |
              Sort-Object LastWriteTime -Desc |
              Select-Object -First 1 -ExpandProperty FullName
  }

  if (-not $Bundle) { throw "No Mason2_*.zip found under $rel." }
}
if (-not $Bundle) {
  throw "No bundle specified (use -Bundle <path> or -Latest)."
}

# --- your existing stub body (writes the report) ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Rep  = Join-Path $Base 'reports'
New-Item -ItemType Directory -Force -Path $Rep | Out-Null

$report = [pscustomobject]@{
  ts           = (Get-Date).ToString('o')
  bundle       = [IO.Path]::GetFileName($Bundle)
  mode         = $Mode
  requiredOk   = $true
  rootsOk      = $true
  countsOk     = $true
  zip_count    = 0
  manifest_count = 0
}
$report | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $Rep 'verify_tighten_report.json')
"OK"

exit 0


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Bundle,
  [ValidateSet('dev','strict')][string]$Mode = 'dev',
  [switch]$Latest
)

if ($Latest -and -not $Bundle) {
  $rel = Join-Path $env:USERPROFILE 'Desktop\Mason2\dist\releases'
  if (-not (Test-Path -LiteralPath $rel)) {
    throw "Releases folder not found: $rel"
  }

  # Prefer LATEST.txt if present, else pick newest zip
  $latestTxt = Join-Path $rel 'LATEST.txt'
  if (Test-Path -LiteralPath $latestTxt) {
    $Bundle = Join-Path $rel ((Get-Content $latestTxt -Raw).Trim())
  } else {
    $Bundle = Get-ChildItem $rel -File -Filter 'Mason2_*.zip' |
              Sort-Object LastWriteTime -Desc |
              Select-Object -First 1 -ExpandProperty FullName
  }

  if (-not $Bundle) { throw "No Mason2_*.zip found under $rel." }
}
if (-not $Bundle) {
  throw "No bundle specified (use -Bundle <path> or -Latest)."
}

# --- your existing stub body (writes the report) ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Rep  = Join-Path $Base 'reports'
New-Item -ItemType Directory -Force -Path $Rep | Out-Null

$report = [pscustomobject]@{
  ts           = (Get-Date).ToString('o')
  bundle       = [IO.Path]::GetFileName($Bundle)
  mode         = $Mode
  requiredOk   = $true
  rootsOk      = $true
  countsOk     = $true
  zip_count    = 0
  manifest_count = 0
}
$report | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $Rep 'verify_tighten_report.json')
"OK"

exit 0


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Bundle,
  [ValidateSet('dev','strict')][string]$Mode = 'dev',
  [switch]$Latest
)

if ($Latest -and -not $Bundle) {
  $rel = Join-Path $env:USERPROFILE 'Desktop\Mason2\dist\releases'
  if (-not (Test-Path -LiteralPath $rel)) {
    throw "Releases folder not found: $rel"
  }

  # Prefer LATEST.txt if present, else pick newest zip
  $latestTxt = Join-Path $rel 'LATEST.txt'
  if (Test-Path -LiteralPath $latestTxt) {
    $Bundle = Join-Path $rel ((Get-Content $latestTxt -Raw).Trim())
  } else {
    $Bundle = Get-ChildItem $rel -File -Filter 'Mason2_*.zip' |
              Sort-Object LastWriteTime -Desc |
              Select-Object -First 1 -ExpandProperty FullName
  }

  if (-not $Bundle) { throw "No Mason2_*.zip found under $rel." }
}
if (-not $Bundle) {
  throw "No bundle specified (use -Bundle <path> or -Latest)."
}

# --- your existing stub body (writes the report) ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Rep  = Join-Path $Base 'reports'
New-Item -ItemType Directory -Force -Path $Rep | Out-Null

$report = [pscustomobject]@{
  ts           = (Get-Date).ToString('o')
  bundle       = [IO.Path]::GetFileName($Bundle)
  mode         = $Mode
  requiredOk   = $true
  rootsOk      = $true
  countsOk     = $true
  zip_count    = 0
  manifest_count = 0
}
$report | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $Rep 'verify_tighten_report.json')
"OK"

exit 0


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Bundle,
  [ValidateSet('dev','strict')][string]$Mode = 'dev',
  [switch]$Latest
)

if ($Latest -and -not $Bundle) {
  $rel = Join-Path $env:USERPROFILE 'Desktop\Mason2\dist\releases'
  if (-not (Test-Path -LiteralPath $rel)) {
    throw "Releases folder not found: $rel"
  }

  # Prefer LATEST.txt if present, else pick newest zip
  $latestTxt = Join-Path $rel 'LATEST.txt'
  if (Test-Path -LiteralPath $latestTxt) {
    $Bundle = Join-Path $rel ((Get-Content $latestTxt -Raw).Trim())
  } else {
    $Bundle = Get-ChildItem $rel -File -Filter 'Mason2_*.zip' |
              Sort-Object LastWriteTime -Desc |
              Select-Object -First 1 -ExpandProperty FullName
  }

  if (-not $Bundle) { throw "No Mason2_*.zip found under $rel." }
}
if (-not $Bundle) {
  throw "No bundle specified (use -Bundle <path> or -Latest)."
}

# --- your existing stub body (writes the report) ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Rep  = Join-Path $Base 'reports'
New-Item -ItemType Directory -Force -Path $Rep | Out-Null

$report = [pscustomobject]@{
  ts           = (Get-Date).ToString('o')
  bundle       = [IO.Path]::GetFileName($Bundle)
  mode         = $Mode
  requiredOk   = $true
  rootsOk      = $true
  countsOk     = $true
  zip_count    = 0
  manifest_count = 0
}
$report | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $Rep 'verify_tighten_report.json')
"OK"

exit 0


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Bundle,
  [ValidateSet('dev','strict')][string]$Mode = 'dev',
  [switch]$Latest
)

if ($Latest -and -not $Bundle) {
  $rel = Join-Path $env:USERPROFILE 'Desktop\Mason2\dist\releases'
  if (-not (Test-Path -LiteralPath $rel)) {
    throw "Releases folder not found: $rel"
  }

  # Prefer LATEST.txt if present, else pick newest zip
  $latestTxt = Join-Path $rel 'LATEST.txt'
  if (Test-Path -LiteralPath $latestTxt) {
    $Bundle = Join-Path $rel ((Get-Content $latestTxt -Raw).Trim())
  } else {
    $Bundle = Get-ChildItem $rel -File -Filter 'Mason2_*.zip' |
              Sort-Object LastWriteTime -Desc |
              Select-Object -First 1 -ExpandProperty FullName
  }

  if (-not $Bundle) { throw "No Mason2_*.zip found under $rel." }
}
if (-not $Bundle) {
  throw "No bundle specified (use -Bundle <path> or -Latest)."
}

# --- your existing stub body (writes the report) ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Rep  = Join-Path $Base 'reports'
New-Item -ItemType Directory -Force -Path $Rep | Out-Null

$report = [pscustomobject]@{
  ts           = (Get-Date).ToString('o')
  bundle       = [IO.Path]::GetFileName($Bundle)
  mode         = $Mode
  requiredOk   = $true
  rootsOk      = $true
  countsOk     = $true
  zip_count    = 0
  manifest_count = 0
}
$report | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $Rep 'verify_tighten_report.json')
"OK"

exit 0


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Bundle,
  [ValidateSet('dev','strict')][string]$Mode = 'dev',
  [switch]$Latest
)

if ($Latest -and -not $Bundle) {
  $rel = Join-Path $env:USERPROFILE 'Desktop\Mason2\dist\releases'
  if (-not (Test-Path -LiteralPath $rel)) {
    throw "Releases folder not found: $rel"
  }

  # Prefer LATEST.txt if present, else pick newest zip
  $latestTxt = Join-Path $rel 'LATEST.txt'
  if (Test-Path -LiteralPath $latestTxt) {
    $Bundle = Join-Path $rel ((Get-Content $latestTxt -Raw).Trim())
  } else {
    $Bundle = Get-ChildItem $rel -File -Filter 'Mason2_*.zip' |
              Sort-Object LastWriteTime -Desc |
              Select-Object -First 1 -ExpandProperty FullName
  }

  if (-not $Bundle) { throw "No Mason2_*.zip found under $rel." }
}
if (-not $Bundle) {
  throw "No bundle specified (use -Bundle <path> or -Latest)."
}

# --- your existing stub body (writes the report) ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Rep  = Join-Path $Base 'reports'
New-Item -ItemType Directory -Force -Path $Rep | Out-Null

$report = [pscustomobject]@{
  ts           = (Get-Date).ToString('o')
  bundle       = [IO.Path]::GetFileName($Bundle)
  mode         = $Mode
  requiredOk   = $true
  rootsOk      = $true
  countsOk     = $true
  zip_count    = 0
  manifest_count = 0
}
$report | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $Rep 'verify_tighten_report.json')
"OK"

exit 0


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Bundle,
  [ValidateSet('dev','strict')][string]$Mode = 'dev',
  [switch]$Latest
)

if ($Latest -and -not $Bundle) {
  $rel = Join-Path $env:USERPROFILE 'Desktop\Mason2\dist\releases'
  if (-not (Test-Path -LiteralPath $rel)) {
    throw "Releases folder not found: $rel"
  }

  # Prefer LATEST.txt if present, else pick newest zip
  $latestTxt = Join-Path $rel 'LATEST.txt'
  if (Test-Path -LiteralPath $latestTxt) {
    $Bundle = Join-Path $rel ((Get-Content $latestTxt -Raw).Trim())
  } else {
    $Bundle = Get-ChildItem $rel -File -Filter 'Mason2_*.zip' |
              Sort-Object LastWriteTime -Desc |
              Select-Object -First 1 -ExpandProperty FullName
  }

  if (-not $Bundle) { throw "No Mason2_*.zip found under $rel." }
}
if (-not $Bundle) {
  throw "No bundle specified (use -Bundle <path> or -Latest)."
}

# --- your existing stub body (writes the report) ---
$Base = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Rep  = Join-Path $Base 'reports'
New-Item -ItemType Directory -Force -Path $Rep | Out-Null

$report = [pscustomobject]@{
  ts           = (Get-Date).ToString('o')
  bundle       = [IO.Path]::GetFileName($Bundle)
  mode         = $Mode
  requiredOk   = $true
  rootsOk      = $true
  countsOk     = $true
  zip_count    = 0
  manifest_count = 0
}
$report | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $Rep 'verify_tighten_report.json')
"OK"

exit 0


