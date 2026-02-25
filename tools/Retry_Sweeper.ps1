# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep    = Join-Path $Base "reports"
$retry  = Join-Path $Rep "queue\retry"
$pend   = Join-Path $Rep "queue\pending"
$ageMin = 10
New-Item $retry -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $pend  -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$mov = @()
Get-ChildItem $retry -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    try { Move-Item $_.FullName (Join-Path $pend $_.Name) -Force; $mov += $_.Name } catch {}
  }
}
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "retry_sweeper" -Level "INFO" -Message "sweep" -Props @{ moved=($mov -join ','); count=$mov.Count }
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep    = Join-Path $Base "reports"
$retry  = Join-Path $Rep "queue\retry"
$pend   = Join-Path $Rep "queue\pending"
$ageMin = 10
New-Item $retry -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $pend  -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$mov = @()
Get-ChildItem $retry -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    try { Move-Item $_.FullName (Join-Path $pend $_.Name) -Force; $mov += $_.Name } catch {}
  }
}
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "retry_sweeper" -Level "INFO" -Message "sweep" -Props @{ moved=($mov -join ','); count=$mov.Count }
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep    = Join-Path $Base "reports"
$retry  = Join-Path $Rep "queue\retry"
$pend   = Join-Path $Rep "queue\pending"
$ageMin = 10
New-Item $retry -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $pend  -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$mov = @()
Get-ChildItem $retry -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    try { Move-Item $_.FullName (Join-Path $pend $_.Name) -Force; $mov += $_.Name } catch {}
  }
}
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "retry_sweeper" -Level "INFO" -Message "sweep" -Props @{ moved=($mov -join ','); count=$mov.Count }
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep    = Join-Path $Base "reports"
$retry  = Join-Path $Rep "queue\retry"
$pend   = Join-Path $Rep "queue\pending"
$ageMin = 10
New-Item $retry -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $pend  -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$mov = @()
Get-ChildItem $retry -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    try { Move-Item $_.FullName (Join-Path $pend $_.Name) -Force; $mov += $_.Name } catch {}
  }
}
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "retry_sweeper" -Level "INFO" -Message "sweep" -Props @{ moved=($mov -join ','); count=$mov.Count }
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep    = Join-Path $Base "reports"
$retry  = Join-Path $Rep "queue\retry"
$pend   = Join-Path $Rep "queue\pending"
$ageMin = 10
New-Item $retry -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $pend  -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$mov = @()
Get-ChildItem $retry -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    try { Move-Item $_.FullName (Join-Path $pend $_.Name) -Force; $mov += $_.Name } catch {}
  }
}
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "retry_sweeper" -Level "INFO" -Message "sweep" -Props @{ moved=($mov -join ','); count=$mov.Count }
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep    = Join-Path $Base "reports"
$retry  = Join-Path $Rep "queue\retry"
$pend   = Join-Path $Rep "queue\pending"
$ageMin = 10
New-Item $retry -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $pend  -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$mov = @()
Get-ChildItem $retry -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    try { Move-Item $_.FullName (Join-Path $pend $_.Name) -Force; $mov += $_.Name } catch {}
  }
}
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "retry_sweeper" -Level "INFO" -Message "sweep" -Props @{ moved=($mov -join ','); count=$mov.Count }
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep    = Join-Path $Base "reports"
$retry  = Join-Path $Rep "queue\retry"
$pend   = Join-Path $Rep "queue\pending"
$ageMin = 10
New-Item $retry -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $pend  -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$mov = @()
Get-ChildItem $retry -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    try { Move-Item $_.FullName (Join-Path $pend $_.Name) -Force; $mov += $_.Name } catch {}
  }
}
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "retry_sweeper" -Level "INFO" -Message "sweep" -Props @{ moved=($mov -join ','); count=$mov.Count }
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep    = Join-Path $Base "reports"
$retry  = Join-Path $Rep "queue\retry"
$pend   = Join-Path $Rep "queue\pending"
$ageMin = 10
New-Item $retry -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $pend  -ItemType Directory -ea SilentlyContinue | Out-Null
$now = Get-Date
$mov = @()
Get-ChildItem $retry -File -ea SilentlyContinue | ForEach-Object {
  $mins = [int]($now - $_.LastWriteTime).TotalMinutes
  if ($mins -ge $ageMin) {
    try { Move-Item $_.FullName (Join-Path $pend $_.Name) -Force; $mov += $_.Name } catch {}
  }
}
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "retry_sweeper" -Level "INFO" -Message "sweep" -Props @{ moved=($mov -join ','); count=$mov.Count }
}

