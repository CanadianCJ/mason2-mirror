[CmdletBinding()]
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
        [int]$MaxItems = 24,
        [int]$MaxLength = 240
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
    return ,@($items)
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

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if (-not (Normalize-Text $raw)) {
            return $null
        }
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

function Get-AgeHours {
    param([AllowNull()][object]$Timestamp)

    $text = Normalize-Text $Timestamp
    if (-not $text) {
        return [double]::PositiveInfinity
    }

    try {
        $parsed = [datetimeoffset]::Parse($text)
        return [Math]::Round(((Get-Date).ToUniversalTime() - $parsed.UtcDateTime).TotalHours, 2)
    }
    catch {
        return [double]::PositiveInfinity
    }
}

function Add-UniqueReason {
    param(
        [System.Collections.Generic.List[string]]$List,
        [AllowNull()][object]$Value
    )

    $text = Normalize-ShortText -Value $Value -MaxLength 260
    if ($text -and -not $List.Contains($text)) {
        [void]$List.Add($text)
    }
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

function Get-SafeIdentifier {
    param([string]$Value)

    $text = Normalize-Text $Value
    if (-not $text) {
        return "local"
    }

    $text = [regex]::Replace($text.ToLowerInvariant(), "[^a-z0-9]+", "_").Trim("_")
    if (-not $text) {
        return "local"
    }
    return $text
}

function Get-ShortHash {
    param(
        [string]$Value,
        [int]$Length = 10
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes((Normalize-Text $Value))
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }

    $hex = -join ($hashBytes | ForEach-Object { $_.ToString("x2") })
    return $hex.Substring(0, [Math]::Min($Length, $hex.Length))
}

$repoRoot = Resolve-RepoRoot -ExplicitRoot $RepoRoot
$reportsDir = Join-Path $repoRoot "reports"
$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"
$configDir = Join-Path $repoRoot "config"

$systemTruthPath = Join-Path $reportsDir "system_truth_spine_last.json"
$systemMetricsPath = Join-Path $reportsDir "system_metrics_spine_last.json"
$systemValidationPath = Join-Path $reportsDir "system_validation_last.json"
$regressionGuardPath = Join-Path $reportsDir "regression_guard_last.json"
$rollbackPlanPath = Join-Path $reportsDir "rollback_plan_last.json"
$promotionGatePath = Join-Path $reportsDir "promotion_gate_last.json"
$capabilityScorecardPath = Join-Path $reportsDir "capability_scorecard_last.json"
$changeBudgetPath = Join-Path $reportsDir "change_budget_last.json"
$promotionThrottlePath = Join-Path $reportsDir "promotion_throttle_last.json"
$keepAlivePath = Join-Path $reportsDir "keepalive_last.json"
$securityPosturePath = Join-Path $reportsDir "security_posture.json"
$tenantSafetyPath = Join-Path $reportsDir "tenant_safety_report.json"
$billingSummaryPath = Join-Path $reportsDir "billing_summary.json"
$brandExposurePath = Join-Path $reportsDir "brand_exposure_isolation_last.json"
$playbookSupportPath = Join-Path $reportsDir "support_brain_last.json"
$businessOutcomesPath = Join-Path $reportsDir "business_outcomes_last.json"
$wedgePackFrameworkPath = Join-Path $reportsDir "wedge_pack_framework_last.json"
$liveDocsSummaryPath = Join-Path $reportsDir "live_docs_summary.json"
$mirrorUpdatePath = Join-Path $reportsDir "mirror_update_last.json"

$releaseManagementPath = Join-Path $reportsDir "release_management_last.json"
$releaseCandidatePath = Join-Path $reportsDir "release_candidate_last.json"
$releaseNotesPath = Join-Path $reportsDir "release_notes_last.json"
$releaseRolloutPath = Join-Path $reportsDir "release_rollout_last.json"
$releaseRegistryPath = Join-Path $stateKnowledgeDir "release_registry.json"
$releaseManagementPolicyPath = Join-Path $configDir "release_management_policy.json"

$systemTruth = Read-JsonSafe -Path $systemTruthPath
$systemMetrics = Read-JsonSafe -Path $systemMetricsPath
$systemValidation = Read-JsonSafe -Path $systemValidationPath
$regressionGuard = Read-JsonSafe -Path $regressionGuardPath
$rollbackPlan = Read-JsonSafe -Path $rollbackPlanPath
$promotionGate = Read-JsonSafe -Path $promotionGatePath
$capabilityScorecard = Read-JsonSafe -Path $capabilityScorecardPath
$changeBudget = Read-JsonSafe -Path $changeBudgetPath
$promotionThrottle = Read-JsonSafe -Path $promotionThrottlePath
$keepAlive = Read-JsonSafe -Path $keepAlivePath
$securityPosture = Read-JsonSafe -Path $securityPosturePath
$tenantSafety = Read-JsonSafe -Path $tenantSafetyPath
$billingSummary = Read-JsonSafe -Path $billingSummaryPath
$brandExposure = Read-JsonSafe -Path $brandExposurePath
$playbookSupport = Read-JsonSafe -Path $playbookSupportPath
$businessOutcomes = Read-JsonSafe -Path $businessOutcomesPath
$wedgePackFramework = Read-JsonSafe -Path $wedgePackFrameworkPath
$liveDocsSummary = Read-JsonSafe -Path $liveDocsSummaryPath
$mirrorUpdate = Read-JsonSafe -Path $mirrorUpdatePath

$nowUtc = (Get-Date).ToUniversalTime().ToString("o")
$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Autonomous_Release_Management.ps1"

$policy = [ordered]@{
    version = 1
    policy_name = "autonomous_release_management"
    release_stages = @("draft", "candidate", "blocked", "canary_only", "pilot_ready", "customer_ready", "rollback_recommended")
    canary_group_rules = [ordered]@{
        internal_operator_only = "Can receive internal canary exposure when core loopback health is stable and a basic rollback path is known."
        founder_pilot = "Requires regression gate clearance, trusted baseline, rollback readiness, and non-frozen change posture."
        limited_customer_safe = "Requires pilot readiness plus clean brand exposure, non-stub billing posture, and stronger business outcome confidence."
        broader_rollout_blocked = "Stays active whenever the release is not customer-ready."
    }
    promotion_prerequisites = @(
        "whole-system validator has no failures",
        "regression guard allows promotion",
        "trusted baseline exists",
        "rollback path is known and safe enough",
        "release-critical services are stable",
        "change budget and promotion throttle allow broader rollout"
    )
    rollback_prerequisites = @(
        "rollback plan artifact exists",
        "safe rollback steps are recorded",
        "baseline reference is trusted enough for broader rollout"
    )
    blocking_conditions = @(
        "validator failures",
        "regression guard blocks promotion",
        "trusted baseline missing",
        "rollback readiness is weak",
        "brand leakage in public/customer-safe surfaces",
        "release-critical services are unstable"
    )
    warning_only_conditions = @(
        "validator overall WARN without failures",
        "security or tenant safety watch posture",
        "billing remains in stub mode",
        "business outcomes remain sparse or low-confidence",
        "playbook support still reports recurring issues"
    )
    release_note_generation_rules = @(
        "Release notes must be built from current local artifacts and payload evidence.",
        "Do not claim customer readiness or general availability unless the gates actually allow it.",
        "Prefer operationally useful summaries over marketing language."
    )
    domain_dependency_rules = @(
        "system truth, validator, regression, and rollback are release-critical inputs",
        "capability/change budget is advisory when missing and gating when present",
        "security, billing, brand exposure, keepalive, and business outcomes influence release scope"
    )
    pilot_customer_internal_visibility_rules = [ordered]@{
        internal_canary = "owner/operator only"
        founder_pilot = "founder-controlled pilot only"
        limited_customer_safe = "customer-safe only with governed wording and clean exposure posture"
    }
    stale_evidence_handling = [ordered]@{
        validator_max_age_hours = 24
        regression_max_age_hours = 24
        system_truth_max_age_hours = 24
        action_if_stale = "downgrade to blocked or canary-only depending on missing evidence severity"
    }
    release_freeze_conditions = @(
        "critical regression appears",
        "security or tenant safety materially degrades",
        "brand leakage appears",
        "validator fails",
        "rollback path becomes unknown or unsafe"
    )
}

$validatorStatus = Normalize-Text (Get-PropValue -Object $systemValidation -Name "overall_status" -Default "MISSING")
$validatorFailCount = [int](Get-PropValue -Object $systemValidation -Name "failed_count" -Default 0)
$validatorWarnCount = [int](Get-PropValue -Object $systemValidation -Name "warn_count" -Default 0)
$baselineTag = Normalize-Text (Get-PropValue -Object $systemValidation -Name "baseline_tag" -Default (Get-PropValue -Object $systemTruth -Name "baseline_tag" -Default "CoreWithAthenaOnyx"))
$stackBaseSection = Get-ValidatorSection -SystemValidation $systemValidation -SectionName "stack/base"
$stackBaseStatus = Normalize-Text (Get-PropValue -Object $stackBaseSection -Name "status" -Default "MISSING")

$regressionStatus = Normalize-Text (Get-PropValue -Object $regressionGuard -Name "overall_status" -Default "MISSING")
$regressionPromotionAllowed = [bool](Get-PropValue -Object $regressionGuard -Name "promotion_allowed" -Default $false)
$regressionCount = [int](Get-PropValue -Object $regressionGuard -Name "regression_count" -Default 0)
$blockingRegressionCount = [int](Get-PropValue -Object $regressionGuard -Name "blocking_regression_count" -Default 0)
$warningRegressionCount = [int](Get-PropValue -Object $regressionGuard -Name "warning_regression_count" -Default 0)
$baselineAvailable = [bool](Get-PropValue -Object $regressionGuard -Name "baseline_available" -Default $false)
$baselineTrusted = [bool](Get-PropValue -Object $regressionGuard -Name "baseline_trusted" -Default $false)
$comparisonMode = Normalize-Text (Get-PropValue -Object $regressionGuard -Name "comparison_mode" -Default "")

$rollbackRecommended = [bool](Get-PropValue -Object $rollbackPlan -Name "rollback_recommended" -Default (Get-PropValue -Object $regressionGuard -Name "rollback_recommended" -Default $false))
$rollbackBlockedReasons = Normalize-StringList -Value (Get-PropValue -Object $rollbackPlan -Name "blocked_rollback_reasons" -Default @())
$rollbackSteps = @((Get-PropValue -Object $rollbackPlan -Name "safe_rollback_steps" -Default @()))
$rollbackPathKnown = ($rollbackSteps.Count -gt 0)
$rollbackReady = ($rollbackPathKnown -and (-not (@($rollbackBlockedReasons) -contains "trusted_baseline_missing")) -and (-not (@($rollbackBlockedReasons) -contains "rollback_path_missing")))

$capabilityAvailable = ($null -ne $capabilityScorecard -and $null -ne $changeBudget -and $null -ne $promotionThrottle)
$capabilityStatus = Normalize-Text (Get-PropValue -Object $capabilityScorecard -Name "overall_status" -Default "MISSING")
$overallChangeBudgetTier = Normalize-Text (Get-PropValue -Object $changeBudget -Name "overall_change_budget_tier" -Default "")
$promotionThrottleLevel = Normalize-Text (Get-PropValue -Object $promotionThrottle -Name "promotion_throttle_level" -Default "")
$throttledDomains = Normalize-StringList -Value (Get-PropValue -Object $changeBudget -Name "throttled_domains" -Default @())

$keepAliveStatus = Normalize-Text (Get-PropValue -Object $keepAlive -Name "overall_status" -Default "MISSING")
$keepAliveEscalations = [int](Get-PropValue -Object $keepAlive -Name "escalated_issue_count" -Default 0)
$securityStatus = Normalize-Text (Get-PropValue -Object $securityPosture -Name "overall_status" -Default (Get-PropValue -Object $securityPosture -Name "status" -Default "MISSING"))
$tenantSafetyStatus = Normalize-Text (Get-PropValue -Object $tenantSafety -Name "status" -Default "MISSING")
$tenantSafetyIssues = [int](Get-PropValue -Object $tenantSafety -Name "issues_total" -Default 0)
$billingProvider = Get-PropValue -Object $billingSummary -Name "provider" -Default $null
$billingMode = Normalize-Text (Get-PropValue -Object $billingProvider -Name "mode" -Default (Get-PropValue -Object $billingSummary -Name "provider_mode" -Default ""))
$billingTenant = Get-PropValue -Object $billingSummary -Name "tenant" -Default $null
$billingTenantStatus = Normalize-Text (Get-PropValue -Object $billingTenant -Name "status" -Default "")
$brandStatus = Normalize-Text (Get-PropValue -Object $brandExposure -Name "overall_status" -Default "MISSING")
$brandLeakCount = [int](Get-PropValue -Object $brandExposure -Name "public_leak_count" -Default 0)
$playbookStatus = Normalize-Text (Get-PropValue -Object $playbookSupport -Name "overall_status" -Default "MISSING")
$recurringIssueCount = [int](Get-PropValue -Object $playbookSupport -Name "recurring_issue_count" -Default 0)
$businessOutcomesStatus = Normalize-Text (Get-PropValue -Object $businessOutcomes -Name "overall_status" -Default "MISSING")
$businessOutcomeTenantCount = [int](Get-PropValue -Object $businessOutcomes -Name "tenant_count" -Default 0)
$businessOutcomeLowConfidenceDomains = [int](Get-PropValue -Object $businessOutcomes -Name "low_confidence_domain_count" -Default 0)
$wedgeStatus = Normalize-Text (Get-PropValue -Object $wedgePackFramework -Name "overall_status" -Default "MISSING")
$liveDocsStatus = Normalize-Text (Get-PropValue -Object $liveDocsSummary -Name "summary_status" -Default "MISSING")
$mirrorOk = [bool](Get-PropValue -Object $mirrorUpdate -Name "ok" -Default $false)
$mirrorPhase = Normalize-Text (Get-PropValue -Object $mirrorUpdate -Name "phase" -Default "")
$systemTruthStatus = Normalize-Text (Get-PropValue -Object $systemTruth -Name "overall_status" -Default "MISSING")
$warningDomainCount = [int](Get-PropValue -Object $systemMetrics -Name "warning_domain_count" -Default 0)

$blockingReasons = New-Object 'System.Collections.Generic.List[string]'
$warningReasons = New-Object 'System.Collections.Generic.List[string]'
$internalCanaryBlockers = New-Object 'System.Collections.Generic.List[string]'

if (-not $systemValidation) {
    Add-UniqueReason -List $blockingReasons -Value "Validator evidence is missing, so release readiness cannot be trusted."
    Add-UniqueReason -List $internalCanaryBlockers -Value "Validator evidence is missing."
}
elseif ($validatorFailCount -gt 0 -or $validatorStatus.ToUpperInvariant() -eq "FAIL") {
    Add-UniqueReason -List $blockingReasons -Value "Validator still reports failures, so release promotion is blocked."
    Add-UniqueReason -List $internalCanaryBlockers -Value "Validator still reports failures."
}
elseif ($stackBaseStatus.ToUpperInvariant() -ne "PASS") {
    Add-UniqueReason -List $blockingReasons -Value "Stack/base validation is not PASS, so release rollout stays blocked."
    Add-UniqueReason -List $internalCanaryBlockers -Value "Stack/base validation is not PASS."
}
elseif ($validatorStatus.ToUpperInvariant() -eq "WARN") {
    Add-UniqueReason -List $warningReasons -Value "Validator remains WARN, so rollout should stay conservative."
}

if ((Get-AgeHours -Timestamp (Get-PropValue -Object $systemValidation -Name "timestamp_utc" -Default "")) -gt 24) {
    Add-UniqueReason -List $blockingReasons -Value "Validator evidence is stale, so promotion cannot rely on it."
}

if (-not $regressionGuard) {
    Add-UniqueReason -List $blockingReasons -Value "Regression guard evidence is missing, so broader promotion cannot be trusted."
}
else {
    if (-not $regressionPromotionAllowed) {
        Add-UniqueReason -List $blockingReasons -Value "Promotion remains blocked because the regression guard does not currently allow promotion."
    }
    if (-not $baselineAvailable) {
        Add-UniqueReason -List $blockingReasons -Value "No eligible comparison baseline exists yet, so promotion remains blocked."
    }
    elseif (-not $baselineTrusted) {
        Add-UniqueReason -List $blockingReasons -Value "Only a seeded baseline exists; a trusted release baseline has not been accepted yet."
    }
    if ($blockingRegressionCount -gt 0) {
        Add-UniqueReason -List $blockingReasons -Value "Blocking regressions are still present in the regression guard."
    }
    elseif ($warningRegressionCount -gt 0) {
        Add-UniqueReason -List $warningReasons -Value "Warning-level regressions remain open and should be watched before broader rollout."
    }
}

if ((Get-AgeHours -Timestamp (Get-PropValue -Object $regressionGuard -Name "timestamp_utc" -Default "")) -gt 24) {
    Add-UniqueReason -List $warningReasons -Value "Regression evidence is stale, so rollout should stay conservative."
}

if ($rollbackRecommended) {
    Add-UniqueReason -List $blockingReasons -Value "Rollback is currently recommended, so broader rollout is blocked."
}
if (-not $rollbackPathKnown) {
    Add-UniqueReason -List $blockingReasons -Value "No rollback path is recorded, so release promotion stays blocked."
    Add-UniqueReason -List $internalCanaryBlockers -Value "No rollback path is recorded."
}
elseif (-not $rollbackReady) {
    Add-UniqueReason -List $blockingReasons -Value "Rollback readiness is not strong enough for broader rollout because the rollback plan still depends on missing or untrusted baseline evidence."
}

if ($capabilityAvailable) {
    if ($promotionThrottleLevel.ToLowerInvariant() -eq "blocked" -or $overallChangeBudgetTier.ToLowerInvariant() -eq "frozen") {
        Add-UniqueReason -List $blockingReasons -Value "Change budget or promotion throttle is frozen, so broader rollout is blocked."
    }
    elseif ($promotionThrottleLevel -or $overallChangeBudgetTier) {
        Add-UniqueReason -List $warningReasons -Value ("Change budget remains {0} with throttle {1}, so rollout stays conservative." -f $(if ($overallChangeBudgetTier) { $overallChangeBudgetTier } else { "unknown" }), $(if ($promotionThrottleLevel) { $promotionThrottleLevel } else { "unknown" }))
    }
}
else {
    Add-UniqueReason -List $warningReasons -Value "Capability scorecard and change-budget artifacts are missing, so release pace stays conservative by default."
}

if ($keepAliveStatus.ToUpperInvariant() -eq "FAIL") {
    Add-UniqueReason -List $blockingReasons -Value "KeepAlive/self-heal is failing, so rollout is blocked."
    Add-UniqueReason -List $internalCanaryBlockers -Value "KeepAlive/self-heal is failing."
}
elseif ($keepAliveStatus.ToUpperInvariant() -eq "WARN" -or $keepAliveEscalations -gt 0) {
    Add-UniqueReason -List $warningReasons -Value "KeepAlive/self-heal still has escalated or policy-blocked issues, so rollout should stay conservative."
}

if ($securityStatus.ToUpperInvariant() -eq "FAIL" -or $tenantSafetyStatus.ToUpperInvariant() -eq "FAIL") {
    Add-UniqueReason -List $blockingReasons -Value "Security or tenant-safety posture is degraded, so broader rollout is blocked."
    Add-UniqueReason -List $internalCanaryBlockers -Value "Security or tenant-safety posture is degraded."
}
elseif ($securityStatus.ToUpperInvariant() -eq "WARN" -or $tenantSafetyStatus.ToUpperInvariant() -eq "WARN" -or $tenantSafetyIssues -gt 0) {
    Add-UniqueReason -List $warningReasons -Value "Security or tenant-safety posture remains in watch state and needs review before broader rollout."
}

if ($brandLeakCount -gt 0 -or $brandStatus.ToUpperInvariant() -eq "FAIL") {
    Add-UniqueReason -List $blockingReasons -Value "Public brand leakage is present, so customer-facing rollout is blocked."
}
elseif ($brandStatus.ToUpperInvariant() -eq "WARN") {
    Add-UniqueReason -List $warningReasons -Value "Brand exposure posture is not fully clean yet."
}

if ($systemTruthStatus.ToUpperInvariant() -eq "FAIL" -or -not $systemTruth) {
    Add-UniqueReason -List $blockingReasons -Value "System truth is unavailable or failing, so release readiness cannot be trusted."
}
elseif ($systemTruthStatus.ToUpperInvariant() -eq "WARN" -or $warningDomainCount -gt 0) {
    Add-UniqueReason -List $warningReasons -Value "System truth still shows unresolved warning domains."
}

if ($billingMode.ToLowerInvariant() -eq "stub") {
    Add-UniqueReason -List $warningReasons -Value "Billing remains in stub mode, so customer-ready rollout must not be claimed."
}
elseif ($billingTenantStatus -and $billingTenantStatus.ToLowerInvariant() -ne "active") {
    Add-UniqueReason -List $warningReasons -Value "Billing tenant status is not fully active, so rollout claims should stay conservative."
}

if ($businessOutcomesStatus.ToUpperInvariant() -eq "WARN" -or $businessOutcomeLowConfidenceDomains -gt 0 -or $businessOutcomeTenantCount -lt 2) {
    Add-UniqueReason -List $warningReasons -Value "Business outcome evidence is still pilot-sized or low-confidence, so customer readiness is not proven."
}

if ($playbookStatus.ToUpperInvariant() -eq "WARN" -or $recurringIssueCount -gt 0) {
    Add-UniqueReason -List $warningReasons -Value "Recurring operational issues are still active, even though the support brain is explaining them consistently."
}

if ($liveDocsStatus.ToUpperInvariant() -eq "WARN") {
    Add-UniqueReason -List $warningReasons -Value "Live docs still report warnings for some components."
}

if (-not $mirrorOk -or $mirrorPhase -ne "done") {
    Add-UniqueReason -List $warningReasons -Value "Mirror/checkpoint state is not fully clean, so release confidence is reduced."
}

if ($wedgeStatus.ToUpperInvariant() -eq "WARN") {
    Add-UniqueReason -List $warningReasons -Value "Wedge-pack framework is not fully clean yet."
}

$internalCanaryAllowed = ($internalCanaryBlockers.Count -eq 0)
$pilotReady = (
    $internalCanaryAllowed -and
    $regressionPromotionAllowed -and
    $baselineTrusted -and
    $rollbackReady -and
    $capabilityAvailable -and
    ($overallChangeBudgetTier.ToLowerInvariant() -notin @("frozen", "minimal")) -and
    ($promotionThrottleLevel.ToLowerInvariant() -notin @("blocked", "review_only"))
)
$customerReady = (
    $pilotReady -and
    $securityStatus.ToUpperInvariant() -eq "PASS" -and
    $tenantSafetyIssues -eq 0 -and
    $brandLeakCount -eq 0 -and
    $billingMode.ToLowerInvariant() -ne "stub" -and
    $businessOutcomesStatus.ToUpperInvariant() -eq "PASS" -and
    $businessOutcomeLowConfidenceDomains -le 1
)

$promotionAllowed = $pilotReady
$canaryAllowed = $internalCanaryAllowed

$releaseStage = "blocked"
if ($rollbackRecommended) {
    $releaseStage = "rollback_recommended"
}
elseif ($customerReady) {
    $releaseStage = "customer_ready"
}
elseif ($pilotReady) {
    $releaseStage = "pilot_ready"
}
elseif ($canaryAllowed) {
    $releaseStage = "canary_only"
}
elseif ($systemValidation -or $systemTruth -or $regressionGuard) {
    $releaseStage = "blocked"
}
else {
    $releaseStage = "draft"
}

$rolloutMode = if ($customerReady) {
    "limited_customer_safe"
}
elseif ($pilotReady) {
    "founder_pilot"
}
elseif ($canaryAllowed) {
    "internal_operator_canary_only"
}
else {
    "blocked"
}

$releaseReadinessClassification = if ($customerReady) {
    "customer_ready"
}
elseif ($pilotReady) {
    "pilot_candidate"
}
elseif ($canaryAllowed) {
    "guarded_internal_canary"
}
elseif ($releaseStage -eq "draft") {
    "draft_only"
}
else {
    "blocked_by_gates"
}

$candidateFingerprint = @(
    $baselineTag,
    $validatorStatus,
    $validatorFailCount,
    $validatorWarnCount,
    $regressionStatus,
    $regressionPromotionAllowed,
    $baselineTrusted,
    $rollbackReady,
    $releaseStage,
    $rolloutMode,
    $billingMode,
    $businessOutcomesStatus
) -join "|"
$releaseCandidateId = "rc_{0}_{1}" -f (Get-SafeIdentifier -Value $baselineTag), (Get-ShortHash -Value $candidateFingerprint -Length 12)

$sourceEvidence = Normalize-StringList -Value @(
    $systemTruthPath,
    $systemMetricsPath,
    $systemValidationPath,
    $regressionGuardPath,
    $rollbackPlanPath,
    $promotionGatePath,
    $capabilityScorecardPath,
    $changeBudgetPath,
    $promotionThrottlePath,
    $keepAlivePath,
    $securityPosturePath,
    $tenantSafetyPath,
    $billingSummaryPath,
    $brandExposurePath,
    $playbookSupportPath,
    $businessOutcomesPath,
    $wedgePackFrameworkPath,
    $liveDocsSummaryPath,
    $mirrorUpdatePath
) -MaxItems 32 -MaxLength 260

$releaseNotesReady = $true
$newCapabilities = @(
    "Governed release candidate evaluation now merges validator, regression, rollback, security, billing, brand, and business outcome posture into one release decision.",
    "Staged rollout groups now distinguish internal canary, founder/pilot, limited customer-safe, and blocked broader rollout.",
    "Release notes and rollout artifacts are generated from current local truth instead of ad hoc restart behavior."
)
$changedSurfaces = @(
    "Athena Operations exposes an additive Release Management summary card.",
    "/api/stack_status exposes a governed release_management payload branch.",
    "Reports now include release candidate, rollout, release notes, and release registry artifacts."
)
$operationalChanges = @(
    ("Current release stage is {0} with rollout mode {1}." -f $releaseStage, $rolloutMode),
    ("Promotion allowed={0}; canary allowed={1}; rollback ready={2}." -f $promotionAllowed.ToString().ToLowerInvariant(), $canaryAllowed.ToString().ToLowerInvariant(), $rollbackReady.ToString().ToLowerInvariant()),
    ("Release gating currently reads validator={0}, regression={1}, security={2}, billing={3}, business_outcomes={4}." -f $(if ($validatorStatus) { $validatorStatus } else { "missing" }), $(if ($regressionStatus) { $regressionStatus } else { "missing" }), $(if ($securityStatus) { $securityStatus } else { "missing" }), $(if ($billingMode) { $billingMode } else { "missing" }), $(if ($businessOutcomesStatus) { $businessOutcomesStatus } else { "missing" }))
)
$governanceChanges = @(
    "Promotion remains blocked whenever regression guard blocks promotion, the trusted baseline is missing, or rollback readiness is weak.",
    "Customer-ready rollout stays blocked while billing remains stubbed or business-outcome confidence is still sparse.",
    "Internal canary exposure is allowed only when core loopback health is stable and a basic rollback path is known."
)

$groupInternalReasons = if ($canaryAllowed) {
    @("Core loopback health is stable enough for internal/operator-only canary observation.")
}
else {
    @($internalCanaryBlockers)
}
$groupPilotReasons = if ($pilotReady) {
    @("Regression, baseline, rollback, and change-budget gates are clean enough for founder/pilot rollout.")
}
else {
    @($blockingReasons | Where-Object { $_ -match "Promotion remains blocked|trusted release baseline|rollback readiness|rollback path|Change budget|regression" })
}
if ($groupPilotReasons.Count -eq 0 -and -not $pilotReady) {
    $groupPilotReasons = @("Founder/pilot rollout is still blocked by conservative governance posture.")
}
$groupCustomerReasons = if ($customerReady) {
    @("Security, billing, brand exposure, and business-outcome confidence are strong enough for limited customer-safe rollout.")
}
else {
    @(($blockingReasons + $warningReasons) | Where-Object { $_ -match "Billing|brand|Business outcome|Security|tenant-safety|customer" } | Select-Object -Unique)
}
if ($groupCustomerReasons.Count -eq 0 -and -not $customerReady) {
    $groupCustomerReasons = @("Customer-safe rollout is not yet justified by the current baseline and outcome evidence.")
}

$rolloutGroups = @(
    [pscustomobject]@{
        group_id = "internal_operator_only"
        status = if ($canaryAllowed) { "eligible" } else { "blocked" }
        eligibility = [bool]$canaryAllowed
        gating_reasons = Normalize-StringList -Value $groupInternalReasons -MaxItems 8 -MaxLength 220
        recommended_action = if ($canaryAllowed) { "Keep this candidate in internal/operator canary mode while broader promotion remains gated." } else { "Fix the core internal canary blockers before attempting any rollout." }
    }
    [pscustomobject]@{
        group_id = "founder_pilot"
        status = if ($pilotReady) { "eligible" } else { "blocked" }
        eligibility = [bool]$pilotReady
        gating_reasons = Normalize-StringList -Value $groupPilotReasons -MaxItems 8 -MaxLength 220
        recommended_action = if ($pilotReady) { "Pilot rollout can proceed under founder control." } else { "Keep founder/pilot rollout blocked until regression, baseline, rollback, and change-budget gates improve." }
    }
    [pscustomobject]@{
        group_id = "limited_customer_safe"
        status = if ($customerReady) { "eligible" } else { "blocked" }
        eligibility = [bool]$customerReady
        gating_reasons = Normalize-StringList -Value $groupCustomerReasons -MaxItems 8 -MaxLength 220
        recommended_action = if ($customerReady) { "Customer-safe rollout is permitted within the governed scope." } else { "Do not claim customer-ready rollout while billing, security, brand, or outcome confidence gates remain unresolved." }
    }
    [pscustomobject]@{
        group_id = "broader_rollout_blocked"
        status = if ($customerReady) { "inactive" } else { "active" }
        eligibility = $false
        gating_reasons = Normalize-StringList -Value $(if ($customerReady) { @("Broader rollout is no longer blocked by the current gates.") } else { @($blockingReasons + $warningReasons) }) -MaxItems 10 -MaxLength 220
        recommended_action = if ($customerReady) { "No action required." } else { "Keep broader rollout blocked until the blocking reasons are resolved or deliberately waived through governance." }
    }
)

$eligibleGroupCount = @($rolloutGroups | Where-Object { [bool]$_.eligibility }).Count
$blockedGroupCount = @($rolloutGroups | Where-Object { (Normalize-Text $_.status) -in @("blocked", "active") }).Count
$canaryGroupCount = @($rolloutGroups | Where-Object { (Normalize-Text $_.group_id) -eq "internal_operator_only" -and [bool]$_.eligibility }).Count

$releaseNotesStatus = if ($customerReady) { "PASS" } else { "WARN" }
$releaseOverallStatus = if ($customerReady) { "PASS" } else { "WARN" }
$recommendedNextAction = if ($blockingReasons.Count -gt 0) {
    $blockingReasons[0]
}
elseif ($warningReasons.Count -gt 0) {
    $warningReasons[0]
}
else {
    "No action required."
}

$gatingInputs = [ordered]@{
    validator = [ordered]@{
        available = ($null -ne $systemValidation)
        status = $(if ($systemValidation) { $validatorStatus } else { "MISSING" })
        failed_count = [int]$validatorFailCount
        warn_count = [int]$validatorWarnCount
        stack_base_status = $stackBaseStatus
        source_artifact = $systemValidationPath
    }
    regression = [ordered]@{
        available = ($null -ne $regressionGuard)
        status = $(if ($regressionGuard) { $regressionStatus } else { "MISSING" })
        promotion_allowed = [bool]$regressionPromotionAllowed
        baseline_available = [bool]$baselineAvailable
        baseline_trusted = [bool]$baselineTrusted
        regression_count = [int]$regressionCount
        blocking_regression_count = [int]$blockingRegressionCount
        comparison_mode = $comparisonMode
        source_artifact = $regressionGuardPath
    }
    capability_change_budget = [ordered]@{
        available = $capabilityAvailable
        status = $(if ($capabilityAvailable) { $capabilityStatus } else { "MISSING" })
        overall_change_budget_tier = $(if ($overallChangeBudgetTier) { $overallChangeBudgetTier } else { "unavailable" })
        promotion_throttle_level = $(if ($promotionThrottleLevel) { $promotionThrottleLevel } else { "unavailable" })
        source_artifacts = Normalize-StringList -Value @($capabilityScorecardPath, $changeBudgetPath, $promotionThrottlePath) -MaxItems 3 -MaxLength 260
    }
    keepalive = [ordered]@{
        available = ($null -ne $keepAlive)
        status = $(if ($keepAlive) { $keepAliveStatus } else { "MISSING" })
        escalated_issue_count = [int]$keepAliveEscalations
        source_artifact = $keepAlivePath
    }
    security = [ordered]@{
        available = ($null -ne $securityPosture)
        status = $(if ($securityPosture) { $securityStatus } else { "MISSING" })
        tenant_safety_status = $(if ($tenantSafety) { $tenantSafetyStatus } else { "MISSING" })
        tenant_safety_issue_count = [int]$tenantSafetyIssues
        source_artifacts = Normalize-StringList -Value @($securityPosturePath, $tenantSafetyPath) -MaxItems 2 -MaxLength 260
    }
    billing = [ordered]@{
        available = ($null -ne $billingSummary)
        provider_mode = $(if ($billingMode) { $billingMode } else { "missing" })
        tenant_status = $(if ($billingTenantStatus) { $billingTenantStatus } else { "unknown" })
        source_artifact = $billingSummaryPath
    }
    brand_exposure = [ordered]@{
        available = ($null -ne $brandExposure)
        status = $(if ($brandExposure) { $brandStatus } else { "MISSING" })
        public_leak_count = [int]$brandLeakCount
        source_artifact = $brandExposurePath
    }
    release_note_readiness = [ordered]@{
        ready = [bool]$releaseNotesReady
        changed_surface_count = $changedSurfaces.Count
        known_warning_count = $warningReasons.Count
        source_artifacts = Normalize-StringList -Value @($liveDocsSummaryPath, $wedgePackFrameworkPath, $businessOutcomesPath) -MaxItems 3 -MaxLength 260
    }
    rollback_readiness = [ordered]@{
        rollback_ready = [bool]$rollbackReady
        rollback_recommended = [bool]$rollbackRecommended
        rollback_path_known = [bool]$rollbackPathKnown
        blocked_rollback_reasons = @($rollbackBlockedReasons)
        source_artifact = $rollbackPlanPath
    }
}

$releaseCandidateArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $releaseOverallStatus
    release_candidate_id = $releaseCandidateId
    release_stage = $releaseStage
    promotion_allowed = [bool]$promotionAllowed
    canary_allowed = [bool]$canaryAllowed
    pilot_ready = [bool]$pilotReady
    customer_ready = [bool]$customerReady
    blocking_reasons = @($blockingReasons)
    warning_reasons = @($warningReasons)
    source_evidence = @($sourceEvidence)
    recommended_next_action = $recommendedNextAction
    command_run = $commandRun
    repo_root = $repoRoot
    gating_inputs = $gatingInputs
}

$releaseNotesArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    release_candidate_id = $releaseCandidateId
    overall_status = $releaseNotesStatus
    change_summary = @(
        "Release evaluation is now governed instead of implicit.",
        ("Current release stage is {0} and rollout mode is {1}." -f $releaseStage, $rolloutMode),
        ("Promotion remains {0}." -f $(if ($promotionAllowed) { "allowed for broader rollout" } else { "blocked beyond internal canary" }))
    )
    new_capabilities = @($newCapabilities)
    changed_surfaces = @($changedSurfaces)
    operational_changes = Normalize-StringList -Value $operationalChanges -MaxItems 8 -MaxLength 240
    governance_changes = Normalize-StringList -Value $governanceChanges -MaxItems 8 -MaxLength 240
    known_warnings = @($warningReasons)
    blocked_items = @($blockingReasons)
    recommended_release_scope = if ($customerReady) { "limited_customer_safe" } elseif ($pilotReady) { "founder_pilot" } elseif ($canaryAllowed) { "internal_operator_only" } else { "blocked" }
}

$releaseRolloutArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $releaseOverallStatus
    release_candidate_id = $releaseCandidateId
    rollout_mode = $rolloutMode
    canary_group_count = [int]$canaryGroupCount
    eligible_group_count = [int]$eligibleGroupCount
    blocked_group_count = [int]$blockedGroupCount
    promotion_allowed = [bool]$promotionAllowed
    rollback_recommended = [bool]$rollbackRecommended
    recommended_next_action = $recommendedNextAction
    groups = @($rolloutGroups)
}

$releaseManagementArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $releaseOverallStatus
    release_candidate_id = $releaseCandidateId
    release_stage = $releaseStage
    release_readiness_classification = $releaseReadinessClassification
    promotion_allowed = [bool]$promotionAllowed
    rollout_mode = $rolloutMode
    rollback_ready = [bool]$rollbackReady
    blocking_reason_count = $blockingReasons.Count
    warning_reason_count = $warningReasons.Count
    recommended_next_action = $recommendedNextAction
    summary = [ordered]@{
        blocking_reasons = @($blockingReasons)
        warning_reasons = @($warningReasons)
        canary_allowed = [bool]$canaryAllowed
        pilot_ready = [bool]$pilotReady
        customer_ready = [bool]$customerReady
        baseline_tag = $baselineTag
    }
    command_run = $commandRun
    repo_root = $repoRoot
}

$releaseRegistryArtifact = [ordered]@{
    generated_at_utc = $nowUtc
    current_release_candidate_id = $releaseCandidateId
    current_release_stage = $releaseStage
    latest_release_management_artifact = $releaseManagementPath
    latest_release_notes_artifact = $releaseNotesPath
    latest_rollout_artifact = $releaseRolloutPath
    promotion_allowed = [bool]$promotionAllowed
    rollback_ready = [bool]$rollbackReady
    notes = Normalize-ShortText -Value ("Current release posture is {0}; rollout mode {1}; trusted baseline available={2}." -f $releaseStage, $rolloutMode, $baselineTrusted.ToString().ToLowerInvariant()) -MaxLength 220
}

