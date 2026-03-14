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
        [int]$MaxItems = 48,
        [int]$MaxLength = 180
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

function Get-StatusFromConfidence {
    param(
        [string]$Confidence,
        [string]$Default = "WARN"
    )

    switch ((Normalize-Text $Confidence).ToLowerInvariant()) {
        "high" { return "PASS" }
        "medium" { return "PASS" }
        "low" { return "WARN" }
        "unknown" { return "WARN" }
        default { return $Default }
    }
}

function Get-ToolRunRecords {
    param([string]$ToolsRoot)

    $records = @()
    if (-not (Test-Path -LiteralPath $ToolsRoot)) {
        return ,@($records)
    }

    $directories = Get-ChildItem -LiteralPath $ToolsRoot -Directory | Sort-Object LastWriteTimeUtc -Descending
    foreach ($directory in $directories) {
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
            tool_id = Normalize-Text (Get-PropValue -Object $tool -Name "tool_id" -Default "")
            tool_name = Normalize-ShortText -Value (Get-PropValue -Object $tool -Name "name" -Default "") -MaxLength 120
            category = Normalize-Text (Get-PropValue -Object $tool -Name "category" -Default "")
            tenant_id = Normalize-Text (Get-PropValue -Object $tenant -Name "tenant_id" -Default "")
            created_at_utc = Normalize-Text (Get-PropValue -Object $artifact -Name "created_at_utc" -Default "")
            summary = Normalize-ShortText -Value (Get-PropValue -Object $output -Name "summary" -Default "") -MaxLength 220
            task_count = @((Get-PropValue -Object $artifact -Name "tasks" -Default @())).Count
            recommendation_count = @((Get-PropValue -Object $artifact -Name "recommendations" -Default @())).Count
            artifact_path = $artifactPath
        }
    }

    return ,@($records)
}

$repoRoot = Resolve-RepoRoot -ExplicitRoot $RepoRoot
$reportsDir = Join-Path $repoRoot "reports"
$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"
$configDir = Join-Path $repoRoot "config"
$onyxStateDir = Join-Path $repoRoot "state\onyx"

$tenantWorkspacePath = Join-Path $onyxStateDir "tenant_workspace.json"
$recommendationsDir = Join-Path $onyxStateDir "recommendations"
$toolRegistryPath = Join-Path $configDir "tool_registry.json"
$billingSummaryPath = Join-Path $reportsDir "billing_summary.json"
$systemTruthPath = Join-Path $reportsDir "system_truth_spine_last.json"
$toolsRoot = Join-Path $reportsDir "tools"

$businessOutcomesPath = Join-Path $reportsDir "business_outcomes_last.json"
$toolUsefulnessPath = Join-Path $reportsDir "tool_usefulness_last.json"
$recommendationEffectivenessPath = Join-Path $reportsDir "recommendation_effectiveness_last.json"
$tenantEngagementPath = Join-Path $reportsDir "tenant_engagement_last.json"
$businessOutcomeRegistryPath = Join-Path $stateKnowledgeDir "business_outcome_registry.json"
$businessOutcomePolicyPath = Join-Path $configDir "business_outcome_policy.json"

$nowUtc = (Get-Date).ToUniversalTime().ToString("o")
$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Business_Outcome_Optimization.ps1"

