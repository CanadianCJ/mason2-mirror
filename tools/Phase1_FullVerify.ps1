# Stamped: 2025-11-05T17:02:01
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$miss=@()
function T($b,$good,$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$miss+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }

T (Test-Path (Join-Path $Base "dist\manifest.json")) "Portable manifest generated" "Portable manifest missing"             # System Structure & Packaging :contentReference[oaicite:4]{index=4}
T (Test-Path (Join-Path $Base "tools\Emergency_Rollback.ps1")) "Rollback cache/script present" "Rollback tooling missing"     # :contentReference[oaicite:5]{index=5}
T (Test-Path (Join-Path $Base "tools\Atomic_Deploy.ps1")) "Atomic deploy stub present" "Atomic deploy missing"                # :contentReference[oaicite:6]{index=6}
T (Test-Path (Join-Path $Base "reports\roadmap_integrity.json")) "Roadmap integrity hash written" "Roadmap integrity missing" # Dashboard & UX integrity display :contentReference[oaicite:7]{index=7}
T (Test-Path (Join-Path $Base "services\Log.psm1")) "JSON logging module present" "Logging module missing"                    # Logging & Telemetry :contentReference[oaicite:8]{index=8}
T (Test-Path (Join-Path $Base "config\policy.json")) "Guardrails policy present" "policy.json missing"                        # Safety & Guardrails :contentReference[oaicite:9]{index=9}
T (Test-Path (Join-Path $Base "tools\Daily_Snapshot.ps1")) "Daily snapshot script present" "Snapshot missing"                 # Automation :contentReference[oaicite:10]{index=10}
T (Test-Path (Join-Path $Base "tools\Weekly_RestoreTest.ps1")) "Weekly restore test present" "Weekly restore test missing"    # :contentReference[oaicite:11]{index=11}
T (Test-Path (Join-Path $Base "tools\Log_Maintenance.ps1")) "Log maintenance job present" "Log maintenance missing"           # :contentReference[oaicite:12]{index=12}

$okAll = ($miss.Count -eq 0)
$lines = @(
  "# Phase 1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Full(er) Coverage Check",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","",
  "## OK", ($ok -join "`r`n"), "", "## Gaps", ($miss -join "`r`n"), ""
)
$rep = Join-Path $Rep "phase1_fullcheck.md"
$lines | Set-Content $rep -Encoding UTF8
if($okAll){ "ok" | Set-Content (Join-Path $Sig 'phase1_full_applied.ok') -Encoding ASCII }
Write-Host $rep

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$miss=@()
function T($b,$good,$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$miss+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }

T (Test-Path (Join-Path $Base "dist\manifest.json")) "Portable manifest generated" "Portable manifest missing"             # System Structure & Packaging :contentReference[oaicite:4]{index=4}
T (Test-Path (Join-Path $Base "tools\Emergency_Rollback.ps1")) "Rollback cache/script present" "Rollback tooling missing"     # :contentReference[oaicite:5]{index=5}
T (Test-Path (Join-Path $Base "tools\Atomic_Deploy.ps1")) "Atomic deploy stub present" "Atomic deploy missing"                # :contentReference[oaicite:6]{index=6}
T (Test-Path (Join-Path $Base "reports\roadmap_integrity.json")) "Roadmap integrity hash written" "Roadmap integrity missing" # Dashboard & UX integrity display :contentReference[oaicite:7]{index=7}
T (Test-Path (Join-Path $Base "services\Log.psm1")) "JSON logging module present" "Logging module missing"                    # Logging & Telemetry :contentReference[oaicite:8]{index=8}
T (Test-Path (Join-Path $Base "config\policy.json")) "Guardrails policy present" "policy.json missing"                        # Safety & Guardrails :contentReference[oaicite:9]{index=9}
T (Test-Path (Join-Path $Base "tools\Daily_Snapshot.ps1")) "Daily snapshot script present" "Snapshot missing"                 # Automation :contentReference[oaicite:10]{index=10}
T (Test-Path (Join-Path $Base "tools\Weekly_RestoreTest.ps1")) "Weekly restore test present" "Weekly restore test missing"    # :contentReference[oaicite:11]{index=11}
T (Test-Path (Join-Path $Base "tools\Log_Maintenance.ps1")) "Log maintenance job present" "Log maintenance missing"           # :contentReference[oaicite:12]{index=12}

$okAll = ($miss.Count -eq 0)
$lines = @(
  "# Phase 1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Full(er) Coverage Check",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","",
  "## OK", ($ok -join "`r`n"), "", "## Gaps", ($miss -join "`r`n"), ""
)
$rep = Join-Path $Rep "phase1_fullcheck.md"
$lines | Set-Content $rep -Encoding UTF8
if($okAll){ "ok" | Set-Content (Join-Path $Sig 'phase1_full_applied.ok') -Encoding ASCII }
Write-Host $rep

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$miss=@()
function T($b,$good,$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$miss+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }

