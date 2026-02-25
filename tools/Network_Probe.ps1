# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$dnsOK=$false; $gwOK=$false; $loopOK=$false
try{ Resolve-DnsName localhost -ErrorAction Stop | Out-Null; $dnsOK=$true }catch{}
try{ Test-Connection 127.0.0.1 -Count 1 -Quiet -ErrorAction SilentlyContinue | Out-Null; $loopOK=$true }catch{}
try{ $gwOK = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue) -ne $null }catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_probe.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_probe'; dns=$dnsOK; gateway=$gwOK; loop=$loopOK }

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$dnsOK=$false; $gwOK=$false; $loopOK=$false
try{ Resolve-DnsName localhost -ErrorAction Stop | Out-Null; $dnsOK=$true }catch{}
try{ Test-Connection 127.0.0.1 -Count 1 -Quiet -ErrorAction SilentlyContinue | Out-Null; $loopOK=$true }catch{}
try{ $gwOK = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue) -ne $null }catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_probe.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_probe'; dns=$dnsOK; gateway=$gwOK; loop=$loopOK }

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$dnsOK=$false; $gwOK=$false; $loopOK=$false
try{ Resolve-DnsName localhost -ErrorAction Stop | Out-Null; $dnsOK=$true }catch{}
try{ Test-Connection 127.0.0.1 -Count 1 -Quiet -ErrorAction SilentlyContinue | Out-Null; $loopOK=$true }catch{}
try{ $gwOK = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue) -ne $null }catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_probe.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_probe'; dns=$dnsOK; gateway=$gwOK; loop=$loopOK }

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$dnsOK=$false; $gwOK=$false; $loopOK=$false
try{ Resolve-DnsName localhost -ErrorAction Stop | Out-Null; $dnsOK=$true }catch{}
try{ Test-Connection 127.0.0.1 -Count 1 -Quiet -ErrorAction SilentlyContinue | Out-Null; $loopOK=$true }catch{}
try{ $gwOK = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue) -ne $null }catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_probe.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_probe'; dns=$dnsOK; gateway=$gwOK; loop=$loopOK }

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$dnsOK=$false; $gwOK=$false; $loopOK=$false
try{ Resolve-DnsName localhost -ErrorAction Stop | Out-Null; $dnsOK=$true }catch{}
try{ Test-Connection 127.0.0.1 -Count 1 -Quiet -ErrorAction SilentlyContinue | Out-Null; $loopOK=$true }catch{}
try{ $gwOK = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue) -ne $null }catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_probe.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_probe'; dns=$dnsOK; gateway=$gwOK; loop=$loopOK }

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$dnsOK=$false; $gwOK=$false; $loopOK=$false
try{ Resolve-DnsName localhost -ErrorAction Stop | Out-Null; $dnsOK=$true }catch{}
try{ Test-Connection 127.0.0.1 -Count 1 -Quiet -ErrorAction SilentlyContinue | Out-Null; $loopOK=$true }catch{}
try{ $gwOK = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue) -ne $null }catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_probe.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_probe'; dns=$dnsOK; gateway=$gwOK; loop=$loopOK }

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$dnsOK=$false; $gwOK=$false; $loopOK=$false
try{ Resolve-DnsName localhost -ErrorAction Stop | Out-Null; $dnsOK=$true }catch{}
try{ Test-Connection 127.0.0.1 -Count 1 -Quiet -ErrorAction SilentlyContinue | Out-Null; $loopOK=$true }catch{}
try{ $gwOK = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue) -ne $null }catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_probe.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_probe'; dns=$dnsOK; gateway=$gwOK; loop=$loopOK }

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$dnsOK=$false; $gwOK=$false; $loopOK=$false
try{ Resolve-DnsName localhost -ErrorAction Stop | Out-Null; $dnsOK=$true }catch{}
try{ Test-Connection 127.0.0.1 -Count 1 -Quiet -ErrorAction SilentlyContinue | Out-Null; $loopOK=$true }catch{}
try{ $gwOK = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue) -ne $null }catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\net_probe.jsonl') -Obj @{ ts=$now.ToString('s'); kind='net_probe'; dns=$dnsOK; gateway=$gwOK; loop=$loopOK }

