# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep "signals"
$Dist = Join-Path $Base "dist"
$need = @(
  # structure/packaging
  "system-structure-portable-base.ok","system-structure-manifest.ok","system-structure-portable-manifest.ok",
  "system-structure-prereqs.ok","system-structure-prereq.ok","system-structure-onefolder.ok",
  "system-structure-package.ok","system-structure-pack-unpack.ok","system-structure-roadmap-integrity.ok",
  "system-structure-env-discovery.ok","system-structure-version-stamp.ok","system-structure-startstop.ok",
  "system-structure-install-log.ok","system-structure-config-sample.ok","system-structure-license-notice.ok",
  "system-structure-prereq-cache.ok","system-structure-bootstrap-sanity.ok","system-structure-uninstall-script.ok",
  "system-structure-first-run-wizard.ok","system-structure-compatibility-check.ok",
  # logging/telemetry
  "logging-telemetry.ok","logging-telemetry-structured-log-format-json-lines.ok","logging-telemetry-heartbeat.ok",
  # watchdog/governor
  "watchdog-governor.ok","watchdog-governor-sidecar-7000-sentinel.ok",
  # safety
  "safety-guardrails.ok","safety-guardrails-kill-switch-hotkey.ok","safety-guardrails-money-loop-hard-off-when-unstable.ok",
  "safety-guardrails-file-scope.ok","safety-guardrails-command-allowlist.ok",
  # dashboard/ux
  "dashboard-ux.ok","dashboard-ux-status-banner-green-amber-red-logic.ok",
  "dashboard-ux-copy-status-to-clipboard.ok","dashboard-ux-open-logs-folder-button.ok",
  "dashboard-ux-queue-browser-peek-top-n.ok","dashboard-ux-next-hint-updated.ok",
  # automation
  "automation-schedules-task-scheduler-verifier.ok"
)
$have = @{}
if(Test-Path $Sig){ Get-ChildItem $Sig -Filter *.ok | % { $have[$_.Name.ToLower()]=1 } }
$missing = @()
foreach($s in $need){ if(-not $have[$s.ToLower()]){ $missing += $s } }

if($missing.Count -gt 0){
  Write-Host "`n[FAIL] Phase 1 validator ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â MISSING signals:" -ForegroundColor Red
  $missing | % { Write-Host " - $_" -ForegroundColor Yellow }
  exit 1
}

# pack + integrity verify
$pack = Join-Path $Base "tools\Pack_Bundle.ps1"
if(Test-Path $pack){
  powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
  $zip = (Get-Item (Join-Path $Dist "mason2-*.zip") | Sort-Object LastWriteTime -desc | Select-Object -First 1)
  if($zip){
    $out = Join-Path $Dist ("unpacked-verify-" + $zip.BaseName)
    $un  = Join-Path $Base "tools\Unpack_WithVerify.ps1"
    if(Test-Path $un){ powershell -NoProfile -ExecutionPolicy Bypass -File $un -Zip $zip.FullName -OutDir $out | Out-Null }
  }
}

