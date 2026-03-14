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
        [int]$Depth = 16
    )

    Ensure-Parent -Path $Path
    $json = $Object | ConvertTo-Json -Depth $Depth
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
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
        return $raw | ConvertFrom-Json -Depth 100
    }
    catch {
        return $Default
    }
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

    return $null -ne $Object.PSObject.Properties[$Name]
}

function Convert-ToUtcIso {
    param($Value)

    if ($null -eq $Value) {
        return ""
    }

    if ($Value -is [datetimeoffset]) {
        return $Value.ToUniversalTime().ToString("o")
    }

    if ($Value -is [datetime]) {
        return ([datetimeoffset]$Value).ToUniversalTime().ToString("o")
    }

    $text = Normalize-Text $Value
    if (-not $text) {
        return ""
    }

    try {
        return ([datetimeoffset]::Parse($text, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)).ToUniversalTime().ToString("o")
    }
    catch {
        return ""
    }
}

function Get-NowUtc {
    return (Get-Date).ToUniversalTime()
}

function Parse-DateSafe {
    param($Value)

    $text = Normalize-Text $Value
    if (-not $text) {
        return $null
    }

    try {
        return [datetimeoffset]::Parse($text, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
    }
    catch {
        return $null
    }
}

function Get-AgeHours {
    param($Timestamp)

    $parsed = Parse-DateSafe -Value $Timestamp
    if ($null -eq $parsed) {
        return [double]::PositiveInfinity
    }
    return [math]::Round(((Get-NowUtc) - $parsed.UtcDateTime).TotalHours, 2)
}

function Get-RepoRoot {
    param([string]$OverrideRoot)

    $candidate = Normalize-Text $OverrideRoot
    if ($candidate) {
        return [System.IO.Path]::GetFullPath($candidate)
    }

    $scriptDir = Split-Path -Parent $PSCommandPath
    return [System.IO.Path]::GetFullPath((Join-Path $scriptDir "..\.."))
}

function Get-ContractPorts {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $path = Join-Path $RepoRoot "config\ports.json"
    $payload = Read-JsonSafe -Path $path -Default $null
    $portsNode = if ($payload) { Get-PropValue -Object $payload -Name "ports" -Default $payload } else { $null }

    $defaults = [ordered]@{
        mason_api = 8383
        seed_api  = 8109
        bridge    = 8484
        athena    = 8000
        onyx      = 5353
    }

    $ports = [ordered]@{}
    foreach ($key in @($defaults.Keys)) {
        $parsed = 0
        $raw = Get-PropValue -Object $portsNode -Name $key -Default $defaults[$key]
        if (-not [int]::TryParse([string]$raw, [ref]$parsed) -or $parsed -le 0) {
            $parsed = [int]$defaults[$key]
        }
        $ports[$key] = [int]$parsed
    }

    return $ports
}

function Get-PortListenerRows {
    param([int[]]$Ports)

    $rows = @()
    if (-not $Ports -or $Ports.Count -eq 0) {
        return $rows
    }

    $portSet = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($port in @($Ports | Sort-Object -Unique)) {
        [void]$portSet.Add([int]$port)
    }

    try {
        foreach ($row in @(Get-NetTCPConnection -State Listen -ErrorAction Stop)) {
            $localPort = [int]$row.LocalPort
            if (-not $portSet.Contains($localPort)) {
                continue
            }

            $rows += [pscustomobject]@{
                local_port    = $localPort
                local_address = [string]$row.LocalAddress
                owning_pid    = [int]$row.OwningProcess
            }
        }
    }
    catch {
        foreach ($line in @(netstat -ano -p tcp 2>$null)) {
            $trimmed = ([string]$line).Trim()
            if ($trimmed -notmatch '^\s*TCP\s+(\S+):(\d+)\s+\S+\s+LISTENING\s+(\d+)\s*$') {
                continue
            }

            $parsedPort = 0
            $parsedPid = 0
            if (-not [int]::TryParse([string]$Matches[2], [ref]$parsedPort)) {
                continue
            }
            if (-not $portSet.Contains($parsedPort)) {
                continue
            }
            if (-not [int]::TryParse([string]$Matches[3], [ref]$parsedPid)) {
                continue
            }

            $rows += [pscustomobject]@{
                local_port    = [int]$parsedPort
                local_address = [string]$Matches[1]
                owning_pid    = [int]$parsedPid
            }
        }
    }

    return @($rows)
}

function Get-ListenerMap {
    param([int[]]$Ports)

    $map = @{}
    foreach ($port in @($Ports | Sort-Object -Unique)) {
        $map[[int]$port] = @()
    }

    foreach ($row in @(Get-PortListenerRows -Ports $Ports)) {
        $port = [int]$row.local_port
        $existing = @()
        if ($map.ContainsKey($port)) {
            $existing = @($map[$port])
        }
        $existing += $row
        $map[$port] = @($existing)
    }

    return $map
}

function Get-CurrentLivePidMap {
    param($StackPidsPayload)

    $result = @{}
    $current = Get-PropValue -Object $StackPidsPayload -Name "current_live_pids" -Default $null
    if (-not $current) {
        return $result
    }

    if ($current -is [System.Collections.IDictionary]) {
        foreach ($key in @($current.Keys)) {
            $parsed = 0
            if ([int]::TryParse([string]$current[$key], [ref]$parsed) -and $parsed -gt 0) {
                $result[[string]$key] = [int]$parsed
            }
        }
        return $result
    }

    foreach ($property in @($current.PSObject.Properties)) {
        $parsed = 0
        if ([int]::TryParse([string]$property.Value, [ref]$parsed) -and $parsed -gt 0) {
            $result[[string]$property.Name] = [int]$parsed
        }
    }

    return $result
}

function Invoke-LoopbackProbe {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSec = 6
    )

    try {
        $params = @{
            Uri         = $Url
            Method      = "Get"
            TimeoutSec  = $TimeoutSec
            ErrorAction = "Stop"
        }
        if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey("UseBasicParsing")) {
            $params["UseBasicParsing"] = $true
        }

        $response = Invoke-WebRequest @params
        return [ordered]@{
            ok             = ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400)
            status_code    = [int]$response.StatusCode
            error          = ""
            checked_at_utc = Convert-ToUtcIso (Get-NowUtc)
            url            = $Url
        }
    }
    catch {
        $statusCode = 0
        if ($_.Exception.Response) {
            try {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
            catch {
                $statusCode = 0
            }
        }

        return [ordered]@{
            ok             = $false
            status_code    = $statusCode
            error          = $_.Exception.Message
            checked_at_utc = Convert-ToUtcIso (Get-NowUtc)
            url            = $Url
        }
    }
}

function Get-SnapshotTimestamp {
    param(
        $Payload,
        [string]$Path
    )

    foreach ($key in @(
        "timestamp_utc",
        "generated_at_utc",
        "updated_at_utc",
        "lastUpdatedAtUtc",
        "last_updated_utc",
        "created_at",
        "createdAtUtc",
        "last_build_timestamp_utc"
    )) {
        $value = Convert-ToUtcIso (Get-PropValue -Object $Payload -Name $key -Default "")
        if ($value) {
            return $value
        }
    }

    if ($Path -and (Test-Path -LiteralPath $Path)) {
        try {
            return Convert-ToUtcIso ((Get-Item -LiteralPath $Path).LastWriteTimeUtc)
        }
        catch {
            return ""
        }
    }

    return ""
}

function Get-ArtifactSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$SourceId,
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$StaleAfterHours = 24
    )

    $snapshot = [ordered]@{
        source_id = $SourceId
        type = "artifact"
        path = $Path
        available = $false
        readable = $false
        status = "missing"
        last_updated_utc = ""
        age_hours = [double]::PositiveInfinity
        stale = $true
        data = $null
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        return $snapshot
    }

    $snapshot.available = $true
    $data = Read-JsonSafe -Path $Path -Default $null
    if ($null -eq $data) {
        try {
            $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
            if ($raw -and $raw.Trim()) {
                $data = $raw | ConvertFrom-Json -ErrorAction Stop
            }
        }
        catch {
            $data = $null
        }
    }
    if ($null -eq $data) {
        $snapshot.status = "unreadable"
        return $snapshot
    }

    $timestamp = Get-SnapshotTimestamp -Payload $data -Path $Path
    $ageHours = Get-AgeHours -Timestamp $timestamp
    $stale = $false
    if ($ageHours -eq [double]::PositiveInfinity) {
        $stale = $false
    }
    elseif ($ageHours -gt [double]$StaleAfterHours) {
        $stale = $true
    }

    $snapshot.readable = $true
    $snapshot.status = if ($stale) { "stale" } else { "ready" }
    $snapshot.last_updated_utc = $timestamp
    $snapshot.age_hours = $ageHours
    $snapshot.stale = $stale
    $snapshot.data = $data
    return $snapshot
}

