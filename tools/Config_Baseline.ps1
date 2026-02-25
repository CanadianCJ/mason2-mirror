$ErrorActionPreference='Stop'
$root = Join-Path $Base 'config'
$rows=@()
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rows += [pscustomobject]@{ path = $_.FullName.Substring($Base.Length+1); sha256 = $h.Hash; bytes = $_.Length }
    }catch{}
  }
}
($rows | ConvertTo-Json -Depth 4) | Out-File -FilePath (Join-Path $Base 'config\config_baseline.json') -Encoding UTF8
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$root = Join-Path $Base 'config'
$rows=@()
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rows += [pscustomobject]@{ path = $_.FullName.Substring($Base.Length+1); sha256 = $h.Hash; bytes = $_.Length }
    }catch{}
  }
}
($rows | ConvertTo-Json -Depth 4) | Out-File -FilePath (Join-Path $Base 'config\config_baseline.json') -Encoding UTF8
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$root = Join-Path $Base 'config'
$rows=@()
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rows += [pscustomobject]@{ path = $_.FullName.Substring($Base.Length+1); sha256 = $h.Hash; bytes = $_.Length }
    }catch{}
  }
}
($rows | ConvertTo-Json -Depth 4) | Out-File -FilePath (Join-Path $Base 'config\config_baseline.json') -Encoding UTF8
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$root = Join-Path $Base 'config'
$rows=@()
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rows += [pscustomobject]@{ path = $_.FullName.Substring($Base.Length+1); sha256 = $h.Hash; bytes = $_.Length }
    }catch{}
  }
}
($rows | ConvertTo-Json -Depth 4) | Out-File -FilePath (Join-Path $Base 'config\config_baseline.json') -Encoding UTF8
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$root = Join-Path $Base 'config'
$rows=@()
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rows += [pscustomobject]@{ path = $_.FullName.Substring($Base.Length+1); sha256 = $h.Hash; bytes = $_.Length }
    }catch{}
  }
}
($rows | ConvertTo-Json -Depth 4) | Out-File -FilePath (Join-Path $Base 'config\config_baseline.json') -Encoding UTF8
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$root = Join-Path $Base 'config'
$rows=@()
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rows += [pscustomobject]@{ path = $_.FullName.Substring($Base.Length+1); sha256 = $h.Hash; bytes = $_.Length }
    }catch{}
  }
}
($rows | ConvertTo-Json -Depth 4) | Out-File -FilePath (Join-Path $Base 'config\config_baseline.json') -Encoding UTF8
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$root = Join-Path $Base 'config'
$rows=@()
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rows += [pscustomobject]@{ path = $_.FullName.Substring($Base.Length+1); sha256 = $h.Hash; bytes = $_.Length }
    }catch{}
  }
}
($rows | ConvertTo-Json -Depth 4) | Out-File -FilePath (Join-Path $Base 'config\config_baseline.json') -Encoding UTF8
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
$root = Join-Path $Base 'config'
$rows=@()
if(Test-Path $root){
  Get-ChildItem -LiteralPath $root -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rows += [pscustomobject]@{ path = $_.FullName.Substring($Base.Length+1); sha256 = $h.Hash; bytes = $_.Length }
    }catch{}
  }
}
($rows | ConvertTo-Json -Depth 4) | Out-File -FilePath (Join-Path $Base 'config\config_baseline.json') -Encoding UTF8
