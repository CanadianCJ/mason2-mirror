[CmdletBinding()]
param(
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Normalize-Text {
    param($Value)
    return [regex]::Replace(([string]$Value), "\s+", " ").Trim()
}

function Limit-Text {
    param(
        [string]$Text,
        [int]$MaxLength = 400
    )

    $value = [string]$Text
    if ($value.Length -le $MaxLength) {
        return $value
    }
    return $value.Substring(0, $MaxLength).TrimEnd()
}

function Ensure-Parent {
    param([Parameter(Mandatory = $true)][string]$Path)
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Read-JsonSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        $Default = $null
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $Default
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if (-not $raw.Trim()) {
            return $Default
        }
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $Default
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 20
    )

    Ensure-Parent -Path $Path
    $Object | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-RepoRoot {
    param([string]$OverrideRoot)

    if ($OverrideRoot -and (Test-Path -LiteralPath $OverrideRoot)) {
        return (Resolve-Path -LiteralPath $OverrideRoot).Path
    }

    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Get-PropValue {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string]$Name,
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
    if ($property) {
        return $property.Value
    }

    return $Default
}

function Convert-ToPlainData {
    param($Value)

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [string] -or $Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal] -or $Value -is [bool] -or $Value -is [datetime]) {
        return $Value
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $map = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $map[[string]$key] = Convert-ToPlainData -Value $Value[$key]
        }
        return $map
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $items = @()
        foreach ($item in $Value) {
            $items += @(Convert-ToPlainData -Value $item)
        }
        return $items
    }

    $properties = @($Value.PSObject.Properties)
    if ($properties.Count -gt 0) {
        $map = [ordered]@{}
        foreach ($property in $properties) {
            $map[[string]$property.Name] = Convert-ToPlainData -Value $property.Value
        }
        return $map
    }

    return [string]$Value
}

function Merge-Maps {
    param(
        [Parameter(Mandatory = $true)]$Base,
        [Parameter(Mandatory = $true)]$Override
    )

    $left = Convert-ToPlainData -Value $Base
    $right = Convert-ToPlainData -Value $Override

    if (-not ($left -is [System.Collections.IDictionary])) {
        return $right
    }
    if (-not ($right -is [System.Collections.IDictionary])) {
        return $left
    }

    foreach ($key in $right.Keys) {
        if ($left.Contains($key) -and $left[$key] -is [System.Collections.IDictionary] -and $right[$key] -is [System.Collections.IDictionary]) {
            $left[$key] = Merge-Maps -Base $left[$key] -Override $right[$key]
        }
        else {
            $left[$key] = $right[$key]
        }
    }

    return $left
}

function Get-List {
    param($Value)

    if ($null -eq $Value) {
        return @()
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        return @($Value)
    }

    return @($Value)
}

function Get-DefaultPolicy {
    return [ordered]@{
        version                                = 1
        generated_at_utc                       = ""
        policy_name                            = "self_improvement_governor"
        local_first_mandatory                  = $true
        teacher_calls_enabled                  = $true
        cost_sensitivity                       = "guarded"
        minimum_teacher_quality_score          = 70
        minimum_teacher_quality_classification = "queue_for_review"
        local_first_sources                    = @("runtime", "self-heal", "manual", "owner", "recommendation")
        teacher_optional_sources               = @("recommendation", "owner")
        teacher_focus_sources                  = @("competitor", "tool-gap")
        blocked_target_types                   = @("billing", "security")
        blocked_keywords                       = @("billing", "payment", "pricing", "stripe", "subscription", "webhook", "secret", "credential", "token", "password", "api key", "firewall", "registry", "network exposure")
        score_thresholds                       = [ordered]@{
            trivial_local_only_max_difficulty    = 30
            local_first_optional_min_fallback    = 65
            teacher_low_cost_min_expected_value  = 55
            teacher_standard_min_expected_value  = 70
            teacher_high_value_min_expected_value = 85
            safe_to_stage_min_quality            = 78
            safe_to_test_min_quality             = 88
        }
        cost_tiers                             = [ordered]@{
            low_usd      = 5
            standard_usd = 15
            high_usd     = 30
        }
        blocked_conditions                     = [ordered]@{
            money_actions_require_human_gate      = $true
            credential_and_secret_changes_blocked = $true
            risky_external_actions_blocked        = $true
            medium_or_higher_risk_needs_review    = $true
            security_and_billing_teacher_blocked  = $true
        }
        execution_disposition_rules            = [ordered]@{
            allow_safe_to_stage_max_risk                  = "R1"
            allow_safe_to_test_requires_auto_allowed_behavior = $true
            default_high_risk_disposition                 = "approval_required"
            default_unknown_disposition                   = "suggest_only"
        }
    }
}

function Get-UtcTimestamp {
    return ([datetime]::UtcNow.ToString("o"))
}

function Get-RiskScore {
    param([string]$RiskLevel)

    switch ((Normalize-Text $RiskLevel).ToUpperInvariant()) {
        "R0" { return 10 }
        "R1" { return 25 }
        "R2" { return 55 }
        "R3" { return 80 }
        "R4" { return 95 }
        default { return 60 }
    }
}

function Get-BehaviorRiskScore {
    param([string]$RiskLevel)

    switch ((Normalize-Text $RiskLevel).ToLowerInvariant()) {
        "low" { return 25 }
        "medium" { return 55 }
        "high" { return 80 }
        "critical" { return 95 }
        default { return 45 }
    }
}

