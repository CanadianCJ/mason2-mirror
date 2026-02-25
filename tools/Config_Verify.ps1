$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$baseP = Join-Path $Base 'config\config_baseline.json'
if (-not (Test-Path $baseP)) { exit 0 }

try {
  $baseRaw = Get-Content $baseP -Raw | ConvertFrom-Json
} catch {
  exit 0
}

# Normalize to array (PS 5.1-safe)
$base = @()
if ($null -ne $baseRaw) {
  if ($baseRaw -is [array]) { $base = $baseRaw } else { $base = @($baseRaw) }
}

$map = @{}
foreach ($b in $base) {
  if ($b -and $b.PSObject.Properties['path'] -and $b.PSObject.Properties['sha256']) {
    $map[$b.path] = $b.sha256
  }
}

$curr = @{}
Get-ChildItem -LiteralPath (Join-Path $Base 'config') -Filter *.json -File -ErrorAction SilentlyContinue |
  ForEach-Object {
    try {
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $curr[$rel] = $h.Hash
    } catch {}
  }

$added=@(); $removed=@(); $changed=@()
foreach ($k in $map.Keys) {
  if (-not $curr.ContainsKey($k)) { $removed += $k }
  elseif ($curr[$k] -ne $map[$k]) { $changed += $k }
}
foreach ($k in $curr.Keys) {
  if (-not $map.ContainsKey($k)) { $added += $k }
}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_diff.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='config_diff'; added=$added; removed=$removed; changed=$changed
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$baseP = Join-Path $Base 'config\config_baseline.json'
if (-not (Test-Path $baseP)) { exit 0 }

try {
  $baseRaw = Get-Content $baseP -Raw | ConvertFrom-Json
} catch {
  exit 0
}

# Normalize to array (PS 5.1-safe)
$base = @()
if ($null -ne $baseRaw) {
  if ($baseRaw -is [array]) { $base = $baseRaw } else { $base = @($baseRaw) }
}

$map = @{}
foreach ($b in $base) {
  if ($b -and $b.PSObject.Properties['path'] -and $b.PSObject.Properties['sha256']) {
    $map[$b.path] = $b.sha256
  }
}

$curr = @{}
Get-ChildItem -LiteralPath (Join-Path $Base 'config') -Filter *.json -File -ErrorAction SilentlyContinue |
  ForEach-Object {
    try {
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $curr[$rel] = $h.Hash
    } catch {}
  }

$added=@(); $removed=@(); $changed=@()
foreach ($k in $map.Keys) {
  if (-not $curr.ContainsKey($k)) { $removed += $k }
  elseif ($curr[$k] -ne $map[$k]) { $changed += $k }
}
foreach ($k in $curr.Keys) {
  if (-not $map.ContainsKey($k)) { $added += $k }
}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_diff.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='config_diff'; added=$added; removed=$removed; changed=$changed
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$baseP = Join-Path $Base 'config\config_baseline.json'
if (-not (Test-Path $baseP)) { exit 0 }

try {
  $baseRaw = Get-Content $baseP -Raw | ConvertFrom-Json
} catch {
  exit 0
}

# Normalize to array (PS 5.1-safe)
$base = @()
if ($null -ne $baseRaw) {
  if ($baseRaw -is [array]) { $base = $baseRaw } else { $base = @($baseRaw) }
}

$map = @{}
foreach ($b in $base) {
  if ($b -and $b.PSObject.Properties['path'] -and $b.PSObject.Properties['sha256']) {
    $map[$b.path] = $b.sha256
  }
}

$curr = @{}
Get-ChildItem -LiteralPath (Join-Path $Base 'config') -Filter *.json -File -ErrorAction SilentlyContinue |
  ForEach-Object {
    try {
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $curr[$rel] = $h.Hash
    } catch {}
  }

$added=@(); $removed=@(); $changed=@()
foreach ($k in $map.Keys) {
  if (-not $curr.ContainsKey($k)) { $removed += $k }
  elseif ($curr[$k] -ne $map[$k]) { $changed += $k }
}
foreach ($k in $curr.Keys) {
  if (-not $map.ContainsKey($k)) { $added += $k }
}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_diff.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='config_diff'; added=$added; removed=$removed; changed=$changed
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$baseP = Join-Path $Base 'config\config_baseline.json'
if (-not (Test-Path $baseP)) { exit 0 }

try {
  $baseRaw = Get-Content $baseP -Raw | ConvertFrom-Json
} catch {
  exit 0
}

# Normalize to array (PS 5.1-safe)
$base = @()
if ($null -ne $baseRaw) {
  if ($baseRaw -is [array]) { $base = $baseRaw } else { $base = @($baseRaw) }
}

$map = @{}
foreach ($b in $base) {
  if ($b -and $b.PSObject.Properties['path'] -and $b.PSObject.Properties['sha256']) {
    $map[$b.path] = $b.sha256
  }
}

$curr = @{}
Get-ChildItem -LiteralPath (Join-Path $Base 'config') -Filter *.json -File -ErrorAction SilentlyContinue |
  ForEach-Object {
    try {
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $curr[$rel] = $h.Hash
    } catch {}
  }

$added=@(); $removed=@(); $changed=@()
foreach ($k in $map.Keys) {
  if (-not $curr.ContainsKey($k)) { $removed += $k }
  elseif ($curr[$k] -ne $map[$k]) { $changed += $k }
}
foreach ($k in $curr.Keys) {
  if (-not $map.ContainsKey($k)) { $added += $k }
}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_diff.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='config_diff'; added=$added; removed=$removed; changed=$changed
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$baseP = Join-Path $Base 'config\config_baseline.json'
if (-not (Test-Path $baseP)) { exit 0 }

