$ErrorActionPreference='Stop'
$zip = Join-Path $Base ("dist\qa\QA_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip")
$items = @(
  (Join-Path $Base 'config\*'),
  (Join-Path $Base 'reports\*.jsonl'),
  (Join-Path $Base 'reports\status_summary.md'),
  (Join-Path $Base 'reports\changelog.md')
) | Where-Object { Test-Path $_ }
if(Test-Path $zip){ Remove-Item $zip -Force }
Compress-Archive -Path $items -DestinationPath $zip -Force
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$zip = Join-Path $Base ("dist\qa\QA_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip")
$items = @(
  (Join-Path $Base 'config\*'),
  (Join-Path $Base 'reports\*.jsonl'),
  (Join-Path $Base 'reports\status_summary.md'),
  (Join-Path $Base 'reports\changelog.md')
) | Where-Object { Test-Path $_ }
if(Test-Path $zip){ Remove-Item $zip -Force }
Compress-Archive -Path $items -DestinationPath $zip -Force
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$zip = Join-Path $Base ("dist\qa\QA_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip")
$items = @(
  (Join-Path $Base 'config\*'),
  (Join-Path $Base 'reports\*.jsonl'),
  (Join-Path $Base 'reports\status_summary.md'),
  (Join-Path $Base 'reports\changelog.md')
) | Where-Object { Test-Path $_ }
if(Test-Path $zip){ Remove-Item $zip -Force }
Compress-Archive -Path $items -DestinationPath $zip -Force
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$zip = Join-Path $Base ("dist\qa\QA_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip")
$items = @(
  (Join-Path $Base 'config\*'),
  (Join-Path $Base 'reports\*.jsonl'),
  (Join-Path $Base 'reports\status_summary.md'),
  (Join-Path $Base 'reports\changelog.md')
) | Where-Object { Test-Path $_ }
if(Test-Path $zip){ Remove-Item $zip -Force }
Compress-Archive -Path $items -DestinationPath $zip -Force
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$zip = Join-Path $Base ("dist\qa\QA_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip")
$items = @(
  (Join-Path $Base 'config\*'),
  (Join-Path $Base 'reports\*.jsonl'),
  (Join-Path $Base 'reports\status_summary.md'),
  (Join-Path $Base 'reports\changelog.md')
) | Where-Object { Test-Path $_ }
if(Test-Path $zip){ Remove-Item $zip -Force }
Compress-Archive -Path $items -DestinationPath $zip -Force
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$zip = Join-Path $Base ("dist\qa\QA_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip")
$items = @(
  (Join-Path $Base 'config\*'),
  (Join-Path $Base 'reports\*.jsonl'),
  (Join-Path $Base 'reports\status_summary.md'),
  (Join-Path $Base 'reports\changelog.md')
) | Where-Object { Test-Path $_ }
if(Test-Path $zip){ Remove-Item $zip -Force }
Compress-Archive -Path $items -DestinationPath $zip -Force
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$zip = Join-Path $Base ("dist\qa\QA_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip")
$items = @(
  (Join-Path $Base 'config\*'),
  (Join-Path $Base 'reports\*.jsonl'),
  (Join-Path $Base 'reports\status_summary.md'),
  (Join-Path $Base 'reports\changelog.md')
) | Where-Object { Test-Path $_ }
if(Test-Path $zip){ Remove-Item $zip -Force }
Compress-Archive -Path $items -DestinationPath $zip -Force
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
$zip = Join-Path $Base ("dist\qa\QA_" + (Get-Date).ToString("yyyyMMdd_HHmmss") + ".zip")
$items = @(
  (Join-Path $Base 'config\*'),
  (Join-Path $Base 'reports\*.jsonl'),
  (Join-Path $Base 'reports\status_summary.md'),
  (Join-Path $Base 'reports\changelog.md')
) | Where-Object { Test-Path $_ }
if(Test-Path $zip){ Remove-Item $zip -Force }
Compress-Archive -Path $items -DestinationPath $zip -Force
