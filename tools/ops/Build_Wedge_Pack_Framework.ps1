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

function New-Category {
    param(
        [string]$CategoryId,
        [string]$CustomerSafeLabel,
        [string]$Status,
        [string]$Summary,
        [string[]]$SupportedSubcategories
    )

    return [pscustomobject]@{
        business_category = Normalize-ShortText -Value $CategoryId -MaxLength 64
        customer_safe_label = Normalize-ShortText -Value $CustomerSafeLabel -MaxLength 120
        status = Normalize-ShortText -Value $Status -MaxLength 32
        summary = Normalize-ShortText -Value $Summary -MaxLength 240
        supported_subcategories = Normalize-StringList -Value $SupportedSubcategories -MaxItems 24 -MaxLength 64
    }
}

function New-Subcategory {
    param(
        [string]$CategoryId,
        [string]$SubcategoryId,
        [string]$CustomerSafeLabel,
        [string]$Status,
        [string]$Summary
    )

    return [pscustomobject]@{
        business_category = Normalize-ShortText -Value $CategoryId -MaxLength 64
        business_subcategory = Normalize-ShortText -Value $SubcategoryId -MaxLength 64
        customer_safe_label = Normalize-ShortText -Value $CustomerSafeLabel -MaxLength 120
        status = Normalize-ShortText -Value $Status -MaxLength 32
        summary = Normalize-ShortText -Value $Summary -MaxLength 220
    }
}

function New-Overlay {
    param(
        [string]$OverlayId,
        [string[]]$AppliesToCategories,
        [string[]]$AppliesToSubcategories,
        [string]$Status,
        [string]$Scope,
        [string]$Summary,
        [string]$CustomerSafeLabel,
        [string[]]$PriorityQuestions = @(),
        [string[]]$OptionalAdvancedFields = @(),
        [string[]]$HighlightedCards = @(),
        [string[]]$SuppressedCards = @(),
        [string[]]$RecommendedCards = @(),
        [string[]]$PriorityMetrics = @(),
        [string[]]$RecommendationFocus = @()
    )

    return [pscustomobject]@{
        overlay_id = Normalize-ShortText -Value $OverlayId -MaxLength 80
        applies_to_categories = Normalize-StringList -Value $AppliesToCategories -MaxItems 12 -MaxLength 64
        applies_to_subcategories = Normalize-StringList -Value $AppliesToSubcategories -MaxItems 16 -MaxLength 64
        status = Normalize-ShortText -Value $Status -MaxLength 32
        scope = Normalize-ShortText -Value $Scope -MaxLength 40
        summary = Normalize-ShortText -Value $Summary -MaxLength 240
        customer_safe_label = Normalize-ShortText -Value $CustomerSafeLabel -MaxLength 120
        priority_questions = Normalize-StringList -Value $PriorityQuestions -MaxItems 12 -MaxLength 140
        optional_advanced_fields = Normalize-StringList -Value $OptionalAdvancedFields -MaxItems 12 -MaxLength 120
        highlighted_cards = Normalize-StringList -Value $HighlightedCards -MaxItems 12 -MaxLength 100
        suppressed_cards = Normalize-StringList -Value $SuppressedCards -MaxItems 12 -MaxLength 100
        recommended_cards = Normalize-StringList -Value $RecommendedCards -MaxItems 12 -MaxLength 100
        priority_metrics = Normalize-StringList -Value $PriorityMetrics -MaxItems 12 -MaxLength 100
        recommendation_focus = Normalize-StringList -Value $RecommendationFocus -MaxItems 12 -MaxLength 120
    }
}

function New-ToolBundle {
    param(
        [string]$ToolBundleId,
        [string[]]$AppliesToCategories,
        [string[]]$AppliesToSubcategories,
        [string]$Status,
        [string]$Summary,
        [string]$CustomerSafeLabel,
        [string[]]$DefaultToolIds,
        [string[]]$OptionalToolIds,
        [string[]]$HiddenToolIds,
        [string[]]$FutureAddonPackIds = @()
    )

    return [pscustomobject]@{
        tool_bundle_id = Normalize-ShortText -Value $ToolBundleId -MaxLength 80
        applies_to_categories = Normalize-StringList -Value $AppliesToCategories -MaxItems 12 -MaxLength 64
        applies_to_subcategories = Normalize-StringList -Value $AppliesToSubcategories -MaxItems 16 -MaxLength 64
        status = Normalize-ShortText -Value $Status -MaxLength 32
        summary = Normalize-ShortText -Value $Summary -MaxLength 240
        customer_safe_label = Normalize-ShortText -Value $CustomerSafeLabel -MaxLength 120
        default_tool_ids = Normalize-StringList -Value $DefaultToolIds -MaxItems 16 -MaxLength 80
        optional_tool_ids = Normalize-StringList -Value $OptionalToolIds -MaxItems 16 -MaxLength 80
        hidden_tool_ids = Normalize-StringList -Value $HiddenToolIds -MaxItems 16 -MaxLength 80
        future_addon_pack_ids = Normalize-StringList -Value $FutureAddonPackIds -MaxItems 12 -MaxLength 80
    }
}

function New-RecommendationRulePack {
    param(
        [string]$RecommendationRulePackId,
        [string[]]$AppliesToCategories,
        [string[]]$AppliesToSubcategories,
        [string]$Status,
        [string]$Summary,
        [string[]]$RelevantRecommendations,
        [string[]]$SuppressedRecommendations,
        [string[]]$HighPriorityRecommendations,
        [string[]]$PriorityQuestions,
        [string[]]$PriorityDashboardCards
    )

    return [pscustomobject]@{
        recommendation_rule_pack_id = Normalize-ShortText -Value $RecommendationRulePackId -MaxLength 80
        applies_to_categories = Normalize-StringList -Value $AppliesToCategories -MaxItems 12 -MaxLength 64
        applies_to_subcategories = Normalize-StringList -Value $AppliesToSubcategories -MaxItems 16 -MaxLength 64
        status = Normalize-ShortText -Value $Status -MaxLength 32
        summary = Normalize-ShortText -Value $Summary -MaxLength 240
        relevant_recommendations = Normalize-StringList -Value $RelevantRecommendations -MaxItems 12 -MaxLength 120
        suppressed_recommendations = Normalize-StringList -Value $SuppressedRecommendations -MaxItems 12 -MaxLength 120
        high_priority_recommendations = Normalize-StringList -Value $HighPriorityRecommendations -MaxItems 12 -MaxLength 120
        onboarding_priority_questions = Normalize-StringList -Value $PriorityQuestions -MaxItems 12 -MaxLength 120
        dashboard_priority_cards = Normalize-StringList -Value $PriorityDashboardCards -MaxItems 12 -MaxLength 100
    }
}

