# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Compat_DashboardWriter.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }

$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path

$Rep = Join-Path $Base "reports"
$SS  = Join-Path $Rep  "status_summary.md"
$RM  = Join-Path $Rep  "roadmap_render.md"
$PH1 = Join-Path $Base "roadmap\PHASE 1.txt"
$PriceDir = Join-Path $Rep "price"
$PriceTot = Join-Path $PriceDir "total_cad.txt"
$PriceMD  = Join-Path $PriceDir "line_items.md"
$DashMD   = Join-Path $Rep  "dashboard.md"

# Ensure roadmap_render exists
$roBuilder = Join-Path $Base "tools\Build_RoadmapRender.ps1"
if(Test-Path $roBuilder){ powershell -NoProfile -ExecutionPolicy Bypass -File $roBuilder | Out-Null }

# Header + price
$header = "# Mason 2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Dashboard`r`n_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_`r`n"
$priceBlock = ""
if( (Test-Path $PriceTot) -and (Test-Path $PriceMD) ){
  $total = (Get-Content $PriceTot -Raw).Trim()
  $priceBlock = "## Current Total: **$${total} CAD**`r`n`r`n" + (Get-Content $PriceMD -Raw) + "`r`n"
}

# Compose: Price + Status + Roadmap (no Checklist)
$sep = "`r`n---`r`n"
$body = @()
if($priceBlock -ne ""){ $body += $priceBlock + $sep }
if(Test-Path $SS){ $body += (Get-Content $SS -Raw) } else { $body += "_status_summary.md missing_" }
$body += $sep
if(Test-Path $RM){ $body += (Get-Content $RM -Raw) }
elseif(Test-Path $PH1){ $body += (Get-Content $PH1 -Raw) }
else{ $body += "_Roadmap missing_" }

Set-Content $DashMD ($header + ($body -join "")) -Encoding UTF8
Ok ("Rendered dashboard -> " + $DashMD)

# Point both frontends at dashboard.md and also drop defensive copies
$Targets = @()
$Targets += (Join-Path $Base "ui\dashboard_path.txt")
$M1 = Join-Path $env:USERPROFILE "Desktop\Mason\Frontend"
$Targets += (Join-Path $M1 "dashboard_path.txt")
$Targets += (Join-Path $M1 "ui\dashboard_path.txt")

foreach($t in $Targets){
  $dir = Split-Path $t -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Set-Content $t -Value $DashMD -Encoding ASCII
}

# Defensive copies for UIs that ignore the pointer
$copies = @(
  (Join-Path $M1 "status_summary.md"),
  (Join-Path $M1 "dashboard.md"),
  (Join-Path $M1 "public\status_summary.md"),
  (Join-Path $M1 "public\dashboard.md")
)
foreach($c in $copies){
  $dir = Split-Path $c -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Copy-Item $DashMD $c -Force
}
Ok "Pointers and copies updated."


_tryRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace(Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Compat_DashboardWriter.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }

$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path

$Rep = Join-Path $Base "reports"
$SS  = Join-Path $Rep  "status_summary.md"
$RM  = Join-Path $Rep  "roadmap_render.md"
$PH1 = Join-Path $Base "roadmap\PHASE 1.txt"
$PriceDir = Join-Path $Rep "price"
$PriceTot = Join-Path $PriceDir "total_cad.txt"
$PriceMD  = Join-Path $PriceDir "line_items.md"
$DashMD   = Join-Path $Rep  "dashboard.md"

# Ensure roadmap_render exists
$roBuilder = Join-Path $Base "tools\Build_RoadmapRender.ps1"
if(Test-Path $roBuilder){ powershell -NoProfile -ExecutionPolicy Bypass -File $roBuilder | Out-Null }

# Header + price
$header = "# Mason 2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Dashboard`r`n_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_`r`n"
$priceBlock = ""
if( (Test-Path $PriceTot) -and (Test-Path $PriceMD) ){
  $total = (Get-Content $PriceTot -Raw).Trim()
  $priceBlock = "## Current Total: **$${total} CAD**`r`n`r`n" + (Get-Content $PriceMD -Raw) + "`r`n"
}

