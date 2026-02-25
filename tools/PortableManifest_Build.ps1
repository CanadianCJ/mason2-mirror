# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\PortableManifest_Build.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$OutDir = Join-Path $Base "reports"
$SigDir = Join-Path $OutDir "signals"
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null

$targets = @("tools","reports","roadmap","learn","ui","dist")
$entries = @()
foreach($t in $targets){
  $root = Join-Path $Base $t
  if(Test-Path $root){
    gci $root -Recurse -File | ForEach-Object {
      $p = $_.FullName
      $rel = Resolve-Path $p | % { $_.Path.Substring($Base.Length).TrimStart('\') }
      $hash = (Get-FileHash -Algorithm SHA256 -Path $p).Hash
      $ver = ""
      if($_.Extension -match '^(?:\.exe|\.dll)$'){
        try { $ver = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($p).FileVersion } catch {}
      }
      $entries += [pscustomobject]@{ rel=$rel; bytes=$_.Length; sha256=$hash; version=$ver }
    }
  }
}
$manifest = [pscustomobject]@{
  base = $Base
  generated = (Get-Date).ToString("s")
  files = $entries
}
$mf = Join-Path $OutDir "portable_manifest.json"
$manifest | ConvertTo-Json -Depth 6 | Set-Content $mf -Encoding UTF8
'ok' | Set-Content (Join-Path $SigDir 'system-structure-portable-manifest.ok') -Encoding ASCII
Write-Host "[ OK ] Manifest -> $mf"


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\PortableManifest_Build.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$OutDir = Join-Path $Base "reports"
$SigDir = Join-Path $OutDir "signals"
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null

$targets = @("tools","reports","roadmap","learn","ui","dist")
$entries = @()
foreach($t in $targets){
  $root = Join-Path $Base $t
  if(Test-Path $root){
    gci $root -Recurse -File | ForEach-Object {
      $p = $_.FullName
      $rel = Resolve-Path $p | % { $_.Path.Substring($Base.Length).TrimStart('\') }
      $hash = (Get-FileHash -Algorithm SHA256 -Path $p).Hash
      $ver = ""
      if($_.Extension -match '^(?:\.exe|\.dll)$'){
        try { $ver = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($p).FileVersion } catch {}
      }
      $entries += [pscustomobject]@{ rel=$rel; bytes=$_.Length; sha256=$hash; version=$ver }
    }
  }
}
$manifest = [pscustomobject]@{
  base = $Base
  generated = (Get-Date).ToString("s")
  files = $entries
}
$mf = Join-Path $OutDir "portable_manifest.json"
$manifest | ConvertTo-Json -Depth 6 | Set-Content $mf -Encoding UTF8
'ok' | Set-Content (Join-Path $SigDir 'system-structure-portable-manifest.ok') -Encoding ASCII
Write-Host "[ OK ] Manifest -> $mf"


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\PortableManifest_Build.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$OutDir = Join-Path $Base "reports"
$SigDir = Join-Path $OutDir "signals"
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null

$targets = @("tools","reports","roadmap","learn","ui","dist")
$entries = @()
foreach($t in $targets){
  $root = Join-Path $Base $t
  if(Test-Path $root){
    gci $root -Recurse -File | ForEach-Object {
      $p = $_.FullName
      $rel = Resolve-Path $p | % { $_.Path.Substring($Base.Length).TrimStart('\') }
      $hash = (Get-FileHash -Algorithm SHA256 -Path $p).Hash
      $ver = ""
      if($_.Extension -match '^(?:\.exe|\.dll)$'){
        try { $ver = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($p).FileVersion } catch {}
      }
      $entries += [pscustomobject]@{ rel=$rel; bytes=$_.Length; sha256=$hash; version=$ver }
    }
  }
}
$manifest = [pscustomobject]@{
  base = $Base
  generated = (Get-Date).ToString("s")
  files = $entries
}
$mf = Join-Path $OutDir "portable_manifest.json"
$manifest | ConvertTo-Json -Depth 6 | Set-Content $mf -Encoding UTF8
'ok' | Set-Content (Join-Path $SigDir 'system-structure-portable-manifest.ok') -Encoding ASCII
Write-Host "[ OK ] Manifest -> $mf"


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\PortableManifest_Build.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$OutDir = Join-Path $Base "reports"
$SigDir = Join-Path $OutDir "signals"
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null

$targets = @("tools","reports","roadmap","learn","ui","dist")
$entries = @()
foreach($t in $targets){
  $root = Join-Path $Base $t
  if(Test-Path $root){
    gci $root -Recurse -File | ForEach-Object {
      $p = $_.FullName
      $rel = Resolve-Path $p | % { $_.Path.Substring($Base.Length).TrimStart('\') }
      $hash = (Get-FileHash -Algorithm SHA256 -Path $p).Hash
      $ver = ""
      if($_.Extension -match '^(?:\.exe|\.dll)$'){
        try { $ver = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($p).FileVersion } catch {}
      }
      $entries += [pscustomobject]@{ rel=$rel; bytes=$_.Length; sha256=$hash; version=$ver }
    }
  }
}
$manifest = [pscustomobject]@{
  base = $Base
  generated = (Get-Date).ToString("s")
  files = $entries
}
$mf = Join-Path $OutDir "portable_manifest.json"
$manifest | ConvertTo-Json -Depth 6 | Set-Content $mf -Encoding UTF8
'ok' | Set-Content (Join-Path $SigDir 'system-structure-portable-manifest.ok') -Encoding ASCII
Write-Host "[ OK ] Manifest -> $mf"


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\PortableManifest_Build.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$OutDir = Join-Path $Base "reports"
$SigDir = Join-Path $OutDir "signals"
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null

$targets = @("tools","reports","roadmap","learn","ui","dist")
$entries = @()
foreach($t in $targets){
  $root = Join-Path $Base $t
  if(Test-Path $root){
    gci $root -Recurse -File | ForEach-Object {
      $p = $_.FullName
      $rel = Resolve-Path $p | % { $_.Path.Substring($Base.Length).TrimStart('\') }
      $hash = (Get-FileHash -Algorithm SHA256 -Path $p).Hash
      $ver = ""
      if($_.Extension -match '^(?:\.exe|\.dll)$'){
        try { $ver = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($p).FileVersion } catch {}
      }
      $entries += [pscustomobject]@{ rel=$rel; bytes=$_.Length; sha256=$hash; version=$ver }
    }
  }
}
$manifest = [pscustomobject]@{
  base = $Base
  generated = (Get-Date).ToString("s")
  files = $entries
}
$mf = Join-Path $OutDir "portable_manifest.json"
$manifest | ConvertTo-Json -Depth 6 | Set-Content $mf -Encoding UTF8
'ok' | Set-Content (Join-Path $SigDir 'system-structure-portable-manifest.ok') -Encoding ASCII
Write-Host "[ OK ] Manifest -> $mf"


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\PortableManifest_Build.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$OutDir = Join-Path $Base "reports"
$SigDir = Join-Path $OutDir "signals"
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null

$targets = @("tools","reports","roadmap","learn","ui","dist")
$entries = @()
foreach($t in $targets){
  $root = Join-Path $Base $t
  if(Test-Path $root){
    gci $root -Recurse -File | ForEach-Object {
      $p = $_.FullName
      $rel = Resolve-Path $p | % { $_.Path.Substring($Base.Length).TrimStart('\') }
      $hash = (Get-FileHash -Algorithm SHA256 -Path $p).Hash
      $ver = ""
      if($_.Extension -match '^(?:\.exe|\.dll)$'){
        try { $ver = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($p).FileVersion } catch {}
      }
      $entries += [pscustomobject]@{ rel=$rel; bytes=$_.Length; sha256=$hash; version=$ver }
    }
  }
}
$manifest = [pscustomobject]@{
  base = $Base
  generated = (Get-Date).ToString("s")
  files = $entries
}
$mf = Join-Path $OutDir "portable_manifest.json"
$manifest | ConvertTo-Json -Depth 6 | Set-Content $mf -Encoding UTF8
'ok' | Set-Content (Join-Path $SigDir 'system-structure-portable-manifest.ok') -Encoding ASCII
Write-Host "[ OK ] Manifest -> $mf"


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\PortableManifest_Build.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$OutDir = Join-Path $Base "reports"
$SigDir = Join-Path $OutDir "signals"
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null

$targets = @("tools","reports","roadmap","learn","ui","dist")
$entries = @()
foreach($t in $targets){
  $root = Join-Path $Base $t
  if(Test-Path $root){
    gci $root -Recurse -File | ForEach-Object {
      $p = $_.FullName
      $rel = Resolve-Path $p | % { $_.Path.Substring($Base.Length).TrimStart('\') }
      $hash = (Get-FileHash -Algorithm SHA256 -Path $p).Hash
      $ver = ""
      if($_.Extension -match '^(?:\.exe|\.dll)$'){
        try { $ver = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($p).FileVersion } catch {}
      }
      $entries += [pscustomobject]@{ rel=$rel; bytes=$_.Length; sha256=$hash; version=$ver }
    }
  }
}
$manifest = [pscustomobject]@{
  base = $Base
  generated = (Get-Date).ToString("s")
  files = $entries
}
$mf = Join-Path $OutDir "portable_manifest.json"
$manifest | ConvertTo-Json -Depth 6 | Set-Content $mf -Encoding UTF8
'ok' | Set-Content (Join-Path $SigDir 'system-structure-portable-manifest.ok') -Encoding ASCII
Write-Host "[ OK ] Manifest -> $mf"


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\PortableManifest_Build.ps1
param([string]$Base = (Join-Path $env:USERPROFILE "Desktop\Mason2"))
$OutDir = Join-Path $Base "reports"
$SigDir = Join-Path $OutDir "signals"
ni $OutDir -ItemType Directory -ea SilentlyContinue | Out-Null
ni $SigDir -ItemType Directory -ea SilentlyContinue | Out-Null

$targets = @("tools","reports","roadmap","learn","ui","dist")
$entries = @()
foreach($t in $targets){
  $root = Join-Path $Base $t
  if(Test-Path $root){
    gci $root -Recurse -File | ForEach-Object {
      $p = $_.FullName
      $rel = Resolve-Path $p | % { $_.Path.Substring($Base.Length).TrimStart('\') }
      $hash = (Get-FileHash -Algorithm SHA256 -Path $p).Hash
      $ver = ""
      if($_.Extension -match '^(?:\.exe|\.dll)$'){
        try { $ver = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($p).FileVersion } catch {}
      }
      $entries += [pscustomobject]@{ rel=$rel; bytes=$_.Length; sha256=$hash; version=$ver }
    }
  }
}
$manifest = [pscustomobject]@{
  base = $Base
  generated = (Get-Date).ToString("s")
  files = $entries
}
$mf = Join-Path $OutDir "portable_manifest.json"
$manifest | ConvertTo-Json -Depth 6 | Set-Content $mf -Encoding UTF8
'ok' | Set-Content (Join-Path $SigDir 'system-structure-portable-manifest.ok') -Encoding ASCII
Write-Host "[ OK ] Manifest -> $mf"