function New-WorkflowPack {
    param(
        [string]$WorkflowPackId,
        [string]$BusinessCategory,
        [string[]]$BusinessSubcategories,
        [string[]]$ToolBundleIds,
        [string[]]$RecommendationRulePackIds,
        [string]$Status,
        [string]$Summary,
        [string]$CustomerSafeLabel,
        [string]$OwnerNotes = "",
        [string]$WedgeStatus = ""
    )

    return [pscustomobject]@{
        workflow_pack_id = Normalize-ShortText -Value $WorkflowPackId -MaxLength 80
        business_category = Normalize-ShortText -Value $BusinessCategory -MaxLength 64
        business_subcategory = Normalize-StringList -Value $BusinessSubcategories -MaxItems 16 -MaxLength 64
        tool_bundle_ids = Normalize-StringList -Value $ToolBundleIds -MaxItems 16 -MaxLength 80
        recommendation_rule_pack_ids = Normalize-StringList -Value $RecommendationRulePackIds -MaxItems 16 -MaxLength 80
        status = Normalize-ShortText -Value $Status -MaxLength 32
        wedge_status = Normalize-ShortText -Value $(if ($WedgeStatus) { $WedgeStatus } else { $Status }) -MaxLength 32
        summary = Normalize-ShortText -Value $Summary -MaxLength 240
        owner_notes = Normalize-ShortText -Value $OwnerNotes -MaxLength 240
        customer_safe_label = Normalize-ShortText -Value $CustomerSafeLabel -MaxLength 120
    }
}

function New-SegmentProfile {
    param(
        [string]$SegmentProfileId,
        [string]$BusinessCategory,
        [string[]]$BusinessSubcategories,
        [string]$Status,
        [string[]]$OnboardingOverlayIds,
        [string[]]$DashboardOverlayIds,
        [string[]]$RecommendationOverlayIds,
        [string[]]$ToolBundleIds,
        [string[]]$WorkflowPackIds,
        [string[]]$RecommendationRulePackIds,
        [string]$Summary
    )

    return [pscustomobject]@{
        segment_profile_id = Normalize-ShortText -Value $SegmentProfileId -MaxLength 80
        business_category = Normalize-ShortText -Value $BusinessCategory -MaxLength 64
        business_subcategories = Normalize-StringList -Value $BusinessSubcategories -MaxItems 16 -MaxLength 64
        status = Normalize-ShortText -Value $Status -MaxLength 32
        onboarding_overlay_ids = Normalize-StringList -Value $OnboardingOverlayIds -MaxItems 16 -MaxLength 80
        dashboard_overlay_ids = Normalize-StringList -Value $DashboardOverlayIds -MaxItems 16 -MaxLength 80
        recommendation_overlay_ids = Normalize-StringList -Value $RecommendationOverlayIds -MaxItems 16 -MaxLength 80
        tool_bundle_ids = Normalize-StringList -Value $ToolBundleIds -MaxItems 16 -MaxLength 80
        workflow_pack_ids = Normalize-StringList -Value $WorkflowPackIds -MaxItems 16 -MaxLength 80
        recommendation_rule_pack_ids = Normalize-StringList -Value $RecommendationRulePackIds -MaxItems 16 -MaxLength 80
        summary = Normalize-ShortText -Value $Summary -MaxLength 240
    }
}

function Resolve-BusinessSegment {
    param(
        [AllowNull()][object]$Profile,
        [AllowNull()][object]$Tenant
    )

    $businessType = Normalize-Text (Get-PropValue -Object $Profile -Name "businessType" -Default "")
    $businessName = Normalize-Text (Get-PropValue -Object $Profile -Name "businessName" -Default "")
    $servicesProducts = Normalize-StringList -Value (Get-PropValue -Object $Profile -Name "servicesProducts" -Default @()) -MaxItems 12 -MaxLength 80
    $goals = Normalize-StringList -Value (Get-PropValue -Object $Profile -Name "goals" -Default @()) -MaxItems 12 -MaxLength 80
    $notes = Normalize-Text (Get-PropValue -Object $Profile -Name "notes" -Default "")
    $signals = ("{0} {1} {2} {3} {4}" -f $businessType, $businessName, ($servicesProducts -join " "), ($goals -join " "), $notes).ToLowerInvariant()

    $category = "general_small_business"
    $subcategory = "other"
    $confidence = 0.40
    $reason = "No strong category keywords were present, so the default general small-business fallback applies."

    if ($signals -match "plumb|painter|electric|hvac|roofer|cabinet|landscape|contractor|renovat|handyman") {
        $category = "contractor"
        $confidence = 0.82
        $reason = "Business profile keywords match a contractor-style field-service business."
        if ($signals -match "plumb") {
            $subcategory = "plumber"
            $confidence = 0.90
        }
        elseif ($signals -match "painter") {
            $subcategory = "painter"
            $confidence = 0.90
        }
        elseif ($signals -match "cabinet") {
            $subcategory = "cabinet_maker"
            $confidence = 0.88
        }
        else {
            $subcategory = "general_contractor"
        }
    }
    elseif ($signals -match "salon|barber|hair|spa") {
        $category = "services"
        $subcategory = if ($signals -match "barber") { "barber" } else { "salon" }
        $confidence = 0.90
        $reason = "Business profile keywords match a service-business personal-care flow."
    }
    elseif ($signals -match "studio|creative|agency|consult|coach") {
        $category = "services"
        $subcategory = if ($signals -match "consult|coach") { "consulting_practice" } else { "studio_creative" }
        $confidence = 0.88
        $reason = "Business profile keywords match a studio or consulting service workflow."
    }
    elseif ($signals -match "retail|boutique|shop|store|merch|ecom") {
        $category = "retail"
        $subcategory = if ($signals -match "ecom") { "ecommerce_retail" } else { "boutique_retail" }
        $confidence = 0.86
        $reason = "Business profile keywords match a retail-style selling workflow."
    }
    elseif ($signals -match "restaurant|cafe|coffee|bakery|food truck|kitchen") {
        $category = "restaurant"
        $subcategory = if ($signals -match "cafe|coffee") { "cafe" } else { "restaurant_general" }
        $confidence = 0.84
        $reason = "Business profile keywords match a restaurant or food-service workflow."
    }
    elseif ($signals -match "bookkeep|account|cfo|tax") {
        $category = "bookkeeping_advisory"
        $subcategory = "bookkeeping_practice"
        $confidence = 0.84
        $reason = "Business profile keywords match a bookkeeping or advisory workflow."
    }

    return [pscustomobject]@{
        business_category = $category
        business_subcategory = $subcategory
        tenant_fit_confidence = [math]::Round([double]$confidence, 2)
        tenant_fit_reason = Normalize-ShortText -Value $reason -MaxLength 240
        business_type_signal = Normalize-ShortText -Value $businessType -MaxLength 80
    }
}

$repoRoot = Resolve-RepoRoot -ExplicitRoot $RepoRoot
$reportsDir = Join-Path $repoRoot "reports"
$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"
$configDir = Join-Path $repoRoot "config"
$onyxStateDir = Join-Path $repoRoot "state\onyx"

