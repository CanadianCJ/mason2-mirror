$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  # ports
  if(-not $j.PSObject.Properties['ports']){ $j | Add-Member -NotePropertyName ports -NotePropertyValue (@()) -Force }
  $ports = @($j.ports); if(7001 -notin $ports){ $ports += 7001 }; $j.ports=$ports
  # http
  if(-not $j.PSObject.Properties['http']){ $j | Add-Member -NotePropertyName http -NotePropertyValue (@()) -Force }
  $http = @($j.http | ForEach-Object { $_ })
  $want = @{ url='http://127.0.0.1:7001/healthz'; timeout_s=2 }
  $has = $false
  foreach($e in $http){ if($e -and $e.url -eq $want.url){ $has=$true } }
  if(-not $has){ $http += ($want | ConvertTo-Json | ConvertFrom-Json) }
  $j.http = $http
  # expected task
  if(-not $j.PSObject.Properties['tasks_expected']){ $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue (@()) -Force }
  $tx=@($j.tasks_expected); if('Mason2-FileServer-7001' -notin $tx){ $tx += 'Mason2-FileServer-7001' }; $j.tasks_expected=$tx
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  # ports
  if(-not $j.PSObject.Properties['ports']){ $j | Add-Member -NotePropertyName ports -NotePropertyValue (@()) -Force }
  $ports = @($j.ports); if(7001 -notin $ports){ $ports += 7001 }; $j.ports=$ports
  # http
  if(-not $j.PSObject.Properties['http']){ $j | Add-Member -NotePropertyName http -NotePropertyValue (@()) -Force }
  $http = @($j.http | ForEach-Object { $_ })
  $want = @{ url='http://127.0.0.1:7001/healthz'; timeout_s=2 }
  $has = $false
  foreach($e in $http){ if($e -and $e.url -eq $want.url){ $has=$true } }
  if(-not $has){ $http += ($want | ConvertTo-Json | ConvertFrom-Json) }
  $j.http = $http
  # expected task
  if(-not $j.PSObject.Properties['tasks_expected']){ $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue (@()) -Force }
  $tx=@($j.tasks_expected); if('Mason2-FileServer-7001' -notin $tx){ $tx += 'Mason2-FileServer-7001' }; $j.tasks_expected=$tx
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  # ports
  if(-not $j.PSObject.Properties['ports']){ $j | Add-Member -NotePropertyName ports -NotePropertyValue (@()) -Force }
  $ports = @($j.ports); if(7001 -notin $ports){ $ports += 7001 }; $j.ports=$ports
  # http
  if(-not $j.PSObject.Properties['http']){ $j | Add-Member -NotePropertyName http -NotePropertyValue (@()) -Force }
  $http = @($j.http | ForEach-Object { $_ })
  $want = @{ url='http://127.0.0.1:7001/healthz'; timeout_s=2 }
  $has = $false
  foreach($e in $http){ if($e -and $e.url -eq $want.url){ $has=$true } }
  if(-not $has){ $http += ($want | ConvertTo-Json | ConvertFrom-Json) }
  $j.http = $http
  # expected task
  if(-not $j.PSObject.Properties['tasks_expected']){ $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue (@()) -Force }
  $tx=@($j.tasks_expected); if('Mason2-FileServer-7001' -notin $tx){ $tx += 'Mason2-FileServer-7001' }; $j.tasks_expected=$tx
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  # ports
  if(-not $j.PSObject.Properties['ports']){ $j | Add-Member -NotePropertyName ports -NotePropertyValue (@()) -Force }
  $ports = @($j.ports); if(7001 -notin $ports){ $ports += 7001 }; $j.ports=$ports
  # http
  if(-not $j.PSObject.Properties['http']){ $j | Add-Member -NotePropertyName http -NotePropertyValue (@()) -Force }
  $http = @($j.http | ForEach-Object { $_ })
  $want = @{ url='http://127.0.0.1:7001/healthz'; timeout_s=2 }
  $has = $false
  foreach($e in $http){ if($e -and $e.url -eq $want.url){ $has=$true } }
  if(-not $has){ $http += ($want | ConvertTo-Json | ConvertFrom-Json) }
  $j.http = $http
  # expected task
  if(-not $j.PSObject.Properties['tasks_expected']){ $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue (@()) -Force }
  $tx=@($j.tasks_expected); if('Mason2-FileServer-7001' -notin $tx){ $tx += 'Mason2-FileServer-7001' }; $j.tasks_expected=$tx
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  # ports
  if(-not $j.PSObject.Properties['ports']){ $j | Add-Member -NotePropertyName ports -NotePropertyValue (@()) -Force }
  $ports = @($j.ports); if(7001 -notin $ports){ $ports += 7001 }; $j.ports=$ports
  # http
  if(-not $j.PSObject.Properties['http']){ $j | Add-Member -NotePropertyName http -NotePropertyValue (@()) -Force }
  $http = @($j.http | ForEach-Object { $_ })
  $want = @{ url='http://127.0.0.1:7001/healthz'; timeout_s=2 }
  $has = $false
  foreach($e in $http){ if($e -and $e.url -eq $want.url){ $has=$true } }
  if(-not $has){ $http += ($want | ConvertTo-Json | ConvertFrom-Json) }
  $j.http = $http
  # expected task
  if(-not $j.PSObject.Properties['tasks_expected']){ $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue (@()) -Force }
  $tx=@($j.tasks_expected); if('Mason2-FileServer-7001' -notin $tx){ $tx += 'Mason2-FileServer-7001' }; $j.tasks_expected=$tx
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  # ports
  if(-not $j.PSObject.Properties['ports']){ $j | Add-Member -NotePropertyName ports -NotePropertyValue (@()) -Force }
  $ports = @($j.ports); if(7001 -notin $ports){ $ports += 7001 }; $j.ports=$ports
  # http
  if(-not $j.PSObject.Properties['http']){ $j | Add-Member -NotePropertyName http -NotePropertyValue (@()) -Force }
  $http = @($j.http | ForEach-Object { $_ })
  $want = @{ url='http://127.0.0.1:7001/healthz'; timeout_s=2 }
  $has = $false
  foreach($e in $http){ if($e -and $e.url -eq $want.url){ $has=$true } }
  if(-not $has){ $http += ($want | ConvertTo-Json | ConvertFrom-Json) }
  $j.http = $http
  # expected task
  if(-not $j.PSObject.Properties['tasks_expected']){ $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue (@()) -Force }
  $tx=@($j.tasks_expected); if('Mason2-FileServer-7001' -notin $tx){ $tx += 'Mason2-FileServer-7001' }; $j.tasks_expected=$tx
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  # ports
  if(-not $j.PSObject.Properties['ports']){ $j | Add-Member -NotePropertyName ports -NotePropertyValue (@()) -Force }
  $ports = @($j.ports); if(7001 -notin $ports){ $ports += 7001 }; $j.ports=$ports
  # http
  if(-not $j.PSObject.Properties['http']){ $j | Add-Member -NotePropertyName http -NotePropertyValue (@()) -Force }
  $http = @($j.http | ForEach-Object { $_ })
  $want = @{ url='http://127.0.0.1:7001/healthz'; timeout_s=2 }
  $has = $false
  foreach($e in $http){ if($e -and $e.url -eq $want.url){ $has=$true } }
  if(-not $has){ $http += ($want | ConvertTo-Json | ConvertFrom-Json) }
  $j.http = $http
  # expected task
  if(-not $j.PSObject.Properties['tasks_expected']){ $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue (@()) -Force }
  $tx=@($j.tasks_expected); if('Mason2-FileServer-7001' -notin $tx){ $tx += 'Mason2-FileServer-7001' }; $j.tasks_expected=$tx
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
$cfg = Join-Path $Base 'config\watchdog.json'
if(-not (Test-Path $cfg)){ exit 0 }
try{
  $j = Get-Content $cfg -Raw | ConvertFrom-Json
  # ports
  if(-not $j.PSObject.Properties['ports']){ $j | Add-Member -NotePropertyName ports -NotePropertyValue (@()) -Force }
  $ports = @($j.ports); if(7001 -notin $ports){ $ports += 7001 }; $j.ports=$ports
  # http
  if(-not $j.PSObject.Properties['http']){ $j | Add-Member -NotePropertyName http -NotePropertyValue (@()) -Force }
  $http = @($j.http | ForEach-Object { $_ })
  $want = @{ url='http://127.0.0.1:7001/healthz'; timeout_s=2 }
  $has = $false
  foreach($e in $http){ if($e -and $e.url -eq $want.url){ $has=$true } }
  if(-not $has){ $http += ($want | ConvertTo-Json | ConvertFrom-Json) }
  $j.http = $http
  # expected task
  if(-not $j.PSObject.Properties['tasks_expected']){ $j | Add-Member -NotePropertyName tasks_expected -NotePropertyValue (@()) -Force }
  $tx=@($j.tasks_expected); if('Mason2-FileServer-7001' -notin $tx){ $tx += 'Mason2-FileServer-7001' }; $j.tasks_expected=$tx
  ($j | ConvertTo-Json -Depth 10) | Out-File -FilePath $cfg -Encoding UTF8
}catch{}
