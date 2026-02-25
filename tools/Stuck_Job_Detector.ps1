# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep   = Join-Path $Base "reports"
$locks = Join-Path $Rep  "locks"
$out   = Join-Path $Rep  "stuck_jobs.json"
$ageMin = 30
New-Item $locks -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$stuck = @()
Get-ChildItem $locks -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    $stuck += [pscustomobject]@{ file=$_.Name; age_min=$mins; path=$_.FullName }
  }
}
($stuck | ConvertTo-Json -Depth 4) | Set-Content $out -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "stuck" -Level ($(if($stuck.Count -gt 0){"WARN"}else{"INFO"})) -Message "stuck scan" -Props @{ count=$stuck.Count }
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep   = Join-Path $Base "reports"
$locks = Join-Path $Rep  "locks"
$out   = Join-Path $Rep  "stuck_jobs.json"
$ageMin = 30
New-Item $locks -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$stuck = @()
Get-ChildItem $locks -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    $stuck += [pscustomobject]@{ file=$_.Name; age_min=$mins; path=$_.FullName }
  }
}
($stuck | ConvertTo-Json -Depth 4) | Set-Content $out -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "stuck" -Level ($(if($stuck.Count -gt 0){"WARN"}else{"INFO"})) -Message "stuck scan" -Props @{ count=$stuck.Count }
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep   = Join-Path $Base "reports"
$locks = Join-Path $Rep  "locks"
$out   = Join-Path $Rep  "stuck_jobs.json"
$ageMin = 30
New-Item $locks -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$stuck = @()
Get-ChildItem $locks -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    $stuck += [pscustomobject]@{ file=$_.Name; age_min=$mins; path=$_.FullName }
  }
}
($stuck | ConvertTo-Json -Depth 4) | Set-Content $out -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "stuck" -Level ($(if($stuck.Count -gt 0){"WARN"}else{"INFO"})) -Message "stuck scan" -Props @{ count=$stuck.Count }
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep   = Join-Path $Base "reports"
$locks = Join-Path $Rep  "locks"
$out   = Join-Path $Rep  "stuck_jobs.json"
$ageMin = 30
New-Item $locks -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$stuck = @()
Get-ChildItem $locks -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    $stuck += [pscustomobject]@{ file=$_.Name; age_min=$mins; path=$_.FullName }
  }
}
($stuck | ConvertTo-Json -Depth 4) | Set-Content $out -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "stuck" -Level ($(if($stuck.Count -gt 0){"WARN"}else{"INFO"})) -Message "stuck scan" -Props @{ count=$stuck.Count }
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep   = Join-Path $Base "reports"
$locks = Join-Path $Rep  "locks"
$out   = Join-Path $Rep  "stuck_jobs.json"
$ageMin = 30
New-Item $locks -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$stuck = @()
Get-ChildItem $locks -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    $stuck += [pscustomobject]@{ file=$_.Name; age_min=$mins; path=$_.FullName }
  }
}
($stuck | ConvertTo-Json -Depth 4) | Set-Content $out -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "stuck" -Level ($(if($stuck.Count -gt 0){"WARN"}else{"INFO"})) -Message "stuck scan" -Props @{ count=$stuck.Count }
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep   = Join-Path $Base "reports"
$locks = Join-Path $Rep  "locks"
$out   = Join-Path $Rep  "stuck_jobs.json"
$ageMin = 30
New-Item $locks -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$stuck = @()
Get-ChildItem $locks -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    $stuck += [pscustomobject]@{ file=$_.Name; age_min=$mins; path=$_.FullName }
  }
}
($stuck | ConvertTo-Json -Depth 4) | Set-Content $out -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "stuck" -Level ($(if($stuck.Count -gt 0){"WARN"}else{"INFO"})) -Message "stuck scan" -Props @{ count=$stuck.Count }
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep   = Join-Path $Base "reports"
$locks = Join-Path $Rep  "locks"
$out   = Join-Path $Rep  "stuck_jobs.json"
$ageMin = 30
New-Item $locks -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$stuck = @()
Get-ChildItem $locks -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    $stuck += [pscustomobject]@{ file=$_.Name; age_min=$mins; path=$_.FullName }
  }
}
($stuck | ConvertTo-Json -Depth 4) | Set-Content $out -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "stuck" -Level ($(if($stuck.Count -gt 0){"WARN"}else{"INFO"})) -Message "stuck scan" -Props @{ count=$stuck.Count }
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep   = Join-Path $Base "reports"
$locks = Join-Path $Rep  "locks"
$out   = Join-Path $Rep  "stuck_jobs.json"
$ageMin = 30
New-Item $locks -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$stuck = @()
Get-ChildItem $locks -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    $stuck += [pscustomobject]@{ file=$_.Name; age_min=$mins; path=$_.FullName }
  }
}
($stuck | ConvertTo-Json -Depth 4) | Set-Content $out -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "stuck" -Level ($(if($stuck.Count -gt 0){"WARN"}else{"INFO"})) -Message "stuck scan" -Props @{ count=$stuck.Count }
}

