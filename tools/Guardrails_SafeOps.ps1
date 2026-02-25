# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
# Exposes: Resolve-MasonPath, Invoke-AllowedCmd
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Allowed = @("powershell.exe","cmd.exe","schtasks.exe","where.exe","tasklist.exe")  # extend cautiously

function Resolve-MasonPath([string]$Path){
  if([string]::IsNullOrWhiteSpace($Path)){ throw "Empty path" }
  $full = [IO.Path]::GetFullPath((Join-Path (Resolve-Path $Base) $Path))
  $root = [IO.Path]::GetFullPath((Resolve-Path $Base))
  if(-not $full.StartsWith($root,[System.StringComparison]::OrdinalIgnoreCase)){
    throw "Write outside Mason root blocked: $full"
  }
  return $full
}

function Invoke-AllowedCmd([string]$Cmd,[string]$Args=""){
  $leaf = Split-Path $Cmd -Leaf
  if($Allowed -notcontains $leaf){ throw "Command not allowed by guardrails: $leaf" }
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=$Cmd; $psi.Arguments=$Args; $psi.UseShellExecute=$false
  $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
  $p=[System.Diagnostics.Process]::Start($psi); $p.WaitForExit(); return $p.ExitCode
}

# Drop signals on first import
try{
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-file-scope.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-command-allowlist.ok") -Encoding ASCII
}catch{}


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
# Exposes: Resolve-MasonPath, Invoke-AllowedCmd
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Allowed = @("powershell.exe","cmd.exe","schtasks.exe","where.exe","tasklist.exe")  # extend cautiously

function Resolve-MasonPath([string]$Path){
  if([string]::IsNullOrWhiteSpace($Path)){ throw "Empty path" }
  $full = [IO.Path]::GetFullPath((Join-Path (Resolve-Path $Base) $Path))
  $root = [IO.Path]::GetFullPath((Resolve-Path $Base))
  if(-not $full.StartsWith($root,[System.StringComparison]::OrdinalIgnoreCase)){
    throw "Write outside Mason root blocked: $full"
  }
  return $full
}

function Invoke-AllowedCmd([string]$Cmd,[string]$Args=""){
  $leaf = Split-Path $Cmd -Leaf
  if($Allowed -notcontains $leaf){ throw "Command not allowed by guardrails: $leaf" }
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=$Cmd; $psi.Arguments=$Args; $psi.UseShellExecute=$false
  $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
  $p=[System.Diagnostics.Process]::Start($psi); $p.WaitForExit(); return $p.ExitCode
}

# Drop signals on first import
try{
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-file-scope.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-command-allowlist.ok") -Encoding ASCII
}catch{}


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
# Exposes: Resolve-MasonPath, Invoke-AllowedCmd
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Allowed = @("powershell.exe","cmd.exe","schtasks.exe","where.exe","tasklist.exe")  # extend cautiously

function Resolve-MasonPath([string]$Path){
  if([string]::IsNullOrWhiteSpace($Path)){ throw "Empty path" }
  $full = [IO.Path]::GetFullPath((Join-Path (Resolve-Path $Base) $Path))
  $root = [IO.Path]::GetFullPath((Resolve-Path $Base))
  if(-not $full.StartsWith($root,[System.StringComparison]::OrdinalIgnoreCase)){
    throw "Write outside Mason root blocked: $full"
  }
  return $full
}

function Invoke-AllowedCmd([string]$Cmd,[string]$Args=""){
  $leaf = Split-Path $Cmd -Leaf
  if($Allowed -notcontains $leaf){ throw "Command not allowed by guardrails: $leaf" }
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=$Cmd; $psi.Arguments=$Args; $psi.UseShellExecute=$false
  $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
  $p=[System.Diagnostics.Process]::Start($psi); $p.WaitForExit(); return $p.ExitCode
}

# Drop signals on first import
try{
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-file-scope.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-command-allowlist.ok") -Encoding ASCII
}catch{}


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
# Exposes: Resolve-MasonPath, Invoke-AllowedCmd
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Allowed = @("powershell.exe","cmd.exe","schtasks.exe","where.exe","tasklist.exe")  # extend cautiously

function Resolve-MasonPath([string]$Path){
  if([string]::IsNullOrWhiteSpace($Path)){ throw "Empty path" }
  $full = [IO.Path]::GetFullPath((Join-Path (Resolve-Path $Base) $Path))
  $root = [IO.Path]::GetFullPath((Resolve-Path $Base))
  if(-not $full.StartsWith($root,[System.StringComparison]::OrdinalIgnoreCase)){
    throw "Write outside Mason root blocked: $full"
  }
  return $full
}

function Invoke-AllowedCmd([string]$Cmd,[string]$Args=""){
  $leaf = Split-Path $Cmd -Leaf
  if($Allowed -notcontains $leaf){ throw "Command not allowed by guardrails: $leaf" }
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=$Cmd; $psi.Arguments=$Args; $psi.UseShellExecute=$false
  $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
  $p=[System.Diagnostics.Process]::Start($psi); $p.WaitForExit(); return $p.ExitCode
}