T (Test-Path (Join-Path $Base "dist\manifest.json")) "Portable manifest generated" "Portable manifest missing"             # System Structure & Packaging :contentReference[oaicite:4]{index=4}
T (Test-Path (Join-Path $Base "tools\Emergency_Rollback.ps1")) "Rollback cache/script present" "Rollback tooling missing"     # :contentReference[oaicite:5]{index=5}
T (Test-Path (Join-Path $Base "tools\Atomic_Deploy.ps1")) "Atomic deploy stub present" "Atomic deploy missing"                # :contentReference[oaicite:6]{index=6}
T (Test-Path (Join-Path $Base "reports\roadmap_integrity.json")) "Roadmap integrity hash written" "Roadmap integrity missing" # Dashboard & UX integrity display :contentReference[oaicite:7]{index=7}
T (Test-Path (Join-Path $Base "services\Log.psm1")) "JSON logging module present" "Logging module missing"                    # Logging & Telemetry :contentReference[oaicite:8]{index=8}
T (Test-Path (Join-Path $Base "config\policy.json")) "Guardrails policy present" "policy.json missing"                        # Safety & Guardrails :contentReference[oaicite:9]{index=9}
T (Test-Path (Join-Path $Base "tools\Daily_Snapshot.ps1")) "Daily snapshot script present" "Snapshot missing"                 # Automation :contentReference[oaicite:10]{index=10}
T (Test-Path (Join-Path $Base "tools\Weekly_RestoreTest.ps1")) "Weekly restore test present" "Weekly restore test missing"    # :contentReference[oaicite:11]{index=11}
T (Test-Path (Join-Path $Base "tools\Log_Maintenance.ps1")) "Log maintenance job present" "Log maintenance missing"           # :contentReference[oaicite:12]{index=12}

$okAll = ($miss.Count -eq 0)
$lines = @(
  "# Phase 1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Full(er) Coverage Check",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","",
  "## OK", ($ok -join "`r`n"), "", "## Gaps", ($miss -join "`r`n"), ""
)
$rep = Join-Path $Rep "phase1_fullcheck.md"
$lines | Set-Content $rep -Encoding UTF8
if($okAll){ "ok" | Set-Content (Join-Path $Sig 'phase1_full_applied.ok') -Encoding ASCII }
Write-Host $rep

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$miss=@()
function T($b,$good,$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$miss+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }

T (Test-Path (Join-Path $Base "dist\manifest.json")) "Portable manifest generated" "Portable manifest missing"             # System Structure & Packaging :contentReference[oaicite:4]{index=4}
T (Test-Path (Join-Path $Base "tools\Emergency_Rollback.ps1")) "Rollback cache/script present" "Rollback tooling missing"     # :contentReference[oaicite:5]{index=5}
T (Test-Path (Join-Path $Base "tools\Atomic_Deploy.ps1")) "Atomic deploy stub present" "Atomic deploy missing"                # :contentReference[oaicite:6]{index=6}
T (Test-Path (Join-Path $Base "reports\roadmap_integrity.json")) "Roadmap integrity hash written" "Roadmap integrity missing" # Dashboard & UX integrity display :contentReference[oaicite:7]{index=7}
T (Test-Path (Join-Path $Base "services\Log.psm1")) "JSON logging module present" "Logging module missing"                    # Logging & Telemetry :contentReference[oaicite:8]{index=8}
T (Test-Path (Join-Path $Base "config\policy.json")) "Guardrails policy present" "policy.json missing"                        # Safety & Guardrails :contentReference[oaicite:9]{index=9}
T (Test-Path (Join-Path $Base "tools\Daily_Snapshot.ps1")) "Daily snapshot script present" "Snapshot missing"                 # Automation :contentReference[oaicite:10]{index=10}
T (Test-Path (Join-Path $Base "tools\Weekly_RestoreTest.ps1")) "Weekly restore test present" "Weekly restore test missing"    # :contentReference[oaicite:11]{index=11}
T (Test-Path (Join-Path $Base "tools\Log_Maintenance.ps1")) "Log maintenance job present" "Log maintenance missing"           # :contentReference[oaicite:12]{index=12}

$okAll = ($miss.Count -eq 0)
$lines = @(
  "# Phase 1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Full(er) Coverage Check",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","",
  "## OK", ($ok -join "`r`n"), "", "## Gaps", ($miss -join "`r`n"), ""
)
$rep = Join-Path $Rep "phase1_fullcheck.md"
$lines | Set-Content $rep -Encoding UTF8
if($okAll){ "ok" | Set-Content (Join-Path $Sig 'phase1_full_applied.ok') -Encoding ASCII }
Write-Host $rep

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$miss=@()
function T($b,$good,$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$miss+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }

T (Test-Path (Join-Path $Base "dist\manifest.json")) "Portable manifest generated" "Portable manifest missing"             # System Structure & Packaging :contentReference[oaicite:4]{index=4}
T (Test-Path (Join-Path $Base "tools\Emergency_Rollback.ps1")) "Rollback cache/script present" "Rollback tooling missing"     # :contentReference[oaicite:5]{index=5}
T (Test-Path (Join-Path $Base "tools\Atomic_Deploy.ps1")) "Atomic deploy stub present" "Atomic deploy missing"                # :contentReference[oaicite:6]{index=6}
T (Test-Path (Join-Path $Base "reports\roadmap_integrity.json")) "Roadmap integrity hash written" "Roadmap integrity missing" # Dashboard & UX integrity display :contentReference[oaicite:7]{index=7}
T (Test-Path (Join-Path $Base "services\Log.psm1")) "JSON logging module present" "Logging module missing"                    # Logging & Telemetry :contentReference[oaicite:8]{index=8}
T (Test-Path (Join-Path $Base "config\policy.json")) "Guardrails policy present" "policy.json missing"                        # Safety & Guardrails :contentReference[oaicite:9]{index=9}
T (Test-Path (Join-Path $Base "tools\Daily_Snapshot.ps1")) "Daily snapshot script present" "Snapshot missing"                 # Automation :contentReference[oaicite:10]{index=10}
T (Test-Path (Join-Path $Base "tools\Weekly_RestoreTest.ps1")) "Weekly restore test present" "Weekly restore test missing"    # :contentReference[oaicite:11]{index=11}
T (Test-Path (Join-Path $Base "tools\Log_Maintenance.ps1")) "Log maintenance job present" "Log maintenance missing"           # :contentReference[oaicite:12]{index=12}

$okAll = ($miss.Count -eq 0)
$lines = @(
  "# Phase 1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Full(er) Coverage Check",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","",
  "## OK", ($ok -join "`r`n"), "", "## Gaps", ($miss -join "`r`n"), ""
)
$rep = Join-Path $Rep "phase1_fullcheck.md"
$lines | Set-Content $rep -Encoding UTF8
if($okAll){ "ok" | Set-Content (Join-Path $Sig 'phase1_full_applied.ok') -Encoding ASCII }
Write-Host $rep

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$miss=@()
function T($b,$good,$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$miss+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }

T (Test-Path (Join-Path $Base "dist\manifest.json")) "Portable manifest generated" "Portable manifest missing"             # System Structure & Packaging :contentReference[oaicite:4]{index=4}
T (Test-Path (Join-Path $Base "tools\Emergency_Rollback.ps1")) "Rollback cache/script present" "Rollback tooling missing"     # :contentReference[oaicite:5]{index=5}
T (Test-Path (Join-Path $Base "tools\Atomic_Deploy.ps1")) "Atomic deploy stub present" "Atomic deploy missing"                # :contentReference[oaicite:6]{index=6}
T (Test-Path (Join-Path $Base "reports\roadmap_integrity.json")) "Roadmap integrity hash written" "Roadmap integrity missing" # Dashboard & UX integrity display :contentReference[oaicite:7]{index=7}
T (Test-Path (Join-Path $Base "services\Log.psm1")) "JSON logging module present" "Logging module missing"                    # Logging & Telemetry :contentReference[oaicite:8]{index=8}
T (Test-Path (Join-Path $Base "config\policy.json")) "Guardrails policy present" "policy.json missing"                        # Safety & Guardrails :contentReference[oaicite:9]{index=9}
T (Test-Path (Join-Path $Base "tools\Daily_Snapshot.ps1")) "Daily snapshot script present" "Snapshot missing"                 # Automation :contentReference[oaicite:10]{index=10}
T (Test-Path (Join-Path $Base "tools\Weekly_RestoreTest.ps1")) "Weekly restore test present" "Weekly restore test missing"    # :contentReference[oaicite:11]{index=11}
T (Test-Path (Join-Path $Base "tools\Log_Maintenance.ps1")) "Log maintenance job present" "Log maintenance missing"           # :contentReference[oaicite:12]{index=12}

$okAll = ($miss.Count -eq 0)
$lines = @(
  "# Phase 1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Full(er) Coverage Check",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","",
  "## OK", ($ok -join "`r`n"), "", "## Gaps", ($miss -join "`r`n"), ""
)
$rep = Join-Path $Rep "phase1_fullcheck.md"
$lines | Set-Content $rep -Encoding UTF8
if($okAll){ "ok" | Set-Content (Join-Path $Sig 'phase1_full_applied.ok') -Encoding ASCII }
Write-Host $rep

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$miss=@()
function T($b,$good,$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$miss+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }

