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
        [int]$MaxLength = 200
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

function Get-ConfidenceLabel {
    param([double]$Score)

    if ($Score -ge 0.75) { return "high" }
    if ($Score -ge 0.45) { return "medium" }
    if ($Score -gt 0.0) { return "low" }
    return "unknown"
}

function Add-UniqueReason {
    param(
        [System.Collections.Generic.List[string]]$List,
        [AllowNull()][object]$Value
    )

    $text = Normalize-ShortText -Value $Value -MaxLength 240
    if ($text -and -not $List.Contains($text)) {
        [void]$List.Add($text)
    }
}

function Get-ToolRunRecords {
    param([string]$ToolsRoot)

    $records = @()
    if (-not (Test-Path -LiteralPath $ToolsRoot)) {
        return ,@($records)
    }

    foreach ($directory in (Get-ChildItem -LiteralPath $ToolsRoot -Directory | Sort-Object LastWriteTimeUtc -Descending)) {
        $artifactPath = Join-Path $directory.FullName "artifact.json"
        $artifact = Read-JsonSafe -Path $artifactPath
        if (-not $artifact) {
            continue
        }

        $tenant = Get-PropValue -Object $artifact -Name "tenant" -Default $null
        $tool = Get-PropValue -Object $artifact -Name "tool" -Default $null
        $output = Get-PropValue -Object $artifact -Name "output" -Default $null
        $records += [pscustomobject]@{
            run_id = Normalize-Text (Get-PropValue -Object $artifact -Name "run_id" -Default $directory.Name)
            tenant_id = Normalize-Text (Get-PropValue -Object $tenant -Name "tenant_id" -Default "")
            tool_id = Normalize-Text (Get-PropValue -Object $tool -Name "tool_id" -Default "")
            tool_name = Normalize-ShortText -Value (Get-PropValue -Object $tool -Name "name" -Default "") -MaxLength 120
            category = Normalize-Text (Get-PropValue -Object $tool -Name "category" -Default "")
            created_at_utc = Normalize-Text (Get-PropValue -Object $artifact -Name "created_at_utc" -Default "")
            summary = Normalize-ShortText -Value (Get-PropValue -Object $output -Name "summary" -Default "") -MaxLength 220
            artifact_path = $artifactPath
        }
    }

    return ,@($records)
}

function Get-BillingTenantRecord {
    param(
        [AllowNull()][object]$BillingSummary,
        [string]$TenantId
    )

    $tenant = Get-PropValue -Object $BillingSummary -Name "tenant" -Default $null
    if ($tenant -and (Normalize-Text (Get-PropValue -Object $tenant -Name "tenant_id" -Default "")) -eq $TenantId) {
        return $tenant
    }

    foreach ($billingTenant in @((Get-PropValue -Object $BillingSummary -Name "tenants" -Default @()))) {
        if ((Normalize-Text (Get-PropValue -Object $billingTenant -Name "tenant_id" -Default "")) -eq $TenantId) {
            return $billingTenant
        }
    }

    return $null
}

function Find-PlanById {
    param(
        [AllowNull()][object[]]$Plans,
        [string]$PlanId
    )

    foreach ($plan in @($Plans)) {
        if ((Normalize-Text (Get-PropValue -Object $plan -Name "plan_id" -Default "")) -eq $PlanId) {
            return $plan
        }
    }
    return $null
}

function Get-PlanPrice {
    param([AllowNull()][object]$Plan)

    $price = Get-PropValue -Object $Plan -Name "price_usd" -Default 0
    try {
        return [double]$price
    }
    catch {
        return 0.0
    }
}

function Find-UpgradePlan {
    param(
        [AllowNull()][object[]]$Plans,
        [AllowNull()][object]$CurrentPlan,
        [string[]]$NeededToolIds
    )

    $requiredTools = @($NeededToolIds | Where-Object { Normalize-Text $_ } | Sort-Object -Unique)
    if ($requiredTools.Count -eq 0) {
        return $null
    }

    $currentPrice = Get-PlanPrice -Plan $CurrentPlan
    $candidates = @($Plans | Sort-Object { Get-PlanPrice -Plan $_ })
    foreach ($plan in $candidates) {
        if ((Get-PlanPrice -Plan $plan) -le $currentPrice) {
            continue
        }

        $planTools = @((Get-PropValue -Object $plan -Name "enabled_tools" -Default @()) | ForEach-Object { Normalize-Text $_ } | Where-Object { $_ })
        $coversAll = $true
        foreach ($toolId in $requiredTools) {
            if ($toolId -notin $planTools) {
                $coversAll = $false
                break
            }
        }
        if ($coversAll) {
            return $plan
        }
    }

    return $null
}

$repoRoot = Resolve-RepoRoot -ExplicitRoot $RepoRoot
$reportsDir = Join-Path $repoRoot "reports"
$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"
$configDir = Join-Path $repoRoot "config"
$onyxStateDir = Join-Path $repoRoot "state\onyx"

$billingSummaryPath = Join-Path $reportsDir "billing_summary.json"
$businessOutcomesPath = Join-Path $reportsDir "business_outcomes_last.json"
$toolUsefulnessPath = Join-Path $reportsDir "tool_usefulness_last.json"
$recommendationEffectivenessPath = Join-Path $reportsDir "recommendation_effectiveness_last.json"
$tenantEngagementPath = Join-Path $reportsDir "tenant_engagement_last.json"
$systemTruthPath = Join-Path $reportsDir "system_truth_spine_last.json"
$wedgePackFrameworkPath = Join-Path $reportsDir "wedge_pack_framework_last.json"
$toolRegistryPath = Join-Path $configDir "tool_registry.json"
$tenantWorkspacePath = Join-Path $onyxStateDir "tenant_workspace.json"
$recommendationsDir = Join-Path $onyxStateDir "recommendations"
$toolsRoot = Join-Path $reportsDir "tools"