# stamp COMPLETE and update status_summary.md
"ok" | Set-Content (Join-Path $Sig "roadmap-phase-1-complete.ok") -Encoding ASCII
$ss = Join-Path $Rep "status_summary.md"
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "Phase 1: ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE  ($now)"
if(Test-Path $ss){
  $cur = Get-Content $ss -Raw
  if($cur -notmatch 'Phase 1:\s*ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE'){ ($line + "`r`n" + $cur) | Set-Content $ss -Encoding UTF8 }
  else { $cur | Set-Content $ss -Encoding UTF8 }
}else{
  $line | Set-Content $ss -Encoding UTF8
}
Write-Host "`n[ OK ] Phase 1 VALIDATED and STAMPED COMPLETE." -ForegroundColor Green


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep "signals"
$Dist = Join-Path $Base "dist"
$need = @(
  # structure/packaging
  "system-structure-portable-base.ok","system-structure-manifest.ok","system-structure-portable-manifest.ok",
  "system-structure-prereqs.ok","system-structure-prereq.ok","system-structure-onefolder.ok",
  "system-structure-package.ok","system-structure-pack-unpack.ok","system-structure-roadmap-integrity.ok",
  "system-structure-env-discovery.ok","system-structure-version-stamp.ok","system-structure-startstop.ok",
  "system-structure-install-log.ok","system-structure-config-sample.ok","system-structure-license-notice.ok",
  "system-structure-prereq-cache.ok","system-structure-bootstrap-sanity.ok","system-structure-uninstall-script.ok",
  "system-structure-first-run-wizard.ok","system-structure-compatibility-check.ok",
  # logging/telemetry
  "logging-telemetry.ok","logging-telemetry-structured-log-format-json-lines.ok","logging-telemetry-heartbeat.ok",
  # watchdog/governor
  "watchdog-governor.ok","watchdog-governor-sidecar-7000-sentinel.ok",
  # safety
  "safety-guardrails.ok","safety-guardrails-kill-switch-hotkey.ok","safety-guardrails-money-loop-hard-off-when-unstable.ok",
  "safety-guardrails-file-scope.ok","safety-guardrails-command-allowlist.ok",
  # dashboard/ux
  "dashboard-ux.ok","dashboard-ux-status-banner-green-amber-red-logic.ok",
  "dashboard-ux-copy-status-to-clipboard.ok","dashboard-ux-open-logs-folder-button.ok",
  "dashboard-ux-queue-browser-peek-top-n.ok","dashboard-ux-next-hint-updated.ok",
  # automation
  "automation-schedules-task-scheduler-verifier.ok"
)
$have = @{}
if(Test-Path $Sig){ Get-ChildItem $Sig -Filter *.ok | % { $have[$_.Name.ToLower()]=1 } }
$missing = @()
foreach($s in $need){ if(-not $have[$s.ToLower()]){ $missing += $s } }

if($missing.Count -gt 0){
  Write-Host "`n[FAIL] Phase 1 validator ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â MISSING signals:" -ForegroundColor Red
  $missing | % { Write-Host " - $_" -ForegroundColor Yellow }
  exit 1
}

# pack + integrity verify
$pack = Join-Path $Base "tools\Pack_Bundle.ps1"
if(Test-Path $pack){
  powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
  $zip = (Get-Item (Join-Path $Dist "mason2-*.zip") | Sort-Object LastWriteTime -desc | Select-Object -First 1)
  if($zip){
    $out = Join-Path $Dist ("unpacked-verify-" + $zip.BaseName)
    $un  = Join-Path $Base "tools\Unpack_WithVerify.ps1"
    if(Test-Path $un){ powershell -NoProfile -ExecutionPolicy Bypass -File $un -Zip $zip.FullName -OutDir $out | Out-Null }
  }
}

# stamp COMPLETE and update status_summary.md
"ok" | Set-Content (Join-Path $Sig "roadmap-phase-1-complete.ok") -Encoding ASCII
$ss = Join-Path $Rep "status_summary.md"
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "Phase 1: ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE  ($now)"
if(Test-Path $ss){
  $cur = Get-Content $ss -Raw
  if($cur -notmatch 'Phase 1:\s*ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE'){ ($line + "`r`n" + $cur) | Set-Content $ss -Encoding UTF8 }
  else { $cur | Set-Content $ss -Encoding UTF8 }
}else{
  $line | Set-Content $ss -Encoding UTF8
}
Write-Host "`n[ OK ] Phase 1 VALIDATED and STAMPED COMPLETE." -ForegroundColor Green


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep "signals"
$Dist = Join-Path $Base "dist"
$need = @(
  # structure/packaging
  "system-structure-portable-base.ok","system-structure-manifest.ok","system-structure-portable-manifest.ok",
  "system-structure-prereqs.ok","system-structure-prereq.ok","system-structure-onefolder.ok",
  "system-structure-package.ok","system-structure-pack-unpack.ok","system-structure-roadmap-integrity.ok",
  "system-structure-env-discovery.ok","system-structure-version-stamp.ok","system-structure-startstop.ok",
  "system-structure-install-log.ok","system-structure-config-sample.ok","system-structure-license-notice.ok",
  "system-structure-prereq-cache.ok","system-structure-bootstrap-sanity.ok","system-structure-uninstall-script.ok",
  "system-structure-first-run-wizard.ok","system-structure-compatibility-check.ok",
  # logging/telemetry
  "logging-telemetry.ok","logging-telemetry-structured-log-format-json-lines.ok","logging-telemetry-heartbeat.ok",
  # watchdog/governor
  "watchdog-governor.ok","watchdog-governor-sidecar-7000-sentinel.ok",
  # safety
  "safety-guardrails.ok","safety-guardrails-kill-switch-hotkey.ok","safety-guardrails-money-loop-hard-off-when-unstable.ok",
  "safety-guardrails-file-scope.ok","safety-guardrails-command-allowlist.ok",
  # dashboard/ux
  "dashboard-ux.ok","dashboard-ux-status-banner-green-amber-red-logic.ok",
  "dashboard-ux-copy-status-to-clipboard.ok","dashboard-ux-open-logs-folder-button.ok",
  "dashboard-ux-queue-browser-peek-top-n.ok","dashboard-ux-next-hint-updated.ok",
  # automation
  "automation-schedules-task-scheduler-verifier.ok"
)
$have = @{}
if(Test-Path $Sig){ Get-ChildItem $Sig -Filter *.ok | % { $have[$_.Name.ToLower()]=1 } }
$missing = @()
foreach($s in $need){ if(-not $have[$s.ToLower()]){ $missing += $s } }