# Compose: Price + Status + Roadmap (no Checklist)
$sep = "`r`n---`r`n"
$body = @()
if($priceBlock -ne ""){ $body += $priceBlock + $sep }
if(Test-Path $SS){ $body += (Get-Content $SS -Raw) } else { $body += "_status_summary.md missing_" }
$body += $sep
if(Test-Path $RM){ $body += (Get-Content $RM -Raw) }
elseif(Test-Path $PH1){ $body += (Get-Content $PH1 -Raw) }
else{ $body += "_Roadmap missing_" }

Set-Content $DashMD ($header + ($body -join "")) -Encoding UTF8
Ok ("Rendered dashboard -> " + $DashMD)

# Point both frontends at dashboard.md and also drop defensive copies
$Targets = @()
$Targets += (Join-Path $Base "ui\dashboard_path.txt")
$M1 = Join-Path $env:USERPROFILE "Desktop\Mason\Frontend"
$Targets += (Join-Path $M1 "dashboard_path.txt")
$Targets += (Join-Path $M1 "ui\dashboard_path.txt")

foreach($t in $Targets){
  $dir = Split-Path $t -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Set-Content $t -Value $DashMD -Encoding ASCII
}

# Defensive copies for UIs that ignore the pointer
$copies = @(
  (Join-Path $M1 "status_summary.md"),
  (Join-Path $M1 "dashboard.md"),
  (Join-Path $M1 "public\status_summary.md"),
  (Join-Path $M1 "public\dashboard.md")
)
foreach($c in $copies){
  $dir = Split-Path $c -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Copy-Item $DashMD $c -Force
}
Ok "Pointers and copies updated."


_tryRoot)) {
  try { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Compat_DashboardWriter.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }

$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path

$Rep = Join-Path $Base "reports"
$SS  = Join-Path $Rep  "status_summary.md"
$RM  = Join-Path $Rep  "roadmap_render.md"
$PH1 = Join-Path $Base "roadmap\PHASE 1.txt"
$PriceDir = Join-Path $Rep "price"
$PriceTot = Join-Path $PriceDir "total_cad.txt"
$PriceMD  = Join-Path $PriceDir "line_items.md"
$DashMD   = Join-Path $Rep  "dashboard.md"

# Ensure roadmap_render exists
$roBuilder = Join-Path $Base "tools\Build_RoadmapRender.ps1"
if(Test-Path $roBuilder){ powershell -NoProfile -ExecutionPolicy Bypass -File $roBuilder | Out-Null }

# Header + price
$header = "# Mason 2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Dashboard`r`n_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_`r`n"
$priceBlock = ""
if( (Test-Path $PriceTot) -and (Test-Path $PriceMD) ){
  $total = (Get-Content $PriceTot -Raw).Trim()
  $priceBlock = "## Current Total: **$${total} CAD**`r`n`r`n" + (Get-Content $PriceMD -Raw) + "`r`n"
}

# Compose: Price + Status + Roadmap (no Checklist)
$sep = "`r`n---`r`n"
$body = @()
if($priceBlock -ne ""){ $body += $priceBlock + $sep }
if(Test-Path $SS){ $body += (Get-Content $SS -Raw) } else { $body += "_status_summary.md missing_" }
$body += $sep
if(Test-Path $RM){ $body += (Get-Content $RM -Raw) }
elseif(Test-Path $PH1){ $body += (Get-Content $PH1 -Raw) }
else{ $body += "_Roadmap missing_" }

Set-Content $DashMD ($header + ($body -join "")) -Encoding UTF8
Ok ("Rendered dashboard -> " + $DashMD)

# Point both frontends at dashboard.md and also drop defensive copies
$Targets = @()
$Targets += (Join-Path $Base "ui\dashboard_path.txt")
$M1 = Join-Path $env:USERPROFILE "Desktop\Mason\Frontend"
$Targets += (Join-Path $M1 "dashboard_path.txt")
$Targets += (Join-Path $M1 "ui\dashboard_path.txt")

foreach($t in $Targets){
  $dir = Split-Path $t -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Set-Content $t -Value $DashMD -Encoding ASCII
}

# Defensive copies for UIs that ignore the pointer
$copies = @(
  (Join-Path $M1 "status_summary.md"),
  (Join-Path $M1 "dashboard.md"),
  (Join-Path $M1 "public\status_summary.md"),
  (Join-Path $M1 "public\dashboard.md")
)
foreach($c in $copies){
  $dir = Split-Path $c -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Copy-Item $DashMD $c -Force
}
Ok "Pointers and copies updated."


_tryRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent } catch { Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Compat_DashboardWriter.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }

