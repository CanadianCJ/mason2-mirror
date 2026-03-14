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
    if ($null -eq $Value) { return "" }
    return ([string]$Value).Trim()
}

function Normalize-ShortText {
    param(
        [AllowNull()][object]$Value,
        [int]$MaxLength = 240
    )
    $text = Normalize-Text $Value
    if (-not $text) { return "" }
    if ($text.Length -le $MaxLength) { return $text }
    return ($text.Substring(0, [Math]::Max(0, $MaxLength - 3)).TrimEnd() + "...")
}

function Normalize-StringList {
    param(
        [AllowNull()][object]$Value,
        [int]$MaxItems = 24,
        [int]$MaxLength = 220
    )
    $results = New-Object System.Collections.Generic.List[string]
    foreach ($item in @($Value)) {
        $text = Normalize-ShortText -Value $item -MaxLength $MaxLength
        if (-not $text) { continue }
        if (-not $results.Contains($text)) {
            [void]$results.Add($text)
        }
        if ($results.Count -ge $MaxItems) { break }
    }
    return @($results)
}

function Get-PropValue {
    param(
        [AllowNull()][object]$Object,
        [string]$Name,
        $Default = $null
    )
    if ($null -eq $Object) { return $Default }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) {
            Write-Output -NoEnumerate $Object[$Name]
            return
        }
        return $Default
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -ne $property) {
        Write-Output -NoEnumerate $property.Value
        return
    }
    return $Default
}

function Read-JsonSafe {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if (-not (Normalize-Text $raw)) { return $null }
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
    $Data | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Convert-ToInt {
    param([AllowNull()][object]$Value, [int]$Default = 0)
    $parsed = 0
    if ([int]::TryParse((Normalize-Text $Value), [ref]$parsed)) { return [int]$parsed }
    return [int]$Default
}

function Convert-ToDouble {
    param([AllowNull()][object]$Value, [double]$Default = 0.0)
    $parsed = 0.0
    if ([double]::TryParse((Normalize-Text $Value), [ref]$parsed)) { return [double]$parsed }
    return [double]$Default
}

function Convert-ToBool {
    param([AllowNull()][object]$Value, [bool]$Default = $false)
    if ($null -eq $Value) { return [bool]$Default }
    if ($Value -is [bool]) { return [bool]$Value }
    $text = (Normalize-Text $Value).ToLowerInvariant()
    if ($text -in @("true", "1", "yes", "y")) { return $true }
    if ($text -in @("false", "0", "no", "n")) { return $false }
    return [bool]$Default
}

function Get-DateTimeOffsetSafe {
    param([AllowNull()][object]$Value)
    $text = Normalize-Text $Value
    if (-not $text) { return $null }
    $parsed = [DateTimeOffset]::MinValue
    if ([DateTimeOffset]::TryParse($text, [ref]$parsed)) { return $parsed.ToUniversalTime() }
    return $null
}

function Convert-ToArray {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return @($Value) }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string]) -and -not ($Value -is [System.Collections.IDictionary])) {
        return @($Value)
    }
    $embedded = Get-PropValue -Object $Value -Name "value" -Default $null
    if ($null -ne $embedded) { return @(Convert-ToArray -Value $embedded) }
    return @($Value)
}

function Clamp-Score {
    param([double]$Value)
    if ($Value -lt 0.0) { return 0.0 }
    if ($Value -gt 100.0) { return 100.0 }
    return [Math]::Round($Value, 2)
}

function New-SourceRef {
    param([string]$Path, [string]$SourceType, [string]$ObservedAt = "")
    return [pscustomobject]@{
        path = Normalize-Text $Path
        source_type = Normalize-ShortText -Value $SourceType -MaxLength 64
        observed_at = Normalize-Text $ObservedAt
    }
}

function New-AntiRepeatEntry {
    param(
        [string]$IdeaKey,
        [string]$Domain,
        [string]$Component,
        [string]$Title,
        [string]$FailureReason,
        [string[]]$Evidence,
        [string]$BlockPosture,
        [string]$ReconsiderationRequirement,
        [string]$LinkedCardId = ""
    )
    return [pscustomobject]@{
        idea_key = Normalize-ShortText -Value $IdeaKey -MaxLength 120
        domain = Normalize-ShortText -Value $Domain -MaxLength 64
        component = Normalize-ShortText -Value $Component -MaxLength 96
        title = Normalize-ShortText -Value $Title -MaxLength 160
        failure_reason = Normalize-ShortText -Value $FailureReason -MaxLength 320
        evidence = Normalize-StringList -Value $Evidence -MaxItems 12 -MaxLength 220
        block_posture = Normalize-ShortText -Value $BlockPosture -MaxLength 64
        reconsideration_requirement = Normalize-ShortText -Value $ReconsiderationRequirement -MaxLength 280
        linked_card_id = Normalize-ShortText -Value $LinkedCardId -MaxLength 120
    }
}

$repoRoot = Resolve-RepoRoot -ExplicitRoot $RepoRoot
$reportsDir = Join-Path $repoRoot "reports"
$configDir = Join-Path $repoRoot "config"
$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"

$knowledgeQualityLastPath = Join-Path $reportsDir "knowledge_quality_last.json"
$knowledgeCardsLastPath = Join-Path $reportsDir "knowledge_cards_last.json"
$knowledgeReuseLastPath = Join-Path $reportsDir "knowledge_reuse_last.json"
$antiRepeatMemoryLastPath = Join-Path $reportsDir "anti_repeat_memory_last.json"
$outcomeLearningLastPath = Join-Path $reportsDir "outcome_learning_last.json"
$knowledgeQualityPolicyPath = Join-Path $configDir "knowledge_quality_policy.json"

$knowledgeCardsStatePath = Join-Path $stateKnowledgeDir "knowledge_cards.json"
$knowledgeFailuresStatePath = Join-Path $stateKnowledgeDir "knowledge_failures.json"
$knowledgeOutcomesStatePath = Join-Path $stateKnowledgeDir "knowledge_outcomes.json"
$knowledgeReuseHistoryPath = Join-Path $stateKnowledgeDir "knowledge_reuse_history.json"

$systemTruthPath = Join-Path $reportsDir "system_truth_spine_last.json"
$playbookLibraryPath = Join-Path $reportsDir "playbook_library_last.json"
$teacherDecisionLogPath = Join-Path $reportsDir "teacher_decision_log_last.json"
$toolUsefulnessPath = Join-Path $reportsDir "tool_usefulness_last.json"
$recommendationEffectivenessPath = Join-Path $reportsDir "recommendation_effectiveness_last.json"
$businessOutcomesPath = Join-Path $reportsDir "business_outcomes_last.json"
$pendingPatchQuarantinePath = Join-Path $stateKnowledgeDir "pending_patch_runs_quarantine.json"