$toolRegistryPath = Join-Path $configDir "tool_registry.json"
$tenantWorkspacePath = Join-Path $onyxStateDir "tenant_workspace.json"
$systemTruthPath = Join-Path $reportsDir "system_truth_spine_last.json"
$billingSummaryPath = Join-Path $reportsDir "billing_summary.json"
$recommendationsDir = Join-Path $onyxStateDir "recommendations"

$frameworkArtifactPath = Join-Path $reportsDir "wedge_pack_framework_last.json"
$segmentOverlayArtifactPath = Join-Path $reportsDir "segment_overlay_last.json"
$workflowPackArtifactPath = Join-Path $reportsDir "workflow_pack_last.json"
$wedgePackRegistryPath = Join-Path $stateKnowledgeDir "wedge_pack_registry.json"
$wedgePackPolicyPath = Join-Path $configDir "wedge_pack_policy.json"

$nowUtc = (Get-Date).ToUniversalTime().ToString("o")
$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Build_Wedge_Pack_Framework.ps1"

$tenantWorkspace = Read-JsonSafe -Path $tenantWorkspacePath
$activeTenantId = Normalize-Text (Get-PropValue -Object $tenantWorkspace -Name "activeTenantId" -Default "")
$tenantContexts = @((Get-PropValue -Object $tenantWorkspace -Name "contexts" -Default @()))

$policy = [ordered]@{
    version = 1
    policy_name = "wedge_pack_segment_expansion_framework"
    allowed_wedge_pack_statuses = @("planned", "experimental", "internal_only", "pilot_ready", "customer_ready")
    category_subcategory_policy = [ordered]@{
        broad_categories_supported = @("general_small_business", "contractor", "services", "retail", "restaurant", "bookkeeping_advisory")
        fallback_category = "general_small_business"
        fallback_subcategory = "other"
        new_subcategories_must_declare_parent_category = $true
        future_wedges_must_not_break_existing_segment_ids = $true
    }
    default_fallback_segment_behavior = [ordered]@{
        segment_profile = "segment_profile_general_small_business"
        workflow_pack_id = "workflow_pack_general_small_business"
        onboarding_overlay_id = "onboarding_overlay_general_small_business"
        dashboard_overlay_id = "dashboard_overlay_general_small_business"
        recommendation_rule_pack_id = "recommendation_rules_general_small_business"
        customer_safe_label = "General Small Business"
    }
    tenant_fit_confidence_rules = [ordered]@{
        high_confidence_min = 0.85
        medium_confidence_min = 0.65
        low_confidence_below = 0.65
        low_confidence_action = "fallback_to_general_small_business"
    }
    overlay_application_rules = @(
        "Onboarding overlays may add priority questions and advanced optional fields, but must not remove the baseline tenant identity fields.",
        "Dashboard overlays may highlight or suppress cards, but must preserve the core operator and governance surfaces.",
        "Only customer_ready or pilot_ready overlays may be proposed for tenant-facing rollout."
    )
    workflow_pack_application_rules = @(
        "Workflow packs attach by category and optional subcategory match.",
        "Default fallback workflow pack must remain available when tenant fit is unclear.",
        "Experimental workflow packs must stay clearly marked and must not be presented as customer-ready by default."
    )
    recommendation_pack_application_rules = @(
        "Recommendation rule packs may raise or suppress priorities by segment, but must stay grounded in actual tools and current tenant context.",
        "Experimental recommendation packs remain internal until explicitly promoted."
    )
    blocked_or_experimental_wedge_statuses = @("experimental", "internal_only", "planned")
    customer_safe_naming_rules = @(
        "Use Onyx-facing business labels only.",
        "Do not expose internal-only Mason naming in customer-safe wedge summaries.",
        "Customer-ready labels must describe the business workflow, not the internal implementation."
    )
    future_expansion_guidance = @(
        "Add new wedges by registering categories, subcategories, overlays, tool bundles, workflow packs, and recommendation rule packs without rewriting the core platform.",
        "Keep pack status explicit and promote from planned to experimental to pilot_ready to customer_ready only with evidence."
    )
}

$categories = @(
    (New-Category -CategoryId "general_small_business" -CustomerSafeLabel "General Small Business" -Status "customer_ready" -Summary "Fallback small-business pack for tenants without a stronger segment fit." -SupportedSubcategories @("other")),
    (New-Category -CategoryId "contractor" -CustomerSafeLabel "Contractor" -Status "pilot_ready" -Summary "Field-service and jobsite business workflows such as plumbing, painting, and renovation." -SupportedSubcategories @("general_contractor", "plumber", "painter", "cabinet_maker")),
    (New-Category -CategoryId "services" -CustomerSafeLabel "Services" -Status "pilot_ready" -Summary "Service businesses such as studios, consulting practices, salons, and barbers." -SupportedSubcategories @("studio_creative", "consulting_practice", "salon", "barber")),
    (New-Category -CategoryId "retail" -CustomerSafeLabel "Retail" -Status "planned" -Summary "Retail and in-person selling workflows for boutique and e-commerce operators." -SupportedSubcategories @("boutique_retail", "ecommerce_retail", "office_services")),
    (New-Category -CategoryId "restaurant" -CustomerSafeLabel "Restaurant" -Status "planned" -Summary "Restaurant, cafe, and food-service workflows with shift and service priorities." -SupportedSubcategories @("restaurant_general", "cafe")),
    (New-Category -CategoryId "bookkeeping_advisory" -CustomerSafeLabel "Bookkeeping And Advisory" -Status "experimental" -Summary "Bookkeeping and advisory flows for finance-first service operators." -SupportedSubcategories @("bookkeeping_practice"))
)

