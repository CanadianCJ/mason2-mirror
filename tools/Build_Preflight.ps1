# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2",[int]$MinFreePct=5,[switch]$Quiet)
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $rep=Join-Path $Base 'reports'; $sum=Join-Path $rep 'preflight_build.json'; $hist=Join-Path $rep 'preflight_build.jsonl'
$req=@(Join-Path $Base 'tools\Verify_Tighten.ps1',Join-Path $Base 'tools\Verify_And_Unpack.ps1',Join-Path $Base 'tools\Trim_Releases.ps1',Join-Path $Base 'tools\Nightly_VerifyApply.ps1',Join-Path $Base 'tools\Common.ps1') | Where-Object {$_} | Select-Object -Unique
$free=Get-DiskFreePct $Base; $missing=@(); foreach($p in $req){ if(-not (Test-Path $p)){ $missing+=$p } }
$r=@{ts=$now.ToString('s');kind='build_preflight';base=$Base;min_free_pct=$MinFreePct;disk_free_pct=$free;tools_required=$req;tools_missing=$missing;ok=$true;reason=$null}
if($null -eq $free){$r.ok=$false;$r.reason="Unable to read disk free %"} elseif($free -lt $MinFreePct){$r.ok=$false;$r.reason="Disk free too low ($free%). Need $MinFreePct%"} elseif($missing.Count -gt 0){$r.ok=$false;$r.reason="Missing tool(s): "+($missing -join ', ')}
($r|ConvertTo-Json -Depth 6)|Out-File -FilePath $sum -Encoding UTF8 -Force; Write-JsonLineSafe -Path $hist -Obj $r
if(-not $Quiet){ if($r.ok){Write-Host "[Preflight OK] $($r.disk_free_pct)%"} else {Write-Warning "[Preflight FAIL] $($r.reason)"} }
if(-not $r.ok){exit 2}else{exit 0}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2",[int]$MinFreePct=5,[switch]$Quiet)
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $rep=Join-Path $Base 'reports'; $sum=Join-Path $rep 'preflight_build.json'; $hist=Join-Path $rep 'preflight_build.jsonl'
$req=@(Join-Path $Base 'tools\Verify_Tighten.ps1',Join-Path $Base 'tools\Verify_And_Unpack.ps1',Join-Path $Base 'tools\Trim_Releases.ps1',Join-Path $Base 'tools\Nightly_VerifyApply.ps1',Join-Path $Base 'tools\Common.ps1') | Where-Object {$_} | Select-Object -Unique
$free=Get-DiskFreePct $Base; $missing=@(); foreach($p in $req){ if(-not (Test-Path $p)){ $missing+=$p } }
$r=@{ts=$now.ToString('s');kind='build_preflight';base=$Base;min_free_pct=$MinFreePct;disk_free_pct=$free;tools_required=$req;tools_missing=$missing;ok=$true;reason=$null}
if($null -eq $free){$r.ok=$false;$r.reason="Unable to read disk free %"} elseif($free -lt $MinFreePct){$r.ok=$false;$r.reason="Disk free too low ($free%). Need $MinFreePct%"} elseif($missing.Count -gt 0){$r.ok=$false;$r.reason="Missing tool(s): "+($missing -join ', ')}
($r|ConvertTo-Json -Depth 6)|Out-File -FilePath $sum -Encoding UTF8 -Force; Write-JsonLineSafe -Path $hist -Obj $r
if(-not $Quiet){ if($r.ok){Write-Host "[Preflight OK] $($r.disk_free_pct)%"} else {Write-Warning "[Preflight FAIL] $($r.reason)"} }
if(-not $r.ok){exit 2}else{exit 0}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2",[int]$MinFreePct=5,[switch]$Quiet)
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $rep=Join-Path $Base 'reports'; $sum=Join-Path $rep 'preflight_build.json'; $hist=Join-Path $rep 'preflight_build.jsonl'
$req=@(Join-Path $Base 'tools\Verify_Tighten.ps1',Join-Path $Base 'tools\Verify_And_Unpack.ps1',Join-Path $Base 'tools\Trim_Releases.ps1',Join-Path $Base 'tools\Nightly_VerifyApply.ps1',Join-Path $Base 'tools\Common.ps1') | Where-Object {$_} | Select-Object -Unique
$free=Get-DiskFreePct $Base; $missing=@(); foreach($p in $req){ if(-not (Test-Path $p)){ $missing+=$p } }
$r=@{ts=$now.ToString('s');kind='build_preflight';base=$Base;min_free_pct=$MinFreePct;disk_free_pct=$free;tools_required=$req;tools_missing=$missing;ok=$true;reason=$null}
if($null -eq $free){$r.ok=$false;$r.reason="Unable to read disk free %"} elseif($free -lt $MinFreePct){$r.ok=$false;$r.reason="Disk free too low ($free%). Need $MinFreePct%"} elseif($missing.Count -gt 0){$r.ok=$false;$r.reason="Missing tool(s): "+($missing -join ', ')}
($r|ConvertTo-Json -Depth 6)|Out-File -FilePath $sum -Encoding UTF8 -Force; Write-JsonLineSafe -Path $hist -Obj $r
if(-not $Quiet){ if($r.ok){Write-Host "[Preflight OK] $($r.disk_free_pct)%"} else {Write-Warning "[Preflight FAIL] $($r.reason)"} }
if(-not $r.ok){exit 2}else{exit 0}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2",[int]$MinFreePct=5,[switch]$Quiet)
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $rep=Join-Path $Base 'reports'; $sum=Join-Path $rep 'preflight_build.json'; $hist=Join-Path $rep 'preflight_build.jsonl'
$req=@(Join-Path $Base 'tools\Verify_Tighten.ps1',Join-Path $Base 'tools\Verify_And_Unpack.ps1',Join-Path $Base 'tools\Trim_Releases.ps1',Join-Path $Base 'tools\Nightly_VerifyApply.ps1',Join-Path $Base 'tools\Common.ps1') | Where-Object {$_} | Select-Object -Unique
$free=Get-DiskFreePct $Base; $missing=@(); foreach($p in $req){ if(-not (Test-Path $p)){ $missing+=$p } }
$r=@{ts=$now.ToString('s');kind='build_preflight';base=$Base;min_free_pct=$MinFreePct;disk_free_pct=$free;tools_required=$req;tools_missing=$missing;ok=$true;reason=$null}
if($null -eq $free){$r.ok=$false;$r.reason="Unable to read disk free %"} elseif($free -lt $MinFreePct){$r.ok=$false;$r.reason="Disk free too low ($free%). Need $MinFreePct%"} elseif($missing.Count -gt 0){$r.ok=$false;$r.reason="Missing tool(s): "+($missing -join ', ')}
($r|ConvertTo-Json -Depth 6)|Out-File -FilePath $sum -Encoding UTF8 -Force; Write-JsonLineSafe -Path $hist -Obj $r
if(-not $Quiet){ if($r.ok){Write-Host "[Preflight OK] $($r.disk_free_pct)%"} else {Write-Warning "[Preflight FAIL] $($r.reason)"} }
if(-not $r.ok){exit 2}else{exit 0}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2",[int]$MinFreePct=5,[switch]$Quiet)
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $rep=Join-Path $Base 'reports'; $sum=Join-Path $rep 'preflight_build.json'; $hist=Join-Path $rep 'preflight_build.jsonl'
$req=@(Join-Path $Base 'tools\Verify_Tighten.ps1',Join-Path $Base 'tools\Verify_And_Unpack.ps1',Join-Path $Base 'tools\Trim_Releases.ps1',Join-Path $Base 'tools\Nightly_VerifyApply.ps1',Join-Path $Base 'tools\Common.ps1') | Where-Object {$_} | Select-Object -Unique
$free=Get-DiskFreePct $Base; $missing=@(); foreach($p in $req){ if(-not (Test-Path $p)){ $missing+=$p } }
$r=@{ts=$now.ToString('s');kind='build_preflight';base=$Base;min_free_pct=$MinFreePct;disk_free_pct=$free;tools_required=$req;tools_missing=$missing;ok=$true;reason=$null}
if($null -eq $free){$r.ok=$false;$r.reason="Unable to read disk free %"} elseif($free -lt $MinFreePct){$r.ok=$false;$r.reason="Disk free too low ($free%). Need $MinFreePct%"} elseif($missing.Count -gt 0){$r.ok=$false;$r.reason="Missing tool(s): "+($missing -join ', ')}
($r|ConvertTo-Json -Depth 6)|Out-File -FilePath $sum -Encoding UTF8 -Force; Write-JsonLineSafe -Path $hist -Obj $r
if(-not $Quiet){ if($r.ok){Write-Host "[Preflight OK] $($r.disk_free_pct)%"} else {Write-Warning "[Preflight FAIL] $($r.reason)"} }
if(-not $r.ok){exit 2}else{exit 0}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2",[int]$MinFreePct=5,[switch]$Quiet)
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $rep=Join-Path $Base 'reports'; $sum=Join-Path $rep 'preflight_build.json'; $hist=Join-Path $rep 'preflight_build.jsonl'
$req=@(Join-Path $Base 'tools\Verify_Tighten.ps1',Join-Path $Base 'tools\Verify_And_Unpack.ps1',Join-Path $Base 'tools\Trim_Releases.ps1',Join-Path $Base 'tools\Nightly_VerifyApply.ps1',Join-Path $Base 'tools\Common.ps1') | Where-Object {$_} | Select-Object -Unique
$free=Get-DiskFreePct $Base; $missing=@(); foreach($p in $req){ if(-not (Test-Path $p)){ $missing+=$p } }
$r=@{ts=$now.ToString('s');kind='build_preflight';base=$Base;min_free_pct=$MinFreePct;disk_free_pct=$free;tools_required=$req;tools_missing=$missing;ok=$true;reason=$null}
if($null -eq $free){$r.ok=$false;$r.reason="Unable to read disk free %"} elseif($free -lt $MinFreePct){$r.ok=$false;$r.reason="Disk free too low ($free%). Need $MinFreePct%"} elseif($missing.Count -gt 0){$r.ok=$false;$r.reason="Missing tool(s): "+($missing -join ', ')}
($r|ConvertTo-Json -Depth 6)|Out-File -FilePath $sum -Encoding UTF8 -Force; Write-JsonLineSafe -Path $hist -Obj $r
if(-not $Quiet){ if($r.ok){Write-Host "[Preflight OK] $($r.disk_free_pct)%"} else {Write-Warning "[Preflight FAIL] $($r.reason)"} }
if(-not $r.ok){exit 2}else{exit 0}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2",[int]$MinFreePct=5,[switch]$Quiet)
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $rep=Join-Path $Base 'reports'; $sum=Join-Path $rep 'preflight_build.json'; $hist=Join-Path $rep 'preflight_build.jsonl'
$req=@(Join-Path $Base 'tools\Verify_Tighten.ps1',Join-Path $Base 'tools\Verify_And_Unpack.ps1',Join-Path $Base 'tools\Trim_Releases.ps1',Join-Path $Base 'tools\Nightly_VerifyApply.ps1',Join-Path $Base 'tools\Common.ps1') | Where-Object {$_} | Select-Object -Unique
$free=Get-DiskFreePct $Base; $missing=@(); foreach($p in $req){ if(-not (Test-Path $p)){ $missing+=$p } }
$r=@{ts=$now.ToString('s');kind='build_preflight';base=$Base;min_free_pct=$MinFreePct;disk_free_pct=$free;tools_required=$req;tools_missing=$missing;ok=$true;reason=$null}
if($null -eq $free){$r.ok=$false;$r.reason="Unable to read disk free %"} elseif($free -lt $MinFreePct){$r.ok=$false;$r.reason="Disk free too low ($free%). Need $MinFreePct%"} elseif($missing.Count -gt 0){$r.ok=$false;$r.reason="Missing tool(s): "+($missing -join ', ')}
($r|ConvertTo-Json -Depth 6)|Out-File -FilePath $sum -Encoding UTF8 -Force; Write-JsonLineSafe -Path $hist -Obj $r
if(-not $Quiet){ if($r.ok){Write-Host "[Preflight OK] $($r.disk_free_pct)%"} else {Write-Warning "[Preflight FAIL] $($r.reason)"} }
if(-not $r.ok){exit 2}else{exit 0}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2",[int]$MinFreePct=5,[switch]$Quiet)
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$now=Get-Date; $rep=Join-Path $Base 'reports'; $sum=Join-Path $rep 'preflight_build.json'; $hist=Join-Path $rep 'preflight_build.jsonl'
$req=@(Join-Path $Base 'tools\Verify_Tighten.ps1',Join-Path $Base 'tools\Verify_And_Unpack.ps1',Join-Path $Base 'tools\Trim_Releases.ps1',Join-Path $Base 'tools\Nightly_VerifyApply.ps1',Join-Path $Base 'tools\Common.ps1') | Where-Object {$_} | Select-Object -Unique
$free=Get-DiskFreePct $Base; $missing=@(); foreach($p in $req){ if(-not (Test-Path $p)){ $missing+=$p } }
$r=@{ts=$now.ToString('s');kind='build_preflight';base=$Base;min_free_pct=$MinFreePct;disk_free_pct=$free;tools_required=$req;tools_missing=$missing;ok=$true;reason=$null}
if($null -eq $free){$r.ok=$false;$r.reason="Unable to read disk free %"} elseif($free -lt $MinFreePct){$r.ok=$false;$r.reason="Disk free too low ($free%). Need $MinFreePct%"} elseif($missing.Count -gt 0){$r.ok=$false;$r.reason="Missing tool(s): "+($missing -join ', ')}
($r|ConvertTo-Json -Depth 6)|Out-File -FilePath $sum -Encoding UTF8 -Force; Write-JsonLineSafe -Path $hist -Obj $r
if(-not $Quiet){ if($r.ok){Write-Host "[Preflight OK] $($r.disk_free_pct)%"} else {Write-Warning "[Preflight FAIL] $($r.reason)"} }
if(-not $r.ok){exit 2}else{exit 0}

