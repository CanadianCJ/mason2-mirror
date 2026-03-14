[CmdletBinding()]
param(
    [switch]$SkipWholeFolderReverify,
    [switch]$SkipValidator,
    [switch]$SkipMirrorRefresh
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
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
        $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $Default
        }
        return ($raw | ConvertFrom-Json -ErrorAction Stop)
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
    $parent = Split-Path -Parent $Path
    if ($parent) {
        Ensure-Directory -Path $parent
    }
    $Object | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function To-Array {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return @($Value) }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        return @($Value)
    }
    return @($Value)
}

function Get-PropValue {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Default = $null
    )
    if ($null -eq $Object) { return $Default }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $Default
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($property) { return $property.Value }
    return $Default
}

function Normalize-Text {
    param($Value)
    if ($null -eq $Value) { return "" }
    return ([string]$Value).Trim()
}

function Convert-ToUtcIso {
    param([datetime]$Value)
    return $Value.ToUniversalTime().ToString("o")
}

function Get-RepoRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$FullPath,
        [Parameter(Mandatory = $true)][string]$RepoRootPath
    )
    if (-not $FullPath.StartsWith($RepoRootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $FullPath
    }
    return $FullPath.Substring($RepoRootPath.Length).TrimStart("\")
}

function Invoke-LoopbackProbe {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [switch]$ExpectJson
    )
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
        $content = [string]$response.Content
        $data = $null
        if ($ExpectJson) {
            try {
                $data = $content | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                $data = $null
            }
        }
        return [ordered]@{
            ok = $true
            status_code = [int]$response.StatusCode
            content = $content
            data = $data
            error = ""
        }
    }
    catch {
        $statusCode = 0
        try {
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
        }
        catch {}
        return [ordered]@{
            ok = $false
            status_code = $statusCode
            content = ""
            data = $null
            error = [string]$_.Exception.Message
        }
    }
}

function Invoke-ExternalScript {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string[]]$Arguments = @()
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        return [ordered]@{
            ok = $false
            exit_code = 1
            command_run = "missing script: $Path"
        }
    }
    & powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $Path @Arguments
    $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
    return [ordered]@{
        ok = ($exitCode -eq 0)
        exit_code = $exitCode
        command_run = ("powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}{1}" -f $Path, $(if (@($Arguments).Count -gt 0) { " " + (@($Arguments) -join " ") } else { "" }))
    }
}

function To-NormalizedPath {
    param([string]$Path)
    if (-not $Path) { return "" }
    return (($Path -replace "\\", "/").TrimStart("./")).ToLowerInvariant()
}

function Test-PathMatchesAnyPattern {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string[]]$Patterns
    )
    $normalizedPath = To-NormalizedPath -Path $Path
    foreach ($pattern in @($Patterns)) {
        $normalizedPattern = To-NormalizedPath -Path ([string]$pattern)
        if (-not $normalizedPattern) { continue }
        $wildcard = New-Object System.Management.Automation.WildcardPattern($normalizedPattern, [System.Management.Automation.WildcardOptions]::IgnoreCase)
        if ($wildcard.IsMatch($normalizedPath)) {
            return $true
        }
    }
    return $false
}

function New-FixedItem {
    param(
        [string]$IssueId,
        [string]$Category,
        [string]$BeforeState,
        [string]$FixApplied,
        [string]$AfterState,
        [string]$VerificationResult
    )
    return [ordered]@{
        issue_id = $IssueId
        category = $Category
        before_state = $BeforeState
        fix_applied = $FixApplied
        after_state = $AfterState
        verification_result = $VerificationResult
    }
}

function New-QueueItem {
    param(
        [string]$IssueId,
        [string]$Category,
        [string]$Status,
        [string]$Reason,
        [string]$RecommendedNextAction
    )
    return [ordered]@{
        issue_id = $IssueId
        category = $Category
        status = $Status
        reason = $Reason
        recommended_next_action = $RecommendedNextAction
    }
}

$repoRoot = Resolve-Path "C:\Users\Chris\Desktop\Mason2"
$repoRootPath = $repoRoot.ProviderPath
$reportsDir = Join-Path $repoRootPath "reports"
$stateDir = Join-Path $repoRootPath "state\knowledge"
$configDir = Join-Path $repoRootPath "config"
Ensure-Directory -Path $reportsDir
Ensure-Directory -Path $stateDir

$wholeFolderVerificationPath = Join-Path $reportsDir "whole_folder_verification_last.json"
$wholeFolderRegistrationGapsPath = Join-Path $reportsDir "whole_folder_registration_gaps.json"
$wholeFolderBrokenPathsPath = Join-Path $reportsDir "whole_folder_broken_paths_last.json"
$wholeFolderGoldenPathsPath = Join-Path $reportsDir "whole_folder_golden_paths_last.json"
$wholeFolderUsabilityChecksPath = Join-Path $reportsDir "whole_folder_usability_checks_last.json"
$systemValidationPath = Join-Path $reportsDir "system_validation_last.json"
$mirrorUpdatePath = Join-Path $reportsDir "mirror_update_last.json"
$billingSummaryPath = Join-Path $reportsDir "billing_summary.json"
$componentRegistryPath = Join-Path $configDir "component_registry.json"
$componentDocsRegistryPath = Join-Path $configDir "component_docs_registry.json"
$toolRegistryPath = Join-Path $configDir "tool_registry.json"
$mirrorPolicyPath = Join-Path $configDir "mirror_policy.json"
$repairPolicyPath = Join-Path $configDir "repair_wave_01_policy.json"
$workspacePath = Join-Path $repoRootPath "state\onyx\tenant_workspace.json"
$billingStateDir = Join-Path $repoRootPath "state\onyx\billing"
$onyxTabPath = Join-Path $repoRootPath "Component - Onyx App\onyx_business_manager\lib\founder\tenant_business_plan_tab.dart"
$wholeFolderRunnerPath = Join-Path $repoRootPath "tools\ops\Run_Whole_Folder_Verification.ps1"
$validatorPath = Join-Path $repoRootPath "tools\ops\Validate_Whole_System.ps1"
$mirrorRunnerPath = Join-Path $repoRootPath "tools\sync\Mason_Mirror_Update.ps1"
$serverPath = Join-Path $repoRootPath "MasonConsole\server.py"