try {
  $baseRaw = Get-Content $baseP -Raw | ConvertFrom-Json
} catch {
  exit 0
}

# Normalize to array (PS 5.1-safe)
$base = @()
if ($null -ne $baseRaw) {
  if ($baseRaw -is [array]) { $base = $baseRaw } else { $base = @($baseRaw) }
}

$map = @{}
foreach ($b in $base) {
  if ($b -and $b.PSObject.Properties['path'] -and $b.PSObject.Properties['sha256']) {
    $map[$b.path] = $b.sha256
  }
}

$curr = @{}
Get-ChildItem -LiteralPath (Join-Path $Base 'config') -Filter *.json -File -ErrorAction SilentlyContinue |
  ForEach-Object {
    try {
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $curr[$rel] = $h.Hash
    } catch {}
  }

$added=@(); $removed=@(); $changed=@()
foreach ($k in $map.Keys) {
  if (-not $curr.ContainsKey($k)) { $removed += $k }
  elseif ($curr[$k] -ne $map[$k]) { $changed += $k }
}
foreach ($k in $curr.Keys) {
  if (-not $map.ContainsKey($k)) { $added += $k }
}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_diff.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='config_diff'; added=$added; removed=$removed; changed=$changed
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$baseP = Join-Path $Base 'config\config_baseline.json'
if (-not (Test-Path $baseP)) { exit 0 }

try {
  $baseRaw = Get-Content $baseP -Raw | ConvertFrom-Json
} catch {
  exit 0
}

# Normalize to array (PS 5.1-safe)
$base = @()
if ($null -ne $baseRaw) {
  if ($baseRaw -is [array]) { $base = $baseRaw } else { $base = @($baseRaw) }
}

$map = @{}
foreach ($b in $base) {
  if ($b -and $b.PSObject.Properties['path'] -and $b.PSObject.Properties['sha256']) {
    $map[$b.path] = $b.sha256
  }
}

$curr = @{}
Get-ChildItem -LiteralPath (Join-Path $Base 'config') -Filter *.json -File -ErrorAction SilentlyContinue |
  ForEach-Object {
    try {
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $curr[$rel] = $h.Hash
    } catch {}
  }

$added=@(); $removed=@(); $changed=@()
foreach ($k in $map.Keys) {
  if (-not $curr.ContainsKey($k)) { $removed += $k }
  elseif ($curr[$k] -ne $map[$k]) { $changed += $k }
}
foreach ($k in $curr.Keys) {
  if (-not $map.ContainsKey($k)) { $added += $k }
}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_diff.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='config_diff'; added=$added; removed=$removed; changed=$changed
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$baseP = Join-Path $Base 'config\config_baseline.json'
if (-not (Test-Path $baseP)) { exit 0 }

try {
  $baseRaw = Get-Content $baseP -Raw | ConvertFrom-Json
} catch {
  exit 0
}

# Normalize to array (PS 5.1-safe)
$base = @()
if ($null -ne $baseRaw) {
  if ($baseRaw -is [array]) { $base = $baseRaw } else { $base = @($baseRaw) }
}

$map = @{}
foreach ($b in $base) {
  if ($b -and $b.PSObject.Properties['path'] -and $b.PSObject.Properties['sha256']) {
    $map[$b.path] = $b.sha256
  }
}

$curr = @{}
Get-ChildItem -LiteralPath (Join-Path $Base 'config') -Filter *.json -File -ErrorAction SilentlyContinue |
  ForEach-Object {
    try {
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $curr[$rel] = $h.Hash
    } catch {}
  }

$added=@(); $removed=@(); $changed=@()
foreach ($k in $map.Keys) {
  if (-not $curr.ContainsKey($k)) { $removed += $k }
  elseif ($curr[$k] -ne $map[$k]) { $changed += $k }
}
foreach ($k in $curr.Keys) {
  if (-not $map.ContainsKey($k)) { $added += $k }
}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_diff.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='config_diff'; added=$added; removed=$removed; changed=$changed
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$baseP = Join-Path $Base 'config\config_baseline.json'
if (-not (Test-Path $baseP)) { exit 0 }

try {
  $baseRaw = Get-Content $baseP -Raw | ConvertFrom-Json
} catch {
  exit 0
}

# Normalize to array (PS 5.1-safe)
$base = @()
if ($null -ne $baseRaw) {
  if ($baseRaw -is [array]) { $base = $baseRaw } else { $base = @($baseRaw) }
}

$map = @{}
foreach ($b in $base) {
  if ($b -and $b.PSObject.Properties['path'] -and $b.PSObject.Properties['sha256']) {
    $map[$b.path] = $b.sha256
  }
}

$curr = @{}
Get-ChildItem -LiteralPath (Join-Path $Base 'config') -Filter *.json -File -ErrorAction SilentlyContinue |
  ForEach-Object {
    try {
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $curr[$rel] = $h.Hash
    } catch {}
  }

$added=@(); $removed=@(); $changed=@()
foreach ($k in $map.Keys) {
  if (-not $curr.ContainsKey($k)) { $removed += $k }
  elseif ($curr[$k] -ne $map[$k]) { $changed += $k }
}
foreach ($k in $curr.Keys) {
  if (-not $map.ContainsKey($k)) { $added += $k }
}

Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_diff.jsonl') -Obj @{
  ts=(Get-Date).ToString('s'); kind='config_diff'; added=$added; removed=$removed; changed=$changed
}
