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
        [int]$MaxLength = 240
    )

    $results = New-Object System.Collections.Generic.List[string]
    foreach ($item in @($Value)) {
        $text = Normalize-ShortText -Value $item -MaxLength $MaxLength
        if (-not $text) {
            continue
        }
        if (-not $results.Contains($text)) {
            $results.Add($text)
        }
        if ($results.Count -ge $MaxItems) {
            break
        }
    }
    return @($results)
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

function Add-UniqueString {
    param(
        [System.Collections.Generic.List[string]]$Target,
        [AllowNull()][object]$Value
    )

    $text = Normalize-Text $Value
    if (-not $text) {
        return
    }
    if (-not $Target.Contains($text)) {
        $Target.Add($text)
    }
}

function New-PlaybookRecord {
    param(
        [string]$PlaybookId,
        [string]$Title,
        [string]$Category,
        [string]$Applicability,
        [string[]]$TriggerConditions,
        [string]$PlainEnglishExplanation,
        [string[]]$MasonSafeActions,
        [string[]]$BlockedActions,
        [string[]]$OwnerActions,
        [string[]]$EscalationRules,
        [string[]]$EvidenceSources,
        [string]$Status,
        [bool]$CustomerSafeWordingAvailable = $false,
        [string]$CustomerSafeExplanation = ""
    )

    return [pscustomobject]@{
        playbook_id = Normalize-ShortText -Value $PlaybookId -MaxLength 80
        title = Normalize-ShortText -Value $Title -MaxLength 140
        category = Normalize-ShortText -Value $Category -MaxLength 40
        applicability = Normalize-ShortText -Value $Applicability -MaxLength 120
        trigger_conditions = Normalize-StringList -Value $TriggerConditions -MaxItems 12 -MaxLength 220
        plain_english_explanation = Normalize-ShortText -Value $PlainEnglishExplanation -MaxLength 600
        mason_safe_actions = Normalize-StringList -Value $MasonSafeActions -MaxItems 12 -MaxLength 220
        blocked_actions = Normalize-StringList -Value $BlockedActions -MaxItems 12 -MaxLength 220
        owner_actions = Normalize-StringList -Value $OwnerActions -MaxItems 12 -MaxLength 220
        escalation_rules = Normalize-StringList -Value $EscalationRules -MaxItems 12 -MaxLength 220
        evidence_sources = Normalize-StringList -Value $EvidenceSources -MaxItems 16 -MaxLength 260
        status = Normalize-ShortText -Value $Status -MaxLength 40
        customer_safe_wording_available = $CustomerSafeWordingAvailable
        customer_safe_explanation = Normalize-ShortText -Value $CustomerSafeExplanation -MaxLength 400
    }
}

function New-IncidentExplanation {
    param(
        [string]$IssueId,
        [string]$IssueType,
        [string]$Severity,
        [string]$PlainEnglishExplanation,
        [string]$WhyItMatters,
        [string]$WhatMasonDidOrDidNotDo,
        [string]$WhatShouldHappenNext,
        [string]$LinkedPlaybookId,
        [string]$SourceTruthPath
    )

    return [pscustomobject]@{
        issue_id = Normalize-ShortText -Value $IssueId -MaxLength 120
        issue_type = Normalize-ShortText -Value $IssueType -MaxLength 80
        severity = Normalize-ShortText -Value $Severity -MaxLength 24
        plain_english_explanation = Normalize-ShortText -Value $PlainEnglishExplanation -MaxLength 500
        why_it_matters = Normalize-ShortText -Value $WhyItMatters -MaxLength 280
        what_mason_did_or_did_not_do = Normalize-ShortText -Value $WhatMasonDidOrDidNotDo -MaxLength 320
        what_should_happen_next = Normalize-ShortText -Value $WhatShouldHappenNext -MaxLength 280
        linked_playbook_id = Normalize-ShortText -Value $LinkedPlaybookId -MaxLength 80
        source_truth_path = Normalize-Text $SourceTruthPath
    }
}

function Get-ValidatorSection {
    param(
        [AllowNull()][object]$SystemValidation,
        [string]$SectionName
    )

    foreach ($section in @((Get-PropValue -Object $SystemValidation -Name "sections" -Default @()))) {
        $name = Normalize-Text (Get-PropValue -Object $section -Name "section_name" -Default "")
        if ($name -eq $SectionName) {
            return $section
        }
    }
    return $null
}

function Get-TopSeverityRank {
    param([string]$Severity)

    switch ((Normalize-Text $Severity).ToLowerInvariant()) {
        "critical" { return 4 }
        "high" { return 3 }
        "medium" { return 2 }
        "low" { return 1 }
        default { return 0 }
    }
}

$repoRoot = Resolve-RepoRoot -ExplicitRoot $RepoRoot
$reportsDir = Join-Path $repoRoot "reports"
$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"
$configDir = Join-Path $repoRoot "config"

