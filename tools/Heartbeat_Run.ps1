# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
New-Item (Split-Path $hb) -ItemType Directory -ea SilentlyContinue | Out-Null
(Get-Date -Format s) | Set-Content $hb -Encoding ASCII
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "heartbeat" -Level "TRACE" -Message "tick" -Props @{ ts=(Get-Date).ToString("o") }
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
New-Item (Split-Path $hb) -ItemType Directory -ea SilentlyContinue | Out-Null
(Get-Date -Format s) | Set-Content $hb -Encoding ASCII
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "heartbeat" -Level "TRACE" -Message "tick" -Props @{ ts=(Get-Date).ToString("o") }
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
New-Item (Split-Path $hb) -ItemType Directory -ea SilentlyContinue | Out-Null
(Get-Date -Format s) | Set-Content $hb -Encoding ASCII
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "heartbeat" -Level "TRACE" -Message "tick" -Props @{ ts=(Get-Date).ToString("o") }
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
New-Item (Split-Path $hb) -ItemType Directory -ea SilentlyContinue | Out-Null
(Get-Date -Format s) | Set-Content $hb -Encoding ASCII
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "heartbeat" -Level "TRACE" -Message "tick" -Props @{ ts=(Get-Date).ToString("o") }
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
New-Item (Split-Path $hb) -ItemType Directory -ea SilentlyContinue | Out-Null
(Get-Date -Format s) | Set-Content $hb -Encoding ASCII
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "heartbeat" -Level "TRACE" -Message "tick" -Props @{ ts=(Get-Date).ToString("o") }
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
New-Item (Split-Path $hb) -ItemType Directory -ea SilentlyContinue | Out-Null
(Get-Date -Format s) | Set-Content $hb -Encoding ASCII
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "heartbeat" -Level "TRACE" -Message "tick" -Props @{ ts=(Get-Date).ToString("o") }
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
New-Item (Split-Path $hb) -ItemType Directory -ea SilentlyContinue | Out-Null
(Get-Date -Format s) | Set-Content $hb -Encoding ASCII
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "heartbeat" -Level "TRACE" -Message "tick" -Props @{ ts=(Get-Date).ToString("o") }
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
New-Item (Split-Path $hb) -ItemType Directory -ea SilentlyContinue | Out-Null
(Get-Date -Format s) | Set-Content $hb -Encoding ASCII
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "heartbeat" -Level "TRACE" -Message "tick" -Props @{ ts=(Get-Date).ToString("o") }
}