$policy = [ordered]@{
    version = 1
    policy_name = "business_outcome_optimization"
    outcome_domains = @(
        "time_saved_indicators",
        "tool_usefulness",
        "recommendation_effectiveness",
        "onboarding_completion",
        "tenant_engagement",
        "revenue_help_indicators",
        "churn_risk_indicators"
    )
    evidence_sources = @(
        "tenant workspace and onboarding state",
        "tenant recommendation artifacts",
        "tenant-linked tool run artifacts",
        "tool registry",
        "billing summary and entitlement posture",
        "system truth spine"
    )
    scoring_and_confidence_rules = [ordered]@{
        measured_signal = "A signal backed directly by tool runs, recommendation status records, onboarding completion state, or billing subscription state."
        inferred_signal = "A cautious inference based on linked measured events such as accepted recommendation plus matching tool usage."
        sparse_data_signal = "A low-confidence reading where only one or two weak signals are available."
        unavailable_signal = "No trustworthy local evidence exists for that outcome domain."
    }
    fallback_behavior_for_sparse_data = @(
        "Keep the domain present with low or unknown confidence.",
        "Do not infer precise time saved or revenue lift from sparse pilot data."
    )
    customer_safe_vs_internal_metrics_rules = [ordered]@{
        internal_metrics_may_reference = @("tool IDs", "artifact paths", "recommendation statuses", "billing stub posture")
        customer_safe_outputs_must_avoid = @("internal file paths", "private Mason-only terminology", "unsupported ROI claims")
    }
    tenant_aggregation_rules = @(
        "Aggregate by tenant first, then roll up to platform summaries.",
        "One noisy tenant must not be treated as strong proof of broad product impact."
    )
    churn_risk_rules = @(
        "Incomplete onboarding plus no adoption signal increases churn risk.",
        "Completed onboarding plus recent tool usage lowers churn risk.",
        "Sparse data may yield unknown instead of elevated risk."
    )
    revenue_help_heuristics = @(
        "Accepted and followed-through sales or marketing recommendations can count as possible or positive signal.",
        "Active plan fit plus use of follow-up or growth tools may indicate revenue-supportive behavior, not actual revenue lift."
    )
    low_confidence_handling = @(
        "Low-confidence domains remain WARN, not FAIL.",
        "Unknown churn or revenue signals are allowed when evidence is sparse."
    )
    no_fake_metric_rules = @(
        "Do not invent hours saved.",
        "Do not invent revenue increase.",
        "Do not treat tool existence as usefulness."
    )
}

$tenantWorkspace = Read-JsonSafe -Path $tenantWorkspacePath
$toolRegistry = Read-JsonSafe -Path $toolRegistryPath
$billingSummary = Read-JsonSafe -Path $billingSummaryPath
$systemTruth = Read-JsonSafe -Path $systemTruthPath

$tenantContexts = @((Get-PropValue -Object $tenantWorkspace -Name "contexts" -Default @()))
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
                is_current = [bool](Get-PropValue -Object $recommendation -Name "is_current" -Default $true)
                title = Normalize-ShortText -Value (Get-PropValue -Object $recommendation -Name "title" -Default "") -MaxLength 140
                source_path = $file.FullName
            }
        }
    }
}

