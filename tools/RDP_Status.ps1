$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$svc=$null; $deny=$null; $fwAllow=$null
try{ $svc = (Get-Service -Name TermService -ErrorAction SilentlyContinue).Status.ToString() }catch{}
try{
  $rk='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
  if(Test-Path $rk){ $deny = (Get-ItemProperty -Path $rk -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections }
}catch{}
try{
  $fwAllow = (Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True -Direction Inbound -Action Allow -ErrorAction SilentlyContinue | Measure-Object).Count
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\rdp_status.jsonl') -Obj @{ ts=$now.ToString('s'); kind='rdp_status'; service=$svc; deny_ts=$deny; fw_rules_allow=$fwAllow }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$svc=$null; $deny=$null; $fwAllow=$null
try{ $svc = (Get-Service -Name TermService -ErrorAction SilentlyContinue).Status.ToString() }catch{}
try{
  $rk='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
  if(Test-Path $rk){ $deny = (Get-ItemProperty -Path $rk -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections }
}catch{}
try{
  $fwAllow = (Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True -Direction Inbound -Action Allow -ErrorAction SilentlyContinue | Measure-Object).Count
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\rdp_status.jsonl') -Obj @{ ts=$now.ToString('s'); kind='rdp_status'; service=$svc; deny_ts=$deny; fw_rules_allow=$fwAllow }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$svc=$null; $deny=$null; $fwAllow=$null
try{ $svc = (Get-Service -Name TermService -ErrorAction SilentlyContinue).Status.ToString() }catch{}
try{
  $rk='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
  if(Test-Path $rk){ $deny = (Get-ItemProperty -Path $rk -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections }
}catch{}
try{
  $fwAllow = (Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True -Direction Inbound -Action Allow -ErrorAction SilentlyContinue | Measure-Object).Count
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\rdp_status.jsonl') -Obj @{ ts=$now.ToString('s'); kind='rdp_status'; service=$svc; deny_ts=$deny; fw_rules_allow=$fwAllow }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$svc=$null; $deny=$null; $fwAllow=$null
try{ $svc = (Get-Service -Name TermService -ErrorAction SilentlyContinue).Status.ToString() }catch{}
try{
  $rk='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
  if(Test-Path $rk){ $deny = (Get-ItemProperty -Path $rk -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections }
}catch{}
try{
  $fwAllow = (Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True -Direction Inbound -Action Allow -ErrorAction SilentlyContinue | Measure-Object).Count
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\rdp_status.jsonl') -Obj @{ ts=$now.ToString('s'); kind='rdp_status'; service=$svc; deny_ts=$deny; fw_rules_allow=$fwAllow }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$svc=$null; $deny=$null; $fwAllow=$null
try{ $svc = (Get-Service -Name TermService -ErrorAction SilentlyContinue).Status.ToString() }catch{}
try{
  $rk='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
  if(Test-Path $rk){ $deny = (Get-ItemProperty -Path $rk -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections }
}catch{}
try{
  $fwAllow = (Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True -Direction Inbound -Action Allow -ErrorAction SilentlyContinue | Measure-Object).Count
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\rdp_status.jsonl') -Obj @{ ts=$now.ToString('s'); kind='rdp_status'; service=$svc; deny_ts=$deny; fw_rules_allow=$fwAllow }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$svc=$null; $deny=$null; $fwAllow=$null
try{ $svc = (Get-Service -Name TermService -ErrorAction SilentlyContinue).Status.ToString() }catch{}
try{
  $rk='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
  if(Test-Path $rk){ $deny = (Get-ItemProperty -Path $rk -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections }
}catch{}
try{
  $fwAllow = (Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True -Direction Inbound -Action Allow -ErrorAction SilentlyContinue | Measure-Object).Count
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\rdp_status.jsonl') -Obj @{ ts=$now.ToString('s'); kind='rdp_status'; service=$svc; deny_ts=$deny; fw_rules_allow=$fwAllow }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$svc=$null; $deny=$null; $fwAllow=$null
try{ $svc = (Get-Service -Name TermService -ErrorAction SilentlyContinue).Status.ToString() }catch{}
try{
  $rk='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
  if(Test-Path $rk){ $deny = (Get-ItemProperty -Path $rk -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections }
}catch{}
try{
  $fwAllow = (Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True -Direction Inbound -Action Allow -ErrorAction SilentlyContinue | Measure-Object).Count
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\rdp_status.jsonl') -Obj @{ ts=$now.ToString('s'); kind='rdp_status'; service=$svc; deny_ts=$deny; fw_rules_allow=$fwAllow }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$svc=$null; $deny=$null; $fwAllow=$null
try{ $svc = (Get-Service -Name TermService -ErrorAction SilentlyContinue).Status.ToString() }catch{}
try{
  $rk='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
  if(Test-Path $rk){ $deny = (Get-ItemProperty -Path $rk -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections }
}catch{}
try{
  $fwAllow = (Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True -Direction Inbound -Action Allow -ErrorAction SilentlyContinue | Measure-Object).Count
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\rdp_status.jsonl') -Obj @{ ts=$now.ToString('s'); kind='rdp_status'; service=$svc; deny_ts=$deny; fw_rules_allow=$fwAllow }
