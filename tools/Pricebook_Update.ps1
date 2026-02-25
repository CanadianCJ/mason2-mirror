# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Pricebook_Update.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$SigDir = Join-Path $Base "reports\signals"
$RepDir = Join-Path $Base "reports"
if(-not (Test-Path $RepDir)){ New-Item -ItemType Directory -Path $RepDir | Out-Null }

# Baseline (what you asked me to track initially)
$baseFile = Join-Path $RepDir "price_base_cad.txt"
if(-not (Test-Path $baseFile)){ "2820" | Set-Content -Path $baseFile -Encoding ASCII }
[decimal]$baseline = [decimal](Get-Content $baseFile -Raw)

# NOTE: "group" rows are 0 to avoid double counting when specific rows are present.
$items = @(
  @{ sig="system-structure-package.ok";                          label="[Pkg] Portable ZIP (+SHA256)";                     cad=100 },
  @{ sig="system-structure-pack-unpack.ok";                      label="[Pkg] Pack/Unpack with integrity check";           cad=60  },
  @{ sig="system-structure-roadmap-integrity.ok";                label="[Pkg] Roadmap integrity hashing";                  cad=40  },
  @{ sig="system-structure-first-run-wizard.ok";                 label="[Pkg] First-run wizard (.env)";                    cad=30  },
  @{ sig="system-structure-compatibility-check.ok";              label="[Pkg] Compatibility check (OS/locale)";            cad=30  },
  @{ sig="automation-schedules-task-scheduler-verifier.ok";      label="[Auto] Task Scheduler entries verifier";           cad=25  },
  @{ sig="safety-guardrails-file-scope.ok";                      label="[Safety] File write scoping to Mason root";        cad=50  },
  @{ sig="safety-guardrails-command-allowlist.ok";               label="[Safety] Command allowlist wrapper";               cad=40  },

  @{ sig="system-structure-config-sample.ok";     label="[Pkg] Config sample generator";              cad=40 },
  @{ sig="system-structure-license-notice.ok";    label="[Pkg] Portable license/notice file set";     cad=20 },
  @{ sig="system-structure-prereq-cache.ok";      label="[Pkg] Prereq cache (download once)";         cad=40 },
  @{ sig="system-structure-bootstrap-sanity.ok";  label="[Pkg] Bootstrap sanity prompts";             cad=30 },
  @{ sig="system-structure-uninstall-script.ok";  label="[Pkg] Uninstall script (residue cleanup)";   cad=50 },

  @{ sig="system-structure-env-discovery.ok";  label="[Pkg] Environment discovery (dev/prod) toggle"; cad=40 },
  @{ sig="system-structure-version-stamp.ok";  label="[Pkg] Version stamp in script headers";        cad=50 },
  @{ sig="system-structure-startstop.ok";      label="[Pkg] Start/Stop scripts for services";        cad=60 },
  @{ sig="system-structure-install-log.ok";    label="[Pkg] Install log with return codes";          cad=30 },
  @{ sig="logging-telemetry-heartbeat.ok";     label="[Logs] Heartbeat every minute";                cad=20 },
  # System Structure & Packaging
  @{ sig="system-structure-portable-base.ok";   label="[Pkg] Portable base structure";                 cad=0 }
  @{ sig="system-structure-manifest.ok";        label="[Pkg] Manifest (generic)";                      cad=0 }
  @{ sig="system-structure-portable-manifest.ok";label="[Pkg] Portable manifest (paths/versions/SHA)"; cad=120 }
  @{ sig="system-structure-prereqs.ok";         label="[Pkg] Prereqs (compat signal)";                 cad=0 }
  @{ sig="system-structure-prereq.ok";          label="[Pkg] Bootstrap: prerequisites verified";       cad=80 }
  @{ sig="system-structure-onefolder.ok";       label="[Pkg] One-folder install (relative paths)";     cad=150 }
  @{ sig="system-structure-package.ok";         label="[Pkg] Portable ZIP (+SHA256)";                  cad=100 }
  @{ sig="system-structure-pack-unpack.ok";     label="[Pkg] Pack/Unpack with integrity check";        cad=60 }
  @{ sig="system-structure-roadmap-integrity.ok";label="[Pkg] Roadmap integrity hashing";              cad=40 }

  # Logging & Telemetry
  @{ sig="logging-telemetry.ok";                              label="[Logs] Core logging/telemetry wiring";    cad=0 }
  @{ sig="logging-telemetry-structured-log-format-json-lines.ok"; label="[Logs] Structured JSON log lines";     cad=40 }

  # Watchdog & Governor
  @{ sig="watchdog-governor.ok";                   label="[Watchdog] Core watchdog/governor";           cad=140 }
  @{ sig="watchdog-governor-sidecar-7000-sentinel.ok"; label="[Watchdog] Sidecar-7000 sentinel";        cad=30 }

  # Safety & Guardrails
  @{ sig="safety-guardrails.ok";                   label="[Safety] Guardrails baseline";                cad=120 }
  @{ sig="safety-guardrails-kill-switch-hotkey.ok";label="[Safety] Kill-switch hotkey";                cad=40 }
  @{ sig="safety-guardrails-money-loop-hard-off-when-unstable.ok"; label="[Safety] Money loop hard-off"; cad=0 }

  # Dashboard & UX
  @{ sig="dashboard-ux.ok";                        label="[UI] Dashboard/UX baseline";                  cad=0 }
  @{ sig="dashboard-ux-status-banner-green-amber-red-logic.ok"; label="[UI] Status banner (G/A/R)";     cad=40 }
  @{ sig="dashboard-ux-copy-status-to-clipboard.ok"; label="[UI] Copy status to clipboard";            cad=10 }
  @{ sig="dashboard-ux-open-logs-folder-button.ok"; label="[UI] Open logs button";                     cad=10 }
  @{ sig="dashboard-ux-queue-browser-peek-top-n.ok"; label="[UI] Queue browser (peek N)";              cad=20 }
  @{ sig="dashboard-ux-next-hint-updated.ok";      label="[UI] Auto Next-hint writer";                  cad=10 }

  # Admin/meta
  @{ sig="roadmap-phase-1-activated.ok";          label="[Meta] Phase 1 activated";                     cad=0 }
)

# Signals we have
$have = @{}
if(Test-Path $SigDir){ Get-ChildItem $SigDir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }

