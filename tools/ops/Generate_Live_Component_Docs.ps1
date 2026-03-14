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

    return [bool]$Object.PSObject.Properties[$Name]
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

function Ensure-Parent {
    param([Parameter(Mandatory = $true)][string]$Path)
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 24
    )

    Ensure-Parent -Path $Path
    $Object | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Resolve-RepoRoot {
    param([string]$OverrideRoot)

    if ($OverrideRoot -and (Test-Path -LiteralPath $OverrideRoot)) {
        return (Resolve-Path -LiteralPath $OverrideRoot).Path
    }

    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Resolve-RepoPath {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$PathValue
    )

    if ([System.IO.Path]::IsPathRooted($PathValue)) {
        return $PathValue
    }

    return Join-Path $RepoRoot $PathValue
}

function Normalize-StringList {
    param($Values)

    $result = [System.Collections.Generic.List[string]]::new()
    foreach ($value in @($Values)) {
        $text = Normalize-Text $value
        if ($text -and -not $result.Contains($text)) {
            [void]$result.Add($text)
        }
    }
    return @($result)
}

function Add-UniqueString {
    param(
        $Target,
        [string]$Value
    )

    $text = Normalize-Text $Value
    if ($text -and -not $Target.Contains($text)) {
        [void]$Target.Add($text)
    }
}

function Add-UniqueObject {
    param(
        $Target,
        $SeenKeys,
        $Object,
        [string]$Key
    )

    if (-not $SeenKeys.Contains($Key)) {
        [void]$SeenKeys.Add($Key)
        [void]$Target.Add($Object)
    }
}

function Get-StatusScore {
    param([string]$Status)

    switch ((Normalize-Text $Status).ToUpperInvariant()) {
        "FAIL" { return 3 }
        "FAILED" { return 3 }
        "ERROR" { return 3 }
        "BLOCKED" { return 3 }
        "WARN" { return 2 }
        "WARNING" { return 2 }
        "WATCH" { return 2 }
        "UNKNOWN" { return 2 }
        "PASS" { return 1 }
        "OK" { return 1 }
        "GREEN" { return 1 }
        default { return 2 }
    }
}

function Select-Status {
    param($Statuses)

    $highestScore = 0
    $selected = "WARN"
    foreach ($status in @($Statuses)) {
        $normalized = (Normalize-Text $status).ToUpperInvariant()
        if (-not $normalized) {
            continue
        }
        $score = Get-StatusScore $normalized
        if ($score -gt $highestScore) {
            $highestScore = $score
            $selected = $normalized
        }
    }
    return $selected
}

function Convert-ToUtcString {
    param($Value)

    $text = Normalize-Text $Value
    if (-not $text) {
        return ""
    }

    try {
        return ([datetimeoffset]::Parse($text, [System.Globalization.CultureInfo]::InvariantCulture)).UtcDateTime.ToString("o")
    }
    catch {
        return ""
    }
}

function Get-FileLastWriteUtc {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return ""
    }

    return (Get-Item -LiteralPath $Path -Force).LastWriteTimeUtc.ToString("o")
}

function Get-ArtifactTimestampUtc {
    param(
        $Artifact,
        [string]$FallbackPath = ""
    )

    foreach ($field in @("generated_at_utc", "timestamp_utc", "last_updated_utc", "updated_at", "created_at")) {
        $value = Convert-ToUtcString (Get-PropValue -Object $Artifact -Name $field -Default "")
        if ($value) {
            return $value
        }
    }

    if ($FallbackPath) {
        return Get-FileLastWriteUtc -Path $FallbackPath
    }

    return ""
}

function Get-ArtifactMetadata {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$ReferencePath,
        [Parameter(Mandatory = $true)][string]$Role,
        [string]$SourceKind = "artifact"
    )

    $resolvedPath = Resolve-RepoPath -RepoRoot $RepoRoot -PathValue $ReferencePath
    $exists = Test-Path -LiteralPath $resolvedPath
    $itemType = ""
    $lastWriteUtc = ""
    if ($exists) {
        $item = Get-Item -LiteralPath $resolvedPath -Force
        $itemType = if ($item.PSIsContainer) { "directory" } else { "file" }
        $lastWriteUtc = $item.LastWriteTimeUtc.ToString("o")
    }

    return [pscustomobject]@{
        reference_path = $ReferencePath
        path           = $resolvedPath
        role           = $Role
        source_kind    = $SourceKind
        exists         = [bool]$exists
        item_type      = $itemType
        last_write_utc = $lastWriteUtc
    }
}

function Get-ManualRole {
    param($Component)

    $explicit = Normalize-Text (Get-PropValue -Object $Component -Name "role" -Default "")
    if ($explicit) {
        return $explicit
    }

    switch ((Normalize-Text (Get-PropValue -Object $Component -Name "component_id" -Default "")).ToLowerInvariant()) {
        "mason" { return "core orchestrator" }
        "athena" { return "owner cockpit" }
        "onyx" { return "tenant workspace" }
        default { return "managed component" }
    }
}

function Get-PurposeSummary {
    param($Component)

    $explicit = Normalize-Text (Get-PropValue -Object $Component -Name "purpose_summary" -Default "")
    if ($explicit) {
        return $explicit
    }

    $description = Normalize-Text (Get-PropValue -Object $Component -Name "description" -Default "")
    if ($description) {
        return $description
    }

    return ("Live manual for {0}." -f (Normalize-Text (Get-PropValue -Object $Component -Name "display_name" -Default "component")))
}

function New-ActionItem {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Reason,
        [string]$SourceTruthPath = "",
        [string]$RiskLevel = "R1",
        [string]$ActionPosture = "safe",
        [string]$EvidenceType = "artifact-observed"
    )

    return [pscustomobject]@{
        title             = $Title
        reason            = $Reason
        source_truth_path = $SourceTruthPath
        risk_level        = $RiskLevel
        action_posture    = $ActionPosture
        evidence_type     = $EvidenceType
    }
}

function New-WarningItem {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$Status,
        [Parameter(Mandatory = $true)][string]$Reason,
        [string]$SourceTruthPath = "",
        [string]$RecommendedAction = ""
    )

    return [pscustomobject]@{
        title              = $Title
        status             = $Status
        reason             = $Reason
        source_truth_path  = $SourceTruthPath
        recommended_action = $RecommendedAction
    }
}

function New-RecentChange {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][string]$ObservedAtUtc,
        [Parameter(Mandatory = $true)][string]$Summary,
        [string]$SourceTruthPath = "",
        [string]$Provenance = "artifact-observed"
    )

    return [pscustomobject]@{
        title             = $Title
        observed_at_utc   = $ObservedAtUtc
        summary           = $Summary
        source_truth_path = $SourceTruthPath
        provenance        = $Provenance
    }
}

