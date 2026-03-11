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
        "security_posture" { return "Security Posture" }
        "billing" { return "Billing" }
        "mirror" { return "Mirror" }
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
        $hasProperty = $false
        if ($data -is [System.Collections.IDictionary]) {
            $hasProperty = $data.Contains($requiredKey)
        }
        else {
            $hasProperty = $null -ne $data.PSObject.Properties[$requiredKey]
        }
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
$dataGovernanceStatePath = Join-Path $stateKnowledgeDir "data_governance_requests.json"

$onyxStateDir = Join-Path $repoRoot "state\onyx"
$tenantWorkspacePath = Join-Path $onyxStateDir "tenant_workspace.json"
$planStatePath = Join-Path $onyxStateDir "plan_state.json"
$onyxTenantsDir = Join-Path $onyxStateDir "tenants"
$onyxRecommendationsDir = Join-Path $onyxStateDir "recommendations"
$onyxBillingDir = Join-Path $onyxStateDir "billing"

$toolRegistryPath = Join-Path $repoRoot "config\tool_registry.json"
$componentRegistryPath = Join-Path $repoRoot "config\component_registry.json"
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

$stackStatusUrl = "http://127.0.0.1:8000/api/stack_status"
$athenaUiUrl = "http://127.0.0.1:8000/athena/"
$athenaHealthUrl = "http://127.0.0.1:8000/api/health"
$onyxRootUrl = "http://127.0.0.1:5353/"
$onyxMainJsUrl = "http://127.0.0.1:5353/main.dart.js"
$masonApiHealthUrl = "http://127.0.0.1:8383/health"
$seedApiHealthUrl = "http://127.0.0.1:8109/health"
$bridgeHealthUrl = "http://127.0.0.1:8484/health"

$stackStatusProbe = Invoke-HttpJsonProbeCached -Url $stackStatusUrl -TimeoutSeconds $HttpTimeoutSeconds
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
        mason  = "stack/base"
        athena = "Athena"
        onyx   = "Onyx"
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
    if ($enabledTools.Count -gt 0) {
        $billingChecks += New-Check -Name "entitlement_state" -Status "PASS" -Detail ("Tenant entitlement state is readable; enabled_tools={0}." -f ($enabledTools -join ", ")) -Component "billing" -Path $billingSummaryPath -NextAction "No action required."
    }
    else {
        $billingChecks += New-Check -Name "entitlement_state" -Status "FAIL" -Detail "Billing summary is readable but tenant enabled_tools is empty." -Component "billing" -Path $billingSummaryPath -NextAction "Repair entitlement resolution so the active tenant exposes enabled tools and features."
    }
}
$sections += New-SectionResult -SectionName "billing/entitlements" -Checks $billingChecks

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
