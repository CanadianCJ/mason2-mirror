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
        [int]$MaxItems = 64,
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

function Get-DateTimeOffsetSafe {
    param([AllowNull()][object]$Value)

    $text = Normalize-Text $Value
    if (-not $text) {
        return $null
    }

    $parsed = [DateTimeOffset]::MinValue
    if ([DateTimeOffset]::TryParse($text, [ref]$parsed)) {
        return $parsed.ToUniversalTime()
    }

    return $null
}

function Get-ConfidenceLabel {
    param([double]$Score)

    if ($Score -ge 0.8) { return "high" }
    if ($Score -ge 0.5) { return "medium" }
    if ($Score -gt 0.0) { return "low" }
    return "unknown"
}

function Add-UniqueReason {
    param(
        [System.Collections.Generic.List[string]]$List,
        [AllowNull()][object]$Value
    )

    $text = Normalize-ShortText -Value $Value -MaxLength 180
    if (-not $text) {
        return
    }
    if (-not $List.Contains($text)) {
        [void]$List.Add($text)
    }
}

function Convert-ToInt {
    param(
        [AllowNull()][object]$Value,
        [int]$Default = 0
    )

    $parsed = 0
    if ([int]::TryParse((Normalize-Text $Value), [ref]$parsed)) {
        return [int]$parsed
    }
    return [int]$Default
}

function Convert-ToDouble {
    param(
        [AllowNull()][object]$Value,
        [double]$Default = 0.0
    )

    $parsed = 0.0
    if ([double]::TryParse((Normalize-Text $Value), [ref]$parsed)) {
        return [double]$parsed
    }
    return [double]$Default
}

function Convert-ToBool {
    param(
        [AllowNull()][object]$Value,
        [bool]$Default = $false
    )

    if ($null -eq $Value) {
        return [bool]$Default
    }
    if ($Value -is [bool]) {
        return [bool]$Value
    }
    $text = (Normalize-Text $Value).ToLowerInvariant()
    if ($text -in @("true", "1", "yes", "y")) {
        return $true
    }
    if ($text -in @("false", "0", "no", "n")) {
        return $false
    }
    return [bool]$Default
}

function Get-TaskSourceItems {
    param(
        [AllowNull()][object]$GovernorArtifact,
        [AllowNull()][object]$DecisionLogArtifact,
        [AllowNull()][object]$ImprovementQueueArtifact
    )

    $items = @()

    $governorItems = @((Get-PropValue -Object $GovernorArtifact -Name "items" -Default @()))
    if ($governorItems.Count -gt 0) {
        return ,@($governorItems)
    }

    $decisionItems = @((Get-PropValue -Object $DecisionLogArtifact -Name "improvement_decisions" -Default @()))
    if ($decisionItems.Count -gt 0) {
        return ,@($decisionItems)
    }

    $queueItems = @((Get-PropValue -Object $ImprovementQueueArtifact -Name "items" -Default @()))
    if ($queueItems.Count -gt 0) {
        return ,@($queueItems)
    }

    return ,@($items)
}

function Get-TaskClass {
    param(
        [string]$TeacherCallClassification,
        [string]$TargetType,
        [bool]$BlockedByLocalFirst,
        [string]$RiskLevel,
        [int]$ExpectedValue,
        [int]$FallbackQuality
    )

    $classification = (Normalize-Text $TeacherCallClassification).ToLowerInvariant()
    $target = (Normalize-Text $TargetType).ToLowerInvariant()
    $risk = (Normalize-Text $RiskLevel).ToUpperInvariant()

    if ($target -in @("billing", "security")) {
        return "teacher_blocked"
    }
    if ($classification -eq "blocked_pending_human_review") {
        return "teacher_blocked"
    }
    if ($classification -eq "trivial_local_only") {
        return "local_only"
    }
    if ($BlockedByLocalFirst -or $classification -eq "local_first_teacher_optional") {
        return "local_preferred"
    }
    if ($classification -eq "teacher_required_high_value_only") {
        return "teacher_high_value_only"
    }
    if ($classification -in @("teacher_required_standard", "teacher_required_low_cost")) {
        return "teacher_optional"
    }
    if ($risk -in @("R3", "R4", "R5")) {
        return "teacher_blocked"
    }
    if ($FallbackQuality -ge 80 -or $ExpectedValue -lt 80) {
        return "local_preferred"
    }
    return "teacher_optional"
}

function Get-BudgetClass {
    param(
        [string]$TaskClass,
        [string]$EstimatedCostTier,
        [int]$ExpectedValue,
        [string]$RiskLevel
    )

    $taskClassNormalized = (Normalize-Text $TaskClass).ToLowerInvariant()
    $estimatedTier = (Normalize-Text $EstimatedCostTier).ToLowerInvariant()
    $risk = (Normalize-Text $RiskLevel).ToUpperInvariant()

    switch ($taskClassNormalized) {
        "local_only" { return "none" }
        "teacher_blocked" { return "none" }
        "local_preferred" {
            if ($estimatedTier -in @("low", "minimal", "none")) {
                return "minimal"
            }
            return "guarded"
        }
        "teacher_optional" {
            if ($estimatedTier -eq "high") {
                return "moderate"
            }
            if ($estimatedTier -eq "low") {
                return "minimal"
            }
            return "guarded"
        }
        "teacher_high_value_only" {
            if ($risk -in @("R3", "R4", "R5") -or $ExpectedValue -ge 90) {
                return "elevated_with_approval"
            }
            return "moderate"
        }
        default { return "guarded" }
    }
}