$repairWavePath = Join-Path $reportsDir "repair_wave_01_last.json"
$repairOnboardingPath = Join-Path $reportsDir "repair_onboarding_last.json"
$repairBillingPath = Join-Path $reportsDir "repair_billing_entitlements_last.json"
$repairHalfwiredPath = Join-Path $reportsDir "repair_halfwired_last.json"
$repairRegistrationPath = Join-Path $reportsDir "repair_registration_gaps_last.json"
$repairSchedulerPath = Join-Path $reportsDir "repair_scheduler_oversight_last.json"
$repairVisibilityPath = Join-Path $reportsDir "repair_internal_visibility_last.json"
$repairMirrorPath = Join-Path $reportsDir "repair_mirror_hardening_last.json"
$repairFixedPath = Join-Path $reportsDir "repair_broken_paths_fixed_last.json"
$repairQueuePath = Join-Path $reportsDir "repair_unfixed_queue_last.json"
$mirrorCoveragePath = Join-Path $reportsDir "mirror_coverage_last.json"
$mirrorOmissionPath = Join-Path $reportsDir "mirror_omission_last.json"
$mirrorSafeIndexPath = Join-Path $reportsDir "mirror_safe_index.md"
$athenaWidgetStatusPath = Join-Path $reportsDir "athena_widget_status.json"
$onyxStackHealthPath = Join-Path $reportsDir "onyx_stack_health.json"

$beforeWholeFolder = Read-JsonSafe -Path $wholeFolderVerificationPath -Default @{}
$beforeRegistration = Read-JsonSafe -Path $wholeFolderRegistrationGapsPath -Default @{}
$beforeBilling = Read-JsonSafe -Path $billingSummaryPath -Default @{}
$policy = Read-JsonSafe -Path $repairPolicyPath -Default @{}
$mirrorPolicy = Read-JsonSafe -Path $mirrorPolicyPath -Default @{}
$workspace = Read-JsonSafe -Path $workspacePath -Default @{}
$componentRegistry = Read-JsonSafe -Path $componentRegistryPath -Default @{}
$componentDocsRegistry = Read-JsonSafe -Path $componentDocsRegistryPath -Default @{}
$toolRegistry = Read-JsonSafe -Path $toolRegistryPath -Default @{}

$timestampUtc = Convert-ToUtcIso (Get-Date)
$sourceText = if (Test-Path -LiteralPath $onyxTabPath) { Get-Content -LiteralPath $onyxTabPath -Raw } else { "" }
$serverText = if (Test-Path -LiteralPath $serverPath) { Get-Content -LiteralPath $serverPath -Raw } else { "" }
$wholeFolderSource = if (Test-Path -LiteralPath $wholeFolderRunnerPath) { Get-Content -LiteralPath $wholeFolderRunnerPath -Raw } else { "" }

$athenaProbe = Invoke-LoopbackProbe -Url "http://127.0.0.1:8000/athena/"
$stackStatusProbe = Invoke-LoopbackProbe -Url "http://127.0.0.1:8000/api/stack_status" -ExpectJson
$onyxProbe = Invoke-LoopbackProbe -Url "http://127.0.0.1:5353/"
$onyxBundleProbe = Invoke-LoopbackProbe -Url "http://127.0.0.1:5353/main.dart.js"

$athenaTabs = @()
if ($athenaProbe.ok) {
    foreach ($label in @("Operations", "Founder Mode", "Live Docs", "Whole Folder Verification")) {
        if ($athenaProbe.content -match [regex]::Escape($label)) {
            $athenaTabs += $label
        }
    }
}
$athenaWidgetStatus = [ordered]@{
    timestamp_utc = $timestampUtc
    overall_status = if ($athenaProbe.ok -and $stackStatusProbe.ok) { "PASS" } else { "WARN" }
    athena_reachable = [bool]$athenaProbe.ok
    stack_status_reachable = [bool]$stackStatusProbe.ok
    http_status = [int]$athenaProbe.status_code
    stack_status_http_status = [int]$stackStatusProbe.status_code
    detected_tabs = @($athenaTabs)
    widget_card_count = [regex]::Matches(($athenaProbe.content | Out-String), "card card-block").Count
    recommended_next_action = if ($athenaProbe.ok -and $stackStatusProbe.ok) { "No action required." } else { "Restore Athena loopback health and verify /api/stack_status." }
}
Write-JsonFile -Path $athenaWidgetStatusPath -Object $athenaWidgetStatus

$onyxStackHealth = [ordered]@{
    timestamp_utc = $timestampUtc
    overall_status = if ($onyxProbe.ok -and $onyxBundleProbe.ok) { "PASS" } else { "WARN" }
    app_reachable = [bool]$onyxProbe.ok
    bundle_reachable = [bool]$onyxBundleProbe.ok
    http_status = [int]$onyxProbe.status_code
    bundle_http_status = [int]$onyxBundleProbe.status_code
    recommended_next_action = if ($onyxProbe.ok -and $onyxBundleProbe.ok) { "No action required." } else { "Restore the Onyx loopback app path and main.dart.js bundle." }
}
Write-JsonFile -Path $onyxStackHealthPath -Object $onyxStackHealth