function New-InterfaceItem {
    param(
        [Parameter(Mandatory = $true)][string]$Kind,
        [Parameter(Mandatory = $true)][string]$Value,
        [string]$Detail = ""
    )

    return [pscustomobject]@{
        kind   = $Kind
        value  = $Value
        detail = $Detail
    }
}

$repoRoot = Resolve-RepoRoot -OverrideRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$docsDir = Join-Path $reportsDir "docs"
$indexPath = Join-Path $reportsDir "live_docs_index.json"
$summaryPath = Join-Path $reportsDir "live_docs_summary.json"
$docsRegistryPath = Join-Path $repoRoot "config\component_docs_registry.json"
$componentRegistryPath = Join-Path $repoRoot "config\component_registry.json"
$toolRegistryPath = Join-Path $repoRoot "config\tool_registry.json"
$portsPath = Join-Path $repoRoot "config\ports.json"
$systemValidationPath = Join-Path $reportsDir "system_validation_last.json"
$hostHealthPath = Join-Path $reportsDir "host_health_last.json"
$runtimePosturePath = Join-Path $reportsDir "runtime_posture_last.json"
$environmentProfilePath = Join-Path $reportsDir "environment_profile_last.json"
$selfImprovementPath = Join-Path $reportsDir "self_improvement_governor_last.json"
$teacherBudgetPath = Join-Path $reportsDir "teacher_call_budget_last.json"
$billingSummaryPath = Join-Path $reportsDir "billing_summary.json"
$securityPosturePath = Join-Path $reportsDir "security_posture.json"
$tenantSafetyPath = Join-Path $reportsDir "tenant_safety_report.json"
$mirrorUpdatePath = Join-Path $reportsDir "mirror_update_last.json"
$startRunPath = Join-Path $reportsDir "start\start_run_last.json"
$stackPidsPath = Join-Path $repoRoot "state\knowledge\stack_pids.json"
$approvalsPosturePath = Join-Path $reportsDir "approvals_posture.json"

$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
$portsJson = Read-JsonSafe -Path $portsPath -Default @{ ports = @{ mason_api = 8383; seed_api = 8109; bridge = 8484; athena = 8000; onyx = 5353 }; bind_host = "127.0.0.1" }
$validationArtifact = Read-JsonSafe -Path $systemValidationPath -Default @{}
$hostHealthArtifact = Read-JsonSafe -Path $hostHealthPath -Default @{}
$runtimePostureArtifact = Read-JsonSafe -Path $runtimePosturePath -Default @{}
$environmentProfileArtifact = Read-JsonSafe -Path $environmentProfilePath -Default @{}
$selfImprovementArtifact = Read-JsonSafe -Path $selfImprovementPath -Default @{}
$teacherBudgetArtifact = Read-JsonSafe -Path $teacherBudgetPath -Default @{}
$billingSummaryArtifact = Read-JsonSafe -Path $billingSummaryPath -Default @{}
$securityPostureArtifact = Read-JsonSafe -Path $securityPosturePath -Default @{}
$tenantSafetyArtifact = Read-JsonSafe -Path $tenantSafetyPath -Default @{}
$mirrorUpdateArtifact = Read-JsonSafe -Path $mirrorUpdatePath -Default @{}
$startRunArtifact = Read-JsonSafe -Path $startRunPath -Default @{}
$stackPidsArtifact = Read-JsonSafe -Path $stackPidsPath -Default @{}
$approvalsPostureArtifact = Read-JsonSafe -Path $approvalsPosturePath -Default @{}
$docsRegistryArtifact = Read-JsonSafe -Path $docsRegistryPath -Default @{ version = 1; components = @() }
$componentRegistryArtifact = Read-JsonSafe -Path $componentRegistryPath -Default @{ version = 1; components = @() }
$toolRegistryArtifact = Read-JsonSafe -Path $toolRegistryPath -Default @{ version = 2; tools = @() }

$sectionLookup = @{}
foreach ($section in @((Get-PropValue -Object $validationArtifact -Name "sections" -Default @()))) {
    $sectionName = Normalize-Text (Get-PropValue -Object $section -Name "section_name" -Default "")
    if ($sectionName) {
        $sectionLookup[$sectionName.ToLowerInvariant()] = $section
    }
}

$mergedComponents = [System.Collections.Generic.List[object]]::new()
$seenComponentIds = [System.Collections.Generic.HashSet[string]]::new()
$sortSeed = 100

foreach ($component in @((Get-PropValue -Object $docsRegistryArtifact -Name "components" -Default @()))) {
    $componentId = Normalize-Text (Get-PropValue -Object $component -Name "component_id" -Default "")
    if (-not $componentId) {
        continue
    }

    [void]$mergedComponents.Add([pscustomobject]@{
        component_id         = $componentId
        display_name         = Normalize-Text (Get-PropValue -Object $component -Name "display_name" -Default $componentId)
        owner_surface        = Normalize-Text (Get-PropValue -Object $component -Name "owner_surface" -Default "internal")
        category             = Normalize-Text (Get-PropValue -Object $component -Name "category" -Default "generic")
        description          = Normalize-Text (Get-PropValue -Object $component -Name "description" -Default ("Live manual for {0}." -f $componentId))
        role                 = Normalize-Text (Get-PropValue -Object $component -Name "role" -Default "")
        purpose_summary      = Normalize-Text (Get-PropValue -Object $component -Name "purpose_summary" -Default "")
        entrypoints          = @(Normalize-StringList (Get-PropValue -Object $component -Name "entrypoints" -Default @()))
        ports                = @(Normalize-StringList (Get-PropValue -Object $component -Name "ports" -Default @()))
        primary_artifacts    = @(Normalize-StringList (Get-PropValue -Object $component -Name "primary_artifacts" -Default @()))
        supporting_artifacts = @(Normalize-StringList (Get-PropValue -Object $component -Name "supporting_artifacts" -Default @()))
        dependencies         = @(Normalize-StringList (Get-PropValue -Object $component -Name "dependencies" -Default @()))
        capabilities         = @(Normalize-StringList (Get-PropValue -Object $component -Name "capabilities" -Default @()))
        validation_sections  = @(Normalize-StringList (Get-PropValue -Object $component -Name "validation_sections" -Default @()))
        visible_in_athena    = [bool](Get-PropValue -Object $component -Name "visible_in_athena" -Default $true)
        docs_enabled         = [bool](Get-PropValue -Object $component -Name "docs_enabled" -Default $true)
        sort_order           = [int](Get-PropValue -Object $component -Name "sort_order" -Default $sortSeed)
    })
    [void]$seenComponentIds.Add($componentId.ToLowerInvariant())
    $sortSeed += 10
}