function Get-TeacherUsefulnessClassification {
    param(
        [string]$Classification,
        [double]$TotalScore,
        [int]$GroundingEvidence,
        [int]$ReferencedActionPathsFound
    )

    $normalized = (Normalize-Text $Classification).ToLowerInvariant()
    if ($normalized -eq "reject") {
        return "reject"
    }
    if ($TotalScore -ge 80.0 -and $GroundingEvidence -ge 70 -and $ReferencedActionPathsFound -gt 0) {
        return "useful"
    }
    if ($TotalScore -ge 72.0) {
        return "mixed"
    }
    if ($TotalScore -ge 55.0) {
        return "low_value"
    }
    return "reject"
}

function Get-ReuseLikelihood {
    param(
        [string]$UsefulnessClassification,
        [int]$ReferencedActionPathsFound
    )

    $normalized = (Normalize-Text $UsefulnessClassification).ToLowerInvariant()
    if ($normalized -eq "useful" -and $ReferencedActionPathsFound -gt 0) {
        return "likely"
    }
    if ($normalized -eq "mixed") {
        return "possible"
    }
    if ($normalized -eq "low_value") {
        return "unlikely"
    }
    return "reject"
}

function Invoke-MirrorRefresh {
    param(
        [string]$RepoRoot,
        [string]$MirrorScriptPath,
        [string]$MirrorReportPath,
        [int]$FreshArtifactMinutes = 30
    )

    $result = [ordered]@{
        attempted = $false
        integrated = $false
        used_existing_artifact = $false
        exit_code = $null
        refresh_status = "missing"
        ok = $false
        phase = "missing"
        mirror_push_result = ""
        next_action = ""
        source_path = $MirrorReportPath
        artifact_timestamp_utc = ""
        artifact_age_minutes = $null
        raw_output = @()
    }

    $existingMirrorArtifact = Read-JsonSafe -Path $MirrorReportPath
    $existingTimestamp = $null
    $existingAgeMinutes = $null
    if ($existingMirrorArtifact) {
        $existingTimestamp = Get-DateTimeOffsetSafe (Get-PropValue -Object $existingMirrorArtifact -Name "timestamp_utc" -Default "")
        if ($existingTimestamp) {
            $existingAgeMinutes = [Math]::Round(((Get-Date).ToUniversalTime() - $existingTimestamp.UtcDateTime).TotalMinutes, 2)
            $result.artifact_timestamp_utc = $existingTimestamp.ToString("o")
            $result.artifact_age_minutes = $existingAgeMinutes
        }
    }

    $hydrateFromArtifact = {
        param([AllowNull()][object]$MirrorArtifact)

        if (-not $MirrorArtifact) {
            return
        }

        $result.ok = Convert-ToBool (Get-PropValue -Object $MirrorArtifact -Name "ok" -Default $false)
        $result.phase = Normalize-Text (Get-PropValue -Object $MirrorArtifact -Name "phase" -Default "")
        $result.mirror_push_result = Normalize-Text (Get-PropValue -Object $MirrorArtifact -Name "mirror_push_result" -Default "")
        $result.next_action = Normalize-ShortText -Value (Get-PropValue -Object $MirrorArtifact -Name "next_action" -Default "") -MaxLength 220
        if ($result.ok -and $result.phase.ToLowerInvariant() -eq "done") {
            if ($result.mirror_push_result -match "local_commit_only") {
                $result.refresh_status = "local_checkpoint_only"
            }
            else {
                $result.refresh_status = "success"
            }
        }
        elseif ($result.phase) {
            $result.refresh_status = "degraded"
        }
        else {
            $result.refresh_status = "failed"
        }
    }

    if ($existingMirrorArtifact -and $existingTimestamp -and $existingAgeMinutes -le $FreshArtifactMinutes) {
        & $hydrateFromArtifact $existingMirrorArtifact
        $result.integrated = $true
        $result.used_existing_artifact = $true
        if (-not $result.next_action) {
            $result.next_action = "Current canonical mirror artifact is already fresh."
        }
        return [pscustomobject]$result
    }

    if (-not (Test-Path -LiteralPath $MirrorScriptPath)) {
        $result.refresh_status = "missing_script"
        $result.next_action = "Restore tools/sync/Mason_Mirror_Update.ps1 so the canonical mirror flow can run."
        return [pscustomobject]$result
    }

    $result.attempted = $true
    $outputLines = @()
    try {
        $outputLines = @(& powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $MirrorScriptPath -RootPath $RepoRoot -Reason "model-cost-governance" 2>&1 | ForEach-Object { [string]$_ })
        $result.exit_code = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
    }
    catch {
        $outputLines = @($_.Exception.Message)
        $result.exit_code = 1
    }
    $result.raw_output = Normalize-StringList -Value $outputLines -MaxItems 24 -MaxLength 220

    $mirrorArtifact = Read-JsonSafe -Path $MirrorReportPath
    if ($mirrorArtifact) {
        $mirrorTimestamp = Get-DateTimeOffsetSafe (Get-PropValue -Object $mirrorArtifact -Name "timestamp_utc" -Default "")
        if ($mirrorTimestamp) {
            $result.artifact_timestamp_utc = $mirrorTimestamp.ToString("o")
            $result.artifact_age_minutes = [Math]::Round(((Get-Date).ToUniversalTime() - $mirrorTimestamp.UtcDateTime).TotalMinutes, 2)
        }
        & $hydrateFromArtifact $mirrorArtifact
    }
    else {
        $result.refresh_status = "missing_artifact"
        if (-not $result.next_action) {
            $result.next_action = "Inspect the mirror flow and ensure reports/mirror_update_last.json is written."
        }
    }

    return [pscustomobject]$result
}

