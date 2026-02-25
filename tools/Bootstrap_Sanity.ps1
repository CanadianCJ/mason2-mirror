# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking -ErrorAction SilentlyContinue
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Rep -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$warn=@();$fix=@();$err=@()

function T([bool]$b,[string]$good,[string]$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$err+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }
function W([bool]$b,[string]$note){ if(-not $b){$warn+=("ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â "+$note)} }

# PS version
$psv = $PSVersionTable.PSVersion.ToString()
W ([version]$PSVersionTable.PSVersion -ge [version]'5.1') "PowerShell >= 5.1 recommended (you have $psv)"

# Required dirs
$dirs = @("config","tools","services","reports","logs","dist","dist\releases","snapshots")
foreach($d in $dirs){ $full = Join-Path $Base $d; if(-not (Test-Path $full)){ try{ ni $full -ItemType Directory -ea Stop | Out-Null; $fix+="created $d"}catch{ $err+="make dir failed: $d -> $($_.Exception.Message)" } } }

# Logging module loads?
try{
  Import-Module (Join-Path $Base "services\Log.psm1") -Force -DisableNameChecking
  T $true "Logging module loads" "Logging module missing"
}catch{ $err+="Logging module load failed: $($_.Exception.Message)" }

# Manifest & integrity files
$man = Join-Path $Base "dist\manifest.json"
if(-not (Test-Path $man)){
  try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null; $fix+="generated manifest" }catch{ $err+="manifest gen failed: $($_.Exception.Message)" }
}
T (Test-Path $man) "Manifest present" "Manifest missing"
T (Test-Path (Join-Path $Rep "roadmap_integrity.json")) "Roadmap integrity present" "Roadmap integrity missing"

# Disk telemetry present?
$dh = Join-Path $Base "logs\telemetry\disk_health.csv"
if(-not (Test-Path $dh)){ try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Disk_Health.ps1"); $fix+="seeded disk health" }catch{} }
T (Test-Path $dh) "Disk telemetry ok" "Disk telemetry missing"

# Heartbeat file freshness
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
if(-not (Test-Path $hb)){ (Get-Date -Format s) | Set-Content $hb -Encoding ASCII }
$hbAge = [int]([datetime]::Now - (Get-Item $hb).LastWriteTime).TotalMinutes
W ($hbAge -le 5) "Heartbeat older than 5m (age=${hbAge}m) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â scheduler may be idle"

# Scheduled tasks present?
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard")
foreach($n in $need){
  $csv = & schtasks.exe /Query /TN $n /FO CSV 2>$null
  if(-not $csv){ $warn+="task missing: $n" }
}

# Write report
$lines = @(
  "# Mason2 Bootstrap Sanity",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## OK", ($ok -join "`r`n"),
  "", "## Fixups", ($fix -join "`r`n"),
  "", "## Warnings", ($warn -join "`r`n"),
  "", "## Errors", ($err -join "`r`n")
)
$rep = Join-Path $Rep "bootstrap_sanity.md"
$lines | Set-Content $rep -Encoding UTF8
if($err.Count -eq 0){ "ok" | Set-Content (Join-Path $Sig 'bootstrap.ok') -Encoding ASCII }
try{ Write-JsonLog -Component "bootstrap" -Level "INFO" -Message "bootstrap check done" -Props @{ warn=$warn.Count; err=$err.Count } }catch{}
Write-Host $rep

_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking -ErrorAction SilentlyContinue
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Rep -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$warn=@();$fix=@();$err=@()

function T([bool]$b,[string]$good,[string]$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$err+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }
function W([bool]$b,[string]$note){ if(-not $b){$warn+=("ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â "+$note)} }

# PS version
$psv = $PSVersionTable.PSVersion.ToString()
W ([version]$PSVersionTable.PSVersion -ge [version]'5.1') "PowerShell >= 5.1 recommended (you have $psv)"

# Required dirs
$dirs = @("config","tools","services","reports","logs","dist","dist\releases","snapshots")
foreach($d in $dirs){ $full = Join-Path $Base $d; if(-not (Test-Path $full)){ try{ ni $full -ItemType Directory -ea Stop | Out-Null; $fix+="created $d"}catch{ $err+="make dir failed: $d -> $($_.Exception.Message)" } } }

# Logging module loads?
try{
  Import-Module (Join-Path $Base "services\Log.psm1") -Force -DisableNameChecking
  T $true "Logging module loads" "Logging module missing"
}catch{ $err+="Logging module load failed: $($_.Exception.Message)" }

# Manifest & integrity files
$man = Join-Path $Base "dist\manifest.json"
if(-not (Test-Path $man)){
  try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null; $fix+="generated manifest" }catch{ $err+="manifest gen failed: $($_.Exception.Message)" }
}
T (Test-Path $man) "Manifest present" "Manifest missing"
T (Test-Path (Join-Path $Rep "roadmap_integrity.json")) "Roadmap integrity present" "Roadmap integrity missing"

