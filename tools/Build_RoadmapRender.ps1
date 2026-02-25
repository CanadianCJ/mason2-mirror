# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_RoadmapRender.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$out   = Join-Path $Base "reports\roadmap_render.md"
$Sdir  = Join-Path $Base "reports\signals"
if(-not (Test-Path $phase)){ throw "Missing: $phase" }

$have = @{}
if(Test-Path $Sdir){ Get-ChildItem $Sdir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }
function HasAny($arr){ foreach($x in $arr){ if($have[$x.ToLower()]){ return $true } } return $false }
function Norm([string]$s){ if($null -eq $s){return ""}; return ($s.ToLower() -replace "[^a-z0-9]+","") }

# Add detection for the signals you actually have
$map = @(
  @{ sigs=@("system-structure-package.ok","system-structure-pack-unpack.ok"); keys=@("pack/unpack","portable zip","+ sha256","integrity check") },
  @{ sigs=@("system-structure-roadmap-integrity.ok");                        keys=@("roadmap integrity hashing","phase 1 hash") },
  @{ sigs=@("system-structure-first-run-wizard.ok");                         keys=@("first-run wizard","writes .env") },
  @{ sigs=@("system-structure-compatibility-check.ok");                      keys=@("compatibility check","os build","locale") },
  @{ sigs=@("automation-schedules-task-scheduler-verifier.ok");              keys=@("task scheduler entries verifier","scheduled tasks verifier") },
  @{ sigs=@("safety-guardrails-file-scope.ok");                              keys=@("file write scoping to mason root","file write scoping") },
  @{ sigs=@("safety-guardrails-command-allowlist.ok");                       keys=@("command allowlist for scripts","command allowlist") },

  @{ sigs=@("system-structure-config-sample.ok");     keys=@("config sample generator","config sample") },
  @{ sigs=@("system-structure-license-notice.ok");    keys=@("portable license","notice") },
  @{ sigs=@("system-structure-prereq-cache.ok");      keys=@("prereq cache","downloads once") },
  @{ sigs=@("system-structure-bootstrap-sanity.ok");  keys=@("bootstrap sanity","sanity prompts") },
  @{ sigs=@("system-structure-uninstall-script.ok");  keys=@("uninstall script","residue cleanup") },

  @{ sigs=@("system-structure-env-discovery.ok");      keys=@("environment discovery","dev/prod","dev","prod") },
  @{ sigs=@("system-structure-version-stamp.ok");      keys=@("version stamp","version in header") },
  @{ sigs=@("system-structure-startstop.ok");          keys=@("start/stop scripts") },
  @{ sigs=@("system-structure-install-log.ok");        keys=@("install log","return codes") },
  @{ sigs=@("logging-telemetry-heartbeat.ok");         keys=@("heartbeat event every minute","heartbeat") },

  # Packaging / Structure
  @{ sigs=@("system-structure-portable-manifest.ok"); keys=@("portable manifest","manifest (paths","versions","sha256)") },
  @{ sigs=@("system-structure-prereq.ok","system-structure-prereqs.ok"); keys=@("bootstrap script validates prerequisites","prereq","powershell","tls",".net") },
  @{ sigs=@("system-structure-onefolder.ok"); keys=@("one-folder install","relative paths only") },
  @{ sigs=@("system-structure-package.ok"); keys=@("portable zip","+ sha256","dist zip") },
  @{ sigs=@("system-structure-pack-unpack.ok"); keys=@("pack/unpack","integrity check","unpack verify") },
  @{ sigs=@("system-structure-roadmap-integrity.ok"); keys=@("roadmap integrity hashing","phase 1 hash","schema check") },

  # Logging & Telemetry
  @{ sigs=@("logging-telemetry-structured-log-format-json-lines.ok"); keys=@("structured log format","json lines") },

  # Watchdog & Governor
  @{ sigs=@("watchdog-governor.ok"); keys=@("watchdog","governor") },
  @{ sigs=@("watchdog-governor-sidecar-7000-sentinel.ok"); keys=@("sidecar-7000 sentinel","sidecar 7000") },

  # Safety & Guardrails
  @{ sigs=@("safety-guardrails-kill-switch-hotkey.ok"); keys=@("kill switch hotkey","kill switch") },
  @{ sigs=@("safety-guardrails-money-loop-hard-off-when-unstable.ok"); keys=@("money loop hard-off") },

  # Dashboard & UX
  @{ sigs=@("dashboard-ux-status-banner-green-amber-red-logic.ok"); keys=@("status banner (green/amber/red)","status banner") },
  @{ sigs=@("dashboard-ux-copy-status-to-clipboard.ok"); keys=@("copy status to clipboard") },
  @{ sigs=@("dashboard-ux-open-logs-folder-button.ok"); keys=@("open logs folder button","open logs") },
  @{ sigs=@("dashboard-ux-queue-browser-peek-top-n.ok"); keys=@("queue browser","peek top n") },
  @{ sigs=@("dashboard-ux-next-hint-updated.ok"); keys=@("next hint","next-hint") }
)