function Convert-RawStatus {
    param(
        [string]$RawValue,
        [string]$DefaultStatus = "WARN"
    )

    $text = (Normalize-Text $RawValue).ToUpperInvariant()
    switch ($text) {
        "PASS" { return "PASS" }
        "OK" { return "PASS" }
        "GREEN" { return "PASS" }
        "HEALTHY" { return "PASS" }
        "SUCCESS" { return "PASS" }
        "READY" { return "PASS" }
        "DONE" { return "PASS" }
        "WARN" { return "WARN" }
        "WARNING" { return "WARN" }
        "WATCH" { return "WARN" }
        "CAUTION" { return "WARN" }
        "GUARDED" { return "WARN" }
        "STUB" { return "WARN" }
        "REVIEW_ONLY" { return "WARN" }
        "PENDING_REBOOT" { return "WARN" }
        "BLOCKED" { return "WARN" }
        "MISSING" { return "missing" }
        "UNAVAILABLE" { return "missing" }
        "FAIL" { return "FAIL" }
        "FAILED" { return "FAIL" }
        "ERROR" { return "FAIL" }
        "RED" { return "FAIL" }
        "CRITICAL" { return "FAIL" }
        default { return $DefaultStatus }
    }
}

function Get-StatusRank {
    param([string]$Status)

    switch ((Normalize-Text $Status).ToUpperInvariant()) {
        "FAIL" { return 3 }
        "WARN" { return 2 }
        "PASS" { return 1 }
        default { return 0 }
    }
}

function New-DomainState {
    param(
        [Parameter(Mandatory = $true)][string]$DomainId,
        [Parameter(Mandatory = $true)][bool]$Available,
        [Parameter(Mandatory = $true)][string]$Status,
        [string]$SourceArtifactOrProbe = "",
        [string]$LastUpdatedUtc = "",
        [string]$Summary = "",
        [string]$RecommendedNextAction = "",
        $Counts = $null,
        $Details = $null,
        [bool]$Stale = $false,
        [string]$TruthConfidence = "medium"
    )

    if ($null -eq $Counts) {
        $Counts = [ordered]@{}
    }
    if ($null -eq $Details) {
        $Details = [ordered]@{}
    }

    return [ordered]@{
        available = [bool]$Available
        status = if ($Available) { $Status } else { "missing" }
        source_artifact_or_probe = $SourceArtifactOrProbe
        last_updated_utc = $LastUpdatedUtc
        summary = $Summary
        recommended_next_action = $RecommendedNextAction
        counts = $Counts
        details = $Details
        stale = [bool]$Stale
        truth_confidence = $TruthConfidence
    }
}

function Get-ArrayCount {
    param($Value)
    if ($null -eq $Value) {
        return 0
    }
    if ($Value -is [string]) {
        return $(if ((Normalize-Text $Value)) { 1 } else { 0 })
    }
    return @($Value).Count
}

function Get-RecommendationCounts {
    param([Parameter(Mandatory = $true)][string]$DirPath)

    $result = [ordered]@{
        files = 0
        total = 0
        current = 0
        by_status = [ordered]@{}
    }

    if (-not (Test-Path -LiteralPath $DirPath)) {
        return $result
    }

    $files = @(Get-ChildItem -LiteralPath $DirPath -File -Filter *.json -ErrorAction SilentlyContinue)
    $result.files = $files.Count
    foreach ($file in @($files)) {
        $payload = Read-JsonSafe -Path $file.FullName -Default $null
        if (-not $payload) {
            continue
        }

        $items = @((Get-PropValue -Object $payload -Name "recommendations" -Default @()))
        if ($items.Count -eq 0) {
            $items = @((Get-PropValue -Object $payload -Name "items" -Default @()))
        }

        foreach ($item in @($items)) {
            $result.total += 1
            if ([bool](Get-PropValue -Object $item -Name "is_current" -Default $true)) {
                $result.current += 1
            }
            $status = Normalize-Text (Get-PropValue -Object $item -Name "status" -Default "unknown")
            if (-not $status) {
                $status = "unknown"
            }
            if (-not $result.by_status.Contains($status)) {
                $result.by_status[$status] = 0
            }
            $result.by_status[$status] = [int]$result.by_status[$status] + 1
        }
    }

    return $result
}

function Get-LatestToolArtifactSummary {
    param([Parameter(Mandatory = $true)][string]$ToolsReportsDir)

    $result = [ordered]@{
        artifact_count = 0
        latest_artifact_path = ""
        latest_generated_at_utc = ""
    }

    if (-not (Test-Path -LiteralPath $ToolsReportsDir)) {
        return $result
    }

    $artifacts = @(Get-ChildItem -LiteralPath $ToolsReportsDir -Recurse -File -Filter artifact.json -ErrorAction SilentlyContinue)
    $result.artifact_count = $artifacts.Count
    if ($artifacts.Count -eq 0) {
        return $result
    }

    $latest = $artifacts | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    $result.latest_artifact_path = $latest.FullName
    try {
        $result.latest_generated_at_utc = Convert-ToUtcIso $latest.LastWriteTimeUtc
    }
    catch {
        $result.latest_generated_at_utc = ""
    }
    return $result
}

$repoRoot = Get-RepoRoot -OverrideRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"
$systemTruthPath = Join-Path $reportsDir "system_truth_spine_last.json"
$systemMetricsPath = Join-Path $reportsDir "system_metrics_spine_last.json"
$systemTruthSummaryPath = Join-Path $reportsDir "system_truth_summary_last.json"
$systemTruthRegistryPath = Join-Path $stateKnowledgeDir "system_truth_registry.json"
$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Build_System_Truth_Spine.ps1"
$nowUtc = Get-NowUtc
$nowIso = Convert-ToUtcIso $nowUtc

$artifactConfig = [ordered]@{
    ports = @{ path = (Join-Path $repoRoot "config\ports.json"); stale = 168; source_id = "config.ports" }
    start_run = @{ path = (Join-Path $reportsDir "start\start_run_last.json"); stale = 24; source_id = "report.start_run" }
    stack_pids = @{ path = (Join-Path $repoRoot "state\knowledge\stack_pids.json"); stale = 24; source_id = "state.stack_pids" }
    system_validation = @{ path = (Join-Path $reportsDir "system_validation_last.json"); stale = 24; source_id = "report.system_validation" }
    host_health = @{ path = (Join-Path $reportsDir "host_health_last.json"); stale = 24; source_id = "report.host_health" }
    runtime_posture = @{ path = (Join-Path $reportsDir "runtime_posture_last.json"); stale = 24; source_id = "report.runtime_posture" }
    environment_profile = @{ path = (Join-Path $reportsDir "environment_profile_last.json"); stale = 24; source_id = "report.environment_profile" }
    environment_drift = @{ path = (Join-Path $reportsDir "environment_drift_last.json"); stale = 24; source_id = "report.environment_drift" }
    mirror = @{ path = (Join-Path $reportsDir "mirror_update_last.json"); stale = 24; source_id = "report.mirror" }
    billing = @{ path = (Join-Path $reportsDir "billing_summary.json"); stale = 24; source_id = "report.billing" }
    behavior_trust = @{ path = (Join-Path $stateKnowledgeDir "behavior_trust.json"); stale = 168; source_id = "state.behavior_trust" }
    approvals = @{ path = (Join-Path $reportsDir "approvals_posture.json"); stale = 24; source_id = "report.approvals" }
    improvement_queue = @{ path = (Join-Path $stateKnowledgeDir "improvement_queue.json"); stale = 168; source_id = "state.improvement_queue" }
    tenant_workspace = @{ path = (Join-Path $repoRoot "state\onyx\tenant_workspace.json"); stale = 168; source_id = "state.tenant_workspace" }
    tool_registry = @{ path = (Join-Path $repoRoot "config\tool_registry.json"); stale = 168; source_id = "config.tool_registry" }
    self_improvement = @{ path = (Join-Path $reportsDir "self_improvement_governor_last.json"); stale = 48; source_id = "report.self_improvement_governor" }
    teacher_budget = @{ path = (Join-Path $reportsDir "teacher_call_budget_last.json"); stale = 48; source_id = "report.teacher_call_budget" }
    live_docs = @{ path = (Join-Path $reportsDir "live_docs_summary.json"); stale = 48; source_id = "report.live_docs_summary" }
    brand_exposure = @{ path = (Join-Path $reportsDir "brand_exposure_isolation_last.json"); stale = 48; source_id = "report.brand_exposure" }
    keepalive = @{ path = (Join-Path $reportsDir "keepalive_last.json"); stale = 24; source_id = "report.keepalive" }
    self_heal = @{ path = (Join-Path $reportsDir "self_heal_last.json"); stale = 24; source_id = "report.self_heal" }
    daily_report = @{ path = (Join-Path $reportsDir "daily_report_last.json"); stale = 24; source_id = "report.daily_report" }
    escalation_queue = @{ path = (Join-Path $reportsDir "escalation_queue_last.json"); stale = 24; source_id = "report.escalation_queue" }
}

$snapshots = @{}
foreach ($key in @($artifactConfig.Keys)) {
    $config = $artifactConfig[$key]
    $snapshots[$key] = Get-ArtifactSnapshot -SourceId ([string]$config.source_id) -Path ([string]$config.path) -StaleAfterHours ([int]$config.stale)
}

