$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

# -------- single-instance guard (mutex) --------
$mtx = $null
try {
  $mtx = New-Object System.Threading.Mutex($false, "Global\Mason2-FileServer-7081")
  if(-not $mtx.WaitOne(0)){
    Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='already_running' }
    exit 0
  }
} catch {}

# -------- helper: logging --------
function _log($kv){ try{ Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj $kv }catch{} }

# -------- listener setup (loopback only) --------
Add-Type -AssemblyName System.Net
$prefixes=@("http://localhost:7081/","http://127.0.0.1:7081/","http://[::1]:7081/")
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Clear(); foreach($p in $prefixes){ [void]$listener.Prefixes.Add($p) }

# -------- tiny helpers --------
function Write-RespBytes($res,[byte[]]$bytes,[string]$ct){
  $res.ContentType=$ct; $res.ContentLength64=$bytes.Length
  $res.OutputStream.Write($bytes,0,$bytes.Length); $res.OutputStream.Close()
}
function Write-RespText($res,[string]$s,[string]$ct){ Write-RespBytes $res ([Text.Encoding]::UTF8.GetBytes($s)) $ct }
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}

# -------- start listener --------
try{
  $listener.Start()
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='started'; prefixes=$prefixes }
  Write-Host "[Mini-7001] started on: $($prefixes -join ', ')"
} catch {
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='start_failed'; err=$_.Exception.Message }
  throw
}

$stopAt = (Get-Date).AddSeconds([int]$RunSeconds)

# -------- loop --------
while($listener.IsListening -and (Get-Date) -lt $stopAt){
  try{
    $ar = $listener.BeginGetContext($null,$null)
    if(-not $ar.AsyncWaitHandle.WaitOne(500)){ continue }
    $ctx = $listener.EndGetContext($ar)
    $req = $ctx.Request
    $res = $ctx.Response
    $path = ($req.Url.AbsolutePath).TrimEnd('/').ToLower()
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='hit'; path=$path; qs=$req.Url.Query }

    switch($path){
      '' { Write-RespText $res "ok" "text/plain"; continue }
      '/healthz' { Write-RespText $res "ok" "text/plain"; continue }
      '/lastok' {
        $j = $null
        $p = Join-Path $Base 'reports\net_external.jsonl'
        if(Test-Path $p){
          $j = (Get-Content $p -Tail 200 -ErrorAction SilentlyContinue |
                ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } |
                Where-Object { $_ -and $_.dns -and $_.https } |
                Select-Object -Last 1)
        }
        $obj = @{ ts=(Get-Date).ToString('s'); last_ok = $(if($j){ $j.ts } else { $null }) }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 5) "application/json"; continue
      }
      '/metrics.json' {
        $obj = @{
          ts        = (Get-Date).ToString('s')
          net       = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
          timedrift = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
          cpu       = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
          mem       = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 6) "application/json"; continue
      }
      '/metrics' {
        $net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
        $td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
        $cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
        $mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        $lines = @()
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
        Write-RespText $res ( ($lines -join "`n") + "`n" ) "text/plain"; continue
      }
      default {
        $res.StatusCode = 404
        Write-RespText $res "not found" "text/plain"; continue
      }
    }
  } catch {
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='error'; msg=$_.Exception.Message }
    try{ $res.StatusCode = 500; Write-RespText $res "error" "text/plain" }catch{}
  }
}

try{ $listener.Stop() }catch{}
try{ if($mtx){ $mtx.ReleaseMutex(); $mtx.Dispose() } }catch{}
_log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='stopped' }


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$RunSeconds=3300)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

# -------- single-instance guard (mutex) --------
$mtx = $null
try {
  $mtx = New-Object System.Threading.Mutex($false, "Global\Mason2-FileServer-7081")
  if(-not $mtx.WaitOne(0)){
    Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='already_running' }
    exit 0
  }
} catch {}

# -------- helper: logging --------
function _log($kv){ try{ Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj $kv }catch{} }

# -------- listener setup (loopback only) --------
Add-Type -AssemblyName System.Net
$prefixes=@("http://localhost:7081/","http://127.0.0.1:7081/","http://[::1]:7081/")
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Clear(); foreach($p in $prefixes){ [void]$listener.Prefixes.Add($p) }