$repoRoot = Resolve-RepoRoot -ExplicitRoot $RepoRoot
$reportsDir = Join-Path $repoRoot "reports"
$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"
$configDir = Join-Path $repoRoot "config"
$toolsSyncDir = Join-Path $repoRoot "tools\sync"

$systemValidationPath = Join-Path $reportsDir "system_validation_last.json"
$systemTruthPath = Join-Path $reportsDir "system_truth_spine_last.json"
$regressionGuardPath = Join-Path $reportsDir "regression_guard_last.json"
$releaseManagementPath = Join-Path $reportsDir "release_management_last.json"
$keepAlivePath = Join-Path $reportsDir "keepalive_last.json"
$businessOutcomesPath = Join-Path $reportsDir "business_outcomes_last.json"
$supportBrainPath = Join-Path $reportsDir "support_brain_last.json"
$selfImprovementGovernorPath = Join-Path $reportsDir "self_improvement_governor_last.json"
$teacherCallBudgetPath = Join-Path $reportsDir "teacher_call_budget_last.json"
$teacherDecisionLogPath = Join-Path $reportsDir "teacher_decision_log_last.json"
$improvementQueuePath = Join-Path $stateKnowledgeDir "improvement_queue.json"
$toolRegistryPath = Join-Path $configDir "tool_registry.json"
$capabilityScorecardPath = Join-Path $reportsDir "capability_scorecard_last.json"
$changeBudgetPath = Join-Path $reportsDir "change_budget_last.json"
$promotionThrottlePath = Join-Path $reportsDir "promotion_throttle_last.json"
$mirrorUpdatePath = Join-Path $reportsDir "mirror_update_last.json"
$mirrorScriptPath = Join-Path $toolsSyncDir "Mason_Mirror_Update.ps1"

$modelCostGovernancePath = Join-Path $reportsDir "model_cost_governance_last.json"
$taskClassificationPath = Join-Path $reportsDir "task_classification_last.json"
$teacherUsefulnessPath = Join-Path $reportsDir "teacher_usefulness_last.json"
$costEffectivenessPath = Join-Path $reportsDir "cost_effectiveness_last.json"
$modelCostRegistryPath = Join-Path $stateKnowledgeDir "model_cost_registry.json"
$modelCostPolicyPath = Join-Path $configDir "model_cost_governance_policy.json"

$nowUtc = (Get-Date).ToUniversalTime().ToString("o")
$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Model_Cost_Governance.ps1"

$policy = [ordered]@{
    version = 1
    policy_name = "model_cost_governance"
    task_classes = @(
        "local_only",
        "local_preferred",
        "teacher_optional",
        "teacher_high_value_only",
        "teacher_blocked"
    )
    budget_classes = @(
        "none",
        "minimal",
        "guarded",
        "moderate",
        "elevated_with_approval"
    )
    escalation_ladder_rules = @(
        "Stay local-only when existing reports, validators, registries, or playbooks already answer the task well enough.",
        "Use local truth plus internal retrieval before considering any teacher/model escalation.",
        "Allow teacher/model escalation only when the task is high-value, not already solved locally, and the quality floor is met.",
        "Keep low-value, repetitive, or policy-sensitive tasks teacher-blocked even if budget remains."
    )
    local_first_mandatory_classes = @(
        "routine reporting",
        "validator and schema maintenance",
        "artifact refresh",
        "known operational playbook execution"
    )
    teacher_allowed_classes = @(
        "novel strategy with weak local precedent",
        "high-value architecture tradeoffs",
        "domain research with clear downstream value and review"
    )
    teacher_blocked_classes = @(
        "money or billing mutations",
        "security weakening",
        "tenant-impacting unsafe actions",
        "repetitive low-value analysis already answerable locally"
    )
    quality_floor_rules = [ordered]@{
        reusable_minimum_total_score = 75
        reusable_minimum_grounding = 40
        direct_reuse_requires_referenced_action_paths = $true
        reject_if_classification = @("reject")
        queue_for_review_default = "Teacher output stays review-only unless it clears the reusable threshold with grounded evidence."
    }
    usefulness_scoring_rules = @(
        "Useful requires strong score plus grounded or reusable evidence.",
        "Mixed covers good ideas that still need review or stronger grounding.",
        "Low-value covers outputs that cost attention without clear reuse value.",
        "Reject covers weak, unsafe, or ungrounded output."
    )
    cost_effectiveness_rules = @(
        "Low-cost success means local or tightly-scoped work already succeeds without teacher spend.",
        "High-cost low-value means the task would cost more than the current evidence justifies.",
        "Guarded review-only means there is some value, but policy or quality still blocks direct reuse."
    )
    sparse_data_handling = @(
        "Missing capability/change-budget artifacts must remain optional, not fabricated.",
        "Sparse reviewed teacher data must keep the posture guarded."
    )
    mirror_refresh_requirement = @(
        "Use a fresh canonical mirror artifact when it is already current; otherwise invoke tools/sync/Mason_Mirror_Update.ps1.",
        "Treat local checkpoint success with remote push failure as truthful but degraded, not fake green."
    )
    blocked_spend_rules = @(
        "Do not escalate because budget remains.",
        "Do not treat API balance as approval.",
        "Do not loosen local-first posture while validator, regression, or security posture remains WARN."
    )
}
Write-JsonFile -Path $modelCostPolicyPath -Data $policy