$systemValidationPath = Join-Path $reportsDir "system_validation_last.json"
$hostHealthPath = Join-Path $reportsDir "host_health_last.json"
$runtimePosturePath = Join-Path $reportsDir "runtime_posture_last.json"
$environmentDriftPath = Join-Path $reportsDir "environment_drift_last.json"
$keepAlivePath = Join-Path $reportsDir "keepalive_last.json"
$selfHealPath = Join-Path $reportsDir "self_heal_last.json"
$selfImprovementPath = Join-Path $reportsDir "self_improvement_governor_last.json"
$billingSummaryPath = Join-Path $reportsDir "billing_summary.json"
$securityPosturePath = Join-Path $reportsDir "security_posture.json"
$tenantSafetyPath = Join-Path $reportsDir "tenant_safety_report.json"
$mirrorUpdatePath = Join-Path $reportsDir "mirror_update_last.json"
$regressionGuardPath = Join-Path $reportsDir "regression_guard_last.json"
$systemTruthPath = Join-Path $reportsDir "system_truth_spine_last.json"
$brandExposurePath = Join-Path $reportsDir "brand_exposure_isolation_last.json"
$liveDocsSummaryPath = Join-Path $reportsDir "live_docs_summary.json"

$playbookLibraryPath = Join-Path $reportsDir "playbook_library_last.json"
$supportBrainPath = Join-Path $reportsDir "support_brain_last.json"
$incidentExplanationsPath = Join-Path $reportsDir "incident_explanations_last.json"
$playbookRegistryPath = Join-Path $stateKnowledgeDir "playbook_registry.json"
$playbookPolicyPath = Join-Path $configDir "playbook_support_policy.json"

$nowUtc = (Get-Date).ToUniversalTime().ToString("o")
$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Build_Playbook_Support_Brain.ps1"

$policy = [ordered]@{
    version = 1
    policy_name = "playbook_support_brain"
    policy_posture = "conservative_grounded"
    allowed_source_artifacts = @(
        "reports/system_validation_last.json",
        "reports/host_health_last.json",
        "reports/runtime_posture_last.json",
        "reports/environment_drift_last.json",
        "reports/keepalive_last.json",
        "reports/self_heal_last.json",
        "reports/self_improvement_governor_last.json",
        "reports/billing_summary.json",
        "reports/security_posture.json",
        "reports/tenant_safety_report.json",
        "reports/mirror_update_last.json",
        "reports/regression_guard_last.json",
        "reports/system_truth_spine_last.json",
        "reports/brand_exposure_isolation_last.json",
        "reports/live_docs_summary.json"
    )
    explanation_scope_classes = @("internal_operator", "customer_safe")
    internal_vs_customer_safe_output_rules = [ordered]@{
        internal_operator = @(
            "May reference Mason, Athena, validator sections, local artifact names, and governed internal posture."
        )
        customer_safe = @(
            "Must prefer Onyx/customer-safe labels.",
            "Must avoid internal-only file paths, Mason-private terminology, and sensitive operational detail.",
            "Must stay calm, specific, and non-alarmist."
        )
    }
    plain_english_formatting_expectations = @(
        "State what happened.",
        "State what it means operationally.",
        "State what Mason did or refused to do.",
        "State the exact next action when one exists.",
        "Avoid vague filler or speculative language."
    )
    playbook_freshness_rules = [ordered]@{
        preferred_max_age_hours = 24
        stale_if_older_than_hours = 72
        stale_manual_ok_if_marked = $true
    }
    recommendation_safety_rules = @(
        "Respect current validator, keepalive, regression, and self-improvement gates.",
        "Do not recommend destructive cleanup or broad restart storms.",
        "Do not recommend money, billing, or security-control changes without owner approval."
    )
    blocked_content_classes = @(
        "secret values",
        "private credentials",
        "destructive rollback instructions",
        "public exposure of Mason-private internals in customer-safe summaries"
    )
    confidence_evidence_rules = @(
        "Explanations must be backed by current local artifacts.",
        "When provenance is partial, label it artifact-observed instead of code-confirmed.",
        "Missing sources must be called out instead of silently invented."
    )
    escalation_wording_rules = @(
        "Escalate only when recovery is blocked, unsafe, or repeatedly unsuccessful.",
        "State why Mason did not auto-fix the issue.",
        "State the owner action required."
    )
}

Write-JsonFile -Path $playbookPolicyPath -Data $policy

$systemValidation = Read-JsonSafe -Path $systemValidationPath
$hostHealth = Read-JsonSafe -Path $hostHealthPath
$runtimePosture = Read-JsonSafe -Path $runtimePosturePath
$environmentDrift = Read-JsonSafe -Path $environmentDriftPath
$keepAlive = Read-JsonSafe -Path $keepAlivePath
$selfHeal = Read-JsonSafe -Path $selfHealPath
$selfImprovement = Read-JsonSafe -Path $selfImprovementPath
$billingSummary = Read-JsonSafe -Path $billingSummaryPath
$securityPosture = Read-JsonSafe -Path $securityPosturePath
$tenantSafety = Read-JsonSafe -Path $tenantSafetyPath
$mirrorUpdate = Read-JsonSafe -Path $mirrorUpdatePath
$regressionGuard = Read-JsonSafe -Path $regressionGuardPath
$systemTruth = Read-JsonSafe -Path $systemTruthPath
$brandExposure = Read-JsonSafe -Path $brandExposurePath
$liveDocsSummary = Read-JsonSafe -Path $liveDocsSummaryPath

