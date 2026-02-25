$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxH = 48
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.security -and $p.security.defender_sig_max_age_hours){ $maxH=[int]$p.security.defender_sig_max_age_hours } } }catch{}
$now=Get-Date
$ok=$false; $ageH=$null; $took=$null; $action='none'; $reason=$null
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    $s=Get-MpComputerStatus
    $ageH = [int]([double]$s.SignatureAge*24) # SignatureAge is in days
    $ok = ($ageH -lt $maxH)
    if(-not $ok -and $TryUpdate){
      $t0=Get-Date
      try{ Update-MpSignature -ErrorAction SilentlyContinue | Out-Null; $action='update_attempted' }catch{ $action='update_failed' }
      $took=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalSeconds)
    }
  }catch{ $reason='query_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_sig_gate.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='defender_sig'; ok=$ok; sig_age_hours=$ageH; max_hours=$maxH; action=$action; reason=$reason; took_s=$took
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[switch]$TryUpdate)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxH = 48
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.security -and $p.security.defender_sig_max_age_hours){ $maxH=[int]$p.security.defender_sig_max_age_hours } } }catch{}
$now=Get-Date
$ok=$false; $ageH=$null; $took=$null; $action='none'; $reason=$null
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    $s=Get-MpComputerStatus
    $ageH = [int]([double]$s.SignatureAge*24) # SignatureAge is in days
    $ok = ($ageH -lt $maxH)
    if(-not $ok -and $TryUpdate){
      $t0=Get-Date
      try{ Update-MpSignature -ErrorAction SilentlyContinue | Out-Null; $action='update_attempted' }catch{ $action='update_failed' }
      $took=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalSeconds)
    }
  }catch{ $reason='query_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_sig_gate.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='defender_sig'; ok=$ok; sig_age_hours=$ageH; max_hours=$maxH; action=$action; reason=$reason; took_s=$took
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[switch]$TryUpdate)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxH = 48
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.security -and $p.security.defender_sig_max_age_hours){ $maxH=[int]$p.security.defender_sig_max_age_hours } } }catch{}
$now=Get-Date
$ok=$false; $ageH=$null; $took=$null; $action='none'; $reason=$null
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    $s=Get-MpComputerStatus
    $ageH = [int]([double]$s.SignatureAge*24) # SignatureAge is in days
    $ok = ($ageH -lt $maxH)
    if(-not $ok -and $TryUpdate){
      $t0=Get-Date
      try{ Update-MpSignature -ErrorAction SilentlyContinue | Out-Null; $action='update_attempted' }catch{ $action='update_failed' }
      $took=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalSeconds)
    }
  }catch{ $reason='query_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_sig_gate.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='defender_sig'; ok=$ok; sig_age_hours=$ageH; max_hours=$maxH; action=$action; reason=$reason; took_s=$took
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[switch]$TryUpdate)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxH = 48
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.security -and $p.security.defender_sig_max_age_hours){ $maxH=[int]$p.security.defender_sig_max_age_hours } } }catch{}
$now=Get-Date
$ok=$false; $ageH=$null; $took=$null; $action='none'; $reason=$null
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    $s=Get-MpComputerStatus
    $ageH = [int]([double]$s.SignatureAge*24) # SignatureAge is in days
    $ok = ($ageH -lt $maxH)
    if(-not $ok -and $TryUpdate){
      $t0=Get-Date
      try{ Update-MpSignature -ErrorAction SilentlyContinue | Out-Null; $action='update_attempted' }catch{ $action='update_failed' }
      $took=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalSeconds)
    }
  }catch{ $reason='query_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_sig_gate.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='defender_sig'; ok=$ok; sig_age_hours=$ageH; max_hours=$maxH; action=$action; reason=$reason; took_s=$took
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[switch]$TryUpdate)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxH = 48
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.security -and $p.security.defender_sig_max_age_hours){ $maxH=[int]$p.security.defender_sig_max_age_hours } } }catch{}
$now=Get-Date
$ok=$false; $ageH=$null; $took=$null; $action='none'; $reason=$null
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    $s=Get-MpComputerStatus
    $ageH = [int]([double]$s.SignatureAge*24) # SignatureAge is in days
    $ok = ($ageH -lt $maxH)
    if(-not $ok -and $TryUpdate){
      $t0=Get-Date
      try{ Update-MpSignature -ErrorAction SilentlyContinue | Out-Null; $action='update_attempted' }catch{ $action='update_failed' }
      $took=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalSeconds)
    }
  }catch{ $reason='query_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_sig_gate.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='defender_sig'; ok=$ok; sig_age_hours=$ageH; max_hours=$maxH; action=$action; reason=$reason; took_s=$took
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[switch]$TryUpdate)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxH = 48
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.security -and $p.security.defender_sig_max_age_hours){ $maxH=[int]$p.security.defender_sig_max_age_hours } } }catch{}
$now=Get-Date
$ok=$false; $ageH=$null; $took=$null; $action='none'; $reason=$null
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    $s=Get-MpComputerStatus
    $ageH = [int]([double]$s.SignatureAge*24) # SignatureAge is in days
    $ok = ($ageH -lt $maxH)
    if(-not $ok -and $TryUpdate){
      $t0=Get-Date
      try{ Update-MpSignature -ErrorAction SilentlyContinue | Out-Null; $action='update_attempted' }catch{ $action='update_failed' }
      $took=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalSeconds)
    }
  }catch{ $reason='query_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_sig_gate.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='defender_sig'; ok=$ok; sig_age_hours=$ageH; max_hours=$maxH; action=$action; reason=$reason; took_s=$took
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[switch]$TryUpdate)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxH = 48
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.security -and $p.security.defender_sig_max_age_hours){ $maxH=[int]$p.security.defender_sig_max_age_hours } } }catch{}
$now=Get-Date
$ok=$false; $ageH=$null; $took=$null; $action='none'; $reason=$null
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    $s=Get-MpComputerStatus
    $ageH = [int]([double]$s.SignatureAge*24) # SignatureAge is in days
    $ok = ($ageH -lt $maxH)
    if(-not $ok -and $TryUpdate){
      $t0=Get-Date
      try{ Update-MpSignature -ErrorAction SilentlyContinue | Out-Null; $action='update_attempted' }catch{ $action='update_failed' }
      $took=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalSeconds)
    }
  }catch{ $reason='query_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_sig_gate.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='defender_sig'; ok=$ok; sig_age_hours=$ageH; max_hours=$maxH; action=$action; reason=$reason; took_s=$took
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$maxH = 48
try{ if(Test-Path $pol){ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.security -and $p.security.defender_sig_max_age_hours){ $maxH=[int]$p.security.defender_sig_max_age_hours } } }catch{}
$now=Get-Date
$ok=$false; $ageH=$null; $took=$null; $action='none'; $reason=$null
$cmd = Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
if(-not $cmd){ $reason='cmdlet_missing' }
else{
  try{
    $s=Get-MpComputerStatus
    $ageH = [int]([double]$s.SignatureAge*24) # SignatureAge is in days
    $ok = ($ageH -lt $maxH)
    if(-not $ok -and $TryUpdate){
      $t0=Get-Date
      try{ Update-MpSignature -ErrorAction SilentlyContinue | Out-Null; $action='update_attempted' }catch{ $action='update_failed' }
      $took=[int]((New-TimeSpan -Start $t0 -End (Get-Date)).TotalSeconds)
    }
  }catch{ $reason='query_failed' }
}
Write-JsonLineSafe -Path (Join-Path $Base 'reports\defender_sig_gate.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='defender_sig'; ok=$ok; sig_age_hours=$ageH; max_hours=$maxH; action=$action; reason=$reason; took_s=$took
}
