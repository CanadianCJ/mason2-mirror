param()

$ErrorActionPreference = "Stop"

# Figure out Mason base folder from /tools  (Mason2\tools -> Mason2)
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$base      = Split-Path $scriptRoot -Parent

function Read-JsonOrNull {
    param([string]$Path)

    if (-not (Test-Path $Path)) { return $null }
    try {
        return Get-Content $Path -Raw | ConvertFrom-Json
    }
    catch {
        Write-Warning "Failed to read JSON from $Path : $_"
        return $null
    }
}

$healthPath      = Join-Path $base "reports\mason_health_aggregated.json"
$riskStatePath   = Join-Path $base "reports\risk_state.json"
$uePath          = Join-Path $base "config\universal_evolution.json"
$bizPolicyPath   = Join-Path $base "plans\docs\Connectra_Business_Policy_001.json"

$health    = Read-JsonOrNull $healthPath
$riskState = Read-JsonOrNull $riskStatePath
$ue        = Read-JsonOrNull $uePath
$bizPolicy = Read-JsonOrNull $bizPolicyPath

# Index risk_state by area for quick lookup
$riskIndex = @{}
if ($riskState -and $riskState.areas) {
    foreach ($a in $riskState.areas) {
        if ($a.area) { $riskIndex[$a.area] = $a }
    }
}

# Work out UE areas list (supports both old + new shapes)
$ueAreas = @()
if ($ue -and $ue.areas) {
    $ueAreas = $ue.areas
} elseif ($ue -and $ue.core -and $ue.core.areas) {
    $ueAreas = $ue.core.areas
}

$areaSummaries = @()

foreach ($ua in $ueAreas) {
    # Allow "area" or "name"
    $name = $ua.area
    if (-not $name) { $name = $ua.name }
    if (-not $name) { continue }

    $status      = if ($ua.status) { $ua.status } else { "planned" }
    $focusWeight = if ($ua.focus_weight) { $ua.focus_weight } else { 1 }

    $r = $null
    if ($riskIndex.ContainsKey($name)) { $r = $riskIndex[$name] }

    $allowedRisk = 0
    if ($r -and $r.allowed_risk -ne $null) {
        $allowedRisk = [int]$r.allowed_risk
    } elseif ($r -and $r.start_risk -ne $null) {
        $allowedRisk = [int]$r.start_risk
    }

    # Try to read area health if present (optional)
    $healthStatus = $null
    if ($health -and $health.area_status -and $health.area_status.$name) {
        $healthStatus = $health.area_status.$name.status
    }

    $areaSummaries += [ordered]@{
        area          = $name
        ue_status     = $status
        focus_weight  = $focusWeight
        allowed_risk  = $allowedRisk
        health        = $healthStatus
    }
}

$summary = [ordered]@{
    generatedAt         = (Get-Date).ToString("s")
    masonBase           = $base
    healthPath          = $healthPath
    riskStatePath       = $riskStatePath
    uePath              = $uePath
    businessPolicyPath  = $bizPolicyPath
    businessPolicy      = $bizPolicy
    areas               = $areaSummaries
}

$outPath = Join-Path $base "reports\mason_ue_status.json"

# Make sure reports folder exists
$outDir = Split-Path $outPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$summary | ConvertTo-Json -Depth 8 | Set-Content $outPath -Encoding utf8

Write-Host ""
Write-Host "Mason UE snapshot written to:" -ForegroundColor Cyan
Write-Host "  $outPath" -ForegroundColor Cyan
Write-Host ""

foreach ($a in $areaSummaries) {
    $healthText = if ($a.health) { $a.health } else { "-" }
    $line = "{0,-8} | UE={1,-7} | Risk={2} | Health={3}" -f `
        $a.area, $a.ue_status, $a.allowed_risk, $healthText
    Write-Host "  $line"
}

Write-Host ""
Write-Host "Reminder: risk 0 = observe/plan only, no changes." -ForegroundColor DarkGray