# Disk telemetry present?
$dh = Join-Path $Base "logs\telemetry\disk_health.csv"
if(-not (Test-Path $dh)){ try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Disk_Health.ps1"); $fix+="seeded disk health" }catch{} }
T (Test-Path $dh) "Disk telemetry ok" "Disk telemetry missing"

# Heartbeat file freshness
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
if(-not (Test-Path $hb)){ (Get-Date -Format s) | Set-Content $hb -Encoding ASCII }
$hbAge = [int]([datetime]::Now - (Get-Item $hb).LastWriteTime).TotalMinutes
W ($hbAge -le 5) "Heartbeat older than 5m (age=${hbAge}m) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â scheduler may be idle"

# Scheduled tasks present?
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard")
foreach($n in $need){
  $csv = & schtasks.exe /Query /TN $n /FO CSV 2>$null
  if(-not $csv){ $warn+="task missing: $n" }
}

# Write report
$lines = @(
  "# Mason2 Bootstrap Sanity",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## OK", ($ok -join "`r`n"),
  "", "## Fixups", ($fix -join "`r`n"),
  "", "## Warnings", ($warn -join "`r`n"),
  "", "## Errors", ($err -join "`r`n")
)
$rep = Join-Path $Rep "bootstrap_sanity.md"
$lines | Set-Content $rep -Encoding UTF8
if($err.Count -eq 0){ "ok" | Set-Content (Join-Path $Sig 'bootstrap.ok') -Encoding ASCII }
try{ Write-JsonLog -Component "bootstrap" -Level "INFO" -Message "bootstrap check done" -Props @{ warn=$warn.Count; err=$err.Count } }catch{}
Write-Host $rep

_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking -ErrorAction SilentlyContinue
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Rep -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$warn=@();$fix=@();$err=@()

function T([bool]$b,[string]$good,[string]$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$err+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }
function W([bool]$b,[string]$note){ if(-not $b){$warn+=("ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â "+$note)} }

# PS version
$psv = $PSVersionTable.PSVersion.ToString()
W ([version]$PSVersionTable.PSVersion -ge [version]'5.1') "PowerShell >= 5.1 recommended (you have $psv)"

# Required dirs
$dirs = @("config","tools","services","reports","logs","dist","dist\releases","snapshots")
foreach($d in $dirs){ $full = Join-Path $Base $d; if(-not (Test-Path $full)){ try{ ni $full -ItemType Directory -ea Stop | Out-Null; $fix+="created $d"}catch{ $err+="make dir failed: $d -> $($_.Exception.Message)" } } }

# Logging module loads?
try{
  Import-Module (Join-Path $Base "services\Log.psm1") -Force -DisableNameChecking
  T $true "Logging module loads" "Logging module missing"
}catch{ $err+="Logging module load failed: $($_.Exception.Message)" }

# Manifest & integrity files
$man = Join-Path $Base "dist\manifest.json"
if(-not (Test-Path $man)){
  try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null; $fix+="generated manifest" }catch{ $err+="manifest gen failed: $($_.Exception.Message)" }
}
T (Test-Path $man) "Manifest present" "Manifest missing"
T (Test-Path (Join-Path $Rep "roadmap_integrity.json")) "Roadmap integrity present" "Roadmap integrity missing"