$subcategories = @(
    (New-Subcategory -CategoryId "general_small_business" -SubcategoryId "other" -CustomerSafeLabel "Other / Not Yet Classified" -Status "customer_ready" -Summary "Safe fallback when a business does not yet cleanly match a wedge."),
    (New-Subcategory -CategoryId "contractor" -SubcategoryId "general_contractor" -CustomerSafeLabel "General Contractor" -Status "pilot_ready" -Summary "General field-service or jobsite operation."),
    (New-Subcategory -CategoryId "contractor" -SubcategoryId "plumber" -CustomerSafeLabel "Plumber" -Status "pilot_ready" -Summary "Plumbing and repair workflow variant."),
    (New-Subcategory -CategoryId "contractor" -SubcategoryId "painter" -CustomerSafeLabel "Painter" -Status "pilot_ready" -Summary "Painting and finish-trade workflow variant."),
    (New-Subcategory -CategoryId "contractor" -SubcategoryId "cabinet_maker" -CustomerSafeLabel "Cabinet Maker" -Status "pilot_ready" -Summary "Cabinet, millwork, and fabrication workflow variant."),
    (New-Subcategory -CategoryId "services" -SubcategoryId "studio_creative" -CustomerSafeLabel "Studio / Creative Service" -Status "pilot_ready" -Summary "Studio, agency, or creative-service operator."),
    (New-Subcategory -CategoryId "services" -SubcategoryId "consulting_practice" -CustomerSafeLabel "Consulting Practice" -Status "pilot_ready" -Summary "Consulting, coaching, or advisory service business."),
    (New-Subcategory -CategoryId "services" -SubcategoryId "salon" -CustomerSafeLabel "Hair Salon" -Status "pilot_ready" -Summary "Salon appointment and retention workflow."),
    (New-Subcategory -CategoryId "services" -SubcategoryId "barber" -CustomerSafeLabel "Barber Shop" -Status "pilot_ready" -Summary "Barber appointment and repeat-client workflow."),
    (New-Subcategory -CategoryId "retail" -SubcategoryId "boutique_retail" -CustomerSafeLabel "Boutique Retail" -Status "planned" -Summary "In-person selling and repeat-buyer retail workflow."),
    (New-Subcategory -CategoryId "retail" -SubcategoryId "ecommerce_retail" -CustomerSafeLabel "E-Commerce Retail" -Status "planned" -Summary "Online or blended retail workflow."),
    (New-Subcategory -CategoryId "retail" -SubcategoryId "office_services" -CustomerSafeLabel "Office / Front Desk Service" -Status "planned" -Summary "Office-facing service workflow with scheduled client handling."),
    (New-Subcategory -CategoryId "restaurant" -SubcategoryId "restaurant_general" -CustomerSafeLabel "Restaurant" -Status "planned" -Summary "General restaurant workflow."),
    (New-Subcategory -CategoryId "restaurant" -SubcategoryId "cafe" -CustomerSafeLabel "Cafe" -Status "planned" -Summary "Cafe and quick-service workflow."),
    (New-Subcategory -CategoryId "bookkeeping_advisory" -SubcategoryId "bookkeeping_practice" -CustomerSafeLabel "Bookkeeping Practice" -Status "experimental" -Summary "Bookkeeping and close-process workflow.")
)

$onboardingOverlays = @(
    (New-Overlay -OverlayId "onboarding_overlay_general_small_business" -AppliesToCategories @("general_small_business") -AppliesToSubcategories @("other") -Status "customer_ready" -Scope "onboarding" -Summary "Default onboarding overlay for a general small business." -CustomerSafeLabel "General Small-Business Onboarding" -PriorityQuestions @("Primary revenue goal", "Core customer type", "Current operating bottleneck") -OptionalAdvancedFields @("team_workflow_notes", "current_sales_motion")),
    (New-Overlay -OverlayId "onboarding_overlay_contractor" -AppliesToCategories @("contractor") -AppliesToSubcategories @("general_contractor", "plumber", "painter", "cabinet_maker") -Status "pilot_ready" -Scope "onboarding" -Summary "Adds field-service intake and job backlog questions for contractor flows." -CustomerSafeLabel "Contractor Onboarding" -PriorityQuestions @("Job backlog", "Service radius", "Estimate-to-close friction") -OptionalAdvancedFields @("crew_schedule_model", "quote_turnaround_time")),
    (New-Overlay -OverlayId "onboarding_overlay_services" -AppliesToCategories @("services") -AppliesToSubcategories @("studio_creative", "consulting_practice", "salon", "barber") -Status "pilot_ready" -Scope "onboarding" -Summary "Adds service-delivery and repeat-client questions for service businesses." -CustomerSafeLabel "Service-Business Onboarding" -PriorityQuestions @("Offer mix", "Capacity bottleneck", "Repeat-client goal") -OptionalAdvancedFields @("appointment_model", "package_structure")),
    (New-Overlay -OverlayId "onboarding_overlay_retail" -AppliesToCategories @("retail") -AppliesToSubcategories @("boutique_retail", "ecommerce_retail", "office_services") -Status "planned" -Scope "onboarding" -Summary "Adds inventory, channel, and repeat-buyer intake for retail-style businesses." -CustomerSafeLabel "Retail Onboarding" -PriorityQuestions @("Primary sales channel", "Top seller", "Repeat-buyer target") -OptionalAdvancedFields @("inventory_constraints", "fulfillment_notes")),
    (New-Overlay -OverlayId "onboarding_overlay_bookkeeping" -AppliesToCategories @("bookkeeping_advisory") -AppliesToSubcategories @("bookkeeping_practice") -Status "experimental" -Scope "onboarding" -Summary "Adds close-cycle and client bookkeeping complexity questions." -CustomerSafeLabel "Bookkeeping Onboarding" -PriorityQuestions @("Monthly close pain", "Client handoff risk", "Advisory upsell target") -OptionalAdvancedFields @("close_cycle_days", "file_intake_process"))
)

$dashboardOverlays = @(
    (New-Overlay -OverlayId "dashboard_overlay_general_small_business" -AppliesToCategories @("general_small_business") -AppliesToSubcategories @("other") -Status "customer_ready" -Scope "dashboard" -Summary "Highlights core revenue, tasks, and follow-up priorities." -CustomerSafeLabel "General Small-Business Dashboard" -HighlightedCards @("recommendations", "tasks", "pipeline") -RecommendedCards @("rescue_plan", "sales_followup") -PriorityMetrics @("open_tasks", "lead_followup_age")),
    (New-Overlay -OverlayId "dashboard_overlay_contractor" -AppliesToCategories @("contractor") -AppliesToSubcategories @("general_contractor", "plumber", "painter", "cabinet_maker") -Status "pilot_ready" -Scope "dashboard" -Summary "Highlights quote backlog, active jobs, and schedule pressure." -CustomerSafeLabel "Contractor Dashboard" -HighlightedCards @("job_backlog", "schedule_pressure", "quote_pipeline") -RecommendedCards @("rescue_plan", "sales_followup") -PriorityMetrics @("quotes_waiting", "jobs_overdue")),
    (New-Overlay -OverlayId "dashboard_overlay_services" -AppliesToCategories @("services") -AppliesToSubcategories @("studio_creative", "consulting_practice", "salon", "barber") -Status "pilot_ready" -Scope "dashboard" -Summary "Highlights service capacity, repeat-client flow, and offer utilization." -CustomerSafeLabel "Service-Business Dashboard" -HighlightedCards @("capacity", "repeat_clients", "offer_mix") -RecommendedCards @("marketing_pack", "sales_followup") -PriorityMetrics @("booked_capacity", "repeat_client_rate")),
    (New-Overlay -OverlayId "dashboard_overlay_retail" -AppliesToCategories @("retail") -AppliesToSubcategories @("boutique_retail", "ecommerce_retail", "office_services") -Status "planned" -Scope "dashboard" -Summary "Highlights top-seller performance, repeat-buyer flow, and channel mix." -CustomerSafeLabel "Retail Dashboard" -HighlightedCards @("top_sellers", "repeat_buyers", "channel_mix") -RecommendedCards @("marketing_pack") -PriorityMetrics @("repeat_buyer_rate", "channel_conversion")),
    (New-Overlay -OverlayId "dashboard_overlay_bookkeeping" -AppliesToCategories @("bookkeeping_advisory") -AppliesToSubcategories @("bookkeeping_practice") -Status "experimental" -Scope "dashboard" -Summary "Highlights close-cycle pressure, client response lag, and advisory opportunities." -CustomerSafeLabel "Bookkeeping Dashboard" -HighlightedCards @("close_cycle", "client_response_lag", "advisory_pipeline") -RecommendedCards @("rescue_plan") -PriorityMetrics @("close_cycle_days", "missing_documents"))
)

