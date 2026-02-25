# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Env_Discovery.ps1
param([ValidateSet("dev","prod")]$Env="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
@{ environment = $Env; updated = (Get-Date).ToString("s") } |
  ConvertTo-Json | Set-Content (Join-Path $Cfg "env.json") -Encoding UTF8
"ENV=$Env" | Set-Content (Join-Path $Rep "env.txt") -Encoding ASCII
"ok" | Set-Content (Join-Path $Sig "system-structure-env-discovery.ok") -Encoding ASCII
Write-Host "[ OK ] Env set -> $Env"


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Env_Discovery.ps1
param([ValidateSet("dev","prod")]$Env="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
@{ environment = $Env; updated = (Get-Date).ToString("s") } |
  ConvertTo-Json | Set-Content (Join-Path $Cfg "env.json") -Encoding UTF8
"ENV=$Env" | Set-Content (Join-Path $Rep "env.txt") -Encoding ASCII
"ok" | Set-Content (Join-Path $Sig "system-structure-env-discovery.ok") -Encoding ASCII
Write-Host "[ OK ] Env set -> $Env"


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Env_Discovery.ps1
param([ValidateSet("dev","prod")]$Env="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
@{ environment = $Env; updated = (Get-Date).ToString("s") } |
  ConvertTo-Json | Set-Content (Join-Path $Cfg "env.json") -Encoding UTF8
"ENV=$Env" | Set-Content (Join-Path $Rep "env.txt") -Encoding ASCII
"ok" | Set-Content (Join-Path $Sig "system-structure-env-discovery.ok") -Encoding ASCII
Write-Host "[ OK ] Env set -> $Env"


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Env_Discovery.ps1
param([ValidateSet("dev","prod")]$Env="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
@{ environment = $Env; updated = (Get-Date).ToString("s") } |
  ConvertTo-Json | Set-Content (Join-Path $Cfg "env.json") -Encoding UTF8
"ENV=$Env" | Set-Content (Join-Path $Rep "env.txt") -Encoding ASCII
"ok" | Set-Content (Join-Path $Sig "system-structure-env-discovery.ok") -Encoding ASCII
Write-Host "[ OK ] Env set -> $Env"


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Env_Discovery.ps1
param([ValidateSet("dev","prod")]$Env="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
@{ environment = $Env; updated = (Get-Date).ToString("s") } |
  ConvertTo-Json | Set-Content (Join-Path $Cfg "env.json") -Encoding UTF8
"ENV=$Env" | Set-Content (Join-Path $Rep "env.txt") -Encoding ASCII
"ok" | Set-Content (Join-Path $Sig "system-structure-env-discovery.ok") -Encoding ASCII
Write-Host "[ OK ] Env set -> $Env"


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Env_Discovery.ps1
param([ValidateSet("dev","prod")]$Env="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
@{ environment = $Env; updated = (Get-Date).ToString("s") } |
  ConvertTo-Json | Set-Content (Join-Path $Cfg "env.json") -Encoding UTF8
"ENV=$Env" | Set-Content (Join-Path $Rep "env.txt") -Encoding ASCII
"ok" | Set-Content (Join-Path $Sig "system-structure-env-discovery.ok") -Encoding ASCII
Write-Host "[ OK ] Env set -> $Env"


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Env_Discovery.ps1
param([ValidateSet("dev","prod")]$Env="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
@{ environment = $Env; updated = (Get-Date).ToString("s") } |
  ConvertTo-Json | Set-Content (Join-Path $Cfg "env.json") -Encoding UTF8
"ENV=$Env" | Set-Content (Join-Path $Rep "env.txt") -Encoding ASCII
"ok" | Set-Content (Join-Path $Sig "system-structure-env-discovery.ok") -Encoding ASCII
Write-Host "[ OK ] Env set -> $Env"


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Env_Discovery.ps1
param([ValidateSet("dev","prod")]$Env="dev")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
@{ environment = $Env; updated = (Get-Date).ToString("s") } |
  ConvertTo-Json | Set-Content (Join-Path $Cfg "env.json") -Encoding UTF8
"ENV=$Env" | Set-Content (Join-Path $Rep "env.txt") -Encoding ASCII
"ok" | Set-Content (Join-Path $Sig "system-structure-env-discovery.ok") -Encoding ASCII
Write-Host "[ OK ] Env set -> $Env"


