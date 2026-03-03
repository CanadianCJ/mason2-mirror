[CmdletBinding()]
param(
    [string]$RootPath = "",
    [Parameter(Mandatory = $true)][string]$ToolId,
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
$toolTitleValue = [string](Get-MapValue -Map $tool -Key "title")
$toolRiskValue = [string](Get-MapValue -Map $tool -Key "risk_level")

if (-not (Test-Path -LiteralPath $workspaceScriptPath)) {
    throw "WorkspaceManager script missing: $workspaceScriptPath"
}

$workspaceJson = & $workspaceScriptPath -RootPath $repoRoot -WorkspaceId $WorkspaceId -ClientName $ClientName
$workspace = $workspaceJson | ConvertFrom-Json -ErrorAction Stop
if (-not $workspace.ok) {
    throw "Workspace creation failed."
}

$input = Parse-InputObject -InputValue $InputJson
$runId = "toolrun_{0}_{1}" -f (Get-Date -Format "yyyyMMdd_HHmmss"), (ConvertTo-SafeToken -Value $toolIdValue)
$runRoot = Join-Path $repoRoot ("reports\tools\{0}" -f $runId)
$draftsDir = Join-Path $runRoot "drafts"
New-Item -ItemType Directory -Path $draftsDir -Force | Out-Null

$goal = [string](Get-MapValue -Map $input -Key "goal")
$businessType = [string](Get-MapValue -Map $input -Key "business_type")
$issues = @((To-Array (Get-MapValue -Map $input -Key "current_issues")) | ForEach-Object { [string]$_ } | Where-Object { $_.Trim() })
$salesPipelineStatus = [string](Get-MapValue -Map $input -Key "sales_pipeline_status")

$summary = ""
$recommendations = @()
$draftFiles = New-Object System.Collections.Generic.List[string]
$tasks = New-Object System.Collections.Generic.List[object]

switch ($toolIdValue.ToLowerInvariant()) {
    "rescue_plan_v1" {
        $summary = "Rescue plan generated with immediate stabilization, short-term recovery, and checkpoint tasks."
        $recommendations = @(
            "Stabilize top operational blockers in the next 24 hours.",
            "Create a 7-day recovery checklist tied to owner and due date.",
            "Review progress at day 3 and day 7 with measurable outcomes."
        )
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
        $tasks.Add((New-TaskItem -RunId $runId -ToolIdValue $toolIdValue -Title "Create sales follow-up sequence template" -Risk 1)) | Out-Null
        $tasks.Add((New-TaskItem -RunId $runId -ToolIdValue $toolIdValue -Title "Define objection response playbook" -Risk 1)) | Out-Null
    }
    default {
        $summary = "Tool run completed."
        $recommendations = @("Review tool outputs and approve next actions.")
        $tasks.Add((New-TaskItem -RunId $runId -ToolIdValue $toolIdValue -Title "Review generated tool output" -Risk 1)) | Out-Null
    }
}

$reportObj = [ordered]@{
    run_id          = $runId
    tool_id         = $toolIdValue
    tool_version    = $toolVersionValue
    summary         = $summary
    recommendations = $recommendations
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
}

$toolRunObj = [ordered]@{
    run_id          = $runId
    tool_id         = $toolIdValue
    tool_version    = $toolVersionValue
    title           = $toolTitleValue
    risk_level      = $toolRiskValue
    workspace_id    = [string]$workspace.workspace_id
    workspace_path  = [string]$workspace.workspace_path
    client_name     = $ClientName
    input           = $input
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
}

$tasksObj = @($tasks.ToArray())

$toolRunPath = Join-Path $runRoot "tool_run.json"
$reportPath = Join-Path $runRoot "report.json"
$tasksPath = Join-Path $runRoot "tasks.json"
Write-JsonFile -Path $toolRunPath -Object $toolRunObj -Depth 20
Write-JsonFile -Path $reportPath -Object $reportObj -Depth 20
Write-JsonFile -Path $tasksPath -Object $tasksObj -Depth 20

[pscustomobject]@{
    ok               = $true
    run_id           = $runId
    tool_id          = $toolIdValue
    workspace_id     = [string]$workspace.workspace_id
    output_root      = $runRoot
    tool_run_path    = $toolRunPath
    report_path      = $reportPath
    tasks_path       = $tasksPath
    drafts           = @($draftFiles.ToArray())
    task_count       = @($tasksObj).Count
} | ConvertTo-Json -Depth 12
