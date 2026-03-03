[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$AnswersJson = ""
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

function Parse-AnswersObject {
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
        if ($obj -is [hashtable]) { return $obj }
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

function Get-LowerText {
    param($Value)
    if ($null -eq $Value) { return "" }
    if ($Value -is [System.Array]) {
        return ((@($Value) | ForEach-Object { [string]$_ }) -join " ").ToLowerInvariant()
    }
    return ([string]$Value).ToLowerInvariant()
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

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$toolRegistryPath = Join-Path $repoRoot "config\tool_registry.json"
$tiersPath = Join-Path $repoRoot "config\tiers.json"
$addonsPath = Join-Path $repoRoot "config\addons.json"

$registry = Read-JsonSafe -Path $toolRegistryPath -Default ([ordered]@{ tools = @() })
$tiers = Read-JsonSafe -Path $tiersPath -Default ([ordered]@{ tiers = @(); default_tier = "starter" })
$addons = Read-JsonSafe -Path $addonsPath -Default ([ordered]@{ addons = @() })
$answers = Parse-AnswersObject -InputValue $AnswersJson

$goalText = Get-LowerText -Value (Get-MapValue -Map $answers -Key "goal")
$issuesText = Get-LowerText -Value (Get-MapValue -Map $answers -Key "current_issues")
$marketingText = Get-LowerText -Value (Get-MapValue -Map $answers -Key "marketing_status")
$salesText = Get-LowerText -Value (Get-MapValue -Map $answers -Key "sales_pipeline_status")
$budgetText = Get-LowerText -Value (Get-MapValue -Map $answers -Key "budget")
$registryTools = @(To-Array (Get-MapValue -Map $registry -Key "tools" -Default @()))
$tierList = @(To-Array (Get-MapValue -Map $tiers -Key "tiers" -Default @()))
$addonList = @(To-Array (Get-MapValue -Map $addons -Key "addons" -Default @()))

$recommendedToolIds = New-Object System.Collections.Generic.List[string]
$reasons = New-Object System.Collections.Generic.List[string]
$recommendedToolIds.Add("rescue_plan_v1") | Out-Null
$reasons.Add("Baseline stabilization is recommended for all onboarding flows.") | Out-Null

$marketingNeeded = ($marketingText -match "none|weak|stuck|poor|not|no ") -or ($goalText -match "marketing|brand|lead")
if ($marketingNeeded) {
    if (-not $recommendedToolIds.Contains("marketing_pack_v1")) {
        $recommendedToolIds.Add("marketing_pack_v1") | Out-Null
    }
    $reasons.Add("Marketing signals indicate campaign and messaging support is needed.") | Out-Null
}

$salesNeeded = ($salesText -match "empty|weak|stuck|slow|poor|not|no ") -or ($goalText -match "sales|pipeline|close|revenue") -or ($issuesText -match "follow-?up|conversion|pipeline")
if ($salesNeeded) {
    if (-not $recommendedToolIds.Contains("sales_followup_v1")) {
        $recommendedToolIds.Add("sales_followup_v1") | Out-Null
    }
    $reasons.Add("Sales pipeline signals indicate follow-up workflow support is needed.") | Out-Null
}

$recommendedTierId = [string](Get-MapValue -Map $tiers -Key "default_tier" -Default "starter")
if (-not $recommendedTierId) {
    $recommendedTierId = "starter"
}
if ($recommendedToolIds.Count -ge 3) {
    $recommendedTierId = "pro"
}
elseif ($recommendedToolIds.Count -eq 2) {
    $recommendedTierId = "starter"
}
else {
    $recommendedTierId = "free"
}

if ($budgetText -match "0|low|none|tight") {
    $recommendedTierId = "free"
    $reasons.Add("Budget signal is low, so the free tier is recommended first.") | Out-Null
}

$toolMap = @{}
foreach ($tool in $registryTools) {
    if ($tool -and $tool.tool_id) {
        $toolMap[[string]$tool.tool_id] = $tool
    }
}

$recommendedTools = New-Object System.Collections.Generic.List[object]
foreach ($toolId in @($recommendedToolIds.ToArray())) {
    if ($toolMap.ContainsKey($toolId)) {
        $tool = $toolMap[$toolId]
        $recommendedTools.Add([ordered]@{
                tool_id    = [string]$tool.tool_id
                version    = [string]$tool.version
                title      = [string]$tool.title
                risk_level = [string]$tool.risk_level
                tags       = @(To-Array $tool.tags)
            }) | Out-Null
    }
}

$tierObj = $null
foreach ($tier in $tierList) {
    if ($tier -and $tier.tier_id -and ([string]$tier.tier_id).ToLowerInvariant() -eq $recommendedTierId.ToLowerInvariant()) {
        $tierObj = $tier
        break
    }
}

$suggestedAddons = New-Object System.Collections.Generic.List[object]
if ($tierObj) {
    $included = @((To-Array $tierObj.included_tools) | ForEach-Object { [string]$_ })
    foreach ($addon in $addonList) {
        if (-not $addon -or -not $addon.tool_id) { continue }
        $toolId = [string]$addon.tool_id
        if ($included -notcontains $toolId -and $recommendedToolIds.Contains($toolId)) {
            $suggestedAddons.Add([ordered]@{
                    addon_id           = [string]$addon.addon_id
                    tool_id            = $toolId
                    name               = [string]$addon.name
                    one_off_price_usd  = $addon.one_off_price_usd
                    description        = [string]$addon.description
                }) | Out-Null
        }
    }
}

[pscustomobject]@{
    ok                = $true
    generated_at_utc  = (Get-Date).ToUniversalTime().ToString("o")
    recommended_tier  = if ($tierObj) { $tierObj } else { [ordered]@{ tier_id = $recommendedTierId } }
    recommended_tools = @($recommendedTools.ToArray())
    suggested_addons  = @($suggestedAddons.ToArray())
    reasons           = @($reasons.ToArray() | Select-Object -Unique)
} | ConvertTo-Json -Depth 16