$recommendationOverlays = @(
    (New-Overlay -OverlayId "recommendation_overlay_general_small_business" -AppliesToCategories @("general_small_business") -AppliesToSubcategories @("other") -Status "customer_ready" -Scope "recommendations" -Summary "Keeps rescue, growth, and follow-up recommendations balanced for a general small-business operator." -CustomerSafeLabel "General Recommendation Priorities" -RecommendationFocus @("stability", "basic growth", "follow-up cadence")),
    (New-Overlay -OverlayId "recommendation_overlay_contractor" -AppliesToCategories @("contractor") -AppliesToSubcategories @("general_contractor", "plumber", "painter", "cabinet_maker") -Status "pilot_ready" -Scope "recommendations" -Summary "Raises urgency around quote follow-up, schedule pressure, and backlog control." -CustomerSafeLabel "Contractor Recommendation Priorities" -RecommendationFocus @("quote conversion", "schedule control", "job backlog cleanup")),
    (New-Overlay -OverlayId "recommendation_overlay_services" -AppliesToCategories @("services") -AppliesToSubcategories @("studio_creative", "consulting_practice", "salon", "barber") -Status "pilot_ready" -Scope "recommendations" -Summary "Prioritizes capacity, retention, and offer clarity for service businesses." -CustomerSafeLabel "Service Recommendation Priorities" -RecommendationFocus @("retention", "capacity utilization", "offer positioning")),
    (New-Overlay -OverlayId "recommendation_overlay_retail" -AppliesToCategories @("retail") -AppliesToSubcategories @("boutique_retail", "ecommerce_retail", "office_services") -Status "planned" -Scope "recommendations" -Summary "Prioritizes repeat-buyer motion and channel-specific merchandising." -CustomerSafeLabel "Retail Recommendation Priorities" -RecommendationFocus @("repeat buyers", "channel mix", "inventory-sensitive promotion")),
    (New-Overlay -OverlayId "recommendation_overlay_bookkeeping" -AppliesToCategories @("bookkeeping_advisory") -AppliesToSubcategories @("bookkeeping_practice") -Status "experimental" -Scope "recommendations" -Summary "Prioritizes close-process reliability and client document discipline." -CustomerSafeLabel "Bookkeeping Recommendation Priorities" -RecommendationFocus @("close reliability", "document chase", "advisory upsell"))
)

$toolBundles = @(
    (New-ToolBundle -ToolBundleId "tool_bundle_general_core" -AppliesToCategories @("general_small_business") -AppliesToSubcategories @("other") -Status "customer_ready" -Summary "Default small-business tool bundle for stabilization and follow-up." -CustomerSafeLabel "General Core Tools" -DefaultToolIds @("rescue_plan_v1") -OptionalToolIds @("marketing_pack_v1", "sales_followup_v1") -HiddenToolIds @("workflow_capability_builder_v1") -FutureAddonPackIds @("addon_pack_general_reporting")),
    (New-ToolBundle -ToolBundleId "tool_bundle_contractor_core" -AppliesToCategories @("contractor") -AppliesToSubcategories @("general_contractor", "plumber", "painter", "cabinet_maker") -Status "pilot_ready" -Summary "Field-service bundle focused on stabilization and follow-up for quoted jobs." -CustomerSafeLabel "Contractor Core Tools" -DefaultToolIds @("rescue_plan_v1", "sales_followup_v1") -OptionalToolIds @("marketing_pack_v1") -HiddenToolIds @("workflow_capability_builder_v1") -FutureAddonPackIds @("addon_pack_job_costing")),
    (New-ToolBundle -ToolBundleId "tool_bundle_service_growth" -AppliesToCategories @("services") -AppliesToSubcategories @("studio_creative", "consulting_practice", "salon", "barber") -Status "pilot_ready" -Summary "Service-business bundle emphasizing offer clarity, growth, and retention." -CustomerSafeLabel "Service Growth Tools" -DefaultToolIds @("marketing_pack_v1") -OptionalToolIds @("rescue_plan_v1", "sales_followup_v1") -HiddenToolIds @("workflow_capability_builder_v1") -FutureAddonPackIds @("addon_pack_retention_automation")),
    (New-ToolBundle -ToolBundleId "tool_bundle_retail_launch" -AppliesToCategories @("retail") -AppliesToSubcategories @("boutique_retail", "ecommerce_retail", "office_services") -Status "planned" -Summary "Retail starter bundle for merchandising and repeat-buyer growth." -CustomerSafeLabel "Retail Starter Tools" -DefaultToolIds @("marketing_pack_v1") -OptionalToolIds @("rescue_plan_v1") -HiddenToolIds @("sales_followup_v1", "workflow_capability_builder_v1") -FutureAddonPackIds @("addon_pack_inventory_alerts")),
    (New-ToolBundle -ToolBundleId "tool_bundle_bookkeeping_experimental" -AppliesToCategories @("bookkeeping_advisory") -AppliesToSubcategories @("bookkeeping_practice") -Status "experimental" -Summary "Experimental bookkeeping bundle until dedicated finance-safe tools exist." -CustomerSafeLabel "Bookkeeping Experimental Tools" -DefaultToolIds @("rescue_plan_v1") -OptionalToolIds @("marketing_pack_v1") -HiddenToolIds @("sales_followup_v1", "workflow_capability_builder_v1") -FutureAddonPackIds @("addon_pack_close_cycle_controls"))
)