# Drop signals on first import
try{
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-file-scope.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-command-allowlist.ok") -Encoding ASCII
}catch{}


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
# Exposes: Resolve-MasonPath, Invoke-AllowedCmd
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Allowed = @("powershell.exe","cmd.exe","schtasks.exe","where.exe","tasklist.exe")  # extend cautiously

function Resolve-MasonPath([string]$Path){
  if([string]::IsNullOrWhiteSpace($Path)){ throw "Empty path" }
  $full = [IO.Path]::GetFullPath((Join-Path (Resolve-Path $Base) $Path))
  $root = [IO.Path]::GetFullPath((Resolve-Path $Base))
  if(-not $full.StartsWith($root,[System.StringComparison]::OrdinalIgnoreCase)){
    throw "Write outside Mason root blocked: $full"
  }
  return $full
}

function Invoke-AllowedCmd([string]$Cmd,[string]$Args=""){
  $leaf = Split-Path $Cmd -Leaf
  if($Allowed -notcontains $leaf){ throw "Command not allowed by guardrails: $leaf" }
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=$Cmd; $psi.Arguments=$Args; $psi.UseShellExecute=$false
  $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
  $p=[System.Diagnostics.Process]::Start($psi); $p.WaitForExit(); return $p.ExitCode
}

# Drop signals on first import
try{
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-file-scope.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-command-allowlist.ok") -Encoding ASCII
}catch{}


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
# Exposes: Resolve-MasonPath, Invoke-AllowedCmd
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Allowed = @("powershell.exe","cmd.exe","schtasks.exe","where.exe","tasklist.exe")  # extend cautiously

function Resolve-MasonPath([string]$Path){
  if([string]::IsNullOrWhiteSpace($Path)){ throw "Empty path" }
  $full = [IO.Path]::GetFullPath((Join-Path (Resolve-Path $Base) $Path))
  $root = [IO.Path]::GetFullPath((Resolve-Path $Base))
  if(-not $full.StartsWith($root,[System.StringComparison]::OrdinalIgnoreCase)){
    throw "Write outside Mason root blocked: $full"
  }
  return $full
}

function Invoke-AllowedCmd([string]$Cmd,[string]$Args=""){
  $leaf = Split-Path $Cmd -Leaf
  if($Allowed -notcontains $leaf){ throw "Command not allowed by guardrails: $leaf" }
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=$Cmd; $psi.Arguments=$Args; $psi.UseShellExecute=$false
  $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
  $p=[System.Diagnostics.Process]::Start($psi); $p.WaitForExit(); return $p.ExitCode
}

# Drop signals on first import
try{
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-file-scope.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-command-allowlist.ok") -Encoding ASCII
}catch{}


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
# Exposes: Resolve-MasonPath, Invoke-AllowedCmd
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Allowed = @("powershell.exe","cmd.exe","schtasks.exe","where.exe","tasklist.exe")  # extend cautiously

function Resolve-MasonPath([string]$Path){
  if([string]::IsNullOrWhiteSpace($Path)){ throw "Empty path" }
  $full = [IO.Path]::GetFullPath((Join-Path (Resolve-Path $Base) $Path))
  $root = [IO.Path]::GetFullPath((Resolve-Path $Base))
  if(-not $full.StartsWith($root,[System.StringComparison]::OrdinalIgnoreCase)){
    throw "Write outside Mason root blocked: $full"
  }
  return $full
}

function Invoke-AllowedCmd([string]$Cmd,[string]$Args=""){
  $leaf = Split-Path $Cmd -Leaf
  if($Allowed -notcontains $leaf){ throw "Command not allowed by guardrails: $leaf" }
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=$Cmd; $psi.Arguments=$Args; $psi.UseShellExecute=$false
  $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
  $p=[System.Diagnostics.Process]::Start($psi); $p.WaitForExit(); return $p.ExitCode
}

# Drop signals on first import
try{
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-file-scope.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-command-allowlist.ok") -Encoding ASCII
}catch{}


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
# Exposes: Resolve-MasonPath, Invoke-AllowedCmd
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Allowed = @("powershell.exe","cmd.exe","schtasks.exe","where.exe","tasklist.exe")  # extend cautiously

function Resolve-MasonPath([string]$Path){
  if([string]::IsNullOrWhiteSpace($Path)){ throw "Empty path" }
  $full = [IO.Path]::GetFullPath((Join-Path (Resolve-Path $Base) $Path))
  $root = [IO.Path]::GetFullPath((Resolve-Path $Base))
  if(-not $full.StartsWith($root,[System.StringComparison]::OrdinalIgnoreCase)){
    throw "Write outside Mason root blocked: $full"
  }
  return $full
}

function Invoke-AllowedCmd([string]$Cmd,[string]$Args=""){
  $leaf = Split-Path $Cmd -Leaf
  if($Allowed -notcontains $leaf){ throw "Command not allowed by guardrails: $leaf" }
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName=$Cmd; $psi.Arguments=$Args; $psi.UseShellExecute=$false
  $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
  $p=[System.Diagnostics.Process]::Start($psi); $p.WaitForExit(); return $p.ExitCode
}

# Drop signals on first import
try{
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-file-scope.ok") -Encoding ASCII
  "ok" | Set-Content (Join-Path $Base "reports\signals\safety-guardrails-command-allowlist.ok") -Encoding ASCII
}catch{}