function Get-TargetBaseDifficulty {
    param([string]$TargetType)

    switch ((Normalize-Text $TargetType).ToLowerInvariant()) {
        "mason" { return 40 }
        "onyx" { return 50 }
        "athena" { return 55 }
        "tool" { return 55 }
        "system" { return 70 }
        "security" { return 85 }
        "billing" { return 85 }
        "business" { return 35 }
        default { return 45 }
    }
}

function Get-KeywordSet {
    param([string[]]$Values)

    $tokens = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($value in @($Values)) {
        foreach ($token in [regex]::Matches((Normalize-Text $value).ToLowerInvariant(), "[a-z0-9_]{3,}")) {
            [void]$tokens.Add($token.Value)
        }
    }
    return $tokens
}

function Test-ActionPathExists {
    param(
        [string]$RepoRoot,
        [string]$ActionText
    )

    $text = Normalize-Text $ActionText
    if (-not $text) {
        return $false
    }

    $candidate = ""
    if ($text -match "^(EDIT|TEST)\s+([^:]+)") {
        $candidate = $matches[2]
    }
    elseif ($text -match "\.\\([^\s]+)") {
        $candidate = $matches[1]
    }

    $candidate = $candidate.Trim('"', "'", " ")
    if (-not $candidate) {
        return $false
    }

    $candidate = $candidate -replace "^\.[\\/]", ""
    $candidate = $candidate -replace "/", "\"
    $candidate = $candidate.Trim()
    if (-not $candidate) {
        return $false
    }

    $fullPath = Join-Path $RepoRoot $candidate
    return (Test-Path -LiteralPath $fullPath)
}

function Get-TeacherResponseReview {
    param(
        [string]$RepoRoot,
        $Step,
        [System.Collections.Generic.HashSet[string]]$ActiveDomains,
        [System.Collections.Generic.HashSet[string]]$ActiveKeywords
    )

    $domain = Normalize-Text (Get-PropValue -Object $Step -Name "domain" -Default "")
    $area = Normalize-Text (Get-PropValue -Object $Step -Name "area" -Default "")
    $title = Normalize-Text (Get-PropValue -Object $Step -Name "title" -Default "")
    $description = Normalize-Text (Get-PropValue -Object $Step -Name "description" -Default "")
    $actions = @(Get-List (Get-PropValue -Object $Step -Name "actions" -Default @()))
    $requiresHumanApproval = [bool](Get-PropValue -Object $Step -Name "requires_human_approval" -Default $true)
    $actionPathHits = 0
    $hasEditAction = $false
    $hasTestAction = $false
    foreach ($action in $actions) {
        $actionText = Normalize-Text $action
        if ($actionText -match "^EDIT\s+") {
            $hasEditAction = $true
        }
        if ($actionText -match "^TEST\s+" -or $actionText -match "\bflutter test\b" -or $actionText -match "\bpowershell\b") {
            $hasTestAction = $true
        }
        if (Test-ActionPathExists -RepoRoot $RepoRoot -ActionText $actionText) {
            $actionPathHits += 1
        }
    }

    $stepKeywords = Get-KeywordSet -Values @($domain, $area, $title, $description)
    $keywordOverlap = 0
    foreach ($token in $stepKeywords) {
        if ($ActiveKeywords.Contains($token)) {
            $keywordOverlap += 1
        }
    }

    $specificity = 25
    if ($title) { $specificity += 15 }
    if ($area) { $specificity += 10 }
    if ($actions.Count -gt 0) { $specificity += [Math]::Min(25, ($actions.Count * 8)) }
    if ($description.Length -ge 80) { $specificity += 15 }
    $specificity = [Math]::Min(100, $specificity)

    $actionability = 10
    if ($hasEditAction) { $actionability += 30 }
    if ($hasTestAction) { $actionability += 25 }
    if ($actions.Count -gt 1) { $actionability += 15 }
    if ($requiresHumanApproval) { $actionability += 5 }
    $actionability = [Math]::Min(100, $actionability)

    $grounding = 5
    if ($actionPathHits -gt 0 -and $actions.Count -gt 0) {
        $grounding += [Math]::Round((100 * $actionPathHits) / $actions.Count * 0.6)
    }
    if ($domain -and $ActiveDomains.Contains($domain.ToLowerInvariant())) {
        $grounding += 15
    }
    if ($keywordOverlap -gt 0) {
        $grounding += [Math]::Min(20, $keywordOverlap * 4)
    }
    $grounding = [Math]::Min(100, $grounding)

    $relevance = 10
    if ($domain -and $ActiveDomains.Contains($domain.ToLowerInvariant())) {
        $relevance += 35
    }
    if ($keywordOverlap -gt 0) {
        $relevance += [Math]::Min(35, $keywordOverlap * 5)
    }
    $relevance = [Math]::Min(100, $relevance)

    $implementationSafety = 90
    $combinedText = "{0} {1} {2}" -f $title, $description, ($actions -join " ")
    foreach ($riskyTerm in @("delete", "disable", "registry", "privilege", "permission", "encrypted config", "restricted user context")) {
        if ($combinedText.ToLowerInvariant().Contains($riskyTerm)) {
            $implementationSafety -= 20
        }
    }
    if (-not $hasTestAction) {
        $implementationSafety -= 20
    }
    if ($actions.Count -gt 0 -and $actionPathHits -eq 0) {
        $implementationSafety -= 20
    }
    $implementationSafety = [Math]::Max(0, [Math]::Min(100, $implementationSafety))

    $expectedUpside = 25
    if ($domain -and $ActiveDomains.Contains($domain.ToLowerInvariant())) {
        $expectedUpside += 25
    }
    if ($keywordOverlap -gt 1) {
        $expectedUpside += [Math]::Min(25, $keywordOverlap * 4)
    }
    if ($hasTestAction) {
        $expectedUpside += 10
    }
    $expectedUpside = [Math]::Min(100, $expectedUpside)

    $totalScore = [Math]::Round((($specificity + $actionability + $grounding + $relevance + $implementationSafety + $expectedUpside) / 6), 2)
    $classification = "keep_for_reference"
    if ($grounding -lt 25 -or $implementationSafety -lt 35 -or $totalScore -lt 45) {
        $classification = "reject"
    }
    elseif ($totalScore -ge 85 -and $grounding -ge 60 -and $implementationSafety -ge 70) {
        $classification = "safe_to_stage"
    }
    elseif ($totalScore -ge 65) {
        $classification = "queue_for_review"
    }

    return [ordered]@{
        teacher_item_id               = Normalize-Text (Get-PropValue -Object $Step -Name "id" -Default "")
        domain                        = $domain
        area                          = $area
        title                         = $title
        risk_level                    = Normalize-Text (Get-PropValue -Object $Step -Name "risk_level" -Default "")
        specificity                   = [int][Math]::Round($specificity, 0)
        actionability                 = [int][Math]::Round($actionability, 0)
        grounding_evidence            = [int][Math]::Round($grounding, 0)
        relevance_to_current_state    = [int][Math]::Round($relevance, 0)
        implementation_safety         = [int][Math]::Round($implementationSafety, 0)
        expected_upside               = [int][Math]::Round($expectedUpside, 0)
        total_score                   = [double]$totalScore
        classification                = $classification
        requires_human_approval       = $requiresHumanApproval
        referenced_action_paths_found = [int]$actionPathHits
        action_count                  = [int]$actions.Count
        evidence                      = @(
            "domain=$domain",
            "keyword_overlap=$keywordOverlap",
            "referenced_action_paths_found=$actionPathHits/$($actions.Count)"
        )
    }
}