# -------- tiny helpers --------
function Write-RespBytes($res,[byte[]]$bytes,[string]$ct){
  $res.ContentType=$ct; $res.ContentLength64=$bytes.Length
  $res.OutputStream.Write($bytes,0,$bytes.Length); $res.OutputStream.Close()
}
function Write-RespText($res,[string]$s,[string]$ct){ Write-RespBytes $res ([Text.Encoding]::UTF8.GetBytes($s)) $ct }
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}

# -------- start listener --------
try{
  $listener.Start()
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='started'; prefixes=$prefixes }
  Write-Host "[Mini-7001] started on: $($prefixes -join ', ')"
} catch {
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='start_failed'; err=$_.Exception.Message }
  throw
}

$stopAt = (Get-Date).AddSeconds([int]$RunSeconds)

# -------- loop --------
while($listener.IsListening -and (Get-Date) -lt $stopAt){
  try{
    $ar = $listener.BeginGetContext($null,$null)
    if(-not $ar.AsyncWaitHandle.WaitOne(500)){ continue }
    $ctx = $listener.EndGetContext($ar)
    $req = $ctx.Request
    $res = $ctx.Response
    $path = ($req.Url.AbsolutePath).TrimEnd('/').ToLower()
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='hit'; path=$path; qs=$req.Url.Query }

    switch($path){
      '' { Write-RespText $res "ok" "text/plain"; continue }
      '/healthz' { Write-RespText $res "ok" "text/plain"; continue }
      '/lastok' {
        $j = $null
        $p = Join-Path $Base 'reports\net_external.jsonl'
        if(Test-Path $p){
          $j = (Get-Content $p -Tail 200 -ErrorAction SilentlyContinue |
                ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } |
                Where-Object { $_ -and $_.dns -and $_.https } |
                Select-Object -Last 1)
        }
        $obj = @{ ts=(Get-Date).ToString('s'); last_ok = $(if($j){ $j.ts } else { $null }) }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 5) "application/json"; continue
      }
      '/metrics.json' {
        $obj = @{
          ts        = (Get-Date).ToString('s')
          net       = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
          timedrift = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
          cpu       = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
          mem       = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 6) "application/json"; continue
      }
      '/metrics' {
        $net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
        $td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
        $cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
        $mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        $lines = @()
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
        Write-RespText $res ( ($lines -join "`n") + "`n" ) "text/plain"; continue
      }
      default {
        $res.StatusCode = 404
        Write-RespText $res "not found" "text/plain"; continue
      }
    }
  } catch {
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='error'; msg=$_.Exception.Message }
    try{ $res.StatusCode = 500; Write-RespText $res "error" "text/plain" }catch{}
  }
}

try{ $listener.Stop() }catch{}
try{ if($mtx){ $mtx.ReleaseMutex(); $mtx.Dispose() } }catch{}
_log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='stopped' }


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$RunSeconds=3300)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

# -------- single-instance guard (mutex) --------
$mtx = $null
try {
  $mtx = New-Object System.Threading.Mutex($false, "Global\Mason2-FileServer-7081")
  if(-not $mtx.WaitOne(0)){
    Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='already_running' }
    exit 0
  }
} catch {}

# -------- helper: logging --------
function _log($kv){ try{ Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj $kv }catch{} }

# -------- listener setup (loopback only) --------
Add-Type -AssemblyName System.Net
$prefixes=@("http://localhost:7081/","http://127.0.0.1:7081/","http://[::1]:7081/")
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Clear(); foreach($p in $prefixes){ [void]$listener.Prefixes.Add($p) }

# -------- tiny helpers --------
function Write-RespBytes($res,[byte[]]$bytes,[string]$ct){
  $res.ContentType=$ct; $res.ContentLength64=$bytes.Length
  $res.OutputStream.Write($bytes,0,$bytes.Length); $res.OutputStream.Close()
}
function Write-RespText($res,[string]$s,[string]$ct){ Write-RespBytes $res ([Text.Encoding]::UTF8.GetBytes($s)) $ct }
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}

# -------- start listener --------
try{
  $listener.Start()
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='started'; prefixes=$prefixes }
  Write-Host "[Mini-7001] started on: $($prefixes -join ', ')"
} catch {
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='start_failed'; err=$_.Exception.Message }
  throw
}

