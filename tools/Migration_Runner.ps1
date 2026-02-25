# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds  = Join-Path $Base "seeds\migrations"
$Rep    = Join-Path $Base "reports"
$Locks  = Join-Path $Rep  "locks"
$StateF = Join-Path $Rep  "migrations_applied.json"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $Locks -ItemType Directory -ea SilentlyContinue | Out-Null

$lock = Join-Path $Locks "migrations.lock"
if(Test-Path $lock){ Write-Output "Busy: lock present"; exit 1 }
"lock" | Set-Content $lock -Encoding ASCII

try{
  $applied = @()
  if(Test-Path $StateF){ try{ $applied = (Get-Content $StateF -Raw | ConvertFrom-Json) }catch{} }
  $files = Get-ChildItem $Seeds -File -Filter "*.ps1" -ea SilentlyContinue |
           Where-Object { $_.Name -match '^\d+_.+\.ps1$' } |
           Sort-Object { [int]($_.BaseName.Split('_')[0]) }
  $ran = @()
  foreach($f in $files){
    if($applied -contains $f.Name){ continue }
    $rc = powershell -NoProfile -ExecutionPolicy Bypass -File $f.FullName
    $applied += $f.Name
    $ran += $f.Name
  }
  ($applied | ConvertTo-Json) | Set-Content $StateF -Encoding UTF8
  if(Get-Command Write-JsonLog -ea SilentlyContinue){
    Write-JsonLog -Component "migrate" -Level "INFO" -Message "migrations run" -Props @{ count=$ran.Count; items=($ran -join ',') }
  }
  "OK:$($ran.Count)"
} finally {
  Remove-Item $lock -Force -ea SilentlyContinue
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds  = Join-Path $Base "seeds\migrations"
$Rep    = Join-Path $Base "reports"
$Locks  = Join-Path $Rep  "locks"
$StateF = Join-Path $Rep  "migrations_applied.json"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $Locks -ItemType Directory -ea SilentlyContinue | Out-Null

$lock = Join-Path $Locks "migrations.lock"
if(Test-Path $lock){ Write-Output "Busy: lock present"; exit 1 }
"lock" | Set-Content $lock -Encoding ASCII

try{
  $applied = @()
  if(Test-Path $StateF){ try{ $applied = (Get-Content $StateF -Raw | ConvertFrom-Json) }catch{} }
  $files = Get-ChildItem $Seeds -File -Filter "*.ps1" -ea SilentlyContinue |
           Where-Object { $_.Name -match '^\d+_.+\.ps1$' } |
           Sort-Object { [int]($_.BaseName.Split('_')[0]) }
  $ran = @()
  foreach($f in $files){
    if($applied -contains $f.Name){ continue }
    $rc = powershell -NoProfile -ExecutionPolicy Bypass -File $f.FullName
    $applied += $f.Name
    $ran += $f.Name
  }
  ($applied | ConvertTo-Json) | Set-Content $StateF -Encoding UTF8
  if(Get-Command Write-JsonLog -ea SilentlyContinue){
    Write-JsonLog -Component "migrate" -Level "INFO" -Message "migrations run" -Props @{ count=$ran.Count; items=($ran -join ',') }
  }
  "OK:$($ran.Count)"
} finally {
  Remove-Item $lock -Force -ea SilentlyContinue
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds  = Join-Path $Base "seeds\migrations"
$Rep    = Join-Path $Base "reports"
$Locks  = Join-Path $Rep  "locks"
$StateF = Join-Path $Rep  "migrations_applied.json"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $Locks -ItemType Directory -ea SilentlyContinue | Out-Null

$lock = Join-Path $Locks "migrations.lock"
if(Test-Path $lock){ Write-Output "Busy: lock present"; exit 1 }
"lock" | Set-Content $lock -Encoding ASCII

try{
  $applied = @()
  if(Test-Path $StateF){ try{ $applied = (Get-Content $StateF -Raw | ConvertFrom-Json) }catch{} }
  $files = Get-ChildItem $Seeds -File -Filter "*.ps1" -ea SilentlyContinue |
           Where-Object { $_.Name -match '^\d+_.+\.ps1$' } |
           Sort-Object { [int]($_.BaseName.Split('_')[0]) }
  $ran = @()
  foreach($f in $files){
    if($applied -contains $f.Name){ continue }
    $rc = powershell -NoProfile -ExecutionPolicy Bypass -File $f.FullName
    $applied += $f.Name
    $ran += $f.Name
  }
  ($applied | ConvertTo-Json) | Set-Content $StateF -Encoding UTF8
  if(Get-Command Write-JsonLog -ea SilentlyContinue){
    Write-JsonLog -Component "migrate" -Level "INFO" -Message "migrations run" -Props @{ count=$ran.Count; items=($ran -join ',') }
  }
  "OK:$($ran.Count)"
} finally {
  Remove-Item $lock -Force -ea SilentlyContinue
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds  = Join-Path $Base "seeds\migrations"
$Rep    = Join-Path $Base "reports"
$Locks  = Join-Path $Rep  "locks"
$StateF = Join-Path $Rep  "migrations_applied.json"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $Locks -ItemType Directory -ea SilentlyContinue | Out-Null

$lock = Join-Path $Locks "migrations.lock"
if(Test-Path $lock){ Write-Output "Busy: lock present"; exit 1 }
"lock" | Set-Content $lock -Encoding ASCII

try{
  $applied = @()
  if(Test-Path $StateF){ try{ $applied = (Get-Content $StateF -Raw | ConvertFrom-Json) }catch{} }
  $files = Get-ChildItem $Seeds -File -Filter "*.ps1" -ea SilentlyContinue |
           Where-Object { $_.Name -match '^\d+_.+\.ps1$' } |
           Sort-Object { [int]($_.BaseName.Split('_')[0]) }
  $ran = @()
  foreach($f in $files){
    if($applied -contains $f.Name){ continue }
    $rc = powershell -NoProfile -ExecutionPolicy Bypass -File $f.FullName
    $applied += $f.Name
    $ran += $f.Name
  }
  ($applied | ConvertTo-Json) | Set-Content $StateF -Encoding UTF8
  if(Get-Command Write-JsonLog -ea SilentlyContinue){
    Write-JsonLog -Component "migrate" -Level "INFO" -Message "migrations run" -Props @{ count=$ran.Count; items=($ran -join ',') }
  }
  "OK:$($ran.Count)"
} finally {
  Remove-Item $lock -Force -ea SilentlyContinue
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds  = Join-Path $Base "seeds\migrations"
$Rep    = Join-Path $Base "reports"
$Locks  = Join-Path $Rep  "locks"
$StateF = Join-Path $Rep  "migrations_applied.json"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $Locks -ItemType Directory -ea SilentlyContinue | Out-Null

$lock = Join-Path $Locks "migrations.lock"
if(Test-Path $lock){ Write-Output "Busy: lock present"; exit 1 }
"lock" | Set-Content $lock -Encoding ASCII

try{
  $applied = @()
  if(Test-Path $StateF){ try{ $applied = (Get-Content $StateF -Raw | ConvertFrom-Json) }catch{} }
  $files = Get-ChildItem $Seeds -File -Filter "*.ps1" -ea SilentlyContinue |
           Where-Object { $_.Name -match '^\d+_.+\.ps1$' } |
           Sort-Object { [int]($_.BaseName.Split('_')[0]) }
  $ran = @()
  foreach($f in $files){
    if($applied -contains $f.Name){ continue }
    $rc = powershell -NoProfile -ExecutionPolicy Bypass -File $f.FullName
    $applied += $f.Name
    $ran += $f.Name
  }
  ($applied | ConvertTo-Json) | Set-Content $StateF -Encoding UTF8
  if(Get-Command Write-JsonLog -ea SilentlyContinue){
    Write-JsonLog -Component "migrate" -Level "INFO" -Message "migrations run" -Props @{ count=$ran.Count; items=($ran -join ',') }
  }
  "OK:$($ran.Count)"
} finally {
  Remove-Item $lock -Force -ea SilentlyContinue
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds  = Join-Path $Base "seeds\migrations"
$Rep    = Join-Path $Base "reports"
$Locks  = Join-Path $Rep  "locks"
$StateF = Join-Path $Rep  "migrations_applied.json"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $Locks -ItemType Directory -ea SilentlyContinue | Out-Null

$lock = Join-Path $Locks "migrations.lock"
if(Test-Path $lock){ Write-Output "Busy: lock present"; exit 1 }
"lock" | Set-Content $lock -Encoding ASCII

try{
  $applied = @()
  if(Test-Path $StateF){ try{ $applied = (Get-Content $StateF -Raw | ConvertFrom-Json) }catch{} }
  $files = Get-ChildItem $Seeds -File -Filter "*.ps1" -ea SilentlyContinue |
           Where-Object { $_.Name -match '^\d+_.+\.ps1$' } |
           Sort-Object { [int]($_.BaseName.Split('_')[0]) }
  $ran = @()
  foreach($f in $files){
    if($applied -contains $f.Name){ continue }
    $rc = powershell -NoProfile -ExecutionPolicy Bypass -File $f.FullName
    $applied += $f.Name
    $ran += $f.Name
  }
  ($applied | ConvertTo-Json) | Set-Content $StateF -Encoding UTF8
  if(Get-Command Write-JsonLog -ea SilentlyContinue){
    Write-JsonLog -Component "migrate" -Level "INFO" -Message "migrations run" -Props @{ count=$ran.Count; items=($ran -join ',') }
  }
  "OK:$($ran.Count)"
} finally {
  Remove-Item $lock -Force -ea SilentlyContinue
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds  = Join-Path $Base "seeds\migrations"
$Rep    = Join-Path $Base "reports"
$Locks  = Join-Path $Rep  "locks"
$StateF = Join-Path $Rep  "migrations_applied.json"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $Locks -ItemType Directory -ea SilentlyContinue | Out-Null

$lock = Join-Path $Locks "migrations.lock"
if(Test-Path $lock){ Write-Output "Busy: lock present"; exit 1 }
"lock" | Set-Content $lock -Encoding ASCII

try{
  $applied = @()
  if(Test-Path $StateF){ try{ $applied = (Get-Content $StateF -Raw | ConvertFrom-Json) }catch{} }
  $files = Get-ChildItem $Seeds -File -Filter "*.ps1" -ea SilentlyContinue |
           Where-Object { $_.Name -match '^\d+_.+\.ps1$' } |
           Sort-Object { [int]($_.BaseName.Split('_')[0]) }
  $ran = @()
  foreach($f in $files){
    if($applied -contains $f.Name){ continue }
    $rc = powershell -NoProfile -ExecutionPolicy Bypass -File $f.FullName
    $applied += $f.Name
    $ran += $f.Name
  }
  ($applied | ConvertTo-Json) | Set-Content $StateF -Encoding UTF8
  if(Get-Command Write-JsonLog -ea SilentlyContinue){
    Write-JsonLog -Component "migrate" -Level "INFO" -Message "migrations run" -Props @{ count=$ran.Count; items=($ran -join ',') }
  }
  "OK:$($ran.Count)"
} finally {
  Remove-Item $lock -Force -ea SilentlyContinue
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.4.0
try { Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking } catch {}
$Base   = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Seeds  = Join-Path $Base "seeds\migrations"
$Rep    = Join-Path $Base "reports"
$Locks  = Join-Path $Rep  "locks"
$StateF = Join-Path $Rep  "migrations_applied.json"
New-Item $Seeds -ItemType Directory -ea SilentlyContinue | Out-Null
New-Item $Locks -ItemType Directory -ea SilentlyContinue | Out-Null

$lock = Join-Path $Locks "migrations.lock"
if(Test-Path $lock){ Write-Output "Busy: lock present"; exit 1 }
"lock" | Set-Content $lock -Encoding ASCII

try{
  $applied = @()
  if(Test-Path $StateF){ try{ $applied = (Get-Content $StateF -Raw | ConvertFrom-Json) }catch{} }
  $files = Get-ChildItem $Seeds -File -Filter "*.ps1" -ea SilentlyContinue |
           Where-Object { $_.Name -match '^\d+_.+\.ps1$' } |
           Sort-Object { [int]($_.BaseName.Split('_')[0]) }
  $ran = @()
  foreach($f in $files){
    if($applied -contains $f.Name){ continue }
    $rc = powershell -NoProfile -ExecutionPolicy Bypass -File $f.FullName
    $applied += $f.Name
    $ran += $f.Name
  }
  ($applied | ConvertTo-Json) | Set-Content $StateF -Encoding UTF8
  if(Get-Command Write-JsonLog -ea SilentlyContinue){
    Write-JsonLog -Component "migrate" -Level "INFO" -Message "migrations run" -Props @{ count=$ran.Count; items=($ran -join ',') }
  }
  "OK:$($ran.Count)"
} finally {
  Remove-Item $lock -Force -ea SilentlyContinue
}

