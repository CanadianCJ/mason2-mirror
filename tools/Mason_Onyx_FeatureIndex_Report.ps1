Param()

$ErrorActionPreference = "Stop"

$toolsDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$base       = Split-Path -Parent $toolsDir

$configDir  = Join-Path $base "config"
$stateDir   = Join-Path $base "state\onyx"
$reportsDir = Join-Path $base "reports"

New-Item -ItemType Directory -Force -Path $reportsDir | Out-Null

$featureIndexPath = Join-Path $configDir "onyx_feature_index.json"
$menuPath         = Join-Path $configDir "onyx_menu.json"
$planStatePath    = Join-Path $stateDir  "plan_state.json"

$result = [ordered]@{
    kind            = "onyx_feature_index_report"
    generated_at    = (Get-Date).ToString("o")
    feature_index   = $null
    menu            = $null
    plan_state      = $null
    summary         = [ordered]@{
        feature_count          = 0
        features_by_category   = @{}
        features_by_status     = @{}
        features_by_readiness  = @{}
        menu_section_count     = 0
        menu_item_count        = 0
        current_tier           = $null
        beta_opt_in            = $false
        business_name          = $null
        business_type          = $null
    }
    messages        = @()
}

function Load-JsonFile {
    param(
        [string]$Path,
        [string]$Label
    )
    if (-not (Test-Path $Path)) {
        $result.messages += "$Label not found at $Path"
        return $null
    }
    try {
        return Get-Content $Path -Raw | ConvertFrom-Json
    }
    catch {
        $result.messages += "Failed to parse $Label ($Path): $($_.Exception.Message)"
        return $null
    }
}

# Load files
$featureIndex = Load-JsonFile -Path $featureIndexPath -Label "feature index"
$menu         = Load-JsonFile -Path $menuPath         -Label "menu"
$planState    = Load-JsonFile -Path $planStatePath    -Label "plan state"

$result.feature_index = $featureIndex
$result.menu          = $menu
$result.plan_state    = $planState

# Build summary
if ($featureIndex -and $featureIndex.features) {
    $features = @($featureIndex.features)
    $result.summary.feature_count = $features.Count

    $byCat = @{}
    $byStatus = @{}
    $byReady = @{}

    foreach ($f in $features) {
        $cat = if ($f.category) { $f.category } else { "uncategorized" }
        $st  = if ($f.status)   { $f.status }   else { "unknown" }
        $rd  = if ($f.readiness){ $f.readiness} else { "unknown" }

        if (-not $byCat.ContainsKey($cat))   { $byCat[$cat]   = 0 }
        if (-not $byStatus.ContainsKey($st)) { $byStatus[$st] = 0 }
        if (-not $byReady.ContainsKey($rd))  { $byReady[$rd]  = 0 }

        $byCat[$cat]++
        $byStatus[$st]++
        $byReady[$rd]++
    }

    $result.summary.features_by_category  = $byCat
    $result.summary.features_by_status    = $byStatus
    $result.summary.features_by_readiness = $byReady
}

if ($menu -and $menu.sections) {
    $sections = @($menu.sections)
    $result.summary.menu_section_count = $sections.Count
    $totalItems = 0
    foreach ($s in $sections) {
        if ($s.items) {
            $totalItems += @($s.items).Count
        }
    }
    $result.summary.menu_item_count = $totalItems
}

if ($planState) {
    if ($planState.plan) {
        $result.summary.current_tier = $planState.plan.current_tier
        $result.summary.beta_opt_in  = [bool]$planState.plan.beta_opt_in
    }
    if ($planState.business_profile) {
        $result.summary.business_name = $planState.business_profile.business_name
        $result.summary.business_type = $planState.business_profile.business_type
    }
}

$reportPath = Join-Path $reportsDir "onyx_feature_index_report.json"
($result | ConvertTo-Json -Depth 6) | Set-Content -Path $reportPath -Encoding UTF8

Write-Host "[Mason_Onyx_FeatureIndex_Report] Wrote $reportPath"
Write-Host ""
Write-Host "Summary:"
Write-Host ("  Features       : {0}" -f $result.summary.feature_count)
Write-Host ("  Menu sections  : {0}" -f $result.summary.menu_section_count)
Write-Host ("  Menu items     : {0}" -f $result.summary.menu_item_count)
Write-Host ("  Current tier   : {0}" -f $result.summary.current_tier)
Write-Host ("  Business name  : {0}" -f $result.summary.business_name)
Write-Host ("  Business type  : {0}" -f $result.summary.business_type)

if ($result.messages.Count -gt 0) {
    Write-Host ""
    Write-Host "Messages:"
    $result.messages | ForEach-Object { Write-Host "  - $_" }
}
