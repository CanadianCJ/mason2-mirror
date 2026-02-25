# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$EnvF = Join-Path $Base ".env"
if(!(Test-Path $EnvF)){
  $pin = Read-Host "Set OWNER PIN (digits)"; $pinHash = (New-Object -TypeName System.Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($pin)) | ForEach-Object { $_.ToString("x2") } | ForEach-Object {$_} -join ''
  "MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nOWNER_PIN_HASH=$pinHash" | Set-Content $EnvF -Encoding ASCII
}


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$EnvF = Join-Path $Base ".env"
if(!(Test-Path $EnvF)){
  $pin = Read-Host "Set OWNER PIN (digits)"; $pinHash = (New-Object -TypeName System.Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($pin)) | ForEach-Object { $_.ToString("x2") } | ForEach-Object {$_} -join ''
  "MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nOWNER_PIN_HASH=$pinHash" | Set-Content $EnvF -Encoding ASCII
}


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$EnvF = Join-Path $Base ".env"
if(!(Test-Path $EnvF)){
  $pin = Read-Host "Set OWNER PIN (digits)"; $pinHash = (New-Object -TypeName System.Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($pin)) | ForEach-Object { $_.ToString("x2") } | ForEach-Object {$_} -join ''
  "MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nOWNER_PIN_HASH=$pinHash" | Set-Content $EnvF -Encoding ASCII
}


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$EnvF = Join-Path $Base ".env"
if(!(Test-Path $EnvF)){
  $pin = Read-Host "Set OWNER PIN (digits)"; $pinHash = (New-Object -TypeName System.Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($pin)) | ForEach-Object { $_.ToString("x2") } | ForEach-Object {$_} -join ''
  "MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nOWNER_PIN_HASH=$pinHash" | Set-Content $EnvF -Encoding ASCII
}


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$EnvF = Join-Path $Base ".env"
if(!(Test-Path $EnvF)){
  $pin = Read-Host "Set OWNER PIN (digits)"; $pinHash = (New-Object -TypeName System.Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($pin)) | ForEach-Object { $_.ToString("x2") } | ForEach-Object {$_} -join ''
  "MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nOWNER_PIN_HASH=$pinHash" | Set-Content $EnvF -Encoding ASCII
}


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$EnvF = Join-Path $Base ".env"
if(!(Test-Path $EnvF)){
  $pin = Read-Host "Set OWNER PIN (digits)"; $pinHash = (New-Object -TypeName System.Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($pin)) | ForEach-Object { $_.ToString("x2") } | ForEach-Object {$_} -join ''
  "MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nOWNER_PIN_HASH=$pinHash" | Set-Content $EnvF -Encoding ASCII
}


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$EnvF = Join-Path $Base ".env"
if(!(Test-Path $EnvF)){
  $pin = Read-Host "Set OWNER PIN (digits)"; $pinHash = (New-Object -TypeName System.Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($pin)) | ForEach-Object { $_.ToString("x2") } | ForEach-Object {$_} -join ''
  "MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nOWNER_PIN_HASH=$pinHash" | Set-Content $EnvF -Encoding ASCII
}


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$EnvF = Join-Path $Base ".env"
if(!(Test-Path $EnvF)){
  $pin = Read-Host "Set OWNER PIN (digits)"; $pinHash = (New-Object -TypeName System.Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($pin)) | ForEach-Object { $_.ToString("x2") } | ForEach-Object {$_} -join ''
  "MASON_DISK_MIN_FREE_PCT=10`nMASON_MONEY_ENABLE=0`nOWNER_PIN_HASH=$pinHash" | Set-Content $EnvF -Encoding ASCII
}


