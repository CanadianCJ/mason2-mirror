[CmdletBinding()]
param(
    [string]$RootPath = "",
    [Parameter(Mandatory = $true)][string]$ToolId,
    [string]$TenantId = "",
    [string]$WorkspaceId = "",
    [string]$ClientName = "client",
    [string]$InputJson = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param([string]$CandidateRoot)
    if ($CandidateRoot -and (Test-Path -LiteralPath $CandidateRoot)) {
        return (Resolve-Path -LiteralPath $CandidateRoot).Path
    }
    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Read-JsonSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        $Default = $null
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        return $Default
    }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if (-not $raw.Trim()) {
        return $Default
    }
    try {
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
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value ($Object | ConvertTo-Json -Depth $Depth) -Encoding UTF8
}

function To-Array {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return $Value }
    return @($Value)
}

function Redact-Secrets {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    $redacted = [string]$Text
    $redacted = [regex]::Replace($redacted, "(?i)\bsk-proj-[A-Za-z0-9_\-]{8,}\b", "[REDACTED_OPENAI_KEY]")
    $redacted = [regex]::Replace($redacted, "(?i)\bsk-[A-Za-z0-9_\-]{8,}\b", "[REDACTED_OPENAI_KEY]")
    $redacted = [regex]::Replace($redacted, "(?i)\b(?:ghp|gho|ghu|ghs)_[A-Za-z0-9_]{20,}\b", "[REDACTED_GITHUB_TOKEN]")
    $redacted = [regex]::Replace($redacted, "(?i)\bgithub_pat_[A-Za-z0-9_]{20,}\b", "[REDACTED_GITHUB_TOKEN]")
    $redacted = [regex]::Replace(
        $redacted,
        "(?is)-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----.*?-----END [A-Z0-9 ]*PRIVATE KEY-----",
        "[REDACTED_PRIVATE_KEY_BLOCK]"
    )
    return $redacted
}

function ConvertTo-SafeToken {
    param([string]$Value)
    $raw = ([string]$Value).Trim().ToLowerInvariant()
    if (-not $raw) { $raw = "item" }
    $safe = ($raw -replace "[^a-z0-9_-]+", "-").Trim("-")
    if (-not $safe) { $safe = "item" }
    if ($safe.Length -gt 48) { $safe = $safe.Substring(0, 48).Trim("-") }
    if (-not $safe) { $safe = "item" }
    return $safe
}

function Parse-InputObject {
    param([string]$InputValue)
    if (-not $InputValue) { return [ordered]@{} }
    $raw = $InputValue
    if (Test-Path -LiteralPath $InputValue) {
        $raw = Get-Content -LiteralPath $InputValue -Raw -Encoding UTF8
    }
    if (-not $raw -or -not $raw.Trim()) {
        return [ordered]@{}
    }
    $safeRaw = Redact-Secrets -Text $raw
    try {
        $obj = $safeRaw | ConvertFrom-Json -ErrorAction Stop
        if ($obj -is [hashtable]) {
            return $obj
        }
        $map = [ordered]@{}
        foreach ($p in $obj.PSObject.Properties) {
            $map[$p.Name] = $p.Value
        }
        return $map
    }
    catch {
        return [ordered]@{}
    }
}

function Get-MapValue {
    param(
        $Map,
        [string]$Key,
        $Default = $null
    )
    if ($null -eq $Map -or -not $Key) {
        return $Default
    }
    if ($Map -is [System.Collections.IDictionary]) {
        if ($Map.Contains($Key)) {
            return $Map[$Key]
        }
        return $Default
    }
    $prop = $Map.PSObject.Properties[$Key]
    if ($null -ne $prop) {
        return $prop.Value
    }
    return $Default
}

