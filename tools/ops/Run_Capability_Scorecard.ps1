param(
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Resolve-RepoRoot {
    param([string]$ExplicitRoot)

    if ($ExplicitRoot -and (Test-Path -LiteralPath $ExplicitRoot)) {
        return (Resolve-Path -LiteralPath $ExplicitRoot).Path
    }

    return (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
}

function Normalize-Text {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return ""
    }

    return ([string]$Value).Trim()
}

function Normalize-ShortText {
    param(
        [AllowNull()][object]$Value,
        [int]$MaxLength = 240
    )

    $text = Normalize-Text $Value
    if (-not $text) {
        return ""
    }
    if ($text.Length -le $MaxLength) {
        return $text
    }
    return ($text.Substring(0, [Math]::Max(0, $MaxLength - 3)).TrimEnd() + "...")
}

function Normalize-StringList {
    param(
        [AllowNull()][object]$Value,
        [int]$MaxItems = 32,
        [int]$MaxLength = 220
    )

    $items = @()
    foreach ($item in @($Value)) {
        $text = Normalize-ShortText -Value $item -MaxLength $MaxLength
        if (-not $text) {
            continue
        }
        if ($items -notcontains $text) {
            $items += $text
        }
        if ($items.Count -ge $MaxItems) {
            break
        }
    }
    return @($items)
}

function Get-PropValue {
    param(
        [AllowNull()][object]$Object,
        [string]$Name,
        $Default = $null
    )

    if ($null -eq $Object) {
        return $Default
    }

    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) {
            return $Object[$Name]
        }
        return $Default
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($null -ne $property) {
        return $property.Value
    }

    return $Default
}

function Read-JsonSafe {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if (-not (Normalize-Text $raw)) {
        return $null
    }

    try {
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $null
    }
}

