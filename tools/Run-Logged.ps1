# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Run-Logged.ps1
param([Parameter(Mandatory=$true)][string]$Cmd,
      [string]$Args="")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$LogD = Join-Path $Base "logs\install"
ni $LogD -ItemType Directory -ea SilentlyContinue | Out-Null
$log  = Join-Path $LogD "install_log.txt"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "[{0}] >> {1} {2}" -f $ts, $Cmd, $Args
Add-Content $log $line
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName  = $Cmd
$psi.Arguments = $Args
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$p.WaitForExit()
Add-Content $log ("[{0}] << exit {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $p.ExitCode)
if(-not (Test-Path (Join-Path $Base "reports\signals\system-structure-install-log.ok"))){
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-install-log.ok") -Encoding ASCII
}
exit $p.ExitCode


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Run-Logged.ps1
param([Parameter(Mandatory=$true)][string]$Cmd,
      [string]$Args="")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$LogD = Join-Path $Base "logs\install"
ni $LogD -ItemType Directory -ea SilentlyContinue | Out-Null
$log  = Join-Path $LogD "install_log.txt"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "[{0}] >> {1} {2}" -f $ts, $Cmd, $Args
Add-Content $log $line
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName  = $Cmd
$psi.Arguments = $Args
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$p.WaitForExit()
Add-Content $log ("[{0}] << exit {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $p.ExitCode)
if(-not (Test-Path (Join-Path $Base "reports\signals\system-structure-install-log.ok"))){
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-install-log.ok") -Encoding ASCII
}
exit $p.ExitCode


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Run-Logged.ps1
param([Parameter(Mandatory=$true)][string]$Cmd,
      [string]$Args="")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$LogD = Join-Path $Base "logs\install"
ni $LogD -ItemType Directory -ea SilentlyContinue | Out-Null
$log  = Join-Path $LogD "install_log.txt"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "[{0}] >> {1} {2}" -f $ts, $Cmd, $Args
Add-Content $log $line
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName  = $Cmd
$psi.Arguments = $Args
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$p.WaitForExit()
Add-Content $log ("[{0}] << exit {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $p.ExitCode)
if(-not (Test-Path (Join-Path $Base "reports\signals\system-structure-install-log.ok"))){
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-install-log.ok") -Encoding ASCII
}
exit $p.ExitCode


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Run-Logged.ps1
param([Parameter(Mandatory=$true)][string]$Cmd,
      [string]$Args="")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$LogD = Join-Path $Base "logs\install"
ni $LogD -ItemType Directory -ea SilentlyContinue | Out-Null
$log  = Join-Path $LogD "install_log.txt"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "[{0}] >> {1} {2}" -f $ts, $Cmd, $Args
Add-Content $log $line
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName  = $Cmd
$psi.Arguments = $Args
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$p.WaitForExit()
Add-Content $log ("[{0}] << exit {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $p.ExitCode)
if(-not (Test-Path (Join-Path $Base "reports\signals\system-structure-install-log.ok"))){
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-install-log.ok") -Encoding ASCII
}
exit $p.ExitCode


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Run-Logged.ps1
param([Parameter(Mandatory=$true)][string]$Cmd,
      [string]$Args="")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$LogD = Join-Path $Base "logs\install"
ni $LogD -ItemType Directory -ea SilentlyContinue | Out-Null
$log  = Join-Path $LogD "install_log.txt"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "[{0}] >> {1} {2}" -f $ts, $Cmd, $Args
Add-Content $log $line
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName  = $Cmd
$psi.Arguments = $Args
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$p.WaitForExit()
Add-Content $log ("[{0}] << exit {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $p.ExitCode)
if(-not (Test-Path (Join-Path $Base "reports\signals\system-structure-install-log.ok"))){
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-install-log.ok") -Encoding ASCII
}
exit $p.ExitCode


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Run-Logged.ps1
param([Parameter(Mandatory=$true)][string]$Cmd,
      [string]$Args="")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$LogD = Join-Path $Base "logs\install"
ni $LogD -ItemType Directory -ea SilentlyContinue | Out-Null
$log  = Join-Path $LogD "install_log.txt"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "[{0}] >> {1} {2}" -f $ts, $Cmd, $Args
Add-Content $log $line
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName  = $Cmd
$psi.Arguments = $Args
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$p.WaitForExit()
Add-Content $log ("[{0}] << exit {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $p.ExitCode)
if(-not (Test-Path (Join-Path $Base "reports\signals\system-structure-install-log.ok"))){
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-install-log.ok") -Encoding ASCII
}
exit $p.ExitCode


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Run-Logged.ps1
param([Parameter(Mandatory=$true)][string]$Cmd,
      [string]$Args="")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$LogD = Join-Path $Base "logs\install"
ni $LogD -ItemType Directory -ea SilentlyContinue | Out-Null
$log  = Join-Path $LogD "install_log.txt"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "[{0}] >> {1} {2}" -f $ts, $Cmd, $Args
Add-Content $log $line
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName  = $Cmd
$psi.Arguments = $Args
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$p.WaitForExit()
Add-Content $log ("[{0}] << exit {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $p.ExitCode)
if(-not (Test-Path (Join-Path $Base "reports\signals\system-structure-install-log.ok"))){
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-install-log.ok") -Encoding ASCII
}
exit $p.ExitCode


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Run-Logged.ps1
param([Parameter(Mandatory=$true)][string]$Cmd,
      [string]$Args="")
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$LogD = Join-Path $Base "logs\install"
ni $LogD -ItemType Directory -ea SilentlyContinue | Out-Null
$log  = Join-Path $LogD "install_log.txt"
$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "[{0}] >> {1} {2}" -f $ts, $Cmd, $Args
Add-Content $log $line
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName  = $Cmd
$psi.Arguments = $Args
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false
$p = [System.Diagnostics.Process]::Start($psi)
$p.WaitForExit()
Add-Content $log ("[{0}] << exit {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $p.ExitCode)
if(-not (Test-Path (Join-Path $Base "reports\signals\system-structure-install-log.ok"))){
  "ok" | Set-Content (Join-Path $Base "reports\signals\system-structure-install-log.ok") -Encoding ASCII
}
exit $p.ExitCode