function Get-BestTeacherReviewForItem {
    param(
        $Item,
        [object[]]$TeacherReviews
    )

    $title = Normalize-Text (Get-PropValue -Object $Item -Name "title" -Default "")
    $description = Normalize-Text (Get-PropValue -Object $Item -Name "description" -Default "")
    $reason = Normalize-Text (Get-PropValue -Object $Item -Name "reason" -Default "")
    $targetType = Normalize-Text (Get-PropValue -Object $Item -Name "target_type" -Default "")
    $keywords = Get-KeywordSet -Values @($title, $description, $reason, $targetType)

    $best = $null
    $bestScore = 0
    foreach ($review in @($TeacherReviews)) {
        $reviewKeywords = Get-KeywordSet -Values @(
            (Get-PropValue -Object $review -Name "domain" -Default ""),
            (Get-PropValue -Object $review -Name "area" -Default ""),
            (Get-PropValue -Object $review -Name "title" -Default "")
        )
        $matchScore = 0
        if ($targetType -and $targetType.ToLowerInvariant() -eq (Normalize-Text (Get-PropValue -Object $review -Name "domain" -Default "")).ToLowerInvariant()) {
            $matchScore += 30
        }
        foreach ($token in $reviewKeywords) {
            if ($keywords.Contains($token)) {
                $matchScore += 6
            }
        }
        $classification = (Normalize-Text (Get-PropValue -Object $review -Name "classification" -Default "")).ToLowerInvariant()
        if ($classification -eq "safe_to_stage") {
            $matchScore += 10
        }
        elseif ($classification -eq "queue_for_review") {
            $matchScore += 5
        }
        if ($matchScore -gt $bestScore) {
            $bestScore = $matchScore
            $best = $review
        }
    }

    return [ordered]@{
        score  = [int]$bestScore
        review = $best
    }
}

function Get-BudgetPosture {
    param(
        $BudgetState,
        $Policy
    )

    $enabled = [bool](Get-PropValue -Object $BudgetState -Name "enabled" -Default $false)
    $remainingUsd = [double](Get-PropValue -Object $BudgetState -Name "remaining_usd" -Default 0)
    $costTiers = Get-PropValue -Object $Policy -Name "cost_tiers" -Default @{}
    $lowUsd = [double](Get-PropValue -Object $costTiers -Name "low_usd" -Default 5)
    $standardUsd = [double](Get-PropValue -Object $costTiers -Name "standard_usd" -Default 15)
    $sensitivity = Normalize-Text (Get-PropValue -Object $Policy -Name "cost_sensitivity" -Default "guarded")

    if (-not $enabled -or $remainingUsd -lt $lowUsd) {
        return "blocked"
    }
    if ($remainingUsd -lt $standardUsd) {
        return "constrained"
    }
    if ($sensitivity -eq "guarded") {
        return "guarded"
    }
    return "open"
}