$stopAt = (Get-Date).AddSeconds([int]$RunSeconds)

# -------- loop --------
while($listener.IsListening -and (Get-Date) -lt $stopAt){
  try{
    $ar = $listener.BeginGetContext($null,$null)
    if(-not $ar.AsyncWaitHandle.WaitOne(500)){ continue }
    $ctx = $listener.EndGetContext($ar)
    $req = $ctx.Request
    $res = $ctx.Response
    $path = ($req.Url.AbsolutePath).TrimEnd('/').ToLower()
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='hit'; path=$path; qs=$req.Url.Query }

    switch($path){
      '' { Write-RespText $res "ok" "text/plain"; continue }
      '/healthz' { Write-RespText $res "ok" "text/plain"; continue }
      '/lastok' {
        $j = $null
        $p = Join-Path $Base 'reports\net_external.jsonl'
        if(Test-Path $p){
          $j = (Get-Content $p -Tail 200 -ErrorAction SilentlyContinue |
                ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } |
                Where-Object { $_ -and $_.dns -and $_.https } |
                Select-Object -Last 1)
        }
        $obj = @{ ts=(Get-Date).ToString('s'); last_ok = $(if($j){ $j.ts } else { $null }) }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 5) "application/json"; continue
      }
      '/metrics.json' {
        $obj = @{
          ts        = (Get-Date).ToString('s')
          net       = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
          timedrift = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
          cpu       = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
          mem       = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 6) "application/json"; continue
      }
      '/metrics' {
        $net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
        $td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
        $cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
        $mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        $lines = @()
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
        Write-RespText $res ( ($lines -join "`n") + "`n" ) "text/plain"; continue
      }
      default {
        $res.StatusCode = 404
        Write-RespText $res "not found" "text/plain"; continue
      }
    }
  } catch {
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='error'; msg=$_.Exception.Message }
    try{ $res.StatusCode = 500; Write-RespText $res "error" "text/plain" }catch{}
  }
}

try{ $listener.Stop() }catch{}
try{ if($mtx){ $mtx.ReleaseMutex(); $mtx.Dispose() } }catch{}
_log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='stopped' }


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$RunSeconds=3300)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

# -------- single-instance guard (mutex) --------
$mtx = $null
try {
  $mtx = New-Object System.Threading.Mutex($false, "Global\Mason2-FileServer-7081")
  if(-not $mtx.WaitOne(0)){
    Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='already_running' }
    exit 0
  }
} catch {}

# -------- helper: logging --------
function _log($kv){ try{ Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj $kv }catch{} }

# -------- listener setup (loopback only) --------
Add-Type -AssemblyName System.Net
$prefixes=@("http://localhost:7081/","http://127.0.0.1:7081/","http://[::1]:7081/")
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Clear(); foreach($p in $prefixes){ [void]$listener.Prefixes.Add($p) }

# -------- tiny helpers --------
function Write-RespBytes($res,[byte[]]$bytes,[string]$ct){
  $res.ContentType=$ct; $res.ContentLength64=$bytes.Length
  $res.OutputStream.Write($bytes,0,$bytes.Length); $res.OutputStream.Close()
}
function Write-RespText($res,[string]$s,[string]$ct){ Write-RespBytes $res ([Text.Encoding]::UTF8.GetBytes($s)) $ct }
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}

# -------- start listener --------
try{
  $listener.Start()
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='started'; prefixes=$prefixes }
  Write-Host "[Mini-7001] started on: $($prefixes -join ', ')"
} catch {
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='start_failed'; err=$_.Exception.Message }
  throw
}

$stopAt = (Get-Date).AddSeconds([int]$RunSeconds)

