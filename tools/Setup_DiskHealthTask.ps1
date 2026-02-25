# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [string]$At   = "03:30"  # HH:mm (24-hour)
)
$ErrorActionPreference = 'Stop'

$taskName  = "Mason2-DiskHealthDaily"
$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$Base\tools\Disk_Health.ps1`"`"")

$culture   = [System.Globalization.CultureInfo]::InvariantCulture
$time      = [datetime]::ParseExact($At, "HH:mm", $culture)

$trigger   = New-ScheduledTaskTrigger -Daily -At $time
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

try{
  if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  }
  Write-Host "DiskHealth task ready at $At."
} catch {
  Write-Warning $_.Exception.Message
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [string]$At   = "03:30"  # HH:mm (24-hour)
)
$ErrorActionPreference = 'Stop'

$taskName  = "Mason2-DiskHealthDaily"
$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$Base\tools\Disk_Health.ps1`"`"")

$culture   = [System.Globalization.CultureInfo]::InvariantCulture
$time      = [datetime]::ParseExact($At, "HH:mm", $culture)

$trigger   = New-ScheduledTaskTrigger -Daily -At $time
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

try{
  if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  }
  Write-Host "DiskHealth task ready at $At."
} catch {
  Write-Warning $_.Exception.Message
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [string]$At   = "03:30"  # HH:mm (24-hour)
)
$ErrorActionPreference = 'Stop'

$taskName  = "Mason2-DiskHealthDaily"
$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$Base\tools\Disk_Health.ps1`"`"")

$culture   = [System.Globalization.CultureInfo]::InvariantCulture
$time      = [datetime]::ParseExact($At, "HH:mm", $culture)

$trigger   = New-ScheduledTaskTrigger -Daily -At $time
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

try{
  if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  }
  Write-Host "DiskHealth task ready at $At."
} catch {
  Write-Warning $_.Exception.Message
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [string]$At   = "03:30"  # HH:mm (24-hour)
)
$ErrorActionPreference = 'Stop'

$taskName  = "Mason2-DiskHealthDaily"
$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$Base\tools\Disk_Health.ps1`"`"")

$culture   = [System.Globalization.CultureInfo]::InvariantCulture
$time      = [datetime]::ParseExact($At, "HH:mm", $culture)

$trigger   = New-ScheduledTaskTrigger -Daily -At $time
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

try{
  if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  }
  Write-Host "DiskHealth task ready at $At."
} catch {
  Write-Warning $_.Exception.Message
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [string]$At   = "03:30"  # HH:mm (24-hour)
)
$ErrorActionPreference = 'Stop'

$taskName  = "Mason2-DiskHealthDaily"
$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$Base\tools\Disk_Health.ps1`"`"")

$culture   = [System.Globalization.CultureInfo]::InvariantCulture
$time      = [datetime]::ParseExact($At, "HH:mm", $culture)

$trigger   = New-ScheduledTaskTrigger -Daily -At $time
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

try{
  if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  }
  Write-Host "DiskHealth task ready at $At."
} catch {
  Write-Warning $_.Exception.Message
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [string]$At   = "03:30"  # HH:mm (24-hour)
)
$ErrorActionPreference = 'Stop'

$taskName  = "Mason2-DiskHealthDaily"
$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$Base\tools\Disk_Health.ps1`"`"")

$culture   = [System.Globalization.CultureInfo]::InvariantCulture
$time      = [datetime]::ParseExact($At, "HH:mm", $culture)

$trigger   = New-ScheduledTaskTrigger -Daily -At $time
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

try{
  if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  }
  Write-Host "DiskHealth task ready at $At."
} catch {
  Write-Warning $_.Exception.Message
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [string]$At   = "03:30"  # HH:mm (24-hour)
)
$ErrorActionPreference = 'Stop'

$taskName  = "Mason2-DiskHealthDaily"
$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$Base\tools\Disk_Health.ps1`"`"")

$culture   = [System.Globalization.CultureInfo]::InvariantCulture
$time      = [datetime]::ParseExact($At, "HH:mm", $culture)

$trigger   = New-ScheduledTaskTrigger -Daily -At $time
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

try{
  if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  }
  Write-Host "DiskHealth task ready at $At."
} catch {
  Write-Warning $_.Exception.Message
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param(
  [string]$Base = "$env:USERPROFILE\Desktop\Mason2",
  [string]$At   = "03:30"  # HH:mm (24-hour)
)
$ErrorActionPreference = 'Stop'

$taskName  = "Mason2-DiskHealthDaily"
$action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ("-NoProfile -ExecutionPolicy Bypass -File `"`"$Base\tools\Disk_Health.ps1`"`"")

$culture   = [System.Globalization.CultureInfo]::InvariantCulture
$time      = [datetime]::ParseExact($At, "HH:mm", $culture)

$trigger   = New-ScheduledTaskTrigger -Daily -At $time
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

try{
  if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  } else {
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal | Out-Null
  }
  Write-Host "DiskHealth task ready at $At."
} catch {
  Write-Warning $_.Exception.Message
}

