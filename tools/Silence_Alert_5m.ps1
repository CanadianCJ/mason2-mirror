# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$path = Join-Path $Base 'reports\cadence.jsonl'
$now=Get-Date; $names=@('Learner','Governor','Watchdog','TopicSync','AutoAdvance')
foreach($n in $names){
  $ok=$false
  if(Test-Path $path){
    $lines = Get-Content $path -Tail 200 -ErrorAction SilentlyContinue
    foreach($l in ($lines | Select-Object -Last 50)){
      try{ $j=$l|ConvertFrom-Json }catch{ continue }
      if($j.name -eq $n){
        try{ $t=[datetime]::Parse($j.ts) }catch{ continue }
        if(($now-$t).TotalMinutes -le $Minutes){ $ok=$true }
        break
      }
    }
  }
  if(-not $ok){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\silence_alerts.jsonl') -Obj @{ ts=$now.ToString('s'); kind='silence'; name=$n; window_min=$Minutes }
  }
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$path = Join-Path $Base 'reports\cadence.jsonl'
$now=Get-Date; $names=@('Learner','Governor','Watchdog','TopicSync','AutoAdvance')
foreach($n in $names){
  $ok=$false
  if(Test-Path $path){
    $lines = Get-Content $path -Tail 200 -ErrorAction SilentlyContinue
    foreach($l in ($lines | Select-Object -Last 50)){
      try{ $j=$l|ConvertFrom-Json }catch{ continue }
      if($j.name -eq $n){
        try{ $t=[datetime]::Parse($j.ts) }catch{ continue }
        if(($now-$t).TotalMinutes -le $Minutes){ $ok=$true }
        break
      }
    }
  }
  if(-not $ok){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\silence_alerts.jsonl') -Obj @{ ts=$now.ToString('s'); kind='silence'; name=$n; window_min=$Minutes }
  }
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$path = Join-Path $Base 'reports\cadence.jsonl'
$now=Get-Date; $names=@('Learner','Governor','Watchdog','TopicSync','AutoAdvance')
foreach($n in $names){
  $ok=$false
  if(Test-Path $path){
    $lines = Get-Content $path -Tail 200 -ErrorAction SilentlyContinue
    foreach($l in ($lines | Select-Object -Last 50)){
      try{ $j=$l|ConvertFrom-Json }catch{ continue }
      if($j.name -eq $n){
        try{ $t=[datetime]::Parse($j.ts) }catch{ continue }
        if(($now-$t).TotalMinutes -le $Minutes){ $ok=$true }
        break
      }
    }
  }
  if(-not $ok){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\silence_alerts.jsonl') -Obj @{ ts=$now.ToString('s'); kind='silence'; name=$n; window_min=$Minutes }
  }
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$path = Join-Path $Base 'reports\cadence.jsonl'
$now=Get-Date; $names=@('Learner','Governor','Watchdog','TopicSync','AutoAdvance')
foreach($n in $names){
  $ok=$false
  if(Test-Path $path){
    $lines = Get-Content $path -Tail 200 -ErrorAction SilentlyContinue
    foreach($l in ($lines | Select-Object -Last 50)){
      try{ $j=$l|ConvertFrom-Json }catch{ continue }
      if($j.name -eq $n){
        try{ $t=[datetime]::Parse($j.ts) }catch{ continue }
        if(($now-$t).TotalMinutes -le $Minutes){ $ok=$true }
        break
      }
    }
  }
  if(-not $ok){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\silence_alerts.jsonl') -Obj @{ ts=$now.ToString('s'); kind='silence'; name=$n; window_min=$Minutes }
  }
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$path = Join-Path $Base 'reports\cadence.jsonl'
$now=Get-Date; $names=@('Learner','Governor','Watchdog','TopicSync','AutoAdvance')
foreach($n in $names){
  $ok=$false
  if(Test-Path $path){
    $lines = Get-Content $path -Tail 200 -ErrorAction SilentlyContinue
    foreach($l in ($lines | Select-Object -Last 50)){
      try{ $j=$l|ConvertFrom-Json }catch{ continue }
      if($j.name -eq $n){
        try{ $t=[datetime]::Parse($j.ts) }catch{ continue }
        if(($now-$t).TotalMinutes -le $Minutes){ $ok=$true }
        break
      }
    }
  }
  if(-not $ok){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\silence_alerts.jsonl') -Obj @{ ts=$now.ToString('s'); kind='silence'; name=$n; window_min=$Minutes }
  }
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$path = Join-Path $Base 'reports\cadence.jsonl'
$now=Get-Date; $names=@('Learner','Governor','Watchdog','TopicSync','AutoAdvance')
foreach($n in $names){
  $ok=$false
  if(Test-Path $path){
    $lines = Get-Content $path -Tail 200 -ErrorAction SilentlyContinue
    foreach($l in ($lines | Select-Object -Last 50)){
      try{ $j=$l|ConvertFrom-Json }catch{ continue }
      if($j.name -eq $n){
        try{ $t=[datetime]::Parse($j.ts) }catch{ continue }
        if(($now-$t).TotalMinutes -le $Minutes){ $ok=$true }
        break
      }
    }
  }
  if(-not $ok){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\silence_alerts.jsonl') -Obj @{ ts=$now.ToString('s'); kind='silence'; name=$n; window_min=$Minutes }
  }
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$path = Join-Path $Base 'reports\cadence.jsonl'
$now=Get-Date; $names=@('Learner','Governor','Watchdog','TopicSync','AutoAdvance')
foreach($n in $names){
  $ok=$false
  if(Test-Path $path){
    $lines = Get-Content $path -Tail 200 -ErrorAction SilentlyContinue
    foreach($l in ($lines | Select-Object -Last 50)){
      try{ $j=$l|ConvertFrom-Json }catch{ continue }
      if($j.name -eq $n){
        try{ $t=[datetime]::Parse($j.ts) }catch{ continue }
        if(($now-$t).TotalMinutes -le $Minutes){ $ok=$true }
        break
      }
    }
  }
  if(-not $ok){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\silence_alerts.jsonl') -Obj @{ ts=$now.ToString('s'); kind='silence'; name=$n; window_min=$Minutes }
  }
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Minutes=5)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$path = Join-Path $Base 'reports\cadence.jsonl'
$now=Get-Date; $names=@('Learner','Governor','Watchdog','TopicSync','AutoAdvance')
foreach($n in $names){
  $ok=$false
  if(Test-Path $path){
    $lines = Get-Content $path -Tail 200 -ErrorAction SilentlyContinue
    foreach($l in ($lines | Select-Object -Last 50)){
      try{ $j=$l|ConvertFrom-Json }catch{ continue }
      if($j.name -eq $n){
        try{ $t=[datetime]::Parse($j.ts) }catch{ continue }
        if(($now-$t).TotalMinutes -le $Minutes){ $ok=$true }
        break
      }
    }
  }
  if(-not $ok){
    Write-JsonLineSafe -Path (Join-Path $Base 'reports\silence_alerts.jsonl') -Obj @{ ts=$now.ToString('s'); kind='silence'; name=$n; window_min=$Minutes }
  }
}

