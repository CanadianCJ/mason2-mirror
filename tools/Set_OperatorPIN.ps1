# Stamped: 2025-11-05T17:02:01
param([Parameter(Mandatory=$true)][string]$Pin)
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$pol = Join-Path $Cfg "policy.json"
$p = Get-Content $pol -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
$p.operator_pin_hash = $hash
($p | ConvertTo-Json -Depth 5) | Set-Content $pol -Encoding UTF8
"OK: Operator PIN set."

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([Parameter(Mandatory=$true)][string]$Pin)
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$pol = Join-Path $Cfg "policy.json"
$p = Get-Content $pol -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
$p.operator_pin_hash = $hash
($p | ConvertTo-Json -Depth 5) | Set-Content $pol -Encoding UTF8
"OK: Operator PIN set."

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([Parameter(Mandatory=$true)][string]$Pin)
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$pol = Join-Path $Cfg "policy.json"
$p = Get-Content $pol -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
$p.operator_pin_hash = $hash
($p | ConvertTo-Json -Depth 5) | Set-Content $pol -Encoding UTF8
"OK: Operator PIN set."

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([Parameter(Mandatory=$true)][string]$Pin)
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$pol = Join-Path $Cfg "policy.json"
$p = Get-Content $pol -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
$p.operator_pin_hash = $hash
($p | ConvertTo-Json -Depth 5) | Set-Content $pol -Encoding UTF8
"OK: Operator PIN set."

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([Parameter(Mandatory=$true)][string]$Pin)
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$pol = Join-Path $Cfg "policy.json"
$p = Get-Content $pol -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
$p.operator_pin_hash = $hash
($p | ConvertTo-Json -Depth 5) | Set-Content $pol -Encoding UTF8
"OK: Operator PIN set."

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([Parameter(Mandatory=$true)][string]$Pin)
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$pol = Join-Path $Cfg "policy.json"
$p = Get-Content $pol -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
$p.operator_pin_hash = $hash
($p | ConvertTo-Json -Depth 5) | Set-Content $pol -Encoding UTF8
"OK: Operator PIN set."

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([Parameter(Mandatory=$true)][string]$Pin)
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$pol = Join-Path $Cfg "policy.json"
$p = Get-Content $pol -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
$p.operator_pin_hash = $hash
($p | ConvertTo-Json -Depth 5) | Set-Content $pol -Encoding UTF8
"OK: Operator PIN set."

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([Parameter(Mandatory=$true)][string]$Pin)
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$pol = Join-Path $Cfg "policy.json"
$p = Get-Content $pol -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
$p.operator_pin_hash = $hash
($p | ConvertTo-Json -Depth 5) | Set-Content $pol -Encoding UTF8
"OK: Operator PIN set."

