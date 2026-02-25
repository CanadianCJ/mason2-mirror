$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$prof=@{}
try{
  Get-NetFirewallProfile -ErrorAction SilentlyContinue | ForEach-Object {
    $prof[$_.Name] = [pscustomobject]@{
      Enabled=$_.Enabled; DefaultInbound=$_.DefaultInboundAction; DefaultOutbound=$_.DefaultOutboundAction
    }
  }
}catch{}
$rules=@{ allow=0; block=0 }
try{
  $all = Get-NetFirewallRule -ErrorAction SilentlyContinue
  if($all){
    $rules.allow = ($all | Where-Object { $_.Action -eq 'Allow' } | Measure-Object).Count
    $rules.block = ($all | Where-Object { $_.Action -eq 'Block' } | Measure-Object).Count
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\firewall.jsonl') -Obj @{ ts=$now.ToString('s'); kind='firewall'; profiles=$prof; rules=$rules }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$prof=@{}
try{
  Get-NetFirewallProfile -ErrorAction SilentlyContinue | ForEach-Object {
    $prof[$_.Name] = [pscustomobject]@{
      Enabled=$_.Enabled; DefaultInbound=$_.DefaultInboundAction; DefaultOutbound=$_.DefaultOutboundAction
    }
  }
}catch{}
$rules=@{ allow=0; block=0 }
try{
  $all = Get-NetFirewallRule -ErrorAction SilentlyContinue
  if($all){
    $rules.allow = ($all | Where-Object { $_.Action -eq 'Allow' } | Measure-Object).Count
    $rules.block = ($all | Where-Object { $_.Action -eq 'Block' } | Measure-Object).Count
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\firewall.jsonl') -Obj @{ ts=$now.ToString('s'); kind='firewall'; profiles=$prof; rules=$rules }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$prof=@{}
try{
  Get-NetFirewallProfile -ErrorAction SilentlyContinue | ForEach-Object {
    $prof[$_.Name] = [pscustomobject]@{
      Enabled=$_.Enabled; DefaultInbound=$_.DefaultInboundAction; DefaultOutbound=$_.DefaultOutboundAction
    }
  }
}catch{}
$rules=@{ allow=0; block=0 }
try{
  $all = Get-NetFirewallRule -ErrorAction SilentlyContinue
  if($all){
    $rules.allow = ($all | Where-Object { $_.Action -eq 'Allow' } | Measure-Object).Count
    $rules.block = ($all | Where-Object { $_.Action -eq 'Block' } | Measure-Object).Count
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\firewall.jsonl') -Obj @{ ts=$now.ToString('s'); kind='firewall'; profiles=$prof; rules=$rules }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$prof=@{}
try{
  Get-NetFirewallProfile -ErrorAction SilentlyContinue | ForEach-Object {
    $prof[$_.Name] = [pscustomobject]@{
      Enabled=$_.Enabled; DefaultInbound=$_.DefaultInboundAction; DefaultOutbound=$_.DefaultOutboundAction
    }
  }
}catch{}
$rules=@{ allow=0; block=0 }
try{
  $all = Get-NetFirewallRule -ErrorAction SilentlyContinue
  if($all){
    $rules.allow = ($all | Where-Object { $_.Action -eq 'Allow' } | Measure-Object).Count
    $rules.block = ($all | Where-Object { $_.Action -eq 'Block' } | Measure-Object).Count
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\firewall.jsonl') -Obj @{ ts=$now.ToString('s'); kind='firewall'; profiles=$prof; rules=$rules }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$prof=@{}
try{
  Get-NetFirewallProfile -ErrorAction SilentlyContinue | ForEach-Object {
    $prof[$_.Name] = [pscustomobject]@{
      Enabled=$_.Enabled; DefaultInbound=$_.DefaultInboundAction; DefaultOutbound=$_.DefaultOutboundAction
    }
  }
}catch{}
$rules=@{ allow=0; block=0 }
try{
  $all = Get-NetFirewallRule -ErrorAction SilentlyContinue
  if($all){
    $rules.allow = ($all | Where-Object { $_.Action -eq 'Allow' } | Measure-Object).Count
    $rules.block = ($all | Where-Object { $_.Action -eq 'Block' } | Measure-Object).Count
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\firewall.jsonl') -Obj @{ ts=$now.ToString('s'); kind='firewall'; profiles=$prof; rules=$rules }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$prof=@{}
try{
  Get-NetFirewallProfile -ErrorAction SilentlyContinue | ForEach-Object {
    $prof[$_.Name] = [pscustomobject]@{
      Enabled=$_.Enabled; DefaultInbound=$_.DefaultInboundAction; DefaultOutbound=$_.DefaultOutboundAction
    }
  }
}catch{}
$rules=@{ allow=0; block=0 }
try{
  $all = Get-NetFirewallRule -ErrorAction SilentlyContinue
  if($all){
    $rules.allow = ($all | Where-Object { $_.Action -eq 'Allow' } | Measure-Object).Count
    $rules.block = ($all | Where-Object { $_.Action -eq 'Block' } | Measure-Object).Count
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\firewall.jsonl') -Obj @{ ts=$now.ToString('s'); kind='firewall'; profiles=$prof; rules=$rules }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$prof=@{}
try{
  Get-NetFirewallProfile -ErrorAction SilentlyContinue | ForEach-Object {
    $prof[$_.Name] = [pscustomobject]@{
      Enabled=$_.Enabled; DefaultInbound=$_.DefaultInboundAction; DefaultOutbound=$_.DefaultOutboundAction
    }
  }
}catch{}
$rules=@{ allow=0; block=0 }
try{
  $all = Get-NetFirewallRule -ErrorAction SilentlyContinue
  if($all){
    $rules.allow = ($all | Where-Object { $_.Action -eq 'Allow' } | Measure-Object).Count
    $rules.block = ($all | Where-Object { $_.Action -eq 'Block' } | Measure-Object).Count
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\firewall.jsonl') -Obj @{ ts=$now.ToString('s'); kind='firewall'; profiles=$prof; rules=$rules }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$prof=@{}
try{
  Get-NetFirewallProfile -ErrorAction SilentlyContinue | ForEach-Object {
    $prof[$_.Name] = [pscustomobject]@{
      Enabled=$_.Enabled; DefaultInbound=$_.DefaultInboundAction; DefaultOutbound=$_.DefaultOutboundAction
    }
  }
}catch{}
$rules=@{ allow=0; block=0 }
try{
  $all = Get-NetFirewallRule -ErrorAction SilentlyContinue
  if($all){
    $rules.allow = ($all | Where-Object { $_.Action -eq 'Allow' } | Measure-Object).Count
    $rules.block = ($all | Where-Object { $_.Action -eq 'Block' } | Measure-Object).Count
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\firewall.jsonl') -Obj @{ ts=$now.ToString('s'); kind='firewall'; profiles=$prof; rules=$rules }
