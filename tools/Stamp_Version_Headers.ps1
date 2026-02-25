$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
$ver = if(Test-Path (Join-Path $rel 'LATEST.txt')){ (Get-Content (Join-Path $rel 'LATEST.txt') -Raw).Trim() } else { "dev-" + (Get-Date).ToString("yyyyMMdd-HHmmss") }
$now = Get-Date
$wrote = 0
Get-ChildItem -LiteralPath $Base -Recurse -Filter *.ps1 -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $t = Get-Content -Raw -LiteralPath $_.FullName
    if($t -notmatch '# Mason2 Version:'){
      $hdr = "# Mason2 Version: $ver`r`n# Stamped: $($now.ToString('s'))`r`n"
      Set-Content -LiteralPath $_.FullName -Value ($hdr + $t) -Encoding UTF8
      $wrote++
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\version_stamp.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='version_stamp'; version=$ver; added=$wrote }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
$ver = if(Test-Path (Join-Path $rel 'LATEST.txt')){ (Get-Content (Join-Path $rel 'LATEST.txt') -Raw).Trim() } else { "dev-" + (Get-Date).ToString("yyyyMMdd-HHmmss") }
$now = Get-Date
$wrote = 0
Get-ChildItem -LiteralPath $Base -Recurse -Filter *.ps1 -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $t = Get-Content -Raw -LiteralPath $_.FullName
    if($t -notmatch '# Mason2 Version:'){
      $hdr = "# Mason2 Version: $ver`r`n# Stamped: $($now.ToString('s'))`r`n"
      Set-Content -LiteralPath $_.FullName -Value ($hdr + $t) -Encoding UTF8
      $wrote++
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\version_stamp.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='version_stamp'; version=$ver; added=$wrote }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
$ver = if(Test-Path (Join-Path $rel 'LATEST.txt')){ (Get-Content (Join-Path $rel 'LATEST.txt') -Raw).Trim() } else { "dev-" + (Get-Date).ToString("yyyyMMdd-HHmmss") }
$now = Get-Date
$wrote = 0
Get-ChildItem -LiteralPath $Base -Recurse -Filter *.ps1 -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $t = Get-Content -Raw -LiteralPath $_.FullName
    if($t -notmatch '# Mason2 Version:'){
      $hdr = "# Mason2 Version: $ver`r`n# Stamped: $($now.ToString('s'))`r`n"
      Set-Content -LiteralPath $_.FullName -Value ($hdr + $t) -Encoding UTF8
      $wrote++
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\version_stamp.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='version_stamp'; version=$ver; added=$wrote }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
$ver = if(Test-Path (Join-Path $rel 'LATEST.txt')){ (Get-Content (Join-Path $rel 'LATEST.txt') -Raw).Trim() } else { "dev-" + (Get-Date).ToString("yyyyMMdd-HHmmss") }
$now = Get-Date
$wrote = 0
Get-ChildItem -LiteralPath $Base -Recurse -Filter *.ps1 -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $t = Get-Content -Raw -LiteralPath $_.FullName
    if($t -notmatch '# Mason2 Version:'){
      $hdr = "# Mason2 Version: $ver`r`n# Stamped: $($now.ToString('s'))`r`n"
      Set-Content -LiteralPath $_.FullName -Value ($hdr + $t) -Encoding UTF8
      $wrote++
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\version_stamp.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='version_stamp'; version=$ver; added=$wrote }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
$ver = if(Test-Path (Join-Path $rel 'LATEST.txt')){ (Get-Content (Join-Path $rel 'LATEST.txt') -Raw).Trim() } else { "dev-" + (Get-Date).ToString("yyyyMMdd-HHmmss") }
$now = Get-Date
$wrote = 0
Get-ChildItem -LiteralPath $Base -Recurse -Filter *.ps1 -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $t = Get-Content -Raw -LiteralPath $_.FullName
    if($t -notmatch '# Mason2 Version:'){
      $hdr = "# Mason2 Version: $ver`r`n# Stamped: $($now.ToString('s'))`r`n"
      Set-Content -LiteralPath $_.FullName -Value ($hdr + $t) -Encoding UTF8
      $wrote++
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\version_stamp.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='version_stamp'; version=$ver; added=$wrote }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
$ver = if(Test-Path (Join-Path $rel 'LATEST.txt')){ (Get-Content (Join-Path $rel 'LATEST.txt') -Raw).Trim() } else { "dev-" + (Get-Date).ToString("yyyyMMdd-HHmmss") }
$now = Get-Date
$wrote = 0
Get-ChildItem -LiteralPath $Base -Recurse -Filter *.ps1 -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $t = Get-Content -Raw -LiteralPath $_.FullName
    if($t -notmatch '# Mason2 Version:'){
      $hdr = "# Mason2 Version: $ver`r`n# Stamped: $($now.ToString('s'))`r`n"
      Set-Content -LiteralPath $_.FullName -Value ($hdr + $t) -Encoding UTF8
      $wrote++
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\version_stamp.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='version_stamp'; version=$ver; added=$wrote }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
$ver = if(Test-Path (Join-Path $rel 'LATEST.txt')){ (Get-Content (Join-Path $rel 'LATEST.txt') -Raw).Trim() } else { "dev-" + (Get-Date).ToString("yyyyMMdd-HHmmss") }
$now = Get-Date
$wrote = 0
Get-ChildItem -LiteralPath $Base -Recurse -Filter *.ps1 -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $t = Get-Content -Raw -LiteralPath $_.FullName
    if($t -notmatch '# Mason2 Version:'){
      $hdr = "# Mason2 Version: $ver`r`n# Stamped: $($now.ToString('s'))`r`n"
      Set-Content -LiteralPath $_.FullName -Value ($hdr + $t) -Encoding UTF8
      $wrote++
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\version_stamp.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='version_stamp'; version=$ver; added=$wrote }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rel = Join-Path $Base 'dist\releases'
$ver = if(Test-Path (Join-Path $rel 'LATEST.txt')){ (Get-Content (Join-Path $rel 'LATEST.txt') -Raw).Trim() } else { "dev-" + (Get-Date).ToString("yyyyMMdd-HHmmss") }
$now = Get-Date
$wrote = 0
Get-ChildItem -LiteralPath $Base -Recurse -Filter *.ps1 -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $t = Get-Content -Raw -LiteralPath $_.FullName
    if($t -notmatch '# Mason2 Version:'){
      $hdr = "# Mason2 Version: $ver`r`n# Stamped: $($now.ToString('s'))`r`n"
      Set-Content -LiteralPath $_.FullName -Value ($hdr + $t) -Encoding UTF8
      $wrote++
    }
  }catch{}
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\version_stamp.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='version_stamp'; version=$ver; added=$wrote }
