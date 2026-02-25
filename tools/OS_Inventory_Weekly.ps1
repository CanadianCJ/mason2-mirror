$now=Get-Date
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $hotfixN = (Get-HotFix -ErrorAction SilentlyContinue | Measure-Object).Count
  $obj = @{
    ts=$now.ToString('s'); kind='os_inventory';
    caption=$os.Caption; version=$os.Version; build=$os.BuildNumber;
    last_boot=$os.LastBootUpTime; hotfix_count=$hotfixN; csname=$os.CSName
  }
  ($obj | ConvertTo-Json -Depth 6) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\os_inventory.jsonl"
} catch {}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference='Stop'
$now=Get-Date
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $hotfixN = (Get-HotFix -ErrorAction SilentlyContinue | Measure-Object).Count
  $obj = @{
    ts=$now.ToString('s'); kind='os_inventory';
    caption=$os.Caption; version=$os.Version; build=$os.BuildNumber;
    last_boot=$os.LastBootUpTime; hotfix_count=$hotfixN; csname=$os.CSName
  }
  ($obj | ConvertTo-Json -Depth 6) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\os_inventory.jsonl"
} catch {}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference='Stop'
$now=Get-Date
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $hotfixN = (Get-HotFix -ErrorAction SilentlyContinue | Measure-Object).Count
  $obj = @{
    ts=$now.ToString('s'); kind='os_inventory';
    caption=$os.Caption; version=$os.Version; build=$os.BuildNumber;
    last_boot=$os.LastBootUpTime; hotfix_count=$hotfixN; csname=$os.CSName
  }
  ($obj | ConvertTo-Json -Depth 6) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\os_inventory.jsonl"
} catch {}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference='Stop'
$now=Get-Date
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $hotfixN = (Get-HotFix -ErrorAction SilentlyContinue | Measure-Object).Count
  $obj = @{
    ts=$now.ToString('s'); kind='os_inventory';
    caption=$os.Caption; version=$os.Version; build=$os.BuildNumber;
    last_boot=$os.LastBootUpTime; hotfix_count=$hotfixN; csname=$os.CSName
  }
  ($obj | ConvertTo-Json -Depth 6) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\os_inventory.jsonl"
} catch {}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference='Stop'
$now=Get-Date
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $hotfixN = (Get-HotFix -ErrorAction SilentlyContinue | Measure-Object).Count
  $obj = @{
    ts=$now.ToString('s'); kind='os_inventory';
    caption=$os.Caption; version=$os.Version; build=$os.BuildNumber;
    last_boot=$os.LastBootUpTime; hotfix_count=$hotfixN; csname=$os.CSName
  }
  ($obj | ConvertTo-Json -Depth 6) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\os_inventory.jsonl"
} catch {}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference='Stop'
$now=Get-Date
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $hotfixN = (Get-HotFix -ErrorAction SilentlyContinue | Measure-Object).Count
  $obj = @{
    ts=$now.ToString('s'); kind='os_inventory';
    caption=$os.Caption; version=$os.Version; build=$os.BuildNumber;
    last_boot=$os.LastBootUpTime; hotfix_count=$hotfixN; csname=$os.CSName
  }
  ($obj | ConvertTo-Json -Depth 6) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\os_inventory.jsonl"
} catch {}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase$ErrorActionPreference='Stop'
$now=Get-Date
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $hotfixN = (Get-HotFix -ErrorAction SilentlyContinue | Measure-Object).Count
  $obj = @{
    ts=$now.ToString('s'); kind='os_inventory';
    caption=$os.Caption; version=$os.Version; build=$os.BuildNumber;
    last_boot=$os.LastBootUpTime; hotfix_count=$hotfixN; csname=$os.CSName
  }
  ($obj | ConvertTo-Json -Depth 6) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\os_inventory.jsonl"
} catch {}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$now=Get-Date
try {
  $os = Get-CimInstance Win32_OperatingSystem
  $hotfixN = (Get-HotFix -ErrorAction SilentlyContinue | Measure-Object).Count
  $obj = @{
    ts=$now.ToString('s'); kind='os_inventory';
    caption=$os.Caption; version=$os.Version; build=$os.BuildNumber;
    last_boot=$os.LastBootUpTime; hotfix_count=$hotfixN; csname=$os.CSName
  }
  ($obj | ConvertTo-Json -Depth 6) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\os_inventory.jsonl"
} catch {}
