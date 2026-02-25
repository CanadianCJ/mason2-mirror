$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$srcs = @((Join-Path $Base 'reports\exec_log.jsonl'))
$dst  = Join-Path $Base 'reports\redacted'; New-Item -ItemType Directory -Force -Path $dst | Out-Null
$re  = @('[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}','\b\d{3}-\d{2}-\d{4}\b','sk-[A-Za-z0-9]{20,}')
foreach($s in $srcs){
  if(-not (Test-Path $s)){ continue }
  $o = Join-Path $dst ([IO.Path]::GetFileName($s))
  Get-Content $s -ErrorAction SilentlyContinue | ForEach-Object {
    $line = $_
    foreach($p in $re){ $line = ($line -replace $p,'[REDACTED]') }
    $line | Out-File -FilePath $o -Encoding UTF8 -Append
  }
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$srcs = @((Join-Path $Base 'reports\exec_log.jsonl'))
$dst  = Join-Path $Base 'reports\redacted'; New-Item -ItemType Directory -Force -Path $dst | Out-Null
$re  = @('[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}','\b\d{3}-\d{2}-\d{4}\b','sk-[A-Za-z0-9]{20,}')
foreach($s in $srcs){
  if(-not (Test-Path $s)){ continue }
  $o = Join-Path $dst ([IO.Path]::GetFileName($s))
  Get-Content $s -ErrorAction SilentlyContinue | ForEach-Object {
    $line = $_
    foreach($p in $re){ $line = ($line -replace $p,'[REDACTED]') }
    $line | Out-File -FilePath $o -Encoding UTF8 -Append
  }
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$srcs = @((Join-Path $Base 'reports\exec_log.jsonl'))
$dst  = Join-Path $Base 'reports\redacted'; New-Item -ItemType Directory -Force -Path $dst | Out-Null
$re  = @('[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}','\b\d{3}-\d{2}-\d{4}\b','sk-[A-Za-z0-9]{20,}')
foreach($s in $srcs){
  if(-not (Test-Path $s)){ continue }
  $o = Join-Path $dst ([IO.Path]::GetFileName($s))
  Get-Content $s -ErrorAction SilentlyContinue | ForEach-Object {
    $line = $_
    foreach($p in $re){ $line = ($line -replace $p,'[REDACTED]') }
    $line | Out-File -FilePath $o -Encoding UTF8 -Append
  }
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$srcs = @((Join-Path $Base 'reports\exec_log.jsonl'))
$dst  = Join-Path $Base 'reports\redacted'; New-Item -ItemType Directory -Force -Path $dst | Out-Null
$re  = @('[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}','\b\d{3}-\d{2}-\d{4}\b','sk-[A-Za-z0-9]{20,}')
foreach($s in $srcs){
  if(-not (Test-Path $s)){ continue }
  $o = Join-Path $dst ([IO.Path]::GetFileName($s))
  Get-Content $s -ErrorAction SilentlyContinue | ForEach-Object {
    $line = $_
    foreach($p in $re){ $line = ($line -replace $p,'[REDACTED]') }
    $line | Out-File -FilePath $o -Encoding UTF8 -Append
  }
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$srcs = @((Join-Path $Base 'reports\exec_log.jsonl'))
$dst  = Join-Path $Base 'reports\redacted'; New-Item -ItemType Directory -Force -Path $dst | Out-Null
$re  = @('[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}','\b\d{3}-\d{2}-\d{4}\b','sk-[A-Za-z0-9]{20,}')
foreach($s in $srcs){
  if(-not (Test-Path $s)){ continue }
  $o = Join-Path $dst ([IO.Path]::GetFileName($s))
  Get-Content $s -ErrorAction SilentlyContinue | ForEach-Object {
    $line = $_
    foreach($p in $re){ $line = ($line -replace $p,'[REDACTED]') }
    $line | Out-File -FilePath $o -Encoding UTF8 -Append
  }
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$srcs = @((Join-Path $Base 'reports\exec_log.jsonl'))
$dst  = Join-Path $Base 'reports\redacted'; New-Item -ItemType Directory -Force -Path $dst | Out-Null
$re  = @('[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}','\b\d{3}-\d{2}-\d{4}\b','sk-[A-Za-z0-9]{20,}')
foreach($s in $srcs){
  if(-not (Test-Path $s)){ continue }
  $o = Join-Path $dst ([IO.Path]::GetFileName($s))
  Get-Content $s -ErrorAction SilentlyContinue | ForEach-Object {
    $line = $_
    foreach($p in $re){ $line = ($line -replace $p,'[REDACTED]') }
    $line | Out-File -FilePath $o -Encoding UTF8 -Append
  }
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$srcs = @((Join-Path $Base 'reports\exec_log.jsonl'))
$dst  = Join-Path $Base 'reports\redacted'; New-Item -ItemType Directory -Force -Path $dst | Out-Null
$re  = @('[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}','\b\d{3}-\d{2}-\d{4}\b','sk-[A-Za-z0-9]{20,}')
foreach($s in $srcs){
  if(-not (Test-Path $s)){ continue }
  $o = Join-Path $dst ([IO.Path]::GetFileName($s))
  Get-Content $s -ErrorAction SilentlyContinue | ForEach-Object {
    $line = $_
    foreach($p in $re){ $line = ($line -replace $p,'[REDACTED]') }
    $line | Out-File -FilePath $o -Encoding UTF8 -Append
  }
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$srcs = @((Join-Path $Base 'reports\exec_log.jsonl'))
$dst  = Join-Path $Base 'reports\redacted'; New-Item -ItemType Directory -Force -Path $dst | Out-Null
$re  = @('[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}','\b\d{3}-\d{2}-\d{4}\b','sk-[A-Za-z0-9]{20,}')
foreach($s in $srcs){
  if(-not (Test-Path $s)){ continue }
  $o = Join-Path $dst ([IO.Path]::GetFileName($s))
  Get-Content $s -ErrorAction SilentlyContinue | ForEach-Object {
    $line = $_
    foreach($p in $re){ $line = ($line -replace $p,'[REDACTED]') }
    $line | Out-File -FilePath $o -Encoding UTF8 -Append
  }
}
