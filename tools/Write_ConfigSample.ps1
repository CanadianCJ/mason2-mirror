# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envJson = Join-Path $Cfg "env.json.sample"
$dotEnv  = Join-Path $Base ".env.sample"
'{
  "environment": "dev",
  "api": { "port_status": 8383, "port_seed": 8109 },
  "guardrails": { "MASON_DISK_MIN_FREE_PCT": 10, "MASON_MONEY_ENABLE": 0 }
}' | Set-Content $envJson -Encoding UTF8
"MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nMASON_HEALTH_STABLE_RUNS=1" | Set-Content $dotEnv -Encoding ASCII
"ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-config-sample.ok") -Encoding ASCII
Write-Host "[ OK ] Config samples written"


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envJson = Join-Path $Cfg "env.json.sample"
$dotEnv  = Join-Path $Base ".env.sample"
'{
  "environment": "dev",
  "api": { "port_status": 8383, "port_seed": 8109 },
  "guardrails": { "MASON_DISK_MIN_FREE_PCT": 10, "MASON_MONEY_ENABLE": 0 }
}' | Set-Content $envJson -Encoding UTF8
"MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nMASON_HEALTH_STABLE_RUNS=1" | Set-Content $dotEnv -Encoding ASCII
"ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-config-sample.ok") -Encoding ASCII
Write-Host "[ OK ] Config samples written"


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envJson = Join-Path $Cfg "env.json.sample"
$dotEnv  = Join-Path $Base ".env.sample"
'{
  "environment": "dev",
  "api": { "port_status": 8383, "port_seed": 8109 },
  "guardrails": { "MASON_DISK_MIN_FREE_PCT": 10, "MASON_MONEY_ENABLE": 0 }
}' | Set-Content $envJson -Encoding UTF8
"MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nMASON_HEALTH_STABLE_RUNS=1" | Set-Content $dotEnv -Encoding ASCII
"ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-config-sample.ok") -Encoding ASCII
Write-Host "[ OK ] Config samples written"


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envJson = Join-Path $Cfg "env.json.sample"
$dotEnv  = Join-Path $Base ".env.sample"
'{
  "environment": "dev",
  "api": { "port_status": 8383, "port_seed": 8109 },
  "guardrails": { "MASON_DISK_MIN_FREE_PCT": 10, "MASON_MONEY_ENABLE": 0 }
}' | Set-Content $envJson -Encoding UTF8
"MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nMASON_HEALTH_STABLE_RUNS=1" | Set-Content $dotEnv -Encoding ASCII
"ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-config-sample.ok") -Encoding ASCII
Write-Host "[ OK ] Config samples written"


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envJson = Join-Path $Cfg "env.json.sample"
$dotEnv  = Join-Path $Base ".env.sample"
'{
  "environment": "dev",
  "api": { "port_status": 8383, "port_seed": 8109 },
  "guardrails": { "MASON_DISK_MIN_FREE_PCT": 10, "MASON_MONEY_ENABLE": 0 }
}' | Set-Content $envJson -Encoding UTF8
"MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nMASON_HEALTH_STABLE_RUNS=1" | Set-Content $dotEnv -Encoding ASCII
"ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-config-sample.ok") -Encoding ASCII
Write-Host "[ OK ] Config samples written"


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envJson = Join-Path $Cfg "env.json.sample"
$dotEnv  = Join-Path $Base ".env.sample"
'{
  "environment": "dev",
  "api": { "port_status": 8383, "port_seed": 8109 },
  "guardrails": { "MASON_DISK_MIN_FREE_PCT": 10, "MASON_MONEY_ENABLE": 0 }
}' | Set-Content $envJson -Encoding UTF8
"MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nMASON_HEALTH_STABLE_RUNS=1" | Set-Content $dotEnv -Encoding ASCII
"ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-config-sample.ok") -Encoding ASCII
Write-Host "[ OK ] Config samples written"


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envJson = Join-Path $Cfg "env.json.sample"
$dotEnv  = Join-Path $Base ".env.sample"
'{
  "environment": "dev",
  "api": { "port_status": 8383, "port_seed": 8109 },
  "guardrails": { "MASON_DISK_MIN_FREE_PCT": 10, "MASON_MONEY_ENABLE": 0 }
}' | Set-Content $envJson -Encoding UTF8
"MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nMASON_HEALTH_STABLE_RUNS=1" | Set-Content $dotEnv -Encoding ASCII
"ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-config-sample.ok") -Encoding ASCII
Write-Host "[ OK ] Config samples written"


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envJson = Join-Path $Cfg "env.json.sample"
$dotEnv  = Join-Path $Base ".env.sample"
'{
  "environment": "dev",
  "api": { "port_status": 8383, "port_seed": 8109 },
  "guardrails": { "MASON_DISK_MIN_FREE_PCT": 10, "MASON_MONEY_ENABLE": 0 }
}' | Set-Content $envJson -Encoding UTF8
"MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nMASON_HEALTH_STABLE_RUNS=1" | Set-Content $dotEnv -Encoding ASCII
"ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-config-sample.ok") -Encoding ASCII
Write-Host "[ OK ] Config samples written"


