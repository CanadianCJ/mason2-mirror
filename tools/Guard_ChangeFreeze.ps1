# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$fp=Join-Path $Base 'config\freeze.json'; if(-not (Test-Path $fp)){ exit 0 }
try{$fz=Get-Content $fp -Raw|ConvertFrom-Json}catch{ exit 0 }
$now=Get-Date; $block=$false; $note=$null
if($fz.Ranges){ foreach($r in $fz.Ranges){ try{$f=[datetime]$r.From;$t=[datetime]$r.To; if($now -ge $f -and $now -le $t){$block=$true;$note=$r.Note;break}}catch{} } }
if(-not $block -and $fz.Weekdays){ if($fz.Weekdays -contains $now.DayOfWeek.ToString()){ $block=$true; $note=$note??'weekday-freeze' } }
if($block){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='change_freeze';note=$note;decision='block'}; exit 8 }
exit 0

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$fp=Join-Path $Base 'config\freeze.json'; if(-not (Test-Path $fp)){ exit 0 }
try{$fz=Get-Content $fp -Raw|ConvertFrom-Json}catch{ exit 0 }
$now=Get-Date; $block=$false; $note=$null
if($fz.Ranges){ foreach($r in $fz.Ranges){ try{$f=[datetime]$r.From;$t=[datetime]$r.To; if($now -ge $f -and $now -le $t){$block=$true;$note=$r.Note;break}}catch{} } }
if(-not $block -and $fz.Weekdays){ if($fz.Weekdays -contains $now.DayOfWeek.ToString()){ $block=$true; $note=$note??'weekday-freeze' } }
if($block){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='change_freeze';note=$note;decision='block'}; exit 8 }
exit 0

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$fp=Join-Path $Base 'config\freeze.json'; if(-not (Test-Path $fp)){ exit 0 }
try{$fz=Get-Content $fp -Raw|ConvertFrom-Json}catch{ exit 0 }
$now=Get-Date; $block=$false; $note=$null
if($fz.Ranges){ foreach($r in $fz.Ranges){ try{$f=[datetime]$r.From;$t=[datetime]$r.To; if($now -ge $f -and $now -le $t){$block=$true;$note=$r.Note;break}}catch{} } }
if(-not $block -and $fz.Weekdays){ if($fz.Weekdays -contains $now.DayOfWeek.ToString()){ $block=$true; $note=$note??'weekday-freeze' } }
if($block){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='change_freeze';note=$note;decision='block'}; exit 8 }
exit 0

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$fp=Join-Path $Base 'config\freeze.json'; if(-not (Test-Path $fp)){ exit 0 }
try{$fz=Get-Content $fp -Raw|ConvertFrom-Json}catch{ exit 0 }
$now=Get-Date; $block=$false; $note=$null
if($fz.Ranges){ foreach($r in $fz.Ranges){ try{$f=[datetime]$r.From;$t=[datetime]$r.To; if($now -ge $f -and $now -le $t){$block=$true;$note=$r.Note;break}}catch{} } }
if(-not $block -and $fz.Weekdays){ if($fz.Weekdays -contains $now.DayOfWeek.ToString()){ $block=$true; $note=$note??'weekday-freeze' } }
if($block){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='change_freeze';note=$note;decision='block'}; exit 8 }
exit 0

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$fp=Join-Path $Base 'config\freeze.json'; if(-not (Test-Path $fp)){ exit 0 }
try{$fz=Get-Content $fp -Raw|ConvertFrom-Json}catch{ exit 0 }
$now=Get-Date; $block=$false; $note=$null
if($fz.Ranges){ foreach($r in $fz.Ranges){ try{$f=[datetime]$r.From;$t=[datetime]$r.To; if($now -ge $f -and $now -le $t){$block=$true;$note=$r.Note;break}}catch{} } }
if(-not $block -and $fz.Weekdays){ if($fz.Weekdays -contains $now.DayOfWeek.ToString()){ $block=$true; $note=$note??'weekday-freeze' } }
if($block){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='change_freeze';note=$note;decision='block'}; exit 8 }
exit 0

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$fp=Join-Path $Base 'config\freeze.json'; if(-not (Test-Path $fp)){ exit 0 }
try{$fz=Get-Content $fp -Raw|ConvertFrom-Json}catch{ exit 0 }
$now=Get-Date; $block=$false; $note=$null
if($fz.Ranges){ foreach($r in $fz.Ranges){ try{$f=[datetime]$r.From;$t=[datetime]$r.To; if($now -ge $f -and $now -le $t){$block=$true;$note=$r.Note;break}}catch{} } }
if(-not $block -and $fz.Weekdays){ if($fz.Weekdays -contains $now.DayOfWeek.ToString()){ $block=$true; $note=$note??'weekday-freeze' } }
if($block){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='change_freeze';note=$note;decision='block'}; exit 8 }
exit 0

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$fp=Join-Path $Base 'config\freeze.json'; if(-not (Test-Path $fp)){ exit 0 }
try{$fz=Get-Content $fp -Raw|ConvertFrom-Json}catch{ exit 0 }
$now=Get-Date; $block=$false; $note=$null
if($fz.Ranges){ foreach($r in $fz.Ranges){ try{$f=[datetime]$r.From;$t=[datetime]$r.To; if($now -ge $f -and $now -le $t){$block=$true;$note=$r.Note;break}}catch{} } }
if(-not $block -and $fz.Weekdays){ if($fz.Weekdays -contains $now.DayOfWeek.ToString()){ $block=$true; $note=$note??'weekday-freeze' } }
if($block){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='change_freeze';note=$note;decision='block'}; exit 8 }
exit 0

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$fp=Join-Path $Base 'config\freeze.json'; if(-not (Test-Path $fp)){ exit 0 }
try{$fz=Get-Content $fp -Raw|ConvertFrom-Json}catch{ exit 0 }
$now=Get-Date; $block=$false; $note=$null
if($fz.Ranges){ foreach($r in $fz.Ranges){ try{$f=[datetime]$r.From;$t=[datetime]$r.To; if($now -ge $f -and $now -le $t){$block=$true;$note=$r.Note;break}}catch{} } }
if(-not $block -and $fz.Weekdays){ if($fz.Weekdays -contains $now.DayOfWeek.ToString()){ $block=$true; $note=$note??'weekday-freeze' } }
if($block){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='change_freeze';note=$note;decision='block'}; exit 8 }
exit 0

