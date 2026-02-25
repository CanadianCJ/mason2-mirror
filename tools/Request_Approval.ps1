# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Action,[string]$Reason="")
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$file = Join-Path $Cfg "approvals.json"
$items = if(Test-Path $file){ Get-Content $file -Raw | ConvertFrom-Json } else { @() }
$req = [ordered]@{ id=[guid]::NewGuid().ToString("N"); ts=(Get-Date).ToString("o"); action=$Action; reason=$Reason; a1=$env:USERNAME; a2="" }
($items + $req) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"REQUESTED: $($req.id)"

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Action,[string]$Reason="")
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$file = Join-Path $Cfg "approvals.json"
$items = if(Test-Path $file){ Get-Content $file -Raw | ConvertFrom-Json } else { @() }
$req = [ordered]@{ id=[guid]::NewGuid().ToString("N"); ts=(Get-Date).ToString("o"); action=$Action; reason=$Reason; a1=$env:USERNAME; a2="" }
($items + $req) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"REQUESTED: $($req.id)"

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Action,[string]$Reason="")
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$file = Join-Path $Cfg "approvals.json"
$items = if(Test-Path $file){ Get-Content $file -Raw | ConvertFrom-Json } else { @() }
$req = [ordered]@{ id=[guid]::NewGuid().ToString("N"); ts=(Get-Date).ToString("o"); action=$Action; reason=$Reason; a1=$env:USERNAME; a2="" }
($items + $req) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"REQUESTED: $($req.id)"

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Action,[string]$Reason="")
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$file = Join-Path $Cfg "approvals.json"
$items = if(Test-Path $file){ Get-Content $file -Raw | ConvertFrom-Json } else { @() }
$req = [ordered]@{ id=[guid]::NewGuid().ToString("N"); ts=(Get-Date).ToString("o"); action=$Action; reason=$Reason; a1=$env:USERNAME; a2="" }
($items + $req) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"REQUESTED: $($req.id)"

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Action,[string]$Reason="")
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$file = Join-Path $Cfg "approvals.json"
$items = if(Test-Path $file){ Get-Content $file -Raw | ConvertFrom-Json } else { @() }
$req = [ordered]@{ id=[guid]::NewGuid().ToString("N"); ts=(Get-Date).ToString("o"); action=$Action; reason=$Reason; a1=$env:USERNAME; a2="" }
($items + $req) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"REQUESTED: $($req.id)"

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Action,[string]$Reason="")
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$file = Join-Path $Cfg "approvals.json"
$items = if(Test-Path $file){ Get-Content $file -Raw | ConvertFrom-Json } else { @() }
$req = [ordered]@{ id=[guid]::NewGuid().ToString("N"); ts=(Get-Date).ToString("o"); action=$Action; reason=$Reason; a1=$env:USERNAME; a2="" }
($items + $req) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"REQUESTED: $($req.id)"

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Action,[string]$Reason="")
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$file = Join-Path $Cfg "approvals.json"
$items = if(Test-Path $file){ Get-Content $file -Raw | ConvertFrom-Json } else { @() }
$req = [ordered]@{ id=[guid]::NewGuid().ToString("N"); ts=(Get-Date).ToString("o"); action=$Action; reason=$Reason; a1=$env:USERNAME; a2="" }
($items + $req) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"REQUESTED: $($req.id)"

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
param([Parameter(Mandatory)][string]$Action,[string]$Reason="")
$Cfg = Join-Path $env:USERPROFILE "Desktop\Mason2\config"
$file = Join-Path $Cfg "approvals.json"
$items = if(Test-Path $file){ Get-Content $file -Raw | ConvertFrom-Json } else { @() }
$req = [ordered]@{ id=[guid]::NewGuid().ToString("N"); ts=(Get-Date).ToString("o"); action=$Action; reason=$Reason; a1=$env:USERNAME; a2="" }
($items + $req) | ConvertTo-Json -Depth 5 | Set-Content $file -Encoding UTF8
"REQUESTED: $($req.id)"

