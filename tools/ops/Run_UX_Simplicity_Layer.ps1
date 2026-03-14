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

function Invoke-LoopbackJson {
    param([string]$Url)

    try {
        return Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 8
    }
    catch {
        return $null
    }
}

function Test-Contains {
    param(
        [string]$Text,
        [string]$Pattern
    )

    if (-not $Text) {
        return $false
    }
    try {
        return [regex]::IsMatch($Text, $Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
    catch {
        return $Text.IndexOf($Pattern, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
    }
}

function Get-DistinctMatches {
    param(
        [string]$Text,
        [string[]]$Patterns
    )

    $matches = @()
    foreach ($pattern in $Patterns) {
        if (Test-Contains -Text $Text -Pattern [regex]::Escape($pattern)) {
            $matches += $pattern
        }
    }
    return @($matches | Sort-Object -Unique)
}

function Get-ActionDeadCount {
    param(
        [object[]]$Actions,
        [AllowNull()][object]$Controls
    )

    $dead = 0
    foreach ($action in @($Actions)) {
        if (-not $action) {
            continue
        }
        $actionType = Normalize-Text (Get-PropValue -Object $action -Name "action_type" -Default "")
        $actionId = Normalize-Text (Get-PropValue -Object $action -Name "action_id" -Default "")
        switch ($actionType) {
            "control" {
                if (-not $actionId -or -not (Get-PropValue -Object $Controls -Name $actionId -Default $null)) {
                    $dead++
                }
            }
            "open_url" {
                if (-not (Normalize-Text (Get-PropValue -Object $action -Name "url" -Default ""))) {
                    $dead++
                }
            }
            "view" {
                if (-not (Normalize-Text (Get-PropValue -Object $action -Name "view" -Default ""))) {
                    $dead++
                }
            }
            "view_docs" {
                if (-not (Normalize-Text (Get-PropValue -Object $action -Name "component_id" -Default ""))) {
                    $dead++
                }
            }
            "refresh" {
            }
            default {
                $dead++
            }
        }
    }
    return [int]$dead
}

$repoRoot = Resolve-RepoRoot -ExplicitRoot $RepoRoot
$reportsDir = Join-Path $repoRoot "reports"
$configDir = Join-Path $repoRoot "config"
$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"

$uxSimplicityPath = Join-Path $reportsDir "ux_simplicity_last.json"
$athenaFounderUxPath = Join-Path $reportsDir "athena_founder_ux_last.json"
$onyxCustomerUxPath = Join-Path $reportsDir "onyx_customer_ux_last.json"
$approvalSurfacePath = Join-Path $reportsDir "approval_surface_last.json"
$uxRegistryPath = Join-Path $stateKnowledgeDir "ux_simplicity_registry.json"
$uxPolicyPath = Join-Path $configDir "ux_simplicity_policy.json"

$athenaHtmlPath = Join-Path $repoRoot "MasonConsole\static\athena\index.html"
$athenaServerPath = Join-Path $repoRoot "MasonConsole\server.py"
$onyxFounderPath = Join-Path $repoRoot "Component - Onyx App\onyx_business_manager\lib\founder\tenant_business_plan_tab.dart"
$approvalsPosturePath = Join-Path $reportsDir "approvals_posture.json"
$wedgePackFrameworkPath = Join-Path $reportsDir "wedge_pack_framework_last.json"
$stackStatusUrl = "http://127.0.0.1:8000/api/stack_status"

$nowUtc = (Get-Date).ToUniversalTime().ToString("o")
$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_UX_Simplicity_Layer.ps1"

$policy = [ordered]@{
    version = 1
    policy_name = "ux_simplicity_layer"
    plain_english_rules = @(
        "Prefer short, plain-English labels over internal system jargon.",
        "Customer-facing copy should describe business value before implementation detail.",
        "Avoid terms like deterministic, tenant-ready, artifact, and structured recommendation in customer copy."
    )
    no_internal_jargon_rules = @(
        "Onyx customer surfaces must avoid internal Mason and tenant-operations vocabulary.",
        "Athena founder surfaces may use internal/operator terms because Athena is owner-only."
    )
    no_dead_button_rules = @(
        "Every visible interactive button must map to a real UI or backend action.",
        "Disabled buttons must explain why they are unavailable.",
        "Controls that only expose a file path are not acceptable as actions."
    )
    founder_only_athena_rules = @(
        "Athena stays owner-only and loopback-only.",
        "Founder Mode should surface controls, approvals, and docs without exposing them publicly."
    )
    customer_safe_onyx_rules = @(
        "Onyx wording should stay customer-safe, low-jargon, and business-first.",
        "Empty states should explain what to do next in simple language."
    )
    mobile_friendly_layout_rules = @(
        "Founder surfaces should use compact cards and panel navigation.",
        "Avoid endless-scroll founder UX when a panel or card-router pattern is available."
    )
    approval_control_surface_rules = @(
        "Approvals should be visible in Athena with real approve/reject buttons when the backend supports them.",
        "Founder control buttons should point to governed endpoints only."
    )
    action_button_exposure_rules = @(
        "No raw shell execution is exposed in Athena.",
        "Buttons may call signed loopback APIs or local view navigation only."
    )
    progressive_disclosure_rules = @(
        "Show summary first, then details per founder panel.",
        "Customer screens should reveal complexity only when it helps the user."
    )
    clutter_reduction_rules = @(
        "Founder Mode should group related information into panels.",
        "Onyx customer surfaces should reduce intimidating diagnostic phrasing."
    )
}
Write-JsonFile -Path $uxPolicyPath -Data $policy

$athenaHtml = if (Test-Path -LiteralPath $athenaHtmlPath) { Get-Content -LiteralPath $athenaHtmlPath -Raw -Encoding UTF8 } else { "" }
$athenaServer = if (Test-Path -LiteralPath $athenaServerPath) { Get-Content -LiteralPath $athenaServerPath -Raw -Encoding UTF8 } else { "" }
$onyxFounder = if (Test-Path -LiteralPath $onyxFounderPath) { Get-Content -LiteralPath $onyxFounderPath -Raw -Encoding UTF8 } else { "" }

$stackStatus = Invoke-LoopbackJson -Url $stackStatusUrl
$founderPayload = Get-PropValue -Object $stackStatus -Name "founder_mode" -Default $null
$uxPayload = Get-PropValue -Object $stackStatus -Name "ux_simplicity" -Default $null
$controlsPayload = Get-PropValue -Object $stackStatus -Name "controls" -Default $null
$wedgeFramework = Read-JsonSafe -Path $wedgePackFrameworkPath
$approvalsPosture = Read-JsonSafe -Path $approvalsPosturePath

$founderPanelCount = ([regex]::Matches($athenaHtml, 'data-founder-panel=')).Count
$layoutClassification = if ($founderPanelCount -ge 4 -and (Test-Contains -Text $athenaHtml -Pattern "founder-panel-tabs")) { "panel_navigation" } else { "linear_scroll" }
$mobileFriendliness = if ((Test-Contains -Text $athenaHtml -Pattern "@media \(max-width: 980px\)") -and (Test-Contains -Text $athenaHtml -Pattern "founder-panel-tabs")) { "mobile_card_panels" } else { "desktop_bias" }
$approvalActionWired = (Test-Contains -Text $athenaHtml -Pattern "data-approval-decision") -and (Test-Contains -Text $athenaHtml -Pattern "submitApprovalDecision") -and (Test-Contains -Text $athenaServer -Pattern "/api/approvals/decision")
$founderOnlyConfirmed = (Test-Contains -Text $athenaHtml -Pattern "Owner-only Athena surface") -and [bool](Get-PropValue -Object $founderPayload -Name "owner_only" -Default $true)
$componentNavigationReady = (Test-Contains -Text $athenaHtml -Pattern "founderComponentCards") -and (Test-Contains -Text $athenaHtml -Pattern "data-founder-panel=""components""")

$quickActions = @((Get-PropValue -Object $founderPayload -Name "quick_actions" -Default @()))
$componentCards = @((Get-PropValue -Object $founderPayload -Name "component_cards" -Default @()))
$componentActions = @()
foreach ($componentCard in $componentCards) {
    $componentActions += @((Get-PropValue -Object $componentCard -Name "actions" -Default @()))
}
$deadQuickActionCount = Get-ActionDeadCount -Actions $quickActions -Controls $controlsPayload
$deadComponentActionCount = Get-ActionDeadCount -Actions $componentActions -Controls $controlsPayload

$actionableApprovals = @((Get-PropValue -Object (Get-PropValue -Object $founderPayload -Name "approvals_governed_actions" -Default $null) -Name "actionable_items" -Default @()))
$approvalVisibleCount = $actionableApprovals.Count
$approveButtonCount = if ($approvalActionWired) { $approvalVisibleCount } else { 0 }
$rejectButtonCount = if ($approvalActionWired) { $approvalVisibleCount } else { 0 }
$unwiredActionCount = if ($approvalVisibleCount -gt 0 -and -not $approvalActionWired) { $approvalVisibleCount * 2 } else { 0 }
$deadButtonCount = [int]($unwiredActionCount + $deadQuickActionCount + $deadComponentActionCount)
$controlButtonCount = $quickActions.Count

$approvalSurfaceStatus = if ($approvalActionWired) {
    if ($approvalVisibleCount -gt 0) { "actionable" } else { "empty_ready" }
}
else {
    "summary_only"
}

$customerJargonPatterns = @(
    "Deterministic recommendations are generated",
    "No structured recommendations",
    "Tenant tools",
    "tenant-ready tools",
    "linked result artifact",
    "live tool actions",
    "tenant context"
)
$remainingJargon = @(Get-DistinctMatches -Text $onyxFounder -Patterns $customerJargonPatterns)
$customerJargonRisk = if ($remainingJargon.Count -eq 0) { "low" } elseif ($remainingJargon.Count -le 2) { "medium" } else { "high" }
$plainEnglishStatus = if ($remainingJargon.Count -eq 0) { "PASS" } else { "WARN" }
$workflowClarityStatus = if (
    (Test-Contains -Text $onyxFounder -Pattern "Recommended next steps") -and
    (Test-Contains -Text $onyxFounder -Pattern "Available actions") -and
    (Test-Contains -Text $onyxFounder -Pattern "No suggestions are active right now")
) { "PASS" } else { "WARN" }
$onboardingClarityStatus = if (
    (Test-Contains -Text $onyxFounder -Pattern "Complete onboarding") -and
    (Test-Contains -Text $onyxFounder -Pattern "Progress ")
) { "PASS" } else { "WARN" }
$businessTypeRelevanceStatus = if (Normalize-Text (Get-PropValue -Object $wedgeFramework -Name "active_business_category" -Default "")) { "PASS" } else { "WARN" }

$athenaFounderUxStatus = if ($deadButtonCount -eq 0 -and $founderOnlyConfirmed -and $layoutClassification -eq "panel_navigation" -and $componentNavigationReady -and $approvalActionWired) { "PASS" } else { "WARN" }
$onyxCustomerUxStatus = if ($plainEnglishStatus -eq "PASS" -and $workflowClarityStatus -eq "PASS" -and $customerJargonRisk -eq "low") { "PASS" } else { "WARN" }
$mobileLayoutStatus = if ($mobileFriendliness -eq "mobile_card_panels") { "PASS" } else { "WARN" }

$approvalSurfaceStatusValue = if ($approvalActionWired) { "PASS" } else { "WARN" }
$componentNavigationStatus = if ($componentNavigationReady -and $componentCards.Count -gt 0) { "PASS" } else { "WARN" }
$controlSurfaceStatus = if ($quickActions.Count -gt 0) { "PASS" } else { "WARN" }

$recommendedNextAction = if ($deadButtonCount -gt 0) {
    "Finish wiring or remove the remaining dead founder actions before expanding the cockpit further."
}
elseif (-not $approvalActionWired) {
    "Wire approval decisions to real Athena actions so founder review is not summary-only."
}
elseif ($customerJargonRisk -ne "low") {
    "Keep simplifying the remaining customer-facing Onyx copy until internal jargon risk is low."
}
else {
    "Use the founder panels on phone-sized layouts and keep iterating only on surfaces that still feel noisy."
}

$approvalSurfaceReport = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = if ($approvalActionWired -and $unwiredActionCount -eq 0) { "PASS" } else { "WARN" }
    approval_count_visible = [int]$approvalVisibleCount
    approve_button_count = [int]$approveButtonCount
    reject_button_count = [int]$rejectButtonCount
    disabled_button_count = 0
    unwired_action_count = [int]$unwiredActionCount
    recommended_next_action = if ($approvalActionWired) { "Keep using the Athena approvals inbox for governed decisions." } else { "Wire approve and reject actions to a real backend route before presenting them as active founder controls." }
    source_paths = @(
        $athenaHtmlPath,
        $athenaServerPath,
        $approvalsPosturePath
    )
}

$athenaFounderReport = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $athenaFounderUxStatus
    layout_classification = $layoutClassification
    mobile_friendliness_classification = $mobileFriendliness
    approval_surface_status = $approvalSurfaceStatus
    component_navigation_status = if ($componentNavigationStatus -eq "PASS") { "panel_cards" } else { "needs_component_cards" }
    control_surface_status = if ($controlSurfaceStatus -eq "PASS") { "real_controls" } else { "missing_founder_actions" }
    dead_button_count = [int]$deadButtonCount
    founder_only_confirmed = [bool]$founderOnlyConfirmed
    recommended_next_action = $recommendedNextAction
}

$onyxCustomerReport = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $onyxCustomerUxStatus
    plain_english_status = $plainEnglishStatus
    onboarding_clarity_status = $onboardingClarityStatus
    customer_jargon_risk = $customerJargonRisk
    workflow_clarity_status = $workflowClarityStatus
    business_type_relevance_status = $businessTypeRelevanceStatus
    recommended_next_action = if ($customerJargonRisk -eq "low") { "Keep customer wording plain and business-first as new wedge packs arrive." } else { "Keep replacing the remaining internal phrases in customer-visible Onyx copy." }
    remaining_jargon_terms = @($remainingJargon)
}