$tenantOutcomeRecords = @()
foreach ($context in $tenantContexts) {
    $tenant = Get-PropValue -Object $context -Name "tenant" -Default $null
    $profile = Get-PropValue -Object $context -Name "profile" -Default $null
    $plan = Get-PropValue -Object $context -Name "plan" -Default $null
    $onboarding = Get-PropValue -Object $context -Name "onboarding" -Default $null
    $tenantId = Normalize-Text (Get-PropValue -Object $tenant -Name "id" -Default "")
    if (-not $tenantId) {
        continue
    }

    $tenantToolRuns = @($toolRuns | Where-Object { (Normalize-Text $_.tenant_id) -eq $tenantId })
    $tenantRecommendations = @($recommendationRecords | Where-Object { (Normalize-Text $_.tenant_id) -eq $tenantId })
    $acceptedRecommendations = @($tenantRecommendations | Where-Object { (Normalize-Text $_.status) -eq "accepted" })
    $dismissedRecommendations = @($tenantRecommendations | Where-Object { (Normalize-Text $_.status) -in @("dismissed", "rejected") })
    $pendingRecommendations = @($tenantRecommendations | Where-Object { (Normalize-Text $_.status) -in @("new", "seen") })

    $distinctToolsUsed = @($tenantToolRuns | ForEach-Object { $_.tool_id } | Where-Object { $_ } | Sort-Object -Unique)
    $onboardingComplete = [bool](Get-PropValue -Object $onboarding -Name "isCompleted" -Default $false)
    $completionPercent = [int](Get-PropValue -Object $onboarding -Name "completionPercent" -Default 0)
    $planTier = Normalize-Text (Get-PropValue -Object $plan -Name "currentTier" -Default "")
    $billingTenant = Get-PropValue -Object $billingSummary -Name "tenant" -Default $null
    $billingStatus = Normalize-Text (Get-PropValue -Object $billingTenant -Name "status" -Default "")

    $toolAdoptionSignal = "unknown"
    if ($tenantToolRuns.Count -ge 2 -or $distinctToolsUsed.Count -ge 2) {
        $toolAdoptionSignal = "medium_signal"
    }
    elseif ($tenantToolRuns.Count -eq 1) {
        $toolAdoptionSignal = "low_signal"
    }
    elseif ($onboardingComplete) {
        $toolAdoptionSignal = "no_signal"
    }

    $recommendationResponseSignal = "unknown"
    if (($acceptedRecommendations.Count + $dismissedRecommendations.Count) -ge 2) {
        $recommendationResponseSignal = "medium_signal"
    }
    elseif (($acceptedRecommendations.Count + $dismissedRecommendations.Count) -eq 1) {
        $recommendationResponseSignal = "low_signal"
    }
    elseif ($pendingRecommendations.Count -gt 0) {
        $recommendationResponseSignal = "low_signal"
    }

    $followThroughCount = 0
    foreach ($acceptedRecommendation in $acceptedRecommendations) {
        $linkedToolId = Normalize-Text (Get-PropValue -Object $acceptedRecommendation -Name "linked_tool_id" -Default "")
        if ($linkedToolId -and @($tenantToolRuns | Where-Object { (Normalize-Text $_.tool_id) -eq $linkedToolId }).Count -gt 0) {
            $followThroughCount += 1
        }
    }

    $revenueHelpSignal = "unknown"
    if ($followThroughCount -gt 0) {
        $revenueHelpSignal = "possible_signal"
    }
    if (@($tenantToolRuns | Where-Object { (Normalize-Text $_.category) -in @("sales", "marketing") }).Count -gt 0 -and $billingStatus -eq "active") {
        $revenueHelpSignal = "positive_signal"
    }
    elseif ($onboardingComplete -and $planTier) {
        $revenueHelpSignal = "possible_signal"
    }

    $churnRiskClassification = "unknown"
    if ($onboardingComplete -and $tenantToolRuns.Count -gt 0 -and $billingStatus -eq "active") {
        $churnRiskClassification = "low"
    }
    elseif (-not $onboardingComplete -and $tenantToolRuns.Count -eq 0) {
        $churnRiskClassification = "elevated"
    }
    elseif ($onboardingComplete -or $pendingRecommendations.Count -gt 0) {
        $churnRiskClassification = "moderate"
    }

    $engagementClassification = "unknown"
    if ($onboardingComplete -and ($tenantToolRuns.Count -gt 0 -or ($acceptedRecommendations.Count + $dismissedRecommendations.Count) -gt 0)) {
        $engagementClassification = "active"
    }
    elseif ($completionPercent -gt 0) {
        $engagementClassification = "light"
    }
    elseif ($pendingRecommendations.Count -gt 0) {
        $engagementClassification = "light"
    }
    else {
        $engagementClassification = "low"
    }

    $confidenceScore = 0.20
    if ($onboardingComplete) { $confidenceScore += 0.20 }
    if ($tenantToolRuns.Count -gt 0) { $confidenceScore += 0.25 }
    if (($acceptedRecommendations.Count + $dismissedRecommendations.Count + $pendingRecommendations.Count) -gt 0) { $confidenceScore += 0.20 }
    if ($billingStatus) { $confidenceScore += 0.15 }
    if ($followThroughCount -gt 0) { $confidenceScore += 0.10 }
    if ($planTier) { $confidenceScore += 0.10 }
    if ($confidenceScore -gt 1.0) { $confidenceScore = 1.0 }

    $tenantOutcomeRecords += [pscustomobject]@{
        tenant_id = $tenantId
        business_name = Normalize-ShortText -Value (Get-PropValue -Object $profile -Name "businessName" -Default "") -MaxLength 120
        engagement_classification = $engagementClassification
        onboarding_status = if ($onboardingComplete) { "completed" } elseif ($completionPercent -gt 0) { "in_progress" } else { "unknown" }
        tool_adoption_signal = $toolAdoptionSignal
        recommendation_response_signal = $recommendationResponseSignal
        revenue_help_signal = $revenueHelpSignal
        churn_risk_classification = $churnRiskClassification
        confidence = Get-ConfidenceLabel -Score $confidenceScore
        tool_run_count = $tenantToolRuns.Count
        distinct_tool_count = $distinctToolsUsed.Count
        accepted_recommendation_count = $acceptedRecommendations.Count
        dismissed_recommendation_count = $dismissedRecommendations.Count
        pending_recommendation_count = $pendingRecommendations.Count
        followthrough_count = $followThroughCount
        enabled_feature_count = @((Get-PropValue -Object $plan -Name "enabledFeatures" -Default @())).Count
        notes = Normalize-ShortText -Value ("Onboarding {0}; tool runs {1}; accepted recommendations {2}; dismissed {3}." -f $(if ($onboardingComplete) { "completed" } else { "not completed" }), $tenantToolRuns.Count, $acceptedRecommendations.Count, $dismissedRecommendations.Count) -MaxLength 220
    }
}