function Get-ExecutionDisposition {
    param(
        $Item,
        $Behavior,
        $Policy,
        [string]$TeacherCallClassification,
        [string]$TeacherQualityClassification,
        [int]$TeacherQualityScore,
        [int]$FallbackQuality,
        [bool]$BlockedByPolicy
    )

    $risk = (Normalize-Text (Get-PropValue -Object $Item -Name "risk_level" -Default "")).ToUpperInvariant()
    $approvalRequired = [bool](Get-PropValue -Object $Item -Name "approval_required" -Default $false)
    $behaviorApprovalRequired = [bool](Get-PropValue -Object $Behavior -Name "approval_required" -Default $false)
    $behaviorAutoAllowed = [bool](Get-PropValue -Object $Behavior -Name "auto_action_eligible" -Default $false)
    $behaviorHardGated = [bool](Get-PropValue -Object $Behavior -Name "hard_gated" -Default $false)
    $behaviorTrustState = (Normalize-Text (Get-PropValue -Object $Behavior -Name "trust_state" -Default "")).ToLowerInvariant()
    $rules = Get-PropValue -Object $Policy -Name "execution_disposition_rules" -Default @{}
    $safeToTestNeedsAutoAllowed = [bool](Get-PropValue -Object $rules -Name "allow_safe_to_test_requires_auto_allowed_behavior" -Default $true)

    if ($BlockedByPolicy -or $behaviorHardGated) {
        return [ordered]@{
            execution_disposition        = "blocked"
            execution_disposition_reason = "Policy blocks teacher-backed or risky self-improvement for this item until human review."
        }
    }

    if ($approvalRequired -or $behaviorApprovalRequired -or $risk -in @("R2", "R3", "R4")) {
        return [ordered]@{
            execution_disposition        = "approval_required"
            execution_disposition_reason = "This item remains approval-gated under current trust and risk policy."
        }
    }

    if ($TeacherCallClassification -eq "trivial_local_only" -and $FallbackQuality -ge 80) {
        if (-not $safeToTestNeedsAutoAllowed -or $behaviorAutoAllowed) {
            return [ordered]@{
                execution_disposition        = "safe_to_test"
                execution_disposition_reason = "Low-risk local-only work is suitable for governed testing."
            }
        }
        return [ordered]@{
            execution_disposition        = "safe_to_stage"
            execution_disposition_reason = "Low-risk local-only work is well specified and can be staged without a teacher call."
        }
    }

    if ($behaviorAutoAllowed -and $TeacherQualityScore -ge 50) {
        return [ordered]@{
            execution_disposition        = "safe_to_test"
            execution_disposition_reason = "Linked behavior is auto_allowed and the current evidence is strong enough for a safe test."
        }
    }

    if ($TeacherCallClassification -eq "local_first_teacher_optional" -and $FallbackQuality -ge 65) {
        if ($behaviorTrustState -in @("trusted", "approved", "candidate")) {
            return [ordered]@{
                execution_disposition        = "safe_to_stage"
                execution_disposition_reason = "Local artifacts are sufficient to stage this improvement for review."
            }
        }
        return [ordered]@{
            execution_disposition        = "suggest_only"
            execution_disposition_reason = "Local-first evidence exists, but trust is not yet high enough to stage."
        }
    }

    if ($TeacherCallClassification -like "teacher_required*") {
        if ($TeacherQualityClassification -eq "safe_to_stage" -and $TeacherQualityScore -ge 85) {
            return [ordered]@{
                execution_disposition        = "safe_to_stage"
                execution_disposition_reason = "Teacher guidance is specific and safe enough to stage, but not to auto-apply."
            }
        }
        if ($TeacherQualityClassification -eq "queue_for_review") {
            return [ordered]@{
                execution_disposition        = "approval_required"
                execution_disposition_reason = "Teacher input is useful but still needs human review before staging."
            }
        }
        return [ordered]@{
            execution_disposition        = "suggest_only"
            execution_disposition_reason = "Teacher input is not strong enough to move beyond suggestion-only posture."
        }
    }

    return [ordered]@{
        execution_disposition        = "suggest_only"
        execution_disposition_reason = "This item remains suggestion-only until trust or evidence improves."
    }
}

$repoRoot = Get-RepoRoot -OverrideRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"

$governorReportPath = Join-Path $reportsDir "self_improvement_governor_last.json"
$teacherBudgetPath = Join-Path $reportsDir "teacher_call_budget_last.json"
$teacherDecisionLogPath = Join-Path $reportsDir "teacher_decision_log_last.json"
$policyPath = Join-Path $stateKnowledgeDir "self_improvement_policy.json"
$queuePath = Join-Path $stateKnowledgeDir "improvement_queue.json"
$behaviorTrustPath = Join-Path $stateKnowledgeDir "behavior_trust.json"
$budgetStatePath = Join-Path $stateKnowledgeDir "budget_state.json"
$teacherPlanPath = Join-Path $stateKnowledgeDir "mason_teacher_plan_latest.json"
$teacherSuggestionsPath = Join-Path $stateKnowledgeDir "mason_teacher_suggestions.json"
$systemValidationPath = Join-Path $reportsDir "system_validation_last.json"
$hostHealthPath = Join-Path $reportsDir "host_health_last.json"
$runtimePosturePath = Join-Path $reportsDir "runtime_posture_last.json"
$environmentDriftPath = Join-Path $reportsDir "environment_drift_last.json"
$securityPosturePath = Join-Path $reportsDir "security_posture.json"

$policy = Get-DefaultPolicy
$configuredPolicy = Read-JsonSafe -Path $policyPath -Default @{}
if ($configuredPolicy) {
    $policy = Merge-Maps -Base $policy -Override $configuredPolicy
}
$policy.generated_at_utc = Get-UtcTimestamp
Write-JsonFile -Path $policyPath -Object $policy