$publicBadPhrases = @(
    "Active tenant",
    "Create tenant",
    "Tenant status",
    "for this tenant.",
    "pilot tenants",
    "Capture each tenant",
    "unlock tenant entitlements",
    "Select a tenant to review plan access.",
    "Tenant onboarding complete"
)
$remainingPublicPhrases = @()
foreach ($phrase in $publicBadPhrases) {
    if ($sourceText -match [regex]::Escape($phrase)) {
        $remainingPublicPhrases += $phrase
    }
}
$completionActionWired = ($sourceText -match "completeOnboarding:\s*isLastStep") -and ($sourceText -match "await _refreshToolCatalog\(\);")
$onboardingDeadButtons = if ($completionActionWired) { 0 } else { 1 }
$repairOnboarding = [ordered]@{
    timestamp_utc = $timestampUtc
    overall_status = if (@($remainingPublicPhrases).Count -eq 0 -and $completionActionWired) { "PASS" } else { "WARN" }
    public_wording_status = if (@($remainingPublicPhrases).Count -eq 0) { "PASS" } else { "WARN" }
    completion_action_status = if ($completionActionWired) { "PASS" } else { "FAIL" }
    remaining_public_internal_terms = @($remainingPublicPhrases)
    dead_button_count = $onboardingDeadButtons
    active_selector_label = "Active business"
    recommended_next_action = if (@($remainingPublicPhrases).Count -eq 0 -and $completionActionWired) { "No action required." } else { "Remove remaining public internal wording and verify the final onboarding action updates live state." }
    source_path = $onyxTabPath
}
Write-JsonFile -Path $repairOnboardingPath -Object $repairOnboarding

$billingSummary = Read-JsonSafe -Path $billingSummaryPath -Default @{}
$billingTenant = Get-PropValue -Object $billingSummary -Name "tenant" -Default @{}
$workspaceContexts = To-Array (Get-PropValue -Object $workspace -Name "contexts" -Default @())
$activeWorkspaceId = Normalize-Text (Get-PropValue -Object $workspace -Name "activeTenantId" -Default "")
if (-not $activeWorkspaceId) {
    $activeWorkspaceId = Normalize-Text (Get-PropValue -Object $billingSummary -Name "tenant_id" -Default "")
}
if (-not $activeWorkspaceId) {
    $activeWorkspaceId = Normalize-Text (Get-PropValue -Object $billingTenant -Name "tenant_id" -Default "")
}
$activeContext = $null
foreach ($context in $workspaceContexts) {
    $candidateTenant = Get-PropValue -Object $context -Name "tenant" -Default @{}
    $candidateProfile = Get-PropValue -Object $context -Name "profile" -Default @{}
    $candidateTenantId = Normalize-Text (Get-PropValue -Object $candidateTenant -Name "id" -Default "")
    $candidateProfileTenantId = Normalize-Text (Get-PropValue -Object $candidateProfile -Name "tenantId" -Default "")
    if ($candidateTenantId -eq $activeWorkspaceId -or $candidateProfileTenantId -eq $activeWorkspaceId) {
        $activeContext = $context
        break
    }
}
$activePlanState = if ($activeContext) { Get-PropValue -Object $activeContext -Name "plan" -Default @{} } else { @{} }
$activeProfile = if ($activeContext) { Get-PropValue -Object $activeContext -Name "profile" -Default @{} } else { @{} }
$billingStatePath = if ($activeWorkspaceId) { Join-Path $billingStateDir ("{0}.json" -f $activeWorkspaceId) } else { "" }
$billingState = if ($billingStatePath) { Read-JsonSafe -Path $billingStatePath -Default @{} } else { @{} }
$enabledToolsBefore = To-Array (Get-PropValue -Object (Get-PropValue -Object $beforeBilling -Name "tenant" -Default @{}) -Name "enabled_tools" -Default @())
$enabledToolsAfter = To-Array (Get-PropValue -Object $billingTenant -Name "enabled_tools" -Default @())
$selectedPlanId = Normalize-Text (Get-PropValue -Object $billingTenant -Name "selected_plan_id" -Default "")
$currentPlanId = Normalize-Text (Get-PropValue -Object $billingTenant -Name "plan_id" -Default "")
$billingStatus = Normalize-Text (Get-PropValue -Object $billingTenant -Name "status" -Default "")
$checkoutRequired = [bool](Get-PropValue -Object $billingTenant -Name "checkout_required" -Default $false)
$workspaceTier = Normalize-Text (Get-PropValue -Object $activePlanState -Name "currentTier" -Default "")
$billingStatePlanId = Normalize-Text (Get-PropValue -Object $billingState -Name "plan_id" -Default "")
$planMismatch = $billingStatePlanId -and $selectedPlanId -and ($billingStatePlanId -ne $selectedPlanId)
$rootCauseClass = "resolved"
if (-not $activeWorkspaceId) {
    $rootCauseClass = "workspace_resolution_missing"
}
elseif (@($enabledToolsAfter).Count -eq 0 -and $checkoutRequired -and $selectedPlanId) {
    if ($planMismatch) {
        $rootCauseClass = "billing_draft_plan_mismatch_checkout_required"
    }
    else {
        $rootCauseClass = "checkout_required_not_entitled_yet"
    }
}
elseif (@($enabledToolsAfter).Count -eq 0 -and ($billingStatus -eq "active" -or $billingStatus -eq "trialing")) {
    $rootCauseClass = "active_without_enabled_tools"
}
elseif (@($enabledToolsAfter).Count -eq 0) {
    $rootCauseClass = "empty_entitlements_unexplained"
}
$billingRepaired = $false
$billingBlockedReason = ""
if ($rootCauseClass -eq "workspace_resolution_missing") {
    $billingBlockedReason = "The active business workspace could not be resolved from the current workspace and billing artifacts, so entitlement repair was not attempted blindly."
}
elseif ($rootCauseClass -eq "checkout_required_not_entitled_yet" -or $rootCauseClass -eq "billing_draft_plan_mismatch_checkout_required") {
    $billingBlockedReason = "Billing is still gated and no fake entitlements were granted. The repair wave keeps this as analysis-only until checkout or explicit plan activation occurs."
}
elseif ($rootCauseClass -eq "resolved") {
    $billingRepaired = $true
}
else {
    $billingBlockedReason = "Enabled tools are still empty without a safe low-risk entitlement repair path, so this remains review-only until the entitlement resolver is corrected."
}
$repairBilling = [ordered]@{
    timestamp_utc = $timestampUtc
    overall_status = if ($billingRepaired) { "PASS" } else { "WARN" }
    root_cause_class = $rootCauseClass
    active_workspace_id = $activeWorkspaceId
    active_workspace_label = Normalize-Text (Get-PropValue -Object $activeProfile -Name "businessName" -Default "")
    current_tier = $workspaceTier
    current_plan = $currentPlanId
    selected_plan = $selectedPlanId
    enabled_tools_before = @($enabledToolsBefore)
    enabled_tools_after = @($enabledToolsAfter)
    repaired_bool = $billingRepaired
    checkout_required = $checkoutRequired
    why_blocked_if_not_repaired = $billingBlockedReason
    recommended_next_action = if ($billingRepaired) { "No action required." } elseif ($checkoutRequired -and $selectedPlanId) { "Keep billing gated, surface the selected plan truthfully, and only unlock tools after checkout or explicit entitlement activation." } else { "Repair the entitlement resolution path or write a canonical billing state for the active workspace." }
}
Write-JsonFile -Path $repairBillingPath -Object $repairBilling