$recommendationRulePacks = @(
    (New-RecommendationRulePack -RecommendationRulePackId "recommendation_rules_general_small_business" -AppliesToCategories @("general_small_business") -AppliesToSubcategories @("other") -Status "customer_ready" -Summary "Balanced recommendation priorities for a general small business." -RelevantRecommendations @("stability", "growth", "followup") -SuppressedRecommendations @("inventory-heavy") -HighPriorityRecommendations @("rescue_plan", "sales_followup") -PriorityQuestions @("What is the main bottleneck this month?", "Which offer needs traction first?") -PriorityDashboardCards @("recommendations", "pipeline", "tasks")),
    (New-RecommendationRulePack -RecommendationRulePackId "recommendation_rules_contractor" -AppliesToCategories @("contractor") -AppliesToSubcategories @("general_contractor", "plumber", "painter", "cabinet_maker") -Status "pilot_ready" -Summary "Contractor recommendation priorities for quote follow-up and schedule reliability." -RelevantRecommendations @("quote_followup", "backlog_reduction", "job_stability") -SuppressedRecommendations @("broad_branding_first") -HighPriorityRecommendations @("sales_followup", "rescue_plan") -PriorityQuestions @("How fast are quotes followed up?", "Where is schedule pressure highest?") -PriorityDashboardCards @("quote_pipeline", "jobs_overdue", "cash_pressure")),
    (New-RecommendationRulePack -RecommendationRulePackId "recommendation_rules_services" -AppliesToCategories @("services") -AppliesToSubcategories @("studio_creative", "consulting_practice", "salon", "barber") -Status "pilot_ready" -Summary "Service-business priorities for retention, capacity, and clear offer packaging." -RelevantRecommendations @("retention", "capacity", "offer_clarity") -SuppressedRecommendations @("inventory-first") -HighPriorityRecommendations @("marketing_pack", "sales_followup") -PriorityQuestions @("Where is delivery capacity constrained?", "What repeat-client motion is missing?") -PriorityDashboardCards @("capacity", "repeat_clients", "marketing_pipeline")),
    (New-RecommendationRulePack -RecommendationRulePackId "recommendation_rules_retail" -AppliesToCategories @("retail") -AppliesToSubcategories @("boutique_retail", "ecommerce_retail", "office_services") -Status "planned" -Summary "Retail priorities for repeat buyers and channel mix." -RelevantRecommendations @("repeat_buyers", "channel_growth", "offer_rotation") -SuppressedRecommendations @("complex_field_service") -HighPriorityRecommendations @("marketing_pack") -PriorityQuestions @("Which channel is slipping?", "Which customers should return sooner?") -PriorityDashboardCards @("repeat_buyers", "channel_mix", "top_sellers")),
    (New-RecommendationRulePack -RecommendationRulePackId "recommendation_rules_bookkeeping" -AppliesToCategories @("bookkeeping_advisory") -AppliesToSubcategories @("bookkeeping_practice") -Status "experimental" -Summary "Bookkeeping priorities for close-cycle reliability and client intake discipline." -RelevantRecommendations @("close_control", "document_followup", "advisory_upsell") -SuppressedRecommendations @("broad_marketing_push") -HighPriorityRecommendations @("rescue_plan") -PriorityQuestions @("What breaks the monthly close?", "Where do client files arrive late?") -PriorityDashboardCards @("close_cycle", "missing_documents", "client_response_lag"))
)

$workflowPacks = @(
    (New-WorkflowPack -WorkflowPackId "workflow_pack_general_small_business" -BusinessCategory "general_small_business" -BusinessSubcategories @("other") -ToolBundleIds @("tool_bundle_general_core") -RecommendationRulePackIds @("recommendation_rules_general_small_business") -Status "customer_ready" -Summary "General small-business fallback pack with stable onboarding, dashboard, and tool defaults." -CustomerSafeLabel "General Small-Business Pack" -OwnerNotes "Fallback default for tenants with low-confidence segment fit."),
    (New-WorkflowPack -WorkflowPackId "workflow_pack_contractor_field_ops" -BusinessCategory "contractor" -BusinessSubcategories @("general_contractor", "plumber", "painter", "cabinet_maker") -ToolBundleIds @("tool_bundle_contractor_core") -RecommendationRulePackIds @("recommendation_rules_contractor") -Status "pilot_ready" -Summary "Pilot contractor pack focused on backlog control, quoting, and schedule reliability." -CustomerSafeLabel "Contractor Field Ops Pack" -OwnerNotes "Framework-only starter; does not claim contractor automation is fully implemented."),
    (New-WorkflowPack -WorkflowPackId "workflow_pack_service_growth" -BusinessCategory "services" -BusinessSubcategories @("studio_creative", "consulting_practice", "salon", "barber") -ToolBundleIds @("tool_bundle_service_growth") -RecommendationRulePackIds @("recommendation_rules_services") -Status "pilot_ready" -Summary "Pilot service-business pack for capacity, retention, and offer growth." -CustomerSafeLabel "Service Growth Pack" -OwnerNotes "Fits studios, consulting, salon, and barber flows."),
    (New-WorkflowPack -WorkflowPackId "workflow_pack_retail_counter_ops" -BusinessCategory "retail" -BusinessSubcategories @("boutique_retail", "ecommerce_retail", "office_services") -ToolBundleIds @("tool_bundle_retail_launch") -RecommendationRulePackIds @("recommendation_rules_retail") -Status "planned" -Summary "Planned retail pack for repeat-buyer motion and channel priorities." -CustomerSafeLabel "Retail Counter Ops Pack" -OwnerNotes "Structured placeholder only; not customer-ready yet."),
    (New-WorkflowPack -WorkflowPackId "workflow_pack_restaurant_shift_ops" -BusinessCategory "restaurant" -BusinessSubcategories @("restaurant_general", "cafe") -ToolBundleIds @("tool_bundle_general_core") -RecommendationRulePackIds @("recommendation_rules_general_small_business") -Status "planned" -Summary "Planned restaurant pack for shift pressure and repeat guest operations." -CustomerSafeLabel "Restaurant Shift Ops Pack" -OwnerNotes "Restaurant wedge remains framework-only in this chunk."),
    (New-WorkflowPack -WorkflowPackId "workflow_pack_bookkeeping_advisory" -BusinessCategory "bookkeeping_advisory" -BusinessSubcategories @("bookkeeping_practice") -ToolBundleIds @("tool_bundle_bookkeeping_experimental") -RecommendationRulePackIds @("recommendation_rules_bookkeeping") -Status "experimental" -Summary "Experimental bookkeeping-oriented pack until finance-safe tools and flows are fully governed." -CustomerSafeLabel "Bookkeeping Advisory Pack" -OwnerNotes "Do not treat as customer-ready.")
)