function New-TaskItem {
    param(
        [Parameter(Mandatory = $true)][string]$RunId,
        [Parameter(Mandatory = $true)][string]$ToolIdValue,
        [Parameter(Mandatory = $true)][string]$Title,
        [int]$Risk = 1
    )
    $seed = "{0}|{1}|{2}" -f $RunId, $ToolIdValue, $Title
    $hash = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($seed)
        $digest = $hash.ComputeHash($bytes)
        $hex = -join ($digest | ForEach-Object { $_.ToString("x2") })
    }
    finally {
        $hash.Dispose()
    }
    return [ordered]@{
        id             = ("tooltask-{0}" -f $hex.Substring(0, 12))
        component_id   = "mason"
        title          = $Title
        risk_level     = [int]$Risk
        status         = "pending"
        source         = "tool_runner"
        created_at     = (Get-Date).ToUniversalTime().ToString("o")
        evidence_files = @()
    }
}

function New-ArtifactFileEntry {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$Kind = "artifact",
        [string]$Label = ""
    )
    return [ordered]@{
        kind           = $Kind
        label          = $(if ($Label) { $Label } else { Split-Path -Leaf $Path })
        path           = $Path
        source         = "tool_runner"
        created_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    }
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$toolRegistryPath = Join-Path $repoRoot "config\tool_registry.json"
$workspaceScriptPath = Join-Path $repoRoot "tools\platform\WorkspaceManager.ps1"

$registry = Read-JsonSafe -Path $toolRegistryPath -Default ([ordered]@{ tools = @() })
$tools = @(To-Array (Get-MapValue -Map $registry -Key "tools" -Default @()))
$tool = $null
foreach ($t in $tools) {
    $candidateToolId = [string](Get-MapValue -Map $t -Key "tool_id")
    if ($candidateToolId -and $candidateToolId.ToLowerInvariant() -eq $ToolId.ToLowerInvariant()) {
        $tool = $t
        break
    }
}
if (-not $tool) {
    throw "Unknown tool_id: $ToolId"
}
$toolIdValue = [string](Get-MapValue -Map $tool -Key "tool_id")
$toolVersionValue = [string](Get-MapValue -Map $tool -Key "version")
$toolNameValue = [string](Get-MapValue -Map $tool -Key "name")
if (-not $toolNameValue) {
    $toolNameValue = [string](Get-MapValue -Map $tool -Key "title")
}
$toolCategoryValue = [string](Get-MapValue -Map $tool -Key "category")
$toolDescriptionValue = [string](Get-MapValue -Map $tool -Key "description")
$toolRiskValue = [string](Get-MapValue -Map $tool -Key "risk_level")
$toolStatusValue = [string](Get-MapValue -Map $tool -Key "status")
if (-not $toolStatusValue) {
    $toolStatusValue = "enabled"
}

$tenantIdValue = ""
if ([string]$TenantId) {
    $tenantIdValue = ConvertTo-SafeToken -Value $TenantId
}
$tenantArtifactPath = ""
$tenantArtifact = $null
$tenantRecord = [ordered]@{}
$tenantProfile = [ordered]@{}
$tenantPlan = [ordered]@{}
if ($tenantIdValue) {
    $tenantArtifactPath = Join-Path $repoRoot ("state\onyx\tenants\{0}.json" -f $tenantIdValue)
    $tenantArtifact = Read-JsonSafe -Path $tenantArtifactPath -Default $null
    if ($null -ne $tenantArtifact) {
        $tenantRecord = Get-MapValue -Map $tenantArtifact -Key "tenant" -Default ([ordered]@{})
        $tenantProfile = Get-MapValue -Map $tenantArtifact -Key "business_profile" -Default ([ordered]@{})
        $tenantPlan = Get-MapValue -Map $tenantArtifact -Key "plan" -Default ([ordered]@{})
    }
}
$tenantBusinessName = [string](Get-MapValue -Map $tenantProfile -Key "business_name")
$tenantOwnerValue = [string](Get-MapValue -Map $tenantRecord -Key "owner")
$tenantStatusLabel = [string](Get-MapValue -Map $tenantRecord -Key "status")
$tenantPlanTierValue = [string](Get-MapValue -Map $tenantRecord -Key "plan_tier")
if (-not $tenantPlanTierValue) {
    $tenantPlanTierValue = [string](Get-MapValue -Map $tenantPlan -Key "current_tier")
}
if ((-not $ClientName) -or $ClientName -eq "client") {
    if ($tenantBusinessName) {
        $ClientName = $tenantBusinessName
    }
}
if (-not $WorkspaceId -and $tenantIdValue) {
    $WorkspaceId = $tenantIdValue
}

