$ErrorActionPreference='Stop'
$cl = Join-Path $Base 'reports\changelog.md'
$rn = Join-Path $Base 'reports\release_notes.md'
$today = (Get-Date).ToString("yyyy-MM-dd")
$lines = @("# Release Notes - $today","","Changes","--------")
if(Test-Path $cl){ $lines += (Get-Content $cl -Tail 50) }
$lines -join "`r`n" | Out-File -FilePath $rn -Encoding UTF8
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cl = Join-Path $Base 'reports\changelog.md'
$rn = Join-Path $Base 'reports\release_notes.md'
$today = (Get-Date).ToString("yyyy-MM-dd")
$lines = @("# Release Notes - $today","","Changes","--------")
if(Test-Path $cl){ $lines += (Get-Content $cl -Tail 50) }
$lines -join "`r`n" | Out-File -FilePath $rn -Encoding UTF8
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cl = Join-Path $Base 'reports\changelog.md'
$rn = Join-Path $Base 'reports\release_notes.md'
$today = (Get-Date).ToString("yyyy-MM-dd")
$lines = @("# Release Notes - $today","","Changes","--------")
if(Test-Path $cl){ $lines += (Get-Content $cl -Tail 50) }
$lines -join "`r`n" | Out-File -FilePath $rn -Encoding UTF8
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cl = Join-Path $Base 'reports\changelog.md'
$rn = Join-Path $Base 'reports\release_notes.md'
$today = (Get-Date).ToString("yyyy-MM-dd")
$lines = @("# Release Notes - $today","","Changes","--------")
if(Test-Path $cl){ $lines += (Get-Content $cl -Tail 50) }
$lines -join "`r`n" | Out-File -FilePath $rn -Encoding UTF8
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cl = Join-Path $Base 'reports\changelog.md'
$rn = Join-Path $Base 'reports\release_notes.md'
$today = (Get-Date).ToString("yyyy-MM-dd")
$lines = @("# Release Notes - $today","","Changes","--------")
if(Test-Path $cl){ $lines += (Get-Content $cl -Tail 50) }
$lines -join "`r`n" | Out-File -FilePath $rn -Encoding UTF8
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cl = Join-Path $Base 'reports\changelog.md'
$rn = Join-Path $Base 'reports\release_notes.md'
$today = (Get-Date).ToString("yyyy-MM-dd")
$lines = @("# Release Notes - $today","","Changes","--------")
if(Test-Path $cl){ $lines += (Get-Content $cl -Tail 50) }
$lines -join "`r`n" | Out-File -FilePath $rn -Encoding UTF8
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cl = Join-Path $Base 'reports\changelog.md'
$rn = Join-Path $Base 'reports\release_notes.md'
$today = (Get-Date).ToString("yyyy-MM-dd")
$lines = @("# Release Notes - $today","","Changes","--------")
if(Test-Path $cl){ $lines += (Get-Content $cl -Tail 50) }
$lines -join "`r`n" | Out-File -FilePath $rn -Encoding UTF8
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
$cl = Join-Path $Base 'reports\changelog.md'
$rn = Join-Path $Base 'reports\release_notes.md'
$today = (Get-Date).ToString("yyyy-MM-dd")
$lines = @("# Release Notes - $today","","Changes","--------")
if(Test-Path $cl){ $lines += (Get-Content $cl -Tail 50) }
$lines -join "`r`n" | Out-File -FilePath $rn -Encoding UTF8