$queueState = Read-JsonSafe -Path $queuePath -Default @{ items = @() }
$behaviorState = Read-JsonSafe -Path $behaviorTrustPath -Default @{ behaviors = @() }
$budgetState = Read-JsonSafe -Path $budgetStatePath -Default @{}
$teacherPlan = Read-JsonSafe -Path $teacherPlanPath -Default @{ steps = @() }
$teacherSuggestions = Read-JsonSafe -Path $teacherSuggestionsPath -Default @{ suggestions = @() }
$validationState = Read-JsonSafe -Path $systemValidationPath -Default @{}
$hostHealthState = Read-JsonSafe -Path $hostHealthPath -Default @{}
$runtimePostureState = Read-JsonSafe -Path $runtimePosturePath -Default @{}
$environmentDriftState = Read-JsonSafe -Path $environmentDriftPath -Default @{}
$securityPostureState = Read-JsonSafe -Path $securityPosturePath -Default @{}

$behaviorMap = @{}
foreach ($behavior in @(Get-List (Get-PropValue -Object $behaviorState -Name "behaviors" -Default @()))) {
    $behaviorId = Normalize-Text (Get-PropValue -Object $behavior -Name "behavior_id" -Default "")
    if ($behaviorId) {
        $behaviorMap[$behaviorId] = $behavior
    }
}

$activeItems = @()
foreach ($item in @(Get-List (Get-PropValue -Object $queueState -Name "items" -Default @()))) {
    $status = (Normalize-Text (Get-PropValue -Object $item -Name "status" -Default "")).ToLowerInvariant()
    $isCurrent = [bool](Get-PropValue -Object $item -Name "is_current" -Default $true)
    if (-not $isCurrent) {
        continue
    }
    if ($status -in @("completed", "dismissed", "reverted")) {
        continue
    }
    $activeItems += @($item)
}

$activeDomains = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
$activeKeywordSeed = @()
foreach ($item in $activeItems) {
    $targetType = Normalize-Text (Get-PropValue -Object $item -Name "target_type" -Default "")
    if ($targetType) {
        [void]$activeDomains.Add($targetType.ToLowerInvariant())
    }
    $activeKeywordSeed += @(
        Normalize-Text (Get-PropValue -Object $item -Name "title" -Default ""),
        Normalize-Text (Get-PropValue -Object $item -Name "description" -Default ""),
        Normalize-Text (Get-PropValue -Object $item -Name "reason" -Default "")
    )
}
$activeKeywords = Get-KeywordSet -Values $activeKeywordSeed

$teacherReviews = @()
foreach ($step in @(Get-List (Get-PropValue -Object $teacherPlan -Name "steps" -Default @()))) {
    $teacherReviews += @(Get-TeacherResponseReview -RepoRoot $repoRoot -Step $step -ActiveDomains $activeDomains -ActiveKeywords $activeKeywords)
}

if (@(Get-List (Get-PropValue -Object $teacherSuggestions -Name "suggestions" -Default @())).Count -eq 0) {
    $teacherReviews += @([ordered]@{
        teacher_item_id               = "teacher_suggestions_latest"
        domain                        = "mason"
        area                          = "teacher_suggestions"
        title                         = "Latest teacher suggestions artifact"
        risk_level                    = "R1"
        specificity                   = 0
        actionability                 = 0
        grounding_evidence            = 0
        relevance_to_current_state    = 0
        implementation_safety         = 60
        expected_upside               = 0
        total_score                   = 10
        classification                = "reject"
        requires_human_approval       = $true
        referenced_action_paths_found = 0
        action_count                  = 0
        evidence                      = @(
            Limit-Text -Text ("reason=" + (Normalize-Text (Get-PropValue -Object $teacherSuggestions -Name "reason" -Default "No suggestions were retained."))) -MaxLength 220
        )
    })
}

$budgetPosture = Get-BudgetPosture -BudgetState $budgetState -Policy $policy
$validationStatus = (Normalize-Text (Get-PropValue -Object $validationState -Name "overall_status" -Default "")).ToUpperInvariant()
$hostStatus = (Normalize-Text (Get-PropValue -Object $hostHealthState -Name "overall_status" -Default "")).ToUpperInvariant()
$throttleGuidance = (Normalize-Text (Get-PropValue -Object $hostHealthState -Name "throttle_guidance" -Default "")).ToLowerInvariant()
$runtimeThrottle = (Normalize-Text (Get-PropValue -Object $runtimePostureState -Name "throttle_guidance" -Default "")).ToLowerInvariant()
$environmentDriftLevel = (Normalize-Text (Get-PropValue -Object $environmentDriftState -Name "drift_level" -Default "")).ToLowerInvariant()
$securityOverallStatus = (Normalize-Text (Get-PropValue -Object $securityPostureState -Name "overall_status" -Default "")).ToUpperInvariant()

$decisionItems = @()
$classificationCounts = @{}
$dispositionCounts = @{}
$qualityCounts = @{}
$teacherWorthyTotal = 0
$blockedByLocalFirstTotal = 0
$allowedTeacherTotal = 0
$highValueOnlyTotal = 0

