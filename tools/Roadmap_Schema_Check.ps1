# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$files = Get-ChildItem -LiteralPath $Base -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $lines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
  $ok=0;$bad=0
  foreach($l in $lines){
    if([string]::IsNullOrWhiteSpace($l)){ continue }
    if($l -match '^\[.+\]\s'){ $ok++ } else { $bad++ }
  }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\roadmap_schema.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='roadmap_schema';file=$f.Name;ok=$ok;bad=$bad}
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$files = Get-ChildItem -LiteralPath $Base -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $lines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
  $ok=0;$bad=0
  foreach($l in $lines){
    if([string]::IsNullOrWhiteSpace($l)){ continue }
    if($l -match '^\[.+\]\s'){ $ok++ } else { $bad++ }
  }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\roadmap_schema.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='roadmap_schema';file=$f.Name;ok=$ok;bad=$bad}
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$files = Get-ChildItem -LiteralPath $Base -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $lines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
  $ok=0;$bad=0
  foreach($l in $lines){
    if([string]::IsNullOrWhiteSpace($l)){ continue }
    if($l -match '^\[.+\]\s'){ $ok++ } else { $bad++ }
  }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\roadmap_schema.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='roadmap_schema';file=$f.Name;ok=$ok;bad=$bad}
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$files = Get-ChildItem -LiteralPath $Base -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $lines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
  $ok=0;$bad=0
  foreach($l in $lines){
    if([string]::IsNullOrWhiteSpace($l)){ continue }
    if($l -match '^\[.+\]\s'){ $ok++ } else { $bad++ }
  }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\roadmap_schema.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='roadmap_schema';file=$f.Name;ok=$ok;bad=$bad}
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$files = Get-ChildItem -LiteralPath $Base -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $lines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
  $ok=0;$bad=0
  foreach($l in $lines){
    if([string]::IsNullOrWhiteSpace($l)){ continue }
    if($l -match '^\[.+\]\s'){ $ok++ } else { $bad++ }
  }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\roadmap_schema.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='roadmap_schema';file=$f.Name;ok=$ok;bad=$bad}
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$files = Get-ChildItem -LiteralPath $Base -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $lines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
  $ok=0;$bad=0
  foreach($l in $lines){
    if([string]::IsNullOrWhiteSpace($l)){ continue }
    if($l -match '^\[.+\]\s'){ $ok++ } else { $bad++ }
  }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\roadmap_schema.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='roadmap_schema';file=$f.Name;ok=$ok;bad=$bad}
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$files = Get-ChildItem -LiteralPath $Base -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $lines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
  $ok=0;$bad=0
  foreach($l in $lines){
    if([string]::IsNullOrWhiteSpace($l)){ continue }
    if($l -match '^\[.+\]\s'){ $ok++ } else { $bad++ }
  }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\roadmap_schema.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='roadmap_schema';file=$f.Name;ok=$ok;bad=$bad}
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$files = Get-ChildItem -LiteralPath $Base -Filter 'PHASE *.txt' -File -Recurse -ErrorAction SilentlyContinue
foreach($f in $files){
  $lines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
  $ok=0;$bad=0
  foreach($l in $lines){
    if([string]::IsNullOrWhiteSpace($l)){ continue }
    if($l -match '^\[.+\]\s'){ $ok++ } else { $bad++ }
  }
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\roadmap_schema.jsonl') -Obj @{ts=(Get-Date).ToString('s');kind='roadmap_schema';file=$f.Name;ok=$ok;bad=$bad}
}