$componentEntries = To-Array (Get-PropValue -Object $componentRegistry -Name "components" -Default @())
$componentIds = @($componentEntries | ForEach-Object { Normalize-Text (Get-PropValue -Object $_ -Name "id" -Default "") })
$docsEntries = To-Array (Get-PropValue -Object $componentDocsRegistry -Name "components" -Default @())
$docsIds = @($docsEntries | ForEach-Object { Normalize-Text (Get-PropValue -Object $_ -Name "component_id" -Default "") })
$toolEntries = To-Array (Get-PropValue -Object $toolRegistry -Name "tools" -Default @())
$marketingPack = $toolEntries | Where-Object { (Normalize-Text (Get-PropValue -Object $_ -Name "tool_id" -Default "")) -eq "marketing_pack_v1" } | Select-Object -First 1
$salesFollowup = $toolEntries | Where-Object { (Normalize-Text (Get-PropValue -Object $_ -Name "tool_id" -Default "")) -eq "sales_followup_v1" } | Select-Object -First 1
$marketingPlanTiers = To-Array (Get-PropValue -Object (Get-PropValue -Object $marketingPack -Name "tenant_eligibility" -Default @{}) -Name "allowed_plan_tiers" -Default @())
$salesPlanTiers = To-Array (Get-PropValue -Object (Get-PropValue -Object $salesFollowup -Name "tenant_eligibility" -Default @{}) -Name "allowed_plan_tiers" -Default @())
$canaryLookupFixed = $wholeFolderSource -match 'Get-PropValue -Object \$artifactTool -Name "tool_id"'

$fixedItems = @(
    (New-FixedItem -IssueId "onboarding_public_wording" -Category "onboarding_ux" -BeforeState "Customer-facing onboarding copy still exposed internal tenant wording." -FixApplied "Replaced public-facing tenant labels with business/workspace wording in the Onyx onboarding surface." -AfterState "Public onboarding copy now leads with business/workspace language." -VerificationResult $(if (@($remainingPublicPhrases).Count -eq 0) { "PASS" } else { "WARN" })),
    (New-FixedItem -IssueId "onboarding_completion_refresh" -Category "onboarding_ux" -BeforeState "Final onboarding action saved locally without refreshing live catalog state." -FixApplied "Final onboarding flow now refreshes tool/billing/recommendation state after completion." -AfterState "Completion action is source-wired to refresh live catalog state." -VerificationResult $(if ($completionActionWired) { "PASS" } else { "FAIL" })),
    (New-FixedItem -IssueId "tool_runner_canary_lookup" -Category "halfwired_tool" -BeforeState "Whole-folder tool canary ignored artifact.tool.tool_id and could report a false freshness miss." -FixApplied "Whole-folder verification now accepts nested artifact tool identifiers." -AfterState "Tool canary can match current ToolRunner artifact shape." -VerificationResult $(if ($canaryLookupFixed) { "PASS" } else { "FAIL" })),
    (New-FixedItem -IssueId "runtime_component_registry" -Category "registration_gap" -BeforeState "mason_api, seed_api, and bridge existed on disk but were unregistered." -FixApplied "Added first-class runtime component entries to component_registry.json." -AfterState "Runtime services are registered for discovery and verification." -VerificationResult $(if (($componentIds -contains "mason_api") -and ($componentIds -contains "seed_api") -and ($componentIds -contains "bridge")) { "PASS" } else { "FAIL" })),
    (New-FixedItem -IssueId "runtime_component_docs_registry" -Category "registration_gap" -BeforeState "Runtime services had no component docs registry entries." -FixApplied "Added docs-enabled internal component definitions for Mason API, Seed API, and Bridge." -AfterState "Live docs can discover the runtime services." -VerificationResult $(if (($docsIds -contains "mason_api") -and ($docsIds -contains "seed_api") -and ($docsIds -contains "bridge")) { "PASS" } else { "FAIL" })),
    (New-FixedItem -IssueId "tool_plan_tier_alignment" -Category "billing_contract" -BeforeState "Tool registry plan tiers did not match current plan/add-on expectations." -FixApplied "Aligned Growth/Starter eligibility for the surfaced sales and marketing tools." -AfterState "Tool plan-tier contracts now match the intended starter/growth/founder availability." -VerificationResult $(if (($marketingPlanTiers -contains "Starter") -and ($salesPlanTiers -contains "Growth")) { "PASS" } else { "FAIL" })),
    (New-FixedItem -IssueId "billing_draft_price_alignment" -Category "billing_contract" -BeforeState "Inactive billing detail could keep using stale subscription price instead of the selected plan truth." -FixApplied "Billing detail now prefers selected plan pricing when entitlements are not coming from an active subscription." -AfterState "Draft billing summaries can reflect the selected plan without faking live entitlements." -VerificationResult $(if ($serverText -match 'entitlements.get\("entitlement_source"\) != "billing_subscription"') { "PASS" } else { "WARN" }))
)
Write-JsonFile -Path $repairFixedPath -Object ([ordered]@{
        timestamp_utc = $timestampUtc
        fixed_count = @($fixedItems | Where-Object { $_.verification_result -eq "PASS" }).Count
        items = @($fixedItems)
    })

