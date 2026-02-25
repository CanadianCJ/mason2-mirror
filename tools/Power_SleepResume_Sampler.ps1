$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$sleep = $null; $resume = $null
try { $e = Get-WinEvent -FilterHashtable @{LogName='System'; Id=42; ProviderName='Microsoft-Windows-Kernel-Power'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($e){ $sleep=$e.TimeCreated } } catch {}
try { $r = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1;  ProviderName='Microsoft-Windows-Power-Troubleshooter'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($r){ $resume=$r.TimeCreated } } catch {}
$uptimeMin = $null
try { $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime; $uptimeMin = [int]((Get-Date) - $boot).TotalMinutes } catch {}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\power.jsonl') -Obj @{ ts=$now.ToString('s'); kind='power'; last_sleep=$sleep; last_resume=$resume; uptime_min=$uptimeMin }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$sleep = $null; $resume = $null
try { $e = Get-WinEvent -FilterHashtable @{LogName='System'; Id=42; ProviderName='Microsoft-Windows-Kernel-Power'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($e){ $sleep=$e.TimeCreated } } catch {}
try { $r = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1;  ProviderName='Microsoft-Windows-Power-Troubleshooter'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($r){ $resume=$r.TimeCreated } } catch {}
$uptimeMin = $null
try { $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime; $uptimeMin = [int]((Get-Date) - $boot).TotalMinutes } catch {}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\power.jsonl') -Obj @{ ts=$now.ToString('s'); kind='power'; last_sleep=$sleep; last_resume=$resume; uptime_min=$uptimeMin }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$sleep = $null; $resume = $null
try { $e = Get-WinEvent -FilterHashtable @{LogName='System'; Id=42; ProviderName='Microsoft-Windows-Kernel-Power'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($e){ $sleep=$e.TimeCreated } } catch {}
try { $r = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1;  ProviderName='Microsoft-Windows-Power-Troubleshooter'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($r){ $resume=$r.TimeCreated } } catch {}
$uptimeMin = $null
try { $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime; $uptimeMin = [int]((Get-Date) - $boot).TotalMinutes } catch {}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\power.jsonl') -Obj @{ ts=$now.ToString('s'); kind='power'; last_sleep=$sleep; last_resume=$resume; uptime_min=$uptimeMin }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$sleep = $null; $resume = $null
try { $e = Get-WinEvent -FilterHashtable @{LogName='System'; Id=42; ProviderName='Microsoft-Windows-Kernel-Power'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($e){ $sleep=$e.TimeCreated } } catch {}
try { $r = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1;  ProviderName='Microsoft-Windows-Power-Troubleshooter'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($r){ $resume=$r.TimeCreated } } catch {}
$uptimeMin = $null
try { $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime; $uptimeMin = [int]((Get-Date) - $boot).TotalMinutes } catch {}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\power.jsonl') -Obj @{ ts=$now.ToString('s'); kind='power'; last_sleep=$sleep; last_resume=$resume; uptime_min=$uptimeMin }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$sleep = $null; $resume = $null
try { $e = Get-WinEvent -FilterHashtable @{LogName='System'; Id=42; ProviderName='Microsoft-Windows-Kernel-Power'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($e){ $sleep=$e.TimeCreated } } catch {}
try { $r = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1;  ProviderName='Microsoft-Windows-Power-Troubleshooter'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($r){ $resume=$r.TimeCreated } } catch {}
$uptimeMin = $null
try { $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime; $uptimeMin = [int]((Get-Date) - $boot).TotalMinutes } catch {}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\power.jsonl') -Obj @{ ts=$now.ToString('s'); kind='power'; last_sleep=$sleep; last_resume=$resume; uptime_min=$uptimeMin }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$sleep = $null; $resume = $null
try { $e = Get-WinEvent -FilterHashtable @{LogName='System'; Id=42; ProviderName='Microsoft-Windows-Kernel-Power'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($e){ $sleep=$e.TimeCreated } } catch {}
try { $r = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1;  ProviderName='Microsoft-Windows-Power-Troubleshooter'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($r){ $resume=$r.TimeCreated } } catch {}
$uptimeMin = $null
try { $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime; $uptimeMin = [int]((Get-Date) - $boot).TotalMinutes } catch {}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\power.jsonl') -Obj @{ ts=$now.ToString('s'); kind='power'; last_sleep=$sleep; last_resume=$resume; uptime_min=$uptimeMin }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$sleep = $null; $resume = $null
try { $e = Get-WinEvent -FilterHashtable @{LogName='System'; Id=42; ProviderName='Microsoft-Windows-Kernel-Power'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($e){ $sleep=$e.TimeCreated } } catch {}
try { $r = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1;  ProviderName='Microsoft-Windows-Power-Troubleshooter'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($r){ $resume=$r.TimeCreated } } catch {}
$uptimeMin = $null
try { $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime; $uptimeMin = [int]((Get-Date) - $boot).TotalMinutes } catch {}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\power.jsonl') -Obj @{ ts=$now.ToString('s'); kind='power'; last_sleep=$sleep; last_resume=$resume; uptime_min=$uptimeMin }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
$sleep = $null; $resume = $null
try { $e = Get-WinEvent -FilterHashtable @{LogName='System'; Id=42; ProviderName='Microsoft-Windows-Kernel-Power'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($e){ $sleep=$e.TimeCreated } } catch {}
try { $r = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1;  ProviderName='Microsoft-Windows-Power-Troubleshooter'} -MaxEvents 1 -ErrorAction SilentlyContinue; if($r){ $resume=$r.TimeCreated } } catch {}
$uptimeMin = $null
try { $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime; $uptimeMin = [int]((Get-Date) - $boot).TotalMinutes } catch {}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\power.jsonl') -Obj @{ ts=$now.ToString('s'); kind='power'; last_sleep=$sleep; last_resume=$resume; uptime_min=$uptimeMin }
