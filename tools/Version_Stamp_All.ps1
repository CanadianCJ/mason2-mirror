# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Version_Stamp_All.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$phaseHash = (Get-FileHash -Algorithm SHA256 -Path $phase).Hash
$now = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$skip = @("node_modules","dist","logs",".git",".cache")

function ShouldSkip([string]$p){
  foreach($s in $skip){ if($p -like "*\$s*"){ return $true } }
  return $false
}

Get-ChildItem $Base -Recurse -Filter *.ps1 -File -ea SilentlyContinue | ForEach-Object{
  if(ShouldSkip $_.FullName){ return }
  $text = Get-Content $_.FullName -Raw
  if($text -match '^\s*#\s*Mason2-Version:'){ return } # already stamped
  $rel = $_.FullName.Substring($Base.Length).TrimStart('\')
  $hdr = "# Mason2-Version: $now; RoadmapSHA: $phaseHash`r`n# Mason2-File: $rel`r`n"
  ($hdr + $text) | Set-Content $_.FullName -Encoding UTF8
}
"ok" | Set-Content (Join-Path $Sig "system-structure-version-stamp.ok") -Encoding ASCII
Write-Host "[ OK ] Version headers stamped"


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Version_Stamp_All.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$phaseHash = (Get-FileHash -Algorithm SHA256 -Path $phase).Hash
$now = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$skip = @("node_modules","dist","logs",".git",".cache")

function ShouldSkip([string]$p){
  foreach($s in $skip){ if($p -like "*\$s*"){ return $true } }
  return $false
}

Get-ChildItem $Base -Recurse -Filter *.ps1 -File -ea SilentlyContinue | ForEach-Object{
  if(ShouldSkip $_.FullName){ return }
  $text = Get-Content $_.FullName -Raw
  if($text -match '^\s*#\s*Mason2-Version:'){ return } # already stamped
  $rel = $_.FullName.Substring($Base.Length).TrimStart('\')
  $hdr = "# Mason2-Version: $now; RoadmapSHA: $phaseHash`r`n# Mason2-File: $rel`r`n"
  ($hdr + $text) | Set-Content $_.FullName -Encoding UTF8
}
"ok" | Set-Content (Join-Path $Sig "system-structure-version-stamp.ok") -Encoding ASCII
Write-Host "[ OK ] Version headers stamped"


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Version_Stamp_All.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$phaseHash = (Get-FileHash -Algorithm SHA256 -Path $phase).Hash
$now = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$skip = @("node_modules","dist","logs",".git",".cache")

function ShouldSkip([string]$p){
  foreach($s in $skip){ if($p -like "*\$s*"){ return $true } }
  return $false
}

Get-ChildItem $Base -Recurse -Filter *.ps1 -File -ea SilentlyContinue | ForEach-Object{
  if(ShouldSkip $_.FullName){ return }
  $text = Get-Content $_.FullName -Raw
  if($text -match '^\s*#\s*Mason2-Version:'){ return } # already stamped
  $rel = $_.FullName.Substring($Base.Length).TrimStart('\')
  $hdr = "# Mason2-Version: $now; RoadmapSHA: $phaseHash`r`n# Mason2-File: $rel`r`n"
  ($hdr + $text) | Set-Content $_.FullName -Encoding UTF8
}
"ok" | Set-Content (Join-Path $Sig "system-structure-version-stamp.ok") -Encoding ASCII
Write-Host "[ OK ] Version headers stamped"


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Version_Stamp_All.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$phaseHash = (Get-FileHash -Algorithm SHA256 -Path $phase).Hash
$now = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$skip = @("node_modules","dist","logs",".git",".cache")

function ShouldSkip([string]$p){
  foreach($s in $skip){ if($p -like "*\$s*"){ return $true } }
  return $false
}

Get-ChildItem $Base -Recurse -Filter *.ps1 -File -ea SilentlyContinue | ForEach-Object{
  if(ShouldSkip $_.FullName){ return }
  $text = Get-Content $_.FullName -Raw
  if($text -match '^\s*#\s*Mason2-Version:'){ return } # already stamped
  $rel = $_.FullName.Substring($Base.Length).TrimStart('\')
  $hdr = "# Mason2-Version: $now; RoadmapSHA: $phaseHash`r`n# Mason2-File: $rel`r`n"
  ($hdr + $text) | Set-Content $_.FullName -Encoding UTF8
}
"ok" | Set-Content (Join-Path $Sig "system-structure-version-stamp.ok") -Encoding ASCII
Write-Host "[ OK ] Version headers stamped"


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Version_Stamp_All.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$phaseHash = (Get-FileHash -Algorithm SHA256 -Path $phase).Hash
$now = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$skip = @("node_modules","dist","logs",".git",".cache")

function ShouldSkip([string]$p){
  foreach($s in $skip){ if($p -like "*\$s*"){ return $true } }
  return $false
}

Get-ChildItem $Base -Recurse -Filter *.ps1 -File -ea SilentlyContinue | ForEach-Object{
  if(ShouldSkip $_.FullName){ return }
  $text = Get-Content $_.FullName -Raw
  if($text -match '^\s*#\s*Mason2-Version:'){ return } # already stamped
  $rel = $_.FullName.Substring($Base.Length).TrimStart('\')
  $hdr = "# Mason2-Version: $now; RoadmapSHA: $phaseHash`r`n# Mason2-File: $rel`r`n"
  ($hdr + $text) | Set-Content $_.FullName -Encoding UTF8
}
"ok" | Set-Content (Join-Path $Sig "system-structure-version-stamp.ok") -Encoding ASCII
Write-Host "[ OK ] Version headers stamped"


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Version_Stamp_All.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$phaseHash = (Get-FileHash -Algorithm SHA256 -Path $phase).Hash
$now = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$skip = @("node_modules","dist","logs",".git",".cache")

function ShouldSkip([string]$p){
  foreach($s in $skip){ if($p -like "*\$s*"){ return $true } }
  return $false
}

Get-ChildItem $Base -Recurse -Filter *.ps1 -File -ea SilentlyContinue | ForEach-Object{
  if(ShouldSkip $_.FullName){ return }
  $text = Get-Content $_.FullName -Raw
  if($text -match '^\s*#\s*Mason2-Version:'){ return } # already stamped
  $rel = $_.FullName.Substring($Base.Length).TrimStart('\')
  $hdr = "# Mason2-Version: $now; RoadmapSHA: $phaseHash`r`n# Mason2-File: $rel`r`n"
  ($hdr + $text) | Set-Content $_.FullName -Encoding UTF8
}
"ok" | Set-Content (Join-Path $Sig "system-structure-version-stamp.ok") -Encoding ASCII
Write-Host "[ OK ] Version headers stamped"


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Version_Stamp_All.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$phaseHash = (Get-FileHash -Algorithm SHA256 -Path $phase).Hash
$now = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$skip = @("node_modules","dist","logs",".git",".cache")

function ShouldSkip([string]$p){
  foreach($s in $skip){ if($p -like "*\$s*"){ return $true } }
  return $false
}

Get-ChildItem $Base -Recurse -Filter *.ps1 -File -ea SilentlyContinue | ForEach-Object{
  if(ShouldSkip $_.FullName){ return }
  $text = Get-Content $_.FullName -Raw
  if($text -match '^\s*#\s*Mason2-Version:'){ return } # already stamped
  $rel = $_.FullName.Substring($Base.Length).TrimStart('\')
  $hdr = "# Mason2-Version: $now; RoadmapSHA: $phaseHash`r`n# Mason2-File: $rel`r`n"
  ($hdr + $text) | Set-Content $_.FullName -Encoding UTF8
}
"ok" | Set-Content (Join-Path $Sig "system-structure-version-stamp.ok") -Encoding ASCII
Write-Host "[ OK ] Version headers stamped"


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Version_Stamp_All.ps1
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$phaseHash = (Get-FileHash -Algorithm SHA256 -Path $phase).Hash
$now = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
$skip = @("node_modules","dist","logs",".git",".cache")

function ShouldSkip([string]$p){
  foreach($s in $skip){ if($p -like "*\$s*"){ return $true } }
  return $false
}

Get-ChildItem $Base -Recurse -Filter *.ps1 -File -ea SilentlyContinue | ForEach-Object{
  if(ShouldSkip $_.FullName){ return }
  $text = Get-Content $_.FullName -Raw
  if($text -match '^\s*#\s*Mason2-Version:'){ return } # already stamped
  $rel = $_.FullName.Substring($Base.Length).TrimStart('\')
  $hdr = "# Mason2-Version: $now; RoadmapSHA: $phaseHash`r`n# Mason2-File: $rel`r`n"
  ($hdr + $text) | Set-Content $_.FullName -Encoding UTF8
}
"ok" | Set-Content (Join-Path $Sig "system-structure-version-stamp.ok") -Encoding ASCII
Write-Host "[ OK ] Version headers stamped"