$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path

$Rep = Join-Path $Base "reports"
$SS  = Join-Path $Rep  "status_summary.md"
$RM  = Join-Path $Rep  "roadmap_render.md"
$PH1 = Join-Path $Base "roadmap\PHASE 1.txt"
$PriceDir = Join-Path $Rep "price"
$PriceTot = Join-Path $PriceDir "total_cad.txt"
$PriceMD  = Join-Path $PriceDir "line_items.md"
$DashMD   = Join-Path $Rep  "dashboard.md"

# Ensure roadmap_render exists
$roBuilder = Join-Path $Base "tools\Build_RoadmapRender.ps1"
if(Test-Path $roBuilder){ powershell -NoProfile -ExecutionPolicy Bypass -File $roBuilder | Out-Null }

# Header + price
$header = "# Mason 2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Dashboard`r`n_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_`r`n"
$priceBlock = ""
if( (Test-Path $PriceTot) -and (Test-Path $PriceMD) ){
  $total = (Get-Content $PriceTot -Raw).Trim()
  $priceBlock = "## Current Total: **$${total} CAD**`r`n`r`n" + (Get-Content $PriceMD -Raw) + "`r`n"
}

# Compose: Price + Status + Roadmap (no Checklist)
$sep = "`r`n---`r`n"
$body = @()
if($priceBlock -ne ""){ $body += $priceBlock + $sep }
if(Test-Path $SS){ $body += (Get-Content $SS -Raw) } else { $body += "_status_summary.md missing_" }
$body += $sep
if(Test-Path $RM){ $body += (Get-Content $RM -Raw) }
elseif(Test-Path $PH1){ $body += (Get-Content $PH1 -Raw) }
else{ $body += "_Roadmap missing_" }

Set-Content $DashMD ($header + ($body -join "")) -Encoding UTF8
Ok ("Rendered dashboard -> " + $DashMD)

# Point both frontends at dashboard.md and also drop defensive copies
$Targets = @()
$Targets += (Join-Path $Base "ui\dashboard_path.txt")
$M1 = Join-Path $env:USERPROFILE "Desktop\Mason\Frontend"
$Targets += (Join-Path $M1 "dashboard_path.txt")
$Targets += (Join-Path $M1 "ui\dashboard_path.txt")

foreach($t in $Targets){
  $dir = Split-Path $t -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Set-Content $t -Value $DashMD -Encoding ASCII
}

# Defensive copies for UIs that ignore the pointer
$copies = @(
  (Join-Path $M1 "status_summary.md"),
  (Join-Path $M1 "dashboard.md"),
  (Join-Path $M1 "public\status_summary.md"),
  (Join-Path $M1 "public\dashboard.md")
)
foreach($c in $copies){
  $dir = Split-Path $c -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Copy-Item $DashMD $c -Force
}
Ok "Pointers and copies updated."


_tryRoot = "$env:USERPROFILE\Desktop\Mason2\tools" }
}
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Compat_DashboardWriter.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }

$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path

$Rep = Join-Path $Base "reports"
$SS  = Join-Path $Rep  "status_summary.md"
$RM  = Join-Path $Rep  "roadmap_render.md"
$PH1 = Join-Path $Base "roadmap\PHASE 1.txt"
$PriceDir = Join-Path $Rep "price"
$PriceTot = Join-Path $PriceDir "total_cad.txt"
$PriceMD  = Join-Path $PriceDir "line_items.md"
$DashMD   = Join-Path $Rep  "dashboard.md"