T (Test-Path (Join-Path $Base "dist\manifest.json")) "Portable manifest generated" "Portable manifest missing"             # System Structure & Packaging :contentReference[oaicite:4]{index=4}
T (Test-Path (Join-Path $Base "tools\Emergency_Rollback.ps1")) "Rollback cache/script present" "Rollback tooling missing"     # :contentReference[oaicite:5]{index=5}
T (Test-Path (Join-Path $Base "tools\Atomic_Deploy.ps1")) "Atomic deploy stub present" "Atomic deploy missing"                # :contentReference[oaicite:6]{index=6}
T (Test-Path (Join-Path $Base "reports\roadmap_integrity.json")) "Roadmap integrity hash written" "Roadmap integrity missing" # Dashboard & UX integrity display :contentReference[oaicite:7]{index=7}
T (Test-Path (Join-Path $Base "services\Log.psm1")) "JSON logging module present" "Logging module missing"                    # Logging & Telemetry :contentReference[oaicite:8]{index=8}
T (Test-Path (Join-Path $Base "config\policy.json")) "Guardrails policy present" "policy.json missing"                        # Safety & Guardrails :contentReference[oaicite:9]{index=9}
T (Test-Path (Join-Path $Base "tools\Daily_Snapshot.ps1")) "Daily snapshot script present" "Snapshot missing"                 # Automation :contentReference[oaicite:10]{index=10}
T (Test-Path (Join-Path $Base "tools\Weekly_RestoreTest.ps1")) "Weekly restore test present" "Weekly restore test missing"    # :contentReference[oaicite:11]{index=11}
T (Test-Path (Join-Path $Base "tools\Log_Maintenance.ps1")) "Log maintenance job present" "Log maintenance missing"           # :contentReference[oaicite:12]{index=12}

$okAll = ($miss.Count -eq 0)
$lines = @(
  "# Phase 1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Full(er) Coverage Check",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","",
  "## OK", ($ok -join "`r`n"), "", "## Gaps", ($miss -join "`r`n"), ""
)
$rep = Join-Path $Rep "phase1_fullcheck.md"
$lines | Set-Content $rep -Encoding UTF8
if($okAll){ "ok" | Set-Content (Join-Path $Sig 'phase1_full_applied.ok') -Encoding ASCII }
Write-Host $rep

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
param()
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$miss=@()
function T($b,$good,$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$miss+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }

T (Test-Path (Join-Path $Base "dist\manifest.json")) "Portable manifest generated" "Portable manifest missing"             # System Structure & Packaging :contentReference[oaicite:4]{index=4}
T (Test-Path (Join-Path $Base "tools\Emergency_Rollback.ps1")) "Rollback cache/script present" "Rollback tooling missing"     # :contentReference[oaicite:5]{index=5}
T (Test-Path (Join-Path $Base "tools\Atomic_Deploy.ps1")) "Atomic deploy stub present" "Atomic deploy missing"                # :contentReference[oaicite:6]{index=6}
T (Test-Path (Join-Path $Base "reports\roadmap_integrity.json")) "Roadmap integrity hash written" "Roadmap integrity missing" # Dashboard & UX integrity display :contentReference[oaicite:7]{index=7}
T (Test-Path (Join-Path $Base "services\Log.psm1")) "JSON logging module present" "Logging module missing"                    # Logging & Telemetry :contentReference[oaicite:8]{index=8}
T (Test-Path (Join-Path $Base "config\policy.json")) "Guardrails policy present" "policy.json missing"                        # Safety & Guardrails :contentReference[oaicite:9]{index=9}
T (Test-Path (Join-Path $Base "tools\Daily_Snapshot.ps1")) "Daily snapshot script present" "Snapshot missing"                 # Automation :contentReference[oaicite:10]{index=10}
T (Test-Path (Join-Path $Base "tools\Weekly_RestoreTest.ps1")) "Weekly restore test present" "Weekly restore test missing"    # :contentReference[oaicite:11]{index=11}
T (Test-Path (Join-Path $Base "tools\Log_Maintenance.ps1")) "Log maintenance job present" "Log maintenance missing"           # :contentReference[oaicite:12]{index=12}

$okAll = ($miss.Count -eq 0)
$lines = @(
  "# Phase 1 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Full(er) Coverage Check",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_","",
  "## OK", ($ok -join "`r`n"), "", "## Gaps", ($miss -join "`r`n"), ""
)
$rep = Join-Path $Rep "phase1_fullcheck.md"
$lines | Set-Content $rep -Encoding UTF8
if($okAll){ "ok" | Set-Content (Join-Path $Sig 'phase1_full_applied.ok') -Encoding ASCII }
Write-Host $rep