foreach ($component in @((Get-PropValue -Object $componentRegistryArtifact -Name "components" -Default @()))) {
    $componentId = Normalize-Text (Get-PropValue -Object $component -Name "id" -Default "")
    if (-not $componentId -or $seenComponentIds.Contains($componentId.ToLowerInvariant())) {
        continue
    }

    $defaultSections = switch ($componentId.ToLowerInvariant()) {
        "mason" { @("stack/base", "memory/ingest/context pack", "unified improvement queue", "trust/autonomy ladder", "tool factory", "self-improvement governor", "security/legal/tenant safety", "environment adaptation", "mirror/checkpoint state") }
        "athena" { @("Athena") }
        "onyx" { @("Onyx", "tenant/onboarding/business profile", "recommendations", "billing/entitlements") }
        default { @() }
    }

    [void]$mergedComponents.Add([pscustomobject]@{
        component_id         = $componentId
        display_name         = Normalize-Text (Get-PropValue -Object $component -Name "label" -Default $componentId)
        owner_surface        = "internal"
        category             = Normalize-Text (Get-PropValue -Object $component -Name "type" -Default "generic")
        description          = Normalize-Text ("Autogenerated live manual for {0}." -f (Get-PropValue -Object $component -Name "label" -Default $componentId))
        role                 = ""
        purpose_summary      = ""
        entrypoints          = @()
        ports                = @()
        primary_artifacts    = @()
        supporting_artifacts = @(Normalize-StringList (Get-PropValue -Object $component -Name "status_sources" -Default @()))
        dependencies         = @()
        capabilities         = @()
        validation_sections  = @($defaultSections)
        visible_in_athena    = $true
        docs_enabled         = $true
        sort_order           = $sortSeed
    })
    [void]$seenComponentIds.Add($componentId.ToLowerInvariant())
    $sortSeed += 10
}

$baselineTag = Normalize-Text (Get-PropValue -Object $validationArtifact -Name "baseline_tag" -Default (Get-PropValue -Object $startRunArtifact -Name "baseline_tag" -Default (Get-PropValue -Object $startRunArtifact -Name "mode" -Default "")))
$bindHost = Normalize-Text (Get-PropValue -Object $portsJson -Name "bind_host" -Default "127.0.0.1")
$portsNode = Get-PropValue -Object $portsJson -Name "ports" -Default @{}
$networkPostureNode = Get-PropValue -Object $environmentProfileArtifact -Name "network_posture" -Default @{}
$tenantNode = Get-PropValue -Object $billingSummaryArtifact -Name "tenant" -Default @{}
$approvalsCountsNode = Get-PropValue -Object $approvalsPostureArtifact -Name "counts" -Default @{}
$stackPidPresenceNode = Get-PropValue -Object (Get-PropValue -Object $hostHealthArtifact -Name "mason_runtime_health" -Default @{}) -Name "stack_pid_presence" -Default @{}

$manuals = [System.Collections.Generic.List[object]]::new()
$summaryComponents = [System.Collections.Generic.List[object]]::new()
$componentsWithWarnings = [System.Collections.Generic.List[string]]::new()
$componentsHealthy = [System.Collections.Generic.List[string]]::new()
$componentsBlocked = [System.Collections.Generic.List[string]]::new()
$staleComponentIds = [System.Collections.Generic.List[string]]::new()