$portsPayload = Get-PropValue -Object $snapshots["ports"] -Name "data" -Default $null
$contractPorts = Get-ContractPorts -RepoRoot $repoRoot
$listenerMap = Get-ListenerMap -Ports @($contractPorts.Values)
$stackPidsPayload = Get-PropValue -Object $snapshots["stack_pids"] -Name "data" -Default $null
$currentLivePids = Get-CurrentLivePidMap -StackPidsPayload $stackPidsPayload

$serviceSpecs = @(
    [ordered]@{ component = "mason_api"; display_name = "Mason API"; port = [int]$contractPorts.mason_api; health_url = "http://127.0.0.1:$($contractPorts.mason_api)/health" },
    [ordered]@{ component = "seed_api"; display_name = "Seed API"; port = [int]$contractPorts.seed_api; health_url = "http://127.0.0.1:$($contractPorts.seed_api)/health" },
    [ordered]@{ component = "bridge"; display_name = "Bridge"; port = [int]$contractPorts.bridge; health_url = "http://127.0.0.1:$($contractPorts.bridge)/health" },
    [ordered]@{ component = "athena"; display_name = "Athena"; port = [int]$contractPorts.athena; health_url = "http://127.0.0.1:$($contractPorts.athena)/api/health" },
    [ordered]@{ component = "onyx"; display_name = "Onyx"; port = [int]$contractPorts.onyx; health_url = "http://127.0.0.1:$($contractPorts.onyx)/main.dart.js" }
)

$serviceRows = @()
$probeSourceDescriptors = @()
foreach ($spec in @($serviceSpecs)) {
    $port = [int]$spec.port
    $listeners = @()
    if ($listenerMap.ContainsKey($port)) {
        $listeners = @($listenerMap[$port])
    }
    $ownerPids = @($listeners | ForEach-Object { [int]$_.owning_pid } | Sort-Object -Unique)
    $probe = Invoke-LoopbackProbe -Url ([string]$spec.health_url)
    $currentLivePid = $null
    if ($currentLivePids.ContainsKey([string]$spec.component)) {
        $currentLivePid = [int]$currentLivePids[[string]$spec.component]
    }
    $pidAligned = $true
    if ($ownerPids.Count -gt 0 -and $null -ne $currentLivePid) {
        $pidAligned = ($ownerPids -contains [int]$currentLivePid)
    }

    $status = "PASS"
    if ($ownerPids.Count -eq 0 -or -not [bool]$probe.ok) {
        $status = "FAIL"
    }
    elseif (-not $pidAligned) {
        $status = "WARN"
    }

    $serviceRows += [ordered]@{
        component = [string]$spec.component
        display_name = [string]$spec.display_name
        port = $port
        listening = ($ownerPids.Count -gt 0)
        listener_count = $ownerPids.Count
        listener_addresses = @($listeners | ForEach-Object { [string]$_.local_address } | Sort-Object -Unique)
        listener_pids = @($ownerPids)
        current_live_pid = $currentLivePid
        current_live_pid_aligned = [bool]$pidAligned
        health_url = [string]$spec.health_url
        health_ok = [bool]$probe.ok
        health_status_code = [int]$probe.status_code
        health_error = Normalize-Text $probe.error
        checked_at_utc = [string]$probe.checked_at_utc
        status = $status
    }

    $probeSourceDescriptors += [ordered]@{
        source_id = ("probe.{0}" -f [string]$spec.component)
        type = "probe"
        path = [string]$spec.health_url
        available = $true
        readable = $true
        status = if ([bool]$probe.ok) { "ready" } else { "probe_failed" }
        last_updated_utc = [string]$probe.checked_at_utc
        age_hours = Get-AgeHours -Timestamp $probe.checked_at_utc
        stale = $false
    }
}

$validatorData = $snapshots["system_validation"].data
$startRunData = $snapshots["start_run"].data
$hostHealthData = $snapshots["host_health"].data
$runtimePostureData = $snapshots["runtime_posture"].data
$environmentProfileData = $snapshots["environment_profile"].data
$environmentDriftData = $snapshots["environment_drift"].data
$mirrorData = $snapshots["mirror"].data
$billingData = $snapshots["billing"].data
$behaviorTrustData = $snapshots["behavior_trust"].data
$approvalsData = $snapshots["approvals"].data
$queueData = $snapshots["improvement_queue"].data
$tenantWorkspaceData = $snapshots["tenant_workspace"].data
$toolRegistryData = $snapshots["tool_registry"].data
$selfImprovementData = $snapshots["self_improvement"].data
$teacherBudgetData = $snapshots["teacher_budget"].data
$liveDocsData = $snapshots["live_docs"].data
$brandExposureData = $snapshots["brand_exposure"].data
$keepaliveData = $snapshots["keepalive"].data
$selfHealData = $snapshots["self_heal"].data
$dailyReportData = $snapshots["daily_report"].data
$escalationQueueData = $snapshots["escalation_queue"].data

$queueItems = @((Get-PropValue -Object $queueData -Name "items" -Default @()))
$queueByStatus = [ordered]@{}
foreach ($item in @($queueItems)) {
    $status = Normalize-Text (Get-PropValue -Object $item -Name "status" -Default "unknown")
    if (-not $status) {
        $status = "unknown"
    }
    if (-not $queueByStatus.Contains($status)) {
        $queueByStatus[$status] = 0
    }
    $queueByStatus[$status] = [int]$queueByStatus[$status] + 1
}

$behaviorItems = @((Get-PropValue -Object $behaviorTrustData -Name "behaviors" -Default @()))
$behaviorByTrustState = [ordered]@{}
foreach ($behavior in @($behaviorItems)) {
    $state = Normalize-Text (Get-PropValue -Object $behavior -Name "trust_state" -Default "unknown")
    if (-not $state) {
        $state = "unknown"
    }
    if (-not $behaviorByTrustState.Contains($state)) {
        $behaviorByTrustState[$state] = 0
    }
    $behaviorByTrustState[$state] = [int]$behaviorByTrustState[$state] + 1
}

$workspaceContexts = @((Get-PropValue -Object $tenantWorkspaceData -Name "contexts" -Default @()))
$activeTenantId = Normalize-Text (Get-PropValue -Object $tenantWorkspaceData -Name "activeTenantId" -Default "")
$recommendationCounts = Get-RecommendationCounts -DirPath (Join-Path $repoRoot "state\onyx\recommendations")
$toolArtifactSummary = Get-LatestToolArtifactSummary -ToolsReportsDir (Join-Path $reportsDir "tools")
$toolItems = @((Get-PropValue -Object $toolRegistryData -Name "tools" -Default @()))
$enabledToolItems = @($toolItems | Where-Object { (Normalize-Text (Get-PropValue -Object $_ -Name "status" -Default "")).ToLowerInvariant() -eq "enabled" })
$tenantNode = Get-PropValue -Object $billingData -Name "tenant" -Default $null
$tenantEnabledTools = @((Get-PropValue -Object $tenantNode -Name "enabled_tools" -Default @()))
$pendingApprovals = [int](Get-PropValue -Object $approvalsData -Name "pending_total" -Default 0)
$blockedSelfImprove = [int](Get-PropValue -Object $selfImprovementData -Name "blocked_count" -Default 0)
$reviewOnlySelfImprove = [int](Get-PropValue -Object $selfImprovementData -Name "review_only_count" -Default 0)

$allServicesHealthy = @($serviceRows | Where-Object { $_.status -eq "FAIL" }).Count -eq 0
$serviceWarnCount = @($serviceRows | Where-Object { $_.status -eq "WARN" }).Count
$healthyServiceCount = @($serviceRows | Where-Object { $_.status -eq "PASS" }).Count

$domains = [ordered]@{}

$stackStartStatus = Convert-RawStatus -RawValue (Get-PropValue -Object $startRunData -Name "overall_status" -Default "")
$stackStatus = "PASS"
$stackSummary = "Start artifact and live loopback stack checks are healthy."
$stackNextAction = "No action required."
if (-not $snapshots["start_run"].readable) {
    $stackStatus = "WARN"
    $stackSummary = "Start artifact is missing or unreadable, but live probes still provide current service truth."
    $stackNextAction = "Restore reports/start/start_run_last.json on the next normal stack start."
}
if (-not $allServicesHealthy) {
    $stackStatus = "FAIL"
    $failedService = @($serviceRows | Where-Object { $_.status -eq "FAIL" } | Select-Object -First 1)
    $stackSummary = ("Live loopback checks show an unhealthy required service: {0}." -f ($failedService.display_name))
    $stackNextAction = ("Restore {0} on its contract port and rerun the validator." -f ($failedService.display_name))
}
elseif ($serviceWarnCount -gt 0 -or $stackStartStatus -eq "WARN" -or $stackStartStatus -eq "FAIL") {
    $stackStatus = "WARN"
    $warnedService = @($serviceRows | Where-Object { $_.status -eq "WARN" } | Select-Object -First 1)
    if ($warnedService) {
        $stackSummary = ("All required services are healthy, but runtime truth drift remains for {0}." -f $warnedService.display_name)
        $stackNextAction = ("Refresh the normal stack start flow so stack_pids.json matches live runtime truth for {0}." -f $warnedService.display_name)
    }
    elseif ($stackStartStatus -ne "PASS") {
        $stackSummary = ("Live loopback probes are healthy, but the start artifact still reports {0}." -f $stackStartStatus)
        $stackNextAction = "Rerun the normal stack start flow so the start artifact matches live runtime truth."
    }
}

