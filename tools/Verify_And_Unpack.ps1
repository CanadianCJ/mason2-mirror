# Stamped: 2025-11-05T17:02:01
param(
  [Parameter(Mandatory=$true)][string]$Bundle,
  [switch]$Apply
)
. (Join-Path $PSScriptRoot 'Common.ps1')

$paths = $script:Paths
$rep   = Join-Path $paths.Reports 'verify_unpack.jsonl'

if(!(Test-Path -LiteralPath $Bundle -PathType Leaf)){ throw "Bundle not found: $Bundle" }
$zip = Open-Zip $Bundle
try{
  # extract to stage
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $stage = Join-Path $paths.Dist ("unpacked-verify-mason2-$stamp")
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  [IO.Compression.ZipFile]::ExtractToDirectory($Bundle,$stage)

  # compare to manifest
  $manifestFile = Join-Path $stage 'manifest.json'
  if(!(Test-Path $manifestFile)){ throw 'manifest.json missing in bundle' }
  $man = Get-Content $manifestFile -Raw | ConvertFrom-Json
  $manFiles = @{}
  foreach($f in $man.files){ $manFiles[$f.path] = $f }

  $zipEntries = @{}
  foreach($e in $zip.Entries){ if($e.FullName -ne 'manifest.json' -and $e.FullName -notmatch '/$'){ $zipEntries[$e.FullName] = $true } }

  # set counts
  $zipCount = $zipEntries.Keys.Count + 1  # +manifest
  $manCount = $man.files.Count + 1

  # sha256 verify every file listed in manifest
  $badHash = @()
  foreach($kv in $manFiles.GetEnumerator()){
    $rel = $kv.Key
    $dst = Join-Path $stage $rel
    if(!(Test-Path $dst)){ throw "File from manifest missing after extract: $rel" }
    $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $dst).Hash
    if($h -ne $kv.Value.sha256){ $badHash += $rel }
  }

  # zip vs manifest membership
  $zipNotInMan = @()
  foreach($k in $zipEntries.Keys){ if(-not $manFiles.ContainsKey($k) -and $k -ne 'manifest.json'){ $zipNotInMan += $k } }
  $manNotInZip = @()
  foreach($k in $manFiles.Keys){ if(-not $zipEntries.ContainsKey($k)){ $manNotInZip += $k } }

  if($badHash.Count){ throw "Hash mismatch: $($badHash -join ', ')" }
  if($zipNotInMan.Count){ throw "Zip has extra files not in manifest: $($zipNotInMan -join ', ')" }
  if($manNotInZip.Count){ throw "Manifest lists files missing in zip: $($manNotInZip -join ', ')" }

  # success ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â optionally apply atomically
  $applied = $false
  if($Apply){
    Atomic-Swap -newDir $stage -currentDir $paths.Current
    $applied = $true
  }

  Write-JsonLine $rep ([pscustomobject]@{
    ts = (Get-Date).ToString('o')
    bundle = [IO.Path]::GetFileName($Bundle)
    applied = $applied
    zip_count = $zipCount
    manifest_count = $manCount
    ok = $true
  })
  if(-not $Apply){ Write-Output "Verified + unpacked to: $stage (not applied)" } else { Write-Output "Verified + applied atomically to: $($paths.Current)" }
}
finally { $zip.Dispose() }

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [Parameter(Mandatory=$true)][string]$Bundle,
  [switch]$Apply
)
. (Join-Path $PSScriptRoot 'Common.ps1')

$paths = $script:Paths
$rep   = Join-Path $paths.Reports 'verify_unpack.jsonl'