$systemValidation = Read-JsonSafe -Path $systemValidationPath
$systemTruth = Read-JsonSafe -Path $systemTruthPath
$regressionGuard = Read-JsonSafe -Path $regressionGuardPath
$releaseManagement = Read-JsonSafe -Path $releaseManagementPath
$keepAlive = Read-JsonSafe -Path $keepAlivePath
$businessOutcomes = Read-JsonSafe -Path $businessOutcomesPath
$supportBrain = Read-JsonSafe -Path $supportBrainPath
$selfImprovementGovernor = Read-JsonSafe -Path $selfImprovementGovernorPath
$teacherCallBudget = Read-JsonSafe -Path $teacherCallBudgetPath
$teacherDecisionLog = Read-JsonSafe -Path $teacherDecisionLogPath
$improvementQueue = Read-JsonSafe -Path $improvementQueuePath
$toolRegistry = Read-JsonSafe -Path $toolRegistryPath
$capabilityScorecard = Read-JsonSafe -Path $capabilityScorecardPath
$changeBudget = Read-JsonSafe -Path $changeBudgetPath
$promotionThrottle = Read-JsonSafe -Path $promotionThrottlePath

$validatorStatus = Normalize-Text (Get-PropValue -Object $systemValidation -Name "overall_status" -Default "")
$systemTruthStatus = Normalize-Text (Get-PropValue -Object $systemTruth -Name "overall_status" -Default "")
$regressionStatus = Normalize-Text (Get-PropValue -Object $regressionGuard -Name "overall_status" -Default "")
$releaseStatus = Normalize-Text (Get-PropValue -Object $releaseManagement -Name "overall_status" -Default "")
$keepAliveStatus = Normalize-Text (Get-PropValue -Object $keepAlive -Name "overall_status" -Default "")
$businessOutcomeStatus = Normalize-Text (Get-PropValue -Object $businessOutcomes -Name "overall_status" -Default "")
$supportBrainStatus = Normalize-Text (Get-PropValue -Object $supportBrain -Name "overall_status" -Default "")
$budgetPosture = Normalize-Text (Get-PropValue -Object $teacherCallBudget -Name "current_budget_posture" -Default "")
$qualityThreshold = Convert-ToInt (Get-PropValue -Object $policy.quality_floor_rules -Name "reusable_minimum_total_score" -Default 75)

$taskSourceItems = Get-TaskSourceItems -GovernorArtifact $selfImprovementGovernor -DecisionLogArtifact $teacherDecisionLog -ImprovementQueueArtifact $improvementQueue
$classifiedTasks = @()
$localOnlyCount = 0
$localPreferredCount = 0
$teacherOptionalCount = 0
$teacherHighValueOnlyCount = 0
$localFirstMandatoryCount = 0
$teacherAllowedCount = 0
$budgetCounts = [ordered]@{
    none = 0
    minimal = 0
    guarded = 0
    moderate = 0
    elevated_with_approval = 0
}

