# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Id,[Parameter(Mandatory)][string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$pol  = Get-Content (Join-Path $Cfg "policy.json") -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
if($hash -ne $pol.operator_pin_hash){ throw "Invalid PIN" }
$file = Join-Path $Cfg "approvals.json"
$items = (Get-Content $file -Raw | ConvertFrom-Json)
$hit = $items | Where-Object { $_.id -eq $Id } | Select-Object -First 1
if(-not $hit){ throw "Not found" }
if([string]::IsNullOrWhiteSpace($hit.a2)){ $hit.a2 = $env:USERNAME }
($items) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"APPROVED: $Id"

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Id,[Parameter(Mandatory)][string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$pol  = Get-Content (Join-Path $Cfg "policy.json") -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
if($hash -ne $pol.operator_pin_hash){ throw "Invalid PIN" }
$file = Join-Path $Cfg "approvals.json"
$items = (Get-Content $file -Raw | ConvertFrom-Json)
$hit = $items | Where-Object { $_.id -eq $Id } | Select-Object -First 1
if(-not $hit){ throw "Not found" }
if([string]::IsNullOrWhiteSpace($hit.a2)){ $hit.a2 = $env:USERNAME }
($items) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"APPROVED: $Id"

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Id,[Parameter(Mandatory)][string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$pol  = Get-Content (Join-Path $Cfg "policy.json") -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
if($hash -ne $pol.operator_pin_hash){ throw "Invalid PIN" }
$file = Join-Path $Cfg "approvals.json"
$items = (Get-Content $file -Raw | ConvertFrom-Json)
$hit = $items | Where-Object { $_.id -eq $Id } | Select-Object -First 1
if(-not $hit){ throw "Not found" }
if([string]::IsNullOrWhiteSpace($hit.a2)){ $hit.a2 = $env:USERNAME }
($items) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"APPROVED: $Id"

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Id,[Parameter(Mandatory)][string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$pol  = Get-Content (Join-Path $Cfg "policy.json") -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
if($hash -ne $pol.operator_pin_hash){ throw "Invalid PIN" }
$file = Join-Path $Cfg "approvals.json"
$items = (Get-Content $file -Raw | ConvertFrom-Json)
$hit = $items | Where-Object { $_.id -eq $Id } | Select-Object -First 1
if(-not $hit){ throw "Not found" }
if([string]::IsNullOrWhiteSpace($hit.a2)){ $hit.a2 = $env:USERNAME }
($items) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"APPROVED: $Id"

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Id,[Parameter(Mandatory)][string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$pol  = Get-Content (Join-Path $Cfg "policy.json") -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
if($hash -ne $pol.operator_pin_hash){ throw "Invalid PIN" }
$file = Join-Path $Cfg "approvals.json"
$items = (Get-Content $file -Raw | ConvertFrom-Json)
$hit = $items | Where-Object { $_.id -eq $Id } | Select-Object -First 1
if(-not $hit){ throw "Not found" }
if([string]::IsNullOrWhiteSpace($hit.a2)){ $hit.a2 = $env:USERNAME }
($items) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"APPROVED: $Id"

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Id,[Parameter(Mandatory)][string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$pol  = Get-Content (Join-Path $Cfg "policy.json") -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
if($hash -ne $pol.operator_pin_hash){ throw "Invalid PIN" }
$file = Join-Path $Cfg "approvals.json"
$items = (Get-Content $file -Raw | ConvertFrom-Json)
$hit = $items | Where-Object { $_.id -eq $Id } | Select-Object -First 1
if(-not $hit){ throw "Not found" }
if([string]::IsNullOrWhiteSpace($hit.a2)){ $hit.a2 = $env:USERNAME }
($items) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"APPROVED: $Id"

_tryRoot -Parent) 'lib\Mason.Base.psm1'
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Id,[Parameter(Mandatory)][string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$pol  = Get-Content (Join-Path $Cfg "policy.json") -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
if($hash -ne $pol.operator_pin_hash){ throw "Invalid PIN" }
$file = Join-Path $Cfg "approvals.json"
$items = (Get-Content $file -Raw | ConvertFrom-Json)
$hit = $items | Where-Object { $_.id -eq $Id } | Select-Object -First 1
if(-not $hit){ throw "Not found" }
if([string]::IsNullOrWhiteSpace($hit.a2)){ $hit.a2 = $env:USERNAME }
($items) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"APPROVED: $Id"

_lib -Force
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)

# Mason base/bootstrap (safe; after param)
$__tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($__tryRoot)) {
  try { $__tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { $__tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
$__lib = Join-Path (Split-Path $__tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module $__lib -Force
$MasonBase = Get-MasonBase -FromPath $__tryRoot
Set-Location $MasonBase
$__tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($__tryRoot)) {
  try { $__tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { $__tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
$__lib = Join-Path (Split-Path $__tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module $__lib -Force
][string]$Id,[Parameter(Mandatory)][string]$Pin)
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
$pol  = Get-Content (Join-Path $Cfg "policy.json") -Raw | ConvertFrom-Json
$hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($Pin))).Replace('-','').ToLower()
if($hash -ne $pol.operator_pin_hash){ throw "Invalid PIN" }
$file = Join-Path $Cfg "approvals.json"
$items = (Get-Content $file -Raw | ConvertFrom-Json)
$hit = $items | Where-Object { $_.id -eq $Id } | Select-Object -First 1
if(-not $hit){ throw "Not found" }
if([string]::IsNullOrWhiteSpace($hit.a2)){ $hit.a2 = $env:USERNAME }
($items) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"APPROVED: $Id"

