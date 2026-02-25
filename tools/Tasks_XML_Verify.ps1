$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseDir = Join-Path $Base 'config\tasks_xml'
$curDir  = Join-Path $Base 'reports\tasks_xml_cur'
New-Item -ItemType Directory -Force -Path $curDir | Out-Null
# Export current
try{
  Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
    try{ Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $curDir ($_.TaskName + '.xml')) -Encoding UTF8 }catch{}
  }
}catch{}
$hash = @{
  base=@{}; cur=@{}
}
if(Test-Path $baseDir){
  Get-ChildItem -LiteralPath $baseDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.base[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
if(Test-Path $curDir){
  Get-ChildItem -LiteralPath $curDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.cur[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
$added=@(); $removed=@(); $changed=@()
foreach($k in $hash.base.Keys){ if(-not $hash.cur.ContainsKey($k)){ $removed+=$k } elseif($hash.cur[$k] -ne $hash.base[$k]){ $changed+=$k } }
foreach($k in $hash.cur.Keys){ if(-not $hash.base.ContainsKey($k)){ $added+=$k } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_xml_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_xml_diff'; added=$added; removed=$removed; changed=$changed }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseDir = Join-Path $Base 'config\tasks_xml'
$curDir  = Join-Path $Base 'reports\tasks_xml_cur'
New-Item -ItemType Directory -Force -Path $curDir | Out-Null
# Export current
try{
  Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
    try{ Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $curDir ($_.TaskName + '.xml')) -Encoding UTF8 }catch{}
  }
}catch{}
$hash = @{
  base=@{}; cur=@{}
}
if(Test-Path $baseDir){
  Get-ChildItem -LiteralPath $baseDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.base[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
if(Test-Path $curDir){
  Get-ChildItem -LiteralPath $curDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.cur[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
$added=@(); $removed=@(); $changed=@()
foreach($k in $hash.base.Keys){ if(-not $hash.cur.ContainsKey($k)){ $removed+=$k } elseif($hash.cur[$k] -ne $hash.base[$k]){ $changed+=$k } }
foreach($k in $hash.cur.Keys){ if(-not $hash.base.ContainsKey($k)){ $added+=$k } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_xml_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_xml_diff'; added=$added; removed=$removed; changed=$changed }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseDir = Join-Path $Base 'config\tasks_xml'
$curDir  = Join-Path $Base 'reports\tasks_xml_cur'
New-Item -ItemType Directory -Force -Path $curDir | Out-Null
# Export current
try{
  Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
    try{ Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $curDir ($_.TaskName + '.xml')) -Encoding UTF8 }catch{}
  }
}catch{}
$hash = @{
  base=@{}; cur=@{}
}
if(Test-Path $baseDir){
  Get-ChildItem -LiteralPath $baseDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.base[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
if(Test-Path $curDir){
  Get-ChildItem -LiteralPath $curDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.cur[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
$added=@(); $removed=@(); $changed=@()
foreach($k in $hash.base.Keys){ if(-not $hash.cur.ContainsKey($k)){ $removed+=$k } elseif($hash.cur[$k] -ne $hash.base[$k]){ $changed+=$k } }
foreach($k in $hash.cur.Keys){ if(-not $hash.base.ContainsKey($k)){ $added+=$k } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_xml_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_xml_diff'; added=$added; removed=$removed; changed=$changed }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseDir = Join-Path $Base 'config\tasks_xml'
$curDir  = Join-Path $Base 'reports\tasks_xml_cur'
New-Item -ItemType Directory -Force -Path $curDir | Out-Null
# Export current
try{
  Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
    try{ Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $curDir ($_.TaskName + '.xml')) -Encoding UTF8 }catch{}
  }
}catch{}
$hash = @{
  base=@{}; cur=@{}
}
if(Test-Path $baseDir){
  Get-ChildItem -LiteralPath $baseDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.base[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
if(Test-Path $curDir){
  Get-ChildItem -LiteralPath $curDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.cur[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
$added=@(); $removed=@(); $changed=@()
foreach($k in $hash.base.Keys){ if(-not $hash.cur.ContainsKey($k)){ $removed+=$k } elseif($hash.cur[$k] -ne $hash.base[$k]){ $changed+=$k } }
foreach($k in $hash.cur.Keys){ if(-not $hash.base.ContainsKey($k)){ $added+=$k } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_xml_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_xml_diff'; added=$added; removed=$removed; changed=$changed }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseDir = Join-Path $Base 'config\tasks_xml'
$curDir  = Join-Path $Base 'reports\tasks_xml_cur'
New-Item -ItemType Directory -Force -Path $curDir | Out-Null
# Export current
try{
  Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
    try{ Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $curDir ($_.TaskName + '.xml')) -Encoding UTF8 }catch{}
  }
}catch{}
$hash = @{
  base=@{}; cur=@{}
}
if(Test-Path $baseDir){
  Get-ChildItem -LiteralPath $baseDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.base[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
if(Test-Path $curDir){
  Get-ChildItem -LiteralPath $curDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.cur[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
$added=@(); $removed=@(); $changed=@()
foreach($k in $hash.base.Keys){ if(-not $hash.cur.ContainsKey($k)){ $removed+=$k } elseif($hash.cur[$k] -ne $hash.base[$k]){ $changed+=$k } }
foreach($k in $hash.cur.Keys){ if(-not $hash.base.ContainsKey($k)){ $added+=$k } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_xml_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_xml_diff'; added=$added; removed=$removed; changed=$changed }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseDir = Join-Path $Base 'config\tasks_xml'
$curDir  = Join-Path $Base 'reports\tasks_xml_cur'
New-Item -ItemType Directory -Force -Path $curDir | Out-Null
# Export current
try{
  Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
    try{ Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $curDir ($_.TaskName + '.xml')) -Encoding UTF8 }catch{}
  }
}catch{}
$hash = @{
  base=@{}; cur=@{}
}
if(Test-Path $baseDir){
  Get-ChildItem -LiteralPath $baseDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.base[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
if(Test-Path $curDir){
  Get-ChildItem -LiteralPath $curDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.cur[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
$added=@(); $removed=@(); $changed=@()
foreach($k in $hash.base.Keys){ if(-not $hash.cur.ContainsKey($k)){ $removed+=$k } elseif($hash.cur[$k] -ne $hash.base[$k]){ $changed+=$k } }
foreach($k in $hash.cur.Keys){ if(-not $hash.base.ContainsKey($k)){ $added+=$k } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_xml_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_xml_diff'; added=$added; removed=$removed; changed=$changed }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseDir = Join-Path $Base 'config\tasks_xml'
$curDir  = Join-Path $Base 'reports\tasks_xml_cur'
New-Item -ItemType Directory -Force -Path $curDir | Out-Null
# Export current
try{
  Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
    try{ Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $curDir ($_.TaskName + '.xml')) -Encoding UTF8 }catch{}
  }
}catch{}
$hash = @{
  base=@{}; cur=@{}
}
if(Test-Path $baseDir){
  Get-ChildItem -LiteralPath $baseDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.base[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
if(Test-Path $curDir){
  Get-ChildItem -LiteralPath $curDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.cur[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
$added=@(); $removed=@(); $changed=@()
foreach($k in $hash.base.Keys){ if(-not $hash.cur.ContainsKey($k)){ $removed+=$k } elseif($hash.cur[$k] -ne $hash.base[$k]){ $changed+=$k } }
foreach($k in $hash.cur.Keys){ if(-not $hash.base.ContainsKey($k)){ $added+=$k } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_xml_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_xml_diff'; added=$added; removed=$removed; changed=$changed }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$baseDir = Join-Path $Base 'config\tasks_xml'
$curDir  = Join-Path $Base 'reports\tasks_xml_cur'
New-Item -ItemType Directory -Force -Path $curDir | Out-Null
# Export current
try{
  Get-ScheduledTask 'Mason2-*' -ErrorAction SilentlyContinue | ForEach-Object {
    try{ Export-ScheduledTask -TaskName $_.TaskName -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $curDir ($_.TaskName + '.xml')) -Encoding UTF8 }catch{}
  }
}catch{}
$hash = @{
  base=@{}; cur=@{}
}
if(Test-Path $baseDir){
  Get-ChildItem -LiteralPath $baseDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.base[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
if(Test-Path $curDir){
  Get-ChildItem -LiteralPath $curDir -Filter *.xml -File -ErrorAction SilentlyContinue | ForEach-Object {
    try{ $hash.cur[$_.Name] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }catch{}
  }
}
$added=@(); $removed=@(); $changed=@()
foreach($k in $hash.base.Keys){ if(-not $hash.cur.ContainsKey($k)){ $removed+=$k } elseif($hash.cur[$k] -ne $hash.base[$k]){ $changed+=$k } }
foreach($k in $hash.cur.Keys){ if(-not $hash.base.ContainsKey($k)){ $added+=$k } }
Write-JsonLineSafe -Path (Join-Path $Base 'reports\tasks_xml_diff.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='tasks_xml_diff'; added=$added; removed=$removed; changed=$changed }