# Disk telemetry present?
$dh = Join-Path $Base "logs\telemetry\disk_health.csv"
if(-not (Test-Path $dh)){ try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Disk_Health.ps1"); $fix+="seeded disk health" }catch{} }
T (Test-Path $dh) "Disk telemetry ok" "Disk telemetry missing"

# Heartbeat file freshness
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
if(-not (Test-Path $hb)){ (Get-Date -Format s) | Set-Content $hb -Encoding ASCII }
$hbAge = [int]([datetime]::Now - (Get-Item $hb).LastWriteTime).TotalMinutes
W ($hbAge -le 5) "Heartbeat older than 5m (age=${hbAge}m) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â scheduler may be idle"

# Scheduled tasks present?
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard")
foreach($n in $need){
  $csv = & schtasks.exe /Query /TN $n /FO CSV 2>$null
  if(-not $csv){ $warn+="task missing: $n" }
}

# Write report
$lines = @(
  "# Mason2 Bootstrap Sanity",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## OK", ($ok -join "`r`n"),
  "", "## Fixups", ($fix -join "`r`n"),
  "", "## Warnings", ($warn -join "`r`n"),
  "", "## Errors", ($err -join "`r`n")
)
$rep = Join-Path $Rep "bootstrap_sanity.md"
$lines | Set-Content $rep -Encoding UTF8
if($err.Count -eq 0){ "ok" | Set-Content (Join-Path $Sig 'bootstrap.ok') -Encoding ASCII }
try{ Write-JsonLog -Component "bootstrap" -Level "INFO" -Message "bootstrap check done" -Props @{ warn=$warn.Count; err=$err.Count } }catch{}
Write-Host $rep

_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking -ErrorAction SilentlyContinue
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Rep -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$warn=@();$fix=@();$err=@()

function T([bool]$b,[string]$good,[string]$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$err+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }
function W([bool]$b,[string]$note){ if(-not $b){$warn+=("ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â "+$note)} }

# PS version
$psv = $PSVersionTable.PSVersion.ToString()
W ([version]$PSVersionTable.PSVersion -ge [version]'5.1') "PowerShell >= 5.1 recommended (you have $psv)"

# Required dirs
$dirs = @("config","tools","services","reports","logs","dist","dist\releases","snapshots")
foreach($d in $dirs){ $full = Join-Path $Base $d; if(-not (Test-Path $full)){ try{ ni $full -ItemType Directory -ea Stop | Out-Null; $fix+="created $d"}catch{ $err+="make dir failed: $d -> $($_.Exception.Message)" } } }

# Logging module loads?
try{
  Import-Module (Join-Path $Base "services\Log.psm1") -Force -DisableNameChecking
  T $true "Logging module loads" "Logging module missing"
}catch{ $err+="Logging module load failed: $($_.Exception.Message)" }

# Manifest & integrity files
$man = Join-Path $Base "dist\manifest.json"
if(-not (Test-Path $man)){
  try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null; $fix+="generated manifest" }catch{ $err+="manifest gen failed: $($_.Exception.Message)" }
}
T (Test-Path $man) "Manifest present" "Manifest missing"
T (Test-Path (Join-Path $Rep "roadmap_integrity.json")) "Roadmap integrity present" "Roadmap integrity missing"