if(!(Test-Path -LiteralPath $Bundle -PathType Leaf)){ throw "Bundle not found: $Bundle" }
$zip = Open-Zip $Bundle
try{
  # extract to stage
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $stage = Join-Path $paths.Dist ("unpacked-verify-mason2-$stamp")
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  [IO.Compression.ZipFile]::ExtractToDirectory($Bundle,$stage)

  # compare to manifest
  $manifestFile = Join-Path $stage 'manifest.json'
  if(!(Test-Path $manifestFile)){ throw 'manifest.json missing in bundle' }
  $man = Get-Content $manifestFile -Raw | ConvertFrom-Json
  $manFiles = @{}
  foreach($f in $man.files){ $manFiles[$f.path] = $f }

  $zipEntries = @{}
  foreach($e in $zip.Entries){ if($e.FullName -ne 'manifest.json' -and $e.FullName -notmatch '/$'){ $zipEntries[$e.FullName] = $true } }

  # set counts
  $zipCount = $zipEntries.Keys.Count + 1  # +manifest
  $manCount = $man.files.Count + 1

  # sha256 verify every file listed in manifest
  $badHash = @()
  foreach($kv in $manFiles.GetEnumerator()){
    $rel = $kv.Key
    $dst = Join-Path $stage $rel
    if(!(Test-Path $dst)){ throw "File from manifest missing after extract: $rel" }
    $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $dst).Hash
    if($h -ne $kv.Value.sha256){ $badHash += $rel }
  }

  # zip vs manifest membership
  $zipNotInMan = @()
  foreach($k in $zipEntries.Keys){ if(-not $manFiles.ContainsKey($k) -and $k -ne 'manifest.json'){ $zipNotInMan += $k } }
  $manNotInZip = @()
  foreach($k in $manFiles.Keys){ if(-not $zipEntries.ContainsKey($k)){ $manNotInZip += $k } }

  if($badHash.Count){ throw "Hash mismatch: $($badHash -join ', ')" }
  if($zipNotInMan.Count){ throw "Zip has extra files not in manifest: $($zipNotInMan -join ', ')" }
  if($manNotInZip.Count){ throw "Manifest lists files missing in zip: $($manNotInZip -join ', ')" }

  # success ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â optionally apply atomically
  $applied = $false
  if($Apply){
    Atomic-Swap -newDir $stage -currentDir $paths.Current
    $applied = $true
  }

  Write-JsonLine $rep ([pscustomobject]@{
    ts = (Get-Date).ToString('o')
    bundle = [IO.Path]::GetFileName($Bundle)
    applied = $applied
    zip_count = $zipCount
    manifest_count = $manCount
    ok = $true
  })
  if(-not $Apply){ Write-Output "Verified + unpacked to: $stage (not applied)" } else { Write-Output "Verified + applied atomically to: $($paths.Current)" }
}
finally { $zip.Dispose() }

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [Parameter(Mandatory=$true)][string]$Bundle,
  [switch]$Apply
)
. (Join-Path $PSScriptRoot 'Common.ps1')

$paths = $script:Paths
$rep   = Join-Path $paths.Reports 'verify_unpack.jsonl'

if(!(Test-Path -LiteralPath $Bundle -PathType Leaf)){ throw "Bundle not found: $Bundle" }
$zip = Open-Zip $Bundle
try{
  # extract to stage
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $stage = Join-Path $paths.Dist ("unpacked-verify-mason2-$stamp")
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  [IO.Compression.ZipFile]::ExtractToDirectory($Bundle,$stage)

  # compare to manifest
  $manifestFile = Join-Path $stage 'manifest.json'
  if(!(Test-Path $manifestFile)){ throw 'manifest.json missing in bundle' }
  $man = Get-Content $manifestFile -Raw | ConvertFrom-Json
  $manFiles = @{}
  foreach($f in $man.files){ $manFiles[$f.path] = $f }

  $zipEntries = @{}
  foreach($e in $zip.Entries){ if($e.FullName -ne 'manifest.json' -and $e.FullName -notmatch '/$'){ $zipEntries[$e.FullName] = $true } }

  # set counts
  $zipCount = $zipEntries.Keys.Count + 1  # +manifest
  $manCount = $man.files.Count + 1

  # sha256 verify every file listed in manifest
  $badHash = @()
  foreach($kv in $manFiles.GetEnumerator()){
    $rel = $kv.Key
    $dst = Join-Path $stage $rel
    if(!(Test-Path $dst)){ throw "File from manifest missing after extract: $rel" }
    $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $dst).Hash
    if($h -ne $kv.Value.sha256){ $badHash += $rel }
  }

  # zip vs manifest membership
  $zipNotInMan = @()
  foreach($k in $zipEntries.Keys){ if(-not $manFiles.ContainsKey($k) -and $k -ne 'manifest.json'){ $zipNotInMan += $k } }
  $manNotInZip = @()
  foreach($k in $manFiles.Keys){ if(-not $zipEntries.ContainsKey($k)){ $manNotInZip += $k } }

  if($badHash.Count){ throw "Hash mismatch: $($badHash -join ', ')" }
  if($zipNotInMan.Count){ throw "Zip has extra files not in manifest: $($zipNotInMan -join ', ')" }
  if($manNotInZip.Count){ throw "Manifest lists files missing in zip: $($manNotInZip -join ', ')" }

  # success ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â optionally apply atomically
  $applied = $false
  if($Apply){
    Atomic-Swap -newDir $stage -currentDir $paths.Current
    $applied = $true
  }

  Write-JsonLine $rep ([pscustomobject]@{
    ts = (Get-Date).ToString('o')
    bundle = [IO.Path]::GetFileName($Bundle)
    applied = $applied
    zip_count = $zipCount
    manifest_count = $manCount
    ok = $true
  })
  if(-not $Apply){ Write-Output "Verified + unpacked to: $stage (not applied)" } else { Write-Output "Verified + applied atomically to: $($paths.Current)" }
}
finally { $zip.Dispose() }

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [Parameter(Mandatory=$true)][string]$Bundle,
  [switch]$Apply
)
. (Join-Path $PSScriptRoot 'Common.ps1')