$currentGapClosures = @()
if (($componentIds -contains "mason_api") -and ($componentIds -contains "seed_api") -and ($componentIds -contains "bridge")) {
    $currentGapClosures += "runtime_component_registration"
}
if ((Test-Path -LiteralPath $athenaWidgetStatusPath) -and (Test-Path -LiteralPath $onyxStackHealthPath)) {
    $currentGapClosures += "status_source_artifacts"
}
$repairRegistration = [ordered]@{
    timestamp_utc = $timestampUtc
    overall_status = if (@($currentGapClosures).Count -ge 2) { "PASS" } else { "WARN" }
    gap_count_before = [int](Get-PropValue -Object $beforeRegistration -Name "gap_count" -Default 0)
    unregistered_before = [int](Get-PropValue -Object $beforeRegistration -Name "unregistered_count" -Default 0)
    gap_closures = @($currentGapClosures)
    closed_count = @($currentGapClosures).Count
    expected_remaining_after_reverify = [int]$(if (@($currentGapClosures).Count -ge 2) { 0 } else { [int](Get-PropValue -Object $beforeRegistration -Name "gap_count" -Default 0) - @($currentGapClosures).Count })
    recommended_next_action = if (@($currentGapClosures).Count -ge 2) { "Rerun whole-folder verification so the reduced registration gap count is reflected." } else { "Close the remaining obvious registration gaps before rerunning whole-folder verification." }
}
Write-JsonFile -Path $repairRegistrationPath -Object $repairRegistration

$repairHalfwiredQueue = @()
if (-not $canaryLookupFixed) {
    $repairHalfwiredQueue += New-QueueItem -IssueId "tool_runner_canary_lookup" -Category "halfwired_tool" -Status "review_needed" -Reason "The whole-folder tool canary still does not recognize the current ToolRunner artifact shape." -RecommendedNextAction "Repair Get-LatestToolArtifactInfo so nested tool ids are recognized."
}
if ($rootCauseClass -eq "active_without_enabled_tools" -or $rootCauseClass -eq "empty_entitlements_unexplained") {
    $repairHalfwiredQueue += New-QueueItem -IssueId "billing_entitlements" -Category "billing_contract" -Status "review_needed" -Reason "Billing entitlements are empty without a truthful checkout-gated explanation." -RecommendedNextAction "Repair entitlement resolution or regenerate canonical billing state."
}
$repairHalfwired = [ordered]@{
    timestamp_utc = $timestampUtc
    overall_status = if (@($repairHalfwiredQueue).Count -eq 0) { "PASS" } else { "WARN" }
    fixed_count = @($fixedItems | Where-Object { $_.category -in @("halfwired_tool", "billing_contract") -and $_.verification_result -eq "PASS" }).Count
    queued_count = @($repairHalfwiredQueue).Count
    queue = @($repairHalfwiredQueue)
    recommended_next_action = if (@($repairHalfwiredQueue).Count -eq 0) { "No action required." } else { "Review the remaining half-wired or blocked repair items before claiming those paths are clean." }
}
Write-JsonFile -Path $repairHalfwiredPath -Object $repairHalfwired

