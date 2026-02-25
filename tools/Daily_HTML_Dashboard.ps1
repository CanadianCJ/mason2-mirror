$ErrorActionPreference='Stop'
$out = Join-Path $Base 'reports\dashboard.html'
$now = Get-Date
function _tail($p,$n){ if(Test-Path $p){ (Get-Content $p -Tail $n) -join "<br/>" } else { "(none)" } }
$body = @"
<!doctype html><meta charset="utf-8">
<title>Mason2 Dashboard</title>
<h2>Mason2 Dashboard <small>$($now.ToString('s'))</small></h2>
<ul>
<li>Disk Top Dirs: <code>reports\disk_topdirs.jsonl</code></li>
<li>Health Index: <code>reports\health_index.jsonl</code></li>
<li>CPU Pressure: <code>reports\cpu_pressure.jsonl</code></li>
<li>Memory Pressure: <code>reports\mem_pressure.jsonl</code></li>
<li>EventLog (tail):<br/><small>$(_tail (Join-Path $Base 'reports\eventlog.jsonl') 5)</small></li>
</ul>
"@
$body | Out-File -FilePath $out -Encoding UTF8
_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$out = Join-Path $Base 'reports\dashboard.html'
$now = Get-Date
function _tail($p,$n){ if(Test-Path $p){ (Get-Content $p -Tail $n) -join "<br/>" } else { "(none)" } }
$body = @"
<!doctype html><meta charset="utf-8">
<title>Mason2 Dashboard</title>
<h2>Mason2 Dashboard <small>$($now.ToString('s'))</small></h2>
<ul>
<li>Disk Top Dirs: <code>reports\disk_topdirs.jsonl</code></li>
<li>Health Index: <code>reports\health_index.jsonl</code></li>
<li>CPU Pressure: <code>reports\cpu_pressure.jsonl</code></li>
<li>Memory Pressure: <code>reports\mem_pressure.jsonl</code></li>
<li>EventLog (tail):<br/><small>$(_tail (Join-Path $Base 'reports\eventlog.jsonl') 5)</small></li>
</ul>
"@
$body | Out-File -FilePath $out -Encoding UTF8
_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$out = Join-Path $Base 'reports\dashboard.html'
$now = Get-Date
function _tail($p,$n){ if(Test-Path $p){ (Get-Content $p -Tail $n) -join "<br/>" } else { "(none)" } }
$body = @"
<!doctype html><meta charset="utf-8">
<title>Mason2 Dashboard</title>
<h2>Mason2 Dashboard <small>$($now.ToString('s'))</small></h2>
<ul>
<li>Disk Top Dirs: <code>reports\disk_topdirs.jsonl</code></li>
<li>Health Index: <code>reports\health_index.jsonl</code></li>
<li>CPU Pressure: <code>reports\cpu_pressure.jsonl</code></li>
<li>Memory Pressure: <code>reports\mem_pressure.jsonl</code></li>
<li>EventLog (tail):<br/><small>$(_tail (Join-Path $Base 'reports\eventlog.jsonl') 5)</small></li>
</ul>
"@
$body | Out-File -FilePath $out -Encoding UTF8
_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$out = Join-Path $Base 'reports\dashboard.html'
$now = Get-Date
function _tail($p,$n){ if(Test-Path $p){ (Get-Content $p -Tail $n) -join "<br/>" } else { "(none)" } }
$body = @"
<!doctype html><meta charset="utf-8">
<title>Mason2 Dashboard</title>
<h2>Mason2 Dashboard <small>$($now.ToString('s'))</small></h2>
<ul>
<li>Disk Top Dirs: <code>reports\disk_topdirs.jsonl</code></li>
<li>Health Index: <code>reports\health_index.jsonl</code></li>
<li>CPU Pressure: <code>reports\cpu_pressure.jsonl</code></li>
<li>Memory Pressure: <code>reports\mem_pressure.jsonl</code></li>
<li>EventLog (tail):<br/><small>$(_tail (Join-Path $Base 'reports\eventlog.jsonl') 5)</small></li>
</ul>
"@
$body | Out-File -FilePath $out -Encoding UTF8
_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$out = Join-Path $Base 'reports\dashboard.html'
$now = Get-Date
function _tail($p,$n){ if(Test-Path $p){ (Get-Content $p -Tail $n) -join "<br/>" } else { "(none)" } }
$body = @"
<!doctype html><meta charset="utf-8">
<title>Mason2 Dashboard</title>
<h2>Mason2 Dashboard <small>$($now.ToString('s'))</small></h2>
<ul>
<li>Disk Top Dirs: <code>reports\disk_topdirs.jsonl</code></li>
<li>Health Index: <code>reports\health_index.jsonl</code></li>
<li>CPU Pressure: <code>reports\cpu_pressure.jsonl</code></li>
<li>Memory Pressure: <code>reports\mem_pressure.jsonl</code></li>
<li>EventLog (tail):<br/><small>$(_tail (Join-Path $Base 'reports\eventlog.jsonl') 5)</small></li>
</ul>
"@
$body | Out-File -FilePath $out -Encoding UTF8
_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$out = Join-Path $Base 'reports\dashboard.html'
$now = Get-Date
function _tail($p,$n){ if(Test-Path $p){ (Get-Content $p -Tail $n) -join "<br/>" } else { "(none)" } }
$body = @"
<!doctype html><meta charset="utf-8">
<title>Mason2 Dashboard</title>
<h2>Mason2 Dashboard <small>$($now.ToString('s'))</small></h2>
<ul>
<li>Disk Top Dirs: <code>reports\disk_topdirs.jsonl</code></li>
<li>Health Index: <code>reports\health_index.jsonl</code></li>
<li>CPU Pressure: <code>reports\cpu_pressure.jsonl</code></li>
<li>Memory Pressure: <code>reports\mem_pressure.jsonl</code></li>
<li>EventLog (tail):<br/><small>$(_tail (Join-Path $Base 'reports\eventlog.jsonl') 5)</small></li>
</ul>
"@
$body | Out-File -FilePath $out -Encoding UTF8
_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2")
$ErrorActionPreference='Stop'
$out = Join-Path $Base 'reports\dashboard.html'
$now = Get-Date
function _tail($p,$n){ if(Test-Path $p){ (Get-Content $p -Tail $n) -join "<br/>" } else { "(none)" } }
$body = @"
<!doctype html><meta charset="utf-8">
<title>Mason2 Dashboard</title>
<h2>Mason2 Dashboard <small>$($now.ToString('s'))</small></h2>
<ul>
<li>Disk Top Dirs: <code>reports\disk_topdirs.jsonl</code></li>
<li>Health Index: <code>reports\health_index.jsonl</code></li>
<li>CPU Pressure: <code>reports\cpu_pressure.jsonl</code></li>
<li>Memory Pressure: <code>reports\mem_pressure.jsonl</code></li>
<li>EventLog (tail):<br/><small>$(_tail (Join-Path $Base 'reports\eventlog.jsonl') 5)</small></li>
</ul>
"@
$body | Out-File -FilePath $out -Encoding UTF8
_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
$out = Join-Path $Base 'reports\dashboard.html'
$now = Get-Date
function _tail($p,$n){ if(Test-Path $p){ (Get-Content $p -Tail $n) -join "<br/>" } else { "(none)" } }
$body = @"
<!doctype html><meta charset="utf-8">
<title>Mason2 Dashboard</title>
<h2>Mason2 Dashboard <small>$($now.ToString('s'))</small></h2>
<ul>
<li>Disk Top Dirs: <code>reports\disk_topdirs.jsonl</code></li>
<li>Health Index: <code>reports\health_index.jsonl</code></li>
<li>CPU Pressure: <code>reports\cpu_pressure.jsonl</code></li>
<li>Memory Pressure: <code>reports\mem_pressure.jsonl</code></li>
<li>EventLog (tail):<br/><small>$(_tail (Join-Path $Base 'reports\eventlog.jsonl') 5)</small></li>
</ul>
"@
$body | Out-File -FilePath $out -Encoding UTF8
