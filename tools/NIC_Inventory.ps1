$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$rows=@()
try{
  $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
  foreach($a in $adapters){
    $ip = (Get-NetIPConfiguration -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue)
    $dns = $null
    try{ $dns = (Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue).ServerAddresses }catch{}
    $rows += [pscustomobject]@{
      name=$a.Name; status=$a.Status.ToString(); mac=$a.MacAddress; linkspeed=$a.LinkSpeed
      ipv4=($ip.IPv4Address | ForEach-Object { $_.IPv4Address }); gateway=($ip.IPv4DefaultGateway.NextHop)
      dns=$dns
    }
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\nic_inventory.jsonl') -Obj @{ ts=$now.ToString('s'); kind='nic_inventory'; items=$rows }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$rows=@()
try{
  $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
  foreach($a in $adapters){
    $ip = (Get-NetIPConfiguration -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue)
    $dns = $null
    try{ $dns = (Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue).ServerAddresses }catch{}
    $rows += [pscustomobject]@{
      name=$a.Name; status=$a.Status.ToString(); mac=$a.MacAddress; linkspeed=$a.LinkSpeed
      ipv4=($ip.IPv4Address | ForEach-Object { $_.IPv4Address }); gateway=($ip.IPv4DefaultGateway.NextHop)
      dns=$dns
    }
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\nic_inventory.jsonl') -Obj @{ ts=$now.ToString('s'); kind='nic_inventory'; items=$rows }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$rows=@()
try{
  $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
  foreach($a in $adapters){
    $ip = (Get-NetIPConfiguration -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue)
    $dns = $null
    try{ $dns = (Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue).ServerAddresses }catch{}
    $rows += [pscustomobject]@{
      name=$a.Name; status=$a.Status.ToString(); mac=$a.MacAddress; linkspeed=$a.LinkSpeed
      ipv4=($ip.IPv4Address | ForEach-Object { $_.IPv4Address }); gateway=($ip.IPv4DefaultGateway.NextHop)
      dns=$dns
    }
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\nic_inventory.jsonl') -Obj @{ ts=$now.ToString('s'); kind='nic_inventory'; items=$rows }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$rows=@()
try{
  $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
  foreach($a in $adapters){
    $ip = (Get-NetIPConfiguration -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue)
    $dns = $null
    try{ $dns = (Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue).ServerAddresses }catch{}
    $rows += [pscustomobject]@{
      name=$a.Name; status=$a.Status.ToString(); mac=$a.MacAddress; linkspeed=$a.LinkSpeed
      ipv4=($ip.IPv4Address | ForEach-Object { $_.IPv4Address }); gateway=($ip.IPv4DefaultGateway.NextHop)
      dns=$dns
    }
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\nic_inventory.jsonl') -Obj @{ ts=$now.ToString('s'); kind='nic_inventory'; items=$rows }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$rows=@()
try{
  $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
  foreach($a in $adapters){
    $ip = (Get-NetIPConfiguration -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue)
    $dns = $null
    try{ $dns = (Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue).ServerAddresses }catch{}
    $rows += [pscustomobject]@{
      name=$a.Name; status=$a.Status.ToString(); mac=$a.MacAddress; linkspeed=$a.LinkSpeed
      ipv4=($ip.IPv4Address | ForEach-Object { $_.IPv4Address }); gateway=($ip.IPv4DefaultGateway.NextHop)
      dns=$dns
    }
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\nic_inventory.jsonl') -Obj @{ ts=$now.ToString('s'); kind='nic_inventory'; items=$rows }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$rows=@()
try{
  $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
  foreach($a in $adapters){
    $ip = (Get-NetIPConfiguration -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue)
    $dns = $null
    try{ $dns = (Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue).ServerAddresses }catch{}
    $rows += [pscustomobject]@{
      name=$a.Name; status=$a.Status.ToString(); mac=$a.MacAddress; linkspeed=$a.LinkSpeed
      ipv4=($ip.IPv4Address | ForEach-Object { $_.IPv4Address }); gateway=($ip.IPv4DefaultGateway.NextHop)
      dns=$dns
    }
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\nic_inventory.jsonl') -Obj @{ ts=$now.ToString('s'); kind='nic_inventory'; items=$rows }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$rows=@()
try{
  $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
  foreach($a in $adapters){
    $ip = (Get-NetIPConfiguration -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue)
    $dns = $null
    try{ $dns = (Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue).ServerAddresses }catch{}
    $rows += [pscustomobject]@{
      name=$a.Name; status=$a.Status.ToString(); mac=$a.MacAddress; linkspeed=$a.LinkSpeed
      ipv4=($ip.IPv4Address | ForEach-Object { $_.IPv4Address }); gateway=($ip.IPv4DefaultGateway.NextHop)
      dns=$dns
    }
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\nic_inventory.jsonl') -Obj @{ ts=$now.ToString('s'); kind='nic_inventory'; items=$rows }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date
$rows=@()
try{
  $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
  foreach($a in $adapters){
    $ip = (Get-NetIPConfiguration -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue)
    $dns = $null
    try{ $dns = (Get-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue).ServerAddresses }catch{}
    $rows += [pscustomobject]@{
      name=$a.Name; status=$a.Status.ToString(); mac=$a.MacAddress; linkspeed=$a.LinkSpeed
      ipv4=($ip.IPv4Address | ForEach-Object { $_.IPv4Address }); gateway=($ip.IPv4DefaultGateway.NextHop)
      dns=$dns
    }
  }
}catch{}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\nic_inventory.jsonl') -Obj @{ ts=$now.ToString('s'); kind='nic_inventory'; items=$rows }