# -------- loop --------
while($listener.IsListening -and (Get-Date) -lt $stopAt){
  try{
    $ar = $listener.BeginGetContext($null,$null)
    if(-not $ar.AsyncWaitHandle.WaitOne(500)){ continue }
    $ctx = $listener.EndGetContext($ar)
    $req = $ctx.Request
    $res = $ctx.Response
    $path = ($req.Url.AbsolutePath).TrimEnd('/').ToLower()
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='hit'; path=$path; qs=$req.Url.Query }

    switch($path){
      '' { Write-RespText $res "ok" "text/plain"; continue }
      '/healthz' { Write-RespText $res "ok" "text/plain"; continue }
      '/lastok' {
        $j = $null
        $p = Join-Path $Base 'reports\net_external.jsonl'
        if(Test-Path $p){
          $j = (Get-Content $p -Tail 200 -ErrorAction SilentlyContinue |
                ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } |
                Where-Object { $_ -and $_.dns -and $_.https } |
                Select-Object -Last 1)
        }
        $obj = @{ ts=(Get-Date).ToString('s'); last_ok = $(if($j){ $j.ts } else { $null }) }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 5) "application/json"; continue
      }
      '/metrics.json' {
        $obj = @{
          ts        = (Get-Date).ToString('s')
          net       = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
          timedrift = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
          cpu       = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
          mem       = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 6) "application/json"; continue
      }
      '/metrics' {
        $net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
        $td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
        $cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
        $mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        $lines = @()
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
        Write-RespText $res ( ($lines -join "`n") + "`n" ) "text/plain"; continue
      }
      default {
        $res.StatusCode = 404
        Write-RespText $res "not found" "text/plain"; continue
      }
    }
  } catch {
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='error'; msg=$_.Exception.Message }
    try{ $res.StatusCode = 500; Write-RespText $res "error" "text/plain" }catch{}
  }
}

try{ $listener.Stop() }catch{}
try{ if($mtx){ $mtx.ReleaseMutex(); $mtx.Dispose() } }catch{}
_log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='stopped' }


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$RunSeconds=3300)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

# -------- single-instance guard (mutex) --------
$mtx = $null
try {
  $mtx = New-Object System.Threading.Mutex($false, "Global\Mason2-FileServer-7081")
  if(-not $mtx.WaitOne(0)){
    Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='already_running' }
    exit 0
  }
} catch {}

# -------- helper: logging --------
function _log($kv){ try{ Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj $kv }catch{} }

# -------- listener setup (loopback only) --------
Add-Type -AssemblyName System.Net
$prefixes=@("http://localhost:7081/","http://127.0.0.1:7081/","http://[::1]:7081/")
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Clear(); foreach($p in $prefixes){ [void]$listener.Prefixes.Add($p) }

# -------- tiny helpers --------
function Write-RespBytes($res,[byte[]]$bytes,[string]$ct){
  $res.ContentType=$ct; $res.ContentLength64=$bytes.Length
  $res.OutputStream.Write($bytes,0,$bytes.Length); $res.OutputStream.Close()
}
function Write-RespText($res,[string]$s,[string]$ct){ Write-RespBytes $res ([Text.Encoding]::UTF8.GetBytes($s)) $ct }
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}

# -------- start listener --------
try{
  $listener.Start()
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='started'; prefixes=$prefixes }
  Write-Host "[Mini-7001] started on: $($prefixes -join ', ')"
} catch {
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='start_failed'; err=$_.Exception.Message }
  throw
}

$stopAt = (Get-Date).AddSeconds([int]$RunSeconds)

# -------- loop --------
while($listener.IsListening -and (Get-Date) -lt $stopAt){
  try{
    $ar = $listener.BeginGetContext($null,$null)
    if(-not $ar.AsyncWaitHandle.WaitOne(500)){ continue }
    $ctx = $listener.EndGetContext($ar)
    $req = $ctx.Request
    $res = $ctx.Response
    $path = ($req.Url.AbsolutePath).TrimEnd('/').ToLower()
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='hit'; path=$path; qs=$req.Url.Query }

    switch($path){
      '' { Write-RespText $res "ok" "text/plain"; continue }
      '/healthz' { Write-RespText $res "ok" "text/plain"; continue }
      '/lastok' {
        $j = $null
        $p = Join-Path $Base 'reports\net_external.jsonl'
        if(Test-Path $p){
          $j = (Get-Content $p -Tail 200 -ErrorAction SilentlyContinue |
                ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } |
                Where-Object { $_ -and $_.dns -and $_.https } |
                Select-Object -Last 1)
        }
        $obj = @{ ts=(Get-Date).ToString('s'); last_ok = $(if($j){ $j.ts } else { $null }) }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 5) "application/json"; continue
      }
      '/metrics.json' {
        $obj = @{
          ts        = (Get-Date).ToString('s')
          net       = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
          timedrift = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
          cpu       = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
          mem       = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 6) "application/json"; continue
      }
      '/metrics' {
        $net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
        $td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
        $cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
        $mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        $lines = @()
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
        Write-RespText $res ( ($lines -join "`n") + "`n" ) "text/plain"; continue
      }
      default {
        $res.StatusCode = 404
        Write-RespText $res "not found" "text/plain"; continue
      }
    }
  } catch {
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='error'; msg=$_.Exception.Message }
    try{ $res.StatusCode = 500; Write-RespText $res "error" "text/plain" }catch{}
  }
}

