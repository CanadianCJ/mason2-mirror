$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgDir = Join-Path $Base 'config'
$hashFile = Join-Path $Base 'reports\config_hash.json'
$now = Get-Date
$map = @{}
if(Test-Path $cfgDir){
  Get-ChildItem -LiteralPath $cfgDir -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $map[$rel] = $h.Hash
    }catch{}
  }
}
$prev = @{}
if(Test-Path $hashFile){
  try{ $prev = Get-Content $hashFile -Raw | ConvertFrom-Json }catch{ $prev=@{} }
}
# compare
$added=@(); $removed=@(); $changed=@()
foreach($k in $prev.PSObject.Properties.Name){ if(-not $map.ContainsKey($k)){ $removed += $k } elseif($map[$k] -ne $prev.$k){ $changed += $k } }
foreach($k in $map.Keys){ if(-not $prev.PSObject.Properties.Name -contains $k){ $added += $k } }
if($added.Count -gt 0 -or $removed.Count -gt 0 -or $changed.Count -gt 0){
  $sig = @{ ts=$now.ToString('s'); kind='config_reload_signal'; added=$added; removed=$removed; changed=$changed }
  ($sig | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'reports\reload_signal.json') -Encoding UTF8
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_reload.jsonl') -Obj $sig
}
($map | ConvertTo-Json -Depth 4) | Out-File -FilePath $hashFile -Encoding UTF8
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgDir = Join-Path $Base 'config'
$hashFile = Join-Path $Base 'reports\config_hash.json'
$now = Get-Date
$map = @{}
if(Test-Path $cfgDir){
  Get-ChildItem -LiteralPath $cfgDir -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $map[$rel] = $h.Hash
    }catch{}
  }
}
$prev = @{}
if(Test-Path $hashFile){
  try{ $prev = Get-Content $hashFile -Raw | ConvertFrom-Json }catch{ $prev=@{} }
}
# compare
$added=@(); $removed=@(); $changed=@()
foreach($k in $prev.PSObject.Properties.Name){ if(-not $map.ContainsKey($k)){ $removed += $k } elseif($map[$k] -ne $prev.$k){ $changed += $k } }
foreach($k in $map.Keys){ if(-not $prev.PSObject.Properties.Name -contains $k){ $added += $k } }
if($added.Count -gt 0 -or $removed.Count -gt 0 -or $changed.Count -gt 0){
  $sig = @{ ts=$now.ToString('s'); kind='config_reload_signal'; added=$added; removed=$removed; changed=$changed }
  ($sig | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'reports\reload_signal.json') -Encoding UTF8
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_reload.jsonl') -Obj $sig
}
($map | ConvertTo-Json -Depth 4) | Out-File -FilePath $hashFile -Encoding UTF8
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgDir = Join-Path $Base 'config'
$hashFile = Join-Path $Base 'reports\config_hash.json'
$now = Get-Date
$map = @{}
if(Test-Path $cfgDir){
  Get-ChildItem -LiteralPath $cfgDir -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $map[$rel] = $h.Hash
    }catch{}
  }
}
$prev = @{}
if(Test-Path $hashFile){
  try{ $prev = Get-Content $hashFile -Raw | ConvertFrom-Json }catch{ $prev=@{} }
}
# compare
$added=@(); $removed=@(); $changed=@()
foreach($k in $prev.PSObject.Properties.Name){ if(-not $map.ContainsKey($k)){ $removed += $k } elseif($map[$k] -ne $prev.$k){ $changed += $k } }
foreach($k in $map.Keys){ if(-not $prev.PSObject.Properties.Name -contains $k){ $added += $k } }
if($added.Count -gt 0 -or $removed.Count -gt 0 -or $changed.Count -gt 0){
  $sig = @{ ts=$now.ToString('s'); kind='config_reload_signal'; added=$added; removed=$removed; changed=$changed }
  ($sig | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'reports\reload_signal.json') -Encoding UTF8
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_reload.jsonl') -Obj $sig
}
($map | ConvertTo-Json -Depth 4) | Out-File -FilePath $hashFile -Encoding UTF8
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgDir = Join-Path $Base 'config'
$hashFile = Join-Path $Base 'reports\config_hash.json'
$now = Get-Date
$map = @{}
if(Test-Path $cfgDir){
  Get-ChildItem -LiteralPath $cfgDir -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $map[$rel] = $h.Hash
    }catch{}
  }
}
$prev = @{}
if(Test-Path $hashFile){
  try{ $prev = Get-Content $hashFile -Raw | ConvertFrom-Json }catch{ $prev=@{} }
}
# compare
$added=@(); $removed=@(); $changed=@()
foreach($k in $prev.PSObject.Properties.Name){ if(-not $map.ContainsKey($k)){ $removed += $k } elseif($map[$k] -ne $prev.$k){ $changed += $k } }
foreach($k in $map.Keys){ if(-not $prev.PSObject.Properties.Name -contains $k){ $added += $k } }
if($added.Count -gt 0 -or $removed.Count -gt 0 -or $changed.Count -gt 0){
  $sig = @{ ts=$now.ToString('s'); kind='config_reload_signal'; added=$added; removed=$removed; changed=$changed }
  ($sig | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'reports\reload_signal.json') -Encoding UTF8
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_reload.jsonl') -Obj $sig
}
($map | ConvertTo-Json -Depth 4) | Out-File -FilePath $hashFile -Encoding UTF8
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgDir = Join-Path $Base 'config'
$hashFile = Join-Path $Base 'reports\config_hash.json'
$now = Get-Date
$map = @{}
if(Test-Path $cfgDir){
  Get-ChildItem -LiteralPath $cfgDir -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $map[$rel] = $h.Hash
    }catch{}
  }
}
$prev = @{}
if(Test-Path $hashFile){
  try{ $prev = Get-Content $hashFile -Raw | ConvertFrom-Json }catch{ $prev=@{} }
}
# compare
$added=@(); $removed=@(); $changed=@()
foreach($k in $prev.PSObject.Properties.Name){ if(-not $map.ContainsKey($k)){ $removed += $k } elseif($map[$k] -ne $prev.$k){ $changed += $k } }
foreach($k in $map.Keys){ if(-not $prev.PSObject.Properties.Name -contains $k){ $added += $k } }
if($added.Count -gt 0 -or $removed.Count -gt 0 -or $changed.Count -gt 0){
  $sig = @{ ts=$now.ToString('s'); kind='config_reload_signal'; added=$added; removed=$removed; changed=$changed }
  ($sig | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'reports\reload_signal.json') -Encoding UTF8
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_reload.jsonl') -Obj $sig
}
($map | ConvertTo-Json -Depth 4) | Out-File -FilePath $hashFile -Encoding UTF8
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgDir = Join-Path $Base 'config'
$hashFile = Join-Path $Base 'reports\config_hash.json'
$now = Get-Date
$map = @{}
if(Test-Path $cfgDir){
  Get-ChildItem -LiteralPath $cfgDir -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $map[$rel] = $h.Hash
    }catch{}
  }
}
$prev = @{}
if(Test-Path $hashFile){
  try{ $prev = Get-Content $hashFile -Raw | ConvertFrom-Json }catch{ $prev=@{} }
}
# compare
$added=@(); $removed=@(); $changed=@()
foreach($k in $prev.PSObject.Properties.Name){ if(-not $map.ContainsKey($k)){ $removed += $k } elseif($map[$k] -ne $prev.$k){ $changed += $k } }
foreach($k in $map.Keys){ if(-not $prev.PSObject.Properties.Name -contains $k){ $added += $k } }
if($added.Count -gt 0 -or $removed.Count -gt 0 -or $changed.Count -gt 0){
  $sig = @{ ts=$now.ToString('s'); kind='config_reload_signal'; added=$added; removed=$removed; changed=$changed }
  ($sig | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'reports\reload_signal.json') -Encoding UTF8
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_reload.jsonl') -Obj $sig
}
($map | ConvertTo-Json -Depth 4) | Out-File -FilePath $hashFile -Encoding UTF8
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgDir = Join-Path $Base 'config'
$hashFile = Join-Path $Base 'reports\config_hash.json'
$now = Get-Date
$map = @{}
if(Test-Path $cfgDir){
  Get-ChildItem -LiteralPath $cfgDir -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $map[$rel] = $h.Hash
    }catch{}
  }
}
$prev = @{}
if(Test-Path $hashFile){
  try{ $prev = Get-Content $hashFile -Raw | ConvertFrom-Json }catch{ $prev=@{} }
}
# compare
$added=@(); $removed=@(); $changed=@()
foreach($k in $prev.PSObject.Properties.Name){ if(-not $map.ContainsKey($k)){ $removed += $k } elseif($map[$k] -ne $prev.$k){ $changed += $k } }
foreach($k in $map.Keys){ if(-not $prev.PSObject.Properties.Name -contains $k){ $added += $k } }
if($added.Count -gt 0 -or $removed.Count -gt 0 -or $changed.Count -gt 0){
  $sig = @{ ts=$now.ToString('s'); kind='config_reload_signal'; added=$added; removed=$removed; changed=$changed }
  ($sig | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'reports\reload_signal.json') -Encoding UTF8
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_reload.jsonl') -Obj $sig
}
($map | ConvertTo-Json -Depth 4) | Out-File -FilePath $hashFile -Encoding UTF8
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfgDir = Join-Path $Base 'config'
$hashFile = Join-Path $Base 'reports\config_hash.json'
$now = Get-Date
$map = @{}
if(Test-Path $cfgDir){
  Get-ChildItem -LiteralPath $cfgDir -Filter *.json -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{
      $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
      $rel = $_.FullName.Substring($Base.Length+1)
      $map[$rel] = $h.Hash
    }catch{}
  }
}
$prev = @{}
if(Test-Path $hashFile){
  try{ $prev = Get-Content $hashFile -Raw | ConvertFrom-Json }catch{ $prev=@{} }
}
# compare
$added=@(); $removed=@(); $changed=@()
foreach($k in $prev.PSObject.Properties.Name){ if(-not $map.ContainsKey($k)){ $removed += $k } elseif($map[$k] -ne $prev.$k){ $changed += $k } }
foreach($k in $map.Keys){ if(-not $prev.PSObject.Properties.Name -contains $k){ $added += $k } }
if($added.Count -gt 0 -or $removed.Count -gt 0 -or $changed.Count -gt 0){
  $sig = @{ ts=$now.ToString('s'); kind='config_reload_signal'; added=$added; removed=$removed; changed=$changed }
  ($sig | ConvertTo-Json -Depth 6) | Out-File -FilePath (Join-Path $Base 'reports\reload_signal.json') -Encoding UTF8
  Write-JsonLineSafe -Path (Join-Path $Base 'reports\config_reload.jsonl') -Obj $sig
}
($map | ConvertTo-Json -Depth 4) | Out-File -FilePath $hashFile -Encoding UTF8