$policy = [ordered]@{
    version = "2026-03-13"
    policy_name = "knowledge_quality_engine"
    source_classes = [ordered]@{
        validated_local_execution = [ordered]@{ trust_order = 1; base_evidence_weight = 84 }
        local_authoritative_artifact = [ordered]@{ trust_order = 2; base_evidence_weight = 76 }
        explicit_owner_directive = [ordered]@{ trust_order = 3; base_evidence_weight = 78 }
        repeat_success_playbook = [ordered]@{ trust_order = 4; base_evidence_weight = 72 }
        teacher_output_reviewed = [ordered]@{ trust_order = 5; base_evidence_weight = 44 }
        inferred_synthesis = [ordered]@{ trust_order = 6; base_evidence_weight = 34 }
        stale_memory = [ordered]@{ trust_order = 7; base_evidence_weight = 20 }
        failed_prior_suggestion = [ordered]@{ trust_order = 8; base_evidence_weight = 10 }
    }
    evidence_weighting = [ordered]@{
        freshness = 0.12
        source_count_bonus = 6
        contradiction_penalty = 10
    }
    confidence_weighting = [ordered]@{
        evidence_score = 0.55
        freshness_score = 0.20
        success_weight = 6
        failure_weight = 8
        rejection_weight = 10
    }
    freshness_decay_behavior = [ordered]@{
        fast_domains = @("stack", "validator", "services", "host", "environment", "mirror", "billing", "keepalive_ops", "system_truth", "release_management")
        medium_domains = @("tools", "recommendations", "tenant_engagement", "business_outcomes", "revenue_optimization", "regression_guard")
        slow_domains = @("playbook_support", "live_docs", "brand_exposure", "security_posture")
    }
    contradiction_penalties = [ordered]@{ warn = 8; fail = 18; direct = 25 }
    anti_repeat_thresholds = [ordered]@{
        rejection_count_block = 1
        failure_count_review_gate = 1
        repeated_failure_block = 2
        quarantine_duplicate_review_gate = 3
        quarantine_duplicate_block = 10
    }
    minimum_score_for_reuse = [ordered]@{ evidence_score = 60; confidence_score = 55; freshness_score = 35 }
    minimum_score_for_action_influence = [ordered]@{ evidence_score = 75; confidence_score = 70; freshness_score = 50 }
    teacher_reuse_restrictions = [ordered]@{
        blocked_classifications = @("reject")
        review_required_classifications = @("queue_for_review")
        blocked_use_modes = @("action_influence", "autonomous_action", "recommendation_priority")
    }
    operator_override_rules = [ordered]@{ owner_can_reenable_blocked_card = $true; override_requires_notes = $true }
}

Write-JsonFile -Path $knowledgeQualityPolicyPath -Data $policy

$systemTruth = Read-JsonSafe -Path $systemTruthPath
$playbookLibrary = Read-JsonSafe -Path $playbookLibraryPath
$teacherDecisionLog = Read-JsonSafe -Path $teacherDecisionLogPath
$toolUsefulness = Read-JsonSafe -Path $toolUsefulnessPath
$recommendationEffectiveness = Read-JsonSafe -Path $recommendationEffectivenessPath
$businessOutcomes = Read-JsonSafe -Path $businessOutcomesPath
$pendingPatchQuarantine = Read-JsonSafe -Path $pendingPatchQuarantinePath
$previousKnowledgeCards = Read-JsonSafe -Path $knowledgeCardsStatePath
$previousKnowledgeReuse = Read-JsonSafe -Path $knowledgeReuseHistoryPath

$previousById = @{}
foreach ($previousCard in @(Convert-ToArray -Value (Get-PropValue -Object $previousKnowledgeCards -Name "cards" -Default @()))) {
    $previousCardId = Normalize-Text (Get-PropValue -Object $previousCard -Name "card_id" -Default "")
    if ($previousCardId) { $previousById[$previousCardId] = $previousCard }
}

$nowUtc = [DateTimeOffset]::UtcNow
$nowUtcText = $nowUtc.ToString("o")
$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Knowledge_Quality_Engine.ps1"

function Get-BaseScore {
    param([string]$ProvenanceClass)
    $sourceClasses = Get-PropValue -Object $policy -Name "source_classes" -Default @{}
    $sourceConfig = Get-PropValue -Object $sourceClasses -Name $ProvenanceClass -Default $null
    return Convert-ToDouble -Value (Get-PropValue -Object $sourceConfig -Name "base_evidence_weight" -Default 28)
}

function Get-DecayDays {
    param(
        [string]$Domain,
        [string]$ProvenanceClass
    )
    $domainKey = (Normalize-Text $Domain).ToLowerInvariant()
    if ($domainKey -in @("stack", "validator", "services", "host", "environment", "mirror", "billing", "keepalive_ops", "system_truth", "release_management")) { return 7.0 }
    if ($domainKey -in @("tools", "recommendations", "tenant_engagement", "business_outcomes", "revenue_optimization", "regression_guard")) { return 14.0 }
    if ($domainKey -in @("playbook_support", "live_docs", "brand_exposure", "security_posture")) { return 30.0 }
    if ((Normalize-Text $ProvenanceClass).ToLowerInvariant() -eq "teacher_output_reviewed") { return 21.0 }
    return 21.0
}

function Get-FreshnessScore {
    param(
        [string]$LastVerifiedAt,
        [string]$Domain,
        [string]$ProvenanceClass
    )
    $parsed = Get-DateTimeOffsetSafe -Value $LastVerifiedAt
    if ($null -eq $parsed) { return 18.0 }
    $ratio = [Math]::Max(0.0, ($nowUtc - $parsed).TotalDays) / [Math]::Max(1.0, (Get-DecayDays -Domain $Domain -ProvenanceClass $ProvenanceClass))
    $score = 100.0 - ($ratio * 45.0)
    if ($ratio -gt 1.0) { $score -= (($ratio - 1.0) * 15.0) }
    return Clamp-Score -Value $score
}

function Get-EvidenceBand {
    param([double]$Score)
    if ($Score -ge 80.0) { return "high_evidence" }
    if ($Score -ge 60.0) { return "medium_evidence" }
    if ($Score -ge 35.0) { return "low_evidence" }
    return "rejected_evidence"
}

function Get-ConfidenceBand {
    param([double]$Score)
    if ($Score -ge 80.0) { return "trusted" }
    if ($Score -ge 60.0) { return "usable_with_review" }
    if ($Score -ge 35.0) { return "caution" }
    return "blocked"
}

function Get-FreshnessBand {
    param([double]$Score)
    if ($Score -ge 80.0) { return "fresh" }
    if ($Score -ge 60.0) { return "recent" }
    if ($Score -ge 35.0) { return "aging" }
    return "stale"
}

function Get-ExecutionSupportModifier {
    param([string]$ExecutionSupport)
    switch ((Normalize-Text $ExecutionSupport).ToLowerInvariant()) {
        "validated_local_execution" { return 12.0 }
        "execution_verified" { return 10.0 }
        "artifact_supported" { return 6.0 }
        "review_only" { return 1.0 }
        "not_verified" { return -6.0 }
        "blocked" { return -12.0 }
        default { return 0.0 }
    }
}

function Get-OutcomeSupportModifier {
    param([string]$OutcomeSupport)
    switch ((Normalize-Text $OutcomeSupport).ToLowerInvariant()) {
        "positive" { return 10.0 }
        "mixed" { return 4.0 }
        "weak" { return -4.0 }
        "negative" { return -14.0 }
        default { return 0.0 }
    }
}

function Get-BaseAllowedModes {
    param([string]$SourceType)
    switch ((Normalize-Text $SourceType).ToLowerInvariant()) {
        "system_truth_domain" { return @("founder_summary", "support_explanation", "knowledge_reuse") }
        "playbook" { return @("support_explanation", "incident_response", "knowledge_reuse") }
        "teacher_review" { return @("reference_review") }
        "tool_usefulness" { return @("tenant_context", "recommendation_refinement", "knowledge_reuse") }
        "recommendation_effectiveness" { return @("recommendation_refinement", "knowledge_reuse") }
        "business_outcome" { return @("founder_summary", "outcome_analysis", "knowledge_reuse") }
        default { return @("knowledge_reuse") }
    }
}

$seedCards = New-Object System.Collections.Generic.List[object]