try{ $listener.Stop() }catch{}
try{ if($mtx){ $mtx.ReleaseMutex(); $mtx.Dispose() } }catch{}
_log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='stopped' }


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$RunSeconds=3300)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

# -------- single-instance guard (mutex) --------
$mtx = $null
try {
  $mtx = New-Object System.Threading.Mutex($false, "Global\Mason2-FileServer-7081")
  if(-not $mtx.WaitOne(0)){
    Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='already_running' }
    exit 0
  }
} catch {}

# -------- helper: logging --------
function _log($kv){ try{ Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj $kv }catch{} }

# -------- listener setup (loopback only) --------
Add-Type -AssemblyName System.Net
$prefixes=@("http://localhost:7081/","http://127.0.0.1:7081/","http://[::1]:7081/")
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Clear(); foreach($p in $prefixes){ [void]$listener.Prefixes.Add($p) }

# -------- tiny helpers --------
function Write-RespBytes($res,[byte[]]$bytes,[string]$ct){
  $res.ContentType=$ct; $res.ContentLength64=$bytes.Length
  $res.OutputStream.Write($bytes,0,$bytes.Length); $res.OutputStream.Close()
}
function Write-RespText($res,[string]$s,[string]$ct){ Write-RespBytes $res ([Text.Encoding]::UTF8.GetBytes($s)) $ct }
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}

# -------- start listener --------
try{
  $listener.Start()
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='started'; prefixes=$prefixes }
  Write-Host "[Mini-7001] started on: $($prefixes -join ', ')"
} catch {
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='start_failed'; err=$_.Exception.Message }
  throw
}

$stopAt = (Get-Date).AddSeconds([int]$RunSeconds)

# -------- loop --------
while($listener.IsListening -and (Get-Date) -lt $stopAt){
  try{
    $ar = $listener.BeginGetContext($null,$null)
    if(-not $ar.AsyncWaitHandle.WaitOne(500)){ continue }
    $ctx = $listener.EndGetContext($ar)
    $req = $ctx.Request
    $res = $ctx.Response
    $path = ($req.Url.AbsolutePath).TrimEnd('/').ToLower()
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='hit'; path=$path; qs=$req.Url.Query }

    switch($path){
      '' { Write-RespText $res "ok" "text/plain"; continue }
      '/healthz' { Write-RespText $res "ok" "text/plain"; continue }
      '/lastok' {
        $j = $null
        $p = Join-Path $Base 'reports\net_external.jsonl'
        if(Test-Path $p){
          $j = (Get-Content $p -Tail 200 -ErrorAction SilentlyContinue |
                ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } |
                Where-Object { $_ -and $_.dns -and $_.https } |
                Select-Object -Last 1)
        }
        $obj = @{ ts=(Get-Date).ToString('s'); last_ok = $(if($j){ $j.ts } else { $null }) }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 5) "application/json"; continue
      }
      '/metrics.json' {
        $obj = @{
          ts        = (Get-Date).ToString('s')
          net       = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
          timedrift = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
          cpu       = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
          mem       = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 6) "application/json"; continue
      }
      '/metrics' {
        $net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
        $td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
        $cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
        $mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        $lines = @()
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
        Write-RespText $res ( ($lines -join "`n") + "`n" ) "text/plain"; continue
      }
      default {
        $res.StatusCode = 404
        Write-RespText $res "not found" "text/plain"; continue
      }
    }
  } catch {
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='error'; msg=$_.Exception.Message }
    try{ $res.StatusCode = 500; Write-RespText $res "error" "text/plain" }catch{}
  }
}