# Disk telemetry present?
$dh = Join-Path $Base "logs\telemetry\disk_health.csv"
if(-not (Test-Path $dh)){ try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Disk_Health.ps1"); $fix+="seeded disk health" }catch{} }
T (Test-Path $dh) "Disk telemetry ok" "Disk telemetry missing"

# Heartbeat file freshness
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
if(-not (Test-Path $hb)){ (Get-Date -Format s) | Set-Content $hb -Encoding ASCII }
$hbAge = [int]([datetime]::Now - (Get-Item $hb).LastWriteTime).TotalMinutes
W ($hbAge -le 5) "Heartbeat older than 5m (age=${hbAge}m) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â scheduler may be idle"

# Scheduled tasks present?
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard")
foreach($n in $need){
  $csv = & schtasks.exe /Query /TN $n /FO CSV 2>$null
  if(-not $csv){ $warn+="task missing: $n" }
}

# Write report
$lines = @(
  "# Mason2 Bootstrap Sanity",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## OK", ($ok -join "`r`n"),
  "", "## Fixups", ($fix -join "`r`n"),
  "", "## Warnings", ($warn -join "`r`n"),
  "", "## Errors", ($err -join "`r`n")
)
$rep = Join-Path $Rep "bootstrap_sanity.md"
$lines | Set-Content $rep -Encoding UTF8
if($err.Count -eq 0){ "ok" | Set-Content (Join-Path $Sig 'bootstrap.ok') -Encoding ASCII }
try{ Write-JsonLog -Component "bootstrap" -Level "INFO" -Message "bootstrap check done" -Props @{ warn=$warn.Count; err=$err.Count } }catch{}
Write-Host $rep

_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking -ErrorAction SilentlyContinue
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Rep -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$warn=@();$fix=@();$err=@()

function T([bool]$b,[string]$good,[string]$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$err+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }
function W([bool]$b,[string]$note){ if(-not $b){$warn+=("ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â "+$note)} }

# PS version
$psv = $PSVersionTable.PSVersion.ToString()
W ([version]$PSVersionTable.PSVersion -ge [version]'5.1') "PowerShell >= 5.1 recommended (you have $psv)"

# Required dirs
$dirs = @("config","tools","services","reports","logs","dist","dist\releases","snapshots")
foreach($d in $dirs){ $full = Join-Path $Base $d; if(-not (Test-Path $full)){ try{ ni $full -ItemType Directory -ea Stop | Out-Null; $fix+="created $d"}catch{ $err+="make dir failed: $d -> $($_.Exception.Message)" } } }

# Logging module loads?
try{
  Import-Module (Join-Path $Base "services\Log.psm1") -Force -DisableNameChecking
  T $true "Logging module loads" "Logging module missing"
}catch{ $err+="Logging module load failed: $($_.Exception.Message)" }

# Manifest & integrity files
$man = Join-Path $Base "dist\manifest.json"
if(-not (Test-Path $man)){
  try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null; $fix+="generated manifest" }catch{ $err+="manifest gen failed: $($_.Exception.Message)" }
}
T (Test-Path $man) "Manifest present" "Manifest missing"
T (Test-Path (Join-Path $Rep "roadmap_integrity.json")) "Roadmap integrity present" "Roadmap integrity missing"