$paths = $script:Paths
$rep   = Join-Path $paths.Reports 'verify_unpack.jsonl'

if(!(Test-Path -LiteralPath $Bundle -PathType Leaf)){ throw "Bundle not found: $Bundle" }
$zip = Open-Zip $Bundle
try{
  # extract to stage
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $stage = Join-Path $paths.Dist ("unpacked-verify-mason2-$stamp")
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  [IO.Compression.ZipFile]::ExtractToDirectory($Bundle,$stage)

  # compare to manifest
  $manifestFile = Join-Path $stage 'manifest.json'
  if(!(Test-Path $manifestFile)){ throw 'manifest.json missing in bundle' }
  $man = Get-Content $manifestFile -Raw | ConvertFrom-Json
  $manFiles = @{}
  foreach($f in $man.files){ $manFiles[$f.path] = $f }

  $zipEntries = @{}
  foreach($e in $zip.Entries){ if($e.FullName -ne 'manifest.json' -and $e.FullName -notmatch '/$'){ $zipEntries[$e.FullName] = $true } }

  # set counts
  $zipCount = $zipEntries.Keys.Count + 1  # +manifest
  $manCount = $man.files.Count + 1

  # sha256 verify every file listed in manifest
  $badHash = @()
  foreach($kv in $manFiles.GetEnumerator()){
    $rel = $kv.Key
    $dst = Join-Path $stage $rel
    if(!(Test-Path $dst)){ throw "File from manifest missing after extract: $rel" }
    $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $dst).Hash
    if($h -ne $kv.Value.sha256){ $badHash += $rel }
  }

  # zip vs manifest membership
  $zipNotInMan = @()
  foreach($k in $zipEntries.Keys){ if(-not $manFiles.ContainsKey($k) -and $k -ne 'manifest.json'){ $zipNotInMan += $k } }
  $manNotInZip = @()
  foreach($k in $manFiles.Keys){ if(-not $zipEntries.ContainsKey($k)){ $manNotInZip += $k } }

  if($badHash.Count){ throw "Hash mismatch: $($badHash -join ', ')" }
  if($zipNotInMan.Count){ throw "Zip has extra files not in manifest: $($zipNotInMan -join ', ')" }
  if($manNotInZip.Count){ throw "Manifest lists files missing in zip: $($manNotInZip -join ', ')" }

  # success ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â optionally apply atomically
  $applied = $false
  if($Apply){
    Atomic-Swap -newDir $stage -currentDir $paths.Current
    $applied = $true
  }

  Write-JsonLine $rep ([pscustomobject]@{
    ts = (Get-Date).ToString('o')
    bundle = [IO.Path]::GetFileName($Bundle)
    applied = $applied
    zip_count = $zipCount
    manifest_count = $manCount
    ok = $true
  })
  if(-not $Apply){ Write-Output "Verified + unpacked to: $stage (not applied)" } else { Write-Output "Verified + applied atomically to: $($paths.Current)" }
}
finally { $zip.Dispose() }

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [Parameter(Mandatory=$true)][string]$Bundle,
  [switch]$Apply
)
. (Join-Path $PSScriptRoot 'Common.ps1')

