# Stamped: 2025-11-05T17:02:01
param([int]$KeepN)
. (Join-Path $PSScriptRoot 'Common.ps1')
$cfg = Read-Config
if(-not $KeepN){ $KeepN = [int]$cfg.KeepTopN }
$rel = $script:Paths.Releases
if(!(Test-Path $rel)){ return }
$z = Get-ChildItem $rel -File -Filter 'Mason2_*.zip'       | Sort-Object LastWriteTime -Desc
$h = Get-ChildItem $rel -File -Filter 'Mason2_*.zip.sha256'| Sort-Object LastWriteTime -Desc
$z | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
$h | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Output "Kept top $KeepN releases; trimmed the rest."

exit 0


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([int]$KeepN)
. (Join-Path $PSScriptRoot 'Common.ps1')
$cfg = Read-Config
if(-not $KeepN){ $KeepN = [int]$cfg.KeepTopN }
$rel = $script:Paths.Releases
if(!(Test-Path $rel)){ return }
$z = Get-ChildItem $rel -File -Filter 'Mason2_*.zip'       | Sort-Object LastWriteTime -Desc
$h = Get-ChildItem $rel -File -Filter 'Mason2_*.zip.sha256'| Sort-Object LastWriteTime -Desc
$z | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
$h | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Output "Kept top $KeepN releases; trimmed the rest."

exit 0


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([int]$KeepN)
. (Join-Path $PSScriptRoot 'Common.ps1')
$cfg = Read-Config
if(-not $KeepN){ $KeepN = [int]$cfg.KeepTopN }
$rel = $script:Paths.Releases
if(!(Test-Path $rel)){ return }
$z = Get-ChildItem $rel -File -Filter 'Mason2_*.zip'       | Sort-Object LastWriteTime -Desc
$h = Get-ChildItem $rel -File -Filter 'Mason2_*.zip.sha256'| Sort-Object LastWriteTime -Desc
$z | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
$h | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Output "Kept top $KeepN releases; trimmed the rest."

exit 0


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([int]$KeepN)
. (Join-Path $PSScriptRoot 'Common.ps1')
$cfg = Read-Config
if(-not $KeepN){ $KeepN = [int]$cfg.KeepTopN }
$rel = $script:Paths.Releases
if(!(Test-Path $rel)){ return }
$z = Get-ChildItem $rel -File -Filter 'Mason2_*.zip'       | Sort-Object LastWriteTime -Desc
$h = Get-ChildItem $rel -File -Filter 'Mason2_*.zip.sha256'| Sort-Object LastWriteTime -Desc
$z | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
$h | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Output "Kept top $KeepN releases; trimmed the rest."

exit 0


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([int]$KeepN)
. (Join-Path $PSScriptRoot 'Common.ps1')
$cfg = Read-Config
if(-not $KeepN){ $KeepN = [int]$cfg.KeepTopN }
$rel = $script:Paths.Releases
if(!(Test-Path $rel)){ return }
$z = Get-ChildItem $rel -File -Filter 'Mason2_*.zip'       | Sort-Object LastWriteTime -Desc
$h = Get-ChildItem $rel -File -Filter 'Mason2_*.zip.sha256'| Sort-Object LastWriteTime -Desc
$z | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
$h | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Output "Kept top $KeepN releases; trimmed the rest."

exit 0


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([int]$KeepN)
. (Join-Path $PSScriptRoot 'Common.ps1')
$cfg = Read-Config
if(-not $KeepN){ $KeepN = [int]$cfg.KeepTopN }
$rel = $script:Paths.Releases
if(!(Test-Path $rel)){ return }
$z = Get-ChildItem $rel -File -Filter 'Mason2_*.zip'       | Sort-Object LastWriteTime -Desc
$h = Get-ChildItem $rel -File -Filter 'Mason2_*.zip.sha256'| Sort-Object LastWriteTime -Desc
$z | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
$h | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Output "Kept top $KeepN releases; trimmed the rest."

exit 0


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([int]$KeepN)
. (Join-Path $PSScriptRoot 'Common.ps1')
$cfg = Read-Config
if(-not $KeepN){ $KeepN = [int]$cfg.KeepTopN }
$rel = $script:Paths.Releases
if(!(Test-Path $rel)){ return }
$z = Get-ChildItem $rel -File -Filter 'Mason2_*.zip'       | Sort-Object LastWriteTime -Desc
$h = Get-ChildItem $rel -File -Filter 'Mason2_*.zip.sha256'| Sort-Object LastWriteTime -Desc
$z | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
$h | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Output "Kept top $KeepN releases; trimmed the rest."

exit 0


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([int]$KeepN)
. (Join-Path $PSScriptRoot 'Common.ps1')
$cfg = Read-Config
if(-not $KeepN){ $KeepN = [int]$cfg.KeepTopN }
$rel = $script:Paths.Releases
if(!(Test-Path $rel)){ return }
$z = Get-ChildItem $rel -File -Filter 'Mason2_*.zip'       | Sort-Object LastWriteTime -Desc
$h = Get-ChildItem $rel -File -Filter 'Mason2_*.zip.sha256'| Sort-Object LastWriteTime -Desc
$z | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
$h | Select-Object -Skip $KeepN | Remove-Item -Force -ErrorAction SilentlyContinue
Write-Output "Kept top $KeepN releases; trimmed the rest."

exit 0