try{ $listener.Stop() }catch{}
try{ if($mtx){ $mtx.ReleaseMutex(); $mtx.Dispose() } }catch{}
_log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='stopped' }


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBaseparam([string]$Base="$env:USERPROFILE\Desktop\Mason2",[int]$RunSeconds=3300)
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

# -------- single-instance guard (mutex) --------
$mtx = $null
try {
  $mtx = New-Object System.Threading.Mutex($false, "Global\Mason2-FileServer-7081")
  if(-not $mtx.WaitOne(0)){
    Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='already_running' }
    exit 0
  }
} catch {}

# -------- helper: logging --------
function _log($kv){ try{ Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj $kv }catch{} }

# -------- listener setup (loopback only) --------
Add-Type -AssemblyName System.Net
$prefixes=@("http://localhost:7081/","http://127.0.0.1:7081/","http://[::1]:7081/")
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Clear(); foreach($p in $prefixes){ [void]$listener.Prefixes.Add($p) }

# -------- tiny helpers --------
function Write-RespBytes($res,[byte[]]$bytes,[string]$ct){
  $res.ContentType=$ct; $res.ContentLength64=$bytes.Length
  $res.OutputStream.Write($bytes,0,$bytes.Length); $res.OutputStream.Close()
}
function Write-RespText($res,[string]$s,[string]$ct){ Write-RespBytes $res ([Text.Encoding]::UTF8.GetBytes($s)) $ct }
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}

# -------- start listener --------
try{
  $listener.Start()
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='started'; prefixes=$prefixes }
  Write-Host "[Mini-7001] started on: $($prefixes -join ', ')"
} catch {
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='start_failed'; err=$_.Exception.Message }
  throw
}

$stopAt = (Get-Date).AddSeconds([int]$RunSeconds)

# -------- loop --------
while($listener.IsListening -and (Get-Date) -lt $stopAt){
  try{
    $ar = $listener.BeginGetContext($null,$null)
    if(-not $ar.AsyncWaitHandle.WaitOne(500)){ continue }
    $ctx = $listener.EndGetContext($ar)
    $req = $ctx.Request
    $res = $ctx.Response
    $path = ($req.Url.AbsolutePath).TrimEnd('/').ToLower()
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='hit'; path=$path; qs=$req.Url.Query }

    switch($path){
      '' { Write-RespText $res "ok" "text/plain"; continue }
      '/healthz' { Write-RespText $res "ok" "text/plain"; continue }
      '/lastok' {
        $j = $null
        $p = Join-Path $Base 'reports\net_external.jsonl'
        if(Test-Path $p){
          $j = (Get-Content $p -Tail 200 -ErrorAction SilentlyContinue |
                ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } |
                Where-Object { $_ -and $_.dns -and $_.https } |
                Select-Object -Last 1)
        }
        $obj = @{ ts=(Get-Date).ToString('s'); last_ok = $(if($j){ $j.ts } else { $null }) }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 5) "application/json"; continue
      }
      '/metrics.json' {
        $obj = @{
          ts        = (Get-Date).ToString('s')
          net       = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
          timedrift = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
          cpu       = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
          mem       = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 6) "application/json"; continue
      }
      '/metrics' {
        $net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
        $td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
        $cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
        $mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        $lines = @()
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
        Write-RespText $res ( ($lines -join "`n") + "`n" ) "text/plain"; continue
      }
      default {
        $res.StatusCode = 404
        Write-RespText $res "not found" "text/plain"; continue
      }
    }
  } catch {
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='error'; msg=$_.Exception.Message }
    try{ $res.StatusCode = 500; Write-RespText $res "error" "text/plain" }catch{}
  }
}

try{ $listener.Stop() }catch{}
try{ if($mtx){ $mtx.ReleaseMutex(); $mtx.Dispose() } }catch{}
_log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='stopped' }


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
$ErrorActionPreference='Stop'
. (Join-Path $Base "tools\Common_Compat.ps1")

# -------- single-instance guard (mutex) --------
$mtx = $null
try {
  $mtx = New-Object System.Threading.Mutex($false, "Global\Mason2-FileServer-7081")
  if(-not $mtx.WaitOne(0)){
    Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='already_running' }
    exit 0
  }
} catch {}