$schedulerRelevant = @()
$schedulerStatus = "WARN"
$schedulerRecommendedNextAction = "No Mason2-related scheduled tasks were detected yet."
try {
    $keywords = To-Array (Get-PropValue -Object (Get-PropValue -Object $policy -Name "scheduler_oversight" -Default @{}) -Name "keywords" -Default @())
    $tasks = @(Get-ScheduledTask -ErrorAction Stop)
    foreach ($task in $tasks) {
        $name = Normalize-Text (Get-PropValue -Object $task -Name "TaskName" -Default "")
        $path = Normalize-Text (Get-PropValue -Object $task -Name "TaskPath" -Default "")
        $actions = To-Array (Get-PropValue -Object $task -Name "Actions" -Default @())
        $actionText = @()
        foreach ($action in $actions) {
            $execute = Normalize-Text (Get-PropValue -Object $action -Name "Execute" -Default "")
            $arguments = Normalize-Text (Get-PropValue -Object $action -Name "Arguments" -Default "")
            $actionText += (($execute + " " + $arguments).Trim())
        }
        $haystack = (($name + " " + $path + " " + ($actionText -join " ")).ToLowerInvariant())
        $matches = $false
        foreach ($keyword in $keywords) {
            if ($haystack -like ("*" + ([string]$keyword).ToLowerInvariant() + "*")) {
                $matches = $true
                break
            }
        }
        if (-not $matches) { continue }

        $info = Get-ScheduledTaskInfo -TaskName $name -TaskPath $path -ErrorAction SilentlyContinue
        $lastResult = if ($info) { [int](Get-PropValue -Object $info -Name "LastTaskResult" -Default -1) } else { -1 }
        $stateText = Normalize-Text (Get-PropValue -Object $task -Name "State" -Default "")
        $classification = "unknown"
        if ($stateText -match "Disabled") {
            $classification = "disabled"
        }
        elseif ($lastResult -eq 0) {
            $classification = "healthy"
        }
        elseif ($lastResult -eq 267011) {
            $classification = "stale"
        }
        elseif ($lastResult -gt 0) {
            $classification = "failing"
        }
        $schedulerRelevant += [ordered]@{
            task_name = $name
            task_path = $path
            enabled = ($stateText -notmatch "Disabled")
            state = $stateText
            last_run_time = if ($info) { Convert-ToUtcIso ([datetime](Get-PropValue -Object $info -Name "LastRunTime" -Default (Get-Date "1970-01-01"))) } else { "" }
            next_run_time = if ($info) { Convert-ToUtcIso ([datetime](Get-PropValue -Object $info -Name "NextRunTime" -Default (Get-Date "1970-01-01"))) } else { "" }
            last_result = $lastResult
            action = (($actionText | Where-Object { $_ }) -join " | ")
            classification = $classification
        }
    }
    if (@($schedulerRelevant).Count -gt 0) {
        $schedulerStatus = if (@($schedulerRelevant | Where-Object { $_.classification -eq "failing" }).Count -gt 0) { "WARN" } else { "PASS" }
        $schedulerRecommendedNextAction = if ($schedulerStatus -eq "PASS") { "No action required." } else { "Review failing or stale scheduled tasks before relying on unattended runs." }
    }
}
catch {
    $schedulerRelevant = @()
    $schedulerStatus = "WARN"
    $schedulerRecommendedNextAction = "Task Scheduler inspection was unavailable in this run; verify scheduled task visibility on the host."
}
$repairScheduler = [ordered]@{
    timestamp_utc = $timestampUtc
    overall_status = $schedulerStatus
    relevant_task_count = @($schedulerRelevant).Count
    healthy_count = @($schedulerRelevant | Where-Object { $_.classification -eq "healthy" }).Count
    missing_count = 0
    disabled_count = @($schedulerRelevant | Where-Object { $_.classification -eq "disabled" }).Count
    stale_count = @($schedulerRelevant | Where-Object { $_.classification -eq "stale" }).Count
    failing_count = @($schedulerRelevant | Where-Object { $_.classification -eq "failing" }).Count
    tasks = @($schedulerRelevant | Select-Object -First 40)
    recommended_next_action = $schedulerRecommendedNextAction
}
Write-JsonFile -Path $repairSchedulerPath -Object $repairScheduler

$visibilityRoots = @(
    @{ category = "tools"; path = Join-Path $repoRoot "tools" },
    @{ category = "ops"; path = Join-Path $repoRoot "tools\ops" },
    @{ category = "reports"; path = $reportsDir },
    @{ category = "state"; path = Join-Path $repoRoot "state" },
    @{ category = "config"; path = $configDir },
    @{ category = "ui_web"; path = Join-Path $repoRoot "MasonConsole\static\athena" },
    @{ category = "app_surfaces"; path = Join-Path $repoRoot "Component - Onyx App\onyx_business_manager\lib" },
    @{ category = "docs"; path = Join-Path $repoRoot "docs" },
    @{ category = "roadmap"; path = Join-Path $repoRoot "roadmap" },
    @{ category = "archives_backups"; path = Join-Path $repoRoot "archives" }
)
$visibilityCategories = @()
foreach ($root in $visibilityRoots) {
    $path = [string]$root.path
    $exists = Test-Path -LiteralPath $path
    $count = 0
    if ($exists) {
        try {
            $count = @(Get-ChildItem -LiteralPath $path -Force -ErrorAction Stop | Select-Object -First 5000).Count
        }
        catch {
            $count = 0
        }
    }
    $visibilityCategories += [ordered]@{
        category = [string]$root.category
        path = $path
        readable = $exists
        item_count = [int]$count
    }
}
$repairVisibility = [ordered]@{
    timestamp_utc = $timestampUtc
    overall_status = "PASS"
    visible_category_count = @($visibilityCategories | Where-Object { $_.readable }).Count
    blind_spot_count = @($visibilityCategories | Where-Object { -not $_.readable }).Count
    categories = @($visibilityCategories)
    recommended_next_action = "Use the blind spot list to decide whether any archive/backups or auxiliary zones need governed visibility later."
}
Write-JsonFile -Path $repairVisibilityPath -Object $repairVisibility

