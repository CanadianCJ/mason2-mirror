$procs = Get-WmiObject Win32_Process -Filter "Name='powershell.exe'"
$mini = @()
foreach($p in $procs){
  $cmd = $p.CommandLine
  if($cmd -and $cmd -match 'Mini_File_Server_7001\.ps1'){ $mini += $p }
}
if($mini.Count -gt 1){
  # keep newest, kill older
  $keep = ($mini | Sort-Object CreationDate -Descending | Select-Object -First 1)
  foreach($p in $mini){ if($p.ProcessId -ne $keep.ProcessId){ try{ Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop; Out-MasonJsonl -Kind 'reaper' -Event 'killed' -Level 'WARN' -Data @{ pid=$p.ProcessId } }catch{} } }
}else{
  Out-MasonJsonl -Kind 'reaper' -Event 'clean' -Level 'INFO'
}_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$procs = Get-WmiObject Win32_Process -Filter "Name='powershell.exe'"
$mini = @()
foreach($p in $procs){
  $cmd = $p.CommandLine
  if($cmd -and $cmd -match 'Mini_File_Server_7001\.ps1'){ $mini += $p }
}
if($mini.Count -gt 1){
  # keep newest, kill older
  $keep = ($mini | Sort-Object CreationDate -Descending | Select-Object -First 1)
  foreach($p in $mini){ if($p.ProcessId -ne $keep.ProcessId){ try{ Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop; Out-MasonJsonl -Kind 'reaper' -Event 'killed' -Level 'WARN' -Data @{ pid=$p.ProcessId } }catch{} } }
}else{
  Out-MasonJsonl -Kind 'reaper' -Event 'clean' -Level 'INFO'
}_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$procs = Get-WmiObject Win32_Process -Filter "Name='powershell.exe'"
$mini = @()
foreach($p in $procs){
  $cmd = $p.CommandLine
  if($cmd -and $cmd -match 'Mini_File_Server_7001\.ps1'){ $mini += $p }
}
if($mini.Count -gt 1){
  # keep newest, kill older
  $keep = ($mini | Sort-Object CreationDate -Descending | Select-Object -First 1)
  foreach($p in $mini){ if($p.ProcessId -ne $keep.ProcessId){ try{ Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop; Out-MasonJsonl -Kind 'reaper' -Event 'killed' -Level 'WARN' -Data @{ pid=$p.ProcessId } }catch{} } }
}else{
  Out-MasonJsonl -Kind 'reaper' -Event 'clean' -Level 'INFO'
}_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$procs = Get-WmiObject Win32_Process -Filter "Name='powershell.exe'"
$mini = @()
foreach($p in $procs){
  $cmd = $p.CommandLine
  if($cmd -and $cmd -match 'Mini_File_Server_7001\.ps1'){ $mini += $p }
}
if($mini.Count -gt 1){
  # keep newest, kill older
  $keep = ($mini | Sort-Object CreationDate -Descending | Select-Object -First 1)
  foreach($p in $mini){ if($p.ProcessId -ne $keep.ProcessId){ try{ Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop; Out-MasonJsonl -Kind 'reaper' -Event 'killed' -Level 'WARN' -Data @{ pid=$p.ProcessId } }catch{} } }
}else{
  Out-MasonJsonl -Kind 'reaper' -Event 'clean' -Level 'INFO'
}_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$procs = Get-WmiObject Win32_Process -Filter "Name='powershell.exe'"
$mini = @()
foreach($p in $procs){
  $cmd = $p.CommandLine
  if($cmd -and $cmd -match 'Mini_File_Server_7001\.ps1'){ $mini += $p }
}
if($mini.Count -gt 1){
  # keep newest, kill older
  $keep = ($mini | Sort-Object CreationDate -Descending | Select-Object -First 1)
  foreach($p in $mini){ if($p.ProcessId -ne $keep.ProcessId){ try{ Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop; Out-MasonJsonl -Kind 'reaper' -Event 'killed' -Level 'WARN' -Data @{ pid=$p.ProcessId } }catch{} } }
}else{
  Out-MasonJsonl -Kind 'reaper' -Event 'clean' -Level 'INFO'
}_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$procs = Get-WmiObject Win32_Process -Filter "Name='powershell.exe'"
$mini = @()
foreach($p in $procs){
  $cmd = $p.CommandLine
  if($cmd -and $cmd -match 'Mini_File_Server_7001\.ps1'){ $mini += $p }
}
if($mini.Count -gt 1){
  # keep newest, kill older
  $keep = ($mini | Sort-Object CreationDate -Descending | Select-Object -First 1)
  foreach($p in $mini){ if($p.ProcessId -ne $keep.ProcessId){ try{ Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop; Out-MasonJsonl -Kind 'reaper' -Event 'killed' -Level 'WARN' -Data @{ pid=$p.ProcessId } }catch{} } }
}else{
  Out-MasonJsonl -Kind 'reaper' -Event 'clean' -Level 'INFO'
}_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseImport-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Logging.psm1") -Force
$procs = Get-WmiObject Win32_Process -Filter "Name='powershell.exe'"
$mini = @()
foreach($p in $procs){
  $cmd = $p.CommandLine
  if($cmd -and $cmd -match 'Mini_File_Server_7001\.ps1'){ $mini += $p }
}
if($mini.Count -gt 1){
  # keep newest, kill older
  $keep = ($mini | Sort-Object CreationDate -Descending | Select-Object -First 1)
  foreach($p in $mini){ if($p.ProcessId -ne $keep.ProcessId){ try{ Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop; Out-MasonJsonl -Kind 'reaper' -Event 'killed' -Level 'WARN' -Data @{ pid=$p.ProcessId } }catch{} } }
}else{
  Out-MasonJsonl -Kind 'reaper' -Event 'clean' -Level 'INFO'
}_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$procs = Get-WmiObject Win32_Process -Filter "Name='powershell.exe'"
$mini = @()
foreach($p in $procs){
  $cmd = $p.CommandLine
  if($cmd -and $cmd -match 'Mini_File_Server_7001\.ps1'){ $mini += $p }
}
if($mini.Count -gt 1){
  # keep newest, kill older
  $keep = ($mini | Sort-Object CreationDate -Descending | Select-Object -First 1)
  foreach($p in $mini){ if($p.ProcessId -ne $keep.ProcessId){ try{ Stop-Process -Id $p.ProcessId -Force -ErrorAction Stop; Out-MasonJsonl -Kind 'reaper' -Event 'killed' -Level 'WARN' -Data @{ pid=$p.ProcessId } }catch{} } }
}else{
  Out-MasonJsonl -Kind 'reaper' -Event 'clean' -Level 'INFO'
}