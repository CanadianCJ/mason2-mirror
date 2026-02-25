$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$pol = Join-Path $Base 'config\policy.json'
$back = @{window_min=30; max_in_window=3}
$autoDisable=$true
try{ if(Test-Path $cfg){ $j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.restart_backoff){ $back=$j.restart_backoff } } }catch{}
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.quarantine -and $p.quarantine.auto_disable -ne $null){ $autoDisable=[bool]$p.quarantine.auto_disable } } }catch{}
$stateP = Join-Path $Base 'reports\watchdog_state.jsonl'
$now=Get-Date; $cut=$now.AddMinutes(-([int]$back.window_min))
$recent=@{}
if(Test-Path $stateP){
  Get-Content $stateP -ErrorAction SilentlyContinue | Select-String -SimpleMatch ($now.ToString('yyyy-MM-dd')) | ForEach-Object {
    try{ $x=$_.ToString()|ConvertFrom-Json; if($x.kind -eq 'restart'){ $k=$x.task; if(-not $recent[$k]){ $recent[$k]=@() }; $recent[$k]+=[datetime]$x.ts } }catch{}
  }
}
$tasks = @(); try{ $tasks = Get-Content $cfg -Raw | ConvertFrom-Json | Select-Object -Expand tasks_expected -ErrorAction SilentlyContinue }catch{}
foreach($tn in $tasks){
  $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
  if(-not $t){ continue }
  $info = $t | Get-ScheduledTaskInfo
  $isRunning = $t.State -eq 'Running'
  if(-not $isRunning){
    $hist = $recent[$tn] | Where-Object { $_ -ge $cut }
    if($hist.Count -ge [int]$back.max_in_window){
      if($autoDisable){ try{ Disable-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{} }
      Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='quarantine'; task=$tn; window_min=$back.window_min; count=$hist.Count; auto_disabled=$autoDisable }
      continue
    }
    try{ Start-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{}
    Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='restart'; task=$tn }
  }
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$pol = Join-Path $Base 'config\policy.json'
$back = @{window_min=30; max_in_window=3}
$autoDisable=$true
try{ if(Test-Path $cfg){ $j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.restart_backoff){ $back=$j.restart_backoff } } }catch{}
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.quarantine -and $p.quarantine.auto_disable -ne $null){ $autoDisable=[bool]$p.quarantine.auto_disable } } }catch{}
$stateP = Join-Path $Base 'reports\watchdog_state.jsonl'
$now=Get-Date; $cut=$now.AddMinutes(-([int]$back.window_min))
$recent=@{}
if(Test-Path $stateP){
  Get-Content $stateP -ErrorAction SilentlyContinue | Select-String -SimpleMatch ($now.ToString('yyyy-MM-dd')) | ForEach-Object {
    try{ $x=$_.ToString()|ConvertFrom-Json; if($x.kind -eq 'restart'){ $k=$x.task; if(-not $recent[$k]){ $recent[$k]=@() }; $recent[$k]+=[datetime]$x.ts } }catch{}
  }
}
$tasks = @(); try{ $tasks = Get-Content $cfg -Raw | ConvertFrom-Json | Select-Object -Expand tasks_expected -ErrorAction SilentlyContinue }catch{}
foreach($tn in $tasks){
  $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
  if(-not $t){ continue }
  $info = $t | Get-ScheduledTaskInfo
  $isRunning = $t.State -eq 'Running'
  if(-not $isRunning){
    $hist = $recent[$tn] | Where-Object { $_ -ge $cut }
    if($hist.Count -ge [int]$back.max_in_window){
      if($autoDisable){ try{ Disable-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{} }
      Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='quarantine'; task=$tn; window_min=$back.window_min; count=$hist.Count; auto_disabled=$autoDisable }
      continue
    }
    try{ Start-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{}
    Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='restart'; task=$tn }
  }
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$pol = Join-Path $Base 'config\policy.json'
$back = @{window_min=30; max_in_window=3}
$autoDisable=$true
try{ if(Test-Path $cfg){ $j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.restart_backoff){ $back=$j.restart_backoff } } }catch{}
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.quarantine -and $p.quarantine.auto_disable -ne $null){ $autoDisable=[bool]$p.quarantine.auto_disable } } }catch{}
$stateP = Join-Path $Base 'reports\watchdog_state.jsonl'
$now=Get-Date; $cut=$now.AddMinutes(-([int]$back.window_min))
$recent=@{}
if(Test-Path $stateP){
  Get-Content $stateP -ErrorAction SilentlyContinue | Select-String -SimpleMatch ($now.ToString('yyyy-MM-dd')) | ForEach-Object {
    try{ $x=$_.ToString()|ConvertFrom-Json; if($x.kind -eq 'restart'){ $k=$x.task; if(-not $recent[$k]){ $recent[$k]=@() }; $recent[$k]+=[datetime]$x.ts } }catch{}
  }
}
$tasks = @(); try{ $tasks = Get-Content $cfg -Raw | ConvertFrom-Json | Select-Object -Expand tasks_expected -ErrorAction SilentlyContinue }catch{}
foreach($tn in $tasks){
  $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
  if(-not $t){ continue }
  $info = $t | Get-ScheduledTaskInfo
  $isRunning = $t.State -eq 'Running'
  if(-not $isRunning){
    $hist = $recent[$tn] | Where-Object { $_ -ge $cut }
    if($hist.Count -ge [int]$back.max_in_window){
      if($autoDisable){ try{ Disable-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{} }
      Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='quarantine'; task=$tn; window_min=$back.window_min; count=$hist.Count; auto_disabled=$autoDisable }
      continue
    }
    try{ Start-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{}
    Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='restart'; task=$tn }
  }
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$pol = Join-Path $Base 'config\policy.json'
$back = @{window_min=30; max_in_window=3}
$autoDisable=$true
try{ if(Test-Path $cfg){ $j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.restart_backoff){ $back=$j.restart_backoff } } }catch{}
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.quarantine -and $p.quarantine.auto_disable -ne $null){ $autoDisable=[bool]$p.quarantine.auto_disable } } }catch{}
$stateP = Join-Path $Base 'reports\watchdog_state.jsonl'
$now=Get-Date; $cut=$now.AddMinutes(-([int]$back.window_min))
$recent=@{}
if(Test-Path $stateP){
  Get-Content $stateP -ErrorAction SilentlyContinue | Select-String -SimpleMatch ($now.ToString('yyyy-MM-dd')) | ForEach-Object {
    try{ $x=$_.ToString()|ConvertFrom-Json; if($x.kind -eq 'restart'){ $k=$x.task; if(-not $recent[$k]){ $recent[$k]=@() }; $recent[$k]+=[datetime]$x.ts } }catch{}
  }
}
$tasks = @(); try{ $tasks = Get-Content $cfg -Raw | ConvertFrom-Json | Select-Object -Expand tasks_expected -ErrorAction SilentlyContinue }catch{}
foreach($tn in $tasks){
  $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
  if(-not $t){ continue }
  $info = $t | Get-ScheduledTaskInfo
  $isRunning = $t.State -eq 'Running'
  if(-not $isRunning){
    $hist = $recent[$tn] | Where-Object { $_ -ge $cut }
    if($hist.Count -ge [int]$back.max_in_window){
      if($autoDisable){ try{ Disable-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{} }
      Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='quarantine'; task=$tn; window_min=$back.window_min; count=$hist.Count; auto_disabled=$autoDisable }
      continue
    }
    try{ Start-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{}
    Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='restart'; task=$tn }
  }
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$pol = Join-Path $Base 'config\policy.json'
$back = @{window_min=30; max_in_window=3}
$autoDisable=$true
try{ if(Test-Path $cfg){ $j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.restart_backoff){ $back=$j.restart_backoff } } }catch{}
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.quarantine -and $p.quarantine.auto_disable -ne $null){ $autoDisable=[bool]$p.quarantine.auto_disable } } }catch{}
$stateP = Join-Path $Base 'reports\watchdog_state.jsonl'
$now=Get-Date; $cut=$now.AddMinutes(-([int]$back.window_min))
$recent=@{}
if(Test-Path $stateP){
  Get-Content $stateP -ErrorAction SilentlyContinue | Select-String -SimpleMatch ($now.ToString('yyyy-MM-dd')) | ForEach-Object {
    try{ $x=$_.ToString()|ConvertFrom-Json; if($x.kind -eq 'restart'){ $k=$x.task; if(-not $recent[$k]){ $recent[$k]=@() }; $recent[$k]+=[datetime]$x.ts } }catch{}
  }
}
$tasks = @(); try{ $tasks = Get-Content $cfg -Raw | ConvertFrom-Json | Select-Object -Expand tasks_expected -ErrorAction SilentlyContinue }catch{}
foreach($tn in $tasks){
  $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
  if(-not $t){ continue }
  $info = $t | Get-ScheduledTaskInfo
  $isRunning = $t.State -eq 'Running'
  if(-not $isRunning){
    $hist = $recent[$tn] | Where-Object { $_ -ge $cut }
    if($hist.Count -ge [int]$back.max_in_window){
      if($autoDisable){ try{ Disable-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{} }
      Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='quarantine'; task=$tn; window_min=$back.window_min; count=$hist.Count; auto_disabled=$autoDisable }
      continue
    }
    try{ Start-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{}
    Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='restart'; task=$tn }
  }
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$pol = Join-Path $Base 'config\policy.json'
$back = @{window_min=30; max_in_window=3}
$autoDisable=$true
try{ if(Test-Path $cfg){ $j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.restart_backoff){ $back=$j.restart_backoff } } }catch{}
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.quarantine -and $p.quarantine.auto_disable -ne $null){ $autoDisable=[bool]$p.quarantine.auto_disable } } }catch{}
$stateP = Join-Path $Base 'reports\watchdog_state.jsonl'
$now=Get-Date; $cut=$now.AddMinutes(-([int]$back.window_min))
$recent=@{}
if(Test-Path $stateP){
  Get-Content $stateP -ErrorAction SilentlyContinue | Select-String -SimpleMatch ($now.ToString('yyyy-MM-dd')) | ForEach-Object {
    try{ $x=$_.ToString()|ConvertFrom-Json; if($x.kind -eq 'restart'){ $k=$x.task; if(-not $recent[$k]){ $recent[$k]=@() }; $recent[$k]+=[datetime]$x.ts } }catch{}
  }
}
$tasks = @(); try{ $tasks = Get-Content $cfg -Raw | ConvertFrom-Json | Select-Object -Expand tasks_expected -ErrorAction SilentlyContinue }catch{}
foreach($tn in $tasks){
  $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
  if(-not $t){ continue }
  $info = $t | Get-ScheduledTaskInfo
  $isRunning = $t.State -eq 'Running'
  if(-not $isRunning){
    $hist = $recent[$tn] | Where-Object { $_ -ge $cut }
    if($hist.Count -ge [int]$back.max_in_window){
      if($autoDisable){ try{ Disable-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{} }
      Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='quarantine'; task=$tn; window_min=$back.window_min; count=$hist.Count; auto_disabled=$autoDisable }
      continue
    }
    try{ Start-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{}
    Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='restart'; task=$tn }
  }
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$pol = Join-Path $Base 'config\policy.json'
$back = @{window_min=30; max_in_window=3}
$autoDisable=$true
try{ if(Test-Path $cfg){ $j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.restart_backoff){ $back=$j.restart_backoff } } }catch{}
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.quarantine -and $p.quarantine.auto_disable -ne $null){ $autoDisable=[bool]$p.quarantine.auto_disable } } }catch{}
$stateP = Join-Path $Base 'reports\watchdog_state.jsonl'
$now=Get-Date; $cut=$now.AddMinutes(-([int]$back.window_min))
$recent=@{}
if(Test-Path $stateP){
  Get-Content $stateP -ErrorAction SilentlyContinue | Select-String -SimpleMatch ($now.ToString('yyyy-MM-dd')) | ForEach-Object {
    try{ $x=$_.ToString()|ConvertFrom-Json; if($x.kind -eq 'restart'){ $k=$x.task; if(-not $recent[$k]){ $recent[$k]=@() }; $recent[$k]+=[datetime]$x.ts } }catch{}
  }
}
$tasks = @(); try{ $tasks = Get-Content $cfg -Raw | ConvertFrom-Json | Select-Object -Expand tasks_expected -ErrorAction SilentlyContinue }catch{}
foreach($tn in $tasks){
  $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
  if(-not $t){ continue }
  $info = $t | Get-ScheduledTaskInfo
  $isRunning = $t.State -eq 'Running'
  if(-not $isRunning){
    $hist = $recent[$tn] | Where-Object { $_ -ge $cut }
    if($hist.Count -ge [int]$back.max_in_window){
      if($autoDisable){ try{ Disable-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{} }
      Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='quarantine'; task=$tn; window_min=$back.window_min; count=$hist.Count; auto_disabled=$autoDisable }
      continue
    }
    try{ Start-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{}
    Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='restart'; task=$tn }
  }
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$cfg = Join-Path $Base 'config\watchdog.json'
$pol = Join-Path $Base 'config\policy.json'
$back = @{window_min=30; max_in_window=3}
$autoDisable=$true
try{ if(Test-Path $cfg){ $j=Get-Content $cfg -Raw|ConvertFrom-Json; if($j.restart_backoff){ $back=$j.restart_backoff } } }catch{}
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.quarantine -and $p.quarantine.auto_disable -ne $null){ $autoDisable=[bool]$p.quarantine.auto_disable } } }catch{}
$stateP = Join-Path $Base 'reports\watchdog_state.jsonl'
$now=Get-Date; $cut=$now.AddMinutes(-([int]$back.window_min))
$recent=@{}
if(Test-Path $stateP){
  Get-Content $stateP -ErrorAction SilentlyContinue | Select-String -SimpleMatch ($now.ToString('yyyy-MM-dd')) | ForEach-Object {
    try{ $x=$_.ToString()|ConvertFrom-Json; if($x.kind -eq 'restart'){ $k=$x.task; if(-not $recent[$k]){ $recent[$k]=@() }; $recent[$k]+=[datetime]$x.ts } }catch{}
  }
}
$tasks = @(); try{ $tasks = Get-Content $cfg -Raw | ConvertFrom-Json | Select-Object -Expand tasks_expected -ErrorAction SilentlyContinue }catch{}
foreach($tn in $tasks){
  $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
  if(-not $t){ continue }
  $info = $t | Get-ScheduledTaskInfo
  $isRunning = $t.State -eq 'Running'
  if(-not $isRunning){
    $hist = $recent[$tn] | Where-Object { $_ -ge $cut }
    if($hist.Count -ge [int]$back.max_in_window){
      if($autoDisable){ try{ Disable-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{} }
      Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='quarantine'; task=$tn; window_min=$back.window_min; count=$hist.Count; auto_disabled=$autoDisable }
      continue
    }
    try{ Start-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue | Out-Null }catch{}
    Write-JsonLineSafe -Path $stateP -Obj @{ ts=$now.ToString('s'); kind='restart'; task=$tn }
  }
}