$overallStatus = if ($athenaFounderUxStatus -eq "PASS" -and $onyxCustomerUxStatus -eq "PASS") { "PASS" } else { "WARN" }
$uxSummary = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $overallStatus
    athena_founder_ux_status = $athenaFounderUxStatus
    onyx_customer_ux_status = $onyxCustomerUxStatus
    approval_surface_status = $approvalSurfaceStatus
    dead_button_count = [int]$deadButtonCount
    approval_button_count = [int]($approveButtonCount + $rejectButtonCount)
    control_button_count = [int]$controlButtonCount
    mobile_layout_status = if ($mobileLayoutStatus -eq "PASS") { "mobile_card_panels" } else { "needs_mobile_polish" }
    recommended_next_action = $recommendedNextAction
    command_run = $commandRun
    repo_root = $repoRoot
}

$registry = [ordered]@{
    generated_at_utc = $nowUtc
    overall_status = $overallStatus
    latest_ux_artifact = $uxSimplicityPath
    athena_founder_ux_status = $athenaFounderUxStatus
    onyx_customer_ux_status = $onyxCustomerUxStatus
    dead_button_count = [int]$deadButtonCount
    notes = @(
        ("approval_surface_status={0}" -f $approvalSurfaceStatus),
        ("remaining_customer_jargon={0}" -f $remainingJargon.Count),
        ("approval_count_visible={0}" -f $approvalVisibleCount)
    )
}

Write-JsonFile -Path $approvalSurfacePath -Data $approvalSurfaceReport
Write-JsonFile -Path $athenaFounderUxPath -Data $athenaFounderReport
Write-JsonFile -Path $onyxCustomerUxPath -Data $onyxCustomerReport
Write-JsonFile -Path $uxSimplicityPath -Data $uxSummary
Write-JsonFile -Path $uxRegistryPath -Data $registry

$uxSummary | ConvertTo-Json -Depth 100