# Ensure roadmap_render exists
$roBuilder = Join-Path $Base "tools\Build_RoadmapRender.ps1"
if(Test-Path $roBuilder){ powershell -NoProfile -ExecutionPolicy Bypass -File $roBuilder | Out-Null }

# Header + price
$header = "# Mason 2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Dashboard`r`n_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_`r`n"
$priceBlock = ""
if( (Test-Path $PriceTot) -and (Test-Path $PriceMD) ){
  $total = (Get-Content $PriceTot -Raw).Trim()
  $priceBlock = "## Current Total: **$${total} CAD**`r`n`r`n" + (Get-Content $PriceMD -Raw) + "`r`n"
}

# Compose: Price + Status + Roadmap (no Checklist)
$sep = "`r`n---`r`n"
$body = @()
if($priceBlock -ne ""){ $body += $priceBlock + $sep }
if(Test-Path $SS){ $body += (Get-Content $SS -Raw) } else { $body += "_status_summary.md missing_" }
$body += $sep
if(Test-Path $RM){ $body += (Get-Content $RM -Raw) }
elseif(Test-Path $PH1){ $body += (Get-Content $PH1 -Raw) }
else{ $body += "_Roadmap missing_" }

Set-Content $DashMD ($header + ($body -join "")) -Encoding UTF8
Ok ("Rendered dashboard -> " + $DashMD)

# Point both frontends at dashboard.md and also drop defensive copies
$Targets = @()
$Targets += (Join-Path $Base "ui\dashboard_path.txt")
$M1 = Join-Path $env:USERPROFILE "Desktop\Mason\Frontend"
$Targets += (Join-Path $M1 "dashboard_path.txt")
$Targets += (Join-Path $M1 "ui\dashboard_path.txt")

foreach($t in $Targets){
  $dir = Split-Path $t -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Set-Content $t -Value $DashMD -Encoding ASCII
}

# Defensive copies for UIs that ignore the pointer
$copies = @(
  (Join-Path $M1 "status_summary.md"),
  (Join-Path $M1 "dashboard.md"),
  (Join-Path $M1 "public\status_summary.md"),
  (Join-Path $M1 "public\dashboard.md")
)
foreach($c in $copies){
  $dir = Split-Path $c -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Copy-Item $DashMD $c -Force
}
Ok "Pointers and copies updated."


_lib = Join-Path (Split-Path Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Compat_DashboardWriter.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }

$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path

$Rep = Join-Path $Base "reports"
$SS  = Join-Path $Rep  "status_summary.md"
$RM  = Join-Path $Rep  "roadmap_render.md"
$PH1 = Join-Path $Base "roadmap\PHASE 1.txt"
$PriceDir = Join-Path $Rep "price"
$PriceTot = Join-Path $PriceDir "total_cad.txt"
$PriceMD  = Join-Path $PriceDir "line_items.md"
$DashMD   = Join-Path $Rep  "dashboard.md"

# Ensure roadmap_render exists
$roBuilder = Join-Path $Base "tools\Build_RoadmapRender.ps1"
if(Test-Path $roBuilder){ powershell -NoProfile -ExecutionPolicy Bypass -File $roBuilder | Out-Null }

# Header + price
$header = "# Mason 2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Dashboard`r`n_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_`r`n"
$priceBlock = ""
if( (Test-Path $PriceTot) -and (Test-Path $PriceMD) ){
  $total = (Get-Content $PriceTot -Raw).Trim()
  $priceBlock = "## Current Total: **$${total} CAD**`r`n`r`n" + (Get-Content $PriceMD -Raw) + "`r`n"
}

