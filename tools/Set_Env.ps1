# Stamped: 2025-11-05T17:02:01
param([ValidateSet("dev","prod")][string]$Env = "dev",[string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgP=Join-Path $Base 'config\mason2.config.json'
if(!(Test-Path $cfgP)){ throw "config not found: $cfgP" }
$cfg=Get-Content $cfgP -Raw | ConvertFrom-Json
$old=$cfg.Env; $cfg.Env=$Env
$cfg | ConvertTo-Json -Depth 6 | Out-File -FilePath $cfgP -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_changes.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='env_toggle'; from=$old; to=$Env }
Write-Host "Env set to $Env"

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([ValidateSet("dev","prod")][string]$Env = "dev",[string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgP=Join-Path $Base 'config\mason2.config.json'
if(!(Test-Path $cfgP)){ throw "config not found: $cfgP" }
$cfg=Get-Content $cfgP -Raw | ConvertFrom-Json
$old=$cfg.Env; $cfg.Env=$Env
$cfg | ConvertTo-Json -Depth 6 | Out-File -FilePath $cfgP -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_changes.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='env_toggle'; from=$old; to=$Env }
Write-Host "Env set to $Env"

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([ValidateSet("dev","prod")][string]$Env = "dev",[string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgP=Join-Path $Base 'config\mason2.config.json'
if(!(Test-Path $cfgP)){ throw "config not found: $cfgP" }
$cfg=Get-Content $cfgP -Raw | ConvertFrom-Json
$old=$cfg.Env; $cfg.Env=$Env
$cfg | ConvertTo-Json -Depth 6 | Out-File -FilePath $cfgP -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_changes.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='env_toggle'; from=$old; to=$Env }
Write-Host "Env set to $Env"

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([ValidateSet("dev","prod")][string]$Env = "dev",[string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgP=Join-Path $Base 'config\mason2.config.json'
if(!(Test-Path $cfgP)){ throw "config not found: $cfgP" }
$cfg=Get-Content $cfgP -Raw | ConvertFrom-Json
$old=$cfg.Env; $cfg.Env=$Env
$cfg | ConvertTo-Json -Depth 6 | Out-File -FilePath $cfgP -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_changes.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='env_toggle'; from=$old; to=$Env }
Write-Host "Env set to $Env"

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([ValidateSet("dev","prod")][string]$Env = "dev",[string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgP=Join-Path $Base 'config\mason2.config.json'
if(!(Test-Path $cfgP)){ throw "config not found: $cfgP" }
$cfg=Get-Content $cfgP -Raw | ConvertFrom-Json
$old=$cfg.Env; $cfg.Env=$Env
$cfg | ConvertTo-Json -Depth 6 | Out-File -FilePath $cfgP -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_changes.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='env_toggle'; from=$old; to=$Env }
Write-Host "Env set to $Env"

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([ValidateSet("dev","prod")][string]$Env = "dev",[string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgP=Join-Path $Base 'config\mason2.config.json'
if(!(Test-Path $cfgP)){ throw "config not found: $cfgP" }
$cfg=Get-Content $cfgP -Raw | ConvertFrom-Json
$old=$cfg.Env; $cfg.Env=$Env
$cfg | ConvertTo-Json -Depth 6 | Out-File -FilePath $cfgP -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_changes.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='env_toggle'; from=$old; to=$Env }
Write-Host "Env set to $Env"

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([ValidateSet("dev","prod")][string]$Env = "dev",[string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgP=Join-Path $Base 'config\mason2.config.json'
if(!(Test-Path $cfgP)){ throw "config not found: $cfgP" }
$cfg=Get-Content $cfgP -Raw | ConvertFrom-Json
$old=$cfg.Env; $cfg.Env=$Env
$cfg | ConvertTo-Json -Depth 6 | Out-File -FilePath $cfgP -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_changes.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='env_toggle'; from=$old; to=$Env }
Write-Host "Env set to $Env"

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([ValidateSet("dev","prod")][string]$Env = "dev",[string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgP=Join-Path $Base 'config\mason2.config.json'
if(!(Test-Path $cfgP)){ throw "config not found: $cfgP" }
$cfg=Get-Content $cfgP -Raw | ConvertFrom-Json
$old=$cfg.Env; $cfg.Env=$Env
$cfg | ConvertTo-Json -Depth 6 | Out-File -FilePath $cfgP -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_changes.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='env_toggle'; from=$old; to=$Env }
Write-Host "Env set to $Env"