foreach ($item in @($taskSourceItems)) {
    $scores = Get-PropValue -Object $item -Name "scores" -Default $null
    $expectedValue = Convert-ToInt (Get-PropValue -Object $scores -Name "expected_value" -Default (Get-PropValue -Object $item -Name "priority" -Default 0))
    $fallbackQuality = Convert-ToInt (Get-PropValue -Object $scores -Name "fallback_quality_without_teacher" -Default 0)
    $teacherCallClassification = Normalize-Text (Get-PropValue -Object $item -Name "teacher_call_classification" -Default "")
    $targetType = Normalize-Text (Get-PropValue -Object $item -Name "target_type" -Default "")
    $riskLevel = Normalize-Text (Get-PropValue -Object $item -Name "risk_level" -Default "")
    $blockedByLocalFirst = Convert-ToBool (Get-PropValue -Object $item -Name "blocked_by_local_first" -Default $false)
    $estimatedCostTier = Normalize-Text (Get-PropValue -Object $item -Name "estimated_cost_tier" -Default "")
    $executionDisposition = Normalize-Text (Get-PropValue -Object $item -Name "execution_disposition" -Default "")
    $teacherQualityClassification = Normalize-Text (Get-PropValue -Object $item -Name "teacher_quality_classification" -Default "")
    $teacherQualityScore = Convert-ToInt (Get-PropValue -Object $item -Name "teacher_quality_score" -Default 0)

    $taskClass = Get-TaskClass -TeacherCallClassification $teacherCallClassification -TargetType $targetType -BlockedByLocalFirst $blockedByLocalFirst -RiskLevel $riskLevel -ExpectedValue $expectedValue -FallbackQuality $fallbackQuality
    $budgetClass = Get-BudgetClass -TaskClass $taskClass -EstimatedCostTier $estimatedCostTier -ExpectedValue $expectedValue -RiskLevel $riskLevel
    $localFirstMandatory = ($taskClass -in @("local_only", "local_preferred")) -or $blockedByLocalFirst
    $teacherAllowed = ($taskClass -in @("teacher_optional", "teacher_high_value_only")) -and (-not $localFirstMandatory) -and ($budgetClass -ne "none")
    $confidenceScore = 0.45
    if ($teacherCallClassification) { $confidenceScore += 0.20 }
    if ($executionDisposition) { $confidenceScore += 0.10 }
    if ($expectedValue -gt 0) { $confidenceScore += 0.10 }
    if ($riskLevel) { $confidenceScore += 0.05 }

    $rationale = New-Object 'System.Collections.Generic.List[string]'
    Add-UniqueReason -List $rationale -Value ("teacher_call_classification={0}" -f $(if ($teacherCallClassification) { $teacherCallClassification } else { "unknown" }))
    Add-UniqueReason -List $rationale -Value ("execution_disposition={0}" -f $(if ($executionDisposition) { $executionDisposition } else { "unknown" }))
    Add-UniqueReason -List $rationale -Value ("budget_posture={0}" -f $(if ($budgetPosture) { $budgetPosture } else { "unknown" }))
    if ($targetType) {
        Add-UniqueReason -List $rationale -Value ("target_type={0}" -f $targetType)
    }
    if ($riskLevel) {
        Add-UniqueReason -List $rationale -Value ("risk_level={0}" -f $riskLevel)
    }
    if ($fallbackQuality -gt 0) {
        Add-UniqueReason -List $rationale -Value ("fallback_quality_without_teacher={0}" -f $fallbackQuality)
    }
    if ($teacherQualityClassification) {
        Add-UniqueReason -List $rationale -Value ("teacher_quality_classification={0}" -f $teacherQualityClassification)
    }

    $classifiedTasks += [pscustomobject]@{
        task_id_or_type = Normalize-Text (Get-PropValue -Object $item -Name "improvement_id" -Default (Get-PropValue -Object $item -Name "target_id" -Default (Get-PropValue -Object $item -Name "title" -Default "")))
        task_class = $taskClass
        budget_class = $budgetClass
        local_first_mandatory = [bool]$localFirstMandatory
        teacher_allowed = [bool]$teacherAllowed
        rationale = Normalize-StringList -Value $rationale -MaxItems 10 -MaxLength 180
        confidence = Get-ConfidenceLabel -Score $confidenceScore
        title = Normalize-ShortText -Value (Get-PropValue -Object $item -Name "title" -Default "") -MaxLength 160
        target_type = $targetType
        risk_level = $riskLevel
        estimated_cost_tier = if ($estimatedCostTier) { $estimatedCostTier } else { "unknown" }
        execution_disposition = $executionDisposition
        expected_value = [int]$expectedValue
        fallback_quality_without_teacher = [int]$fallbackQuality
        teacher_quality_classification = $teacherQualityClassification
        teacher_quality_score = [int]$teacherQualityScore
    }

    switch ($taskClass) {
        "local_only" { $localOnlyCount++ }
        "local_preferred" { $localPreferredCount++ }
        "teacher_optional" { $teacherOptionalCount++ }
        "teacher_high_value_only" { $teacherHighValueOnlyCount++ }
    }

    if ($localFirstMandatory) {
        $localFirstMandatoryCount++
    }
    if ($teacherAllowed) {
        $teacherAllowedCount++
    }
    if ($budgetCounts.Contains($budgetClass)) {
        $budgetCounts[$budgetClass] = [int]$budgetCounts[$budgetClass] + 1
    }
}

$teacherBlockedCount = [int](@($classifiedTasks | Where-Object { -not $_.teacher_allowed }).Count)

$taskClassificationArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = if ($classifiedTasks.Count -gt 0) { "PASS" } else { "WARN" }
    task_class_total = @($policy.task_classes).Count
    classified_active_items = @($classifiedTasks).Count
    local_only_count = [int]$localOnlyCount
    local_preferred_count = [int]$localPreferredCount
    teacher_optional_count = [int]$teacherOptionalCount
    teacher_high_value_only_count = [int]$teacherHighValueOnlyCount
    teacher_blocked_count = [int]$teacherBlockedCount
    recommended_next_action = if ($teacherAllowedCount -gt 0) { "Keep teacher escalation limited to the explicitly allowed high-value tasks." } else { "Keep the platform local-first and review only exceptional high-value tasks manually." }
    tasks = @($classifiedTasks)
    command_run = $commandRun
    repo_root = $repoRoot
}
Write-JsonFile -Path $taskClassificationPath -Data $taskClassificationArtifact

$teacherReviews = @((Get-PropValue -Object $teacherDecisionLog -Name "teacher_response_reviews" -Default @()))
$teacherUsefulnessRecords = @()
$usefulCount = 0
$mixedCount = 0
$lowValueCount = 0
$rejectCount = 0