# -------- helper: logging --------
function _log($kv){ try{ Write-JsonLineSafe -Path (Join-Path $Base "reports\http7001.jsonl") -Obj $kv }catch{} }

# -------- listener setup (loopback only) --------
Add-Type -AssemblyName System.Net
$prefixes=@("http://localhost:7081/","http://127.0.0.1:7081/","http://[::1]:7081/")
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Clear(); foreach($p in $prefixes){ [void]$listener.Prefixes.Add($p) }

# -------- tiny helpers --------
function Write-RespBytes($res,[byte[]]$bytes,[string]$ct){
  $res.ContentType=$ct; $res.ContentLength64=$bytes.Length
  $res.OutputStream.Write($bytes,0,$bytes.Length); $res.OutputStream.Close()
}
function Write-RespText($res,[string]$s,[string]$ct){ Write-RespBytes $res ([Text.Encoding]::UTF8.GetBytes($s)) $ct }
function _tailJson($p){
  if(Test-Path -LiteralPath $p){
    try{ return (Get-Content -LiteralPath $p -Tail 1 | ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } | Select-Object -Last 1) }catch{}
  }
  return $null
}

# -------- start listener --------
try{
  $listener.Start()
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='started'; prefixes=$prefixes }
  Write-Host "[Mini-7001] started on: $($prefixes -join ', ')"
} catch {
  _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='start_failed'; err=$_.Exception.Message }
  throw
}

$stopAt = (Get-Date).AddSeconds([int]$RunSeconds)

# -------- loop --------
while($listener.IsListening -and (Get-Date) -lt $stopAt){
  try{
    $ar = $listener.BeginGetContext($null,$null)
    if(-not $ar.AsyncWaitHandle.WaitOne(500)){ continue }
    $ctx = $listener.EndGetContext($ar)
    $req = $ctx.Request
    $res = $ctx.Response
    $path = ($req.Url.AbsolutePath).TrimEnd('/').ToLower()
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='hit'; path=$path; qs=$req.Url.Query }

    switch($path){
      '' { Write-RespText $res "ok" "text/plain"; continue }
      '/healthz' { Write-RespText $res "ok" "text/plain"; continue }
      '/lastok' {
        $j = $null
        $p = Join-Path $Base 'reports\net_external.jsonl'
        if(Test-Path $p){
          $j = (Get-Content $p -Tail 200 -ErrorAction SilentlyContinue |
                ForEach-Object { try{ $_|ConvertFrom-Json }catch{$null} } |
                Where-Object { $_ -and $_.dns -and $_.https } |
                Select-Object -Last 1)
        }
        $obj = @{ ts=(Get-Date).ToString('s'); last_ok = $(if($j){ $j.ts } else { $null }) }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 5) "application/json"; continue
      }
      '/metrics.json' {
        $obj = @{
          ts        = (Get-Date).ToString('s')
          net       = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
          timedrift = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
          cpu       = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
          mem       = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        }
        Write-RespText $res ($obj | ConvertTo-Json -Depth 6) "application/json"; continue
      }
      '/metrics' {
        $net  = _tailJson (Join-Path $Base 'reports\net_external.jsonl')
        $td   = _tailJson (Join-Path $Base 'reports\timedrift.jsonl')
        $cpu  = _tailJson (Join-Path $Base 'reports\cpu_pressure.jsonl')
        $mem  = _tailJson (Join-Path $Base 'reports\mem_pressure.jsonl')
        $lines = @()
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
        Write-RespText $res ( ($lines -join "`n") + "`n" ) "text/plain"; continue
      }
      default {
        $res.StatusCode = 404
        Write-RespText $res "not found" "text/plain"; continue
      }
    }
  } catch {
    _log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='error'; msg=$_.Exception.Message }
    try{ $res.StatusCode = 500; Write-RespText $res "error" "text/plain" }catch{}
  }
}

try{ $listener.Stop() }catch{}
try{ if($mtx){ $mtx.ReleaseMutex(); $mtx.Dispose() } }catch{}
_log @{ ts=(Get-Date).ToString('s'); kind='server7081'; event='stopped' }