foreach ($component in @($mergedComponents | Where-Object { $_.docs_enabled } | Sort-Object sort_order, display_name)) {
    $matchedSections = [System.Collections.Generic.List[object]]::new()
    $statusInputs = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[object]]::new()
    $warningSeen = [System.Collections.Generic.HashSet[string]]::new()
    $safeActions = [System.Collections.Generic.List[object]]::new()
    $safeActionSeen = [System.Collections.Generic.HashSet[string]]::new()
    $founderActions = [System.Collections.Generic.List[object]]::new()
    $founderActionSeen = [System.Collections.Generic.HashSet[string]]::new()
    $blockedActions = [System.Collections.Generic.List[object]]::new()
    $blockedActionSeen = [System.Collections.Generic.HashSet[string]]::new()
    $operatorChecks = [System.Collections.Generic.List[object]]::new()
    $sourceTruthPaths = [System.Collections.Generic.List[string]]::new()

    foreach ($sectionName in @($component.validation_sections)) {
        $lookupKey = (Normalize-Text $sectionName).ToLowerInvariant()
        if (-not $lookupKey -or -not $sectionLookup.ContainsKey($lookupKey)) {
            continue
        }

        $section = $sectionLookup[$lookupKey]
        [void]$matchedSections.Add($section)
        [void]$statusInputs.Add((Normalize-Text (Get-PropValue -Object $section -Name "status" -Default "WARN")).ToUpperInvariant())

        $sectionStatus = (Normalize-Text (Get-PropValue -Object $section -Name "status" -Default "WARN")).ToUpperInvariant()
        $sectionLabel = Normalize-Text (Get-PropValue -Object $section -Name "section_name" -Default "Validation section")
        $sectionAction = Normalize-Text (Get-PropValue -Object $section -Name "recommended_next_action" -Default "Review the latest validator findings.")
        $sectionPath = Normalize-Text (Get-PropValue -Object $section -Name "relevant_log_or_artifact_path" -Default "")
        Add-UniqueString -Target $sourceTruthPaths -Value $sectionPath

        if ($sectionStatus -ne "PASS") {
            $warningItem = New-WarningItem -Title $sectionLabel -Status $sectionStatus -Reason $sectionAction -SourceTruthPath $sectionPath -RecommendedAction $sectionAction
            Add-UniqueObject -Target $warnings -SeenKeys $warningSeen -Object $warningItem -Key ($warningItem.title + "|" + $warningItem.reason + "|" + $warningItem.source_truth_path)

            $founderAction = New-ActionItem -Title $sectionLabel -Reason $sectionAction -SourceTruthPath $sectionPath -RiskLevel ($(if ($sectionStatus -eq "FAIL") { "R2" } else { "R1" })) -ActionPosture ($(if ($sectionStatus -eq "FAIL") { "review_needed" } else { "safe" }))
            Add-UniqueObject -Target $founderActions -SeenKeys $founderActionSeen -Object $founderAction -Key ($founderAction.title + "|" + $founderAction.reason + "|" + $founderAction.source_truth_path)
            if ($sectionStatus -ne "FAIL") {
                $safeAction = New-ActionItem -Title $sectionLabel -Reason $sectionAction -SourceTruthPath $sectionPath -RiskLevel "R1" -ActionPosture "safe"
                Add-UniqueObject -Target $safeActions -SeenKeys $safeActionSeen -Object $safeAction -Key ($safeAction.title + "|" + $safeAction.reason + "|" + $safeAction.source_truth_path)
            }
        }

        foreach ($check in @((Get-PropValue -Object $section -Name "checks" -Default @()))) {
            $checkObject = [pscustomobject]@{
                section_name = $sectionLabel
                name         = Normalize-Text (Get-PropValue -Object $check -Name "name" -Default "")
                status       = (Normalize-Text (Get-PropValue -Object $check -Name "status" -Default "WARN")).ToUpperInvariant()
                detail       = Normalize-Text (Get-PropValue -Object $check -Name "detail" -Default "")
                path         = Normalize-Text (Get-PropValue -Object $check -Name "path" -Default "")
                next_action  = Normalize-Text (Get-PropValue -Object $check -Name "next_action" -Default "")
            }
            [void]$operatorChecks.Add($checkObject)
            Add-UniqueString -Target $sourceTruthPaths -Value $checkObject.path

            if ($checkObject.status -in @("WARN", "FAIL")) {
                $warningItem = New-WarningItem -Title ($(if ($checkObject.name) { $checkObject.name } else { $sectionLabel })) -Status $checkObject.status -Reason ($(if ($checkObject.detail) { $checkObject.detail } else { "Live validator warning detected." })) -SourceTruthPath $checkObject.path -RecommendedAction $checkObject.next_action
                Add-UniqueObject -Target $warnings -SeenKeys $warningSeen -Object $warningItem -Key ($warningItem.title + "|" + $warningItem.reason + "|" + $warningItem.source_truth_path)
            }
        }
    }

    if ($statusInputs.Count -eq 0) {
        [void]$statusInputs.Add("WARN")
    }

    $componentStatus = Select-Status -Statuses $statusInputs
    $statusReason = if ($componentStatus -eq "PASS") { "Mapped validator sections are passing and required live artifacts are readable." } elseif ($warnings.Count -gt 0) { Normalize-Text $warnings[0].reason } else { "Current live status requires operator review." }

    if ($founderActions.Count -eq 0 -and $componentStatus -eq "PASS") {
        $baselineFounderAction = New-ActionItem -Title "Healthy baseline" -Reason "No founder-only action is required for this component right now." -SourceTruthPath $systemValidationPath -RiskLevel "R1" -ActionPosture "safe"
        Add-UniqueObject -Target $founderActions -SeenKeys $founderActionSeen -Object $baselineFounderAction -Key ($baselineFounderAction.title + "|" + $baselineFounderAction.reason)
    }

    if ($safeActions.Count -eq 0) {
        $baselineSafeAction = New-ActionItem -Title "Baseline posture" -Reason "No immediate Mason-safe action is required for this component." -SourceTruthPath $systemValidationPath -RiskLevel "R1" -ActionPosture "safe"
        Add-UniqueObject -Target $safeActions -SeenKeys $safeActionSeen -Object $baselineSafeAction -Key ($baselineSafeAction.title + "|" + $baselineSafeAction.reason)
    }

    $loopbackBlockedAction = New-ActionItem -Title "Loopback-only network posture" -Reason "Public or non-loopback exposure remains guarded; keep this component on the 127.0.0.1 loopback contract." -SourceTruthPath $portsPath -RiskLevel "R2" -ActionPosture "guarded"
    Add-UniqueObject -Target $blockedActions -SeenKeys $blockedActionSeen -Object $loopbackBlockedAction -Key ($loopbackBlockedAction.title + "|" + $loopbackBlockedAction.reason)

    if ($component.component_id -in @("mason", "onyx") -and [bool](Get-PropValue -Object $billingSummaryArtifact -Name "money_actions_require_approval" -Default $true)) {
        $moneyBlockedAction = New-ActionItem -Title "Live money actions stay approval-gated" -Reason "Billing posture remains approval-gated until the external provider is intentionally configured for live money." -SourceTruthPath $billingSummaryPath -RiskLevel "R3" -ActionPosture "blocked"
        Add-UniqueObject -Target $blockedActions -SeenKeys $blockedActionSeen -Object $moneyBlockedAction -Key ($moneyBlockedAction.title + "|" + $moneyBlockedAction.reason)
    }

    if ($component.component_id -eq "mason") {
        $governorBlockedAction = New-ActionItem -Title "Teacher-backed self-improvement cannot bypass the governor" -Reason "Weak, expensive, or approval-gated teacher-backed improvements must not stage directly into runtime changes." -SourceTruthPath $selfImprovementPath -RiskLevel "R3" -ActionPosture "blocked"
        Add-UniqueObject -Target $blockedActions -SeenKeys $blockedActionSeen -Object $governorBlockedAction -Key ($governorBlockedAction.title + "|" + $governorBlockedAction.reason)
    }

    if ([bool](Get-PropValue -Object (Get-PropValue -Object $hostHealthArtifact -Name "uptime" -Default @{}) -Name "pending_reboot" -Default $false) -and $component.component_id -in @("mason", "athena")) {
        $rebootAction = New-ActionItem -Title "Pending reboot needs scheduling" -Reason "The host reports a pending reboot; schedule it before heavier maintenance or long founder sessions." -SourceTruthPath $hostHealthPath -RiskLevel "R1" -ActionPosture "review_needed"
        Add-UniqueObject -Target $founderActions -SeenKeys $founderActionSeen -Object $rebootAction -Key ($rebootAction.title + "|" + $rebootAction.reason)
    }

    if ($component.component_id -eq "mason" -and (Normalize-Text (Get-PropValue -Object $securityPostureArtifact -Name "overall_status" -Default "")).ToLowerInvariant() -eq "watch") {
        $securityAction = New-ActionItem -Title "Review security posture watch items" -Reason "Security posture is still watch; clear the remaining tenant isolation and governance watch items before widening autonomy." -SourceTruthPath $securityPosturePath -RiskLevel "R2" -ActionPosture "review_needed"
        Add-UniqueObject -Target $founderActions -SeenKeys $founderActionSeen -Object $securityAction -Key ($securityAction.title + "|" + $securityAction.reason)
    }

    if ($component.component_id -eq "onyx" -and (Normalize-Text (Get-PropValue -Object $tenantSafetyArtifact -Name "status" -Default "")).ToLowerInvariant() -eq "watch") {
        $tenantSafetyAction = New-ActionItem -Title "Review tenant safety warnings" -Reason "Tenant safety is still watch; clear the current tenant isolation warnings before broader tenant rollout." -SourceTruthPath $tenantSafetyPath -RiskLevel "R2" -ActionPosture "review_needed"
        Add-UniqueObject -Target $founderActions -SeenKeys $founderActionSeen -Object $tenantSafetyAction -Key ($tenantSafetyAction.title + "|" + $tenantSafetyAction.reason)
    }

    $requiredArtifactRefs = [System.Collections.Generic.List[string]]::new()
    foreach ($artifactRef in @($component.primary_artifacts + $component.supporting_artifacts)) {
        Add-UniqueString -Target $requiredArtifactRefs -Value $artifactRef
    }

    $discoveredArtifacts = [System.Collections.Generic.List[object]]::new()
    $sourceArtifacts = [System.Collections.Generic.List[object]]::new()
    $artifactSeen = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($artifactRef in @($requiredArtifactRefs)) {
        $role = if ($component.primary_artifacts -contains $artifactRef) { "primary" } else { "supporting" }
        $metadata = Get-ArtifactMetadata -RepoRoot $repoRoot -ReferencePath $artifactRef -Role $role -SourceKind "required_artifact"
        [void]$discoveredArtifacts.Add($metadata)
        Add-UniqueObject -Target $sourceArtifacts -SeenKeys $artifactSeen -Object $metadata -Key $metadata.path
        Add-UniqueString -Target $sourceTruthPaths -Value $metadata.path
    }

    foreach ($truthPath in @(
        $systemValidationPath,
        $hostHealthPath,
        $runtimePosturePath,
        $environmentProfilePath,
        $selfImprovementPath,
        $teacherBudgetPath,
        $billingSummaryPath,
        $securityPosturePath,
        $tenantSafetyPath,
        $mirrorUpdatePath,
        $startRunPath,
        $stackPidsPath,
        $componentRegistryPath,
        $docsRegistryPath,
        $toolRegistryPath,
        $portsPath,
        $approvalsPosturePath
    )) {
        Add-UniqueString -Target $sourceTruthPaths -Value $truthPath
        $metadata = Get-ArtifactMetadata -RepoRoot $repoRoot -ReferencePath $truthPath -Role "truth_source" -SourceKind "truth_source"
        Add-UniqueObject -Target $sourceArtifacts -SeenKeys $artifactSeen -Object $metadata -Key $metadata.path
    }

    $contractPorts = [System.Collections.Generic.List[object]]::new()
    $healthEndpoints = [System.Collections.Generic.List[string]]::new()
    $interfaces = [System.Collections.Generic.List[object]]::new()
    $interfaceSeen = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($entrypoint in @($component.entrypoints)) {
        $entrypointItem = New-InterfaceItem -Kind "entrypoint" -Value $entrypoint
        Add-UniqueObject -Target $interfaces -SeenKeys $interfaceSeen -Object $entrypointItem -Key ("entrypoint|" + $entrypointItem.value)
        if ($entrypoint -match '^https?://127\.0\.0\.1') {
            Add-UniqueString -Target $healthEndpoints -Value $entrypoint
        }
    }

    foreach ($portKey in @($component.ports)) {
        $portNumber = [int](Get-PropValue -Object $portsNode -Name $portKey -Default 0)
        if ($portNumber -le 0) {
            continue
        }

        $contractPort = [pscustomobject]@{
            port_key  = $portKey
            port      = $portNumber
            bind_host = $bindHost
        }
        [void]$contractPorts.Add($contractPort)
        Add-UniqueObject -Target $interfaces -SeenKeys $interfaceSeen -Object (New-InterfaceItem -Kind "port" -Value ("{0}:{1}" -f $bindHost, $portNumber) -Detail $portKey) -Key ("port|" + $portKey + "|" + $portNumber)

        foreach ($endpoint in @(
            switch ($portKey) {
                "mason_api" { "http://127.0.0.1:$portNumber/health" }
                "seed_api" { "http://127.0.0.1:$portNumber/health" }
                "bridge" { "http://127.0.0.1:$portNumber/health" }
                "athena" { @("http://127.0.0.1:$portNumber/api/health", "http://127.0.0.1:$portNumber/athena/", "http://127.0.0.1:$portNumber/api/stack_status") }
                "onyx" { @("http://127.0.0.1:$portNumber/", "http://127.0.0.1:$portNumber/main.dart.js") }
                default { @() }
            }
        )) {
            Add-UniqueString -Target $healthEndpoints -Value $endpoint
            Add-UniqueObject -Target $interfaces -SeenKeys $interfaceSeen -Object (New-InterfaceItem -Kind "health_endpoint" -Value $endpoint) -Key ("health|" + $endpoint)
        }
    }

    $recentChanges = [System.Collections.Generic.List[object]]::new()
    $recentChangeSeen = [System.Collections.Generic.HashSet[string]]::new()

    $docsGeneratedChange = New-RecentChange -Title "Live manual regenerated" -ObservedAtUtc $generatedAtUtc -Summary "Live docs were regenerated from current local registries and artifacts." -SourceTruthPath $summaryPath -Provenance "artifact-observed"
    Add-UniqueObject -Target $recentChanges -SeenKeys $recentChangeSeen -Object $docsGeneratedChange -Key ($docsGeneratedChange.title + "|" + $docsGeneratedChange.observed_at_utc)

    $validationTimestamp = Get-ArtifactTimestampUtc -Artifact $validationArtifact -FallbackPath $systemValidationPath
    if ($validationTimestamp) {
        $validatorChange = New-RecentChange -Title "Validator snapshot refreshed" -ObservedAtUtc $validationTimestamp -Summary ("Validator overall_status={0}; this manual uses mapped validator evidence from local artifacts." -f (Normalize-Text (Get-PropValue -Object $validationArtifact -Name "overall_status" -Default "WARN"))) -SourceTruthPath $systemValidationPath -Provenance "artifact-observed"
        Add-UniqueObject -Target $recentChanges -SeenKeys $recentChangeSeen -Object $validatorChange -Key ($validatorChange.title + "|" + $validatorChange.observed_at_utc)
    }

    $environmentTimestamp = Get-ArtifactTimestampUtc -Artifact $environmentProfileArtifact -FallbackPath $environmentProfilePath
    if ($environmentTimestamp) {
        $environmentChange = New-RecentChange -Title "Environment profile observed" -ObservedAtUtc $environmentTimestamp -Summary ("Environment profile reports host_classification={0}; provenance is artifact-observed, not code-confirmed." -f (Normalize-Text (Get-PropValue -Object $environmentProfileArtifact -Name "host_classification" -Default "unknown"))) -SourceTruthPath $environmentProfilePath -Provenance "artifact-observed"
        Add-UniqueObject -Target $recentChanges -SeenKeys $recentChangeSeen -Object $environmentChange -Key ($environmentChange.title + "|" + $environmentChange.observed_at_utc)
    }

    $runtimeTimestamp = Get-ArtifactTimestampUtc -Artifact $runtimePostureArtifact -FallbackPath $runtimePosturePath
    if ($runtimeTimestamp) {
        $runtimeChange = New-RecentChange -Title "Runtime posture refreshed" -ObservedAtUtc $runtimeTimestamp -Summary ("Runtime posture is {0} / throttle {1}; provenance is artifact-observed." -f (Normalize-Text (Get-PropValue -Object $runtimePostureArtifact -Name "heavy_jobs_posture" -Default "n/a")), (Normalize-Text (Get-PropValue -Object $runtimePostureArtifact -Name "throttle_guidance" -Default "n/a"))) -SourceTruthPath $runtimePosturePath -Provenance "artifact-observed"
        Add-UniqueObject -Target $recentChanges -SeenKeys $recentChangeSeen -Object $runtimeChange -Key ($runtimeChange.title + "|" + $runtimeChange.observed_at_utc)
    }

    $startTimestamp = Get-ArtifactTimestampUtc -Artifact $startRunArtifact -FallbackPath $startRunPath
    if ($startTimestamp -and $component.component_id -in @("mason", "athena", "onyx")) {
        $startChange = New-RecentChange -Title "Start baseline refreshed" -ObservedAtUtc $startTimestamp -Summary ("Start artifact overall_status={0}; runtime ownership and loopback listeners were last refreshed from the normal start flow." -f (Normalize-Text (Get-PropValue -Object $startRunArtifact -Name "overall_status" -Default "unknown"))) -SourceTruthPath $startRunPath -Provenance "artifact-observed"
        Add-UniqueObject -Target $recentChanges -SeenKeys $recentChangeSeen -Object $startChange -Key ($startChange.title + "|" + $startChange.observed_at_utc)
    }

    if ($component.component_id -eq "mason") {
        $governorTimestamp = Get-ArtifactTimestampUtc -Artifact $selfImprovementArtifact -FallbackPath $selfImprovementPath
        if ($governorTimestamp) {
            $governorChange = New-RecentChange -Title "Self-improvement governor refreshed" -ObservedAtUtc $governorTimestamp -Summary ("Governor overall_status={0}; teacher-backed work remains quality-gated and local-first." -f (Normalize-Text (Get-PropValue -Object $selfImprovementArtifact -Name "overall_status" -Default "unknown"))) -SourceTruthPath $selfImprovementPath -Provenance "artifact-observed"
            Add-UniqueObject -Target $recentChanges -SeenKeys $recentChangeSeen -Object $governorChange -Key ($governorChange.title + "|" + $governorChange.observed_at_utc)
        }

        $mirrorTimestamp = Get-ArtifactTimestampUtc -Artifact $mirrorUpdateArtifact -FallbackPath $mirrorUpdatePath
        if ($mirrorTimestamp) {
            $mirrorChange = New-RecentChange -Title "Mirror checkpoint updated" -ObservedAtUtc $mirrorTimestamp -Summary ("Mirror checkpoint recorded ok={0}, phase={1}; provenance is artifact-observed." -f ([bool](Get-PropValue -Object $mirrorUpdateArtifact -Name "ok" -Default $false)).ToString().ToLowerInvariant(), (Normalize-Text (Get-PropValue -Object $mirrorUpdateArtifact -Name "phase" -Default "unknown"))) -SourceTruthPath $mirrorUpdatePath -Provenance "artifact-observed"
            Add-UniqueObject -Target $recentChanges -SeenKeys $recentChangeSeen -Object $mirrorChange -Key ($mirrorChange.title + "|" + $mirrorChange.observed_at_utc)
        }
    }

    if ($component.component_id -eq "onyx") {
        $billingTimestamp = Get-ArtifactTimestampUtc -Artifact $billingSummaryArtifact -FallbackPath $billingSummaryPath
        if ($billingTimestamp) {
            $billingChange = New-RecentChange -Title "Billing summary updated" -ObservedAtUtc $billingTimestamp -Summary ("Billing summary reflects plan {0}; live money remains governed by the current provider posture." -f (Normalize-Text (Get-PropValue -Object $tenantNode -Name "plan_id" -Default "unknown"))) -SourceTruthPath $billingSummaryPath -Provenance "artifact-observed"
            Add-UniqueObject -Target $recentChanges -SeenKeys $recentChangeSeen -Object $billingChange -Key ($billingChange.title + "|" + $billingChange.observed_at_utc)
        }

        $tenantSafetyTimestamp = Get-ArtifactTimestampUtc -Artifact $tenantSafetyArtifact -FallbackPath $tenantSafetyPath
        if ($tenantSafetyTimestamp) {
            $tenantChange = New-RecentChange -Title "Tenant safety report observed" -ObservedAtUtc $tenantSafetyTimestamp -Summary ("Tenant safety status={0}; provenance is artifact-observed." -f (Normalize-Text (Get-PropValue -Object $tenantSafetyArtifact -Name "status" -Default "unknown"))) -SourceTruthPath $tenantSafetyPath -Provenance "artifact-observed"
            Add-UniqueObject -Target $recentChanges -SeenKeys $recentChangeSeen -Object $tenantChange -Key ($tenantChange.title + "|" + $tenantChange.observed_at_utc)
        }
    }

    foreach ($artifactEntry in @($sourceArtifacts | Where-Object { $_.exists -and $_.last_write_utc } | Sort-Object last_write_utc -Descending | Select-Object -First 2)) {
        $leaf = Split-Path -Leaf $artifactEntry.path
        $genericChange = New-RecentChange -Title ("Artifact observed: {0}" -f $leaf) -ObservedAtUtc $artifactEntry.last_write_utc -Summary ("Artifact {0} was updated locally; provenance is artifact-observed, not code-confirmed." -f $artifactEntry.reference_path) -SourceTruthPath $artifactEntry.path -Provenance "artifact-observed"
        Add-UniqueObject -Target $recentChanges -SeenKeys $recentChangeSeen -Object $genericChange -Key ($genericChange.title + "|" + $genericChange.observed_at_utc)
    }

    $recentChangesList = @($recentChanges | Sort-Object observed_at_utc -Descending | Select-Object -First 8)
    $staleSources = @(
        $sourceArtifacts |
            Where-Object {
                $_.exists -and
                $_.last_write_utc -and
                $_.path -ne $systemValidationPath -and
                $_.path -ne $indexPath -and
                $_.path -ne $summaryPath -and
                $_.path -notlike (Join-Path $docsDir "*") -and
                $_.last_write_utc -gt $generatedAtUtc
            }
    )
    $isStale = $staleSources.Count -gt 0

    if ($warnings.Count -gt 0 -or $componentStatus -ne "PASS") {
        Add-UniqueString -Target $componentsWithWarnings -Value $component.component_id
    }
    else {
        Add-UniqueString -Target $componentsHealthy -Value $component.component_id
    }

    $blockedCount = @($blockedActions | Where-Object { $_.action_posture -eq "blocked" }).Count
    if ($blockedCount -gt 0) {
        Add-UniqueString -Target $componentsBlocked -Value $component.component_id
    }
    if ($isStale) {
        Add-UniqueString -Target $staleComponentIds -Value $component.component_id
    }

    $warningSummary = [ordered]@{
        total                    = [int]$warnings.Count
        headline                 = $(if ($warnings.Count -gt 0) { Normalize-Text $warnings[0].reason } else { "No current warnings are recorded." })
        highest_severity         = $(if ($warnings.Count -gt 0) { Select-Status -Statuses ($warnings | ForEach-Object { $_.status }) } else { "PASS" })
        blocked_or_guarded_total = [int]@($blockedActions).Count
        stale                    = [bool]$isStale
    }

    $validationSummary = [ordered]@{
        overall_status           = $componentStatus
        matched_section_count    = [int]@($matchedSections).Count
        matched_sections         = @($matchedSections | ForEach-Object {
            [pscustomobject]@{
                section_name            = Normalize-Text (Get-PropValue -Object $_ -Name "section_name" -Default "")
                status                  = Normalize-Text (Get-PropValue -Object $_ -Name "status" -Default "")
                passed_count            = [int](Get-PropValue -Object $_ -Name "passed_count" -Default 0)
                failed_count            = [int](Get-PropValue -Object $_ -Name "failed_count" -Default 0)
                warn_count              = [int](Get-PropValue -Object $_ -Name "warn_count" -Default 0)
                recommended_next_action = Normalize-Text (Get-PropValue -Object $_ -Name "recommended_next_action" -Default "")
                source_path             = Normalize-Text (Get-PropValue -Object $_ -Name "relevant_log_or_artifact_path" -Default "")
            }
        })
        validator_overall_status = Normalize-Text (Get-PropValue -Object $validationArtifact -Name "overall_status" -Default "")
        validator_artifact_path  = $systemValidationPath
        stale                    = [bool]$isStale
        stale_source_count       = [int]$staleSources.Count
    }

    $manualPath = Join-Path $docsDir ("{0}_live_manual.json" -f $component.component_id)
    $manual = [ordered]@{
        component_id                 = $component.component_id
        display_name                 = $component.display_name
        role                         = Get-ManualRole -Component $component
        purpose_summary              = Get-PurposeSummary -Component $component
        current_status               = $componentStatus
        warning_summary              = $warningSummary
        dependencies                 = @($component.dependencies)
        key_endpoints_or_interfaces  = @($interfaces)
        source_artifacts             = @($sourceArtifacts)
        founder_actions              = @($founderActions | Select-Object -First 8)
        mason_safe_actions           = @($safeActions | Select-Object -First 8)
        blocked_or_guarded_actions   = @($blockedActions | Select-Object -First 8)
        recent_changes               = @($recentChangesList)
        validation_summary           = $validationSummary
        generated_at_utc             = $generatedAtUtc
        description                  = $component.description
        current_status_reason        = $statusReason
        baseline_tag                 = $baselineTag
        owner_surface                = $component.owner_surface
        capabilities                 = @($component.capabilities)
        key_entrypoints              = @($component.entrypoints)
        contract_ports               = @($contractPorts)
        health_endpoints             = @($healthEndpoints)
        required_artifacts           = @($requiredArtifactRefs)
        discovered_artifacts         = @($discoveredArtifacts)
        governance_posture           = [ordered]@{
            security_status               = Normalize-Text (Get-PropValue -Object $securityPostureArtifact -Name "overall_status" -Default "")
            tenant_safety_status          = Normalize-Text (Get-PropValue -Object $tenantSafetyArtifact -Name "status" -Default "")
            self_improvement_status       = Normalize-Text (Get-PropValue -Object $selfImprovementArtifact -Name "overall_status" -Default "")
            mirror_status                 = $(if ([bool](Get-PropValue -Object $mirrorUpdateArtifact -Name "ok" -Default $false)) { "PASS" } else { "WARN" })
            billing_provider_mode         = Normalize-Text (Get-PropValue -Object (Get-PropValue -Object $billingSummaryArtifact -Name "provider" -Default @{}) -Name "mode" -Default "")
            money_actions_require_approval = [bool](Get-PropValue -Object $billingSummaryArtifact -Name "money_actions_require_approval" -Default $true)
            bind_host                     = $bindHost
            loopback_network_posture      = Normalize-Text (Get-PropValue -Object $networkPostureNode -Name "network_exposure_posture" -Default "loopback_only")
        }
        approvals_posture            = [ordered]@{
            eligible_total   = [int](Get-PropValue -Object $approvalsCountsNode -Name "eligible_total" -Default 0)
            quarantine_total = [int](Get-PropValue -Object $approvalsCountsNode -Name "quarantine_total" -Default 0)
            pending_total    = [int](Get-PropValue -Object (Get-PropValue -Object $approvalsCountsNode -Name "eligible_by_status" -Default @{}) -Name "pending" -Default 0)
            source_path      = $approvalsPosturePath
        }
        runtime_posture              = [ordered]@{
            environment_id           = Normalize-Text (Get-PropValue -Object $runtimePostureArtifact -Name "environment_id" -Default "")
            host_classification      = Normalize-Text (Get-PropValue -Object $runtimePostureArtifact -Name "host_classification" -Default "")
            learning_posture         = Normalize-Text (Get-PropValue -Object $runtimePostureArtifact -Name "learning_posture" -Default "")
            heavy_jobs_posture       = Normalize-Text (Get-PropValue -Object $runtimePostureArtifact -Name "heavy_jobs_posture" -Default "")
            monitoring_posture       = Normalize-Text (Get-PropValue -Object $runtimePostureArtifact -Name "monitoring_posture" -Default "")
            cleanup_posture          = Normalize-Text (Get-PropValue -Object $runtimePostureArtifact -Name "cleanup_posture" -Default "")
            throttle_guidance        = Normalize-Text (Get-PropValue -Object $runtimePostureArtifact -Name "throttle_guidance" -Default "")
            pending_reboot           = [bool](Get-PropValue -Object (Get-PropValue -Object $hostHealthArtifact -Name "uptime" -Default @{}) -Name "pending_reboot" -Default $false)
            stack_pid_source         = Normalize-Text (Get-PropValue -Object $stackPidPresenceNode -Name "source" -Default "")
            enabled_tools            = @(Normalize-StringList (Get-PropValue -Object $tenantNode -Name "enabled_tools" -Default @()))
            loopback_network_posture = Normalize-Text (Get-PropValue -Object $networkPostureNode -Name "network_exposure_posture" -Default "loopback_only")
        }
        latest_known_warnings        = @($warnings | Select-Object -First 10)
        safe_next_actions            = @($safeActions | Select-Object -First 8)
        operator_checks              = @($operatorChecks | Select-Object -First 24)
        source_truth_paths           = @($sourceTruthPaths)
        last_validator_timestamp_utc = Normalize-Text (Get-PropValue -Object $validationArtifact -Name "timestamp_utc" -Default "")
        docs_version                 = 2
        manual_path                  = $manualPath
        visible_in_athena            = [bool]$component.visible_in_athena
        sort_order                   = [int]$component.sort_order
        stale                        = [bool]$isStale
    }

    [void]$manuals.Add($manual)
    [void]$summaryComponents.Add([pscustomobject]@{
        component_id               = $manual.component_id
        display_name               = $manual.display_name
        role                       = $manual.role
        purpose_summary            = $manual.purpose_summary
        current_status             = $manual.current_status
        current_status_reason      = $manual.current_status_reason
        warning_summary            = $manual.warning_summary
        latest_known_warnings      = @($manual.latest_known_warnings | Select-Object -First 3)
        safe_next_actions          = @($manual.safe_next_actions | Select-Object -First 3)
        founder_actions            = @($manual.founder_actions | Select-Object -First 3)
        mason_safe_actions         = @($manual.mason_safe_actions | Select-Object -First 3)
        blocked_or_guarded_actions = @($manual.blocked_or_guarded_actions | Select-Object -First 3)
        recent_changes             = @($manual.recent_changes | Select-Object -First 3)
        source_artifacts           = @($manual.source_artifacts | Select-Object -First 6)
        validation_summary         = $manual.validation_summary
        manual_path                = $manual.manual_path
        owner_surface              = $manual.owner_surface
        visible_in_athena          = [bool]$manual.visible_in_athena
        sort_order                 = [int]$manual.sort_order
        stale                      = [bool]$manual.stale
    })
}