$revenueOptimizationPath = Join-Path $reportsDir "revenue_optimization_last.json"
$planFitAnalysisPath = Join-Path $reportsDir "plan_fit_analysis_last.json"
$upgradeSuggestionsPath = Join-Path $reportsDir "upgrade_suggestions_last.json"
$churnRescuePath = Join-Path $reportsDir "churn_rescue_last.json"
$revenueOptimizationRegistryPath = Join-Path $stateKnowledgeDir "revenue_optimization_registry.json"
$revenueOptimizationPolicyPath = Join-Path $configDir "revenue_optimization_policy.json"

$nowUtc = (Get-Date).ToUniversalTime().ToString("o")
$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Revenue_Optimization.ps1"

$policy = [ordered]@{
    version = 1
    policy_name = "revenue_optimization_engine"
    recommendation_classes = @(
        "plan_fit_analysis",
        "plan_upgrade_review",
        "add_on_fit_review",
        "wedge_pack_fit_review",
        "churn_rescue_review"
    )
    evidence_sources = @(
        "billing summary and provider posture",
        "tenant workspace and onboarding state",
        "recommendation records and statuses",
        "tool usefulness and tool run artifacts",
        "business outcomes and tenant engagement",
        "wedge-pack framework and tenant fit",
        "tool registry and plan configuration",
        "system truth spine"
    )
    gating_rules = @(
        "Revenue suggestions must remain recommendation-only when billing is stubbed or approval-gated.",
        "Low-confidence commercial fit must stay review-only.",
        "Sparse pilot data must not be converted into aggressive upgrade posture."
    )
    billing_safety_rules = @(
        "No auto-upgrades.",
        "No auto-add-on purchases.",
        "No auto-plan migration.",
        "No live money mutation without explicit approval and real provider readiness."
    )
    upgrade_add_on_fit_thresholds = [ordered]@{
        upgrade_review_threshold = 0.55
        add_on_review_threshold = 0.35
        low_confidence_cap_when_dismissed = 0.40
    }
    churn_rescue_thresholds = [ordered]@{
        elevated = @("elevated")
        moderate = @("moderate")
        review_only = @("moderate", "elevated")
    }
    sparse_data_handling = @(
        "Use low or unknown confidence when only one tenant or one weak signal exists.",
        "Do not treat zero upgrade suggestions as malformed."
    )
    no_auto_money_rules = @(
        "All commercial suggestions must include action_posture.",
        "billing_gated, analysis_only, owner_review_required, or not_actionable_yet are valid outcomes.",
        "Execution remains blocked until billing posture changes."
    )
    customer_safe_output_rules = @(
        "Customer-safe summaries may mention plan or add-on names but must avoid internal file paths and Mason-private implementation details.",
        "Do not imply a charge or automatic change already happened."
    )
    owner_internal_output_rules = @(
        "Owner/internal outputs may reference billing stub posture, confidence level, and gating reasons.",
        "Revenue suggestions must remain explicit about blocked money actions."
    )
}

$tenantWorkspace = Read-JsonSafe -Path $tenantWorkspacePath
$billingSummary = Read-JsonSafe -Path $billingSummaryPath
$businessOutcomes = Read-JsonSafe -Path $businessOutcomesPath
$toolUsefulness = Read-JsonSafe -Path $toolUsefulnessPath
$recommendationEffectiveness = Read-JsonSafe -Path $recommendationEffectivenessPath
$tenantEngagement = Read-JsonSafe -Path $tenantEngagementPath
$systemTruth = Read-JsonSafe -Path $systemTruthPath
$wedgePackFramework = Read-JsonSafe -Path $wedgePackFrameworkPath
$toolRegistry = Read-JsonSafe -Path $toolRegistryPath

$tenantContexts = @((Get-PropValue -Object $tenantWorkspace -Name "contexts" -Default @()))
$plans = @((Get-PropValue -Object $billingSummary -Name "plans" -Default @()))
$tools = @((Get-PropValue -Object $toolRegistry -Name "tools" -Default @()))
$toolRuns = Get-ToolRunRecords -ToolsRoot $toolsRoot

$recommendationRecords = @()
if (Test-Path -LiteralPath $recommendationsDir) {
    foreach ($file in (Get-ChildItem -LiteralPath $recommendationsDir -Filter *.json -File | Sort-Object LastWriteTimeUtc -Descending)) {
        $tenantRecommendation = Read-JsonSafe -Path $file.FullName
        if (-not $tenantRecommendation) {
            continue
        }

        $tenantId = Normalize-Text (Get-PropValue -Object $tenantRecommendation -Name "tenant_id" -Default "")
        foreach ($recommendation in @((Get-PropValue -Object $tenantRecommendation -Name "recommendations" -Default @()))) {
            $recommendationRecords += [pscustomobject]@{
                tenant_id = $tenantId
                recommendation_id = Normalize-Text (Get-PropValue -Object $recommendation -Name "recommendation_id" -Default "")
                recommendation_type = Normalize-Text (Get-PropValue -Object $recommendation -Name "type" -Default "")
                status = Normalize-Text (Get-PropValue -Object $recommendation -Name "status" -Default "")
                linked_tool_id = Normalize-Text (Get-PropValue -Object $recommendation -Name "linked_tool_id" -Default "")
                title = Normalize-ShortText -Value (Get-PropValue -Object $recommendation -Name "title" -Default "") -MaxLength 140
                source_path = $file.FullName
            }
        }
    }
}

