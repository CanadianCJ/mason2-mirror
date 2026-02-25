param(
    [string]$Base = "C:\Users\Chris\Desktop\Mason2"
)

$ErrorActionPreference = "Stop"

Write-Host "[SelfInspect] Starting Mason_Seed_SelfInspect.ps1..." -ForegroundColor Cyan
Write-Host "  Base: $Base"

$reports = Join-Path $Base "reports"
$config  = Join-Path $Base "config"

$healthPath      = Join-Path $reports "mason_health_aggregated.json"
$riskStatePath   = Join-Path $reports "risk_state.json"
$ueStatusPath    = Join-Path $reports "mason_ue_status.json"

$athenaUrl = "http://127.0.0.1:8000"   # Athena API base
$proposalUrl = "$athenaUrl/api/proposals"

function Load-JsonSafe {
    param(
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        Write-Host "  [WARN] Missing JSON: $Path" -ForegroundColor Yellow
        return $null
    }
    try {
        $raw = Get-Content $Path -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
        return $raw | ConvertFrom-Json
    } catch {
        Write-Host "  [WARN] Failed to parse JSON: $Path -> $($_.Exception.Message)" -ForegroundColor Yellow
        return $null
    }
}

# --- Load inputs ---

$healthAgg = Load-JsonSafe -Path $healthPath
$riskState = Load-JsonSafe -Path $riskStatePath
$ueStatus  = Load-JsonSafe -Path $ueStatusPath

if (-not $healthAgg -and -not $riskState) {
    Write-Host "  [WARN] No health or risk_state available. Nothing to inspect." -ForegroundColor Yellow
    return
}

# Helper: find allowed risk for an area from risk_state
function Get-AreaAllowedRisk {
    param(
        [string]$AreaName
    )
    if (-not $riskState -or -not $riskState.areas) { return 0 }
    foreach ($a in $riskState.areas) {
        if ($a.area -eq $AreaName) {
            return [int]($a.allowed_risk)
        }
    }
    return 0
}

# Helper: post a proposal
function New-Proposal {
    param(
        [string]$Area,
        [int]$RiskLevel,
        [string]$Title,
        [string]$Summary,
        [hashtable]$Details,
        [string[]]$Tags
    )

    Write-Host "  [Proposal] $Area (risk $RiskLevel): $Title" -ForegroundColor Green

    $body = @{
        area       = $Area
        risk_level = $RiskLevel
        title      = $Title
        summary    = $Summary
        details    = $Details
        source     = "mason-seed-selfinspect"
        tags       = $Tags
    }

    $json = $body | ConvertTo-Json -Depth 8

    try {
        $resp = Invoke-RestMethod -Method Post `
                                  -Uri $proposalUrl `
                                  -ContentType "application/json" `
                                  -Body $json `
                                  -TimeoutSec 60
        if ($resp.ok -ne $true) {
            Write-Host "    [WARN] Proposals API returned ok=false: $($resp.error)" -ForegroundColor Yellow
        } else {
            Write-Host "    [OK] Proposal created with id $($resp.proposal.id)" -ForegroundColor Green
        }
    } catch {
        Write-Host "    [ERR] Failed to call proposals API: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- 1) Inspect Onyx health ---

if ($healthAgg -and $healthAgg.onyx_health) {
    $oh = $healthAgg.onyx_health
    $opinion = $oh.healthOpinion
    $errors  = $oh.errorCount
    $total   = $oh.totalChecks
    $avgMs   = $oh.avgElapsedMs

    $onyxAllowed = Get-AreaAllowedRisk -AreaName "onyx"

    if ($onyxAllowed -ge 1 -and $opinion -ne "healthy" -and $total -gt 0) {
        $title = "Onyx health is $opinion ($errors errors out of $total checks)"
        $summary = "Onyx health summary reports healthOpinion=$opinion, errorCount=$errors, avgElapsedMs=$avgMs. Mason should investigate logs and propose fixes."

        $details = @{
            reason            = "health-check"
            metrics           = @{
                totalChecks  = $total
                errorCount   = $errors
                avgElapsedMs = $avgMs
                healthOpinion= $opinion
            }
            suggested_actions = @(
                "Review logs/onyx_health.log for repeated connection errors.",
                "Check if the local Onyx Flutter server is stable or needs restart logic.",
                "Propose specific low-risk fixes (e.g., retry strategy, better error reporting)."
            )
        }

        New-Proposal -Area "onyx" `
                     -RiskLevel 1 `
                     -Title $title `
                     -Summary $summary `
                     -Details $details `
                     -Tags @("onyx","health","selfinspect")
    }
} else {
    Write-Host "  [INFO] No onyx_health in mason_health_aggregated.json yet." -ForegroundColor DarkGray
}

# --- 2) Inspect Mason core risk area ---

$masonAllowed = Get-AreaAllowedRisk -AreaName "mason"
if ($masonAllowed -ge 1 -and $riskState -and $riskState.areas) {
    $masonArea = $riskState.areas | Where-Object { $_.area -eq "mason" }
    if ($masonArea) {
        $succ = [int]$masonArea.metrics.successful_tasks
        $fail = [int]$masonArea.metrics.failed_tasks
        $rb   = [int]$masonArea.metrics.rollbacks

        if ($fail -gt 0 -or $rb -gt 0) {
            $title = "Mason core has $fail failures and $rb rollbacks recorded"
            $summary = "Risk metrics show failures/rollbacks in Mason core tasks. Mason should review logs and propose self-heal or refactors."

            $details = @{
                reason  = "risk-metrics"
                metrics = @{
                    successful_tasks = $succ
                    failed_tasks     = $fail
                    rollbacks        = $rb
                }
                suggested_actions = @(
                    "Scan logs/selfheal for repeated failures.",
                    "Identify fragile scripts and propose more robust variants.",
                    "Consider adding more health checks around failing areas."
                )
            }

            New-Proposal -Area "mason" `
                         -RiskLevel 1 `
                         -Title $title `
                         -Summary $summary `
                         -Details $details `
                         -Tags @("mason","selfheal","risk","selfinspect")
        } else {
            Write-Host "  [INFO] Mason core risk metrics show no failures/rollbacks yet." -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "  [INFO] Risk state for 'mason' not available or allowed_risk < 1." -ForegroundColor DarkGray
}

# --- 3) Optional: Inspect PC health (placeholder) ---

$pcAllowed = Get-AreaAllowedRisk -AreaName "pc"
if ($pcAllowed -ge 1) {
    # You can extend this once pc_health_summary.json is richer.
    Write-Host "  [INFO] PC area allowed risk >= 1; future: add disk/cleanup proposals here." -ForegroundColor DarkGray
}

Write-Host "[SelfInspect] Done." -ForegroundColor Cyan