foreach ($review in $teacherReviews) {
    $totalScore = Convert-ToDouble (Get-PropValue -Object $review -Name "total_score" -Default 0)
    $groundingEvidence = Convert-ToInt (Get-PropValue -Object $review -Name "grounding_evidence" -Default 0)
    $referencedActionPathsFound = Convert-ToInt (Get-PropValue -Object $review -Name "referenced_action_paths_found" -Default 0)
    $qualityClassification = Normalize-Text (Get-PropValue -Object $review -Name "classification" -Default "")
    $usefulnessClassification = Get-TeacherUsefulnessClassification -Classification $qualityClassification -TotalScore $totalScore -GroundingEvidence $groundingEvidence -ReferencedActionPathsFound $referencedActionPathsFound
    $reuseLikelihood = Get-ReuseLikelihood -UsefulnessClassification $usefulnessClassification -ReferencedActionPathsFound $referencedActionPathsFound

    switch ($usefulnessClassification) {
        "useful" { $usefulCount++ }
        "mixed" { $mixedCount++ }
        "low_value" { $lowValueCount++ }
        "reject" { $rejectCount++ }
    }

    $rationale = New-Object 'System.Collections.Generic.List[string]'
    Add-UniqueReason -List $rationale -Value ("total_score={0}" -f ([Math]::Round($totalScore, 2)))
    Add-UniqueReason -List $rationale -Value ("grounding_evidence={0}" -f $groundingEvidence)
    Add-UniqueReason -List $rationale -Value ("referenced_action_paths_found={0}" -f $referencedActionPathsFound)
    Add-UniqueReason -List $rationale -Value ("quality_classification={0}" -f $(if ($qualityClassification) { $qualityClassification } else { "unknown" }))

    $estimatedValue = if ($totalScore -ge 80) {
        "high"
    }
    elseif ($totalScore -ge 70) {
        "medium"
    }
    else {
        "low"
    }

    $teacherUsefulnessRecords += [pscustomobject]@{
        teacher_item_id = Normalize-Text (Get-PropValue -Object $review -Name "teacher_item_id" -Default "")
        usefulness_classification = $usefulnessClassification
        quality_classification = if ($qualityClassification) { $qualityClassification } else { "unknown" }
        quality_score = [Math]::Round($totalScore, 2)
        estimated_value = $estimatedValue
        reuse_likelihood = $reuseLikelihood
        rationale = Normalize-StringList -Value $rationale -MaxItems 8 -MaxLength 180
        title = Normalize-ShortText -Value (Get-PropValue -Object $review -Name "title" -Default "") -MaxLength 140
        requires_human_approval = Convert-ToBool (Get-PropValue -Object $review -Name "requires_human_approval" -Default $true)
    }
}

$qualityFloorStatus = if ($teacherUsefulnessRecords.Count -eq 0) {
    "insufficient_data"
}
elseif ($usefulCount -gt 0 -and $rejectCount -eq 0) {
    "pass"
}
else {
    "guarded"
}

$teacherUsefulnessArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = if ($teacherUsefulnessRecords.Count -eq 0) { "WARN" } elseif ($rejectCount -gt 0 -or $qualityFloorStatus -ne "pass") { "WARN" } else { "PASS" }
    teacher_reviewed_item_count = @($teacherUsefulnessRecords).Count
    useful_count = [int]$usefulCount
    mixed_count = [int]$mixedCount
    low_value_count = [int]$lowValueCount
    reject_count = [int]$rejectCount
    recommended_next_action = if ($qualityFloorStatus -eq "pass") { "Only reuse teacher outputs that clear the current quality floor." } else { "Keep teacher outputs review-only unless they clear the grounded quality floor." }
    reviews = @($teacherUsefulnessRecords)
    command_run = $commandRun
    repo_root = $repoRoot
}
Write-JsonFile -Path $teacherUsefulnessPath -Data $teacherUsefulnessArtifact

$costEffectivenessRecords = @()
$successfulLowCostCount = 0
$successfulHighCostCount = 0
$highCostLowValueCount = 0