$paths = $script:Paths
$rep   = Join-Path $paths.Reports 'verify_unpack.jsonl'

if(!(Test-Path -LiteralPath $Bundle -PathType Leaf)){ throw "Bundle not found: $Bundle" }
$zip = Open-Zip $Bundle
try{
  # extract to stage
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $stage = Join-Path $paths.Dist ("unpacked-verify-mason2-$stamp")
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  [IO.Compression.ZipFile]::ExtractToDirectory($Bundle,$stage)

  # compare to manifest
  $manifestFile = Join-Path $stage 'manifest.json'
  if(!(Test-Path $manifestFile)){ throw 'manifest.json missing in bundle' }
  $man = Get-Content $manifestFile -Raw | ConvertFrom-Json
  $manFiles = @{}
  foreach($f in $man.files){ $manFiles[$f.path] = $f }

  $zipEntries = @{}
  foreach($e in $zip.Entries){ if($e.FullName -ne 'manifest.json' -and $e.FullName -notmatch '/$'){ $zipEntries[$e.FullName] = $true } }

  # set counts
  $zipCount = $zipEntries.Keys.Count + 1  # +manifest
  $manCount = $man.files.Count + 1

  # sha256 verify every file listed in manifest
  $badHash = @()
  foreach($kv in $manFiles.GetEnumerator()){
    $rel = $kv.Key
    $dst = Join-Path $stage $rel
    if(!(Test-Path $dst)){ throw "File from manifest missing after extract: $rel" }
    $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $dst).Hash
    if($h -ne $kv.Value.sha256){ $badHash += $rel }
  }

  # zip vs manifest membership
  $zipNotInMan = @()
  foreach($k in $zipEntries.Keys){ if(-not $manFiles.ContainsKey($k) -and $k -ne 'manifest.json'){ $zipNotInMan += $k } }
  $manNotInZip = @()
  foreach($k in $manFiles.Keys){ if(-not $zipEntries.ContainsKey($k)){ $manNotInZip += $k } }

  if($badHash.Count){ throw "Hash mismatch: $($badHash -join ', ')" }
  if($zipNotInMan.Count){ throw "Zip has extra files not in manifest: $($zipNotInMan -join ', ')" }
  if($manNotInZip.Count){ throw "Manifest lists files missing in zip: $($manNotInZip -join ', ')" }

  # success ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â optionally apply atomically
  $applied = $false
  if($Apply){
    Atomic-Swap -newDir $stage -currentDir $paths.Current
    $applied = $true
  }

  Write-JsonLine $rep ([pscustomobject]@{
    ts = (Get-Date).ToString('o')
    bundle = [IO.Path]::GetFileName($Bundle)
    applied = $applied
    zip_count = $zipCount
    manifest_count = $manCount
    ok = $true
  })
  if(-not $Apply){ Write-Output "Verified + unpacked to: $stage (not applied)" } else { Write-Output "Verified + applied atomically to: $($paths.Current)" }
}
finally { $zip.Dispose() }

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [Parameter(Mandatory=$true)][string]$Bundle,
  [switch]$Apply
)
. (Join-Path $PSScriptRoot 'Common.ps1')

$paths = $script:Paths
$rep   = Join-Path $paths.Reports 'verify_unpack.jsonl'

