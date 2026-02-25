# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfgS = Join-Path $Base 'config\mason2.sample.json'
if(!(Test-Path $cfgS)){
@"{
  `"Env`": `"dev`",
  `"CleanupDays`": 2,
  `"UseFolderTime`": true,
  `"KeepTopN`": 10,
  `"VerifyMode`": `"strict`",
  `"Auto`": {
    `"VerifyEveryHours`": 4,
    `"CleanupEveryHours`": 1,
    `"NightlyTrimAt`": `"03:30`",
    `"NightlyApplyAt`": `"03:45`",
    `"QuietHours`": [ `"00:30-06:00`" ],
    `"DiskHealthAt`": `"03:30`"
  }
}"@ | Out-File -FilePath $cfgS -Encoding UTF8
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfgS = Join-Path $Base 'config\mason2.sample.json'
if(!(Test-Path $cfgS)){
@"{
  `"Env`": `"dev`",
  `"CleanupDays`": 2,
  `"UseFolderTime`": true,
  `"KeepTopN`": 10,
  `"VerifyMode`": `"strict`",
  `"Auto`": {
    `"VerifyEveryHours`": 4,
    `"CleanupEveryHours`": 1,
    `"NightlyTrimAt`": `"03:30`",
    `"NightlyApplyAt`": `"03:45`",
    `"QuietHours`": [ `"00:30-06:00`" ],
    `"DiskHealthAt`": `"03:30`"
  }
}"@ | Out-File -FilePath $cfgS -Encoding UTF8
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfgS = Join-Path $Base 'config\mason2.sample.json'
if(!(Test-Path $cfgS)){
@"{
  `"Env`": `"dev`",
  `"CleanupDays`": 2,
  `"UseFolderTime`": true,
  `"KeepTopN`": 10,
  `"VerifyMode`": `"strict`",
  `"Auto`": {
    `"VerifyEveryHours`": 4,
    `"CleanupEveryHours`": 1,
    `"NightlyTrimAt`": `"03:30`",
    `"NightlyApplyAt`": `"03:45`",
    `"QuietHours`": [ `"00:30-06:00`" ],
    `"DiskHealthAt`": `"03:30`"
  }
}"@ | Out-File -FilePath $cfgS -Encoding UTF8
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfgS = Join-Path $Base 'config\mason2.sample.json'
if(!(Test-Path $cfgS)){
@"{
  `"Env`": `"dev`",
  `"CleanupDays`": 2,
  `"UseFolderTime`": true,
  `"KeepTopN`": 10,
  `"VerifyMode`": `"strict`",
  `"Auto`": {
    `"VerifyEveryHours`": 4,
    `"CleanupEveryHours`": 1,
    `"NightlyTrimAt`": `"03:30`",
    `"NightlyApplyAt`": `"03:45`",
    `"QuietHours`": [ `"00:30-06:00`" ],
    `"DiskHealthAt`": `"03:30`"
  }
}"@ | Out-File -FilePath $cfgS -Encoding UTF8
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfgS = Join-Path $Base 'config\mason2.sample.json'
if(!(Test-Path $cfgS)){
@"{
  `"Env`": `"dev`",
  `"CleanupDays`": 2,
  `"UseFolderTime`": true,
  `"KeepTopN`": 10,
  `"VerifyMode`": `"strict`",
  `"Auto`": {
    `"VerifyEveryHours`": 4,
    `"CleanupEveryHours`": 1,
    `"NightlyTrimAt`": `"03:30`",
    `"NightlyApplyAt`": `"03:45`",
    `"QuietHours`": [ `"00:30-06:00`" ],
    `"DiskHealthAt`": `"03:30`"
  }
}"@ | Out-File -FilePath $cfgS -Encoding UTF8
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfgS = Join-Path $Base 'config\mason2.sample.json'
if(!(Test-Path $cfgS)){
@"{
  `"Env`": `"dev`",
  `"CleanupDays`": 2,
  `"UseFolderTime`": true,
  `"KeepTopN`": 10,
  `"VerifyMode`": `"strict`",
  `"Auto`": {
    `"VerifyEveryHours`": 4,
    `"CleanupEveryHours`": 1,
    `"NightlyTrimAt`": `"03:30`",
    `"NightlyApplyAt`": `"03:45`",
    `"QuietHours`": [ `"00:30-06:00`" ],
    `"DiskHealthAt`": `"03:30`"
  }
}"@ | Out-File -FilePath $cfgS -Encoding UTF8
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfgS = Join-Path $Base 'config\mason2.sample.json'
if(!(Test-Path $cfgS)){
@"{
  `"Env`": `"dev`",
  `"CleanupDays`": 2,
  `"UseFolderTime`": true,
  `"KeepTopN`": 10,
  `"VerifyMode`": `"strict`",
  `"Auto`": {
    `"VerifyEveryHours`": 4,
    `"CleanupEveryHours`": 1,
    `"NightlyTrimAt`": `"03:30`",
    `"NightlyApplyAt`": `"03:45`",
    `"QuietHours`": [ `"00:30-06:00`" ],
    `"DiskHealthAt`": `"03:30`"
  }
}"@ | Out-File -FilePath $cfgS -Encoding UTF8
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfgS = Join-Path $Base 'config\mason2.sample.json'
if(!(Test-Path $cfgS)){
@"{
  `"Env`": `"dev`",
  `"CleanupDays`": 2,
  `"UseFolderTime`": true,
  `"KeepTopN`": 10,
  `"VerifyMode`": `"strict`",
  `"Auto`": {
    `"VerifyEveryHours`": 4,
    `"CleanupEveryHours`": 1,
    `"NightlyTrimAt`": `"03:30`",
    `"NightlyApplyAt`": `"03:45`",
    `"QuietHours`": [ `"00:30-06:00`" ],
    `"DiskHealthAt`": `"03:30`"
  }
}"@ | Out-File -FilePath $cfgS -Encoding UTF8
}

