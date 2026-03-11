$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$ss  = Join-Path $rep 'status_summary.md'
$cl  = Join-Path $rep 'changelog.md'
$now = Get-Date

# gather a few quick facts
$hi = $null; if(Test-Path (Join-Path $rep 'health_index.jsonl')){ try{ $hi = (Get-Content (Join-Path $rep 'health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$errN = 0; if(Test-Path (Join-Path $rep 'exec_log.jsonl')){ try{ $today = $now.ToString('yyyy-MM-dd'); $errN = (Select-String -Path (Join-Path $rep 'exec_log.jsonl') -SimpleMatch $today | ForEach-Object { try{ $_.ToString() | ConvertFrom-Json }catch{$null} } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count }catch{} }
$diskPct = $null; if(Test-Path (Join-Path $Base 'metrics\disk_usage.csv')){ try{ $diskPct = ([string](Get-Content (Join-Path $Base 'metrics\disk_usage.csv') -Tail 1)).Split(',')[-1].Trim('"') }catch{} }

# write status summary
$lines = @()
$lines += "# Mason2 Status"
$lines += "Date: $($now.ToString('s'))"
if($hi){ $lines += "Health: $($hi.score)  (disk free: $($hi.disk_free_pct)%, errors today: $($hi.errors), drift warn: $($hi.drift_warn))" }
elseif($diskPct){ $lines += "Disk free: $diskPct%" }
$lines += "Errors today: $errN"
$lines += ""
$lines += "Next: (auto-updated elsewhere)"
$lines -join "`r`n" | Set-Content -LiteralPath $ss -Encoding UTF8

# append minimal changelog line
"[{0}] status updated; errors={1}" -f $now.ToString('s'), $errN | Add-Content -LiteralPath $cl -Encoding UTF8
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$ss  = Join-Path $rep 'status_summary.md'
$cl  = Join-Path $rep 'changelog.md'
$now = Get-Date

# gather a few quick facts
$hi = $null; if(Test-Path (Join-Path $rep 'health_index.jsonl')){ try{ $hi = (Get-Content (Join-Path $rep 'health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$errN = 0; if(Test-Path (Join-Path $rep 'exec_log.jsonl')){ try{ $today = $now.ToString('yyyy-MM-dd'); $errN = (Select-String -Path (Join-Path $rep 'exec_log.jsonl') -SimpleMatch $today | ForEach-Object { try{ $_.ToString() | ConvertFrom-Json }catch{$null} } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count }catch{} }
$diskPct = $null; if(Test-Path (Join-Path $Base 'metrics\disk_usage.csv')){ try{ $diskPct = ([string](Get-Content (Join-Path $Base 'metrics\disk_usage.csv') -Tail 1)).Split(',')[-1].Trim('"') }catch{} }

# write status summary
$lines = @()
$lines += "# Mason2 Status"
$lines += "Date: $($now.ToString('s'))"
if($hi){ $lines += "Health: $($hi.score)  (disk free: $($hi.disk_free_pct)%, errors today: $($hi.errors), drift warn: $($hi.drift_warn))" }
elseif($diskPct){ $lines += "Disk free: $diskPct%" }
$lines += "Errors today: $errN"
$lines += ""
$lines += "Next: (auto-updated elsewhere)"
$lines -join "`r`n" | Set-Content -LiteralPath $ss -Encoding UTF8

# append minimal changelog line
"[{0}] status updated; errors={1}" -f $now.ToString('s'), $errN | Add-Content -LiteralPath $cl -Encoding UTF8
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$ss  = Join-Path $rep 'status_summary.md'
$cl  = Join-Path $rep 'changelog.md'
$now = Get-Date

# gather a few quick facts
$hi = $null; if(Test-Path (Join-Path $rep 'health_index.jsonl')){ try{ $hi = (Get-Content (Join-Path $rep 'health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$errN = 0; if(Test-Path (Join-Path $rep 'exec_log.jsonl')){ try{ $today = $now.ToString('yyyy-MM-dd'); $errN = (Select-String -Path (Join-Path $rep 'exec_log.jsonl') -SimpleMatch $today | ForEach-Object { try{ $_.ToString() | ConvertFrom-Json }catch{$null} } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count }catch{} }
$diskPct = $null; if(Test-Path (Join-Path $Base 'metrics\disk_usage.csv')){ try{ $diskPct = ([string](Get-Content (Join-Path $Base 'metrics\disk_usage.csv') -Tail 1)).Split(',')[-1].Trim('"') }catch{} }

# write status summary
$lines = @()
$lines += "# Mason2 Status"
$lines += "Date: $($now.ToString('s'))"
if($hi){ $lines += "Health: $($hi.score)  (disk free: $($hi.disk_free_pct)%, errors today: $($hi.errors), drift warn: $($hi.drift_warn))" }
elseif($diskPct){ $lines += "Disk free: $diskPct%" }
$lines += "Errors today: $errN"
$lines += ""
$lines += "Next: (auto-updated elsewhere)"
$lines -join "`r`n" | Set-Content -LiteralPath $ss -Encoding UTF8

# append minimal changelog line
"[{0}] status updated; errors={1}" -f $now.ToString('s'), $errN | Add-Content -LiteralPath $cl -Encoding UTF8
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$ss  = Join-Path $rep 'status_summary.md'
$cl  = Join-Path $rep 'changelog.md'
$now = Get-Date

# gather a few quick facts
$hi = $null; if(Test-Path (Join-Path $rep 'health_index.jsonl')){ try{ $hi = (Get-Content (Join-Path $rep 'health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$errN = 0; if(Test-Path (Join-Path $rep 'exec_log.jsonl')){ try{ $today = $now.ToString('yyyy-MM-dd'); $errN = (Select-String -Path (Join-Path $rep 'exec_log.jsonl') -SimpleMatch $today | ForEach-Object { try{ $_.ToString() | ConvertFrom-Json }catch{$null} } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count }catch{} }
$diskPct = $null; if(Test-Path (Join-Path $Base 'metrics\disk_usage.csv')){ try{ $diskPct = ([string](Get-Content (Join-Path $Base 'metrics\disk_usage.csv') -Tail 1)).Split(',')[-1].Trim('"') }catch{} }

# write status summary
$lines = @()
$lines += "# Mason2 Status"
$lines += "Date: $($now.ToString('s'))"
if($hi){ $lines += "Health: $($hi.score)  (disk free: $($hi.disk_free_pct)%, errors today: $($hi.errors), drift warn: $($hi.drift_warn))" }
elseif($diskPct){ $lines += "Disk free: $diskPct%" }
$lines += "Errors today: $errN"
$lines += ""
$lines += "Next: (auto-updated elsewhere)"
$lines -join "`r`n" | Set-Content -LiteralPath $ss -Encoding UTF8

# append minimal changelog line
"[{0}] status updated; errors={1}" -f $now.ToString('s'), $errN | Add-Content -LiteralPath $cl -Encoding UTF8
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$ss  = Join-Path $rep 'status_summary.md'
$cl  = Join-Path $rep 'changelog.md'
$now = Get-Date

# gather a few quick facts
$hi = $null; if(Test-Path (Join-Path $rep 'health_index.jsonl')){ try{ $hi = (Get-Content (Join-Path $rep 'health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$errN = 0; if(Test-Path (Join-Path $rep 'exec_log.jsonl')){ try{ $today = $now.ToString('yyyy-MM-dd'); $errN = (Select-String -Path (Join-Path $rep 'exec_log.jsonl') -SimpleMatch $today | ForEach-Object { try{ $_.ToString() | ConvertFrom-Json }catch{$null} } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count }catch{} }
$diskPct = $null; if(Test-Path (Join-Path $Base 'metrics\disk_usage.csv')){ try{ $diskPct = ([string](Get-Content (Join-Path $Base 'metrics\disk_usage.csv') -Tail 1)).Split(',')[-1].Trim('"') }catch{} }

# write status summary
$lines = @()
$lines += "# Mason2 Status"
$lines += "Date: $($now.ToString('s'))"
if($hi){ $lines += "Health: $($hi.score)  (disk free: $($hi.disk_free_pct)%, errors today: $($hi.errors), drift warn: $($hi.drift_warn))" }
elseif($diskPct){ $lines += "Disk free: $diskPct%" }
$lines += "Errors today: $errN"
$lines += ""
$lines += "Next: (auto-updated elsewhere)"
$lines -join "`r`n" | Set-Content -LiteralPath $ss -Encoding UTF8

# append minimal changelog line
"[{0}] status updated; errors={1}" -f $now.ToString('s'), $errN | Add-Content -LiteralPath $cl -Encoding UTF8
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$ss  = Join-Path $rep 'status_summary.md'
$cl  = Join-Path $rep 'changelog.md'
$now = Get-Date

# gather a few quick facts
$hi = $null; if(Test-Path (Join-Path $rep 'health_index.jsonl')){ try{ $hi = (Get-Content (Join-Path $rep 'health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$errN = 0; if(Test-Path (Join-Path $rep 'exec_log.jsonl')){ try{ $today = $now.ToString('yyyy-MM-dd'); $errN = (Select-String -Path (Join-Path $rep 'exec_log.jsonl') -SimpleMatch $today | ForEach-Object { try{ $_.ToString() | ConvertFrom-Json }catch{$null} } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count }catch{} }
$diskPct = $null; if(Test-Path (Join-Path $Base 'metrics\disk_usage.csv')){ try{ $diskPct = ([string](Get-Content (Join-Path $Base 'metrics\disk_usage.csv') -Tail 1)).Split(',')[-1].Trim('"') }catch{} }

# write status summary
$lines = @()
$lines += "# Mason2 Status"
$lines += "Date: $($now.ToString('s'))"
if($hi){ $lines += "Health: $($hi.score)  (disk free: $($hi.disk_free_pct)%, errors today: $($hi.errors), drift warn: $($hi.drift_warn))" }
elseif($diskPct){ $lines += "Disk free: $diskPct%" }
$lines += "Errors today: $errN"
$lines += ""
$lines += "Next: (auto-updated elsewhere)"
$lines -join "`r`n" | Set-Content -LiteralPath $ss -Encoding UTF8

# append minimal changelog line
"[{0}] status updated; errors={1}" -f $now.ToString('s'), $errN | Add-Content -LiteralPath $cl -Encoding UTF8
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$ss  = Join-Path $rep 'status_summary.md'
$cl  = Join-Path $rep 'changelog.md'
$now = Get-Date

# gather a few quick facts
$hi = $null; if(Test-Path (Join-Path $rep 'health_index.jsonl')){ try{ $hi = (Get-Content (Join-Path $rep 'health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$errN = 0; if(Test-Path (Join-Path $rep 'exec_log.jsonl')){ try{ $today = $now.ToString('yyyy-MM-dd'); $errN = (Select-String -Path (Join-Path $rep 'exec_log.jsonl') -SimpleMatch $today | ForEach-Object { try{ $_.ToString() | ConvertFrom-Json }catch{$null} } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count }catch{} }
$diskPct = $null; if(Test-Path (Join-Path $Base 'metrics\disk_usage.csv')){ try{ $diskPct = ([string](Get-Content (Join-Path $Base 'metrics\disk_usage.csv') -Tail 1)).Split(',')[-1].Trim('"') }catch{} }

# write status summary
$lines = @()
$lines += "# Mason2 Status"
$lines += "Date: $($now.ToString('s'))"
if($hi){ $lines += "Health: $($hi.score)  (disk free: $($hi.disk_free_pct)%, errors today: $($hi.errors), drift warn: $($hi.drift_warn))" }
elseif($diskPct){ $lines += "Disk free: $diskPct%" }
$lines += "Errors today: $errN"
$lines += ""
$lines += "Next: (auto-updated elsewhere)"
$lines -join "`r`n" | Set-Content -LiteralPath $ss -Encoding UTF8

# append minimal changelog line
"[{0}] status updated; errors={1}" -f $now.ToString('s'), $errN | Add-Content -LiteralPath $cl -Encoding UTF8
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")
$rep = Join-Path $Base 'reports'
$ss  = Join-Path $rep 'status_summary.md'
$cl  = Join-Path $rep 'changelog.md'
$now = Get-Date

# gather a few quick facts
$hi = $null; if(Test-Path (Join-Path $rep 'health_index.jsonl')){ try{ $hi = (Get-Content (Join-Path $rep 'health_index.jsonl') -Tail 1 | ConvertFrom-Json) }catch{} }
$errN = 0; if(Test-Path (Join-Path $rep 'exec_log.jsonl')){ try{ $today = $now.ToString('yyyy-MM-dd'); $errN = (Select-String -Path (Join-Path $rep 'exec_log.jsonl') -SimpleMatch $today | ForEach-Object { try{ $_.ToString() | ConvertFrom-Json }catch{$null} } | Where-Object { $_ -and $_.rc -and $_.rc -ne 0 } | Measure-Object).Count }catch{} }
$diskPct = $null; if(Test-Path (Join-Path $Base 'metrics\disk_usage.csv')){ try{ $diskPct = ([string](Get-Content (Join-Path $Base 'metrics\disk_usage.csv') -Tail 1)).Split(',')[-1].Trim('"') }catch{} }

# write status summary
$lines = @()
$lines += "# Mason2 Status"
$lines += "Date: $($now.ToString('s'))"
if($hi){ $lines += "Health: $($hi.score)  (disk free: $($hi.disk_free_pct)%, errors today: $($hi.errors), drift warn: $($hi.drift_warn))" }
elseif($diskPct){ $lines += "Disk free: $diskPct%" }
$lines += "Errors today: $errN"
$lines += ""
$lines += "Next: (auto-updated elsewhere)"
$lines -join "`r`n" | Set-Content -LiteralPath $ss -Encoding UTF8

# append minimal changelog line
"[{0}] status updated; errors={1}" -f $now.ToString('s'), $errN | Add-Content -LiteralPath $cl -Encoding UTF8