$domains["stack"] = New-DomainState -DomainId "stack" -Available $true -Status $stackStatus -SourceArtifactOrProbe $artifactConfig.start_run.path -LastUpdatedUtc $nowIso -Summary $stackSummary -RecommendedNextAction $stackNextAction -Counts ([ordered]@{
    contract_port_count = @($contractPorts.Keys).Count
    healthy_service_count = $healthyServiceCount
    warning_service_count = $serviceWarnCount
    start_artifact_status = $stackStartStatus
}) -Details ([ordered]@{
    bind_host = Normalize-Text (Get-PropValue -Object $portsPayload -Name "bind_host" -Default "")
    contract_ports = $contractPorts
    current_live_pids = $currentLivePids
    service_snapshot = $serviceRows
}) -Stale $false -TruthConfidence "high"

$validatorStatus = if ($snapshots["system_validation"].readable) { Convert-RawStatus -RawValue (Get-PropValue -Object $validatorData -Name "overall_status" -Default "") } else { "missing" }
$validatorSummary = if ($snapshots["system_validation"].readable) {
    "{0} with {1} fail / {2} warn / {3} pass." -f $validatorStatus, [int](Get-PropValue -Object $validatorData -Name "failed_count" -Default 0), [int](Get-PropValue -Object $validatorData -Name "warn_count" -Default 0), [int](Get-PropValue -Object $validatorData -Name "passed_count" -Default 0)
}
else {
    "System validator artifact is missing or unreadable."
}
$validatorNextAction = if ($snapshots["system_validation"].readable) {
    Normalize-Text (Get-PropValue -Object $validatorData -Name "recommended_next_action" -Default "Run the validator.")
}
else {
    "Run tools/ops/Validate_Whole_System.ps1 so the validator artifact exists."
}
$domains["validator"] = New-DomainState -DomainId "validator" -Available ([bool]$snapshots["system_validation"].readable) -Status $validatorStatus -SourceArtifactOrProbe $artifactConfig.system_validation.path -LastUpdatedUtc $snapshots["system_validation"].last_updated_utc -Summary $validatorSummary -RecommendedNextAction $validatorNextAction -Counts ([ordered]@{
    passed_count = [int](Get-PropValue -Object $validatorData -Name "passed_count" -Default 0)
    failed_count = [int](Get-PropValue -Object $validatorData -Name "failed_count" -Default 0)
    warn_count = [int](Get-PropValue -Object $validatorData -Name "warn_count" -Default 0)
}) -Details ([ordered]@{
    failing_components = @((Get-PropValue -Object $validatorData -Name "failing_components" -Default @()))
    relevant_paths = @((Get-PropValue -Object $validatorData -Name "relevant_paths" -Default @()))
    mirror_ok = [bool](Get-PropValue -Object $validatorData -Name "mirror_ok" -Default $false)
}) -Stale ([bool]$snapshots["system_validation"].stale) -TruthConfidence "high"

$servicesStatus = "PASS"
$servicesSummary = "{0}/{1} required services are healthy on live loopback probes." -f $healthyServiceCount, $serviceRows.Count
$servicesNextAction = "No action required."
if (-not $allServicesHealthy) {
    $servicesStatus = "FAIL"
    $failedService = @($serviceRows | Where-Object { $_.status -eq "FAIL" } | Select-Object -First 1)
    $servicesSummary = ("Required service {0} failed live listener or health checks." -f $failedService.display_name)
    $servicesNextAction = ("Restore {0} on port {1} and rerun the validator." -f $failedService.display_name, $failedService.port)
}
elseif ($serviceWarnCount -gt 0) {
    $servicesStatus = "WARN"
    $warnedService = @($serviceRows | Where-Object { $_.status -eq "WARN" } | Select-Object -First 1)
    $servicesSummary = ("All required services are healthy, but {0} has live PID truth drift." -f $warnedService.display_name)
    $servicesNextAction = ("Refresh stack PID truth for {0} without broad restarts." -f $warnedService.display_name)
}

$domains["services"] = New-DomainState -DomainId "services" -Available $true -Status $servicesStatus -SourceArtifactOrProbe "live://contract_ports_and_health_probes" -LastUpdatedUtc $nowIso -Summary $servicesSummary -RecommendedNextAction $servicesNextAction -Counts ([ordered]@{
    service_count = $serviceRows.Count
    healthy_service_count = $healthyServiceCount
    warning_service_count = $serviceWarnCount
    failing_service_count = @($serviceRows | Where-Object { $_.status -eq "FAIL" }).Count
}) -Details ([ordered]@{
    services = $serviceRows
}) -Stale $false -TruthConfidence "high"

$hostStatus = if ($snapshots["host_health"].readable) { Convert-RawStatus -RawValue (Get-PropValue -Object $hostHealthData -Name "overall_status" -Default "") } else { "missing" }
$hostSummary = if ($snapshots["host_health"].readable) {
    "Host status {0}; throttle={1}; next={2}" -f $hostStatus, (Normalize-Text (Get-PropValue -Object $hostHealthData -Name "throttle_guidance" -Default "")), (Normalize-Text (Get-PropValue -Object $hostHealthData -Name "recommended_next_action" -Default ""))
}
else {
    "Host guardian artifact is missing or unreadable."
}
$domains["host"] = New-DomainState -DomainId "host" -Available ([bool]$snapshots["host_health"].readable) -Status $hostStatus -SourceArtifactOrProbe $artifactConfig.host_health.path -LastUpdatedUtc $snapshots["host_health"].last_updated_utc -Summary $hostSummary -RecommendedNextAction ($(if ($snapshots["host_health"].readable) { Normalize-Text (Get-PropValue -Object $hostHealthData -Name "recommended_next_action" -Default "") } else { "Run tools/ops/Run_Host_Guardian.ps1." })) -Counts ([ordered]@{
    pending_reboot = [bool](Get-PropValue -Object $hostHealthData -Name "pending_reboot" -Default $false)
    process_count = [int](Get-PropValue -Object $hostHealthData -Name "process_count" -Default 0)
}) -Details ([ordered]@{
    cpu = Get-PropValue -Object $hostHealthData -Name "cpu" -Default $null
    memory = Get-PropValue -Object $hostHealthData -Name "memory" -Default $null
    disk = Get-PropValue -Object $hostHealthData -Name "disk" -Default $null
    mason_runtime_health = Get-PropValue -Object $hostHealthData -Name "mason_runtime_health" -Default $null
    throttle_guidance = Normalize-Text (Get-PropValue -Object $hostHealthData -Name "throttle_guidance" -Default "")
}) -Stale ([bool]$snapshots["host_health"].stale) -TruthConfidence "high"

$environmentAvailable = ([bool]$snapshots["environment_profile"].readable) -or ([bool]$snapshots["environment_drift"].readable) -or ([bool]$snapshots["runtime_posture"].readable)
$environmentStatus = "missing"
$environmentSummary = "Environment adaptation artifacts are missing or unreadable."
$environmentNextAction = "Run tools/ops/Run_Environment_Adaptation.ps1 so current environment posture is rebuilt."
if ($environmentAvailable) {
    $driftLevel = Normalize-Text (Get-PropValue -Object $environmentDriftData -Name "drift_level" -Default "")
    $hostClassification = Normalize-Text (Get-PropValue -Object $environmentProfileData -Name "host_classification" -Default "")
    $environmentId = Normalize-Text (Get-PropValue -Object $environmentDriftData -Name "current_environment_id" -Default (Get-PropValue -Object $environmentProfileData -Name "environment_id" -Default ""))
    $runtimeThrottle = Normalize-Text (Get-PropValue -Object $runtimePostureData -Name "throttle_guidance" -Default "")
    $environmentStatus = "PASS"
    if ($driftLevel -in @("minor_change", "significant_change", "new_environment")) {
        $environmentStatus = "WARN"
    }
    elseif ($runtimeThrottle -and $runtimeThrottle.ToLowerInvariant() -notin @("normal", "none", "clear")) {
        $environmentStatus = "WARN"
    }
    $environmentSummary = ("Environment {0} on {1}; drift={2}; throttle={3}." -f `
        $(if ($environmentId) { $environmentId } else { "unknown" }), `
        $(if ($hostClassification) { $hostClassification } else { "unknown" }), `
        $(if ($driftLevel) { $driftLevel } else { "unknown" }), `
        $(if ($runtimeThrottle) { $runtimeThrottle } else { "n/a" }))
    $environmentNextAction = Normalize-Text (Get-PropValue -Object $environmentDriftData -Name "recommended_next_action" -Default (Get-PropValue -Object $runtimePostureData -Name "recommended_next_action" -Default "No action required."))
}
$domains["environment"] = New-DomainState -DomainId "environment" -Available $environmentAvailable -Status $environmentStatus -SourceArtifactOrProbe $artifactConfig.environment_profile.path -LastUpdatedUtc ($(if ($snapshots["runtime_posture"].last_updated_utc) { $snapshots["runtime_posture"].last_updated_utc } elseif ($snapshots["environment_drift"].last_updated_utc) { $snapshots["environment_drift"].last_updated_utc } else { $snapshots["environment_profile"].last_updated_utc })) -Summary $environmentSummary -RecommendedNextAction $environmentNextAction -Counts ([ordered]@{
    changed_dimension_count = Get-ArrayCount (Get-PropValue -Object $environmentDriftData -Name "changed_dimensions" -Default @())
    migration_detected = [bool](Get-PropValue -Object $environmentDriftData -Name "migration_detected" -Default $false)
}) -Details ([ordered]@{
    environment_id = Normalize-Text (Get-PropValue -Object $environmentDriftData -Name "current_environment_id" -Default (Get-PropValue -Object $environmentProfileData -Name "environment_id" -Default ""))
    host_classification = Normalize-Text (Get-PropValue -Object $environmentProfileData -Name "host_classification" -Default "")
    drift = $environmentDriftData
    runtime_posture = $runtimePostureData
    profile = $environmentProfileData
}) -Stale ([bool]($snapshots["runtime_posture"].stale -or $snapshots["environment_profile"].stale -or $snapshots["environment_drift"].stale)) -TruthConfidence "high"