foreach ($taskRecord in $classifiedTasks) {
    $estimatedCostTier = (Normalize-Text (Get-PropValue -Object $taskRecord -Name "estimated_cost_tier" -Default "")).ToLowerInvariant()
    $fallbackQuality = Convert-ToInt (Get-PropValue -Object $taskRecord -Name "fallback_quality_without_teacher" -Default 0)
    $teacherQualityScore = Convert-ToInt (Get-PropValue -Object $taskRecord -Name "teacher_quality_score" -Default 0)
    $teacherQualityClassification = Normalize-Text (Get-PropValue -Object $taskRecord -Name "teacher_quality_classification" -Default "")

    $successSignal = "review_only"
    $costEffectivenessClassification = "guarded_review_only"

    if ((Convert-ToBool (Get-PropValue -Object $taskRecord -Name "local_first_mandatory" -Default $false)) -and $fallbackQuality -ge $qualityThreshold) {
        $successSignal = "local_success_signal"
        $costEffectivenessClassification = "successful_low_cost"
        $successfulLowCostCount++
    }
    elseif ((Normalize-Text (Get-PropValue -Object $taskRecord -Name "task_class" -Default "")).ToLowerInvariant() -eq "teacher_high_value_only" -and $estimatedCostTier -eq "high" -and $teacherQualityScore -ge $qualityThreshold) {
        $successSignal = "high_value_candidate"
        $costEffectivenessClassification = "successful_high_cost"
        $successfulHighCostCount++
    }
    elseif ($estimatedCostTier -in @("high", "standard") -and (($teacherQualityClassification -eq "reject") -or $teacherQualityScore -lt $qualityThreshold)) {
        $successSignal = "no_clear_teacher_win"
        $costEffectivenessClassification = "high_cost_low_value"
        $highCostLowValueCount++
    }

    $rationale = New-Object 'System.Collections.Generic.List[string]'
    Add-UniqueReason -List $rationale -Value ("task_class={0}" -f (Get-PropValue -Object $taskRecord -Name "task_class" -Default ""))
    Add-UniqueReason -List $rationale -Value ("budget_class={0}" -f (Get-PropValue -Object $taskRecord -Name "budget_class" -Default ""))
    Add-UniqueReason -List $rationale -Value ("estimated_cost_tier={0}" -f $(if ($estimatedCostTier) { $estimatedCostTier } else { "unknown" }))
    Add-UniqueReason -List $rationale -Value ("fallback_quality_without_teacher={0}" -f $fallbackQuality)
    if ($teacherQualityClassification) {
        Add-UniqueReason -List $rationale -Value ("teacher_quality_classification={0}" -f $teacherQualityClassification)
    }

    $costEffectivenessRecords += [pscustomobject]@{
        task_id_or_type = Normalize-Text (Get-PropValue -Object $taskRecord -Name "task_id_or_type" -Default "")
        budget_class = Normalize-Text (Get-PropValue -Object $taskRecord -Name "budget_class" -Default "")
        estimated_cost_tier = if ($estimatedCostTier) { $estimatedCostTier } else { "unknown" }
        success_signal = $successSignal
        cost_effectiveness_classification = $costEffectivenessClassification
        rationale = Normalize-StringList -Value $rationale -MaxItems 8 -MaxLength 180
    }
}

$costEffectivenessSummary = if ($highCostLowValueCount -gt 0) {
    "High-cost teacher paths remain low-value relative to the current local-first evidence, so spend should stay tightly gated."
}
elseif ($successfulHighCostCount -gt 0) {
    "A small number of high-value tasks may justify escalation, but only under approval."
}
else {
    "Current success is dominated by local-first work, which keeps cost-per-success conservative."
}

$costEffectivenessArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = if ($costEffectivenessRecords.Count -eq 0) { "WARN" } elseif ($highCostLowValueCount -gt 0) { "WARN" } else { "PASS" }
    evaluated_task_count = @($costEffectivenessRecords).Count
    successful_low_cost_count = [int]$successfulLowCostCount
    successful_high_cost_count = [int]$successfulHighCostCount
    high_cost_low_value_count = [int]$highCostLowValueCount
    cost_per_success_summary = $costEffectivenessSummary
    recommended_next_action = if ($highCostLowValueCount -gt 0) { "Keep high-cost teacher escalation blocked unless the task is clearly high-value and approval-backed." } else { "Continue using local-first success patterns as the default cost posture." }
    tracked_records = @($costEffectivenessRecords)
    command_run = $commandRun
    repo_root = $repoRoot
}
Write-JsonFile -Path $costEffectivenessPath -Data $costEffectivenessArtifact

$mirrorRefresh = Invoke-MirrorRefresh -RepoRoot $repoRoot -MirrorScriptPath $mirrorScriptPath -MirrorReportPath $mirrorUpdatePath
$mirrorRefreshStatus = Normalize-Text (Get-PropValue -Object $mirrorRefresh -Name "refresh_status" -Default "")
$mirrorNextAction = Normalize-ShortText -Value (Get-PropValue -Object $mirrorRefresh -Name "next_action" -Default "") -MaxLength 220

$costGovernancePosture = if ($teacherAllowedCount -gt 0 -and $qualityFloorStatus -eq "pass") {
    "targeted_escalation_allowed"
}
elseif ($localFirstMandatoryCount -gt 0) {
    "guarded_local_first"
}
else {
    "review_only"
}

$overallStatus = "PASS"
if (($validatorStatus -and $validatorStatus -ne "PASS") -or
    ($systemTruthStatus -and $systemTruthStatus -ne "PASS") -or
    ($regressionStatus -and $regressionStatus -ne "PASS") -or
    ($releaseStatus -and $releaseStatus -ne "PASS") -or
    ($keepAliveStatus -and $keepAliveStatus -ne "PASS") -or
    ($businessOutcomeStatus -and $businessOutcomeStatus -ne "PASS") -or
    ($supportBrainStatus -and $supportBrainStatus -ne "PASS") -or
    ($qualityFloorStatus -ne "pass") -or
    ($budgetPosture -and $budgetPosture -ne "pass" -and $budgetPosture -ne "expanded") -or
    ($mirrorRefreshStatus -notin @("success", "local_checkpoint_only"))) {
    $overallStatus = "WARN"
}