# Compose: Price + Status + Roadmap (no Checklist)
$sep = "`r`n---`r`n"
$body = @()
if($priceBlock -ne ""){ $body += $priceBlock + $sep }
if(Test-Path $SS){ $body += (Get-Content $SS -Raw) } else { $body += "_status_summary.md missing_" }
$body += $sep
if(Test-Path $RM){ $body += (Get-Content $RM -Raw) }
elseif(Test-Path $PH1){ $body += (Get-Content $PH1 -Raw) }
else{ $body += "_Roadmap missing_" }

Set-Content $DashMD ($header + ($body -join "")) -Encoding UTF8
Ok ("Rendered dashboard -> " + $DashMD)

# Point both frontends at dashboard.md and also drop defensive copies
$Targets = @()
$Targets += (Join-Path $Base "ui\dashboard_path.txt")
$M1 = Join-Path $env:USERPROFILE "Desktop\Mason\Frontend"
$Targets += (Join-Path $M1 "dashboard_path.txt")
$Targets += (Join-Path $M1 "ui\dashboard_path.txt")

foreach($t in $Targets){
  $dir = Split-Path $t -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Set-Content $t -Value $DashMD -Encoding ASCII
}

# Defensive copies for UIs that ignore the pointer
$copies = @(
  (Join-Path $M1 "status_summary.md"),
  (Join-Path $M1 "dashboard.md"),
  (Join-Path $M1 "public\status_summary.md"),
  (Join-Path $M1 "public\dashboard.md")
)
foreach($c in $copies){
  $dir = Split-Path $c -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Copy-Item $DashMD $c -Force
}
Ok "Pointers and copies updated."


_tryRoot -Parent) 'lib\Mason.Base.psm1'
Import-Module Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase# Mason2 Version: Mason2_20251104_145719.zip
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Compat_DashboardWriter.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }

$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path

$Rep = Join-Path $Base "reports"
$SS  = Join-Path $Rep  "status_summary.md"
$RM  = Join-Path $Rep  "roadmap_render.md"
$PH1 = Join-Path $Base "roadmap\PHASE 1.txt"
$PriceDir = Join-Path $Rep "price"
$PriceTot = Join-Path $PriceDir "total_cad.txt"
$PriceMD  = Join-Path $PriceDir "line_items.md"
$DashMD   = Join-Path $Rep  "dashboard.md"

# Ensure roadmap_render exists
$roBuilder = Join-Path $Base "tools\Build_RoadmapRender.ps1"
if(Test-Path $roBuilder){ powershell -NoProfile -ExecutionPolicy Bypass -File $roBuilder | Out-Null }

# Header + price
$header = "# Mason 2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Dashboard`r`n_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_`r`n"
$priceBlock = ""
if( (Test-Path $PriceTot) -and (Test-Path $PriceMD) ){
  $total = (Get-Content $PriceTot -Raw).Trim()
  $priceBlock = "## Current Total: **$${total} CAD**`r`n`r`n" + (Get-Content $PriceMD -Raw) + "`r`n"
}

# Compose: Price + Status + Roadmap (no Checklist)
$sep = "`r`n---`r`n"
$body = @()
if($priceBlock -ne ""){ $body += $priceBlock + $sep }
if(Test-Path $SS){ $body += (Get-Content $SS -Raw) } else { $body += "_status_summary.md missing_" }
$body += $sep
if(Test-Path $RM){ $body += (Get-Content $RM -Raw) }
elseif(Test-Path $PH1){ $body += (Get-Content $PH1 -Raw) }
else{ $body += "_Roadmap missing_" }

Set-Content $DashMD ($header + ($body -join "")) -Encoding UTF8
Ok ("Rendered dashboard -> " + $DashMD)

# Point both frontends at dashboard.md and also drop defensive copies
$Targets = @()
$Targets += (Join-Path $Base "ui\dashboard_path.txt")
$M1 = Join-Path $env:USERPROFILE "Desktop\Mason\Frontend"
$Targets += (Join-Path $M1 "dashboard_path.txt")
$Targets += (Join-Path $M1 "ui\dashboard_path.txt")

foreach($t in $Targets){
  $dir = Split-Path $t -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Set-Content $t -Value $DashMD -Encoding ASCII
}

