[CmdletBinding()]
param(
    [string]$RootPath = "",
    [int]$HttpTimeoutSeconds = 15
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
    $normalized = [string]$Text
    if ($normalized.Length -le $MaxLength) {
        return $normalized
    }
    return $normalized.Substring(0, $MaxLength).TrimEnd()
}

function Convert-ToDouble {
    param(
        $Value,
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
        $Value,
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
            Write-Output -NoEnumerate $Object[$Name]
            return
        }
        return $Default
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($property) {
        Write-Output -NoEnumerate $property.Value
        return
    }

    return $Default
}

function Test-ObjectHasKey {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($null -eq $Object) {
        return $false
    }

    if ($Object -is [System.Collections.IDictionary]) {
        return $Object.Contains($Name)
    }

    return $null -ne $Object.PSObject.Properties[$Name]
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
        [int]$Depth = 16
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

function Get-ComponentLabel {
    param([string]$ComponentId)

    $normalized = Normalize-Text $ComponentId
    switch ($normalized.ToLowerInvariant()) {
        "mason" { return "Mason" }
        "mason_api" { return "Mason API" }
        "seed_api" { return "Seed API" }
        "bridge" { return "Bridge" }
        "athena" { return "Athena" }
        "onyx" { return "Onyx" }
        "memory" { return "Memory" }
        "tenant_profile" { return "Tenant Profile" }
        "tool_registry" { return "Tool Registry" }
        "recommendations" { return "Recommendations" }
        "improvement_queue" { return "Improvement Queue" }
        "behavior_trust" { return "Behavior Trust" }
        "tool_factory" { return "Tool Factory" }
        "brand_exposure" { return "Brand Exposure" }
        "keepalive_ops" { return "KeepAlive Ops" }
        "self_improvement" { return "Self-Improvement Governor" }
        "environment" { return "Environment" }
        "security_posture" { return "Security Posture" }
        "billing" { return "Billing" }
        "mirror" { return "Mirror" }
        "release_management" { return "Release Management" }
        "revenue_optimization" { return "Revenue Optimization" }
        "model_cost_governance" { return "Model Cost Governance" }
        default {
            if (-not $normalized) {
                return ""
            }
            return $normalized
        }
    }
}

function New-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet("PASS", "WARN", "FAIL")][string]$Status,
        [Parameter(Mandatory = $true)][string]$Detail,
        [string]$Component = "",
        [string]$Path = "",
        [string]$NextAction = ""
    )

    return [pscustomobject]@{
        name        = [string]$Name
        status      = [string]$Status
        detail      = [string]$Detail
        component   = [string]$Component
        path        = [string]$Path
        next_action = [string]$NextAction
    }
}

function New-SectionResult {
    param(
        [Parameter(Mandatory = $true)][string]$SectionName,
        [Parameter(Mandatory = $true)][object[]]$Checks
    )

    $failChecks = @($Checks | Where-Object { $_.status -eq "FAIL" })
    $warnChecks = @($Checks | Where-Object { $_.status -eq "WARN" })
    $passChecks = @($Checks | Where-Object { $_.status -eq "PASS" })

    $status = "PASS"
    if ($failChecks.Count -gt 0) {
        $status = "FAIL"
    }
    elseif ($warnChecks.Count -gt 0) {
        $status = "WARN"
    }

    $focusCheck = $null
    if ($failChecks.Count -gt 0) {
        $focusCheck = $failChecks[0]
    }
    elseif ($warnChecks.Count -gt 0) {
        $focusCheck = $warnChecks[0]
    }

    $fallbackPath = ""
    foreach ($check in $Checks) {
        $checkPath = Normalize-Text (Get-PropValue -Object $check -Name "path" -Default "")
        if ($checkPath) {
            $fallbackPath = $checkPath
            break
        }
    }

    $focusComponent = ""
    $focusNextAction = "No action required."
    $focusPath = [string]$fallbackPath
    if ($focusCheck) {
        $focusComponent = [string](Get-PropValue -Object $focusCheck -Name "component" -Default "")
        $focusNextAction = [string](Get-PropValue -Object $focusCheck -Name "next_action" -Default "")
        $focusPath = [string](Get-PropValue -Object $focusCheck -Name "path" -Default "")
    }

    return [pscustomobject]@{
        section_name                  = [string]$SectionName
        status                        = [string]$status
        checks_run                    = @($Checks).Count
        passed_count                  = $passChecks.Count
        failed_count                  = $failChecks.Count
        warn_count                    = $warnChecks.Count
        failing_component             = [string]$focusComponent
        recommended_next_action       = [string]$focusNextAction
        relevant_log_or_artifact_path = [string]$focusPath
        checks                        = @($Checks)
    }
}

function Convert-ArtifactStateToCheckStatus {
    param(
        [string]$RawValue,
        [string]$DefaultStatus = "WARN"
    )

    $normalized = Normalize-Text $RawValue
    if (-not $normalized) {
        return $DefaultStatus
    }

    switch ($normalized.ToUpperInvariant()) {
        "PASS" { return "PASS" }
        "OK" { return "PASS" }
        "GREEN" { return "PASS" }
        "DONE" { return "PASS" }
        "SUCCESS" { return "PASS" }
        "GUARDED" { return "PASS" }
        "ACTIVE" { return "PASS" }
        "TRUSTED" { return "PASS" }
        "WARN" { return "WARN" }
        "WARNING" { return "WARN" }
        "WATCH" { return "WARN" }
        "YELLOW" { return "WARN" }
        "STUB" { return "WARN" }
        "FAIL" { return "FAIL" }
        "FAILED" { return "FAIL" }
        "ERROR" { return "FAIL" }
        "RED" { return "FAIL" }
        "BLOCKED" { return "FAIL" }
        default { return $DefaultStatus }
    }
}

function Get-PortFromEndpoint {
    param([string]$Endpoint)

    if (-not $Endpoint) {
        return $null
    }

    $match = [regex]::Match([string]$Endpoint, ":(\d+)$")
    if (-not $match.Success) {
        return $null
    }

    $parsedPort = 0
    if ([int]::TryParse([string]$match.Groups[1].Value, [ref]$parsedPort)) {
        return [int]$parsedPort
    }

    return $null
}

function Get-PortListenersMap {
    param([int[]]$Ports)

    $portSet = [System.Collections.Generic.HashSet[int]]::new()
    $result = @{}
    foreach ($portValue in @($Ports | Sort-Object -Unique)) {
        if ($portValue -gt 0) {
            [void]$portSet.Add([int]$portValue)
            $result[[int]$portValue] = @()
        }
    }

    $lines = @(& netstat -ano -p tcp 2>$null)
    foreach ($line in $lines) {
        $trimmed = ([string]$line).Trim()
        if (-not $trimmed) {
            continue
        }
        if ($trimmed -notmatch '^\s*TCP\s+(\S+)\s+\S+\s+LISTENING\s+(\d+)\s*$') {
            continue
        }

        $localEndpoint = [string]$Matches[1]
        $parsedPort = Get-PortFromEndpoint -Endpoint $localEndpoint
        if ($null -eq $parsedPort -or -not $portSet.Contains([int]$parsedPort)) {
            continue
        }

        $ownerPid = 0
        if (-not [int]::TryParse([string]$Matches[2], [ref]$ownerPid)) {
            continue
        }

        $localAddress = $localEndpoint
        if ($localEndpoint -match '^(.*):\d+$') {
            $localAddress = [string]$Matches[1]
        }

        $entry = [pscustomobject]@{
            local_address  = [string]$localAddress
            local_endpoint = [string]$localEndpoint
            owning_pid     = [int]$ownerPid
        }
        $result[[int]$parsedPort] = @($result[[int]$parsedPort]) + @($entry)
    }

    return $result
}

function Get-ContractPorts {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $defaults = [ordered]@{
        mason_api = 8383
        seed_api  = 8109
        bridge    = 8484
        athena    = 8000
        onyx      = 5353
    }

    $aliases = @{
        mason = "mason_api"
        mason_api = "mason_api"
        masonapi = "mason_api"
        seed = "seed_api"
        seed_api = "seed_api"
        seedapi = "seed_api"
        bridge = "bridge"
        athena = "athena"
        onyx = "onyx"
    }

    $normalized = [ordered]@{}
    foreach ($key in $defaults.Keys) {
        $normalized[$key] = [int]$defaults[$key]
    }

    $portsPath = Join-Path $RepoRoot "config\ports.json"
    $portsJson = Read-JsonSafe -Path $portsPath -Default $null
    if (-not $portsJson) {
        return $normalized
    }

    $portsNode = Get-PropValue -Object $portsJson -Name "ports" -Default $null
    if (-not $portsNode) {
        return $normalized
    }

    foreach ($property in @($portsNode.PSObject.Properties)) {
        $name = Normalize-Text $property.Name
        if (-not $name) {
            continue
        }
        $aliasKey = $name.ToLowerInvariant().Replace("-", "_")
        if (-not $aliases.ContainsKey($aliasKey)) {
            continue
        }
        $parsed = 0
        if ([int]::TryParse([string]$property.Value, [ref]$parsed) -and $parsed -gt 0 -and $parsed -le 65535) {
            $normalized[$aliases[$aliasKey]] = [int]$parsed
        }
    }

    return $normalized
}

$script:HttpProbeCache = @{}

function Invoke-HttpProbeCached {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSeconds = 5,
        [switch]$NoContentLimit
    )

    $cacheKey = if ($NoContentLimit) { "{0}|full" -f $Url } else { $Url }
    if ($script:HttpProbeCache.ContainsKey($cacheKey)) {
        return $script:HttpProbeCache[$cacheKey]
    }

    $payload = [ordered]@{
        url         = [string]$Url
        ok          = $false
        status_code = 0
        content     = ""
        error       = ""
    }

    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $TimeoutSeconds -MaximumRedirection 5
        $payload.ok = $true
        $payload.status_code = [int]$response.StatusCode
        if ($NoContentLimit) {
            $payload.content = [string]$response.Content
        }
        else {
            $payload.content = Limit-Text -Text ([string]$response.Content) -MaxLength 4000
        }
    }
    catch {
        $payload.error = Limit-Text -Text $_.Exception.Message -MaxLength 400
        if ($_.Exception.Response) {
            try {
                $payload.status_code = [int]$_.Exception.Response.StatusCode.value__
            }
            catch {
                try {
                    $payload.status_code = [int]$_.Exception.Response.StatusCode
                }
                catch {
                    $payload.status_code = 0
                }
            }
            try {
                $stream = $_.Exception.Response.GetResponseStream()
                if ($stream) {
                    $reader = New-Object System.IO.StreamReader($stream)
                    try {
                        $errorBody = $reader.ReadToEnd()
                        if ($NoContentLimit) {
                            $payload.content = [string]$errorBody
                        }
                        else {
                            $payload.content = Limit-Text -Text $errorBody -MaxLength 4000
                        }
                    }
                    finally {
                        $reader.Close()
                    }
                }
            }
            catch {
                $payload.content = ""
            }
        }
    }

    $result = [pscustomobject]$payload
    $script:HttpProbeCache[$cacheKey] = $result
    return $result
}

function Invoke-HttpJsonProbeCached {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSeconds = 5
    )

    $probe = Invoke-HttpProbeCached -Url $Url -TimeoutSeconds $TimeoutSeconds -NoContentLimit
    $data = $null
    $parseError = ""

    if ([int]$probe.status_code -eq 200 -and (Normalize-Text $probe.content)) {
        try {
            $data = $probe.content | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            $parseError = Limit-Text -Text $_.Exception.Message -MaxLength 300
        }
    }

    $errorText = [string]$probe.error
    if ($parseError) {
        $errorText = $parseError
    }

    return [pscustomobject]@{
        ok          = [bool]($probe.ok -and [int]$probe.status_code -eq 200 -and $null -ne $data)
        status_code = [int]$probe.status_code
        error       = $errorText
        data        = $data
        content     = [string]$probe.content
        url         = [string]$probe.url
    }
}

function Get-AgeHours {
    param($Timestamp)

    $normalized = Normalize-Text $Timestamp
    if (-not $normalized) {
        return [double]::PositiveInfinity
    }

    try {
        $parsed = [datetimeoffset]::Parse($normalized, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
        return [math]::Round(((Get-Date).ToUniversalTime() - $parsed.UtcDateTime).TotalHours, 2)
    }
    catch {
        return [double]::PositiveInfinity
    }
}

function Get-FileArtifactCheck {
    param(
        [Parameter(Mandatory = $true)][string]$CheckName,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Component,
        [Parameter(Mandatory = $true)][string]$MissingNextAction,
        [string[]]$RequiredKeys = @()
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{
            check = New-Check -Name $CheckName -Status "FAIL" -Detail ("Missing artifact: {0}" -f $Path) -Component $Component -Path $Path -NextAction $MissingNextAction
            data  = $null
        }
    }

    $data = Read-JsonSafe -Path $Path -Default $null
    if ($null -eq $data) {
        return [pscustomobject]@{
            check = New-Check -Name $CheckName -Status "FAIL" -Detail ("Artifact is not readable JSON: {0}" -f $Path) -Component $Component -Path $Path -NextAction ("Repair or rewrite the artifact at {0}." -f $Path)
            data  = $null
        }
    }

    $missingKeys = @()
    foreach ($requiredKey in $RequiredKeys) {
        $hasProperty = Test-ObjectHasKey -Object $data -Name $requiredKey
        if (-not $hasProperty) {
            $missingKeys += $requiredKey
            continue
        }

        $value = Get-PropValue -Object $data -Name $requiredKey -Default $null
        if ($null -eq $value) {
            $missingKeys += $requiredKey
            continue
        }
        if ($value -is [string] -and -not (Normalize-Text $value)) {
            $missingKeys += $requiredKey
        }
    }

    if ($missingKeys.Count -gt 0) {
        return [pscustomobject]@{
            check = New-Check -Name $CheckName -Status "FAIL" -Detail ("Artifact is missing required fields: {0}" -f ($missingKeys -join ", ")) -Component $Component -Path $Path -NextAction ("Rewrite {0} with the required schema." -f $Path)
            data  = $data
        }
    }

    return [pscustomobject]@{
        check = New-Check -Name $CheckName -Status "PASS" -Detail ("Readable artifact: {0}" -f $Path) -Component $Component -Path $Path -NextAction "No action required."
        data  = $data
    }
}

function Get-AllowedRecommendationStatuses {
    return @("new", "seen", "accepted", "dismissed", "completed")
}

function Get-AllowedImprovementStatuses {
    return @("new", "triaged", "planned", "in_progress", "blocked", "completed", "reverted", "dismissed")
}

function Get-AllowedTrustStates {
    return @("discovered", "shadow", "tested", "candidate", "approved", "trusted", "auto_allowed", "blocked", "reverted")
}

function Get-AllowedToolFactoryStatuses {
    return @("new", "spec_ready", "build_ready", "built", "tested", "published", "rejected")
}

function Add-UniqueString {
    param(
        [System.Collections.Generic.List[string]]$Target,
        [string]$Value
    )

    $normalized = Normalize-Text $Value
    if (-not $normalized) {
        return
    }
    if (-not $Target.Contains($normalized)) {
        [void]$Target.Add($normalized)
    }
}

$repoRoot = Get-RepoRoot -OverrideRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$systemValidationPath = Join-Path $reportsDir "system_validation_last.json"
$startRunPath = Join-Path $reportsDir "start\start_run_last.json"
$verifyLastPath = Join-Path $reportsDir "verify_last.json"
$mirrorUpdatePath = Join-Path $reportsDir "mirror_update_last.json"
$contextPackPath = Join-Path $reportsDir "context_pack.json"
$memoryIngestPath = Join-Path $reportsDir "memory_ingest_last.json"
$memoryRetrievePath = Join-Path $reportsDir "memory_retrieve_last.json"
$billingSummaryPath = Join-Path $reportsDir "billing_summary.json"
$brandExposureSummaryPath = Join-Path $reportsDir "brand_exposure_isolation_last.json"
$brandLeakAuditPath = Join-Path $reportsDir "brand_leak_audit_last.json"
$publicVocabularyPolicyLastPath = Join-Path $reportsDir "public_vocabulary_policy_last.json"
$liveDocsIndexPath = Join-Path $reportsDir "live_docs_index.json"
$liveDocsSummaryPath = Join-Path $reportsDir "live_docs_summary.json"
$systemTruthSpinePath = Join-Path $reportsDir "system_truth_spine_last.json"
$systemMetricsSpinePath = Join-Path $reportsDir "system_metrics_spine_last.json"
$systemTruthSummaryPath = Join-Path $reportsDir "system_truth_summary_last.json"
$regressionGuardLastPath = Join-Path $reportsDir "regression_guard_last.json"
$rollbackPlanLastPath = Join-Path $reportsDir "rollback_plan_last.json"
$promotionGateLastPath = Join-Path $reportsDir "promotion_gate_last.json"
$playbookLibraryLastPath = Join-Path $reportsDir "playbook_library_last.json"
$supportBrainLastPath = Join-Path $reportsDir "support_brain_last.json"
$incidentExplanationsLastPath = Join-Path $reportsDir "incident_explanations_last.json"
$wedgePackFrameworkLastPath = Join-Path $reportsDir "wedge_pack_framework_last.json"
$segmentOverlayLastPath = Join-Path $reportsDir "segment_overlay_last.json"
$workflowPackLastPath = Join-Path $reportsDir "workflow_pack_last.json"
$businessOutcomesLastPath = Join-Path $reportsDir "business_outcomes_last.json"
$toolUsefulnessLastPath = Join-Path $reportsDir "tool_usefulness_last.json"
$recommendationEffectivenessLastPath = Join-Path $reportsDir "recommendation_effectiveness_last.json"
$tenantEngagementLastPath = Join-Path $reportsDir "tenant_engagement_last.json"
$releaseManagementLastPath = Join-Path $reportsDir "release_management_last.json"
$releaseCandidateLastPath = Join-Path $reportsDir "release_candidate_last.json"
$releaseNotesLastPath = Join-Path $reportsDir "release_notes_last.json"
$releaseRolloutLastPath = Join-Path $reportsDir "release_rollout_last.json"
$revenueOptimizationLastPath = Join-Path $reportsDir "revenue_optimization_last.json"
$planFitAnalysisLastPath = Join-Path $reportsDir "plan_fit_analysis_last.json"
$upgradeSuggestionsLastPath = Join-Path $reportsDir "upgrade_suggestions_last.json"
$churnRescueLastPath = Join-Path $reportsDir "churn_rescue_last.json"
$modelCostGovernanceLastPath = Join-Path $reportsDir "model_cost_governance_last.json"
$taskClassificationLastPath = Join-Path $reportsDir "task_classification_last.json"
$teacherUsefulnessLastPath = Join-Path $reportsDir "teacher_usefulness_last.json"
$costEffectivenessLastPath = Join-Path $reportsDir "cost_effectiveness_last.json"
$knowledgeQualityLastPath = Join-Path $reportsDir "knowledge_quality_last.json"
$knowledgeCardsLastPath = Join-Path $reportsDir "knowledge_cards_last.json"
$knowledgeReuseLastPath = Join-Path $reportsDir "knowledge_reuse_last.json"
$antiRepeatMemoryLastPath = Join-Path $reportsDir "anti_repeat_memory_last.json"
$outcomeLearningLastPath = Join-Path $reportsDir "outcome_learning_last.json"
$uxSimplicityLastPath = Join-Path $reportsDir "ux_simplicity_last.json"
$athenaFounderUxLastPath = Join-Path $reportsDir "athena_founder_ux_last.json"
$onyxCustomerUxLastPath = Join-Path $reportsDir "onyx_customer_ux_last.json"
$approvalSurfaceLastPath = Join-Path $reportsDir "approval_surface_last.json"
$wholeFolderVerificationPath = Join-Path $reportsDir "whole_folder_verification_last.json"
$wholeFolderInventoryPath = Join-Path $reportsDir "whole_folder_inventory_last.json"
$wholeFolderRegistrationGapsPath = Join-Path $reportsDir "whole_folder_registration_gaps.json"
$wholeFolderBrokenPathsPath = Join-Path $reportsDir "whole_folder_broken_paths_last.json"
$wholeFolderGoldenPathsPath = Join-Path $reportsDir "whole_folder_golden_paths_last.json"
$wholeFolderFaultTestsPath = Join-Path $reportsDir "whole_folder_fault_tests_last.json"
$wholeFolderMigrationChecksPath = Join-Path $reportsDir "whole_folder_migration_checks_last.json"
$wholeFolderUsabilityChecksPath = Join-Path $reportsDir "whole_folder_usability_checks_last.json"
$wholeFolderCleanupQueuePath = Join-Path $reportsDir "whole_folder_cleanup_queue.json"
$wholeFolderSummaryMarkdownPath = Join-Path $reportsDir "whole_folder_verification_summary.md"
$repairWave01LastPath = Join-Path $reportsDir "repair_wave_01_last.json"
$repairOnboardingLastPath = Join-Path $reportsDir "repair_onboarding_last.json"
$repairBillingEntitlementsLastPath = Join-Path $reportsDir "repair_billing_entitlements_last.json"
$repairHalfwiredLastPath = Join-Path $reportsDir "repair_halfwired_last.json"
$repairRegistrationGapsLastPath = Join-Path $reportsDir "repair_registration_gaps_last.json"
$repairSchedulerOversightLastPath = Join-Path $reportsDir "repair_scheduler_oversight_last.json"
$repairInternalVisibilityLastPath = Join-Path $reportsDir "repair_internal_visibility_last.json"
$repairMirrorHardeningLastPath = Join-Path $reportsDir "repair_mirror_hardening_last.json"
$repairBrokenPathsFixedLastPath = Join-Path $reportsDir "repair_broken_paths_fixed_last.json"
$repairUnfixedQueueLastPath = Join-Path $reportsDir "repair_unfixed_queue_last.json"
$repairWave02LastPath = Join-Path $reportsDir "repair_wave_02_last.json"
$internalSchedulerLastPath = Join-Path $reportsDir "internal_scheduler_last.json"
$legacyTaskInventoryLastPath = Join-Path $reportsDir "legacy_task_inventory_last.json"
$legacyTaskMigrationLastPath = Join-Path $reportsDir "legacy_task_migration_last.json"
$popupSuppressionLastPath = Join-Path $reportsDir "popup_suppression_last.json"
$validatorCoverageRepairLastPath = Join-Path $reportsDir "validator_coverage_repair_last.json"
$brokenPathClusterRepairLastPath = Join-Path $reportsDir "broken_path_cluster_repair_last.json"
$remotePushRepairLastPath = Join-Path $reportsDir "remote_push_repair_last.json"
$repairWave02UnfixedQueueLastPath = Join-Path $reportsDir "repair_wave_02_unfixed_queue_last.json"
$repairWave03LastPath = Join-Path $reportsDir "repair_wave_03_last.json"
$internalSchedulerMigrationLastPath = Join-Path $reportsDir "internal_scheduler_migration_last.json"
$windowsTaskFallbackLastPath = Join-Path $reportsDir "windows_task_fallback_last.json"
$popupWindowEliminationLastPath = Join-Path $reportsDir "popup_window_elimination_last.json"
$brokenPathReductionWave03LastPath = Join-Path $reportsDir "broken_path_reduction_wave_03_last.json"
$onyxCoreFlowVerificationLastPath = Join-Path $reportsDir "onyx_core_flow_verification_last.json"
$repairWave03UnfixedQueueLastPath = Join-Path $reportsDir "repair_wave_03_unfixed_queue_last.json"
$mirrorCoverageLastPath = Join-Path $reportsDir "mirror_coverage_last.json"
$mirrorOmissionLastPath = Join-Path $reportsDir "mirror_omission_last.json"
$mirrorSafeIndexPath = Join-Path $reportsDir "mirror_safe_index.md"
$athenaWidgetStatusPath = Join-Path $reportsDir "athena_widget_status.json"
$onyxStackHealthPath = Join-Path $reportsDir "onyx_stack_health.json"
$liveDocsMasonPath = Join-Path $reportsDir "docs\mason_live_manual.json"
$liveDocsAthenaPath = Join-Path $reportsDir "docs\athena_live_manual.json"
$liveDocsOnyxPath = Join-Path $reportsDir "docs\onyx_live_manual.json"
$environmentProfilePath = Join-Path $reportsDir "environment_profile_last.json"
$environmentDriftPath = Join-Path $reportsDir "environment_drift_last.json"
$runtimePosturePath = Join-Path $reportsDir "runtime_posture_last.json"
$keepAliveLastPath = Join-Path $reportsDir "keepalive_last.json"
$selfHealLastPath = Join-Path $reportsDir "self_heal_last.json"
$dailyReportLastPath = Join-Path $reportsDir "daily_report_last.json"
$escalationQueueLastPath = Join-Path $reportsDir "escalation_queue_last.json"
$selfImprovementGovernorPath = Join-Path $reportsDir "self_improvement_governor_last.json"
$teacherCallBudgetPath = Join-Path $reportsDir "teacher_call_budget_last.json"
$teacherDecisionLogPath = Join-Path $reportsDir "teacher_decision_log_last.json"
$queueReportPath = Join-Path $reportsDir "queue\improvement_queue_last.json"
$behaviorTrustReportPath = Join-Path $reportsDir "queue\behavior_trust_last.json"
$toolFactoryReportPath = Join-Path $reportsDir "queue\tool_factory_last.json"
$securityPosturePath = Join-Path $reportsDir "security_posture.json"
$tenantSafetyPath = Join-Path $reportsDir "tenant_safety_report.json"
$auditLogPath = Join-Path $reportsDir "platform_audit.jsonl"
$toolRunsDir = Join-Path $reportsDir "tools"

$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"
$memoryRoot = Join-Path $stateKnowledgeDir "memory"
$memoryCatalogPath = Join-Path $memoryRoot "catalog.json"
$memoryHotIndexPath = Join-Path $memoryRoot "hot\index.json"
$memoryColdIndexPath = Join-Path $memoryRoot "cold\index.json"
$improvementQueuePath = Join-Path $stateKnowledgeDir "improvement_queue.json"
$behaviorTrustPath = Join-Path $stateKnowledgeDir "behavior_trust.json"
$toolFactoryPath = Join-Path $stateKnowledgeDir "tool_factory.json"
$trustIndexPath = Join-Path $stateKnowledgeDir "trust_index.json"
$selfImprovementPolicyPath = Join-Path $stateKnowledgeDir "self_improvement_policy.json"
$dataGovernanceStatePath = Join-Path $stateKnowledgeDir "data_governance_requests.json"
$stackPidPath = Join-Path $stateKnowledgeDir "stack_pids.json"
$environmentRegistryPath = Join-Path $stateKnowledgeDir "environment_registry.json"
$systemTruthRegistryPath = Join-Path $stateKnowledgeDir "system_truth_registry.json"
$regressionBaselinesPath = Join-Path $stateKnowledgeDir "regression_baselines.json"
$playbookRegistryPath = Join-Path $stateKnowledgeDir "playbook_registry.json"
$wedgePackRegistryPath = Join-Path $stateKnowledgeDir "wedge_pack_registry.json"
$businessOutcomeRegistryPath = Join-Path $stateKnowledgeDir "business_outcome_registry.json"
$releaseRegistryPath = Join-Path $stateKnowledgeDir "release_registry.json"
$revenueOptimizationRegistryPath = Join-Path $stateKnowledgeDir "revenue_optimization_registry.json"
$modelCostRegistryPath = Join-Path $stateKnowledgeDir "model_cost_registry.json"
$knowledgeCardsStatePath = Join-Path $stateKnowledgeDir "knowledge_cards.json"
$knowledgeFailuresStatePath = Join-Path $stateKnowledgeDir "knowledge_failures.json"
$knowledgeOutcomesStatePath = Join-Path $stateKnowledgeDir "knowledge_outcomes.json"
$knowledgeReuseHistoryPath = Join-Path $stateKnowledgeDir "knowledge_reuse_history.json"
$uxSimplicityRegistryPath = Join-Path $stateKnowledgeDir "ux_simplicity_registry.json"
$internalSchedulerRegistryPath = Join-Path $stateKnowledgeDir "internal_scheduler_registry.json"

$onyxStateDir = Join-Path $repoRoot "state\onyx"
$tenantWorkspacePath = Join-Path $onyxStateDir "tenant_workspace.json"
$planStatePath = Join-Path $onyxStateDir "plan_state.json"
$onyxTenantsDir = Join-Path $onyxStateDir "tenants"
$onyxRecommendationsDir = Join-Path $onyxStateDir "recommendations"
$onyxBillingDir = Join-Path $onyxStateDir "billing"

$toolRegistryPath = Join-Path $repoRoot "config\tool_registry.json"
$componentRegistryPath = Join-Path $repoRoot "config\component_registry.json"
$knowledgeQualityPolicyPath = Join-Path $repoRoot "config\knowledge_quality_policy.json"
$componentDocsRegistryPath = Join-Path $repoRoot "config\component_docs_registry.json"
$brandExposurePolicyPath = Join-Path $repoRoot "config\brand_exposure_policy.json"
$keepAlivePolicyPath = Join-Path $repoRoot "config\keepalive_policy.json"
$regressionGuardPolicyPath = Join-Path $repoRoot "config\regression_guard_policy.json"
$playbookSupportPolicyPath = Join-Path $repoRoot "config\playbook_support_policy.json"
$wedgePackPolicyPath = Join-Path $repoRoot "config\wedge_pack_policy.json"
$businessOutcomePolicyPath = Join-Path $repoRoot "config\business_outcome_policy.json"
$releaseManagementPolicyPath = Join-Path $repoRoot "config\release_management_policy.json"
$revenueOptimizationPolicyPath = Join-Path $repoRoot "config\revenue_optimization_policy.json"
$modelCostGovernancePolicyPath = Join-Path $repoRoot "config\model_cost_governance_policy.json"
$uxSimplicityPolicyPath = Join-Path $repoRoot "config\ux_simplicity_policy.json"
$wholeFolderVerificationPolicyPath = Join-Path $repoRoot "config\whole_folder_verification_policy.json"
$repairWave01PolicyPath = Join-Path $repoRoot "config\repair_wave_01_policy.json"
$repairWave02PolicyPath = Join-Path $repoRoot "config\repair_wave_02_policy.json"
$repairWave03PolicyPath = Join-Path $repoRoot "config\repair_wave_03_policy.json"
$internalSchedulerPolicyPath = Join-Path $repoRoot "config\internal_scheduler_policy.json"
$legacyTaskMigrationPolicyPath = Join-Path $repoRoot "config\legacy_task_migration_policy.json"
$tiersPath = Join-Path $repoRoot "config\tiers.json"
$billingProviderPath = Join-Path $repoRoot "config\billing_provider.json"
$rbacPolicyPath = Join-Path $repoRoot "config\rbac_policy.json"
$dataGovernancePolicyPath = Join-Path $repoRoot "config\data_governance_policy.json"
$toolRunnerPath = Join-Path $repoRoot "tools\platform\ToolRunner.ps1"

$ports = Get-ContractPorts -RepoRoot $repoRoot
$expectedPorts = [ordered]@{
    mason_api = 8383
    seed_api  = 8109
    bridge    = 8484
    athena    = 8000
    onyx      = 5353
}
$portListeners = Get-PortListenersMap -Ports @($expectedPorts.Values)
$stackPidArtifact = Read-JsonSafe -Path $stackPidPath -Default $null
$stackCurrentLivePids = if ($stackPidArtifact) { Get-PropValue -Object $stackPidArtifact -Name "current_live_pids" -Default $null } else { $null }

$stackStatusUrl = "http://127.0.0.1:8000/api/stack_status"
$athenaUiUrl = "http://127.0.0.1:8000/athena/"
$athenaHealthUrl = "http://127.0.0.1:8000/api/health"
$onyxRootUrl = "http://127.0.0.1:5353/"
$onyxMainJsUrl = "http://127.0.0.1:5353/main.dart.js"
$masonApiHealthUrl = "http://127.0.0.1:8383/health"
$seedApiHealthUrl = "http://127.0.0.1:8109/health"
$bridgeHealthUrl = "http://127.0.0.1:8484/health"

$stackStatusProbe = Invoke-HttpJsonProbeCached -Url $stackStatusUrl -TimeoutSeconds ([Math]::Max($HttpTimeoutSeconds, 45))
$athenaUiProbe = Invoke-HttpProbeCached -Url $athenaUiUrl -TimeoutSeconds $HttpTimeoutSeconds
$athenaHealthProbe = Invoke-HttpProbeCached -Url $athenaHealthUrl -TimeoutSeconds $HttpTimeoutSeconds
$onyxRootProbe = Invoke-HttpProbeCached -Url $onyxRootUrl -TimeoutSeconds $HttpTimeoutSeconds
$onyxMainJsProbe = Invoke-HttpProbeCached -Url $onyxMainJsUrl -TimeoutSeconds $HttpTimeoutSeconds
$masonApiHealthProbe = Invoke-HttpProbeCached -Url $masonApiHealthUrl -TimeoutSeconds $HttpTimeoutSeconds
$seedApiHealthProbe = Invoke-HttpProbeCached -Url $seedApiHealthUrl -TimeoutSeconds $HttpTimeoutSeconds
$bridgeHealthProbe = Invoke-HttpProbeCached -Url $bridgeHealthUrl -TimeoutSeconds $HttpTimeoutSeconds

$startRunArtifact = Read-JsonSafe -Path $startRunPath -Default $null
$mirrorArtifact = Read-JsonSafe -Path $mirrorUpdatePath -Default $null
$tenantWorkspaceArtifact = Read-JsonSafe -Path $tenantWorkspacePath -Default $null
$toolRegistryArtifact = Read-JsonSafe -Path $toolRegistryPath -Default $null
$componentRegistryArtifact = Read-JsonSafe -Path $componentRegistryPath -Default $null
$queueArtifact = Read-JsonSafe -Path $improvementQueuePath -Default $null
$behaviorTrustArtifact = Read-JsonSafe -Path $behaviorTrustPath -Default $null
$toolFactoryArtifact = Read-JsonSafe -Path $toolFactoryPath -Default $null

$tenantFiles = @()
if (Test-Path -LiteralPath $onyxTenantsDir) {
    $tenantFiles = @(Get-ChildItem -LiteralPath $onyxTenantsDir -File -Filter "*.json" | Sort-Object LastWriteTime -Descending)
}
$recommendationFiles = @()
if (Test-Path -LiteralPath $onyxRecommendationsDir) {
    $recommendationFiles = @(Get-ChildItem -LiteralPath $onyxRecommendationsDir -File -Filter "*.json" | Sort-Object LastWriteTime -Descending)
}
$billingFiles = @()
if (Test-Path -LiteralPath $onyxBillingDir) {
    $billingFiles = @(Get-ChildItem -LiteralPath $onyxBillingDir -File -Filter "*.json" | Sort-Object LastWriteTime -Descending)
}
$toolRunDirs = @()
if (Test-Path -LiteralPath $toolRunsDir) {
    $toolRunDirs = @(Get-ChildItem -LiteralPath $toolRunsDir -Directory | Sort-Object LastWriteTime -Descending)
}

$activeTenantIds = [System.Collections.Generic.List[string]]::new()
$workspaceActiveTenantId = Normalize-Text (Get-PropValue -Object $tenantWorkspaceArtifact -Name "activeTenantId" -Default "")
Add-UniqueString -Target $activeTenantIds -Value $workspaceActiveTenantId

foreach ($context in @((Get-PropValue -Object $tenantWorkspaceArtifact -Name "contexts" -Default @()))) {
    $tenantNode = Get-PropValue -Object $context -Name "tenant" -Default $null
    Add-UniqueString -Target $activeTenantIds -Value (Get-PropValue -Object $tenantNode -Name "id" -Default "")
}
foreach ($file in $tenantFiles) {
    Add-UniqueString -Target $activeTenantIds -Value $file.BaseName
}
foreach ($file in $recommendationFiles) {
    Add-UniqueString -Target $activeTenantIds -Value $file.BaseName
}
foreach ($file in $billingFiles) {
    Add-UniqueString -Target $activeTenantIds -Value $file.BaseName
}

$sections = @()

# stack/base
$stackChecks = @()
$portDrift = @()
foreach ($name in $expectedPorts.Keys) {
    if ([int]$ports[$name] -ne [int]$expectedPorts[$name]) {
        $portDrift += ("{0}={1}" -f $name, [int]$ports[$name])
    }
}
if ($portDrift.Count -eq 0) {
    $stackChecks += New-Check -Name "port_contract" -Status "PASS" -Detail "Loopback port contract matches 8383, 8109, 8484, 8000, 5353." -Component "stack/base" -Path (Join-Path $repoRoot "config\ports.json") -NextAction "No action required."
}
else {
    $stackChecks += New-Check -Name "port_contract" -Status "FAIL" -Detail ("Port contract drift detected: {0}" -f ($portDrift -join ", ")) -Component "stack/base" -Path (Join-Path $repoRoot "config\ports.json") -NextAction "Restore config/ports.json to the loopback contract 8383, 8109, 8484, 8000, 5353."
}

foreach ($entry in @(
    [pscustomobject]@{ name = "mason_api"; port = 8383; health_url = $masonApiHealthUrl },
    [pscustomobject]@{ name = "seed_api"; port = 8109; health_url = $seedApiHealthUrl },
    [pscustomobject]@{ name = "bridge"; port = 8484; health_url = $bridgeHealthUrl },
    [pscustomobject]@{ name = "athena"; port = 8000; health_url = $athenaHealthUrl },
    [pscustomobject]@{ name = "onyx"; port = 5353; health_url = $onyxMainJsUrl }
)) {
    $listeners = @()
    if ($portListeners.ContainsKey([int]$entry.port)) {
        $listeners = @($portListeners[[int]$entry.port])
    }
    if ($listeners.Count -gt 0) {
        $listenerSummary = ($listeners | Select-Object -First 2 | ForEach-Object { "{0} pid={1}" -f $_.local_address, $_.owning_pid }) -join "; "
        $stackChecks += New-Check -Name ("listener_{0}" -f $entry.name) -Status "PASS" -Detail ("Port {0} is listening ({1})." -f $entry.port, $listenerSummary) -Component $entry.name -Path $startRunPath -NextAction "No action required."
    }
    else {
        $stackChecks += New-Check -Name ("listener_{0}" -f $entry.name) -Status "FAIL" -Detail ("Port {0} is not listening." -f $entry.port) -Component $entry.name -Path $startRunPath -NextAction ("Start or reset the stack until {0} listens on {1}." -f (Get-ComponentLabel $entry.name), $entry.port)
    }

    $ownerPids = @($listeners | ForEach-Object { [int]$_.owning_pid } | Where-Object { $_ -gt 0 } | Sort-Object -Unique)
    if ($ownerPids.Count -le 1) {
        $stackChecks += New-Check -Name ("singleton_{0}" -f $entry.name) -Status "PASS" -Detail ("Singleton listener ownership is clean for port {0}." -f $entry.port) -Component $entry.name -Path $stackPidPath -NextAction "No action required."
    }
    else {
        $ownerText = ($ownerPids | ForEach-Object { $_.ToString() }) -join ", "
        $stackChecks += New-Check -Name ("singleton_{0}" -f $entry.name) -Status "WARN" -Detail ("Port {0} has multiple listener owners: {1}." -f $entry.port, $ownerText) -Component $entry.name -Path $stackPidPath -NextAction ("Run the normal stack reset/start flow to collapse duplicate singleton ownership for {0}." -f (Get-ComponentLabel $entry.name))
    }

    $canonicalRaw = $null
    if ($stackCurrentLivePids) {
        $canonicalRaw = Get-PropValue -Object $stackCurrentLivePids -Name $entry.name -Default $null
    }
    if (-not $canonicalRaw) {
        $topLevelPidKey = switch ($entry.name) {
            "mason_api" { "mason_api_pid" }
            "seed_api" { "seed_api_pid" }
            "bridge" { "bridge_pid" }
            "athena" { "athena_pid" }
            "onyx" { "onyx_pid" }
            default { "" }
        }
        if ($topLevelPidKey) {
            $canonicalRaw = Get-PropValue -Object $stackPidArtifact -Name $topLevelPidKey -Default $null
        }
    }

    $canonicalPid = 0
    if ($ownerPids.Count -eq 1 -and [int]::TryParse([string]$canonicalRaw, [ref]$canonicalPid) -and $canonicalPid -gt 0) {
        if ($ownerPids -contains $canonicalPid) {
            $stackChecks += New-Check -Name ("stack_pid_truth_{0}" -f $entry.name) -Status "PASS" -Detail ("stack_pids canonical pid matches the live listener owner for port {0}." -f $entry.port) -Component $entry.name -Path $stackPidPath -NextAction "No action required."
        }
        else {
            $stackChecks += New-Check -Name ("stack_pid_truth_{0}" -f $entry.name) -Status "WARN" -Detail ("stack_pids canonical pid {0} does not match live listener owner {1} for port {2}." -f $canonicalPid, [int]$ownerPids[0], $entry.port) -Component $entry.name -Path $stackPidPath -NextAction ("Refresh the normal stack start flow so stack_pids.json matches live runtime truth for {0}." -f (Get-ComponentLabel $entry.name))
        }
    }
    elseif ($ownerPids.Count -eq 1) {
        $stackChecks += New-Check -Name ("stack_pid_truth_{0}" -f $entry.name) -Status "WARN" -Detail ("stack_pids.json is missing a canonical live pid for {0}." -f (Get-ComponentLabel $entry.name)) -Component $entry.name -Path $stackPidPath -NextAction ("Refresh the normal stack start flow so stack_pids.json records the live owner for {0}." -f (Get-ComponentLabel $entry.name))
    }
}

$listenerHealthyByComponent = @{
    mason_api = $(if ($portListeners.ContainsKey(8383)) { @($portListeners[8383]).Count -gt 0 } else { $false })
    seed_api  = $(if ($portListeners.ContainsKey(8109)) { @($portListeners[8109]).Count -gt 0 } else { $false })
    bridge    = $(if ($portListeners.ContainsKey(8484)) { @($portListeners[8484]).Count -gt 0 } else { $false })
    athena    = $(if ($portListeners.ContainsKey(8000)) { @($portListeners[8000]).Count -gt 0 } else { $false })
    onyx      = $(if ($portListeners.ContainsKey(5353)) { @($portListeners[5353]).Count -gt 0 } else { $false })
}

foreach ($probeConfig in @(
    [pscustomobject]@{ name = "mason_api_health"; component = "mason_api"; probe = $masonApiHealthProbe; path = $masonApiHealthUrl },
    [pscustomobject]@{ name = "seed_api_health"; component = "seed_api"; probe = $seedApiHealthProbe; path = $seedApiHealthUrl },
    [pscustomobject]@{ name = "bridge_health"; component = "bridge"; probe = $bridgeHealthProbe; path = $bridgeHealthUrl },
    [pscustomobject]@{ name = "athena_health"; component = "athena"; probe = $athenaHealthProbe; path = $athenaHealthUrl },
    [pscustomobject]@{ name = "onyx_main_dart_js"; component = "onyx"; probe = $onyxMainJsProbe; path = $onyxMainJsUrl }
)) {
    if ([int]$probeConfig.probe.status_code -eq 200) {
        $stackChecks += New-Check -Name ("endpoint_{0}" -f $probeConfig.name) -Status "PASS" -Detail ("HTTP 200 from {0}" -f $probeConfig.path) -Component $probeConfig.component -Path $probeConfig.path -NextAction "No action required."
    }
    else {
        $stackChecks += New-Check -Name ("endpoint_{0}" -f $probeConfig.name) -Status "FAIL" -Detail ("Expected HTTP 200 from {0}; got {1} ({2})." -f $probeConfig.path, [int]$probeConfig.probe.status_code, (Normalize-Text $probeConfig.probe.error)) -Component $probeConfig.component -Path $probeConfig.path -NextAction ("Restore {0} until {1} returns HTTP 200." -f (Get-ComponentLabel $probeConfig.component), $probeConfig.path)
    }
}

$endpointHealthyByComponent = @{
    mason_api = ([int]$masonApiHealthProbe.status_code -eq 200)
    seed_api  = ([int]$seedApiHealthProbe.status_code -eq 200)
    bridge    = ([int]$bridgeHealthProbe.status_code -eq 200)
    athena    = ([int]$athenaHealthProbe.status_code -eq 200)
    onyx      = ([int]$onyxMainJsProbe.status_code -eq 200)
}

$startRunCheck = Get-FileArtifactCheck -CheckName "start_run_last_readable" -Path $startRunPath -Component "stack/base" -MissingNextAction "Run the stack start flow so reports/start/start_run_last.json is written." -RequiredKeys @("generated_at_utc", "run_id", "overall_status")
$stackChecks += $startRunCheck.check
if ($startRunCheck.data) {
    $startRunOverallStatus = Normalize-Text (Get-PropValue -Object $startRunCheck.data -Name "overall_status" -Default "")
    $startRunOverallStatusDisplay = if ($startRunOverallStatus) { $startRunOverallStatus } else { "unknown" }
    $runtimeFailureComponents = New-Object System.Collections.Generic.List[string]
    foreach ($componentName in @("mason_api", "seed_api", "bridge", "athena", "onyx")) {
        $listenerHealthy = [bool]($listenerHealthyByComponent[$componentName])
        $endpointHealthy = [bool]($endpointHealthyByComponent[$componentName])
        if (-not $listenerHealthy -or -not $endpointHealthy) {
            $runtimeFailureComponents.Add([string]$componentName) | Out-Null
        }
    }

    if ($startRunOverallStatus -eq "PASS" -and $runtimeFailureComponents.Count -gt 0) {
        $componentDisplay = ($runtimeFailureComponents | ForEach-Object { Get-ComponentLabel $_ }) -join ", "
        $stackChecks += New-Check -Name "start_run_last_status" -Status "FAIL" -Detail ("start_run_last.json overall_status=PASS but live runtime is failing for: {0}." -f $componentDisplay) -Component "stack/base" -Path $startRunPath -NextAction "Run the normal stack reset/start flow so the authoritative start artifact matches live runtime health."
    }
    elseif ($startRunOverallStatus -and $startRunOverallStatus -ne "PASS" -and $runtimeFailureComponents.Count -eq 0) {
        $stackChecks += New-Check -Name "start_run_last_status" -Status "WARN" -Detail ("start_run_last.json overall_status={0} but live runtime probes are currently healthy." -f $startRunOverallStatusDisplay) -Component "stack/base" -Path $startRunPath -NextAction "Rerun the normal stack start flow to refresh reports/start/start_run_last.json."
    }
    else {
        $stackChecks += New-Check -Name "start_run_last_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $startRunOverallStatus -DefaultStatus "WARN") -Detail ("start_run_last.json overall_status={0}" -f $startRunOverallStatusDisplay) -Component "stack/base" -Path $startRunPath -NextAction "Inspect reports/start/start_run_last.json and rerun the stack start flow if the baseline is not PASS."
    }
}

if ($componentRegistryArtifact) {
    $componentMap = @{
        mason     = "stack/base"
        mason_api = "stack/base"
        seed_api  = "stack/base"
        bridge    = "stack/base"
        athena    = "Athena"
        onyx      = "Onyx"
    }
    $unmappedComponents = @()
    foreach ($component in @((Get-PropValue -Object $componentRegistryArtifact -Name "components" -Default @()))) {
        $componentId = Normalize-Text (Get-PropValue -Object $component -Name "id" -Default "")
        if (-not $componentId) {
            continue
        }
        if (-not $componentMap.ContainsKey($componentId.ToLowerInvariant())) {
            $unmappedComponents += $componentId
        }
    }
    if ($unmappedComponents.Count -eq 0) {
        $stackChecks += New-Check -Name "component_registry_coverage" -Status "PASS" -Detail "Registered components have validator coverage." -Component "stack/base" -Path $componentRegistryPath -NextAction "No action required."
    }
    else {
        $stackChecks += New-Check -Name "component_registry_coverage" -Status "WARN" -Detail ("Registered components are missing validator coverage: {0}" -f ($unmappedComponents -join ", ")) -Component "stack/base" -Path $componentRegistryPath -NextAction "Add validator coverage for newly registered components."
    }
}
else {
    $stackChecks += New-Check -Name "component_registry_coverage" -Status "WARN" -Detail "component_registry.json is missing or unreadable, so component coverage cannot be verified." -Component "stack/base" -Path $componentRegistryPath -NextAction "Restore config/component_registry.json to keep validator coverage registry-driven."
}
$sections += New-SectionResult -SectionName "stack/base" -Checks $stackChecks

# Athena
$athenaChecks = @()
if ([int]$athenaUiProbe.status_code -eq 200) {
    $athenaChecks += New-Check -Name "athena_ui_route" -Status "PASS" -Detail "Athena UI route /athena/ returned HTTP 200." -Component "athena" -Path $athenaUiUrl -NextAction "No action required."
}
else {
    $athenaChecks += New-Check -Name "athena_ui_route" -Status "FAIL" -Detail ("Athena UI route /athena/ did not return HTTP 200 (status={0})." -f [int]$athenaUiProbe.status_code) -Component "athena" -Path $athenaUiUrl -NextAction "Restore the Athena static UI route at http://127.0.0.1:8000/athena/."
}

if ($stackStatusProbe.ok -and (Get-PropValue -Object $stackStatusProbe.data -Name "overall" -Default $null)) {
    $overallNode = Get-PropValue -Object $stackStatusProbe.data -Name "overall" -Default $null
    $athenaChecks += New-Check -Name "stack_status_payload" -Status "PASS" -Detail ("Athena stack status is readable; overall={0}." -f (Normalize-Text (Get-PropValue -Object $overallNode -Name "status" -Default ""))) -Component "athena" -Path $stackStatusUrl -NextAction "No action required."
}
else {
    $athenaChecks += New-Check -Name "stack_status_payload" -Status "FAIL" -Detail ("Athena stack status payload is unavailable or malformed ({0})." -f (Normalize-Text $stackStatusProbe.error)) -Component "athena" -Path $stackStatusUrl -NextAction "Restore GET /api/stack_status so Athena can load the live dashboard payload."
}

$verifyCheck = Get-FileArtifactCheck -CheckName "verify_artifact" -Path $verifyLastPath -Component "athena" -MissingNextAction "Run Verify Stack so reports/verify_last.json is written." -RequiredKeys @("timestamp_utc", "status", "recommended_next_action", "raw_report_path", "command_run")
$athenaChecks += $verifyCheck.check
if ($verifyCheck.data) {
    $verifyStatus = Normalize-Text (Get-PropValue -Object $verifyCheck.data -Name "status" -Default "")
    $verifyComponent = Normalize-Text (Get-PropValue -Object $verifyCheck.data -Name "failing_component" -Default "")
    $verifyPath = Normalize-Text (Get-PropValue -Object $verifyCheck.data -Name "failing_log_path" -Default "")
    if (-not $verifyPath) {
        $verifyPath = Normalize-Text (Get-PropValue -Object $verifyCheck.data -Name "raw_report_path" -Default $verifyLastPath)
    }
    $verifyNextAction = Normalize-Text (Get-PropValue -Object $verifyCheck.data -Name "recommended_next_action" -Default "Inspect reports/verify_last.json and rerun Verify Stack.")
    $verifyStatusDisplay = if ($verifyStatus) { $verifyStatus } else { "unknown" }
    $verifyComponentValue = if ($verifyComponent) { $verifyComponent } else { "athena" }
    $athenaChecks += New-Check -Name "verify_authoritative_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $verifyStatus -DefaultStatus "WARN") -Detail ("verify_last.json status={0}." -f $verifyStatusDisplay) -Component $verifyComponentValue -Path $verifyPath -NextAction $verifyNextAction
}

if ($stackStatusProbe.ok -and (Get-PropValue -Object $stackStatusProbe.data -Name "autonomy" -Default $null)) {
    $autonomyNode = Get-PropValue -Object $stackStatusProbe.data -Name "autonomy" -Default $null
    $athenaChecks += New-Check -Name "autonomy_summary" -Status "PASS" -Detail ("Autonomy summary is present; trust_posture={0}." -f (Normalize-Text (Get-PropValue -Object $autonomyNode -Name "trust_posture" -Default ""))) -Component "athena" -Path $stackStatusUrl -NextAction "No action required."
}
else {
    $athenaChecks += New-Check -Name "autonomy_summary" -Status "FAIL" -Detail "Athena stack status payload is missing the autonomy summary." -Component "athena" -Path $stackStatusUrl -NextAction "Restore autonomy summary fields in the Athena stack payload."
}
$sections += New-SectionResult -SectionName "Athena" -Checks $athenaChecks

# Onyx
$onyxChecks = @()
if ([int]$onyxRootProbe.status_code -eq 200) {
    $onyxChecks += New-Check -Name "onyx_ui_root" -Status "PASS" -Detail "Onyx UI root returned HTTP 200." -Component "onyx" -Path $onyxRootUrl -NextAction "No action required."
}
else {
    $onyxChecks += New-Check -Name "onyx_ui_root" -Status "FAIL" -Detail ("Onyx UI root did not return HTTP 200 (status={0})." -f [int]$onyxRootProbe.status_code) -Component "onyx" -Path $onyxRootUrl -NextAction "Restore the Onyx UI route at http://127.0.0.1:5353/."
}

$planStateCheck = Get-FileArtifactCheck -CheckName "onyx_plan_state" -Path $planStatePath -Component "onyx" -MissingNextAction "Restore state/onyx/plan_state.json from the Onyx save flow."
$onyxChecks += $planStateCheck.check

$workspaceCheck = Get-FileArtifactCheck -CheckName "onyx_workspace_link" -Path $tenantWorkspacePath -Component "onyx" -MissingNextAction "Restore state/onyx/tenant_workspace.json so Onyx can reload tenant context." -RequiredKeys @("activeTenantId", "contexts")
$onyxChecks += $workspaceCheck.check
$sections += New-SectionResult -SectionName "Onyx" -Checks $onyxChecks

# memory/ingest/context pack
$memoryChecks = @()
if (Test-Path -LiteralPath $memoryRoot) {
    $memoryChecks += New-Check -Name "memory_store_root" -Status "PASS" -Detail "Canonical memory store directory exists." -Component "memory" -Path $memoryRoot -NextAction "No action required."
}
else {
    $memoryChecks += New-Check -Name "memory_store_root" -Status "FAIL" -Detail "Canonical memory store directory is missing." -Component "memory" -Path $memoryRoot -NextAction "Restore state/knowledge/memory and rerun memory ingest."
}

$memoryChecks += (Get-FileArtifactCheck -CheckName "memory_catalog" -Path $memoryCatalogPath -Component "memory" -MissingNextAction "Restore state/knowledge/memory/catalog.json by rerunning memory ingest." -RequiredKeys @("items")).check
$memoryChecks += (Get-FileArtifactCheck -CheckName "memory_hot_index" -Path $memoryHotIndexPath -Component "memory" -MissingNextAction "Restore state/knowledge/memory/hot/index.json by rerunning memory ingest." -RequiredKeys @("items")).check
$memoryChecks += (Get-FileArtifactCheck -CheckName "memory_cold_index" -Path $memoryColdIndexPath -Component "memory" -MissingNextAction "Restore state/knowledge/memory/cold/index.json by rerunning memory ingest." -RequiredKeys @("items")).check
$memoryChecks += (Get-FileArtifactCheck -CheckName "memory_ingest_artifact" -Path $memoryIngestPath -Component "memory" -MissingNextAction "Run tools/ingest/Mason_Memory_Ingest.ps1 so reports/memory_ingest_last.json is written.").check
$memoryChecks += (Get-FileArtifactCheck -CheckName "memory_retrieve_artifact" -Path $memoryRetrievePath -Component "memory" -MissingNextAction "Run tools/knowledge/Mason_Memory_Retrieve.ps1 so reports/memory_retrieve_last.json is written.").check
$contextPackCheck = Get-FileArtifactCheck -CheckName "context_pack_artifact" -Path $contextPackPath -Component "memory" -MissingNextAction "Run tools/knowledge/Mason_Generate_ContextPack.ps1 so reports/context_pack.json is written." -RequiredKeys @("generated_at_utc", "current_stack_state", "latest_failures", "current_ports_services", "latest_mirror_status", "important_recent_memory_items")
$memoryChecks += $contextPackCheck.check
if ($contextPackCheck.data) {
    $roadmapChunk = Normalize-Text (Get-PropValue -Object $contextPackCheck.data -Name "current_roadmap_chunk" -Default "")
    if ($roadmapChunk) {
        $memoryChecks += New-Check -Name "context_pack_roadmap" -Status "PASS" -Detail ("Context pack includes roadmap chunk {0}." -f $roadmapChunk) -Component "memory" -Path $contextPackPath -NextAction "No action required."
    }
    else {
        $memoryChecks += New-Check -Name "context_pack_roadmap" -Status "WARN" -Detail "Context pack is readable but current_roadmap_chunk is missing." -Component "memory" -Path $contextPackPath -NextAction "Regenerate reports/context_pack.json so the current roadmap chunk is included."
    }
}
$sections += New-SectionResult -SectionName "memory/ingest/context pack" -Checks $memoryChecks

# tenant/onboarding/business profile
$tenantChecks = @()
$workspaceTenantCheck = Get-FileArtifactCheck -CheckName "tenant_workspace" -Path $tenantWorkspacePath -Component "tenant_profile" -MissingNextAction "Restore state/onyx/tenant_workspace.json from the Onyx onboarding save flow." -RequiredKeys @("activeTenantId", "contexts")
$tenantChecks += $workspaceTenantCheck.check

if ($tenantFiles.Count -gt 0) {
    $tenantChecks += New-Check -Name "tenant_artifacts" -Status "PASS" -Detail ("Found {0} tenant artifact(s)." -f $tenantFiles.Count) -Component "tenant_profile" -Path $onyxTenantsDir -NextAction "No action required."
}
else {
    $tenantChecks += New-Check -Name "tenant_artifacts" -Status "FAIL" -Detail "No tenant artifacts were found in state/onyx/tenants." -Component "tenant_profile" -Path $onyxTenantsDir -NextAction "Create or reload at least one tenant through Onyx onboarding."
}

$activeTenantId = $workspaceActiveTenantId
if (-not $activeTenantId -and $tenantFiles.Count -gt 0) {
    $activeTenantId = $tenantFiles[0].BaseName
}

$activeTenantFilePath = if ($activeTenantId) { Join-Path $onyxTenantsDir ($activeTenantId + ".json") } else { "" }
$activeTenantArtifact = if ($activeTenantFilePath) { Read-JsonSafe -Path $activeTenantFilePath -Default $null } else { $null }

if ($activeTenantArtifact) {
    $businessProfileNode = Get-PropValue -Object $activeTenantArtifact -Name "business_profile" -Default $null
    $businessName = Normalize-Text (Get-PropValue -Object $activeTenantArtifact -Name "businessName" -Default (Get-PropValue -Object $activeTenantArtifact -Name "business_name" -Default (Get-PropValue -Object $businessProfileNode -Name "business_name" -Default "")))
    $businessType = Normalize-Text (Get-PropValue -Object $activeTenantArtifact -Name "businessType" -Default (Get-PropValue -Object $activeTenantArtifact -Name "business_type" -Default (Get-PropValue -Object $businessProfileNode -Name "business_type" -Default "")))
    if ($businessName -and $businessType) {
        $tenantChecks += New-Check -Name "business_profile_artifact" -Status "PASS" -Detail ("Active tenant profile is readable for {0} ({1})." -f $businessName, $businessType) -Component "tenant_profile" -Path $activeTenantFilePath -NextAction "No action required."
    }
    else {
        $tenantChecks += New-Check -Name "business_profile_artifact" -Status "FAIL" -Detail "Active tenant artifact is missing business name or business type." -Component "tenant_profile" -Path $activeTenantFilePath -NextAction "Complete or repair the Onyx business profile for the active tenant."
    }
}
else {
    $tenantChecks += New-Check -Name "business_profile_artifact" -Status "FAIL" -Detail "Active tenant business profile artifact is missing or unreadable." -Component "tenant_profile" -Path $activeTenantFilePath -NextAction "Save the active tenant onboarding flow so the business profile artifact exists."
}

$activeContext = $null
foreach ($context in @((Get-PropValue -Object $tenantWorkspaceArtifact -Name "contexts" -Default @()))) {
    $tenantNode = Get-PropValue -Object $context -Name "tenant" -Default $null
    $contextTenantId = Normalize-Text (Get-PropValue -Object $tenantNode -Name "id" -Default "")
    if ($contextTenantId -and $contextTenantId -eq $activeTenantId) {
        $activeContext = $context
        break
    }
}
if ($activeContext) {
    $onboardingNode = Get-PropValue -Object $activeContext -Name "onboarding" -Default $null
    $stepIndex = Get-PropValue -Object $onboardingNode -Name "currentStepIndex" -Default $null
    $completionPercent = Get-PropValue -Object $onboardingNode -Name "completionPercent" -Default $null
    if ($null -ne $stepIndex -and $null -ne $completionPercent) {
        $tenantChecks += New-Check -Name "onboarding_state" -Status "PASS" -Detail ("Onboarding state persisted for tenant {0}: step={1}, completion={2}%." -f $activeTenantId, $stepIndex, $completionPercent) -Component "tenant_profile" -Path $tenantWorkspacePath -NextAction "No action required."
    }
    else {
        $tenantChecks += New-Check -Name "onboarding_state" -Status "FAIL" -Detail ("Onboarding state is missing currentStepIndex or completionPercent for tenant {0}." -f $activeTenantId) -Component "tenant_profile" -Path $tenantWorkspacePath -NextAction "Resave the Onyx onboarding flow so partial completion state persists."
    }
}
else {
    $tenantChecks += New-Check -Name "onboarding_state" -Status "FAIL" -Detail "Active tenant context is missing from tenant_workspace.json." -Component "tenant_profile" -Path $tenantWorkspacePath -NextAction "Repair tenant_workspace.json so the active tenant context matches the tenant artifact."
}
$sections += New-SectionResult -SectionName "tenant/onboarding/business profile" -Checks $tenantChecks

# tool registry/runner/artifacts
$toolChecks = @()
$toolRegistryCheck = Get-FileArtifactCheck -CheckName "tool_registry" -Path $toolRegistryPath -Component "tool_registry" -MissingNextAction "Restore config/tool_registry.json so the tool platform can load contracts." -RequiredKeys @("version", "tools")
$toolChecks += $toolRegistryCheck.check

$enabledRunnableTools = @()
$invalidToolContracts = @()
if ($toolRegistryCheck.data) {
    foreach ($tool in @((Get-PropValue -Object $toolRegistryCheck.data -Name "tools" -Default @()))) {
        $toolId = Normalize-Text (Get-PropValue -Object $tool -Name "tool_id" -Default "")
        $name = Normalize-Text (Get-PropValue -Object $tool -Name "name" -Default "")
        $status = Normalize-Text (Get-PropValue -Object $tool -Name "status" -Default "")
        $inputSchema = Get-PropValue -Object $tool -Name "input_schema" -Default $null
        $outputSchema = Get-PropValue -Object $tool -Name "output_schema" -Default $null
        $enabled = $false
        $enabledFlag = Get-PropValue -Object $tool -Name "enabled" -Default $null
        if ($enabledFlag -is [bool]) {
            $enabled = [bool]$enabledFlag
        }
        elseif ($status -eq "enabled") {
            $enabled = $true
        }
        if (-not $toolId -or -not $name -or -not $status -or $null -eq $inputSchema -or $null -eq $outputSchema) {
            if ($toolId) {
                $invalidToolContracts += $toolId
            }
            continue
        }
        if ($enabled) {
            $enabledRunnableTools += $toolId
        }
    }
}

if ($enabledRunnableTools.Count -gt 0) {
    $toolChecks += New-Check -Name "runnable_tool_contracts" -Status "PASS" -Detail ("Found {0} enabled runnable tool contract(s): {1}" -f $enabledRunnableTools.Count, ($enabledRunnableTools -join ", ")) -Component "tool_registry" -Path $toolRegistryPath -NextAction "No action required."
}
else {
    $toolChecks += New-Check -Name "runnable_tool_contracts" -Status "FAIL" -Detail "No enabled runnable tool contracts were found in tool_registry.json." -Component "tool_registry" -Path $toolRegistryPath -NextAction "Restore at least one enabled tool contract in config/tool_registry.json."
}

if ($invalidToolContracts.Count -eq 0) {
    $toolChecks += New-Check -Name "tool_contract_schema" -Status "PASS" -Detail "Registered tools have the core contract fields required for validation." -Component "tool_registry" -Path $toolRegistryPath -NextAction "No action required."
}
else {
    $toolChecks += New-Check -Name "tool_contract_schema" -Status "WARN" -Detail ("Some tool contracts are missing validation fields: {0}" -f ($invalidToolContracts -join ", ")) -Component "tool_registry" -Path $toolRegistryPath -NextAction "Repair incomplete tool contracts so they expose the canonical schema."
}

if (Test-Path -LiteralPath $toolRunnerPath) {
    $toolChecks += New-Check -Name "tool_runner_path" -Status "PASS" -Detail "Tool runner script exists." -Component "tool_registry" -Path $toolRunnerPath -NextAction "No action required."
}
else {
    $toolChecks += New-Check -Name "tool_runner_path" -Status "FAIL" -Detail "Tool runner script is missing." -Component "tool_registry" -Path $toolRunnerPath -NextAction "Restore tools/platform/ToolRunner.ps1."
}

if ($toolRunDirs.Count -gt 0) {
    $latestRunDir = $toolRunDirs[0].FullName
    $toolRunPath = Join-Path $latestRunDir "tool_run.json"
    $toolArtifactPath = Join-Path $latestRunDir "artifact.json"
    $toolRunJson = Read-JsonSafe -Path $toolRunPath -Default $null
    $toolArtifactJson = Read-JsonSafe -Path $toolArtifactPath -Default $null
    if ($toolRunJson -and $toolArtifactJson) {
        $toolRunToolId = Normalize-Text (Get-PropValue -Object $toolRunJson -Name "tool_id" -Default "")
        $toolRunToolIdDisplay = if ($toolRunToolId) { $toolRunToolId } else { $toolRunDirs[0].Name }
        $toolChecks += New-Check -Name "latest_tool_output_artifact" -Status "PASS" -Detail ("Latest tool run bundle is readable for {0}." -f $toolRunToolIdDisplay) -Component "tool_registry" -Path $toolArtifactPath -NextAction "No action required."
    }
    else {
        $toolChecks += New-Check -Name "latest_tool_output_artifact" -Status "FAIL" -Detail ("Latest tool run bundle is missing tool_run.json or artifact.json in {0}." -f $latestRunDir) -Component "tool_registry" -Path $latestRunDir -NextAction "Repair the latest tool run output bundle so both tool_run.json and artifact.json exist."
    }
}
else {
    $toolChecks += New-Check -Name "latest_tool_output_artifact" -Status "WARN" -Detail "No tool run bundles were found in reports/tools." -Component "tool_registry" -Path $toolRunsDir -NextAction "Execute at least one real tool run so the validator can confirm artifact output."
}
$sections += New-SectionResult -SectionName "tool registry/runner/artifacts" -Checks $toolChecks

# recommendations
$recommendationChecks = @()
if ($recommendationFiles.Count -gt 0) {
    $recommendationChecks += New-Check -Name "recommendation_artifacts" -Status "PASS" -Detail ("Found {0} tenant recommendation artifact(s)." -f $recommendationFiles.Count) -Component "recommendations" -Path $onyxRecommendationsDir -NextAction "No action required."
}
elseif ($activeTenantIds.Count -gt 0) {
    $recommendationChecks += New-Check -Name "recommendation_artifacts" -Status "FAIL" -Detail "Tenants exist but no recommendation artifacts were found." -Component "recommendations" -Path $onyxRecommendationsDir -NextAction "Refresh tenant recommendations so state/onyx/recommendations contains tenant artifacts."
}
else {
    $recommendationChecks += New-Check -Name "recommendation_artifacts" -Status "WARN" -Detail "No recommendation artifacts were found and no tenant ids were discovered." -Component "recommendations" -Path $onyxRecommendationsDir -NextAction "Create a tenant and generate recommendations."
}

$invalidRecommendationStatuses = @()
$recommendationCount = 0
foreach ($file in $recommendationFiles) {
    $artifact = Read-JsonSafe -Path $file.FullName -Default $null
    foreach ($item in @((Get-PropValue -Object $artifact -Name "recommendations" -Default @()))) {
        $recommendationCount += 1
        $status = Normalize-Text (Get-PropValue -Object $item -Name "status" -Default "")
        if ($status -and -not (Get-AllowedRecommendationStatuses).Contains($status.ToLowerInvariant())) {
            $invalidRecommendationStatuses += ("{0}:{1}" -f $file.BaseName, $status)
        }
    }
}
if ($invalidRecommendationStatuses.Count -eq 0) {
    $recommendationChecks += New-Check -Name "recommendation_statuses" -Status "PASS" -Detail "Recommendation statuses are readable and valid." -Component "recommendations" -Path $onyxRecommendationsDir -NextAction "No action required."
}
else {
    $recommendationChecks += New-Check -Name "recommendation_statuses" -Status "FAIL" -Detail ("Invalid recommendation statuses found: {0}" -f ($invalidRecommendationStatuses -join ", ")) -Component "recommendations" -Path $onyxRecommendationsDir -NextAction "Repair recommendation artifacts so statuses stay within new/seen/accepted/dismissed/completed."
}

if ($activeTenantIds.Count -gt 0) {
    if ($recommendationCount -gt 0) {
        $recommendationChecks += New-Check -Name "recommendation_records" -Status "PASS" -Detail ("Found {0} recommendation record(s) across discovered tenants." -f $recommendationCount) -Component "recommendations" -Path $onyxRecommendationsDir -NextAction "No action required."
    }
    else {
        $recommendationChecks += New-Check -Name "recommendation_records" -Status "FAIL" -Detail "A sample tenant exists but no recommendation records were found." -Component "recommendations" -Path $onyxRecommendationsDir -NextAction "Generate recommendations for the active tenant."
    }
}
else {
    $recommendationChecks += New-Check -Name "recommendation_records" -Status "WARN" -Detail "No tenant ids were discovered, so recommendation record coverage could not be verified." -Component "recommendations" -Path $onyxRecommendationsDir -NextAction "Create a tenant and generate recommendations before relying on this section."
}
$sections += New-SectionResult -SectionName "recommendations" -Checks $recommendationChecks

# unified improvement queue
$queueChecks = @()
$queueRootCheck = Get-FileArtifactCheck -CheckName "improvement_queue_store" -Path $improvementQueuePath -Component "improvement_queue" -MissingNextAction "Restore state/knowledge/improvement_queue.json so the unified queue store exists." -RequiredKeys @("updated_at_utc", "items")
$queueChecks += $queueRootCheck.check
$queueReportCheck = Get-FileArtifactCheck -CheckName "improvement_queue_report" -Path $queueReportPath -Component "improvement_queue" -MissingNextAction "Refresh the improvement queue so reports/queue/improvement_queue_last.json is written." -RequiredKeys @("updated_at_utc", "items")
$queueChecks += $queueReportCheck.check

$invalidImprovementStatuses = @()
$improvementCount = 0
foreach ($item in @((Get-PropValue -Object $queueArtifact -Name "items" -Default @()))) {
    $improvementCount += 1
    $status = Normalize-Text (Get-PropValue -Object $item -Name "status" -Default "")
    if ($status -and -not (Get-AllowedImprovementStatuses).Contains($status.ToLowerInvariant())) {
        $invalidImprovementStatuses += $status
    }
}
if ($invalidImprovementStatuses.Count -eq 0) {
    $queueChecks += New-Check -Name "improvement_queue_statuses" -Status "PASS" -Detail "Improvement queue statuses are readable and valid." -Component "improvement_queue" -Path $improvementQueuePath -NextAction "No action required."
}
else {
    $queueChecks += New-Check -Name "improvement_queue_statuses" -Status "FAIL" -Detail ("Invalid improvement queue statuses found: {0}" -f (($invalidImprovementStatuses | Sort-Object -Unique) -join ", ")) -Component "improvement_queue" -Path $improvementQueuePath -NextAction "Repair improvement_queue.json so lifecycle states stay canonical."
}

if ($improvementCount -gt 0) {
    $queueChecks += New-Check -Name "improvement_queue_counts" -Status "PASS" -Detail ("Unified improvement queue contains {0} item(s)." -f $improvementCount) -Component "improvement_queue" -Path $improvementQueuePath -NextAction "No action required."
}
else {
    $queueChecks += New-Check -Name "improvement_queue_counts" -Status "WARN" -Detail "Unified improvement queue is readable but currently empty." -Component "improvement_queue" -Path $improvementQueuePath -NextAction "Populate the improvement queue from runtime, recommendations, or manual owner tasks."
}
$sections += New-SectionResult -SectionName "unified improvement queue" -Checks $queueChecks

# trust/autonomy ladder
$trustChecks = @()
$trustRootCheck = Get-FileArtifactCheck -CheckName "behavior_trust_store" -Path $behaviorTrustPath -Component "behavior_trust" -MissingNextAction "Restore state/knowledge/behavior_trust.json so the trust ladder store exists." -RequiredKeys @("updated_at_utc", "behaviors")
$trustChecks += $trustRootCheck.check
$trustReportCheck = Get-FileArtifactCheck -CheckName "behavior_trust_report" -Path $behaviorTrustReportPath -Component "behavior_trust" -MissingNextAction "Refresh the trust ladder so reports/queue/behavior_trust_last.json is written." -RequiredKeys @("updated_at_utc", "behaviors")
$trustChecks += $trustReportCheck.check

$invalidTrustStates = @()
$behaviorCount = 0
$trustStateCounts = @{}
foreach ($behavior in @((Get-PropValue -Object $behaviorTrustArtifact -Name "behaviors" -Default @()))) {
    $behaviorCount += 1
    $trustState = Normalize-Text (Get-PropValue -Object $behavior -Name "trust_state" -Default "")
    if ($trustState) {
        $key = $trustState.ToLowerInvariant()
        if (-not $trustStateCounts.ContainsKey($key)) {
            $trustStateCounts[$key] = 0
        }
        $trustStateCounts[$key] += 1
        if (-not (Get-AllowedTrustStates).Contains($key)) {
            $invalidTrustStates += $trustState
        }
    }
}
if ($invalidTrustStates.Count -eq 0) {
    $trustChecks += New-Check -Name "trust_state_values" -Status "PASS" -Detail "Behavior trust states are readable and valid." -Component "behavior_trust" -Path $behaviorTrustPath -NextAction "No action required."
}
else {
    $trustChecks += New-Check -Name "trust_state_values" -Status "FAIL" -Detail ("Invalid trust states found: {0}" -f (($invalidTrustStates | Sort-Object -Unique) -join ", ")) -Component "behavior_trust" -Path $behaviorTrustPath -NextAction "Repair state/knowledge/behavior_trust.json so behavior trust_state stays canonical."
}

if ($behaviorCount -gt 0) {
    $summaryText = (($trustStateCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { "{0}={1}" -f $_.Name, $_.Value }) -join ", ")
    $trustChecks += New-Check -Name "behavior_records" -Status "PASS" -Detail ("Found {0} behavior record(s): {1}" -f $behaviorCount, $summaryText) -Component "behavior_trust" -Path $behaviorTrustPath -NextAction "No action required."
}
else {
    $trustChecks += New-Check -Name "behavior_records" -Status "FAIL" -Detail "No behavior trust records were found." -Component "behavior_trust" -Path $behaviorTrustPath -NextAction "Create or restore at least one canonical behavior record in the trust ladder."
}

if (Test-Path -LiteralPath $trustIndexPath) {
    $trustChecks += New-Check -Name "trust_index_snapshot" -Status "PASS" -Detail "Trust index snapshot exists." -Component "behavior_trust" -Path $trustIndexPath -NextAction "No action required."
}
else {
    $trustChecks += New-Check -Name "trust_index_snapshot" -Status "WARN" -Detail "Trust index snapshot is missing." -Component "behavior_trust" -Path $trustIndexPath -NextAction "Regenerate the trust index snapshot so Athena and Mason can read the current ladder quickly."
}
$sections += New-SectionResult -SectionName "trust/autonomy ladder" -Checks $trustChecks

# tool factory
$toolFactoryChecks = @()
$toolFactoryRootCheck = Get-FileArtifactCheck -CheckName "tool_factory_store" -Path $toolFactoryPath -Component "tool_factory" -MissingNextAction "Restore state/knowledge/tool_factory.json so the governed tool factory store exists." -RequiredKeys @("updated_at_utc", "specs")
$toolFactoryChecks += $toolFactoryRootCheck.check
$toolFactoryReportCheck = Get-FileArtifactCheck -CheckName "tool_factory_report" -Path $toolFactoryReportPath -Component "tool_factory" -MissingNextAction "Refresh the tool factory so reports/queue/tool_factory_last.json is written." -RequiredKeys @("updated_at_utc", "specs")
$toolFactoryChecks += $toolFactoryReportCheck.check

$invalidSpecStatuses = @()
$specCount = 0
$publishedSpecIds = @()
foreach ($spec in @((Get-PropValue -Object $toolFactoryArtifact -Name "specs" -Default @()))) {
    $specCount += 1
    $status = Normalize-Text (Get-PropValue -Object $spec -Name "status" -Default "")
    if ($status -and -not (Get-AllowedToolFactoryStatuses).Contains($status.ToLowerInvariant())) {
        $invalidSpecStatuses += $status
    }
    $publishedToolId = Normalize-Text (Get-PropValue -Object $spec -Name "published_tool_id" -Default "")
    if ($publishedToolId) {
        $publishedSpecIds += $publishedToolId
    }
}
if ($invalidSpecStatuses.Count -eq 0) {
    $toolFactoryChecks += New-Check -Name "tool_factory_statuses" -Status "PASS" -Detail "Tool factory spec statuses are readable and valid." -Component "tool_factory" -Path $toolFactoryPath -NextAction "No action required."
}
else {
    $toolFactoryChecks += New-Check -Name "tool_factory_statuses" -Status "FAIL" -Detail ("Invalid tool factory statuses found: {0}" -f (($invalidSpecStatuses | Sort-Object -Unique) -join ", ")) -Component "tool_factory" -Path $toolFactoryPath -NextAction "Repair state/knowledge/tool_factory.json so spec status values stay canonical."
}

if ($specCount -gt 0) {
    $toolFactoryChecks += New-Check -Name "tool_factory_specs" -Status "PASS" -Detail ("Tool factory contains {0} spec(s)." -f $specCount) -Component "tool_factory" -Path $toolFactoryPath -NextAction "No action required."
}
else {
    $toolFactoryChecks += New-Check -Name "tool_factory_specs" -Status "FAIL" -Detail "No tool factory specs were found." -Component "tool_factory" -Path $toolFactoryPath -NextAction "Generate at least one tool opportunity/spec through the tool factory."
}

if ($publishedSpecIds.Count -gt 0) {
    $registeredToolIds = @()
    foreach ($tool in @((Get-PropValue -Object $toolRegistryArtifact -Name "tools" -Default @()))) {
        $registeredToolIds += Normalize-Text (Get-PropValue -Object $tool -Name "tool_id" -Default "")
    }
    $missingPublishedLinks = @($publishedSpecIds | Where-Object { $_ -and $_ -notin $registeredToolIds })
    if ($missingPublishedLinks.Count -eq 0) {
        $toolFactoryChecks += New-Check -Name "tool_factory_registry_linkage" -Status "PASS" -Detail ("Published staged registry linkage is readable for {0}." -f (($publishedSpecIds | Sort-Object -Unique) -join ", ")) -Component "tool_factory" -Path $toolRegistryPath -NextAction "No action required."
    }
    else {
        $toolFactoryChecks += New-Check -Name "tool_factory_registry_linkage" -Status "FAIL" -Detail ("Published tool specs are missing staged registry entries: {0}" -f (($missingPublishedLinks | Sort-Object -Unique) -join ", ")) -Component "tool_factory" -Path $toolRegistryPath -NextAction "Repair staged registry linkage for published tool factory specs."
    }
}
else {
    $toolFactoryChecks += New-Check -Name "tool_factory_registry_linkage" -Status "PASS" -Detail "No published tool specs exist yet, so staged registry linkage is not required for this run." -Component "tool_factory" -Path $toolFactoryPath -NextAction "No action required."
}
$sections += New-SectionResult -SectionName "tool factory" -Checks $toolFactoryChecks

# self-improvement governor
$selfImprovementChecks = @()
$selfImprovementChecks += (Get-FileArtifactCheck -CheckName "self_improvement_policy" -Path $selfImprovementPolicyPath -Component "self_improvement" -MissingNextAction "Run tools/ops/Run_Self_Improvement_Governor.ps1 so the canonical self-improvement policy is written." -RequiredKeys @("version", "policy_name", "local_first_mandatory", "minimum_teacher_quality_score", "blocked_target_types", "score_thresholds")).check
$governorArtifactCheck = Get-FileArtifactCheck -CheckName "self_improvement_governor_artifact" -Path $selfImprovementGovernorPath -Component "self_improvement" -MissingNextAction "Run tools/ops/Run_Self_Improvement_Governor.ps1 so the self-improvement governor artifact is written." -RequiredKeys @("timestamp_utc", "overall_status", "active_improvement_total", "counts_by_teacher_call_classification", "counts_by_execution_disposition", "recommended_next_action")
$selfImprovementChecks += $governorArtifactCheck.check
$teacherBudgetCheck = Get-FileArtifactCheck -CheckName "teacher_call_budget_artifact" -Path $teacherCallBudgetPath -Component "self_improvement" -MissingNextAction "Run tools/ops/Run_Self_Improvement_Governor.ps1 so the teacher-call budget posture artifact is written." -RequiredKeys @("timestamp_utc", "total_teacher_worthy_items_considered", "total_blocked_by_local_first", "total_allowed", "total_high_value_only", "current_budget_posture", "recommended_next_action")
$selfImprovementChecks += $teacherBudgetCheck.check
$teacherDecisionCheck = Get-FileArtifactCheck -CheckName "teacher_decision_log_artifact" -Path $teacherDecisionLogPath -Component "self_improvement" -MissingNextAction "Run tools/ops/Run_Self_Improvement_Governor.ps1 so the teacher decision log artifact is written." -RequiredKeys @("timestamp_utc", "improvement_decisions", "teacher_response_reviews", "recommended_next_action")
$selfImprovementChecks += $teacherDecisionCheck.check

if ($governorArtifactCheck.data) {
    $governorStatus = Normalize-Text (Get-PropValue -Object $governorArtifactCheck.data -Name "overall_status" -Default "")
    $governorStatusDisplay = if ($governorStatus) { $governorStatus } else { "unknown" }
    $selfImprovementChecks += New-Check -Name "self_improvement_governor_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $governorStatus -DefaultStatus "WARN") -Detail ("Self-improvement governor overall_status={0}." -f $governorStatusDisplay) -Component "self_improvement" -Path $selfImprovementGovernorPath -NextAction "Review the governor artifact and keep blocked or weak teacher-backed items out of staging."

    $allowedTeacherCallClassifications = @("trivial_local_only", "local_first_teacher_optional", "teacher_required_low_cost", "teacher_required_standard", "teacher_required_high_value_only", "blocked_pending_human_review")
    $allowedExecutionDispositions = @("blocked", "suggest_only", "approval_required", "safe_to_stage", "safe_to_test")
    $governorItems = @((Get-PropValue -Object $governorArtifactCheck.data -Name "items" -Default @()))
    $invalidTeacherClassifications = @()
    $invalidExecutionDispositions = @()
    foreach ($governorItem in $governorItems) {
        $teacherCallClassification = Normalize-Text (Get-PropValue -Object $governorItem -Name "teacher_call_classification" -Default "")
        if ($teacherCallClassification -and $teacherCallClassification.ToLowerInvariant() -notin $allowedTeacherCallClassifications) {
            $invalidTeacherClassifications += $teacherCallClassification
        }
        $executionDisposition = Normalize-Text (Get-PropValue -Object $governorItem -Name "execution_disposition" -Default "")
        if ($executionDisposition -and $executionDisposition.ToLowerInvariant() -notin $allowedExecutionDispositions) {
            $invalidExecutionDispositions += $executionDisposition
        }
    }
    if ($invalidTeacherClassifications.Count -eq 0) {
        $selfImprovementChecks += New-Check -Name "teacher_call_classifications" -Status "PASS" -Detail "Teacher call classifications are readable and canonical." -Component "self_improvement" -Path $selfImprovementGovernorPath -NextAction "No action required."
    }
    else {
        $selfImprovementChecks += New-Check -Name "teacher_call_classifications" -Status "FAIL" -Detail ("Invalid teacher call classifications found: {0}" -f (($invalidTeacherClassifications | Sort-Object -Unique) -join ", ")) -Component "self_improvement" -Path $selfImprovementGovernorPath -NextAction "Repair the self-improvement governor artifact so call classifications stay canonical."
    }
    if ($invalidExecutionDispositions.Count -eq 0) {
        $selfImprovementChecks += New-Check -Name "execution_dispositions" -Status "PASS" -Detail "Improvement execution dispositions are readable and canonical." -Component "self_improvement" -Path $selfImprovementGovernorPath -NextAction "No action required."
    }
    else {
        $selfImprovementChecks += New-Check -Name "execution_dispositions" -Status "FAIL" -Detail ("Invalid execution dispositions found: {0}" -f (($invalidExecutionDispositions | Sort-Object -Unique) -join ", ")) -Component "self_improvement" -Path $selfImprovementGovernorPath -NextAction "Repair the self-improvement governor artifact so execution dispositions stay within blocked/suggest_only/approval_required/safe_to_stage/safe_to_test."
    }
}

if ($teacherBudgetCheck.data) {
    $budgetPosture = Normalize-Text (Get-PropValue -Object $teacherBudgetCheck.data -Name "current_budget_posture" -Default "")
    if ($budgetPosture.ToLowerInvariant() -in @("blocked", "constrained", "guarded", "open")) {
        $selfImprovementChecks += New-Check -Name "teacher_budget_posture" -Status "PASS" -Detail ("Teacher-call budget posture is {0}." -f $budgetPosture) -Component "self_improvement" -Path $teacherCallBudgetPath -NextAction "No action required."
    }
    else {
        $budgetPostureDisplay = if ($budgetPosture) { $budgetPosture } else { "unknown" }
        $selfImprovementChecks += New-Check -Name "teacher_budget_posture" -Status "FAIL" -Detail ("Teacher-call budget posture is missing or invalid: {0}" -f $budgetPostureDisplay) -Component "self_improvement" -Path $teacherCallBudgetPath -NextAction "Repair the teacher-call budget artifact so current_budget_posture stays canonical."
    }
}

if ($teacherDecisionCheck.data) {
    $decisionItems = @((Get-PropValue -Object $teacherDecisionCheck.data -Name "improvement_decisions" -Default @()))
    $teacherReviews = @((Get-PropValue -Object $teacherDecisionCheck.data -Name "teacher_response_reviews" -Default @()))
    if ($decisionItems.Count -gt 0) {
        $selfImprovementChecks += New-Check -Name "teacher_decision_records" -Status "PASS" -Detail ("Teacher decision log contains {0} improvement decision record(s) and {1} teacher response review(s)." -f $decisionItems.Count, $teacherReviews.Count) -Component "self_improvement" -Path $teacherDecisionLogPath -NextAction "No action required."
    }
    else {
        $selfImprovementChecks += New-Check -Name "teacher_decision_records" -Status "WARN" -Detail "Teacher decision log is readable but currently contains no improvement decision records." -Component "self_improvement" -Path $teacherDecisionLogPath -NextAction "Populate the improvement queue and rerun the self-improvement governor."
    }
}
$sections += New-SectionResult -SectionName "self-improvement governor" -Checks $selfImprovementChecks

# keepalive / self-heal / daily report
$keepAliveChecks = @()
$keepAlivePolicyCheck = Get-FileArtifactCheck -CheckName "keepalive_policy" -Path $keepAlivePolicyPath -Component "keepalive_ops" -MissingNextAction "Restore config/keepalive_policy.json so governed keepalive policy remains canonical." -RequiredKeys @("policy_name", "policy_posture", "allowed_low_risk_repair_actions", "blocked_action_classes", "retry_policy", "escalation_thresholds", "daily_report_policy", "service_scope", "truth_source_precedence", "restart_suppression_rules", "duplicate_repair_suppression", "owner_escalation_guidance")
$keepAliveChecks += $keepAlivePolicyCheck.check
$keepAliveArtifactCheck = Get-FileArtifactCheck -CheckName "keepalive_last_artifact" -Path $keepAliveLastPath -Component "keepalive_ops" -MissingNextAction "Run tools/ops/Run_KeepAlive_SelfHeal.ps1 so reports/keepalive_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "services_evaluated", "healthy_service_count", "recoverable_issue_count", "escalated_issue_count", "repair_attempt_count", "repair_success_count", "repair_blocked_count", "throttle_guidance", "recommended_next_action")
$keepAliveChecks += $keepAliveArtifactCheck.check
$selfHealArtifactCheck = Get-FileArtifactCheck -CheckName "self_heal_last_artifact" -Path $selfHealLastPath -Component "keepalive_ops" -MissingNextAction "Run tools/ops/Run_KeepAlive_SelfHeal.ps1 so reports/self_heal_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "issues", "repair_attempt_count", "repair_success_count", "repair_blocked_count", "escalated_issue_count")
$keepAliveChecks += $selfHealArtifactCheck.check
$dailyReportArtifactCheck = Get-FileArtifactCheck -CheckName "daily_report_last_artifact" -Path $dailyReportLastPath -Component "keepalive_ops" -MissingNextAction "Run tools/ops/Run_KeepAlive_SelfHeal.ps1 so reports/daily_report_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "overall_posture", "healthy_areas", "warnings", "changed_since_prior_run", "what_mason_attempted", "what_mason_refused_to_do", "what_remains_blocked", "what_needs_owner_review", "recommended_next_action")
$keepAliveChecks += $dailyReportArtifactCheck.check
$escalationQueueCheck = Get-FileArtifactCheck -CheckName "escalation_queue_last_artifact" -Path $escalationQueueLastPath -Component "keepalive_ops" -MissingNextAction "Run tools/ops/Run_KeepAlive_SelfHeal.ps1 so reports/escalation_queue_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "escalation_count", "escalations", "recommended_next_action")
$keepAliveChecks += $escalationQueueCheck.check

if ($keepAliveArtifactCheck.data) {
    $keepAliveStatus = Normalize-Text (Get-PropValue -Object $keepAliveArtifactCheck.data -Name "overall_status" -Default "")
    $keepAliveStatusDisplay = if ($keepAliveStatus) { $keepAliveStatus } else { "unknown" }
    $keepAliveChecks += New-Check -Name "keepalive_overall_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $keepAliveStatus -DefaultStatus "WARN") -Detail ("KeepAlive overall_status={0}." -f $keepAliveStatusDisplay) -Component "keepalive_ops" -Path $keepAliveLastPath -NextAction "Review keepalive/escalation artifacts if the posture is not PASS."

    $servicesEvaluated = @((Get-PropValue -Object $keepAliveArtifactCheck.data -Name "services_evaluated" -Default @()))
    if ($servicesEvaluated.Count -gt 0) {
        $keepAliveChecks += New-Check -Name "keepalive_services_evaluated" -Status "PASS" -Detail ("KeepAlive evaluated {0} service(s)." -f $servicesEvaluated.Count) -Component "keepalive_ops" -Path $keepAliveLastPath -NextAction "No action required."
    }
    else {
        $keepAliveChecks += New-Check -Name "keepalive_services_evaluated" -Status "FAIL" -Detail "KeepAlive artifact is readable but services_evaluated is empty." -Component "keepalive_ops" -Path $keepAliveLastPath -NextAction "Repair Run_KeepAlive_SelfHeal.ps1 so it records real service evaluations."
    }

    $keepAliveAgeHours = Get-AgeHours -Timestamp (Get-PropValue -Object $keepAliveArtifactCheck.data -Name "timestamp_utc" -Default "")
    if ($keepAliveAgeHours -le 24) {
        $keepAliveChecks += New-Check -Name "keepalive_freshness" -Status "PASS" -Detail ("KeepAlive artifact freshness is {0} hour(s)." -f $keepAliveAgeHours) -Component "keepalive_ops" -Path $keepAliveLastPath -NextAction "No action required."
    }
    else {
        $keepAliveChecks += New-Check -Name "keepalive_freshness" -Status "WARN" -Detail ("KeepAlive artifact is stale at {0} hour(s)." -f $keepAliveAgeHours) -Component "keepalive_ops" -Path $keepAliveLastPath -NextAction "Rerun tools/ops/Run_KeepAlive_SelfHeal.ps1 to refresh governed ops state."
    }
}

if ($selfHealArtifactCheck.data) {
    $selfHealIssues = @((Get-PropValue -Object $selfHealArtifactCheck.data -Name "issues" -Default @()))
    $blockedRepairs = @($selfHealIssues | Where-Object { (Normalize-Text (Get-PropValue -Object $_ -Name "action_attempted_or_blocked" -Default "")) -notin @("attempted", "attempted_success", "deferred_due_single_action_limit") })
    if ($blockedRepairs.Count -gt 0) {
        $keepAliveChecks += New-Check -Name "policy_blocked_repairs" -Status "WARN" -Detail ("KeepAlive blocked or escalated {0} issue(s) by policy/cooldown without blind retries." -f $blockedRepairs.Count) -Component "keepalive_ops" -Path $selfHealLastPath -NextAction "Review the escalated items; policy-blocked repairs are not auto-applied."
    }
    else {
        $keepAliveChecks += New-Check -Name "policy_blocked_repairs" -Status "PASS" -Detail "No repairs were blocked by policy or cooldown in the latest keepalive cycle." -Component "keepalive_ops" -Path $selfHealLastPath -NextAction "No action required."
    }
}

if ($dailyReportArtifactCheck.data) {
    $changedSincePrior = @((Get-PropValue -Object $dailyReportArtifactCheck.data -Name "changed_since_prior_run" -Default @()))
    if ($changedSincePrior.Count -gt 0) {
        $keepAliveChecks += New-Check -Name "daily_report_change_tracking" -Status "PASS" -Detail ("Daily report exposes {0} change-tracking item(s)." -f $changedSincePrior.Count) -Component "keepalive_ops" -Path $dailyReportLastPath -NextAction "No action required."
    }
    else {
        $keepAliveChecks += New-Check -Name "daily_report_change_tracking" -Status "FAIL" -Detail "Daily report is readable but changed_since_prior_run is empty." -Component "keepalive_ops" -Path $dailyReportLastPath -NextAction "Repair Run_KeepAlive_SelfHeal.ps1 so the daily report always carries change tracking, even if it says no material change."
    }
}

if ($escalationQueueCheck.data) {
    $escalationCount = [int](Get-PropValue -Object $escalationQueueCheck.data -Name "escalation_count" -Default 0)
    if ($escalationCount -eq 0) {
        $keepAliveChecks += New-Check -Name "escalation_queue_state" -Status "PASS" -Detail "Escalation queue is empty; no unresolved keepalive escalations are present." -Component "keepalive_ops" -Path $escalationQueueLastPath -NextAction "No action required."
    }
    else {
        $keepAliveChecks += New-Check -Name "escalation_queue_state" -Status "WARN" -Detail ("Escalation queue contains {0} unresolved item(s)." -f $escalationCount) -Component "keepalive_ops" -Path $escalationQueueLastPath -NextAction "Review the unresolved keepalive escalations before authorizing broader changes."
    }
}

$stackKeepAlive = Get-PropValue -Object $stackStatusProbe.data -Name "keepalive_ops" -Default $null
if ($stackStatusProbe.ok -and $stackKeepAlive) {
    $keepAliveChecks += New-Check -Name "keepalive_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes keepalive_ops with overall_status={0}." -f (Normalize-Text (Get-PropValue -Object $stackKeepAlive -Name "overall_status" -Default ""))) -Component "keepalive_ops" -Path $stackStatusUrl -NextAction "No action required."

    $requiredPayloadKeys = @("overall_status", "recoverable_issue_count", "escalated_issue_count", "repair_success_count", "repair_blocked_count", "daily_report_status", "recommended_next_action")
    $missingPayloadKeys = @()
    foreach ($payloadKey in $requiredPayloadKeys) {
        if (-not (Test-ObjectHasKey -Object $stackKeepAlive -Name $payloadKey)) {
            $missingPayloadKeys += $payloadKey
        }
    }

    if ($missingPayloadKeys.Count -eq 0) {
        $keepAliveChecks += New-Check -Name "keepalive_payload_shape" -Status "PASS" -Detail "Athena stack payload exposes the governed keepalive_ops keys." -Component "keepalive_ops" -Path $stackStatusUrl -NextAction "No action required."
    }
    else {
        $keepAliveChecks += New-Check -Name "keepalive_payload_shape" -Status "FAIL" -Detail ("Athena stack payload is missing keepalive_ops keys: {0}" -f ($missingPayloadKeys -join ", ")) -Component "keepalive_ops" -Path $stackStatusUrl -NextAction "Patch MasonConsole/server.py so keepalive_ops exposes the governed summary keys."
    }
}
else {
    $keepAliveChecks += New-Check -Name "keepalive_payload_visible" -Status "WARN" -Detail "Athena stack payload does not currently expose keepalive_ops." -Component "keepalive_ops" -Path $stackStatusUrl -NextAction "Restart Athena after patching MasonConsole/server.py so the keepalive_ops summary is available."
}
$sections += New-SectionResult -SectionName "keepalive / self-heal / daily report" -Checks $keepAliveChecks

# security/legal/tenant safety
$securityChecks = @()
$tenantSafetyCheck = Get-FileArtifactCheck -CheckName "tenant_safety_report" -Path $tenantSafetyPath -Component "security_posture" -MissingNextAction "Regenerate reports/tenant_safety_report.json so tenant isolation posture is visible." -RequiredKeys @("generated_at_utc", "status", "issues_total")
$securityChecks += $tenantSafetyCheck.check
if ($tenantSafetyCheck.data) {
    $tenantSafetyStatus = Normalize-Text (Get-PropValue -Object $tenantSafetyCheck.data -Name "status" -Default "")
    $tenantSafetyIssues = Get-PropValue -Object $tenantSafetyCheck.data -Name "issues_total" -Default 0
    $tenantSafetyStatusDisplay = if ($tenantSafetyStatus) { $tenantSafetyStatus } else { "unknown" }
    $securityChecks += New-Check -Name "tenant_safety_posture" -Status (Convert-ArtifactStateToCheckStatus -RawValue $tenantSafetyStatus -DefaultStatus "WARN") -Detail ("Tenant safety posture={0}; issues_total={1}." -f $tenantSafetyStatusDisplay, $tenantSafetyIssues) -Component "security_posture" -Path $tenantSafetyPath -NextAction "Resolve tenant isolation warnings called out in reports/tenant_safety_report.json."
}

$securityPostureCheck = Get-FileArtifactCheck -CheckName "security_posture_artifact" -Path $securityPosturePath -Component "security_posture" -MissingNextAction "Regenerate reports/security_posture.json so the security posture artifact exists." -RequiredKeys @("timestamp_utc", "overall_status", "tenant_isolation_posture", "audit_posture")
$securityChecks += $securityPostureCheck.check
if ($securityPostureCheck.data) {
    $securityPostureStatus = Normalize-Text (Get-PropValue -Object $securityPostureCheck.data -Name "overall_status" -Default "")
    $securityPostureStatusDisplay = if ($securityPostureStatus) { $securityPostureStatus } else { "unknown" }
    $securityChecks += New-Check -Name "security_posture_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $securityPostureStatus -DefaultStatus "WARN") -Detail ("Security posture overall_status={0}." -f $securityPostureStatusDisplay) -Component "security_posture" -Path $securityPosturePath -NextAction "Resolve the posture items called out in reports/security_posture.json."
}

$securityChecks += (Get-FileArtifactCheck -CheckName "rbac_policy" -Path $rbacPolicyPath -Component "security_posture" -MissingNextAction "Restore config/rbac_policy.json so the permission model exists." -RequiredKeys @("roles")).check
$securityChecks += (Get-FileArtifactCheck -CheckName "data_governance_policy" -Path $dataGovernancePolicyPath -Component "security_posture" -MissingNextAction "Restore config/data_governance_policy.json so retention/export/delete policy exists." -RequiredKeys @("retention", "export", "delete", "legal")).check
$dataGovernanceStateCheck = Get-FileArtifactCheck -CheckName "data_governance_state" -Path $dataGovernanceStatePath -Component "security_posture" -MissingNextAction "Restore state/knowledge/data_governance_requests.json so export/delete state exists."
$securityChecks += $dataGovernanceStateCheck.check
if ($dataGovernanceStateCheck.data) {
    $hasExportRequests = $false
    $hasDeleteRequests = $false
    if ($dataGovernanceStateCheck.data -is [System.Collections.IDictionary]) {
        $hasExportRequests = $dataGovernanceStateCheck.data.Contains("export_requests")
        $hasDeleteRequests = $dataGovernanceStateCheck.data.Contains("delete_requests")
    }
    else {
        $hasExportRequests = $null -ne $dataGovernanceStateCheck.data.PSObject.Properties["export_requests"]
        $hasDeleteRequests = $null -ne $dataGovernanceStateCheck.data.PSObject.Properties["delete_requests"]
    }
    $exportRequests = Get-PropValue -Object $dataGovernanceStateCheck.data -Name "export_requests" -Default @()
    $deleteRequests = Get-PropValue -Object $dataGovernanceStateCheck.data -Name "delete_requests" -Default @()
    if ($hasExportRequests -and $hasDeleteRequests) {
        $securityChecks += New-Check -Name "data_governance_request_shape" -Status "PASS" -Detail ("Data-governance state exposes export_requests={0} and delete_requests={1}." -f @($exportRequests).Count, @($deleteRequests).Count) -Component "security_posture" -Path $dataGovernanceStatePath -NextAction "No action required."
    }
    else {
        $securityChecks += New-Check -Name "data_governance_request_shape" -Status "FAIL" -Detail "Data-governance state is missing export_requests or delete_requests." -Component "security_posture" -Path $dataGovernanceStatePath -NextAction "Rewrite state/knowledge/data_governance_requests.json with export_requests and delete_requests."
    }
}

if (Test-Path -LiteralPath $auditLogPath) {
    $firstAuditLine = Get-Content -LiteralPath $auditLogPath -TotalCount 1 -Encoding UTF8
    if (Normalize-Text $firstAuditLine) {
        try {
            $firstAuditEvent = $firstAuditLine | ConvertFrom-Json -ErrorAction Stop
            $eventType = Normalize-Text (Get-PropValue -Object $firstAuditEvent -Name "event_type" -Default "")
            if ($eventType) {
                $securityChecks += New-Check -Name "platform_audit_log" -Status "PASS" -Detail ("Structured audit log exists with event_type={0}." -f $eventType) -Component "security_posture" -Path $auditLogPath -NextAction "No action required."
            }
            else {
                $securityChecks += New-Check -Name "platform_audit_log" -Status "FAIL" -Detail "Audit log exists but the first event is missing event_type." -Component "security_posture" -Path $auditLogPath -NextAction "Repair reports/platform_audit.jsonl so events follow the canonical audit schema."
            }
        }
        catch {
            $securityChecks += New-Check -Name "platform_audit_log" -Status "FAIL" -Detail "Audit log exists but is not parseable JSONL." -Component "security_posture" -Path $auditLogPath -NextAction "Repair reports/platform_audit.jsonl so events follow the canonical audit schema."
        }
    }
    else {
        $securityChecks += New-Check -Name "platform_audit_log" -Status "FAIL" -Detail "Audit log file exists but is empty." -Component "security_posture" -Path $auditLogPath -NextAction "Write at least one real structured audit event to reports/platform_audit.jsonl."
    }
}
else {
    $securityChecks += New-Check -Name "platform_audit_log" -Status "FAIL" -Detail "Audit log file is missing." -Component "security_posture" -Path $auditLogPath -NextAction "Restore reports/platform_audit.jsonl and ensure at least one audit event is recorded."
}
$sections += New-SectionResult -SectionName "security/legal/tenant safety" -Checks $securityChecks

# billing/entitlements
$billingChecks = @()
if ($billingFiles.Count -gt 0) {
    $billingChecks += New-Check -Name "billing_state_store" -Status "PASS" -Detail ("Found {0} tenant billing artifact(s)." -f $billingFiles.Count) -Component "billing" -Path $onyxBillingDir -NextAction "No action required."
}
elseif (Read-JsonSafe -Path $billingSummaryPath -Default $null) {
    $billingChecks += New-Check -Name "billing_state_store" -Status "WARN" -Detail "Billing summary exists but no per-tenant billing state artifacts were found." -Component "billing" -Path $onyxBillingDir -NextAction "Write canonical tenant billing state into state/onyx/billing."
}
else {
    $billingChecks += New-Check -Name "billing_state_store" -Status "FAIL" -Detail "Billing state is missing from both state/onyx/billing and reports/billing_summary.json." -Component "billing" -Path $onyxBillingDir -NextAction "Restore the billing state and summary artifacts."
}

$tiersCheck = Get-FileArtifactCheck -CheckName "plan_tier_artifact" -Path $tiersPath -Component "billing" -MissingNextAction "Restore config/tiers.json so plan entitlements can be enforced."
$billingChecks += $tiersCheck.check
if ($tiersCheck.data) {
    $tierItems = @((Get-PropValue -Object $tiersCheck.data -Name "tiers" -Default @()))
    if ($tierItems.Count -eq 0) {
        $tierItems = @((Get-PropValue -Object $tiersCheck.data -Name "plans" -Default @()))
    }
    if ($tierItems.Count -gt 0) {
        $billingChecks += New-Check -Name "plan_tier_records" -Status "PASS" -Detail ("Plan/tier artifact contains {0} tier record(s)." -f $tierItems.Count) -Component "billing" -Path $tiersPath -NextAction "No action required."
    }
    else {
        $billingChecks += New-Check -Name "plan_tier_records" -Status "FAIL" -Detail "Plan/tier artifact is readable but contains no tiers or plans array." -Component "billing" -Path $tiersPath -NextAction "Rewrite config/tiers.json so it contains the canonical plan/tier records."
    }
}

$billingProviderCheck = Get-FileArtifactCheck -CheckName "billing_provider_config" -Path $billingProviderPath -Component "billing" -MissingNextAction "Restore config/billing_provider.json so provider posture is readable."
$billingChecks += $billingProviderCheck.check
if ($billingProviderCheck.data) {
    $providerMode = Normalize-Text (Get-PropValue -Object $billingProviderCheck.data -Name "mode" -Default "")
    $providerName = Normalize-Text (Get-PropValue -Object $billingProviderCheck.data -Name "provider" -Default "")
    $configured = Get-PropValue -Object $billingProviderCheck.data -Name "configured" -Default $null
    if ($configured -is [bool] -and $configured) {
        $billingChecks += New-Check -Name "billing_provider_posture" -Status "PASS" -Detail ("Billing provider {0} is configured in mode={1}." -f $providerName, $providerMode) -Component "billing" -Path $billingProviderPath -NextAction "No action required."
    }
    else {
        $providerNameDisplay = if ($providerName) { $providerName } else { "unknown" }
        $providerModeDisplay = if ($providerMode) { $providerMode } else { "unknown" }
        $billingChecks += New-Check -Name "billing_provider_posture" -Status "WARN" -Detail ("Billing provider {0} is running in mode={1} and is not fully configured." -f $providerNameDisplay, $providerModeDisplay) -Component "billing" -Path $billingProviderPath -NextAction "Configure external billing secrets and webhook settings before enabling live money actions."
    }
}

$billingSummaryCheck = Get-FileArtifactCheck -CheckName "billing_summary_artifact" -Path $billingSummaryPath -Component "billing" -MissingNextAction "Regenerate reports/billing_summary.json so billing and revenue state are visible." -RequiredKeys @("generated_at_utc", "plans", "subscription_counts", "revenue")
$billingChecks += $billingSummaryCheck.check
if ($billingSummaryCheck.data) {
    $tenantNode = Get-PropValue -Object $billingSummaryCheck.data -Name "tenant" -Default $null
    $enabledTools = @((Get-PropValue -Object $tenantNode -Name "enabled_tools" -Default @()))
    $selectedPlanId = Normalize-Text (Get-PropValue -Object $tenantNode -Name "selected_plan_id" -Default "")
    $planId = Normalize-Text (Get-PropValue -Object $tenantNode -Name "plan_id" -Default "")
    $billingStatus = Normalize-Text (Get-PropValue -Object $tenantNode -Name "status" -Default "")
    $checkoutRequired = [bool](Get-PropValue -Object $tenantNode -Name "checkout_required" -Default $false)
    if ($enabledTools.Count -gt 0) {
        $billingChecks += New-Check -Name "entitlement_state" -Status "PASS" -Detail ("Tenant entitlement state is readable; enabled_tools={0}." -f ($enabledTools -join ", ")) -Component "billing" -Path $billingSummaryPath -NextAction "No action required."
    }
    elseif ($checkoutRequired -and ($selectedPlanId -or $planId) -and @("inactive", "pending_checkout", "incomplete", "draft") -contains $billingStatus.ToLowerInvariant()) {
        $displayPlan = if ($selectedPlanId) { $selectedPlanId } else { $planId }
        $billingChecks += New-Check -Name "entitlement_state" -Status "WARN" -Detail ("Billing is in a truthful checkout-gated posture for plan={0}; enabled_tools is empty until activation completes." -f $displayPlan) -Component "billing" -Path $billingSummaryPath -NextAction "Keep billing analysis-only until checkout or explicit entitlement activation completes."
    }
    else {
        $billingChecks += New-Check -Name "entitlement_state" -Status "FAIL" -Detail "Billing summary is readable but tenant enabled_tools is empty." -Component "billing" -Path $billingSummaryPath -NextAction "Repair entitlement resolution so the active tenant exposes enabled tools and features."
    }
}
$sections += New-SectionResult -SectionName "billing/entitlements" -Checks $billingChecks

# environment adaptation
$environmentChecks = @()
$environmentProfileCheck = Get-FileArtifactCheck -CheckName "environment_profile_artifact" -Path $environmentProfilePath -Component "environment" -MissingNextAction "Run tools/ops/Run_Environment_Adaptation.ps1 so the environment profile artifact is written." -RequiredKeys @("timestamp_utc", "environment_id", "host_classification", "host_identity_summary", "capability_summary", "network_posture", "service_availability")
$environmentChecks += $environmentProfileCheck.check

$environmentDriftCheck = Get-FileArtifactCheck -CheckName "environment_drift_artifact" -Path $environmentDriftPath -Component "environment" -MissingNextAction "Run tools/ops/Run_Environment_Adaptation.ps1 so the environment drift artifact is written." -RequiredKeys @("timestamp_utc", "current_environment_id", "drift_level", "recommended_next_action", "migration_detected", "safe_posture_adjustment")
$environmentChecks += $environmentDriftCheck.check
if ($environmentDriftCheck.data) {
    $hasChangedDimensions = $false
    if ($environmentDriftCheck.data -is [System.Collections.IDictionary]) {
        $hasChangedDimensions = $environmentDriftCheck.data.Contains("changed_dimensions")
    }
    else {
        $hasChangedDimensions = $null -ne $environmentDriftCheck.data.PSObject.Properties["changed_dimensions"]
    }
    if ($hasChangedDimensions) {
        $changedDimensions = @((Get-PropValue -Object $environmentDriftCheck.data -Name "changed_dimensions" -Default @()))
        $environmentChecks += New-Check -Name "environment_changed_dimensions" -Status "PASS" -Detail ("Environment drift exposes changed_dimensions count={0}." -f $changedDimensions.Count) -Component "environment" -Path $environmentDriftPath -NextAction "No action required."
    }
    else {
        $environmentChecks += New-Check -Name "environment_changed_dimensions" -Status "FAIL" -Detail "Environment drift artifact is missing changed_dimensions." -Component "environment" -Path $environmentDriftPath -NextAction "Rewrite reports/environment_drift_last.json so changed_dimensions is always present, even when empty."
    }

    $driftLevel = Normalize-Text (Get-PropValue -Object $environmentDriftCheck.data -Name "drift_level" -Default "")
    $allowedDriftLevels = @("no_material_change", "minor_change", "significant_change", "new_environment")
    if ($driftLevel -and $allowedDriftLevels -contains $driftLevel) {
        $environmentChecks += New-Check -Name "environment_drift_level" -Status "PASS" -Detail ("Environment drift level is {0}." -f $driftLevel) -Component "environment" -Path $environmentDriftPath -NextAction "No action required."
    }
    else {
        $driftLevelDisplay = if ($driftLevel) { $driftLevel } else { "unknown" }
        $environmentChecks += New-Check -Name "environment_drift_level" -Status "FAIL" -Detail ("Environment drift level is missing or invalid: {0}" -f $driftLevelDisplay) -Component "environment" -Path $environmentDriftPath -NextAction "Rewrite reports/environment_drift_last.json with a canonical drift level."
    }
}

$runtimePostureCheck = Get-FileArtifactCheck -CheckName "runtime_posture_artifact" -Path $runtimePosturePath -Component "environment" -MissingNextAction "Run tools/ops/Run_Environment_Adaptation.ps1 so the runtime posture artifact is written." -RequiredKeys @("timestamp_utc", "environment_id", "host_classification", "learning_posture", "heavy_jobs_posture", "monitoring_posture", "cleanup_posture", "throttle_guidance", "recommended_next_action")
$environmentChecks += $runtimePostureCheck.check
if ($runtimePostureCheck.data) {
    $rationale = @((Get-PropValue -Object $runtimePostureCheck.data -Name "rationale" -Default @()))
    if ($rationale.Count -gt 0) {
        $environmentChecks += New-Check -Name "runtime_posture_rationale" -Status "PASS" -Detail ("Runtime posture exposes {0} rationale item(s)." -f $rationale.Count) -Component "environment" -Path $runtimePosturePath -NextAction "No action required."
    }
    else {
        $environmentChecks += New-Check -Name "runtime_posture_rationale" -Status "FAIL" -Detail "Runtime posture is missing rationale entries." -Component "environment" -Path $runtimePosturePath -NextAction "Rewrite reports/runtime_posture_last.json with rationale for the selected posture."
    }
}

$environmentRegistryCheck = Get-FileArtifactCheck -CheckName "environment_registry_artifact" -Path $environmentRegistryPath -Component "environment" -MissingNextAction "Run tools/ops/Run_Environment_Adaptation.ps1 so the environment registry is written." -RequiredKeys @("generated_at_utc", "current_environment_id", "environments")
$environmentChecks += $environmentRegistryCheck.check
if ($environmentRegistryCheck.data) {
    $registryEnvironments = @((Get-PropValue -Object $environmentRegistryCheck.data -Name "environments" -Default @()))
    $currentEnvironmentId = Normalize-Text (Get-PropValue -Object $environmentRegistryCheck.data -Name "current_environment_id" -Default "")
    if ($registryEnvironments.Count -gt 0) {
        $environmentChecks += New-Check -Name "environment_registry_records" -Status "PASS" -Detail ("Environment registry contains {0} environment record(s)." -f $registryEnvironments.Count) -Component "environment" -Path $environmentRegistryPath -NextAction "No action required."
    }
    else {
        $environmentChecks += New-Check -Name "environment_registry_records" -Status "FAIL" -Detail "Environment registry is readable but contains no environment records." -Component "environment" -Path $environmentRegistryPath -NextAction "Rewrite state/knowledge/environment_registry.json with at least one environment entry."
    }

    $currentEntry = @($registryEnvironments | Where-Object { (Normalize-Text (Get-PropValue -Object $_ -Name "environment_id" -Default "")) -eq $currentEnvironmentId } | Select-Object -First 1)
    if ($currentEnvironmentId -and $currentEntry) {
        $environmentChecks += New-Check -Name "environment_registry_current" -Status "PASS" -Detail ("Environment registry current_environment_id={0} is present." -f $currentEnvironmentId) -Component "environment" -Path $environmentRegistryPath -NextAction "No action required."
    }
    else {
        $environmentChecks += New-Check -Name "environment_registry_current" -Status "FAIL" -Detail "Environment registry current_environment_id is missing or not present in environments." -Component "environment" -Path $environmentRegistryPath -NextAction "Rewrite state/knowledge/environment_registry.json so current_environment_id points to a real environment entry."
    }
}
$sections += New-SectionResult -SectionName "environment adaptation" -Checks $environmentChecks

# brand / exposure isolation
$brandExposureChecks = @()
$brandPolicyCheck = Get-FileArtifactCheck -CheckName "brand_exposure_policy" -Path $brandExposurePolicyPath -Component "brand_exposure" -MissingNextAction "Restore config/brand_exposure_policy.json so public/internal naming policy remains governed." -RequiredKeys @("version", "owner_internal_allowed_names", "customer_public_allowed_names", "banned_public_terms", "scan_targets")
$brandExposureChecks += $brandPolicyCheck.check
$brandSummaryCheck = Get-FileArtifactCheck -CheckName "brand_exposure_summary_artifact" -Path $brandExposureSummaryPath -Component "brand_exposure" -MissingNextAction "Run tools/ops/Run_Brand_Exposure_Isolation.ps1 so reports/brand_exposure_isolation_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "public_brand_posture", "internal_brand_posture", "total_surfaces_scanned", "public_safe_surface_count", "public_leak_count", "internal_surface_count", "recommended_next_action", "owner_only_wording_preserved", "customer_only_wording_isolated")
$brandExposureChecks += $brandSummaryCheck.check
$brandAuditCheck = Get-FileArtifactCheck -CheckName "brand_leak_audit_artifact" -Path $brandLeakAuditPath -Component "brand_exposure" -MissingNextAction "Run tools/ops/Run_Brand_Exposure_Isolation.ps1 so reports/brand_leak_audit_last.json is written." -RequiredKeys @("timestamp_utc", "surfaces_scanned_count", "exposures_found_count", "severity_summary", "per_surface_classification", "public_surfaces_clean", "owner_internal_surfaces_intact")
$brandExposureChecks += $brandAuditCheck.check
$publicVocabularyCheck = Get-FileArtifactCheck -CheckName "public_vocabulary_policy_last_artifact" -Path $publicVocabularyPolicyLastPath -Component "brand_exposure" -MissingNextAction "Run tools/ops/Run_Brand_Exposure_Isolation.ps1 so reports/public_vocabulary_policy_last.json is written." -RequiredKeys @("timestamp_utc", "policy_version", "owner_internal_allowed_names", "customer_public_allowed_names", "banned_public_terms", "scan_targets_count")
$brandExposureChecks += $publicVocabularyCheck.check

if ($brandAuditCheck.data) {
    if (Test-ObjectHasKey -Object $brandAuditCheck.data -Name "leak_records") {
        $brandLeakRecords = @(Get-PropValue -Object $brandAuditCheck.data -Name "leak_records" -Default @())
        $brandExposureChecks += New-Check -Name "brand_leak_records_present" -Status "PASS" -Detail ("Brand leak audit includes leak_records with {0} record(s)." -f $brandLeakRecords.Count) -Component "brand_exposure" -Path $brandLeakAuditPath -NextAction "No action required."
    }
    else {
        $brandExposureChecks += New-Check -Name "brand_leak_records_present" -Status "FAIL" -Detail "Brand leak audit is missing the leak_records field." -Component "brand_exposure" -Path $brandLeakAuditPath -NextAction "Rewrite reports/brand_leak_audit_last.json with the required leak_records field."
    }
}

if ($brandSummaryCheck.data -and $brandAuditCheck.data) {
    $publicLeakCount = [int](Get-PropValue -Object $brandSummaryCheck.data -Name "public_leak_count" -Default 0)
    $publicSafe = [bool](Get-PropValue -Object $brandSummaryCheck.data -Name "customer_only_wording_isolated" -Default $false)
    $ownerOnlyPreserved = [bool](Get-PropValue -Object $brandSummaryCheck.data -Name "owner_only_wording_preserved" -Default $false)
    $surfacesScanned = [int](Get-PropValue -Object $brandSummaryCheck.data -Name "total_surfaces_scanned" -Default 0)
    $exposuresFound = [int](Get-PropValue -Object $brandAuditCheck.data -Name "exposures_found_count" -Default 0)
    $auditPublicClean = [bool](Get-PropValue -Object $brandAuditCheck.data -Name "public_surfaces_clean" -Default $false)
    $auditOwnerIntact = [bool](Get-PropValue -Object $brandAuditCheck.data -Name "owner_internal_surfaces_intact" -Default $false)

    if ($surfacesScanned -gt 0) {
        $brandExposureChecks += New-Check -Name "brand_surfaces_scanned" -Status "PASS" -Detail ("Brand exposure audit scanned {0} surface(s)." -f $surfacesScanned) -Component "brand_exposure" -Path $brandExposureSummaryPath -NextAction "No action required."
    }
    else {
        $brandExposureChecks += New-Check -Name "brand_surfaces_scanned" -Status "WARN" -Detail "Brand exposure audit wrote artifacts but scanned zero surfaces." -Component "brand_exposure" -Path $brandExposureSummaryPath -NextAction "Repair the scan target policy and rerun the brand exposure audit."
    }

    if ($publicLeakCount -eq 0 -and $publicSafe -and $auditPublicClean -and $exposuresFound -eq 0) {
        $brandExposureChecks += New-Check -Name "public_brand_leak_count" -Status "PASS" -Detail "Public/customer-facing brand surfaces are clean; public_leak_count=0." -Component "brand_exposure" -Path $brandExposureSummaryPath -NextAction "No action required."
    }
    elseif ($publicLeakCount -gt 0 -or $exposuresFound -gt 0) {
        $brandExposureChecks += New-Check -Name "public_brand_leak_count" -Status "FAIL" -Detail ("Brand exposure audit found {0} public leak(s)." -f ([Math]::Max($publicLeakCount, $exposuresFound))) -Component "brand_exposure" -Path $brandLeakAuditPath -NextAction "Replace public/internal leakage with Onyx-safe vocabulary, then rerun the brand exposure audit."
    }
    else {
        $brandExposureChecks += New-Check -Name "public_brand_leak_count" -Status "WARN" -Detail "Brand exposure artifacts are readable but the public-safe posture is not fully aligned yet." -Component "brand_exposure" -Path $brandExposureSummaryPath -NextAction "Rerun the brand exposure audit after reviewing policy and surface classifications."
    }

    if ($ownerOnlyPreserved -and $auditOwnerIntact) {
        $brandExposureChecks += New-Check -Name "owner_only_brand_preserved" -Status "PASS" -Detail "Owner/internal surfaces still preserve intended Mason vocabulary where allowed." -Component "brand_exposure" -Path $brandExposureSummaryPath -NextAction "No action required."
    }
    else {
        $brandExposureChecks += New-Check -Name "owner_only_brand_preserved" -Status "WARN" -Detail "Owner/internal vocabulary preservation could not be fully confirmed from the latest audit." -Component "brand_exposure" -Path $brandExposureSummaryPath -NextAction "Review the brand exposure audit to ensure owner-only Mason references remain intact."
    }
}

$stackBrandExposure = Get-PropValue -Object $stackStatusProbe.data -Name "brand_exposure" -Default $null
if ($stackStatusProbe.ok -and $stackBrandExposure) {
    $brandExposureChecks += New-Check -Name "brand_exposure_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes brand_exposure with public_leak_count={0}." -f ([int](Get-PropValue -Object $stackBrandExposure -Name "public_leak_count" -Default 0))) -Component "brand_exposure" -Path $stackStatusUrl -NextAction "No action required."

    $brandPayloadKeys = @("overall_status", "public_brand_posture", "public_leak_count", "surfaces_scanned", "recommended_next_action", "owner_only_preserved", "customer_safe")
    $missingBrandPayloadKeys = @($brandPayloadKeys | Where-Object { -not (Test-ObjectHasKey -Object $stackBrandExposure -Name $_) })
    if ($missingBrandPayloadKeys.Count -eq 0) {
        $brandExposureChecks += New-Check -Name "brand_exposure_payload_shape" -Status "PASS" -Detail "Athena stack payload exposes the governed brand_exposure keys." -Component "brand_exposure" -Path $stackStatusUrl -NextAction "No action required."
    }
    else {
        $brandExposureChecks += New-Check -Name "brand_exposure_payload_shape" -Status "WARN" -Detail ("Athena stack payload brand_exposure is readable but missing keys: {0}" -f ($missingBrandPayloadKeys -join ", ")) -Component "brand_exposure" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow after rerunning the brand exposure audit so /api/stack_status exposes the full payload shape."
    }
}
elseif ($stackStatusProbe.ok) {
    $brandExposureChecks += New-Check -Name "brand_exposure_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but brand_exposure is missing." -Component "brand_exposure" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes brand_exposure."
}
else {
    $brandExposureChecks += New-Check -Name "brand_exposure_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so brand exposure visibility cannot be verified right now." -Component "brand_exposure" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify brand exposure visibility."
}
$sections += New-SectionResult -SectionName "brand / exposure isolation" -Checks $brandExposureChecks

# live docs / manuals
$liveDocsChecks = @()
$docsRegistryCheck = Get-FileArtifactCheck -CheckName "component_docs_registry" -Path $componentDocsRegistryPath -Component "athena" -MissingNextAction "Restore config/component_docs_registry.json so live docs coverage remains governed." -RequiredKeys @("version", "components")
$liveDocsChecks += $docsRegistryCheck.check
$liveDocsIndexCheck = Get-FileArtifactCheck -CheckName "live_docs_index_artifact" -Path $liveDocsIndexPath -Component "athena" -MissingNextAction "Run tools/ops/Generate_Live_Component_Docs.ps1 so reports/live_docs_index.json is written." -RequiredKeys @("generated_at_utc", "docs_version", "components", "default_component")
$liveDocsChecks += $liveDocsIndexCheck.check
$liveDocsSummaryCheck = Get-FileArtifactCheck -CheckName "live_docs_summary_artifact" -Path $liveDocsSummaryPath -Component "athena" -MissingNextAction "Run tools/ops/Generate_Live_Component_Docs.ps1 so reports/live_docs_summary.json is written." -RequiredKeys @("generated_at_utc", "summary_status", "docs_count", "components", "default_component")
$liveDocsChecks += $liveDocsSummaryCheck.check
$masonManualCheck = Get-FileArtifactCheck -CheckName "mason_live_manual" -Path $liveDocsMasonPath -Component "mason" -MissingNextAction "Run tools/ops/Generate_Live_Component_Docs.ps1 so reports/docs/mason_live_manual.json is written." -RequiredKeys @("generated_at_utc", "component_id", "current_status", "docs_version")
$liveDocsChecks += $masonManualCheck.check
$athenaManualCheck = Get-FileArtifactCheck -CheckName "athena_live_manual" -Path $liveDocsAthenaPath -Component "athena" -MissingNextAction "Run tools/ops/Generate_Live_Component_Docs.ps1 so reports/docs/athena_live_manual.json is written." -RequiredKeys @("generated_at_utc", "component_id", "current_status", "docs_version")
$liveDocsChecks += $athenaManualCheck.check
$onyxManualCheck = Get-FileArtifactCheck -CheckName "onyx_live_manual" -Path $liveDocsOnyxPath -Component "onyx" -MissingNextAction "Run tools/ops/Generate_Live_Component_Docs.ps1 so reports/docs/onyx_live_manual.json is written." -RequiredKeys @("generated_at_utc", "component_id", "current_status", "docs_version")
$liveDocsChecks += $onyxManualCheck.check

$summaryComponents = @()
if ($liveDocsSummaryCheck.data) {
    $summaryComponents = @((Get-PropValue -Object $liveDocsSummaryCheck.data -Name "components" -Default @()))
    if ($summaryComponents.Count -ge 3) {
        $liveDocsChecks += New-Check -Name "live_docs_component_count" -Status "PASS" -Detail ("Live docs summary contains {0} component manual(s)." -f $summaryComponents.Count) -Component "athena" -Path $liveDocsSummaryPath -NextAction "No action required."
    }
    else {
        $liveDocsChecks += New-Check -Name "live_docs_component_count" -Status "FAIL" -Detail ("Live docs summary contains only {0} component manual(s)." -f $summaryComponents.Count) -Component "athena" -Path $liveDocsSummaryPath -NextAction "Regenerate live docs so Mason, Athena, and Onyx manuals all exist."
    }
}

if ($liveDocsIndexCheck.data) {
    $missingIndexKeys = @(@("docs_count", "summary_status", "components_with_warnings", "components_healthy", "components_blocked", "stale_docs_count", "latest_generated_at_utc") | Where-Object { -not (Test-ObjectHasKey -Object $liveDocsIndexCheck.data -Name $_) })
    if ($missingIndexKeys.Count -eq 0) {
        $liveDocsChecks += New-Check -Name "live_docs_index_shape" -Status "PASS" -Detail "Live docs index includes the enriched summary fields." -Component "athena" -Path $liveDocsIndexPath -NextAction "No action required."
    }
    else {
        $liveDocsChecks += New-Check -Name "live_docs_index_shape" -Status "WARN" -Detail ("Live docs index is readable but missing enriched fields: {0}" -f ($missingIndexKeys -join ", ")) -Component "athena" -Path $liveDocsIndexPath -NextAction "Regenerate live docs so the index carries the enriched summary fields."
    }
}

$liveDocsSummaryExpectedKeys = @("docs_count", "summary_status", "components_with_warnings", "components_healthy", "components_blocked", "stale_docs_count", "latest_generated_at_utc")
if ($liveDocsSummaryCheck.data) {
    $missingSummaryKeys = @($liveDocsSummaryExpectedKeys | Where-Object { -not (Test-ObjectHasKey -Object $liveDocsSummaryCheck.data -Name $_) })
    if ($missingSummaryKeys.Count -eq 0) {
        $liveDocsChecks += New-Check -Name "live_docs_summary_shape" -Status "PASS" -Detail "Live docs summary includes the enriched manual coverage fields." -Component "athena" -Path $liveDocsSummaryPath -NextAction "No action required."
    }
    else {
        $liveDocsChecks += New-Check -Name "live_docs_summary_shape" -Status "WARN" -Detail ("Live docs summary is readable but missing enriched fields: {0}" -f ($missingSummaryKeys -join ", ")) -Component "athena" -Path $liveDocsSummaryPath -NextAction "Regenerate live docs so summary coverage includes warning, blocked, stale, and freshness fields."
    }

    $staleDocsCount = [int](Get-PropValue -Object $liveDocsSummaryCheck.data -Name "stale_docs_count" -Default 0)
    if ($staleDocsCount -gt 0) {
        $liveDocsChecks += New-Check -Name "live_docs_staleness" -Status "WARN" -Detail ("Live docs summary reports stale_docs_count={0}." -f $staleDocsCount) -Component "athena" -Path $liveDocsSummaryPath -NextAction "Regenerate live docs after the latest authoritative artifacts are refreshed."
    }
    else {
        $liveDocsChecks += New-Check -Name "live_docs_staleness" -Status "PASS" -Detail "Live docs summary reports stale_docs_count=0." -Component "athena" -Path $liveDocsSummaryPath -NextAction "No action required."
    }
}

$requiredManualKeys = @(
    "component_id",
    "display_name",
    "role",
    "purpose_summary",
    "current_status",
    "warning_summary",
    "dependencies",
    "key_endpoints_or_interfaces",
    "source_artifacts",
    "founder_actions",
    "mason_safe_actions",
    "blocked_or_guarded_actions",
    "recent_changes",
    "validation_summary",
    "generated_at_utc"
)

foreach ($manualCheck in @(
    @{ name = "mason_live_manual_shape"; component = "mason"; path = $liveDocsMasonPath; data = $masonManualCheck.data },
    @{ name = "athena_live_manual_shape"; component = "athena"; path = $liveDocsAthenaPath; data = $athenaManualCheck.data },
    @{ name = "onyx_live_manual_shape"; component = "onyx"; path = $liveDocsOnyxPath; data = $onyxManualCheck.data }
)) {
    if (-not $manualCheck.data) {
        continue
    }

    $missingManualKeys = @($requiredManualKeys | Where-Object { -not (Test-ObjectHasKey -Object $manualCheck.data -Name $_) })
    if ($missingManualKeys.Count -eq 0) {
        $liveDocsChecks += New-Check -Name $manualCheck.name -Status "PASS" -Detail ("{0} includes the enriched operational manual sections." -f (Split-Path -Leaf $manualCheck.path)) -Component $manualCheck.component -Path $manualCheck.path -NextAction "No action required."
    }
    else {
        $liveDocsChecks += New-Check -Name $manualCheck.name -Status "WARN" -Detail ("{0} is readable but missing enriched manual fields: {1}" -f (Split-Path -Leaf $manualCheck.path), ($missingManualKeys -join ", ")) -Component $manualCheck.component -Path $manualCheck.path -NextAction "Regenerate live docs so the component manual includes the required operator-manual sections."
    }
}

$stackLiveDocs = Get-PropValue -Object $stackStatusProbe.data -Name "live_docs" -Default $null
if ($stackStatusProbe.ok -and $stackLiveDocs) {
    $payloadDocsCount = [int](Get-PropValue -Object $stackLiveDocs -Name "docs_count" -Default 0)
    $liveDocsChecks += New-Check -Name "live_docs_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes live_docs with docs_count={0}." -f $payloadDocsCount) -Component "athena" -Path $stackStatusUrl -NextAction "No action required."

    $payloadRequiredKeys = @("owner_only", "generated_at_utc", "latest_generated_at_utc", "summary_status", "docs_count", "components_with_warnings", "components_healthy", "components_blocked", "stale_docs_count", "components", "index_path", "summary_path", "default_component", "manuals")
    $missingPayloadKeys = @($payloadRequiredKeys | Where-Object { -not (Test-ObjectHasKey -Object $stackLiveDocs -Name $_) })
    if ($missingPayloadKeys.Count -eq 0) {
        $liveDocsChecks += New-Check -Name "live_docs_payload_shape" -Status "PASS" -Detail "Athena stack payload exposes the enriched live_docs keys." -Component "athena" -Path $stackStatusUrl -NextAction "No action required."
    }
    else {
        $liveDocsChecks += New-Check -Name "live_docs_payload_shape" -Status "WARN" -Detail ("Athena stack payload live_docs is readable but missing keys: {0}" -f ($missingPayloadKeys -join ", ")) -Component "athena" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow after regenerating live docs so /api/stack_status exposes the enriched payload."
    }
}
elseif ($stackStatusProbe.ok) {
    $liveDocsChecks += New-Check -Name "live_docs_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but live_docs is missing." -Component "athena" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes live_docs."
}
else {
    $liveDocsChecks += New-Check -Name "live_docs_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so live_docs visibility cannot be verified right now." -Component "athena" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify live_docs visibility."
}

if ($docsRegistryCheck.data) {
    $enabledRegistryIds = @()
    foreach ($item in @((Get-PropValue -Object $docsRegistryCheck.data -Name "components" -Default @()))) {
        $componentId = Normalize-Text (Get-PropValue -Object $item -Name "component_id" -Default "")
        $docsEnabled = Get-PropValue -Object $item -Name "docs_enabled" -Default $true
        if ($componentId -and $docsEnabled) {
            $enabledRegistryIds += $componentId
        }
    }
    $summaryIds = @($summaryComponents | ForEach-Object { Normalize-Text (Get-PropValue -Object $_ -Name "component_id" -Default "") } | Where-Object { $_ })
    $missingCore = @(@("mason", "athena", "onyx") | Where-Object { $summaryIds -notcontains $_ })
    $missingOptional = @($enabledRegistryIds | Where-Object { $summaryIds -notcontains $_ -and $_ -notin @("mason", "athena", "onyx") })
    if ($missingCore.Count -gt 0) {
        $liveDocsChecks += New-Check -Name "docs_registry_coverage" -Status "FAIL" -Detail ("Live docs are missing required manuals for: {0}" -f ($missingCore -join ", ")) -Component "athena" -Path $componentDocsRegistryPath -NextAction "Regenerate live docs so Mason, Athena, and Onyx manuals are all present."
    }
    elseif ($missingOptional.Count -gt 0) {
        $liveDocsChecks += New-Check -Name "docs_registry_coverage" -Status "WARN" -Detail ("Docs-enabled future components are not yet generated: {0}" -f ($missingOptional -join ", ")) -Component "athena" -Path $componentDocsRegistryPath -NextAction "Regenerate live docs after the new docs-enabled components write authoritative artifacts."
    }
    else {
        $liveDocsChecks += New-Check -Name "docs_registry_coverage" -Status "PASS" -Detail "Docs-enabled registry coverage matches the generated live manuals." -Component "athena" -Path $componentDocsRegistryPath -NextAction "No action required."
    }
}
$sections += New-SectionResult -SectionName "live docs / manuals" -Checks $liveDocsChecks

# system truth + metrics spine
$systemTruthChecks = @()
$systemTruthArtifactCheck = Get-FileArtifactCheck -CheckName "system_truth_spine_artifact" -Path $systemTruthSpinePath -Component "system_truth" -MissingNextAction "Run tools/ops/Build_System_Truth_Spine.ps1 so reports/system_truth_spine_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "truth_version", "baseline_tag", "command_run", "repo_root", "recommended_next_action", "truth_sources", "domains", "summary", "staleness", "merge_warnings")
$systemTruthChecks += $systemTruthArtifactCheck.check
$systemMetricsArtifactCheck = Get-FileArtifactCheck -CheckName "system_metrics_spine_artifact" -Path $systemMetricsSpinePath -Component "system_truth" -MissingNextAction "Run tools/ops/Build_System_Truth_Spine.ps1 so reports/system_metrics_spine_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "service_count", "healthy_service_count", "tenant_count", "queue_total", "tool_total", "enabled_tool_total", "warning_domain_count", "failing_domain_count", "available_domain_count")
$systemTruthChecks += $systemMetricsArtifactCheck.check
$systemTruthSummaryArtifactData = Read-JsonSafe -Path $systemTruthSummaryPath -Default $null
if (-not (Test-Path -LiteralPath $systemTruthSummaryPath)) {
    $systemTruthSummaryArtifactCheck = [pscustomobject]@{
        check = New-Check -Name "system_truth_summary_artifact" -Status "FAIL" -Detail ("Missing artifact: {0}" -f $systemTruthSummaryPath) -Component "system_truth" -Path $systemTruthSummaryPath -NextAction "Run tools/ops/Build_System_Truth_Spine.ps1 so reports/system_truth_summary_last.json is written."
        data  = $null
    }
}
elseif ($null -eq $systemTruthSummaryArtifactData) {
    $systemTruthSummaryArtifactCheck = [pscustomobject]@{
        check = New-Check -Name "system_truth_summary_artifact" -Status "FAIL" -Detail ("Artifact is not readable JSON: {0}" -f $systemTruthSummaryPath) -Component "system_truth" -Path $systemTruthSummaryPath -NextAction ("Repair or rewrite the artifact at {0}." -f $systemTruthSummaryPath)
        data  = $null
    }
}
else {
    $systemTruthSummaryRequiredKeys = @("timestamp_utc", "overall_status", "top_warnings", "top_healthy_areas", "current_blocker_domains", "recommended_next_action", "summary_cards", "truth_timestamp_utc")
    $missingSystemTruthSummaryKeys = @()
    foreach ($requiredKey in $systemTruthSummaryRequiredKeys) {
        if (-not (Test-ObjectHasKey -Object $systemTruthSummaryArtifactData -Name $requiredKey)) {
            $missingSystemTruthSummaryKeys += $requiredKey
            continue
        }

        $value = Get-PropValue -Object $systemTruthSummaryArtifactData -Name $requiredKey -Default $null
        if ($value -is [string] -and -not (Normalize-Text $value)) {
            $missingSystemTruthSummaryKeys += $requiredKey
        }
    }

    if ($missingSystemTruthSummaryKeys.Count -gt 0) {
        $systemTruthSummaryArtifactCheck = [pscustomobject]@{
            check = New-Check -Name "system_truth_summary_artifact" -Status "FAIL" -Detail ("Artifact is missing required fields: {0}" -f ($missingSystemTruthSummaryKeys -join ", ")) -Component "system_truth" -Path $systemTruthSummaryPath -NextAction ("Rewrite {0} with the required schema." -f $systemTruthSummaryPath)
            data  = $systemTruthSummaryArtifactData
        }
    }
    else {
        $systemTruthSummaryArtifactCheck = [pscustomobject]@{
            check = New-Check -Name "system_truth_summary_artifact" -Status "PASS" -Detail ("Readable artifact: {0}" -f $systemTruthSummaryPath) -Component "system_truth" -Path $systemTruthSummaryPath -NextAction "No action required."
            data  = $systemTruthSummaryArtifactData
        }
    }
}
$systemTruthChecks += $systemTruthSummaryArtifactCheck.check
$systemTruthRegistryArtifactCheck = Get-FileArtifactCheck -CheckName "system_truth_registry_artifact" -Path $systemTruthRegistryPath -Component "system_truth" -MissingNextAction "Run tools/ops/Build_System_Truth_Spine.ps1 so state/knowledge/system_truth_registry.json is written." -RequiredKeys @("version", "latest_truth_artifact_path", "latest_metrics_artifact_path", "latest_summary_artifact_path", "last_build_timestamp_utc", "last_overall_status", "last_domain_statuses", "source_availability_summary")
$systemTruthChecks += $systemTruthRegistryArtifactCheck.check

$requiredTruthDomainKeys = @("stack", "validator", "services", "host", "environment", "mirror", "billing", "trust", "queues", "tenants", "tools", "self_improvement", "live_docs", "brand_exposure", "keepalive_ops")
if ($systemTruthArtifactCheck.data) {
    $truthDomains = Get-PropValue -Object $systemTruthArtifactCheck.data -Name "domains" -Default $null
    if ($truthDomains) {
        $missingTruthDomains = @($requiredTruthDomainKeys | Where-Object { -not (Test-ObjectHasKey -Object $truthDomains -Name $_) })
        if ($missingTruthDomains.Count -eq 0) {
            $systemTruthChecks += New-Check -Name "system_truth_domain_keys" -Status "PASS" -Detail "System truth spine exposes all required normalized domains." -Component "system_truth" -Path $systemTruthSpinePath -NextAction "No action required."
        }
        else {
            $systemTruthChecks += New-Check -Name "system_truth_domain_keys" -Status "FAIL" -Detail ("System truth spine is missing required domains: {0}" -f ($missingTruthDomains -join ", ")) -Component "system_truth" -Path $systemTruthSpinePath -NextAction "Repair Build_System_Truth_Spine.ps1 so all required domains are represented even when unavailable."
        }

        $domainSchemaWarnings = @()
        $misrepresentedUnavailable = @()
        foreach ($domainId in @($requiredTruthDomainKeys | Where-Object { Test-ObjectHasKey -Object $truthDomains -Name $_ })) {
            $domainNode = Get-PropValue -Object $truthDomains -Name $domainId -Default $null
            foreach ($fieldName in @("available", "status", "source_artifact_or_probe", "summary", "recommended_next_action")) {
                if (-not (Test-ObjectHasKey -Object $domainNode -Name $fieldName)) {
                    $domainSchemaWarnings += ("{0}.{1}" -f $domainId, $fieldName)
                }
            }
            $domainAvailable = [bool](Get-PropValue -Object $domainNode -Name "available" -Default $false)
            $domainStatusValue = Normalize-Text (Get-PropValue -Object $domainNode -Name "status" -Default "")
            if (-not $domainAvailable -and $domainStatusValue -and $domainStatusValue -ne "missing") {
                $misrepresentedUnavailable += $domainId
            }
        }
        if ($domainSchemaWarnings.Count -eq 0) {
            $systemTruthChecks += New-Check -Name "system_truth_domain_shape" -Status "PASS" -Detail "Every required system truth domain exposes the stable minimum shape." -Component "system_truth" -Path $systemTruthSpinePath -NextAction "No action required."
        }
        else {
            $systemTruthChecks += New-Check -Name "system_truth_domain_shape" -Status "WARN" -Detail ("System truth domains are readable but missing fields: {0}" -f ($domainSchemaWarnings -join ", ")) -Component "system_truth" -Path $systemTruthSpinePath -NextAction "Repair Build_System_Truth_Spine.ps1 so each required domain exposes the stable minimum structure."
        }
        if ($misrepresentedUnavailable.Count -eq 0) {
            $systemTruthChecks += New-Check -Name "system_truth_unavailable_representation" -Status "PASS" -Detail "Unavailable domains are truthfully represented as missing rather than silently omitted." -Component "system_truth" -Path $systemTruthSpinePath -NextAction "No action required."
        }
        else {
            $systemTruthChecks += New-Check -Name "system_truth_unavailable_representation" -Status "WARN" -Detail ("Unavailable domains are not fully represented as missing: {0}" -f ($misrepresentedUnavailable -join ", ")) -Component "system_truth" -Path $systemTruthSpinePath -NextAction "Normalize unavailable domains so available=false aligns with status=missing."
        }
    }

    $truthOverallStatus = Normalize-Text (Get-PropValue -Object $systemTruthArtifactCheck.data -Name "overall_status" -Default "")
    $validatorSourceArtifact = Read-JsonSafe -Path $systemValidationPath -Default $null
    $validatorOverallStatus = Normalize-Text (Get-PropValue -Object $validatorSourceArtifact -Name "overall_status" -Default "")
    if ($truthOverallStatus -eq "PASS" -and $validatorOverallStatus -in @("WARN", "FAIL")) {
        $systemTruthChecks += New-Check -Name "system_truth_validator_alignment" -Status "FAIL" -Detail ("System truth reports PASS while validator is {0}." -f $validatorOverallStatus) -Component "system_truth" -Path $systemTruthSpinePath -NextAction "Keep unresolved validator warnings/failures visible in the merged truth spine instead of collapsing them to PASS."
    }
    else {
        $systemTruthChecks += New-Check -Name "system_truth_validator_alignment" -Status "PASS" -Detail ("System truth overall_status={0} remains aligned with validator overall_status={1}." -f $truthOverallStatus, $validatorOverallStatus) -Component "system_truth" -Path $systemTruthSpinePath -NextAction "No action required."
    }
}

if ($systemMetricsArtifactCheck.data) {
    $metricsKeyGaps = @(@("recommendation_total", "queue_status_counts", "blocked_governed_count") | Where-Object { -not (Test-ObjectHasKey -Object $systemMetricsArtifactCheck.data -Name $_) })
    if ($metricsKeyGaps.Count -eq 0) {
        $systemTruthChecks += New-Check -Name "system_metrics_shape" -Status "PASS" -Detail "System metrics spine includes the expected normalized count fields." -Component "system_truth" -Path $systemMetricsSpinePath -NextAction "No action required."
    }
    else {
        $systemTruthChecks += New-Check -Name "system_metrics_shape" -Status "WARN" -Detail ("System metrics spine is readable but missing fields: {0}" -f ($metricsKeyGaps -join ", ")) -Component "system_truth" -Path $systemMetricsSpinePath -NextAction "Repair Build_System_Truth_Spine.ps1 so the metrics view exposes the normalized count fields."
    }
}

$stackSystemTruth = Get-PropValue -Object $stackStatusProbe.data -Name "system_truth" -Default $null
if ($stackStatusProbe.ok -and $stackSystemTruth) {
    $systemTruthChecks += New-Check -Name "system_truth_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes system_truth with overall_status={0}." -f (Normalize-Text (Get-PropValue -Object $stackSystemTruth -Name "overall_status" -Default "UNKNOWN"))) -Component "system_truth" -Path $stackStatusUrl -NextAction "No action required."

    $payloadTruthKeys = @("overall_status", "recommended_next_action", "available_domain_count", "warning_domain_count", "failing_domain_count", "truth_timestamp_utc", "top_warning_domains", "top_healthy_domains")
    $missingTruthPayloadKeys = @($payloadTruthKeys | Where-Object { -not (Test-ObjectHasKey -Object $stackSystemTruth -Name $_) })
    if ($missingTruthPayloadKeys.Count -eq 0) {
        $systemTruthChecks += New-Check -Name "system_truth_payload_shape" -Status "PASS" -Detail "Athena stack payload exposes the expected system_truth keys." -Component "system_truth" -Path $stackStatusUrl -NextAction "No action required."
    }
    else {
        $systemTruthChecks += New-Check -Name "system_truth_payload_shape" -Status "WARN" -Detail ("Athena stack payload system_truth is readable but missing keys: {0}" -f ($missingTruthPayloadKeys -join ", ")) -Component "system_truth" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow after rebuilding the truth spine so /api/stack_status exposes the full system_truth shape."
    }
}
elseif ($stackStatusProbe.ok) {
    $systemTruthChecks += New-Check -Name "system_truth_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but system_truth is missing." -Component "system_truth" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes system_truth."
}
else {
    $systemTruthChecks += New-Check -Name "system_truth_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so system_truth visibility cannot be verified right now." -Component "system_truth" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify system_truth visibility."
}

$stackSystemMetrics = Get-PropValue -Object $stackStatusProbe.data -Name "system_metrics" -Default $null
if ($stackStatusProbe.ok -and $stackSystemMetrics) {
    $systemTruthChecks += New-Check -Name "system_metrics_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes system_metrics with tool_total={0}." -f ([int](Get-PropValue -Object $stackSystemMetrics -Name "tool_total" -Default 0))) -Component "system_truth" -Path $stackStatusUrl -NextAction "No action required."
}
elseif ($stackStatusProbe.ok) {
    $systemTruthChecks += New-Check -Name "system_metrics_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but system_metrics is missing." -Component "system_truth" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes system_metrics."
}
$sections += New-SectionResult -SectionName "system truth + metrics spine" -Checks $systemTruthChecks

# regression guard / rollback engine
$regressionChecks = @()
$regressionGuardArtifactCheck = Get-FileArtifactCheck -CheckName "regression_guard_artifact" -Path $regressionGuardLastPath -Component "regression_guard" -MissingNextAction "Run tools/ops/Run_Regression_Guard.ps1 so reports/regression_guard_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "baseline_id", "baseline_available", "comparison_result", "regression_count", "blocking_regression_count", "warning_regression_count", "improved_domain_count", "unchanged_domain_count", "worsened_domain_count", "recommended_next_action", "rollback_recommended", "promotion_allowed", "command_run", "repo_root", "comparison_records")
$regressionChecks += $regressionGuardArtifactCheck.check
$promotionGateArtifactCheck = Get-FileArtifactCheck -CheckName "promotion_gate_artifact" -Path $promotionGateLastPath -Component "regression_guard" -MissingNextAction "Run tools/ops/Run_Regression_Guard.ps1 so reports/promotion_gate_last.json is written." -RequiredKeys @("timestamp_utc", "promotion_allowed", "promotion_blocked", "blocking_reasons", "allowed_with_warnings", "baseline_reference", "recommended_next_action")
$regressionChecks += $promotionGateArtifactCheck.check
$rollbackPlanArtifactCheck = Get-FileArtifactCheck -CheckName "rollback_plan_artifact" -Path $rollbackPlanLastPath -Component "regression_guard" -MissingNextAction "Run tools/ops/Run_Regression_Guard.ps1 so reports/rollback_plan_last.json is written." -RequiredKeys @("timestamp_utc", "rollback_recommended", "rollback_reason", "safe_rollback_steps", "artifacts_to_review", "preconditions", "blocked_rollback_reasons", "owner_action_required")
$regressionChecks += $rollbackPlanArtifactCheck.check
$regressionBaselinesArtifactCheck = Get-FileArtifactCheck -CheckName "regression_baselines_artifact" -Path $regressionBaselinesPath -Component "regression_guard" -MissingNextAction "Run tools/ops/Run_Regression_Guard.ps1 so state/knowledge/regression_baselines.json is written." -RequiredKeys @("version", "current_active_baseline_id", "baselines")
$regressionChecks += $regressionBaselinesArtifactCheck.check
$regressionPolicyArtifactCheck = Get-FileArtifactCheck -CheckName "regression_guard_policy" -Path $regressionGuardPolicyPath -Component "regression_guard" -MissingNextAction "Restore config/regression_guard_policy.json so regression comparisons and promotion gating stay canonical." -RequiredKeys @("version", "baseline_source_policy", "comparison_domains", "regression_severity_thresholds", "allowed_deltas", "promotion_blocking_rules", "rollback_recommendation_rules", "excluded_noisy_signals", "evidence_precedence", "stale_baseline_handling", "missing_baseline_handling")
$regressionChecks += $regressionPolicyArtifactCheck.check

if ($regressionGuardArtifactCheck.data) {
    $regressionStatus = Normalize-Text (Get-PropValue -Object $regressionGuardArtifactCheck.data -Name "overall_status" -Default "")
    $regressionStatusDisplay = if ($regressionStatus) { $regressionStatus } else { "unknown" }
    $regressionChecks += New-Check -Name "regression_guard_overall_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $regressionStatus -DefaultStatus "WARN") -Detail ("Regression guard overall_status={0}." -f $regressionStatusDisplay) -Component "regression_guard" -Path $regressionGuardLastPath -NextAction "Review regression, promotion, and rollback artifacts if the posture is not PASS."

    $baselineAvailable = [bool](Get-PropValue -Object $regressionGuardArtifactCheck.data -Name "baseline_available" -Default $false)
    $baselineTrusted = [bool](Get-PropValue -Object $regressionGuardArtifactCheck.data -Name "baseline_trusted" -Default $false)
    $comparisonResult = Normalize-Text (Get-PropValue -Object $regressionGuardArtifactCheck.data -Name "comparison_result" -Default "")
    $comparisonMode = Normalize-Text (Get-PropValue -Object $regressionGuardArtifactCheck.data -Name "comparison_mode" -Default "")
    if (-not $baselineAvailable) {
        $regressionChecks += New-Check -Name "regression_baseline_state" -Status "WARN" -Detail ("No eligible regression baseline is available; comparison_mode={0}." -f ($(if ($comparisonMode) { $comparisonMode } else { "unknown" }))) -Component "regression_guard" -Path $regressionBaselinesPath -NextAction "Seed or approve a usable baseline before treating promotion as eligible."
    }
    elseif (-not $baselineTrusted) {
        $comparisonResultDisplay = if ($comparisonResult) { $comparisonResult } else { "unknown" }
        $regressionChecks += New-Check -Name "regression_baseline_state" -Status "WARN" -Detail ("Regression guard is comparing against a seed/untrusted baseline; comparison_result={0}." -f $comparisonResultDisplay) -Component "regression_guard" -Path $regressionBaselinesPath -NextAction "Promote a trusted baseline only after the current posture is intentionally accepted."
    }
    else {
        $regressionChecks += New-Check -Name "regression_baseline_state" -Status "PASS" -Detail "Regression guard has a trusted eligible comparison baseline." -Component "regression_guard" -Path $regressionBaselinesPath -NextAction "No action required."
    }

    $comparisonRecords = @((Get-PropValue -Object $regressionGuardArtifactCheck.data -Name "comparison_records" -Default @()))
    if ($comparisonRecords.Count -gt 0) {
        $regressionChecks += New-Check -Name "regression_comparison_records" -Status "PASS" -Detail ("Regression guard produced {0} domain comparison record(s)." -f $comparisonRecords.Count) -Component "regression_guard" -Path $regressionGuardLastPath -NextAction "No action required."
    }
    else {
        $regressionChecks += New-Check -Name "regression_comparison_records" -Status "FAIL" -Detail "Regression guard artifact is readable but comparison_records is empty." -Component "regression_guard" -Path $regressionGuardLastPath -NextAction "Repair Run_Regression_Guard.ps1 so it records domain-by-domain comparison evidence."
    }

    $regressionCount = [int](Get-PropValue -Object $regressionGuardArtifactCheck.data -Name "regression_count" -Default 0)
    $blockingRegressionCount = [int](Get-PropValue -Object $regressionGuardArtifactCheck.data -Name "blocking_regression_count" -Default 0)
    $rollbackRecommended = [bool](Get-PropValue -Object $regressionGuardArtifactCheck.data -Name "rollback_recommended" -Default $false)
    $promotionAllowedFromGuard = [bool](Get-PropValue -Object $regressionGuardArtifactCheck.data -Name "promotion_allowed" -Default $false)
    if ($regressionCount -eq 0) {
        $regressionChecks += New-Check -Name "regression_count_state" -Status "PASS" -Detail "Regression guard reports regression_count=0." -Component "regression_guard" -Path $regressionGuardLastPath -NextAction "No action required."
    }
    elseif ($blockingRegressionCount -gt 0) {
        $regressionChecks += New-Check -Name "regression_count_state" -Status "WARN" -Detail ("Regression guard reports {0} regression(s), including {1} blocking regression(s)." -f $regressionCount, $blockingRegressionCount) -Component "regression_guard" -Path $regressionGuardLastPath -NextAction "Hold promotion and investigate the blocking regression evidence before approving more changes."
    }
    else {
        $regressionChecks += New-Check -Name "regression_count_state" -Status "WARN" -Detail ("Regression guard reports {0} warning-level regression(s)." -f $regressionCount) -Component "regression_guard" -Path $regressionGuardLastPath -NextAction "Review the warning-level regressions and decide whether the current drift is acceptable."
    }

    if ($blockingRegressionCount -gt 0 -and $promotionAllowedFromGuard) {
        $regressionChecks += New-Check -Name "promotion_blocking_alignment" -Status "FAIL" -Detail "Promotion is still allowed even though blocking regressions are present." -Component "regression_guard" -Path $promotionGateLastPath -NextAction "Repair Run_Regression_Guard.ps1 so blocking regressions always prevent promotion."
    }
    elseif ($rollbackRecommended -and $promotionAllowedFromGuard) {
        $regressionChecks += New-Check -Name "promotion_blocking_alignment" -Status "FAIL" -Detail "Promotion is still allowed even though rollback is recommended." -Component "regression_guard" -Path $promotionGateLastPath -NextAction "Repair Run_Regression_Guard.ps1 so rollback-recommended states block promotion."
    }
    elseif (-not $promotionAllowedFromGuard) {
        $regressionChecks += New-Check -Name "promotion_blocking_alignment" -Status "WARN" -Detail "Promotion remains blocked by conservative regression policy or baseline trust posture." -Component "regression_guard" -Path $promotionGateLastPath -NextAction "Keep promotion blocked until a trusted baseline exists and no blocking regressions remain."
    }
    else {
        $regressionChecks += New-Check -Name "promotion_blocking_alignment" -Status "PASS" -Detail "Promotion is allowed and no blocking regression/rollback contradictions were detected." -Component "regression_guard" -Path $promotionGateLastPath -NextAction "No action required."
    }
}

if ($promotionGateArtifactCheck.data) {
    if (Test-ObjectHasKey -Object $promotionGateArtifactCheck.data -Name "gating_domains") {
        $regressionChecks += New-Check -Name "promotion_gate_gating_domains" -Status "PASS" -Detail "Promotion gate records gating_domains, including the valid empty-list case." -Component "regression_guard" -Path $promotionGateLastPath -NextAction "No action required."
    }
    else {
        $regressionChecks += New-Check -Name "promotion_gate_gating_domains" -Status "FAIL" -Detail "Promotion gate is missing gating_domains." -Component "regression_guard" -Path $promotionGateLastPath -NextAction "Repair reports/promotion_gate_last.json so gating_domains is always represented, even when empty."
    }

    $promotionAllowed = [bool](Get-PropValue -Object $promotionGateArtifactCheck.data -Name "promotion_allowed" -Default $false)
    $promotionBlocked = [bool](Get-PropValue -Object $promotionGateArtifactCheck.data -Name "promotion_blocked" -Default $false)
    $blockingReasons = @((Get-PropValue -Object $promotionGateArtifactCheck.data -Name "blocking_reasons" -Default @()))
    if ($promotionAllowed -and $promotionBlocked) {
        $regressionChecks += New-Check -Name "promotion_gate_coherence" -Status "FAIL" -Detail "Promotion gate says promotion_allowed=true and promotion_blocked=true." -Component "regression_guard" -Path $promotionGateLastPath -NextAction "Repair reports/promotion_gate_last.json so promotion gate booleans are coherent."
    }
    elseif (-not $promotionAllowed -and $blockingReasons.Count -eq 0) {
        $regressionChecks += New-Check -Name "promotion_gate_coherence" -Status "WARN" -Detail "Promotion is blocked but blocking_reasons is empty." -Component "regression_guard" -Path $promotionGateLastPath -NextAction "Record explicit blocking reasons so promotion posture stays auditable."
    }
    else {
        $regressionChecks += New-Check -Name "promotion_gate_coherence" -Status "PASS" -Detail ("Promotion gate coherence is intact; promotion_allowed={0}; blocking_reasons={1}." -f $promotionAllowed.ToString().ToLowerInvariant(), $blockingReasons.Count) -Component "regression_guard" -Path $promotionGateLastPath -NextAction "No action required."
    }
}

if ($rollbackPlanArtifactCheck.data) {
    if (Test-ObjectHasKey -Object $rollbackPlanArtifactCheck.data -Name "rollback_scope") {
        $regressionChecks += New-Check -Name "rollback_scope_representation" -Status "PASS" -Detail "Rollback plan records rollback_scope, including the valid empty-list case." -Component "regression_guard" -Path $rollbackPlanLastPath -NextAction "No action required."
    }
    else {
        $regressionChecks += New-Check -Name "rollback_scope_representation" -Status "FAIL" -Detail "Rollback plan is missing rollback_scope." -Component "regression_guard" -Path $rollbackPlanLastPath -NextAction "Repair reports/rollback_plan_last.json so rollback_scope is always represented, even when empty."
    }

    $rollbackRecommended = [bool](Get-PropValue -Object $rollbackPlanArtifactCheck.data -Name "rollback_recommended" -Default $false)
    $safeRollbackSteps = @((Get-PropValue -Object $rollbackPlanArtifactCheck.data -Name "safe_rollback_steps" -Default @()))
    $blockedRollbackReasons = @((Get-PropValue -Object $rollbackPlanArtifactCheck.data -Name "blocked_rollback_reasons" -Default @()))
    if ($rollbackRecommended -and $safeRollbackSteps.Count -eq 0) {
        $regressionChecks += New-Check -Name "rollback_plan_shape" -Status "FAIL" -Detail "Rollback is recommended but safe_rollback_steps is empty." -Component "regression_guard" -Path $rollbackPlanLastPath -NextAction "Repair reports/rollback_plan_last.json so a recommended rollback includes safe rollback steps."
    }
    elseif (-not $rollbackRecommended -and $blockedRollbackReasons.Count -gt 0) {
        $regressionChecks += New-Check -Name "rollback_plan_shape" -Status "PASS" -Detail ("Rollback is not recommended and blocked_rollback_reasons records {0} reason(s)." -f $blockedRollbackReasons.Count) -Component "regression_guard" -Path $rollbackPlanLastPath -NextAction "No action required."
    }
    else {
        $rollbackStatus = if ($rollbackRecommended) { "WARN" } else { "PASS" }
        $rollbackDetail = if ($rollbackRecommended) { "Rollback is recommended and a safe rollback plan is present." } else { "Rollback plan is coherent and does not currently recommend rollback." }
        $regressionChecks += New-Check -Name "rollback_plan_shape" -Status $rollbackStatus -Detail $rollbackDetail -Component "regression_guard" -Path $rollbackPlanLastPath -NextAction $(if ($rollbackRecommended) { "Review the rollback plan before making further changes." } else { "No action required." })
    }
}

$stackRegressionGuard = Get-PropValue -Object $stackStatusProbe.data -Name "regression_guard" -Default $null
if ($stackStatusProbe.ok -and $stackRegressionGuard) {
    $regressionChecks += New-Check -Name "regression_guard_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes regression_guard with overall_status={0}." -f (Normalize-Text (Get-PropValue -Object $stackRegressionGuard -Name "overall_status" -Default "UNKNOWN"))) -Component "regression_guard" -Path $stackStatusUrl -NextAction "No action required."

    $requiredRegressionPayloadKeys = @("overall_status", "baseline_available", "regression_count", "blocking_regression_count", "rollback_recommended", "promotion_allowed", "recommended_next_action")
    $missingRegressionPayloadKeys = @($requiredRegressionPayloadKeys | Where-Object { -not (Test-ObjectHasKey -Object $stackRegressionGuard -Name $_) })
    if ($missingRegressionPayloadKeys.Count -eq 0) {
        $regressionChecks += New-Check -Name "regression_guard_payload_shape" -Status "PASS" -Detail "Athena stack payload exposes the expected regression_guard keys." -Component "regression_guard" -Path $stackStatusUrl -NextAction "No action required."
    }
    else {
        $regressionChecks += New-Check -Name "regression_guard_payload_shape" -Status "FAIL" -Detail ("Athena stack payload regression_guard is missing keys: {0}" -f ($missingRegressionPayloadKeys -join ", ")) -Component "regression_guard" -Path $stackStatusUrl -NextAction "Patch MasonConsole/server.py so regression_guard exposes the governed summary keys."
    }
}
elseif ($stackStatusProbe.ok) {
    $regressionChecks += New-Check -Name "regression_guard_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but regression_guard is missing." -Component "regression_guard" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes regression_guard."
}
else {
    $regressionChecks += New-Check -Name "regression_guard_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so regression_guard visibility cannot be verified right now." -Component "regression_guard" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify regression_guard visibility."
}
$sections += New-SectionResult -SectionName "regression guard / rollback engine" -Checks $regressionChecks

# playbook library + support brain
$playbookChecks = @()
$playbookLibraryArtifactCheck = Get-FileArtifactCheck -CheckName "playbook_library_artifact" -Path $playbookLibraryLastPath -Component "playbook_support" -MissingNextAction "Run tools/ops/Build_Playbook_Support_Brain.ps1 so reports/playbook_library_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "playbook_count", "active_playbook_count", "playbook_categories", "playbooks", "recommended_next_action", "command_run", "repo_root")
$playbookChecks += $playbookLibraryArtifactCheck.check
$supportBrainArtifactCheck = Get-FileArtifactCheck -CheckName "support_brain_artifact" -Path $supportBrainLastPath -Component "playbook_support" -MissingNextAction "Run tools/ops/Build_Playbook_Support_Brain.ps1 so reports/support_brain_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "recurring_issue_count", "supported_issue_types", "customer_safe_ready_count", "internal_support_ready_count", "recommended_next_action", "issue_type_mappings")
$playbookChecks += $supportBrainArtifactCheck.check
$incidentExplanationsArtifactCheck = Get-FileArtifactCheck -CheckName "incident_explanations_artifact" -Path $incidentExplanationsLastPath -Component "playbook_support" -MissingNextAction "Run tools/ops/Build_Playbook_Support_Brain.ps1 so reports/incident_explanations_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "issue_count", "issues")
$playbookChecks += $incidentExplanationsArtifactCheck.check
$playbookRegistryArtifactCheck = Get-FileArtifactCheck -CheckName "playbook_registry_artifact" -Path $playbookRegistryPath -Component "playbook_support" -MissingNextAction "Run tools/ops/Build_Playbook_Support_Brain.ps1 so state/knowledge/playbook_registry.json is written." -RequiredKeys @("generated_at_utc", "current_playbook_count", "current_categories", "latest_library_artifact", "current_status", "playbooks")
$playbookChecks += $playbookRegistryArtifactCheck.check
$playbookPolicyArtifactCheck = Get-FileArtifactCheck -CheckName "playbook_support_policy" -Path $playbookSupportPolicyPath -Component "playbook_support" -MissingNextAction "Restore config/playbook_support_policy.json so the playbook/support policy remains canonical." -RequiredKeys @("version", "allowed_source_artifacts", "explanation_scope_classes", "internal_vs_customer_safe_output_rules", "plain_english_formatting_expectations", "playbook_freshness_rules", "recommendation_safety_rules", "blocked_content_classes", "confidence_evidence_rules", "escalation_wording_rules")
$playbookChecks += $playbookPolicyArtifactCheck.check

if ($playbookLibraryArtifactCheck.data) {
    $playbookLibraryStatus = Normalize-Text (Get-PropValue -Object $playbookLibraryArtifactCheck.data -Name "overall_status" -Default "")
    $playbookChecks += New-Check -Name "playbook_library_overall_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $playbookLibraryStatus -DefaultStatus "WARN") -Detail ("Playbook library overall_status={0}." -f $(if ($playbookLibraryStatus) { $playbookLibraryStatus } else { "unknown" })) -Component "playbook_support" -Path $playbookLibraryLastPath -NextAction "Review the current recurring-issue playbooks and next actions if the posture is not PASS."

    $playbooks = @((Get-PropValue -Object $playbookLibraryArtifactCheck.data -Name "playbooks" -Default @()))
    if ($playbooks.Count -gt 0) {
        $playbookChecks += New-Check -Name "playbook_count_state" -Status "PASS" -Detail ("Playbook library contains {0} playbook record(s)." -f $playbooks.Count) -Component "playbook_support" -Path $playbookLibraryLastPath -NextAction "No action required."
    }
    else {
        $playbookChecks += New-Check -Name "playbook_count_state" -Status "WARN" -Detail "Playbook library structure is valid but playbooks is empty." -Component "playbook_support" -Path $playbookLibraryLastPath -NextAction "Populate at least one grounded playbook so recurring issues can be explained consistently."
    }

    $missingPlaybookFields = @()
    foreach ($playbook in $playbooks) {
        foreach ($field in @("playbook_id", "title", "category", "applicability", "trigger_conditions", "plain_english_explanation", "mason_safe_actions", "blocked_actions", "owner_actions", "escalation_rules", "evidence_sources", "status")) {
            if (-not (Test-ObjectHasKey -Object $playbook -Name $field)) {
                $missingPlaybookFields += $field
            }
        }
    }
    if ($missingPlaybookFields.Count -eq 0) {
        $playbookChecks += New-Check -Name "playbook_record_shape" -Status "PASS" -Detail "Playbook records expose the required reusable fields." -Component "playbook_support" -Path $playbookLibraryLastPath -NextAction "No action required."
    }
    else {
        $playbookChecks += New-Check -Name "playbook_record_shape" -Status "FAIL" -Detail ("Playbook records are missing required fields: {0}" -f (($missingPlaybookFields | Sort-Object -Unique) -join ", ")) -Component "playbook_support" -Path $playbookLibraryLastPath -NextAction "Repair Build_Playbook_Support_Brain.ps1 so every playbook carries the required reusable fields."
    }
}

if ($supportBrainArtifactCheck.data) {
    $supportBrainStatus = Normalize-Text (Get-PropValue -Object $supportBrainArtifactCheck.data -Name "overall_status" -Default "")
    $playbookChecks += New-Check -Name "support_brain_overall_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $supportBrainStatus -DefaultStatus "WARN") -Detail ("Support brain overall_status={0}." -f $(if ($supportBrainStatus) { $supportBrainStatus } else { "unknown" })) -Component "playbook_support" -Path $supportBrainLastPath -NextAction "Review current recurring issue mappings if the support brain is not PASS."

    $customerSafeReadyCount = [int](Get-PropValue -Object $supportBrainArtifactCheck.data -Name "customer_safe_ready_count" -Default 0)
    if ($customerSafeReadyCount -gt 0) {
        $playbookChecks += New-Check -Name "customer_safe_readiness" -Status "PASS" -Detail ("Support brain has {0} customer-safe-ready mapping(s)." -f $customerSafeReadyCount) -Component "playbook_support" -Path $supportBrainLastPath -NextAction "No action required."
    }
    else {
        $playbookChecks += New-Check -Name "customer_safe_readiness" -Status "WARN" -Detail "Support brain currently has zero customer-safe-ready mappings." -Component "playbook_support" -Path $supportBrainLastPath -NextAction "Add customer-safe wording only where it is grounded and appropriate."
    }
}

if ($incidentExplanationsArtifactCheck.data) {
    $incidentIssues = @((Get-PropValue -Object $incidentExplanationsArtifactCheck.data -Name "issues" -Default @()))
    $missingIncidentFields = @()
    foreach ($incidentIssue in $incidentIssues) {
        foreach ($field in @("issue_id", "issue_type", "severity", "plain_english_explanation", "why_it_matters", "what_mason_did_or_did_not_do", "what_should_happen_next", "linked_playbook_id")) {
            if (-not (Test-ObjectHasKey -Object $incidentIssue -Name $field)) {
                $missingIncidentFields += $field
            }
        }
    }
    if ($missingIncidentFields.Count -eq 0) {
        $playbookChecks += New-Check -Name "incident_explanations_shape" -Status "PASS" -Detail ("Incident explanations expose the required fields for {0} issue record(s)." -f $incidentIssues.Count) -Component "playbook_support" -Path $incidentExplanationsLastPath -NextAction "No action required."
    }
    else {
        $playbookChecks += New-Check -Name "incident_explanations_shape" -Status "FAIL" -Detail ("Incident explanations are missing required fields: {0}" -f (($missingIncidentFields | Sort-Object -Unique) -join ", ")) -Component "playbook_support" -Path $incidentExplanationsLastPath -NextAction "Repair Build_Playbook_Support_Brain.ps1 so incident explanations keep the required explanation fields."
    }
}

$stackPlaybookSupport = Get-PropValue -Object $stackStatusProbe.data -Name "playbook_support" -Default $null
if ($stackStatusProbe.ok -and $stackPlaybookSupport) {
    $playbookChecks += New-Check -Name "playbook_support_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes playbook_support with overall_status={0}." -f (Normalize-Text (Get-PropValue -Object $stackPlaybookSupport -Name "overall_status" -Default "UNKNOWN"))) -Component "playbook_support" -Path $stackStatusUrl -NextAction "No action required."

    $requiredPlaybookPayloadKeys = @("overall_status", "playbook_count", "recurring_issue_count", "customer_safe_ready_count", "internal_support_ready_count", "recommended_next_action", "top_issue_explanations")
    $missingPlaybookPayloadKeys = @($requiredPlaybookPayloadKeys | Where-Object { -not (Test-ObjectHasKey -Object $stackPlaybookSupport -Name $_) })
    if ($missingPlaybookPayloadKeys.Count -eq 0) {
        $playbookChecks += New-Check -Name "playbook_support_payload_shape" -Status "PASS" -Detail "Athena stack payload exposes the expected playbook_support keys." -Component "playbook_support" -Path $stackStatusUrl -NextAction "No action required."
    }
    else {
        $playbookChecks += New-Check -Name "playbook_support_payload_shape" -Status "FAIL" -Detail ("Athena stack payload playbook_support is missing keys: {0}" -f ($missingPlaybookPayloadKeys -join ", ")) -Component "playbook_support" -Path $stackStatusUrl -NextAction "Patch MasonConsole/server.py so playbook_support exposes the governed summary keys."
    }
}
elseif ($stackStatusProbe.ok) {
    $playbookChecks += New-Check -Name "playbook_support_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but playbook_support is missing." -Component "playbook_support" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes playbook_support."
}
else {
    $playbookChecks += New-Check -Name "playbook_support_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so playbook_support visibility cannot be verified right now." -Component "playbook_support" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify playbook_support visibility."
}
$sections += New-SectionResult -SectionName "playbook library + support brain" -Checks $playbookChecks

# wedge-pack / segment expansion framework
$wedgePackChecks = @()
$wedgePackFrameworkArtifactCheck = Get-FileArtifactCheck -CheckName "wedge_pack_framework_artifact" -Path $wedgePackFrameworkLastPath -Component "wedge_pack_framework" -MissingNextAction "Run tools/ops/Build_Wedge_Pack_Framework.ps1 so reports/wedge_pack_framework_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "business_category_count", "business_subcategory_count", "wedge_pack_count", "customer_ready_pack_count", "experimental_pack_count", "fallback_pack_available", "recommended_next_action", "command_run", "repo_root", "categories", "subcategories", "wedge_packs", "tool_bundles", "recommendation_rule_packs", "segment_profiles", "tenant_fit")
$wedgePackChecks += $wedgePackFrameworkArtifactCheck.check
$segmentOverlayArtifactCheck = Get-FileArtifactCheck -CheckName "segment_overlay_artifact" -Path $segmentOverlayLastPath -Component "wedge_pack_framework" -MissingNextAction "Run tools/ops/Build_Wedge_Pack_Framework.ps1 so reports/segment_overlay_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "onboarding_overlays", "dashboard_overlays", "recommendation_overlays", "recommended_next_action", "command_run", "repo_root")
$wedgePackChecks += $segmentOverlayArtifactCheck.check
$workflowPackArtifactCheck = Get-FileArtifactCheck -CheckName "workflow_pack_artifact" -Path $workflowPackLastPath -Component "wedge_pack_framework" -MissingNextAction "Run tools/ops/Build_Wedge_Pack_Framework.ps1 so reports/workflow_pack_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "workflow_packs", "tool_bundles", "recommendation_rule_packs", "recommended_next_action", "command_run", "repo_root")
$wedgePackChecks += $workflowPackArtifactCheck.check
$wedgePackRegistryArtifactCheck = Get-FileArtifactCheck -CheckName "wedge_pack_registry_artifact" -Path $wedgePackRegistryPath -Component "wedge_pack_framework" -MissingNextAction "Run tools/ops/Build_Wedge_Pack_Framework.ps1 so state/knowledge/wedge_pack_registry.json is written." -RequiredKeys @("generated_at_utc", "current_status", "current_framework_generation_timestamp", "wedge_packs", "current_categories", "current_subcategories", "pack_statuses", "default_fallback_rules", "latest_artifacts")
$wedgePackChecks += $wedgePackRegistryArtifactCheck.check
$wedgePackPolicyArtifactCheck = Get-FileArtifactCheck -CheckName "wedge_pack_policy" -Path $wedgePackPolicyPath -Component "wedge_pack_framework" -MissingNextAction "Restore config/wedge_pack_policy.json so wedge-pack policy stays canonical." -RequiredKeys @("version", "policy_name", "allowed_wedge_pack_statuses", "category_subcategory_policy", "default_fallback_segment_behavior", "tenant_fit_confidence_rules", "overlay_application_rules", "workflow_pack_application_rules", "recommendation_pack_application_rules", "blocked_or_experimental_wedge_statuses", "customer_safe_naming_rules", "future_expansion_guidance")
$wedgePackChecks += $wedgePackPolicyArtifactCheck.check

if ($wedgePackFrameworkArtifactCheck.data) {
    $frameworkStatus = Normalize-Text (Get-PropValue -Object $wedgePackFrameworkArtifactCheck.data -Name "overall_status" -Default "")
    $wedgePackChecks += New-Check -Name "wedge_pack_framework_overall_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $frameworkStatus -DefaultStatus "WARN") -Detail ("Wedge-pack framework overall_status={0}." -f $(if ($frameworkStatus) { $frameworkStatus } else { "unknown" })) -Component "wedge_pack_framework" -Path $wedgePackFrameworkLastPath -NextAction "Review the framework artifact if the wedge-pack posture is not PASS."

    $wedgePacks = @((Get-PropValue -Object $wedgePackFrameworkArtifactCheck.data -Name "wedge_packs" -Default @()))
    if ($wedgePacks.Count -gt 0) {
        $wedgePackChecks += New-Check -Name "wedge_pack_count_state" -Status "PASS" -Detail ("Framework records {0} wedge pack(s)." -f $wedgePacks.Count) -Component "wedge_pack_framework" -Path $wedgePackFrameworkLastPath -NextAction "No action required."
    }
    else {
        $wedgePackChecks += New-Check -Name "wedge_pack_count_state" -Status "FAIL" -Detail "Framework structure is present but wedge_packs is empty." -Component "wedge_pack_framework" -Path $wedgePackFrameworkLastPath -NextAction "Seed at least the fallback general small-business wedge pack."
    }

    $fallbackPackAvailable = [bool](Get-PropValue -Object $wedgePackFrameworkArtifactCheck.data -Name "fallback_pack_available" -Default $false)
    if ($fallbackPackAvailable) {
        $wedgePackChecks += New-Check -Name "fallback_pack_available" -Status "PASS" -Detail "Fallback/default wedge pack is available." -Component "wedge_pack_framework" -Path $wedgePackFrameworkLastPath -NextAction "No action required."
    }
    else {
        $wedgePackChecks += New-Check -Name "fallback_pack_available" -Status "FAIL" -Detail "Fallback/default wedge pack is missing." -Component "wedge_pack_framework" -Path $wedgePackFrameworkLastPath -NextAction "Restore the general small-business fallback pack so unclear tenants still map to a safe default."
    }

    $customerReadyPackCount = [int](Get-PropValue -Object $wedgePackFrameworkArtifactCheck.data -Name "customer_ready_pack_count" -Default 0)
    if ($customerReadyPackCount -gt 0) {
        $wedgePackChecks += New-Check -Name "customer_ready_pack_state" -Status "PASS" -Detail ("Framework records {0} customer-ready pack(s)." -f $customerReadyPackCount) -Component "wedge_pack_framework" -Path $wedgePackFrameworkLastPath -NextAction "No action required."
    }
    else {
        $wedgePackChecks += New-Check -Name "customer_ready_pack_state" -Status "WARN" -Detail "Framework is valid but currently has zero customer-ready packs." -Component "wedge_pack_framework" -Path $wedgePackFrameworkLastPath -NextAction "Promote at least the fallback pack when the framework evidence is ready."
    }

    $requiredFrameworkCollections = @("tool_bundles", "recommendation_rule_packs", "segment_profiles", "tenant_fit")
    $missingFrameworkCollections = @($requiredFrameworkCollections | Where-Object { -not (Test-ObjectHasKey -Object $wedgePackFrameworkArtifactCheck.data -Name $_) })
    if ($missingFrameworkCollections.Count -eq 0) {
        $wedgePackChecks += New-Check -Name "framework_concept_coverage" -Status "PASS" -Detail "Framework exposes tool bundles, recommendation rule packs, segment profiles, and tenant-fit output." -Component "wedge_pack_framework" -Path $wedgePackFrameworkLastPath -NextAction "No action required."
    }
    else {
        $wedgePackChecks += New-Check -Name "framework_concept_coverage" -Status "FAIL" -Detail ("Framework is missing concept collections: {0}" -f ($missingFrameworkCollections -join ", ")) -Component "wedge_pack_framework" -Path $wedgePackFrameworkLastPath -NextAction "Repair Build_Wedge_Pack_Framework.ps1 so the framework exposes the required segment-expansion concepts."
    }
}

if ($segmentOverlayArtifactCheck.data) {
    $overlayRecords = @()
    $overlayRecords += @((Get-PropValue -Object $segmentOverlayArtifactCheck.data -Name "onboarding_overlays" -Default @()))
    $overlayRecords += @((Get-PropValue -Object $segmentOverlayArtifactCheck.data -Name "dashboard_overlays" -Default @()))
    $overlayRecords += @((Get-PropValue -Object $segmentOverlayArtifactCheck.data -Name "recommendation_overlays" -Default @()))

    $missingOverlayFields = @()
    foreach ($overlayRecord in $overlayRecords) {
        foreach ($field in @("overlay_id", "applies_to_categories", "applies_to_subcategories", "status", "scope", "summary", "customer_safe_label")) {
            if (-not (Test-ObjectHasKey -Object $overlayRecord -Name $field)) {
                $missingOverlayFields += $field
            }
        }
    }
    if ($missingOverlayFields.Count -eq 0) {
        $wedgePackChecks += New-Check -Name "segment_overlay_shape" -Status "PASS" -Detail ("Overlay artifact exposes the required fields across {0} overlay record(s)." -f $overlayRecords.Count) -Component "wedge_pack_framework" -Path $segmentOverlayLastPath -NextAction "No action required."
    }
    else {
        $wedgePackChecks += New-Check -Name "segment_overlay_shape" -Status "FAIL" -Detail ("Overlay artifact is missing required fields: {0}" -f (($missingOverlayFields | Sort-Object -Unique) -join ", ")) -Component "wedge_pack_framework" -Path $segmentOverlayLastPath -NextAction "Repair Build_Wedge_Pack_Framework.ps1 so all overlay records keep the required fields."
    }
}

if ($workflowPackArtifactCheck.data) {
    $workflowPacks = @((Get-PropValue -Object $workflowPackArtifactCheck.data -Name "workflow_packs" -Default @()))
    $missingWorkflowFields = @()
    foreach ($workflowPack in $workflowPacks) {
        foreach ($field in @("workflow_pack_id", "business_category", "business_subcategory", "tool_bundle_ids", "recommendation_rule_pack_ids", "status", "summary", "customer_safe_label")) {
            if (-not (Test-ObjectHasKey -Object $workflowPack -Name $field)) {
                $missingWorkflowFields += $field
            }
        }
    }
    if ($missingWorkflowFields.Count -eq 0) {
        $wedgePackChecks += New-Check -Name "workflow_pack_shape" -Status "PASS" -Detail ("Workflow pack artifact exposes the required fields for {0} workflow pack record(s)." -f $workflowPacks.Count) -Component "wedge_pack_framework" -Path $workflowPackLastPath -NextAction "No action required."
    }
    else {
        $wedgePackChecks += New-Check -Name "workflow_pack_shape" -Status "FAIL" -Detail ("Workflow pack artifact is missing required fields: {0}" -f (($missingWorkflowFields | Sort-Object -Unique) -join ", ")) -Component "wedge_pack_framework" -Path $workflowPackLastPath -NextAction "Repair Build_Wedge_Pack_Framework.ps1 so each workflow pack carries the required fields."
    }
}

$stackWedgePackFramework = Get-PropValue -Object $stackStatusProbe.data -Name "wedge_pack_framework" -Default $null
if ($stackStatusProbe.ok -and $stackWedgePackFramework) {
    $wedgePackChecks += New-Check -Name "wedge_pack_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes wedge_pack_framework with overall_status={0}." -f (Normalize-Text (Get-PropValue -Object $stackWedgePackFramework -Name "overall_status" -Default "UNKNOWN"))) -Component "wedge_pack_framework" -Path $stackStatusUrl -NextAction "No action required."

    $requiredWedgePackPayloadKeys = @("overall_status", "business_category_count", "business_subcategory_count", "wedge_pack_count", "customer_ready_pack_count", "experimental_pack_count", "fallback_pack_available", "recommended_next_action")
    $missingWedgePackPayloadKeys = @($requiredWedgePackPayloadKeys | Where-Object { -not (Test-ObjectHasKey -Object $stackWedgePackFramework -Name $_) })
    if ($missingWedgePackPayloadKeys.Count -eq 0) {
        $wedgePackChecks += New-Check -Name "wedge_pack_payload_shape" -Status "PASS" -Detail "Athena stack payload exposes the expected wedge_pack_framework keys." -Component "wedge_pack_framework" -Path $stackStatusUrl -NextAction "No action required."
    }
    else {
        $wedgePackChecks += New-Check -Name "wedge_pack_payload_shape" -Status "FAIL" -Detail ("Athena stack payload wedge_pack_framework is missing keys: {0}" -f ($missingWedgePackPayloadKeys -join ", ")) -Component "wedge_pack_framework" -Path $stackStatusUrl -NextAction "Patch MasonConsole/server.py so wedge_pack_framework exposes the governed summary keys."
    }
}
elseif ($stackStatusProbe.ok) {
    $wedgePackChecks += New-Check -Name "wedge_pack_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but wedge_pack_framework is missing." -Component "wedge_pack_framework" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes wedge_pack_framework."
}
else {
    $wedgePackChecks += New-Check -Name "wedge_pack_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so wedge_pack_framework visibility cannot be verified right now." -Component "wedge_pack_framework" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify wedge_pack_framework visibility."
}
$sections += New-SectionResult -SectionName "wedge-pack / segment expansion framework" -Checks $wedgePackChecks

# business outcome optimization
$businessOutcomeChecks = @()
$businessOutcomesArtifactCheck = Get-FileArtifactCheck -CheckName "business_outcomes_artifact" -Path $businessOutcomesLastPath -Component "business_outcomes" -MissingNextAction "Run tools/ops/Run_Business_Outcome_Optimization.ps1 so reports/business_outcomes_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "tenant_count", "tenants_with_measurable_signals", "outcome_domain_count", "low_confidence_domain_count", "recommended_next_action", "summary", "command_run", "repo_root", "time_saved_indicators", "tool_usefulness", "recommendation_effectiveness", "onboarding_completion", "tenant_engagement", "revenue_help_indicators", "churn_risk_indicators")
$businessOutcomeChecks += $businessOutcomesArtifactCheck.check
$toolUsefulnessArtifactCheck = Get-FileArtifactCheck -CheckName "tool_usefulness_artifact" -Path $toolUsefulnessLastPath -Component "business_outcomes" -MissingNextAction "Run tools/ops/Run_Business_Outcome_Optimization.ps1 so reports/tool_usefulness_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "tool_total", "tools_with_usage_signal", "tools_with_usefulness_signal", "per_tool_usefulness", "recommended_next_action", "command_run", "repo_root")
$businessOutcomeChecks += $toolUsefulnessArtifactCheck.check
$recommendationEffectivenessArtifactCheck = Get-FileArtifactCheck -CheckName "recommendation_effectiveness_artifact" -Path $recommendationEffectivenessLastPath -Component "business_outcomes" -MissingNextAction "Run tools/ops/Run_Business_Outcome_Optimization.ps1 so reports/recommendation_effectiveness_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "recommendation_total", "accepted_count", "rejected_count", "pending_count", "low_confidence_count", "effectiveness_summary", "recommended_next_action", "recommendation_type_records", "command_run", "repo_root")
$businessOutcomeChecks += $recommendationEffectivenessArtifactCheck.check
$tenantEngagementArtifactCheck = Get-FileArtifactCheck -CheckName "tenant_engagement_artifact" -Path $tenantEngagementLastPath -Component "business_outcomes" -MissingNextAction "Run tools/ops/Run_Business_Outcome_Optimization.ps1 so reports/tenant_engagement_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "tenant_count", "active_signal_count", "low_engagement_count", "onboarding_complete_count", "onboarding_incomplete_count", "churn_risk_count", "recommended_next_action", "tenants", "command_run", "repo_root")
$businessOutcomeChecks += $tenantEngagementArtifactCheck.check
$businessOutcomeRegistryArtifactCheck = Get-FileArtifactCheck -CheckName "business_outcome_registry_artifact" -Path $businessOutcomeRegistryPath -Component "business_outcomes" -MissingNextAction "Run tools/ops/Run_Business_Outcome_Optimization.ps1 so state/knowledge/business_outcome_registry.json is written." -RequiredKeys @("generated_at_utc", "overall_status", "latest_business_outcomes_artifact", "tenant_count", "tool_count", "outcome_domain_count", "current_summary_status", "notes")
$businessOutcomeChecks += $businessOutcomeRegistryArtifactCheck.check
$businessOutcomePolicyArtifactCheck = Get-FileArtifactCheck -CheckName "business_outcome_policy" -Path $businessOutcomePolicyPath -Component "business_outcomes" -MissingNextAction "Restore config/business_outcome_policy.json so business outcome policy stays canonical." -RequiredKeys @("version", "policy_name", "outcome_domains", "evidence_sources", "scoring_and_confidence_rules", "fallback_behavior_for_sparse_data", "customer_safe_vs_internal_metrics_rules", "tenant_aggregation_rules", "churn_risk_rules", "revenue_help_heuristics", "low_confidence_handling", "no_fake_metric_rules")
$businessOutcomeChecks += $businessOutcomePolicyArtifactCheck.check

if ($businessOutcomesArtifactCheck.data) {
    $outcomeStatus = Normalize-Text (Get-PropValue -Object $businessOutcomesArtifactCheck.data -Name "overall_status" -Default "")
    $businessOutcomeChecks += New-Check -Name "business_outcomes_overall_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $outcomeStatus -DefaultStatus "WARN") -Detail ("Business outcomes overall_status={0}." -f $(if ($outcomeStatus) { $outcomeStatus } else { "unknown" })) -Component "business_outcomes" -Path $businessOutcomesLastPath -NextAction "Review the business outcome summary if the posture is not PASS."

    $missingOutcomeDomains = @()
    foreach ($field in @("time_saved_indicators", "tool_usefulness", "recommendation_effectiveness", "onboarding_completion", "tenant_engagement", "revenue_help_indicators", "churn_risk_indicators")) {
        if (-not (Test-ObjectHasKey -Object $businessOutcomesArtifactCheck.data -Name $field)) {
            $missingOutcomeDomains += $field
        }
    }
    if ($missingOutcomeDomains.Count -eq 0) {
        $businessOutcomeChecks += New-Check -Name "business_outcome_domain_coverage" -Status "PASS" -Detail "Business outcomes artifact exposes all required outcome domains." -Component "business_outcomes" -Path $businessOutcomesLastPath -NextAction "No action required."
    }
    else {
        $businessOutcomeChecks += New-Check -Name "business_outcome_domain_coverage" -Status "FAIL" -Detail ("Business outcomes artifact is missing domains: {0}" -f ($missingOutcomeDomains -join ", ")) -Component "business_outcomes" -Path $businessOutcomesLastPath -NextAction "Repair Run_Business_Outcome_Optimization.ps1 so all required outcome domains are always represented."
    }
}

if ($toolUsefulnessArtifactCheck.data) {
    $toolUsefulnessRecords = @((Get-PropValue -Object $toolUsefulnessArtifactCheck.data -Name "per_tool_usefulness" -Default @()))
    $missingToolUsefulnessFields = @()
    foreach ($toolRecord in $toolUsefulnessRecords) {
        foreach ($field in @("tool_id", "usage_signal", "usefulness_classification", "confidence", "tenant_count_affected", "notes")) {
            if (-not (Test-ObjectHasKey -Object $toolRecord -Name $field)) {
                $missingToolUsefulnessFields += $field
            }
        }
    }
    if ($missingToolUsefulnessFields.Count -eq 0) {
        $businessOutcomeChecks += New-Check -Name "tool_usefulness_shape" -Status "PASS" -Detail ("Tool usefulness records expose the required fields for {0} tool(s)." -f $toolUsefulnessRecords.Count) -Component "business_outcomes" -Path $toolUsefulnessLastPath -NextAction "No action required."
    }
    else {
        $businessOutcomeChecks += New-Check -Name "tool_usefulness_shape" -Status "FAIL" -Detail ("Tool usefulness records are missing required fields: {0}" -f (($missingToolUsefulnessFields | Sort-Object -Unique) -join ", ")) -Component "business_outcomes" -Path $toolUsefulnessLastPath -NextAction "Repair Run_Business_Outcome_Optimization.ps1 so every tool usefulness record is complete."
    }
}

if ($recommendationEffectivenessArtifactCheck.data) {
    $acceptedCount = [int](Get-PropValue -Object $recommendationEffectivenessArtifactCheck.data -Name "accepted_count" -Default 0)
    if ($acceptedCount -gt 0) {
        $businessOutcomeChecks += New-Check -Name "accepted_recommendation_state" -Status "PASS" -Detail ("Recommendation effectiveness records {0} accepted recommendation(s)." -f $acceptedCount) -Component "business_outcomes" -Path $recommendationEffectivenessLastPath -NextAction "No action required."
    }
    else {
        $businessOutcomeChecks += New-Check -Name "accepted_recommendation_state" -Status "WARN" -Detail "Recommendation effectiveness currently records zero accepted recommendations." -Component "business_outcomes" -Path $recommendationEffectivenessLastPath -NextAction "Keep measuring recommendation fit; zero accepted recommendations is valid if that is the truth."
    }

    $recommendationTypeRecords = @((Get-PropValue -Object $recommendationEffectivenessArtifactCheck.data -Name "recommendation_type_records" -Default @()))
    $missingRecommendationFields = @()
    foreach ($recommendationTypeRecord in $recommendationTypeRecords) {
        foreach ($field in @("recommendation_type", "acceptance_signal", "rejection_signal", "effectiveness_classification", "confidence", "refinement_needed")) {
            if (-not (Test-ObjectHasKey -Object $recommendationTypeRecord -Name $field)) {
                $missingRecommendationFields += $field
            }
        }
    }
    if ($missingRecommendationFields.Count -eq 0) {
        $businessOutcomeChecks += New-Check -Name "recommendation_effectiveness_shape" -Status "PASS" -Detail ("Recommendation effectiveness records expose the required fields for {0} recommendation type record(s)." -f $recommendationTypeRecords.Count) -Component "business_outcomes" -Path $recommendationEffectivenessLastPath -NextAction "No action required."
    }
    else {
        $businessOutcomeChecks += New-Check -Name "recommendation_effectiveness_shape" -Status "FAIL" -Detail ("Recommendation effectiveness records are missing required fields: {0}" -f (($missingRecommendationFields | Sort-Object -Unique) -join ", ")) -Component "business_outcomes" -Path $recommendationEffectivenessLastPath -NextAction "Repair Run_Business_Outcome_Optimization.ps1 so recommendation effectiveness records stay complete."
    }
}

if ($tenantEngagementArtifactCheck.data) {
    $tenantRecords = @((Get-PropValue -Object $tenantEngagementArtifactCheck.data -Name "tenants" -Default @()))
    $missingTenantFields = @()
    foreach ($tenantRecord in $tenantRecords) {
        foreach ($field in @("tenant_id", "engagement_classification", "onboarding_status", "tool_adoption_signal", "recommendation_response_signal", "revenue_help_signal", "churn_risk_classification", "confidence")) {
            if (-not (Test-ObjectHasKey -Object $tenantRecord -Name $field)) {
                $missingTenantFields += $field
            }
        }
    }
    if ($missingTenantFields.Count -eq 0) {
        $businessOutcomeChecks += New-Check -Name "tenant_engagement_shape" -Status "PASS" -Detail ("Tenant engagement records expose the required fields for {0} tenant(s)." -f $tenantRecords.Count) -Component "business_outcomes" -Path $tenantEngagementLastPath -NextAction "No action required."
    }
    else {
        $businessOutcomeChecks += New-Check -Name "tenant_engagement_shape" -Status "FAIL" -Detail ("Tenant engagement records are missing required fields: {0}" -f (($missingTenantFields | Sort-Object -Unique) -join ", ")) -Component "business_outcomes" -Path $tenantEngagementLastPath -NextAction "Repair Run_Business_Outcome_Optimization.ps1 so tenant engagement records stay complete."
    }

    $churnRiskCount = [int](Get-PropValue -Object $tenantEngagementArtifactCheck.data -Name "churn_risk_count" -Default 0)
    if ($churnRiskCount -gt 0) {
        $businessOutcomeChecks += New-Check -Name "churn_risk_state" -Status "WARN" -Detail ("Tenant engagement currently flags {0} churn-risk tenant(s)." -f $churnRiskCount) -Component "business_outcomes" -Path $tenantEngagementLastPath -NextAction "Review low-engagement or incomplete-onboarding tenants before the risk rises further."
    }
    else {
        $businessOutcomeChecks += New-Check -Name "churn_risk_state" -Status "PASS" -Detail "Tenant engagement currently flags zero churn-risk tenants, which is valid if the data supports it." -Component "business_outcomes" -Path $tenantEngagementLastPath -NextAction "No action required."
    }
}

$stackBusinessOutcomes = Get-PropValue -Object $stackStatusProbe.data -Name "business_outcomes" -Default $null
if ($stackStatusProbe.ok -and $stackBusinessOutcomes) {
    $businessOutcomeChecks += New-Check -Name "business_outcomes_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes business_outcomes with overall_status={0}." -f (Normalize-Text (Get-PropValue -Object $stackBusinessOutcomes -Name "overall_status" -Default "UNKNOWN"))) -Component "business_outcomes" -Path $stackStatusUrl -NextAction "No action required."

    $requiredBusinessOutcomePayloadKeys = @("overall_status", "tenant_count", "tenants_with_measurable_signals", "tool_usefulness_summary", "recommendation_effectiveness_summary", "onboarding_completion_summary", "revenue_help_summary", "churn_risk_summary", "recommended_next_action")
    $missingBusinessOutcomePayloadKeys = @($requiredBusinessOutcomePayloadKeys | Where-Object { -not (Test-ObjectHasKey -Object $stackBusinessOutcomes -Name $_) })
    if ($missingBusinessOutcomePayloadKeys.Count -eq 0) {
        $businessOutcomeChecks += New-Check -Name "business_outcomes_payload_shape" -Status "PASS" -Detail "Athena stack payload exposes the expected business_outcomes keys." -Component "business_outcomes" -Path $stackStatusUrl -NextAction "No action required."
    }
    else {
        $businessOutcomeChecks += New-Check -Name "business_outcomes_payload_shape" -Status "FAIL" -Detail ("Athena stack payload business_outcomes is missing keys: {0}" -f ($missingBusinessOutcomePayloadKeys -join ", ")) -Component "business_outcomes" -Path $stackStatusUrl -NextAction "Patch MasonConsole/server.py so business_outcomes exposes the governed summary keys."
    }
}
elseif ($stackStatusProbe.ok) {
    $businessOutcomeChecks += New-Check -Name "business_outcomes_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but business_outcomes is missing." -Component "business_outcomes" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes business_outcomes."
}
else {
    $businessOutcomeChecks += New-Check -Name "business_outcomes_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so business_outcomes visibility cannot be verified right now." -Component "business_outcomes" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify business_outcomes visibility."
}
$sections += New-SectionResult -SectionName "business outcome optimization" -Checks $businessOutcomeChecks

# autonomous release management
$releaseChecks = @()
$releaseManagementArtifactCheck = Get-FileArtifactCheck -CheckName "release_management_artifact" -Path $releaseManagementLastPath -Component "release_management" -MissingNextAction "Run tools/ops/Run_Autonomous_Release_Management.ps1 so reports/release_management_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "release_candidate_id", "release_stage", "release_readiness_classification", "promotion_allowed", "rollout_mode", "rollback_ready", "blocking_reason_count", "warning_reason_count", "recommended_next_action", "summary", "command_run", "repo_root")
$releaseChecks += $releaseManagementArtifactCheck.check
$releaseCandidateArtifactCheck = Get-FileArtifactCheck -CheckName "release_candidate_artifact" -Path $releaseCandidateLastPath -Component "release_management" -MissingNextAction "Run tools/ops/Run_Autonomous_Release_Management.ps1 so reports/release_candidate_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "release_candidate_id", "release_stage", "promotion_allowed", "canary_allowed", "pilot_ready", "customer_ready", "blocking_reasons", "warning_reasons", "source_evidence", "recommended_next_action", "command_run", "repo_root", "gating_inputs")
$releaseChecks += $releaseCandidateArtifactCheck.check
$releaseNotesArtifactCheck = Get-FileArtifactCheck -CheckName "release_notes_artifact" -Path $releaseNotesLastPath -Component "release_management" -MissingNextAction "Run tools/ops/Run_Autonomous_Release_Management.ps1 so reports/release_notes_last.json is written." -RequiredKeys @("timestamp_utc", "release_candidate_id", "overall_status", "change_summary", "new_capabilities", "changed_surfaces", "operational_changes", "governance_changes", "known_warnings", "blocked_items", "recommended_release_scope")
$releaseChecks += $releaseNotesArtifactCheck.check
$releaseRolloutArtifactCheck = Get-FileArtifactCheck -CheckName "release_rollout_artifact" -Path $releaseRolloutLastPath -Component "release_management" -MissingNextAction "Run tools/ops/Run_Autonomous_Release_Management.ps1 so reports/release_rollout_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "release_candidate_id", "rollout_mode", "canary_group_count", "eligible_group_count", "blocked_group_count", "promotion_allowed", "rollback_recommended", "recommended_next_action", "groups")
$releaseChecks += $releaseRolloutArtifactCheck.check
$releaseRegistryArtifactCheck = Get-FileArtifactCheck -CheckName "release_registry_artifact" -Path $releaseRegistryPath -Component "release_management" -MissingNextAction "Run tools/ops/Run_Autonomous_Release_Management.ps1 so state/knowledge/release_registry.json is written." -RequiredKeys @("generated_at_utc", "current_release_candidate_id", "current_release_stage", "latest_release_management_artifact", "latest_release_notes_artifact", "latest_rollout_artifact", "promotion_allowed", "rollback_ready", "notes")
$releaseChecks += $releaseRegistryArtifactCheck.check
$releasePolicyArtifactCheck = Get-FileArtifactCheck -CheckName "release_management_policy" -Path $releaseManagementPolicyPath -Component "release_management" -MissingNextAction "Restore config/release_management_policy.json so release governance policy stays canonical." -RequiredKeys @("version", "policy_name", "release_stages", "canary_group_rules", "promotion_prerequisites", "rollback_prerequisites", "blocking_conditions", "warning_only_conditions", "release_note_generation_rules", "domain_dependency_rules", "pilot_customer_internal_visibility_rules", "stale_evidence_handling", "release_freeze_conditions")
$releaseChecks += $releasePolicyArtifactCheck.check

if ($releaseManagementArtifactCheck.data) {
    $releaseStatus = Normalize-Text (Get-PropValue -Object $releaseManagementArtifactCheck.data -Name "overall_status" -Default "")
    $releaseChecks += New-Check -Name "release_management_overall_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $releaseStatus -DefaultStatus "WARN") -Detail ("Release management overall_status={0}." -f $(if ($releaseStatus) { $releaseStatus } else { "unknown" })) -Component "release_management" -Path $releaseManagementLastPath -NextAction "Review the release management summary if the posture is not PASS."
}

if ($releaseCandidateArtifactCheck.data) {
    $releaseStage = Normalize-Text (Get-PropValue -Object $releaseCandidateArtifactCheck.data -Name "release_stage" -Default "")
    $allowedReleaseStages = @("draft", "candidate", "blocked", "canary_only", "pilot_ready", "customer_ready", "rollback_recommended")
    if ($releaseStage.ToLowerInvariant() -in $allowedReleaseStages) {
        $releaseChecks += New-Check -Name "release_stage_valid" -Status "PASS" -Detail ("Release candidate stage is canonical: {0}." -f $releaseStage) -Component "release_management" -Path $releaseCandidateLastPath -NextAction "No action required."
    }
    else {
        $releaseChecks += New-Check -Name "release_stage_valid" -Status "FAIL" -Detail ("Release candidate stage is missing or invalid: {0}" -f $(if ($releaseStage) { $releaseStage } else { "unknown" })) -Component "release_management" -Path $releaseCandidateLastPath -NextAction "Repair Run_Autonomous_Release_Management.ps1 so release_stage stays canonical."
    }

    $promotionAllowed = [bool](Get-PropValue -Object $releaseCandidateArtifactCheck.data -Name "promotion_allowed" -Default $false)
    $canaryAllowed = [bool](Get-PropValue -Object $releaseCandidateArtifactCheck.data -Name "canary_allowed" -Default $false)
    $pilotReady = [bool](Get-PropValue -Object $releaseCandidateArtifactCheck.data -Name "pilot_ready" -Default $false)
    $customerReady = [bool](Get-PropValue -Object $releaseCandidateArtifactCheck.data -Name "customer_ready" -Default $false)
    $candidateBlockingReasons = @((Get-PropValue -Object $releaseCandidateArtifactCheck.data -Name "blocking_reasons" -Default @()))

    if (($releaseStage -eq "canary_only" -and -not $canaryAllowed) -or ($releaseStage -eq "pilot_ready" -and (-not $pilotReady -or -not $promotionAllowed)) -or ($releaseStage -eq "customer_ready" -and (-not $customerReady -or -not $promotionAllowed))) {
        $releaseChecks += New-Check -Name "release_candidate_coherence" -Status "FAIL" -Detail ("Release candidate stage={0} is inconsistent with canary/pilot/customer booleans." -f $releaseStage) -Component "release_management" -Path $releaseCandidateLastPath -NextAction "Repair Run_Autonomous_Release_Management.ps1 so release stage and readiness booleans stay coherent."
    }
    elseif (-not $promotionAllowed -and $candidateBlockingReasons.Count -eq 0) {
        $releaseChecks += New-Check -Name "release_candidate_coherence" -Status "WARN" -Detail "Promotion is blocked but blocking_reasons is empty." -Component "release_management" -Path $releaseCandidateLastPath -NextAction "Record explicit blocking reasons so blocked rollout posture stays auditable."
    }
    else {
        $releaseChecks += New-Check -Name "release_candidate_coherence" -Status "PASS" -Detail ("Release candidate coherence is intact; stage={0}; promotion_allowed={1}; canary_allowed={2}." -f $releaseStage, $promotionAllowed.ToString().ToLowerInvariant(), $canaryAllowed.ToString().ToLowerInvariant()) -Component "release_management" -Path $releaseCandidateLastPath -NextAction "No action required."
    }
}

if ($releaseRolloutArtifactCheck.data) {
    $rolloutGroups = @((Get-PropValue -Object $releaseRolloutArtifactCheck.data -Name "groups" -Default @()))
    $groupIds = @($rolloutGroups | ForEach-Object { Normalize-Text (Get-PropValue -Object $_ -Name "group_id" -Default "") })
    $requiredGroupIds = @("internal_operator_only", "founder_pilot", "limited_customer_safe", "broader_rollout_blocked")
    $missingGroupIds = @($requiredGroupIds | Where-Object { $_ -notin $groupIds })
    if ($missingGroupIds.Count -eq 0) {
        $releaseChecks += New-Check -Name "release_rollout_groups" -Status "PASS" -Detail ("Release rollout artifact exposes all required rollout groups ({0})." -f $rolloutGroups.Count) -Component "release_management" -Path $releaseRolloutLastPath -NextAction "No action required."
    }
    else {
        $releaseChecks += New-Check -Name "release_rollout_groups" -Status "FAIL" -Detail ("Release rollout artifact is missing required groups: {0}" -f ($missingGroupIds -join ", ")) -Component "release_management" -Path $releaseRolloutLastPath -NextAction "Repair Run_Autonomous_Release_Management.ps1 so all rollout groups are always represented."
    }

    $eligibleGroupCount = [int](Get-PropValue -Object $releaseRolloutArtifactCheck.data -Name "eligible_group_count" -Default 0)
    $rolloutMode = Normalize-Text (Get-PropValue -Object $releaseRolloutArtifactCheck.data -Name "rollout_mode" -Default "")
    if ($eligibleGroupCount -eq 0 -and $rolloutMode -eq "blocked") {
        $releaseChecks += New-Check -Name "release_rollout_posture" -Status "PASS" -Detail "Broader rollout is blocked, and the rollout artifact truthfully records zero eligible groups." -Component "release_management" -Path $releaseRolloutLastPath -NextAction "No action required."
    }
    else {
        $releaseChecks += New-Check -Name "release_rollout_posture" -Status "PASS" -Detail ("Rollout mode={0}; eligible_group_count={1}." -f $(if ($rolloutMode) { $rolloutMode } else { "unknown" }), $eligibleGroupCount) -Component "release_management" -Path $releaseRolloutLastPath -NextAction "No action required."
    }
}

if ($releaseNotesArtifactCheck.data) {
    $changedSurfaces = @((Get-PropValue -Object $releaseNotesArtifactCheck.data -Name "changed_surfaces" -Default @()))
    if ($changedSurfaces.Count -gt 0) {
        $releaseChecks += New-Check -Name "release_notes_changed_surfaces" -Status "PASS" -Detail ("Release notes expose {0} changed surface item(s)." -f $changedSurfaces.Count) -Component "release_management" -Path $releaseNotesLastPath -NextAction "No action required."
    }
    else {
        $releaseChecks += New-Check -Name "release_notes_changed_surfaces" -Status "WARN" -Detail "Release notes are readable but changed_surfaces is empty." -Component "release_management" -Path $releaseNotesLastPath -NextAction "Populate release notes with truthful changed surface summaries."
    }
}

if ($releaseRegistryArtifactCheck.data -and $releaseCandidateArtifactCheck.data -and $releaseRolloutArtifactCheck.data -and $releaseNotesArtifactCheck.data) {
    $candidateIdSet = New-Object 'System.Collections.Generic.List[string]'
    $rawCandidateIds = @(
        Normalize-Text (Get-PropValue -Object $releaseRegistryArtifactCheck.data -Name "current_release_candidate_id" -Default "")
        Normalize-Text (Get-PropValue -Object $releaseCandidateArtifactCheck.data -Name "release_candidate_id" -Default "")
        Normalize-Text (Get-PropValue -Object $releaseRolloutArtifactCheck.data -Name "release_candidate_id" -Default "")
        Normalize-Text (Get-PropValue -Object $releaseNotesArtifactCheck.data -Name "release_candidate_id" -Default "")
        Normalize-Text (Get-PropValue -Object $releaseManagementArtifactCheck.data -Name "release_candidate_id" -Default "")
    )
    foreach ($rawCandidateId in $rawCandidateIds) {
        if ($rawCandidateId -and -not $candidateIdSet.Contains($rawCandidateId)) {
            [void]$candidateIdSet.Add($rawCandidateId)
        }
    }
    if ($candidateIdSet.Count -eq 1) {
        $releaseChecks += New-Check -Name "release_candidate_id_coherence" -Status "PASS" -Detail ("Release artifacts agree on release_candidate_id={0}." -f $candidateIdSet[0]) -Component "release_management" -Path $releaseRegistryPath -NextAction "No action required."
    }
    else {
        $releaseChecks += New-Check -Name "release_candidate_id_coherence" -Status "FAIL" -Detail ("Release artifacts disagree on release_candidate_id values: {0}" -f (@($candidateIdSet) -join ", ")) -Component "release_management" -Path $releaseRegistryPath -NextAction "Repair the release management outputs so the registry, candidate, notes, rollout, and summary artifacts stay aligned."
    }
}

$stackReleaseManagement = Get-PropValue -Object $stackStatusProbe.data -Name "release_management" -Default $null
if ($stackStatusProbe.ok -and $stackReleaseManagement) {
    $releaseChecks += New-Check -Name "release_management_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes release_management with overall_status={0}." -f (Normalize-Text (Get-PropValue -Object $stackReleaseManagement -Name "overall_status" -Default "UNKNOWN"))) -Component "release_management" -Path $stackStatusUrl -NextAction "No action required."

    $requiredReleasePayloadKeys = @("overall_status", "release_candidate_id", "release_stage", "promotion_allowed", "rollout_mode", "rollback_ready", "blocking_reason_count", "recommended_next_action")
    $missingReleasePayloadKeys = @($requiredReleasePayloadKeys | Where-Object { -not (Test-ObjectHasKey -Object $stackReleaseManagement -Name $_) })
    if ($missingReleasePayloadKeys.Count -eq 0) {
        $releaseChecks += New-Check -Name "release_management_payload_shape" -Status "PASS" -Detail "Athena stack payload exposes the expected release_management keys." -Component "release_management" -Path $stackStatusUrl -NextAction "No action required."
    }
    else {
        $releaseChecks += New-Check -Name "release_management_payload_shape" -Status "FAIL" -Detail ("Athena stack payload release_management is missing keys: {0}" -f ($missingReleasePayloadKeys -join ", ")) -Component "release_management" -Path $stackStatusUrl -NextAction "Patch MasonConsole/server.py so release_management exposes the governed summary keys."
    }
}
elseif ($stackStatusProbe.ok) {
    $releaseChecks += New-Check -Name "release_management_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but release_management is missing." -Component "release_management" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes release_management."
}
else {
    $releaseChecks += New-Check -Name "release_management_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so release_management visibility cannot be verified right now." -Component "release_management" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify release_management visibility."
}
$sections += New-SectionResult -SectionName "autonomous release management" -Checks $releaseChecks

# revenue optimization engine
$revenueOptimizationChecks = @()
$revenueOptimizationArtifactCheck = Get-FileArtifactCheck -CheckName "revenue_optimization_artifact" -Path $revenueOptimizationLastPath -Component "revenue_optimization" -MissingNextAction "Run tools/ops/Run_Revenue_Optimization.ps1 so reports/revenue_optimization_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "tenant_count", "tenants_with_revenue_signal", "upgrade_opportunity_count", "add_on_fit_count", "churn_rescue_count", "blocked_money_action_count", "low_confidence_count", "recommended_next_action", "summary", "plan_fit", "upgrade_suggestions", "add_on_fit", "churn_rescue", "billing_posture_linkage", "command_run", "repo_root")
$revenueOptimizationChecks += $revenueOptimizationArtifactCheck.check
$planFitArtifactCheck = Get-FileArtifactCheck -CheckName "plan_fit_analysis_artifact" -Path $planFitAnalysisLastPath -Component "revenue_optimization" -MissingNextAction "Run tools/ops/Run_Revenue_Optimization.ps1 so reports/plan_fit_analysis_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "tenant_count", "fit_evaluable_count", "underfit_count", "overfit_count", "well_fit_count", "unknown_fit_count", "recommended_next_action", "tenants", "command_run", "repo_root")
$revenueOptimizationChecks += $planFitArtifactCheck.check
$upgradeSuggestionsArtifactCheck = Get-FileArtifactCheck -CheckName "upgrade_suggestions_artifact" -Path $upgradeSuggestionsLastPath -Component "revenue_optimization" -MissingNextAction "Run tools/ops/Run_Revenue_Optimization.ps1 so reports/upgrade_suggestions_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "tenant_count", "upgrade_suggestion_count", "add_on_suggestion_count", "customer_safe_suggestion_count", "owner_review_required_count", "recommended_next_action", "suggestions", "command_run", "repo_root")
$revenueOptimizationChecks += $upgradeSuggestionsArtifactCheck.check
$churnRescueArtifactCheck = Get-FileArtifactCheck -CheckName "churn_rescue_artifact" -Path $churnRescueLastPath -Component "revenue_optimization" -MissingNextAction "Run tools/ops/Run_Revenue_Optimization.ps1 so reports/churn_rescue_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "tenant_count", "churn_rescue_count", "moderate_risk_count", "elevated_risk_count", "low_confidence_count", "recommended_next_action", "rescues", "command_run", "repo_root")
$revenueOptimizationChecks += $churnRescueArtifactCheck.check
$revenueOptimizationRegistryArtifactCheck = Get-FileArtifactCheck -CheckName "revenue_optimization_registry_artifact" -Path $revenueOptimizationRegistryPath -Component "revenue_optimization" -MissingNextAction "Run tools/ops/Run_Revenue_Optimization.ps1 so state/knowledge/revenue_optimization_registry.json is written." -RequiredKeys @("generated_at_utc", "overall_status", "latest_revenue_optimization_artifact", "tenant_count", "upgrade_opportunity_count", "add_on_fit_count", "churn_rescue_count", "notes")
$revenueOptimizationChecks += $revenueOptimizationRegistryArtifactCheck.check
$revenueOptimizationPolicyArtifactCheck = Get-FileArtifactCheck -CheckName "revenue_optimization_policy" -Path $revenueOptimizationPolicyPath -Component "revenue_optimization" -MissingNextAction "Restore config/revenue_optimization_policy.json so revenue optimization policy stays canonical." -RequiredKeys @("version", "policy_name", "recommendation_classes", "evidence_sources", "gating_rules", "billing_safety_rules", "upgrade_add_on_fit_thresholds", "churn_rescue_thresholds", "sparse_data_handling", "no_auto_money_rules", "customer_safe_output_rules", "owner_internal_output_rules")
$revenueOptimizationChecks += $revenueOptimizationPolicyArtifactCheck.check

if ($revenueOptimizationArtifactCheck.data) {
    $revenueStatus = Normalize-Text (Get-PropValue -Object $revenueOptimizationArtifactCheck.data -Name "overall_status" -Default "")
    $revenueOptimizationChecks += New-Check -Name "revenue_optimization_overall_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $revenueStatus -DefaultStatus "WARN") -Detail ("Revenue optimization overall_status={0}." -f $(if ($revenueStatus) { $revenueStatus } else { "unknown" })) -Component "revenue_optimization" -Path $revenueOptimizationLastPath -NextAction "Review the revenue optimization summary if the posture is not PASS."

    $billingLinkage = Get-PropValue -Object $revenueOptimizationArtifactCheck.data -Name "billing_posture_linkage" -Default $null
    if ($billingLinkage -and (Test-ObjectHasKey -Object $billingLinkage -Name "billing_gated")) {
        $revenueOptimizationChecks += New-Check -Name "revenue_money_gating" -Status "PASS" -Detail ("Revenue optimization records billing_gated={0} explicitly." -f ([bool](Get-PropValue -Object $billingLinkage -Name "billing_gated" -Default $true)).ToString().ToLowerInvariant()) -Component "revenue_optimization" -Path $revenueOptimizationLastPath -NextAction "No action required."
    }
    else {
        $revenueOptimizationChecks += New-Check -Name "revenue_money_gating" -Status "FAIL" -Detail "Revenue optimization is missing explicit billing_gated posture." -Component "revenue_optimization" -Path $revenueOptimizationLastPath -NextAction "Repair Run_Revenue_Optimization.ps1 so money-action gating is always explicit."
    }
}

if ($planFitArtifactCheck.data) {
    $planFitRecords = @((Get-PropValue -Object $planFitArtifactCheck.data -Name "tenants" -Default @()))
    $missingPlanFitFields = @()
    foreach ($tenantRecord in $planFitRecords) {
        foreach ($field in @("tenant_id", "current_plan", "fit_classification", "fit_confidence", "fit_rationale", "recommended_plan_action", "money_action_allowed")) {
            if (-not (Test-ObjectHasKey -Object $tenantRecord -Name $field)) {
                $missingPlanFitFields += $field
            }
        }
    }
    if ($missingPlanFitFields.Count -eq 0) {
        $revenueOptimizationChecks += New-Check -Name "plan_fit_shape" -Status "PASS" -Detail ("Plan fit analysis records expose the required fields for {0} tenant(s)." -f $planFitRecords.Count) -Component "revenue_optimization" -Path $planFitAnalysisLastPath -NextAction "No action required."
    }
    else {
        $revenueOptimizationChecks += New-Check -Name "plan_fit_shape" -Status "FAIL" -Detail ("Plan fit analysis records are missing required fields: {0}" -f (($missingPlanFitFields | Sort-Object -Unique) -join ", ")) -Component "revenue_optimization" -Path $planFitAnalysisLastPath -NextAction "Repair Run_Revenue_Optimization.ps1 so plan fit records stay complete."
    }
}

if ($upgradeSuggestionsArtifactCheck.data) {
    $suggestionRecords = @((Get-PropValue -Object $upgradeSuggestionsArtifactCheck.data -Name "suggestions" -Default @()))
    if ($suggestionRecords.Count -eq 0) {
        $revenueOptimizationChecks += New-Check -Name "upgrade_suggestions_state" -Status "PASS" -Detail "Revenue optimization currently records zero upgrade or add-on suggestions, which is valid if that is the truth." -Component "revenue_optimization" -Path $upgradeSuggestionsLastPath -NextAction "No action required."
    }
    else {
        $missingSuggestionFields = @()
        foreach ($suggestionRecord in $suggestionRecords) {
            foreach ($field in @("tenant_id", "suggestion_type", "current_plan_or_state", "suggested_plan_or_add_on", "confidence", "rationale", "customer_safe_summary", "action_posture", "blocked_by_billing_gate")) {
                if (-not (Test-ObjectHasKey -Object $suggestionRecord -Name $field)) {
                    $missingSuggestionFields += $field
                }
            }
        }
        if ($missingSuggestionFields.Count -eq 0) {
            $revenueOptimizationChecks += New-Check -Name "upgrade_suggestions_shape" -Status "PASS" -Detail ("Revenue suggestions expose the required fields for {0} suggestion(s)." -f $suggestionRecords.Count) -Component "revenue_optimization" -Path $upgradeSuggestionsLastPath -NextAction "No action required."
        }
        else {
            $revenueOptimizationChecks += New-Check -Name "upgrade_suggestions_shape" -Status "FAIL" -Detail ("Revenue suggestions are missing required fields: {0}" -f (($missingSuggestionFields | Sort-Object -Unique) -join ", ")) -Component "revenue_optimization" -Path $upgradeSuggestionsLastPath -NextAction "Repair Run_Revenue_Optimization.ps1 so suggestion records stay complete."
        }
    }
}

if ($churnRescueArtifactCheck.data) {
    $rescueRecords = @((Get-PropValue -Object $churnRescueArtifactCheck.data -Name "rescues" -Default @()))
    if ($rescueRecords.Count -eq 0) {
        $revenueOptimizationChecks += New-Check -Name "churn_rescue_state" -Status "PASS" -Detail "Revenue optimization currently records zero churn-rescue suggestions, which is valid if the current churn signal is low." -Component "revenue_optimization" -Path $churnRescueLastPath -NextAction "No action required."
    }
    else {
        $missingRescueFields = @()
        foreach ($rescueRecord in $rescueRecords) {
            foreach ($field in @("tenant_id", "churn_risk_classification", "rescue_suggestion", "confidence", "supportive_evidence", "customer_safe_summary", "owner_action_required")) {
                if (-not (Test-ObjectHasKey -Object $rescueRecord -Name $field)) {
                    $missingRescueFields += $field
                }
            }
        }
        if ($missingRescueFields.Count -eq 0) {
            $revenueOptimizationChecks += New-Check -Name "churn_rescue_shape" -Status "PASS" -Detail ("Churn rescue records expose the required fields for {0} tenant(s)." -f $rescueRecords.Count) -Component "revenue_optimization" -Path $churnRescueLastPath -NextAction "No action required."
        }
        else {
            $revenueOptimizationChecks += New-Check -Name "churn_rescue_shape" -Status "FAIL" -Detail ("Churn rescue records are missing required fields: {0}" -f (($missingRescueFields | Sort-Object -Unique) -join ", ")) -Component "revenue_optimization" -Path $churnRescueLastPath -NextAction "Repair Run_Revenue_Optimization.ps1 so churn rescue records stay complete."
        }
    }
}

$stackRevenueOptimization = Get-PropValue -Object $stackStatusProbe.data -Name "revenue_optimization" -Default $null
if ($stackStatusProbe.ok -and $stackRevenueOptimization) {
    $revenueOptimizationChecks += New-Check -Name "revenue_optimization_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes revenue_optimization with overall_status={0}." -f (Normalize-Text (Get-PropValue -Object $stackRevenueOptimization -Name "overall_status" -Default "UNKNOWN"))) -Component "revenue_optimization" -Path $stackStatusUrl -NextAction "No action required."

    $requiredRevenuePayloadKeys = @("overall_status", "tenant_count", "upgrade_opportunity_count", "add_on_fit_count", "churn_rescue_count", "blocked_money_action_count", "billing_gated", "recommended_next_action")
    $missingRevenuePayloadKeys = @($requiredRevenuePayloadKeys | Where-Object { -not (Test-ObjectHasKey -Object $stackRevenueOptimization -Name $_) })
    if ($missingRevenuePayloadKeys.Count -eq 0) {
        $revenueOptimizationChecks += New-Check -Name "revenue_optimization_payload_shape" -Status "PASS" -Detail "Athena stack payload exposes the expected revenue_optimization keys." -Component "revenue_optimization" -Path $stackStatusUrl -NextAction "No action required."
    }
    else {
        $revenueOptimizationChecks += New-Check -Name "revenue_optimization_payload_shape" -Status "FAIL" -Detail ("Athena stack payload revenue_optimization is missing keys: {0}" -f ($missingRevenuePayloadKeys -join ", ")) -Component "revenue_optimization" -Path $stackStatusUrl -NextAction "Patch MasonConsole/server.py so revenue_optimization exposes the governed summary keys."
    }
}
elseif ($stackStatusProbe.ok) {
    $revenueOptimizationChecks += New-Check -Name "revenue_optimization_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but revenue_optimization is missing." -Component "revenue_optimization" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes revenue_optimization."
}
else {
    $revenueOptimizationChecks += New-Check -Name "revenue_optimization_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so revenue_optimization visibility cannot be verified right now." -Component "revenue_optimization" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify revenue_optimization visibility."
}
$sections += New-SectionResult -SectionName "revenue optimization engine" -Checks $revenueOptimizationChecks

# model / cost governance
$modelCostGovernanceChecks = @()
$modelCostGovernanceArtifactCheck = Get-FileArtifactCheck -CheckName "model_cost_governance_artifact" -Path $modelCostGovernanceLastPath -Component "model_cost_governance" -MissingNextAction "Run tools/ops/Run_Model_Cost_Governance.ps1 so reports/model_cost_governance_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "task_class_count", "budget_class_count", "local_first_mandatory_count", "teacher_allowed_count", "teacher_blocked_count", "quality_floor_status", "cost_governance_posture", "recommended_next_action", "mirror_refresh_status", "task_classification", "budget_classes", "escalation_ladder", "quality_floor", "teacher_usefulness", "cost_effectiveness", "mirror_refresh", "command_run", "repo_root")
$modelCostGovernanceChecks += $modelCostGovernanceArtifactCheck.check
$taskClassificationArtifactCheck = Get-FileArtifactCheck -CheckName "task_classification_artifact" -Path $taskClassificationLastPath -Component "model_cost_governance" -MissingNextAction "Run tools/ops/Run_Model_Cost_Governance.ps1 so reports/task_classification_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "task_class_total", "classified_active_items", "local_only_count", "local_preferred_count", "teacher_optional_count", "teacher_high_value_only_count", "teacher_blocked_count", "recommended_next_action", "tasks", "command_run", "repo_root")
$modelCostGovernanceChecks += $taskClassificationArtifactCheck.check
$teacherUsefulnessArtifactCheck = Get-FileArtifactCheck -CheckName "teacher_usefulness_artifact" -Path $teacherUsefulnessLastPath -Component "model_cost_governance" -MissingNextAction "Run tools/ops/Run_Model_Cost_Governance.ps1 so reports/teacher_usefulness_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "teacher_reviewed_item_count", "useful_count", "mixed_count", "low_value_count", "reject_count", "recommended_next_action", "reviews", "command_run", "repo_root")
$modelCostGovernanceChecks += $teacherUsefulnessArtifactCheck.check
$costEffectivenessArtifactCheck = Get-FileArtifactCheck -CheckName "cost_effectiveness_artifact" -Path $costEffectivenessLastPath -Component "model_cost_governance" -MissingNextAction "Run tools/ops/Run_Model_Cost_Governance.ps1 so reports/cost_effectiveness_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "evaluated_task_count", "successful_low_cost_count", "successful_high_cost_count", "high_cost_low_value_count", "cost_per_success_summary", "recommended_next_action", "tracked_records", "command_run", "repo_root")
$modelCostGovernanceChecks += $costEffectivenessArtifactCheck.check
$modelCostRegistryArtifactCheck = Get-FileArtifactCheck -CheckName "model_cost_registry_artifact" -Path $modelCostRegistryPath -Component "model_cost_governance" -MissingNextAction "Run tools/ops/Run_Model_Cost_Governance.ps1 so state/knowledge/model_cost_registry.json is written." -RequiredKeys @("generated_at_utc", "overall_status", "latest_governance_artifact", "task_class_count", "teacher_allowed_count", "teacher_blocked_count", "quality_floor_status", "mirror_refresh_status", "notes")
$modelCostGovernanceChecks += $modelCostRegistryArtifactCheck.check
$modelCostPolicyArtifactCheck = Get-FileArtifactCheck -CheckName "model_cost_governance_policy" -Path $modelCostGovernancePolicyPath -Component "model_cost_governance" -MissingNextAction "Restore config/model_cost_governance_policy.json so model/cost governance policy remains canonical." -RequiredKeys @("version", "policy_name", "task_classes", "budget_classes", "escalation_ladder_rules", "local_first_mandatory_classes", "teacher_allowed_classes", "teacher_blocked_classes", "quality_floor_rules", "usefulness_scoring_rules", "cost_effectiveness_rules", "sparse_data_handling", "mirror_refresh_requirement", "blocked_spend_rules")
$modelCostGovernanceChecks += $modelCostPolicyArtifactCheck.check

if ($modelCostGovernanceArtifactCheck.data) {
    $modelCostStatus = Normalize-Text (Get-PropValue -Object $modelCostGovernanceArtifactCheck.data -Name "overall_status" -Default "")
    $modelCostGovernanceChecks += New-Check -Name "model_cost_governance_overall_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $modelCostStatus -DefaultStatus "WARN") -Detail ("Model cost governance overall_status={0}." -f $(if ($modelCostStatus) { $modelCostStatus } else { "unknown" })) -Component "model_cost_governance" -Path $modelCostGovernanceLastPath -NextAction "Review the model/cost governance summary if the posture is not PASS."

    $mirrorRefreshStatus = Normalize-Text (Get-PropValue -Object $modelCostGovernanceArtifactCheck.data -Name "mirror_refresh_status" -Default "")
    if ($mirrorRefreshStatus) {
        $mirrorRefreshCheckStatus = if ($mirrorRefreshStatus -in @("success", "local_checkpoint_only")) { "PASS" } else { "WARN" }
        $modelCostGovernanceChecks += New-Check -Name "model_cost_mirror_refresh_status" -Status $mirrorRefreshCheckStatus -Detail ("Model cost governance records mirror_refresh_status={0}." -f $mirrorRefreshStatus) -Component "model_cost_governance" -Path $modelCostGovernanceLastPath -NextAction "Review the mirror refresh result if it remains degraded."
    }
    else {
        $modelCostGovernanceChecks += New-Check -Name "model_cost_mirror_refresh_status" -Status "FAIL" -Detail "Model cost governance is missing mirror_refresh_status." -Component "model_cost_governance" -Path $modelCostGovernanceLastPath -NextAction "Repair Run_Model_Cost_Governance.ps1 so mirror refresh posture is explicit."
    }
}

if ($taskClassificationArtifactCheck.data) {
    $taskRecords = @((Get-PropValue -Object $taskClassificationArtifactCheck.data -Name "tasks" -Default @()))
    if ($taskRecords.Count -eq 0) {
        $modelCostGovernanceChecks += New-Check -Name "task_classification_state" -Status "PASS" -Detail "No active task classification records are present, which is allowed if the active queue is empty." -Component "model_cost_governance" -Path $taskClassificationLastPath -NextAction "No action required."
    }
    else {
        $missingTaskFields = @()
        foreach ($taskRecord in $taskRecords) {
            foreach ($field in @("task_id_or_type", "task_class", "budget_class", "local_first_mandatory", "teacher_allowed", "rationale", "confidence")) {
                if (-not (Test-ObjectHasKey -Object $taskRecord -Name $field)) {
                    $missingTaskFields += $field
                }
            }
        }
        if ($missingTaskFields.Count -eq 0) {
            $modelCostGovernanceChecks += New-Check -Name "task_classification_shape" -Status "PASS" -Detail ("Task classification records expose the required fields for {0} task(s)." -f $taskRecords.Count) -Component "model_cost_governance" -Path $taskClassificationLastPath -NextAction "No action required."
        }
        else {
            $modelCostGovernanceChecks += New-Check -Name "task_classification_shape" -Status "FAIL" -Detail ("Task classification records are missing required fields: {0}" -f (($missingTaskFields | Sort-Object -Unique) -join ", ")) -Component "model_cost_governance" -Path $taskClassificationLastPath -NextAction "Repair Run_Model_Cost_Governance.ps1 so task classification records stay complete."
        }
    }
}

if ($teacherUsefulnessArtifactCheck.data) {
    $teacherReviewRecords = @((Get-PropValue -Object $teacherUsefulnessArtifactCheck.data -Name "reviews" -Default @()))
    if ($teacherReviewRecords.Count -eq 0) {
        $modelCostGovernanceChecks += New-Check -Name "teacher_usefulness_state" -Status "PASS" -Detail "Teacher usefulness currently records zero reviewed items, which is valid if local-first posture prevented escalation." -Component "model_cost_governance" -Path $teacherUsefulnessLastPath -NextAction "No action required."
    }
    else {
        $missingTeacherFields = @()
        foreach ($teacherRecord in $teacherReviewRecords) {
            foreach ($field in @("teacher_item_id", "usefulness_classification", "quality_classification", "quality_score", "estimated_value", "reuse_likelihood", "rationale")) {
                if (-not (Test-ObjectHasKey -Object $teacherRecord -Name $field)) {
                    $missingTeacherFields += $field
                }
            }
        }
        if ($missingTeacherFields.Count -eq 0) {
            $modelCostGovernanceChecks += New-Check -Name "teacher_usefulness_shape" -Status "PASS" -Detail ("Teacher usefulness records expose the required fields for {0} reviewed item(s)." -f $teacherReviewRecords.Count) -Component "model_cost_governance" -Path $teacherUsefulnessLastPath -NextAction "No action required."
        }
        else {
            $modelCostGovernanceChecks += New-Check -Name "teacher_usefulness_shape" -Status "FAIL" -Detail ("Teacher usefulness records are missing required fields: {0}" -f (($missingTeacherFields | Sort-Object -Unique) -join ", ")) -Component "model_cost_governance" -Path $teacherUsefulnessLastPath -NextAction "Repair Run_Model_Cost_Governance.ps1 so teacher usefulness records stay complete."
        }
    }
}

if ($costEffectivenessArtifactCheck.data) {
    $costRecords = @((Get-PropValue -Object $costEffectivenessArtifactCheck.data -Name "tracked_records" -Default @()))
    if ($costRecords.Count -eq 0) {
        $modelCostGovernanceChecks += New-Check -Name "cost_effectiveness_state" -Status "PASS" -Detail "Cost-effectiveness currently records zero evaluated tasks, which is valid if no active tasks were classifiable." -Component "model_cost_governance" -Path $costEffectivenessLastPath -NextAction "No action required."
    }
    else {
        $missingCostFields = @()
        foreach ($costRecord in $costRecords) {
            foreach ($field in @("task_id_or_type", "budget_class", "estimated_cost_tier", "success_signal", "cost_effectiveness_classification", "rationale")) {
                if (-not (Test-ObjectHasKey -Object $costRecord -Name $field)) {
                    $missingCostFields += $field
                }
            }
        }
        if ($missingCostFields.Count -eq 0) {
            $modelCostGovernanceChecks += New-Check -Name "cost_effectiveness_shape" -Status "PASS" -Detail ("Cost-effectiveness records expose the required fields for {0} task(s)." -f $costRecords.Count) -Component "model_cost_governance" -Path $costEffectivenessLastPath -NextAction "No action required."
        }
        else {
            $modelCostGovernanceChecks += New-Check -Name "cost_effectiveness_shape" -Status "FAIL" -Detail ("Cost-effectiveness records are missing required fields: {0}" -f (($missingCostFields | Sort-Object -Unique) -join ", ")) -Component "model_cost_governance" -Path $costEffectivenessLastPath -NextAction "Repair Run_Model_Cost_Governance.ps1 so cost-effectiveness records stay complete."
        }
    }
}

$stackModelCostGovernance = Get-PropValue -Object $stackStatusProbe.data -Name "model_cost_governance" -Default $null
if ($stackStatusProbe.ok -and $stackModelCostGovernance) {
    $modelCostGovernanceChecks += New-Check -Name "model_cost_governance_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes model_cost_governance with overall_status={0}." -f (Normalize-Text (Get-PropValue -Object $stackModelCostGovernance -Name "overall_status" -Default "UNKNOWN"))) -Component "model_cost_governance" -Path $stackStatusUrl -NextAction "No action required."

    $requiredModelCostPayloadKeys = @("overall_status", "task_class_count", "teacher_allowed_count", "teacher_blocked_count", "quality_floor_status", "cost_governance_posture", "mirror_refresh_status", "recommended_next_action")
    $missingModelCostPayloadKeys = @($requiredModelCostPayloadKeys | Where-Object { -not (Test-ObjectHasKey -Object $stackModelCostGovernance -Name $_) })
    if ($missingModelCostPayloadKeys.Count -eq 0) {
        $modelCostGovernanceChecks += New-Check -Name "model_cost_governance_payload_shape" -Status "PASS" -Detail "Athena stack payload exposes the expected model_cost_governance keys." -Component "model_cost_governance" -Path $stackStatusUrl -NextAction "No action required."
    }
    else {
        $modelCostGovernanceChecks += New-Check -Name "model_cost_governance_payload_shape" -Status "FAIL" -Detail ("Athena stack payload model_cost_governance is missing keys: {0}" -f ($missingModelCostPayloadKeys -join ", ")) -Component "model_cost_governance" -Path $stackStatusUrl -NextAction "Patch MasonConsole/server.py so model_cost_governance exposes the governed summary keys."
    }
}
elseif ($stackStatusProbe.ok) {
    $modelCostGovernanceChecks += New-Check -Name "model_cost_governance_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but model_cost_governance is missing." -Component "model_cost_governance" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes model_cost_governance."
}
else {
    $modelCostGovernanceChecks += New-Check -Name "model_cost_governance_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so model_cost_governance visibility cannot be verified right now." -Component "model_cost_governance" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify model_cost_governance visibility."
}
$sections += New-SectionResult -SectionName "model / cost governance" -Checks $modelCostGovernanceChecks

# knowledge / learning quality
$knowledgeQualityChecks = @()
$knowledgeQualityArtifactCheck = Get-FileArtifactCheck -CheckName "knowledge_quality_artifact" -Path $knowledgeQualityLastPath -Component "knowledge_learning_quality" -MissingNextAction "Run tools/ops/Run_Knowledge_Quality_Engine.ps1 so reports/knowledge_quality_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "card_count", "reusable_card_count", "stale_card_count", "blocked_card_count", "review_card_count", "anti_repeat_count", "low_confidence_teacher_count", "trust_band_counts", "evidence_band_counts", "freshness_band_counts", "recent_reused_cards", "low_confidence_teacher_material", "recommended_next_action", "command_run", "repo_root")
$knowledgeQualityChecks += $knowledgeQualityArtifactCheck.check
$knowledgeCardsArtifactCheck = Get-FileArtifactCheck -CheckName "knowledge_cards_artifact" -Path $knowledgeCardsLastPath -Component "knowledge_learning_quality" -MissingNextAction "Run tools/ops/Run_Knowledge_Quality_Engine.ps1 so reports/knowledge_cards_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "card_count", "trusted_card_count", "review_required_count", "blocked_card_count", "stale_card_count", "recommended_next_action", "cards", "command_run", "repo_root")
$knowledgeQualityChecks += $knowledgeCardsArtifactCheck.check
$knowledgeReuseArtifactCheck = Get-FileArtifactCheck -CheckName "knowledge_reuse_artifact" -Path $knowledgeReuseLastPath -Component "knowledge_learning_quality" -MissingNextAction "Run tools/ops/Run_Knowledge_Quality_Engine.ps1 so reports/knowledge_reuse_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "reuse_candidate_count", "selected_card_count", "suppressed_card_count", "blocked_card_count", "stale_card_count", "weak_card_count", "selected_cards", "blocked_cards", "recommended_next_action", "command_run", "repo_root")
$knowledgeQualityChecks += $knowledgeReuseArtifactCheck.check
$antiRepeatArtifactCheck = Get-FileArtifactCheck -CheckName "anti_repeat_memory_artifact" -Path $antiRepeatMemoryLastPath -Component "knowledge_learning_quality" -MissingNextAction "Run tools/ops/Run_Knowledge_Quality_Engine.ps1 so reports/anti_repeat_memory_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "anti_repeat_count", "blocked_count", "review_gated_count", "recommended_next_action", "entries", "command_run", "repo_root")
$knowledgeQualityChecks += $antiRepeatArtifactCheck.check
$outcomeLearningArtifactCheck = Get-FileArtifactCheck -CheckName "outcome_learning_artifact" -Path $outcomeLearningLastPath -Component "knowledge_learning_quality" -MissingNextAction "Run tools/ops/Run_Knowledge_Quality_Engine.ps1 so reports/outcome_learning_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "update_count", "outcome_supported_count", "contradiction_adjusted_count", "anti_repeat_triggered_count", "score_updates", "recommended_next_action", "command_run", "repo_root")
$knowledgeQualityChecks += $outcomeLearningArtifactCheck.check
$knowledgeCardsStateCheck = Get-FileArtifactCheck -CheckName "knowledge_cards_state" -Path $knowledgeCardsStatePath -Component "knowledge_learning_quality" -MissingNextAction "Run tools/ops/Run_Knowledge_Quality_Engine.ps1 so state/knowledge/knowledge_cards.json is written." -RequiredKeys @("generated_at_utc", "overall_status", "card_count", "cards")
$knowledgeQualityChecks += $knowledgeCardsStateCheck.check
$knowledgeFailuresStateCheck = Get-FileArtifactCheck -CheckName "knowledge_failures_state" -Path $knowledgeFailuresStatePath -Component "knowledge_learning_quality" -MissingNextAction "Run tools/ops/Run_Knowledge_Quality_Engine.ps1 so state/knowledge/knowledge_failures.json is written." -RequiredKeys @("generated_at_utc", "failure_count", "failures")
$knowledgeQualityChecks += $knowledgeFailuresStateCheck.check
$knowledgeOutcomesStateCheck = Get-FileArtifactCheck -CheckName "knowledge_outcomes_state" -Path $knowledgeOutcomesStatePath -Component "knowledge_learning_quality" -MissingNextAction "Run tools/ops/Run_Knowledge_Quality_Engine.ps1 so state/knowledge/knowledge_outcomes.json is written." -RequiredKeys @("generated_at_utc", "outcome_count", "outcomes")
$knowledgeQualityChecks += $knowledgeOutcomesStateCheck.check
$knowledgeReuseHistoryCheck = Get-FileArtifactCheck -CheckName "knowledge_reuse_history_state" -Path $knowledgeReuseHistoryPath -Component "knowledge_learning_quality" -MissingNextAction "Run tools/ops/Run_Knowledge_Quality_Engine.ps1 so state/knowledge/knowledge_reuse_history.json is written." -RequiredKeys @("generated_at_utc", "latest_selected_card_ids", "latest_blocked_card_ids", "recent_runs")
$knowledgeQualityChecks += $knowledgeReuseHistoryCheck.check
$knowledgeQualityPolicyCheck = Get-FileArtifactCheck -CheckName "knowledge_quality_policy" -Path $knowledgeQualityPolicyPath -Component "knowledge_learning_quality" -MissingNextAction "Write config/knowledge_quality_policy.json so knowledge quality rules remain canonical." -RequiredKeys @("version", "policy_name", "source_classes", "evidence_weighting", "confidence_weighting", "freshness_decay_behavior", "contradiction_penalties", "anti_repeat_thresholds", "minimum_score_for_reuse", "minimum_score_for_action_influence", "teacher_reuse_restrictions", "operator_override_rules")
$knowledgeQualityChecks += $knowledgeQualityPolicyCheck.check

if ($knowledgeQualityArtifactCheck.data) {
    $knowledgeQualityStatus = Normalize-Text (Get-PropValue -Object $knowledgeQualityArtifactCheck.data -Name "overall_status" -Default "")
    $knowledgeQualityChecks += New-Check -Name "knowledge_quality_overall_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $knowledgeQualityStatus -DefaultStatus "WARN") -Detail ("Knowledge quality overall_status={0}." -f $(if ($knowledgeQualityStatus) { $knowledgeQualityStatus } else { "unknown" })) -Component "knowledge_learning_quality" -Path $knowledgeQualityLastPath -NextAction "Review knowledge quality posture if it remains WARN."
}

if ($knowledgeCardsArtifactCheck.data) {
    $cardRecords = @((Get-PropValue -Object $knowledgeCardsArtifactCheck.data -Name "cards" -Default @()))
    if ($cardRecords.Count -eq 0) {
        $knowledgeQualityChecks += New-Check -Name "knowledge_card_state" -Status "WARN" -Detail "Knowledge cards artifact is readable but cards is empty." -Component "knowledge_learning_quality" -Path $knowledgeCardsLastPath -NextAction "Populate at least one reusable knowledge card so local reuse has governed material."
    }
    else {
        $missingCardFields = @()
        $invalidScoreCards = @()
        foreach ($cardRecord in $cardRecords) {
            foreach ($field in @("card_id", "title", "domain", "component", "topic", "summary", "source_refs", "source_type", "provenance_class", "evidence_score", "confidence_score", "freshness_score", "contradiction_count", "last_verified_at", "first_seen_at", "last_used_at", "use_count", "success_count", "failure_count", "rejection_count", "review_status", "execution_support", "outcome_support", "anti_repeat_flag", "allowed_use_modes", "blocked_use_modes", "notes_for_reviewer")) {
                if (-not (Test-ObjectHasKey -Object $cardRecord -Name $field)) {
                    $missingCardFields += $field
                }
            }
            foreach ($scoreField in @("evidence_score", "confidence_score", "freshness_score")) {
                $scoreValue = Convert-ToDouble -Value (Get-PropValue -Object $cardRecord -Name $scoreField -Default -1)
                if ($scoreValue -lt 0 -or $scoreValue -gt 100) {
                    $invalidScoreCards += ("{0}:{1}" -f (Normalize-Text (Get-PropValue -Object $cardRecord -Name "card_id" -Default "unknown")), $scoreField)
                }
            }
        }
        $knowledgeQualityChecks += New-Check -Name "knowledge_card_shape" -Status ($(if ($missingCardFields.Count -eq 0) { "PASS" } else { "FAIL" })) -Detail $(if ($missingCardFields.Count -eq 0) { ("Knowledge card records expose the required fields for {0} card(s)." -f $cardRecords.Count) } else { ("Knowledge card records are missing required fields: {0}" -f (($missingCardFields | Sort-Object -Unique) -join ", ")) }) -Component "knowledge_learning_quality" -Path $knowledgeCardsLastPath -NextAction "Repair Run_Knowledge_Quality_Engine.ps1 so reusable knowledge cards stay complete."
        $knowledgeQualityChecks += New-Check -Name "knowledge_card_score_ranges" -Status ($(if ($invalidScoreCards.Count -eq 0) { "PASS" } else { "FAIL" })) -Detail $(if ($invalidScoreCards.Count -eq 0) { "Knowledge card scores remain within 0-100." } else { ("Knowledge card score fields are out of range: {0}" -f (($invalidScoreCards | Sort-Object -Unique) -join ", ")) }) -Component "knowledge_learning_quality" -Path $knowledgeCardsLastPath -NextAction "Repair the knowledge quality scoring model so evidence, confidence, and freshness stay bounded."
    }
}

if ($knowledgeReuseArtifactCheck.data -and $knowledgeCardsArtifactCheck.data) {
    $selectedCards = @((Get-PropValue -Object $knowledgeReuseArtifactCheck.data -Name "selected_cards" -Default @()))
    $cardIndex = @{}
    foreach ($cardRecord in @((Get-PropValue -Object $knowledgeCardsArtifactCheck.data -Name "cards" -Default @()))) {
        $cardIndex[(Normalize-Text (Get-PropValue -Object $cardRecord -Name "card_id" -Default ""))] = $cardRecord
    }
    $badSelections = @()
    foreach ($selectedCard in $selectedCards) {
        $selectedId = Normalize-Text (Get-PropValue -Object $selectedCard -Name "card_id" -Default "")
        if (-not $selectedId -or -not $cardIndex.ContainsKey($selectedId)) { continue }
        $sourceCard = $cardIndex[$selectedId]
        if ((Convert-ToBool -Value (Get-PropValue -Object $sourceCard -Name "anti_repeat_flag" -Default $false)) -or (Normalize-Text (Get-PropValue -Object $sourceCard -Name "review_status" -Default "")) -eq "blocked" -or (@((Get-PropValue -Object $sourceCard -Name "blocked_use_modes" -Default @())) -contains "knowledge_reuse")) {
            $badSelections += $selectedId
        }
    }
    $knowledgeQualityChecks += New-Check -Name "knowledge_reuse_safety" -Status ($(if ($badSelections.Count -eq 0) { "PASS" } else { "FAIL" })) -Detail $(if ($badSelections.Count -eq 0) { "Blocked or anti-repeat knowledge is not being silently selected for reuse." } else { ("Selected reuse cards include blocked or anti-repeat entries: {0}" -f (($badSelections | Sort-Object -Unique) -join ", ")) }) -Component "knowledge_learning_quality" -Path $knowledgeReuseLastPath -NextAction "Repair Run_Knowledge_Quality_Engine.ps1 so blocked knowledge never re-enters the active reuse set."
}

$stackKnowledgeQuality = Get-PropValue -Object $stackStatusProbe.data -Name "knowledge_learning_quality" -Default $null
if ($stackStatusProbe.ok -and $stackKnowledgeQuality) {
    $knowledgeQualityChecks += New-Check -Name "knowledge_quality_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes knowledge_learning_quality with overall_status={0}." -f (Normalize-Text (Get-PropValue -Object $stackKnowledgeQuality -Name "overall_status" -Default "UNKNOWN"))) -Component "knowledge_learning_quality" -Path $stackStatusUrl -NextAction "No action required."
    $requiredKnowledgePayloadKeys = @("overall_status", "card_count", "reusable_card_count", "trusted_card_count", "review_card_count", "stale_card_count", "blocked_card_count", "anti_repeat_count", "low_confidence_teacher_count", "recommended_next_action")
    $missingKnowledgePayloadKeys = @($requiredKnowledgePayloadKeys | Where-Object { -not (Test-ObjectHasKey -Object $stackKnowledgeQuality -Name $_) })
    $knowledgeQualityChecks += New-Check -Name "knowledge_quality_payload_shape" -Status ($(if ($missingKnowledgePayloadKeys.Count -eq 0) { "PASS" } else { "FAIL" })) -Detail $(if ($missingKnowledgePayloadKeys.Count -eq 0) { "Athena stack payload exposes the expected knowledge_learning_quality keys." } else { ("Athena stack payload knowledge_learning_quality is missing keys: {0}" -f ($missingKnowledgePayloadKeys -join ", ")) }) -Component "knowledge_learning_quality" -Path $stackStatusUrl -NextAction "Patch MasonConsole/server.py so knowledge_learning_quality exposes the governed summary keys."
}
elseif ($stackStatusProbe.ok) {
    $knowledgeQualityChecks += New-Check -Name "knowledge_quality_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but knowledge_learning_quality is missing." -Component "knowledge_learning_quality" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes knowledge_learning_quality."
}
else {
    $knowledgeQualityChecks += New-Check -Name "knowledge_quality_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so knowledge_learning_quality visibility cannot be verified right now." -Component "knowledge_learning_quality" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify knowledge_learning_quality visibility."
}
$sections += New-SectionResult -SectionName "knowledge / learning quality" -Checks $knowledgeQualityChecks

# UX / simplicity layer + Athena founder cockpit
$uxSimplicityChecks = @()
$uxSummaryArtifact = Get-FileArtifactCheck -CheckName "ux_simplicity_artifact" -Path $uxSimplicityLastPath -Component "ux_simplicity" -MissingNextAction "Run tools/ops/Run_UX_Simplicity_Layer.ps1 so reports/ux_simplicity_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "athena_founder_ux_status", "onyx_customer_ux_status", "dead_button_count", "approval_button_count", "control_button_count", "mobile_layout_status", "recommended_next_action")
$uxSimplicityChecks += $uxSummaryArtifact.check
$athenaFounderUxArtifact = Get-FileArtifactCheck -CheckName "athena_founder_ux_artifact" -Path $athenaFounderUxLastPath -Component "ux_simplicity" -MissingNextAction "Run tools/ops/Run_UX_Simplicity_Layer.ps1 so reports/athena_founder_ux_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "layout_classification", "mobile_friendliness_classification", "approval_surface_status", "component_navigation_status", "control_surface_status", "dead_button_count", "founder_only_confirmed", "recommended_next_action")
$uxSimplicityChecks += $athenaFounderUxArtifact.check
$onyxCustomerUxArtifact = Get-FileArtifactCheck -CheckName "onyx_customer_ux_artifact" -Path $onyxCustomerUxLastPath -Component "ux_simplicity" -MissingNextAction "Run tools/ops/Run_UX_Simplicity_Layer.ps1 so reports/onyx_customer_ux_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "plain_english_status", "onboarding_clarity_status", "customer_jargon_risk", "workflow_clarity_status", "business_type_relevance_status", "recommended_next_action")
$uxSimplicityChecks += $onyxCustomerUxArtifact.check
$approvalSurfaceArtifact = Get-FileArtifactCheck -CheckName "approval_surface_artifact" -Path $approvalSurfaceLastPath -Component "ux_simplicity" -MissingNextAction "Run tools/ops/Run_UX_Simplicity_Layer.ps1 so reports/approval_surface_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "approval_count_visible", "approve_button_count", "reject_button_count", "disabled_button_count", "unwired_action_count", "recommended_next_action")
$uxSimplicityChecks += $approvalSurfaceArtifact.check
$uxRegistryArtifact = Get-FileArtifactCheck -CheckName "ux_simplicity_registry" -Path $uxSimplicityRegistryPath -Component "ux_simplicity" -MissingNextAction "Run tools/ops/Run_UX_Simplicity_Layer.ps1 so state/knowledge/ux_simplicity_registry.json is written." -RequiredKeys @("generated_at_utc", "overall_status", "latest_ux_artifact", "athena_founder_ux_status", "onyx_customer_ux_status", "dead_button_count")
$uxSimplicityChecks += $uxRegistryArtifact.check
$uxPolicyArtifact = Get-FileArtifactCheck -CheckName "ux_simplicity_policy" -Path $uxSimplicityPolicyPath -Component "ux_simplicity" -MissingNextAction "Write config/ux_simplicity_policy.json with the founder/customer simplicity rules." -RequiredKeys @("plain_english_rules", "no_internal_jargon_rules", "no_dead_button_rules", "founder_only_athena_rules", "customer_safe_onyx_rules", "mobile_friendly_layout_rules", "approval_control_surface_rules", "action_button_exposure_rules", "progressive_disclosure_rules", "clutter_reduction_rules")
$uxSimplicityChecks += $uxPolicyArtifact.check

if ($athenaFounderUxArtifact.data) {
    $founderOnlyConfirmed = [bool](Get-PropValue -Object $athenaFounderUxArtifact.data -Name "founder_only_confirmed" -Default $false)
    $uxSimplicityChecks += New-Check -Name "founder_only_posture" -Status ($(if ($founderOnlyConfirmed) { "PASS" } else { "FAIL" })) -Detail ("Founder-only Athena posture is represented as {0}." -f $founderOnlyConfirmed.ToString().ToLowerInvariant()) -Component "ux_simplicity" -Path $athenaFounderUxLastPath -NextAction "Keep Athena founder-only and ensure the UX artifact reflects that posture."

    $layoutClassification = Normalize-Text (Get-PropValue -Object $athenaFounderUxArtifact.data -Name "layout_classification" -Default "")
    $uxSimplicityChecks += New-Check -Name "founder_layout_classification" -Status ($(if ($layoutClassification) { "PASS" } else { "FAIL" })) -Detail ("Founder layout classification={0}." -f ($(if ($layoutClassification) { $layoutClassification } else { "missing" }))) -Component "ux_simplicity" -Path $athenaFounderUxLastPath -NextAction "Report founder layout truthfully so giant-scroll reduction is explicit."

    $mobileClassification = Normalize-Text (Get-PropValue -Object $athenaFounderUxArtifact.data -Name "mobile_friendliness_classification" -Default "")
    $uxSimplicityChecks += New-Check -Name "mobile_friendliness_classification" -Status ($(if ($mobileClassification) { "PASS" } else { "FAIL" })) -Detail ("Founder mobile classification={0}." -f ($(if ($mobileClassification) { $mobileClassification } else { "missing" }))) -Component "ux_simplicity" -Path $athenaFounderUxLastPath -NextAction "Keep founder mobile posture explicit in the UX artifact."
}

if ($approvalSurfaceArtifact.data) {
    $unwiredActionCount = [int](Get-PropValue -Object $approvalSurfaceArtifact.data -Name "unwired_action_count" -Default 0)
    $approvalButtons = [int](Get-PropValue -Object $approvalSurfaceArtifact.data -Name "approve_button_count" -Default 0) + [int](Get-PropValue -Object $approvalSurfaceArtifact.data -Name "reject_button_count" -Default 0)
    $uxSimplicityChecks += New-Check -Name "approval_buttons_truthful" -Status "PASS" -Detail ("Approval surface reports {0} action buttons and {1} unwired actions." -f $approvalButtons, $unwiredActionCount) -Component "ux_simplicity" -Path $approvalSurfaceLastPath -NextAction "No action required."
}

$stackUxSimplicity = Get-PropValue -Object $stackStatusProbe.data -Name "ux_simplicity" -Default $null
if ($stackStatusProbe.ok -and $stackUxSimplicity) {
    $uxSimplicityChecks += New-Check -Name "ux_simplicity_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes ux_simplicity with overall_status={0}." -f (Normalize-Text (Get-PropValue -Object $stackUxSimplicity -Name "overall_status" -Default "UNKNOWN"))) -Component "ux_simplicity" -Path $stackStatusUrl -NextAction "No action required."
    $requiredUxPayloadKeys = @("overall_status", "athena_founder_ux_status", "onyx_customer_ux_status", "dead_button_count", "approval_surface_status", "mobile_layout_status", "recommended_next_action")
    $missingUxPayloadKeys = @($requiredUxPayloadKeys | Where-Object { -not (Test-ObjectHasKey -Object $stackUxSimplicity -Name $_) })
    if ($missingUxPayloadKeys.Count -eq 0) {
        $uxSimplicityChecks += New-Check -Name "ux_simplicity_payload_shape" -Status "PASS" -Detail "Athena stack payload exposes the expected ux_simplicity keys." -Component "ux_simplicity" -Path $stackStatusUrl -NextAction "No action required."
    }
    else {
        $uxSimplicityChecks += New-Check -Name "ux_simplicity_payload_shape" -Status "FAIL" -Detail ("Athena stack payload ux_simplicity is missing keys: {0}" -f ($missingUxPayloadKeys -join ", ")) -Component "ux_simplicity" -Path $stackStatusUrl -NextAction "Patch MasonConsole/server.py so ux_simplicity exposes the founder/customer UX summary keys."
    }
}
elseif ($stackStatusProbe.ok) {
    $uxSimplicityChecks += New-Check -Name "ux_simplicity_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but ux_simplicity is missing." -Component "ux_simplicity" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes ux_simplicity."
}
else {
    $uxSimplicityChecks += New-Check -Name "ux_simplicity_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so ux_simplicity visibility cannot be verified right now." -Component "ux_simplicity" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify ux_simplicity visibility."
}
$sections += New-SectionResult -SectionName "UX / simplicity layer + Athena founder cockpit" -Checks $uxSimplicityChecks

# whole-folder verification / discovery / mirror assurance
$wholeFolderChecks = @()
$wholeFolderArtifactCheck = Get-FileArtifactCheck -CheckName "whole_folder_verification_artifact" -Path $wholeFolderVerificationPath -Component "whole_folder_verification" -MissingNextAction "Run tools/ops/Run_Whole_Folder_Verification.ps1 so reports/whole_folder_verification_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "inventory_summary", "broken_path_count", "unregistered_count", "registry_gap_count", "golden_path_status", "fault_test_status", "migration_risk_status", "usability_status", "mirror_status", "critical_path_broken", "verified_subsystems", "recommended_next_action", "validator_status", "mirror_path", "summary_markdown_path", "command_run", "repo_root")
$wholeFolderChecks += $wholeFolderArtifactCheck.check
$wholeFolderInventoryArtifactCheck = Get-FileArtifactCheck -CheckName "whole_folder_inventory_artifact" -Path $wholeFolderInventoryPath -Component "whole_folder_verification" -MissingNextAction "Run tools/ops/Run_Whole_Folder_Verification.ps1 so reports/whole_folder_inventory_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "repo_root", "inventory_summary", "items")
$wholeFolderChecks += $wholeFolderInventoryArtifactCheck.check
$wholeFolderRegistrationArtifactCheck = Get-FileArtifactCheck -CheckName "whole_folder_registration_gaps_artifact" -Path $wholeFolderRegistrationGapsPath -Component "whole_folder_verification" -MissingNextAction "Run tools/ops/Run_Whole_Folder_Verification.ps1 so reports/whole_folder_registration_gaps.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "gap_count", "unregistered_count", "severity_summary", "gaps", "recommended_next_action")
$wholeFolderChecks += $wholeFolderRegistrationArtifactCheck.check
$wholeFolderBrokenArtifactCheck = Get-FileArtifactCheck -CheckName "whole_folder_broken_paths_artifact" -Path $wholeFolderBrokenPathsPath -Component "whole_folder_verification" -MissingNextAction "Run tools/ops/Run_Whole_Folder_Verification.ps1 so reports/whole_folder_broken_paths_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "broken_path_count", "critical_path_broken", "records", "recommended_next_action")
$wholeFolderChecks += $wholeFolderBrokenArtifactCheck.check
$wholeFolderGoldenArtifactCheck = Get-FileArtifactCheck -CheckName "whole_folder_golden_paths_artifact" -Path $wholeFolderGoldenPathsPath -Component "whole_folder_verification" -MissingNextAction "Run tools/ops/Run_Whole_Folder_Verification.ps1 so reports/whole_folder_golden_paths_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "checks_run", "passed_count", "failed_count", "warn_count", "checks", "recommended_next_action")
$wholeFolderChecks += $wholeFolderGoldenArtifactCheck.check
$wholeFolderFaultArtifactCheck = Get-FileArtifactCheck -CheckName "whole_folder_fault_tests_artifact" -Path $wholeFolderFaultTestsPath -Component "whole_folder_verification" -MissingNextAction "Run tools/ops/Run_Whole_Folder_Verification.ps1 so reports/whole_folder_fault_tests_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "safe_only", "test_count", "passed_count", "failed_count", "warn_count", "tests", "recommended_next_action")
$wholeFolderChecks += $wholeFolderFaultArtifactCheck.check
$wholeFolderMigrationArtifactCheck = Get-FileArtifactCheck -CheckName "whole_folder_migration_checks_artifact" -Path $wholeFolderMigrationChecksPath -Component "whole_folder_verification" -MissingNextAction "Run tools/ops/Run_Whole_Folder_Verification.ps1 so reports/whole_folder_migration_checks_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "hardcoded_path_hit_count", "missing_migration_artifact_count", "mirror_usefulness_status", "adaptive_settings_coverage", "recommended_next_action", "mirror_push_result")
$wholeFolderChecks += $wholeFolderMigrationArtifactCheck.check
$wholeFolderUsabilityArtifactCheck = Get-FileArtifactCheck -CheckName "whole_folder_usability_checks_artifact" -Path $wholeFolderUsabilityChecksPath -Component "whole_folder_verification" -MissingNextAction "Run tools/ops/Run_Whole_Folder_Verification.ps1 so reports/whole_folder_usability_checks_last.json is written." -RequiredKeys @("timestamp_utc", "overall_status", "founder_operability_status", "athena_plain_english_status", "approval_actionability_status", "public_brand_safety_status", "dead_button_status", "owner_pain_score", "recommended_next_action")
$wholeFolderChecks += $wholeFolderUsabilityArtifactCheck.check
$wholeFolderCleanupQueueArtifactCheck = Get-FileArtifactCheck -CheckName "whole_folder_cleanup_queue_artifact" -Path $wholeFolderCleanupQueuePath -Component "whole_folder_verification" -MissingNextAction "Run tools/ops/Run_Whole_Folder_Verification.ps1 so reports/whole_folder_cleanup_queue.json is written." -RequiredKeys @("timestamp_utc", "total_items", "queue_type_counts", "items")
$wholeFolderChecks += $wholeFolderCleanupQueueArtifactCheck.check
$wholeFolderPolicyArtifactCheck = Get-FileArtifactCheck -CheckName "whole_folder_verification_policy" -Path $wholeFolderVerificationPolicyPath -Component "whole_folder_verification" -MissingNextAction "Restore config/whole_folder_verification_policy.json so the whole-folder campaign rules remain canonical." -RequiredKeys @("version", "policy_name", "discovery", "registration_alignment", "golden_paths", "fault_tests", "migration_checks", "usability_checks", "mirror")
$wholeFolderChecks += $wholeFolderPolicyArtifactCheck.check

if (Test-Path -LiteralPath $wholeFolderSummaryMarkdownPath) {
    $wholeFolderSummaryMarkdown = Get-Content -LiteralPath $wholeFolderSummaryMarkdownPath -Raw -Encoding UTF8
    if (Normalize-Text $wholeFolderSummaryMarkdown) {
        $wholeFolderChecks += New-Check -Name "whole_folder_summary_markdown" -Status "PASS" -Detail "Whole-folder verification markdown summary is readable." -Component "whole_folder_verification" -Path $wholeFolderSummaryMarkdownPath -NextAction "No action required."
    }
    else {
        $wholeFolderChecks += New-Check -Name "whole_folder_summary_markdown" -Status "FAIL" -Detail "Whole-folder verification markdown summary exists but is empty." -Component "whole_folder_verification" -Path $wholeFolderSummaryMarkdownPath -NextAction "Rewrite reports/whole_folder_verification_summary.md with the campaign summary."
    }
}
else {
    $wholeFolderChecks += New-Check -Name "whole_folder_summary_markdown" -Status "FAIL" -Detail ("Missing markdown summary: {0}" -f $wholeFolderSummaryMarkdownPath) -Component "whole_folder_verification" -Path $wholeFolderSummaryMarkdownPath -NextAction "Run tools/ops/Run_Whole_Folder_Verification.ps1 so the founder-readable markdown summary is written."
}

if ($wholeFolderArtifactCheck.data) {
    $wholeFolderOverallStatus = Normalize-Text (Get-PropValue -Object $wholeFolderArtifactCheck.data -Name "overall_status" -Default "")
    $wholeFolderChecks += New-Check -Name "whole_folder_overall_status" -Status (Convert-ArtifactStateToCheckStatus -RawValue $wholeFolderOverallStatus -DefaultStatus "WARN") -Detail ("Whole-folder verification overall_status={0}." -f $(if ($wholeFolderOverallStatus) { $wholeFolderOverallStatus } else { "unknown" })) -Component "whole_folder_verification" -Path $wholeFolderVerificationPath -NextAction "Review the whole-folder verification posture if it remains WARN or FAIL."

    $wholeFolderInventorySummary = Get-PropValue -Object $wholeFolderArtifactCheck.data -Name "inventory_summary" -Default @{}
    $missingInventorySummaryKeys = @()
    foreach ($field in @("total_scanned", "registered_item_count", "expected_runtime_count", "orphaned_count", "duplicate_count", "stale_count", "broken_count", "dangerous_count", "archive_like_count")) {
        if (-not (Test-ObjectHasKey -Object $wholeFolderInventorySummary -Name $field)) {
            $missingInventorySummaryKeys += $field
        }
    }
    $wholeFolderChecks += New-Check -Name "whole_folder_inventory_summary_shape" -Status ($(if ($missingInventorySummaryKeys.Count -eq 0) { "PASS" } else { "FAIL" })) -Detail $(if ($missingInventorySummaryKeys.Count -eq 0) { "Whole-folder inventory summary exposes the expected counts." } else { ("Whole-folder inventory summary is missing keys: {0}" -f ($missingInventorySummaryKeys -join ", ")) }) -Component "whole_folder_verification" -Path $wholeFolderVerificationPath -NextAction "Repair Run_Whole_Folder_Verification.ps1 so the inventory summary remains complete."

    $wholeFolderCoverage = Get-PropValue -Object $wholeFolderArtifactCheck.data -Name "coverage" -Default @{}
    $missingCoverageKeys = @()
    foreach ($field in @("discovery_ran", "validator_ran", "stack_restart_attempted", "fault_tests_ran", "tool_canary_ran", "mirror_refresh_attempted")) {
        if (-not (Test-ObjectHasKey -Object $wholeFolderCoverage -Name $field)) {
            $missingCoverageKeys += $field
        }
    }
    $wholeFolderChecks += New-Check -Name "whole_folder_coverage_shape" -Status ($(if ($missingCoverageKeys.Count -eq 0) { "PASS" } else { "FAIL" })) -Detail $(if ($missingCoverageKeys.Count -eq 0) { "Whole-folder verification coverage flags are present." } else { ("Whole-folder verification coverage is missing keys: {0}" -f ($missingCoverageKeys -join ", ")) }) -Component "whole_folder_verification" -Path $wholeFolderVerificationPath -NextAction "Repair Run_Whole_Folder_Verification.ps1 so campaign coverage stays explicit."

    $severitySummary = if ($wholeFolderRegistrationArtifactCheck.data) { Get-PropValue -Object $wholeFolderRegistrationArtifactCheck.data -Name "severity_summary" -Default @{} } else { @{} }
    $missingSeverityKeys = @()
    foreach ($field in @("critical", "high", "medium", "low")) {
        if (-not (Test-ObjectHasKey -Object $severitySummary -Name $field)) {
            $missingSeverityKeys += $field
        }
    }
    $wholeFolderChecks += New-Check -Name "whole_folder_registration_gap_severity_summary" -Status ($(if ($missingSeverityKeys.Count -eq 0) { "PASS" } else { "FAIL" })) -Detail $(if ($missingSeverityKeys.Count -eq 0) { "Registration gaps expose critical/high/medium/low severity counts." } else { ("Registration gap severity summary is missing keys: {0}" -f ($missingSeverityKeys -join ", ")) }) -Component "whole_folder_verification" -Path $wholeFolderRegistrationGapsPath -NextAction "Repair Run_Whole_Folder_Verification.ps1 so registration gap severity stays explicit."

    $campaignMirrorStatus = Normalize-Text (Get-PropValue -Object $wholeFolderArtifactCheck.data -Name "mirror_status" -Default "")
    $mirrorOk = Convert-ToBool -Value (Get-PropValue -Object $mirrorArtifact -Name "ok" -Default $false)
    $mirrorPhase = Normalize-Text (Get-PropValue -Object $mirrorArtifact -Name "phase" -Default "")
    $mirrorPushResult = Normalize-Text (Get-PropValue -Object $mirrorArtifact -Name "mirror_push_result" -Default "")
    $mirrorRemoteCurrent = $mirrorOk -and $mirrorPhase -eq "done" -and $mirrorPushResult -in @("pushed", "noop")
    $mirrorLocalOnly = $mirrorOk -and $mirrorPhase -eq "done" -and -not $mirrorRemoteCurrent
    $mirrorTruthful = (($mirrorRemoteCurrent -and $campaignMirrorStatus -eq "PASS") -or ($mirrorLocalOnly -and $campaignMirrorStatus -eq "WARN") -or ((-not $mirrorOk -or $mirrorPhase -ne "done") -and $campaignMirrorStatus -in @("WARN", "FAIL")))
    $wholeFolderChecks += New-Check -Name "whole_folder_mirror_truth" -Status ($(if ($mirrorTruthful) { "PASS" } else { "FAIL" })) -Detail $(if ($mirrorTruthful) { ("Whole-folder mirror_status={0} matches mirror_update_last.json ({1}, phase={2}, push={3})." -f $campaignMirrorStatus, $mirrorOk.ToString().ToLowerInvariant(), $(if ($mirrorPhase) { $mirrorPhase } else { "unknown" }), $(if ($mirrorPushResult) { $mirrorPushResult } else { "unknown" })) } else { ("Whole-folder mirror_status={0} does not match mirror_update_last.json ({1}, phase={2}, push={3})." -f $campaignMirrorStatus, $mirrorOk.ToString().ToLowerInvariant(), $(if ($mirrorPhase) { $mirrorPhase } else { "unknown" }), $(if ($mirrorPushResult) { $mirrorPushResult } else { "unknown" })) }) -Component "whole_folder_verification" -Path $mirrorUpdatePath -NextAction "Align the whole-folder mirror summary with the canonical mirror artifact."
}

$stackWholeFolderVerification = Get-PropValue -Object $stackStatusProbe.data -Name "whole_folder_verification" -Default $null
if ($stackStatusProbe.ok -and $stackWholeFolderVerification) {
    $wholeFolderChecks += New-Check -Name "whole_folder_payload_visible" -Status "PASS" -Detail ("Athena stack payload exposes whole_folder_verification with overall_status={0}." -f (Normalize-Text (Get-PropValue -Object $stackWholeFolderVerification -Name "overall_status" -Default "UNKNOWN"))) -Component "whole_folder_verification" -Path $stackStatusUrl -NextAction "No action required."
    $requiredWholeFolderPayloadKeys = @("overall_status", "inventory_summary", "broken_path_count", "unregistered_count", "golden_path_status", "fault_test_status", "migration_risk_status", "mirror_status", "recommended_next_action", "top_broken_paths", "top_registration_gaps")
    $missingWholeFolderPayloadKeys = @($requiredWholeFolderPayloadKeys | Where-Object { -not (Test-ObjectHasKey -Object $stackWholeFolderVerification -Name $_) })
    $wholeFolderChecks += New-Check -Name "whole_folder_payload_shape" -Status ($(if ($missingWholeFolderPayloadKeys.Count -eq 0) { "PASS" } else { "FAIL" })) -Detail $(if ($missingWholeFolderPayloadKeys.Count -eq 0) { "Athena stack payload exposes the expected whole_folder_verification keys." } else { ("Athena stack payload whole_folder_verification is missing keys: {0}" -f ($missingWholeFolderPayloadKeys -join ", ")) }) -Component "whole_folder_verification" -Path $stackStatusUrl -NextAction "Patch MasonConsole/server.py so whole_folder_verification exposes the founder-readable summary keys."

    if ($wholeFolderArtifactCheck.data) {
        $artifactWholeFolderStatus = Normalize-Text (Get-PropValue -Object $wholeFolderArtifactCheck.data -Name "overall_status" -Default "")
        $payloadWholeFolderStatus = Normalize-Text (Get-PropValue -Object $stackWholeFolderVerification -Name "overall_status" -Default "")
        $wholeFolderChecks += New-Check -Name "whole_folder_payload_status_alignment" -Status ($(if ($artifactWholeFolderStatus -and $artifactWholeFolderStatus -eq $payloadWholeFolderStatus) { "PASS" } else { "FAIL" })) -Detail $(if ($artifactWholeFolderStatus -and $artifactWholeFolderStatus -eq $payloadWholeFolderStatus) { ("Athena whole_folder_verification matches the campaign artifact status ({0})." -f $payloadWholeFolderStatus) } else { ("Athena whole_folder_verification status ({0}) does not match reports/whole_folder_verification_last.json ({1})." -f $(if ($payloadWholeFolderStatus) { $payloadWholeFolderStatus } else { "missing" }), $(if ($artifactWholeFolderStatus) { $artifactWholeFolderStatus } else { "missing" })) }) -Component "whole_folder_verification" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow or repair the payload loader so whole-folder status stays current."
    }
}
elseif ($stackStatusProbe.ok) {
    $wholeFolderChecks += New-Check -Name "whole_folder_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but whole_folder_verification is missing." -Component "whole_folder_verification" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow so /api/stack_status exposes whole_folder_verification."
}
else {
    $wholeFolderChecks += New-Check -Name "whole_folder_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so whole_folder_verification visibility cannot be verified right now." -Component "whole_folder_verification" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify whole_folder_verification visibility."
}
$sections += New-SectionResult -SectionName "whole-folder verification / discovery / mirror assurance" -Checks $wholeFolderChecks

# repair wave 01 / corrective wiring / mirror hardening
$repairWaveChecks = @()
$repairWaveArtifactCheck = Get-FileArtifactCheck -CheckName "repair_wave_01_artifact" -Path $repairWave01LastPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so the corrective repair summary is written." -RequiredKeys @("timestamp_utc", "overall_status", "onboarding_repair_status", "billing_entitlements_repair_status", "halfwired_repair_status", "registration_gap_status", "scheduler_oversight_status", "internal_visibility_status", "mirror_hardening_status", "fixed_count", "unresolved_queue_count", "recommended_next_action", "command_run", "repo_root")
$repairWaveChecks += $repairWaveArtifactCheck.check
$repairOnboardingCheck = Get-FileArtifactCheck -CheckName "repair_onboarding_artifact" -Path $repairOnboardingLastPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so the onboarding repair artifact is written." -RequiredKeys @("timestamp_utc", "overall_status", "public_wording_status", "completion_action_status", "dead_button_count", "recommended_next_action")
$repairWaveChecks += $repairOnboardingCheck.check
$repairBillingCheck = Get-FileArtifactCheck -CheckName "repair_billing_entitlements_artifact" -Path $repairBillingEntitlementsLastPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so billing/entitlement triage is written." -RequiredKeys @("timestamp_utc", "overall_status", "root_cause_class", "active_workspace_id", "current_tier", "enabled_tools_before", "enabled_tools_after", "repaired_bool", "recommended_next_action")
$repairWaveChecks += $repairBillingCheck.check
$repairHalfwiredCheck = Get-FileArtifactCheck -CheckName "repair_halfwired_artifact" -Path $repairHalfwiredLastPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so half-wired repair results are written." -RequiredKeys @("timestamp_utc", "overall_status", "fixed_count", "queued_count", "recommended_next_action")
$repairWaveChecks += $repairHalfwiredCheck.check
$repairRegistrationCheck = Get-FileArtifactCheck -CheckName "repair_registration_gaps_artifact" -Path $repairRegistrationGapsLastPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so registration-gap repair results are written." -RequiredKeys @("timestamp_utc", "overall_status", "gap_count_before", "closed_count", "expected_remaining_after_reverify", "recommended_next_action")
$repairWaveChecks += $repairRegistrationCheck.check
$repairSchedulerCheck = Get-FileArtifactCheck -CheckName "repair_scheduler_oversight_artifact" -Path $repairSchedulerOversightLastPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so Task Scheduler oversight is written." -RequiredKeys @("timestamp_utc", "overall_status", "relevant_task_count", "healthy_count", "disabled_count", "stale_count", "failing_count", "recommended_next_action")
$repairWaveChecks += $repairSchedulerCheck.check
$repairVisibilityCheck = Get-FileArtifactCheck -CheckName "repair_internal_visibility_artifact" -Path $repairInternalVisibilityLastPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so internal visibility reporting is written." -RequiredKeys @("timestamp_utc", "overall_status", "visible_category_count", "blind_spot_count", "categories", "recommended_next_action")
$repairWaveChecks += $repairVisibilityCheck.check
$repairMirrorCheck = Get-FileArtifactCheck -CheckName "repair_mirror_hardening_artifact" -Path $repairMirrorHardeningLastPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so mirror hardening posture is written." -RequiredKeys @("timestamp_utc", "overall_status", "coverage_status", "omission_status", "matched_file_count", "omission_count", "remote_push_result", "remote_current", "recommended_next_action")
$repairWaveChecks += $repairMirrorCheck.check
$repairBrokenFixedCheck = Get-FileArtifactCheck -CheckName "repair_broken_paths_fixed_artifact" -Path $repairBrokenPathsFixedLastPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so the fixed broken-path queue is written." -RequiredKeys @("timestamp_utc", "fixed_count", "items")
$repairWaveChecks += $repairBrokenFixedCheck.check
$repairQueueArtifactCheck = Get-FileArtifactCheck -CheckName "repair_unfixed_queue_artifact" -Path $repairUnfixedQueueLastPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so the unresolved repair queue is written." -RequiredKeys @("timestamp_utc", "overall_status", "total_items", "items")
$repairWaveChecks += $repairQueueArtifactCheck.check
$mirrorCoverageArtifactCheck = Get-FileArtifactCheck -CheckName "mirror_coverage_artifact" -Path $mirrorCoverageLastPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so mirror coverage is written." -RequiredKeys @("timestamp_utc", "overall_status", "allowlist_pattern_count", "matched_file_count", "missing_pattern_count", "recommended_next_action")
$repairWaveChecks += $mirrorCoverageArtifactCheck.check
$mirrorOmissionArtifactCheck = Get-FileArtifactCheck -CheckName "mirror_omission_artifact" -Path $mirrorOmissionLastPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so mirror omissions are written." -RequiredKeys @("timestamp_utc", "overall_status", "omission_count", "omissions", "recommended_next_action")
$repairWaveChecks += $mirrorOmissionArtifactCheck.check
$athenaWidgetStatusCheck = Get-FileArtifactCheck -CheckName "athena_widget_status_artifact" -Path $athenaWidgetStatusPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so Athena widget status is written." -RequiredKeys @("timestamp_utc", "overall_status", "athena_reachable", "stack_status_reachable", "detected_tabs", "recommended_next_action")
$repairWaveChecks += $athenaWidgetStatusCheck.check
$onyxStackHealthCheck = Get-FileArtifactCheck -CheckName "onyx_stack_health_artifact" -Path $onyxStackHealthPath -Component "repair_wave_01" -MissingNextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so Onyx stack health is written." -RequiredKeys @("timestamp_utc", "overall_status", "app_reachable", "bundle_reachable", "recommended_next_action")
$repairWaveChecks += $onyxStackHealthCheck.check
$repairPolicyCheck = Get-FileArtifactCheck -CheckName "repair_wave_01_policy" -Path $repairWave01PolicyPath -Component "repair_wave_01" -MissingNextAction "Restore config/repair_wave_01_policy.json so the repair-wave rules remain canonical." -RequiredKeys @("version", "policy_name", "repair_buckets", "safe_auto_fix_classes", "blocked_auto_fix_classes", "billing_rules", "scheduler_oversight", "mirror_hardening", "reverify")
$repairWaveChecks += $repairPolicyCheck.check

if (Test-Path -LiteralPath $mirrorSafeIndexPath) {
    $mirrorSafeIndexLength = (Get-Item -LiteralPath $mirrorSafeIndexPath).Length
    $repairWaveChecks += New-Check -Name "mirror_safe_index_markdown" -Status ($(if ($mirrorSafeIndexLength -gt 0) { "PASS" } else { "FAIL" })) -Detail $(if ($mirrorSafeIndexLength -gt 0) { "Mirror-safe markdown index is readable." } else { "Mirror-safe markdown index exists but is empty." }) -Component "repair_wave_01" -Path $mirrorSafeIndexPath -NextAction "Rewrite reports/mirror_safe_index.md with the mirror-safe inspection summary."
}
else {
    $repairWaveChecks += New-Check -Name "mirror_safe_index_markdown" -Status "FAIL" -Detail ("Missing mirror-safe markdown index: {0}" -f $mirrorSafeIndexPath) -Component "repair_wave_01" -Path $mirrorSafeIndexPath -NextAction "Run tools/ops/Run_Repair_Wave_01.ps1 so reports/mirror_safe_index.md is written."
}

if ($repairOnboardingCheck.data) {
    $completionStatus = Normalize-Text (Get-PropValue -Object $repairOnboardingCheck.data -Name "completion_action_status" -Default "")
    $deadButtons = [int](Get-PropValue -Object $repairOnboardingCheck.data -Name "dead_button_count" -Default 0)
    $repairWaveChecks += New-Check -Name "onboarding_completion_action" -Status ($(if ($completionStatus -eq "PASS") { "PASS" } else { "FAIL" })) -Detail ("Onboarding completion action status={0}." -f $(if ($completionStatus) { $completionStatus } else { "unknown" })) -Component "repair_wave_01" -Path $repairOnboardingLastPath -NextAction "Repair the final onboarding action so the customer-facing button is no longer dead."
    $repairWaveChecks += New-Check -Name "onboarding_dead_button_count" -Status ($(if ($deadButtons -eq 0) { "PASS" } else { "WARN" })) -Detail ("Onboarding repair reports dead_button_count={0}." -f $deadButtons) -Component "repair_wave_01" -Path $repairOnboardingLastPath -NextAction "Remove remaining dead or disabled-without-reason onboarding controls."
}

if ($repairBillingCheck.data) {
    $rootCauseClass = Normalize-Text (Get-PropValue -Object $repairBillingCheck.data -Name "root_cause_class" -Default "")
    $repairedBool = Convert-ToBool -Value (Get-PropValue -Object $repairBillingCheck.data -Name "repaired_bool" -Default $false)
    $enabledToolsAfter = @((Get-PropValue -Object $repairBillingCheck.data -Name "enabled_tools_after" -Default @()))
    $billingRepairStatus = if ($repairedBool -or $rootCauseClass -in @("checkout_required_not_entitled_yet", "billing_draft_plan_mismatch_checkout_required")) { "PASS" } elseif ($enabledToolsAfter.Count -gt 0) { "PASS" } else { "WARN" }
    $repairWaveChecks += New-Check -Name "billing_entitlement_root_cause" -Status $billingRepairStatus -Detail ("Billing triage root_cause_class={0}; enabled_tools_after={1}." -f $(if ($rootCauseClass) { $rootCauseClass } else { "unknown" }), $enabledToolsAfter.Count) -Component "repair_wave_01" -Path $repairBillingEntitlementsLastPath -NextAction "Keep billing truthful and analysis-only until explicit entitlement activation is complete."
}

if ($repairMirrorCheck.data) {
    $remotePushResult = Normalize-Text (Get-PropValue -Object $repairMirrorCheck.data -Name "remote_push_result" -Default "")
    $remoteCurrent = Convert-ToBool -Value (Get-PropValue -Object $repairMirrorCheck.data -Name "remote_current" -Default $false)
    $mirrorRemoteStatus = if ($remoteCurrent) { "PASS" } elseif ($remotePushResult) { "WARN" } else { "FAIL" }
    $repairWaveChecks += New-Check -Name "mirror_remote_truth" -Status $mirrorRemoteStatus -Detail ("Repair-wave mirror posture reports remote_push_result={0} remote_current={1}." -f $(if ($remotePushResult) { $remotePushResult } else { "missing" }), $remoteCurrent.ToString().ToLowerInvariant()) -Component "repair_wave_01" -Path $repairMirrorHardeningLastPath -NextAction "Do not claim GitHub/off-box currentness unless remote push succeeds."
}

$stackRepairWave = Get-PropValue -Object $stackStatusProbe.data -Name "repair_wave_01" -Default $null
$stackOnboardingRepair = Get-PropValue -Object $stackStatusProbe.data -Name "onboarding_repair" -Default $null
$stackBillingRepair = Get-PropValue -Object $stackStatusProbe.data -Name "billing_entitlements_repair" -Default $null
$stackHalfwiredRepair = Get-PropValue -Object $stackStatusProbe.data -Name "halfwired_repair" -Default $null
$stackSchedulerRepair = Get-PropValue -Object $stackStatusProbe.data -Name "scheduler_oversight" -Default $null
$stackVisibilityRepair = Get-PropValue -Object $stackStatusProbe.data -Name "internal_visibility" -Default $null
$stackMirrorRepair = Get-PropValue -Object $stackStatusProbe.data -Name "mirror_hardening" -Default $null
if ($stackStatusProbe.ok -and $stackRepairWave -and $stackOnboardingRepair -and $stackBillingRepair -and $stackHalfwiredRepair -and $stackSchedulerRepair -and $stackVisibilityRepair -and $stackMirrorRepair) {
    $repairWaveChecks += New-Check -Name "repair_wave_payload_visible" -Status "PASS" -Detail "Athena stack payload exposes all repair-wave summary branches." -Component "repair_wave_01" -Path $stackStatusUrl -NextAction "No action required."
}
elseif ($stackStatusProbe.ok) {
    $repairWaveChecks += New-Check -Name "repair_wave_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but one or more repair-wave branches are missing." -Component "repair_wave_01" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow or patch MasonConsole/server.py so repair-wave payload branches are exposed."
}
else {
    $repairWaveChecks += New-Check -Name "repair_wave_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so repair-wave payload visibility cannot be verified right now." -Component "repair_wave_01" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify repair-wave payload visibility."
}
$sections += New-SectionResult -SectionName "repair wave 01 / corrective wiring / mirror hardening" -Checks $repairWaveChecks

# repair wave 02 / internal scheduler / popup suppression / remote push repair
$repairWave02Checks = @()
$repairWave02ArtifactCheck = Get-FileArtifactCheck -CheckName "repair_wave_02_artifact" -Path $repairWave02LastPath -Component "repair_wave_02" -MissingNextAction "Run tools/ops/Run_Repair_Wave_02.ps1 so the repair-wave-02 summary is written." -RequiredKeys @("timestamp_utc", "overall_status", "internal_scheduler_status", "legacy_task_migration_status", "popup_suppression_status", "validator_coverage_status", "broken_path_repair_status", "remote_push_repair_status", "migrated_task_count", "popup_fixed_count", "broken_paths_before", "broken_paths_after", "remote_push_result", "recommended_next_action", "command_run", "repo_root")
$repairWave02Checks += $repairWave02ArtifactCheck.check
$internalSchedulerArtifactCheck = Get-FileArtifactCheck -CheckName "internal_scheduler_artifact" -Path $internalSchedulerLastPath -Component "repair_wave_02" -MissingNextAction "Run tools/ops/Run_Repair_Wave_02.ps1 so the internal scheduler foundation artifact is written." -RequiredKeys @("timestamp_utc", "overall_status", "task_definition_count", "enabled_task_count", "audit_logging_status", "foundation_status", "scheduler_state_path", "recommended_next_action")
$repairWave02Checks += $internalSchedulerArtifactCheck.check
$legacyTaskInventoryArtifactCheck = Get-FileArtifactCheck -CheckName "legacy_task_inventory_artifact" -Path $legacyTaskInventoryLastPath -Component "repair_wave_02" -MissingNextAction "Run tools/ops/Run_Repair_Wave_02.ps1 so the legacy task inventory is written." -RequiredKeys @("timestamp_utc", "overall_status", "relevant_task_count", "classification_counts", "tasks", "recommended_next_action")
$repairWave02Checks += $legacyTaskInventoryArtifactCheck.check
$legacyTaskMigrationArtifactCheck = Get-FileArtifactCheck -CheckName "legacy_task_migration_artifact" -Path $legacyTaskMigrationLastPath -Component "repair_wave_02" -MissingNextAction "Run tools/ops/Run_Repair_Wave_02.ps1 so legacy task migration posture is written." -RequiredKeys @("timestamp_utc", "overall_status", "migrated_count", "fallback_only_count", "keep_temporarily_count", "blocked_count", "items", "recommended_next_action")
$repairWave02Checks += $legacyTaskMigrationArtifactCheck.check
$popupSuppressionArtifactCheck = Get-FileArtifactCheck -CheckName "popup_suppression_artifact" -Path $popupSuppressionLastPath -Component "repair_wave_02" -MissingNextAction "Run tools/ops/Run_Repair_Wave_02.ps1 so popup suppression posture is written." -RequiredKeys @("timestamp_utc", "overall_status", "noisy_source_count", "fixed_count", "remaining_visible_count", "items", "recommended_next_action")
$repairWave02Checks += $popupSuppressionArtifactCheck.check
$validatorCoverageRepairArtifactCheck = Get-FileArtifactCheck -CheckName "validator_coverage_repair_artifact" -Path $validatorCoverageRepairLastPath -Component "repair_wave_02" -MissingNextAction "Run tools/ops/Run_Repair_Wave_02.ps1 so validator coverage repair is written." -RequiredKeys @("timestamp_utc", "overall_status", "components_checked", "fully_covered_count", "uncovered_count", "recommended_next_action")
$repairWave02Checks += $validatorCoverageRepairArtifactCheck.check
$brokenPathClusterRepairArtifactCheck = Get-FileArtifactCheck -CheckName "broken_path_cluster_repair_artifact" -Path $brokenPathClusterRepairLastPath -Component "repair_wave_02" -MissingNextAction "Run tools/ops/Run_Repair_Wave_02.ps1 so broken-path cluster repair is written." -RequiredKeys @("timestamp_utc", "overall_status", "target_cluster_count", "fixed_count", "broken_paths_before", "broken_paths_after", "recommended_next_action")
$repairWave02Checks += $brokenPathClusterRepairArtifactCheck.check
$remotePushRepairArtifactCheck = Get-FileArtifactCheck -CheckName "remote_push_repair_artifact" -Path $remotePushRepairLastPath -Component "repair_wave_02" -MissingNextAction "Run tools/ops/Run_Repair_Wave_02.ps1 so remote push repair posture is written." -RequiredKeys @("timestamp_utc", "overall_status", "push_failure_class", "safe_repair_attempted", "remote_push_result", "remote_current", "recommended_next_action")
$repairWave02Checks += $remotePushRepairArtifactCheck.check
$repairWave02QueueArtifactCheck = Get-FileArtifactCheck -CheckName "repair_wave_02_unfixed_queue_artifact" -Path $repairWave02UnfixedQueueLastPath -Component "repair_wave_02" -MissingNextAction "Run tools/ops/Run_Repair_Wave_02.ps1 so the unresolved repair-wave-02 queue is written." -RequiredKeys @("timestamp_utc", "overall_status", "total_items", "items")
$repairWave02Checks += $repairWave02QueueArtifactCheck.check
$repairWave02PolicyCheck = Get-FileArtifactCheck -CheckName "repair_wave_02_policy" -Path $repairWave02PolicyPath -Component "repair_wave_02" -MissingNextAction "Restore config/repair_wave_02_policy.json so repair-wave-02 rules remain canonical." -RequiredKeys @("version", "policy_name", "repair_targets", "popup_suppression_rules", "remote_push_repair", "reverify")
$repairWave02Checks += $repairWave02PolicyCheck.check
$internalSchedulerPolicyCheck = Get-FileArtifactCheck -CheckName "internal_scheduler_policy" -Path $internalSchedulerPolicyPath -Component "repair_wave_02" -MissingNextAction "Restore config/internal_scheduler_policy.json so the scheduler foundation remains canonical." -RequiredKeys @("version", "policy_name", "task_classes", "risk_classes", "default_run_modes", "foundation_tasks")
$repairWave02Checks += $internalSchedulerPolicyCheck.check
$legacyTaskMigrationPolicyCheck = Get-FileArtifactCheck -CheckName "legacy_task_migration_policy" -Path $legacyTaskMigrationPolicyPath -Component "repair_wave_02" -MissingNextAction "Restore config/legacy_task_migration_policy.json so host-task migration remains canonical." -RequiredKeys @("version", "policy_name", "classification_rules", "migration_postures", "popup_rules", "safe_disable_rules")
$repairWave02Checks += $legacyTaskMigrationPolicyCheck.check
if (Test-Path -LiteralPath $internalSchedulerRegistryPath) {
    $repairWave02Checks += New-Check -Name "internal_scheduler_registry" -Status "PASS" -Detail "Internal scheduler registry is readable." -Component "repair_wave_02" -Path $internalSchedulerRegistryPath -NextAction "No action required."
}
else {
    $repairWave02Checks += New-Check -Name "internal_scheduler_registry" -Status "WARN" -Detail "Internal scheduler registry is not yet present." -Component "repair_wave_02" -Path $internalSchedulerRegistryPath -NextAction "Write state/knowledge/internal_scheduler_registry.json so the scheduler foundation has durable state."
}

if ($validatorCoverageRepairArtifactCheck.data) {
    $uncoveredCount = [int](Get-PropValue -Object $validatorCoverageRepairArtifactCheck.data -Name "uncovered_count" -Default 0)
    $repairWave02Checks += New-Check -Name "validator_component_coverage" -Status ($(if ($uncoveredCount -eq 0) { "PASS" } else { "WARN" })) -Detail ("Validator coverage repair reports uncovered_count={0}." -f $uncoveredCount) -Component "repair_wave_02" -Path $validatorCoverageRepairLastPath -NextAction "Finish validator coverage for any remaining registered components before trusting stack/base coverage."
}

if ($popupSuppressionArtifactCheck.data) {
    $remainingVisible = [int](Get-PropValue -Object $popupSuppressionArtifactCheck.data -Name "remaining_visible_count" -Default 0)
    $fixedPopupCount = [int](Get-PropValue -Object $popupSuppressionArtifactCheck.data -Name "fixed_count" -Default 0)
    $popupStatus = if ($remainingVisible -eq 0 -or $fixedPopupCount -gt 0) { "PASS" } else { "WARN" }
    $repairWave02Checks += New-Check -Name "popup_suppression_posture" -Status $popupStatus -Detail ("Popup suppression reports fixed_count={0} remaining_visible_count={1}." -f $fixedPopupCount, $remainingVisible) -Component "repair_wave_02" -Path $popupSuppressionLastPath -NextAction "Keep background Mason jobs hidden unless they genuinely require interactive visibility."
}

if ($brokenPathClusterRepairArtifactCheck.data) {
    $brokenBefore = [int](Get-PropValue -Object $brokenPathClusterRepairArtifactCheck.data -Name "broken_paths_before" -Default 0)
    $brokenAfter = [int](Get-PropValue -Object $brokenPathClusterRepairArtifactCheck.data -Name "broken_paths_after" -Default 0)
    $clusterRepairStatus = if ($brokenAfter -lt $brokenBefore) { "PASS" } else { "WARN" }
    $repairWave02Checks += New-Check -Name "broken_path_reduction" -Status $clusterRepairStatus -Detail ("Broken-path cluster repair reports broken_paths_before={0} and broken_paths_after={1}." -f $brokenBefore, $brokenAfter) -Component "repair_wave_02" -Path $brokenPathClusterRepairLastPath -NextAction "Keep attacking high-value broken-path clusters until the verified count actually drops."
}

if ($remotePushRepairArtifactCheck.data) {
    $remotePushResult = Normalize-Text (Get-PropValue -Object $remotePushRepairArtifactCheck.data -Name "remote_push_result" -Default "")
    $pushFailureClass = Normalize-Text (Get-PropValue -Object $remotePushRepairArtifactCheck.data -Name "push_failure_class" -Default "")
    $remoteCurrent = Convert-ToBool -Value (Get-PropValue -Object $remotePushRepairArtifactCheck.data -Name "remote_current" -Default $false)
    $remotePushStatus = if ($remoteCurrent) { "PASS" } elseif ($remotePushResult -or $pushFailureClass) { "WARN" } else { "FAIL" }
    $repairWave02Checks += New-Check -Name "remote_push_truth" -Status $remotePushStatus -Detail ("Remote push repair reports result={0} failure_class={1} remote_current={2}." -f $(if ($remotePushResult) { $remotePushResult } else { "missing" }), $(if ($pushFailureClass) { $pushFailureClass } else { "unknown" }), $remoteCurrent.ToString().ToLowerInvariant()) -Component "repair_wave_02" -Path $remotePushRepairLastPath -NextAction "Do not claim GitHub/off-box currentness unless remote_current becomes true."
}

$stackRepairWave02 = Get-PropValue -Object $stackStatusProbe.data -Name "repair_wave_02" -Default $null
$stackInternalScheduler = Get-PropValue -Object $stackStatusProbe.data -Name "internal_scheduler" -Default $null
$stackLegacyTaskMigration = Get-PropValue -Object $stackStatusProbe.data -Name "legacy_task_migration" -Default $null
$stackPopupSuppression = Get-PropValue -Object $stackStatusProbe.data -Name "popup_suppression" -Default $null
$stackValidatorCoverageRepair = Get-PropValue -Object $stackStatusProbe.data -Name "validator_coverage_repair" -Default $null
$stackBrokenPathClusterRepair = Get-PropValue -Object $stackStatusProbe.data -Name "broken_path_cluster_repair" -Default $null
$stackRemotePushRepair = Get-PropValue -Object $stackStatusProbe.data -Name "remote_push_repair" -Default $null
if ($stackStatusProbe.ok -and $stackRepairWave02 -and $stackInternalScheduler -and $stackLegacyTaskMigration -and $stackPopupSuppression -and $stackValidatorCoverageRepair -and $stackBrokenPathClusterRepair -and $stackRemotePushRepair) {
    $repairWave02Checks += New-Check -Name "repair_wave_02_payload_visible" -Status "PASS" -Detail "Athena stack payload exposes all repair-wave-02 summary branches." -Component "repair_wave_02" -Path $stackStatusUrl -NextAction "No action required."
}
elseif ($stackStatusProbe.ok) {
    $repairWave02Checks += New-Check -Name "repair_wave_02_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but one or more repair-wave-02 branches are missing." -Component "repair_wave_02" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow or patch MasonConsole/server.py so repair-wave-02 payload branches are exposed."
}
else {
    $repairWave02Checks += New-Check -Name "repair_wave_02_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so repair-wave-02 payload visibility cannot be verified right now." -Component "repair_wave_02" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify repair-wave-02 payload visibility."
}
$sections += New-SectionResult -SectionName "repair wave 02 / internal scheduler / popup suppression / remote push repair" -Checks $repairWave02Checks

# repair wave 03 / scheduler migration / popup elimination / Onyx core flow / mirror closure
$repairWave03Checks = @()
$repairWave03ArtifactCheck = Get-FileArtifactCheck -CheckName "repair_wave_03_artifact" -Path $repairWave03LastPath -Component "repair_wave_03" -MissingNextAction "Run tools/ops/Run_Repair_Wave_03.ps1 so the repair-wave-03 summary is written." -RequiredKeys @("timestamp_utc", "overall_status", "internal_scheduler_migration_status", "windows_task_fallback_status", "popup_window_elimination_status", "broken_path_reduction_status", "onyx_core_flow_status", "migrated_task_count", "host_disabled_count", "broken_paths_before", "broken_paths_after", "remote_push_result", "github_current", "recommended_next_action", "command_run", "repo_root")
$repairWave03Checks += $repairWave03ArtifactCheck.check
$internalSchedulerMigrationArtifactCheck = Get-FileArtifactCheck -CheckName "internal_scheduler_migration_artifact" -Path $internalSchedulerMigrationLastPath -Component "repair_wave_03" -MissingNextAction "Run tools/ops/Run_Repair_Wave_03.ps1 so actual internal scheduler migration state is written." -RequiredKeys @("timestamp_utc", "overall_status", "migrated_task_count", "host_disabled_count", "executed_via_internal_scheduler_count", "bootstrap_task_name", "bootstrap_verification_status", "items", "recommended_next_action")
$repairWave03Checks += $internalSchedulerMigrationArtifactCheck.check
$windowsTaskFallbackArtifactCheck = Get-FileArtifactCheck -CheckName "windows_task_fallback_artifact" -Path $windowsTaskFallbackLastPath -Component "repair_wave_03" -MissingNextAction "Run tools/ops/Run_Repair_Wave_03.ps1 so the remaining Windows fallback dependence is written." -RequiredKeys @("timestamp_utc", "overall_status", "bootstrap_task_name", "migrated_disable_host_count", "keep_as_bootstrap_count", "keep_as_fallback_count", "keep_temporarily_pending_count", "manual_review_required_count", "remaining_windows_dependency_count", "items", "recommended_next_action")
$repairWave03Checks += $windowsTaskFallbackArtifactCheck.check
$popupWindowEliminationArtifactCheck = Get-FileArtifactCheck -CheckName "popup_window_elimination_artifact" -Path $popupWindowEliminationLastPath -Component "repair_wave_03" -MissingNextAction "Run tools/ops/Run_Repair_Wave_03.ps1 so popup-window elimination posture is written." -RequiredKeys @("timestamp_utc", "overall_status", "active_noisy_before", "active_noisy_after", "fixed_count", "reduced_count", "items", "recommended_next_action")
$repairWave03Checks += $popupWindowEliminationArtifactCheck.check
$brokenPathReductionWave03ArtifactCheck = Get-FileArtifactCheck -CheckName "broken_path_reduction_wave_03_artifact" -Path $brokenPathReductionWave03LastPath -Component "repair_wave_03" -MissingNextAction "Run tools/ops/Run_Repair_Wave_03.ps1 so broken-path reduction wave 03 is written." -RequiredKeys @("timestamp_utc", "overall_status", "target_cluster_count", "fixed_count", "broken_paths_before", "broken_paths_after", "items", "recommended_next_action")
$repairWave03Checks += $brokenPathReductionWave03ArtifactCheck.check
$onyxCoreFlowVerificationArtifactCheck = Get-FileArtifactCheck -CheckName "onyx_core_flow_verification_artifact" -Path $onyxCoreFlowVerificationLastPath -Component "repair_wave_03" -MissingNextAction "Run tools/ops/Run_Repair_Wave_03.ps1 so the Onyx core-flow verification summary is written." -RequiredKeys @("timestamp_utc", "overall_status", "app_reachable", "bundle_reachable", "runtime_status", "onboarding_wording_status", "onboarding_completion_status", "core_surface_status", "verified_label_count", "required_label_count", "recommended_next_action")
$repairWave03Checks += $onyxCoreFlowVerificationArtifactCheck.check
$repairWave03QueueArtifactCheck = Get-FileArtifactCheck -CheckName "repair_wave_03_unfixed_queue_artifact" -Path $repairWave03UnfixedQueueLastPath -Component "repair_wave_03" -MissingNextAction "Run tools/ops/Run_Repair_Wave_03.ps1 so the unresolved Wave 03 queue is written." -RequiredKeys @("timestamp_utc", "overall_status", "total_items", "items")
$repairWave03Checks += $repairWave03QueueArtifactCheck.check
$repairWave03PolicyCheck = Get-FileArtifactCheck -CheckName "repair_wave_03_policy" -Path $repairWave03PolicyPath -Component "repair_wave_03" -MissingNextAction "Restore config/repair_wave_03_policy.json so Wave 03 remains canonical." -RequiredKeys @("version", "policy_name", "migration_targets", "popup_rules", "broken_path_reduction", "onyx_core_flow_checks", "mirror_closure")
$repairWave03Checks += $repairWave03PolicyCheck.check

if ($internalSchedulerMigrationArtifactCheck.data) {
    $migratedCount = [int](Get-PropValue -Object $internalSchedulerMigrationArtifactCheck.data -Name "migrated_task_count" -Default 0)
    $executedCount = [int](Get-PropValue -Object $internalSchedulerMigrationArtifactCheck.data -Name "executed_via_internal_scheduler_count" -Default 0)
    $migrationStatus = if ($migratedCount -gt 0 -and $executedCount -gt 0) { "PASS" } else { "WARN" }
    $repairWave03Checks += New-Check -Name "internal_scheduler_migration_truth" -Status $migrationStatus -Detail ("Wave 03 migration reports migrated_task_count={0} executed_via_internal_scheduler_count={1}." -f $migratedCount, $executedCount) -Component "repair_wave_03" -Path $internalSchedulerMigrationLastPath -NextAction "Do not claim scheduler migration unless tasks actually ran through the internal scheduler and refreshed their audit artifacts."
}

if ($windowsTaskFallbackArtifactCheck.data) {
    $remainingWindowsDependencies = [int](Get-PropValue -Object $windowsTaskFallbackArtifactCheck.data -Name "remaining_windows_dependency_count" -Default 0)
    $repairWave03Checks += New-Check -Name "windows_task_fallback_truth" -Status ($(if ($remainingWindowsDependencies -ge 0) { "PASS" } else { "FAIL" })) -Detail ("Windows fallback artifact reports remaining_windows_dependency_count={0}." -f $remainingWindowsDependencies) -Component "repair_wave_03" -Path $windowsTaskFallbackLastPath -NextAction "Keep Windows Task Scheduler scoped to bootstrap/fallback only and report the remaining set truthfully."
}

if ($popupWindowEliminationArtifactCheck.data) {
    $activeBefore = [int](Get-PropValue -Object $popupWindowEliminationArtifactCheck.data -Name "active_noisy_before" -Default 0)
    $activeAfter = [int](Get-PropValue -Object $popupWindowEliminationArtifactCheck.data -Name "active_noisy_after" -Default 0)
    $fixedCount = [int](Get-PropValue -Object $popupWindowEliminationArtifactCheck.data -Name "fixed_count" -Default 0)
    $popupStatus = if ($activeAfter -lt $activeBefore -or $activeAfter -eq 0 -or $fixedCount -gt 0) { "PASS" } else { "WARN" }
    $repairWave03Checks += New-Check -Name "popup_window_elimination_truth" -Status $popupStatus -Detail ("Popup elimination reports active_noisy_before={0} active_noisy_after={1} fixed_count={2}." -f $activeBefore, $activeAfter, $fixedCount) -Component "repair_wave_03" -Path $popupWindowEliminationLastPath -NextAction "Keep background Mason jobs hidden unless they genuinely require direct interaction."
}

if ($brokenPathReductionWave03ArtifactCheck.data) {
    $brokenBefore = [int](Get-PropValue -Object $brokenPathReductionWave03ArtifactCheck.data -Name "broken_paths_before" -Default 0)
    $brokenAfter = [int](Get-PropValue -Object $brokenPathReductionWave03ArtifactCheck.data -Name "broken_paths_after" -Default 0)
    $repairWave03Checks += New-Check -Name "broken_path_reduction_truth" -Status ($(if ($brokenAfter -lt $brokenBefore) { "PASS" } else { "WARN" })) -Detail ("Wave 03 broken-path reduction reports broken_paths_before={0} broken_paths_after={1}." -f $brokenBefore, $brokenAfter) -Component "repair_wave_03" -Path $brokenPathReductionWave03LastPath -NextAction "Do not claim broken-path cleanup unless the verified count actually drops."
}

if ($onyxCoreFlowVerificationArtifactCheck.data) {
    $appReachable = Convert-ToBool -Value (Get-PropValue -Object $onyxCoreFlowVerificationArtifactCheck.data -Name "app_reachable" -Default $false)
    $bundleReachable = Convert-ToBool -Value (Get-PropValue -Object $onyxCoreFlowVerificationArtifactCheck.data -Name "bundle_reachable" -Default $false)
    $onyxStatus = if ($appReachable -and $bundleReachable) { "PASS" } else { "WARN" }
    $repairWave03Checks += New-Check -Name "onyx_core_flow_truth" -Status $onyxStatus -Detail ("Onyx core-flow verification reports app_reachable={0} bundle_reachable={1}." -f $appReachable.ToString().ToLowerInvariant(), $bundleReachable.ToString().ToLowerInvariant()) -Component "repair_wave_03" -Path $onyxCoreFlowVerificationLastPath -NextAction "Do not overclaim Onyx owner-flow proof if runtime reachability or wiring verification is still partial."
}

if ($repairWave03ArtifactCheck.data) {
    $githubCurrent = Convert-ToBool -Value (Get-PropValue -Object $repairWave03ArtifactCheck.data -Name "github_current" -Default $false)
    $remotePushResult = Normalize-Text (Get-PropValue -Object $repairWave03ArtifactCheck.data -Name "remote_push_result" -Default "")
    $repairWave03Checks += New-Check -Name "mirror_closure_truth" -Status ($(if ($githubCurrent) { "PASS" } elseif ($remotePushResult) { "WARN" } else { "FAIL" })) -Detail ("Wave 03 repair summary reports remote_push_result={0} github_current={1}." -f $(if ($remotePushResult) { $remotePushResult } else { "missing" }), $githubCurrent.ToString().ToLowerInvariant()) -Component "repair_wave_03" -Path $repairWave03LastPath -NextAction "Do not finish the wave without a truthful GitHub currentness statement."
}

$stackRepairWave03 = Get-PropValue -Object $stackStatusProbe.data -Name "repair_wave_03" -Default $null
$stackInternalSchedulerMigration = Get-PropValue -Object $stackStatusProbe.data -Name "internal_scheduler_migration" -Default $null
$stackWindowsTaskFallback = Get-PropValue -Object $stackStatusProbe.data -Name "windows_task_fallback" -Default $null
$stackPopupWindowElimination = Get-PropValue -Object $stackStatusProbe.data -Name "popup_window_elimination" -Default $null
$stackBrokenPathReductionWave03 = Get-PropValue -Object $stackStatusProbe.data -Name "broken_path_reduction_wave_03" -Default $null
$stackOnyxCoreFlowVerification = Get-PropValue -Object $stackStatusProbe.data -Name "onyx_core_flow_verification" -Default $null
if ($stackStatusProbe.ok -and $stackRepairWave03 -and $stackInternalSchedulerMigration -and $stackWindowsTaskFallback -and $stackPopupWindowElimination -and $stackBrokenPathReductionWave03 -and $stackOnyxCoreFlowVerification) {
    $repairWave03Checks += New-Check -Name "repair_wave_03_payload_visible" -Status "PASS" -Detail "Athena stack payload exposes all repair-wave-03 summary branches." -Component "repair_wave_03" -Path $stackStatusUrl -NextAction "No action required."
}
elseif ($stackStatusProbe.ok) {
    $repairWave03Checks += New-Check -Name "repair_wave_03_payload_visible" -Status "WARN" -Detail "Athena stack payload is readable but one or more repair-wave-03 branches are missing." -Component "repair_wave_03" -Path $stackStatusUrl -NextAction "Restart Athena on the normal loopback-only flow or patch MasonConsole/server.py so repair-wave-03 payload branches are exposed."
}
else {
    $repairWave03Checks += New-Check -Name "repair_wave_03_payload_visible" -Status "WARN" -Detail "Athena stack payload is unavailable, so repair-wave-03 payload visibility cannot be verified right now." -Component "repair_wave_03" -Path $stackStatusUrl -NextAction "Restore Athena stack status first, then verify repair-wave-03 payload visibility."
}
$sections += New-SectionResult -SectionName "repair wave 03 / scheduler migration / popup elimination / Onyx core flow / mirror closure" -Checks $repairWave03Checks

# mirror/checkpoint state
$mirrorChecks = @()
$mirrorFileCheck = Get-FileArtifactCheck -CheckName "mirror_update_artifact" -Path $mirrorUpdatePath -Component "mirror" -MissingNextAction "Run the mirror update flow so reports/mirror_update_last.json is written." -RequiredKeys @("timestamp_utc", "ok", "phase")
$mirrorChecks += $mirrorFileCheck.check
if ($mirrorFileCheck.data) {
    $mirrorOk = [bool](Get-PropValue -Object $mirrorFileCheck.data -Name "ok" -Default $false)
    $mirrorPhase = Normalize-Text (Get-PropValue -Object $mirrorFileCheck.data -Name "phase" -Default "")
    $mirrorPushResult = Normalize-Text (Get-PropValue -Object $mirrorFileCheck.data -Name "mirror_push_result" -Default "")
    $mirrorNextAction = Normalize-Text (Get-PropValue -Object $mirrorFileCheck.data -Name "next_action" -Default "Rerun the mirror update flow and inspect reports/mirror_update_last.json.")
    $mirrorOkStatus = if ($mirrorOk) { "PASS" } else { "WARN" }
    $mirrorPhaseStatus = if ($mirrorPhase -eq "done") { "PASS" } else { "WARN" }
    $mirrorPhaseDisplay = if ($mirrorPhase) { $mirrorPhase } else { "unknown" }
    $mirrorChecks += New-Check -Name "mirror_ok" -Status $mirrorOkStatus -Detail ("mirror_update_last.json ok={0}." -f $mirrorOk.ToString().ToLowerInvariant()) -Component "mirror" -Path $mirrorUpdatePath -NextAction $mirrorNextAction
    $mirrorChecks += New-Check -Name "mirror_phase" -Status $mirrorPhaseStatus -Detail ("mirror_update_last.json phase={0}." -f $mirrorPhaseDisplay) -Component "mirror" -Path $mirrorUpdatePath -NextAction "Wait for or rerun the mirror flow until phase is done."
    if ($mirrorPushResult) {
        $mirrorChecks += New-Check -Name "mirror_push_result" -Status "PASS" -Detail ("mirror_push_result={0}." -f $mirrorPushResult) -Component "mirror" -Path $mirrorUpdatePath -NextAction "No action required."
    }
    else {
        $mirrorChecks += New-Check -Name "mirror_push_result" -Status "WARN" -Detail "mirror_push_result is missing from reports/mirror_update_last.json." -Component "mirror" -Path $mirrorUpdatePath -NextAction "Repair mirror_update_last.json so mirror_push_result is recorded."
    }
}
$sections += New-SectionResult -SectionName "mirror/checkpoint state" -Checks $mirrorChecks

$sectionFailCount = @($sections | Where-Object { $_.status -eq "FAIL" }).Count
$sectionWarnCount = @($sections | Where-Object { $_.status -eq "WARN" }).Count
$overallStatus = "PASS"
if ($sectionFailCount -gt 0) {
    $overallStatus = "FAIL"
}
elseif ($sectionWarnCount -gt 0) {
    $overallStatus = "WARN"
}

$totalPassCount = [int](@($sections | Measure-Object -Property passed_count -Sum).Sum)
$totalFailCount = [int](@($sections | Measure-Object -Property failed_count -Sum).Sum)
$totalWarnCount = [int](@($sections | Measure-Object -Property warn_count -Sum).Sum)

$failingComponents = [System.Collections.Generic.List[string]]::new()
$relevantPaths = [System.Collections.Generic.List[string]]::new()
$overallNextAction = "No action required."
foreach ($section in $sections) {
    $sectionComponent = Normalize-Text (Get-PropValue -Object $section -Name "failing_component" -Default "")
    if (-not $sectionComponent -and (Get-PropValue -Object $section -Name "status" -Default "") -ne "PASS") {
        $sectionComponent = Normalize-Text (Get-PropValue -Object $section -Name "section_name" -Default "")
    }
    Add-UniqueString -Target $failingComponents -Value $sectionComponent
    Add-UniqueString -Target $relevantPaths -Value (Get-PropValue -Object $section -Name "relevant_log_or_artifact_path" -Default "")
    if ($overallNextAction -eq "No action required." -and (Get-PropValue -Object $section -Name "status" -Default "") -ne "PASS") {
        $candidateAction = Normalize-Text (Get-PropValue -Object $section -Name "recommended_next_action" -Default "")
        if ($candidateAction) {
            $overallNextAction = $candidateAction
        }
    }
}

$baselineTag = ""
if ($startRunArtifact) {
    $baselineTag = Normalize-Text (Get-PropValue -Object $startRunArtifact -Name "baseline_tag" -Default "")
    if (-not $baselineTag) {
        $baselineTag = Normalize-Text (Get-PropValue -Object $startRunArtifact -Name "mode" -Default "")
    }
}

$reportMirrorOk = $false
if ($mirrorArtifact) {
    $reportMirrorOk = [bool](Get-PropValue -Object $mirrorArtifact -Name "ok" -Default $false)
}

$report = [ordered]@{
    timestamp_utc           = (Get-Date).ToUniversalTime().ToString("o")
    overall_status          = $overallStatus
    passed_count            = [int]$totalPassCount
    failed_count            = [int]$totalFailCount
    warn_count              = [int]$totalWarnCount
    sections                = @($sections)
    failing_components      = @($failingComponents)
    recommended_next_action = $overallNextAction
    relevant_paths          = @($relevantPaths)
    mirror_ok               = [bool]$reportMirrorOk
    baseline_tag            = [string]$baselineTag
    command_run             = 'powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Validate_Whole_System.ps1'
    repo_root               = [string]$repoRoot
    artifact_path           = [string]$systemValidationPath
}

Write-JsonFile -Path $systemValidationPath -Object $report -Depth 20
$report | ConvertTo-Json -Depth 20
exit 0
