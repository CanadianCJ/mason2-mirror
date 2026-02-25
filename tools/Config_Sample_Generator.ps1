# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
New-Item $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envSample = @"
# Mason2 .env (sample)
MASON_MODE=dev
MASON_DISK_MIN_FREE_PCT=10
MASON_OUTBOUND_DAILY_MAX=200
MASON_OUTBOUND_PER_MIN=10
"@
$envSample | Set-Content (Join-Path $Cfg ".env.sample") -Encoding UTF8
# sample policy mirrors current policy (if present) with placeholders
$pol = Join-Path $Cfg "policy.json"
if(Test-Path $pol){
  $p = Get-Content $pol -Raw | ConvertFrom-Json
}else{
  $p = [ordered]@{
    high_risk_window="00:00-23:59"; cmd_allowlist=@("powershell.exe","cmd.exe")
    file_scope_root=$Base; egress_denylist=@("pastebin.com")
    operator_pin_hash=""; safe_mode=$true
    outbound_budget=@{ daily_requests_max=200; per_minute_max=10 }
    risk_budget=@{ max_blast="low"; max_size_mb=20 }
    kill_switch_file=(Join-Path $Base "reports\signals\kill.switch")
  }
}
($p | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Cfg "sample.policy.json") -Encoding UTF8
"OK: wrote .env.sample and sample.policy.json"

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
New-Item $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envSample = @"
# Mason2 .env (sample)
MASON_MODE=dev
MASON_DISK_MIN_FREE_PCT=10
MASON_OUTBOUND_DAILY_MAX=200
MASON_OUTBOUND_PER_MIN=10
"@
$envSample | Set-Content (Join-Path $Cfg ".env.sample") -Encoding UTF8
# sample policy mirrors current policy (if present) with placeholders
$pol = Join-Path $Cfg "policy.json"
if(Test-Path $pol){
  $p = Get-Content $pol -Raw | ConvertFrom-Json
}else{
  $p = [ordered]@{
    high_risk_window="00:00-23:59"; cmd_allowlist=@("powershell.exe","cmd.exe")
    file_scope_root=$Base; egress_denylist=@("pastebin.com")
    operator_pin_hash=""; safe_mode=$true
    outbound_budget=@{ daily_requests_max=200; per_minute_max=10 }
    risk_budget=@{ max_blast="low"; max_size_mb=20 }
    kill_switch_file=(Join-Path $Base "reports\signals\kill.switch")
  }
}
($p | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Cfg "sample.policy.json") -Encoding UTF8
"OK: wrote .env.sample and sample.policy.json"

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
New-Item $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envSample = @"
# Mason2 .env (sample)
MASON_MODE=dev
MASON_DISK_MIN_FREE_PCT=10
MASON_OUTBOUND_DAILY_MAX=200
MASON_OUTBOUND_PER_MIN=10
"@
$envSample | Set-Content (Join-Path $Cfg ".env.sample") -Encoding UTF8
# sample policy mirrors current policy (if present) with placeholders
$pol = Join-Path $Cfg "policy.json"
if(Test-Path $pol){
  $p = Get-Content $pol -Raw | ConvertFrom-Json
}else{
  $p = [ordered]@{
    high_risk_window="00:00-23:59"; cmd_allowlist=@("powershell.exe","cmd.exe")
    file_scope_root=$Base; egress_denylist=@("pastebin.com")
    operator_pin_hash=""; safe_mode=$true
    outbound_budget=@{ daily_requests_max=200; per_minute_max=10 }
    risk_budget=@{ max_blast="low"; max_size_mb=20 }
    kill_switch_file=(Join-Path $Base "reports\signals\kill.switch")
  }
}
($p | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Cfg "sample.policy.json") -Encoding UTF8
"OK: wrote .env.sample and sample.policy.json"

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
New-Item $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envSample = @"
# Mason2 .env (sample)
MASON_MODE=dev
MASON_DISK_MIN_FREE_PCT=10
MASON_OUTBOUND_DAILY_MAX=200
MASON_OUTBOUND_PER_MIN=10
"@
$envSample | Set-Content (Join-Path $Cfg ".env.sample") -Encoding UTF8
# sample policy mirrors current policy (if present) with placeholders
$pol = Join-Path $Cfg "policy.json"
if(Test-Path $pol){
  $p = Get-Content $pol -Raw | ConvertFrom-Json
}else{
  $p = [ordered]@{
    high_risk_window="00:00-23:59"; cmd_allowlist=@("powershell.exe","cmd.exe")
    file_scope_root=$Base; egress_denylist=@("pastebin.com")
    operator_pin_hash=""; safe_mode=$true
    outbound_budget=@{ daily_requests_max=200; per_minute_max=10 }
    risk_budget=@{ max_blast="low"; max_size_mb=20 }
    kill_switch_file=(Join-Path $Base "reports\signals\kill.switch")
  }
}
($p | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Cfg "sample.policy.json") -Encoding UTF8
"OK: wrote .env.sample and sample.policy.json"

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
New-Item $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envSample = @"
# Mason2 .env (sample)
MASON_MODE=dev
MASON_DISK_MIN_FREE_PCT=10
MASON_OUTBOUND_DAILY_MAX=200
MASON_OUTBOUND_PER_MIN=10
"@
$envSample | Set-Content (Join-Path $Cfg ".env.sample") -Encoding UTF8
# sample policy mirrors current policy (if present) with placeholders
$pol = Join-Path $Cfg "policy.json"
if(Test-Path $pol){
  $p = Get-Content $pol -Raw | ConvertFrom-Json
}else{
  $p = [ordered]@{
    high_risk_window="00:00-23:59"; cmd_allowlist=@("powershell.exe","cmd.exe")
    file_scope_root=$Base; egress_denylist=@("pastebin.com")
    operator_pin_hash=""; safe_mode=$true
    outbound_budget=@{ daily_requests_max=200; per_minute_max=10 }
    risk_budget=@{ max_blast="low"; max_size_mb=20 }
    kill_switch_file=(Join-Path $Base "reports\signals\kill.switch")
  }
}
($p | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Cfg "sample.policy.json") -Encoding UTF8
"OK: wrote .env.sample and sample.policy.json"

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
New-Item $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envSample = @"
# Mason2 .env (sample)
MASON_MODE=dev
MASON_DISK_MIN_FREE_PCT=10
MASON_OUTBOUND_DAILY_MAX=200
MASON_OUTBOUND_PER_MIN=10
"@
$envSample | Set-Content (Join-Path $Cfg ".env.sample") -Encoding UTF8
# sample policy mirrors current policy (if present) with placeholders
$pol = Join-Path $Cfg "policy.json"
if(Test-Path $pol){
  $p = Get-Content $pol -Raw | ConvertFrom-Json
}else{
  $p = [ordered]@{
    high_risk_window="00:00-23:59"; cmd_allowlist=@("powershell.exe","cmd.exe")
    file_scope_root=$Base; egress_denylist=@("pastebin.com")
    operator_pin_hash=""; safe_mode=$true
    outbound_budget=@{ daily_requests_max=200; per_minute_max=10 }
    risk_budget=@{ max_blast="low"; max_size_mb=20 }
    kill_switch_file=(Join-Path $Base "reports\signals\kill.switch")
  }
}
($p | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Cfg "sample.policy.json") -Encoding UTF8
"OK: wrote .env.sample and sample.policy.json"

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
New-Item $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envSample = @"
# Mason2 .env (sample)
MASON_MODE=dev
MASON_DISK_MIN_FREE_PCT=10
MASON_OUTBOUND_DAILY_MAX=200
MASON_OUTBOUND_PER_MIN=10
"@
$envSample | Set-Content (Join-Path $Cfg ".env.sample") -Encoding UTF8
# sample policy mirrors current policy (if present) with placeholders
$pol = Join-Path $Cfg "policy.json"
if(Test-Path $pol){
  $p = Get-Content $pol -Raw | ConvertFrom-Json
}else{
  $p = [ordered]@{
    high_risk_window="00:00-23:59"; cmd_allowlist=@("powershell.exe","cmd.exe")
    file_scope_root=$Base; egress_denylist=@("pastebin.com")
    operator_pin_hash=""; safe_mode=$true
    outbound_budget=@{ daily_requests_max=200; per_minute_max=10 }
    risk_budget=@{ max_blast="low"; max_size_mb=20 }
    kill_switch_file=(Join-Path $Base "reports\signals\kill.switch")
  }
}
($p | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Cfg "sample.policy.json") -Encoding UTF8
"OK: wrote .env.sample and sample.policy.json"

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Cfg  = Join-Path $Base "config"
New-Item $Cfg -ItemType Directory -ea SilentlyContinue | Out-Null
$envSample = @"
# Mason2 .env (sample)
MASON_MODE=dev
MASON_DISK_MIN_FREE_PCT=10
MASON_OUTBOUND_DAILY_MAX=200
MASON_OUTBOUND_PER_MIN=10
"@
$envSample | Set-Content (Join-Path $Cfg ".env.sample") -Encoding UTF8
# sample policy mirrors current policy (if present) with placeholders
$pol = Join-Path $Cfg "policy.json"
if(Test-Path $pol){
  $p = Get-Content $pol -Raw | ConvertFrom-Json
}else{
  $p = [ordered]@{
    high_risk_window="00:00-23:59"; cmd_allowlist=@("powershell.exe","cmd.exe")
    file_scope_root=$Base; egress_denylist=@("pastebin.com")
    operator_pin_hash=""; safe_mode=$true
    outbound_budget=@{ daily_requests_max=200; per_minute_max=10 }
    risk_budget=@{ max_blast="low"; max_size_mb=20 }
    kill_switch_file=(Join-Path $Base "reports\signals\kill.switch")
  }
}
($p | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Cfg "sample.policy.json") -Encoding UTF8
"OK: wrote .env.sample and sample.policy.json"