$toolUsefulnessById = @{}
foreach ($toolRecord in @((Get-PropValue -Object $toolUsefulness -Name "per_tool_usefulness" -Default @()))) {
    $toolId = Normalize-Text (Get-PropValue -Object $toolRecord -Name "tool_id" -Default "")
    if ($toolId) {
        $toolUsefulnessById[$toolId] = $toolRecord
    }
}

$tenantEngagementById = @{}
foreach ($tenantRecord in @((Get-PropValue -Object $tenantEngagement -Name "tenants" -Default @()))) {
    $tenantId = Normalize-Text (Get-PropValue -Object $tenantRecord -Name "tenant_id" -Default "")
    if ($tenantId) {
        $tenantEngagementById[$tenantId] = $tenantRecord
    }
}

$tenantFitById = @{}
foreach ($tenantFit in @((Get-PropValue -Object $wedgePackFramework -Name "tenant_fit" -Default @()))) {
    $tenantId = Normalize-Text (Get-PropValue -Object $tenantFit -Name "tenant_id" -Default "")
    if ($tenantId) {
        $tenantFitById[$tenantId] = $tenantFit
    }
}

$provider = Get-PropValue -Object $billingSummary -Name "provider" -Default $null
$billingMode = Normalize-Text (Get-PropValue -Object $provider -Name "mode" -Default "")
$providerConfigured = [bool](Get-PropValue -Object $billingSummary -Name "provider_configured" -Default $false)
$moneyActionsRequireApproval = [bool](Get-PropValue -Object $billingSummary -Name "money_actions_require_approval" -Default $true)
$billingGated = (-not $providerConfigured) -or $moneyActionsRequireApproval -or ($billingMode -eq "stub")
$moneyActionAllowed = (-not $billingGated)
$outcomeLowConfidenceCount = [int](Get-PropValue -Object $businessOutcomes -Name "low_confidence_domain_count" -Default 0)
$acceptedRecommendationTotal = [int](Get-PropValue -Object $recommendationEffectiveness -Name "accepted_count" -Default 0)
$pendingRecommendationTotal = [int](Get-PropValue -Object $recommendationEffectiveness -Name "pending_count" -Default 0)

$planFitRecords = @()
$suggestionRecords = @()
$churnRescueRecords = @()

