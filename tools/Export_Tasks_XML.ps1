$ErrorActionPreference='Stop'
$dir = Join-Path $Base 'config\tasks_xml'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try {
    $out = Join-Path $dir ($_.TaskName + '.xml')
    Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath $out -Encoding UTF8
  } catch {}
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$dir = Join-Path $Base 'config\tasks_xml'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try {
    $out = Join-Path $dir ($_.TaskName + '.xml')
    Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath $out -Encoding UTF8
  } catch {}
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$dir = Join-Path $Base 'config\tasks_xml'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try {
    $out = Join-Path $dir ($_.TaskName + '.xml')
    Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath $out -Encoding UTF8
  } catch {}
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$dir = Join-Path $Base 'config\tasks_xml'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try {
    $out = Join-Path $dir ($_.TaskName + '.xml')
    Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath $out -Encoding UTF8
  } catch {}
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$dir = Join-Path $Base 'config\tasks_xml'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try {
    $out = Join-Path $dir ($_.TaskName + '.xml')
    Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath $out -Encoding UTF8
  } catch {}
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$dir = Join-Path $Base 'config\tasks_xml'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try {
    $out = Join-Path $dir ($_.TaskName + '.xml')
    Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath $out -Encoding UTF8
  } catch {}
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$dir = Join-Path $Base 'config\tasks_xml'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try {
    $out = Join-Path $dir ($_.TaskName + '.xml')
    Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath $out -Encoding UTF8
  } catch {}
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
$dir = Join-Path $Base 'config\tasks_xml'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
  try {
    $out = Join-Path $dir ($_.TaskName + '.xml')
    Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath $out -Encoding UTF8
  } catch {}
}