$sourceAvailabilityWarnings = New-Object System.Collections.Generic.List[string]
foreach ($requiredPath in @(
    $systemValidationPath,
    $hostHealthPath,
    $runtimePosturePath,
    $keepAlivePath,
    $selfImprovementPath,
    $billingSummaryPath,
    $securityPosturePath,
    $tenantSafetyPath,
    $mirrorUpdatePath,
    $regressionGuardPath
)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        Add-UniqueString -Target $sourceAvailabilityWarnings -Value ("Missing source artifact: {0}" -f $requiredPath)
    }
}

$stackBaseSection = Get-ValidatorSection -SystemValidation $systemValidation -SectionName "stack/base"
$stackBaseStatus = Normalize-Text (Get-PropValue -Object $stackBaseSection -Name "status" -Default "")
$hostPendingReboot = [bool](Get-PropValue -Object (Get-PropValue -Object $hostHealth -Name "uptime" -Default $null) -Name "pending_reboot" -Default $false)
$keepAliveEscalatedCount = [int](Get-PropValue -Object $keepAlive -Name "escalated_issue_count" -Default 0)
$selfImprovementStatus = Normalize-Text (Get-PropValue -Object $selfImprovement -Name "overall_status" -Default "")
$selfImprovementBlocked = [int](Get-PropValue -Object (Get-PropValue -Object $selfImprovement -Name "counts_by_execution_disposition" -Default $null) -Name "blocked" -Default 0)
$selfImprovementApprovalRequired = [int](Get-PropValue -Object (Get-PropValue -Object $selfImprovement -Name "counts_by_execution_disposition" -Default $null) -Name "approval_required" -Default 0)
$securityStatus = Normalize-Text (Get-PropValue -Object $securityPosture -Name "overall_status" -Default "")
$tenantSafetyStatus = Normalize-Text (Get-PropValue -Object $tenantSafety -Name "status" -Default "")
$tenantSafetyIssues = [int](Get-PropValue -Object $tenantSafety -Name "issues_total" -Default 0)
$billingProvider = Get-PropValue -Object $billingSummary -Name "provider" -Default $null
$billingMode = Normalize-Text (Get-PropValue -Object $billingProvider -Name "mode" -Default "")
$billingMoneyApproval = [bool](Get-PropValue -Object $billingSummary -Name "money_actions_require_approval" -Default $true)
$mirrorOk = [bool](Get-PropValue -Object $mirrorUpdate -Name "ok" -Default $false)
$mirrorPhase = Normalize-Text (Get-PropValue -Object $mirrorUpdate -Name "phase" -Default "")
$regressionStatus = Normalize-Text (Get-PropValue -Object $regressionGuard -Name "overall_status" -Default "")
$promotionAllowed = [bool](Get-PropValue -Object $regressionGuard -Name "promotion_allowed" -Default $false)
$baselineTrusted = [bool](Get-PropValue -Object $regressionGuard -Name "baseline_trusted" -Default $false)
$publicLeakCount = [int](Get-PropValue -Object $brandExposure -Name "public_leak_count" -Default 0)

$playbooks = New-Object System.Collections.Generic.List[object]
$incidentExplanations = New-Object System.Collections.Generic.List[object]
$issueMappings = New-Object System.Collections.Generic.List[object]