function Ensure-Parent {
    param([string]$Path)

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Write-JsonFile {
    param(
        [string]$Path,
        [AllowNull()][object]$Data
    )

    Ensure-Parent -Path $Path
    $json = $Data | ConvertTo-Json -Depth 100
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Get-ValidatorSection {
    param(
        [AllowNull()][object]$SystemValidation,
        [string]$SectionName
    )

    foreach ($section in @((Get-PropValue -Object $SystemValidation -Name "sections" -Default @()))) {
        if ((Normalize-Text (Get-PropValue -Object $section -Name "section_name" -Default "")) -eq $SectionName) {
            return $section
        }
    }
    return $null
}

function Get-MaturityTier {
    param([int]$Score)

    if ($Score -le 0) { return "tier_0_unavailable" }
    if ($Score -lt 40) { return "tier_1_fragile" }
    if ($Score -lt 60) { return "tier_2_guarded" }
    if ($Score -lt 75) { return "tier_3_stable" }
    if ($Score -lt 90) { return "tier_4_trusted" }
    return "tier_5_operator_grade"
}

function Get-BudgetTierRank {
    param([string]$Tier)

    switch ((Normalize-Text $Tier).ToLowerInvariant()) {
        "frozen" { return 0 }
        "minimal" { return 1 }
        "guarded" { return 2 }
        "moderate" { return 3 }
        "expanded" { return 4 }
        default { return 0 }
    }
}

function Get-BudgetTierFromRank {
    param([int]$Rank)

    switch ($Rank) {
        4 { return "expanded" }
        3 { return "moderate" }
        2 { return "guarded" }
        1 { return "minimal" }
        default { return "frozen" }
    }
}

function Get-DefaultBudgetTierForPosture {
    param([string]$PromotionPosture)

    switch ((Normalize-Text $PromotionPosture).ToLowerInvariant()) {
        "guarded_expandable" { return "expanded" }
        "low_risk_allowed" { return "moderate" }
        "canary_only" { return "guarded" }
        "review_only" { return "minimal" }
        default { return "frozen" }
    }
}

function New-DomainRecord {
    param(
        [string]$DomainId,
        [bool]$Available,
        [string]$Status,
        [int]$MaturityScore,
        [string]$PromotionPosture,
        [string]$Confidence,
        [string[]]$EvidenceSources,
        [string]$Summary,
        [string]$RecommendedNextAction,
        [AllowNull()][object]$Details = $null
    )

    $resolvedStatus = (Normalize-Text $Status).ToUpperInvariant()
    if (-not $Available) {
        $resolvedStatus = "MISSING"
        $MaturityScore = 0
        $PromotionPosture = "blocked"
    }

    return [pscustomobject]@{
        domain_id = Normalize-ShortText -Value $DomainId -MaxLength 64
        available = $Available
        status = $resolvedStatus
        maturity_score = [int]$MaturityScore
        maturity_tier = Get-MaturityTier -Score $MaturityScore
        change_budget_tier = Get-DefaultBudgetTierForPosture -PromotionPosture $PromotionPosture
        promotion_posture = Normalize-ShortText -Value $PromotionPosture -MaxLength 32
        confidence = Normalize-ShortText -Value $Confidence -MaxLength 16
        evidence_sources = Normalize-StringList -Value $EvidenceSources -MaxItems 16 -MaxLength 260
        summary = Normalize-ShortText -Value $Summary -MaxLength 260
        recommended_next_action = Normalize-ShortText -Value $RecommendedNextAction -MaxLength 240
        details = $Details
    }
}

$repoRoot = Resolve-RepoRoot -ExplicitRoot $RepoRoot
$reportsDir = Join-Path $repoRoot "reports"
$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"
$configDir = Join-Path $repoRoot "config"
$onyxStateDir = Join-Path $repoRoot "state\onyx"

$systemValidationPath = Join-Path $reportsDir "system_validation_last.json"
$systemTruthPath = Join-Path $reportsDir "system_truth_spine_last.json"
$regressionGuardPath = Join-Path $reportsDir "regression_guard_last.json"
$keepAlivePath = Join-Path $reportsDir "keepalive_last.json"
$selfHealPath = Join-Path $reportsDir "self_heal_last.json"
$selfImprovementPath = Join-Path $reportsDir "self_improvement_governor_last.json"
$hostHealthPath = Join-Path $reportsDir "host_health_last.json"
$runtimePosturePath = Join-Path $reportsDir "runtime_posture_last.json"
$environmentProfilePath = Join-Path $reportsDir "environment_profile_last.json"
$environmentDriftPath = Join-Path $reportsDir "environment_drift_last.json"
$securityPosturePath = Join-Path $reportsDir "security_posture.json"
$tenantSafetyPath = Join-Path $reportsDir "tenant_safety_report.json"
$billingSummaryPath = Join-Path $reportsDir "billing_summary.json"
$mirrorUpdatePath = Join-Path $reportsDir "mirror_update_last.json"
$liveDocsSummaryPath = Join-Path $reportsDir "live_docs_summary.json"
$brandExposurePath = Join-Path $reportsDir "brand_exposure_isolation_last.json"
$toolRegistryPath = Join-Path $configDir "tool_registry.json"
$tenantWorkspacePath = Join-Path $onyxStateDir "tenant_workspace.json"

$capabilityScorecardPath = Join-Path $reportsDir "capability_scorecard_last.json"
$changeBudgetPath = Join-Path $reportsDir "change_budget_last.json"
$promotionThrottlePath = Join-Path $reportsDir "promotion_throttle_last.json"
$capabilityRegistryPath = Join-Path $stateKnowledgeDir "capability_registry.json"
$capabilityPolicyPath = Join-Path $configDir "capability_budget_policy.json"

$nowUtc = (Get-Date).ToUniversalTime().ToString("o")
$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Capability_Scorecard.ps1"

$policy = [ordered]@{
    version = 1
    policy_name = "capability_scorecard_change_budget"
    score_domains = @(
        "stack_runtime","service_health","truth_integrity","keepalive_self_heal","regression_control",
        "self_improvement_governance","security_tenant_safety","billing_money_safety","brand_exposure_control",
        "environment_adaptation","docs_operability","athena_operator_surface","tool_registry_execution",
        "tenant_workflows","release_governance"
    )
    maturity_tiers = [ordered]@{
        tier_0_unavailable = @{ min_score = 0; max_score = 0 }
        tier_1_fragile = @{ min_score = 1; max_score = 39 }
        tier_2_guarded = @{ min_score = 40; max_score = 59 }
        tier_3_stable = @{ min_score = 60; max_score = 74 }
        tier_4_trusted = @{ min_score = 75; max_score = 89 }
        tier_5_operator_grade = @{ min_score = 90; max_score = 100 }
    }
    scoring_inputs = @(
        "whole-system validator",
        "system truth spine",
        "regression guard",
        "keepalive/self-heal",
        "host guardian",
        "environment adaptation",
        "self-improvement governor",
        "security posture and tenant safety",
        "billing posture",
        "brand exposure isolation",
        "live docs",
        "tool registry",
        "tenant workspace"
    )
    weight_model = [ordered]@{
        validator = 0.35
        direct_domain_artifact = 0.35
        governance_posture = 0.20
        freshness_and_operability = 0.10
    }
    change_budget_tiers = [ordered]@{
        frozen = @{ allowed_change_volume = 0; allowed_high_risk_volume = 0; allowed_low_risk_volume = 0 }
        minimal = @{ allowed_change_volume = 1; allowed_high_risk_volume = 0; allowed_low_risk_volume = 1 }
        guarded = @{ allowed_change_volume = 3; allowed_high_risk_volume = 0; allowed_low_risk_volume = 3 }
        moderate = @{ allowed_change_volume = 5; allowed_high_risk_volume = 1; allowed_low_risk_volume = 4 }
        expanded = @{ allowed_change_volume = 8; allowed_high_risk_volume = 2; allowed_low_risk_volume = 6 }
    }
    promotion_throttle_rules = [ordered]@{
        blocked_when = @(
            "regression promotion is blocked",
            "baseline is missing or untrusted for promotion",
            "critical safety or brand regression appears"
        )
        review_only_when = @(
            "security or billing posture remains warning-grade",
            "keepalive or self-improvement remains noisy"
        )
        canary_only_when = @(
            "domain is stable but overall platform remains WARN"
        )
    }
    downgrade_rules = @(
        "Downgrade domain maturity when current truth gets worse than the prior safe posture.",
        "Downgrade change budget when validator, regression guard, keepalive, security, or billing posture worsens."
    )
    stale_data_handling = [ordered]@{
        warn_if_artifact_missing = $true
        do_not_fabricate_green = $true
    }
    missing_domain_handling = [ordered]@{
        status = "MISSING"
        maturity_tier = "tier_0_unavailable"
        change_budget_tier = "frozen"
        promotion_posture = "blocked"
    }
    gating_integration_rules = @(
        "Regression guard can block promotion even when low-risk change work remains allowed.",
        "Security, tenant safety, and billing safety can freeze or minimize domain-local budgets.",
        "Overall change budget clamps domain-local budgets to the current platform-wide posture."
    )
}

Write-JsonFile -Path $capabilityPolicyPath -Data $policy
