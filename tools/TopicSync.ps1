# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds = Join-Path $Base "seeds"
$Rep   = Join-Path $Base "reports"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
$rows = foreach($f in (Get-ChildItem $Seeds -Recurse -File -ea SilentlyContinue)){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [pscustomobject]@{
    path = $f.FullName.Substring($Base.Length+1)
    bytes = $f.Length
    sha256 = $sha
    lastWrite = $f.LastWriteTimeUtc.ToString("o")
    ext = $f.Extension
  }
}
$idx = [ordered]@{ generated=(Get-Date).ToString("o"); count=$rows.Count; items=$rows }
($idx | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Rep "seeds_index.json") -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "topicsync" -Level "INFO" -Message "seeds indexed" -Props @{ count=$rows.Count }
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds = Join-Path $Base "seeds"
$Rep   = Join-Path $Base "reports"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
$rows = foreach($f in (Get-ChildItem $Seeds -Recurse -File -ea SilentlyContinue)){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [pscustomobject]@{
    path = $f.FullName.Substring($Base.Length+1)
    bytes = $f.Length
    sha256 = $sha
    lastWrite = $f.LastWriteTimeUtc.ToString("o")
    ext = $f.Extension
  }
}
$idx = [ordered]@{ generated=(Get-Date).ToString("o"); count=$rows.Count; items=$rows }
($idx | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Rep "seeds_index.json") -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "topicsync" -Level "INFO" -Message "seeds indexed" -Props @{ count=$rows.Count }
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds = Join-Path $Base "seeds"
$Rep   = Join-Path $Base "reports"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
$rows = foreach($f in (Get-ChildItem $Seeds -Recurse -File -ea SilentlyContinue)){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [pscustomobject]@{
    path = $f.FullName.Substring($Base.Length+1)
    bytes = $f.Length
    sha256 = $sha
    lastWrite = $f.LastWriteTimeUtc.ToString("o")
    ext = $f.Extension
  }
}
$idx = [ordered]@{ generated=(Get-Date).ToString("o"); count=$rows.Count; items=$rows }
($idx | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Rep "seeds_index.json") -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "topicsync" -Level "INFO" -Message "seeds indexed" -Props @{ count=$rows.Count }
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds = Join-Path $Base "seeds"
$Rep   = Join-Path $Base "reports"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
$rows = foreach($f in (Get-ChildItem $Seeds -Recurse -File -ea SilentlyContinue)){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [pscustomobject]@{
    path = $f.FullName.Substring($Base.Length+1)
    bytes = $f.Length
    sha256 = $sha
    lastWrite = $f.LastWriteTimeUtc.ToString("o")
    ext = $f.Extension
  }
}
$idx = [ordered]@{ generated=(Get-Date).ToString("o"); count=$rows.Count; items=$rows }
($idx | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Rep "seeds_index.json") -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "topicsync" -Level "INFO" -Message "seeds indexed" -Props @{ count=$rows.Count }
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds = Join-Path $Base "seeds"
$Rep   = Join-Path $Base "reports"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
$rows = foreach($f in (Get-ChildItem $Seeds -Recurse -File -ea SilentlyContinue)){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [pscustomobject]@{
    path = $f.FullName.Substring($Base.Length+1)
    bytes = $f.Length
    sha256 = $sha
    lastWrite = $f.LastWriteTimeUtc.ToString("o")
    ext = $f.Extension
  }
}
$idx = [ordered]@{ generated=(Get-Date).ToString("o"); count=$rows.Count; items=$rows }
($idx | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Rep "seeds_index.json") -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "topicsync" -Level "INFO" -Message "seeds indexed" -Props @{ count=$rows.Count }
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds = Join-Path $Base "seeds"
$Rep   = Join-Path $Base "reports"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
$rows = foreach($f in (Get-ChildItem $Seeds -Recurse -File -ea SilentlyContinue)){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [pscustomobject]@{
    path = $f.FullName.Substring($Base.Length+1)
    bytes = $f.Length
    sha256 = $sha
    lastWrite = $f.LastWriteTimeUtc.ToString("o")
    ext = $f.Extension
  }
}
$idx = [ordered]@{ generated=(Get-Date).ToString("o"); count=$rows.Count; items=$rows }
($idx | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Rep "seeds_index.json") -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "topicsync" -Level "INFO" -Message "seeds indexed" -Props @{ count=$rows.Count }
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds = Join-Path $Base "seeds"
$Rep   = Join-Path $Base "reports"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
$rows = foreach($f in (Get-ChildItem $Seeds -Recurse -File -ea SilentlyContinue)){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [pscustomobject]@{
    path = $f.FullName.Substring($Base.Length+1)
    bytes = $f.Length
    sha256 = $sha
    lastWrite = $f.LastWriteTimeUtc.ToString("o")
    ext = $f.Extension
  }
}
$idx = [ordered]@{ generated=(Get-Date).ToString("o"); count=$rows.Count; items=$rows }
($idx | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Rep "seeds_index.json") -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "topicsync" -Level "INFO" -Message "seeds indexed" -Props @{ count=$rows.Count }
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.3.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base  = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds = Join-Path $Base "seeds"
$Rep   = Join-Path $Base "reports"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
$rows = foreach($f in (Get-ChildItem $Seeds -Recurse -File -ea SilentlyContinue)){
  $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([IO.File]::ReadAllBytes($f.FullName))).Replace('-','').ToLower()
  [pscustomobject]@{
    path = $f.FullName.Substring($Base.Length+1)
    bytes = $f.Length
    sha256 = $sha
    lastWrite = $f.LastWriteTimeUtc.ToString("o")
    ext = $f.Extension
  }
}
$idx = [ordered]@{ generated=(Get-Date).ToString("o"); count=$rows.Count; items=$rows }
($idx | ConvertTo-Json -Depth 6) | Set-Content (Join-Path $Rep "seeds_index.json") -Encoding UTF8
if (Get-Command Write-JsonLog -ea SilentlyContinue) {
  Write-JsonLog -Component "topicsync" -Level "INFO" -Message "seeds indexed" -Props @{ count=$rows.Count }
}