function Add-PlaybookAndMapping {
    param(
        [pscustomobject]$Playbook,
        [bool]$ActiveNow,
        [string]$IssueType,
        [string]$Severity,
        [string]$NextAction,
        [string]$SourceTruthPath,
        [string]$WhyItMatters,
        [string]$WhatMasonDidOrDidNotDo
    )

    $script:playbooks.Add($Playbook)
    $script:issueMappings.Add([pscustomobject]@{
        issue_type = Normalize-ShortText -Value $IssueType -MaxLength 80
        severity = Normalize-ShortText -Value $Severity -MaxLength 24
        explanation = Normalize-ShortText -Value $Playbook.plain_english_explanation -MaxLength 400
        next_action = Normalize-ShortText -Value $NextAction -MaxLength 240
        known_playbook_id = Normalize-ShortText -Value $Playbook.playbook_id -MaxLength 80
        customer_safe_wording_available = [bool]$Playbook.customer_safe_wording_available
        customer_safe_explanation = Normalize-ShortText -Value $Playbook.customer_safe_explanation -MaxLength 320
        active_now = $ActiveNow
    })
    if ($ActiveNow) {
        $script:incidentExplanations.Add((New-IncidentExplanation `
            -IssueId $IssueType `
            -IssueType $IssueType `
            -Severity $Severity `
            -PlainEnglishExplanation $Playbook.plain_english_explanation `
            -WhyItMatters $WhyItMatters `
            -WhatMasonDidOrDidNotDo $WhatMasonDidOrDidNotDo `
            -WhatShouldHappenNext $NextAction `
            -LinkedPlaybookId $Playbook.playbook_id `
            -SourceTruthPath $SourceTruthPath))
    }
}

$serviceHealthPlaybook = New-PlaybookRecord -PlaybookId "pb_service_health_missing_listener" -Title "Service Health Or Missing Listener" -Category "incident" -Applicability $(if ($stackBaseStatus -and $stackBaseStatus -ne "PASS") { "active_now" } else { "available_when_triggered" }) -TriggerConditions @("A required loopback contract port is not listening.", "A required health endpoint stops returning ready.", "The validator stack/base section drops below PASS.") -PlainEnglishExplanation "A required Mason stack service is missing, unhealthy, or not answering on its loopback contract port. Mason should trust the live probe and listener state first, then use the validator and start artifacts to explain what changed." -MasonSafeActions @("Recheck the loopback port and health endpoint once.", "Use the current validator and last-failure artifacts to identify the failing component.", "If policy allows, perform one targeted safe restart instead of a broad restart storm.") -BlockedActions @("Do not assume a stale PASS start artifact means the service is healthy.", "Do not restart the full stack repeatedly without component-specific evidence.") -OwnerActions @("Review the failing component log and authorize targeted recovery if the service does not return cleanly.") -EscalationRules @("Escalate when the same component stays unhealthy after a safe targeted recovery or when the live probe disagrees with stale artifacts.") -EvidenceSources @($systemValidationPath, $systemTruthPath, $keepAlivePath) -Status $(if ($stackBaseStatus -and $stackBaseStatus -ne "PASS") { "active" } else { "ready" })
Add-PlaybookAndMapping -Playbook $serviceHealthPlaybook -ActiveNow ($stackBaseStatus -and $stackBaseStatus -ne "PASS") -IssueType "service_health_missing_listener" -Severity "high" -NextAction "Use the validator and live loopback probes to identify the failing service, then authorize only one targeted recovery action." -SourceTruthPath $systemValidationPath -WhyItMatters "If a required service stops answering, Athena and Onyx can look healthy only in stale reports while the real stack is degraded." -WhatMasonDidOrDidNotDo "Mason should trust live port and health checks before making any recovery claim."

$runtimeTruthPlaybook = New-PlaybookRecord -PlaybookId "pb_runtime_singleton_truth_drift" -Title "Runtime Singleton Or PID Truth Drift" -Category "recovery" -Applicability "available_when_triggered" -TriggerConditions @("current_live_pids disagrees with stale launcher PID history.", "A singleton service shows duplicate unexpected listener owners.", "The validator flags runtime truth drift.") -PlainEnglishExplanation "Runtime truth drift means the platform has conflicting answers about which process actually owns a required service. Mason should treat current live listener ownership as authoritative and avoid trusting stale launcher PID leftovers." -MasonSafeActions @("Compare current_live_pids against live listeners on the contract ports.", "Refresh the runtime truth artifacts before escalating.") -BlockedActions @("Do not kill multiple candidate owners blindly.", "Do not keep stale PIDs marked as live truth.") -OwnerActions @("Review the canonical live owner if singleton ownership cannot be established safely.") -EscalationRules @("Escalate when duplicate ownership persists after a safe runtime truth refresh.") -EvidenceSources @($systemValidationPath, (Join-Path $stateKnowledgeDir "stack_pids.json"), $systemTruthPath) -Status "ready"
Add-PlaybookAndMapping -Playbook $runtimeTruthPlaybook -ActiveNow $false -IssueType "runtime_singleton_truth_drift" -Severity "medium" -NextAction "Refresh runtime truth and compare current_live_pids against the live listener map before taking action." -SourceTruthPath (Join-Path $stateKnowledgeDir "stack_pids.json") -WhyItMatters "Conflicting runtime ownership makes recovery unsafe because the wrong process could be treated as canonical." -WhatMasonDidOrDidNotDo "Mason should refresh truth first and avoid broad process kills."

$truthMismatchPlaybook = New-PlaybookRecord -PlaybookId "pb_stale_truth_artifact_mismatch" -Title "Stale Artifact Versus Live Probe Mismatch" -Category "explanation" -Applicability "available_when_triggered" -TriggerConditions @("A stale artifact claims PASS while live loopback probes disagree.", "Generated summaries lag behind newer source-of-truth artifacts.") -PlainEnglishExplanation "A truth mismatch means an older artifact is describing a healthier or different state than the live machine. Mason should trust the freshest authoritative producer or the live loopback probe, not the prettier-looking stale file." -MasonSafeActions @("Record the mismatch and point to the fresher artifact or probe.", "Refresh the stale generator if it is safe to rerun.") -BlockedActions @("Do not report green just because an old JSON file still says PASS.") -OwnerActions @("Review whether the stale producer needs to be rerun or repaired.") -EscalationRules @("Escalate when the mismatch affects service health truth or governance decisions.") -EvidenceSources @($systemValidationPath, $systemTruthPath, $keepAlivePath) -Status "ready"
Add-PlaybookAndMapping -Playbook $truthMismatchPlaybook -ActiveNow $false -IssueType "stale_truth_artifact_mismatch" -Severity "medium" -NextAction "Refresh the stale producer only if it is safe, and keep the live probe or fresher artifact as the canonical truth." -SourceTruthPath $systemTruthPath -WhyItMatters "Using stale truth can trigger the wrong recovery, the wrong explanation, or a false green state." -WhatMasonDidOrDidNotDo "Mason should record the mismatch instead of hiding it."

$keepaliveEscalationPlaybook = New-PlaybookRecord -PlaybookId "pb_keepalive_policy_escalation" -Title "KeepAlive Escalated Instead Of Retrying Blindly" -Category "escalation" -Applicability $(if ($keepAliveEscalatedCount -gt 0) { "active_now" } else { "available_when_triggered" }) -TriggerConditions @("KeepAlive finds real issues but policy blocks unsafe repair.", "Cooldown or duplicate suppression prevents a retry storm.", "Escalation queue contains unresolved items.") -PlainEnglishExplanation "KeepAlive saw issues it could explain, but it refused to keep retrying because the next action was not low-risk or would have created a restart storm. That is correct governed behavior, not a missed heal." -MasonSafeActions @("Record the issue and the blocked repair decision.", "Keep the escalation queue current.", "Recommend the next safe owner action.") -BlockedActions @("Do not retry the same blocked repair over and over in one run.", "Do not widen a small issue into a full-stack restart without evidence.") -OwnerActions @("Review the escalation queue and authorize only the specific recovery that matches the evidence.") -EscalationRules @("Escalate when policy blocks the fix, cooldown is active, or the issue repeats without improvement.") -EvidenceSources @($keepAlivePath, $selfHealPath, (Join-Path $reportsDir "escalation_queue_last.json")) -Status $(if ($keepAliveEscalatedCount -gt 0) { "active" } else { "ready" })
Add-PlaybookAndMapping -Playbook $keepaliveEscalationPlaybook -ActiveNow ($keepAliveEscalatedCount -gt 0) -IssueType "keepalive_policy_escalation" -Severity "medium" -NextAction (Normalize-ShortText -Value (Get-PropValue -Object $keepAlive -Name "recommended_next_action" -Default "Review the escalated keepalive items before allowing broader recovery.")) -SourceTruthPath $keepAlivePath -WhyItMatters "A blocked repair means the issue is real, but the safe automated response has already been exhausted for now." -WhatMasonDidOrDidNotDo "Mason documented the issue, respected cooldown and policy, and refused blind retries."

$selfImprovementPlaybook = New-PlaybookRecord -PlaybookId "pb_self_improvement_review_gate" -Title "Self-Improvement Remains Review-Gated" -Category "governance" -Applicability $(if ($selfImprovementStatus -and $selfImprovementStatus -ne "PASS") { "active_now" } else { "available_when_triggered" }) -TriggerConditions @("Teacher-backed items are blocked or review-only.", "Money, security, or policy-sensitive improvements remain approval-gated.", "The self-improvement governor stays in guarded posture.") -PlainEnglishExplanation "The self-improvement governor is doing its job: it is screening ideas, keeping risky changes approval-gated, and refusing to let weak teacher-backed work flow straight into staging." -MasonSafeActions @("Use local-first evidence before considering teacher spend.", "Keep low-risk proven items in suggest-only or safe-to-test lanes.", "Record blocked and approval-required items clearly.") -BlockedActions @("Do not auto-apply money, security, policy, or trust-expanding changes.", "Do not accept weak teacher output as action-ready.") -OwnerActions @("Review blocked teacher-worthy items manually and approve only the ones with strong evidence.") -EscalationRules @("Escalate when a high-value improvement remains blocked but the local-first evidence is exhausted.") -EvidenceSources @($selfImprovementPath, (Join-Path $reportsDir "teacher_call_budget_last.json"), (Join-Path $reportsDir "teacher_decision_log_last.json")) -Status $(if ($selfImprovementStatus -and $selfImprovementStatus -ne "PASS") { "active" } else { "ready" })
Add-PlaybookAndMapping -Playbook $selfImprovementPlaybook -ActiveNow ($selfImprovementStatus -and $selfImprovementStatus -ne "PASS") -IssueType "self_improvement_review_gated" -Severity "medium" -NextAction (Normalize-ShortText -Value (Get-PropValue -Object $selfImprovement -Name "recommended_next_action" -Default "Keep blocked teacher-backed changes out of staging until owner review is complete.")) -SourceTruthPath $selfImprovementPath -WhyItMatters "This keeps self-improvement from quietly degrading the platform or spending money on weak advice." -WhatMasonDidOrDidNotDo ("Mason screened improvements, kept {0} approval-required and {1} blocked item(s) gated, and did not auto-stage risky changes." -f $selfImprovementApprovalRequired, $selfImprovementBlocked)

$securityPlaybook = New-PlaybookRecord -PlaybookId "pb_security_tenant_safety_watch" -Title "Security Or Tenant-Safety Watch Posture" -Category "warning" -Applicability $(if (($securityStatus -and $securityStatus -ne "PASS") -or ($tenantSafetyStatus -and $tenantSafetyStatus -ne "PASS" -and $tenantSafetyStatus -ne "OK") -or $tenantSafetyIssues -gt 0) { "active_now" } else { "available_when_triggered" }) -TriggerConditions @("Security posture drops to watch/guarded.", "Tenant safety issues remain unresolved.", "Validator keeps the security/legal/tenant safety section below PASS.") -PlainEnglishExplanation "Security and tenant-safety are in a watch posture. That means the platform still has known governance or isolation work to finish, even if the stack is otherwise running." -MasonSafeActions @("Keep the warnings visible in Athena and the validator.", "Point to the tenant-safety and security artifacts directly.", "Avoid auto-editing tenant isolation or security policy.") -BlockedActions @("Do not weaken security controls to make a warning disappear.", "Do not mutate tenant data automatically in the name of self-heal.") -OwnerActions @("Review the tenant safety report and close the isolation warnings intentionally.") -EscalationRules @("Escalate when the issue count grows, tenant exposure risk increases, or the posture degrades to FAIL.") -EvidenceSources @($securityPosturePath, $tenantSafetyPath, $systemValidationPath) -Status $(if (($securityStatus -and $securityStatus -ne "PASS") -or ($tenantSafetyStatus -and $tenantSafetyStatus -ne "PASS" -and $tenantSafetyStatus -ne "OK") -or $tenantSafetyIssues -gt 0) { "active" } else { "ready" })
Add-PlaybookAndMapping -Playbook $securityPlaybook -ActiveNow ((($securityStatus -and $securityStatus -ne "PASS") -or ($tenantSafetyStatus -and $tenantSafetyStatus -ne "PASS" -and $tenantSafetyStatus -ne "OK") -or $tenantSafetyIssues -gt 0)) -IssueType "security_tenant_safety_watch" -Severity "high" -NextAction "Review the tenant safety report and resolve the remaining isolation warnings before relaxing this posture." -SourceTruthPath $tenantSafetyPath -WhyItMatters "Known tenant-safety warnings mean the platform is not ready to pretend everything is clean, even if customer flows still work." -WhatMasonDidOrDidNotDo "Mason kept the watch posture visible and did not auto-edit security or tenant data."

$billingPlaybook = New-PlaybookRecord -PlaybookId "pb_billing_stub_gated" -Title "Billing Remains Stubbed And Approval-Gated" -Category "customer_safe_support" -Applicability $(if ($billingMode -eq "stub" -or $billingMoneyApproval) { "active_now" } else { "available_when_triggered" }) -TriggerConditions @("The billing provider is still in stub mode.", "Money actions remain approval-gated.", "Validator keeps billing/entitlements below PASS for live-money readiness.") -PlainEnglishExplanation "Billing is still in a safe setup posture. Plan visibility and entitlement logic can work, but live money actions remain intentionally blocked until external billing secrets and webhook configuration are ready." -MasonSafeActions @("Keep plan entitlements readable without enabling live money actions.", "Explain that billing is still in guided setup.", "Keep all money actions approval-gated.") -BlockedActions @("Do not enable live money actions locally just to clear a warning.", "Do not store card data or internal billing secrets in local artifacts.") -OwnerActions @("Configure the external billing provider only when you are ready for real money flow and webhook verification.") -EscalationRules @("Escalate when live billing is required for launch or when entitlement logic diverges from the configured plan state.") -EvidenceSources @($billingSummaryPath, (Join-Path $configDir "billing_provider.json"), $systemValidationPath) -Status $(if ($billingMode -eq "stub" -or $billingMoneyApproval) { "active" } else { "ready" }) -CustomerSafeWordingAvailable $true -CustomerSafeExplanation "Onyx billing is still in guided setup. Plans and access rules are visible, but live payment actions are not turned on yet."
Add-PlaybookAndMapping -Playbook $billingPlaybook -ActiveNow ($billingMode -eq "stub" -or $billingMoneyApproval) -IssueType "billing_stub_gated" -Severity "low" -NextAction "Keep billing stubbed until external billing secrets and webhook configuration are intentionally completed." -SourceTruthPath $billingSummaryPath -WhyItMatters "This prevents unsafe live money behavior while keeping billing and entitlement posture visible." -WhatMasonDidOrDidNotDo "Mason kept plan logic readable but refused to enable real money actions automatically."

$mirrorPlaybook = New-PlaybookRecord -PlaybookId "pb_mirror_incomplete_or_stale" -Title "Mirror Or Checkpoint Incomplete" -Category "recovery" -Applicability $(if ((-not $mirrorOk) -or $mirrorPhase -ne "done") { "active_now" } else { "available_when_triggered" }) -TriggerConditions @("Mirror update reports ok=false.", "Mirror phase stops before done.", "Mirror push result is missing after a failed run.") -PlainEnglishExplanation "The checkpoint mirror did not complete cleanly. That means rollback and off-box continuity evidence may be incomplete, even if the stack itself is still up." -MasonSafeActions @("Record the failed mirror state and its exact phase.", "Point to the current mirror artifact and error.", "Recommend a controlled rerun instead of forcing repeated mirror attempts.") -BlockedActions @("Do not keep rerunning mirror blindly when the same access error is still present.", "Do not treat a partial mirror as a clean checkpoint.") -OwnerActions @("Resolve the access issue, then rerun the mirror flow so the checkpoint can return to ok=true and phase=done.") -EscalationRules @("Escalate when rollback confidence depends on a fresh checkpoint and the mirror remains incomplete.") -EvidenceSources @($mirrorUpdatePath, $regressionGuardPath, $systemValidationPath) -Status $(if ((-not $mirrorOk) -or $mirrorPhase -ne "done") { "active" } else { "ready" })
Add-PlaybookAndMapping -Playbook $mirrorPlaybook -ActiveNow ((-not $mirrorOk) -or $mirrorPhase -ne "done") -IssueType "mirror_incomplete" -Severity "high" -NextAction "Resolve the mirror access problem, then rerun the mirror update flow until ok=true and phase=done." -SourceTruthPath $mirrorUpdatePath -WhyItMatters "A partial mirror weakens rollback and portability confidence because the latest checkpoint may not be complete." -WhatMasonDidOrDidNotDo "Mason recorded the failed phase and did not keep forcing repeat mirror attempts without new evidence."

$rebootPlaybook = New-PlaybookRecord -PlaybookId "pb_host_pending_reboot" -Title "Pending Reboot And Caution Host Posture" -Category "warning" -Applicability $(if ($hostPendingReboot) { "active_now" } else { "available_when_triggered" }) -TriggerConditions @("Windows reports a pending reboot.", "Host guardian stays in caution throttle posture after updates or repair activity.") -PlainEnglishExplanation "The host is asking for a reboot. Mason can keep observing and throttling, but it should not reboot the machine automatically because that would interrupt the running stack and may affect active work." -MasonSafeActions @("Keep host posture at caution when warranted.", "Recommend a controlled reboot window.", "Avoid launching heavy repair or upgrade work until the host is steady.") -BlockedActions @("Do not reboot the host automatically.", "Do not hide the pending reboot state behind a green summary.") -OwnerActions @("Schedule a controlled Windows reboot when it will not interrupt current work.") -EscalationRules @("Escalate when host pressure grows or repeated maintenance requires a reboot window.") -EvidenceSources @($hostHealthPath, $runtimePosturePath) -Status $(if ($hostPendingReboot) { "active" } else { "ready" })
Add-PlaybookAndMapping -Playbook $rebootPlaybook -ActiveNow $hostPendingReboot -IssueType "host_pending_reboot" -Severity "medium" -NextAction (Normalize-ShortText -Value (Get-PropValue -Object $hostHealth -Name "recommended_next_action" -Default "Schedule a controlled Windows reboot when practical.")) -SourceTruthPath $hostHealthPath -WhyItMatters "A pending reboot can keep the host in a cautious posture and may limit how aggressively Mason should operate." -WhatMasonDidOrDidNotDo "Mason kept monitoring and throttle guidance active, and it refused to reboot the host automatically."

$brandPlaybook = New-PlaybookRecord -PlaybookId "pb_brand_exposure_leakage" -Title "Brand Exposure Leakage" -Category "customer_safe_support" -Applicability $(if ($publicLeakCount -gt 0) { "active_now" } else { "available_when_triggered" }) -TriggerConditions @("Customer-facing or public-facing surfaces expose Mason instead of Onyx.", "Brand isolation audit reports public leakage.") -PlainEnglishExplanation "A brand exposure leak means an internal/operator name escaped into a customer-facing surface. Internal naming can remain intact, but public surfaces must stay Onyx-only." -MasonSafeActions @("Record the public leak count and the affected surface.", "Recommend the smallest safe customer-facing wording fix.") -BlockedActions @("Do not mass-rename internal identifiers blindly.", "Do not hide a real public leak count.") -OwnerActions @("Correct the public wording and rerun brand exposure isolation.") -EscalationRules @("Escalate immediately when any public/customer leak is confirmed.") -EvidenceSources @($brandExposurePath, $systemValidationPath) -Status $(if ($publicLeakCount -gt 0) { "active" } else { "ready" }) -CustomerSafeWordingAvailable $true -CustomerSafeExplanation "A public-facing wording issue was found and is being corrected so customer surfaces stay Onyx-only."
Add-PlaybookAndMapping -Playbook $brandPlaybook -ActiveNow ($publicLeakCount -gt 0) -IssueType "brand_exposure_leakage" -Severity "critical" -NextAction "Correct the public wording leak and rerun brand exposure isolation before any customer-facing promotion." -SourceTruthPath $brandExposurePath -WhyItMatters "Public brand leakage breaks the intended Onyx-only customer boundary." -WhatMasonDidOrDidNotDo "Mason preserved internal wording where intended and only escalated customer-facing leakage."

$regressionPlaybook = New-PlaybookRecord -PlaybookId "pb_regression_promotion_blocked" -Title "Promotion Blocked By Regression Guard" -Category "governance" -Applicability $(if (($regressionStatus -and $regressionStatus -ne "PASS") -or (-not $promotionAllowed)) { "active_now" } else { "available_when_triggered" }) -TriggerConditions @("Regression guard sees warning or blocking regressions.", "Only a seed or untrusted baseline exists.", "Promotion remains blocked pending better comparison confidence.") -PlainEnglishExplanation "Promotion is blocked because the regression guard does not yet have enough evidence to say the current platform is safely better than the comparison baseline. That is a guardrail, not an accidental slowdown." -MasonSafeActions @("Keep promotion blocked while the baseline is untrusted or regressions remain.", "Point directly to the comparison evidence and rollback plan.") -BlockedActions @("Do not promote because the platform merely looks mostly okay.", "Do not ignore mirror or warning-regression evidence just to move faster.") -OwnerActions @("Review the seeded baseline, accept a trusted baseline when justified, and clear the remaining warning regressions before promotion.") -EscalationRules @("Escalate when a new regression becomes blocking or rollback is recommended.") -EvidenceSources @($regressionGuardPath, (Join-Path $reportsDir "promotion_gate_last.json"), (Join-Path $reportsDir "rollback_plan_last.json")) -Status $(if (($regressionStatus -and $regressionStatus -ne "PASS") -or (-not $promotionAllowed)) { "active" } else { "ready" })
Add-PlaybookAndMapping -Playbook $regressionPlaybook -ActiveNow ((($regressionStatus -and $regressionStatus -ne "PASS") -or (-not $promotionAllowed))) -IssueType "regression_promotion_blocked" -Severity "medium" -NextAction (Normalize-ShortText -Value (Get-PropValue -Object $regressionGuard -Name "recommended_next_action" -Default "Review the baseline and regression evidence before allowing promotion.")) -SourceTruthPath $regressionGuardPath -WhyItMatters "Without a trusted baseline and clean comparison result, promotion can quietly move the platform into a worse state." -WhatMasonDidOrDidNotDo ("Mason kept promotion blocked because baseline_trusted={0} and promotion_allowed={1}." -f $baselineTrusted.ToString().ToLowerInvariant(), $promotionAllowed.ToString().ToLowerInvariant())

$activePlaybooks = @($playbooks | Where-Object { (Normalize-Text $_.status) -eq "active" })
$playbookCategories = @($playbooks | ForEach-Object { Normalize-Text $_.category } | Where-Object { $_ } | Sort-Object -Unique)
$sortedActiveIssues = @($incidentExplanations | Sort-Object @{Expression = { Get-TopSeverityRank -Severity (Get-PropValue -Object $_ -Name "severity" -Default "") }; Descending = $true }, issue_type)
$sortedMappings = @($issueMappings | Sort-Object issue_type)
$customerSafeReadyCount = @($sortedMappings | Where-Object { [bool](Get-PropValue -Object $_ -Name "customer_safe_wording_available" -Default $false) }).Count
$internalSupportReadyCount = @($sortedMappings).Count
$playbookItems = @($playbooks | ForEach-Object { $_ })
$sourceAvailabilityWarningItems = @($sourceAvailabilityWarnings | ForEach-Object { $_ })

$topRecommendedAction = "No action required."
if ($sortedActiveIssues.Count -gt 0) {
    $topRecommendedAction = Normalize-ShortText -Value (Get-PropValue -Object $sortedActiveIssues[0] -Name "what_should_happen_next" -Default "")
}
if (-not $topRecommendedAction) {
    $topRecommendedAction = "No action required."
}
if ($sourceAvailabilityWarnings.Count -gt 0 -and $topRecommendedAction -eq "No action required.") {
    $topRecommendedAction = "Restore the missing playbook source artifacts before relying on support explanations."
}

$overallStatus = if ($sortedActiveIssues.Count -gt 0 -or $sourceAvailabilityWarnings.Count -gt 0) { "WARN" } else { "PASS" }

$playbookLibrary = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $overallStatus
    playbook_count = $playbooks.Count
    active_playbook_count = $activePlaybooks.Count
    playbook_categories = $playbookCategories
    playbooks = $playbookItems
    recommended_next_action = $topRecommendedAction
    command_run = $commandRun
    repo_root = $repoRoot
    source_availability_warnings = $sourceAvailabilityWarningItems
}

$supportBrain = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $overallStatus
    recurring_issue_count = $sortedActiveIssues.Count
    supported_issue_types = @($sortedMappings | ForEach-Object { Get-PropValue -Object $_ -Name "issue_type" -Default "" } | Where-Object { $_ } | Sort-Object -Unique)
    customer_safe_ready_count = $customerSafeReadyCount
    internal_support_ready_count = $internalSupportReadyCount
    recommended_next_action = $topRecommendedAction
    issue_type_mappings = @($sortedMappings)
}

$incidentExplanationArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $overallStatus
    issue_count = $sortedActiveIssues.Count
    issues = @($sortedActiveIssues)
    recommended_next_action = $topRecommendedAction
}

$registry = [ordered]@{
    generated_at_utc = $nowUtc
    current_playbook_count = $playbooks.Count
    current_categories = $playbookCategories
    latest_library_artifact = $playbookLibraryPath
    current_status = $overallStatus
    playbooks = @($playbooks | ForEach-Object {
        [pscustomobject]@{
            playbook_id = $_.playbook_id
            title = $_.title
            category = $_.category
            status = $_.status
            customer_safe_wording_available = $_.customer_safe_wording_available
        }
    })
}

Write-JsonFile -Path $playbookLibraryPath -Data $playbookLibrary
Write-JsonFile -Path $supportBrainPath -Data $supportBrain
Write-JsonFile -Path $incidentExplanationsPath -Data $incidentExplanationArtifact
Write-JsonFile -Path $playbookRegistryPath -Data $registry

[pscustomobject]@{
    ok = $true
    overall_status = $overallStatus
    playbook_count = $playbooks.Count
    active_playbook_count = $activePlaybooks.Count
    recurring_issue_count = $sortedActiveIssues.Count
    customer_safe_ready_count = $customerSafeReadyCount
    internal_support_ready_count = $internalSupportReadyCount
    recommended_next_action = $topRecommendedAction
    playbook_library_path = $playbookLibraryPath
    support_brain_path = $supportBrainPath
    incident_explanations_path = $incidentExplanationsPath
    playbook_registry_path = $playbookRegistryPath
    policy_path = $playbookPolicyPath
} | ConvertTo-Json -Depth 10
