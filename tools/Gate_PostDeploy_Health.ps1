$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$min=70; if(Test-Path $pol){ try{ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.post_deploy.min_health){ $min=[int]$p.post_deploy.min_health } }catch{} }
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$ok = ($hi -and $hi.score -ge $min)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\post_deploy_gate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='post_gate'; min=$min; score=($hi.score); ok=$ok }
if(-not $ok){ exit 12 } else { exit 0 }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$min=70; if(Test-Path $pol){ try{ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.post_deploy.min_health){ $min=[int]$p.post_deploy.min_health } }catch{} }
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$ok = ($hi -and $hi.score -ge $min)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\post_deploy_gate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='post_gate'; min=$min; score=($hi.score); ok=$ok }
if(-not $ok){ exit 12 } else { exit 0 }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$min=70; if(Test-Path $pol){ try{ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.post_deploy.min_health){ $min=[int]$p.post_deploy.min_health } }catch{} }
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$ok = ($hi -and $hi.score -ge $min)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\post_deploy_gate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='post_gate'; min=$min; score=($hi.score); ok=$ok }
if(-not $ok){ exit 12 } else { exit 0 }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$min=70; if(Test-Path $pol){ try{ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.post_deploy.min_health){ $min=[int]$p.post_deploy.min_health } }catch{} }
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$ok = ($hi -and $hi.score -ge $min)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\post_deploy_gate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='post_gate'; min=$min; score=($hi.score); ok=$ok }
if(-not $ok){ exit 12 } else { exit 0 }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$min=70; if(Test-Path $pol){ try{ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.post_deploy.min_health){ $min=[int]$p.post_deploy.min_health } }catch{} }
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$ok = ($hi -and $hi.score -ge $min)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\post_deploy_gate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='post_gate'; min=$min; score=($hi.score); ok=$ok }
if(-not $ok){ exit 12 } else { exit 0 }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$min=70; if(Test-Path $pol){ try{ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.post_deploy.min_health){ $min=[int]$p.post_deploy.min_health } }catch{} }
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$ok = ($hi -and $hi.score -ge $min)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\post_deploy_gate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='post_gate'; min=$min; score=($hi.score); ok=$ok }
if(-not $ok){ exit 12 } else { exit 0 }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$min=70; if(Test-Path $pol){ try{ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.post_deploy.min_health){ $min=[int]$p.post_deploy.min_health } }catch{} }
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$ok = ($hi -and $hi.score -ge $min)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\post_deploy_gate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='post_gate'; min=$min; score=($hi.score); ok=$ok }
if(-not $ok){ exit 12 } else { exit 0 }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$pol = Join-Path $Base 'config\policy.json'
$min=70; if(Test-Path $pol){ try{ $p=Get-Content $pol -Raw|ConvertFrom-Json; if($p.post_deploy.min_health){ $min=[int]$p.post_deploy.min_health } }catch{} }
$hi = $null; if(Test-Path (Join-Path $Base 'reports\health_index.jsonl')){ try{ $hi=(Get-Content (Join-Path $Base 'reports\health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$ok = ($hi -and $hi.score -ge $min)
Write-JsonLineSafe -Path (Join-Path $Base 'reports\post_deploy_gate.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='post_gate'; min=$min; score=($hi.score); ok=$ok }
if(-not $ok){ exit 12 } else { exit 0 }