foreach ($item in $activeItems) {
    $teacherWorthyTotal += 1
    $improvementId = Normalize-Text (Get-PropValue -Object $item -Name "improvement_id" -Default "")
    $title = Normalize-Text (Get-PropValue -Object $item -Name "title" -Default "")
    $description = Normalize-Text (Get-PropValue -Object $item -Name "description" -Default "")
    $reason = Normalize-Text (Get-PropValue -Object $item -Name "reason" -Default "")
    $source = (Normalize-Text (Get-PropValue -Object $item -Name "source" -Default "")).ToLowerInvariant()
    $status = (Normalize-Text (Get-PropValue -Object $item -Name "status" -Default "")).ToLowerInvariant()
    $targetType = (Normalize-Text (Get-PropValue -Object $item -Name "target_type" -Default "")).ToLowerInvariant()
    $priority = [int](Get-PropValue -Object $item -Name "priority" -Default 50)
    $riskLevel = (Normalize-Text (Get-PropValue -Object $item -Name "risk_level" -Default "R1")).ToUpperInvariant()
    $linkedBehaviorId = Normalize-Text (Get-PropValue -Object $item -Name "linked_behavior_id" -Default "")
    $behavior = $null
    if ($linkedBehaviorId -and $behaviorMap.ContainsKey($linkedBehaviorId)) {
        $behavior = $behaviorMap[$linkedBehaviorId]
    }

    $riskScore = Get-RiskScore -RiskLevel $riskLevel
    if ($behavior) {
        $riskScore = [Math]::Round((($riskScore + (Get-BehaviorRiskScore -RiskLevel (Get-PropValue -Object $behavior -Name "risk_level" -Default ""))) / 2), 0)
    }

    $expectedValue = [Math]::Min(100, [Math]::Max(0, $priority))
    if ($source -in @("self-heal", "runtime")) { $expectedValue = [Math]::Min(100, $expectedValue + 10) }
    if ($targetType -in @("system", "security", "billing")) { $expectedValue = [Math]::Min(100, $expectedValue + 5) }

    $urgency = [Math]::Min(100, [Math]::Max(20, [Math]::Round(($priority * 0.7), 0)))
    if ($validationStatus -eq "WARN" -and $targetType -in @("security", "billing", "system")) { $urgency = [Math]::Min(100, $urgency + 15) }
    if ($hostStatus -eq "WARN" -and $targetType -eq "system") { $urgency = [Math]::Min(100, $urgency + 10) }
    if ($status -eq "blocked") { $urgency = [Math]::Min(100, $urgency + 10) }

    $implementationDifficulty = Get-TargetBaseDifficulty -TargetType $targetType
    if ([bool](Get-PropValue -Object $item -Name "approval_required" -Default $false)) { $implementationDifficulty += 10 }
    if ($source -in @("competitor", "tool-gap")) { $implementationDifficulty += 20 }
    if ($behavior -and [bool](Get-PropValue -Object $behavior -Name "auto_action_eligible" -Default $false)) { $implementationDifficulty -= 15 }
    if (@(Get-List (Get-PropValue -Object $item -Name "evidence" -Default @())).Count -gt 0) { $implementationDifficulty -= 5 }
    if ($environmentDriftLevel -in @("significant_change", "new_environment")) { $implementationDifficulty += 10 }
    $implementationDifficulty = [Math]::Max(5, [Math]::Min(100, $implementationDifficulty))

    $fallbackQuality = 20
    if ($source -in @(Get-List (Get-PropValue -Object $policy -Name "local_first_sources" -Default @()))) { $fallbackQuality += 30 }
    if (@(Get-List (Get-PropValue -Object $item -Name "evidence" -Default @())).Count -gt 0) { $fallbackQuality += 20 }
    if ($behavior) { $fallbackQuality += 20 }
    if ($validationStatus -eq "WARN" -and $targetType -in @("security", "billing", "system")) { $fallbackQuality += 5 }
    if ($throttleGuidance -in @("throttle_heavy_jobs", "protect_host")) { $fallbackQuality += 5 }
    if ($runtimeThrottle -in @("throttle_heavy_jobs", "protect_host")) { $fallbackQuality += 5 }
    if ($source -in @("competitor", "tool-gap")) { $fallbackQuality -= 20 }
    $fallbackQuality = [Math]::Max(0, [Math]::Min(100, $fallbackQuality))

    $estimatedCostTier = "low"
    if ($implementationDifficulty -ge 70 -or $riskScore -ge 70) {
        $estimatedCostTier = "high"
    }
    elseif ($implementationDifficulty -ge 45 -or $expectedValue -ge 70) {
        $estimatedCostTier = "standard"
    }

    $textForBlocking = ("{0} {1} {2}" -f $title, $description, $reason).ToLowerInvariant()
    $blockedByKeyword = $false
    foreach ($keyword in @(Get-List (Get-PropValue -Object $policy -Name "blocked_keywords" -Default @()))) {
        if ($textForBlocking.Contains(([string]$keyword).ToLowerInvariant())) {
            $blockedByKeyword = $true
            break
        }
    }

    $blockedByPolicy = $false
    if ($targetType -in @(Get-List (Get-PropValue -Object $policy -Name "blocked_target_types" -Default @()))) {
        $blockedByPolicy = $true
    }
    if ($blockedByKeyword) {
        $blockedByPolicy = $true
    }
    if ($riskLevel -in @("R3", "R4")) {
        $blockedByPolicy = $true
    }
    if ($budgetPosture -eq "blocked" -and $estimatedCostTier -ne "low") {
        $blockedByPolicy = $true
    }

    $scoreThresholds = Get-PropValue -Object $policy -Name "score_thresholds" -Default @{}
    $teacherCallClassification = "local_first_teacher_optional"
    if ($blockedByPolicy) {
        $teacherCallClassification = "blocked_pending_human_review"
    }
    elseif ($implementationDifficulty -le [int](Get-PropValue -Object $scoreThresholds -Name "trivial_local_only_max_difficulty" -Default 30) -and $fallbackQuality -ge 80) {
        $teacherCallClassification = "trivial_local_only"
    }
    elseif ($fallbackQuality -ge [int](Get-PropValue -Object $scoreThresholds -Name "local_first_optional_min_fallback" -Default 65)) {
        $teacherCallClassification = "local_first_teacher_optional"
    }
    elseif ($estimatedCostTier -eq "low" -and $expectedValue -ge [int](Get-PropValue -Object $scoreThresholds -Name "teacher_low_cost_min_expected_value" -Default 55)) {
        $teacherCallClassification = "teacher_required_low_cost"
    }
    elseif ($estimatedCostTier -eq "standard" -and $expectedValue -ge [int](Get-PropValue -Object $scoreThresholds -Name "teacher_standard_min_expected_value" -Default 70)) {
        $teacherCallClassification = "teacher_required_standard"
    }
    elseif ($expectedValue -ge [int](Get-PropValue -Object $scoreThresholds -Name "teacher_high_value_min_expected_value" -Default 85)) {
        $teacherCallClassification = "teacher_required_high_value_only"
    }

    $bestTeacherMatch = Get-BestTeacherReviewForItem -Item $item -TeacherReviews $teacherReviews
    $matchedReview = Get-PropValue -Object $bestTeacherMatch -Name "review" -Default $null
    $matchedReviewScore = [int](Get-PropValue -Object $bestTeacherMatch -Name "score" -Default 0)
    $teacherQualityClassification = "reject"
    $teacherQualityScore = 0
    $teacherQualityEvidence = @("No relevant teacher response matched this item.")
    if ($matchedReview) {
        $teacherQualityClassification = (Normalize-Text (Get-PropValue -Object $matchedReview -Name "classification" -Default "reject")).ToLowerInvariant()
        $teacherQualityScore = [int][Math]::Round([double](Get-PropValue -Object $matchedReview -Name "total_score" -Default 0), 0)
        $teacherQualityEvidence = @(
            ("matched_teacher_item_id=" + (Normalize-Text (Get-PropValue -Object $matchedReview -Name "teacher_item_id" -Default ""))),
            ("match_score=" + $matchedReviewScore),
            ("grounding=" + (Get-PropValue -Object $matchedReview -Name "grounding_evidence" -Default 0))
        )
    }

    $disposition = Get-ExecutionDisposition -Item $item -Behavior $behavior -Policy $policy -TeacherCallClassification $teacherCallClassification -TeacherQualityClassification $teacherQualityClassification -TeacherQualityScore $teacherQualityScore -FallbackQuality $fallbackQuality -BlockedByPolicy $blockedByPolicy

    if ($teacherCallClassification -in @("trivial_local_only", "local_first_teacher_optional", "blocked_pending_human_review")) {
        $blockedByLocalFirstTotal += 1
    }
    if ($teacherCallClassification -in @("teacher_required_low_cost", "teacher_required_standard")) {
        $allowedTeacherTotal += 1
    }
    if ($teacherCallClassification -eq "teacher_required_high_value_only") {
        $highValueOnlyTotal += 1
    }

    if (-not $classificationCounts.ContainsKey($teacherCallClassification)) {
        $classificationCounts[$teacherCallClassification] = 0
    }
    $classificationCounts[$teacherCallClassification] += 1

    $executionDisposition = Normalize-Text (Get-PropValue -Object $disposition -Name "execution_disposition" -Default "suggest_only")
    if (-not $dispositionCounts.ContainsKey($executionDisposition)) {
        $dispositionCounts[$executionDisposition] = 0
    }
    $dispositionCounts[$executionDisposition] += 1

    if (-not $qualityCounts.ContainsKey($teacherQualityClassification)) {
        $qualityCounts[$teacherQualityClassification] = 0
    }
    $qualityCounts[$teacherQualityClassification] += 1

    $decisionItems += @([ordered]@{
        improvement_id                   = $improvementId
        target_type                      = $targetType
        target_id                        = Normalize-Text (Get-PropValue -Object $item -Name "target_id" -Default "")
        title                            = $title
        status                           = $status
        priority                         = $priority
        risk_level                       = $riskLevel
        linked_behavior_id               = $linkedBehaviorId
        teacher_call_classification      = $teacherCallClassification
        blocked_by_local_first           = ($teacherCallClassification -in @("trivial_local_only", "local_first_teacher_optional", "blocked_pending_human_review"))
        estimated_cost_tier              = $estimatedCostTier
        execution_disposition            = $executionDisposition
        execution_disposition_reason     = Limit-Text -Text (Get-PropValue -Object $disposition -Name "execution_disposition_reason" -Default "") -MaxLength 220
        teacher_quality_classification   = $teacherQualityClassification
        teacher_quality_score            = $teacherQualityScore
        teacher_quality_evidence         = @($teacherQualityEvidence)
        matched_teacher_item_id          = Normalize-Text (Get-PropValue -Object $matchedReview -Name "teacher_item_id" -Default "")
        matched_teacher_title            = Normalize-Text (Get-PropValue -Object $matchedReview -Name "title" -Default "")
        scores                           = [ordered]@{
            expected_value                   = [int]$expectedValue
            urgency                          = [int]$urgency
            safety_risk                      = [int]$riskScore
            implementation_difficulty        = [int]$implementationDifficulty
            fallback_quality_without_teacher = [int]$fallbackQuality
        }
        rationale                        = @(
            ("source=" + $source),
            ("budget_posture=" + $budgetPosture),
            ("validator_status=" + $validationStatus),
            ("runtime_throttle=" + $runtimeThrottle)
        )
    })
}