$mirrorAvailable = [bool]$snapshots["mirror"].readable
$mirrorOk = [bool](Get-PropValue -Object $mirrorData -Name "ok" -Default $false)
$mirrorPhase = Normalize-Text (Get-PropValue -Object $mirrorData -Name "phase" -Default "")
$mirrorStatus = "missing"
$mirrorSummary = "Mirror artifact is missing or unreadable."
$mirrorNextAction = "Run tools/sync/Mason_Mirror_Update.ps1 so mirror checkpoint truth is refreshed."
if ($mirrorAvailable) {
    $mirrorStatus = "PASS"
    if (-not $mirrorOk -or $mirrorPhase.ToLowerInvariant() -ne "done") {
        $mirrorStatus = "WARN"
    }
    $mirrorSummary = ("Mirror ok={0}; phase={1}; push={2}." -f $mirrorOk.ToString().ToLowerInvariant(), $(if ($mirrorPhase) { $mirrorPhase } else { "unknown" }), (Normalize-Text (Get-PropValue -Object $mirrorData -Name "mirror_push_result" -Default "")))
    $mirrorNextAction = Normalize-Text (Get-PropValue -Object $mirrorData -Name "next_action" -Default "Review mirror result and rerun only if checkpoint freshness is required.")
}
$domains["mirror"] = New-DomainState -DomainId "mirror" -Available $mirrorAvailable -Status $mirrorStatus -SourceArtifactOrProbe $artifactConfig.mirror.path -LastUpdatedUtc $snapshots["mirror"].last_updated_utc -Summary $mirrorSummary -RecommendedNextAction $mirrorNextAction -Counts ([ordered]@{
    ok = $mirrorOk
}) -Details ([ordered]@{
    phase = $mirrorPhase
    mirror_push_result = Normalize-Text (Get-PropValue -Object $mirrorData -Name "mirror_push_result" -Default "")
    reason = Normalize-Text (Get-PropValue -Object $mirrorData -Name "reason" -Default (Get-PropValue -Object $mirrorData -Name "reason_requested" -Default ""))
    error = Normalize-Text (Get-PropValue -Object $mirrorData -Name "error" -Default "")
}) -Stale ([bool]$snapshots["mirror"].stale) -TruthConfidence "high"

$billingAvailable = [bool]$snapshots["billing"].readable
$billingStatus = "missing"
$billingSummary = "Billing summary artifact is missing or unreadable."
$billingNextAction = "Regenerate billing summary and entitlement posture."
if ($billingAvailable) {
    $providerNode = Get-PropValue -Object $billingData -Name "provider" -Default $null
    $providerMode = Normalize-Text (Get-PropValue -Object $providerNode -Name "mode" -Default "")
    $tenantPlanId = Normalize-Text (Get-PropValue -Object $tenantNode -Name "plan_id" -Default "")
    $tenantStatus = Normalize-Text (Get-PropValue -Object $tenantNode -Name "status" -Default "")
    $billingStatus = "PASS"
    if ($providerMode.ToLowerInvariant() -eq "stub" -or -not [bool](Get-PropValue -Object $billingData -Name "provider_configured" -Default $false)) {
        $billingStatus = "WARN"
    }
    if ($tenantStatus.ToLowerInvariant() -eq "active" -and $tenantEnabledTools.Count -eq 0) {
        $billingStatus = "WARN"
    }
    $billingSummary = ("Billing plan={0}; tenant_status={1}; provider_mode={2}; enabled_tools={3}." -f $(if ($tenantPlanId) { $tenantPlanId } else { "none" }), $(if ($tenantStatus) { $tenantStatus } else { "unknown" }), $(if ($providerMode) { $providerMode } else { "unknown" }), $tenantEnabledTools.Count)
    $billingNextAction = if ($billingStatus -eq "WARN" -and $providerMode.ToLowerInvariant() -eq "stub") { "Configure external billing secrets and webhook settings before enabling live money actions." } elseif ($billingStatus -eq "WARN" -and $tenantEnabledTools.Count -eq 0) { "Repair entitlement resolution so active tenants inherit enabled tools from their plan." } else { "No action required." }
}
$domains["billing"] = New-DomainState -DomainId "billing" -Available $billingAvailable -Status $billingStatus -SourceArtifactOrProbe $artifactConfig.billing.path -LastUpdatedUtc $snapshots["billing"].last_updated_utc -Summary $billingSummary -RecommendedNextAction $billingNextAction -Counts ([ordered]@{
    plan_count = Get-ArrayCount (Get-PropValue -Object $billingData -Name "plans" -Default @())
    subscription_total = [int](Get-PropValue -Object (Get-PropValue -Object $billingData -Name "subscription_counts" -Default $null) -Name "total" -Default 0)
    enabled_tool_count = $tenantEnabledTools.Count
}) -Details ([ordered]@{
    tenant = $tenantNode
    provider = Get-PropValue -Object $billingData -Name "provider" -Default $null
    revenue = Get-PropValue -Object $billingData -Name "revenue" -Default $null
    money_actions_require_approval = [bool](Get-PropValue -Object $billingData -Name "money_actions_require_approval" -Default $true)
}) -Stale ([bool]$snapshots["billing"].stale) -TruthConfidence "high"

$trustAvailable = [bool]$snapshots["behavior_trust"].readable
$trustStatus = "missing"
$trustSummary = "Behavior trust artifact is missing or unreadable."
$trustNextAction = "Restore state/knowledge/behavior_trust.json so autonomy posture remains governed."
if ($trustAvailable) {
    $autoAllowedCount = 0
    if ($behaviorByTrustState.Contains("auto_allowed")) {
        $autoAllowedCount = [int]$behaviorByTrustState["auto_allowed"]
    }
    $blockedBehaviorCount = 0
    if ($behaviorByTrustState.Contains("blocked")) {
        $blockedBehaviorCount = [int]$behaviorByTrustState["blocked"]
    }
    $trustStatus = if ($behaviorItems.Count -gt 0) { "PASS" } else { "WARN" }
    $trustSummary = ("Behavior trust tracks {0} behaviors; auto_allowed={1}; blocked={2}." -f $behaviorItems.Count, $autoAllowedCount, $blockedBehaviorCount)
    $trustNextAction = if ($behaviorItems.Count -gt 0) { "No action required." } else { "Seed at least one governed behavior into the trust store." }
}
$domains["trust"] = New-DomainState -DomainId "trust" -Available $trustAvailable -Status $trustStatus -SourceArtifactOrProbe $artifactConfig.behavior_trust.path -LastUpdatedUtc $snapshots["behavior_trust"].last_updated_utc -Summary $trustSummary -RecommendedNextAction $trustNextAction -Counts ([ordered]@{
    behavior_total = $behaviorItems.Count
    auto_allowed_total = $(if ($behaviorByTrustState.Contains("auto_allowed")) { [int]$behaviorByTrustState["auto_allowed"] } else { 0 })
    blocked_total = $(if ($behaviorByTrustState.Contains("blocked")) { [int]$behaviorByTrustState["blocked"] } else { 0 })
}) -Details ([ordered]@{
    by_trust_state = $behaviorByTrustState
}) -Stale ([bool]$snapshots["behavior_trust"].stale) -TruthConfidence "medium"