$src = Get-Content $phase
$lines = @("# Roadmap (read-only, auto-colored)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
foreach($raw in $src){
  $t = $raw.TrimEnd()
  if($t -eq ""){ $lines += ""; continue }
  if($t -match "^\s*#"){ $lines += $t; continue }
  if($t -match "^\s*\[.*\]"){ $lines += $t; continue }

  $done = $false
  if($t -match "(?i)\[\s*x\s*\]"){ $done = $true }
  else{
    $tn = Norm($t)
  if(Test-Path (Join-Path $Sdir ('phase1-' + $tn + '.ok'))){ $done = $true }
foreach($m in $map){
      if(-not (HasAny $m.sigs)){ continue }
      foreach($k in $m.keys){
        if((Norm($k)) -ne "" -and $tn.Contains((Norm($k)))){ $done = $true; break }
      }
      if($done){ break }
    }
  }

  $label = ($t -replace "^\s*[-\*]\s*\[\s*[xX ]\s*\]\s*","") -replace "^\s*[-\*]\s*",""
  $prefix = if($done){"ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ($prefix + " " + $label)
}
$lines | Set-Content -Path $out -Encoding UTF8
Ok ("Rendered -> " + $out)






_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_RoadmapRender.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$out   = Join-Path $Base "reports\roadmap_render.md"
$Sdir  = Join-Path $Base "reports\signals"
if(-not (Test-Path $phase)){ throw "Missing: $phase" }

$have = @{}
if(Test-Path $Sdir){ Get-ChildItem $Sdir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }
function HasAny($arr){ foreach($x in $arr){ if($have[$x.ToLower()]){ return $true } } return $false }
function Norm([string]$s){ if($null -eq $s){return ""}; return ($s.ToLower() -replace "[^a-z0-9]+","") }

# Add detection for the signals you actually have
$map = @(
  @{ sigs=@("system-structure-package.ok","system-structure-pack-unpack.ok"); keys=@("pack/unpack","portable zip","+ sha256","integrity check") },
  @{ sigs=@("system-structure-roadmap-integrity.ok");                        keys=@("roadmap integrity hashing","phase 1 hash") },
  @{ sigs=@("system-structure-first-run-wizard.ok");                         keys=@("first-run wizard","writes .env") },
  @{ sigs=@("system-structure-compatibility-check.ok");                      keys=@("compatibility check","os build","locale") },
  @{ sigs=@("automation-schedules-task-scheduler-verifier.ok");              keys=@("task scheduler entries verifier","scheduled tasks verifier") },
  @{ sigs=@("safety-guardrails-file-scope.ok");                              keys=@("file write scoping to mason root","file write scoping") },
  @{ sigs=@("safety-guardrails-command-allowlist.ok");                       keys=@("command allowlist for scripts","command allowlist") },

  @{ sigs=@("system-structure-config-sample.ok");     keys=@("config sample generator","config sample") },
  @{ sigs=@("system-structure-license-notice.ok");    keys=@("portable license","notice") },
  @{ sigs=@("system-structure-prereq-cache.ok");      keys=@("prereq cache","downloads once") },
  @{ sigs=@("system-structure-bootstrap-sanity.ok");  keys=@("bootstrap sanity","sanity prompts") },
  @{ sigs=@("system-structure-uninstall-script.ok");  keys=@("uninstall script","residue cleanup") },

  @{ sigs=@("system-structure-env-discovery.ok");      keys=@("environment discovery","dev/prod","dev","prod") },
  @{ sigs=@("system-structure-version-stamp.ok");      keys=@("version stamp","version in header") },
  @{ sigs=@("system-structure-startstop.ok");          keys=@("start/stop scripts") },
  @{ sigs=@("system-structure-install-log.ok");        keys=@("install log","return codes") },
  @{ sigs=@("logging-telemetry-heartbeat.ok");         keys=@("heartbeat event every minute","heartbeat") },

  # Packaging / Structure
  @{ sigs=@("system-structure-portable-manifest.ok"); keys=@("portable manifest","manifest (paths","versions","sha256)") },
  @{ sigs=@("system-structure-prereq.ok","system-structure-prereqs.ok"); keys=@("bootstrap script validates prerequisites","prereq","powershell","tls",".net") },
  @{ sigs=@("system-structure-onefolder.ok"); keys=@("one-folder install","relative paths only") },
  @{ sigs=@("system-structure-package.ok"); keys=@("portable zip","+ sha256","dist zip") },
  @{ sigs=@("system-structure-pack-unpack.ok"); keys=@("pack/unpack","integrity check","unpack verify") },
  @{ sigs=@("system-structure-roadmap-integrity.ok"); keys=@("roadmap integrity hashing","phase 1 hash","schema check") },

  # Logging & Telemetry
  @{ sigs=@("logging-telemetry-structured-log-format-json-lines.ok"); keys=@("structured log format","json lines") },

  # Watchdog & Governor
  @{ sigs=@("watchdog-governor.ok"); keys=@("watchdog","governor") },
  @{ sigs=@("watchdog-governor-sidecar-7000-sentinel.ok"); keys=@("sidecar-7000 sentinel","sidecar 7000") },

  # Safety & Guardrails
  @{ sigs=@("safety-guardrails-kill-switch-hotkey.ok"); keys=@("kill switch hotkey","kill switch") },
  @{ sigs=@("safety-guardrails-money-loop-hard-off-when-unstable.ok"); keys=@("money loop hard-off") },

  # Dashboard & UX
  @{ sigs=@("dashboard-ux-status-banner-green-amber-red-logic.ok"); keys=@("status banner (green/amber/red)","status banner") },
  @{ sigs=@("dashboard-ux-copy-status-to-clipboard.ok"); keys=@("copy status to clipboard") },
  @{ sigs=@("dashboard-ux-open-logs-folder-button.ok"); keys=@("open logs folder button","open logs") },
  @{ sigs=@("dashboard-ux-queue-browser-peek-top-n.ok"); keys=@("queue browser","peek top n") },
  @{ sigs=@("dashboard-ux-next-hint-updated.ok"); keys=@("next hint","next-hint") }
)

$src = Get-Content $phase
$lines = @("# Roadmap (read-only, auto-colored)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
foreach($raw in $src){
  $t = $raw.TrimEnd()
  if($t -eq ""){ $lines += ""; continue }
  if($t -match "^\s*#"){ $lines += $t; continue }
  if($t -match "^\s*\[.*\]"){ $lines += $t; continue }

  $done = $false
  if($t -match "(?i)\[\s*x\s*\]"){ $done = $true }
  else{
    $tn = Norm($t)
  if(Test-Path (Join-Path $Sdir ('phase1-' + $tn + '.ok'))){ $done = $true }
foreach($m in $map){
      if(-not (HasAny $m.sigs)){ continue }
      foreach($k in $m.keys){
        if((Norm($k)) -ne "" -and $tn.Contains((Norm($k)))){ $done = $true; break }
      }
      if($done){ break }
    }
  }

  $label = ($t -replace "^\s*[-\*]\s*\[\s*[xX ]\s*\]\s*","") -replace "^\s*[-\*]\s*",""
  $prefix = if($done){"ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ($prefix + " " + $label)
}
$lines | Set-Content -Path $out -Encoding UTF8
Ok ("Rendered -> " + $out)






_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_RoadmapRender.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$out   = Join-Path $Base "reports\roadmap_render.md"
$Sdir  = Join-Path $Base "reports\signals"
if(-not (Test-Path $phase)){ throw "Missing: $phase" }

$have = @{}
if(Test-Path $Sdir){ Get-ChildItem $Sdir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }
function HasAny($arr){ foreach($x in $arr){ if($have[$x.ToLower()]){ return $true } } return $false }
function Norm([string]$s){ if($null -eq $s){return ""}; return ($s.ToLower() -replace "[^a-z0-9]+","") }

# Add detection for the signals you actually have
$map = @(
  @{ sigs=@("system-structure-package.ok","system-structure-pack-unpack.ok"); keys=@("pack/unpack","portable zip","+ sha256","integrity check") },
  @{ sigs=@("system-structure-roadmap-integrity.ok");                        keys=@("roadmap integrity hashing","phase 1 hash") },
  @{ sigs=@("system-structure-first-run-wizard.ok");                         keys=@("first-run wizard","writes .env") },
  @{ sigs=@("system-structure-compatibility-check.ok");                      keys=@("compatibility check","os build","locale") },
  @{ sigs=@("automation-schedules-task-scheduler-verifier.ok");              keys=@("task scheduler entries verifier","scheduled tasks verifier") },
  @{ sigs=@("safety-guardrails-file-scope.ok");                              keys=@("file write scoping to mason root","file write scoping") },
  @{ sigs=@("safety-guardrails-command-allowlist.ok");                       keys=@("command allowlist for scripts","command allowlist") },

  @{ sigs=@("system-structure-config-sample.ok");     keys=@("config sample generator","config sample") },
  @{ sigs=@("system-structure-license-notice.ok");    keys=@("portable license","notice") },
  @{ sigs=@("system-structure-prereq-cache.ok");      keys=@("prereq cache","downloads once") },
  @{ sigs=@("system-structure-bootstrap-sanity.ok");  keys=@("bootstrap sanity","sanity prompts") },
  @{ sigs=@("system-structure-uninstall-script.ok");  keys=@("uninstall script","residue cleanup") },

  @{ sigs=@("system-structure-env-discovery.ok");      keys=@("environment discovery","dev/prod","dev","prod") },
  @{ sigs=@("system-structure-version-stamp.ok");      keys=@("version stamp","version in header") },
  @{ sigs=@("system-structure-startstop.ok");          keys=@("start/stop scripts") },
  @{ sigs=@("system-structure-install-log.ok");        keys=@("install log","return codes") },
  @{ sigs=@("logging-telemetry-heartbeat.ok");         keys=@("heartbeat event every minute","heartbeat") },

  # Packaging / Structure
  @{ sigs=@("system-structure-portable-manifest.ok"); keys=@("portable manifest","manifest (paths","versions","sha256)") },
  @{ sigs=@("system-structure-prereq.ok","system-structure-prereqs.ok"); keys=@("bootstrap script validates prerequisites","prereq","powershell","tls",".net") },
  @{ sigs=@("system-structure-onefolder.ok"); keys=@("one-folder install","relative paths only") },
  @{ sigs=@("system-structure-package.ok"); keys=@("portable zip","+ sha256","dist zip") },
  @{ sigs=@("system-structure-pack-unpack.ok"); keys=@("pack/unpack","integrity check","unpack verify") },
  @{ sigs=@("system-structure-roadmap-integrity.ok"); keys=@("roadmap integrity hashing","phase 1 hash","schema check") },

  # Logging & Telemetry
  @{ sigs=@("logging-telemetry-structured-log-format-json-lines.ok"); keys=@("structured log format","json lines") },

  # Watchdog & Governor
  @{ sigs=@("watchdog-governor.ok"); keys=@("watchdog","governor") },
  @{ sigs=@("watchdog-governor-sidecar-7000-sentinel.ok"); keys=@("sidecar-7000 sentinel","sidecar 7000") },

  # Safety & Guardrails
  @{ sigs=@("safety-guardrails-kill-switch-hotkey.ok"); keys=@("kill switch hotkey","kill switch") },
  @{ sigs=@("safety-guardrails-money-loop-hard-off-when-unstable.ok"); keys=@("money loop hard-off") },

  # Dashboard & UX
  @{ sigs=@("dashboard-ux-status-banner-green-amber-red-logic.ok"); keys=@("status banner (green/amber/red)","status banner") },
  @{ sigs=@("dashboard-ux-copy-status-to-clipboard.ok"); keys=@("copy status to clipboard") },
  @{ sigs=@("dashboard-ux-open-logs-folder-button.ok"); keys=@("open logs folder button","open logs") },
  @{ sigs=@("dashboard-ux-queue-browser-peek-top-n.ok"); keys=@("queue browser","peek top n") },
  @{ sigs=@("dashboard-ux-next-hint-updated.ok"); keys=@("next hint","next-hint") }
)

$src = Get-Content $phase
$lines = @("# Roadmap (read-only, auto-colored)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
foreach($raw in $src){
  $t = $raw.TrimEnd()
  if($t -eq ""){ $lines += ""; continue }
  if($t -match "^\s*#"){ $lines += $t; continue }
  if($t -match "^\s*\[.*\]"){ $lines += $t; continue }

  $done = $false
  if($t -match "(?i)\[\s*x\s*\]"){ $done = $true }
  else{
    $tn = Norm($t)
  if(Test-Path (Join-Path $Sdir ('phase1-' + $tn + '.ok'))){ $done = $true }
foreach($m in $map){
      if(-not (HasAny $m.sigs)){ continue }
      foreach($k in $m.keys){
        if((Norm($k)) -ne "" -and $tn.Contains((Norm($k)))){ $done = $true; break }
      }
      if($done){ break }
    }
  }

  $label = ($t -replace "^\s*[-\*]\s*\[\s*[xX ]\s*\]\s*","") -replace "^\s*[-\*]\s*",""
  $prefix = if($done){"ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ($prefix + " " + $label)
}
$lines | Set-Content -Path $out -Encoding UTF8
Ok ("Rendered -> " + $out)






_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_RoadmapRender.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$out   = Join-Path $Base "reports\roadmap_render.md"
$Sdir  = Join-Path $Base "reports\signals"
if(-not (Test-Path $phase)){ throw "Missing: $phase" }

$have = @{}
if(Test-Path $Sdir){ Get-ChildItem $Sdir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }
function HasAny($arr){ foreach($x in $arr){ if($have[$x.ToLower()]){ return $true } } return $false }
function Norm([string]$s){ if($null -eq $s){return ""}; return ($s.ToLower() -replace "[^a-z0-9]+","") }

# Add detection for the signals you actually have
$map = @(
  @{ sigs=@("system-structure-package.ok","system-structure-pack-unpack.ok"); keys=@("pack/unpack","portable zip","+ sha256","integrity check") },
  @{ sigs=@("system-structure-roadmap-integrity.ok");                        keys=@("roadmap integrity hashing","phase 1 hash") },
  @{ sigs=@("system-structure-first-run-wizard.ok");                         keys=@("first-run wizard","writes .env") },
  @{ sigs=@("system-structure-compatibility-check.ok");                      keys=@("compatibility check","os build","locale") },
  @{ sigs=@("automation-schedules-task-scheduler-verifier.ok");              keys=@("task scheduler entries verifier","scheduled tasks verifier") },
  @{ sigs=@("safety-guardrails-file-scope.ok");                              keys=@("file write scoping to mason root","file write scoping") },
  @{ sigs=@("safety-guardrails-command-allowlist.ok");                       keys=@("command allowlist for scripts","command allowlist") },

  @{ sigs=@("system-structure-config-sample.ok");     keys=@("config sample generator","config sample") },
  @{ sigs=@("system-structure-license-notice.ok");    keys=@("portable license","notice") },
  @{ sigs=@("system-structure-prereq-cache.ok");      keys=@("prereq cache","downloads once") },
  @{ sigs=@("system-structure-bootstrap-sanity.ok");  keys=@("bootstrap sanity","sanity prompts") },
  @{ sigs=@("system-structure-uninstall-script.ok");  keys=@("uninstall script","residue cleanup") },

  @{ sigs=@("system-structure-env-discovery.ok");      keys=@("environment discovery","dev/prod","dev","prod") },
  @{ sigs=@("system-structure-version-stamp.ok");      keys=@("version stamp","version in header") },
  @{ sigs=@("system-structure-startstop.ok");          keys=@("start/stop scripts") },
  @{ sigs=@("system-structure-install-log.ok");        keys=@("install log","return codes") },
  @{ sigs=@("logging-telemetry-heartbeat.ok");         keys=@("heartbeat event every minute","heartbeat") },

  # Packaging / Structure
  @{ sigs=@("system-structure-portable-manifest.ok"); keys=@("portable manifest","manifest (paths","versions","sha256)") },
  @{ sigs=@("system-structure-prereq.ok","system-structure-prereqs.ok"); keys=@("bootstrap script validates prerequisites","prereq","powershell","tls",".net") },
  @{ sigs=@("system-structure-onefolder.ok"); keys=@("one-folder install","relative paths only") },
  @{ sigs=@("system-structure-package.ok"); keys=@("portable zip","+ sha256","dist zip") },
  @{ sigs=@("system-structure-pack-unpack.ok"); keys=@("pack/unpack","integrity check","unpack verify") },
  @{ sigs=@("system-structure-roadmap-integrity.ok"); keys=@("roadmap integrity hashing","phase 1 hash","schema check") },

  # Logging & Telemetry
  @{ sigs=@("logging-telemetry-structured-log-format-json-lines.ok"); keys=@("structured log format","json lines") },

  # Watchdog & Governor
  @{ sigs=@("watchdog-governor.ok"); keys=@("watchdog","governor") },
  @{ sigs=@("watchdog-governor-sidecar-7000-sentinel.ok"); keys=@("sidecar-7000 sentinel","sidecar 7000") },

  # Safety & Guardrails
  @{ sigs=@("safety-guardrails-kill-switch-hotkey.ok"); keys=@("kill switch hotkey","kill switch") },
  @{ sigs=@("safety-guardrails-money-loop-hard-off-when-unstable.ok"); keys=@("money loop hard-off") },

  # Dashboard & UX
  @{ sigs=@("dashboard-ux-status-banner-green-amber-red-logic.ok"); keys=@("status banner (green/amber/red)","status banner") },
  @{ sigs=@("dashboard-ux-copy-status-to-clipboard.ok"); keys=@("copy status to clipboard") },
  @{ sigs=@("dashboard-ux-open-logs-folder-button.ok"); keys=@("open logs folder button","open logs") },
  @{ sigs=@("dashboard-ux-queue-browser-peek-top-n.ok"); keys=@("queue browser","peek top n") },
  @{ sigs=@("dashboard-ux-next-hint-updated.ok"); keys=@("next hint","next-hint") }
)

$src = Get-Content $phase
$lines = @("# Roadmap (read-only, auto-colored)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
foreach($raw in $src){
  $t = $raw.TrimEnd()
  if($t -eq ""){ $lines += ""; continue }
  if($t -match "^\s*#"){ $lines += $t; continue }
  if($t -match "^\s*\[.*\]"){ $lines += $t; continue }

  $done = $false
  if($t -match "(?i)\[\s*x\s*\]"){ $done = $true }
  else{
    $tn = Norm($t)
  if(Test-Path (Join-Path $Sdir ('phase1-' + $tn + '.ok'))){ $done = $true }
foreach($m in $map){
      if(-not (HasAny $m.sigs)){ continue }
      foreach($k in $m.keys){
        if((Norm($k)) -ne "" -and $tn.Contains((Norm($k)))){ $done = $true; break }
      }
      if($done){ break }
    }
  }

  $label = ($t -replace "^\s*[-\*]\s*\[\s*[xX ]\s*\]\s*","") -replace "^\s*[-\*]\s*",""
  $prefix = if($done){"ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ($prefix + " " + $label)
}
$lines | Set-Content -Path $out -Encoding UTF8
Ok ("Rendered -> " + $out)






_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_RoadmapRender.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$out   = Join-Path $Base "reports\roadmap_render.md"
$Sdir  = Join-Path $Base "reports\signals"
if(-not (Test-Path $phase)){ throw "Missing: $phase" }

$have = @{}
if(Test-Path $Sdir){ Get-ChildItem $Sdir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }
function HasAny($arr){ foreach($x in $arr){ if($have[$x.ToLower()]){ return $true } } return $false }
function Norm([string]$s){ if($null -eq $s){return ""}; return ($s.ToLower() -replace "[^a-z0-9]+","") }

# Add detection for the signals you actually have
$map = @(
  @{ sigs=@("system-structure-package.ok","system-structure-pack-unpack.ok"); keys=@("pack/unpack","portable zip","+ sha256","integrity check") },
  @{ sigs=@("system-structure-roadmap-integrity.ok");                        keys=@("roadmap integrity hashing","phase 1 hash") },
  @{ sigs=@("system-structure-first-run-wizard.ok");                         keys=@("first-run wizard","writes .env") },
  @{ sigs=@("system-structure-compatibility-check.ok");                      keys=@("compatibility check","os build","locale") },
  @{ sigs=@("automation-schedules-task-scheduler-verifier.ok");              keys=@("task scheduler entries verifier","scheduled tasks verifier") },
  @{ sigs=@("safety-guardrails-file-scope.ok");                              keys=@("file write scoping to mason root","file write scoping") },
  @{ sigs=@("safety-guardrails-command-allowlist.ok");                       keys=@("command allowlist for scripts","command allowlist") },

  @{ sigs=@("system-structure-config-sample.ok");     keys=@("config sample generator","config sample") },
  @{ sigs=@("system-structure-license-notice.ok");    keys=@("portable license","notice") },
  @{ sigs=@("system-structure-prereq-cache.ok");      keys=@("prereq cache","downloads once") },
  @{ sigs=@("system-structure-bootstrap-sanity.ok");  keys=@("bootstrap sanity","sanity prompts") },
  @{ sigs=@("system-structure-uninstall-script.ok");  keys=@("uninstall script","residue cleanup") },

  @{ sigs=@("system-structure-env-discovery.ok");      keys=@("environment discovery","dev/prod","dev","prod") },
  @{ sigs=@("system-structure-version-stamp.ok");      keys=@("version stamp","version in header") },
  @{ sigs=@("system-structure-startstop.ok");          keys=@("start/stop scripts") },
  @{ sigs=@("system-structure-install-log.ok");        keys=@("install log","return codes") },
  @{ sigs=@("logging-telemetry-heartbeat.ok");         keys=@("heartbeat event every minute","heartbeat") },

  # Packaging / Structure
  @{ sigs=@("system-structure-portable-manifest.ok"); keys=@("portable manifest","manifest (paths","versions","sha256)") },
  @{ sigs=@("system-structure-prereq.ok","system-structure-prereqs.ok"); keys=@("bootstrap script validates prerequisites","prereq","powershell","tls",".net") },
  @{ sigs=@("system-structure-onefolder.ok"); keys=@("one-folder install","relative paths only") },
  @{ sigs=@("system-structure-package.ok"); keys=@("portable zip","+ sha256","dist zip") },
  @{ sigs=@("system-structure-pack-unpack.ok"); keys=@("pack/unpack","integrity check","unpack verify") },
  @{ sigs=@("system-structure-roadmap-integrity.ok"); keys=@("roadmap integrity hashing","phase 1 hash","schema check") },

  # Logging & Telemetry
  @{ sigs=@("logging-telemetry-structured-log-format-json-lines.ok"); keys=@("structured log format","json lines") },

  # Watchdog & Governor
  @{ sigs=@("watchdog-governor.ok"); keys=@("watchdog","governor") },
  @{ sigs=@("watchdog-governor-sidecar-7000-sentinel.ok"); keys=@("sidecar-7000 sentinel","sidecar 7000") },

  # Safety & Guardrails
  @{ sigs=@("safety-guardrails-kill-switch-hotkey.ok"); keys=@("kill switch hotkey","kill switch") },
  @{ sigs=@("safety-guardrails-money-loop-hard-off-when-unstable.ok"); keys=@("money loop hard-off") },

  # Dashboard & UX
  @{ sigs=@("dashboard-ux-status-banner-green-amber-red-logic.ok"); keys=@("status banner (green/amber/red)","status banner") },
  @{ sigs=@("dashboard-ux-copy-status-to-clipboard.ok"); keys=@("copy status to clipboard") },
  @{ sigs=@("dashboard-ux-open-logs-folder-button.ok"); keys=@("open logs folder button","open logs") },
  @{ sigs=@("dashboard-ux-queue-browser-peek-top-n.ok"); keys=@("queue browser","peek top n") },
  @{ sigs=@("dashboard-ux-next-hint-updated.ok"); keys=@("next hint","next-hint") }
)

$src = Get-Content $phase
$lines = @("# Roadmap (read-only, auto-colored)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
foreach($raw in $src){
  $t = $raw.TrimEnd()
  if($t -eq ""){ $lines += ""; continue }
  if($t -match "^\s*#"){ $lines += $t; continue }
  if($t -match "^\s*\[.*\]"){ $lines += $t; continue }

  $done = $false
  if($t -match "(?i)\[\s*x\s*\]"){ $done = $true }
  else{
    $tn = Norm($t)
  if(Test-Path (Join-Path $Sdir ('phase1-' + $tn + '.ok'))){ $done = $true }
foreach($m in $map){
      if(-not (HasAny $m.sigs)){ continue }
      foreach($k in $m.keys){
        if((Norm($k)) -ne "" -and $tn.Contains((Norm($k)))){ $done = $true; break }
      }
      if($done){ break }
    }
  }

  $label = ($t -replace "^\s*[-\*]\s*\[\s*[xX ]\s*\]\s*","") -replace "^\s*[-\*]\s*",""
  $prefix = if($done){"ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ($prefix + " " + $label)
}
$lines | Set-Content -Path $out -Encoding UTF8
Ok ("Rendered -> " + $out)






_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_RoadmapRender.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$out   = Join-Path $Base "reports\roadmap_render.md"
$Sdir  = Join-Path $Base "reports\signals"
if(-not (Test-Path $phase)){ throw "Missing: $phase" }

$have = @{}
if(Test-Path $Sdir){ Get-ChildItem $Sdir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }
function HasAny($arr){ foreach($x in $arr){ if($have[$x.ToLower()]){ return $true } } return $false }
function Norm([string]$s){ if($null -eq $s){return ""}; return ($s.ToLower() -replace "[^a-z0-9]+","") }

# Add detection for the signals you actually have
$map = @(
  @{ sigs=@("system-structure-package.ok","system-structure-pack-unpack.ok"); keys=@("pack/unpack","portable zip","+ sha256","integrity check") },
  @{ sigs=@("system-structure-roadmap-integrity.ok");                        keys=@("roadmap integrity hashing","phase 1 hash") },
  @{ sigs=@("system-structure-first-run-wizard.ok");                         keys=@("first-run wizard","writes .env") },
  @{ sigs=@("system-structure-compatibility-check.ok");                      keys=@("compatibility check","os build","locale") },
  @{ sigs=@("automation-schedules-task-scheduler-verifier.ok");              keys=@("task scheduler entries verifier","scheduled tasks verifier") },
  @{ sigs=@("safety-guardrails-file-scope.ok");                              keys=@("file write scoping to mason root","file write scoping") },
  @{ sigs=@("safety-guardrails-command-allowlist.ok");                       keys=@("command allowlist for scripts","command allowlist") },

  @{ sigs=@("system-structure-config-sample.ok");     keys=@("config sample generator","config sample") },
  @{ sigs=@("system-structure-license-notice.ok");    keys=@("portable license","notice") },
  @{ sigs=@("system-structure-prereq-cache.ok");      keys=@("prereq cache","downloads once") },
  @{ sigs=@("system-structure-bootstrap-sanity.ok");  keys=@("bootstrap sanity","sanity prompts") },
  @{ sigs=@("system-structure-uninstall-script.ok");  keys=@("uninstall script","residue cleanup") },

  @{ sigs=@("system-structure-env-discovery.ok");      keys=@("environment discovery","dev/prod","dev","prod") },
  @{ sigs=@("system-structure-version-stamp.ok");      keys=@("version stamp","version in header") },
  @{ sigs=@("system-structure-startstop.ok");          keys=@("start/stop scripts") },
  @{ sigs=@("system-structure-install-log.ok");        keys=@("install log","return codes") },
  @{ sigs=@("logging-telemetry-heartbeat.ok");         keys=@("heartbeat event every minute","heartbeat") },

  # Packaging / Structure
  @{ sigs=@("system-structure-portable-manifest.ok"); keys=@("portable manifest","manifest (paths","versions","sha256)") },
  @{ sigs=@("system-structure-prereq.ok","system-structure-prereqs.ok"); keys=@("bootstrap script validates prerequisites","prereq","powershell","tls",".net") },
  @{ sigs=@("system-structure-onefolder.ok"); keys=@("one-folder install","relative paths only") },
  @{ sigs=@("system-structure-package.ok"); keys=@("portable zip","+ sha256","dist zip") },
  @{ sigs=@("system-structure-pack-unpack.ok"); keys=@("pack/unpack","integrity check","unpack verify") },
  @{ sigs=@("system-structure-roadmap-integrity.ok"); keys=@("roadmap integrity hashing","phase 1 hash","schema check") },

  # Logging & Telemetry
  @{ sigs=@("logging-telemetry-structured-log-format-json-lines.ok"); keys=@("structured log format","json lines") },

  # Watchdog & Governor
  @{ sigs=@("watchdog-governor.ok"); keys=@("watchdog","governor") },
  @{ sigs=@("watchdog-governor-sidecar-7000-sentinel.ok"); keys=@("sidecar-7000 sentinel","sidecar 7000") },

  # Safety & Guardrails
  @{ sigs=@("safety-guardrails-kill-switch-hotkey.ok"); keys=@("kill switch hotkey","kill switch") },
  @{ sigs=@("safety-guardrails-money-loop-hard-off-when-unstable.ok"); keys=@("money loop hard-off") },

  # Dashboard & UX
  @{ sigs=@("dashboard-ux-status-banner-green-amber-red-logic.ok"); keys=@("status banner (green/amber/red)","status banner") },
  @{ sigs=@("dashboard-ux-copy-status-to-clipboard.ok"); keys=@("copy status to clipboard") },
  @{ sigs=@("dashboard-ux-open-logs-folder-button.ok"); keys=@("open logs folder button","open logs") },
  @{ sigs=@("dashboard-ux-queue-browser-peek-top-n.ok"); keys=@("queue browser","peek top n") },
  @{ sigs=@("dashboard-ux-next-hint-updated.ok"); keys=@("next hint","next-hint") }
)

$src = Get-Content $phase
$lines = @("# Roadmap (read-only, auto-colored)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
foreach($raw in $src){
  $t = $raw.TrimEnd()
  if($t -eq ""){ $lines += ""; continue }
  if($t -match "^\s*#"){ $lines += $t; continue }
  if($t -match "^\s*\[.*\]"){ $lines += $t; continue }

  $done = $false
  if($t -match "(?i)\[\s*x\s*\]"){ $done = $true }
  else{
    $tn = Norm($t)
  if(Test-Path (Join-Path $Sdir ('phase1-' + $tn + '.ok'))){ $done = $true }
foreach($m in $map){
      if(-not (HasAny $m.sigs)){ continue }
      foreach($k in $m.keys){
        if((Norm($k)) -ne "" -and $tn.Contains((Norm($k)))){ $done = $true; break }
      }
      if($done){ break }
    }
  }

  $label = ($t -replace "^\s*[-\*]\s*\[\s*[xX ]\s*\]\s*","") -replace "^\s*[-\*]\s*",""
  $prefix = if($done){"ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ($prefix + " " + $label)
}
$lines | Set-Content -Path $out -Encoding UTF8
Ok ("Rendered -> " + $out)






_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_RoadmapRender.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$out   = Join-Path $Base "reports\roadmap_render.md"
$Sdir  = Join-Path $Base "reports\signals"
if(-not (Test-Path $phase)){ throw "Missing: $phase" }

$have = @{}
if(Test-Path $Sdir){ Get-ChildItem $Sdir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }
function HasAny($arr){ foreach($x in $arr){ if($have[$x.ToLower()]){ return $true } } return $false }
function Norm([string]$s){ if($null -eq $s){return ""}; return ($s.ToLower() -replace "[^a-z0-9]+","") }

# Add detection for the signals you actually have
$map = @(
  @{ sigs=@("system-structure-package.ok","system-structure-pack-unpack.ok"); keys=@("pack/unpack","portable zip","+ sha256","integrity check") },
  @{ sigs=@("system-structure-roadmap-integrity.ok");                        keys=@("roadmap integrity hashing","phase 1 hash") },
  @{ sigs=@("system-structure-first-run-wizard.ok");                         keys=@("first-run wizard","writes .env") },
  @{ sigs=@("system-structure-compatibility-check.ok");                      keys=@("compatibility check","os build","locale") },
  @{ sigs=@("automation-schedules-task-scheduler-verifier.ok");              keys=@("task scheduler entries verifier","scheduled tasks verifier") },
  @{ sigs=@("safety-guardrails-file-scope.ok");                              keys=@("file write scoping to mason root","file write scoping") },
  @{ sigs=@("safety-guardrails-command-allowlist.ok");                       keys=@("command allowlist for scripts","command allowlist") },

  @{ sigs=@("system-structure-config-sample.ok");     keys=@("config sample generator","config sample") },
  @{ sigs=@("system-structure-license-notice.ok");    keys=@("portable license","notice") },
  @{ sigs=@("system-structure-prereq-cache.ok");      keys=@("prereq cache","downloads once") },
  @{ sigs=@("system-structure-bootstrap-sanity.ok");  keys=@("bootstrap sanity","sanity prompts") },
  @{ sigs=@("system-structure-uninstall-script.ok");  keys=@("uninstall script","residue cleanup") },

  @{ sigs=@("system-structure-env-discovery.ok");      keys=@("environment discovery","dev/prod","dev","prod") },
  @{ sigs=@("system-structure-version-stamp.ok");      keys=@("version stamp","version in header") },
  @{ sigs=@("system-structure-startstop.ok");          keys=@("start/stop scripts") },
  @{ sigs=@("system-structure-install-log.ok");        keys=@("install log","return codes") },
  @{ sigs=@("logging-telemetry-heartbeat.ok");         keys=@("heartbeat event every minute","heartbeat") },

  # Packaging / Structure
  @{ sigs=@("system-structure-portable-manifest.ok"); keys=@("portable manifest","manifest (paths","versions","sha256)") },
  @{ sigs=@("system-structure-prereq.ok","system-structure-prereqs.ok"); keys=@("bootstrap script validates prerequisites","prereq","powershell","tls",".net") },
  @{ sigs=@("system-structure-onefolder.ok"); keys=@("one-folder install","relative paths only") },
  @{ sigs=@("system-structure-package.ok"); keys=@("portable zip","+ sha256","dist zip") },
  @{ sigs=@("system-structure-pack-unpack.ok"); keys=@("pack/unpack","integrity check","unpack verify") },
  @{ sigs=@("system-structure-roadmap-integrity.ok"); keys=@("roadmap integrity hashing","phase 1 hash","schema check") },

  # Logging & Telemetry
  @{ sigs=@("logging-telemetry-structured-log-format-json-lines.ok"); keys=@("structured log format","json lines") },

  # Watchdog & Governor
  @{ sigs=@("watchdog-governor.ok"); keys=@("watchdog","governor") },
  @{ sigs=@("watchdog-governor-sidecar-7000-sentinel.ok"); keys=@("sidecar-7000 sentinel","sidecar 7000") },

  # Safety & Guardrails
  @{ sigs=@("safety-guardrails-kill-switch-hotkey.ok"); keys=@("kill switch hotkey","kill switch") },
  @{ sigs=@("safety-guardrails-money-loop-hard-off-when-unstable.ok"); keys=@("money loop hard-off") },

  # Dashboard & UX
  @{ sigs=@("dashboard-ux-status-banner-green-amber-red-logic.ok"); keys=@("status banner (green/amber/red)","status banner") },
  @{ sigs=@("dashboard-ux-copy-status-to-clipboard.ok"); keys=@("copy status to clipboard") },
  @{ sigs=@("dashboard-ux-open-logs-folder-button.ok"); keys=@("open logs folder button","open logs") },
  @{ sigs=@("dashboard-ux-queue-browser-peek-top-n.ok"); keys=@("queue browser","peek top n") },
  @{ sigs=@("dashboard-ux-next-hint-updated.ok"); keys=@("next hint","next-hint") }
)

$src = Get-Content $phase
$lines = @("# Roadmap (read-only, auto-colored)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
foreach($raw in $src){
  $t = $raw.TrimEnd()
  if($t -eq ""){ $lines += ""; continue }
  if($t -match "^\s*#"){ $lines += $t; continue }
  if($t -match "^\s*\[.*\]"){ $lines += $t; continue }

  $done = $false
  if($t -match "(?i)\[\s*x\s*\]"){ $done = $true }
  else{
    $tn = Norm($t)
  if(Test-Path (Join-Path $Sdir ('phase1-' + $tn + '.ok'))){ $done = $true }
foreach($m in $map){
      if(-not (HasAny $m.sigs)){ continue }
      foreach($k in $m.keys){
        if((Norm($k)) -ne "" -and $tn.Contains((Norm($k)))){ $done = $true; break }
      }
      if($done){ break }
    }
  }

  $label = ($t -replace "^\s*[-\*]\s*\[\s*[xX ]\s*\]\s*","") -replace "^\s*[-\*]\s*",""
  $prefix = if($done){"ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ($prefix + " " + $label)
}
$lines | Set-Content -Path $out -Encoding UTF8
Ok ("Rendered -> " + $out)






_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Build_RoadmapRender.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$phase = Join-Path $Base "roadmap\PHASE 1.txt"
$out   = Join-Path $Base "reports\roadmap_render.md"
$Sdir  = Join-Path $Base "reports\signals"
if(-not (Test-Path $phase)){ throw "Missing: $phase" }

$have = @{}
if(Test-Path $Sdir){ Get-ChildItem $Sdir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }
function HasAny($arr){ foreach($x in $arr){ if($have[$x.ToLower()]){ return $true } } return $false }
function Norm([string]$s){ if($null -eq $s){return ""}; return ($s.ToLower() -replace "[^a-z0-9]+","") }

# Add detection for the signals you actually have
$map = @(
  @{ sigs=@("system-structure-package.ok","system-structure-pack-unpack.ok"); keys=@("pack/unpack","portable zip","+ sha256","integrity check") },
  @{ sigs=@("system-structure-roadmap-integrity.ok");                        keys=@("roadmap integrity hashing","phase 1 hash") },
  @{ sigs=@("system-structure-first-run-wizard.ok");                         keys=@("first-run wizard","writes .env") },
  @{ sigs=@("system-structure-compatibility-check.ok");                      keys=@("compatibility check","os build","locale") },
  @{ sigs=@("automation-schedules-task-scheduler-verifier.ok");              keys=@("task scheduler entries verifier","scheduled tasks verifier") },
  @{ sigs=@("safety-guardrails-file-scope.ok");                              keys=@("file write scoping to mason root","file write scoping") },
  @{ sigs=@("safety-guardrails-command-allowlist.ok");                       keys=@("command allowlist for scripts","command allowlist") },

  @{ sigs=@("system-structure-config-sample.ok");     keys=@("config sample generator","config sample") },
  @{ sigs=@("system-structure-license-notice.ok");    keys=@("portable license","notice") },
  @{ sigs=@("system-structure-prereq-cache.ok");      keys=@("prereq cache","downloads once") },
  @{ sigs=@("system-structure-bootstrap-sanity.ok");  keys=@("bootstrap sanity","sanity prompts") },
  @{ sigs=@("system-structure-uninstall-script.ok");  keys=@("uninstall script","residue cleanup") },

  @{ sigs=@("system-structure-env-discovery.ok");      keys=@("environment discovery","dev/prod","dev","prod") },
  @{ sigs=@("system-structure-version-stamp.ok");      keys=@("version stamp","version in header") },
  @{ sigs=@("system-structure-startstop.ok");          keys=@("start/stop scripts") },
  @{ sigs=@("system-structure-install-log.ok");        keys=@("install log","return codes") },
  @{ sigs=@("logging-telemetry-heartbeat.ok");         keys=@("heartbeat event every minute","heartbeat") },

  # Packaging / Structure
  @{ sigs=@("system-structure-portable-manifest.ok"); keys=@("portable manifest","manifest (paths","versions","sha256)") },
  @{ sigs=@("system-structure-prereq.ok","system-structure-prereqs.ok"); keys=@("bootstrap script validates prerequisites","prereq","powershell","tls",".net") },
  @{ sigs=@("system-structure-onefolder.ok"); keys=@("one-folder install","relative paths only") },
  @{ sigs=@("system-structure-package.ok"); keys=@("portable zip","+ sha256","dist zip") },
  @{ sigs=@("system-structure-pack-unpack.ok"); keys=@("pack/unpack","integrity check","unpack verify") },
  @{ sigs=@("system-structure-roadmap-integrity.ok"); keys=@("roadmap integrity hashing","phase 1 hash","schema check") },

  # Logging & Telemetry
  @{ sigs=@("logging-telemetry-structured-log-format-json-lines.ok"); keys=@("structured log format","json lines") },

  # Watchdog & Governor
  @{ sigs=@("watchdog-governor.ok"); keys=@("watchdog","governor") },
  @{ sigs=@("watchdog-governor-sidecar-7000-sentinel.ok"); keys=@("sidecar-7000 sentinel","sidecar 7000") },

  # Safety & Guardrails
  @{ sigs=@("safety-guardrails-kill-switch-hotkey.ok"); keys=@("kill switch hotkey","kill switch") },
  @{ sigs=@("safety-guardrails-money-loop-hard-off-when-unstable.ok"); keys=@("money loop hard-off") },

  # Dashboard & UX
  @{ sigs=@("dashboard-ux-status-banner-green-amber-red-logic.ok"); keys=@("status banner (green/amber/red)","status banner") },
  @{ sigs=@("dashboard-ux-copy-status-to-clipboard.ok"); keys=@("copy status to clipboard") },
  @{ sigs=@("dashboard-ux-open-logs-folder-button.ok"); keys=@("open logs folder button","open logs") },
  @{ sigs=@("dashboard-ux-queue-browser-peek-top-n.ok"); keys=@("queue browser","peek top n") },
  @{ sigs=@("dashboard-ux-next-hint-updated.ok"); keys=@("next hint","next-hint") }
)

$src = Get-Content $phase
$lines = @("# Roadmap (read-only, auto-colored)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
foreach($raw in $src){
  $t = $raw.TrimEnd()
  if($t -eq ""){ $lines += ""; continue }
  if($t -match "^\s*#"){ $lines += $t; continue }
  if($t -match "^\s*\[.*\]"){ $lines += $t; continue }

  $done = $false
  if($t -match "(?i)\[\s*x\s*\]"){ $done = $true }
  else{
    $tn = Norm($t)
  if(Test-Path (Join-Path $Sdir ('phase1-' + $tn + '.ok'))){ $done = $true }
foreach($m in $map){
      if(-not (HasAny $m.sigs)){ continue }
      foreach($k in $m.keys){
        if((Norm($k)) -ne "" -and $tn.Contains((Norm($k)))){ $done = $true; break }
      }
      if($done){ break }
    }
  }

  $label = ($t -replace "^\s*[-\*]\s*\[\s*[xX ]\s*\]\s*","") -replace "^\s*[-\*]\s*",""
  $prefix = if($done){"ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ($prefix + " " + $label)
}
$lines | Set-Content -Path $out -Encoding UTF8
Ok ("Rendered -> " + $out)