foreach ($context in $tenantContexts) {
    $tenant = Get-PropValue -Object $context -Name "tenant" -Default $null
    $onboarding = Get-PropValue -Object $context -Name "onboarding" -Default $null
    $tenantId = Normalize-Text (Get-PropValue -Object $tenant -Name "id" -Default "")
    if (-not $tenantId) {
        continue
    }

    $billingTenant = Get-BillingTenantRecord -BillingSummary $billingSummary -TenantId $tenantId
    $engagementRecord = if ($tenantEngagementById.ContainsKey($tenantId)) { $tenantEngagementById[$tenantId] } else { $null }
    $tenantFitRecord = if ($tenantFitById.ContainsKey($tenantId)) { $tenantFitById[$tenantId] } else { $null }

    $tenantToolRuns = @($toolRuns | Where-Object { (Normalize-Text $_.tenant_id) -eq $tenantId })
    $usedTools = @($tenantToolRuns | ForEach-Object { Normalize-Text $_.tool_id } | Where-Object { $_ } | Sort-Object -Unique)
    $tenantRecommendations = @($recommendationRecords | Where-Object { (Normalize-Text $_.tenant_id) -eq $tenantId })
    $acceptedRecommendations = @($tenantRecommendations | Where-Object { (Normalize-Text $_.status) -eq "accepted" })
    $dismissedRecommendations = @($tenantRecommendations | Where-Object { (Normalize-Text $_.status) -in @("dismissed", "rejected") })
    $pendingRecommendations = @($tenantRecommendations | Where-Object { (Normalize-Text $_.status) -in @("new", "seen") })

    $currentPlanId = Normalize-Text (Get-PropValue -Object $billingTenant -Name "plan_id" -Default "")
    $currentPlan = Find-PlanById -Plans $plans -PlanId $currentPlanId
    $currentPlanName = Normalize-ShortText -Value (Get-PropValue -Object $billingTenant -Name "plan_name" -Default $(Get-PropValue -Object $currentPlan -Name "name" -Default "")) -MaxLength 120
    $enabledTools = @((Get-PropValue -Object $billingTenant -Name "enabled_tools" -Default @()) | ForEach-Object { Normalize-Text $_ } | Where-Object { $_ } | Sort-Object -Unique)
    $availableAddons = @((Get-PropValue -Object $billingTenant -Name "available_addons" -Default @()))
    $activeAddons = @((Get-PropValue -Object $billingTenant -Name "active_addons" -Default @()))
    $billingStatus = Normalize-Text (Get-PropValue -Object $billingTenant -Name "status" -Default "")
    $onboardingComplete = [bool](Get-PropValue -Object $onboarding -Name "isCompleted" -Default $false)
    $completionPercent = [int](Get-PropValue -Object $onboarding -Name "completionPercent" -Default 0)
    $onboardingStatus = if ($onboardingComplete) { "completed" } elseif ($completionPercent -gt 0) { "in_progress" } else { "unknown" }
    $engagementClass = Normalize-Text (Get-PropValue -Object $engagementRecord -Name "engagement_classification" -Default "")
    $revenueHelpSignal = Normalize-Text (Get-PropValue -Object $engagementRecord -Name "revenue_help_signal" -Default "")
    $churnRisk = Normalize-Text (Get-PropValue -Object $engagementRecord -Name "churn_risk_classification" -Default "")
    $businessCategory = Normalize-Text (Get-PropValue -Object $tenantFitRecord -Name "business_category" -Default "")
    $businessSubcategory = Normalize-Text (Get-PropValue -Object $tenantFitRecord -Name "business_subcategory" -Default "")

    $underfitReasons = New-Object 'System.Collections.Generic.List[string]'
    $overfitReasons = New-Object 'System.Collections.Generic.List[string]'
    $wellFitReasons = New-Object 'System.Collections.Generic.List[string]'
    $missingToolCandidates = New-Object 'System.Collections.Generic.List[string]'

    foreach ($acceptedRecommendation in $acceptedRecommendations) {
        $linkedToolId = Normalize-Text (Get-PropValue -Object $acceptedRecommendation -Name "linked_tool_id" -Default "")
        if (-not $linkedToolId) {
            continue
        }
        if ($enabledTools -notcontains $linkedToolId) {
            [void]$missingToolCandidates.Add($linkedToolId)
            Add-UniqueReason -List $underfitReasons -Value ("Accepted recommendation {0} points to tool {1} which is not included in the current plan." -f (Normalize-ShortText -Value $acceptedRecommendation.title -MaxLength 100), $linkedToolId)
        }
    }

    if ($onboardingComplete -and $usedTools.Count -gt 0 -and $billingStatus -eq "active") {
        Add-UniqueReason -List $wellFitReasons -Value "Onboarding is complete, the subscription is active, and the tenant is using entitled tools."
    }
    if ($usedTools.Count -gt 0 -and @($usedTools | Where-Object { $_ -notin $enabledTools }).Count -eq 0) {
        Add-UniqueReason -List $wellFitReasons -Value "Current tool usage fits within the current plan entitlements."
    }
    if ((Normalize-Text $engagementClass) -eq "active" -and (Normalize-Text $revenueHelpSignal) -in @("possible_signal", "positive_signal")) {
        Add-UniqueReason -List $wellFitReasons -Value "Engagement and revenue-help signals show the current plan is supporting active work rather than blocking it."
    }

    $currentPlanTierId = Normalize-Text (Get-PropValue -Object $currentPlan -Name "tier_id" -Default "")
    if ($currentPlanTierId -in @("growth", "founder") -and $usedTools.Count -eq 0 -and -not $onboardingComplete) {
        Add-UniqueReason -List $overfitReasons -Value "A higher plan is active, but there is no current usage signal and onboarding is incomplete."
    }
    if ($currentPlanTierId -eq "founder" -and $usedTools.Count -le 1 -and (Normalize-Text $engagementClass) -in @("low", "light")) {
        Add-UniqueReason -List $overfitReasons -Value "Founder-tier surface may be broader than the current tenant activity requires."
    }

    $fitClassification = "unknown"
    if ($underfitReasons.Count -gt 0) {
        $fitClassification = "underfit"
    }
    elseif ($overfitReasons.Count -gt 0) {
        $fitClassification = "overfit"
    }
    elseif ($wellFitReasons.Count -gt 0) {
        $fitClassification = "well_fit"
    }

    $fitConfidenceScore = 0.20
    if ($billingStatus) { $fitConfidenceScore += 0.20 }
    if ($onboardingComplete) { $fitConfidenceScore += 0.15 }
    if ($usedTools.Count -gt 0) { $fitConfidenceScore += 0.20 }
    if (($acceptedRecommendations.Count + $dismissedRecommendations.Count + $pendingRecommendations.Count) -gt 0) { $fitConfidenceScore += 0.10 }
    if ($businessCategory) { $fitConfidenceScore += 0.10 }
    if ($fitClassification -ne "unknown") { $fitConfidenceScore += 0.10 }
    if ($tenantContexts.Count -lt 2) { $fitConfidenceScore = [Math]::Min($fitConfidenceScore, 0.70) }
    $fitConfidence = Get-ConfidenceLabel -Score $fitConfidenceScore

    $fitRationaleSource = switch ($fitClassification) {
        "underfit" { @($underfitReasons) }
        "overfit" { @($overfitReasons) }
        "well_fit" { @($wellFitReasons) }
        default { @("Current plan fit is still sparse or inconclusive with the available tenant evidence.") }
    }

    $recommendedPlanAction = switch ($fitClassification) {
        "underfit" { "review_upgrade_options" }
        "overfit" { "review_lower_tier_fit" }
        "well_fit" { "keep_current_plan" }
        default { "gather_more_signal" }
    }

    $planFitRecords += [pscustomobject]@{
        tenant_id = $tenantId
        current_plan = if ($currentPlanId) { $currentPlanId } else { Normalize-Text (Get-PropValue -Object $tenant -Name "planTier" -Default "") }
        fit_classification = $fitClassification
        fit_confidence = $fitConfidence
        fit_rationale = Normalize-ShortText -Value (($fitRationaleSource -join " ")) -MaxLength 260
        recommended_plan_action = $recommendedPlanAction
        money_action_allowed = $moneyActionAllowed
        business_category = $businessCategory
        business_subcategory = $businessSubcategory
        current_plan_name = $currentPlanName
        action_posture = if ($moneyActionAllowed) { "owner_review_required" } else { "billing_gated" }
    }

    if ($fitClassification -eq "underfit") {
        $upgradePlan = Find-UpgradePlan -Plans $plans -CurrentPlan $currentPlan -NeededToolIds @($missingToolCandidates)
        if ($upgradePlan) {
            $upgradeConfidenceScore = [Math]::Min(0.85, ($fitConfidenceScore + 0.10))
            $suggestionRecords += [pscustomobject]@{
                tenant_id = $tenantId
                suggestion_type = "plan_upgrade"
                current_plan_or_state = if ($currentPlanName) { $currentPlanName } else { $currentPlanId }
                suggested_plan_or_add_on = Normalize-Text (Get-PropValue -Object $upgradePlan -Name "plan_id" -Default "")
                confidence = Get-ConfidenceLabel -Score $upgradeConfidenceScore
                rationale = Normalize-ShortText -Value ("{0} Review {1} because it covers the missing tool surface: {2}." -f ($fitRationaleSource -join " "), (Normalize-Text (Get-PropValue -Object $upgradePlan -Name "name" -Default "")), (@($missingToolCandidates | Sort-Object -Unique) -join ", ")) -MaxLength 260
                customer_safe_summary = Normalize-ShortText -Value ("If you need the missing tool surface in one plan, {0} is the next plan to review. Nothing changes automatically." -f (Normalize-Text (Get-PropValue -Object $upgradePlan -Name "name" -Default "the next plan"))) -MaxLength 200
                action_posture = if ($moneyActionAllowed) { "owner_review_required" } else { "billing_gated" }
                blocked_by_billing_gate = (-not $moneyActionAllowed)
            }
        }
    }

    foreach ($addon in $availableAddons) {
        $addonId = Normalize-Text (Get-PropValue -Object $addon -Name "addon_id" -Default "")
        $addonName = Normalize-Text (Get-PropValue -Object $addon -Name "name" -Default "")
        $addonToolId = Normalize-Text (Get-PropValue -Object $addon -Name "tool_id" -Default "")
        if (-not $addonId -or -not $addonToolId) {
            continue
        }
        if (@($activeAddons | ForEach-Object { Normalize-Text (Get-PropValue -Object $_ -Name "addon_id" -Default "") }) -contains $addonId) {
            continue
        }

        $addonRecommendations = @($tenantRecommendations | Where-Object { (Normalize-Text $_.linked_tool_id) -eq $addonToolId })
        $addonAccepted = @($addonRecommendations | Where-Object { (Normalize-Text $_.status) -eq "accepted" }).Count
        $addonDismissed = @($addonRecommendations | Where-Object { (Normalize-Text $_.status) -in @("dismissed", "rejected") }).Count
        $addonPending = @($addonRecommendations | Where-Object { (Normalize-Text $_.status) -in @("new", "seen") }).Count
        $toolUsefulnessRecord = if ($toolUsefulnessById.ContainsKey($addonToolId)) { $toolUsefulnessById[$addonToolId] } else { $null }

        $addonScore = 0.10
        $addonReasons = New-Object 'System.Collections.Generic.List[string]'
        Add-UniqueReason -List $addonReasons -Value ("{0} is available on the current billing record." -f $addonName)

        if ($businessCategory -eq "services" -and $addonToolId -eq "marketing_pack_v1") {
            $addonScore += 0.15
            Add-UniqueReason -List $addonReasons -Value "The active tenant fit is a service-growth segment where marketing support can be relevant."
        }
        if ($businessCategory -in @("services", "contractor", "retail") -and $addonToolId -eq "sales_followup_v1") {
            $addonScore += 0.15
            Add-UniqueReason -List $addonReasons -Value "The active tenant fit is a segment where tighter sales follow-up can matter."
        }
        if ($onboardingComplete) {
            $addonScore += 0.10
            Add-UniqueReason -List $addonReasons -Value "Onboarding is complete, so expansion fit can be evaluated without guessing basic setup."
        }
        if ((Normalize-Text $engagementClass) -eq "active") {
            $addonScore += 0.10
            Add-UniqueReason -List $addonReasons -Value "The tenant is actively engaging with the product rather than sitting idle."
        }
        if ((Normalize-Text $revenueHelpSignal) -eq "positive_signal") {
            $addonScore += 0.20
            Add-UniqueReason -List $addonReasons -Value "Current revenue-help indicators are positive at the behavior level."
        }
        elseif ((Normalize-Text $revenueHelpSignal) -eq "possible_signal") {
            $addonScore += 0.10
            Add-UniqueReason -List $addonReasons -Value "There is at least some revenue-supportive behavior signal."
        }
        if ($addonAccepted -gt 0) {
            $addonScore += 0.25
            Add-UniqueReason -List $addonReasons -Value "An accepted recommendation already points toward this add-on capability."
        }
        elseif ($addonPending -gt 0) {
            $addonScore += 0.15
            Add-UniqueReason -List $addonReasons -Value "There is a pending recommendation that maps to this add-on capability."
        }
        elseif ($addonDismissed -gt 0) {
            $addonScore -= 0.10
            Add-UniqueReason -List $addonReasons -Value "A prior recommendation for this area was dismissed, so fit remains uncertain."
        }

        $toolUsefulnessClass = Normalize-Text (Get-PropValue -Object $toolUsefulnessRecord -Name "usefulness_classification" -Default "")
        if ($toolUsefulnessClass -eq "useful") {
            $addonScore += 0.20
        }
        elseif ($toolUsefulnessClass -eq "underused") {
            $addonScore -= 0.05
        }

        if ($addonDismissed -gt 0 -and $addonAccepted -eq 0 -and $addonPending -eq 0) {
            $addonScore = [Math]::Min($addonScore, [double](Get-PropValue -Object $policy.upgrade_add_on_fit_thresholds -Name "low_confidence_cap_when_dismissed" -Default 0.40))
        }

        if ($addonScore -ge [double](Get-PropValue -Object $policy.upgrade_add_on_fit_thresholds -Name "add_on_review_threshold" -Default 0.35)) {
            $suggestionRecords += [pscustomobject]@{
                tenant_id = $tenantId
                suggestion_type = "add_on_fit"
                current_plan_or_state = if ($currentPlanName) { $currentPlanName } else { $currentPlanId }
                suggested_plan_or_add_on = $addonId
                confidence = Get-ConfidenceLabel -Score $addonScore
                rationale = Normalize-ShortText -Value (($addonReasons -join " ")) -MaxLength 260
                customer_safe_summary = Normalize-ShortText -Value ("If you want more {0} support later, review {1}. Nothing is being applied or billed automatically." -f $(if ($addonToolId -eq "marketing_pack_v1") { "marketing" } elseif ($addonToolId -eq "sales_followup_v1") { "follow-up" } else { "workflow" }), $addonName) -MaxLength 220
                action_posture = if ($moneyActionAllowed) { "owner_review_required" } else { "billing_gated" }
                blocked_by_billing_gate = (-not $moneyActionAllowed)
            }
        }
    }

    if ((Normalize-Text $churnRisk) -in @("moderate", "elevated")) {
        $rescueSuggestion = if (-not $onboardingComplete) {
            "Offer a simpler onboarding path before pushing broader commercial changes."
        }
        elseif ((Normalize-Text $engagementClass) -eq "low") {
            "Offer a lower-friction next step tied to the most relevant current tool or workflow."
        }
        elseif ($fitClassification -eq "underfit") {
            "Review plan or add-on fit before trying to expand usage."
        }
        else {
            "Use the support/playbook layer to propose a targeted owner review and next step."
        }

        $rescueEvidence = New-Object 'System.Collections.Generic.List[string]'
        Add-UniqueReason -List $rescueEvidence -Value ("Churn risk is currently classified as {0}." -f $churnRisk)
        Add-UniqueReason -List $rescueEvidence -Value ("Engagement classification is {0}." -f $(if ($engagementClass) { $engagementClass } else { "unknown" }))
        Add-UniqueReason -List $rescueEvidence -Value ("Onboarding status is {0}." -f $onboardingStatus)

        $rescueConfidenceScore = 0.25
        if ((Normalize-Text $churnRisk) -eq "elevated") { $rescueConfidenceScore += 0.30 } else { $rescueConfidenceScore += 0.15 }
        if ($engagementClass) { $rescueConfidenceScore += 0.10 }
        if ($onboardingStatus -ne "unknown") { $rescueConfidenceScore += 0.10 }

        $churnRescueRecords += [pscustomobject]@{
            tenant_id = $tenantId
            churn_risk_classification = $churnRisk
            rescue_suggestion = $rescueSuggestion
            confidence = Get-ConfidenceLabel -Score $rescueConfidenceScore
            supportive_evidence = Normalize-StringList -Value $rescueEvidence -MaxItems 6 -MaxLength 180
            customer_safe_summary = Normalize-ShortText -Value "A lighter next step or fit review may help this account re-engage before any commercial conversation." -MaxLength 180
            owner_action_required = $true
        }
    }
}