if(!(Test-Path -LiteralPath $Bundle -PathType Leaf)){ throw "Bundle not found: $Bundle" }
$zip = Open-Zip $Bundle
try{
  # extract to stage
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $stage = Join-Path $paths.Dist ("unpacked-verify-mason2-$stamp")
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  [IO.Compression.ZipFile]::ExtractToDirectory($Bundle,$stage)

  # compare to manifest
  $manifestFile = Join-Path $stage 'manifest.json'
  if(!(Test-Path $manifestFile)){ throw 'manifest.json missing in bundle' }
  $man = Get-Content $manifestFile -Raw | ConvertFrom-Json
  $manFiles = @{}
  foreach($f in $man.files){ $manFiles[$f.path] = $f }

  $zipEntries = @{}
  foreach($e in $zip.Entries){ if($e.FullName -ne 'manifest.json' -and $e.FullName -notmatch '/$'){ $zipEntries[$e.FullName] = $true } }

  # set counts
  $zipCount = $zipEntries.Keys.Count + 1  # +manifest
  $manCount = $man.files.Count + 1

  # sha256 verify every file listed in manifest
  $badHash = @()
  foreach($kv in $manFiles.GetEnumerator()){
    $rel = $kv.Key
    $dst = Join-Path $stage $rel
    if(!(Test-Path $dst)){ throw "File from manifest missing after extract: $rel" }
    $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $dst).Hash
    if($h -ne $kv.Value.sha256){ $badHash += $rel }
  }

  # zip vs manifest membership
  $zipNotInMan = @()
  foreach($k in $zipEntries.Keys){ if(-not $manFiles.ContainsKey($k) -and $k -ne 'manifest.json'){ $zipNotInMan += $k } }
  $manNotInZip = @()
  foreach($k in $manFiles.Keys){ if(-not $zipEntries.ContainsKey($k)){ $manNotInZip += $k } }

  if($badHash.Count){ throw "Hash mismatch: $($badHash -join ', ')" }
  if($zipNotInMan.Count){ throw "Zip has extra files not in manifest: $($zipNotInMan -join ', ')" }
  if($manNotInZip.Count){ throw "Manifest lists files missing in zip: $($manNotInZip -join ', ')" }

  # success ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â optionally apply atomically
  $applied = $false
  if($Apply){
    Atomic-Swap -newDir $stage -currentDir $paths.Current
    $applied = $true
  }

  Write-JsonLine $rep ([pscustomobject]@{
    ts = (Get-Date).ToString('o')
    bundle = [IO.Path]::GetFileName($Bundle)
    applied = $applied
    zip_count = $zipCount
    manifest_count = $manCount
    ok = $true
  })
  if(-not $Apply){ Write-Output "Verified + unpacked to: $stage (not applied)" } else { Write-Output "Verified + applied atomically to: $($paths.Current)" }
}
finally { $zip.Dispose() }

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param(
  [Parameter(Mandatory=$true)][string]$Bundle,
  [switch]$Apply
)
. (Join-Path $PSScriptRoot 'Common.ps1')

$paths = $script:Paths
$rep   = Join-Path $paths.Reports 'verify_unpack.jsonl'

if(!(Test-Path -LiteralPath $Bundle -PathType Leaf)){ throw "Bundle not found: $Bundle" }
$zip = Open-Zip $Bundle
try{
  # extract to stage
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $stage = Join-Path $paths.Dist ("unpacked-verify-mason2-$stamp")
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  [IO.Compression.ZipFile]::ExtractToDirectory($Bundle,$stage)

  # compare to manifest
  $manifestFile = Join-Path $stage 'manifest.json'
  if(!(Test-Path $manifestFile)){ throw 'manifest.json missing in bundle' }
  $man = Get-Content $manifestFile -Raw | ConvertFrom-Json
  $manFiles = @{}
  foreach($f in $man.files){ $manFiles[$f.path] = $f }

  $zipEntries = @{}
  foreach($e in $zip.Entries){ if($e.FullName -ne 'manifest.json' -and $e.FullName -notmatch '/$'){ $zipEntries[$e.FullName] = $true } }

  # set counts
  $zipCount = $zipEntries.Keys.Count + 1  # +manifest
  $manCount = $man.files.Count + 1

  # sha256 verify every file listed in manifest
  $badHash = @()
  foreach($kv in $manFiles.GetEnumerator()){
    $rel = $kv.Key
    $dst = Join-Path $stage $rel
    if(!(Test-Path $dst)){ throw "File from manifest missing after extract: $rel" }
    $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $dst).Hash
    if($h -ne $kv.Value.sha256){ $badHash += $rel }
  }

  # zip vs manifest membership
  $zipNotInMan = @()
  foreach($k in $zipEntries.Keys){ if(-not $manFiles.ContainsKey($k) -and $k -ne 'manifest.json'){ $zipNotInMan += $k } }
  $manNotInZip = @()
  foreach($k in $manFiles.Keys){ if(-not $zipEntries.ContainsKey($k)){ $manNotInZip += $k } }

  if($badHash.Count){ throw "Hash mismatch: $($badHash -join ', ')" }
  if($zipNotInMan.Count){ throw "Zip has extra files not in manifest: $($zipNotInMan -join ', ')" }
  if($manNotInZip.Count){ throw "Manifest lists files missing in zip: $($manNotInZip -join ', ')" }

  # success ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â optionally apply atomically
  $applied = $false
  if($Apply){
    Atomic-Swap -newDir $stage -currentDir $paths.Current
    $applied = $true
  }

  Write-JsonLine $rep ([pscustomobject]@{
    ts = (Get-Date).ToString('o')
    bundle = [IO.Path]::GetFileName($Bundle)
    applied = $applied
    zip_count = $zipCount
    manifest_count = $manCount
    ok = $true
  })
  if(-not $Apply){ Write-Output "Verified + unpacked to: $stage (not applied)" } else { Write-Output "Verified + applied atomically to: $($paths.Current)" }
}
finally { $zip.Dispose() }

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param(
  [Parameter(Mandatory=$true)][string]$Bundle,
  [switch]$Apply
)
. (Join-Path $PSScriptRoot 'Common.ps1')