if (-not (Test-Path -LiteralPath $workspaceScriptPath)) {
    throw "WorkspaceManager script missing: $workspaceScriptPath"
}

$workspaceJson = & $workspaceScriptPath -RootPath $repoRoot -WorkspaceId $WorkspaceId -ClientName $ClientName
$workspace = $workspaceJson | ConvertFrom-Json -ErrorAction Stop
if (-not $workspace.ok) {
    throw "Workspace creation failed."
}

$input = Parse-InputObject -InputValue $InputJson
$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
$runId = "toolrun_{0}_{1}" -f (Get-Date -Format "yyyyMMdd_HHmmss"), (ConvertTo-SafeToken -Value $toolIdValue)
$runRoot = Join-Path $repoRoot ("reports\tools\{0}" -f $runId)
$draftsDir = Join-Path $runRoot "drafts"
New-Item -ItemType Directory -Path $draftsDir -Force | Out-Null

$goal = [string](Get-MapValue -Map $input -Key "goal")
$businessType = [string](Get-MapValue -Map $input -Key "business_type")
$issues = @((To-Array (Get-MapValue -Map $input -Key "current_issues")) | ForEach-Object { [string]$_ } | Where-Object { $_.Trim() })
$salesPipelineStatus = [string](Get-MapValue -Map $input -Key "sales_pipeline_status")
$offers = @((To-Array (Get-MapValue -Map $input -Key "offers")) | ForEach-Object { [string]$_ } | Where-Object { $_.Trim() })
$objections = @((To-Array (Get-MapValue -Map $input -Key "objections")) | ForEach-Object { [string]$_ } | Where-Object { $_.Trim() })
$leadSources = @((To-Array (Get-MapValue -Map $input -Key "lead_sources")) | ForEach-Object { [string]$_ } | Where-Object { $_.Trim() })
$audience = [string](Get-MapValue -Map $input -Key "audience")
$marketingStatus = [string](Get-MapValue -Map $input -Key "marketing_status")

$summary = ""
$recommendations = @()
$draftFiles = New-Object System.Collections.Generic.List[string]
$artifactFiles = New-Object System.Collections.Generic.List[object]
$tasks = New-Object System.Collections.Generic.List[object]
$topRisks = @()
$messagePillars = @()
$draftObjects = @()
$followupSequences = @()