$segmentProfiles = @(
    (New-SegmentProfile -SegmentProfileId "segment_profile_general_small_business" -BusinessCategory "general_small_business" -BusinessSubcategories @("other") -Status "customer_ready" -OnboardingOverlayIds @("onboarding_overlay_general_small_business") -DashboardOverlayIds @("dashboard_overlay_general_small_business") -RecommendationOverlayIds @("recommendation_overlay_general_small_business") -ToolBundleIds @("tool_bundle_general_core") -WorkflowPackIds @("workflow_pack_general_small_business") -RecommendationRulePackIds @("recommendation_rules_general_small_business") -Summary "Fallback profile for a general small business."),
    (New-SegmentProfile -SegmentProfileId "segment_profile_contractor" -BusinessCategory "contractor" -BusinessSubcategories @("general_contractor", "plumber", "painter", "cabinet_maker") -Status "pilot_ready" -OnboardingOverlayIds @("onboarding_overlay_contractor") -DashboardOverlayIds @("dashboard_overlay_contractor") -RecommendationOverlayIds @("recommendation_overlay_contractor") -ToolBundleIds @("tool_bundle_contractor_core") -WorkflowPackIds @("workflow_pack_contractor_field_ops") -RecommendationRulePackIds @("recommendation_rules_contractor") -Summary "Pilot contractor segment profile."),
    (New-SegmentProfile -SegmentProfileId "segment_profile_services" -BusinessCategory "services" -BusinessSubcategories @("studio_creative", "consulting_practice", "salon", "barber") -Status "pilot_ready" -OnboardingOverlayIds @("onboarding_overlay_services") -DashboardOverlayIds @("dashboard_overlay_services") -RecommendationOverlayIds @("recommendation_overlay_services") -ToolBundleIds @("tool_bundle_service_growth") -WorkflowPackIds @("workflow_pack_service_growth") -RecommendationRulePackIds @("recommendation_rules_services") -Summary "Pilot service-business segment profile."),
    (New-SegmentProfile -SegmentProfileId "segment_profile_retail" -BusinessCategory "retail" -BusinessSubcategories @("boutique_retail", "ecommerce_retail", "office_services") -Status "planned" -OnboardingOverlayIds @("onboarding_overlay_retail") -DashboardOverlayIds @("dashboard_overlay_retail") -RecommendationOverlayIds @("recommendation_overlay_retail") -ToolBundleIds @("tool_bundle_retail_launch") -WorkflowPackIds @("workflow_pack_retail_counter_ops") -RecommendationRulePackIds @("recommendation_rules_retail") -Summary "Planned retail segment profile."),
    (New-SegmentProfile -SegmentProfileId "segment_profile_bookkeeping" -BusinessCategory "bookkeeping_advisory" -BusinessSubcategories @("bookkeeping_practice") -Status "experimental" -OnboardingOverlayIds @("onboarding_overlay_bookkeeping") -DashboardOverlayIds @("dashboard_overlay_bookkeeping") -RecommendationOverlayIds @("recommendation_overlay_bookkeeping") -ToolBundleIds @("tool_bundle_bookkeeping_experimental") -WorkflowPackIds @("workflow_pack_bookkeeping_advisory") -RecommendationRulePackIds @("recommendation_rules_bookkeeping") -Summary "Experimental bookkeeping/advisory segment profile.")
)

$tenantFits = @()
foreach ($context in $tenantContexts) {
    $tenant = Get-PropValue -Object $context -Name "tenant" -Default $null
    $profile = Get-PropValue -Object $context -Name "profile" -Default $null
    $plan = Get-PropValue -Object $context -Name "plan" -Default $null
    $tenantId = Normalize-Text (Get-PropValue -Object $tenant -Name "id" -Default "")
    if (-not $tenantId) {
        continue
    }

    $segment = Resolve-BusinessSegment -Profile $profile -Tenant $tenant
    $category = Normalize-Text (Get-PropValue -Object $segment -Name "business_category" -Default "general_small_business")
    $subcategory = Normalize-Text (Get-PropValue -Object $segment -Name "business_subcategory" -Default "other")

    $profileRecord = $segmentProfiles | Where-Object { (Normalize-Text $_.business_category) -eq $category } | Select-Object -First 1
    if (-not $profileRecord) {
        $profileRecord = $segmentProfiles | Where-Object { (Normalize-Text $_.segment_profile_id) -eq "segment_profile_general_small_business" } | Select-Object -First 1
    }

    $categoryCustomerSafeLabel = (($categories | Where-Object { (Normalize-Text $_.business_category) -eq $category } | Select-Object -First 1).customer_safe_label)
    $subcategoryCustomerSafeLabel = (($subcategories | Where-Object { (Normalize-Text $_.business_subcategory) -eq $subcategory } | Select-Object -First 1).customer_safe_label)
    $enabledFeatures = Normalize-StringList -Value (Get-PropValue -Object $plan -Name "enabledFeatures" -Default @()) -MaxItems 16 -MaxLength 80

    $tenantRecommendationPath = Join-Path $recommendationsDir ("{0}.json" -f $tenantId)
    $tenantRecommendationData = Read-JsonSafe -Path $tenantRecommendationPath
    $recommendationCount = 0
    if ($tenantRecommendationData) {
        $recommendationCount = @((Get-PropValue -Object $tenantRecommendationData -Name "recommendations" -Default @())).Count
    }

    $tenantFits += [pscustomobject]@{
        tenant_id = $tenantId
        active = [bool]($tenantId -eq $activeTenantId)
        business_name = Normalize-ShortText -Value (Get-PropValue -Object $profile -Name "businessName" -Default "") -MaxLength 120
        business_type = Normalize-ShortText -Value (Get-PropValue -Object $profile -Name "businessType" -Default "") -MaxLength 80
        business_category = $category
        business_subcategory = $subcategory
        segment_profile_id = Normalize-Text (Get-PropValue -Object $profileRecord -Name "segment_profile_id" -Default "segment_profile_general_small_business")
        onboarding_overlay_ids = Normalize-StringList -Value (Get-PropValue -Object $profileRecord -Name "onboarding_overlay_ids" -Default @()) -MaxItems 16 -MaxLength 80
        dashboard_overlay_ids = Normalize-StringList -Value (Get-PropValue -Object $profileRecord -Name "dashboard_overlay_ids" -Default @()) -MaxItems 16 -MaxLength 80
        recommendation_overlay_ids = Normalize-StringList -Value (Get-PropValue -Object $profileRecord -Name "recommendation_overlay_ids" -Default @()) -MaxItems 16 -MaxLength 80
        tool_bundle_ids = Normalize-StringList -Value (Get-PropValue -Object $profileRecord -Name "tool_bundle_ids" -Default @()) -MaxItems 16 -MaxLength 80
        workflow_pack_ids = Normalize-StringList -Value (Get-PropValue -Object $profileRecord -Name "workflow_pack_ids" -Default @()) -MaxItems 16 -MaxLength 80
        recommendation_rule_pack_ids = Normalize-StringList -Value (Get-PropValue -Object $profileRecord -Name "recommendation_rule_pack_ids" -Default @()) -MaxItems 16 -MaxLength 80
        wedge_status = Normalize-ShortText -Value (Get-PropValue -Object $profileRecord -Name "status" -Default "planned") -MaxLength 32
        tenant_fit_confidence = [double](Get-PropValue -Object $segment -Name "tenant_fit_confidence" -Default 0.40)
        tenant_fit_reason = Normalize-ShortText -Value (Get-PropValue -Object $segment -Name "tenant_fit_reason" -Default "") -MaxLength 240
        customer_safe_category_label = Normalize-ShortText -Value $categoryCustomerSafeLabel -MaxLength 120
        customer_safe_subcategory_label = Normalize-ShortText -Value $subcategoryCustomerSafeLabel -MaxLength 120
        enabled_feature_count = $enabledFeatures.Count
        enabled_features = $enabledFeatures
        recommendation_count = [int]$recommendationCount
        source_artifacts = @($tenantWorkspacePath, $toolRegistryPath, $tenantRecommendationPath)
    }
}