Write-JsonFile -Path $releaseManagementPolicyPath -Data $policy
Write-JsonFile -Path $releaseCandidatePath -Data $releaseCandidateArtifact
Write-JsonFile -Path $releaseNotesPath -Data $releaseNotesArtifact
Write-JsonFile -Path $releaseRolloutPath -Data $releaseRolloutArtifact
Write-JsonFile -Path $releaseManagementPath -Data $releaseManagementArtifact
Write-JsonFile -Path $releaseRegistryPath -Data $releaseRegistryArtifact

$output = [ordered]@{
    ok = $true
    overall_status = $releaseOverallStatus
    release_candidate_id = $releaseCandidateId
    release_stage = $releaseStage
    promotion_allowed = [bool]$promotionAllowed
    canary_allowed = [bool]$canaryAllowed
    pilot_ready = [bool]$pilotReady
    customer_ready = [bool]$customerReady
    rollback_ready = [bool]$rollbackReady
    blocking_reason_count = $blockingReasons.Count
    warning_reason_count = $warningReasons.Count
    release_management_artifact = $releaseManagementPath
    release_candidate_artifact = $releaseCandidatePath
    release_notes_artifact = $releaseNotesPath
    release_rollout_artifact = $releaseRolloutPath
    release_registry_artifact = $releaseRegistryPath
    release_policy_artifact = $releaseManagementPolicyPath
}

$output | ConvertTo-Json -Depth 20