# Disk telemetry present?
$dh = Join-Path $Base "logs\telemetry\disk_health.csv"
if(-not (Test-Path $dh)){ try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Disk_Health.ps1"); $fix+="seeded disk health" }catch{} }
T (Test-Path $dh) "Disk telemetry ok" "Disk telemetry missing"

# Heartbeat file freshness
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
if(-not (Test-Path $hb)){ (Get-Date -Format s) | Set-Content $hb -Encoding ASCII }
$hbAge = [int]([datetime]::Now - (Get-Item $hb).LastWriteTime).TotalMinutes
W ($hbAge -le 5) "Heartbeat older than 5m (age=${hbAge}m) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â scheduler may be idle"

# Scheduled tasks present?
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard")
foreach($n in $need){
  $csv = & schtasks.exe /Query /TN $n /FO CSV 2>$null
  if(-not $csv){ $warn+="task missing: $n" }
}

# Write report
$lines = @(
  "# Mason2 Bootstrap Sanity",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## OK", ($ok -join "`r`n"),
  "", "## Fixups", ($fix -join "`r`n"),
  "", "## Warnings", ($warn -join "`r`n"),
  "", "## Errors", ($err -join "`r`n")
)
$rep = Join-Path $Rep "bootstrap_sanity.md"
$lines | Set-Content $rep -Encoding UTF8
if($err.Count -eq 0){ "ok" | Set-Content (Join-Path $Sig 'bootstrap.ok') -Encoding ASCII }
try{ Write-JsonLog -Component "bootstrap" -Level "INFO" -Message "bootstrap check done" -Props @{ warn=$warn.Count; err=$err.Count } }catch{}
Write-Host $rep

_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking -ErrorAction SilentlyContinue
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Rep -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$warn=@();$fix=@();$err=@()

function T([bool]$b,[string]$good,[string]$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$err+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }
function W([bool]$b,[string]$note){ if(-not $b){$warn+=("ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â "+$note)} }

# PS version
$psv = $PSVersionTable.PSVersion.ToString()
W ([version]$PSVersionTable.PSVersion -ge [version]'5.1') "PowerShell >= 5.1 recommended (you have $psv)"

# Required dirs
$dirs = @("config","tools","services","reports","logs","dist","dist\releases","snapshots")
foreach($d in $dirs){ $full = Join-Path $Base $d; if(-not (Test-Path $full)){ try{ ni $full -ItemType Directory -ea Stop | Out-Null; $fix+="created $d"}catch{ $err+="make dir failed: $d -> $($_.Exception.Message)" } } }

# Logging module loads?
try{
  Import-Module (Join-Path $Base "services\Log.psm1") -Force -DisableNameChecking
  T $true "Logging module loads" "Logging module missing"
}catch{ $err+="Logging module load failed: $($_.Exception.Message)" }

# Manifest & integrity files
$man = Join-Path $Base "dist\manifest.json"
if(-not (Test-Path $man)){
  try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null; $fix+="generated manifest" }catch{ $err+="manifest gen failed: $($_.Exception.Message)" }
}
T (Test-Path $man) "Manifest present" "Manifest missing"
T (Test-Path (Join-Path $Rep "roadmap_integrity.json")) "Roadmap integrity present" "Roadmap integrity missing"