$systemTruthDomains = Get-PropValue -Object $systemTruth -Name "domains" -Default $null
if ($null -ne $systemTruthDomains -and $null -ne $systemTruthDomains.PSObject) {
    foreach ($domainProperty in $systemTruthDomains.PSObject.Properties) {
        $domainName = Normalize-Text $domainProperty.Name
        $domainData = $domainProperty.Value
        $domainStatus = Normalize-Text (Get-PropValue -Object $domainData -Name "status" -Default "")
        $truthConfidence = Normalize-Text (Get-PropValue -Object $domainData -Name "truth_confidence" -Default "")
        $sourceRefs = @(
            New-SourceRef -Path $systemTruthPath -SourceType "system_truth_spine" -ObservedAt (Normalize-Text (Get-PropValue -Object $systemTruth -Name "timestamp_utc" -Default ""))
        )
        $domainPath = Normalize-Text (Get-PropValue -Object $domainData -Name "source_artifact_or_probe" -Default "")
        if ($domainPath) {
            $sourceRefs += New-SourceRef -Path $domainPath -SourceType "domain_source" -ObservedAt (Normalize-Text (Get-PropValue -Object $domainData -Name "last_updated_utc" -Default ""))
        }
        $seedCards.Add([pscustomobject]@{
            card_id = "card_system_truth_$domainName"
            title = "System truth: $domainName"
            domain = $domainName
            component = $domainName
            topic = "system_truth"
            summary = Normalize-ShortText -Value (Get-PropValue -Object $domainData -Name "summary" -Default "Current normalized truth for $domainName.") -MaxLength 360
            source_refs = @($sourceRefs)
            source_type = "system_truth_domain"
            provenance_class = "validated_local_execution"
            contradiction_count = if ($domainStatus -eq "FAIL") { 2 } elseif ($domainStatus -eq "WARN") { 1 } else { 0 }
            last_verified_at = Normalize-Text (Get-PropValue -Object $domainData -Name "last_updated_utc" -Default "")
            execution_support = if ($truthConfidence -eq "high") { "validated_local_execution" } else { "artifact_supported" }
            outcome_support = if ($domainStatus -eq "PASS") { "positive" } elseif ($domainStatus -eq "WARN") { "mixed" } elseif ($domainStatus -eq "FAIL") { "negative" } else { "unknown" }
            success_count = if ($domainStatus -eq "PASS") { 1 } else { 0 }
            failure_count = if ($domainStatus -eq "FAIL") { 1 } else { 0 }
            rejection_count = 0
            review_state = if ($truthConfidence -eq "high") { "trusted" } else { "review_required" }
            status_hint = $domainStatus
            source_quality_score = if ($truthConfidence -eq "high") { 90.0 } elseif ($truthConfidence -eq "medium") { 68.0 } else { 55.0 }
            notes_for_reviewer = Normalize-ShortText -Value (Get-PropValue -Object $domainData -Name "recommended_next_action" -Default "Keep current live truth aligned with authoritative artifacts.") -MaxLength 240
        }) | Out-Null
    }
}

foreach ($playbook in @(Convert-ToArray -Value (Get-PropValue -Object $playbookLibrary -Name "playbooks" -Default @()))) {
    $playbookId = Normalize-Text (Get-PropValue -Object $playbook -Name "playbook_id" -Default "")
    if (-not $playbookId) { continue }
    $status = Normalize-Text (Get-PropValue -Object $playbook -Name "status" -Default "")
    $sourceRefs = @(
        New-SourceRef -Path $playbookLibraryPath -SourceType "playbook_library" -ObservedAt (Normalize-Text (Get-PropValue -Object $playbookLibrary -Name "timestamp_utc" -Default ""))
    )
    foreach ($evidencePath in @(Convert-ToArray -Value (Get-PropValue -Object $playbook -Name "evidence_sources" -Default @()))) {
        $sourceRefs += New-SourceRef -Path (Normalize-Text $evidencePath) -SourceType "playbook_evidence"
    }
    $seedCards.Add([pscustomobject]@{
        card_id = "card_playbook_$playbookId"
        title = Normalize-Text (Get-PropValue -Object $playbook -Name "title" -Default $playbookId)
        domain = "playbook_support"
        component = "playbook_support"
        topic = Normalize-Text (Get-PropValue -Object $playbook -Name "category" -Default "playbook")
        summary = Normalize-ShortText -Value (Get-PropValue -Object $playbook -Name "plain_english_explanation" -Default "") -MaxLength 420
        source_refs = @($sourceRefs)
        source_type = "playbook"
        provenance_class = if ($status -in @("ready", "active")) { "repeat_success_playbook" } else { "inferred_synthesis" }
        contradiction_count = 0
        last_verified_at = Normalize-Text (Get-PropValue -Object $playbookLibrary -Name "timestamp_utc" -Default "")
        execution_support = "artifact_supported"
        outcome_support = if ($status -in @("ready", "active")) { "mixed" } else { "unknown" }
        success_count = if ($status -in @("ready", "active")) { 1 } else { 0 }
        failure_count = 0
        rejection_count = 0
        review_state = if ($status -in @("ready", "active")) { "trusted" } else { "review_required" }
        status_hint = if ($status -in @("ready", "active")) { "PASS" } else { "WARN" }
        source_quality_score = if ($status -in @("ready", "active")) { 78.0 } else { 58.0 }
        notes_for_reviewer = Normalize-ShortText -Value (Get-PropValue -Object $playbook -Name "owner_actions" -Default "Keep playbook actions grounded in local truth.") -MaxLength 240
    }) | Out-Null
}

foreach ($review in @(Convert-ToArray -Value (Get-PropValue -Object $teacherDecisionLog -Name "teacher_response_reviews" -Default @()))) {
    $teacherItemId = Normalize-Text (Get-PropValue -Object $review -Name "teacher_item_id" -Default "")
    if (-not $teacherItemId) { continue }
    $classification = Normalize-Text (Get-PropValue -Object $review -Name "classification" -Default "")
    $score = Convert-ToDouble -Value (Get-PropValue -Object $review -Name "total_score" -Default 0.0)
    $grounding = Convert-ToDouble -Value (Get-PropValue -Object $review -Name "grounding_evidence" -Default 0.0)
    $pathsFound = Convert-ToInt -Value (Get-PropValue -Object $review -Name "referenced_action_paths_found" -Default 0)
    $sourceRefs = @(
        New-SourceRef -Path $teacherDecisionLogPath -SourceType "teacher_decision_log" -ObservedAt (Normalize-Text (Get-PropValue -Object $teacherDecisionLog -Name "timestamp_utc" -Default ""))
    )
    foreach ($evidenceItem in @(Convert-ToArray -Value (Get-PropValue -Object $review -Name "evidence" -Default @()))) {
        $sourceRefs += New-SourceRef -Path (Normalize-Text $evidenceItem) -SourceType "teacher_evidence"
    }
    $seedCards.Add([pscustomobject]@{
        card_id = "card_teacher_$teacherItemId"
        title = Normalize-Text (Get-PropValue -Object $review -Name "title" -Default $teacherItemId)
        domain = Normalize-Text (Get-PropValue -Object $review -Name "domain" -Default "teacher")
        component = Normalize-Text (Get-PropValue -Object $review -Name "area" -Default "teacher")
        topic = "teacher_review"
        summary = Normalize-ShortText -Value ("Teacher material scored {0} and is {1}." -f $score, $classification) -MaxLength 320
        source_refs = @($sourceRefs)
        source_type = "teacher_review"
        provenance_class = if ($classification -eq "reject") { "failed_prior_suggestion" } else { "teacher_output_reviewed" }
        contradiction_count = if ($classification -eq "reject") { 2 } elseif ($pathsFound -eq 0) { 1 } else { 0 }
        last_verified_at = Normalize-Text (Get-PropValue -Object $teacherDecisionLog -Name "timestamp_utc" -Default "")
        execution_support = if ($pathsFound -gt 0) { "review_only" } else { "not_verified" }
        outcome_support = if ($classification -eq "reject") { "negative" } elseif ($classification -eq "queue_for_review") { "weak" } else { "mixed" }
        success_count = 0
        failure_count = if ($classification -eq "reject") { 1 } else { 0 }
        rejection_count = if ($classification -eq "reject") { 1 } else { 0 }
        review_state = if ($classification -eq "reject") { "blocked" } else { "review_required" }
        status_hint = if ($classification -eq "reject") { "FAIL" } else { "WARN" }
        source_quality_score = (($score * 0.7) + ($grounding * 0.3))
        explicit_anti_repeat = ($classification -eq "reject")
        notes_for_reviewer = Normalize-ShortText -Value ("Teacher classification={0}; referenced_action_paths_found={1}." -f $classification, $pathsFound) -MaxLength 220
    }) | Out-Null
}