$customerReadyPackCount = @($workflowPacks | Where-Object { (Normalize-Text $_.status) -eq "customer_ready" }).Count
$experimentalPackCount = @($workflowPacks | Where-Object { (Normalize-Text $_.status) -eq "experimental" }).Count
$fallbackPackAvailable = @($workflowPacks | Where-Object { (Normalize-Text $_.workflow_pack_id) -eq "workflow_pack_general_small_business" }).Count -gt 0
$activeTenantFit = $tenantFits | Where-Object { $_.active } | Select-Object -First 1

$frameworkStatus = "PASS"
if (-not $fallbackPackAvailable) {
    $frameworkStatus = "WARN"
}

$frameworkNextAction = if ($activeTenantFit) {
    "Use the active tenant fit to wire segment-specific onboarding and dashboard behavior later, while keeping only customer_ready packs public by default."
}
else {
    "Classify at least one tenant through the wedge-pack framework so segment-fit outputs are exercised against real tenant context."
}

$frameworkArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $frameworkStatus
    business_category_count = $categories.Count
    business_subcategory_count = $subcategories.Count
    wedge_pack_count = $workflowPacks.Count
    customer_ready_pack_count = [int]$customerReadyPackCount
    experimental_pack_count = [int]$experimentalPackCount
    fallback_pack_available = [bool]$fallbackPackAvailable
    active_tenant_id = $activeTenantId
    active_tenant_fit = $activeTenantFit
    recommended_next_action = $frameworkNextAction
    command_run = $commandRun
    repo_root = $repoRoot
    categories = @($categories)
    subcategories = @($subcategories)
    wedge_packs = @($workflowPacks)
    tool_bundles = @($toolBundles)
    recommendation_rule_packs = @($recommendationRulePacks)
    segment_profiles = @($segmentProfiles)
    tenant_fit = @($tenantFits)
    source_artifacts = @($tenantWorkspacePath, $toolRegistryPath, $systemTruthPath, $billingSummaryPath)
}

$segmentOverlayArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $frameworkStatus
    onboarding_overlays = @($onboardingOverlays)
    dashboard_overlays = @($dashboardOverlays)
    recommendation_overlays = @($recommendationOverlays)
    active_tenant_id = $activeTenantId
    active_tenant_overlay_fit = if ($activeTenantFit) {
        [ordered]@{
            onboarding_overlay_ids = @($activeTenantFit.onboarding_overlay_ids)
            dashboard_overlay_ids = @($activeTenantFit.dashboard_overlay_ids)
            recommendation_overlay_ids = @($activeTenantFit.recommendation_overlay_ids)
        }
    } else {
        [ordered]@{
            onboarding_overlay_ids = @()
            dashboard_overlay_ids = @()
            recommendation_overlay_ids = @()
        }
    }
    recommended_next_action = $frameworkNextAction
    command_run = $commandRun
    repo_root = $repoRoot
}

$workflowPackArtifact = [ordered]@{
    timestamp_utc = $nowUtc
    overall_status = $frameworkStatus
    workflow_packs = @($workflowPacks)
    tool_bundles = @($toolBundles)
    recommendation_rule_packs = @($recommendationRulePacks)
    active_tenant_id = $activeTenantId
    active_tenant_pack_fit = if ($activeTenantFit) {
        [ordered]@{
            workflow_pack_ids = @($activeTenantFit.workflow_pack_ids)
            tool_bundle_ids = @($activeTenantFit.tool_bundle_ids)
            recommendation_rule_pack_ids = @($activeTenantFit.recommendation_rule_pack_ids)
        }
    } else {
        [ordered]@{
            workflow_pack_ids = @()
            tool_bundle_ids = @()
            recommendation_rule_pack_ids = @()
        }
    }
    recommended_next_action = $frameworkNextAction
    command_run = $commandRun
    repo_root = $repoRoot
}

$registryArtifact = [ordered]@{
    generated_at_utc = $nowUtc
    current_status = $frameworkStatus
    current_framework_generation_timestamp = $nowUtc
    wedge_packs = @($workflowPacks | ForEach-Object {
        [ordered]@{
            workflow_pack_id = $_.workflow_pack_id
            business_category = $_.business_category
            business_subcategory = @($_.business_subcategory)
            status = $_.status
            wedge_status = $_.wedge_status
            customer_safe_label = $_.customer_safe_label
        }
    })
    current_categories = @($categories | ForEach-Object { $_.business_category })
    current_subcategories = @($subcategories | ForEach-Object { $_.business_subcategory })
    pack_statuses = [ordered]@{
        customer_ready = [int]$customerReadyPackCount
        pilot_ready = [int](@($workflowPacks | Where-Object { (Normalize-Text $_.status) -eq "pilot_ready" }).Count)
        experimental = [int]$experimentalPackCount
        planned = [int](@($workflowPacks | Where-Object { (Normalize-Text $_.status) -eq "planned" }).Count)
    }
    default_fallback_rules = $policy.default_fallback_segment_behavior
    latest_artifacts = [ordered]@{
        framework = $frameworkArtifactPath
        overlays = $segmentOverlayArtifactPath
        workflow_packs = $workflowPackArtifactPath
        policy = $wedgePackPolicyPath
    }
    active_tenant_fit = $activeTenantFit
}

Write-JsonFile -Path $wedgePackPolicyPath -Data $policy
Write-JsonFile -Path $frameworkArtifactPath -Data $frameworkArtifact
Write-JsonFile -Path $segmentOverlayArtifactPath -Data $segmentOverlayArtifact
Write-JsonFile -Path $workflowPackArtifactPath -Data $workflowPackArtifact
Write-JsonFile -Path $wedgePackRegistryPath -Data $registryArtifact

$output = [ordered]@{
    ok = $true
    overall_status = $frameworkStatus
    active_tenant_id = $activeTenantId
    wedge_pack_count = $workflowPacks.Count
    customer_ready_pack_count = [int]$customerReadyPackCount
    experimental_pack_count = [int]$experimentalPackCount
    fallback_pack_available = [bool]$fallbackPackAvailable
    framework_artifact = $frameworkArtifactPath
    segment_overlay_artifact = $segmentOverlayArtifactPath
    workflow_pack_artifact = $workflowPackArtifactPath
    registry_artifact = $wedgePackRegistryPath
    policy_artifact = $wedgePackPolicyPath
}

$output | ConvertTo-Json -Depth 20
