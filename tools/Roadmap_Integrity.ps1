# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Rdir = Join-Path $Base "roadmap"
ni $Rdir -ItemType Directory -ea SilentlyContinue | Out-Null

$items = @()
Get-ChildItem $Base -Filter "PHASE *.txt" -File -ea SilentlyContinue | %{
  $bytes = [IO.File]::ReadAllBytes($_.FullName)
  $sha   = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace('-','').ToLower()
  $items += [ordered]@{ file=$_.Name; sha256=$sha; size=$_.Length }
}
$meta = [ordered]@{ generated=(Get-Date).ToString("o"); count=$items.Count; files=$items }
($meta | ConvertTo-Json -Depth 5) | Set-Content (Join-Path $Rep 'roadmap_integrity.json') -Encoding UTF8

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Rdir = Join-Path $Base "roadmap"
ni $Rdir -ItemType Directory -ea SilentlyContinue | Out-Null

$items = @()
Get-ChildItem $Base -Filter "PHASE *.txt" -File -ea SilentlyContinue | %{
  $bytes = [IO.File]::ReadAllBytes($_.FullName)
  $sha   = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace('-','').ToLower()
  $items += [ordered]@{ file=$_.Name; sha256=$sha; size=$_.Length }
}
$meta = [ordered]@{ generated=(Get-Date).ToString("o"); count=$items.Count; files=$items }
($meta | ConvertTo-Json -Depth 5) | Set-Content (Join-Path $Rep 'roadmap_integrity.json') -Encoding UTF8

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Rdir = Join-Path $Base "roadmap"
ni $Rdir -ItemType Directory -ea SilentlyContinue | Out-Null

$items = @()
Get-ChildItem $Base -Filter "PHASE *.txt" -File -ea SilentlyContinue | %{
  $bytes = [IO.File]::ReadAllBytes($_.FullName)
  $sha   = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace('-','').ToLower()
  $items += [ordered]@{ file=$_.Name; sha256=$sha; size=$_.Length }
}
$meta = [ordered]@{ generated=(Get-Date).ToString("o"); count=$items.Count; files=$items }
($meta | ConvertTo-Json -Depth 5) | Set-Content (Join-Path $Rep 'roadmap_integrity.json') -Encoding UTF8

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Rdir = Join-Path $Base "roadmap"
ni $Rdir -ItemType Directory -ea SilentlyContinue | Out-Null

$items = @()
Get-ChildItem $Base -Filter "PHASE *.txt" -File -ea SilentlyContinue | %{
  $bytes = [IO.File]::ReadAllBytes($_.FullName)
  $sha   = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace('-','').ToLower()
  $items += [ordered]@{ file=$_.Name; sha256=$sha; size=$_.Length }
}
$meta = [ordered]@{ generated=(Get-Date).ToString("o"); count=$items.Count; files=$items }
($meta | ConvertTo-Json -Depth 5) | Set-Content (Join-Path $Rep 'roadmap_integrity.json') -Encoding UTF8

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Rdir = Join-Path $Base "roadmap"
ni $Rdir -ItemType Directory -ea SilentlyContinue | Out-Null

$items = @()
Get-ChildItem $Base -Filter "PHASE *.txt" -File -ea SilentlyContinue | %{
  $bytes = [IO.File]::ReadAllBytes($_.FullName)
  $sha   = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace('-','').ToLower()
  $items += [ordered]@{ file=$_.Name; sha256=$sha; size=$_.Length }
}
$meta = [ordered]@{ generated=(Get-Date).ToString("o"); count=$items.Count; files=$items }
($meta | ConvertTo-Json -Depth 5) | Set-Content (Join-Path $Rep 'roadmap_integrity.json') -Encoding UTF8

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Rdir = Join-Path $Base "roadmap"
ni $Rdir -ItemType Directory -ea SilentlyContinue | Out-Null

$items = @()
Get-ChildItem $Base -Filter "PHASE *.txt" -File -ea SilentlyContinue | %{
  $bytes = [IO.File]::ReadAllBytes($_.FullName)
  $sha   = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace('-','').ToLower()
  $items += [ordered]@{ file=$_.Name; sha256=$sha; size=$_.Length }
}
$meta = [ordered]@{ generated=(Get-Date).ToString("o"); count=$items.Count; files=$items }
($meta | ConvertTo-Json -Depth 5) | Set-Content (Join-Path $Rep 'roadmap_integrity.json') -Encoding UTF8

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Rdir = Join-Path $Base "roadmap"
ni $Rdir -ItemType Directory -ea SilentlyContinue | Out-Null

$items = @()
Get-ChildItem $Base -Filter "PHASE *.txt" -File -ea SilentlyContinue | %{
  $bytes = [IO.File]::ReadAllBytes($_.FullName)
  $sha   = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace('-','').ToLower()
  $items += [ordered]@{ file=$_.Name; sha256=$sha; size=$_.Length }
}
$meta = [ordered]@{ generated=(Get-Date).ToString("o"); count=$items.Count; files=$items }
($meta | ConvertTo-Json -Depth 5) | Set-Content (Join-Path $Rep 'roadmap_integrity.json') -Encoding UTF8

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Rdir = Join-Path $Base "roadmap"
ni $Rdir -ItemType Directory -ea SilentlyContinue | Out-Null

$items = @()
Get-ChildItem $Base -Filter "PHASE *.txt" -File -ea SilentlyContinue | %{
  $bytes = [IO.File]::ReadAllBytes($_.FullName)
  $sha   = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($bytes)).Replace('-','').ToLower()
  $items += [ordered]@{ file=$_.Name; sha256=$sha; size=$_.Length }
}
$meta = [ordered]@{ generated=(Get-Date).ToString("o"); count=$items.Count; files=$items }
($meta | ConvertTo-Json -Depth 5) | Set-Content (Join-Path $Rep 'roadmap_integrity.json') -Encoding UTF8