foreach ($toolRecord in @(Convert-ToArray -Value (Get-PropValue -Object $toolUsefulness -Name "per_tool_usefulness" -Default @()))) {
    $toolId = Normalize-Text (Get-PropValue -Object $toolRecord -Name "tool_id" -Default "")
    if (-not $toolId) { continue }
    $usefulness = Normalize-Text (Get-PropValue -Object $toolRecord -Name "usefulness_classification" -Default "")
    $confidenceText = Normalize-Text (Get-PropValue -Object $toolRecord -Name "confidence" -Default "")
    $tenantCountAffected = Convert-ToInt -Value (Get-PropValue -Object $toolRecord -Name "tenant_count_affected" -Default 0)
    $seedCards.Add([pscustomobject]@{
        card_id = "card_tool_$toolId"
        title = "Tool usefulness: $toolId"
        domain = "tools"
        component = $toolId
        topic = "tool_usefulness"
        summary = Normalize-ShortText -Value (Get-PropValue -Object $toolRecord -Name "notes" -Default "$toolId usefulness is $usefulness.") -MaxLength 360
        source_refs = @(
            New-SourceRef -Path $toolUsefulnessPath -SourceType "tool_usefulness" -ObservedAt (Normalize-Text (Get-PropValue -Object $toolUsefulness -Name "timestamp_utc" -Default ""))
        )
        source_type = "tool_usefulness"
        provenance_class = "local_authoritative_artifact"
        contradiction_count = if ($usefulness -eq "underused") { 1 } else { 0 }
        last_verified_at = Normalize-Text (Get-PropValue -Object $toolUsefulness -Name "timestamp_utc" -Default "")
        execution_support = if ($tenantCountAffected -gt 0) { "artifact_supported" } else { "review_only" }
        outcome_support = if ($usefulness -eq "useful") { "positive" } elseif ($usefulness -eq "unclear") { "mixed" } elseif ($usefulness -eq "underused") { "weak" } else { "unknown" }
        success_count = if ($usefulness -eq "useful") { [Math]::Max(1, $tenantCountAffected) } else { 0 }
        failure_count = if ($usefulness -eq "underused") { 1 } else { 0 }
        rejection_count = 0
        review_state = if ($usefulness -eq "underused") { "review_required" } else { "trusted" }
        status_hint = if ($usefulness -eq "underused") { "WARN" } else { "PASS" }
        source_quality_score = switch ($confidenceText.ToLowerInvariant()) { "high" { 82.0 } "medium" { 66.0 } "low" { 46.0 } default { 40.0 } }
        notes_for_reviewer = Normalize-ShortText -Value ("tenant_count_affected={0}; usefulness={1}." -f $tenantCountAffected, $usefulness) -MaxLength 220
    }) | Out-Null
}

foreach ($recommendationRecord in @(Convert-ToArray -Value (Get-PropValue -Object $recommendationEffectiveness -Name "recommendation_type_records" -Default @()))) {
    $recommendationType = Normalize-Text (Get-PropValue -Object $recommendationRecord -Name "recommendation_type" -Default "")
    if (-not $recommendationType) { continue }
    $classification = Normalize-Text (Get-PropValue -Object $recommendationRecord -Name "effectiveness_classification" -Default "")
    $acceptanceSignal = Convert-ToInt -Value (Get-PropValue -Object $recommendationRecord -Name "acceptance_signal" -Default 0)
    $rejectionSignal = Convert-ToInt -Value (Get-PropValue -Object $recommendationRecord -Name "rejection_signal" -Default 0)
    $seedCards.Add([pscustomobject]@{
        card_id = "card_recommendation_$recommendationType"
        title = "Recommendation effectiveness: $recommendationType"
        domain = "recommendations"
        component = $recommendationType
        topic = "recommendation_effectiveness"
        summary = Normalize-ShortText -Value ("$recommendationType recommendations are $classification; acceptance=$acceptanceSignal; rejection=$rejectionSignal.") -MaxLength 320
        source_refs = @(
            New-SourceRef -Path $recommendationEffectivenessPath -SourceType "recommendation_effectiveness" -ObservedAt (Normalize-Text (Get-PropValue -Object $recommendationEffectiveness -Name "timestamp_utc" -Default ""))
        )
        source_type = "recommendation_effectiveness"
        provenance_class = "local_authoritative_artifact"
        contradiction_count = if ($rejectionSignal -gt $acceptanceSignal) { 1 } else { 0 }
        last_verified_at = Normalize-Text (Get-PropValue -Object $recommendationEffectiveness -Name "timestamp_utc" -Default "")
        execution_support = "artifact_supported"
        outcome_support = if ($classification -eq "effective") { "positive" } elseif ($classification -eq "mixed") { "mixed" } elseif ($classification -eq "needs_refinement") { "negative" } else { "unknown" }
        success_count = $acceptanceSignal
        failure_count = 0
        rejection_count = $rejectionSignal
        review_state = if ($classification -eq "needs_refinement") { "review_required" } else { "trusted" }
        status_hint = if ($classification -eq "needs_refinement") { "WARN" } else { "PASS" }
        source_quality_score = switch ((Normalize-Text (Get-PropValue -Object $recommendationRecord -Name "confidence" -Default "")).ToLowerInvariant()) { "high" { 80.0 } "medium" { 64.0 } "low" { 44.0 } default { 40.0 } }
        explicit_anti_repeat = ($classification -eq "needs_refinement" -and $rejectionSignal -gt [Math]::Max(0, $acceptanceSignal))
        notes_for_reviewer = Normalize-ShortText -Value ("refinement_needed={0}." -f ((Convert-ToBool -Value (Get-PropValue -Object $recommendationRecord -Name "refinement_needed" -Default $false)).ToString().ToLowerInvariant())) -MaxLength 180
    }) | Out-Null
}