$toolUsefulnessRecords = @()
foreach ($tool in $tools) {
    $toolId = Normalize-Text (Get-PropValue -Object $tool -Name "tool_id" -Default "")
    if (-not $toolId) {
        continue
    }

    $toolRunsForTool = @($toolRuns | Where-Object { (Normalize-Text $_.tool_id) -eq $toolId })
    $recommendationsForTool = @($recommendationRecords | Where-Object { (Normalize-Text $_.linked_tool_id) -eq $toolId })
    $acceptedForTool = @($recommendationsForTool | Where-Object { (Normalize-Text $_.status) -eq "accepted" })
    $dismissedForTool = @($recommendationsForTool | Where-Object { (Normalize-Text $_.status) -in @("dismissed", "rejected") })
    $tenantCountAffected = @($toolRunsForTool | ForEach-Object { $_.tenant_id } | Where-Object { $_ } | Sort-Object -Unique).Count

    $usageSignal = "unknown"
    if ($toolRunsForTool.Count -ge 2) {
        $usageSignal = "high_signal"
    }
    elseif ($toolRunsForTool.Count -eq 1) {
        $usageSignal = "medium_signal"
    }
    elseif ($recommendationsForTool.Count -gt 0) {
        $usageSignal = "low_signal"
    }

    $usefulnessClassification = "not_enough_data"
    if ($toolRunsForTool.Count -gt 0 -and ($acceptedForTool.Count -gt 0 -or $toolRunsForTool.Count -gt 1)) {
        $usefulnessClassification = "useful"
    }
    elseif ($toolRunsForTool.Count -gt 0) {
        $usefulnessClassification = "unclear"
    }
    elseif ($recommendationsForTool.Count -gt 0) {
        $usefulnessClassification = "underused"
    }

    $confidenceScore = 0.10
    if ($toolRunsForTool.Count -gt 0) { $confidenceScore += 0.45 }
    if ($acceptedForTool.Count -gt 0 -or $dismissedForTool.Count -gt 0) { $confidenceScore += 0.25 }
    if ([bool](Get-PropValue -Object $tool -Name "enabled" -Default $false)) { $confidenceScore += 0.15 }
    if ($tenantCountAffected -gt 0) { $confidenceScore += 0.10 }
    if ($confidenceScore -gt 1.0) { $confidenceScore = 1.0 }

    $toolUsefulnessRecords += [pscustomobject]@{
        tool_id = $toolId
        usage_signal = $usageSignal
        usefulness_classification = $usefulnessClassification
        confidence = Get-ConfidenceLabel -Score $confidenceScore
        tenant_count_affected = [int]$tenantCountAffected
        notes = Normalize-ShortText -Value ("Runs={0}; accepted_recommendations={1}; dismissed_recommendations={2}." -f $toolRunsForTool.Count, $acceptedForTool.Count, $dismissedForTool.Count) -MaxLength 220
    }
}

$recommendationTypeRecords = @()
foreach ($typeName in @($recommendationRecords | ForEach-Object { $_.recommendation_type } | Where-Object { $_ } | Sort-Object -Unique)) {
    $typeRecords = @($recommendationRecords | Where-Object { (Normalize-Text $_.recommendation_type) -eq $typeName })
    $accepted = @($typeRecords | Where-Object { (Normalize-Text $_.status) -eq "accepted" }).Count
    $rejected = @($typeRecords | Where-Object { (Normalize-Text $_.status) -in @("dismissed", "rejected") }).Count
    $pending = @($typeRecords | Where-Object { (Normalize-Text $_.status) -in @("new", "seen") }).Count

    $classification = "not_enough_data"
    if ($accepted -gt 0 -and $rejected -eq 0) {
        $classification = "effective"
    }
    elseif ($accepted -gt 0 -and $rejected -gt 0) {
        $classification = "mixed"
    }
    elseif ($rejected -gt 0) {
        $classification = "needs_refinement"
    }

    $confidenceScore = 0.15
    if (($accepted + $rejected + $pending) -ge 2) { $confidenceScore += 0.35 }
    if ($accepted -gt 0 -or $rejected -gt 0) { $confidenceScore += 0.25 }
    if ($pending -gt 0) { $confidenceScore += 0.10 }
    if ($confidenceScore -gt 1.0) { $confidenceScore = 1.0 }

    $recommendationTypeRecords += [pscustomobject]@{
        recommendation_type = $typeName
        acceptance_signal = [int]$accepted
        rejection_signal = [int]$rejected
        effectiveness_classification = $classification
        confidence = Get-ConfidenceLabel -Score $confidenceScore
        refinement_needed = [bool]($rejected -gt 0)
    }
}