if($missing.Count -gt 0){
  Write-Host "`n[FAIL] Phase 1 validator ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â MISSING signals:" -ForegroundColor Red
  $missing | % { Write-Host " - $_" -ForegroundColor Yellow }
  exit 1
}

# pack + integrity verify
$pack = Join-Path $Base "tools\Pack_Bundle.ps1"
if(Test-Path $pack){
  powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
  $zip = (Get-Item (Join-Path $Dist "mason2-*.zip") | Sort-Object LastWriteTime -desc | Select-Object -First 1)
  if($zip){
    $out = Join-Path $Dist ("unpacked-verify-" + $zip.BaseName)
    $un  = Join-Path $Base "tools\Unpack_WithVerify.ps1"
    if(Test-Path $un){ powershell -NoProfile -ExecutionPolicy Bypass -File $un -Zip $zip.FullName -OutDir $out | Out-Null }
  }
}

# stamp COMPLETE and update status_summary.md
"ok" | Set-Content (Join-Path $Sig "roadmap-phase-1-complete.ok") -Encoding ASCII
$ss = Join-Path $Rep "status_summary.md"
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "Phase 1: ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE  ($now)"
if(Test-Path $ss){
  $cur = Get-Content $ss -Raw
  if($cur -notmatch 'Phase 1:\s*ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE'){ ($line + "`r`n" + $cur) | Set-Content $ss -Encoding UTF8 }
  else { $cur | Set-Content $ss -Encoding UTF8 }
}else{
  $line | Set-Content $ss -Encoding UTF8
}
Write-Host "`n[ OK ] Phase 1 VALIDATED and STAMPED COMPLETE." -ForegroundColor Green


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep "signals"
$Dist = Join-Path $Base "dist"
$need = @(
  # structure/packaging
  "system-structure-portable-base.ok","system-structure-manifest.ok","system-structure-portable-manifest.ok",
  "system-structure-prereqs.ok","system-structure-prereq.ok","system-structure-onefolder.ok",
  "system-structure-package.ok","system-structure-pack-unpack.ok","system-structure-roadmap-integrity.ok",
  "system-structure-env-discovery.ok","system-structure-version-stamp.ok","system-structure-startstop.ok",
  "system-structure-install-log.ok","system-structure-config-sample.ok","system-structure-license-notice.ok",
  "system-structure-prereq-cache.ok","system-structure-bootstrap-sanity.ok","system-structure-uninstall-script.ok",
  "system-structure-first-run-wizard.ok","system-structure-compatibility-check.ok",
  # logging/telemetry
  "logging-telemetry.ok","logging-telemetry-structured-log-format-json-lines.ok","logging-telemetry-heartbeat.ok",
  # watchdog/governor
  "watchdog-governor.ok","watchdog-governor-sidecar-7000-sentinel.ok",
  # safety
  "safety-guardrails.ok","safety-guardrails-kill-switch-hotkey.ok","safety-guardrails-money-loop-hard-off-when-unstable.ok",
  "safety-guardrails-file-scope.ok","safety-guardrails-command-allowlist.ok",
  # dashboard/ux
  "dashboard-ux.ok","dashboard-ux-status-banner-green-amber-red-logic.ok",
  "dashboard-ux-copy-status-to-clipboard.ok","dashboard-ux-open-logs-folder-button.ok",
  "dashboard-ux-queue-browser-peek-top-n.ok","dashboard-ux-next-hint-updated.ok",
  # automation
  "automation-schedules-task-scheduler-verifier.ok"
)
$have = @{}
if(Test-Path $Sig){ Get-ChildItem $Sig -Filter *.ok | % { $have[$_.Name.ToLower()]=1 } }
$missing = @()
foreach($s in $need){ if(-not $have[$s.ToLower()]){ $missing += $s } }