$tenantCount = $planFitRecords.Count
$underfitCount = @($planFitRecords | Where-Object { (Normalize-Text $_.fit_classification) -eq "underfit" }).Count
$overfitCount = @($planFitRecords | Where-Object { (Normalize-Text $_.fit_classification) -eq "overfit" }).Count
$wellFitCount = @($planFitRecords | Where-Object { (Normalize-Text $_.fit_classification) -eq "well_fit" }).Count
$unknownFitCount = @($planFitRecords | Where-Object { (Normalize-Text $_.fit_classification) -eq "unknown" }).Count
$fitEvaluableCount = $tenantCount - $unknownFitCount

$upgradeSuggestionCount = @($suggestionRecords | Where-Object { (Normalize-Text $_.suggestion_type) -eq "plan_upgrade" }).Count
$addOnSuggestionCount = @($suggestionRecords | Where-Object { (Normalize-Text $_.suggestion_type) -eq "add_on_fit" }).Count
$customerSafeSuggestionCount = @($suggestionRecords | Where-Object { Normalize-Text $_.customer_safe_summary }).Count
$ownerReviewRequiredCount = @($suggestionRecords | Where-Object { (Normalize-Text $_.action_posture) -eq "owner_review_required" }).Count
$blockedMoneyActionCount = @($suggestionRecords | Where-Object { [bool]$_.blocked_by_billing_gate }).Count