# Disk telemetry present?
$dh = Join-Path $Base "logs\telemetry\disk_health.csv"
if(-not (Test-Path $dh)){ try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Disk_Health.ps1"); $fix+="seeded disk health" }catch{} }
T (Test-Path $dh) "Disk telemetry ok" "Disk telemetry missing"

# Heartbeat file freshness
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
if(-not (Test-Path $hb)){ (Get-Date -Format s) | Set-Content $hb -Encoding ASCII }
$hbAge = [int]([datetime]::Now - (Get-Item $hb).LastWriteTime).TotalMinutes
W ($hbAge -le 5) "Heartbeat older than 5m (age=${hbAge}m) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â scheduler may be idle"

# Scheduled tasks present?
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard")
foreach($n in $need){
  $csv = & schtasks.exe /Query /TN $n /FO CSV 2>$null
  if(-not $csv){ $warn+="task missing: $n" }
}

# Write report
$lines = @(
  "# Mason2 Bootstrap Sanity",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## OK", ($ok -join "`r`n"),
  "", "## Fixups", ($fix -join "`r`n"),
  "", "## Warnings", ($warn -join "`r`n"),
  "", "## Errors", ($err -join "`r`n")
)
$rep = Join-Path $Rep "bootstrap_sanity.md"
$lines | Set-Content $rep -Encoding UTF8
if($err.Count -eq 0){ "ok" | Set-Content (Join-Path $Sig 'bootstrap.ok') -Encoding ASCII }
try{ Write-JsonLog -Component "bootstrap" -Level "INFO" -Message "bootstrap check done" -Props @{ warn=$warn.Count; err=$err.Count } }catch{}
Write-Host $rep

_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking -ErrorAction SilentlyContinue
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Rep -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$warn=@();$fix=@();$err=@()

function T([bool]$b,[string]$good,[string]$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$err+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }
function W([bool]$b,[string]$note){ if(-not $b){$warn+=("ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â "+$note)} }

# PS version
$psv = $PSVersionTable.PSVersion.ToString()
W ([version]$PSVersionTable.PSVersion -ge [version]'5.1') "PowerShell >= 5.1 recommended (you have $psv)"

# Required dirs
$dirs = @("config","tools","services","reports","logs","dist","dist\releases","snapshots")
foreach($d in $dirs){ $full = Join-Path $Base $d; if(-not (Test-Path $full)){ try{ ni $full -ItemType Directory -ea Stop | Out-Null; $fix+="created $d"}catch{ $err+="make dir failed: $d -> $($_.Exception.Message)" } } }

# Logging module loads?
try{
  Import-Module (Join-Path $Base "services\Log.psm1") -Force -DisableNameChecking
  T $true "Logging module loads" "Logging module missing"
}catch{ $err+="Logging module load failed: $($_.Exception.Message)" }

# Manifest & integrity files
$man = Join-Path $Base "dist\manifest.json"
if(-not (Test-Path $man)){
  try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null; $fix+="generated manifest" }catch{ $err+="manifest gen failed: $($_.Exception.Message)" }
}
T (Test-Path $man) "Manifest present" "Manifest missing"
T (Test-Path (Join-Path $Rep "roadmap_integrity.json")) "Roadmap integrity present" "Roadmap integrity missing"

# Disk telemetry present?
$dh = Join-Path $Base "logs\telemetry\disk_health.csv"
if(-not (Test-Path $dh)){ try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Disk_Health.ps1"); $fix+="seeded disk health" }catch{} }
T (Test-Path $dh) "Disk telemetry ok" "Disk telemetry missing"

# Heartbeat file freshness
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
if(-not (Test-Path $hb)){ (Get-Date -Format s) | Set-Content $hb -Encoding ASCII }
$hbAge = [int]([datetime]::Now - (Get-Item $hb).LastWriteTime).TotalMinutes
W ($hbAge -le 5) "Heartbeat older than 5m (age=${hbAge}m) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â scheduler may be idle"

# Scheduled tasks present?
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard")
foreach($n in $need){
  $csv = & schtasks.exe /Query /TN $n /FO CSV 2>$null
  if(-not $csv){ $warn+="task missing: $n" }
}

# Write report
$lines = @(
  "# Mason2 Bootstrap Sanity",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## OK", ($ok -join "`r`n"),
  "", "## Fixups", ($fix -join "`r`n"),
  "", "## Warnings", ($warn -join "`r`n"),
  "", "## Errors", ($err -join "`r`n")
)
$rep = Join-Path $Rep "bootstrap_sanity.md"
$lines | Set-Content $rep -Encoding UTF8
if($err.Count -eq 0){ "ok" | Set-Content (Join-Path $Sig 'bootstrap.ok') -Encoding ASCII }
try{ Write-JsonLog -Component "bootstrap" -Level "INFO" -Message "bootstrap check done" -Props @{ warn=$warn.Count; err=$err.Count } }catch{}
Write-Host $rep

_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 1.2.0
Import-Module (Join-Path $env:USERPROFILE "Desktop\Mason2\services\Log.psm1") -Force -DisableNameChecking -ErrorAction SilentlyContinue
$Base = Join-Path $env:USERPROFILE "Desktop\Mason2"
$Rep  = Join-Path $Base "reports"
$Sig  = Join-Path $Rep  "signals"
ni $Rep -ItemType Directory -ea SilentlyContinue | Out-Null
ni $Sig -ItemType Directory -ea SilentlyContinue | Out-Null
$ok=@();$warn=@();$fix=@();$err=@()

function T([bool]$b,[string]$good,[string]$bad){ if($b){$ok+=("ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ "+$good)}else{$err+=("ÃƒÂ¢Ã‚ÂÃ…â€™ "+$bad)} }
function W([bool]$b,[string]$note){ if(-not $b){$warn+=("ÃƒÂ¢Ã…Â¡Ã‚Â ÃƒÂ¯Ã‚Â¸Ã‚Â "+$note)} }

# PS version
$psv = $PSVersionTable.PSVersion.ToString()
W ([version]$PSVersionTable.PSVersion -ge [version]'5.1') "PowerShell >= 5.1 recommended (you have $psv)"

# Required dirs
$dirs = @("config","tools","services","reports","logs","dist","dist\releases","snapshots")
foreach($d in $dirs){ $full = Join-Path $Base $d; if(-not (Test-Path $full)){ try{ ni $full -ItemType Directory -ea Stop | Out-Null; $fix+="created $d"}catch{ $err+="make dir failed: $d -> $($_.Exception.Message)" } } }

# Logging module loads?
try{
  Import-Module (Join-Path $Base "services\Log.psm1") -Force -DisableNameChecking
  T $true "Logging module loads" "Logging module missing"
}catch{ $err+="Logging module load failed: $($_.Exception.Message)" }

# Manifest & integrity files
$man = Join-Path $Base "dist\manifest.json"
if(-not (Test-Path $man)){
  try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Create_Portable_Manifest.ps1") | Out-Null; $fix+="generated manifest" }catch{ $err+="manifest gen failed: $($_.Exception.Message)" }
}
T (Test-Path $man) "Manifest present" "Manifest missing"
T (Test-Path (Join-Path $Rep "roadmap_integrity.json")) "Roadmap integrity present" "Roadmap integrity missing"

# Disk telemetry present?
$dh = Join-Path $Base "logs\telemetry\disk_health.csv"
if(-not (Test-Path $dh)){ try{ powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Base "tools\Disk_Health.ps1"); $fix+="seeded disk health" }catch{} }
T (Test-Path $dh) "Disk telemetry ok" "Disk telemetry missing"