if($missing.Count -gt 0){
  Write-Host "`n[FAIL] Phase 1 validator ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â MISSING signals:" -ForegroundColor Red
  $missing | % { Write-Host " - $_" -ForegroundColor Yellow }
  exit 1
}

# pack + integrity verify
$pack = Join-Path $Base "tools\Pack_Bundle.ps1"
if(Test-Path $pack){
  powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
  $zip = (Get-Item (Join-Path $Dist "mason2-*.zip") | Sort-Object LastWriteTime -desc | Select-Object -First 1)
  if($zip){
    $out = Join-Path $Dist ("unpacked-verify-" + $zip.BaseName)
    $un  = Join-Path $Base "tools\Unpack_WithVerify.ps1"
    if(Test-Path $un){ powershell -NoProfile -ExecutionPolicy Bypass -File $un -Zip $zip.FullName -OutDir $out | Out-Null }
  }
}

# stamp COMPLETE and update status_summary.md
"ok" | Set-Content (Join-Path $Sig "roadmap-phase-1-complete.ok") -Encoding ASCII
$ss = Join-Path $Rep "status_summary.md"
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "Phase 1: ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE  ($now)"
if(Test-Path $ss){
  $cur = Get-Content $ss -Raw
  if($cur -notmatch 'Phase 1:\s*ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE'){ ($line + "`r`n" + $cur) | Set-Content $ss -Encoding UTF8 }
  else { $cur | Set-Content $ss -Encoding UTF8 }
}else{
  $line | Set-Content $ss -Encoding UTF8
}
Write-Host "`n[ OK ] Phase 1 VALIDATED and STAMPED COMPLETE." -ForegroundColor Green


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep "signals"
$Dist = Join-Path $Base "dist"
$need = @(
  # structure/packaging
  "system-structure-portable-base.ok","system-structure-manifest.ok","system-structure-portable-manifest.ok",
  "system-structure-prereqs.ok","system-structure-prereq.ok","system-structure-onefolder.ok",
  "system-structure-package.ok","system-structure-pack-unpack.ok","system-structure-roadmap-integrity.ok",
  "system-structure-env-discovery.ok","system-structure-version-stamp.ok","system-structure-startstop.ok",
  "system-structure-install-log.ok","system-structure-config-sample.ok","system-structure-license-notice.ok",
  "system-structure-prereq-cache.ok","system-structure-bootstrap-sanity.ok","system-structure-uninstall-script.ok",
  "system-structure-first-run-wizard.ok","system-structure-compatibility-check.ok",
  # logging/telemetry
  "logging-telemetry.ok","logging-telemetry-structured-log-format-json-lines.ok","logging-telemetry-heartbeat.ok",
  # watchdog/governor
  "watchdog-governor.ok","watchdog-governor-sidecar-7000-sentinel.ok",
  # safety
  "safety-guardrails.ok","safety-guardrails-kill-switch-hotkey.ok","safety-guardrails-money-loop-hard-off-when-unstable.ok",
  "safety-guardrails-file-scope.ok","safety-guardrails-command-allowlist.ok",
  # dashboard/ux
  "dashboard-ux.ok","dashboard-ux-status-banner-green-amber-red-logic.ok",
  "dashboard-ux-copy-status-to-clipboard.ok","dashboard-ux-open-logs-folder-button.ok",
  "dashboard-ux-queue-browser-peek-top-n.ok","dashboard-ux-next-hint-updated.ok",
  # automation
  "automation-schedules-task-scheduler-verifier.ok"
)
$have = @{}
if(Test-Path $Sig){ Get-ChildItem $Sig -Filter *.ok | % { $have[$_.Name.ToLower()]=1 } }
$missing = @()
foreach($s in $need){ if(-not $have[$s.ToLower()]){ $missing += $s } }

if($missing.Count -gt 0){
  Write-Host "`n[FAIL] Phase 1 validator ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â MISSING signals:" -ForegroundColor Red
  $missing | % { Write-Host " - $_" -ForegroundColor Yellow }
  exit 1
}