$outcomeDomains = @("time_saved_indicators", "tool_usefulness", "recommendation_effectiveness", "onboarding_completion", "tenant_engagement", "revenue_help_indicators", "churn_risk_indicators")
foreach ($outcomeDomain in $outcomeDomains) {
    $domainData = Get-PropValue -Object $businessOutcomes -Name $outcomeDomain -Default $null
    if ($null -eq $domainData) { continue }
    $classification = Normalize-Text (Get-PropValue -Object $domainData -Name "classification" -Default "")
    $confidenceText = Normalize-Text (Get-PropValue -Object $domainData -Name "confidence" -Default "")
    $seedCards.Add([pscustomobject]@{
        card_id = "card_business_outcome_$outcomeDomain"
        title = $outcomeDomain
        domain = "business_outcomes"
        component = "business_outcomes"
        topic = $outcomeDomain
        summary = Normalize-ShortText -Value (Get-PropValue -Object $domainData -Name "summary" -Default "$outcomeDomain is available but still low-signal.") -MaxLength 320
        source_refs = @(
            New-SourceRef -Path $businessOutcomesPath -SourceType "business_outcomes" -ObservedAt (Normalize-Text (Get-PropValue -Object $businessOutcomes -Name "timestamp_utc" -Default ""))
        )
        source_type = "business_outcome"
        provenance_class = "local_authoritative_artifact"
        contradiction_count = if ($confidenceText -eq "low") { 1 } else { 0 }
        last_verified_at = Normalize-Text (Get-PropValue -Object $businessOutcomes -Name "timestamp_utc" -Default "")
        execution_support = "artifact_supported"
        outcome_support = if ($classification -in @("positive_signal", "high_signal", "low")) { "positive" } elseif ($classification -in @("medium_signal", "possible_signal", "moderate")) { "mixed" } elseif ($classification -in @("no_signal", "elevated")) { "weak" } else { "unknown" }
        success_count = if ($classification -in @("positive_signal", "high_signal", "low")) { 1 } else { 0 }
        failure_count = 0
        rejection_count = 0
        review_state = if ($confidenceText -eq "low") { "review_required" } else { "trusted" }
        status_hint = if ($confidenceText -eq "low") { "WARN" } else { "PASS" }
        source_quality_score = switch ($confidenceText.ToLowerInvariant()) { "high" { 82.0 } "medium" { 62.0 } "low" { 42.0 } default { 38.0 } }
        notes_for_reviewer = Normalize-ShortText -Value (Get-PropValue -Object $domainData -Name "recommended_next_action" -Default "Collect more outcome evidence before promoting this card.") -MaxLength 220
    }) | Out-Null
}