$decisionItems = @($decisionItems | Sort-Object @{ Expression = { [int](Get-PropValue -Object $_ -Name "priority" -Default 0) }; Descending = $true }, @{ Expression = { Normalize-Text (Get-PropValue -Object $_ -Name "title" -Default "") }; Descending = $false })
$teacherReviews = @($teacherReviews | Sort-Object @{ Expression = { [double](Get-PropValue -Object $_ -Name "total_score" -Default 0) }; Descending = $true }, @{ Expression = { Normalize-Text (Get-PropValue -Object $_ -Name "teacher_item_id" -Default "") }; Descending = $false })

$overallStatus = "PASS"
if ($decisionItems.Count -eq 0) {
    $overallStatus = "WARN"
}
elseif ($blockedByLocalFirstTotal -gt 0 -or $qualityCounts.ContainsKey("reject")) {
    $overallStatus = "WARN"
}

$recommendedNextAction = "No action required."
if ($classificationCounts.ContainsKey("blocked_pending_human_review")) {
    $recommendedNextAction = "Review blocked teacher-worthy items manually and keep money/security/policy changes approval-gated."
}
elseif ($allowedTeacherTotal -gt 0) {
    $recommendedNextAction = "Keep local-first for most items and only consult the teacher for the highest-value approved items."
}
elseif ($qualityCounts.ContainsKey("reject")) {
    $recommendedNextAction = "Do not stage teacher-backed changes from the current stored answers; keep them as reference only."
}
elseif ($decisionItems.Count -eq 0) {
    $recommendedNextAction = "Populate the improvement queue before relying on the self-improvement governor."
}