# Heartbeat file freshness
$hb = Join-Path $Base "logs\telemetry\heartbeat.log"
if(-not (Test-Path $hb)){ (Get-Date -Format s) | Set-Content $hb -Encoding ASCII }
$hbAge = [int]([datetime]::Now - (Get-Item $hb).LastWriteTime).TotalMinutes
W ($hbAge -le 5) "Heartbeat older than 5m (age=${hbAge}m) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â scheduler may be idle"

# Scheduled tasks present?
$need = @("Mason2 Heartbeat","Mason2 Watchdog","Mason2 Governor","Mason2 AnomalyDetector","Mason2 Coalescer","Mason2 RetrySweeper","Mason2 StuckJobDetector","Mason2 ScheduleDriftAlarms","Mason2 Dashboard")
foreach($n in $need){
  $csv = & schtasks.exe /Query /TN $n /FO CSV 2>$null
  if(-not $csv){ $warn+="task missing: $n" }
}

# Write report
$lines = @(
  "# Mason2 Bootstrap Sanity",
  "_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_",
  "",
  "## OK", ($ok -join "`r`n"),
  "", "## Fixups", ($fix -join "`r`n"),
  "", "## Warnings", ($warn -join "`r`n"),
  "", "## Errors", ($err -join "`r`n")
)
$rep = Join-Path $Rep "bootstrap_sanity.md"
$lines | Set-Content $rep -Encoding UTF8
if($err.Count -eq 0){ "ok" | Set-Content (Join-Path $Sig 'bootstrap.ok') -Encoding ASCII }
try{ Write-JsonLog -Component "bootstrap" -Level "INFO" -Message "bootstrap check done" -Props @{ warn=$warn.Count; err=$err.Count } }catch{}
Write-Host $rep