switch ($toolIdValue.ToLowerInvariant()) {
    "rescue_plan_v1" {
        $summary = "Rescue plan generated with immediate stabilization, short-term recovery, and checkpoint tasks."
        $recommendations = @(
            "Stabilize top operational blockers in the next 24 hours.",
            "Create a 7-day recovery checklist tied to owner and due date.",
            "Review progress at day 3 and day 7 with measurable outcomes."
        )
        $topRisks = if ($issues.Count -gt 0) {
            $issues
        }
        else {
            @("No explicit operating blockers were supplied.")
        }
        $tasks.Add((New-TaskItem -RunId $runId -ToolIdValue $toolIdValue -Title "Create 24-hour rescue stabilization checklist" -Risk 1)) | Out-Null
        $tasks.Add((New-TaskItem -RunId $runId -ToolIdValue $toolIdValue -Title "Assign owners to 7-day recovery actions" -Risk 1)) | Out-Null
    }
    "marketing_pack_v1" {
        $summary = "Marketing pack generated with message pillars, campaign themes, and launch tasks."
        $recommendations = @(
            "Publish one clear offer-focused campaign this week.",
            "Repurpose campaign messaging across 3 channels.",
            "Track response and adjust based on 7-day performance."
        )
        $draftPath = Join-Path $draftsDir "campaign_outline.txt"
        $draftText = @(
            "Campaign Goal: $goal"
            "Business Type: $businessType"
            "Top Issues: $($issues -join ', ')"
            ""
            "Pillars:"
            "- Problem framing"
            "- Clear offer"
            "- Simple call to action"
        ) -join "`r`n"
        Set-Content -LiteralPath $draftPath -Value (Redact-Secrets -Text $draftText) -Encoding UTF8
        $draftFiles.Add($draftPath) | Out-Null
        $artifactFiles.Add((New-ArtifactFileEntry -Path $draftPath -Kind "draft" -Label "campaign_outline")) | Out-Null
        $messagePillars = @(
            "Problem framing for $businessType",
            "Clear offer: $($(if ($offers.Count -gt 0) { $offers[0] } else { 'Core service' }))",
            "Simple call to action for $($(if ($audience) { $audience } else { 'current audience' }))"
        )
        $draftObjects = @(
            [ordered]@{
                title = "Campaign outline"
                path  = $draftPath
                type  = "text/plain"
            }
        )
        $tasks.Add((New-TaskItem -RunId $runId -ToolIdValue $toolIdValue -Title "Finalize campaign message pillars" -Risk 1)) | Out-Null
        $tasks.Add((New-TaskItem -RunId $runId -ToolIdValue $toolIdValue -Title "Schedule first campaign publish window" -Risk 1)) | Out-Null
    }
    "sales_followup_v1" {
        $summary = "Sales follow-up plan generated with sequence checkpoints and objection handling tasks."
        $recommendations = @(
            "Use a 3-touch follow-up cadence for new leads.",
            "Define objection responses for top 3 blockers.",
            "Track conversion deltas weekly."
        )
        $draftPath = Join-Path $draftsDir "followup_sequence.txt"
        $draftText = @(
            "Goal: $goal"
            "Sales Pipeline Status: $salesPipelineStatus"
            ""
            "Sequence:"
            "1) Day 0: Intro + value"
            "2) Day 2: proof + case"
            "3) Day 5: close attempt + deadline"
        ) -join "`r`n"
        Set-Content -LiteralPath $draftPath -Value (Redact-Secrets -Text $draftText) -Encoding UTF8
        $draftFiles.Add($draftPath) | Out-Null
        $artifactFiles.Add((New-ArtifactFileEntry -Path $draftPath -Kind "draft" -Label "followup_sequence")) | Out-Null
        $followupSequences = @(
            [ordered]@{
                name   = "3-touch follow-up"
                steps  = @(
                    "Day 0: Intro + value",
                    "Day 2: Proof + case",
                    "Day 5: Close attempt + deadline"
                )
                focus  = if ($objections.Count -gt 0) { $objections[0] } else { "Lead momentum" }
                source = if ($leadSources.Count -gt 0) { $leadSources[0] } else { "general" }
            }
        )
        $tasks.Add((New-TaskItem -RunId $runId -ToolIdValue $toolIdValue -Title "Create sales follow-up sequence template" -Risk 1)) | Out-Null
        $tasks.Add((New-TaskItem -RunId $runId -ToolIdValue $toolIdValue -Title "Define objection response playbook" -Risk 1)) | Out-Null
    }
    default {
        $summary = "Tool run completed."
        $recommendations = @("Review tool outputs and approve next actions.")
        $tasks.Add((New-TaskItem -RunId $runId -ToolIdValue $toolIdValue -Title "Review generated tool output" -Risk 1)) | Out-Null
    }
}

$tasksObj = @($tasks.ToArray())
$outputObj = switch ($toolIdValue.ToLowerInvariant()) {
    "rescue_plan_v1" {
        [ordered]@{
            summary             = $summary
            top_risks           = $topRisks
            recommended_actions = $recommendations
            tasks               = $tasksObj
        }
        break
    }
    "marketing_pack_v1" {
        [ordered]@{
            summary          = $summary
            message_pillars  = $messagePillars
            drafts           = $draftObjects
            tasks            = $tasksObj
            marketing_status = $marketingStatus
        }
        break
    }
    "sales_followup_v1" {
        [ordered]@{
            summary             = $summary
            followup_sequences  = $followupSequences
            tasks               = $tasksObj
            sales_pipeline_note = $salesPipelineStatus
        }
        break
    }
    default {
        [ordered]@{
            summary             = $summary
            recommended_actions = $recommendations
            tasks               = $tasksObj
        }
    }
}