$sortedSummaryComponents = @($summaryComponents | Sort-Object sort_order, display_name)
$visibleComponents = @($sortedSummaryComponents | Where-Object { $_.visible_in_athena } | Sort-Object sort_order, display_name)
$defaultComponentId = if ($visibleComponents.Count -gt 0) { [string]$visibleComponents[0].component_id } elseif ($sortedSummaryComponents.Count -gt 0) { [string]$sortedSummaryComponents[0].component_id } else { "" }
$summaryStatus = Select-Status -Statuses @($sortedSummaryComponents | ForEach-Object { $_.current_status })
if ($staleComponentIds.Count -gt 0 -and $summaryStatus -eq "PASS") {
    $summaryStatus = "WARN"
}

$indexArtifact = [ordered]@{
    generated_at_utc             = $generatedAtUtc
    latest_generated_at_utc      = $generatedAtUtc
    docs_version                 = 2
    summary_status               = $summaryStatus
    docs_count                   = [int]$sortedSummaryComponents.Count
    components_with_warnings     = @($componentsWithWarnings | Sort-Object -Unique)
    components_healthy           = @($componentsHealthy | Sort-Object -Unique)
    components_blocked           = @($componentsBlocked | Sort-Object -Unique)
    stale_docs_count             = [int](@($staleComponentIds | Sort-Object -Unique)).Count
    stale_components             = @($staleComponentIds | Sort-Object -Unique)
    default_component            = $defaultComponentId
    index_path                   = $indexPath
    summary_path                 = $summaryPath
    component_docs_registry_path = $docsRegistryPath
    components                   = @($sortedSummaryComponents)
}