# pack + integrity verify
$pack = Join-Path $Base "tools\Pack_Bundle.ps1"
if(Test-Path $pack){
  powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
  $zip = (Get-Item (Join-Path $Dist "mason2-*.zip") | Sort-Object LastWriteTime -desc | Select-Object -First 1)
  if($zip){
    $out = Join-Path $Dist ("unpacked-verify-" + $zip.BaseName)
    $un  = Join-Path $Base "tools\Unpack_WithVerify.ps1"
    if(Test-Path $un){ powershell -NoProfile -ExecutionPolicy Bypass -File $un -Zip $zip.FullName -OutDir $out | Out-Null }
  }
}

# stamp COMPLETE and update status_summary.md
"ok" | Set-Content (Join-Path $Sig "roadmap-phase-1-complete.ok") -Encoding ASCII
$ss = Join-Path $Rep "status_summary.md"
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "Phase 1: ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE  ($now)"
if(Test-Path $ss){
  $cur = Get-Content $ss -Raw
  if($cur -notmatch 'Phase 1:\s*ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE'){ ($line + "`r`n" + $cur) | Set-Content $ss -Encoding UTF8 }
  else { $cur | Set-Content $ss -Encoding UTF8 }
}else{
  $line | Set-Content $ss -Encoding UTF8
}
Write-Host "`n[ OK ] Phase 1 VALIDATED and STAMPED COMPLETE." -ForegroundColor Green


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep "signals"
$Dist = Join-Path $Base "dist"
$need = @(
  # structure/packaging
  "system-structure-portable-base.ok","system-structure-manifest.ok","system-structure-portable-manifest.ok",
  "system-structure-prereqs.ok","system-structure-prereq.ok","system-structure-onefolder.ok",
  "system-structure-package.ok","system-structure-pack-unpack.ok","system-structure-roadmap-integrity.ok",
  "system-structure-env-discovery.ok","system-structure-version-stamp.ok","system-structure-startstop.ok",
  "system-structure-install-log.ok","system-structure-config-sample.ok","system-structure-license-notice.ok",
  "system-structure-prereq-cache.ok","system-structure-bootstrap-sanity.ok","system-structure-uninstall-script.ok",
  "system-structure-first-run-wizard.ok","system-structure-compatibility-check.ok",
  # logging/telemetry
  "logging-telemetry.ok","logging-telemetry-structured-log-format-json-lines.ok","logging-telemetry-heartbeat.ok",
  # watchdog/governor
  "watchdog-governor.ok","watchdog-governor-sidecar-7000-sentinel.ok",
  # safety
  "safety-guardrails.ok","safety-guardrails-kill-switch-hotkey.ok","safety-guardrails-money-loop-hard-off-when-unstable.ok",
  "safety-guardrails-file-scope.ok","safety-guardrails-command-allowlist.ok",
  # dashboard/ux
  "dashboard-ux.ok","dashboard-ux-status-banner-green-amber-red-logic.ok",
  "dashboard-ux-copy-status-to-clipboard.ok","dashboard-ux-open-logs-folder-button.ok",
  "dashboard-ux-queue-browser-peek-top-n.ok","dashboard-ux-next-hint-updated.ok",
  # automation
  "automation-schedules-task-scheduler-verifier.ok"
)
$have = @{}
if(Test-Path $Sig){ Get-ChildItem $Sig -Filter *.ok | % { $have[$_.Name.ToLower()]=1 } }
$missing = @()
foreach($s in $need){ if(-not $have[$s.ToLower()]){ $missing += $s } }

if($missing.Count -gt 0){
  Write-Host "`n[FAIL] Phase 1 validator ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â MISSING signals:" -ForegroundColor Red
  $missing | % { Write-Host " - $_" -ForegroundColor Yellow }
  exit 1
}

# pack + integrity verify
$pack = Join-Path $Base "tools\Pack_Bundle.ps1"
if(Test-Path $pack){
  powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
  $zip = (Get-Item (Join-Path $Dist "mason2-*.zip") | Sort-Object LastWriteTime -desc | Select-Object -First 1)
  if($zip){
    $out = Join-Path $Dist ("unpacked-verify-" + $zip.BaseName)
    $un  = Join-Path $Base "tools\Unpack_WithVerify.ps1"
    if(Test-Path $un){ powershell -NoProfile -ExecutionPolicy Bypass -File $un -Zip $zip.FullName -OutDir $out | Out-Null }
  }
}

