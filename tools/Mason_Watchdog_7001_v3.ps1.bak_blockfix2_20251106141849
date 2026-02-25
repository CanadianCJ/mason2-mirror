Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base  = "$env:USERPROFILE\Desktop\Mason2"
$Log   = Join-Path $Base 'reports\http7001.jsonl'
$State = Join-Path $Base 'reports\watchdog7001_state.json'
$Task  = 'Mason2-FileServer-7001'
$u     = 'http://127.0.0.1:7001/healthz'
$Freeze= Join-Path $Base 'reports\governor_freeze.flag'
$Cfg   = Join-Path $Base 'config\governor.json'
$cfg = @{ quarantine_threshold=3 }
try{ }catch{}

Start-Sleep -Seconds (Get-Random -Minimum 0 -Maximum 21)  # jitter

function jl($o){ try{ ($o|ConvertTo-Json -Compress)+[Environment]::NewLine | Out-File $Log -Append -Encoding UTF8 }catch{} }

# freeze gate

# load state
$st = @{ fail_count=0; next=0; quarantine=0 }

# probe
$ok=$false
try { $r = (Invoke-MasonHttp -Uri $u -TimeoutSec 5 -Retries 1).Content.Trim() } catch { $r='' } else {
  $st.fail_count = [Math]::Min(($st.fail_count + 1), 10)
  # backoff ladder
  $ladder = @(0,30,120,300,600,1800,3600,7200,14400,28800,57600)
  $delay  = $ladder[$st.fail_count]
  $now    = [int][double]::Parse((Get-Date -UFormat %s)) else {
    jl @{ts=(Get-Date).ToString('s'); kind='watch7001'; event='backoff'; fail=$st.fail_count; next=$st.next}


$st | ConvertTo-Json -Compress | Set-Content -Path $State_tryRoot = $PSScriptRoot
try{ }catch{}

Start-Sleep -Seconds (Get-Random -Minimum 0 -Maximum 21)  # jitter

function jl($o){ try{ ($o|ConvertTo-Json -Compress)+[Environment]::NewLine | Out-File $Log -Append -Encoding UTF8 }catch{} }

# freeze gate

# load state
$st = @{ fail_count=0; next=0; quarantine=0 }

# probe
$ok=$false
try { $r = (Invoke-MasonHttp -Uri $u -TimeoutSec 5 -Retries 1).Content.Trim() } catch { $r='' } else {
  $st.fail_count = [Math]::Min(($st.fail_count + 1), 10)
  # backoff ladder
  $ladder = @(0,30,120,300,600,1800,3600,7200,14400,28800,57600)
  $delay  = $ladder[$st.fail_count]
  $now    = [int][double]::Parse((Get-Date -UFormat %s)) else {
    jl @{ts=(Get-Date).ToString('s'); kind='watch7001'; event='backoff'; fail=$st.fail_count; next=$st.next}


$st | ConvertTo-Json -Compress | Set-Content -Path $State_tryRoot)) {
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base  = "$env:USERPROFILE\Desktop\Mason2"
$Log   = Join-Path $Base 'reports\http7001.jsonl'
$State = Join-Path $Base 'reports\watchdog7001_state.json'
$Task  = 'Mason2-FileServer-7001'
$u     = 'http://127.0.0.1:7001/healthz'
$Freeze= Join-Path $Base 'reports\governor_freeze.flag'
$Cfg   = Join-Path $Base 'config\governor.json'
$cfg = @{ quarantine_threshold=3 }
try{ }catch{}

Start-Sleep -Seconds (Get-Random -Minimum 0 -Maximum 21)  # jitter

function jl($o){ try{ ($o|ConvertTo-Json -Compress)+[Environment]::NewLine | Out-File $Log -Append -Encoding UTF8 }catch{} }

# freeze gate

# load state
$st = @{ fail_count=0; next=0; quarantine=0 }

# probe
$ok=$false
try { $r = (Invoke-MasonHttp -Uri $u -TimeoutSec 5 -Retries 1).Content.Trim() } catch { $r='' } else {
  $st.fail_count = [Math]::Min(($st.fail_count + 1), 10)
  # backoff ladder
  $ladder = @(0,30,120,300,600,1800,3600,7200,14400,28800,57600)
  $delay  = $ladder[$st.fail_count]
  $now    = [int][double]::Parse((Get-Date -UFormat %s)) else {
    jl @{ts=(Get-Date).ToString('s'); kind='watch7001'; event='backoff'; fail=$st.fail_count; next=$st.next}


Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base  = "$env:USERPROFILE\Desktop\Mason2"
$Log   = Join-Path $Base 'reports\http7001.jsonl'
$State = Join-Path $Base 'reports\watchdog7001_state.json'
$Task  = 'Mason2-FileServer-7001'
$u     = 'http://127.0.0.1:7001/healthz'
$Freeze= Join-Path $Base 'reports\governor_freeze.flag'
$Cfg   = Join-Path $Base 'config\governor.json'
$cfg = @{ quarantine_threshold=3 }
try{ }catch{}

Start-Sleep -Seconds (Get-Random -Minimum 0 -Maximum 21)  # jitter

function jl($o){ try{ ($o|ConvertTo-Json -Compress)+[Environment]::NewLine | Out-File $Log -Append -Encoding UTF8 }catch{} }

# freeze gate

# load state
$st = @{ fail_count=0; next=0; quarantine=0 }

# probe
$ok=$false
try { $r = (Invoke-MasonHttp -Uri $u -TimeoutSec 5 -Retries 1).Content.Trim() } catch { $r='' } else {
  $st.fail_count = [Math]::Min(($st.fail_count + 1), 10)
  # backoff ladder
  $ladder = @(0,30,120,300,600,1800,3600,7200,14400,28800,57600)
  $delay  = $ladder[$st.fail_count]
  $now    = [int][double]::Parse((Get-Date -UFormat %s)) else {
    jl @{ts=(Get-Date).ToString('s'); kind='watch7001'; event='backoff'; fail=$st.fail_count; next=$st.next}


$st | ConvertTo-Json -Compress | Set-Content -Path $State_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }

Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base  = "$env:USERPROFILE\Desktop\Mason2"
$Log   = Join-Path $Base 'reports\http7001.jsonl'
$State = Join-Path $Base 'reports\watchdog7001_state.json'
$Task  = 'Mason2-FileServer-7001'
$u     = 'http://127.0.0.1:7001/healthz'
$Freeze= Join-Path $Base 'reports\governor_freeze.flag'
$Cfg   = Join-Path $Base 'config\governor.json'
$cfg = @{ quarantine_threshold=3 }
try{ }catch{}

Start-Sleep -Seconds (Get-Random -Minimum 0 -Maximum 21)  # jitter

function jl($o){ try{ ($o|ConvertTo-Json -Compress)+[Environment]::NewLine | Out-File $Log -Append -Encoding UTF8 }catch{} }

# freeze gate

# load state
$st = @{ fail_count=0; next=0; quarantine=0 }

# probe
$ok=$false
try { $r = (Invoke-MasonHttp -Uri $u -TimeoutSec 5 -Retries 1).Content.Trim() } catch { $r='' } else {
  $st.fail_count = [Math]::Min(($st.fail_count + 1), 10)
  # backoff ladder
  $ladder = @(0,30,120,300,600,1800,3600,7200,14400,28800,57600)
  $delay  = $ladder[$st.fail_count]
  $now    = [int][double]::Parse((Get-Date -UFormat %s)) else {
    jl @{ts=(Get-Date).ToString('s'); kind='watch7001'; event='backoff'; fail=$st.fail_count; next=$st.next}


Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base  = "$env:USERPROFILE\Desktop\Mason2"
$Log   = Join-Path $Base 'reports\http7001.jsonl'
$State = Join-Path $Base 'reports\watchdog7001_state.json'
$Task  = 'Mason2-FileServer-7001'
$u     = 'http://127.0.0.1:7001/healthz'
$Freeze= Join-Path $Base 'reports\governor_freeze.flag'
$Cfg   = Join-Path $Base 'config\governor.json'
$cfg = @{ quarantine_threshold=3 }
try{ }catch{}

Start-Sleep -Seconds (Get-Random -Minimum 0 -Maximum 21)  # jitter

function jl($o){ try{ ($o|ConvertTo-Json -Compress)+[Environment]::NewLine | Out-File $Log -Append -Encoding UTF8 }catch{} }

# freeze gate

# load state
$st = @{ fail_count=0; next=0; quarantine=0 }

# probe
$ok=$false
try { $r = (Invoke-MasonHttp -Uri $u -TimeoutSec 5 -Retries 1).Content.Trim() } catch { $r='' } else {
  $st.fail_count = [Math]::Min(($st.fail_count + 1), 10)
  # backoff ladder
  $ladder = @(0,30,120,300,600,1800,3600,7200,14400,28800,57600)
  $delay  = $ladder[$st.fail_count]
  $now    = [int][double]::Parse((Get-Date -UFormat %s)) else {
    jl @{ts=(Get-Date).ToString('s'); kind='watch7001'; event='backoff'; fail=$st.fail_count; next=$st.next}


Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base  = "$env:USERPROFILE\Desktop\Mason2"
$Log   = Join-Path $Base 'reports\http7001.jsonl'
$State = Join-Path $Base 'reports\watchdog7001_state.json'
$Task  = 'Mason2-FileServer-7001'
$u     = 'http://127.0.0.1:7001/healthz'
$Freeze= Join-Path $Base 'reports\governor_freeze.flag'
$Cfg   = Join-Path $Base 'config\governor.json'
$cfg = @{ quarantine_threshold=3 }
try{ }catch{}

Start-Sleep -Seconds (Get-Random -Minimum 0 -Maximum 21)  # jitter

function jl($o){ try{ ($o|ConvertTo-Json -Compress)+[Environment]::NewLine | Out-File $Log -Append -Encoding UTF8 }catch{} }

# freeze gate

# load state
$st = @{ fail_count=0; next=0; quarantine=0 }

# probe
$ok=$false
try { $r = (Invoke-MasonHttp -Uri $u -TimeoutSec 5 -Retries 1).Content.Trim() } catch { $r='' } else {
  $st.fail_count = [Math]::Min(($st.fail_count + 1), 10)
  # backoff ladder
  $ladder = @(0,30,120,300,600,1800,3600,7200,14400,28800,57600)
  $delay  = $ladder[$st.fail_count]
  $now    = [int][double]::Parse((Get-Date -UFormat %s)) else {
    jl @{ts=(Get-Date).ToString('s'); kind='watch7001'; event='backoff'; fail=$st.fail_count; next=$st.next}


$st | ConvertTo-Json -Compress | Set-Content -Path $State_lib -Force
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Mason.Net.psm1") -Force
$Base  = "$env:USERPROFILE\Desktop\Mason2"
$Log   = Join-Path $Base 'reports\http7001.jsonl'
$State = Join-Path $Base 'reports\watchdog7001_state.json'
$Task  = 'Mason2-FileServer-7001'
$u     = 'http://127.0.0.1:7001/healthz'
$Freeze= Join-Path $Base 'reports\governor_freeze.flag'
$Cfg   = Join-Path $Base 'config\governor.json'
$cfg = @{ quarantine_threshold=3 }
try{ if(Test-Path $Cfg){ $cfg = Get-Content $Cfg -Raw | ConvertFrom-Json } }catch{}

Start-Sleep -Seconds (Get-Random -Minimum 0 -Maximum 21)  # jitter

function jl($o){ try{ ($o|ConvertTo-Json -Compress)+[Environment]::NewLine | Out-File $Log -Append -Encoding UTF8 }catch{} }

# freeze gate
if(Test-Path $Freeze){
  jl @{ts=(Get-Date).ToString('s'); kind='watch7001'; event='frozen'}
  exit 0

# load state
$st = @{ fail_count=0; next=0; quarantine=0 }
if (Test-Path $State) { try { $st = Get-Content $State -Raw | ConvertFrom-Json } catch {} }

# probe
$ok=$false
try { $r = (Invoke-MasonHttp -Uri $u -TimeoutSec 5 -Retries 1).Content.Trim() } catch { $r='' }
if ($r -eq 'ok') {
  $ok=$true
  $st.fail_count = 0; $st.next = 0
  jl @{ts=(Get-Date).ToString('s'); kind='watch7001'; event='ok'}
} else {
  $st.fail_count = [Math]::Min(($st.fail_count + 1), 10)
  # backoff ladder
  $ladder = @(0,30,120,300,600,1800,3600,7200,14400,28800,57600)
  $delay  = $ladder[$st.fail_count]
  $now    = [int][double]::Parse((Get-Date -UFormat %s))
  if ($now -ge [int]$st.next) {
    schtasks /Run /TN $Task | Out-Null
    $st.next = $now + $delay
    jl @{ts=(Get-Date).ToString('s'); kind='watch7001'; event='restart'; fail=$st.fail_count; next=$st.next}
  } else {
    jl @{ts=(Get-Date).ToString('s'); kind='watch7001'; event='backoff'; fail=$st.fail_count; next=$st.next}

  if ($st.fail_count -ge [int]$cfg.quarantine_threshold){
    # quarantine: disable task to stop flapping
    schtasks /Change /TN $Task /Disable | Out-Null
    $st.quarantine = 1
    jl @{ts=(Get-Date).ToString('s'); kind='watch7001'; event='quarantined'; reason='excess_failures'}


$st | ConvertTo-Json -Compress | Set-Content -Path $State