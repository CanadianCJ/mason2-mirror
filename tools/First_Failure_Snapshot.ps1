$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$src = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $src)){ exit 0 }

$lines = Get-Content $src -Tail 500 -ErrorAction SilentlyContinue
$cand = @()
foreach($l in $lines){
  try { $j=$l | ConvertFrom-Json } catch { $j=$null }
  if($j -and $j.rc -and $j.rc -ne 0){ $cand += $j }
}
if($cand.Count -eq 0){ exit 0 }

$last = $cand | Select-Object -Last 1

# Ensure properties exist in PS 5.1 style
$hasTsEnd = $last -and $last.PSObject.Properties['ts_end'] -and $last.ts_end
$hasTs    = $last -and $last.PSObject.Properties['ts']     -and $last.ts
$hasFile  = $last -and $last.PSObject.Properties['file']   -and $last.file

if(-not $hasTsEnd -and $hasTs){
  try { $last | Add-Member -NotePropertyName ts_end -NotePropertyValue $last.ts -Force } catch {}
}
if(-not $hasFile){
  try { $last | Add-Member -NotePropertyName file -NotePropertyValue 'unknown' -Force } catch {}
}

# Build a stable snapshot key (no ??)
$tsKey = $null
if($last.PSObject.Properties['ts_end'] -and $last.ts_end){ $tsKey = [string]$last.ts_end }
elseif($last.PSObject.Properties['ts'] -and $last.ts){     $tsKey = [string]$last.ts }
else { $tsKey = (Get-Date).ToString('s') }

$fileKey = if($last.PSObject.Properties['file'] -and $last.file){ [string]$last.file } else { 'unknown' }
$key = $tsKey + '|' + $fileKey