$tenantCount = $tenantOutcomeRecords.Count
$tenantsWithMeasurableSignals = @($tenantOutcomeRecords | Where-Object {
    (Normalize-Text $_.tool_adoption_signal) -ne "unknown" -or
    (Normalize-Text $_.recommendation_response_signal) -ne "unknown" -or
    (Normalize-Text $_.revenue_help_signal) -ne "unknown"
}).Count

$activeSignalCount = @($tenantOutcomeRecords | Where-Object { (Normalize-Text $_.engagement_classification) -eq "active" }).Count
$lowEngagementCount = @($tenantOutcomeRecords | Where-Object { (Normalize-Text $_.engagement_classification) -eq "low" }).Count
$onboardingCompleteCount = @($tenantOutcomeRecords | Where-Object { (Normalize-Text $_.onboarding_status) -eq "completed" }).Count
$onboardingIncompleteCount = @($tenantOutcomeRecords | Where-Object { (Normalize-Text $_.onboarding_status) -ne "completed" }).Count
$churnRiskCount = @($tenantOutcomeRecords | Where-Object { (Normalize-Text $_.churn_risk_classification) -in @("moderate", "elevated") }).Count

$acceptedRecommendationCount = @($recommendationRecords | Where-Object { (Normalize-Text $_.status) -eq "accepted" }).Count
$rejectedRecommendationCount = @($recommendationRecords | Where-Object { (Normalize-Text $_.status) -in @("dismissed", "rejected") }).Count
$pendingRecommendationCount = @($recommendationRecords | Where-Object { (Normalize-Text $_.status) -in @("new", "seen") }).Count
$singleTenantSample = ($tenantCount -lt 2)
$limitedRecommendationEvidence = (($acceptedRecommendationCount + $rejectedRecommendationCount + $pendingRecommendationCount) -lt 3)
$limitedWorkflowEvidence = ($toolRuns.Count -lt 3)

$timeSavedClassification = "unknown"
if (@($tenantOutcomeRecords | Where-Object { $_.followthrough_count -gt 0 }).Count -gt 0 -and $toolRuns.Count -ge 2) {
    $timeSavedClassification = "medium_signal"
}
elseif ($toolRuns.Count -gt 0) {
    $timeSavedClassification = "low_signal"
}

$timeSavedConfidenceScore = 0.10
if ($toolRuns.Count -gt 0) { $timeSavedConfidenceScore += 0.30 }
if (@($tenantOutcomeRecords | Where-Object { $_.followthrough_count -gt 0 }).Count -gt 0) { $timeSavedConfidenceScore += 0.25 }
if ($tenantCount -gt 1) { $timeSavedConfidenceScore += 0.15 }
if ($singleTenantSample) { $timeSavedConfidenceScore = [Math]::Min($timeSavedConfidenceScore, 0.30) }
if ($limitedWorkflowEvidence) { $timeSavedConfidenceScore = [Math]::Min($timeSavedConfidenceScore, 0.40) }
if ($timeSavedConfidenceScore -gt 1.0) { $timeSavedConfidenceScore = 1.0 }
$timeSavedConfidence = Get-ConfidenceLabel -Score $timeSavedConfidenceScore

$toolUsefulnessSummaryText = if (@($toolUsefulnessRecords | Where-Object { (Normalize-Text $_.usefulness_classification) -eq "useful" }).Count -gt 0) {
    "Some tools show real usefulness signal, but usage remains sparse."
} else {
    "Tool usefulness remains sparse or unclear."
}

