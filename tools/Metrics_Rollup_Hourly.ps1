$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
function _readJsonl($p){ if(Test-Path $p){ Get-Content $p -ErrorAction SilentlyContinue | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } } }
$tsCut = $now.AddMinutes(-[int]$WindowMin)
$net = @(); $td = @()
$net = (_readJsonl (Join-Path $Base 'reports\net_external.jsonl') | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })
$td  = (_readJsonl (Join-Path $Base 'reports\timedrift.jsonl')   | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })

# averages
function _avg($nums){ $a=@($nums|Where-Object { $_ -ne $null }); if($a.Count -eq 0){ return $null } [math]::Round( ($a | Measure-Object -Average).Average, 2) }
$lat = _avg ($net | ForEach-Object { $_.ms })
$up  = _avg ($net | ForEach-Object { if( $_.dns -and $_.https ){1}else{0} })
$off = _avg ($td  | ForEach-Object { $_.offset_s })

Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_rollup_hourly.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='metrics_rollup'; window_min=$WindowMin; net_up_avg=$up; net_latency_ms_avg=$lat; timesync_offset_s_avg=$off
}
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
function _readJsonl($p){ if(Test-Path $p){ Get-Content $p -ErrorAction SilentlyContinue | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } } }
$tsCut = $now.AddMinutes(-[int]$WindowMin)
$net = @(); $td = @()
$net = (_readJsonl (Join-Path $Base 'reports\net_external.jsonl') | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })
$td  = (_readJsonl (Join-Path $Base 'reports\timedrift.jsonl')   | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })

# averages
function _avg($nums){ $a=@($nums|Where-Object { $_ -ne $null }); if($a.Count -eq 0){ return $null } [math]::Round( ($a | Measure-Object -Average).Average, 2) }
$lat = _avg ($net | ForEach-Object { $_.ms })
$up  = _avg ($net | ForEach-Object { if( $_.dns -and $_.https ){1}else{0} })
$off = _avg ($td  | ForEach-Object { $_.offset_s })

Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_rollup_hourly.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='metrics_rollup'; window_min=$WindowMin; net_up_avg=$up; net_latency_ms_avg=$lat; timesync_offset_s_avg=$off
}
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
function _readJsonl($p){ if(Test-Path $p){ Get-Content $p -ErrorAction SilentlyContinue | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } } }
$tsCut = $now.AddMinutes(-[int]$WindowMin)
$net = @(); $td = @()
$net = (_readJsonl (Join-Path $Base 'reports\net_external.jsonl') | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })
$td  = (_readJsonl (Join-Path $Base 'reports\timedrift.jsonl')   | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })

# averages
function _avg($nums){ $a=@($nums|Where-Object { $_ -ne $null }); if($a.Count -eq 0){ return $null } [math]::Round( ($a | Measure-Object -Average).Average, 2) }
$lat = _avg ($net | ForEach-Object { $_.ms })
$up  = _avg ($net | ForEach-Object { if( $_.dns -and $_.https ){1}else{0} })
$off = _avg ($td  | ForEach-Object { $_.offset_s })

Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_rollup_hourly.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='metrics_rollup'; window_min=$WindowMin; net_up_avg=$up; net_latency_ms_avg=$lat; timesync_offset_s_avg=$off
}
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
function _readJsonl($p){ if(Test-Path $p){ Get-Content $p -ErrorAction SilentlyContinue | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } } }
$tsCut = $now.AddMinutes(-[int]$WindowMin)
$net = @(); $td = @()
$net = (_readJsonl (Join-Path $Base 'reports\net_external.jsonl') | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })
$td  = (_readJsonl (Join-Path $Base 'reports\timedrift.jsonl')   | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })

# averages
function _avg($nums){ $a=@($nums|Where-Object { $_ -ne $null }); if($a.Count -eq 0){ return $null } [math]::Round( ($a | Measure-Object -Average).Average, 2) }
$lat = _avg ($net | ForEach-Object { $_.ms })
$up  = _avg ($net | ForEach-Object { if( $_.dns -and $_.https ){1}else{0} })
$off = _avg ($td  | ForEach-Object { $_.offset_s })

Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_rollup_hourly.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='metrics_rollup'; window_min=$WindowMin; net_up_avg=$up; net_latency_ms_avg=$lat; timesync_offset_s_avg=$off
}
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
function _readJsonl($p){ if(Test-Path $p){ Get-Content $p -ErrorAction SilentlyContinue | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } } }
$tsCut = $now.AddMinutes(-[int]$WindowMin)
$net = @(); $td = @()
$net = (_readJsonl (Join-Path $Base 'reports\net_external.jsonl') | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })
$td  = (_readJsonl (Join-Path $Base 'reports\timedrift.jsonl')   | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })

# averages
function _avg($nums){ $a=@($nums|Where-Object { $_ -ne $null }); if($a.Count -eq 0){ return $null } [math]::Round( ($a | Measure-Object -Average).Average, 2) }
$lat = _avg ($net | ForEach-Object { $_.ms })
$up  = _avg ($net | ForEach-Object { if( $_.dns -and $_.https ){1}else{0} })
$off = _avg ($td  | ForEach-Object { $_.offset_s })

Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_rollup_hourly.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='metrics_rollup'; window_min=$WindowMin; net_up_avg=$up; net_latency_ms_avg=$lat; timesync_offset_s_avg=$off
}
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
function _readJsonl($p){ if(Test-Path $p){ Get-Content $p -ErrorAction SilentlyContinue | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } } }
$tsCut = $now.AddMinutes(-[int]$WindowMin)
$net = @(); $td = @()
$net = (_readJsonl (Join-Path $Base 'reports\net_external.jsonl') | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })
$td  = (_readJsonl (Join-Path $Base 'reports\timedrift.jsonl')   | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })

# averages
function _avg($nums){ $a=@($nums|Where-Object { $_ -ne $null }); if($a.Count -eq 0){ return $null } [math]::Round( ($a | Measure-Object -Average).Average, 2) }
$lat = _avg ($net | ForEach-Object { $_.ms })
$up  = _avg ($net | ForEach-Object { if( $_.dns -and $_.https ){1}else{0} })
$off = _avg ($td  | ForEach-Object { $_.offset_s })

Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_rollup_hourly.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='metrics_rollup'; window_min=$WindowMin; net_up_avg=$up; net_latency_ms_avg=$lat; timesync_offset_s_avg=$off
}
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$WindowMin=60)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
function _readJsonl($p){ if(Test-Path $p){ Get-Content $p -ErrorAction SilentlyContinue | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } } }
$tsCut = $now.AddMinutes(-[int]$WindowMin)
$net = @(); $td = @()
$net = (_readJsonl (Join-Path $Base 'reports\net_external.jsonl') | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })
$td  = (_readJsonl (Join-Path $Base 'reports\timedrift.jsonl')   | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })

# averages
function _avg($nums){ $a=@($nums|Where-Object { $_ -ne $null }); if($a.Count -eq 0){ return $null } [math]::Round( ($a | Measure-Object -Average).Average, 2) }
$lat = _avg ($net | ForEach-Object { $_.ms })
$up  = _avg ($net | ForEach-Object { if( $_.dns -and $_.https ){1}else{0} })
$off = _avg ($td  | ForEach-Object { $_.offset_s })

Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_rollup_hourly.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='metrics_rollup'; window_min=$WindowMin; net_up_avg=$up; net_latency_ms_avg=$lat; timesync_offset_s_avg=$off
}
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$now = Get-Date
function _readJsonl($p){ if(Test-Path $p){ Get-Content $p -ErrorAction SilentlyContinue | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } } }
$tsCut = $now.AddMinutes(-[int]$WindowMin)
$net = @(); $td = @()
$net = (_readJsonl (Join-Path $Base 'reports\net_external.jsonl') | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })
$td  = (_readJsonl (Join-Path $Base 'reports\timedrift.jsonl')   | Where-Object { $_ -and $_.ts -and ([datetime]$_.ts) -ge $tsCut })

# averages
function _avg($nums){ $a=@($nums|Where-Object { $_ -ne $null }); if($a.Count -eq 0){ return $null } [math]::Round( ($a | Measure-Object -Average).Average, 2) }
$lat = _avg ($net | ForEach-Object { $_.ms })
$up  = _avg ($net | ForEach-Object { if( $_.dns -and $_.https ){1}else{0} })
$off = _avg ($td  | ForEach-Object { $_.offset_s })

Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_rollup_hourly.jsonl') -Obj @{
  ts=$now.ToString('s'); kind='metrics_rollup'; window_min=$WindowMin; net_up_avg=$up; net_latency_ms_avg=$lat; timesync_offset_s_avg=$off
}