$recommendedNextAction = if ($mirrorRefreshStatus -notin @("success", "local_checkpoint_only")) {
    if ($mirrorNextAction) {
        $mirrorNextAction
    }
    else {
        "Resolve the mirror access issue and rerun the canonical mirror flow so off-box state stays current."
    }
}
elseif ($teacherAllowedCount -eq 0) {
    "Keep teacher escalation blocked by default, reuse local truth first, and manually review only exceptional high-value tasks."
}
elseif ($qualityFloorStatus -ne "pass") {
    "Keep teacher outputs review-only until more grounded, reusable results clear the quality floor."
}
else {
    "Use targeted, approval-backed teacher escalation only for the explicitly allowed high-value tasks."
}

$modelCostGovernanceArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $overallStatus
    task_class_count = @($policy.task_classes).Count
    budget_class_count = @($policy.budget_classes).Count
    local_first_mandatory_count = [int]$localFirstMandatoryCount
    teacher_allowed_count = [int]$teacherAllowedCount
    teacher_blocked_count = [int]$teacherBlockedCount
    quality_floor_status = $qualityFloorStatus
    cost_governance_posture = $costGovernancePosture
    recommended_next_action = $recommendedNextAction
    mirror_refresh_status = $mirrorRefreshStatus
    task_classification = [ordered]@{
        summary = if ($localFirstMandatoryCount -gt 0) { "Most active work remains local-first and budget-guarded." } else { "No active tasks are currently classified." }
        local_only_count = [int]$localOnlyCount
        local_preferred_count = [int]$localPreferredCount
        teacher_optional_count = [int]$teacherOptionalCount
        teacher_high_value_only_count = [int]$teacherHighValueOnlyCount
        teacher_blocked_count = [int]$teacherBlockedCount
    }
    budget_classes = [ordered]@{
        summary = if ($budgetPosture) { "Current teacher spend posture remains $budgetPosture." } else { "Budget posture is not explicitly available." }
        counts = $budgetCounts
    }
    escalation_ladder = [ordered]@{
        summary = "Local artifacts, registries, and playbooks remain the default path; teacher escalation stays exceptional."
        steps = @($policy.escalation_ladder_rules)
    }
    quality_floor = [ordered]@{
        summary = if ($qualityFloorStatus -eq "pass") { "Stored teacher outputs meet the current reusable quality floor." } else { "Stored teacher outputs remain guarded or review-only under the current quality floor." }
        reusable_minimum_total_score = $qualityThreshold
        useful_count = [int]$usefulCount
        mixed_count = [int]$mixedCount
        low_value_count = [int]$lowValueCount
        reject_count = [int]$rejectCount
    }
    teacher_usefulness = [ordered]@{
        summary = if ($usefulCount -gt 0) { "Some teacher output has reuse value, but the overall posture still needs review." } else { "Teacher output is not yet strong enough to relax the guarded posture." }
        teacher_reviewed_item_count = @($teacherUsefulnessRecords).Count
        useful_count = [int]$usefulCount
        mixed_count = [int]$mixedCount
        low_value_count = [int]$lowValueCount
        reject_count = [int]$rejectCount
    }
    cost_effectiveness = [ordered]@{
        summary = $costEffectivenessSummary
        evaluated_task_count = @($costEffectivenessRecords).Count
        successful_low_cost_count = [int]$successfulLowCostCount
        successful_high_cost_count = [int]$successfulHighCostCount
        high_cost_low_value_count = [int]$highCostLowValueCount
    }
    mirror_refresh = [ordered]@{
        attempted = Convert-ToBool (Get-PropValue -Object $mirrorRefresh -Name "attempted" -Default $false)
        refresh_status = $mirrorRefreshStatus
        ok = Convert-ToBool (Get-PropValue -Object $mirrorRefresh -Name "ok" -Default $false)
        phase = Normalize-Text (Get-PropValue -Object $mirrorRefresh -Name "phase" -Default "")
        mirror_push_result = Normalize-Text (Get-PropValue -Object $mirrorRefresh -Name "mirror_push_result" -Default "")
        exit_code = Get-PropValue -Object $mirrorRefresh -Name "exit_code" -Default $null
        next_action = $mirrorNextAction
        source_path = $mirrorUpdatePath
    }
    command_run = $commandRun
    repo_root = $repoRoot
}
Write-JsonFile -Path $modelCostGovernancePath -Data $modelCostGovernanceArtifact

$modelCostRegistry = [ordered]@{
    generated_at_utc = $nowUtc
    overall_status = $overallStatus
    latest_governance_artifact = $modelCostGovernancePath
    task_class_count = @($policy.task_classes).Count
    teacher_allowed_count = [int]$teacherAllowedCount
    teacher_blocked_count = [int]$teacherBlockedCount
    quality_floor_status = $qualityFloorStatus
    mirror_refresh_status = $mirrorRefreshStatus
    notes = Normalize-StringList -Value @(
        ("budget_posture={0}" -f $(if ($budgetPosture) { $budgetPosture } else { "unknown" })),
        ("validator_status={0}" -f $(if ($validatorStatus) { $validatorStatus } else { "unknown" })),
        ("regression_status={0}" -f $(if ($regressionStatus) { $regressionStatus } else { "unknown" })),
        ("mirror_refresh_status={0}" -f $(if ($mirrorRefreshStatus) { $mirrorRefreshStatus } else { "unknown" }))
    ) -MaxItems 8 -MaxLength 160
}
Write-JsonFile -Path $modelCostRegistryPath -Data $modelCostRegistry

$modelCostGovernanceArtifact | ConvertTo-Json -Depth 100