$antiRepeatEntries = New-Object System.Collections.Generic.List[object]
$quarantineGroups = @{}
foreach ($quarantineItem in @(Convert-ToArray -Value $pendingPatchQuarantine)) {
    $ideaKey = Normalize-Text (Get-PropValue -Object $quarantineItem -Name "title" -Default (Get-PropValue -Object $quarantineItem -Name "source_step" -Default (Get-PropValue -Object $quarantineItem -Name "id" -Default "")))
    if (-not $ideaKey) { continue }
    if (-not $quarantineGroups.ContainsKey($ideaKey)) {
        $quarantineGroups[$ideaKey] = New-Object System.Collections.Generic.List[object]
    }
    [void]$quarantineGroups[$ideaKey].Add($quarantineItem)
}
foreach ($quarantineKey in @($quarantineGroups.Keys)) {
    $groupItems = @($quarantineGroups[$quarantineKey].ToArray())
    $firstItem = $groupItems[0]
    $reasonGroups = @($groupItems | Group-Object { Normalize-Text (Get-PropValue -Object $_ -Name "quarantine_reason" -Default "unknown") } | Sort-Object Count -Descending)
    $topReason = if ($reasonGroups.Count -gt 0) { Normalize-Text $reasonGroups[0].Name } else { "quarantine" }
    $antiRepeatEntries.Add((New-AntiRepeatEntry `
        -IdeaKey ("quarantine:{0}" -f ($quarantineKey.ToLowerInvariant().Replace(" ", "_"))) `
        -Domain (Normalize-Text (Get-PropValue -Object $firstItem -Name "domain" -Default "knowledge")) `
        -Component (Normalize-Text (Get-PropValue -Object $firstItem -Name "component_id" -Default "knowledge")) `
        -Title $quarantineKey `
        -FailureReason ("Quarantined {0} time(s); top reason={1}." -f $groupItems.Count, $topReason) `
        -Evidence @($groupItems | Select-Object -First 3 | ForEach-Object { "{0}:{1}" -f (Normalize-Text (Get-PropValue -Object $_ -Name "id" -Default "")), (Normalize-Text (Get-PropValue -Object $_ -Name "quarantine_reason" -Default "")) }) `
        -BlockPosture $(if ($groupItems.Count -ge 10) { "blocked" } else { "review_gated" }) `
        -ReconsiderationRequirement $(if ($groupItems.Count -ge 10) { "Require materially new local evidence or explicit owner override before resurfacing this idea." } else { "Reconsider only if the gating reason changes or new validated local evidence appears." })
    )) | Out-Null
}
foreach ($review in @(Convert-ToArray -Value (Get-PropValue -Object $teacherDecisionLog -Name "teacher_response_reviews" -Default @()))) {
    if ((Normalize-Text (Get-PropValue -Object $review -Name "classification" -Default "")).ToLowerInvariant() -ne "reject") { continue }
    $teacherItemId = Normalize-Text (Get-PropValue -Object $review -Name "teacher_item_id" -Default "")
    $antiRepeatEntries.Add((New-AntiRepeatEntry `
        -IdeaKey ("teacher:{0}" -f $teacherItemId) `
        -Domain (Normalize-Text (Get-PropValue -Object $review -Name "domain" -Default "teacher")) `
        -Component (Normalize-Text (Get-PropValue -Object $review -Name "area" -Default "teacher")) `
        -Title (Normalize-Text (Get-PropValue -Object $review -Name "title" -Default $teacherItemId)) `
        -FailureReason ("Teacher material was rejected with total_score={0}." -f (Convert-ToDouble -Value (Get-PropValue -Object $review -Name "total_score" -Default 0.0))) `
        -Evidence @(Convert-ToArray -Value (Get-PropValue -Object $review -Name "evidence" -Default @())) `
        -BlockPosture "blocked" `
        -ReconsiderationRequirement "Only reconsider if fresh local evidence materially changes the grounding or safety posture." `
        -LinkedCardId ("card_teacher_{0}" -f $teacherItemId)
    )) | Out-Null
}
$antiRepeatEntries = @($antiRepeatEntries.ToArray())

$minReuse = Get-PropValue -Object $policy -Name "minimum_score_for_reuse" -Default @{}
$minAction = Get-PropValue -Object $policy -Name "minimum_score_for_action_influence" -Default @{}
$cards = New-Object System.Collections.Generic.List[object]
$seedCards = @($seedCards.ToArray())
foreach ($seed in $seedCards) {
    $cardId = Normalize-Text (Get-PropValue -Object $seed -Name "card_id" -Default "")
    $priorCard = $null
    if ($cardId -and $previousById.ContainsKey($cardId)) { $priorCard = $previousById[$cardId] }
    $sourceRefs = @(Convert-ToArray -Value (Get-PropValue -Object $seed -Name "source_refs" -Default @()))
    $sourceType = Normalize-Text (Get-PropValue -Object $seed -Name "source_type" -Default "unknown")
    $provenanceClass = Normalize-Text (Get-PropValue -Object $seed -Name "provenance_class" -Default "inferred_synthesis")
    $executionSupport = Normalize-Text (Get-PropValue -Object $seed -Name "execution_support" -Default "artifact_supported")
    $outcomeSupport = Normalize-Text (Get-PropValue -Object $seed -Name "outcome_support" -Default "unknown")
    $freshnessScore = Get-FreshnessScore -LastVerifiedAt (Normalize-Text (Get-PropValue -Object $seed -Name "last_verified_at" -Default "")) -Domain (Normalize-Text (Get-PropValue -Object $seed -Name "domain" -Default "knowledge")) -ProvenanceClass $provenanceClass
    $contradictionCount = Convert-ToInt -Value (Get-PropValue -Object $seed -Name "contradiction_count" -Default 0)
    $sourceBase = Get-BaseScore -ProvenanceClass $provenanceClass
    $evidenceScore = Clamp-Score -Value ($sourceBase + ([Math]::Min((@($sourceRefs).Count - 1) * 6.0, 18.0)) + ($freshnessScore * 0.12) + (Get-ExecutionSupportModifier -ExecutionSupport $executionSupport) + (Get-OutcomeSupportModifier -OutcomeSupport $outcomeSupport) + ((Convert-ToDouble -Value (Get-PropValue -Object $seed -Name "source_quality_score" -Default 0.0)) * 0.15) - ($contradictionCount * 10.0))
    $confidenceScore = Clamp-Score -Value (($evidenceScore * 0.55) + ($freshnessScore * 0.20) + ([Math]::Min((Convert-ToInt -Value (Get-PropValue -Object $seed -Name "success_count" -Default 0)) * 6.0, 18.0)) - ([Math]::Min((Convert-ToInt -Value (Get-PropValue -Object $seed -Name "failure_count" -Default 0)) * 8.0, 24.0)) - ([Math]::Min((Convert-ToInt -Value (Get-PropValue -Object $seed -Name "rejection_count" -Default 0)) * 10.0, 25.0)) + ([Math]::Min((Convert-ToInt -Value (Get-PropValue -Object $priorCard -Name "use_count" -Default 0)) * 1.5, 12.0)) - ($contradictionCount * 7.0))
    $antiRepeatFlag = Convert-ToBool -Value (Get-PropValue -Object $seed -Name "explicit_anti_repeat" -Default $false)
    if (-not $antiRepeatFlag -and (Convert-ToInt -Value (Get-PropValue -Object $seed -Name "rejection_count" -Default 0)) -ge (Convert-ToInt -Value (Get-PropValue -Object $policy.anti_repeat_thresholds -Name "rejection_count_block" -Default 1))) { $antiRepeatFlag = $true }
    if ($antiRepeatFlag) { $confidenceScore = [Math]::Min($confidenceScore, 24.0) }
    $confidenceBand = Get-ConfidenceBand -Score $confidenceScore
    $reviewStatus = "trusted"
    if ($antiRepeatFlag -or (Normalize-Text (Get-PropValue -Object $seed -Name "review_state" -Default "")) -eq "blocked" -or $confidenceBand -eq "blocked") {
        $reviewStatus = "blocked"
    } elseif ($sourceType -eq "teacher_review" -or (Normalize-Text (Get-PropValue -Object $seed -Name "review_state" -Default "")) -eq "review_required" -or $confidenceBand -in @("usable_with_review", "caution")) {
        $reviewStatus = "review_required"
    }
    $reuseEligible = (-not $antiRepeatFlag -and $reviewStatus -ne "blocked" -and $evidenceScore -ge (Convert-ToDouble -Value (Get-PropValue -Object $minReuse -Name "evidence_score" -Default 60.0)) -and $confidenceScore -ge (Convert-ToDouble -Value (Get-PropValue -Object $minReuse -Name "confidence_score" -Default 55.0)) -and $freshnessScore -ge (Convert-ToDouble -Value (Get-PropValue -Object $minReuse -Name "freshness_score" -Default 35.0)))
    $actionEligible = ($reuseEligible -and $sourceType -ne "teacher_review" -and $evidenceScore -ge (Convert-ToDouble -Value (Get-PropValue -Object $minAction -Name "evidence_score" -Default 75.0)) -and $confidenceScore -ge (Convert-ToDouble -Value (Get-PropValue -Object $minAction -Name "confidence_score" -Default 70.0)) -and $freshnessScore -ge (Convert-ToDouble -Value (Get-PropValue -Object $minAction -Name "freshness_score" -Default 50.0)))
    $allowedModes = @(Get-BaseAllowedModes -SourceType $sourceType)
    if ($actionEligible) { $allowedModes += "action_influence" }
    if ($reviewStatus -ne "blocked") { $allowedModes += "history_review" }
    $blockedModes = @()
    if ($sourceType -eq "teacher_review") { $blockedModes += @("action_influence", "autonomous_action", "recommendation_priority") }
    if ($antiRepeatFlag) { $blockedModes += @("knowledge_reuse", "action_influence", "autonomous_action", "recommendation_priority") } elseif (-not $reuseEligible) { $blockedModes += "knowledge_reuse" }
    if (-not $actionEligible) { $blockedModes += "action_influence" }
    $cards.Add([pscustomobject]@{
        card_id = $cardId
        title = Normalize-ShortText -Value (Get-PropValue -Object $seed -Name "title" -Default $cardId) -MaxLength 140
        domain = Normalize-Text (Get-PropValue -Object $seed -Name "domain" -Default "knowledge")
        component = Normalize-Text (Get-PropValue -Object $seed -Name "component" -Default "")
        topic = Normalize-Text (Get-PropValue -Object $seed -Name "topic" -Default "")
        summary = Normalize-ShortText -Value (Get-PropValue -Object $seed -Name "summary" -Default "") -MaxLength 420
        source_refs = @($sourceRefs)
        source_type = $sourceType
        provenance_class = $provenanceClass
        evidence_score = $evidenceScore
        evidence_band = Get-EvidenceBand -Score $evidenceScore
        confidence_score = $confidenceScore
        confidence_band = $confidenceBand
        freshness_score = $freshnessScore
        freshness_band = Get-FreshnessBand -Score $freshnessScore
        contradiction_count = $contradictionCount
        last_verified_at = Normalize-Text (Get-PropValue -Object $seed -Name "last_verified_at" -Default "")
        first_seen_at = Normalize-Text (Get-PropValue -Object $priorCard -Name "first_seen_at" -Default $(if (Normalize-Text (Get-PropValue -Object $seed -Name "last_verified_at" -Default "")) { Normalize-Text (Get-PropValue -Object $seed -Name "last_verified_at" -Default "") } else { $nowUtcText }))
        last_used_at = Normalize-Text (Get-PropValue -Object $priorCard -Name "last_used_at" -Default "")
        use_count = Convert-ToInt -Value (Get-PropValue -Object $priorCard -Name "use_count" -Default 0)
        success_count = Convert-ToInt -Value (Get-PropValue -Object $seed -Name "success_count" -Default 0)
        failure_count = Convert-ToInt -Value (Get-PropValue -Object $seed -Name "failure_count" -Default 0)
        rejection_count = Convert-ToInt -Value (Get-PropValue -Object $seed -Name "rejection_count" -Default 0)
        review_status = $reviewStatus
        execution_support = $executionSupport
        outcome_support = $outcomeSupport
        anti_repeat_flag = $antiRepeatFlag
        allowed_use_modes = Normalize-StringList -Value $allowedModes -MaxItems 12 -MaxLength 120
        blocked_use_modes = Normalize-StringList -Value $blockedModes -MaxItems 12 -MaxLength 120
        notes_for_reviewer = Normalize-StringList -Value @((Get-PropValue -Object $seed -Name "notes_for_reviewer" -Default ""), $(if ($sourceType -eq "teacher_review") { "Teacher-originated material remains local-first and review-gated until it passes the quality floor." } else { "" }), $(if ($antiRepeatFlag) { "Anti-repeat memory is active for this card." } else { "" })) -MaxItems 6 -MaxLength 200
        stale = ((Get-FreshnessBand -Score $freshnessScore) -eq "stale")
        reuse_eligible = $reuseEligible
        action_eligible = $actionEligible
    }) | Out-Null
}
$cards = @($cards.ToArray())

$selectedCards = @($cards | Where-Object { $_.reuse_eligible } | Sort-Object @{ Expression = { $_.confidence_score }; Descending = $true }, @{ Expression = { $_.evidence_score }; Descending = $true }, @{ Expression = { $_.freshness_score }; Descending = $true }, title)
$selectedIdSet = @{}
foreach ($selectedCard in $selectedCards) { $selectedIdSet[$selectedCard.card_id] = $true }
foreach ($card in @($cards)) {
    if ($selectedIdSet.ContainsKey($card.card_id)) {
        $card.use_count = [int]$card.use_count + 1
        $card.last_used_at = $nowUtcText
    }
}

$blockedCards = @($cards | Where-Object { $_.blocked_use_modes -contains "knowledge_reuse" } | ForEach-Object {
    [pscustomobject]@{ card_id = $_.card_id; title = $_.title; confidence_band = $_.confidence_band; freshness_band = $_.freshness_band; reason = $(if ($_.anti_repeat_flag) { "anti_repeat_blocked" } else { "policy_or_quality_blocked" }); anti_repeat_flag = $_.anti_repeat_flag; review_status = $_.review_status }
})
$suppressedCards = @($cards | Where-Object { -not $_.reuse_eligible -and -not ($_.blocked_use_modes -contains "knowledge_reuse") } | ForEach-Object {
    [pscustomobject]@{ card_id = $_.card_id; title = $_.title; confidence_band = $_.confidence_band; freshness_band = $_.freshness_band; reason = "below_reuse_threshold"; review_status = $_.review_status }
})
$weakTeacherItems = @($cards | Where-Object { $_.source_type -eq "teacher_review" -and $_.review_status -ne "trusted" } | ForEach-Object {
    [pscustomobject]@{ card_id = $_.card_id; title = $_.title; confidence_band = $_.confidence_band; review_status = $_.review_status; freshness_band = $_.freshness_band; notes_for_reviewer = @($_.notes_for_reviewer) }
})
$recentReusedCards = @($selectedCards | Select-Object -First 6 | ForEach-Object {
    [pscustomobject]@{ card_id = $_.card_id; title = $_.title; confidence_band = $_.confidence_band; evidence_band = $_.evidence_band; freshness_band = $_.freshness_band; why_selected = Normalize-ShortText -Value ("confidence={0}; evidence={1}; freshness={2}" -f $_.confidence_band, $_.evidence_band, $_.freshness_band) -MaxLength 180; last_used_at = $_.last_used_at; source_type = $_.source_type }
})

$trustBandCounts = [ordered]@{ trusted = @($cards | Where-Object { $_.confidence_band -eq "trusted" }).Count; usable_with_review = @($cards | Where-Object { $_.confidence_band -eq "usable_with_review" }).Count; caution = @($cards | Where-Object { $_.confidence_band -eq "caution" }).Count; blocked = @($cards | Where-Object { $_.confidence_band -eq "blocked" }).Count }
$evidenceBandCounts = [ordered]@{ high_evidence = @($cards | Where-Object { $_.evidence_band -eq "high_evidence" }).Count; medium_evidence = @($cards | Where-Object { $_.evidence_band -eq "medium_evidence" }).Count; low_evidence = @($cards | Where-Object { $_.evidence_band -eq "low_evidence" }).Count; rejected_evidence = @($cards | Where-Object { $_.evidence_band -eq "rejected_evidence" }).Count }
$freshnessBandCounts = [ordered]@{ fresh = @($cards | Where-Object { $_.freshness_band -eq "fresh" }).Count; recent = @($cards | Where-Object { $_.freshness_band -eq "recent" }).Count; aging = @($cards | Where-Object { $_.freshness_band -eq "aging" }).Count; stale = @($cards | Where-Object { $_.freshness_band -eq "stale" }).Count }

$scoreUpdates = @($cards | ForEach-Object {
    $priorCard = if ($previousById.ContainsKey($_.card_id)) { $previousById[$_.card_id] } else { $null }
    $reasons = @()
    if ($null -eq $priorCard) { $reasons += "new_card_discovered" }
    else {
        if ([Math]::Abs($_.evidence_score - (Convert-ToDouble -Value (Get-PropValue -Object $priorCard -Name "evidence_score" -Default 0.0))) -ge 0.5) { $reasons += "evidence_score_changed" }
        if ([Math]::Abs($_.confidence_score - (Convert-ToDouble -Value (Get-PropValue -Object $priorCard -Name "confidence_score" -Default 0.0))) -ge 0.5) { $reasons += "confidence_score_changed" }
        if ($_.outcome_support -ne (Normalize-Text (Get-PropValue -Object $priorCard -Name "outcome_support" -Default ""))) { $reasons += "outcome_support_changed" }
        if ($_.contradiction_count -ne (Convert-ToInt -Value (Get-PropValue -Object $priorCard -Name "contradiction_count" -Default 0))) { $reasons += "contradiction_count_changed" }
    }
    if ($reasons.Count -eq 0) { $reasons = @("no_material_change") }
    [pscustomobject]@{
        card_id = $_.card_id
        title = $_.title
        prior_evidence_score = if ($null -ne $priorCard) { Convert-ToDouble -Value (Get-PropValue -Object $priorCard -Name "evidence_score" -Default 0.0) } else { $null }
        new_evidence_score = $_.evidence_score
        prior_confidence_score = if ($null -ne $priorCard) { Convert-ToDouble -Value (Get-PropValue -Object $priorCard -Name "confidence_score" -Default 0.0) } else { $null }
        new_confidence_score = $_.confidence_score
        prior_freshness_score = if ($null -ne $priorCard) { Convert-ToDouble -Value (Get-PropValue -Object $priorCard -Name "freshness_score" -Default 0.0) } else { $null }
        new_freshness_score = $_.freshness_score
        why_it_changed = @($reasons)
        source_of_change = "current_artifact_refresh"
        outcome_evidence_affected = $reasons -contains "outcome_support_changed"
        contradiction_affected = $reasons -contains "contradiction_count_changed"
        anti_repeat_triggered = (Convert-ToBool -Value $_.anti_repeat_flag -Default $false) -and ($null -eq $priorCard -or -not (Convert-ToBool -Value (Get-PropValue -Object $priorCard -Name "anti_repeat_flag" -Default $false)))
        became_blocked = ($_.review_status -eq "blocked") -and ($null -eq $priorCard -or (Normalize-Text (Get-PropValue -Object $priorCard -Name "review_status" -Default "")) -ne "blocked")
        became_reusable = $_.reuse_eligible -and ($null -eq $priorCard -or -not (Convert-ToBool -Value (Get-PropValue -Object $priorCard -Name "reuse_eligible" -Default $false)))
    }
})

$overallStatus = if (@($cards).Count -eq 0) { "FAIL" } elseif (@($weakTeacherItems).Count -gt 0 -or @($blockedCards).Count -gt 0 -or @($cards | Where-Object { $_.stale }).Count -gt 0) { "WARN" } else { "PASS" }
$recommendedNextAction = "Keep reusing fresh, high-confidence local knowledge first."
if (@($weakTeacherItems).Count -gt 0) { $recommendedNextAction = "Review low-confidence teacher material before letting it influence recommendations or actions." }
elseif (@($cards | Where-Object { $_.stale }).Count -gt 0) { $recommendedNextAction = "Re-verify stale operational knowledge before relying on it in action paths." }
elseif (@($antiRepeatEntries).Count -gt 0) { $recommendedNextAction = "Respect anti-repeat memory and require fresh evidence before resurfacing blocked ideas." }

$knowledgeQualityArtifact = [ordered]@{
    timestamp_utc = $nowUtcText
    overall_status = $overallStatus
    card_count = @($cards).Count
    reusable_card_count = @($selectedCards).Count
    stale_card_count = @($cards | Where-Object { $_.stale }).Count
    blocked_card_count = @($cards | Where-Object { $_.review_status -eq "blocked" }).Count
    review_card_count = @($cards | Where-Object { $_.review_status -eq "review_required" }).Count
    anti_repeat_count = @($antiRepeatEntries).Count
    low_confidence_teacher_count = @($weakTeacherItems).Count
    trust_band_counts = $trustBandCounts
    evidence_band_counts = $evidenceBandCounts
    freshness_band_counts = $freshnessBandCounts
    recent_reused_cards = @($recentReusedCards)
    low_confidence_teacher_material = @($weakTeacherItems | Select-Object -First 8)
    recommended_next_action = $recommendedNextAction
    command_run = $commandRun
    repo_root = $repoRoot
}
$knowledgeCardsArtifact = [ordered]@{ timestamp_utc = $nowUtcText; overall_status = $overallStatus; card_count = @($cards).Count; trusted_card_count = $trustBandCounts.trusted; review_required_count = @($cards | Where-Object { $_.review_status -eq "review_required" }).Count; blocked_card_count = @($cards | Where-Object { $_.review_status -eq "blocked" }).Count; stale_card_count = @($cards | Where-Object { $_.stale }).Count; recommended_next_action = $recommendedNextAction; cards = @($cards | Sort-Object @{ Expression = { $_.confidence_score }; Descending = $true }, @{ Expression = { $_.evidence_score }; Descending = $true }, title); command_run = $commandRun; repo_root = $repoRoot }
$knowledgeReuseArtifact = [ordered]@{ timestamp_utc = $nowUtcText; overall_status = $overallStatus; reuse_candidate_count = @($cards).Count; selected_card_count = @($selectedCards).Count; suppressed_card_count = @($suppressedCards).Count; blocked_card_count = @($blockedCards).Count; stale_card_count = @($cards | Where-Object { $_.stale }).Count; weak_card_count = @($cards | Where-Object { $_.confidence_band -in @("caution", "blocked") }).Count; selected_cards = @($selectedCards | Select-Object -First 12 | ForEach-Object { [pscustomobject]@{ card_id = $_.card_id; title = $_.title; confidence_band = $_.confidence_band; evidence_band = $_.evidence_band; freshness_band = $_.freshness_band; why_selected = Normalize-ShortText -Value ("evidence={0}; confidence={1}; freshness={2}" -f $_.evidence_band, $_.confidence_band, $_.freshness_band) -MaxLength 180; allowed_use_modes = @($_.allowed_use_modes) } }); suppressed_cards = @($suppressedCards | Select-Object -First 16); blocked_cards = @($blockedCards | Select-Object -First 16); recent_reused_cards = @($recentReusedCards); low_confidence_teacher_material = @($weakTeacherItems | Select-Object -First 8); recommended_next_action = $recommendedNextAction; command_run = $commandRun; repo_root = $repoRoot }
$antiRepeatArtifact = [ordered]@{ timestamp_utc = $nowUtcText; overall_status = if (@($antiRepeatEntries).Count -gt 0) { "WARN" } else { "PASS" }; anti_repeat_count = @($antiRepeatEntries).Count; blocked_count = @($antiRepeatEntries | Where-Object { $_.block_posture -eq "blocked" }).Count; review_gated_count = @($antiRepeatEntries | Where-Object { $_.block_posture -ne "blocked" }).Count; recommended_next_action = if (@($antiRepeatEntries).Count -gt 0) { "Only reconsider blocked ideas when new validated evidence changes the case." } else { "No anti-repeat issues are currently recorded." }; entries = @($antiRepeatEntries); command_run = $commandRun; repo_root = $repoRoot }
$outcomeLearningArtifact = [ordered]@{ timestamp_utc = $nowUtcText; overall_status = if (@($cards).Count -gt 0) { "PASS" } else { "FAIL" }; update_count = @($scoreUpdates).Count; outcome_supported_count = @($cards | Where-Object { $_.outcome_support -in @("positive", "mixed") }).Count; contradiction_adjusted_count = @($cards | Where-Object { $_.contradiction_count -gt 0 }).Count; anti_repeat_triggered_count = @($scoreUpdates | Where-Object { $_.anti_repeat_triggered }).Count; score_updates = @($scoreUpdates); recommended_next_action = "Use outcome-backed score changes to keep strong cards near the top and failed ideas out of action paths."; command_run = $commandRun; repo_root = $repoRoot }

Write-JsonFile -Path $knowledgeQualityLastPath -Data $knowledgeQualityArtifact
Write-JsonFile -Path $knowledgeCardsLastPath -Data $knowledgeCardsArtifact
Write-JsonFile -Path $knowledgeReuseLastPath -Data $knowledgeReuseArtifact
Write-JsonFile -Path $antiRepeatMemoryLastPath -Data $antiRepeatArtifact
Write-JsonFile -Path $outcomeLearningLastPath -Data $outcomeLearningArtifact
Write-JsonFile -Path $knowledgeCardsStatePath -Data ([ordered]@{ generated_at_utc = $nowUtcText; overall_status = $overallStatus; card_count = @($cards).Count; cards = @($knowledgeCardsArtifact.cards) })
Write-JsonFile -Path $knowledgeFailuresStatePath -Data ([ordered]@{ generated_at_utc = $nowUtcText; failure_count = @($antiRepeatEntries).Count; failures = @($antiRepeatEntries) })
Write-JsonFile -Path $knowledgeOutcomesStatePath -Data ([ordered]@{ generated_at_utc = $nowUtcText; outcome_count = @($cards).Count; outcomes = @($cards | ForEach-Object { [pscustomobject]@{ card_id = $_.card_id; title = $_.title; outcome_support = $_.outcome_support; success_count = $_.success_count; failure_count = $_.failure_count; rejection_count = $_.rejection_count; confidence_score = $_.confidence_score; review_status = $_.review_status } }) })
Write-JsonFile -Path $knowledgeReuseHistoryPath -Data ([ordered]@{ generated_at_utc = $nowUtcText; latest_selected_card_ids = @($selectedCards | Select-Object -First 12 | ForEach-Object { $_.card_id }); latest_blocked_card_ids = @($blockedCards | Select-Object -First 20 | ForEach-Object { $_.card_id }); recent_runs = @([pscustomobject]@{ timestamp_utc = $nowUtcText; selected_card_ids = @($selectedCards | Select-Object -First 12 | ForEach-Object { $_.card_id }); blocked_card_ids = @($blockedCards | Select-Object -First 20 | ForEach-Object { $_.card_id }); suppressed_card_ids = @($suppressedCards | Select-Object -First 20 | ForEach-Object { $_.card_id }); low_confidence_teacher = @($weakTeacherItems | Select-Object -First 10 | ForEach-Object { $_.card_id }) }) + @((Convert-ToArray -Value (Get-PropValue -Object $previousKnowledgeReuse -Name "recent_runs" -Default @())) | Select-Object -First 19) })

Write-Output ($knowledgeQualityArtifact | ConvertTo-Json -Depth 8)