$reportObj = [ordered]@{
    run_id           = $runId
    tenant_id        = $tenantIdValue
    tool_id          = $toolIdValue
    tool_name        = $toolNameValue
    tool_version     = $toolVersionValue
    status           = "completed"
    summary          = $summary
    recommendations  = $recommendations
    generated_at_utc = $generatedAtUtc
}

$toolRunPath = Join-Path $runRoot "tool_run.json"
$reportPath = Join-Path $runRoot "report.json"
$tasksPath = Join-Path $runRoot "tasks.json"
$artifactPath = Join-Path $runRoot "artifact.json"

$toolRunObj = [ordered]@{
    run_id                = $runId
    tenant_id             = $tenantIdValue
    tenant_business_name  = $tenantBusinessName
    tenant_owner          = $tenantOwnerValue
    tenant_status         = $tenantStatusLabel
    tenant_plan_tier      = $tenantPlanTierValue
    tenant_profile_path   = $tenantArtifactPath
    tool_id               = $toolIdValue
    tool_name             = $toolNameValue
    tool_version          = $toolVersionValue
    title                 = $toolNameValue
    category              = $toolCategoryValue
    description           = $toolDescriptionValue
    risk_level            = $toolRiskValue
    status                = $toolStatusValue
    workspace_id          = [string]$workspace.workspace_id
    workspace_path        = [string]$workspace.workspace_path
    client_name           = $ClientName
    input                 = $input
    artifact_path         = $artifactPath
    report_path           = $reportPath
    tasks_path            = $tasksPath
    generated_at_utc      = $generatedAtUtc
}

$artifactObj = [ordered]@{
    artifact_version = 1
    run_id           = $runId
    status           = "completed"
    created_at_utc   = $generatedAtUtc
    tool             = [ordered]@{
        tool_id      = $toolIdValue
        name         = $toolNameValue
        version      = $toolVersionValue
        category     = $toolCategoryValue
        description  = $toolDescriptionValue
        risk_level   = $toolRiskValue
        status       = $toolStatusValue
    }
    tenant           = [ordered]@{
        tenant_id          = $tenantIdValue
        business_name      = $tenantBusinessName
        owner              = $tenantOwnerValue
        status             = $tenantStatusLabel
        plan_tier          = $tenantPlanTierValue
        tenant_profile_path = $tenantArtifactPath
    }
    workspace        = [ordered]@{
        workspace_id   = [string]$workspace.workspace_id
        workspace_path = [string]$workspace.workspace_path
    }
    source_metadata  = [ordered]@{
        runner_script     = $PSCommandPath
        registry_path     = $toolRegistryPath
        tenant_source     = $tenantArtifactPath
        generated_at_utc  = $generatedAtUtc
    }
    input            = $input
    output           = $outputObj
    recommendations  = $recommendations
    tasks            = $tasksObj
    artifact_files   = @($artifactFiles.ToArray())
    tool_run_path    = $toolRunPath
    report_path      = $reportPath
    tasks_path       = $tasksPath
    output_root      = $runRoot
}

Write-JsonFile -Path $toolRunPath -Object $toolRunObj -Depth 20
Write-JsonFile -Path $reportPath -Object $reportObj -Depth 20
Write-JsonFile -Path $tasksPath -Object $tasksObj -Depth 20
Write-JsonFile -Path $artifactPath -Object $artifactObj -Depth 24

[pscustomobject]@{
    ok               = $true
    run_id           = $runId
    tenant_id        = $tenantIdValue
    tool_id          = $toolIdValue
    tool_name        = $toolNameValue
    status           = "completed"
    summary          = $summary
    workspace_id     = [string]$workspace.workspace_id
    output_root      = $runRoot
    artifact_path    = $artifactPath
    tool_run_path    = $toolRunPath
    report_path      = $reportPath
    tasks_path       = $tasksPath
    drafts           = @($draftFiles.ToArray())
    task_count       = @($tasksObj).Count
} | ConvertTo-Json -Depth 12