# stamp COMPLETE and update status_summary.md
"ok" | Set-Content (Join-Path $Sig "roadmap-phase-1-complete.ok") -Encoding ASCII
$ss = Join-Path $Rep "status_summary.md"
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "Phase 1: ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE  ($now)"
if(Test-Path $ss){
  $cur = Get-Content $ss -Raw
  if($cur -notmatch 'Phase 1:\s*ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE'){ ($line + "`r`n" + $cur) | Set-Content $ss -Encoding UTF8 }
  else { $cur | Set-Content $ss -Encoding UTF8 }
}else{
  $line | Set-Content $ss -Encoding UTF8
}
Write-Host "`n[ OK ] Phase 1 VALIDATED and STAMPED COMPLETE." -ForegroundColor Green


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep "signals"
$Dist = Join-Path $Base "dist"
$need = @(
  # structure/packaging
  "system-structure-portable-base.ok","system-structure-manifest.ok","system-structure-portable-manifest.ok",
  "system-structure-prereqs.ok","system-structure-prereq.ok","system-structure-onefolder.ok",
  "system-structure-package.ok","system-structure-pack-unpack.ok","system-structure-roadmap-integrity.ok",
  "system-structure-env-discovery.ok","system-structure-version-stamp.ok","system-structure-startstop.ok",
  "system-structure-install-log.ok","system-structure-config-sample.ok","system-structure-license-notice.ok",
  "system-structure-prereq-cache.ok","system-structure-bootstrap-sanity.ok","system-structure-uninstall-script.ok",
  "system-structure-first-run-wizard.ok","system-structure-compatibility-check.ok",
  # logging/telemetry
  "logging-telemetry.ok","logging-telemetry-structured-log-format-json-lines.ok","logging-telemetry-heartbeat.ok",
  # watchdog/governor
  "watchdog-governor.ok","watchdog-governor-sidecar-7000-sentinel.ok",
  # safety
  "safety-guardrails.ok","safety-guardrails-kill-switch-hotkey.ok","safety-guardrails-money-loop-hard-off-when-unstable.ok",
  "safety-guardrails-file-scope.ok","safety-guardrails-command-allowlist.ok",
  # dashboard/ux
  "dashboard-ux.ok","dashboard-ux-status-banner-green-amber-red-logic.ok",
  "dashboard-ux-copy-status-to-clipboard.ok","dashboard-ux-open-logs-folder-button.ok",
  "dashboard-ux-queue-browser-peek-top-n.ok","dashboard-ux-next-hint-updated.ok",
  # automation
  "automation-schedules-task-scheduler-verifier.ok"
)
$have = @{}
if(Test-Path $Sig){ Get-ChildItem $Sig -Filter *.ok | % { $have[$_.Name.ToLower()]=1 } }
$missing = @()
foreach($s in $need){ if(-not $have[$s.ToLower()]){ $missing += $s } }

if($missing.Count -gt 0){
  Write-Host "`n[FAIL] Phase 1 validator ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â MISSING signals:" -ForegroundColor Red
  $missing | % { Write-Host " - $_" -ForegroundColor Yellow }
  exit 1
}

# pack + integrity verify
$pack = Join-Path $Base "tools\Pack_Bundle.ps1"
if(Test-Path $pack){
  powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
  $zip = (Get-Item (Join-Path $Dist "mason2-*.zip") | Sort-Object LastWriteTime -desc | Select-Object -First 1)
  if($zip){
    $out = Join-Path $Dist ("unpacked-verify-" + $zip.BaseName)
    $un  = Join-Path $Base "tools\Unpack_WithVerify.ps1"
    if(Test-Path $un){ powershell -NoProfile -ExecutionPolicy Bypass -File $un -Zip $zip.FullName -OutDir $out | Out-Null }
  }
}