# Build output
$lines = @("# Price / Line Items (CAD)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
[decimal]$total = $baseline
foreach($it in $items){
  $hit = $false; if($have[$it.sig]){ $hit = $true }
  [decimal]$amt = 0; if($hit){ $amt = [decimal]$it.cad }
  $mark = if($hit){"ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â©"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ("{0} {1} ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ${2}" -f $mark, $it.label, $it.cad)
  $total += $amt
}

$priceDir = Join-Path $RepDir "price"
$totFile  = Join-Path $priceDir "total_cad.txt"
$logFile  = Join-Path $priceDir "line_items.md"
[math]::Round($total,2).ToString() | Set-Content -Path $totFile -Encoding ASCII
$lines | Set-Content -Path $logFile -Encoding UTF8
Ok ("Total CAD -> " + (Get-Content $totFile -Raw))
Ok ("Line items  -> " + $logFile)





_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Pricebook_Update.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$SigDir = Join-Path $Base "reports\signals"
$RepDir = Join-Path $Base "reports"
if(-not (Test-Path $RepDir)){ New-Item -ItemType Directory -Path $RepDir | Out-Null }

# Baseline (what you asked me to track initially)
$baseFile = Join-Path $RepDir "price_base_cad.txt"
if(-not (Test-Path $baseFile)){ "2820" | Set-Content -Path $baseFile -Encoding ASCII }
[decimal]$baseline = [decimal](Get-Content $baseFile -Raw)

# NOTE: "group" rows are 0 to avoid double counting when specific rows are present.
$items = @(
  @{ sig="system-structure-package.ok";                          label="[Pkg] Portable ZIP (+SHA256)";                     cad=100 },
  @{ sig="system-structure-pack-unpack.ok";                      label="[Pkg] Pack/Unpack with integrity check";           cad=60  },
  @{ sig="system-structure-roadmap-integrity.ok";                label="[Pkg] Roadmap integrity hashing";                  cad=40  },
  @{ sig="system-structure-first-run-wizard.ok";                 label="[Pkg] First-run wizard (.env)";                    cad=30  },
  @{ sig="system-structure-compatibility-check.ok";              label="[Pkg] Compatibility check (OS/locale)";            cad=30  },
  @{ sig="automation-schedules-task-scheduler-verifier.ok";      label="[Auto] Task Scheduler entries verifier";           cad=25  },
  @{ sig="safety-guardrails-file-scope.ok";                      label="[Safety] File write scoping to Mason root";        cad=50  },
  @{ sig="safety-guardrails-command-allowlist.ok";               label="[Safety] Command allowlist wrapper";               cad=40  },

  @{ sig="system-structure-config-sample.ok";     label="[Pkg] Config sample generator";              cad=40 },
  @{ sig="system-structure-license-notice.ok";    label="[Pkg] Portable license/notice file set";     cad=20 },
  @{ sig="system-structure-prereq-cache.ok";      label="[Pkg] Prereq cache (download once)";         cad=40 },
  @{ sig="system-structure-bootstrap-sanity.ok";  label="[Pkg] Bootstrap sanity prompts";             cad=30 },
  @{ sig="system-structure-uninstall-script.ok";  label="[Pkg] Uninstall script (residue cleanup)";   cad=50 },

  @{ sig="system-structure-env-discovery.ok";  label="[Pkg] Environment discovery (dev/prod) toggle"; cad=40 },
  @{ sig="system-structure-version-stamp.ok";  label="[Pkg] Version stamp in script headers";        cad=50 },
  @{ sig="system-structure-startstop.ok";      label="[Pkg] Start/Stop scripts for services";        cad=60 },
  @{ sig="system-structure-install-log.ok";    label="[Pkg] Install log with return codes";          cad=30 },
  @{ sig="logging-telemetry-heartbeat.ok";     label="[Logs] Heartbeat every minute";                cad=20 },
  # System Structure & Packaging
  @{ sig="system-structure-portable-base.ok";   label="[Pkg] Portable base structure";                 cad=0 }
  @{ sig="system-structure-manifest.ok";        label="[Pkg] Manifest (generic)";                      cad=0 }
  @{ sig="system-structure-portable-manifest.ok";label="[Pkg] Portable manifest (paths/versions/SHA)"; cad=120 }
  @{ sig="system-structure-prereqs.ok";         label="[Pkg] Prereqs (compat signal)";                 cad=0 }
  @{ sig="system-structure-prereq.ok";          label="[Pkg] Bootstrap: prerequisites verified";       cad=80 }
  @{ sig="system-structure-onefolder.ok";       label="[Pkg] One-folder install (relative paths)";     cad=150 }
  @{ sig="system-structure-package.ok";         label="[Pkg] Portable ZIP (+SHA256)";                  cad=100 }
  @{ sig="system-structure-pack-unpack.ok";     label="[Pkg] Pack/Unpack with integrity check";        cad=60 }
  @{ sig="system-structure-roadmap-integrity.ok";label="[Pkg] Roadmap integrity hashing";              cad=40 }

  # Logging & Telemetry
  @{ sig="logging-telemetry.ok";                              label="[Logs] Core logging/telemetry wiring";    cad=0 }
  @{ sig="logging-telemetry-structured-log-format-json-lines.ok"; label="[Logs] Structured JSON log lines";     cad=40 }

  # Watchdog & Governor
  @{ sig="watchdog-governor.ok";                   label="[Watchdog] Core watchdog/governor";           cad=140 }
  @{ sig="watchdog-governor-sidecar-7000-sentinel.ok"; label="[Watchdog] Sidecar-7000 sentinel";        cad=30 }

  # Safety & Guardrails
  @{ sig="safety-guardrails.ok";                   label="[Safety] Guardrails baseline";                cad=120 }
  @{ sig="safety-guardrails-kill-switch-hotkey.ok";label="[Safety] Kill-switch hotkey";                cad=40 }
  @{ sig="safety-guardrails-money-loop-hard-off-when-unstable.ok"; label="[Safety] Money loop hard-off"; cad=0 }

  # Dashboard & UX
  @{ sig="dashboard-ux.ok";                        label="[UI] Dashboard/UX baseline";                  cad=0 }
  @{ sig="dashboard-ux-status-banner-green-amber-red-logic.ok"; label="[UI] Status banner (G/A/R)";     cad=40 }
  @{ sig="dashboard-ux-copy-status-to-clipboard.ok"; label="[UI] Copy status to clipboard";            cad=10 }
  @{ sig="dashboard-ux-open-logs-folder-button.ok"; label="[UI] Open logs button";                     cad=10 }
  @{ sig="dashboard-ux-queue-browser-peek-top-n.ok"; label="[UI] Queue browser (peek N)";              cad=20 }
  @{ sig="dashboard-ux-next-hint-updated.ok";      label="[UI] Auto Next-hint writer";                  cad=10 }

  # Admin/meta
  @{ sig="roadmap-phase-1-activated.ok";          label="[Meta] Phase 1 activated";                     cad=0 }
)

# Signals we have
$have = @{}
if(Test-Path $SigDir){ Get-ChildItem $SigDir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }

# Build output
$lines = @("# Price / Line Items (CAD)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
[decimal]$total = $baseline
foreach($it in $items){
  $hit = $false; if($have[$it.sig]){ $hit = $true }
  [decimal]$amt = 0; if($hit){ $amt = [decimal]$it.cad }
  $mark = if($hit){"ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â©"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ("{0} {1} ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ${2}" -f $mark, $it.label, $it.cad)
  $total += $amt
}

$priceDir = Join-Path $RepDir "price"
$totFile  = Join-Path $priceDir "total_cad.txt"
$logFile  = Join-Path $priceDir "line_items.md"
[math]::Round($total,2).ToString() | Set-Content -Path $totFile -Encoding ASCII
$lines | Set-Content -Path $logFile -Encoding UTF8
Ok ("Total CAD -> " + (Get-Content $totFile -Raw))
Ok ("Line items  -> " + $logFile)





_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Pricebook_Update.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$SigDir = Join-Path $Base "reports\signals"
$RepDir = Join-Path $Base "reports"
if(-not (Test-Path $RepDir)){ New-Item -ItemType Directory -Path $RepDir | Out-Null }

# Baseline (what you asked me to track initially)
$baseFile = Join-Path $RepDir "price_base_cad.txt"
if(-not (Test-Path $baseFile)){ "2820" | Set-Content -Path $baseFile -Encoding ASCII }
[decimal]$baseline = [decimal](Get-Content $baseFile -Raw)

# NOTE: "group" rows are 0 to avoid double counting when specific rows are present.
$items = @(
  @{ sig="system-structure-package.ok";                          label="[Pkg] Portable ZIP (+SHA256)";                     cad=100 },
  @{ sig="system-structure-pack-unpack.ok";                      label="[Pkg] Pack/Unpack with integrity check";           cad=60  },
  @{ sig="system-structure-roadmap-integrity.ok";                label="[Pkg] Roadmap integrity hashing";                  cad=40  },
  @{ sig="system-structure-first-run-wizard.ok";                 label="[Pkg] First-run wizard (.env)";                    cad=30  },
  @{ sig="system-structure-compatibility-check.ok";              label="[Pkg] Compatibility check (OS/locale)";            cad=30  },
  @{ sig="automation-schedules-task-scheduler-verifier.ok";      label="[Auto] Task Scheduler entries verifier";           cad=25  },
  @{ sig="safety-guardrails-file-scope.ok";                      label="[Safety] File write scoping to Mason root";        cad=50  },
  @{ sig="safety-guardrails-command-allowlist.ok";               label="[Safety] Command allowlist wrapper";               cad=40  },

  @{ sig="system-structure-config-sample.ok";     label="[Pkg] Config sample generator";              cad=40 },
  @{ sig="system-structure-license-notice.ok";    label="[Pkg] Portable license/notice file set";     cad=20 },
  @{ sig="system-structure-prereq-cache.ok";      label="[Pkg] Prereq cache (download once)";         cad=40 },
  @{ sig="system-structure-bootstrap-sanity.ok";  label="[Pkg] Bootstrap sanity prompts";             cad=30 },
  @{ sig="system-structure-uninstall-script.ok";  label="[Pkg] Uninstall script (residue cleanup)";   cad=50 },

  @{ sig="system-structure-env-discovery.ok";  label="[Pkg] Environment discovery (dev/prod) toggle"; cad=40 },
  @{ sig="system-structure-version-stamp.ok";  label="[Pkg] Version stamp in script headers";        cad=50 },
  @{ sig="system-structure-startstop.ok";      label="[Pkg] Start/Stop scripts for services";        cad=60 },
  @{ sig="system-structure-install-log.ok";    label="[Pkg] Install log with return codes";          cad=30 },
  @{ sig="logging-telemetry-heartbeat.ok";     label="[Logs] Heartbeat every minute";                cad=20 },
  # System Structure & Packaging
  @{ sig="system-structure-portable-base.ok";   label="[Pkg] Portable base structure";                 cad=0 }
  @{ sig="system-structure-manifest.ok";        label="[Pkg] Manifest (generic)";                      cad=0 }
  @{ sig="system-structure-portable-manifest.ok";label="[Pkg] Portable manifest (paths/versions/SHA)"; cad=120 }
  @{ sig="system-structure-prereqs.ok";         label="[Pkg] Prereqs (compat signal)";                 cad=0 }
  @{ sig="system-structure-prereq.ok";          label="[Pkg] Bootstrap: prerequisites verified";       cad=80 }
  @{ sig="system-structure-onefolder.ok";       label="[Pkg] One-folder install (relative paths)";     cad=150 }
  @{ sig="system-structure-package.ok";         label="[Pkg] Portable ZIP (+SHA256)";                  cad=100 }
  @{ sig="system-structure-pack-unpack.ok";     label="[Pkg] Pack/Unpack with integrity check";        cad=60 }
  @{ sig="system-structure-roadmap-integrity.ok";label="[Pkg] Roadmap integrity hashing";              cad=40 }

  # Logging & Telemetry
  @{ sig="logging-telemetry.ok";                              label="[Logs] Core logging/telemetry wiring";    cad=0 }
  @{ sig="logging-telemetry-structured-log-format-json-lines.ok"; label="[Logs] Structured JSON log lines";     cad=40 }

  # Watchdog & Governor
  @{ sig="watchdog-governor.ok";                   label="[Watchdog] Core watchdog/governor";           cad=140 }
  @{ sig="watchdog-governor-sidecar-7000-sentinel.ok"; label="[Watchdog] Sidecar-7000 sentinel";        cad=30 }

  # Safety & Guardrails
  @{ sig="safety-guardrails.ok";                   label="[Safety] Guardrails baseline";                cad=120 }
  @{ sig="safety-guardrails-kill-switch-hotkey.ok";label="[Safety] Kill-switch hotkey";                cad=40 }
  @{ sig="safety-guardrails-money-loop-hard-off-when-unstable.ok"; label="[Safety] Money loop hard-off"; cad=0 }

  # Dashboard & UX
  @{ sig="dashboard-ux.ok";                        label="[UI] Dashboard/UX baseline";                  cad=0 }
  @{ sig="dashboard-ux-status-banner-green-amber-red-logic.ok"; label="[UI] Status banner (G/A/R)";     cad=40 }
  @{ sig="dashboard-ux-copy-status-to-clipboard.ok"; label="[UI] Copy status to clipboard";            cad=10 }
  @{ sig="dashboard-ux-open-logs-folder-button.ok"; label="[UI] Open logs button";                     cad=10 }
  @{ sig="dashboard-ux-queue-browser-peek-top-n.ok"; label="[UI] Queue browser (peek N)";              cad=20 }
  @{ sig="dashboard-ux-next-hint-updated.ok";      label="[UI] Auto Next-hint writer";                  cad=10 }

  # Admin/meta
  @{ sig="roadmap-phase-1-activated.ok";          label="[Meta] Phase 1 activated";                     cad=0 }
)

# Signals we have
$have = @{}
if(Test-Path $SigDir){ Get-ChildItem $SigDir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }

# Build output
$lines = @("# Price / Line Items (CAD)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
[decimal]$total = $baseline
foreach($it in $items){
  $hit = $false; if($have[$it.sig]){ $hit = $true }
  [decimal]$amt = 0; if($hit){ $amt = [decimal]$it.cad }
  $mark = if($hit){"ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â©"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ("{0} {1} ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ${2}" -f $mark, $it.label, $it.cad)
  $total += $amt
}

$priceDir = Join-Path $RepDir "price"
$totFile  = Join-Path $priceDir "total_cad.txt"
$logFile  = Join-Path $priceDir "line_items.md"
[math]::Round($total,2).ToString() | Set-Content -Path $totFile -Encoding ASCII
$lines | Set-Content -Path $logFile -Encoding UTF8
Ok ("Total CAD -> " + (Get-Content $totFile -Raw))
Ok ("Line items  -> " + $logFile)





_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Pricebook_Update.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$SigDir = Join-Path $Base "reports\signals"
$RepDir = Join-Path $Base "reports"
if(-not (Test-Path $RepDir)){ New-Item -ItemType Directory -Path $RepDir | Out-Null }

# Baseline (what you asked me to track initially)
$baseFile = Join-Path $RepDir "price_base_cad.txt"
if(-not (Test-Path $baseFile)){ "2820" | Set-Content -Path $baseFile -Encoding ASCII }
[decimal]$baseline = [decimal](Get-Content $baseFile -Raw)

# NOTE: "group" rows are 0 to avoid double counting when specific rows are present.
$items = @(
  @{ sig="system-structure-package.ok";                          label="[Pkg] Portable ZIP (+SHA256)";                     cad=100 },
  @{ sig="system-structure-pack-unpack.ok";                      label="[Pkg] Pack/Unpack with integrity check";           cad=60  },
  @{ sig="system-structure-roadmap-integrity.ok";                label="[Pkg] Roadmap integrity hashing";                  cad=40  },
  @{ sig="system-structure-first-run-wizard.ok";                 label="[Pkg] First-run wizard (.env)";                    cad=30  },
  @{ sig="system-structure-compatibility-check.ok";              label="[Pkg] Compatibility check (OS/locale)";            cad=30  },
  @{ sig="automation-schedules-task-scheduler-verifier.ok";      label="[Auto] Task Scheduler entries verifier";           cad=25  },
  @{ sig="safety-guardrails-file-scope.ok";                      label="[Safety] File write scoping to Mason root";        cad=50  },
  @{ sig="safety-guardrails-command-allowlist.ok";               label="[Safety] Command allowlist wrapper";               cad=40  },

  @{ sig="system-structure-config-sample.ok";     label="[Pkg] Config sample generator";              cad=40 },
  @{ sig="system-structure-license-notice.ok";    label="[Pkg] Portable license/notice file set";     cad=20 },
  @{ sig="system-structure-prereq-cache.ok";      label="[Pkg] Prereq cache (download once)";         cad=40 },
  @{ sig="system-structure-bootstrap-sanity.ok";  label="[Pkg] Bootstrap sanity prompts";             cad=30 },
  @{ sig="system-structure-uninstall-script.ok";  label="[Pkg] Uninstall script (residue cleanup)";   cad=50 },

  @{ sig="system-structure-env-discovery.ok";  label="[Pkg] Environment discovery (dev/prod) toggle"; cad=40 },
  @{ sig="system-structure-version-stamp.ok";  label="[Pkg] Version stamp in script headers";        cad=50 },
  @{ sig="system-structure-startstop.ok";      label="[Pkg] Start/Stop scripts for services";        cad=60 },
  @{ sig="system-structure-install-log.ok";    label="[Pkg] Install log with return codes";          cad=30 },
  @{ sig="logging-telemetry-heartbeat.ok";     label="[Logs] Heartbeat every minute";                cad=20 },
  # System Structure & Packaging
  @{ sig="system-structure-portable-base.ok";   label="[Pkg] Portable base structure";                 cad=0 }
  @{ sig="system-structure-manifest.ok";        label="[Pkg] Manifest (generic)";                      cad=0 }
  @{ sig="system-structure-portable-manifest.ok";label="[Pkg] Portable manifest (paths/versions/SHA)"; cad=120 }
  @{ sig="system-structure-prereqs.ok";         label="[Pkg] Prereqs (compat signal)";                 cad=0 }
  @{ sig="system-structure-prereq.ok";          label="[Pkg] Bootstrap: prerequisites verified";       cad=80 }
  @{ sig="system-structure-onefolder.ok";       label="[Pkg] One-folder install (relative paths)";     cad=150 }
  @{ sig="system-structure-package.ok";         label="[Pkg] Portable ZIP (+SHA256)";                  cad=100 }
  @{ sig="system-structure-pack-unpack.ok";     label="[Pkg] Pack/Unpack with integrity check";        cad=60 }
  @{ sig="system-structure-roadmap-integrity.ok";label="[Pkg] Roadmap integrity hashing";              cad=40 }

  # Logging & Telemetry
  @{ sig="logging-telemetry.ok";                              label="[Logs] Core logging/telemetry wiring";    cad=0 }
  @{ sig="logging-telemetry-structured-log-format-json-lines.ok"; label="[Logs] Structured JSON log lines";     cad=40 }

  # Watchdog & Governor
  @{ sig="watchdog-governor.ok";                   label="[Watchdog] Core watchdog/governor";           cad=140 }
  @{ sig="watchdog-governor-sidecar-7000-sentinel.ok"; label="[Watchdog] Sidecar-7000 sentinel";        cad=30 }

  # Safety & Guardrails
  @{ sig="safety-guardrails.ok";                   label="[Safety] Guardrails baseline";                cad=120 }
  @{ sig="safety-guardrails-kill-switch-hotkey.ok";label="[Safety] Kill-switch hotkey";                cad=40 }
  @{ sig="safety-guardrails-money-loop-hard-off-when-unstable.ok"; label="[Safety] Money loop hard-off"; cad=0 }

  # Dashboard & UX
  @{ sig="dashboard-ux.ok";                        label="[UI] Dashboard/UX baseline";                  cad=0 }
  @{ sig="dashboard-ux-status-banner-green-amber-red-logic.ok"; label="[UI] Status banner (G/A/R)";     cad=40 }
  @{ sig="dashboard-ux-copy-status-to-clipboard.ok"; label="[UI] Copy status to clipboard";            cad=10 }
  @{ sig="dashboard-ux-open-logs-folder-button.ok"; label="[UI] Open logs button";                     cad=10 }
  @{ sig="dashboard-ux-queue-browser-peek-top-n.ok"; label="[UI] Queue browser (peek N)";              cad=20 }
  @{ sig="dashboard-ux-next-hint-updated.ok";      label="[UI] Auto Next-hint writer";                  cad=10 }

  # Admin/meta
  @{ sig="roadmap-phase-1-activated.ok";          label="[Meta] Phase 1 activated";                     cad=0 }
)

# Signals we have
$have = @{}
if(Test-Path $SigDir){ Get-ChildItem $SigDir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }

# Build output
$lines = @("# Price / Line Items (CAD)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
[decimal]$total = $baseline
foreach($it in $items){
  $hit = $false; if($have[$it.sig]){ $hit = $true }
  [decimal]$amt = 0; if($hit){ $amt = [decimal]$it.cad }
  $mark = if($hit){"ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â©"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ("{0} {1} ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ${2}" -f $mark, $it.label, $it.cad)
  $total += $amt
}

$priceDir = Join-Path $RepDir "price"
$totFile  = Join-Path $priceDir "total_cad.txt"
$logFile  = Join-Path $priceDir "line_items.md"
[math]::Round($total,2).ToString() | Set-Content -Path $totFile -Encoding ASCII
$lines | Set-Content -Path $logFile -Encoding UTF8
Ok ("Total CAD -> " + (Get-Content $totFile -Raw))
Ok ("Line items  -> " + $logFile)





_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Pricebook_Update.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$SigDir = Join-Path $Base "reports\signals"
$RepDir = Join-Path $Base "reports"
if(-not (Test-Path $RepDir)){ New-Item -ItemType Directory -Path $RepDir | Out-Null }

# Baseline (what you asked me to track initially)
$baseFile = Join-Path $RepDir "price_base_cad.txt"
if(-not (Test-Path $baseFile)){ "2820" | Set-Content -Path $baseFile -Encoding ASCII }
[decimal]$baseline = [decimal](Get-Content $baseFile -Raw)

# NOTE: "group" rows are 0 to avoid double counting when specific rows are present.
$items = @(
  @{ sig="system-structure-package.ok";                          label="[Pkg] Portable ZIP (+SHA256)";                     cad=100 },
  @{ sig="system-structure-pack-unpack.ok";                      label="[Pkg] Pack/Unpack with integrity check";           cad=60  },
  @{ sig="system-structure-roadmap-integrity.ok";                label="[Pkg] Roadmap integrity hashing";                  cad=40  },
  @{ sig="system-structure-first-run-wizard.ok";                 label="[Pkg] First-run wizard (.env)";                    cad=30  },
  @{ sig="system-structure-compatibility-check.ok";              label="[Pkg] Compatibility check (OS/locale)";            cad=30  },
  @{ sig="automation-schedules-task-scheduler-verifier.ok";      label="[Auto] Task Scheduler entries verifier";           cad=25  },
  @{ sig="safety-guardrails-file-scope.ok";                      label="[Safety] File write scoping to Mason root";        cad=50  },
  @{ sig="safety-guardrails-command-allowlist.ok";               label="[Safety] Command allowlist wrapper";               cad=40  },

  @{ sig="system-structure-config-sample.ok";     label="[Pkg] Config sample generator";              cad=40 },
  @{ sig="system-structure-license-notice.ok";    label="[Pkg] Portable license/notice file set";     cad=20 },
  @{ sig="system-structure-prereq-cache.ok";      label="[Pkg] Prereq cache (download once)";         cad=40 },
  @{ sig="system-structure-bootstrap-sanity.ok";  label="[Pkg] Bootstrap sanity prompts";             cad=30 },
  @{ sig="system-structure-uninstall-script.ok";  label="[Pkg] Uninstall script (residue cleanup)";   cad=50 },

  @{ sig="system-structure-env-discovery.ok";  label="[Pkg] Environment discovery (dev/prod) toggle"; cad=40 },
  @{ sig="system-structure-version-stamp.ok";  label="[Pkg] Version stamp in script headers";        cad=50 },
  @{ sig="system-structure-startstop.ok";      label="[Pkg] Start/Stop scripts for services";        cad=60 },
  @{ sig="system-structure-install-log.ok";    label="[Pkg] Install log with return codes";          cad=30 },
  @{ sig="logging-telemetry-heartbeat.ok";     label="[Logs] Heartbeat every minute";                cad=20 },
  # System Structure & Packaging
  @{ sig="system-structure-portable-base.ok";   label="[Pkg] Portable base structure";                 cad=0 }
  @{ sig="system-structure-manifest.ok";        label="[Pkg] Manifest (generic)";                      cad=0 }
  @{ sig="system-structure-portable-manifest.ok";label="[Pkg] Portable manifest (paths/versions/SHA)"; cad=120 }
  @{ sig="system-structure-prereqs.ok";         label="[Pkg] Prereqs (compat signal)";                 cad=0 }
  @{ sig="system-structure-prereq.ok";          label="[Pkg] Bootstrap: prerequisites verified";       cad=80 }
  @{ sig="system-structure-onefolder.ok";       label="[Pkg] One-folder install (relative paths)";     cad=150 }
  @{ sig="system-structure-package.ok";         label="[Pkg] Portable ZIP (+SHA256)";                  cad=100 }
  @{ sig="system-structure-pack-unpack.ok";     label="[Pkg] Pack/Unpack with integrity check";        cad=60 }
  @{ sig="system-structure-roadmap-integrity.ok";label="[Pkg] Roadmap integrity hashing";              cad=40 }

  # Logging & Telemetry
  @{ sig="logging-telemetry.ok";                              label="[Logs] Core logging/telemetry wiring";    cad=0 }
  @{ sig="logging-telemetry-structured-log-format-json-lines.ok"; label="[Logs] Structured JSON log lines";     cad=40 }

  # Watchdog & Governor
  @{ sig="watchdog-governor.ok";                   label="[Watchdog] Core watchdog/governor";           cad=140 }
  @{ sig="watchdog-governor-sidecar-7000-sentinel.ok"; label="[Watchdog] Sidecar-7000 sentinel";        cad=30 }

  # Safety & Guardrails
  @{ sig="safety-guardrails.ok";                   label="[Safety] Guardrails baseline";                cad=120 }
  @{ sig="safety-guardrails-kill-switch-hotkey.ok";label="[Safety] Kill-switch hotkey";                cad=40 }
  @{ sig="safety-guardrails-money-loop-hard-off-when-unstable.ok"; label="[Safety] Money loop hard-off"; cad=0 }

  # Dashboard & UX
  @{ sig="dashboard-ux.ok";                        label="[UI] Dashboard/UX baseline";                  cad=0 }
  @{ sig="dashboard-ux-status-banner-green-amber-red-logic.ok"; label="[UI] Status banner (G/A/R)";     cad=40 }
  @{ sig="dashboard-ux-copy-status-to-clipboard.ok"; label="[UI] Copy status to clipboard";            cad=10 }
  @{ sig="dashboard-ux-open-logs-folder-button.ok"; label="[UI] Open logs button";                     cad=10 }
  @{ sig="dashboard-ux-queue-browser-peek-top-n.ok"; label="[UI] Queue browser (peek N)";              cad=20 }
  @{ sig="dashboard-ux-next-hint-updated.ok";      label="[UI] Auto Next-hint writer";                  cad=10 }

  # Admin/meta
  @{ sig="roadmap-phase-1-activated.ok";          label="[Meta] Phase 1 activated";                     cad=0 }
)

# Signals we have
$have = @{}
if(Test-Path $SigDir){ Get-ChildItem $SigDir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }

# Build output
$lines = @("# Price / Line Items (CAD)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
[decimal]$total = $baseline
foreach($it in $items){
  $hit = $false; if($have[$it.sig]){ $hit = $true }
  [decimal]$amt = 0; if($hit){ $amt = [decimal]$it.cad }
  $mark = if($hit){"ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â©"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ("{0} {1} ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ${2}" -f $mark, $it.label, $it.cad)
  $total += $amt
}

$priceDir = Join-Path $RepDir "price"
$totFile  = Join-Path $priceDir "total_cad.txt"
$logFile  = Join-Path $priceDir "line_items.md"
[math]::Round($total,2).ToString() | Set-Content -Path $totFile -Encoding ASCII
$lines | Set-Content -Path $logFile -Encoding UTF8
Ok ("Total CAD -> " + (Get-Content $totFile -Raw))
Ok ("Line items  -> " + $logFile)





_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Pricebook_Update.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$SigDir = Join-Path $Base "reports\signals"
$RepDir = Join-Path $Base "reports"
if(-not (Test-Path $RepDir)){ New-Item -ItemType Directory -Path $RepDir | Out-Null }

# Baseline (what you asked me to track initially)
$baseFile = Join-Path $RepDir "price_base_cad.txt"
if(-not (Test-Path $baseFile)){ "2820" | Set-Content -Path $baseFile -Encoding ASCII }
[decimal]$baseline = [decimal](Get-Content $baseFile -Raw)

# NOTE: "group" rows are 0 to avoid double counting when specific rows are present.
$items = @(
  @{ sig="system-structure-package.ok";                          label="[Pkg] Portable ZIP (+SHA256)";                     cad=100 },
  @{ sig="system-structure-pack-unpack.ok";                      label="[Pkg] Pack/Unpack with integrity check";           cad=60  },
  @{ sig="system-structure-roadmap-integrity.ok";                label="[Pkg] Roadmap integrity hashing";                  cad=40  },
  @{ sig="system-structure-first-run-wizard.ok";                 label="[Pkg] First-run wizard (.env)";                    cad=30  },
  @{ sig="system-structure-compatibility-check.ok";              label="[Pkg] Compatibility check (OS/locale)";            cad=30  },
  @{ sig="automation-schedules-task-scheduler-verifier.ok";      label="[Auto] Task Scheduler entries verifier";           cad=25  },
  @{ sig="safety-guardrails-file-scope.ok";                      label="[Safety] File write scoping to Mason root";        cad=50  },
  @{ sig="safety-guardrails-command-allowlist.ok";               label="[Safety] Command allowlist wrapper";               cad=40  },

  @{ sig="system-structure-config-sample.ok";     label="[Pkg] Config sample generator";              cad=40 },
  @{ sig="system-structure-license-notice.ok";    label="[Pkg] Portable license/notice file set";     cad=20 },
  @{ sig="system-structure-prereq-cache.ok";      label="[Pkg] Prereq cache (download once)";         cad=40 },
  @{ sig="system-structure-bootstrap-sanity.ok";  label="[Pkg] Bootstrap sanity prompts";             cad=30 },
  @{ sig="system-structure-uninstall-script.ok";  label="[Pkg] Uninstall script (residue cleanup)";   cad=50 },

  @{ sig="system-structure-env-discovery.ok";  label="[Pkg] Environment discovery (dev/prod) toggle"; cad=40 },
  @{ sig="system-structure-version-stamp.ok";  label="[Pkg] Version stamp in script headers";        cad=50 },
  @{ sig="system-structure-startstop.ok";      label="[Pkg] Start/Stop scripts for services";        cad=60 },
  @{ sig="system-structure-install-log.ok";    label="[Pkg] Install log with return codes";          cad=30 },
  @{ sig="logging-telemetry-heartbeat.ok";     label="[Logs] Heartbeat every minute";                cad=20 },
  # System Structure & Packaging
  @{ sig="system-structure-portable-base.ok";   label="[Pkg] Portable base structure";                 cad=0 }
  @{ sig="system-structure-manifest.ok";        label="[Pkg] Manifest (generic)";                      cad=0 }
  @{ sig="system-structure-portable-manifest.ok";label="[Pkg] Portable manifest (paths/versions/SHA)"; cad=120 }
  @{ sig="system-structure-prereqs.ok";         label="[Pkg] Prereqs (compat signal)";                 cad=0 }
  @{ sig="system-structure-prereq.ok";          label="[Pkg] Bootstrap: prerequisites verified";       cad=80 }
  @{ sig="system-structure-onefolder.ok";       label="[Pkg] One-folder install (relative paths)";     cad=150 }
  @{ sig="system-structure-package.ok";         label="[Pkg] Portable ZIP (+SHA256)";                  cad=100 }
  @{ sig="system-structure-pack-unpack.ok";     label="[Pkg] Pack/Unpack with integrity check";        cad=60 }
  @{ sig="system-structure-roadmap-integrity.ok";label="[Pkg] Roadmap integrity hashing";              cad=40 }

  # Logging & Telemetry
  @{ sig="logging-telemetry.ok";                              label="[Logs] Core logging/telemetry wiring";    cad=0 }
  @{ sig="logging-telemetry-structured-log-format-json-lines.ok"; label="[Logs] Structured JSON log lines";     cad=40 }

  # Watchdog & Governor
  @{ sig="watchdog-governor.ok";                   label="[Watchdog] Core watchdog/governor";           cad=140 }
  @{ sig="watchdog-governor-sidecar-7000-sentinel.ok"; label="[Watchdog] Sidecar-7000 sentinel";        cad=30 }

  # Safety & Guardrails
  @{ sig="safety-guardrails.ok";                   label="[Safety] Guardrails baseline";                cad=120 }
  @{ sig="safety-guardrails-kill-switch-hotkey.ok";label="[Safety] Kill-switch hotkey";                cad=40 }
  @{ sig="safety-guardrails-money-loop-hard-off-when-unstable.ok"; label="[Safety] Money loop hard-off"; cad=0 }

  # Dashboard & UX
  @{ sig="dashboard-ux.ok";                        label="[UI] Dashboard/UX baseline";                  cad=0 }
  @{ sig="dashboard-ux-status-banner-green-amber-red-logic.ok"; label="[UI] Status banner (G/A/R)";     cad=40 }
  @{ sig="dashboard-ux-copy-status-to-clipboard.ok"; label="[UI] Copy status to clipboard";            cad=10 }
  @{ sig="dashboard-ux-open-logs-folder-button.ok"; label="[UI] Open logs button";                     cad=10 }
  @{ sig="dashboard-ux-queue-browser-peek-top-n.ok"; label="[UI] Queue browser (peek N)";              cad=20 }
  @{ sig="dashboard-ux-next-hint-updated.ok";      label="[UI] Auto Next-hint writer";                  cad=10 }

  # Admin/meta
  @{ sig="roadmap-phase-1-activated.ok";          label="[Meta] Phase 1 activated";                     cad=0 }
)

# Signals we have
$have = @{}
if(Test-Path $SigDir){ Get-ChildItem $SigDir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }

# Build output
$lines = @("# Price / Line Items (CAD)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
[decimal]$total = $baseline
foreach($it in $items){
  $hit = $false; if($have[$it.sig]){ $hit = $true }
  [decimal]$amt = 0; if($hit){ $amt = [decimal]$it.cad }
  $mark = if($hit){"ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â©"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ("{0} {1} ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ${2}" -f $mark, $it.label, $it.cad)
  $total += $amt
}

$priceDir = Join-Path $RepDir "price"
$totFile  = Join-Path $priceDir "total_cad.txt"
$logFile  = Join-Path $priceDir "line_items.md"
[math]::Round($total,2).ToString() | Set-Content -Path $totFile -Encoding ASCII
$lines | Set-Content -Path $logFile -Encoding UTF8
Ok ("Total CAD -> " + (Get-Content $totFile -Raw))
Ok ("Line items  -> " + $logFile)





_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Pricebook_Update.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$SigDir = Join-Path $Base "reports\signals"
$RepDir = Join-Path $Base "reports"
if(-not (Test-Path $RepDir)){ New-Item -ItemType Directory -Path $RepDir | Out-Null }

# Baseline (what you asked me to track initially)
$baseFile = Join-Path $RepDir "price_base_cad.txt"
if(-not (Test-Path $baseFile)){ "2820" | Set-Content -Path $baseFile -Encoding ASCII }
[decimal]$baseline = [decimal](Get-Content $baseFile -Raw)

# NOTE: "group" rows are 0 to avoid double counting when specific rows are present.
$items = @(
  @{ sig="system-structure-package.ok";                          label="[Pkg] Portable ZIP (+SHA256)";                     cad=100 },
  @{ sig="system-structure-pack-unpack.ok";                      label="[Pkg] Pack/Unpack with integrity check";           cad=60  },
  @{ sig="system-structure-roadmap-integrity.ok";                label="[Pkg] Roadmap integrity hashing";                  cad=40  },
  @{ sig="system-structure-first-run-wizard.ok";                 label="[Pkg] First-run wizard (.env)";                    cad=30  },
  @{ sig="system-structure-compatibility-check.ok";              label="[Pkg] Compatibility check (OS/locale)";            cad=30  },
  @{ sig="automation-schedules-task-scheduler-verifier.ok";      label="[Auto] Task Scheduler entries verifier";           cad=25  },
  @{ sig="safety-guardrails-file-scope.ok";                      label="[Safety] File write scoping to Mason root";        cad=50  },
  @{ sig="safety-guardrails-command-allowlist.ok";               label="[Safety] Command allowlist wrapper";               cad=40  },

  @{ sig="system-structure-config-sample.ok";     label="[Pkg] Config sample generator";              cad=40 },
  @{ sig="system-structure-license-notice.ok";    label="[Pkg] Portable license/notice file set";     cad=20 },
  @{ sig="system-structure-prereq-cache.ok";      label="[Pkg] Prereq cache (download once)";         cad=40 },
  @{ sig="system-structure-bootstrap-sanity.ok";  label="[Pkg] Bootstrap sanity prompts";             cad=30 },
  @{ sig="system-structure-uninstall-script.ok";  label="[Pkg] Uninstall script (residue cleanup)";   cad=50 },

  @{ sig="system-structure-env-discovery.ok";  label="[Pkg] Environment discovery (dev/prod) toggle"; cad=40 },
  @{ sig="system-structure-version-stamp.ok";  label="[Pkg] Version stamp in script headers";        cad=50 },
  @{ sig="system-structure-startstop.ok";      label="[Pkg] Start/Stop scripts for services";        cad=60 },
  @{ sig="system-structure-install-log.ok";    label="[Pkg] Install log with return codes";          cad=30 },
  @{ sig="logging-telemetry-heartbeat.ok";     label="[Logs] Heartbeat every minute";                cad=20 },
  # System Structure & Packaging
  @{ sig="system-structure-portable-base.ok";   label="[Pkg] Portable base structure";                 cad=0 }
  @{ sig="system-structure-manifest.ok";        label="[Pkg] Manifest (generic)";                      cad=0 }
  @{ sig="system-structure-portable-manifest.ok";label="[Pkg] Portable manifest (paths/versions/SHA)"; cad=120 }
  @{ sig="system-structure-prereqs.ok";         label="[Pkg] Prereqs (compat signal)";                 cad=0 }
  @{ sig="system-structure-prereq.ok";          label="[Pkg] Bootstrap: prerequisites verified";       cad=80 }
  @{ sig="system-structure-onefolder.ok";       label="[Pkg] One-folder install (relative paths)";     cad=150 }
  @{ sig="system-structure-package.ok";         label="[Pkg] Portable ZIP (+SHA256)";                  cad=100 }
  @{ sig="system-structure-pack-unpack.ok";     label="[Pkg] Pack/Unpack with integrity check";        cad=60 }
  @{ sig="system-structure-roadmap-integrity.ok";label="[Pkg] Roadmap integrity hashing";              cad=40 }

  # Logging & Telemetry
  @{ sig="logging-telemetry.ok";                              label="[Logs] Core logging/telemetry wiring";    cad=0 }
  @{ sig="logging-telemetry-structured-log-format-json-lines.ok"; label="[Logs] Structured JSON log lines";     cad=40 }

  # Watchdog & Governor
  @{ sig="watchdog-governor.ok";                   label="[Watchdog] Core watchdog/governor";           cad=140 }
  @{ sig="watchdog-governor-sidecar-7000-sentinel.ok"; label="[Watchdog] Sidecar-7000 sentinel";        cad=30 }

  # Safety & Guardrails
  @{ sig="safety-guardrails.ok";                   label="[Safety] Guardrails baseline";                cad=120 }
  @{ sig="safety-guardrails-kill-switch-hotkey.ok";label="[Safety] Kill-switch hotkey";                cad=40 }
  @{ sig="safety-guardrails-money-loop-hard-off-when-unstable.ok"; label="[Safety] Money loop hard-off"; cad=0 }

  # Dashboard & UX
  @{ sig="dashboard-ux.ok";                        label="[UI] Dashboard/UX baseline";                  cad=0 }
  @{ sig="dashboard-ux-status-banner-green-amber-red-logic.ok"; label="[UI] Status banner (G/A/R)";     cad=40 }
  @{ sig="dashboard-ux-copy-status-to-clipboard.ok"; label="[UI] Copy status to clipboard";            cad=10 }
  @{ sig="dashboard-ux-open-logs-folder-button.ok"; label="[UI] Open logs button";                     cad=10 }
  @{ sig="dashboard-ux-queue-browser-peek-top-n.ok"; label="[UI] Queue browser (peek N)";              cad=20 }
  @{ sig="dashboard-ux-next-hint-updated.ok";      label="[UI] Auto Next-hint writer";                  cad=10 }

  # Admin/meta
  @{ sig="roadmap-phase-1-activated.ok";          label="[Meta] Phase 1 activated";                     cad=0 }
)

# Signals we have
$have = @{}
if(Test-Path $SigDir){ Get-ChildItem $SigDir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }

# Build output
$lines = @("# Price / Line Items (CAD)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
[decimal]$total = $baseline
foreach($it in $items){
  $hit = $false; if($have[$it.sig]){ $hit = $true }
  [decimal]$amt = 0; if($hit){ $amt = [decimal]$it.cad }
  $mark = if($hit){"ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â©"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ("{0} {1} ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ${2}" -f $mark, $it.label, $it.cad)
  $total += $amt
}

$priceDir = Join-Path $RepDir "price"
$totFile  = Join-Path $priceDir "total_cad.txt"
$logFile  = Join-Path $priceDir "line_items.md"
[math]::Round($total,2).ToString() | Set-Content -Path $totFile -Encoding ASCII
$lines | Set-Content -Path $logFile -Encoding UTF8
Ok ("Total CAD -> " + (Get-Content $totFile -Raw))
Ok ("Line items  -> " + $logFile)





_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Pricebook_Update.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path
$SigDir = Join-Path $Base "reports\signals"
$RepDir = Join-Path $Base "reports"
if(-not (Test-Path $RepDir)){ New-Item -ItemType Directory -Path $RepDir | Out-Null }

# Baseline (what you asked me to track initially)
$baseFile = Join-Path $RepDir "price_base_cad.txt"
if(-not (Test-Path $baseFile)){ "2820" | Set-Content -Path $baseFile -Encoding ASCII }
[decimal]$baseline = [decimal](Get-Content $baseFile -Raw)

# NOTE: "group" rows are 0 to avoid double counting when specific rows are present.
$items = @(
  @{ sig="system-structure-package.ok";                          label="[Pkg] Portable ZIP (+SHA256)";                     cad=100 },
  @{ sig="system-structure-pack-unpack.ok";                      label="[Pkg] Pack/Unpack with integrity check";           cad=60  },
  @{ sig="system-structure-roadmap-integrity.ok";                label="[Pkg] Roadmap integrity hashing";                  cad=40  },
  @{ sig="system-structure-first-run-wizard.ok";                 label="[Pkg] First-run wizard (.env)";                    cad=30  },
  @{ sig="system-structure-compatibility-check.ok";              label="[Pkg] Compatibility check (OS/locale)";            cad=30  },
  @{ sig="automation-schedules-task-scheduler-verifier.ok";      label="[Auto] Task Scheduler entries verifier";           cad=25  },
  @{ sig="safety-guardrails-file-scope.ok";                      label="[Safety] File write scoping to Mason root";        cad=50  },
  @{ sig="safety-guardrails-command-allowlist.ok";               label="[Safety] Command allowlist wrapper";               cad=40  },

  @{ sig="system-structure-config-sample.ok";     label="[Pkg] Config sample generator";              cad=40 },
  @{ sig="system-structure-license-notice.ok";    label="[Pkg] Portable license/notice file set";     cad=20 },
  @{ sig="system-structure-prereq-cache.ok";      label="[Pkg] Prereq cache (download once)";         cad=40 },
  @{ sig="system-structure-bootstrap-sanity.ok";  label="[Pkg] Bootstrap sanity prompts";             cad=30 },
  @{ sig="system-structure-uninstall-script.ok";  label="[Pkg] Uninstall script (residue cleanup)";   cad=50 },

  @{ sig="system-structure-env-discovery.ok";  label="[Pkg] Environment discovery (dev/prod) toggle"; cad=40 },
  @{ sig="system-structure-version-stamp.ok";  label="[Pkg] Version stamp in script headers";        cad=50 },
  @{ sig="system-structure-startstop.ok";      label="[Pkg] Start/Stop scripts for services";        cad=60 },
  @{ sig="system-structure-install-log.ok";    label="[Pkg] Install log with return codes";          cad=30 },
  @{ sig="logging-telemetry-heartbeat.ok";     label="[Logs] Heartbeat every minute";                cad=20 },
  # System Structure & Packaging
  @{ sig="system-structure-portable-base.ok";   label="[Pkg] Portable base structure";                 cad=0 }
  @{ sig="system-structure-manifest.ok";        label="[Pkg] Manifest (generic)";                      cad=0 }
  @{ sig="system-structure-portable-manifest.ok";label="[Pkg] Portable manifest (paths/versions/SHA)"; cad=120 }
  @{ sig="system-structure-prereqs.ok";         label="[Pkg] Prereqs (compat signal)";                 cad=0 }
  @{ sig="system-structure-prereq.ok";          label="[Pkg] Bootstrap: prerequisites verified";       cad=80 }
  @{ sig="system-structure-onefolder.ok";       label="[Pkg] One-folder install (relative paths)";     cad=150 }
  @{ sig="system-structure-package.ok";         label="[Pkg] Portable ZIP (+SHA256)";                  cad=100 }
  @{ sig="system-structure-pack-unpack.ok";     label="[Pkg] Pack/Unpack with integrity check";        cad=60 }
  @{ sig="system-structure-roadmap-integrity.ok";label="[Pkg] Roadmap integrity hashing";              cad=40 }

  # Logging & Telemetry
  @{ sig="logging-telemetry.ok";                              label="[Logs] Core logging/telemetry wiring";    cad=0 }
  @{ sig="logging-telemetry-structured-log-format-json-lines.ok"; label="[Logs] Structured JSON log lines";     cad=40 }

  # Watchdog & Governor
  @{ sig="watchdog-governor.ok";                   label="[Watchdog] Core watchdog/governor";           cad=140 }
  @{ sig="watchdog-governor-sidecar-7000-sentinel.ok"; label="[Watchdog] Sidecar-7000 sentinel";        cad=30 }

  # Safety & Guardrails
  @{ sig="safety-guardrails.ok";                   label="[Safety] Guardrails baseline";                cad=120 }
  @{ sig="safety-guardrails-kill-switch-hotkey.ok";label="[Safety] Kill-switch hotkey";                cad=40 }
  @{ sig="safety-guardrails-money-loop-hard-off-when-unstable.ok"; label="[Safety] Money loop hard-off"; cad=0 }

  # Dashboard & UX
  @{ sig="dashboard-ux.ok";                        label="[UI] Dashboard/UX baseline";                  cad=0 }
  @{ sig="dashboard-ux-status-banner-green-amber-red-logic.ok"; label="[UI] Status banner (G/A/R)";     cad=40 }
  @{ sig="dashboard-ux-copy-status-to-clipboard.ok"; label="[UI] Copy status to clipboard";            cad=10 }
  @{ sig="dashboard-ux-open-logs-folder-button.ok"; label="[UI] Open logs button";                     cad=10 }
  @{ sig="dashboard-ux-queue-browser-peek-top-n.ok"; label="[UI] Queue browser (peek N)";              cad=20 }
  @{ sig="dashboard-ux-next-hint-updated.ok";      label="[UI] Auto Next-hint writer";                  cad=10 }

  # Admin/meta
  @{ sig="roadmap-phase-1-activated.ok";          label="[Meta] Phase 1 activated";                     cad=0 }
)

# Signals we have
$have = @{}
if(Test-Path $SigDir){ Get-ChildItem $SigDir -Filter *.ok -ea SilentlyContinue | % { $have[$_.Name.ToLower()] = $true } }

# Build output
$lines = @("# Price / Line Items (CAD)","_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","")
[decimal]$total = $baseline
foreach($it in $items){
  $hit = $false; if($have[$it.sig]){ $hit = $true }
  [decimal]$amt = 0; if($hit){ $amt = [decimal]$it.cad }
  $mark = if($hit){"ÃƒÂ°Ã…Â¸Ã…Â¸Ã‚Â©"}else{"ÃƒÂ¢Ã‚Â¬Ã…â€œ"}
  $lines += ("{0} {1} ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â ${2}" -f $mark, $it.label, $it.cad)
  $total += $amt
}

$priceDir = Join-Path $RepDir "price"
$totFile  = Join-Path $priceDir "total_cad.txt"
$logFile  = Join-Path $priceDir "line_items.md"
[math]::Round($total,2).ToString() | Set-Content -Path $totFile -Encoding ASCII
$lines | Set-Content -Path $logFile -Encoding UTF8
Ok ("Total CAD -> " + (Get-Content $totFile -Raw))
Ok ("Line items  -> " + $logFile)





