$ErrorActionPreference='Stop'
$now=Get-Date
$logs = @(
  @{ p='reports\config_diff.jsonl'; k=@('added','removed','changed') },
  @{ p='reports\integrity.jsonl';   k=@('added','removed','changed') },
  @{ p='reports\tasks_diff.jsonl';  k=@('added','removed') }
)
$bucket=@{}
function _date($ts){ try{ return ([datetime]$ts).ToString('yyyy-MM-dd') }catch{ return $null } }
foreach($t in $logs){
  $fp=Join-Path $Base $t.p
  if(Test-Path $fp){
    Get-Content $fp -ErrorAction SilentlyContinue | ForEach-Object {
      try{
        $j = $_ | ConvertFrom-Json
        if($j -and $j.ts){
          $d=_date $j.ts
          if($d){
            if(-not $bucket[$d]){ $bucket[$d]=@{count=0} }
            foreach($kk in $t.k){
              if($j.$kk){ 
                $c = if($j.$kk -is [array]){ $j.$kk.Count } else { 1 }
                $bucket[$d].count += [int]$c
              }
            }
          }
        }
      }catch{}
    }
  }
}
# restrict to last N days
$keys = $bucket.Keys | Where-Object { try{ (([datetime]$_) -ge $now.AddDays(-$Days)) }catch{ $false } } | Sort-Object
# write CSV + MD
$csv = "date,delta_count`r`n" + ($keys | ForEach-Object { "$_," + $bucket[$_].count })
$csv | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.csv') -Encoding UTF8
$md = @("# Drift Heatmap (last $Days days)", "", "| date | delta_count |","|---:|---:|")
foreach($k in $keys){ $md += "| $k | " + $bucket[$k].count + " |" }
$md -join "`r`n" | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.md') -Encoding UTF8
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
$now=Get-Date
$logs = @(
  @{ p='reports\config_diff.jsonl'; k=@('added','removed','changed') },
  @{ p='reports\integrity.jsonl';   k=@('added','removed','changed') },
  @{ p='reports\tasks_diff.jsonl';  k=@('added','removed') }
)
$bucket=@{}
function _date($ts){ try{ return ([datetime]$ts).ToString('yyyy-MM-dd') }catch{ return $null } }
foreach($t in $logs){
  $fp=Join-Path $Base $t.p
  if(Test-Path $fp){
    Get-Content $fp -ErrorAction SilentlyContinue | ForEach-Object {
      try{
        $j = $_ | ConvertFrom-Json
        if($j -and $j.ts){
          $d=_date $j.ts
          if($d){
            if(-not $bucket[$d]){ $bucket[$d]=@{count=0} }
            foreach($kk in $t.k){
              if($j.$kk){ 
                $c = if($j.$kk -is [array]){ $j.$kk.Count } else { 1 }
                $bucket[$d].count += [int]$c
              }
            }
          }
        }
      }catch{}
    }
  }
}
# restrict to last N days
$keys = $bucket.Keys | Where-Object { try{ (([datetime]$_) -ge $now.AddDays(-$Days)) }catch{ $false } } | Sort-Object
# write CSV + MD
$csv = "date,delta_count`r`n" + ($keys | ForEach-Object { "$_," + $bucket[$_].count })
$csv | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.csv') -Encoding UTF8
$md = @("# Drift Heatmap (last $Days days)", "", "| date | delta_count |","|---:|---:|")
foreach($k in $keys){ $md += "| $k | " + $bucket[$k].count + " |" }
$md -join "`r`n" | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.md') -Encoding UTF8
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
$now=Get-Date
$logs = @(
  @{ p='reports\config_diff.jsonl'; k=@('added','removed','changed') },
  @{ p='reports\integrity.jsonl';   k=@('added','removed','changed') },
  @{ p='reports\tasks_diff.jsonl';  k=@('added','removed') }
)
$bucket=@{}
function _date($ts){ try{ return ([datetime]$ts).ToString('yyyy-MM-dd') }catch{ return $null } }
foreach($t in $logs){
  $fp=Join-Path $Base $t.p
  if(Test-Path $fp){
    Get-Content $fp -ErrorAction SilentlyContinue | ForEach-Object {
      try{
        $j = $_ | ConvertFrom-Json
        if($j -and $j.ts){
          $d=_date $j.ts
          if($d){
            if(-not $bucket[$d]){ $bucket[$d]=@{count=0} }
            foreach($kk in $t.k){
              if($j.$kk){ 
                $c = if($j.$kk -is [array]){ $j.$kk.Count } else { 1 }
                $bucket[$d].count += [int]$c
              }
            }
          }
        }
      }catch{}
    }
  }
}
# restrict to last N days
$keys = $bucket.Keys | Where-Object { try{ (([datetime]$_) -ge $now.AddDays(-$Days)) }catch{ $false } } | Sort-Object
# write CSV + MD
$csv = "date,delta_count`r`n" + ($keys | ForEach-Object { "$_," + $bucket[$_].count })
$csv | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.csv') -Encoding UTF8
$md = @("# Drift Heatmap (last $Days days)", "", "| date | delta_count |","|---:|---:|")
foreach($k in $keys){ $md += "| $k | " + $bucket[$k].count + " |" }
$md -join "`r`n" | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.md') -Encoding UTF8
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
$now=Get-Date
$logs = @(
  @{ p='reports\config_diff.jsonl'; k=@('added','removed','changed') },
  @{ p='reports\integrity.jsonl';   k=@('added','removed','changed') },
  @{ p='reports\tasks_diff.jsonl';  k=@('added','removed') }
)
$bucket=@{}
function _date($ts){ try{ return ([datetime]$ts).ToString('yyyy-MM-dd') }catch{ return $null } }
foreach($t in $logs){
  $fp=Join-Path $Base $t.p
  if(Test-Path $fp){
    Get-Content $fp -ErrorAction SilentlyContinue | ForEach-Object {
      try{
        $j = $_ | ConvertFrom-Json
        if($j -and $j.ts){
          $d=_date $j.ts
          if($d){
            if(-not $bucket[$d]){ $bucket[$d]=@{count=0} }
            foreach($kk in $t.k){
              if($j.$kk){ 
                $c = if($j.$kk -is [array]){ $j.$kk.Count } else { 1 }
                $bucket[$d].count += [int]$c
              }
            }
          }
        }
      }catch{}
    }
  }
}
# restrict to last N days
$keys = $bucket.Keys | Where-Object { try{ (([datetime]$_) -ge $now.AddDays(-$Days)) }catch{ $false } } | Sort-Object
# write CSV + MD
$csv = "date,delta_count`r`n" + ($keys | ForEach-Object { "$_," + $bucket[$_].count })
$csv | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.csv') -Encoding UTF8
$md = @("# Drift Heatmap (last $Days days)", "", "| date | delta_count |","|---:|---:|")
foreach($k in $keys){ $md += "| $k | " + $bucket[$k].count + " |" }
$md -join "`r`n" | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.md') -Encoding UTF8
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
$now=Get-Date
$logs = @(
  @{ p='reports\config_diff.jsonl'; k=@('added','removed','changed') },
  @{ p='reports\integrity.jsonl';   k=@('added','removed','changed') },
  @{ p='reports\tasks_diff.jsonl';  k=@('added','removed') }
)
$bucket=@{}
function _date($ts){ try{ return ([datetime]$ts).ToString('yyyy-MM-dd') }catch{ return $null } }
foreach($t in $logs){
  $fp=Join-Path $Base $t.p
  if(Test-Path $fp){
    Get-Content $fp -ErrorAction SilentlyContinue | ForEach-Object {
      try{
        $j = $_ | ConvertFrom-Json
        if($j -and $j.ts){
          $d=_date $j.ts
          if($d){
            if(-not $bucket[$d]){ $bucket[$d]=@{count=0} }
            foreach($kk in $t.k){
              if($j.$kk){ 
                $c = if($j.$kk -is [array]){ $j.$kk.Count } else { 1 }
                $bucket[$d].count += [int]$c
              }
            }
          }
        }
      }catch{}
    }
  }
}
# restrict to last N days
$keys = $bucket.Keys | Where-Object { try{ (([datetime]$_) -ge $now.AddDays(-$Days)) }catch{ $false } } | Sort-Object
# write CSV + MD
$csv = "date,delta_count`r`n" + ($keys | ForEach-Object { "$_," + $bucket[$_].count })
$csv | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.csv') -Encoding UTF8
$md = @("# Drift Heatmap (last $Days days)", "", "| date | delta_count |","|---:|---:|")
foreach($k in $keys){ $md += "| $k | " + $bucket[$k].count + " |" }
$md -join "`r`n" | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.md') -Encoding UTF8
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
$now=Get-Date
$logs = @(
  @{ p='reports\config_diff.jsonl'; k=@('added','removed','changed') },
  @{ p='reports\integrity.jsonl';   k=@('added','removed','changed') },
  @{ p='reports\tasks_diff.jsonl';  k=@('added','removed') }
)
$bucket=@{}
function _date($ts){ try{ return ([datetime]$ts).ToString('yyyy-MM-dd') }catch{ return $null } }
foreach($t in $logs){
  $fp=Join-Path $Base $t.p
  if(Test-Path $fp){
    Get-Content $fp -ErrorAction SilentlyContinue | ForEach-Object {
      try{
        $j = $_ | ConvertFrom-Json
        if($j -and $j.ts){
          $d=_date $j.ts
          if($d){
            if(-not $bucket[$d]){ $bucket[$d]=@{count=0} }
            foreach($kk in $t.k){
              if($j.$kk){ 
                $c = if($j.$kk -is [array]){ $j.$kk.Count } else { 1 }
                $bucket[$d].count += [int]$c
              }
            }
          }
        }
      }catch{}
    }
  }
}
# restrict to last N days
$keys = $bucket.Keys | Where-Object { try{ (([datetime]$_) -ge $now.AddDays(-$Days)) }catch{ $false } } | Sort-Object
# write CSV + MD
$csv = "date,delta_count`r`n" + ($keys | ForEach-Object { "$_," + $bucket[$_].count })
$csv | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.csv') -Encoding UTF8
$md = @("# Drift Heatmap (last $Days days)", "", "| date | delta_count |","|---:|---:|")
foreach($k in $keys){ $md += "| $k | " + $bucket[$k].count + " |" }
$md -join "`r`n" | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.md') -Encoding UTF8
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$Days=14)
$ErrorActionPreference='Stop'
$now=Get-Date
$logs = @(
  @{ p='reports\config_diff.jsonl'; k=@('added','removed','changed') },
  @{ p='reports\integrity.jsonl';   k=@('added','removed','changed') },
  @{ p='reports\tasks_diff.jsonl';  k=@('added','removed') }
)
$bucket=@{}
function _date($ts){ try{ return ([datetime]$ts).ToString('yyyy-MM-dd') }catch{ return $null } }
foreach($t in $logs){
  $fp=Join-Path $Base $t.p
  if(Test-Path $fp){
    Get-Content $fp -ErrorAction SilentlyContinue | ForEach-Object {
      try{
        $j = $_ | ConvertFrom-Json
        if($j -and $j.ts){
          $d=_date $j.ts
          if($d){
            if(-not $bucket[$d]){ $bucket[$d]=@{count=0} }
            foreach($kk in $t.k){
              if($j.$kk){ 
                $c = if($j.$kk -is [array]){ $j.$kk.Count } else { 1 }
                $bucket[$d].count += [int]$c
              }
            }
          }
        }
      }catch{}
    }
  }
}
# restrict to last N days
$keys = $bucket.Keys | Where-Object { try{ (([datetime]$_) -ge $now.AddDays(-$Days)) }catch{ $false } } | Sort-Object
# write CSV + MD
$csv = "date,delta_count`r`n" + ($keys | ForEach-Object { "$_," + $bucket[$_].count })
$csv | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.csv') -Encoding UTF8
$md = @("# Drift Heatmap (last $Days days)", "", "| date | delta_count |","|---:|---:|")
foreach($k in $keys){ $md += "| $k | " + $bucket[$k].count + " |" }
$md -join "`r`n" | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.md') -Encoding UTF8
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
$now=Get-Date
$logs = @(
  @{ p='reports\config_diff.jsonl'; k=@('added','removed','changed') },
  @{ p='reports\integrity.jsonl';   k=@('added','removed','changed') },
  @{ p='reports\tasks_diff.jsonl';  k=@('added','removed') }
)
$bucket=@{}
function _date($ts){ try{ return ([datetime]$ts).ToString('yyyy-MM-dd') }catch{ return $null } }
foreach($t in $logs){
  $fp=Join-Path $Base $t.p
  if(Test-Path $fp){
    Get-Content $fp -ErrorAction SilentlyContinue | ForEach-Object {
      try{
        $j = $_ | ConvertFrom-Json
        if($j -and $j.ts){
          $d=_date $j.ts
          if($d){
            if(-not $bucket[$d]){ $bucket[$d]=@{count=0} }
            foreach($kk in $t.k){
              if($j.$kk){ 
                $c = if($j.$kk -is [array]){ $j.$kk.Count } else { 1 }
                $bucket[$d].count += [int]$c
              }
            }
          }
        }
      }catch{}
    }
  }
}
# restrict to last N days
$keys = $bucket.Keys | Where-Object { try{ (([datetime]$_) -ge $now.AddDays(-$Days)) }catch{ $false } } | Sort-Object
# write CSV + MD
$csv = "date,delta_count`r`n" + ($keys | ForEach-Object { "$_," + $bucket[$_].count })
$csv | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.csv') -Encoding UTF8
$md = @("# Drift Heatmap (last $Days days)", "", "| date | delta_count |","|---:|---:|")
foreach($k in $keys){ $md += "| $k | " + $bucket[$k].count + " |" }
$md -join "`r`n" | Out-File -FilePath (Join-Path $Base 'reports\drift_heatmap.md') -Encoding UTF8
