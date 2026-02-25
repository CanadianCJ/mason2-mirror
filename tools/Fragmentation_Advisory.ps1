$ErrorActionPreference='Stop'
try{
  $r = Optimize-Volume -Analyze -DriveLetter $Drive -Verbose:$false -ErrorAction Stop
  $frag = ($r | Select-Object -ExpandProperty FilePercentFragmentation -ErrorAction SilentlyContinue)
}catch{ $frag=$null }
$line = @{ ts=(Get-Date).ToString('s'); kind='frag'; drive=$Drive; file_fragment_pct=$frag }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\frag.jsonl"
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Drive='C')
$ErrorActionPreference='Stop'
try{
  $r = Optimize-Volume -Analyze -DriveLetter $Drive -Verbose:$false -ErrorAction Stop
  $frag = ($r | Select-Object -ExpandProperty FilePercentFragmentation -ErrorAction SilentlyContinue)
}catch{ $frag=$null }
$line = @{ ts=(Get-Date).ToString('s'); kind='frag'; drive=$Drive; file_fragment_pct=$frag }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\frag.jsonl"
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Drive='C')
$ErrorActionPreference='Stop'
try{
  $r = Optimize-Volume -Analyze -DriveLetter $Drive -Verbose:$false -ErrorAction Stop
  $frag = ($r | Select-Object -ExpandProperty FilePercentFragmentation -ErrorAction SilentlyContinue)
}catch{ $frag=$null }
$line = @{ ts=(Get-Date).ToString('s'); kind='frag'; drive=$Drive; file_fragment_pct=$frag }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\frag.jsonl"
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Drive='C')
$ErrorActionPreference='Stop'
try{
  $r = Optimize-Volume -Analyze -DriveLetter $Drive -Verbose:$false -ErrorAction Stop
  $frag = ($r | Select-Object -ExpandProperty FilePercentFragmentation -ErrorAction SilentlyContinue)
}catch{ $frag=$null }
$line = @{ ts=(Get-Date).ToString('s'); kind='frag'; drive=$Drive; file_fragment_pct=$frag }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\frag.jsonl"
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Drive='C')
$ErrorActionPreference='Stop'
try{
  $r = Optimize-Volume -Analyze -DriveLetter $Drive -Verbose:$false -ErrorAction Stop
  $frag = ($r | Select-Object -ExpandProperty FilePercentFragmentation -ErrorAction SilentlyContinue)
}catch{ $frag=$null }
$line = @{ ts=(Get-Date).ToString('s'); kind='frag'; drive=$Drive; file_fragment_pct=$frag }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\frag.jsonl"
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Drive='C')
$ErrorActionPreference='Stop'
try{
  $r = Optimize-Volume -Analyze -DriveLetter $Drive -Verbose:$false -ErrorAction Stop
  $frag = ($r | Select-Object -ExpandProperty FilePercentFragmentation -ErrorAction SilentlyContinue)
}catch{ $frag=$null }
$line = @{ ts=(Get-Date).ToString('s'); kind='frag'; drive=$Drive; file_fragment_pct=$frag }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\frag.jsonl"
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Drive='C')
$ErrorActionPreference='Stop'
try{
  $r = Optimize-Volume -Analyze -DriveLetter $Drive -Verbose:$false -ErrorAction Stop
  $frag = ($r | Select-Object -ExpandProperty FilePercentFragmentation -ErrorAction SilentlyContinue)
}catch{ $frag=$null }
$line = @{ ts=(Get-Date).ToString('s'); kind='frag'; drive=$Drive; file_fragment_pct=$frag }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\frag.jsonl"
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
try{
  $r = Optimize-Volume -Analyze -DriveLetter $Drive -Verbose:$false -ErrorAction Stop
  $frag = ($r | Select-Object -ExpandProperty FilePercentFragmentation -ErrorAction SilentlyContinue)
}catch{ $frag=$null }
$line = @{ ts=(Get-Date).ToString('s'); kind='frag'; drive=$Drive; file_fragment_pct=$frag }
($line | ConvertTo-Json -Compress) + [Environment]::NewLine | Out-File -Append -Encoding UTF8 "$env:USERPROFILE\Desktop\Mason2\reports\frag.jsonl"