$paths = $script:Paths
$rep   = Join-Path $paths.Reports 'verify_unpack.jsonl'

if(!(Test-Path -LiteralPath $Bundle -PathType Leaf)){ throw "Bundle not found: $Bundle" }
$zip = Open-Zip $Bundle
try{
  # extract to stage
  $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $stage = Join-Path $paths.Dist ("unpacked-verify-mason2-$stamp")
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  [IO.Compression.ZipFile]::ExtractToDirectory($Bundle,$stage)

  # compare to manifest
  $manifestFile = Join-Path $stage 'manifest.json'
  if(!(Test-Path $manifestFile)){ throw 'manifest.json missing in bundle' }
  $man = Get-Content $manifestFile -Raw | ConvertFrom-Json
  $manFiles = @{}
  foreach($f in $man.files){ $manFiles[$f.path] = $f }

  $zipEntries = @{}
  foreach($e in $zip.Entries){ if($e.FullName -ne 'manifest.json' -and $e.FullName -notmatch '/$'){ $zipEntries[$e.FullName] = $true } }

  # set counts
  $zipCount = $zipEntries.Keys.Count + 1  # +manifest
  $manCount = $man.files.Count + 1

  # sha256 verify every file listed in manifest
  $badHash = @()
  foreach($kv in $manFiles.GetEnumerator()){
    $rel = $kv.Key
    $dst = Join-Path $stage $rel
    if(!(Test-Path $dst)){ throw "File from manifest missing after extract: $rel" }
    $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $dst).Hash
    if($h -ne $kv.Value.sha256){ $badHash += $rel }
  }

  # zip vs manifest membership
  $zipNotInMan = @()
  foreach($k in $zipEntries.Keys){ if(-not $manFiles.ContainsKey($k) -and $k -ne 'manifest.json'){ $zipNotInMan += $k } }
  $manNotInZip = @()
  foreach($k in $manFiles.Keys){ if(-not $zipEntries.ContainsKey($k)){ $manNotInZip += $k } }

  if($badHash.Count){ throw "Hash mismatch: $($badHash -join ', ')" }
  if($zipNotInMan.Count){ throw "Zip has extra files not in manifest: $($zipNotInMan -join ', ')" }
  if($manNotInZip.Count){ throw "Manifest lists files missing in zip: $($manNotInZip -join ', ')" }

  # success ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â optionally apply atomically
  $applied = $false
  if($Apply){
    Atomic-Swap -newDir $stage -currentDir $paths.Current
    $applied = $true
  }

  Write-JsonLine $rep ([pscustomobject]@{
    ts = (Get-Date).ToString('o')
    bundle = [IO.Path]::GetFileName($Bundle)
    applied = $applied
    zip_count = $zipCount
    manifest_count = $manCount
    ok = $true
  })
  if(-not $Apply){ Write-Output "Verified + unpacked to: $stage (not applied)" } else { Write-Output "Verified + applied atomically to: $($paths.Current)" }
}
finally { $zip.Dispose() }

