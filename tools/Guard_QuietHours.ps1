# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg=Join-Path $Base 'config\mason2.config.json'; $spans=@()
if(Test-Path $cfg){ try{$j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.Auto -and $j.Auto.QuietHours){ $spans=@($j.Auto.QuietHours) }}catch{} }
if(-not $spans -or $spans.Count -eq 0){ exit 0 }
function In-Span($now,[string]$span){
  if(-not $span -or -not $span.Contains('-')){ return $false }
  $p=$span.Split('-',2); $fmt='HH:mm'
  try{$t1=[datetime]::ParseExact($p[0].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture);$t2=[datetime]::ParseExact($p[1].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture)}catch{return $false}
  $n=[datetime]::ParseExact($now.ToString($fmt),$fmt,[Globalization.CultureInfo]::InvariantCulture)
  if($t1 -le $t2){ return ($n -ge $t1 -and $n -le $t2) } else { return ($n -ge $t1 -or $n -le $t2) }
}
$now=Get-Date; $hit=$spans|Where-Object{ In-Span $now $_ }|Select-Object -First 1
if($hit){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='quiet_hours';span=$hit;decision='block'}; exit 9 }
exit 0

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg=Join-Path $Base 'config\mason2.config.json'; $spans=@()
if(Test-Path $cfg){ try{$j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.Auto -and $j.Auto.QuietHours){ $spans=@($j.Auto.QuietHours) }}catch{} }
if(-not $spans -or $spans.Count -eq 0){ exit 0 }
function In-Span($now,[string]$span){
  if(-not $span -or -not $span.Contains('-')){ return $false }
  $p=$span.Split('-',2); $fmt='HH:mm'
  try{$t1=[datetime]::ParseExact($p[0].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture);$t2=[datetime]::ParseExact($p[1].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture)}catch{return $false}
  $n=[datetime]::ParseExact($now.ToString($fmt),$fmt,[Globalization.CultureInfo]::InvariantCulture)
  if($t1 -le $t2){ return ($n -ge $t1 -and $n -le $t2) } else { return ($n -ge $t1 -or $n -le $t2) }
}
$now=Get-Date; $hit=$spans|Where-Object{ In-Span $now $_ }|Select-Object -First 1
if($hit){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='quiet_hours';span=$hit;decision='block'}; exit 9 }
exit 0

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg=Join-Path $Base 'config\mason2.config.json'; $spans=@()
if(Test-Path $cfg){ try{$j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.Auto -and $j.Auto.QuietHours){ $spans=@($j.Auto.QuietHours) }}catch{} }
if(-not $spans -or $spans.Count -eq 0){ exit 0 }
function In-Span($now,[string]$span){
  if(-not $span -or -not $span.Contains('-')){ return $false }
  $p=$span.Split('-',2); $fmt='HH:mm'
  try{$t1=[datetime]::ParseExact($p[0].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture);$t2=[datetime]::ParseExact($p[1].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture)}catch{return $false}
  $n=[datetime]::ParseExact($now.ToString($fmt),$fmt,[Globalization.CultureInfo]::InvariantCulture)
  if($t1 -le $t2){ return ($n -ge $t1 -and $n -le $t2) } else { return ($n -ge $t1 -or $n -le $t2) }
}
$now=Get-Date; $hit=$spans|Where-Object{ In-Span $now $_ }|Select-Object -First 1
if($hit){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='quiet_hours';span=$hit;decision='block'}; exit 9 }
exit 0

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg=Join-Path $Base 'config\mason2.config.json'; $spans=@()
if(Test-Path $cfg){ try{$j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.Auto -and $j.Auto.QuietHours){ $spans=@($j.Auto.QuietHours) }}catch{} }
if(-not $spans -or $spans.Count -eq 0){ exit 0 }
function In-Span($now,[string]$span){
  if(-not $span -or -not $span.Contains('-')){ return $false }
  $p=$span.Split('-',2); $fmt='HH:mm'
  try{$t1=[datetime]::ParseExact($p[0].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture);$t2=[datetime]::ParseExact($p[1].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture)}catch{return $false}
  $n=[datetime]::ParseExact($now.ToString($fmt),$fmt,[Globalization.CultureInfo]::InvariantCulture)
  if($t1 -le $t2){ return ($n -ge $t1 -and $n -le $t2) } else { return ($n -ge $t1 -or $n -le $t2) }
}
$now=Get-Date; $hit=$spans|Where-Object{ In-Span $now $_ }|Select-Object -First 1
if($hit){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='quiet_hours';span=$hit;decision='block'}; exit 9 }
exit 0

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg=Join-Path $Base 'config\mason2.config.json'; $spans=@()
if(Test-Path $cfg){ try{$j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.Auto -and $j.Auto.QuietHours){ $spans=@($j.Auto.QuietHours) }}catch{} }
if(-not $spans -or $spans.Count -eq 0){ exit 0 }
function In-Span($now,[string]$span){
  if(-not $span -or -not $span.Contains('-')){ return $false }
  $p=$span.Split('-',2); $fmt='HH:mm'
  try{$t1=[datetime]::ParseExact($p[0].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture);$t2=[datetime]::ParseExact($p[1].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture)}catch{return $false}
  $n=[datetime]::ParseExact($now.ToString($fmt),$fmt,[Globalization.CultureInfo]::InvariantCulture)
  if($t1 -le $t2){ return ($n -ge $t1 -and $n -le $t2) } else { return ($n -ge $t1 -or $n -le $t2) }
}
$now=Get-Date; $hit=$spans|Where-Object{ In-Span $now $_ }|Select-Object -First 1
if($hit){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='quiet_hours';span=$hit;decision='block'}; exit 9 }
exit 0

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg=Join-Path $Base 'config\mason2.config.json'; $spans=@()
if(Test-Path $cfg){ try{$j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.Auto -and $j.Auto.QuietHours){ $spans=@($j.Auto.QuietHours) }}catch{} }
if(-not $spans -or $spans.Count -eq 0){ exit 0 }
function In-Span($now,[string]$span){
  if(-not $span -or -not $span.Contains('-')){ return $false }
  $p=$span.Split('-',2); $fmt='HH:mm'
  try{$t1=[datetime]::ParseExact($p[0].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture);$t2=[datetime]::ParseExact($p[1].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture)}catch{return $false}
  $n=[datetime]::ParseExact($now.ToString($fmt),$fmt,[Globalization.CultureInfo]::InvariantCulture)
  if($t1 -le $t2){ return ($n -ge $t1 -and $n -le $t2) } else { return ($n -ge $t1 -or $n -le $t2) }
}
$now=Get-Date; $hit=$spans|Where-Object{ In-Span $now $_ }|Select-Object -First 1
if($hit){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='quiet_hours';span=$hit;decision='block'}; exit 9 }
exit 0

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg=Join-Path $Base 'config\mason2.config.json'; $spans=@()
if(Test-Path $cfg){ try{$j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.Auto -and $j.Auto.QuietHours){ $spans=@($j.Auto.QuietHours) }}catch{} }
if(-not $spans -or $spans.Count -eq 0){ exit 0 }
function In-Span($now,[string]$span){
  if(-not $span -or -not $span.Contains('-')){ return $false }
  $p=$span.Split('-',2); $fmt='HH:mm'
  try{$t1=[datetime]::ParseExact($p[0].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture);$t2=[datetime]::ParseExact($p[1].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture)}catch{return $false}
  $n=[datetime]::ParseExact($now.ToString($fmt),$fmt,[Globalization.CultureInfo]::InvariantCulture)
  if($t1 -le $t2){ return ($n -ge $t1 -and $n -le $t2) } else { return ($n -ge $t1 -or $n -le $t2) }
}
$now=Get-Date; $hit=$spans|Where-Object{ In-Span $now $_ }|Select-Object -First 1
if($hit){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='quiet_hours';span=$hit;decision='block'}; exit 9 }
exit 0

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base = "$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
if (Test-Path (Join-Path $Base "tools\Common.ps1")){ . (Join-Path $Base "tools\Common.ps1") }
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg=Join-Path $Base 'config\mason2.config.json'; $spans=@()
if(Test-Path $cfg){ try{$j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.Auto -and $j.Auto.QuietHours){ $spans=@($j.Auto.QuietHours) }}catch{} }
if(-not $spans -or $spans.Count -eq 0){ exit 0 }
function In-Span($now,[string]$span){
  if(-not $span -or -not $span.Contains('-')){ return $false }
  $p=$span.Split('-',2); $fmt='HH:mm'
  try{$t1=[datetime]::ParseExact($p[0].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture);$t2=[datetime]::ParseExact($p[1].Trim(),$fmt,[Globalization.CultureInfo]::InvariantCulture)}catch{return $false}
  $n=[datetime]::ParseExact($now.ToString($fmt),$fmt,[Globalization.CultureInfo]::InvariantCulture)
  if($t1 -le $t2){ return ($n -ge $t1 -and $n -le $t2) } else { return ($n -ge $t1 -or $n -le $t2) }
}
$now=Get-Date; $hit=$spans|Where-Object{ In-Span $now $_ }|Select-Object -First 1
if($hit){ Write-JsonLineSafe -Path (Join-Path $Base 'reports\ops_gates.jsonl') -Obj @{ts=$now.ToString('s');kind='gate';gate='quiet_hours';span=$hit;decision='block'}; exit 9 }
exit 0