$queueAvailable = [bool]$snapshots["improvement_queue"].readable
$queueStatus = "missing"
$queueSummary = "Improvement queue artifact is missing or unreadable."
$queueNextAction = "Restore state/knowledge/improvement_queue.json so queue posture remains readable."
if ($queueAvailable) {
    $queueStatus = if ($queueItems.Count -gt 0) { "PASS" } else { "WARN" }
    $queueSummary = ("Improvement queue has {0} item(s); pending approvals={1}." -f $queueItems.Count, $pendingApprovals)
    $queueNextAction = if ($pendingApprovals -gt 0) { "Review pending approvals in Athena Founder Mode." } elseif ($queueItems.Count -eq 0) { "Seed the improvement queue from current governed sources." } else { "No action required." }
}
$domains["queues"] = New-DomainState -DomainId "queues" -Available $queueAvailable -Status $queueStatus -SourceArtifactOrProbe $artifactConfig.improvement_queue.path -LastUpdatedUtc $snapshots["improvement_queue"].last_updated_utc -Summary $queueSummary -RecommendedNextAction $queueNextAction -Counts ([ordered]@{
    improvement_total = $queueItems.Count
    pending_approvals = $pendingApprovals
    recommendation_total = [int]$recommendationCounts.total
}) -Details ([ordered]@{
    by_status = $queueByStatus
    recommendation_counts = $recommendationCounts
}) -Stale ([bool]$snapshots["improvement_queue"].stale) -TruthConfidence "medium"

$tenantsAvailable = [bool]$snapshots["tenant_workspace"].readable
$tenantStatus = "missing"
$tenantSummary = "Tenant workspace artifact is missing or unreadable."
$tenantNextAction = "Restore state/onyx/tenant_workspace.json so tenant context remains available."
if ($tenantsAvailable) {
    $tenantStatus = if ($workspaceContexts.Count -gt 0 -and $activeTenantId) { "PASS" } else { "WARN" }
    $tenantSummary = ("Tenant workspace tracks {0} tenant context(s); active_tenant_id={1}." -f $workspaceContexts.Count, $(if ($activeTenantId) { $activeTenantId } else { "none" }))
    $tenantNextAction = if (-not $activeTenantId -and $workspaceContexts.Count -gt 0) { "Set or restore the active tenant id in tenant_workspace.json." } elseif ($workspaceContexts.Count -eq 0) { "Create or restore at least one tenant workspace context." } else { "No action required." }
}
$domains["tenants"] = New-DomainState -DomainId "tenants" -Available $tenantsAvailable -Status $tenantStatus -SourceArtifactOrProbe $artifactConfig.tenant_workspace.path -LastUpdatedUtc $snapshots["tenant_workspace"].last_updated_utc -Summary $tenantSummary -RecommendedNextAction $tenantNextAction -Counts ([ordered]@{
    tenant_count = $workspaceContexts.Count
    active_tenant_present = [bool]$activeTenantId
}) -Details ([ordered]@{
    active_tenant_id = $activeTenantId
    active_tenant_enabled_tools = $tenantEnabledTools
    workspace_last_updated_utc = Normalize-Text (Get-PropValue -Object $tenantWorkspaceData -Name "lastUpdatedAtUtc" -Default "")
}) -Stale ([bool]$snapshots["tenant_workspace"].stale) -TruthConfidence "medium"

$toolsAvailable = [bool]$snapshots["tool_registry"].readable
$toolsStatus = "missing"
$toolsSummary = "Tool registry artifact is missing or unreadable."
$toolsNextAction = "Restore config/tool_registry.json so the tool platform remains governed."
if ($toolsAvailable) {
    $toolsStatus = if ($toolItems.Count -gt 0 -and $enabledToolItems.Count -gt 0) { "PASS" } elseif ($toolItems.Count -gt 0) { "WARN" } else { "WARN" }
    $toolsSummary = ("Tool registry has {0} tools; enabled={1}; latest_artifact_count={2}." -f $toolItems.Count, $enabledToolItems.Count, [int]$toolArtifactSummary.artifact_count)
    $toolsNextAction = if ($enabledToolItems.Count -eq 0) { "Enable at least one governed tool contract in the registry." } else { "No action required." }
}
$domains["tools"] = New-DomainState -DomainId "tools" -Available $toolsAvailable -Status $toolsStatus -SourceArtifactOrProbe $artifactConfig.tool_registry.path -LastUpdatedUtc $snapshots["tool_registry"].last_updated_utc -Summary $toolsSummary -RecommendedNextAction $toolsNextAction -Counts ([ordered]@{
    tool_total = $toolItems.Count
    enabled_tool_total = $enabledToolItems.Count
    tool_artifact_total = [int]$toolArtifactSummary.artifact_count
}) -Details ([ordered]@{
    latest_artifact_path = Normalize-Text $toolArtifactSummary.latest_artifact_path
    latest_generated_at_utc = Normalize-Text $toolArtifactSummary.latest_generated_at_utc
    tenant_enabled_tools = $tenantEnabledTools
}) -Stale ([bool]$snapshots["tool_registry"].stale) -TruthConfidence "medium"

$selfImprovementAvailable = [bool]$snapshots["self_improvement"].readable
$selfImprovementStatus = "missing"
$selfImprovementSummary = "Self-improvement governor artifact is missing or unreadable."
$selfImprovementNextAction = "Run tools/ops/Run_Self_Improvement_Governor.ps1."
if ($selfImprovementAvailable) {
    $selfImprovementStatus = Convert-RawStatus -RawValue (Get-PropValue -Object $selfImprovementData -Name "overall_status" -Default "")
    $selfImprovementSummary = ("Self-improvement posture {0}; active={1}; teacher_allowed={2}; blocked_by_local_first={3}." -f $selfImprovementStatus, [int](Get-PropValue -Object $selfImprovementData -Name "active_improvement_total" -Default 0), [int](Get-PropValue -Object $selfImprovementData -Name "total_teacher_allowed" -Default 0), [int](Get-PropValue -Object $selfImprovementData -Name "total_blocked_by_local_first" -Default 0))
    $selfImprovementNextAction = Normalize-Text (Get-PropValue -Object $selfImprovementData -Name "recommended_next_action" -Default "Review the governor posture and blocked items.")
}
$domains["self_improvement"] = New-DomainState -DomainId "self_improvement" -Available $selfImprovementAvailable -Status $selfImprovementStatus -SourceArtifactOrProbe $artifactConfig.self_improvement.path -LastUpdatedUtc $snapshots["self_improvement"].last_updated_utc -Summary $selfImprovementSummary -RecommendedNextAction $selfImprovementNextAction -Counts ([ordered]@{
    active_improvement_total = [int](Get-PropValue -Object $selfImprovementData -Name "active_improvement_total" -Default 0)
    teacher_allowed_total = [int](Get-PropValue -Object $selfImprovementData -Name "total_teacher_allowed" -Default 0)
    blocked_total = $blockedSelfImprove
    review_only_total = $reviewOnlySelfImprove
}) -Details ([ordered]@{
    execution_disposition_counts = Get-PropValue -Object $selfImprovementData -Name "counts_by_execution_disposition" -Default $null
    teacher_quality_counts = Get-PropValue -Object $selfImprovementData -Name "counts_by_teacher_quality_classification" -Default $null
    budget_posture = Normalize-Text (Get-PropValue -Object $selfImprovementData -Name "current_budget_posture" -Default "")
    teacher_budget = $teacherBudgetData
}) -Stale ([bool]($snapshots["self_improvement"].stale -or $snapshots["teacher_budget"].stale)) -TruthConfidence "high"

$liveDocsAvailable = [bool]$snapshots["live_docs"].readable
$liveDocsStatus = "missing"
$liveDocsSummary = "Live docs summary artifact is missing or unreadable."
$liveDocsNextAction = "Run tools/ops/Generate_Live_Component_Docs.ps1."
if ($liveDocsAvailable) {
    $liveDocsStatus = Convert-RawStatus -RawValue (Get-PropValue -Object $liveDocsData -Name "summary_status" -Default "")
    $liveDocsSummary = ("Live docs {0}; docs_count={1}; stale_docs={2}." -f $liveDocsStatus, [int](Get-PropValue -Object $liveDocsData -Name "docs_count" -Default 0), [int](Get-PropValue -Object $liveDocsData -Name "stale_docs_count" -Default 0))
    $liveDocsNextAction = if ([int](Get-PropValue -Object $liveDocsData -Name "stale_docs_count" -Default 0) -gt 0) { "Regenerate live docs from the latest authoritative artifacts." } else { "No action required." }
}
$domains["live_docs"] = New-DomainState -DomainId "live_docs" -Available $liveDocsAvailable -Status $liveDocsStatus -SourceArtifactOrProbe $artifactConfig.live_docs.path -LastUpdatedUtc $snapshots["live_docs"].last_updated_utc -Summary $liveDocsSummary -RecommendedNextAction $liveDocsNextAction -Counts ([ordered]@{
    docs_count = [int](Get-PropValue -Object $liveDocsData -Name "docs_count" -Default 0)
    stale_docs_count = [int](Get-PropValue -Object $liveDocsData -Name "stale_docs_count" -Default 0)
    blocked_component_count = Get-ArrayCount (Get-PropValue -Object $liveDocsData -Name "components_blocked" -Default @())
}) -Details ([ordered]@{
    components_with_warnings = Get-PropValue -Object $liveDocsData -Name "components_with_warnings" -Default @()
    components_healthy = Get-PropValue -Object $liveDocsData -Name "components_healthy" -Default @()
    components_blocked = Get-PropValue -Object $liveDocsData -Name "components_blocked" -Default @()
}) -Stale ([bool]$snapshots["live_docs"].stale) -TruthConfidence "medium"

