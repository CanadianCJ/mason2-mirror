$Base = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
$Dump = Join-Path $Base 'crashdumps'
New-Item -ItemType Directory -Force -Path $Dump | Out-Null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpType /t REG_DWORD /d 2 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpCount /t REG_DWORD /d 10 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpFolder /t REG_EXPAND_SZ /d "$Dump" /f >$null
Out-MasonJsonl -Kind 'crash' -Event 'localdumps_enabled' -Level 'INFO' -Data @{ folder=$Dump }_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
$Dump = Join-Path $Base 'crashdumps'
New-Item -ItemType Directory -Force -Path $Dump | Out-Null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpType /t REG_DWORD /d 2 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpCount /t REG_DWORD /d 10 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpFolder /t REG_EXPAND_SZ /d "$Dump" /f >$null
Out-MasonJsonl -Kind 'crash' -Event 'localdumps_enabled' -Level 'INFO' -Data @{ folder=$Dump }_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
$Dump = Join-Path $Base 'crashdumps'
New-Item -ItemType Directory -Force -Path $Dump | Out-Null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpType /t REG_DWORD /d 2 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpCount /t REG_DWORD /d 10 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpFolder /t REG_EXPAND_SZ /d "$Dump" /f >$null
Out-MasonJsonl -Kind 'crash' -Event 'localdumps_enabled' -Level 'INFO' -Data @{ folder=$Dump }_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
$Dump = Join-Path $Base 'crashdumps'
New-Item -ItemType Directory -Force -Path $Dump | Out-Null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpType /t REG_DWORD /d 2 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpCount /t REG_DWORD /d 10 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpFolder /t REG_EXPAND_SZ /d "$Dump" /f >$null
Out-MasonJsonl -Kind 'crash' -Event 'localdumps_enabled' -Level 'INFO' -Data @{ folder=$Dump }_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
$Dump = Join-Path $Base 'crashdumps'
New-Item -ItemType Directory -Force -Path $Dump | Out-Null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpType /t REG_DWORD /d 2 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpCount /t REG_DWORD /d 10 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpFolder /t REG_EXPAND_SZ /d "$Dump" /f >$null
Out-MasonJsonl -Kind 'crash' -Event 'localdumps_enabled' -Level 'INFO' -Data @{ folder=$Dump }_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
$Dump = Join-Path $Base 'crashdumps'
New-Item -ItemType Directory -Force -Path $Dump | Out-Null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpType /t REG_DWORD /d 2 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpCount /t REG_DWORD /d 10 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpFolder /t REG_EXPAND_SZ /d "$Dump" /f >$null
Out-MasonJsonl -Kind 'crash' -Event 'localdumps_enabled' -Level 'INFO' -Data @{ folder=$Dump }_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$Base = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
$Dump = Join-Path $Base 'crashdumps'
New-Item -ItemType Directory -Force -Path $Dump | Out-Null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpType /t REG_DWORD /d 2 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpCount /t REG_DWORD /d 10 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpFolder /t REG_EXPAND_SZ /d "$Dump" /f >$null
Out-MasonJsonl -Kind 'crash' -Event 'localdumps_enabled' -Level 'INFO' -Data @{ folder=$Dump }_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$Base = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
$Dump = Join-Path $Base 'crashdumps'
New-Item -ItemType Directory -Force -Path $Dump | Out-Null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpType /t REG_DWORD /d 2 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpCount /t REG_DWORD /d 10 /f >$null
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\powershell.exe" /v DumpFolder /t REG_EXPAND_SZ /d "$Dump" /f >$null
Out-MasonJsonl -Kind 'crash' -Event 'localdumps_enabled' -Level 'INFO' -Data @{ folder=$Dump }