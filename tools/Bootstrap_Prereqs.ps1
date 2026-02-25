# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Bootstrap_Prereqs.ps1
$ok = $true
# PowerShell
try { if($PSVersionTable.PSVersion.Major -lt 5){ $ok=$false; Write-Host "[FAIL] PS version < 5" -ForegroundColor Red } }
catch { $ok=$false }
# .NET
try { $v=[Environment]::Version; if(-not $v){ $ok=$false; Write-Host "[FAIL] .NET missing" -ForegroundColor Red } } catch { $ok=$false }
# TLS 1.2 available
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { $ok=$false }

$SigDir = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($ok){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereq.ok')    -Encoding ASCII
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereqs.ok')   -Encoding ASCII
  Write-Host "[ OK ] Prereqs validated"
}else{
  Write-Host "[WARN] Prereqs check failed" -ForegroundColor Yellow
}


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Bootstrap_Prereqs.ps1
$ok = $true
# PowerShell
try { if($PSVersionTable.PSVersion.Major -lt 5){ $ok=$false; Write-Host "[FAIL] PS version < 5" -ForegroundColor Red } }
catch { $ok=$false }
# .NET
try { $v=[Environment]::Version; if(-not $v){ $ok=$false; Write-Host "[FAIL] .NET missing" -ForegroundColor Red } } catch { $ok=$false }
# TLS 1.2 available
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { $ok=$false }

$SigDir = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($ok){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereq.ok')    -Encoding ASCII
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereqs.ok')   -Encoding ASCII
  Write-Host "[ OK ] Prereqs validated"
}else{
  Write-Host "[WARN] Prereqs check failed" -ForegroundColor Yellow
}


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Bootstrap_Prereqs.ps1
$ok = $true
# PowerShell
try { if($PSVersionTable.PSVersion.Major -lt 5){ $ok=$false; Write-Host "[FAIL] PS version < 5" -ForegroundColor Red } }
catch { $ok=$false }
# .NET
try { $v=[Environment]::Version; if(-not $v){ $ok=$false; Write-Host "[FAIL] .NET missing" -ForegroundColor Red } } catch { $ok=$false }
# TLS 1.2 available
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { $ok=$false }

$SigDir = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($ok){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereq.ok')    -Encoding ASCII
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereqs.ok')   -Encoding ASCII
  Write-Host "[ OK ] Prereqs validated"
}else{
  Write-Host "[WARN] Prereqs check failed" -ForegroundColor Yellow
}


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Bootstrap_Prereqs.ps1
$ok = $true
# PowerShell
try { if($PSVersionTable.PSVersion.Major -lt 5){ $ok=$false; Write-Host "[FAIL] PS version < 5" -ForegroundColor Red } }
catch { $ok=$false }
# .NET
try { $v=[Environment]::Version; if(-not $v){ $ok=$false; Write-Host "[FAIL] .NET missing" -ForegroundColor Red } } catch { $ok=$false }
# TLS 1.2 available
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { $ok=$false }

$SigDir = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($ok){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereq.ok')    -Encoding ASCII
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereqs.ok')   -Encoding ASCII
  Write-Host "[ OK ] Prereqs validated"
}else{
  Write-Host "[WARN] Prereqs check failed" -ForegroundColor Yellow
}


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Bootstrap_Prereqs.ps1
$ok = $true
# PowerShell
try { if($PSVersionTable.PSVersion.Major -lt 5){ $ok=$false; Write-Host "[FAIL] PS version < 5" -ForegroundColor Red } }
catch { $ok=$false }
# .NET
try { $v=[Environment]::Version; if(-not $v){ $ok=$false; Write-Host "[FAIL] .NET missing" -ForegroundColor Red } } catch { $ok=$false }
# TLS 1.2 available
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { $ok=$false }

$SigDir = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($ok){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereq.ok')    -Encoding ASCII
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereqs.ok')   -Encoding ASCII
  Write-Host "[ OK ] Prereqs validated"
}else{
  Write-Host "[WARN] Prereqs check failed" -ForegroundColor Yellow
}


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Bootstrap_Prereqs.ps1
$ok = $true
# PowerShell
try { if($PSVersionTable.PSVersion.Major -lt 5){ $ok=$false; Write-Host "[FAIL] PS version < 5" -ForegroundColor Red } }
catch { $ok=$false }
# .NET
try { $v=[Environment]::Version; if(-not $v){ $ok=$false; Write-Host "[FAIL] .NET missing" -ForegroundColor Red } } catch { $ok=$false }
# TLS 1.2 available
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { $ok=$false }

$SigDir = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($ok){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereq.ok')    -Encoding ASCII
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereqs.ok')   -Encoding ASCII
  Write-Host "[ OK ] Prereqs validated"
}else{
  Write-Host "[WARN] Prereqs check failed" -ForegroundColor Yellow
}


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Bootstrap_Prereqs.ps1
$ok = $true
# PowerShell
try { if($PSVersionTable.PSVersion.Major -lt 5){ $ok=$false; Write-Host "[FAIL] PS version < 5" -ForegroundColor Red } }
catch { $ok=$false }
# .NET
try { $v=[Environment]::Version; if(-not $v){ $ok=$false; Write-Host "[FAIL] .NET missing" -ForegroundColor Red } } catch { $ok=$false }
# TLS 1.2 available
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { $ok=$false }

$SigDir = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($ok){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereq.ok')    -Encoding ASCII
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereqs.ok')   -Encoding ASCII
  Write-Host "[ OK ] Prereqs validated"
}else{
  Write-Host "[WARN] Prereqs check failed" -ForegroundColor Yellow
}


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Bootstrap_Prereqs.ps1
$ok = $true
# PowerShell
try { if($PSVersionTable.PSVersion.Major -lt 5){ $ok=$false; Write-Host "[FAIL] PS version < 5" -ForegroundColor Red } }
catch { $ok=$false }
# .NET
try { $v=[Environment]::Version; if(-not $v){ $ok=$false; Write-Host "[FAIL] .NET missing" -ForegroundColor Red } } catch { $ok=$false }
# TLS 1.2 available
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { $ok=$false }

$SigDir = Join-Path $env:USERPROFILE 'Desktop\Mason2\reports\signals'
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null
if($ok){
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereq.ok')    -Encoding ASCII
  'ok' | Set-Content (Join-Path $SigDir 'system-structure-prereqs.ok')   -Encoding ASCII
  Write-Host "[ OK ] Prereqs validated"
}else{
  Write-Host "[WARN] Prereqs check failed" -ForegroundColor Yellow
}