# Defensive copies for UIs that ignore the pointer
$copies = @(
  (Join-Path $M1 "status_summary.md"),
  (Join-Path $M1 "dashboard.md"),
  (Join-Path $M1 "public\status_summary.md"),
  (Join-Path $M1 "public\dashboard.md")
)
foreach($c in $copies){
  $dir = Split-Path $c -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Copy-Item $DashMD $c -Force
}
Ok "Pointers and copies updated."


_lib -Force
$MasonBase = Get-MasonBase
Set-Location $MasonBase
# Stamped: 2025-11-05T17:02:01
# Mason2-Version: 2025-11-03T21:27:57; RoadmapSHA: 5CBDB63808F6D1F666BDB9F147CF88411CC5414AC3B488AB41BB21A44ED19E94
# Mason2-File: tools\Compat_DashboardWriter.ps1
param([string]$BaseOverride = "")
function Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }

$Base = if([string]::IsNullOrWhiteSpace($BaseOverride)){ Join-Path $env:USERPROFILE "Desktop\Mason2" } else { $BaseOverride }
$Base = (Resolve-Path $Base).Path

$Rep = Join-Path $Base "reports"
$SS  = Join-Path $Rep  "status_summary.md"
$RM  = Join-Path $Rep  "roadmap_render.md"
$PH1 = Join-Path $Base "roadmap\PHASE 1.txt"
$PriceDir = Join-Path $Rep "price"
$PriceTot = Join-Path $PriceDir "total_cad.txt"
$PriceMD  = Join-Path $PriceDir "line_items.md"
$DashMD   = Join-Path $Rep  "dashboard.md"

# Ensure roadmap_render exists
$roBuilder = Join-Path $Base "tools\Build_RoadmapRender.ps1"
if(Test-Path $roBuilder){ powershell -NoProfile -ExecutionPolicy Bypass -File $roBuilder | Out-Null }

# Header + price
$header = "# Mason 2 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â Dashboard`r`n_Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')_`r`n"
$priceBlock = ""
if( (Test-Path $PriceTot) -and (Test-Path $PriceMD) ){
  $total = (Get-Content $PriceTot -Raw).Trim()
  $priceBlock = "## Current Total: **$${total} CAD**`r`n`r`n" + (Get-Content $PriceMD -Raw) + "`r`n"
}

# Compose: Price + Status + Roadmap (no Checklist)
$sep = "`r`n---`r`n"
$body = @()
if($priceBlock -ne ""){ $body += $priceBlock + $sep }
if(Test-Path $SS){ $body += (Get-Content $SS -Raw) } else { $body += "_status_summary.md missing_" }
$body += $sep
if(Test-Path $RM){ $body += (Get-Content $RM -Raw) }
elseif(Test-Path $PH1){ $body += (Get-Content $PH1 -Raw) }
else{ $body += "_Roadmap missing_" }

Set-Content $DashMD ($header + ($body -join "")) -Encoding UTF8
Ok ("Rendered dashboard -> " + $DashMD)

# Point both frontends at dashboard.md and also drop defensive copies
$Targets = @()
$Targets += (Join-Path $Base "ui\dashboard_path.txt")
$M1 = Join-Path $env:USERPROFILE "Desktop\Mason\Frontend"
$Targets += (Join-Path $M1 "dashboard_path.txt")
$Targets += (Join-Path $M1 "ui\dashboard_path.txt")

foreach($t in $Targets){
  $dir = Split-Path $t -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Set-Content $t -Value $DashMD -Encoding ASCII
}

# Defensive copies for UIs that ignore the pointer
$copies = @(
  (Join-Path $M1 "status_summary.md"),
  (Join-Path $M1 "dashboard.md"),
  (Join-Path $M1 "public\status_summary.md"),
  (Join-Path $M1 "public\dashboard.md")
)
foreach($c in $copies){
  $dir = Split-Path $c -Parent
  if(-not (Test-Path $dir)){ New-Item -ItemType Directory -Path $dir | Out-Null }
  Copy-Item $DashMD $c -Force
}
Ok "Pointers and copies updated."


