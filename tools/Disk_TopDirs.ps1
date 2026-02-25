$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rows=@()
Get-ChildItem -LiteralPath $Base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $sum = (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    $rows += [pscustomobject]@{ dir=$_.FullName.Substring($Base.Length+1); mb=[math]::Round(($sum/1MB),2) }
  }catch{}
}
$topRows = $rows | Sort-Object mb -Descending | Select-Object -First ([int]$Top)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_topdirs.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='disk_topdirs'; items=$topRows }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=15)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rows=@()
Get-ChildItem -LiteralPath $Base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $sum = (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    $rows += [pscustomobject]@{ dir=$_.FullName.Substring($Base.Length+1); mb=[math]::Round(($sum/1MB),2) }
  }catch{}
}
$topRows = $rows | Sort-Object mb -Descending | Select-Object -First ([int]$Top)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_topdirs.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='disk_topdirs'; items=$topRows }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=15)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rows=@()
Get-ChildItem -LiteralPath $Base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $sum = (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    $rows += [pscustomobject]@{ dir=$_.FullName.Substring($Base.Length+1); mb=[math]::Round(($sum/1MB),2) }
  }catch{}
}
$topRows = $rows | Sort-Object mb -Descending | Select-Object -First ([int]$Top)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_topdirs.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='disk_topdirs'; items=$topRows }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=15)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rows=@()
Get-ChildItem -LiteralPath $Base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $sum = (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    $rows += [pscustomobject]@{ dir=$_.FullName.Substring($Base.Length+1); mb=[math]::Round(($sum/1MB),2) }
  }catch{}
}
$topRows = $rows | Sort-Object mb -Descending | Select-Object -First ([int]$Top)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_topdirs.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='disk_topdirs'; items=$topRows }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=15)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rows=@()
Get-ChildItem -LiteralPath $Base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $sum = (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    $rows += [pscustomobject]@{ dir=$_.FullName.Substring($Base.Length+1); mb=[math]::Round(($sum/1MB),2) }
  }catch{}
}
$topRows = $rows | Sort-Object mb -Descending | Select-Object -First ([int]$Top)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_topdirs.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='disk_topdirs'; items=$topRows }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=15)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rows=@()
Get-ChildItem -LiteralPath $Base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $sum = (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    $rows += [pscustomobject]@{ dir=$_.FullName.Substring($Base.Length+1); mb=[math]::Round(($sum/1MB),2) }
  }catch{}
}
$topRows = $rows | Sort-Object mb -Descending | Select-Object -First ([int]$Top)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_topdirs.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='disk_topdirs'; items=$topRows }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Top=15)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rows=@()
Get-ChildItem -LiteralPath $Base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $sum = (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    $rows += [pscustomobject]@{ dir=$_.FullName.Substring($Base.Length+1); mb=[math]::Round(($sum/1MB),2) }
  }catch{}
}
$topRows = $rows | Sort-Object mb -Descending | Select-Object -First ([int]$Top)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_topdirs.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='disk_topdirs'; items=$topRows }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rows=@()
Get-ChildItem -LiteralPath $Base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  try{
    $sum = (Get-ChildItem -LiteralPath $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    $rows += [pscustomobject]@{ dir=$_.FullName.Substring($Base.Length+1); mb=[math]::Round(($sum/1MB),2) }
  }catch{}
}
$topRows = $rows | Sort-Object mb -Descending | Select-Object -First ([int]$Top)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\disk_topdirs.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='disk_topdirs'; items=$topRows }