# stamp COMPLETE and update status_summary.md
"ok" | Set-Content (Join-Path $Sig "roadmap-phase-1-complete.ok") -Encoding ASCII
$ss = Join-Path $Rep "status_summary.md"
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "Phase 1: ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE  ($now)"
if(Test-Path $ss){
  $cur = Get-Content $ss -Raw
  if($cur -notmatch 'Phase 1:\s*ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE'){ ($line + "`r`n" + $cur) | Set-Content $ss -Encoding UTF8 }
  else { $cur | Set-Content $ss -Encoding UTF8 }
}else{
  $line | Set-Content $ss -Encoding UTF8
}
Write-Host "`n[ OK ] Phase 1 VALIDATED and STAMPED COMPLETE." -ForegroundColor Green


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.0.0
# Updated: 2025-11-03 22:30:41
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep "signals"
$Dist = Join-Path $Base "dist"
$need = @(
  # structure/packaging
  "system-structure-portable-base.ok","system-structure-manifest.ok","system-structure-portable-manifest.ok",
  "system-structure-prereqs.ok","system-structure-prereq.ok","system-structure-onefolder.ok",
  "system-structure-package.ok","system-structure-pack-unpack.ok","system-structure-roadmap-integrity.ok",
  "system-structure-env-discovery.ok","system-structure-version-stamp.ok","system-structure-startstop.ok",
  "system-structure-install-log.ok","system-structure-config-sample.ok","system-structure-license-notice.ok",
  "system-structure-prereq-cache.ok","system-structure-bootstrap-sanity.ok","system-structure-uninstall-script.ok",
  "system-structure-first-run-wizard.ok","system-structure-compatibility-check.ok",
  # logging/telemetry
  "logging-telemetry.ok","logging-telemetry-structured-log-format-json-lines.ok","logging-telemetry-heartbeat.ok",
  # watchdog/governor
  "watchdog-governor.ok","watchdog-governor-sidecar-7000-sentinel.ok",
  # safety
  "safety-guardrails.ok","safety-guardrails-kill-switch-hotkey.ok","safety-guardrails-money-loop-hard-off-when-unstable.ok",
  "safety-guardrails-file-scope.ok","safety-guardrails-command-allowlist.ok",
  # dashboard/ux
  "dashboard-ux.ok","dashboard-ux-status-banner-green-amber-red-logic.ok",
  "dashboard-ux-copy-status-to-clipboard.ok","dashboard-ux-open-logs-folder-button.ok",
  "dashboard-ux-queue-browser-peek-top-n.ok","dashboard-ux-next-hint-updated.ok",
  # automation
  "automation-schedules-task-scheduler-verifier.ok"
)
$have = @{}
if(Test-Path $Sig){ Get-ChildItem $Sig -Filter *.ok | % { $have[$_.Name.ToLower()]=1 } }
$missing = @()
foreach($s in $need){ if(-not $have[$s.ToLower()]){ $missing += $s } }

if($missing.Count -gt 0){
  Write-Host "`n[FAIL] Phase 1 validator ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â MISSING signals:" -ForegroundColor Red
  $missing | % { Write-Host " - $_" -ForegroundColor Yellow }
  exit 1
}

# pack + integrity verify
$pack = Join-Path $Base "tools\Pack_Bundle.ps1"
if(Test-Path $pack){
  powershell -NoProfile -ExecutionPolicy Bypass -File $pack | Out-Null
  $zip = (Get-Item (Join-Path $Dist "mason2-*.zip") | Sort-Object LastWriteTime -desc | Select-Object -First 1)
  if($zip){
    $out = Join-Path $Dist ("unpacked-verify-" + $zip.BaseName)
    $un  = Join-Path $Base "tools\Unpack_WithVerify.ps1"
    if(Test-Path $un){ powershell -NoProfile -ExecutionPolicy Bypass -File $un -Zip $zip.FullName -OutDir $out | Out-Null }
  }
}

# stamp COMPLETE and update status_summary.md
"ok" | Set-Content (Join-Path $Sig "roadmap-phase-1-complete.ok") -Encoding ASCII
$ss = Join-Path $Rep "status_summary.md"
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$line = "Phase 1: ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE  ($now)"
if(Test-Path $ss){
  $cur = Get-Content $ss -Raw
  if($cur -notmatch 'Phase 1:\s*ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ COMPLETE'){ ($line + "`r`n" + $cur) | Set-Content $ss -Encoding UTF8 }
  else { $cur | Set-Content $ss -Encoding UTF8 }
}else{
  $line | Set-Content $ss -Encoding UTF8
}
Write-Host "`n[ OK ] Phase 1 VALIDATED and STAMPED COMPLETE." -ForegroundColor Green