$brandExposureAvailable = [bool]$snapshots["brand_exposure"].readable
$brandExposureStatus = "missing"
$brandExposureSummary = "Brand exposure artifact is missing or unreadable."
$brandExposureNextAction = "Run tools/ops/Run_Brand_Exposure_Isolation.ps1."
if ($brandExposureAvailable) {
    $brandExposureStatus = Convert-RawStatus -RawValue (Get-PropValue -Object $brandExposureData -Name "overall_status" -Default "")
    $brandExposureSummary = ("Brand exposure {0}; public_leaks={1}; surfaces_scanned={2}." -f $brandExposureStatus, [int](Get-PropValue -Object $brandExposureData -Name "public_leak_count" -Default 0), [int](Get-PropValue -Object $brandExposureData -Name "total_surfaces_scanned" -Default 0))
    $brandExposureNextAction = Normalize-Text (Get-PropValue -Object $brandExposureData -Name "recommended_next_action" -Default "No action required.")
}
$domains["brand_exposure"] = New-DomainState -DomainId "brand_exposure" -Available $brandExposureAvailable -Status $brandExposureStatus -SourceArtifactOrProbe $artifactConfig.brand_exposure.path -LastUpdatedUtc $snapshots["brand_exposure"].last_updated_utc -Summary $brandExposureSummary -RecommendedNextAction $brandExposureNextAction -Counts ([ordered]@{
    public_leak_count = [int](Get-PropValue -Object $brandExposureData -Name "public_leak_count" -Default 0)
    surfaces_scanned = [int](Get-PropValue -Object $brandExposureData -Name "total_surfaces_scanned" -Default 0)
}) -Details ([ordered]@{
    public_brand_posture = Normalize-Text (Get-PropValue -Object $brandExposureData -Name "public_brand_posture" -Default "")
    internal_brand_posture = Normalize-Text (Get-PropValue -Object $brandExposureData -Name "internal_brand_posture" -Default "")
    owner_only_wording_preserved = [bool](Get-PropValue -Object $brandExposureData -Name "owner_only_wording_preserved" -Default $false)
    customer_only_wording_isolated = [bool](Get-PropValue -Object $brandExposureData -Name "customer_only_wording_isolated" -Default $false)
}) -Stale ([bool]$snapshots["brand_exposure"].stale) -TruthConfidence "medium"

$keepaliveAvailable = [bool]$snapshots["keepalive"].readable
$keepaliveStatus = "missing"
$keepaliveSummary = "KeepAlive artifact is missing or unreadable."
$keepaliveNextAction = "Run tools/ops/Run_KeepAlive_SelfHeal.ps1."
if ($keepaliveAvailable) {
    $keepaliveStatus = Convert-RawStatus -RawValue (Get-PropValue -Object $keepaliveData -Name "overall_status" -Default "")
    $keepaliveSummary = ("KeepAlive {0}; recoverable={1}; escalated={2}; repairs={3}/{4} success." -f $keepaliveStatus, [int](Get-PropValue -Object $keepaliveData -Name "recoverable_issue_count" -Default 0), [int](Get-PropValue -Object $keepaliveData -Name "escalated_issue_count" -Default 0), [int](Get-PropValue -Object $keepaliveData -Name "repair_success_count" -Default 0), [int](Get-PropValue -Object $keepaliveData -Name "repair_attempt_count" -Default 0))
    $keepaliveNextAction = Normalize-Text (Get-PropValue -Object $keepaliveData -Name "recommended_next_action" -Default "Review the latest keepalive report.")
}
$domains["keepalive_ops"] = New-DomainState -DomainId "keepalive_ops" -Available $keepaliveAvailable -Status $keepaliveStatus -SourceArtifactOrProbe $artifactConfig.keepalive.path -LastUpdatedUtc $snapshots["keepalive"].last_updated_utc -Summary $keepaliveSummary -RecommendedNextAction $keepaliveNextAction -Counts ([ordered]@{
    recoverable_issue_count = [int](Get-PropValue -Object $keepaliveData -Name "recoverable_issue_count" -Default 0)
    escalated_issue_count = [int](Get-PropValue -Object $keepaliveData -Name "escalated_issue_count" -Default 0)
    repair_attempt_count = [int](Get-PropValue -Object $keepaliveData -Name "repair_attempt_count" -Default 0)
    repair_success_count = [int](Get-PropValue -Object $keepaliveData -Name "repair_success_count" -Default 0)
    repair_blocked_count = [int](Get-PropValue -Object $keepaliveData -Name "repair_blocked_count" -Default 0)
}) -Details ([ordered]@{
    daily_report_status = Normalize-Text (Get-PropValue -Object $keepaliveData -Name "daily_report_status" -Default "")
    throttle_guidance = Normalize-Text (Get-PropValue -Object $keepaliveData -Name "throttle_guidance" -Default "")
    escalation_count = Get-ArrayCount (Get-PropValue -Object $escalationQueueData -Name "escalations" -Default @())
    self_heal_issue_count = Get-ArrayCount (Get-PropValue -Object $selfHealData -Name "issues" -Default @())
}) -Stale ([bool]($snapshots["keepalive"].stale -or $snapshots["self_heal"].stale -or $snapshots["daily_report"].stale -or $snapshots["escalation_queue"].stale)) -TruthConfidence "high"

$domainStatusMap = [ordered]@{}
$availableDomainCount = 0
$warningDomainCount = 0
$failingDomainCount = 0
$healthyDomainCount = 0
$missingDomainCount = 0
$topWarningDomains = @()
$topHealthyDomains = @()
$currentBlockerDomains = @()
$recommendedNextAction = "No action required."
$overallStatus = "PASS"

foreach ($domainId in @($domains.Keys)) {
    $domain = $domains[$domainId]
    $status = Normalize-Text (Get-PropValue -Object $domain -Name "status" -Default "missing")
    $domainStatusMap[$domainId] = $status
    if ([bool](Get-PropValue -Object $domain -Name "available" -Default $false)) {
        $availableDomainCount += 1
    }

    switch ($status.ToUpperInvariant()) {
        "FAIL" {
            $failingDomainCount += 1
            $overallStatus = "FAIL"
            $currentBlockerDomains += $domainId
            if (-not $recommendedNextAction -or $recommendedNextAction -eq "No action required.") {
                $recommendedNextAction = Normalize-Text (Get-PropValue -Object $domain -Name "recommended_next_action" -Default "")
            }
        }
        "WARN" {
            $warningDomainCount += 1
            if ($overallStatus -ne "FAIL") {
                $overallStatus = "WARN"
            }
            $topWarningDomains += $domainId
            if ($recommendedNextAction -eq "No action required.") {
                $recommendedNextAction = Normalize-Text (Get-PropValue -Object $domain -Name "recommended_next_action" -Default "")
            }
        }
        "PASS" {
            $healthyDomainCount += 1
            $topHealthyDomains += $domainId
        }
        default {
            $missingDomainCount += 1
            if ($overallStatus -ne "FAIL") {
                $overallStatus = "WARN"
            }
            $topWarningDomains += $domainId
            if ($recommendedNextAction -eq "No action required.") {
                $recommendedNextAction = Normalize-Text (Get-PropValue -Object $domain -Name "recommended_next_action" -Default "")
            }
        }
    }
}

if ($validatorStatus -eq "FAIL" -and $overallStatus -ne "FAIL") {
    $overallStatus = "FAIL"
}
elseif ($validatorStatus -eq "WARN" -and $overallStatus -eq "PASS") {
    $overallStatus = "WARN"
}
if (-not $recommendedNextAction) {
    $recommendedNextAction = Normalize-Text (Get-PropValue -Object $validatorData -Name "recommended_next_action" -Default "No action required.")
}

$truthSources = [ordered]@{
    artifacts = @(
        foreach ($key in @($artifactConfig.Keys)) {
            $snapshot = $snapshots[$key]
            [ordered]@{
                source_id = [string]$snapshot.source_id
                type = [string]$snapshot.type
                path = [string]$snapshot.path
                available = [bool]$snapshot.available
                readable = [bool]$snapshot.readable
                status = [string]$snapshot.status
                last_updated_utc = [string]$snapshot.last_updated_utc
                age_hours = $snapshot.age_hours
                stale = [bool]$snapshot.stale
            }
        }
    )
    probes = @($probeSourceDescriptors)
}

$staleArtifactSources = @($truthSources.artifacts | Where-Object { $_.stale -eq $true })
$missingArtifactSources = @($truthSources.artifacts | Where-Object { $_.available -eq $false })
$unreadableArtifactSources = @($truthSources.artifacts | Where-Object { $_.available -eq $true -and $_.readable -eq $false })