$summaryArtifact = [ordered]@{
    generated_at_utc               = $generatedAtUtc
    latest_generated_at_utc        = $generatedAtUtc
    summary_status                 = $summaryStatus
    docs_count                     = [int]$sortedSummaryComponents.Count
    visible_docs_count             = [int]$visibleComponents.Count
    default_component              = $defaultComponentId
    latest_validator_timestamp_utc = Normalize-Text (Get-PropValue -Object $validationArtifact -Name "timestamp_utc" -Default "")
    baseline_tag                   = $baselineTag
    component_docs_registry_path   = $docsRegistryPath
    components_with_warnings       = @($componentsWithWarnings | Sort-Object -Unique)
    components_healthy             = @($componentsHealthy | Sort-Object -Unique)
    components_blocked             = @($componentsBlocked | Sort-Object -Unique)
    stale_docs_count               = [int](@($staleComponentIds | Sort-Object -Unique)).Count
    stale_components               = @($staleComponentIds | Sort-Object -Unique)
    components                     = @($sortedSummaryComponents)
}

Write-JsonFile -Path $indexPath -Object $indexArtifact -Depth 24
Write-JsonFile -Path $summaryPath -Object $summaryArtifact -Depth 24
foreach ($manual in @($manuals)) {
    Write-JsonFile -Path $manual.manual_path -Object $manual -Depth 24
}

[ordered]@{
    ok                           = $true
    generated_at_utc             = $generatedAtUtc
    latest_generated_at_utc      = $generatedAtUtc
    docs_version                 = 2
    docs_count                   = [int]$sortedSummaryComponents.Count
    visible_docs_count           = [int]$visibleComponents.Count
    summary_status               = $summaryStatus
    components_with_warnings     = @($componentsWithWarnings | Sort-Object -Unique)
    components_healthy           = @($componentsHealthy | Sort-Object -Unique)
    components_blocked           = @($componentsBlocked | Sort-Object -Unique)
    stale_docs_count             = [int](@($staleComponentIds | Sort-Object -Unique)).Count
    default_component            = $defaultComponentId
    index_path                   = $indexPath
    summary_path                 = $summaryPath
    component_docs_registry_path = $docsRegistryPath
    manual_paths                 = @($manuals | ForEach-Object { $_.manual_path })
    command_run                  = 'powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Generate_Live_Component_Docs.ps1'
    repo_root                    = $repoRoot
} | ConvertTo-Json -Depth 24