$seen = Join-Path $Base 'reports\audit\firstfail_seen.txt'
$already=$false
if(Test-Path $seen){
  try{ $already = (Select-String -Path $seen -SimpleMatch $key -ErrorAction SilentlyContinue) -ne $null }catch{}
}
if($already){ exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$dst = Join-Path $Base ("reports\snapshots\fail_" + $stamp)
New-Item -ItemType Directory -Force -Path $dst | Out-Null

# gather tails from a few useful reports
$targets = @('exec_log.jsonl','schedule_drift.jsonl','health_index.jsonl','cadence.jsonl','watchdog_state.jsonl')
foreach($t in $targets){
  $p = Join-Path $Base ('reports\' + $t)
  if(Test-Path $p){
    try{ Get-Content $p -Tail $Tail -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $dst $t) -Encoding UTF8 }catch{}
  }
}

# copy referenced tool if exists
if($last.file){
  $tool = Join-Path $Base $last.file
  if(Test-Path $tool){ try{ Copy-Item -LiteralPath $tool -Destination (Join-Path $dst ([IO.Path]::GetFileName($tool))) -Force }catch{} }
}

# manifest + marker
$man = [pscustomobject]@{ ts=(Get-Date).ToString('s'); kind='first_failure'; line=$last; folder=(Resolve-Path $dst).Path }
($man | ConvertTo-Json -Depth 8) | Out-File -FilePath (Join-Path $dst 'manifest.json') -Encoding UTF8
Add-Content -LiteralPath $seen -Value $key

Write-JsonLineSafe -Path (Join-Path $Base 'reports\first_failure.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='first_failure'; snapshot=$dst; file=$last.file; rc=$last.rc }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Tail=200)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$src = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $src)){ exit 0 }

$lines = Get-Content $src -Tail 500 -ErrorAction SilentlyContinue
$cand = @()
foreach($l in $lines){
  try { $j=$l | ConvertFrom-Json } catch { $j=$null }
  if($j -and $j.rc -and $j.rc -ne 0){ $cand += $j }
}
if($cand.Count -eq 0){ exit 0 }

$last = $cand | Select-Object -Last 1

# Ensure properties exist in PS 5.1 style
$hasTsEnd = $last -and $last.PSObject.Properties['ts_end'] -and $last.ts_end
$hasTs    = $last -and $last.PSObject.Properties['ts']     -and $last.ts
$hasFile  = $last -and $last.PSObject.Properties['file']   -and $last.file

if(-not $hasTsEnd -and $hasTs){
  try { $last | Add-Member -NotePropertyName ts_end -NotePropertyValue $last.ts -Force } catch {}
}
if(-not $hasFile){
  try { $last | Add-Member -NotePropertyName file -NotePropertyValue 'unknown' -Force } catch {}
}

# Build a stable snapshot key (no ??)
$tsKey = $null
if($last.PSObject.Properties['ts_end'] -and $last.ts_end){ $tsKey = [string]$last.ts_end }
elseif($last.PSObject.Properties['ts'] -and $last.ts){     $tsKey = [string]$last.ts }
else { $tsKey = (Get-Date).ToString('s') }

$fileKey = if($last.PSObject.Properties['file'] -and $last.file){ [string]$last.file } else { 'unknown' }
$key = $tsKey + '|' + $fileKey

$seen = Join-Path $Base 'reports\audit\firstfail_seen.txt'
$already=$false
if(Test-Path $seen){
  try{ $already = (Select-String -Path $seen -SimpleMatch $key -ErrorAction SilentlyContinue) -ne $null }catch{}
}
if($already){ exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$dst = Join-Path $Base ("reports\snapshots\fail_" + $stamp)
New-Item -ItemType Directory -Force -Path $dst | Out-Null

# gather tails from a few useful reports
$targets = @('exec_log.jsonl','schedule_drift.jsonl','health_index.jsonl','cadence.jsonl','watchdog_state.jsonl')
foreach($t in $targets){
  $p = Join-Path $Base ('reports\' + $t)
  if(Test-Path $p){
    try{ Get-Content $p -Tail $Tail -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $dst $t) -Encoding UTF8 }catch{}
  }
}

# copy referenced tool if exists
if($last.file){
  $tool = Join-Path $Base $last.file
  if(Test-Path $tool){ try{ Copy-Item -LiteralPath $tool -Destination (Join-Path $dst ([IO.Path]::GetFileName($tool))) -Force }catch{} }
}

# manifest + marker
$man = [pscustomobject]@{ ts=(Get-Date).ToString('s'); kind='first_failure'; line=$last; folder=(Resolve-Path $dst).Path }
($man | ConvertTo-Json -Depth 8) | Out-File -FilePath (Join-Path $dst 'manifest.json') -Encoding UTF8
Add-Content -LiteralPath $seen -Value $key

Write-JsonLineSafe -Path (Join-Path $Base 'reports\first_failure.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='first_failure'; snapshot=$dst; file=$last.file; rc=$last.rc }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Tail=200)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$src = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $src)){ exit 0 }

$lines = Get-Content $src -Tail 500 -ErrorAction SilentlyContinue
$cand = @()
foreach($l in $lines){
  try { $j=$l | ConvertFrom-Json } catch { $j=$null }
  if($j -and $j.rc -and $j.rc -ne 0){ $cand += $j }
}
if($cand.Count -eq 0){ exit 0 }

$last = $cand | Select-Object -Last 1

# Ensure properties exist in PS 5.1 style
$hasTsEnd = $last -and $last.PSObject.Properties['ts_end'] -and $last.ts_end
$hasTs    = $last -and $last.PSObject.Properties['ts']     -and $last.ts
$hasFile  = $last -and $last.PSObject.Properties['file']   -and $last.file

if(-not $hasTsEnd -and $hasTs){
  try { $last | Add-Member -NotePropertyName ts_end -NotePropertyValue $last.ts -Force } catch {}
}
if(-not $hasFile){
  try { $last | Add-Member -NotePropertyName file -NotePropertyValue 'unknown' -Force } catch {}
}

# Build a stable snapshot key (no ??)
$tsKey = $null
if($last.PSObject.Properties['ts_end'] -and $last.ts_end){ $tsKey = [string]$last.ts_end }
elseif($last.PSObject.Properties['ts'] -and $last.ts){     $tsKey = [string]$last.ts }
else { $tsKey = (Get-Date).ToString('s') }

$fileKey = if($last.PSObject.Properties['file'] -and $last.file){ [string]$last.file } else { 'unknown' }
$key = $tsKey + '|' + $fileKey

$seen = Join-Path $Base 'reports\audit\firstfail_seen.txt'
$already=$false
if(Test-Path $seen){
  try{ $already = (Select-String -Path $seen -SimpleMatch $key -ErrorAction SilentlyContinue) -ne $null }catch{}
}
if($already){ exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$dst = Join-Path $Base ("reports\snapshots\fail_" + $stamp)
New-Item -ItemType Directory -Force -Path $dst | Out-Null

# gather tails from a few useful reports
$targets = @('exec_log.jsonl','schedule_drift.jsonl','health_index.jsonl','cadence.jsonl','watchdog_state.jsonl')
foreach($t in $targets){
  $p = Join-Path $Base ('reports\' + $t)
  if(Test-Path $p){
    try{ Get-Content $p -Tail $Tail -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $dst $t) -Encoding UTF8 }catch{}
  }
}

# copy referenced tool if exists
if($last.file){
  $tool = Join-Path $Base $last.file
  if(Test-Path $tool){ try{ Copy-Item -LiteralPath $tool -Destination (Join-Path $dst ([IO.Path]::GetFileName($tool))) -Force }catch{} }
}

# manifest + marker
$man = [pscustomobject]@{ ts=(Get-Date).ToString('s'); kind='first_failure'; line=$last; folder=(Resolve-Path $dst).Path }
($man | ConvertTo-Json -Depth 8) | Out-File -FilePath (Join-Path $dst 'manifest.json') -Encoding UTF8
Add-Content -LiteralPath $seen -Value $key

Write-JsonLineSafe -Path (Join-Path $Base 'reports\first_failure.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='first_failure'; snapshot=$dst; file=$last.file; rc=$last.rc }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Tail=200)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$src = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $src)){ exit 0 }

$lines = Get-Content $src -Tail 500 -ErrorAction SilentlyContinue
$cand = @()
foreach($l in $lines){
  try { $j=$l | ConvertFrom-Json } catch { $j=$null }
  if($j -and $j.rc -and $j.rc -ne 0){ $cand += $j }
}
if($cand.Count -eq 0){ exit 0 }

$last = $cand | Select-Object -Last 1

# Ensure properties exist in PS 5.1 style
$hasTsEnd = $last -and $last.PSObject.Properties['ts_end'] -and $last.ts_end
$hasTs    = $last -and $last.PSObject.Properties['ts']     -and $last.ts
$hasFile  = $last -and $last.PSObject.Properties['file']   -and $last.file

if(-not $hasTsEnd -and $hasTs){
  try { $last | Add-Member -NotePropertyName ts_end -NotePropertyValue $last.ts -Force } catch {}
}
if(-not $hasFile){
  try { $last | Add-Member -NotePropertyName file -NotePropertyValue 'unknown' -Force } catch {}
}

# Build a stable snapshot key (no ??)
$tsKey = $null
if($last.PSObject.Properties['ts_end'] -and $last.ts_end){ $tsKey = [string]$last.ts_end }
elseif($last.PSObject.Properties['ts'] -and $last.ts){     $tsKey = [string]$last.ts }
else { $tsKey = (Get-Date).ToString('s') }

$fileKey = if($last.PSObject.Properties['file'] -and $last.file){ [string]$last.file } else { 'unknown' }
$key = $tsKey + '|' + $fileKey

$seen = Join-Path $Base 'reports\audit\firstfail_seen.txt'
$already=$false
if(Test-Path $seen){
  try{ $already = (Select-String -Path $seen -SimpleMatch $key -ErrorAction SilentlyContinue) -ne $null }catch{}
}
if($already){ exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$dst = Join-Path $Base ("reports\snapshots\fail_" + $stamp)
New-Item -ItemType Directory -Force -Path $dst | Out-Null

# gather tails from a few useful reports
$targets = @('exec_log.jsonl','schedule_drift.jsonl','health_index.jsonl','cadence.jsonl','watchdog_state.jsonl')
foreach($t in $targets){
  $p = Join-Path $Base ('reports\' + $t)
  if(Test-Path $p){
    try{ Get-Content $p -Tail $Tail -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $dst $t) -Encoding UTF8 }catch{}
  }
}

# copy referenced tool if exists
if($last.file){
  $tool = Join-Path $Base $last.file
  if(Test-Path $tool){ try{ Copy-Item -LiteralPath $tool -Destination (Join-Path $dst ([IO.Path]::GetFileName($tool))) -Force }catch{} }
}

# manifest + marker
$man = [pscustomobject]@{ ts=(Get-Date).ToString('s'); kind='first_failure'; line=$last; folder=(Resolve-Path $dst).Path }
($man | ConvertTo-Json -Depth 8) | Out-File -FilePath (Join-Path $dst 'manifest.json') -Encoding UTF8
Add-Content -LiteralPath $seen -Value $key

Write-JsonLineSafe -Path (Join-Path $Base 'reports\first_failure.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='first_failure'; snapshot=$dst; file=$last.file; rc=$last.rc }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Tail=200)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$src = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $src)){ exit 0 }

$lines = Get-Content $src -Tail 500 -ErrorAction SilentlyContinue
$cand = @()
foreach($l in $lines){
  try { $j=$l | ConvertFrom-Json } catch { $j=$null }
  if($j -and $j.rc -and $j.rc -ne 0){ $cand += $j }
}
if($cand.Count -eq 0){ exit 0 }

$last = $cand | Select-Object -Last 1

# Ensure properties exist in PS 5.1 style
$hasTsEnd = $last -and $last.PSObject.Properties['ts_end'] -and $last.ts_end
$hasTs    = $last -and $last.PSObject.Properties['ts']     -and $last.ts
$hasFile  = $last -and $last.PSObject.Properties['file']   -and $last.file

if(-not $hasTsEnd -and $hasTs){
  try { $last | Add-Member -NotePropertyName ts_end -NotePropertyValue $last.ts -Force } catch {}
}
if(-not $hasFile){
  try { $last | Add-Member -NotePropertyName file -NotePropertyValue 'unknown' -Force } catch {}
}

# Build a stable snapshot key (no ??)
$tsKey = $null
if($last.PSObject.Properties['ts_end'] -and $last.ts_end){ $tsKey = [string]$last.ts_end }
elseif($last.PSObject.Properties['ts'] -and $last.ts){     $tsKey = [string]$last.ts }
else { $tsKey = (Get-Date).ToString('s') }

$fileKey = if($last.PSObject.Properties['file'] -and $last.file){ [string]$last.file } else { 'unknown' }
$key = $tsKey + '|' + $fileKey

$seen = Join-Path $Base 'reports\audit\firstfail_seen.txt'
$already=$false
if(Test-Path $seen){
  try{ $already = (Select-String -Path $seen -SimpleMatch $key -ErrorAction SilentlyContinue) -ne $null }catch{}
}
if($already){ exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$dst = Join-Path $Base ("reports\snapshots\fail_" + $stamp)
New-Item -ItemType Directory -Force -Path $dst | Out-Null

# gather tails from a few useful reports
$targets = @('exec_log.jsonl','schedule_drift.jsonl','health_index.jsonl','cadence.jsonl','watchdog_state.jsonl')
foreach($t in $targets){
  $p = Join-Path $Base ('reports\' + $t)
  if(Test-Path $p){
    try{ Get-Content $p -Tail $Tail -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $dst $t) -Encoding UTF8 }catch{}
  }
}

# copy referenced tool if exists
if($last.file){
  $tool = Join-Path $Base $last.file
  if(Test-Path $tool){ try{ Copy-Item -LiteralPath $tool -Destination (Join-Path $dst ([IO.Path]::GetFileName($tool))) -Force }catch{} }
}

# manifest + marker
$man = [pscustomobject]@{ ts=(Get-Date).ToString('s'); kind='first_failure'; line=$last; folder=(Resolve-Path $dst).Path }
($man | ConvertTo-Json -Depth 8) | Out-File -FilePath (Join-Path $dst 'manifest.json') -Encoding UTF8
Add-Content -LiteralPath $seen -Value $key

Write-JsonLineSafe -Path (Join-Path $Base 'reports\first_failure.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='first_failure'; snapshot=$dst; file=$last.file; rc=$last.rc }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Tail=200)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$src = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $src)){ exit 0 }

$lines = Get-Content $src -Tail 500 -ErrorAction SilentlyContinue
$cand = @()
foreach($l in $lines){
  try { $j=$l | ConvertFrom-Json } catch { $j=$null }
  if($j -and $j.rc -and $j.rc -ne 0){ $cand += $j }
}
if($cand.Count -eq 0){ exit 0 }

$last = $cand | Select-Object -Last 1

# Ensure properties exist in PS 5.1 style
$hasTsEnd = $last -and $last.PSObject.Properties['ts_end'] -and $last.ts_end
$hasTs    = $last -and $last.PSObject.Properties['ts']     -and $last.ts
$hasFile  = $last -and $last.PSObject.Properties['file']   -and $last.file

if(-not $hasTsEnd -and $hasTs){
  try { $last | Add-Member -NotePropertyName ts_end -NotePropertyValue $last.ts -Force } catch {}
}
if(-not $hasFile){
  try { $last | Add-Member -NotePropertyName file -NotePropertyValue 'unknown' -Force } catch {}
}

# Build a stable snapshot key (no ??)
$tsKey = $null
if($last.PSObject.Properties['ts_end'] -and $last.ts_end){ $tsKey = [string]$last.ts_end }
elseif($last.PSObject.Properties['ts'] -and $last.ts){     $tsKey = [string]$last.ts }
else { $tsKey = (Get-Date).ToString('s') }

$fileKey = if($last.PSObject.Properties['file'] -and $last.file){ [string]$last.file } else { 'unknown' }
$key = $tsKey + '|' + $fileKey

$seen = Join-Path $Base 'reports\audit\firstfail_seen.txt'
$already=$false
if(Test-Path $seen){
  try{ $already = (Select-String -Path $seen -SimpleMatch $key -ErrorAction SilentlyContinue) -ne $null }catch{}
}
if($already){ exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$dst = Join-Path $Base ("reports\snapshots\fail_" + $stamp)
New-Item -ItemType Directory -Force -Path $dst | Out-Null

# gather tails from a few useful reports
$targets = @('exec_log.jsonl','schedule_drift.jsonl','health_index.jsonl','cadence.jsonl','watchdog_state.jsonl')
foreach($t in $targets){
  $p = Join-Path $Base ('reports\' + $t)
  if(Test-Path $p){
    try{ Get-Content $p -Tail $Tail -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $dst $t) -Encoding UTF8 }catch{}
  }
}

# copy referenced tool if exists
if($last.file){
  $tool = Join-Path $Base $last.file
  if(Test-Path $tool){ try{ Copy-Item -LiteralPath $tool -Destination (Join-Path $dst ([IO.Path]::GetFileName($tool))) -Force }catch{} }
}

# manifest + marker
$man = [pscustomobject]@{ ts=(Get-Date).ToString('s'); kind='first_failure'; line=$last; folder=(Resolve-Path $dst).Path }
($man | ConvertTo-Json -Depth 8) | Out-File -FilePath (Join-Path $dst 'manifest.json') -Encoding UTF8
Add-Content -LiteralPath $seen -Value $key

Write-JsonLineSafe -Path (Join-Path $Base 'reports\first_failure.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='first_failure'; snapshot=$dst; file=$last.file; rc=$last.rc }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Tail=200)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$src = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $src)){ exit 0 }

$lines = Get-Content $src -Tail 500 -ErrorAction SilentlyContinue
$cand = @()
foreach($l in $lines){
  try { $j=$l | ConvertFrom-Json } catch { $j=$null }
  if($j -and $j.rc -and $j.rc -ne 0){ $cand += $j }
}
if($cand.Count -eq 0){ exit 0 }

$last = $cand | Select-Object -Last 1

# Ensure properties exist in PS 5.1 style
$hasTsEnd = $last -and $last.PSObject.Properties['ts_end'] -and $last.ts_end
$hasTs    = $last -and $last.PSObject.Properties['ts']     -and $last.ts
$hasFile  = $last -and $last.PSObject.Properties['file']   -and $last.file

if(-not $hasTsEnd -and $hasTs){
  try { $last | Add-Member -NotePropertyName ts_end -NotePropertyValue $last.ts -Force } catch {}
}
if(-not $hasFile){
  try { $last | Add-Member -NotePropertyName file -NotePropertyValue 'unknown' -Force } catch {}
}

# Build a stable snapshot key (no ??)
$tsKey = $null
if($last.PSObject.Properties['ts_end'] -and $last.ts_end){ $tsKey = [string]$last.ts_end }
elseif($last.PSObject.Properties['ts'] -and $last.ts){     $tsKey = [string]$last.ts }
else { $tsKey = (Get-Date).ToString('s') }

$fileKey = if($last.PSObject.Properties['file'] -and $last.file){ [string]$last.file } else { 'unknown' }
$key = $tsKey + '|' + $fileKey

$seen = Join-Path $Base 'reports\audit\firstfail_seen.txt'
$already=$false
if(Test-Path $seen){
  try{ $already = (Select-String -Path $seen -SimpleMatch $key -ErrorAction SilentlyContinue) -ne $null }catch{}
}
if($already){ exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$dst = Join-Path $Base ("reports\snapshots\fail_" + $stamp)
New-Item -ItemType Directory -Force -Path $dst | Out-Null

# gather tails from a few useful reports
$targets = @('exec_log.jsonl','schedule_drift.jsonl','health_index.jsonl','cadence.jsonl','watchdog_state.jsonl')
foreach($t in $targets){
  $p = Join-Path $Base ('reports\' + $t)
  if(Test-Path $p){
    try{ Get-Content $p -Tail $Tail -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $dst $t) -Encoding UTF8 }catch{}
  }
}

# copy referenced tool if exists
if($last.file){
  $tool = Join-Path $Base $last.file
  if(Test-Path $tool){ try{ Copy-Item -LiteralPath $tool -Destination (Join-Path $dst ([IO.Path]::GetFileName($tool))) -Force }catch{} }
}

# manifest + marker
$man = [pscustomobject]@{ ts=(Get-Date).ToString('s'); kind='first_failure'; line=$last; folder=(Resolve-Path $dst).Path }
($man | ConvertTo-Json -Depth 8) | Out-File -FilePath (Join-Path $dst 'manifest.json') -Encoding UTF8
Add-Content -LiteralPath $seen -Value $key

Write-JsonLineSafe -Path (Join-Path $Base 'reports\first_failure.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='first_failure'; snapshot=$dst; file=$last.file; rc=$last.rc }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

$src = Join-Path $Base 'reports\exec_log.jsonl'
if(-not (Test-Path $src)){ exit 0 }

$lines = Get-Content $src -Tail 500 -ErrorAction SilentlyContinue
$cand = @()
foreach($l in $lines){
  try { $j=$l | ConvertFrom-Json } catch { $j=$null }
  if($j -and $j.rc -and $j.rc -ne 0){ $cand += $j }
}
if($cand.Count -eq 0){ exit 0 }

$last = $cand | Select-Object -Last 1

# Ensure properties exist in PS 5.1 style
$hasTsEnd = $last -and $last.PSObject.Properties['ts_end'] -and $last.ts_end
$hasTs    = $last -and $last.PSObject.Properties['ts']     -and $last.ts
$hasFile  = $last -and $last.PSObject.Properties['file']   -and $last.file

if(-not $hasTsEnd -and $hasTs){
  try { $last | Add-Member -NotePropertyName ts_end -NotePropertyValue $last.ts -Force } catch {}
}
if(-not $hasFile){
  try { $last | Add-Member -NotePropertyName file -NotePropertyValue 'unknown' -Force } catch {}
}

# Build a stable snapshot key (no ??)
$tsKey = $null
if($last.PSObject.Properties['ts_end'] -and $last.ts_end){ $tsKey = [string]$last.ts_end }
elseif($last.PSObject.Properties['ts'] -and $last.ts){     $tsKey = [string]$last.ts }
else { $tsKey = (Get-Date).ToString('s') }

$fileKey = if($last.PSObject.Properties['file'] -and $last.file){ [string]$last.file } else { 'unknown' }
$key = $tsKey + '|' + $fileKey

$seen = Join-Path $Base 'reports\audit\firstfail_seen.txt'
$already=$false
if(Test-Path $seen){
  try{ $already = (Select-String -Path $seen -SimpleMatch $key -ErrorAction SilentlyContinue) -ne $null }catch{}
}
if($already){ exit 0 }

$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$dst = Join-Path $Base ("reports\snapshots\fail_" + $stamp)
New-Item -ItemType Directory -Force -Path $dst | Out-Null

# gather tails from a few useful reports
$targets = @('exec_log.jsonl','schedule_drift.jsonl','health_index.jsonl','cadence.jsonl','watchdog_state.jsonl')
foreach($t in $targets){
  $p = Join-Path $Base ('reports\' + $t)
  if(Test-Path $p){
    try{ Get-Content $p -Tail $Tail -ErrorAction SilentlyContinue | Out-File -FilePath (Join-Path $dst $t) -Encoding UTF8 }catch{}
  }
}

# copy referenced tool if exists
if($last.file){
  $tool = Join-Path $Base $last.file
  if(Test-Path $tool){ try{ Copy-Item -LiteralPath $tool -Destination (Join-Path $dst ([IO.Path]::GetFileName($tool))) -Force }catch{} }
}

# manifest + marker
$man = [pscustomobject]@{ ts=(Get-Date).ToString('s'); kind='first_failure'; line=$last; folder=(Resolve-Path $dst).Path }
($man | ConvertTo-Json -Depth 8) | Out-File -FilePath (Join-Path $dst 'manifest.json') -Encoding UTF8
Add-Content -LiteralPath $seen -Value $key

Write-JsonLineSafe -Path (Join-Path $Base 'reports\first_failure.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='first_failure'; snapshot=$dst; file=$last.file; rc=$last.rc }
