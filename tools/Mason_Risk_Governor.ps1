param()

# -------------------------------
# Bootstrap Mason base + logging
# -------------------------------
$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$parentDir  = Split-Path -Path $scriptRoot -Parent

$baseLib    = Join-Path $parentDir "lib\Mason.Base.psm1"
$logLib     = Join-Path $parentDir "lib\Mason.Logging.psm1"

if (Test-Path $baseLib) {
    Import-Module $baseLib -Force
    $MasonBase = Get-MasonBase -FromPath $scriptRoot
    Set-Location $MasonBase
} else {
    # Fallback if library is missing
    $MasonBase = Join-Path $env:USERPROFILE "Desktop\Mason2"
    Set-Location $MasonBase
}

if (Test-Path $logLib) {
    Import-Module $logLib -Force
}

# Fallback logger if Out-MasonJsonl is not available
if (-not (Get-Command Out-MasonJsonl -ErrorAction SilentlyContinue)) {
    function Out-MasonJsonl {
        param(
            [string]$Kind,
            [string]$Event,
            [string]$Level,
            [hashtable]$Data
        )
        Write-Host "[$Level] $Kind/$Event :: $(($Data | ConvertTo-Json -Compress))"
    }
}

$policyPath    = Join-Path $MasonBase "config\risk_policy.json"
$reportsFolder = Join-Path $MasonBase "reports"
$summaryPath   = Join-Path $MasonBase "reports\mason_selfheal_summary.json"
$riskStatePath = Join-Path $MasonBase "reports\risk_state.json"

if (-not (Test-Path $reportsFolder)) {
    New-Item -ItemType Directory -Path $reportsFolder -Force | Out-Null
}

if (-not (Test-Path $policyPath)) {
    Out-MasonJsonl -Kind 'risk_governor' -Event 'missing_policy' -Level 'WARN' -Data @{
        path = $policyPath
    }
    return
}

$policyJson = Get-Content $policyPath -Raw | ConvertFrom-Json

$hasSummary = Test-Path $summaryPath
$summaryJson = $null
if ($hasSummary) {
    try {
        $summaryJson = Get-Content $summaryPath -Raw | ConvertFrom-Json
    }
    catch {
        Out-MasonJsonl -Kind 'risk_governor' -Event 'summary_parse_failed' -Level 'WARN' -Data @{
            path  = $summaryPath
            error = $_.Exception.Message
        }
    }
}

$areasState = @()

# Build per-area state using start_risk for now
$areaNames = $policyJson.areas.PSObject.Properties.Name
foreach ($areaName in $areaNames) {
    $areaPolicy = $policyJson.areas.$areaName

    $areaState = [PSCustomObject]@{
        area              = $areaName
        description       = $areaPolicy.description
        allowed_risk      = $areaPolicy.start_risk
        start_risk        = $areaPolicy.start_risk
        max_auto_risk     = $areaPolicy.max_auto_risk
        last_promotion    = $null
        metrics           = [PSCustomObject]@{
            successful_tasks   = 0
            failed_tasks       = 0
            rollbacks          = 0
            hours_health_green = 0
        }
        promotion_rules   = $areaPolicy.promotion_rules
        evidence          = @()
    }

    $areasState += $areaState
}

$riskState = [PSCustomObject]@{
    generatedAt = (Get-Date).ToString('o')
    masonBase   = $MasonBase
    policyPath  = $policyPath
    summaryPath = $summaryPath
    hasSummary  = [bool]$hasSummary
    areas       = $areasState
    global      = $policyJson.global
}

$json = $riskState | ConvertTo-Json -Depth 8
$json | Set-Content -Path $riskStatePath -Encoding UTF8

Out-MasonJsonl -Kind 'risk_governor' -Event 'updated' -Level 'INFO' -Data @{
    risk_state = $riskStatePath
}
Write-Host "Mason_Risk_Governor: updated $riskStatePath"
