# Stamped: 2025-11-05T17:02:01
param([switch]$Fix)

function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function ReadText([string]$p){ if(Test-Path $p){ Get-Content $p -Raw } else { "" } }

$Base   = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools  = Join-Path $Base 'tools'
$Cfg    = Join-Path $Base 'config'
$Rep    = Join-Path $Base 'reports'
$Sig    = Join-Path $Rep  'signals'
$Logs   = Join-Path $Base 'logs'
$Tel    = Join-Path $Logs 'telemetry\heartbeat.log'
$Report = Join-Path $Rep 'phase1_acceptance_report.md'
$Dist   = Join-Path $Base 'dist'

ni $Sig  -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null

$MustPass = @()
$Present  = @()
$Miss     = @()

function Check-Task($name, [int]$maxAgeMin = 0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $csv) { $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if ($LASTEXITCODE -ne 0 -or -not $csv) { return @{ ok=$false; msg=('Task not found: {0}' -f $name) } }

  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)

  $lastRun = $null
  try { if($obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){ $lastRun = [datetime]::Parse($obj.'Last Run Time') } } catch {}

  if ($maxAgeMin -gt 0 -and $lastRun) {
    $mins = [int]([datetime]::Now - $lastRun).TotalMinutes
    if ($mins -gt $maxAgeMin) { return @{ ok=$false; msg=("{0} last run {1}m ago (> {2} m)" -f $name,$mins,$maxAgeMin) } }
  }

  $res = ($obj.'Last Result' + '').Trim()
  if ($maxAgeMin -eq 0) {
    # Presence-only: accept Success(0), Running(267009), NotYetRun(267011)
    if (@('0','267009','267011') -notcontains $res) { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  } else {
    if ($res -and $res -ne '0') { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  }
  return @{ ok=$true; msg=("$name present") }
}

function AddRes($cond,$passMsg,$failMsg,$must=$true){
  if($cond){ if($must){$script:MustPass += "ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ $passMsg"} else {$script:Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© $passMsg"} }
  else     { if($must){$script:Miss     += "ÃƒÂ¢Ã‚ÂÃ…â€™ $failMsg"} else {$script:Miss    += "ÃƒÂ¢Ã‚Â¬Ã…â€œ $failMsg"} }
}

# 1) Heartbeat freshness (<=2m)
$hbOk = $false
try{ if(Test-Path $Tel){ $hbOk = ([int]([datetime]::Now - (Get-Item $Tel).LastWriteTime).TotalMinutes) -le 2 } }catch{}
AddRes $hbOk "Heartbeat is fresh (<=2m)" "Heartbeat stale or missing"

# 2) Scheduler health (age-gated)
foreach($t in @(@{n="Mason2 Heartbeat";age=2}, @{n="Mason2 Watchdog";age=3}, @{n="Mason2 Governor";age=4})){
  $r = Check-Task $t.n $t.age; AddRes $r.ok "$($t.n) healthy" $r.msg
}

# 3) Other scheduled jobs present (presence-only)
foreach($n in @("Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance",
                "Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth",
                "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms",
                "Mason2 Dashboard")){
  $r = Check-Task $n 0; AddRes $r.ok "$n present" $r.msg
}

# 4) Env toggle agrees
$envTxt  = ReadText (Join-Path $Rep 'env.txt')
$envJson = ReadText (Join-Path $Cfg 'env.json')
$modeTxt = ($envTxt -replace '.*ENV=','').Trim()
$modeJson = ""; try{ if($envJson){ $modeJson = ((($envJson | ConvertFrom-Json).environment)+"").Trim() } }catch{}
AddRes ( ($modeTxt -ne "") -and ($modeTxt -eq $modeJson) ) "Env consistent: $modeTxt" "Env mismatch or missing"

# 5) Pricebook + Roadmap exist
$priceOK = (Test-Path (Join-Path $Rep 'price\total_cad.txt')) -and ( ((ReadText (Join-Path $Rep 'price\line_items.md')).Trim()) -ne "" )
AddRes $priceOK "Price/line items generated" "Price/line items missing"
$roadOK  = ( (ReadText (Join-Path $Rep 'roadmap_render.md')).Trim() -ne "" )
AddRes $roadOK "Roadmap render exists" "Roadmap render missing"

# 6) One-folder + prereqs + sanity
$vf = Join-Path $Tools 'Verify_OneFolder.ps1'; if(Test-Path $vf){ powershell -NoProfile -ExecutionPolicy Bypass -File $vf | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-onefolder.ok')) "One-folder integrity OK" "One-folder integrity not confirmed"
$pre = Join-Path $Tools 'Bootstrap_Prereqs.ps1'; if(Test-Path $pre){ powershell -NoProfile -ExecutionPolicy Bypass -File $pre | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-prereq.ok')) "Prereqs validated" "Prereqs not validated"
$san = Join-Path $Tools 'Bootstrap_Sanity.ps1'; if(Test-Path $san){ powershell -NoProfile -ExecutionPolicy Bypass -File $san | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-bootstrap-sanity.ok')) "Bootstrap sanity OK" "Bootstrap sanity missing"

# 7) Install-log wrapper round-trip
$wrapOK = $false
$logWrap = Join-Path $Tools 'Run-Logged.ps1'
if(Test-Path $logWrap){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $logWrap -Cmd "cmd.exe" -Args "/c echo accept-test" | Out-Null
    $ilog = Join-Path $Base 'logs\install\install_log.txt'
    if(Test-Path $ilog){ $wrapOK = (Select-String -Path $ilog -Pattern '<< exit 0' -SimpleMatch) -ne $null }
  }catch{}
}
AddRes $wrapOK "Install-log wrapper captured exit 0" "Install-log wrapper test failed"

# 8) Version header present in some tool
$verOK = $false; $some = Get-ChildItem (Join-Path $Base 'tools') -Filter *.ps1 -File -ea SilentlyContinue | Select-Object -First 1
if($some){ $verOK = (ReadText $some.FullName) -match '^\s*#\s*Mason2-Version:' }
AddRes $verOK "Version stamp header detected" "Version stamp header not found"

# 9) Pack/Unpack (if present)
$packOK = $true
$pack = Join-Path $Tools 'Pack_Bundle.ps1'
$unpk = Join-Path $Tools 'Unpack_WithVerify.ps1'
if((Test-Path $pack) -and (Test-Path $unpk)){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
    $zip = Get-Item (Join-Path $Dist 'mason2-*.zip') -ea SilentlyContinue | Sort-Object LastWriteTime -desc | Select-Object -First 1
    if($zip){
      $tmp = Join-Path $Dist ("verify-" + [guid]::NewGuid().ToString("N"))
      powershell -NoProfile -ExecutionPolicy Bypass -File $unpk -Zip $zip.FullName -OutDir $tmp | Out-Null
      $packOK = Test-Path $tmp
      if($packOK){ Remove-Item $tmp -Recurse -Force -ea SilentlyContinue }
    }
  }catch{ $packOK = $false }
}
AddRes $packOK "Pack/Unpack OK (if present)" "Pack/Unpack script failed"

# 10) Dashboard launcher present
AddRes (Test-Path (Join-Path $Tools 'Start_DashboardWindow.ps1')) "Dashboard launcher present" "Dashboard launcher missing"

# Informational (not blockers)
try{
  $p = (Get-Content (Join-Path $Cfg 'policy.json') -Raw | ConvertFrom-Json)
  $need = 'high_risk_window','cmd_allowlist','file_scope_root','egress_denylist','operator_pin_hash'
  $polOK = ($need | Where-Object { $p.PSObject.Properties.Name -notcontains $_ }).Count -eq 0
  if($polOK){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Guardrails policy.json has required keys" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Guardrails policy.json incomplete" }
}catch{}
if(Test-Path (Join-Path $Cfg 'voice\voice.json')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Voice config present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Voice config missing" }
if(Test-Path (Join-Path $Rep 'compat_os.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Compatibility info present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Compatibility info missing" }
if(Test-Path (Join-Path $Base 'LICENSE.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© LICENSE present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ LICENSE missing" }
if(Test-Path (Join-Path $Base 'NOTICE.txt')){  $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© NOTICE present"  } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ NOTICE missing"  }
if(Test-Path (Join-Path $Base 'Uninstall_Mason2.ps1')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Uninstall script present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Uninstall script missing" }

# Write report
$okAll = ($Miss | ? { $_ -like "ÃƒÂ¢Ã‚ÂÃ…â€™*" }).Count -eq 0
$lines = @(
  "# Phase 1 Acceptance Report",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## Must-pass checks",
  ($MustPass -join "`r`n"),
  "",
  "## Present / scaffolds",
  ($Present -join "`r`n"),
  "",
  "## Gaps",
  ($Miss -join "`r`n"),
  ""
)
$lines | Set-Content $Report -Encoding UTF8

if($okAll){
  "ok" | Set-Content (Join-Path $Sig 'roadmap-phase-1-validated.ok') -Encoding ASCII
  Ok "Phase 1: ALL MUST-PASS CHECKS OK ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â validated."
  Ok ("Report -> " + $Report)
}else{
  Warn "Phase 1: some must-pass checks failed ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â see report for details."
  Warn ("Report -> " + $Report)
  exit 2
}

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([switch]$Fix)

function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function ReadText([string]$p){ if(Test-Path $p){ Get-Content $p -Raw } else { "" } }

$Base   = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools  = Join-Path $Base 'tools'
$Cfg    = Join-Path $Base 'config'
$Rep    = Join-Path $Base 'reports'
$Sig    = Join-Path $Rep  'signals'
$Logs   = Join-Path $Base 'logs'
$Tel    = Join-Path $Logs 'telemetry\heartbeat.log'
$Report = Join-Path $Rep 'phase1_acceptance_report.md'
$Dist   = Join-Path $Base 'dist'

ni $Sig  -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null

$MustPass = @()
$Present  = @()
$Miss     = @()

function Check-Task($name, [int]$maxAgeMin = 0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $csv) { $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if ($LASTEXITCODE -ne 0 -or -not $csv) { return @{ ok=$false; msg=('Task not found: {0}' -f $name) } }

  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)

  $lastRun = $null
  try { if($obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){ $lastRun = [datetime]::Parse($obj.'Last Run Time') } } catch {}

  if ($maxAgeMin -gt 0 -and $lastRun) {
    $mins = [int]([datetime]::Now - $lastRun).TotalMinutes
    if ($mins -gt $maxAgeMin) { return @{ ok=$false; msg=("{0} last run {1}m ago (> {2} m)" -f $name,$mins,$maxAgeMin) } }
  }

  $res = ($obj.'Last Result' + '').Trim()
  if ($maxAgeMin -eq 0) {
    # Presence-only: accept Success(0), Running(267009), NotYetRun(267011)
    if (@('0','267009','267011') -notcontains $res) { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  } else {
    if ($res -and $res -ne '0') { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  }
  return @{ ok=$true; msg=("$name present") }
}

function AddRes($cond,$passMsg,$failMsg,$must=$true){
  if($cond){ if($must){$script:MustPass += "ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ $passMsg"} else {$script:Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© $passMsg"} }
  else     { if($must){$script:Miss     += "ÃƒÂ¢Ã‚ÂÃ…â€™ $failMsg"} else {$script:Miss    += "ÃƒÂ¢Ã‚Â¬Ã…â€œ $failMsg"} }
}

# 1) Heartbeat freshness (<=2m)
$hbOk = $false
try{ if(Test-Path $Tel){ $hbOk = ([int]([datetime]::Now - (Get-Item $Tel).LastWriteTime).TotalMinutes) -le 2 } }catch{}
AddRes $hbOk "Heartbeat is fresh (<=2m)" "Heartbeat stale or missing"

# 2) Scheduler health (age-gated)
foreach($t in @(@{n="Mason2 Heartbeat";age=2}, @{n="Mason2 Watchdog";age=3}, @{n="Mason2 Governor";age=4})){
  $r = Check-Task $t.n $t.age; AddRes $r.ok "$($t.n) healthy" $r.msg
}

# 3) Other scheduled jobs present (presence-only)
foreach($n in @("Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance",
                "Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth",
                "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms",
                "Mason2 Dashboard")){
  $r = Check-Task $n 0; AddRes $r.ok "$n present" $r.msg
}

# 4) Env toggle agrees
$envTxt  = ReadText (Join-Path $Rep 'env.txt')
$envJson = ReadText (Join-Path $Cfg 'env.json')
$modeTxt = ($envTxt -replace '.*ENV=','').Trim()
$modeJson = ""; try{ if($envJson){ $modeJson = ((($envJson | ConvertFrom-Json).environment)+"").Trim() } }catch{}
AddRes ( ($modeTxt -ne "") -and ($modeTxt -eq $modeJson) ) "Env consistent: $modeTxt" "Env mismatch or missing"

# 5) Pricebook + Roadmap exist
$priceOK = (Test-Path (Join-Path $Rep 'price\total_cad.txt')) -and ( ((ReadText (Join-Path $Rep 'price\line_items.md')).Trim()) -ne "" )
AddRes $priceOK "Price/line items generated" "Price/line items missing"
$roadOK  = ( (ReadText (Join-Path $Rep 'roadmap_render.md')).Trim() -ne "" )
AddRes $roadOK "Roadmap render exists" "Roadmap render missing"

# 6) One-folder + prereqs + sanity
$vf = Join-Path $Tools 'Verify_OneFolder.ps1'; if(Test-Path $vf){ powershell -NoProfile -ExecutionPolicy Bypass -File $vf | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-onefolder.ok')) "One-folder integrity OK" "One-folder integrity not confirmed"
$pre = Join-Path $Tools 'Bootstrap_Prereqs.ps1'; if(Test-Path $pre){ powershell -NoProfile -ExecutionPolicy Bypass -File $pre | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-prereq.ok')) "Prereqs validated" "Prereqs not validated"
$san = Join-Path $Tools 'Bootstrap_Sanity.ps1'; if(Test-Path $san){ powershell -NoProfile -ExecutionPolicy Bypass -File $san | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-bootstrap-sanity.ok')) "Bootstrap sanity OK" "Bootstrap sanity missing"

# 7) Install-log wrapper round-trip
$wrapOK = $false
$logWrap = Join-Path $Tools 'Run-Logged.ps1'
if(Test-Path $logWrap){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $logWrap -Cmd "cmd.exe" -Args "/c echo accept-test" | Out-Null
    $ilog = Join-Path $Base 'logs\install\install_log.txt'
    if(Test-Path $ilog){ $wrapOK = (Select-String -Path $ilog -Pattern '<< exit 0' -SimpleMatch) -ne $null }
  }catch{}
}
AddRes $wrapOK "Install-log wrapper captured exit 0" "Install-log wrapper test failed"

# 8) Version header present in some tool
$verOK = $false; $some = Get-ChildItem (Join-Path $Base 'tools') -Filter *.ps1 -File -ea SilentlyContinue | Select-Object -First 1
if($some){ $verOK = (ReadText $some.FullName) -match '^\s*#\s*Mason2-Version:' }
AddRes $verOK "Version stamp header detected" "Version stamp header not found"

# 9) Pack/Unpack (if present)
$packOK = $true
$pack = Join-Path $Tools 'Pack_Bundle.ps1'
$unpk = Join-Path $Tools 'Unpack_WithVerify.ps1'
if((Test-Path $pack) -and (Test-Path $unpk)){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
    $zip = Get-Item (Join-Path $Dist 'mason2-*.zip') -ea SilentlyContinue | Sort-Object LastWriteTime -desc | Select-Object -First 1
    if($zip){
      $tmp = Join-Path $Dist ("verify-" + [guid]::NewGuid().ToString("N"))
      powershell -NoProfile -ExecutionPolicy Bypass -File $unpk -Zip $zip.FullName -OutDir $tmp | Out-Null
      $packOK = Test-Path $tmp
      if($packOK){ Remove-Item $tmp -Recurse -Force -ea SilentlyContinue }
    }
  }catch{ $packOK = $false }
}
AddRes $packOK "Pack/Unpack OK (if present)" "Pack/Unpack script failed"

# 10) Dashboard launcher present
AddRes (Test-Path (Join-Path $Tools 'Start_DashboardWindow.ps1')) "Dashboard launcher present" "Dashboard launcher missing"

# Informational (not blockers)
try{
  $p = (Get-Content (Join-Path $Cfg 'policy.json') -Raw | ConvertFrom-Json)
  $need = 'high_risk_window','cmd_allowlist','file_scope_root','egress_denylist','operator_pin_hash'
  $polOK = ($need | Where-Object { $p.PSObject.Properties.Name -notcontains $_ }).Count -eq 0
  if($polOK){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Guardrails policy.json has required keys" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Guardrails policy.json incomplete" }
}catch{}
if(Test-Path (Join-Path $Cfg 'voice\voice.json')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Voice config present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Voice config missing" }
if(Test-Path (Join-Path $Rep 'compat_os.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Compatibility info present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Compatibility info missing" }
if(Test-Path (Join-Path $Base 'LICENSE.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© LICENSE present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ LICENSE missing" }
if(Test-Path (Join-Path $Base 'NOTICE.txt')){  $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© NOTICE present"  } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ NOTICE missing"  }
if(Test-Path (Join-Path $Base 'Uninstall_Mason2.ps1')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Uninstall script present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Uninstall script missing" }

# Write report
$okAll = ($Miss | ? { $_ -like "ÃƒÂ¢Ã‚ÂÃ…â€™*" }).Count -eq 0
$lines = @(
  "# Phase 1 Acceptance Report",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## Must-pass checks",
  ($MustPass -join "`r`n"),
  "",
  "## Present / scaffolds",
  ($Present -join "`r`n"),
  "",
  "## Gaps",
  ($Miss -join "`r`n"),
  ""
)
$lines | Set-Content $Report -Encoding UTF8

if($okAll){
  "ok" | Set-Content (Join-Path $Sig 'roadmap-phase-1-validated.ok') -Encoding ASCII
  Ok "Phase 1: ALL MUST-PASS CHECKS OK ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â validated."
  Ok ("Report -> " + $Report)
}else{
  Warn "Phase 1: some must-pass checks failed ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â see report for details."
  Warn ("Report -> " + $Report)
  exit 2
}

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([switch]$Fix)

function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function ReadText([string]$p){ if(Test-Path $p){ Get-Content $p -Raw } else { "" } }

$Base   = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools  = Join-Path $Base 'tools'
$Cfg    = Join-Path $Base 'config'
$Rep    = Join-Path $Base 'reports'
$Sig    = Join-Path $Rep  'signals'
$Logs   = Join-Path $Base 'logs'
$Tel    = Join-Path $Logs 'telemetry\heartbeat.log'
$Report = Join-Path $Rep 'phase1_acceptance_report.md'
$Dist   = Join-Path $Base 'dist'

ni $Sig  -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null

$MustPass = @()
$Present  = @()
$Miss     = @()

function Check-Task($name, [int]$maxAgeMin = 0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $csv) { $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if ($LASTEXITCODE -ne 0 -or -not $csv) { return @{ ok=$false; msg=('Task not found: {0}' -f $name) } }

  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)

  $lastRun = $null
  try { if($obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){ $lastRun = [datetime]::Parse($obj.'Last Run Time') } } catch {}

  if ($maxAgeMin -gt 0 -and $lastRun) {
    $mins = [int]([datetime]::Now - $lastRun).TotalMinutes
    if ($mins -gt $maxAgeMin) { return @{ ok=$false; msg=("{0} last run {1}m ago (> {2} m)" -f $name,$mins,$maxAgeMin) } }
  }

  $res = ($obj.'Last Result' + '').Trim()
  if ($maxAgeMin -eq 0) {
    # Presence-only: accept Success(0), Running(267009), NotYetRun(267011)
    if (@('0','267009','267011') -notcontains $res) { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  } else {
    if ($res -and $res -ne '0') { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  }
  return @{ ok=$true; msg=("$name present") }
}

function AddRes($cond,$passMsg,$failMsg,$must=$true){
  if($cond){ if($must){$script:MustPass += "ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ $passMsg"} else {$script:Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© $passMsg"} }
  else     { if($must){$script:Miss     += "ÃƒÂ¢Ã‚ÂÃ…â€™ $failMsg"} else {$script:Miss    += "ÃƒÂ¢Ã‚Â¬Ã…â€œ $failMsg"} }
}

# 1) Heartbeat freshness (<=2m)
$hbOk = $false
try{ if(Test-Path $Tel){ $hbOk = ([int]([datetime]::Now - (Get-Item $Tel).LastWriteTime).TotalMinutes) -le 2 } }catch{}
AddRes $hbOk "Heartbeat is fresh (<=2m)" "Heartbeat stale or missing"

# 2) Scheduler health (age-gated)
foreach($t in @(@{n="Mason2 Heartbeat";age=2}, @{n="Mason2 Watchdog";age=3}, @{n="Mason2 Governor";age=4})){
  $r = Check-Task $t.n $t.age; AddRes $r.ok "$($t.n) healthy" $r.msg
}

# 3) Other scheduled jobs present (presence-only)
foreach($n in @("Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance",
                "Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth",
                "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms",
                "Mason2 Dashboard")){
  $r = Check-Task $n 0; AddRes $r.ok "$n present" $r.msg
}

# 4) Env toggle agrees
$envTxt  = ReadText (Join-Path $Rep 'env.txt')
$envJson = ReadText (Join-Path $Cfg 'env.json')
$modeTxt = ($envTxt -replace '.*ENV=','').Trim()
$modeJson = ""; try{ if($envJson){ $modeJson = ((($envJson | ConvertFrom-Json).environment)+"").Trim() } }catch{}
AddRes ( ($modeTxt -ne "") -and ($modeTxt -eq $modeJson) ) "Env consistent: $modeTxt" "Env mismatch or missing"

# 5) Pricebook + Roadmap exist
$priceOK = (Test-Path (Join-Path $Rep 'price\total_cad.txt')) -and ( ((ReadText (Join-Path $Rep 'price\line_items.md')).Trim()) -ne "" )
AddRes $priceOK "Price/line items generated" "Price/line items missing"
$roadOK  = ( (ReadText (Join-Path $Rep 'roadmap_render.md')).Trim() -ne "" )
AddRes $roadOK "Roadmap render exists" "Roadmap render missing"

# 6) One-folder + prereqs + sanity
$vf = Join-Path $Tools 'Verify_OneFolder.ps1'; if(Test-Path $vf){ powershell -NoProfile -ExecutionPolicy Bypass -File $vf | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-onefolder.ok')) "One-folder integrity OK" "One-folder integrity not confirmed"
$pre = Join-Path $Tools 'Bootstrap_Prereqs.ps1'; if(Test-Path $pre){ powershell -NoProfile -ExecutionPolicy Bypass -File $pre | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-prereq.ok')) "Prereqs validated" "Prereqs not validated"
$san = Join-Path $Tools 'Bootstrap_Sanity.ps1'; if(Test-Path $san){ powershell -NoProfile -ExecutionPolicy Bypass -File $san | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-bootstrap-sanity.ok')) "Bootstrap sanity OK" "Bootstrap sanity missing"

# 7) Install-log wrapper round-trip
$wrapOK = $false
$logWrap = Join-Path $Tools 'Run-Logged.ps1'
if(Test-Path $logWrap){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $logWrap -Cmd "cmd.exe" -Args "/c echo accept-test" | Out-Null
    $ilog = Join-Path $Base 'logs\install\install_log.txt'
    if(Test-Path $ilog){ $wrapOK = (Select-String -Path $ilog -Pattern '<< exit 0' -SimpleMatch) -ne $null }
  }catch{}
}
AddRes $wrapOK "Install-log wrapper captured exit 0" "Install-log wrapper test failed"

# 8) Version header present in some tool
$verOK = $false; $some = Get-ChildItem (Join-Path $Base 'tools') -Filter *.ps1 -File -ea SilentlyContinue | Select-Object -First 1
if($some){ $verOK = (ReadText $some.FullName) -match '^\s*#\s*Mason2-Version:' }
AddRes $verOK "Version stamp header detected" "Version stamp header not found"

# 9) Pack/Unpack (if present)
$packOK = $true
$pack = Join-Path $Tools 'Pack_Bundle.ps1'
$unpk = Join-Path $Tools 'Unpack_WithVerify.ps1'
if((Test-Path $pack) -and (Test-Path $unpk)){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
    $zip = Get-Item (Join-Path $Dist 'mason2-*.zip') -ea SilentlyContinue | Sort-Object LastWriteTime -desc | Select-Object -First 1
    if($zip){
      $tmp = Join-Path $Dist ("verify-" + [guid]::NewGuid().ToString("N"))
      powershell -NoProfile -ExecutionPolicy Bypass -File $unpk -Zip $zip.FullName -OutDir $tmp | Out-Null
      $packOK = Test-Path $tmp
      if($packOK){ Remove-Item $tmp -Recurse -Force -ea SilentlyContinue }
    }
  }catch{ $packOK = $false }
}
AddRes $packOK "Pack/Unpack OK (if present)" "Pack/Unpack script failed"

# 10) Dashboard launcher present
AddRes (Test-Path (Join-Path $Tools 'Start_DashboardWindow.ps1')) "Dashboard launcher present" "Dashboard launcher missing"

# Informational (not blockers)
try{
  $p = (Get-Content (Join-Path $Cfg 'policy.json') -Raw | ConvertFrom-Json)
  $need = 'high_risk_window','cmd_allowlist','file_scope_root','egress_denylist','operator_pin_hash'
  $polOK = ($need | Where-Object { $p.PSObject.Properties.Name -notcontains $_ }).Count -eq 0
  if($polOK){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Guardrails policy.json has required keys" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Guardrails policy.json incomplete" }
}catch{}
if(Test-Path (Join-Path $Cfg 'voice\voice.json')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Voice config present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Voice config missing" }
if(Test-Path (Join-Path $Rep 'compat_os.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Compatibility info present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Compatibility info missing" }
if(Test-Path (Join-Path $Base 'LICENSE.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© LICENSE present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ LICENSE missing" }
if(Test-Path (Join-Path $Base 'NOTICE.txt')){  $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© NOTICE present"  } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ NOTICE missing"  }
if(Test-Path (Join-Path $Base 'Uninstall_Mason2.ps1')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Uninstall script present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Uninstall script missing" }

# Write report
$okAll = ($Miss | ? { $_ -like "ÃƒÂ¢Ã‚ÂÃ…â€™*" }).Count -eq 0
$lines = @(
  "# Phase 1 Acceptance Report",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## Must-pass checks",
  ($MustPass -join "`r`n"),
  "",
  "## Present / scaffolds",
  ($Present -join "`r`n"),
  "",
  "## Gaps",
  ($Miss -join "`r`n"),
  ""
)
$lines | Set-Content $Report -Encoding UTF8

if($okAll){
  "ok" | Set-Content (Join-Path $Sig 'roadmap-phase-1-validated.ok') -Encoding ASCII
  Ok "Phase 1: ALL MUST-PASS CHECKS OK ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â validated."
  Ok ("Report -> " + $Report)
}else{
  Warn "Phase 1: some must-pass checks failed ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â see report for details."
  Warn ("Report -> " + $Report)
  exit 2
}

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([switch]$Fix)

function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function ReadText([string]$p){ if(Test-Path $p){ Get-Content $p -Raw } else { "" } }

$Base   = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools  = Join-Path $Base 'tools'
$Cfg    = Join-Path $Base 'config'
$Rep    = Join-Path $Base 'reports'
$Sig    = Join-Path $Rep  'signals'
$Logs   = Join-Path $Base 'logs'
$Tel    = Join-Path $Logs 'telemetry\heartbeat.log'
$Report = Join-Path $Rep 'phase1_acceptance_report.md'
$Dist   = Join-Path $Base 'dist'

ni $Sig  -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null

$MustPass = @()
$Present  = @()
$Miss     = @()

function Check-Task($name, [int]$maxAgeMin = 0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $csv) { $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if ($LASTEXITCODE -ne 0 -or -not $csv) { return @{ ok=$false; msg=('Task not found: {0}' -f $name) } }

  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)

  $lastRun = $null
  try { if($obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){ $lastRun = [datetime]::Parse($obj.'Last Run Time') } } catch {}

  if ($maxAgeMin -gt 0 -and $lastRun) {
    $mins = [int]([datetime]::Now - $lastRun).TotalMinutes
    if ($mins -gt $maxAgeMin) { return @{ ok=$false; msg=("{0} last run {1}m ago (> {2} m)" -f $name,$mins,$maxAgeMin) } }
  }

  $res = ($obj.'Last Result' + '').Trim()
  if ($maxAgeMin -eq 0) {
    # Presence-only: accept Success(0), Running(267009), NotYetRun(267011)
    if (@('0','267009','267011') -notcontains $res) { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  } else {
    if ($res -and $res -ne '0') { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  }
  return @{ ok=$true; msg=("$name present") }
}

function AddRes($cond,$passMsg,$failMsg,$must=$true){
  if($cond){ if($must){$script:MustPass += "ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ $passMsg"} else {$script:Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© $passMsg"} }
  else     { if($must){$script:Miss     += "ÃƒÂ¢Ã‚ÂÃ…â€™ $failMsg"} else {$script:Miss    += "ÃƒÂ¢Ã‚Â¬Ã…â€œ $failMsg"} }
}

# 1) Heartbeat freshness (<=2m)
$hbOk = $false
try{ if(Test-Path $Tel){ $hbOk = ([int]([datetime]::Now - (Get-Item $Tel).LastWriteTime).TotalMinutes) -le 2 } }catch{}
AddRes $hbOk "Heartbeat is fresh (<=2m)" "Heartbeat stale or missing"

# 2) Scheduler health (age-gated)
foreach($t in @(@{n="Mason2 Heartbeat";age=2}, @{n="Mason2 Watchdog";age=3}, @{n="Mason2 Governor";age=4})){
  $r = Check-Task $t.n $t.age; AddRes $r.ok "$($t.n) healthy" $r.msg
}

# 3) Other scheduled jobs present (presence-only)
foreach($n in @("Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance",
                "Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth",
                "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms",
                "Mason2 Dashboard")){
  $r = Check-Task $n 0; AddRes $r.ok "$n present" $r.msg
}

# 4) Env toggle agrees
$envTxt  = ReadText (Join-Path $Rep 'env.txt')
$envJson = ReadText (Join-Path $Cfg 'env.json')
$modeTxt = ($envTxt -replace '.*ENV=','').Trim()
$modeJson = ""; try{ if($envJson){ $modeJson = ((($envJson | ConvertFrom-Json).environment)+"").Trim() } }catch{}
AddRes ( ($modeTxt -ne "") -and ($modeTxt -eq $modeJson) ) "Env consistent: $modeTxt" "Env mismatch or missing"

# 5) Pricebook + Roadmap exist
$priceOK = (Test-Path (Join-Path $Rep 'price\total_cad.txt')) -and ( ((ReadText (Join-Path $Rep 'price\line_items.md')).Trim()) -ne "" )
AddRes $priceOK "Price/line items generated" "Price/line items missing"
$roadOK  = ( (ReadText (Join-Path $Rep 'roadmap_render.md')).Trim() -ne "" )
AddRes $roadOK "Roadmap render exists" "Roadmap render missing"

# 6) One-folder + prereqs + sanity
$vf = Join-Path $Tools 'Verify_OneFolder.ps1'; if(Test-Path $vf){ powershell -NoProfile -ExecutionPolicy Bypass -File $vf | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-onefolder.ok')) "One-folder integrity OK" "One-folder integrity not confirmed"
$pre = Join-Path $Tools 'Bootstrap_Prereqs.ps1'; if(Test-Path $pre){ powershell -NoProfile -ExecutionPolicy Bypass -File $pre | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-prereq.ok')) "Prereqs validated" "Prereqs not validated"
$san = Join-Path $Tools 'Bootstrap_Sanity.ps1'; if(Test-Path $san){ powershell -NoProfile -ExecutionPolicy Bypass -File $san | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-bootstrap-sanity.ok')) "Bootstrap sanity OK" "Bootstrap sanity missing"

# 7) Install-log wrapper round-trip
$wrapOK = $false
$logWrap = Join-Path $Tools 'Run-Logged.ps1'
if(Test-Path $logWrap){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $logWrap -Cmd "cmd.exe" -Args "/c echo accept-test" | Out-Null
    $ilog = Join-Path $Base 'logs\install\install_log.txt'
    if(Test-Path $ilog){ $wrapOK = (Select-String -Path $ilog -Pattern '<< exit 0' -SimpleMatch) -ne $null }
  }catch{}
}
AddRes $wrapOK "Install-log wrapper captured exit 0" "Install-log wrapper test failed"

# 8) Version header present in some tool
$verOK = $false; $some = Get-ChildItem (Join-Path $Base 'tools') -Filter *.ps1 -File -ea SilentlyContinue | Select-Object -First 1
if($some){ $verOK = (ReadText $some.FullName) -match '^\s*#\s*Mason2-Version:' }
AddRes $verOK "Version stamp header detected" "Version stamp header not found"

# 9) Pack/Unpack (if present)
$packOK = $true
$pack = Join-Path $Tools 'Pack_Bundle.ps1'
$unpk = Join-Path $Tools 'Unpack_WithVerify.ps1'
if((Test-Path $pack) -and (Test-Path $unpk)){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
    $zip = Get-Item (Join-Path $Dist 'mason2-*.zip') -ea SilentlyContinue | Sort-Object LastWriteTime -desc | Select-Object -First 1
    if($zip){
      $tmp = Join-Path $Dist ("verify-" + [guid]::NewGuid().ToString("N"))
      powershell -NoProfile -ExecutionPolicy Bypass -File $unpk -Zip $zip.FullName -OutDir $tmp | Out-Null
      $packOK = Test-Path $tmp
      if($packOK){ Remove-Item $tmp -Recurse -Force -ea SilentlyContinue }
    }
  }catch{ $packOK = $false }
}
AddRes $packOK "Pack/Unpack OK (if present)" "Pack/Unpack script failed"

# 10) Dashboard launcher present
AddRes (Test-Path (Join-Path $Tools 'Start_DashboardWindow.ps1')) "Dashboard launcher present" "Dashboard launcher missing"

# Informational (not blockers)
try{
  $p = (Get-Content (Join-Path $Cfg 'policy.json') -Raw | ConvertFrom-Json)
  $need = 'high_risk_window','cmd_allowlist','file_scope_root','egress_denylist','operator_pin_hash'
  $polOK = ($need | Where-Object { $p.PSObject.Properties.Name -notcontains $_ }).Count -eq 0
  if($polOK){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Guardrails policy.json has required keys" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Guardrails policy.json incomplete" }
}catch{}
if(Test-Path (Join-Path $Cfg 'voice\voice.json')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Voice config present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Voice config missing" }
if(Test-Path (Join-Path $Rep 'compat_os.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Compatibility info present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Compatibility info missing" }
if(Test-Path (Join-Path $Base 'LICENSE.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© LICENSE present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ LICENSE missing" }
if(Test-Path (Join-Path $Base 'NOTICE.txt')){  $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© NOTICE present"  } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ NOTICE missing"  }
if(Test-Path (Join-Path $Base 'Uninstall_Mason2.ps1')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Uninstall script present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Uninstall script missing" }

# Write report
$okAll = ($Miss | ? { $_ -like "ÃƒÂ¢Ã‚ÂÃ…â€™*" }).Count -eq 0
$lines = @(
  "# Phase 1 Acceptance Report",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## Must-pass checks",
  ($MustPass -join "`r`n"),
  "",
  "## Present / scaffolds",
  ($Present -join "`r`n"),
  "",
  "## Gaps",
  ($Miss -join "`r`n"),
  ""
)
$lines | Set-Content $Report -Encoding UTF8

if($okAll){
  "ok" | Set-Content (Join-Path $Sig 'roadmap-phase-1-validated.ok') -Encoding ASCII
  Ok "Phase 1: ALL MUST-PASS CHECKS OK ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â validated."
  Ok ("Report -> " + $Report)
}else{
  Warn "Phase 1: some must-pass checks failed ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â see report for details."
  Warn ("Report -> " + $Report)
  exit 2
}

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([switch]$Fix)

function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function ReadText([string]$p){ if(Test-Path $p){ Get-Content $p -Raw } else { "" } }

$Base   = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools  = Join-Path $Base 'tools'
$Cfg    = Join-Path $Base 'config'
$Rep    = Join-Path $Base 'reports'
$Sig    = Join-Path $Rep  'signals'
$Logs   = Join-Path $Base 'logs'
$Tel    = Join-Path $Logs 'telemetry\heartbeat.log'
$Report = Join-Path $Rep 'phase1_acceptance_report.md'
$Dist   = Join-Path $Base 'dist'

ni $Sig  -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null

$MustPass = @()
$Present  = @()
$Miss     = @()

function Check-Task($name, [int]$maxAgeMin = 0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $csv) { $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if ($LASTEXITCODE -ne 0 -or -not $csv) { return @{ ok=$false; msg=('Task not found: {0}' -f $name) } }

  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)

  $lastRun = $null
  try { if($obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){ $lastRun = [datetime]::Parse($obj.'Last Run Time') } } catch {}

  if ($maxAgeMin -gt 0 -and $lastRun) {
    $mins = [int]([datetime]::Now - $lastRun).TotalMinutes
    if ($mins -gt $maxAgeMin) { return @{ ok=$false; msg=("{0} last run {1}m ago (> {2} m)" -f $name,$mins,$maxAgeMin) } }
  }

  $res = ($obj.'Last Result' + '').Trim()
  if ($maxAgeMin -eq 0) {
    # Presence-only: accept Success(0), Running(267009), NotYetRun(267011)
    if (@('0','267009','267011') -notcontains $res) { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  } else {
    if ($res -and $res -ne '0') { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  }
  return @{ ok=$true; msg=("$name present") }
}

function AddRes($cond,$passMsg,$failMsg,$must=$true){
  if($cond){ if($must){$script:MustPass += "ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ $passMsg"} else {$script:Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© $passMsg"} }
  else     { if($must){$script:Miss     += "ÃƒÂ¢Ã‚ÂÃ…â€™ $failMsg"} else {$script:Miss    += "ÃƒÂ¢Ã‚Â¬Ã…â€œ $failMsg"} }
}

# 1) Heartbeat freshness (<=2m)
$hbOk = $false
try{ if(Test-Path $Tel){ $hbOk = ([int]([datetime]::Now - (Get-Item $Tel).LastWriteTime).TotalMinutes) -le 2 } }catch{}
AddRes $hbOk "Heartbeat is fresh (<=2m)" "Heartbeat stale or missing"

# 2) Scheduler health (age-gated)
foreach($t in @(@{n="Mason2 Heartbeat";age=2}, @{n="Mason2 Watchdog";age=3}, @{n="Mason2 Governor";age=4})){
  $r = Check-Task $t.n $t.age; AddRes $r.ok "$($t.n) healthy" $r.msg
}

# 3) Other scheduled jobs present (presence-only)
foreach($n in @("Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance",
                "Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth",
                "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms",
                "Mason2 Dashboard")){
  $r = Check-Task $n 0; AddRes $r.ok "$n present" $r.msg
}

# 4) Env toggle agrees
$envTxt  = ReadText (Join-Path $Rep 'env.txt')
$envJson = ReadText (Join-Path $Cfg 'env.json')
$modeTxt = ($envTxt -replace '.*ENV=','').Trim()
$modeJson = ""; try{ if($envJson){ $modeJson = ((($envJson | ConvertFrom-Json).environment)+"").Trim() } }catch{}
AddRes ( ($modeTxt -ne "") -and ($modeTxt -eq $modeJson) ) "Env consistent: $modeTxt" "Env mismatch or missing"

# 5) Pricebook + Roadmap exist
$priceOK = (Test-Path (Join-Path $Rep 'price\total_cad.txt')) -and ( ((ReadText (Join-Path $Rep 'price\line_items.md')).Trim()) -ne "" )
AddRes $priceOK "Price/line items generated" "Price/line items missing"
$roadOK  = ( (ReadText (Join-Path $Rep 'roadmap_render.md')).Trim() -ne "" )
AddRes $roadOK "Roadmap render exists" "Roadmap render missing"

# 6) One-folder + prereqs + sanity
$vf = Join-Path $Tools 'Verify_OneFolder.ps1'; if(Test-Path $vf){ powershell -NoProfile -ExecutionPolicy Bypass -File $vf | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-onefolder.ok')) "One-folder integrity OK" "One-folder integrity not confirmed"
$pre = Join-Path $Tools 'Bootstrap_Prereqs.ps1'; if(Test-Path $pre){ powershell -NoProfile -ExecutionPolicy Bypass -File $pre | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-prereq.ok')) "Prereqs validated" "Prereqs not validated"
$san = Join-Path $Tools 'Bootstrap_Sanity.ps1'; if(Test-Path $san){ powershell -NoProfile -ExecutionPolicy Bypass -File $san | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-bootstrap-sanity.ok')) "Bootstrap sanity OK" "Bootstrap sanity missing"

# 7) Install-log wrapper round-trip
$wrapOK = $false
$logWrap = Join-Path $Tools 'Run-Logged.ps1'
if(Test-Path $logWrap){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $logWrap -Cmd "cmd.exe" -Args "/c echo accept-test" | Out-Null
    $ilog = Join-Path $Base 'logs\install\install_log.txt'
    if(Test-Path $ilog){ $wrapOK = (Select-String -Path $ilog -Pattern '<< exit 0' -SimpleMatch) -ne $null }
  }catch{}
}
AddRes $wrapOK "Install-log wrapper captured exit 0" "Install-log wrapper test failed"

# 8) Version header present in some tool
$verOK = $false; $some = Get-ChildItem (Join-Path $Base 'tools') -Filter *.ps1 -File -ea SilentlyContinue | Select-Object -First 1
if($some){ $verOK = (ReadText $some.FullName) -match '^\s*#\s*Mason2-Version:' }
AddRes $verOK "Version stamp header detected" "Version stamp header not found"

# 9) Pack/Unpack (if present)
$packOK = $true
$pack = Join-Path $Tools 'Pack_Bundle.ps1'
$unpk = Join-Path $Tools 'Unpack_WithVerify.ps1'
if((Test-Path $pack) -and (Test-Path $unpk)){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
    $zip = Get-Item (Join-Path $Dist 'mason2-*.zip') -ea SilentlyContinue | Sort-Object LastWriteTime -desc | Select-Object -First 1
    if($zip){
      $tmp = Join-Path $Dist ("verify-" + [guid]::NewGuid().ToString("N"))
      powershell -NoProfile -ExecutionPolicy Bypass -File $unpk -Zip $zip.FullName -OutDir $tmp | Out-Null
      $packOK = Test-Path $tmp
      if($packOK){ Remove-Item $tmp -Recurse -Force -ea SilentlyContinue }
    }
  }catch{ $packOK = $false }
}
AddRes $packOK "Pack/Unpack OK (if present)" "Pack/Unpack script failed"

# 10) Dashboard launcher present
AddRes (Test-Path (Join-Path $Tools 'Start_DashboardWindow.ps1')) "Dashboard launcher present" "Dashboard launcher missing"

# Informational (not blockers)
try{
  $p = (Get-Content (Join-Path $Cfg 'policy.json') -Raw | ConvertFrom-Json)
  $need = 'high_risk_window','cmd_allowlist','file_scope_root','egress_denylist','operator_pin_hash'
  $polOK = ($need | Where-Object { $p.PSObject.Properties.Name -notcontains $_ }).Count -eq 0
  if($polOK){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Guardrails policy.json has required keys" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Guardrails policy.json incomplete" }
}catch{}
if(Test-Path (Join-Path $Cfg 'voice\voice.json')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Voice config present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Voice config missing" }
if(Test-Path (Join-Path $Rep 'compat_os.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Compatibility info present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Compatibility info missing" }
if(Test-Path (Join-Path $Base 'LICENSE.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© LICENSE present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ LICENSE missing" }
if(Test-Path (Join-Path $Base 'NOTICE.txt')){  $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© NOTICE present"  } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ NOTICE missing"  }
if(Test-Path (Join-Path $Base 'Uninstall_Mason2.ps1')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Uninstall script present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Uninstall script missing" }

# Write report
$okAll = ($Miss | ? { $_ -like "ÃƒÂ¢Ã‚ÂÃ…â€™*" }).Count -eq 0
$lines = @(
  "# Phase 1 Acceptance Report",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## Must-pass checks",
  ($MustPass -join "`r`n"),
  "",
  "## Present / scaffolds",
  ($Present -join "`r`n"),
  "",
  "## Gaps",
  ($Miss -join "`r`n"),
  ""
)
$lines | Set-Content $Report -Encoding UTF8

if($okAll){
  "ok" | Set-Content (Join-Path $Sig 'roadmap-phase-1-validated.ok') -Encoding ASCII
  Ok "Phase 1: ALL MUST-PASS CHECKS OK ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â validated."
  Ok ("Report -> " + $Report)
}else{
  Warn "Phase 1: some must-pass checks failed ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â see report for details."
  Warn ("Report -> " + $Report)
  exit 2
}

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([switch]$Fix)

function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function ReadText([string]$p){ if(Test-Path $p){ Get-Content $p -Raw } else { "" } }

$Base   = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools  = Join-Path $Base 'tools'
$Cfg    = Join-Path $Base 'config'
$Rep    = Join-Path $Base 'reports'
$Sig    = Join-Path $Rep  'signals'
$Logs   = Join-Path $Base 'logs'
$Tel    = Join-Path $Logs 'telemetry\heartbeat.log'
$Report = Join-Path $Rep 'phase1_acceptance_report.md'
$Dist   = Join-Path $Base 'dist'

ni $Sig  -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null

$MustPass = @()
$Present  = @()
$Miss     = @()

function Check-Task($name, [int]$maxAgeMin = 0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $csv) { $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if ($LASTEXITCODE -ne 0 -or -not $csv) { return @{ ok=$false; msg=('Task not found: {0}' -f $name) } }

  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)

  $lastRun = $null
  try { if($obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){ $lastRun = [datetime]::Parse($obj.'Last Run Time') } } catch {}

  if ($maxAgeMin -gt 0 -and $lastRun) {
    $mins = [int]([datetime]::Now - $lastRun).TotalMinutes
    if ($mins -gt $maxAgeMin) { return @{ ok=$false; msg=("{0} last run {1}m ago (> {2} m)" -f $name,$mins,$maxAgeMin) } }
  }

  $res = ($obj.'Last Result' + '').Trim()
  if ($maxAgeMin -eq 0) {
    # Presence-only: accept Success(0), Running(267009), NotYetRun(267011)
    if (@('0','267009','267011') -notcontains $res) { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  } else {
    if ($res -and $res -ne '0') { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  }
  return @{ ok=$true; msg=("$name present") }
}

function AddRes($cond,$passMsg,$failMsg,$must=$true){
  if($cond){ if($must){$script:MustPass += "ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ $passMsg"} else {$script:Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© $passMsg"} }
  else     { if($must){$script:Miss     += "ÃƒÂ¢Ã‚ÂÃ…â€™ $failMsg"} else {$script:Miss    += "ÃƒÂ¢Ã‚Â¬Ã…â€œ $failMsg"} }
}

# 1) Heartbeat freshness (<=2m)
$hbOk = $false
try{ if(Test-Path $Tel){ $hbOk = ([int]([datetime]::Now - (Get-Item $Tel).LastWriteTime).TotalMinutes) -le 2 } }catch{}
AddRes $hbOk "Heartbeat is fresh (<=2m)" "Heartbeat stale or missing"

# 2) Scheduler health (age-gated)
foreach($t in @(@{n="Mason2 Heartbeat";age=2}, @{n="Mason2 Watchdog";age=3}, @{n="Mason2 Governor";age=4})){
  $r = Check-Task $t.n $t.age; AddRes $r.ok "$($t.n) healthy" $r.msg
}

# 3) Other scheduled jobs present (presence-only)
foreach($n in @("Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance",
                "Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth",
                "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms",
                "Mason2 Dashboard")){
  $r = Check-Task $n 0; AddRes $r.ok "$n present" $r.msg
}

# 4) Env toggle agrees
$envTxt  = ReadText (Join-Path $Rep 'env.txt')
$envJson = ReadText (Join-Path $Cfg 'env.json')
$modeTxt = ($envTxt -replace '.*ENV=','').Trim()
$modeJson = ""; try{ if($envJson){ $modeJson = ((($envJson | ConvertFrom-Json).environment)+"").Trim() } }catch{}
AddRes ( ($modeTxt -ne "") -and ($modeTxt -eq $modeJson) ) "Env consistent: $modeTxt" "Env mismatch or missing"

# 5) Pricebook + Roadmap exist
$priceOK = (Test-Path (Join-Path $Rep 'price\total_cad.txt')) -and ( ((ReadText (Join-Path $Rep 'price\line_items.md')).Trim()) -ne "" )
AddRes $priceOK "Price/line items generated" "Price/line items missing"
$roadOK  = ( (ReadText (Join-Path $Rep 'roadmap_render.md')).Trim() -ne "" )
AddRes $roadOK "Roadmap render exists" "Roadmap render missing"

# 6) One-folder + prereqs + sanity
$vf = Join-Path $Tools 'Verify_OneFolder.ps1'; if(Test-Path $vf){ powershell -NoProfile -ExecutionPolicy Bypass -File $vf | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-onefolder.ok')) "One-folder integrity OK" "One-folder integrity not confirmed"
$pre = Join-Path $Tools 'Bootstrap_Prereqs.ps1'; if(Test-Path $pre){ powershell -NoProfile -ExecutionPolicy Bypass -File $pre | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-prereq.ok')) "Prereqs validated" "Prereqs not validated"
$san = Join-Path $Tools 'Bootstrap_Sanity.ps1'; if(Test-Path $san){ powershell -NoProfile -ExecutionPolicy Bypass -File $san | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-bootstrap-sanity.ok')) "Bootstrap sanity OK" "Bootstrap sanity missing"

# 7) Install-log wrapper round-trip
$wrapOK = $false
$logWrap = Join-Path $Tools 'Run-Logged.ps1'
if(Test-Path $logWrap){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $logWrap -Cmd "cmd.exe" -Args "/c echo accept-test" | Out-Null
    $ilog = Join-Path $Base 'logs\install\install_log.txt'
    if(Test-Path $ilog){ $wrapOK = (Select-String -Path $ilog -Pattern '<< exit 0' -SimpleMatch) -ne $null }
  }catch{}
}
AddRes $wrapOK "Install-log wrapper captured exit 0" "Install-log wrapper test failed"

# 8) Version header present in some tool
$verOK = $false; $some = Get-ChildItem (Join-Path $Base 'tools') -Filter *.ps1 -File -ea SilentlyContinue | Select-Object -First 1
if($some){ $verOK = (ReadText $some.FullName) -match '^\s*#\s*Mason2-Version:' }
AddRes $verOK "Version stamp header detected" "Version stamp header not found"

# 9) Pack/Unpack (if present)
$packOK = $true
$pack = Join-Path $Tools 'Pack_Bundle.ps1'
$unpk = Join-Path $Tools 'Unpack_WithVerify.ps1'
if((Test-Path $pack) -and (Test-Path $unpk)){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
    $zip = Get-Item (Join-Path $Dist 'mason2-*.zip') -ea SilentlyContinue | Sort-Object LastWriteTime -desc | Select-Object -First 1
    if($zip){
      $tmp = Join-Path $Dist ("verify-" + [guid]::NewGuid().ToString("N"))
      powershell -NoProfile -ExecutionPolicy Bypass -File $unpk -Zip $zip.FullName -OutDir $tmp | Out-Null
      $packOK = Test-Path $tmp
      if($packOK){ Remove-Item $tmp -Recurse -Force -ea SilentlyContinue }
    }
  }catch{ $packOK = $false }
}
AddRes $packOK "Pack/Unpack OK (if present)" "Pack/Unpack script failed"

# 10) Dashboard launcher present
AddRes (Test-Path (Join-Path $Tools 'Start_DashboardWindow.ps1')) "Dashboard launcher present" "Dashboard launcher missing"

# Informational (not blockers)
try{
  $p = (Get-Content (Join-Path $Cfg 'policy.json') -Raw | ConvertFrom-Json)
  $need = 'high_risk_window','cmd_allowlist','file_scope_root','egress_denylist','operator_pin_hash'
  $polOK = ($need | Where-Object { $p.PSObject.Properties.Name -notcontains $_ }).Count -eq 0
  if($polOK){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Guardrails policy.json has required keys" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Guardrails policy.json incomplete" }
}catch{}
if(Test-Path (Join-Path $Cfg 'voice\voice.json')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Voice config present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Voice config missing" }
if(Test-Path (Join-Path $Rep 'compat_os.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Compatibility info present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Compatibility info missing" }
if(Test-Path (Join-Path $Base 'LICENSE.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© LICENSE present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ LICENSE missing" }
if(Test-Path (Join-Path $Base 'NOTICE.txt')){  $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© NOTICE present"  } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ NOTICE missing"  }
if(Test-Path (Join-Path $Base 'Uninstall_Mason2.ps1')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Uninstall script present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Uninstall script missing" }

# Write report
$okAll = ($Miss | ? { $_ -like "ÃƒÂ¢Ã‚ÂÃ…â€™*" }).Count -eq 0
$lines = @(
  "# Phase 1 Acceptance Report",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## Must-pass checks",
  ($MustPass -join "`r`n"),
  "",
  "## Present / scaffolds",
  ($Present -join "`r`n"),
  "",
  "## Gaps",
  ($Miss -join "`r`n"),
  ""
)
$lines | Set-Content $Report -Encoding UTF8

if($okAll){
  "ok" | Set-Content (Join-Path $Sig 'roadmap-phase-1-validated.ok') -Encoding ASCII
  Ok "Phase 1: ALL MUST-PASS CHECKS OK ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â validated."
  Ok ("Report -> " + $Report)
}else{
  Warn "Phase 1: some must-pass checks failed ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â see report for details."
  Warn ("Report -> " + $Report)
  exit 2
}

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param([switch]$Fix)

function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function ReadText([string]$p){ if(Test-Path $p){ Get-Content $p -Raw } else { "" } }

$Base   = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools  = Join-Path $Base 'tools'
$Cfg    = Join-Path $Base 'config'
$Rep    = Join-Path $Base 'reports'
$Sig    = Join-Path $Rep  'signals'
$Logs   = Join-Path $Base 'logs'
$Tel    = Join-Path $Logs 'telemetry\heartbeat.log'
$Report = Join-Path $Rep 'phase1_acceptance_report.md'
$Dist   = Join-Path $Base 'dist'

ni $Sig  -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null

$MustPass = @()
$Present  = @()
$Miss     = @()

function Check-Task($name, [int]$maxAgeMin = 0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $csv) { $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if ($LASTEXITCODE -ne 0 -or -not $csv) { return @{ ok=$false; msg=('Task not found: {0}' -f $name) } }

  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)

  $lastRun = $null
  try { if($obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){ $lastRun = [datetime]::Parse($obj.'Last Run Time') } } catch {}

  if ($maxAgeMin -gt 0 -and $lastRun) {
    $mins = [int]([datetime]::Now - $lastRun).TotalMinutes
    if ($mins -gt $maxAgeMin) { return @{ ok=$false; msg=("{0} last run {1}m ago (> {2} m)" -f $name,$mins,$maxAgeMin) } }
  }

  $res = ($obj.'Last Result' + '').Trim()
  if ($maxAgeMin -eq 0) {
    # Presence-only: accept Success(0), Running(267009), NotYetRun(267011)
    if (@('0','267009','267011') -notcontains $res) { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  } else {
    if ($res -and $res -ne '0') { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  }
  return @{ ok=$true; msg=("$name present") }
}

function AddRes($cond,$passMsg,$failMsg,$must=$true){
  if($cond){ if($must){$script:MustPass += "ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ $passMsg"} else {$script:Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© $passMsg"} }
  else     { if($must){$script:Miss     += "ÃƒÂ¢Ã‚ÂÃ…â€™ $failMsg"} else {$script:Miss    += "ÃƒÂ¢Ã‚Â¬Ã…â€œ $failMsg"} }
}

# 1) Heartbeat freshness (<=2m)
$hbOk = $false
try{ if(Test-Path $Tel){ $hbOk = ([int]([datetime]::Now - (Get-Item $Tel).LastWriteTime).TotalMinutes) -le 2 } }catch{}
AddRes $hbOk "Heartbeat is fresh (<=2m)" "Heartbeat stale or missing"

# 2) Scheduler health (age-gated)
foreach($t in @(@{n="Mason2 Heartbeat";age=2}, @{n="Mason2 Watchdog";age=3}, @{n="Mason2 Governor";age=4})){
  $r = Check-Task $t.n $t.age; AddRes $r.ok "$($t.n) healthy" $r.msg
}

# 3) Other scheduled jobs present (presence-only)
foreach($n in @("Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance",
                "Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth",
                "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms",
                "Mason2 Dashboard")){
  $r = Check-Task $n 0; AddRes $r.ok "$n present" $r.msg
}

# 4) Env toggle agrees
$envTxt  = ReadText (Join-Path $Rep 'env.txt')
$envJson = ReadText (Join-Path $Cfg 'env.json')
$modeTxt = ($envTxt -replace '.*ENV=','').Trim()
$modeJson = ""; try{ if($envJson){ $modeJson = ((($envJson | ConvertFrom-Json).environment)+"").Trim() } }catch{}
AddRes ( ($modeTxt -ne "") -and ($modeTxt -eq $modeJson) ) "Env consistent: $modeTxt" "Env mismatch or missing"

# 5) Pricebook + Roadmap exist
$priceOK = (Test-Path (Join-Path $Rep 'price\total_cad.txt')) -and ( ((ReadText (Join-Path $Rep 'price\line_items.md')).Trim()) -ne "" )
AddRes $priceOK "Price/line items generated" "Price/line items missing"
$roadOK  = ( (ReadText (Join-Path $Rep 'roadmap_render.md')).Trim() -ne "" )
AddRes $roadOK "Roadmap render exists" "Roadmap render missing"

# 6) One-folder + prereqs + sanity
$vf = Join-Path $Tools 'Verify_OneFolder.ps1'; if(Test-Path $vf){ powershell -NoProfile -ExecutionPolicy Bypass -File $vf | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-onefolder.ok')) "One-folder integrity OK" "One-folder integrity not confirmed"
$pre = Join-Path $Tools 'Bootstrap_Prereqs.ps1'; if(Test-Path $pre){ powershell -NoProfile -ExecutionPolicy Bypass -File $pre | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-prereq.ok')) "Prereqs validated" "Prereqs not validated"
$san = Join-Path $Tools 'Bootstrap_Sanity.ps1'; if(Test-Path $san){ powershell -NoProfile -ExecutionPolicy Bypass -File $san | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-bootstrap-sanity.ok')) "Bootstrap sanity OK" "Bootstrap sanity missing"

# 7) Install-log wrapper round-trip
$wrapOK = $false
$logWrap = Join-Path $Tools 'Run-Logged.ps1'
if(Test-Path $logWrap){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $logWrap -Cmd "cmd.exe" -Args "/c echo accept-test" | Out-Null
    $ilog = Join-Path $Base 'logs\install\install_log.txt'
    if(Test-Path $ilog){ $wrapOK = (Select-String -Path $ilog -Pattern '<< exit 0' -SimpleMatch) -ne $null }
  }catch{}
}
AddRes $wrapOK "Install-log wrapper captured exit 0" "Install-log wrapper test failed"

# 8) Version header present in some tool
$verOK = $false; $some = Get-ChildItem (Join-Path $Base 'tools') -Filter *.ps1 -File -ea SilentlyContinue | Select-Object -First 1
if($some){ $verOK = (ReadText $some.FullName) -match '^\s*#\s*Mason2-Version:' }
AddRes $verOK "Version stamp header detected" "Version stamp header not found"

# 9) Pack/Unpack (if present)
$packOK = $true
$pack = Join-Path $Tools 'Pack_Bundle.ps1'
$unpk = Join-Path $Tools 'Unpack_WithVerify.ps1'
if((Test-Path $pack) -and (Test-Path $unpk)){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
    $zip = Get-Item (Join-Path $Dist 'mason2-*.zip') -ea SilentlyContinue | Sort-Object LastWriteTime -desc | Select-Object -First 1
    if($zip){
      $tmp = Join-Path $Dist ("verify-" + [guid]::NewGuid().ToString("N"))
      powershell -NoProfile -ExecutionPolicy Bypass -File $unpk -Zip $zip.FullName -OutDir $tmp | Out-Null
      $packOK = Test-Path $tmp
      if($packOK){ Remove-Item $tmp -Recurse -Force -ea SilentlyContinue }
    }
  }catch{ $packOK = $false }
}
AddRes $packOK "Pack/Unpack OK (if present)" "Pack/Unpack script failed"

# 10) Dashboard launcher present
AddRes (Test-Path (Join-Path $Tools 'Start_DashboardWindow.ps1')) "Dashboard launcher present" "Dashboard launcher missing"

# Informational (not blockers)
try{
  $p = (Get-Content (Join-Path $Cfg 'policy.json') -Raw | ConvertFrom-Json)
  $need = 'high_risk_window','cmd_allowlist','file_scope_root','egress_denylist','operator_pin_hash'
  $polOK = ($need | Where-Object { $p.PSObject.Properties.Name -notcontains $_ }).Count -eq 0
  if($polOK){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Guardrails policy.json has required keys" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Guardrails policy.json incomplete" }
}catch{}
if(Test-Path (Join-Path $Cfg 'voice\voice.json')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Voice config present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Voice config missing" }
if(Test-Path (Join-Path $Rep 'compat_os.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Compatibility info present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Compatibility info missing" }
if(Test-Path (Join-Path $Base 'LICENSE.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© LICENSE present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ LICENSE missing" }
if(Test-Path (Join-Path $Base 'NOTICE.txt')){  $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© NOTICE present"  } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ NOTICE missing"  }
if(Test-Path (Join-Path $Base 'Uninstall_Mason2.ps1')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Uninstall script present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Uninstall script missing" }

# Write report
$okAll = ($Miss | ? { $_ -like "ÃƒÂ¢Ã‚ÂÃ…â€™*" }).Count -eq 0
$lines = @(
  "# Phase 1 Acceptance Report",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## Must-pass checks",
  ($MustPass -join "`r`n"),
  "",
  "## Present / scaffolds",
  ($Present -join "`r`n"),
  "",
  "## Gaps",
  ($Miss -join "`r`n"),
  ""
)
$lines | Set-Content $Report -Encoding UTF8

if($okAll){
  "ok" | Set-Content (Join-Path $Sig 'roadmap-phase-1-validated.ok') -Encoding ASCII
  Ok "Phase 1: ALL MUST-PASS CHECKS OK ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â validated."
  Ok ("Report -> " + $Report)
}else{
  Warn "Phase 1: some must-pass checks failed ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â see report for details."
  Warn ("Report -> " + $Report)
  exit 2
}

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param([switch]$Fix)

function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function ReadText([string]$p){ if(Test-Path $p){ Get-Content $p -Raw } else { "" } }

$Base   = Join-Path $env:USERPROFILE 'Desktop\Mason2'
$Tools  = Join-Path $Base 'tools'
$Cfg    = Join-Path $Base 'config'
$Rep    = Join-Path $Base 'reports'
$Sig    = Join-Path $Rep  'signals'
$Logs   = Join-Path $Base 'logs'
$Tel    = Join-Path $Logs 'telemetry\heartbeat.log'
$Report = Join-Path $Rep 'phase1_acceptance_report.md'
$Dist   = Join-Path $Base 'dist'

ni $Sig  -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Dist -ItemType Directory -ea SilentlyContinue | Out-Null

$MustPass = @()
$Present  = @()
$Miss     = @()

function Check-Task($name, [int]$maxAgeMin = 0){
  $csv = & schtasks.exe /Query /TN $name /V /FO CSV 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $csv) { $csv = & schtasks.exe /Query /TN ("\{0}" -f $name) /V /FO CSV 2>$null }
  if ($LASTEXITCODE -ne 0 -or -not $csv) { return @{ ok=$false; msg=('Task not found: {0}' -f $name) } }

  $obj = ($csv | ConvertFrom-Csv | Select-Object -First 1)

  $lastRun = $null
  try { if($obj.'Last Run Time' -and $obj.'Last Run Time' -notmatch 'Never'){ $lastRun = [datetime]::Parse($obj.'Last Run Time') } } catch {}

  if ($maxAgeMin -gt 0 -and $lastRun) {
    $mins = [int]([datetime]::Now - $lastRun).TotalMinutes
    if ($mins -gt $maxAgeMin) { return @{ ok=$false; msg=("{0} last run {1}m ago (> {2} m)" -f $name,$mins,$maxAgeMin) } }
  }

  $res = ($obj.'Last Result' + '').Trim()
  if ($maxAgeMin -eq 0) {
    # Presence-only: accept Success(0), Running(267009), NotYetRun(267011)
    if (@('0','267009','267011') -notcontains $res) { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  } else {
    if ($res -and $res -ne '0') { return @{ ok=$false; msg=("{0} Last Result={1}" -f $name,$res) } }
  }
  return @{ ok=$true; msg=("$name present") }
}

function AddRes($cond,$passMsg,$failMsg,$must=$true){
  if($cond){ if($must){$script:MustPass += "ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ $passMsg"} else {$script:Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© $passMsg"} }
  else     { if($must){$script:Miss     += "ÃƒÂ¢Ã‚ÂÃ…â€™ $failMsg"} else {$script:Miss    += "ÃƒÂ¢Ã‚Â¬Ã…â€œ $failMsg"} }
}

# 1) Heartbeat freshness (<=2m)
$hbOk = $false
try{ if(Test-Path $Tel){ $hbOk = ([int]([datetime]::Now - (Get-Item $Tel).LastWriteTime).TotalMinutes) -le 2 } }catch{}
AddRes $hbOk "Heartbeat is fresh (<=2m)" "Heartbeat stale or missing"

# 2) Scheduler health (age-gated)
foreach($t in @(@{n="Mason2 Heartbeat";age=2}, @{n="Mason2 Watchdog";age=3}, @{n="Mason2 Governor";age=4})){
  $r = Check-Task $t.n $t.age; AddRes $r.ok "$($t.n) healthy" $r.msg
}

# 3) Other scheduled jobs present (presence-only)
foreach($n in @("Mason2 Snapshot","Mason2 WeeklyRestoreTest","Mason2 LogMaintenance",
                "Mason2 TopicSync","Mason2 AutoAdvance","Mason2 DiskHealth",
                "Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms",
                "Mason2 Dashboard")){
  $r = Check-Task $n 0; AddRes $r.ok "$n present" $r.msg
}

# 4) Env toggle agrees
$envTxt  = ReadText (Join-Path $Rep 'env.txt')
$envJson = ReadText (Join-Path $Cfg 'env.json')
$modeTxt = ($envTxt -replace '.*ENV=','').Trim()
$modeJson = ""; try{ if($envJson){ $modeJson = ((($envJson | ConvertFrom-Json).environment)+"").Trim() } }catch{}
AddRes ( ($modeTxt -ne "") -and ($modeTxt -eq $modeJson) ) "Env consistent: $modeTxt" "Env mismatch or missing"

# 5) Pricebook + Roadmap exist
$priceOK = (Test-Path (Join-Path $Rep 'price\total_cad.txt')) -and ( ((ReadText (Join-Path $Rep 'price\line_items.md')).Trim()) -ne "" )
AddRes $priceOK "Price/line items generated" "Price/line items missing"
$roadOK  = ( (ReadText (Join-Path $Rep 'roadmap_render.md')).Trim() -ne "" )
AddRes $roadOK "Roadmap render exists" "Roadmap render missing"

# 6) One-folder + prereqs + sanity
$vf = Join-Path $Tools 'Verify_OneFolder.ps1'; if(Test-Path $vf){ powershell -NoProfile -ExecutionPolicy Bypass -File $vf | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-onefolder.ok')) "One-folder integrity OK" "One-folder integrity not confirmed"
$pre = Join-Path $Tools 'Bootstrap_Prereqs.ps1'; if(Test-Path $pre){ powershell -NoProfile -ExecutionPolicy Bypass -File $pre | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-prereq.ok')) "Prereqs validated" "Prereqs not validated"
$san = Join-Path $Tools 'Bootstrap_Sanity.ps1'; if(Test-Path $san){ powershell -NoProfile -ExecutionPolicy Bypass -File $san | Out-Null }
AddRes (Test-Path (Join-Path $Sig 'system-structure-bootstrap-sanity.ok')) "Bootstrap sanity OK" "Bootstrap sanity missing"

# 7) Install-log wrapper round-trip
$wrapOK = $false
$logWrap = Join-Path $Tools 'Run-Logged.ps1'
if(Test-Path $logWrap){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $logWrap -Cmd "cmd.exe" -Args "/c echo accept-test" | Out-Null
    $ilog = Join-Path $Base 'logs\install\install_log.txt'
    if(Test-Path $ilog){ $wrapOK = (Select-String -Path $ilog -Pattern '<< exit 0' -SimpleMatch) -ne $null }
  }catch{}
}
AddRes $wrapOK "Install-log wrapper captured exit 0" "Install-log wrapper test failed"

# 8) Version header present in some tool
$verOK = $false; $some = Get-ChildItem (Join-Path $Base 'tools') -Filter *.ps1 -File -ea SilentlyContinue | Select-Object -First 1
if($some){ $verOK = (ReadText $some.FullName) -match '^\s*#\s*Mason2-Version:' }
AddRes $verOK "Version stamp header detected" "Version stamp header not found"

# 9) Pack/Unpack (if present)
$packOK = $true
$pack = Join-Path $Tools 'Pack_Bundle.ps1'
$unpk = Join-Path $Tools 'Unpack_WithVerify.ps1'
if((Test-Path $pack) -and (Test-Path $unpk)){
  try{
    powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
    $zip = Get-Item (Join-Path $Dist 'mason2-*.zip') -ea SilentlyContinue | Sort-Object LastWriteTime -desc | Select-Object -First 1
    if($zip){
      $tmp = Join-Path $Dist ("verify-" + [guid]::NewGuid().ToString("N"))
      powershell -NoProfile -ExecutionPolicy Bypass -File $unpk -Zip $zip.FullName -OutDir $tmp | Out-Null
      $packOK = Test-Path $tmp
      if($packOK){ Remove-Item $tmp -Recurse -Force -ea SilentlyContinue }
    }
  }catch{ $packOK = $false }
}
AddRes $packOK "Pack/Unpack OK (if present)" "Pack/Unpack script failed"

# 10) Dashboard launcher present
AddRes (Test-Path (Join-Path $Tools 'Start_DashboardWindow.ps1')) "Dashboard launcher present" "Dashboard launcher missing"

# Informational (not blockers)
try{
  $p = (Get-Content (Join-Path $Cfg 'policy.json') -Raw | ConvertFrom-Json)
  $need = 'high_risk_window','cmd_allowlist','file_scope_root','egress_denylist','operator_pin_hash'
  $polOK = ($need | Where-Object { $p.PSObject.Properties.Name -notcontains $_ }).Count -eq 0
  if($polOK){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Guardrails policy.json has required keys" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Guardrails policy.json incomplete" }
}catch{}
if(Test-Path (Join-Path $Cfg 'voice\voice.json')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Voice config present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Voice config missing" }
if(Test-Path (Join-Path $Rep 'compat_os.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Compatibility info present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Compatibility info missing" }
if(Test-Path (Join-Path $Base 'LICENSE.txt')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© LICENSE present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ LICENSE missing" }
if(Test-Path (Join-Path $Base 'NOTICE.txt')){  $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© NOTICE present"  } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ NOTICE missing"  }
if(Test-Path (Join-Path $Base 'Uninstall_Mason2.ps1')){ $Present += "ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â© Uninstall script present" } else { $Miss += "ÃƒÂ¢Ã‚Â¬Ã…â€œ Uninstall script missing" }

# Write report
$okAll = ($Miss | ? { $_ -like "ÃƒÂ¢Ã‚ÂÃ…â€™*" }).Count -eq 0
$lines = @(
  "# Phase 1 Acceptance Report",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## Must-pass checks",
  ($MustPass -join "`r`n"),
  "",
  "## Present / scaffolds",
  ($Present -join "`r`n"),
  "",
  "## Gaps",
  ($Miss -join "`r`n"),
  ""
)
$lines | Set-Content $Report -Encoding UTF8

if($okAll){
  "ok" | Set-Content (Join-Path $Sig 'roadmap-phase-1-validated.ok') -Encoding ASCII
  Ok "Phase 1: ALL MUST-PASS CHECKS OK ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â validated."
  Ok ("Report -> " + $Report)
}else{
  Warn "Phase 1: some must-pass checks failed ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â see report for details."
  Warn ("Report -> " + $Report)
  exit 2
}

