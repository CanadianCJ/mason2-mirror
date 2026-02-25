# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Sig  = Join-Path (Join-Path $Base "reports") "signals"
$kill = Join-Path $Sig "kill.switch"
if(Test-Path $kill){ Write-JsonLog -Component "watchdog" -Level "WARN" -Message "Kill switch present"; exit 2 }

$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$mem = Get-CimInstance Win32_OperatingSystem
$freePct = [math]::Round(100 * ($mem.FreePhysicalMemory/$mem.TotalVisibleMemorySize),2)

Write-JsonLog -Component "watchdog" -Level "INFO" -Message "health ping" -Props @{ cpu_pct=$cpu; ram_free_pct=$freePct }

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Sig  = Join-Path (Join-Path $Base "reports") "signals"
$kill = Join-Path $Sig "kill.switch"
if(Test-Path $kill){ Write-JsonLog -Component "watchdog" -Level "WARN" -Message "Kill switch present"; exit 2 }

$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$mem = Get-CimInstance Win32_OperatingSystem
$freePct = [math]::Round(100 * ($mem.FreePhysicalMemory/$mem.TotalVisibleMemorySize),2)

Write-JsonLog -Component "watchdog" -Level "INFO" -Message "health ping" -Props @{ cpu_pct=$cpu; ram_free_pct=$freePct }

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Sig  = Join-Path (Join-Path $Base "reports") "signals"
$kill = Join-Path $Sig "kill.switch"
if(Test-Path $kill){ Write-JsonLog -Component "watchdog" -Level "WARN" -Message "Kill switch present"; exit 2 }

$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$mem = Get-CimInstance Win32_OperatingSystem
$freePct = [math]::Round(100 * ($mem.FreePhysicalMemory/$mem.TotalVisibleMemorySize),2)

Write-JsonLog -Component "watchdog" -Level "INFO" -Message "health ping" -Props @{ cpu_pct=$cpu; ram_free_pct=$freePct }

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Sig  = Join-Path (Join-Path $Base "reports") "signals"
$kill = Join-Path $Sig "kill.switch"
if(Test-Path $kill){ Write-JsonLog -Component "watchdog" -Level "WARN" -Message "Kill switch present"; exit 2 }

$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$mem = Get-CimInstance Win32_OperatingSystem
$freePct = [math]::Round(100 * ($mem.FreePhysicalMemory/$mem.TotalVisibleMemorySize),2)

Write-JsonLog -Component "watchdog" -Level "INFO" -Message "health ping" -Props @{ cpu_pct=$cpu; ram_free_pct=$freePct }

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Sig  = Join-Path (Join-Path $Base "reports") "signals"
$kill = Join-Path $Sig "kill.switch"
if(Test-Path $kill){ Write-JsonLog -Component "watchdog" -Level "WARN" -Message "Kill switch present"; exit 2 }

$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$mem = Get-CimInstance Win32_OperatingSystem
$freePct = [math]::Round(100 * ($mem.FreePhysicalMemory/$mem.TotalVisibleMemorySize),2)

Write-JsonLog -Component "watchdog" -Level "INFO" -Message "health ping" -Props @{ cpu_pct=$cpu; ram_free_pct=$freePct }

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Sig  = Join-Path (Join-Path $Base "reports") "signals"
$kill = Join-Path $Sig "kill.switch"
if(Test-Path $kill){ Write-JsonLog -Component "watchdog" -Level "WARN" -Message "Kill switch present"; exit 2 }

$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$mem = Get-CimInstance Win32_OperatingSystem
$freePct = [math]::Round(100 * ($mem.FreePhysicalMemory/$mem.TotalVisibleMemorySize),2)

Write-JsonLog -Component "watchdog" -Level "INFO" -Message "health ping" -Props @{ cpu_pct=$cpu; ram_free_pct=$freePct }

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Sig  = Join-Path (Join-Path $Base "reports") "signals"
$kill = Join-Path $Sig "kill.switch"
if(Test-Path $kill){ Write-JsonLog -Component "watchdog" -Level "WARN" -Message "Kill switch present"; exit 2 }

$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$mem = Get-CimInstance Win32_OperatingSystem
$freePct = [math]::Round(100 * ($mem.FreePhysicalMemory/$mem.TotalVisibleMemorySize),2)

Write-JsonLog -Component "watchdog" -Level "INFO" -Message "health ping" -Props @{ cpu_pct=$cpu; ram_free_pct=$freePct }

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.1.1
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Sig  = Join-Path (Join-Path $Base "reports") "signals"
$kill = Join-Path $Sig "kill.switch"
if(Test-Path $kill){ Write-JsonLog -Component "watchdog" -Level "WARN" -Message "Kill switch present"; exit 2 }

$cpu = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
$mem = Get-CimInstance Win32_OperatingSystem
$freePct = [math]::Round(100 * ($mem.FreePhysicalMemory/$mem.TotalVisibleMemorySize),2)

Write-JsonLog -Component "watchdog" -Level "INFO" -Message "health ping" -Props @{ cpu_pct=$cpu; ram_free_pct=$freePct }

