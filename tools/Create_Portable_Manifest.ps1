# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$files = Get-ChildItem $Base -Recurse -File | ? { $_.FullName -notmatch "\\dist\\releases\\" }
$rows = foreach($f in $files){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [ordered]@{ path=$f.FullName.Substring($Base.Length+1); bytes=$f.Length; sha256=$sha; lastWrite=$f.LastWriteTimeUtc.ToString("o") }
}
$manifest = [ordered]@{ base=$Base; generated=(Get-Date).ToString("o"); count=$rows.Count; files=$rows }
($manifest | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Dist 'manifest.json') -Encoding UTF8

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$files = Get-ChildItem $Base -Recurse -File | ? { $_.FullName -notmatch "\\dist\\releases\\" }
$rows = foreach($f in $files){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [ordered]@{ path=$f.FullName.Substring($Base.Length+1); bytes=$f.Length; sha256=$sha; lastWrite=$f.LastWriteTimeUtc.ToString("o") }
}
$manifest = [ordered]@{ base=$Base; generated=(Get-Date).ToString("o"); count=$rows.Count; files=$rows }
($manifest | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Dist 'manifest.json') -Encoding UTF8

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$files = Get-ChildItem $Base -Recurse -File | ? { $_.FullName -notmatch "\\dist\\releases\\" }
$rows = foreach($f in $files){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [ordered]@{ path=$f.FullName.Substring($Base.Length+1); bytes=$f.Length; sha256=$sha; lastWrite=$f.LastWriteTimeUtc.ToString("o") }
}
$manifest = [ordered]@{ base=$Base; generated=(Get-Date).ToString("o"); count=$rows.Count; files=$rows }
($manifest | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Dist 'manifest.json') -Encoding UTF8

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$files = Get-ChildItem $Base -Recurse -File | ? { $_.FullName -notmatch "\\dist\\releases\\" }
$rows = foreach($f in $files){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [ordered]@{ path=$f.FullName.Substring($Base.Length+1); bytes=$f.Length; sha256=$sha; lastWrite=$f.LastWriteTimeUtc.ToString("o") }
}
$manifest = [ordered]@{ base=$Base; generated=(Get-Date).ToString("o"); count=$rows.Count; files=$rows }
($manifest | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Dist 'manifest.json') -Encoding UTF8

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$files = Get-ChildItem $Base -Recurse -File | ? { $_.FullName -notmatch "\\dist\\releases\\" }
$rows = foreach($f in $files){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [ordered]@{ path=$f.FullName.Substring($Base.Length+1); bytes=$f.Length; sha256=$sha; lastWrite=$f.LastWriteTimeUtc.ToString("o") }
}
$manifest = [ordered]@{ base=$Base; generated=(Get-Date).ToString("o"); count=$rows.Count; files=$rows }
($manifest | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Dist 'manifest.json') -Encoding UTF8

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$files = Get-ChildItem $Base -Recurse -File | ? { $_.FullName -notmatch "\\dist\\releases\\" }
$rows = foreach($f in $files){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [ordered]@{ path=$f.FullName.Substring($Base.Length+1); bytes=$f.Length; sha256=$sha; lastWrite=$f.LastWriteTimeUtc.ToString("o") }
}
$manifest = [ordered]@{ base=$Base; generated=(Get-Date).ToString("o"); count=$rows.Count; files=$rows }
($manifest | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Dist 'manifest.json') -Encoding UTF8

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$files = Get-ChildItem $Base -Recurse -File | ? { $_.FullName -notmatch "\\dist\\releases\\" }
$rows = foreach($f in $files){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [ordered]@{ path=$f.FullName.Substring($Base.Length+1); bytes=$f.Length; sha256=$sha; lastWrite=$f.LastWriteTimeUtc.ToString("o") }
}
$manifest = [ordered]@{ base=$Base; generated=(Get-Date).ToString("o"); count=$rows.Count; files=$rows }
($manifest | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Dist 'manifest.json') -Encoding UTF8

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Dist = Join-Path $Base "dist"
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null
$files = Get-ChildItem $Base -Recurse -File | ? { $_.FullName -notmatch "\\dist\\releases\\" }
$rows = foreach($f in $files){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [ordered]@{ path=$f.FullName.Substring($Base.Length+1); bytes=$f.Length; sha256=$sha; lastWrite=$f.LastWriteTimeUtc.ToString("o") }
}
$manifest = [ordered]@{ base=$Base; generated=(Get-Date).ToString("o"); count=$rows.Count; files=$rows }
($manifest | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Dist 'manifest.json') -Encoding UTF8