$recommendationEffectivenessClassification = "not_enough_data"
if ($acceptedRecommendationCount -gt 0 -and $rejectedRecommendationCount -gt 0) {
    $recommendationEffectivenessClassification = "mixed"
}
elseif ($acceptedRecommendationCount -gt 0) {
    $recommendationEffectivenessClassification = "effective"
}
elseif ($rejectedRecommendationCount -gt 0) {
    $recommendationEffectivenessClassification = "needs_refinement"
}

$recommendationEffectivenessConfidenceScore = if ($recommendationRecords.Count -ge 3) { 0.65 } elseif ($recommendationRecords.Count -gt 0) { 0.40 } else { 0.0 }
if ($singleTenantSample) { $recommendationEffectivenessConfidenceScore = [Math]::Min($recommendationEffectivenessConfidenceScore, 0.40) }
if ($limitedRecommendationEvidence) { $recommendationEffectivenessConfidenceScore = [Math]::Min($recommendationEffectivenessConfidenceScore, 0.40) }
$recommendationEffectivenessConfidence = Get-ConfidenceLabel -Score $recommendationEffectivenessConfidenceScore
$revenueHelpClassification = if (@($tenantOutcomeRecords | Where-Object { (Normalize-Text $_.revenue_help_signal) -eq "positive_signal" }).Count -gt 0) { "positive_signal" } elseif (@($tenantOutcomeRecords | Where-Object { (Normalize-Text $_.revenue_help_signal) -eq "possible_signal" }).Count -gt 0) { "possible_signal" } else { "unknown" }
$revenueHelpConfidenceScore = if ($acceptedRecommendationCount -gt 0 -and $toolRuns.Count -gt 0) { 0.45 } else { 0.20 }
if ($singleTenantSample) { $revenueHelpConfidenceScore = [Math]::Min($revenueHelpConfidenceScore, 0.30) }
$revenueHelpConfidence = Get-ConfidenceLabel -Score $revenueHelpConfidenceScore
$churnSummaryClassification = if ($churnRiskCount -eq 0 -and $tenantCount -gt 0) { "low" } elseif (@($tenantOutcomeRecords | Where-Object { (Normalize-Text $_.churn_risk_classification) -eq "elevated" }).Count -gt 0) { "elevated" } elseif ($churnRiskCount -gt 0) { "moderate" } else { "unknown" }
$churnConfidence = Get-ConfidenceLabel -Score $(if ($tenantCount -gt 0) { 0.60 } else { 0.10 })

$businessOutcomeDomains = [ordered]@{
    time_saved_indicators = [ordered]@{
        classification = $timeSavedClassification
        confidence = $timeSavedConfidence
        summary = Normalize-ShortText -Value ("Tool runs={0}; accepted recommendation follow-through tenants={1}; no precise hours claimed." -f $toolRuns.Count, @($tenantOutcomeRecords | Where-Object { $_.followthrough_count -gt 0 }).Count) -MaxLength 220
        measured_signal_count = $toolRuns.Count
        recommended_next_action = "Collect more repeated tenant workflow completions before making stronger time-saved claims."
    }
    tool_usefulness = [ordered]@{
        classification = if (@($toolUsefulnessRecords | Where-Object { (Normalize-Text $_.usefulness_classification) -eq "useful" }).Count -gt 0) { "measurable" } else { "sparse" }
        confidence = Get-ConfidenceLabel -Score $(if ($toolUsefulnessRecords.Count -gt 0) { $(if ($singleTenantSample) { 0.40 } else { 0.55 }) } else { 0.0 })
        summary = $toolUsefulnessSummaryText
        useful_tool_count = @($toolUsefulnessRecords | Where-Object { (Normalize-Text $_.usefulness_classification) -eq "useful" }).Count
        underused_tool_count = @($toolUsefulnessRecords | Where-Object { (Normalize-Text $_.usefulness_classification) -eq "underused" }).Count
    }
    recommendation_effectiveness = [ordered]@{
        classification = $recommendationEffectivenessClassification
        confidence = $recommendationEffectivenessConfidence
        summary = Normalize-ShortText -Value ("Accepted={0}; dismissed={1}; pending={2}." -f $acceptedRecommendationCount, $rejectedRecommendationCount, $pendingRecommendationCount) -MaxLength 220
        recommended_next_action = "Refine wording or timing where recommendations are dismissed, and keep measuring follow-through."
    }
    onboarding_completion = [ordered]@{
        classification = if ($onboardingCompleteCount -eq $tenantCount -and $tenantCount -gt 0) { "completed" } elseif ($onboardingCompleteCount -gt 0) { "mixed" } else { "low_signal" }
        confidence = Get-ConfidenceLabel -Score $(if ($tenantCount -gt 0) { 0.80 } else { 0.0 })
        summary = Normalize-ShortText -Value ("Completed={0}; incomplete={1}." -f $onboardingCompleteCount, $onboardingIncompleteCount) -MaxLength 220
    }
    tenant_engagement = [ordered]@{
        classification = if ($activeSignalCount -gt 0) { "active_signal_present" } elseif ($tenantCount -gt 0) { "low_signal" } else { "unknown" }
        confidence = Get-ConfidenceLabel -Score $(if ($tenantCount -gt 0) { 0.65 } else { 0.0 })
        summary = Normalize-ShortText -Value ("Active tenants={0}; low engagement={1}." -f $activeSignalCount, $lowEngagementCount) -MaxLength 220
    }
    revenue_help_indicators = [ordered]@{
        classification = $revenueHelpClassification
        confidence = $revenueHelpConfidence
        summary = Normalize-ShortText -Value ("Revenue-help remains behavior-level only; accepted follow-through plus sales/marketing usage are treated as signal, not revenue proof.") -MaxLength 220
        recommended_next_action = "Keep tracking sales or marketing tool follow-through before claiming stronger revenue help."
    }
    churn_risk_indicators = [ordered]@{
        classification = $churnSummaryClassification
        confidence = $churnConfidence
        summary = Normalize-ShortText -Value ("Moderate-or-higher churn risk tenants={0}; completed onboarding tenants={1}." -f $churnRiskCount, $onboardingCompleteCount) -MaxLength 220
        recommended_next_action = "Watch tenants with weak adoption or incomplete onboarding for disengagement."
    }
}