$budgetReport = [ordered]@{
    timestamp_utc                         = Get-UtcTimestamp
    total_teacher_worthy_items_considered = [int]$teacherWorthyTotal
    total_blocked_by_local_first         = [int]$blockedByLocalFirstTotal
    total_allowed                        = [int]$allowedTeacherTotal
    total_high_value_only                = [int]$highValueOnlyTotal
    rationale_summary                    = @(
        ("budget_posture=" + $budgetPosture),
        ("validation_status=" + $validationStatus),
        ("security_status=" + $securityOverallStatus),
        ("host_throttle=" + $throttleGuidance)
    )
    current_budget_posture               = $budgetPosture
    budget_remaining_usd                 = [double](Get-PropValue -Object $budgetState -Name "remaining_usd" -Default 0)
    budget_remaining_cad                 = [double](Get-PropValue -Object $budgetState -Name "remaining_cad" -Default 0)
    weekly_remaining_usd                 = [double](Get-PropValue -Object $budgetState -Name "weekly_remaining_usd" -Default 0)
    weekly_remaining_cad                 = [double](Get-PropValue -Object $budgetState -Name "weekly_remaining_cad" -Default 0)
    recommended_next_action              = $recommendedNextAction
}

$decisionLog = [ordered]@{
    timestamp_utc            = Get-UtcTimestamp
    policy_path              = $policyPath
    improvement_queue_path   = $queuePath
    behavior_trust_path      = $behaviorTrustPath
    teacher_plan_path        = $teacherPlanPath
    teacher_suggestions_path = $teacherSuggestionsPath
    improvement_decisions    = @($decisionItems)
    teacher_response_reviews = @($teacherReviews)
    recommended_next_action  = $recommendedNextAction
}

$governorReport = [ordered]@{
    timestamp_utc                            = Get-UtcTimestamp
    overall_status                           = $overallStatus
    policy_path                              = $policyPath
    queue_path                               = $queuePath
    behavior_trust_path                      = $behaviorTrustPath
    teacher_plan_path                        = $teacherPlanPath
    teacher_suggestions_path                 = $teacherSuggestionsPath
    active_improvement_total                 = [int]$decisionItems.Count
    teacher_response_reviews_total           = [int]$teacherReviews.Count
    counts_by_teacher_call_classification    = Convert-ToPlainData -Value $classificationCounts
    counts_by_execution_disposition          = Convert-ToPlainData -Value $dispositionCounts
    counts_by_teacher_quality_classification = Convert-ToPlainData -Value $qualityCounts
    total_blocked_by_local_first             = [int]$blockedByLocalFirstTotal
    total_teacher_allowed                    = [int]$allowedTeacherTotal
    total_teacher_high_value_only            = [int]$highValueOnlyTotal
    current_budget_posture                   = $budgetPosture
    host_pressure                            = [ordered]@{
        host_health_status = $hostStatus
        host_throttle      = $throttleGuidance
        runtime_throttle   = $runtimeThrottle
        environment_drift  = $environmentDriftLevel
        security_posture   = $securityOverallStatus
    }
    recommended_next_action                  = $recommendedNextAction
    items                                    = @($decisionItems)
}

Write-JsonFile -Path $teacherBudgetPath -Object $budgetReport
Write-JsonFile -Path $teacherDecisionLogPath -Object $decisionLog
Write-JsonFile -Path $governorReportPath -Object $governorReport
