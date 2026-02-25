$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}
$net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
$td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
$cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
$mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
$lines=@("# mason2 metrics", "# ts=" + (Get-Date).ToString('s'))
if($net){
  $up = (if($net.https -and $net.dns){1}else{0})
  $ms = (if($net.ms){ [int]$net.ms }else{ -1 })
  $host = (if($net.host){ $net.host }else{ 'unknown' })
  $lines += "mason2_net_up{host=""$host""} $up"
  $lines += "mason2_net_latency_ms{host=""$host""} $ms"
}
if($td -and $td.offset_s -ne $null){ $lines += "mason2_timesync_offset_seconds $($td.offset_s)" }
if($cpu -and $cpu.pct -ne $null){     $lines += "mason2_cpu_pressure_pct $($cpu.pct)" }
if($mem -and $mem.pct -ne $null){     $lines += "mason2_mem_pressure_pct $($mem.pct)" }
$dst = Join-Path $Base 'reports\metrics.prom'
($lines -join "`r`n") + "`r`n" | Out-File -FilePath $dst -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_export.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='prom_export'; file='reports\metrics.prom' }
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}
$net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
$td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
$cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
$mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
$lines=@("# mason2 metrics", "# ts=" + (Get-Date).ToString('s'))
if($net){
  $up = (if($net.https -and $net.dns){1}else{0})
  $ms = (if($net.ms){ [int]$net.ms }else{ -1 })
  $host = (if($net.host){ $net.host }else{ 'unknown' })
  $lines += "mason2_net_up{host=""$host""} $up"
  $lines += "mason2_net_latency_ms{host=""$host""} $ms"
}
if($td -and $td.offset_s -ne $null){ $lines += "mason2_timesync_offset_seconds $($td.offset_s)" }
if($cpu -and $cpu.pct -ne $null){     $lines += "mason2_cpu_pressure_pct $($cpu.pct)" }
if($mem -and $mem.pct -ne $null){     $lines += "mason2_mem_pressure_pct $($mem.pct)" }
$dst = Join-Path $Base 'reports\metrics.prom'
($lines -join "`r`n") + "`r`n" | Out-File -FilePath $dst -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_export.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='prom_export'; file='reports\metrics.prom' }
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}
$net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
$td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
$cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
$mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
$lines=@("# mason2 metrics", "# ts=" + (Get-Date).ToString('s'))
if($net){
  $up = (if($net.https -and $net.dns){1}else{0})
  $ms = (if($net.ms){ [int]$net.ms }else{ -1 })
  $host = (if($net.host){ $net.host }else{ 'unknown' })
  $lines += "mason2_net_up{host=""$host""} $up"
  $lines += "mason2_net_latency_ms{host=""$host""} $ms"
}
if($td -and $td.offset_s -ne $null){ $lines += "mason2_timesync_offset_seconds $($td.offset_s)" }
if($cpu -and $cpu.pct -ne $null){     $lines += "mason2_cpu_pressure_pct $($cpu.pct)" }
if($mem -and $mem.pct -ne $null){     $lines += "mason2_mem_pressure_pct $($mem.pct)" }
$dst = Join-Path $Base 'reports\metrics.prom'
($lines -join "`r`n") + "`r`n" | Out-File -FilePath $dst -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_export.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='prom_export'; file='reports\metrics.prom' }
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}
$net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
$td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
$cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
$mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
$lines=@("# mason2 metrics", "# ts=" + (Get-Date).ToString('s'))
if($net){
  $up = (if($net.https -and $net.dns){1}else{0})
  $ms = (if($net.ms){ [int]$net.ms }else{ -1 })
  $host = (if($net.host){ $net.host }else{ 'unknown' })
  $lines += "mason2_net_up{host=""$host""} $up"
  $lines += "mason2_net_latency_ms{host=""$host""} $ms"
}
if($td -and $td.offset_s -ne $null){ $lines += "mason2_timesync_offset_seconds $($td.offset_s)" }
if($cpu -and $cpu.pct -ne $null){     $lines += "mason2_cpu_pressure_pct $($cpu.pct)" }
if($mem -and $mem.pct -ne $null){     $lines += "mason2_mem_pressure_pct $($mem.pct)" }
$dst = Join-Path $Base 'reports\metrics.prom'
($lines -join "`r`n") + "`r`n" | Out-File -FilePath $dst -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_export.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='prom_export'; file='reports\metrics.prom' }
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}
$net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
$td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
$cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
$mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
$lines=@("# mason2 metrics", "# ts=" + (Get-Date).ToString('s'))
if($net){
  $up = (if($net.https -and $net.dns){1}else{0})
  $ms = (if($net.ms){ [int]$net.ms }else{ -1 })
  $host = (if($net.host){ $net.host }else{ 'unknown' })
  $lines += "mason2_net_up{host=""$host""} $up"
  $lines += "mason2_net_latency_ms{host=""$host""} $ms"
}
if($td -and $td.offset_s -ne $null){ $lines += "mason2_timesync_offset_seconds $($td.offset_s)" }
if($cpu -and $cpu.pct -ne $null){     $lines += "mason2_cpu_pressure_pct $($cpu.pct)" }
if($mem -and $mem.pct -ne $null){     $lines += "mason2_mem_pressure_pct $($mem.pct)" }
$dst = Join-Path $Base 'reports\metrics.prom'
($lines -join "`r`n") + "`r`n" | Out-File -FilePath $dst -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_export.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='prom_export'; file='reports\metrics.prom' }
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}
$net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
$td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
$cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
$mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
$lines=@("# mason2 metrics", "# ts=" + (Get-Date).ToString('s'))
if($net){
  $up = (if($net.https -and $net.dns){1}else{0})
  $ms = (if($net.ms){ [int]$net.ms }else{ -1 })
  $host = (if($net.host){ $net.host }else{ 'unknown' })
  $lines += "mason2_net_up{host=""$host""} $up"
  $lines += "mason2_net_latency_ms{host=""$host""} $ms"
}
if($td -and $td.offset_s -ne $null){ $lines += "mason2_timesync_offset_seconds $($td.offset_s)" }
if($cpu -and $cpu.pct -ne $null){     $lines += "mason2_cpu_pressure_pct $($cpu.pct)" }
if($mem -and $mem.pct -ne $null){     $lines += "mason2_mem_pressure_pct $($mem.pct)" }
$dst = Join-Path $Base 'reports\metrics.prom'
($lines -join "`r`n") + "`r`n" | Out-File -FilePath $dst -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_export.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='prom_export'; file='reports\metrics.prom' }
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}
$net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
$td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
$cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
$mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
$lines=@("# mason2 metrics", "# ts=" + (Get-Date).ToString('s'))
if($net){
  $up = (if($net.https -and $net.dns){1}else{0})
  $ms = (if($net.ms){ [int]$net.ms }else{ -1 })
  $host = (if($net.host){ $net.host }else{ 'unknown' })
  $lines += "mason2_net_up{host=""$host""} $up"
  $lines += "mason2_net_latency_ms{host=""$host""} $ms"
}
if($td -and $td.offset_s -ne $null){ $lines += "mason2_timesync_offset_seconds $($td.offset_s)" }
if($cpu -and $cpu.pct -ne $null){     $lines += "mason2_cpu_pressure_pct $($cpu.pct)" }
if($mem -and $mem.pct -ne $null){     $lines += "mason2_mem_pressure_pct $($mem.pct)" }
$dst = Join-Path $Base 'reports\metrics.prom'
($lines -join "`r`n") + "`r`n" | Out-File -FilePath $dst -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_export.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='prom_export'; file='reports\metrics.prom' }
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}
$net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
$td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
$cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
$mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
$lines=@("# mason2 metrics", "# ts=" + (Get-Date).ToString('s'))
if($net){
  $up = (if($net.https -and $net.dns){1}else{0})
  $ms = (if($net.ms){ [int]$net.ms }else{ -1 })
  $host = (if($net.host){ $net.host }else{ 'unknown' })
  $lines += "mason2_net_up{host=""$host""} $up"
  $lines += "mason2_net_latency_ms{host=""$host""} $ms"
}
if($td -and $td.offset_s -ne $null){ $lines += "mason2_timesync_offset_seconds $($td.offset_s)" }
if($cpu -and $cpu.pct -ne $null){     $lines += "mason2_cpu_pressure_pct $($cpu.pct)" }
if($mem -and $mem.pct -ne $null){     $lines += "mason2_mem_pressure_pct $($mem.pct)" }
$dst = Join-Path $Base 'reports\metrics.prom'
($lines -join "`r`n") + "`r`n" | Out-File -FilePath $dst -Encoding UTF8
Write-JsonLineSafe -Path (Join-Path $Base 'reports\metrics_export.jsonl') -Obj @{ ts=(Get-Date).ToString('s'); kind='prom_export'; file='reports\metrics.prom' }