$moderateRiskCount = @($churnRescueRecords | Where-Object { (Normalize-Text $_.churn_risk_classification) -eq "moderate" }).Count
$elevatedRiskCount = @($churnRescueRecords | Where-Object { (Normalize-Text $_.churn_risk_classification) -eq "elevated" }).Count
$churnRescueCount = $churnRescueRecords.Count

$lowConfidenceCount = @($planFitRecords | Where-Object { (Normalize-Text $_.fit_confidence) -in @("low", "unknown") }).Count
$lowConfidenceCount += @($suggestionRecords | Where-Object { (Normalize-Text $_.confidence) -in @("low", "unknown") }).Count
$lowConfidenceCount += @($churnRescueRecords | Where-Object { (Normalize-Text $_.confidence) -in @("low", "unknown") }).Count

$tenantsWithRevenueSignal = @($planFitRecords | Where-Object { (Normalize-Text $_.fit_classification) -ne "unknown" }).Count

$planFitStatus = if ($unknownFitCount -gt 0 -or $underfitCount -gt 0 -or $overfitCount -gt 0) { "WARN" } else { "PASS" }
$upgradeStatus = if ($blockedMoneyActionCount -gt 0 -or @($suggestionRecords | Where-Object { (Normalize-Text $_.confidence) -in @("low", "unknown") }).Count -gt 0) { "WARN" } else { "PASS" }
$churnRescueStatus = if ($churnRescueCount -gt 0) { "WARN" } else { "PASS" }
$overallStatus = if ($billingGated -or $lowConfidenceCount -gt 0 -or $churnRescueCount -gt 0) { "WARN" } else { "PASS" }

$planFitArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $planFitStatus
    tenant_count = [int]$tenantCount
    fit_evaluable_count = [int]$fitEvaluableCount
    underfit_count = [int]$underfitCount
    overfit_count = [int]$overfitCount
    well_fit_count = [int]$wellFitCount
    unknown_fit_count = [int]$unknownFitCount
    recommended_next_action = if ($underfitCount -gt 0) { "Review underfit tenants first, but keep any money action blocked until billing posture changes." } elseif ($unknownFitCount -gt 0) { "Collect more tenant evidence before making stronger plan-fit claims." } else { "Keep measuring plan fit as more tenants and tool signals arrive." }
    tenants = $planFitRecords
    command_run = $commandRun
    repo_root = $repoRoot
}

$upgradeSuggestionsArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $upgradeStatus
    tenant_count = [int]$tenantCount
    upgrade_suggestion_count = [int]$upgradeSuggestionCount
    add_on_suggestion_count = [int]$addOnSuggestionCount
    customer_safe_suggestion_count = [int]$customerSafeSuggestionCount
    owner_review_required_count = [int]$ownerReviewRequiredCount
    recommended_next_action = if ($blockedMoneyActionCount -gt 0) { "Keep revenue suggestions in analysis-only mode while billing stays stubbed or approval-gated." } elseif ($suggestionRecords.Count -gt 0) { "Review the highest-confidence suggestion manually before changing anything commercial." } else { "No revenue-fit suggestion clears the threshold yet; keep collecting usage and recommendation evidence." }
    suggestions = $suggestionRecords
    command_run = $commandRun
    repo_root = $repoRoot
}

$churnRescueArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $churnRescueStatus
    tenant_count = [int]$tenantCount
    churn_rescue_count = [int]$churnRescueCount
    moderate_risk_count = [int]$moderateRiskCount
    elevated_risk_count = [int]$elevatedRiskCount
    low_confidence_count = [int](@($churnRescueRecords | Where-Object { (Normalize-Text $_.confidence) -in @("low", "unknown") }).Count)
    recommended_next_action = if ($churnRescueCount -gt 0) { "Review the churn rescue suggestions before trying commercial expansion." } else { "No current tenant needs a churn rescue motion; keep monitoring engagement and onboarding." }
    rescues = $churnRescueRecords
    command_run = $commandRun
    repo_root = $repoRoot
}

$topOpportunities = New-Object 'System.Collections.Generic.List[string]'
if ($addOnSuggestionCount -gt 0) {
    Add-UniqueReason -List $topOpportunities -Value ("{0} add-on fit suggestion(s) are available for manual owner review." -f $addOnSuggestionCount)
}
if ($upgradeSuggestionCount -gt 0) {
    Add-UniqueReason -List $topOpportunities -Value ("{0} tenant(s) appear underfit enough to review a higher plan." -f $upgradeSuggestionCount)
}
if ($wellFitCount -gt 0) {
    Add-UniqueReason -List $topOpportunities -Value ("{0} tenant(s) appear reasonably well fit today, which gives a baseline for future revenue experiments." -f $wellFitCount)
}
if ($acceptedRecommendationTotal -gt 0 -and $upgradeSuggestionCount -eq 0) {
    Add-UniqueReason -List $topOpportunities -Value "Recommendation follow-through exists, but it does not yet justify a stronger commercial step."
}
if ($topOpportunities.Count -eq 0) {
    Add-UniqueReason -List $topOpportunities -Value "No strong commercial opportunity clears the current threshold yet."
}

$cautionAreas = New-Object 'System.Collections.Generic.List[string]'
if ($billingGated) {
    Add-UniqueReason -List $cautionAreas -Value "Billing remains stubbed or approval-gated, so all money actions stay analysis-only."
}
if ($tenantCount -lt 2) {
    Add-UniqueReason -List $cautionAreas -Value "Revenue evidence is still pilot-sized and based on one tenant."
}
if ($lowConfidenceCount -gt 0) {
    Add-UniqueReason -List $cautionAreas -Value ("{0} revenue records remain low-confidence and should not drive aggressive commercial changes." -f $lowConfidenceCount)
}
if ($outcomeLowConfidenceCount -gt 0) {
    Add-UniqueReason -List $cautionAreas -Value ("Business outcome evidence still carries {0} low-confidence domain(s)." -f $outcomeLowConfidenceCount)
}
if ($churnRescueCount -eq 0) {
    Add-UniqueReason -List $cautionAreas -Value "No churn rescue motion is active right now, but that is based on sparse history rather than broad retention proof."
}
if ($pendingRecommendationTotal -gt 0) {
    Add-UniqueReason -List $cautionAreas -Value ("There are still {0} pending recommendation(s), so some commercial fit remains unresolved." -f $pendingRecommendationTotal)
}

$revenueOptimizationArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $overallStatus
    tenant_count = [int]$tenantCount
    tenants_with_revenue_signal = [int]$tenantsWithRevenueSignal
    upgrade_opportunity_count = [int]$upgradeSuggestionCount
    add_on_fit_count = [int]$addOnSuggestionCount
    churn_rescue_count = [int]$churnRescueCount
    blocked_money_action_count = [int]$blockedMoneyActionCount
    low_confidence_count = [int]$lowConfidenceCount
    recommended_next_action = if ($billingGated) { "Keep revenue optimization in analysis-only mode until billing moves beyond stub posture, and review only the low-confidence add-on suggestions manually." } elseif ($suggestionRecords.Count -gt 0) { "Review the highest-confidence revenue suggestion manually before changing plans or add-ons." } else { "Keep collecting usage and tenant-fit evidence before making stronger revenue optimization claims." }
    summary = [ordered]@{
        top_opportunities = @($topOpportunities)
        caution_areas = @($cautionAreas)
    }
    plan_fit = [ordered]@{
        summary = Normalize-ShortText -Value ("well_fit={0}; underfit={1}; overfit={2}; unknown={3}." -f $wellFitCount, $underfitCount, $overfitCount, $unknownFitCount) -MaxLength 160
        underfit_count = [int]$underfitCount
        overfit_count = [int]$overfitCount
        well_fit_count = [int]$wellFitCount
        unknown_fit_count = [int]$unknownFitCount
    }
    upgrade_suggestions = [ordered]@{
        summary = Normalize-ShortText -Value ("upgrade={0}; add_on={1}; blocked_by_billing_gate={2}." -f $upgradeSuggestionCount, $addOnSuggestionCount, $blockedMoneyActionCount) -MaxLength 180
        upgrade_opportunity_count = [int]$upgradeSuggestionCount
        add_on_fit_count = [int]$addOnSuggestionCount
        blocked_money_action_count = [int]$blockedMoneyActionCount
    }
    add_on_fit = [ordered]@{
        summary = if ($addOnSuggestionCount -gt 0) { "At least one add-on fit suggestion exists, but it remains analysis-only under the current billing posture." } else { "No add-on fit suggestion is strong enough yet." }
        add_on_fit_count = [int]$addOnSuggestionCount
        low_confidence_count = [int](@($suggestionRecords | Where-Object { (Normalize-Text $_.suggestion_type) -eq "add_on_fit" -and (Normalize-Text $_.confidence) -in @("low", "unknown") }).Count)
    }
    churn_rescue = [ordered]@{
        summary = if ($churnRescueCount -gt 0) { "Some tenants need rescue review before broader commercial expansion." } else { "No churn rescue action is currently triggered." }
        churn_rescue_count = [int]$churnRescueCount
        moderate_risk_count = [int]$moderateRiskCount
        elevated_risk_count = [int]$elevatedRiskCount
    }
    billing_posture_linkage = [ordered]@{
        provider_mode = $billingMode
        provider_configured = $providerConfigured
        billing_gated = $billingGated
        money_actions_require_approval = $moneyActionsRequireApproval
        summary = if ($billingGated) { "Commercial suggestions are analysis-only because billing is stubbed or approval-gated." } else { "Billing posture allows owner-reviewed commercial action, but not auto-execution." }
    }
    command_run = $commandRun
    repo_root = $repoRoot
}

$registry = [ordered]@{
    generated_at_utc = $nowUtc
    overall_status = $overallStatus
    latest_revenue_optimization_artifact = $revenueOptimizationPath
    tenant_count = [int]$tenantCount
    upgrade_opportunity_count = [int]$upgradeSuggestionCount
    add_on_fit_count = [int]$addOnSuggestionCount
    churn_rescue_count = [int]$churnRescueCount
    notes = Normalize-StringList -Value @(
        $(if ($billingGated) { "Billing is still stubbed or approval-gated." }),
        $(if ($tenantCount -lt 2) { "Revenue evidence is still pilot-sized." }),
        $(if ($systemTruth) { "System truth spine was available during revenue optimization generation." })
    ) -MaxItems 6 -MaxLength 180
}

Write-JsonFile -Path $revenueOptimizationPolicyPath -Data $policy
Write-JsonFile -Path $planFitAnalysisPath -Data $planFitArtifact
Write-JsonFile -Path $upgradeSuggestionsPath -Data $upgradeSuggestionsArtifact
Write-JsonFile -Path $churnRescuePath -Data $churnRescueArtifact
Write-JsonFile -Path $revenueOptimizationPath -Data $revenueOptimizationArtifact
Write-JsonFile -Path $revenueOptimizationRegistryPath -Data $registry

$result = [ordered]@{
    overall_status = $overallStatus
    revenue_optimization_path = $revenueOptimizationPath
    plan_fit_analysis_path = $planFitAnalysisPath
    upgrade_suggestions_path = $upgradeSuggestionsPath
    churn_rescue_path = $churnRescuePath
    registry_path = $revenueOptimizationRegistryPath
    policy_path = $revenueOptimizationPolicyPath
    tenant_count = [int]$tenantCount
    upgrade_opportunity_count = [int]$upgradeSuggestionCount
    add_on_fit_count = [int]$addOnSuggestionCount
    churn_rescue_count = [int]$churnRescueCount
    blocked_money_action_count = [int]$blockedMoneyActionCount
    billing_gated = $billingGated
    recommended_next_action = $revenueOptimizationArtifact.recommended_next_action
}

$result | ConvertTo-Json -Depth 20