$mergeWarnings = @()
if ($validatorStatus -eq "WARN" -or $validatorStatus -eq "FAIL") {
    $mergeWarnings += [ordered]@{
        source = "validator"
        warning = $validatorSummary
        recommended_next_action = $validatorNextAction
    }
}
if ($serviceWarnCount -gt 0) {
    $mergeWarnings += [ordered]@{
        source = "services"
        warning = "Live PID truth drift remains for at least one required service."
        recommended_next_action = $servicesNextAction
    }
}
foreach ($artifact in @($staleArtifactSources)) {
    $mergeWarnings += [ordered]@{
        source = [string]$artifact.source_id
        warning = ("Artifact is stale: {0}" -f [string]$artifact.path)
        recommended_next_action = "Refresh the producing command so the artifact becomes current."
    }
}
foreach ($artifact in @($missingArtifactSources)) {
    $mergeWarnings += [ordered]@{
        source = [string]$artifact.source_id
        warning = ("Artifact is missing: {0}" -f [string]$artifact.path)
        recommended_next_action = "Run or restore the producing path so the artifact exists."
    }
}
foreach ($artifact in @($unreadableArtifactSources)) {
    $mergeWarnings += [ordered]@{
        source = [string]$artifact.source_id
        warning = ("Artifact is unreadable: {0}" -f [string]$artifact.path)
        recommended_next_action = "Repair the unreadable artifact and rerun the producing command."
    }
}

$summaryCards = @(
    foreach ($domainId in @($domains.Keys)) {
        $domain = $domains[$domainId]
        [ordered]@{
            domain = $domainId
            status = Normalize-Text (Get-PropValue -Object $domain -Name "status" -Default "missing")
            summary = Normalize-Text (Get-PropValue -Object $domain -Name "summary" -Default "")
            recommended_next_action = Normalize-Text (Get-PropValue -Object $domain -Name "recommended_next_action" -Default "")
        }
    }
)

$baselineTagValue = Normalize-Text (Get-PropValue -Object $validatorData -Name "baseline_tag" -Default "")
if (-not $baselineTagValue) {
    $baselineTagValue = Normalize-Text (Get-PropValue -Object $liveDocsData -Name "baseline_tag" -Default "")
}
if (-not $baselineTagValue) {
    $baselineTagValue = Normalize-Text (Get-PropValue -Object $startRunData -Name "baseline_tag" -Default (Get-PropValue -Object $startRunData -Name "mode" -Default ""))
}
if (-not $baselineTagValue) {
    $baselineTagValue = "current_local_baseline"
}

$summaryPayload = [ordered]@{
    timestamp_utc = $nowIso
    overall_status = $overallStatus
    top_warnings = @(
        foreach ($domainId in @($topWarningDomains | Select-Object -First 6)) {
            $domain = $domains[$domainId]
            [ordered]@{
                domain = $domainId
                status = Normalize-Text (Get-PropValue -Object $domain -Name "status" -Default "missing")
                summary = Normalize-Text (Get-PropValue -Object $domain -Name "summary" -Default "")
                recommended_next_action = Normalize-Text (Get-PropValue -Object $domain -Name "recommended_next_action" -Default "")
            }
        }
    )
    top_healthy_areas = @(
        foreach ($domainId in @($topHealthyDomains | Select-Object -First 6)) {
            $domain = $domains[$domainId]
            [ordered]@{
                domain = $domainId
                status = Normalize-Text (Get-PropValue -Object $domain -Name "status" -Default "missing")
                summary = Normalize-Text (Get-PropValue -Object $domain -Name "summary" -Default "")
            }
        }
    )
    current_blocker_domains = @($currentBlockerDomains)
    recommended_next_action = $recommendedNextAction
    summary_cards = $summaryCards
    truth_timestamp_utc = $nowIso
    baseline_tag = $baselineTagValue
}

$blockedQueueCount = 0
if ($queueByStatus.Contains("blocked")) {
    $blockedQueueCount = [int]$queueByStatus["blocked"]
}
$metricsPayload = [ordered]@{
    timestamp_utc = $nowIso
    overall_status = $overallStatus
    service_count = $serviceRows.Count
    healthy_service_count = $healthyServiceCount
    warning_service_count = $serviceWarnCount
    failing_service_count = @($serviceRows | Where-Object { $_.status -eq "FAIL" }).Count
    tenant_count = $workspaceContexts.Count
    active_tenant_count = $(if ($activeTenantId) { 1 } else { 0 })
    recommendation_total = [int]$recommendationCounts.total
    recommendation_current_total = [int]$recommendationCounts.current
    queue_total = $queueItems.Count
    queue_status_counts = $queueByStatus
    tool_total = $toolItems.Count
    enabled_tool_total = $enabledToolItems.Count
    latest_tool_artifact_count = [int]$toolArtifactSummary.artifact_count
    validator_warning_count = [int](Get-PropValue -Object $validatorData -Name "warn_count" -Default 0)
    validator_fail_count = [int](Get-PropValue -Object $validatorData -Name "failed_count" -Default 0)
    available_domain_count = $availableDomainCount
    warning_domain_count = $warningDomainCount + $missingDomainCount
    failing_domain_count = $failingDomainCount
    active_domain_count = $healthyDomainCount + $warningDomainCount + $failingDomainCount
    blocked_governed_count = $blockedSelfImprove + $blockedQueueCount
    pending_approval_count = $pendingApprovals
    live_docs_count = [int](Get-PropValue -Object $liveDocsData -Name "docs_count" -Default 0)
    brand_public_leak_count = [int](Get-PropValue -Object $brandExposureData -Name "public_leak_count" -Default 0)
    keepalive_escalated_issue_count = [int](Get-PropValue -Object $keepaliveData -Name "escalated_issue_count" -Default 0)
}

$existingRegistry = Read-JsonSafe -Path $systemTruthRegistryPath -Default $null
$priorOverallStatus = Normalize-Text (Get-PropValue -Object $existingRegistry -Name "last_overall_status" -Default "")
$history = @((Get-PropValue -Object $existingRegistry -Name "history" -Default @()))
$historyEntry = [ordered]@{
    timestamp_utc = $nowIso
    overall_status = $overallStatus
    truth_artifact_path = $systemTruthPath
    summary_artifact_path = $systemTruthSummaryPath
}
$newHistory = @($historyEntry)
foreach ($entry in @($history)) {
    if ($newHistory.Count -ge 10) {
        break
    }
    $newHistory += $entry
}
$registryPayload = [ordered]@{
    version = 1
    latest_truth_artifact_path = $systemTruthPath
    latest_metrics_artifact_path = $systemMetricsPath
    latest_summary_artifact_path = $systemTruthSummaryPath
    last_build_timestamp_utc = $nowIso
    last_overall_status = $overallStatus
    prior_overall_status = $priorOverallStatus
    last_domain_statuses = $domainStatusMap
    source_availability_summary = [ordered]@{
        available_count = @($truthSources.artifacts | Where-Object { $_.available -eq $true }).Count
        readable_count = @($truthSources.artifacts | Where-Object { $_.readable -eq $true }).Count
        stale_count = $staleArtifactSources.Count
        missing_count = $missingArtifactSources.Count
        unreadable_count = $unreadableArtifactSources.Count
    }
    history = $newHistory
}

$truthPayload = [ordered]@{
    timestamp_utc = $nowIso
    overall_status = $overallStatus
    truth_version = "1.0"
    baseline_tag = $baselineTagValue
    command_run = $commandRun
    repo_root = $repoRoot
    recommended_next_action = $recommendedNextAction
    truth_sources = $truthSources
    domains = $domains
    summary = [ordered]@{
        available_domain_count = $availableDomainCount
        warning_domain_count = $warningDomainCount + $missingDomainCount
        failing_domain_count = $failingDomainCount
        healthy_domain_count = $healthyDomainCount
        top_warning_domains = @($topWarningDomains | Select-Object -First 6)
        top_healthy_domains = @($topHealthyDomains | Select-Object -First 6)
        current_blocker_domains = @($currentBlockerDomains)
    }
    staleness = [ordered]@{
        stale_artifact_count = $staleArtifactSources.Count
        stale_artifact_sources = @($staleArtifactSources | ForEach-Object { $_.source_id })
        missing_artifact_count = $missingArtifactSources.Count
        missing_artifact_sources = @($missingArtifactSources | ForEach-Object { $_.source_id })
        unreadable_artifact_count = $unreadableArtifactSources.Count
        unreadable_artifact_sources = @($unreadableArtifactSources | ForEach-Object { $_.source_id })
    }
    merge_warnings = $mergeWarnings
}

Write-JsonFile -Path $systemTruthPath -Object $truthPayload -Depth 24
Write-JsonFile -Path $systemMetricsPath -Object $metricsPayload -Depth 20
Write-JsonFile -Path $systemTruthSummaryPath -Object $summaryPayload -Depth 20
Write-JsonFile -Path $systemTruthRegistryPath -Object $registryPayload -Depth 20

$truthPayload