$lowConfidenceDomainCount = @($businessOutcomeDomains.GetEnumerator() | Where-Object { (Normalize-Text $_.Value.confidence) -in @("low", "unknown") }).Count
$overallOutcomeStatus = if ($tenantCount -eq 0) { "WARN" } elseif ($singleTenantSample) { "WARN" } elseif ($lowConfidenceDomainCount -gt 0) { "WARN" } else { "PASS" }
$overallRecommendedNextAction = if ($singleTenantSample) {
    "Keep this outcome layer in pilot mode until more than one tenant produces repeated adoption and follow-through evidence."
}
elseif ($lowConfidenceDomainCount -gt 0) {
    "Collect more tenant usage and follow-through evidence before treating these business outcome signals as strong proof."
}
else {
    "Continue measuring adoption, onboarding, and recommendation follow-through as more tenants are added."
}

$toolUsefulnessArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = if ($singleTenantSample) { "WARN" } elseif (@($toolUsefulnessRecords | Where-Object { (Normalize-Text $_.usefulness_classification) -eq "useful" }).Count -gt 0) { "PASS" } else { "WARN" }
    tool_total = $toolUsefulnessRecords.Count
    tools_with_usage_signal = @($toolUsefulnessRecords | Where-Object { (Normalize-Text $_.usage_signal) -in @("high_signal", "medium_signal", "low_signal") }).Count
    tools_with_usefulness_signal = @($toolUsefulnessRecords | Where-Object { (Normalize-Text $_.usefulness_classification) -ne "not_enough_data" }).Count
    per_tool_usefulness = @($toolUsefulnessRecords)
    recommended_next_action = "Keep comparing shown tools against real usage so underused tools can be improved or hidden."
    command_run = $commandRun
    repo_root = $repoRoot
}

$recommendationEffectivenessArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = if ($singleTenantSample) { "WARN" } elseif ($recommendationEffectivenessClassification -eq "effective") { "PASS" } else { "WARN" }
    recommendation_total = $recommendationRecords.Count
    accepted_count = [int]$acceptedRecommendationCount
    rejected_count = [int]$rejectedRecommendationCount
    pending_count = [int]$pendingRecommendationCount
    low_confidence_count = @($recommendationTypeRecords | Where-Object { (Normalize-Text $_.confidence) -in @("low", "unknown") }).Count
    effectiveness_summary = Normalize-ShortText -Value ("{0}; accepted={1}; dismissed={2}; pending={3}." -f $recommendationEffectivenessClassification, $acceptedRecommendationCount, $rejectedRecommendationCount, $pendingRecommendationCount) -MaxLength 220
    recommended_next_action = "Use dismissed recommendations as fit or wording feedback, not as proof the recommendation system is worthless."
    recommendation_type_records = @($recommendationTypeRecords)
    command_run = $commandRun
    repo_root = $repoRoot
}

$tenantEngagementArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = if ($activeSignalCount -gt 0) { "PASS" } else { "WARN" }
    tenant_count = $tenantCount
    active_signal_count = [int]$activeSignalCount
    low_engagement_count = [int]$lowEngagementCount
    onboarding_complete_count = [int]$onboardingCompleteCount
    onboarding_incomplete_count = [int]$onboardingIncompleteCount
    churn_risk_count = [int]$churnRiskCount
    recommended_next_action = "Keep monitoring weak-adoption tenants before concluding churn risk is truly low."
    tenants = @($tenantOutcomeRecords)
    command_run = $commandRun
    repo_root = $repoRoot
}

$businessOutcomesArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $overallOutcomeStatus
    tenant_count = $tenantCount
    tenants_with_measurable_signals = [int]$tenantsWithMeasurableSignals
    outcome_domain_count = 7
    low_confidence_domain_count = [int]$lowConfidenceDomainCount
    recommended_next_action = $overallRecommendedNextAction
    summary = [ordered]@{
        top_measured_strengths = @(
            "Onboarding completion is measurable from current tenant workspace state.",
            "Tool usefulness now reflects actual tenant-linked tool runs instead of registry counts.",
            "Recommendation effectiveness is grounded in accepted, dismissed, and pending statuses."
        )
        caution_areas = @(
            "Business outcome evidence is still pilot-sized and based on one active tenant.",
            "Revenue-help remains a behavior signal, not revenue proof.",
            "Time-saved remains conservative because no precise labor-time evidence exists.",
            "The current sample size is a single active tenant."
        )
    }
    time_saved_indicators = $businessOutcomeDomains.time_saved_indicators
    tool_usefulness = $businessOutcomeDomains.tool_usefulness
    recommendation_effectiveness = $businessOutcomeDomains.recommendation_effectiveness
    onboarding_completion = $businessOutcomeDomains.onboarding_completion
    tenant_engagement = $businessOutcomeDomains.tenant_engagement
    revenue_help_indicators = $businessOutcomeDomains.revenue_help_indicators
    churn_risk_indicators = $businessOutcomeDomains.churn_risk_indicators
    command_run = $commandRun
    repo_root = $repoRoot
}

$registryArtifact = [ordered]@{
    generated_at_utc = $nowUtc
    overall_status = $overallOutcomeStatus
    latest_business_outcomes_artifact = $businessOutcomesPath
    tenant_count = $tenantCount
    tool_count = $toolUsefulnessRecords.Count
    outcome_domain_count = 7
    current_summary_status = $overallOutcomeStatus
    notes = Normalize-ShortText -Value "Outcome layer is conservative and pilot-sized; current signals come from one active tenant plus recommendation and tool-run evidence." -MaxLength 220
}

Write-JsonFile -Path $businessOutcomePolicyPath -Data $policy
Write-JsonFile -Path $toolUsefulnessPath -Data $toolUsefulnessArtifact
Write-JsonFile -Path $recommendationEffectivenessPath -Data $recommendationEffectivenessArtifact
Write-JsonFile -Path $tenantEngagementPath -Data $tenantEngagementArtifact
Write-JsonFile -Path $businessOutcomesPath -Data $businessOutcomesArtifact
Write-JsonFile -Path $businessOutcomeRegistryPath -Data $registryArtifact

$output = [ordered]@{
    ok = $true
    overall_status = $overallOutcomeStatus
    tenant_count = $tenantCount
    tenants_with_measurable_signals = [int]$tenantsWithMeasurableSignals
    low_confidence_domain_count = [int]$lowConfidenceDomainCount
    business_outcomes_artifact = $businessOutcomesPath
    tool_usefulness_artifact = $toolUsefulnessPath
    recommendation_effectiveness_artifact = $recommendationEffectivenessPath
    tenant_engagement_artifact = $tenantEngagementPath
    registry_artifact = $businessOutcomeRegistryPath
    policy_artifact = $businessOutcomePolicyPath
}

$output | ConvertTo-Json -Depth 20