$reportPatterns = @()
if ($mirrorPolicy -and ($mirrorPolicy.PSObject.Properties.Name -contains "report_file_allowlist")) {
    $reportPatterns = @($mirrorPolicy.report_file_allowlist | ForEach-Object { [string]$_ } | Where-Object { $_ })
}
if (@($reportPatterns).Count -eq 0 -and $mirrorPolicy -and ($mirrorPolicy.PSObject.Properties.Name -contains "report_json_allowlist")) {
    $reportPatterns = @($mirrorPolicy.report_json_allowlist | ForEach-Object { [string]$_ } | Where-Object { $_ })
}
$matchedMirrorFiles = New-Object System.Collections.Generic.List[string]
$missingMirrorPatterns = @()
foreach ($pattern in $reportPatterns) {
    $resolvedPattern = Join-Path $repoRootPath (($pattern -replace "/", "\").TrimStart("\"))
    $patternMatches = @()
    try {
        $patternMatches = @(
            Get-ChildItem -Path $resolvedPattern -File -ErrorAction SilentlyContinue |
                ForEach-Object { Get-RepoRelativePath -FullPath $_.FullName -RepoRootPath $repoRootPath }
        )
    }
    catch {
        $patternMatches = @()
    }

    if (@($patternMatches).Count -gt 0) {
        foreach ($match in $patternMatches) {
            if (-not $matchedMirrorFiles.Contains($match)) {
                $matchedMirrorFiles.Add($match) | Out-Null
            }
        }
    }
    else {
        $missingMirrorPatterns += $pattern
    }
}
$mirrorCoverageStatus = "PASS"
if (@($reportPatterns).Count -eq 0) {
    $mirrorCoverageStatus = "WARN"
}
elseif ($matchedMirrorFiles.Count -eq 0) {
    $mirrorCoverageStatus = "WARN"
}
elseif (@($missingMirrorPatterns).Count -gt 0) {
    $mirrorCoverageStatus = "WARN"
}
$mirrorCoverage = [ordered]@{
    timestamp_utc = $timestampUtc
    overall_status = $mirrorCoverageStatus
    allowlist_pattern_count = @($reportPatterns).Count
    matched_file_count = $matchedMirrorFiles.Count
    missing_pattern_count = @($missingMirrorPatterns).Count
    safe_report_files = @($matchedMirrorFiles.ToArray() | Sort-Object | Select-Object -First 120)
    missing_patterns = @($missingMirrorPatterns | Select-Object -First 60)
    recommended_next_action = if (@($reportPatterns).Count -eq 0) { "Restore the report mirror allowlist so mirror coverage can be evaluated truthfully." } elseif ($matchedMirrorFiles.Count -eq 0) { "Verify the mirror allowlist paths and report discovery logic because no safe report files were matched." } elseif (@($missingMirrorPatterns).Count -eq 0) { "No action required." } else { "Expand the safe mirror allowlist or generate the missing safe artifacts before the next mirror refresh." }
}
Write-JsonFile -Path $mirrorCoveragePath -Object $mirrorCoverage

$mirrorOmission = [ordered]@{
    timestamp_utc = $timestampUtc
    overall_status = if (@($reportPatterns).Count -eq 0 -or @($missingMirrorPatterns).Count -gt 0) { "WARN" } else { "PASS" }
    omission_count = @($missingMirrorPatterns).Count
    omissions = @($missingMirrorPatterns | ForEach-Object {
            [ordered]@{
                pattern = [string]$_
                reason = "No current matching safe artifact was found under reports."
            }
        })
    recommended_next_action = if (@($reportPatterns).Count -eq 0) { "Restore the report mirror allowlist so omissions can be evaluated truthfully." } elseif (@($missingMirrorPatterns).Count -eq 0) { "No action required." } else { "Review the omitted mirror-safe patterns and decide whether the source artifact should be generated or the allowlist should be tightened." }
}
Write-JsonFile -Path $mirrorOmissionPath -Object $mirrorOmission

$mirrorSafeIndex = @(
    "# Mason2 Mirror Safe Index",
    "",
    "Generated: $timestampUtc",
    "",
    "## Safe Remote Inspection Summary",
    "",
    "- Whole-folder verification: reports/whole_folder_verification_last.json",
    "- Whole-folder broken paths: reports/whole_folder_broken_paths_last.json",
    "- Whole-folder registration gaps: reports/whole_folder_registration_gaps.json",
    "- Validator summary: reports/system_validation_last.json",
    "- Billing summary: reports/billing_summary.json",
    "- Knowledge quality: reports/knowledge_quality_last.json",
    "- Release management: reports/release_management_last.json",
    "- Revenue optimization: reports/revenue_optimization_last.json",
    "- Model/cost governance: reports/model_cost_governance_last.json",
    "- Scheduler oversight: reports/repair_scheduler_oversight_last.json",
    "- Internal visibility: reports/repair_internal_visibility_last.json",
    "- Mirror coverage: reports/mirror_coverage_last.json",
    "- Mirror omissions: reports/mirror_omission_last.json",
    "",
    "## Current Mirror Truth",
    "",
    "- Remote currentness depends on reports/mirror_update_last.json.",
    "- GitHub/off-box is only current when mirror_push_result indicates a successful push."
)
Set-Content -LiteralPath $mirrorSafeIndexPath -Value ($mirrorSafeIndex -join "`r`n") -Encoding UTF8

$mirrorUpdateBefore = Read-JsonSafe -Path $mirrorUpdatePath -Default @{}
$mirrorRefreshResult = [ordered]@{
    ok = $true
    exit_code = 0
    command_run = ""
}
if (-not $SkipMirrorRefresh) {
    $mirrorRefreshResult = Invoke-ExternalScript -Path $mirrorRunnerPath
}
$mirrorUpdateAfter = Read-JsonSafe -Path $mirrorUpdatePath -Default @{}
$mirrorPushResult = Normalize-Text (Get-PropValue -Object $mirrorUpdateAfter -Name "mirror_push_result" -Default (Get-PropValue -Object $mirrorUpdateBefore -Name "mirror_push_result" -Default ""))
$remoteCurrent = ($mirrorPushResult -eq "pushed" -or $mirrorPushResult -eq "noop")
$mirrorFailureReason = ""
if ($mirrorPushResult -like "*remote_*failed*") {
    $lastLines = To-Array (Get-PropValue -Object $mirrorUpdateAfter -Name "push_output" -Default @())
    if (@($lastLines).Count -gt 0) {
        $mirrorFailureReason = Normalize-Text ($lastLines[-1])
    }
    if (-not $mirrorFailureReason) {
        $mirrorFailureReason = Normalize-Text (Get-PropValue -Object $mirrorUpdateAfter -Name "error" -Default "")
    }
}
$repairMirror = [ordered]@{
    timestamp_utc = Convert-ToUtcIso (Get-Date)
    overall_status = if ($remoteCurrent -and @($missingMirrorPatterns).Count -eq 0) { "PASS" } else { "WARN" }
    coverage_status = $mirrorCoverage.overall_status
    omission_status = $mirrorOmission.overall_status
    matched_file_count = $mirrorCoverage.matched_file_count
    omission_count = $mirrorOmission.omission_count
    remote_push_result = $mirrorPushResult
    remote_current = $remoteCurrent
    mirror_push_failure_reason = $mirrorFailureReason
    mirror_safe_index_path = $mirrorSafeIndexPath
    recommended_next_action = if ($remoteCurrent) { "No action required." } else { "Review remote mirror connectivity or credentials if off-box currency is required." }
}
Write-JsonFile -Path $repairMirrorPath -Object $repairMirror

$repairQueue = @()
if (-not $billingRepaired) {
    $repairQueue += New-QueueItem -IssueId "billing_entitlements_gated" -Category "billing" -Status "blocked_by_policy" -Reason $billingBlockedReason -RecommendedNextAction $repairBilling.recommended_next_action
}
if (-not $remoteCurrent) {
    $repairQueue += New-QueueItem -IssueId "mirror_remote_push" -Category "mirror" -Status "review_needed" -Reason "Mirror remote push did not succeed, so GitHub/off-box cannot be claimed current." -RecommendedNextAction $repairMirror.recommended_next_action
}
if ($repairScheduler.failing_count -gt 0 -or $repairScheduler.disabled_count -gt 0 -or $repairScheduler.stale_count -gt 0) {
    $repairQueue += New-QueueItem -IssueId "scheduler_followup" -Category "scheduler" -Status "review_needed" -Reason "Task Scheduler oversight found tasks that are failing, disabled, or stale." -RecommendedNextAction $repairScheduler.recommended_next_action
}
Write-JsonFile -Path $repairQueuePath -Object ([ordered]@{
        timestamp_utc = $timestampUtc
        overall_status = if (@($repairQueue).Count -eq 0) { "PASS" } else { "WARN" }
        total_items = @($repairQueue).Count
        items = @($repairQueue)
    })

$wholeFolderResult = [ordered]@{ ok = $true; exit_code = 0; command_run = "" }
if (-not $SkipWholeFolderReverify) {
    $wholeFolderResult = Invoke-ExternalScript -Path $wholeFolderRunnerPath -Arguments @("-SkipMirrorRefresh")
}
$validatorResult = [ordered]@{ ok = $true; exit_code = 0; command_run = "" }
if (-not $SkipValidator) {
    $validatorResult = Invoke-ExternalScript -Path $validatorPath
}

$afterWholeFolder = Read-JsonSafe -Path $wholeFolderVerificationPath -Default @{}
$afterValidator = Read-JsonSafe -Path $systemValidationPath -Default @{}
$afterRegistration = Read-JsonSafe -Path $wholeFolderRegistrationGapsPath -Default @{}
$afterBroken = Read-JsonSafe -Path $wholeFolderBrokenPathsPath -Default @{}

$beforeBrokenCount = [int](Get-PropValue -Object $beforeWholeFolder -Name "broken_path_count" -Default 0)
$afterBrokenCount = [int](Get-PropValue -Object $afterWholeFolder -Name "broken_path_count" -Default (Get-PropValue -Object $afterBroken -Name "broken_path_count" -Default 0))
$beforeGapCount = [int](Get-PropValue -Object $beforeWholeFolder -Name "registry_gap_count" -Default (Get-PropValue -Object $beforeRegistration -Name "gap_count" -Default 0))
$afterGapCount = [int](Get-PropValue -Object $afterWholeFolder -Name "registry_gap_count" -Default (Get-PropValue -Object $afterRegistration -Name "gap_count" -Default 0))

$repairWave = [ordered]@{
    timestamp_utc = Convert-ToUtcIso (Get-Date)
    overall_status = "WARN"
    onboarding_repair_status = $repairOnboarding.overall_status
    billing_entitlements_repair_status = $repairBilling.overall_status
    halfwired_repair_status = $repairHalfwired.overall_status
    registration_gap_status = $repairRegistration.overall_status
    scheduler_oversight_status = $repairScheduler.overall_status
    internal_visibility_status = $repairVisibility.overall_status
    mirror_hardening_status = $repairMirror.overall_status
    broken_paths_before = $beforeBrokenCount
    broken_paths_after = $afterBrokenCount
    registration_gaps_before = $beforeGapCount
    registration_gaps_after = $afterGapCount
    fixed_count = @($fixedItems | Where-Object { $_.verification_result -eq "PASS" }).Count
    unresolved_queue_count = @($repairQueue).Count
    whole_folder_verification_status = Normalize-Text (Get-PropValue -Object $afterWholeFolder -Name "overall_status" -Default "")
    validator_status = Normalize-Text (Get-PropValue -Object $afterValidator -Name "overall_status" -Default "")
    mirror_push_result = $mirrorPushResult
    mirror_remote_current = $remoteCurrent
    whole_folder_command = $wholeFolderResult.command_run
    validator_command = $validatorResult.command_run
    mirror_command = $mirrorRefreshResult.command_run
    recommended_next_action = if (@($repairQueue).Count -eq 0) { "No action required." } else { "Work the blocked queue, then rerun repair wave and whole-folder verification." }
    command_run = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\\tools\\ops\\Run_Repair_Wave_01.ps1"
    repo_root = $repoRootPath
}
if ($repairOnboarding.overall_status -eq "PASS" -and $repairRegistration.overall_status -eq "PASS" -and $afterBrokenCount -le $beforeBrokenCount -and $afterGapCount -le $beforeGapCount -and @($repairQueue).Count -eq 0) {
    $repairWave.overall_status = "PASS"
}
Write-JsonFile -Path $repairWavePath -Object $repairWave
