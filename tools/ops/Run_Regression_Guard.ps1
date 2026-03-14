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
        [int]$Depth = 20
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
        return $raw | ConvertFrom-Json -ErrorAction Stop
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
    if ($null -ne $property) {
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

function Normalize-Status {
    param(
        $Value,
        [string]$Default = "UNKNOWN"
    )

    $text = Normalize-Text $Value
    if (-not $text) {
        return $Default
    }

    switch ($text.ToUpperInvariant()) {
        "PASS" { return "PASS" }
        "OK" { return "PASS" }
        "GREEN" { return "PASS" }
        "HEALTHY" { return "PASS" }
        "DONE" { return "PASS" }
        "SUCCESS" { return "PASS" }
        "GUARDED" { return "PASS" }
        "WARN" { return "WARN" }
        "WARNING" { return "WARN" }
        "WATCH" { return "WARN" }
        "YELLOW" { return "WARN" }
        "STUB" { return "WARN" }
        "CAUTION" { return "WARN" }
        "FAIL" { return "FAIL" }
        "FAILED" { return "FAIL" }
        "RED" { return "FAIL" }
        "ERROR" { return "FAIL" }
        "BLOCKED" { return "FAIL" }
        "MISSING" { return "MISSING" }
        default { return $text.ToUpperInvariant() }
    }
}

function Get-StatusRank {
    param($Value)

    switch (Normalize-Status -Value $Value -Default "UNKNOWN") {
        "PASS" { return 0 }
        "WARN" { return 1 }
        "FAIL" { return 2 }
        "MISSING" { return 3 }
        default { return 1 }
    }
}

function Get-ThrottleRank {
    param($Value)

    switch ((Normalize-Text $Value).ToLowerInvariant()) {
        "normal" { return 0 }
        "caution" { return 1 }
        "throttle_heavy_jobs" { return 2 }
        "protect_host" { return 3 }
        default { return 0 }
    }
}

function Get-DriftRank {
    param($Value)

    switch ((Normalize-Text $Value).ToLowerInvariant()) {
        "no_material_change" { return 0 }
        "minor_change" { return 1 }
        "significant_change" { return 2 }
        "new_environment" { return 3 }
        default { return 0 }
    }
}

function Get-SeverityRank {
    param($Value)

    switch ((Normalize-Text $Value).ToLowerInvariant()) {
        "low" { return 1 }
        "medium" { return 2 }
        "high" { return 3 }
        "critical" { return 4 }
        default { return 0 }
    }
}

function Convert-ToStringArray {
    param($Value)

    $items = @()
    foreach ($item in @($Value)) {
        $text = Normalize-Text $item
        if ($text) {
            $items += $text
        }
    }
    return @($items)
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

    $portsCfg = Read-JsonSafe -Path (Join-Path $RepoRoot "config\ports.json") -Default $null
    $portsSource = if ($portsCfg) { Get-PropValue -Object $portsCfg -Name "ports" -Default $portsCfg } else { $null }
    if (-not $portsSource) {
        return $defaults
    }

    foreach ($key in @($defaults.Keys)) {
        $parsed = 0
        $raw = Get-PropValue -Object $portsSource -Name $key -Default $defaults[$key]
        if ([int]::TryParse([string]$raw, [ref]$parsed) -and $parsed -gt 0 -and $parsed -le 65535) {
            $defaults[$key] = [int]$parsed
        }
    }

    return $defaults
}

function Get-PortListenerRows {
    param([int[]]$Ports)

    $portSet = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($port in @($Ports | Sort-Object -Unique)) {
        if ([int]$port -gt 0) {
            [void]$portSet.Add([int]$port)
        }
    }

    $rows = @()
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
        $localPort = [int](Get-PropValue -Object $row -Name "local_port" -Default 0)
        if (-not $map.ContainsKey($localPort)) {
            $map[$localPort] = @()
        }
        $map[$localPort] = @($map[$localPort]) + @($row)
    }

    return $map
}

function Invoke-LoopbackProbe {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSeconds = 10
    )

    try {
        $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec $TimeoutSeconds -ErrorAction Stop
        return [ordered]@{
            ok          = ([int]$response.StatusCode -ge 200 -and [int]$response.StatusCode -lt 400)
            status_code = [int]$response.StatusCode
            error       = ""
            url         = $Url
        }
    }
    catch {
        $statusCode = 0
        try {
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
        }
        catch {
        }

        return [ordered]@{
            ok          = $false
            status_code = $statusCode
            error       = Normalize-Text $_.Exception.Message
            url         = $Url
        }
    }
}

function Get-ValidatorSection {
    param(
        $ValidatorPayload,
        [Parameter(Mandatory = $true)][string]$SectionName
    )

    foreach ($section in @((Get-PropValue -Object $ValidatorPayload -Name "sections" -Default @()))) {
        if ((Normalize-Text (Get-PropValue -Object $section -Name "section_name" -Default "")) -eq $SectionName) {
            return $section
        }
    }

    return $null
}

function New-DomainSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$DomainId,
        [Parameter(Mandatory = $true)][string]$Status,
        [Parameter(Mandatory = $true)][string]$Summary,
        [Parameter(Mandatory = $true)][string[]]$EvidenceUsed,
        [Parameter(Mandatory = $true)][hashtable]$Metrics,
        [Parameter(Mandatory = $true)][hashtable]$Details,
        [string]$RecommendedNextAction = "",
        [string]$LastUpdatedUtc = ""
    )

    return [ordered]@{
        domain_id               = $DomainId
        status                  = (Normalize-Status -Value $Status -Default "UNKNOWN")
        summary                 = $Summary
        evidence_used           = @($EvidenceUsed | Where-Object { Normalize-Text $_ } | Select-Object -Unique)
        metrics                 = [ordered]@{} + $Metrics
        details                 = [ordered]@{} + $Details
        recommended_next_action = $RecommendedNextAction
        last_updated_utc        = $LastUpdatedUtc
    }
}

function Get-DefaultRegressionPolicy {
    return [ordered]@{
        version = 1
        policy_name = "regression_guard_policy"
        baseline_source_policy = [ordered]@{
            preferred_baseline = "trusted_eligible"
            fallback_baseline = "seed_observation_only"
            allow_seed_initialization = $true
            prefer_active_baseline_id = $true
        }
        comparison_domains = @(
            "validator",
            "stack",
            "runtime_truth",
            "host",
            "environment",
            "keepalive_ops",
            "self_improvement",
            "security_posture",
            "billing",
            "mirror",
            "brand_exposure",
            "live_docs",
            "system_truth"
        )
        regression_severity_thresholds = [ordered]@{
            critical_domains = @("validator", "stack", "runtime_truth", "security_posture", "brand_exposure")
            high_domains = @("keepalive_ops", "mirror", "system_truth")
            medium_domains = @("host", "environment", "billing", "live_docs")
            validator_warn_delta_for_low = 1
            pid_drift_delta_for_medium = 1
            tenant_safety_issue_delta_for_high = 1
            escalation_delta_for_medium = 1
            live_docs_stale_delta_for_low = 1
        }
        allowed_deltas = [ordered]@{
            unchanged_warn_is_not_regression = $true
            unchanged_billing_stub_is_not_regression = $true
            unchanged_self_improvement_review_gate_is_not_regression = $true
            unchanged_environment_no_material_change_is_not_regression = $true
            unchanged_host_pending_reboot_is_not_regression = $true
            validator_warn_count_increase_without_status_drop = 1
        }
        promotion_blocking_rules = [ordered]@{
            require_trusted_baseline = $true
            block_on_blocking_regression = $true
            block_on_public_brand_leak = $true
            block_on_service_health_degradation = $true
            block_on_truth_integrity_degradation = $true
            block_on_rollback_recommended = $true
            block_on_stale_baseline = $true
        }
        rollback_recommendation_rules = [ordered]@{
            recommend_on_severity = @("high", "critical")
            recommend_on_domains = @("validator", "stack", "runtime_truth", "security_posture", "brand_exposure", "mirror")
        }
        excluded_noisy_signals = @(
            "unchanged_billing_stub",
            "unchanged_self_improvement_review_gate",
            "unchanged_host_pending_reboot",
            "unchanged_environment_no_material_change",
            "unchanged_live_docs_component_warning"
        )
        evidence_precedence = @(
            "live_loopback_probe",
            "current_live_pid_truth",
            "system_truth_spine",
            "whole_system_validator",
            "domain_artifacts"
        )
        stale_baseline_handling = [ordered]@{
            max_age_hours = 168
            warn_if_exceeded = $true
            block_promotion_if_exceeded = $true
        }
        missing_baseline_handling = [ordered]@{
            seed_initial_baseline = $true
            compare_against_seed_for_observation = $true
            allow_promotion_without_trusted_baseline = $false
        }
    }
}

function Get-RegressionPolicy {
    param([Parameter(Mandatory = $true)][string]$PolicyPath)

    $existing = Read-JsonSafe -Path $PolicyPath -Default $null
    if ($existing) {
        return $existing
    }

    $policy = Get-DefaultRegressionPolicy
    Write-JsonFile -Path $PolicyPath -Object $policy
    return $policy
}

function Get-DomainBaseSeverity {
    param(
        [Parameter(Mandatory = $true)][string]$DomainId,
        $Policy
    )

    $thresholds = Get-PropValue -Object $Policy -Name "regression_severity_thresholds" -Default @{}
    $critical = Convert-ToStringArray (Get-PropValue -Object $thresholds -Name "critical_domains" -Default @())
    $high = Convert-ToStringArray (Get-PropValue -Object $thresholds -Name "high_domains" -Default @())
    $medium = Convert-ToStringArray (Get-PropValue -Object $thresholds -Name "medium_domains" -Default @())

    if ($critical -contains $DomainId) {
        return "high"
    }
    if ($high -contains $DomainId) {
        return "medium"
    }
    if ($medium -contains $DomainId) {
        return "low"
    }
    return "low"
}

function Get-WorsenedSeverity {
    param(
        [Parameter(Mandatory = $true)][string]$DomainId,
        [Parameter(Mandatory = $true)][string]$PriorStatus,
        [Parameter(Mandatory = $true)][string]$CurrentStatus,
        [string]$Reason = "",
        $Policy = $null
    )

    $baseSeverity = if ($Policy) { Get-DomainBaseSeverity -DomainId $DomainId -Policy $Policy } else { "low" }
    $baseRank = Get-SeverityRank -Value $baseSeverity

    if ((Get-StatusRank -Value $CurrentStatus) -ge 2) {
        $baseRank = [math]::Max($baseRank, 3)
    }

    $reasonText = (Normalize-Text $Reason).ToLowerInvariant()
    if ($reasonText.Contains("brand leak") -or $reasonText.Contains("public leak")) {
        $baseRank = 4
    }

    switch ($baseRank) {
        4 { return "critical" }
        3 { return "high" }
        2 { return "medium" }
        default { return "low" }
    }
}

function New-ComparisonRecord {
    param(
        [Parameter(Mandatory = $true)][string]$DomainId,
        [Parameter(Mandatory = $true)][string]$Classification,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Severity,
        [Parameter(Mandatory = $true)][AllowNull()]$PriorState,
        [Parameter(Mandatory = $true)][AllowNull()]$CurrentState,
        [Parameter(Mandatory = $true)][string[]]$EvidenceUsed,
        [Parameter(Mandatory = $true)][string]$Why,
        [bool]$BlocksPromotion = $false,
        [bool]$SuggestsRollback = $false
    )

    $normalizedSeverity = Normalize-Text $Severity
    if (-not $normalizedSeverity) {
        $normalizedSeverity = "none"
    }

    return [ordered]@{
        domain_id         = $DomainId
        classification    = $Classification
        severity          = $normalizedSeverity
        prior_state       = $PriorState
        current_state     = $CurrentState
        evidence_used     = @($EvidenceUsed | Where-Object { Normalize-Text $_ } | Select-Object -Unique)
        why               = $Why
        blocks_promotion  = $BlocksPromotion
        suggests_rollback = $SuggestsRollback
    }
}

function Get-BaselineRegistry {
    param([Parameter(Mandatory = $true)][string]$Path)

    $existing = Read-JsonSafe -Path $Path -Default $null
    if ($existing) {
        return $existing
    }

    return [ordered]@{
        version = 1
        current_active_baseline_id = ""
        current_trusted_baseline_id = ""
        last_run_timestamp_utc = ""
        last_comparison_result = ""
        baselines = @()
        history = @()
    }
}

function Test-BaselineUsable {
    param($Baseline)

    if ($null -eq $Baseline) {
        return $false
    }

    $baselineId = Normalize-Text (Get-PropValue -Object $Baseline -Name "baseline_id" -Default "")
    if (-not $baselineId) {
        return $false
    }

    $summary = Get-PropValue -Object $Baseline -Name "baseline_status_summary" -Default @{}
    $overallStatus = Normalize-Status (Get-PropValue -Object $summary -Name "overall_status" -Default "UNKNOWN")
    if ($overallStatus -eq "UNKNOWN") {
        return $false
    }

    return $true
}

function Get-BaselineById {
    param(
        $Registry,
        [string]$BaselineId
    )

    $targetId = Normalize-Text $BaselineId
    if (-not $targetId) {
        return $null
    }

    foreach ($baseline in @((Get-PropValue -Object $Registry -Name "baselines" -Default @()))) {
        if (-not (Test-BaselineUsable -Baseline $baseline)) {
            continue
        }
        if ((Normalize-Text (Get-PropValue -Object $baseline -Name "baseline_id" -Default "")) -eq $targetId) {
            return $baseline
        }
    }

    return $null
}

function Get-LatestEligibleBaseline {
    param(
        $Registry,
        [switch]$TrustedOnly
    )

    $eligible = @()
    foreach ($baseline in @((Get-PropValue -Object $Registry -Name "baselines" -Default @()))) {
        if (-not (Test-BaselineUsable -Baseline $baseline)) {
            continue
        }
        if (-not [bool](Get-PropValue -Object $baseline -Name "eligible_for_comparison" -Default $false)) {
            continue
        }
        if ($TrustedOnly -and -not [bool](Get-PropValue -Object $baseline -Name "trusted" -Default $false)) {
            continue
        }
        $eligible += $baseline
    }

    return @($eligible | Sort-Object { Parse-DateSafe (Get-PropValue -Object $_ -Name "created_at_utc" -Default "") } -Descending | Select-Object -First 1)
}

function New-BaselineRecord {
    param(
        [Parameter(Mandatory = $true)]$CurrentSnapshot,
        [Parameter(Mandatory = $true)][string]$BaselineKind
    )

    $timestampUtc = Convert-ToUtcIso (Get-NowUtc)
    $baselineId = "baseline_{0}_{1}" -f $BaselineKind, (Get-Date -Format "yyyyMMdd_HHmmss")
    $systemTruth = Get-PropValue -Object $CurrentSnapshot -Name "system_truth_artifact" -Default $null
    $validator = Get-PropValue -Object $CurrentSnapshot -Name "validator_artifact" -Default $null
    $domainSnapshots = Get-PropValue -Object $CurrentSnapshot -Name "domains" -Default @{}

    $sourceArtifacts = @(
        $(Get-PropValue -Object $CurrentSnapshot -Name "system_truth_path" -Default ""),
        $(Get-PropValue -Object $CurrentSnapshot -Name "validator_path" -Default ""),
        $(Get-PropValue -Object $CurrentSnapshot -Name "keepalive_path" -Default ""),
        $(Get-PropValue -Object $CurrentSnapshot -Name "host_path" -Default ""),
        $(Get-PropValue -Object $CurrentSnapshot -Name "billing_path" -Default ""),
        $(Get-PropValue -Object $CurrentSnapshot -Name "security_path" -Default ""),
        $(Get-PropValue -Object $CurrentSnapshot -Name "mirror_path" -Default "")
    ) | Where-Object { Normalize-Text $_ } | Select-Object -Unique

    $baselineTag = Normalize-Text (Get-PropValue -Object $systemTruth -Name "baseline_tag" -Default "")
    if (-not $baselineTag) {
        $baselineTag = Normalize-Text (Get-PropValue -Object $validator -Name "baseline_tag" -Default "")
    }

    $domainStatuses = [ordered]@{}
    $baselineDomainSnapshots = [ordered]@{}
    foreach ($domainId in @($domainSnapshots.Keys)) {
        $domainSnapshot = $domainSnapshots[$domainId]
        $domainStatuses[$domainId] = Normalize-Status (Get-PropValue -Object $domainSnapshot -Name "status" -Default "UNKNOWN")
        $baselineDomainSnapshots[$domainId] = [ordered]@{
            status = Normalize-Status (Get-PropValue -Object $domainSnapshot -Name "status" -Default "UNKNOWN")
            summary = Normalize-Text (Get-PropValue -Object $domainSnapshot -Name "summary" -Default "")
            metrics = [ordered]@{} + (Get-PropValue -Object $domainSnapshot -Name "metrics" -Default @{})
            details = [ordered]@{} + (Get-PropValue -Object $domainSnapshot -Name "details" -Default @{})
            last_updated_utc = Normalize-Text (Get-PropValue -Object $domainSnapshot -Name "last_updated_utc" -Default "")
            evidence_used = Convert-ToStringArray (Get-PropValue -Object $domainSnapshot -Name "evidence_used" -Default @())
        }
    }

    return [ordered]@{
        baseline_id = $baselineId
        created_at_utc = $timestampUtc
        source_artifacts = @($sourceArtifacts)
        baseline_tag = $baselineTag
        baseline_status_summary = [ordered]@{
            overall_status = Normalize-Status (Get-PropValue -Object $CurrentSnapshot -Name "overall_status" -Default "UNKNOWN")
            validator_status = Normalize-Status (Get-PropValue -Object $validator -Name "overall_status" -Default "UNKNOWN")
            system_truth_status = Normalize-Status (Get-PropValue -Object $systemTruth -Name "overall_status" -Default "UNKNOWN")
        }
        domain_statuses = $domainStatuses
        domain_snapshots = $baselineDomainSnapshots
        notes = @("Initial regression baseline captured from current local truth.", "Seed baselines are comparison-capable for observation but do not unlock promotion.")
        eligible_for_comparison = $true
        promoted = $false
        approved = $false
        trusted = $false
        baseline_kind = $BaselineKind
    }
}

function Select-ComparisonBaseline {
    param(
        $Registry,
        $Policy
    )

    $trustedBaseline = @(Get-LatestEligibleBaseline -Registry $Registry -TrustedOnly)
    if ($trustedBaseline.Count -gt 0 -and $trustedBaseline[0]) {
        return [ordered]@{
            baseline = $trustedBaseline[0]
            comparison_mode = "trusted"
            trusted = $true
        }
    }

    $activeBaseline = Get-BaselineById -Registry $Registry -BaselineId (Get-PropValue -Object $Registry -Name "current_active_baseline_id" -Default "")
    if ($activeBaseline -and [bool](Get-PropValue -Object $activeBaseline -Name "eligible_for_comparison" -Default $false)) {
        return [ordered]@{
            baseline = $activeBaseline
            comparison_mode = "seed_only"
            trusted = [bool](Get-PropValue -Object $activeBaseline -Name "trusted" -Default $false)
        }
    }

    $seedBaseline = @(Get-LatestEligibleBaseline -Registry $Registry)
    if ($seedBaseline.Count -gt 0 -and $seedBaseline[0]) {
        return [ordered]@{
            baseline = $seedBaseline[0]
            comparison_mode = "seed_only"
            trusted = [bool](Get-PropValue -Object $seedBaseline[0] -Name "trusted" -Default $false)
        }
    }

    return [ordered]@{
        baseline = $null
        comparison_mode = "baseline_missing"
        trusted = $false
    }
}

function Compare-DomainSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$DomainId,
        $PriorSnapshot,
        $CurrentSnapshot,
        $Policy
    )

    if ($null -eq $CurrentSnapshot) {
        return (New-ComparisonRecord -DomainId $DomainId -Classification "missing" -Severity "" -PriorState $PriorSnapshot -CurrentState $null -EvidenceUsed @() -Why "Current domain snapshot is missing." -BlocksPromotion $false -SuggestsRollback $false)
    }

    if ($null -eq $PriorSnapshot) {
        return (New-ComparisonRecord -DomainId $DomainId -Classification "not_comparable" -Severity "" -PriorState $null -CurrentState $CurrentSnapshot -EvidenceUsed (Convert-ToStringArray (Get-PropValue -Object $CurrentSnapshot -Name "evidence_used" -Default @())) -Why "No comparison baseline exists for this domain." -BlocksPromotion $false -SuggestsRollback $false)
    }

    $priorStatus = Normalize-Status (Get-PropValue -Object $PriorSnapshot -Name "status" -Default "UNKNOWN")
    $currentStatus = Normalize-Status (Get-PropValue -Object $CurrentSnapshot -Name "status" -Default "UNKNOWN")
    $priorMetrics = Get-PropValue -Object $PriorSnapshot -Name "metrics" -Default @{}
    $currentMetrics = Get-PropValue -Object $CurrentSnapshot -Name "metrics" -Default @{}
    $priorDetails = Get-PropValue -Object $PriorSnapshot -Name "details" -Default @{}
    $currentDetails = Get-PropValue -Object $CurrentSnapshot -Name "details" -Default @{}
    $priorEvidence = @(Convert-ToStringArray (Get-PropValue -Object $PriorSnapshot -Name "evidence_used" -Default @()))
    $currentEvidence = @(Convert-ToStringArray (Get-PropValue -Object $CurrentSnapshot -Name "evidence_used" -Default @()))
    $evidenceUsed = @(
        @($priorEvidence + $currentEvidence) |
            Where-Object { Normalize-Text $_ } |
            Select-Object -Unique
    )

    $classification = "unchanged"
    $severity = ""
    $why = "Current state is materially unchanged against the comparison baseline."
    $blocksPromotion = $false
    $suggestsRollback = $false
    $warnOnlyRegression = $false

    $statusDelta = (Get-StatusRank -Value $currentStatus) - (Get-StatusRank -Value $priorStatus)
    if ($statusDelta -gt 0) {
        $classification = "worsened"
        $why = "Overall domain status degraded from $priorStatus to $currentStatus."
    }
    elseif ($statusDelta -lt 0) {
        $classification = "improved"
        $why = "Overall domain status improved from $priorStatus to $currentStatus."
    }

    switch ($DomainId) {
        "validator" {
            $priorFails = [int](Get-PropValue -Object $priorMetrics -Name "failed_count" -Default 0)
            $currentFails = [int](Get-PropValue -Object $currentMetrics -Name "failed_count" -Default 0)
            $priorWarns = [int](Get-PropValue -Object $priorMetrics -Name "warn_count" -Default 0)
            $currentWarns = [int](Get-PropValue -Object $currentMetrics -Name "warn_count" -Default 0)
            $warnDeltaAllowed = [int](Get-PropValue -Object (Get-PropValue -Object $Policy -Name "allowed_deltas" -Default @{}) -Name "validator_warn_count_increase_without_status_drop" -Default 1)

            if ($currentFails -gt $priorFails) {
                $classification = "worsened"
                $why = "Validator failed_count increased from $priorFails to $currentFails."
            }
            elseif ($currentFails -lt $priorFails) {
                $classification = "improved"
                $why = "Validator failed_count dropped from $priorFails to $currentFails."
            }
            elseif ($currentWarns -gt ($priorWarns + $warnDeltaAllowed)) {
                $classification = "worsened"
                $why = "Validator warn_count increased from $priorWarns to $currentWarns beyond the allowed delta."
                $warnOnlyRegression = $true
            }
            elseif ($currentWarns -lt $priorWarns) {
                $classification = "improved"
                $why = "Validator warn_count decreased from $priorWarns to $currentWarns."
            }
        }
        "stack" {
            $priorUnhealthy = [int](Get-PropValue -Object $priorMetrics -Name "unhealthy_service_count" -Default 0)
            $currentUnhealthy = [int](Get-PropValue -Object $currentMetrics -Name "unhealthy_service_count" -Default 0)
            $priorDrift = [int](Get-PropValue -Object $priorMetrics -Name "pid_drift_count" -Default 0)
            $currentDrift = [int](Get-PropValue -Object $currentMetrics -Name "pid_drift_count" -Default 0)

            if ($currentUnhealthy -gt $priorUnhealthy) {
                $classification = "worsened"
                $why = "Unhealthy required services increased from $priorUnhealthy to $currentUnhealthy."
            }
            elseif ($currentUnhealthy -lt $priorUnhealthy) {
                $classification = "improved"
                $why = "Unhealthy required services decreased from $priorUnhealthy to $currentUnhealthy."
            }
            elseif ($currentDrift -gt $priorDrift) {
                $classification = "worsened"
                $why = "Runtime ownership drift increased from $priorDrift to $currentDrift service(s)."
            }
            elseif ($currentDrift -lt $priorDrift) {
                $classification = "improved"
                $why = "Runtime ownership drift decreased from $priorDrift to $currentDrift service(s)."
            }
        }
        "runtime_truth" {
            $priorDrift = [int](Get-PropValue -Object $priorMetrics -Name "pid_drift_count" -Default 0)
            $currentDrift = [int](Get-PropValue -Object $currentMetrics -Name "pid_drift_count" -Default 0)
            if ($currentDrift -gt $priorDrift) {
                $classification = "worsened"
                $why = "Singleton/current_live_pid drift increased from $priorDrift to $currentDrift service(s)."
            }
            elseif ($currentDrift -lt $priorDrift) {
                $classification = "improved"
                $why = "Singleton/current_live_pid drift decreased from $priorDrift to $currentDrift service(s)."
            }
        }
        "host" {
            $priorThrottle = Get-ThrottleRank -Value (Get-PropValue -Object $priorMetrics -Name "throttle_guidance" -Default "")
            $currentThrottle = Get-ThrottleRank -Value (Get-PropValue -Object $currentMetrics -Name "throttle_guidance" -Default "")
            if ($currentThrottle -gt $priorThrottle) {
                $classification = "worsened"
                $why = "Host throttle guidance tightened from $($priorMetrics.throttle_guidance) to $($currentMetrics.throttle_guidance)."
            }
            elseif ($currentThrottle -lt $priorThrottle) {
                $classification = "improved"
                $why = "Host throttle guidance relaxed from $($priorMetrics.throttle_guidance) to $($currentMetrics.throttle_guidance)."
            }
        }
        "environment" {
            $priorDrift = Get-DriftRank -Value (Get-PropValue -Object $priorMetrics -Name "drift_level" -Default "")
            $currentDrift = Get-DriftRank -Value (Get-PropValue -Object $currentMetrics -Name "drift_level" -Default "")
            if ($currentDrift -gt $priorDrift) {
                $classification = "worsened"
                $why = "Environment drift level increased from $($priorMetrics.drift_level) to $($currentMetrics.drift_level)."
            }
            elseif ($currentDrift -lt $priorDrift) {
                $classification = "improved"
                $why = "Environment drift level relaxed from $($priorMetrics.drift_level) to $($currentMetrics.drift_level)."
            }
        }
        "keepalive_ops" {
            $priorEscalated = [int](Get-PropValue -Object $priorMetrics -Name "escalated_issue_count" -Default 0)
            $currentEscalated = [int](Get-PropValue -Object $currentMetrics -Name "escalated_issue_count" -Default 0)
            $priorBlocked = [int](Get-PropValue -Object $priorMetrics -Name "repair_blocked_count" -Default 0)
            $currentBlocked = [int](Get-PropValue -Object $currentMetrics -Name "repair_blocked_count" -Default 0)
            if ($currentEscalated -gt $priorEscalated) {
                $classification = "worsened"
                $why = "KeepAlive escalations increased from $priorEscalated to $currentEscalated."
            }
            elseif ($currentEscalated -lt $priorEscalated) {
                $classification = "improved"
                $why = "KeepAlive escalations decreased from $priorEscalated to $currentEscalated."
            }
            elseif ($currentBlocked -gt $priorBlocked) {
                $classification = "worsened"
                $why = "Policy-blocked repair count increased from $priorBlocked to $currentBlocked."
            }
            elseif ($currentBlocked -lt $priorBlocked) {
                $classification = "improved"
                $why = "Policy-blocked repair count decreased from $priorBlocked to $currentBlocked."
            }
        }
        "security_posture" {
            $priorIssues = [int](Get-PropValue -Object $priorMetrics -Name "tenant_safety_issues_total" -Default 0)
            $currentIssues = [int](Get-PropValue -Object $currentMetrics -Name "tenant_safety_issues_total" -Default 0)
            $priorCritical = [int](Get-PropValue -Object $priorMetrics -Name "tenant_safety_critical_total" -Default 0)
            $currentCritical = [int](Get-PropValue -Object $currentMetrics -Name "tenant_safety_critical_total" -Default 0)
            if ($currentCritical -gt $priorCritical) {
                $classification = "worsened"
                $why = "Critical tenant safety issues increased from $priorCritical to $currentCritical."
            }
            elseif ($currentIssues -gt $priorIssues) {
                $classification = "worsened"
                $why = "Tenant safety issues increased from $priorIssues to $currentIssues."
            }
            elseif ($currentIssues -lt $priorIssues) {
                $classification = "improved"
                $why = "Tenant safety issues decreased from $priorIssues to $currentIssues."
            }
        }
        "billing" {
            $priorEnabled = [int](Get-PropValue -Object $priorMetrics -Name "enabled_tool_total" -Default 0)
            $currentEnabled = [int](Get-PropValue -Object $currentMetrics -Name "enabled_tool_total" -Default 0)
            $priorMode = Normalize-Text (Get-PropValue -Object $priorDetails -Name "provider_mode" -Default "")
            $currentMode = Normalize-Text (Get-PropValue -Object $currentDetails -Name "provider_mode" -Default "")
            if ($currentEnabled -lt $priorEnabled) {
                $classification = "worsened"
                $why = "Enabled tools dropped from $priorEnabled to $currentEnabled."
            }
            elseif ($currentEnabled -gt $priorEnabled) {
                $classification = "improved"
                $why = "Enabled tools increased from $priorEnabled to $currentEnabled."
            }
            elseif ($priorMode -and $currentMode -and $priorMode -ne $currentMode -and $currentMode -eq "stub") {
                $classification = "worsened"
                $why = "Billing provider mode regressed from $priorMode to $currentMode."
            }
        }
        "mirror" {
            $priorOk = [bool](Get-PropValue -Object $priorMetrics -Name "ok" -Default $false)
            $currentOk = [bool](Get-PropValue -Object $currentMetrics -Name "ok" -Default $false)
            $priorPhase = Normalize-Text (Get-PropValue -Object $priorMetrics -Name "phase" -Default "")
            $currentPhase = Normalize-Text (Get-PropValue -Object $currentMetrics -Name "phase" -Default "")
            if ($priorOk -and -not $currentOk) {
                $classification = "worsened"
                $why = "Mirror/checkpoint no longer reports ok=true."
            }
            elseif ($priorPhase -eq "done" -and $currentPhase -and $currentPhase -ne "done") {
                $classification = "worsened"
                $why = "Mirror phase regressed from done to $currentPhase."
            }
        }
        "brand_exposure" {
            $priorLeaks = [int](Get-PropValue -Object $priorMetrics -Name "public_leak_count" -Default 0)
            $currentLeaks = [int](Get-PropValue -Object $currentMetrics -Name "public_leak_count" -Default 0)
            if ($currentLeaks -gt $priorLeaks) {
                $classification = "worsened"
                $why = "Public brand leak count increased from $priorLeaks to $currentLeaks."
            }
            elseif ($currentLeaks -lt $priorLeaks) {
                $classification = "improved"
                $why = "Public brand leak count decreased from $priorLeaks to $currentLeaks."
            }
        }
        "live_docs" {
            $priorStale = [int](Get-PropValue -Object $priorMetrics -Name "stale_docs_count" -Default 0)
            $currentStale = [int](Get-PropValue -Object $currentMetrics -Name "stale_docs_count" -Default 0)
            $priorDocs = [int](Get-PropValue -Object $priorMetrics -Name "docs_count" -Default 0)
            $currentDocs = [int](Get-PropValue -Object $currentMetrics -Name "docs_count" -Default 0)
            if ($currentStale -gt $priorStale) {
                $classification = "worsened"
                $why = "Stale live docs count increased from $priorStale to $currentStale."
            }
            elseif ($currentDocs -lt $priorDocs) {
                $classification = "worsened"
                $why = "Generated live docs count dropped from $priorDocs to $currentDocs."
            }
            elseif ($currentDocs -gt $priorDocs -or $currentStale -lt $priorStale) {
                $classification = "improved"
                $why = "Live docs coverage improved against the comparison baseline."
            }
        }
        "system_truth" {
            $priorFails = [int](Get-PropValue -Object $priorMetrics -Name "failing_domain_count" -Default 0)
            $currentFails = [int](Get-PropValue -Object $currentMetrics -Name "failing_domain_count" -Default 0)
            $priorWarns = [int](Get-PropValue -Object $priorMetrics -Name "warning_domain_count" -Default 0)
            $currentWarns = [int](Get-PropValue -Object $currentMetrics -Name "warning_domain_count" -Default 0)
            if ($currentFails -gt $priorFails) {
                $classification = "worsened"
                $why = "System truth failing_domain_count increased from $priorFails to $currentFails."
            }
            elseif ($currentFails -lt $priorFails) {
                $classification = "improved"
                $why = "System truth failing_domain_count decreased from $priorFails to $currentFails."
            }
            elseif ($currentWarns -gt $priorWarns) {
                $classification = "worsened"
                $why = "System truth warning_domain_count increased from $priorWarns to $currentWarns."
            }
            elseif ($currentWarns -lt $priorWarns) {
                $classification = "improved"
                $why = "System truth warning_domain_count decreased from $priorWarns to $currentWarns."
            }
        }
    }

    if ($classification -eq "worsened") {
        $severity = Get-WorsenedSeverity -DomainId $DomainId -PriorStatus $priorStatus -CurrentStatus $currentStatus -Reason $why -Policy $Policy
        $blocksPromotion = ($severity -in @("high", "critical")) -or ($DomainId -in @("validator", "stack", "runtime_truth", "security_posture", "brand_exposure"))
        $rollbackDomains = Convert-ToStringArray (Get-PropValue -Object (Get-PropValue -Object $Policy -Name "rollback_recommendation_rules" -Default @{}) -Name "recommend_on_domains" -Default @())
        $rollbackSeverities = Convert-ToStringArray (Get-PropValue -Object (Get-PropValue -Object $Policy -Name "rollback_recommendation_rules" -Default @{}) -Name "recommend_on_severity" -Default @())
        $suggestsRollback = ($rollbackDomains -contains $DomainId) -and ($rollbackSeverities -contains $severity)

        if ($DomainId -eq "validator" -and $warnOnlyRegression -and $priorStatus -eq $currentStatus) {
            $severity = "low"
            $blocksPromotion = $false
            $suggestsRollback = $false
        }
    }

    return (New-ComparisonRecord -DomainId $DomainId -Classification $classification -Severity $severity -PriorState $PriorSnapshot -CurrentState $CurrentSnapshot -EvidenceUsed $evidenceUsed -Why $why -BlocksPromotion $blocksPromotion -SuggestsRollback $suggestsRollback)
}

$repoRoot = Get-RepoRoot -OverrideRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$stateDir = Join-Path $repoRoot "state\knowledge"
$configDir = Join-Path $repoRoot "config"

$regressionGuardPath = Join-Path $reportsDir "regression_guard_last.json"
$rollbackPlanPath = Join-Path $reportsDir "rollback_plan_last.json"
$promotionGatePath = Join-Path $reportsDir "promotion_gate_last.json"
$regressionBaselinesPath = Join-Path $stateDir "regression_baselines.json"
$regressionPolicyPath = Join-Path $configDir "regression_guard_policy.json"

$systemTruthPath = Join-Path $reportsDir "system_truth_spine_last.json"
$systemMetricsPath = Join-Path $reportsDir "system_metrics_spine_last.json"
$validatorPath = Join-Path $reportsDir "system_validation_last.json"
$hostHealthPath = Join-Path $reportsDir "host_health_last.json"
$runtimePosturePath = Join-Path $reportsDir "runtime_posture_last.json"
$environmentProfilePath = Join-Path $reportsDir "environment_profile_last.json"
$environmentDriftPath = Join-Path $reportsDir "environment_drift_last.json"
$keepalivePath = Join-Path $reportsDir "keepalive_last.json"
$selfHealPath = Join-Path $reportsDir "self_heal_last.json"
$dailyReportPath = Join-Path $reportsDir "daily_report_last.json"
$securityPosturePath = Join-Path $reportsDir "security_posture.json"
$tenantSafetyPath = Join-Path $reportsDir "tenant_safety_report.json"
$billingSummaryPath = Join-Path $reportsDir "billing_summary.json"
$mirrorPath = Join-Path $reportsDir "mirror_update_last.json"
$brandExposurePath = Join-Path $reportsDir "brand_exposure_isolation_last.json"
$liveDocsSummaryPath = Join-Path $reportsDir "live_docs_summary.json"
$selfImprovementPath = Join-Path $reportsDir "self_improvement_governor_last.json"
$stackPidsPath = Join-Path $repoRoot "state\knowledge\stack_pids.json"
$startRunPath = Join-Path $reportsDir "start\start_run_last.json"

$policy = Get-RegressionPolicy -PolicyPath $regressionPolicyPath

$systemTruth = Read-JsonSafe -Path $systemTruthPath -Default $null
$systemMetrics = Read-JsonSafe -Path $systemMetricsPath -Default $null
$validator = Read-JsonSafe -Path $validatorPath -Default $null
$hostHealth = Read-JsonSafe -Path $hostHealthPath -Default $null
$runtimePosture = Read-JsonSafe -Path $runtimePosturePath -Default $null
$environmentProfile = Read-JsonSafe -Path $environmentProfilePath -Default $null
$environmentDrift = Read-JsonSafe -Path $environmentDriftPath -Default $null
$keepalive = Read-JsonSafe -Path $keepalivePath -Default $null
$selfHeal = Read-JsonSafe -Path $selfHealPath -Default $null
$dailyReport = Read-JsonSafe -Path $dailyReportPath -Default $null
$securityPosture = Read-JsonSafe -Path $securityPosturePath -Default $null
$tenantSafety = Read-JsonSafe -Path $tenantSafetyPath -Default $null
$billingSummary = Read-JsonSafe -Path $billingSummaryPath -Default $null
$mirrorUpdate = Read-JsonSafe -Path $mirrorPath -Default $null
$brandExposure = Read-JsonSafe -Path $brandExposurePath -Default $null
$liveDocsSummary = Read-JsonSafe -Path $liveDocsSummaryPath -Default $null
$selfImprovement = Read-JsonSafe -Path $selfImprovementPath -Default $null
$stackPids = Read-JsonSafe -Path $stackPidsPath -Default $null
$startRun = Read-JsonSafe -Path $startRunPath -Default $null

$contractPorts = Get-ContractPorts -RepoRoot $repoRoot
$listenerMap = Get-ListenerMap -Ports @($contractPorts.Values)
$currentLivePids = Get-PropValue -Object $stackPids -Name "current_live_pids" -Default $null
$serviceHealthRows = @()
$healthyServiceCount = 0
$pidDriftServices = @()
$endpointMap = [ordered]@{
    mason_api = "http://127.0.0.1:$($contractPorts.mason_api)/health"
    seed_api = "http://127.0.0.1:$($contractPorts.seed_api)/health"
    bridge = "http://127.0.0.1:$($contractPorts.bridge)/health"
    athena = "http://127.0.0.1:$($contractPorts.athena)/api/health"
    onyx = "http://127.0.0.1:$($contractPorts.onyx)/main.dart.js"
}
foreach ($componentId in @($endpointMap.Keys)) {
    $port = [int]$contractPorts[$componentId]
    $listenerRows = @($listenerMap[$port])
    $probe = Invoke-LoopbackProbe -Url $endpointMap[$componentId]
    $canonicalPid = [int](Get-PropValue -Object $currentLivePids -Name $componentId -Default 0)
    $listenerPids = @($listenerRows | ForEach-Object { [int](Get-PropValue -Object $_ -Name "owning_pid" -Default 0) } | Where-Object { $_ -gt 0 } | Select-Object -Unique)
    $pidAligned = if ($canonicalPid -gt 0) { $listenerPids -contains $canonicalPid } else { $false }
    $status = if ($listenerRows.Count -gt 0 -and [bool]$probe.ok) { "PASS" } elseif ($listenerRows.Count -gt 0 -or [bool]$probe.ok) { "WARN" } else { "FAIL" }
    if ($status -eq "PASS") {
        $healthyServiceCount += 1
    }
    if (-not $pidAligned) {
        $pidDriftServices += $componentId
    }
    $serviceHealthRows += [ordered]@{
        component = $componentId
        port = $port
        listening = ($listenerRows.Count -gt 0)
        listener_count = $listenerRows.Count
        listener_pids = @($listenerPids)
        health_ok = [bool]$probe.ok
        health_status_code = [int](Get-PropValue -Object $probe -Name "status_code" -Default 0)
        health_error = Normalize-Text (Get-PropValue -Object $probe -Name "error" -Default "")
        health_url = $endpointMap[$componentId]
        current_live_pid = $canonicalPid
        current_live_pid_aligned = $pidAligned
        status = $status
    }
}
$unhealthyServiceCount = @($serviceHealthRows | Where-Object { (Normalize-Status -Value (Get-PropValue -Object $_ -Name "status" -Default "UNKNOWN")) -ne "PASS" }).Count
$pidDriftCount = @($pidDriftServices | Select-Object -Unique).Count

$validatorStack = Get-ValidatorSection -ValidatorPayload $validator -SectionName "stack/base"
$validatorSections = @((Get-PropValue -Object $validator -Name "sections" -Default @()))
$validatorComparableSections = @(
    $validatorSections |
        Where-Object {
            (Normalize-Text (Get-PropValue -Object $_ -Name "section_name" -Default "")).ToLowerInvariant() -ne "regression guard / rollback engine"
        }
)
if ($validatorComparableSections.Count -eq 0) {
    $validatorComparableSections = @($validatorSections)
}
$validatorSectionFailCount = @($validatorComparableSections | Where-Object { (Normalize-Status (Get-PropValue -Object $_ -Name "status" -Default "UNKNOWN")) -eq "FAIL" }).Count
$validatorSectionWarnCount = @($validatorComparableSections | Where-Object { (Normalize-Status (Get-PropValue -Object $_ -Name "status" -Default "UNKNOWN")) -eq "WARN" }).Count
$validatorStatus = if ($validatorSectionFailCount -gt 0) { "FAIL" } elseif ($validatorSectionWarnCount -gt 0) { "WARN" } elseif ($validatorComparableSections.Count -gt 0) { "PASS" } else { Normalize-Status (Get-PropValue -Object $validator -Name "overall_status" -Default "UNKNOWN") }
$validatorFailedCount = [int](@($validatorComparableSections | Measure-Object -Property failed_count -Sum).Sum)
$validatorWarnCount = [int](@($validatorComparableSections | Measure-Object -Property warn_count -Sum).Sum)
$validatorPassedCount = [int](@($validatorComparableSections | Measure-Object -Property passed_count -Sum).Sum)

$systemTruthDomains = if ($systemTruth -and (Test-ObjectHasKey -Object $systemTruth -Name "domains")) { Get-PropValue -Object $systemTruth -Name "domains" -Default @{} } else { @{} }
$hostStatus = Normalize-Status (Get-PropValue -Object $hostHealth -Name "overall_status" -Default "UNKNOWN")
$hostThrottle = Normalize-Text (Get-PropValue -Object $hostHealth -Name "throttle_guidance" -Default "")
$environmentStatus = Normalize-Status (Get-PropValue -Object $environmentDrift -Name "overall_status" -Default (Get-PropValue -Object (Get-PropValue -Object $systemTruthDomains -Name "environment" -Default @{}) -Name "status" -Default "UNKNOWN"))
$environmentDriftLevel = Normalize-Text (Get-PropValue -Object $environmentDrift -Name "drift_level" -Default "")
$keepaliveStatus = Normalize-Status (Get-PropValue -Object $keepalive -Name "overall_status" -Default "UNKNOWN")
$securityStatus = Normalize-Status (Get-PropValue -Object $securityPosture -Name "overall_status" -Default "UNKNOWN")
$billingProviderMode = Normalize-Text (Get-PropValue -Object (Get-PropValue -Object $billingSummary -Name "provider" -Default @{}) -Name "mode" -Default "")
$billingStatus = if ($billingProviderMode -eq "stub") { "WARN" } else { Normalize-Status (Get-PropValue -Object $billingSummary -Name "overall_status" -Default "PASS") }
$mirrorOk = [bool](Get-PropValue -Object $mirrorUpdate -Name "ok" -Default $false)
$mirrorPhase = Normalize-Text (Get-PropValue -Object $mirrorUpdate -Name "phase" -Default "")
$mirrorStatus = if ($mirrorOk -and $mirrorPhase -eq "done") { "PASS" } elseif ($mirrorOk -or $mirrorPhase) { "WARN" } else { "FAIL" }
$brandStatus = Normalize-Status (Get-PropValue -Object $brandExposure -Name "overall_status" -Default "UNKNOWN")
$liveDocsStatus = Normalize-Status (Get-PropValue -Object $liveDocsSummary -Name "summary_status" -Default "UNKNOWN")
$selfImprovementStatus = Normalize-Status (Get-PropValue -Object $selfImprovement -Name "overall_status" -Default "UNKNOWN")
$systemTruthStatus = Normalize-Status (Get-PropValue -Object $systemTruth -Name "overall_status" -Default "UNKNOWN")

$currentDomains = [ordered]@{}
$currentDomains["validator"] = New-DomainSnapshot -DomainId "validator" -Status $validatorStatus -Summary ("Validator {0}; failed={1}; warn={2}; passed={3}." -f $validatorStatus, $validatorFailedCount, $validatorWarnCount, $validatorPassedCount) -EvidenceUsed @($validatorPath) -Metrics ([ordered]@{
    failed_count = $validatorFailedCount
    warn_count = $validatorWarnCount
    passed_count = $validatorPassedCount
}) -Details ([ordered]@{
    baseline_tag = Normalize-Text (Get-PropValue -Object $validator -Name "baseline_tag" -Default "")
    raw_overall_status = Normalize-Status (Get-PropValue -Object $validator -Name "overall_status" -Default "UNKNOWN")
    excluded_sections = @("regression guard / rollback engine")
}) -RecommendedNextAction (Normalize-Text (Get-PropValue -Object $validator -Name "recommended_next_action" -Default "")) -LastUpdatedUtc (Convert-ToUtcIso (Get-Item -LiteralPath $validatorPath).LastWriteTimeUtc)

$stackStatus = if ($unhealthyServiceCount -gt 0) { "FAIL" } elseif ($pidDriftCount -gt 0) { "WARN" } else { "PASS" }
$stackSummary = if ($unhealthyServiceCount -gt 0) {
    "Required service health degraded: $unhealthyServiceCount unhealthy service(s)."
}
elseif ($pidDriftCount -gt 0) {
    "All required services are healthy, but runtime truth drift remains for $pidDriftCount service(s)."
}
else {
    "All required services are healthy and singleton/runtime truth is aligned."
}
$currentDomains["stack"] = New-DomainSnapshot -DomainId "stack" -Status $stackStatus -Summary $stackSummary -EvidenceUsed @($validatorPath, $stackPidsPath) -Metrics ([ordered]@{
    service_count = $serviceHealthRows.Count
    healthy_service_count = $healthyServiceCount
    unhealthy_service_count = $unhealthyServiceCount
    pid_drift_count = $pidDriftCount
}) -Details ([ordered]@{
    drifted_services = @($pidDriftServices | Select-Object -Unique)
    stack_validator_status = Normalize-Status (Get-PropValue -Object $validatorStack -Name "status" -Default "")
}) -RecommendedNextAction $(if ($pidDriftCount -gt 0) { "Refresh the normal stack start flow so stack_pids.json matches live runtime truth." } elseif ($unhealthyServiceCount -gt 0) { "Repair the unhealthy loopback service before promotion." } else { "No action required." }) -LastUpdatedUtc (Convert-ToUtcIso (Get-NowUtc))

$runtimeTruthStatus = if ($pidDriftCount -gt 0) { "WARN" } else { "PASS" }
$currentDomains["runtime_truth"] = New-DomainSnapshot -DomainId "runtime_truth" -Status $runtimeTruthStatus -Summary $(if ($pidDriftCount -gt 0) { "current_live_pids drift persists for $pidDriftCount service(s)." } else { "current_live_pids align with live listener ownership." }) -EvidenceUsed @($stackPidsPath) -Metrics ([ordered]@{
    pid_drift_count = $pidDriftCount
    tracked_service_count = $serviceHealthRows.Count
}) -Details ([ordered]@{
    drifted_services = @($pidDriftServices | Select-Object -Unique)
}) -RecommendedNextAction $(if ($pidDriftCount -gt 0) { "Refresh stack_pids current_live_pids using the normal start flow." } else { "No action required." }) -LastUpdatedUtc (Convert-ToUtcIso (Get-Item -LiteralPath $stackPidsPath).LastWriteTimeUtc)

$hostThrottleDisplay = if ($hostThrottle) { $hostThrottle } else { "unknown" }
$currentDomains["host"] = New-DomainSnapshot -DomainId "host" -Status $hostStatus -Summary ("Host posture {0}; throttle={1}." -f $hostStatus, $hostThrottleDisplay) -EvidenceUsed @($hostHealthPath) -Metrics ([ordered]@{
    throttle_guidance = $hostThrottle
}) -Details ([ordered]@{
    recommended_next_action = Normalize-Text (Get-PropValue -Object $hostHealth -Name "recommended_next_action" -Default "")
}) -RecommendedNextAction (Normalize-Text (Get-PropValue -Object $hostHealth -Name "recommended_next_action" -Default "")) -LastUpdatedUtc (Convert-ToUtcIso (Get-Item -LiteralPath $hostHealthPath).LastWriteTimeUtc)

$environmentStatusDisplay = if ($environmentStatus) { $environmentStatus } else { "UNKNOWN" }
$environmentDriftDisplay = if ($environmentDriftLevel) { $environmentDriftLevel } else { "unknown" }
$environmentHostClass = Normalize-Text (Get-PropValue -Object $runtimePosture -Name "host_classification" -Default "")
$currentDomains["environment"] = New-DomainSnapshot -DomainId "environment" -Status $environmentStatus -Summary ("Environment {0}; drift={1}; host_classification={2}." -f $environmentStatusDisplay, $environmentDriftDisplay, $environmentHostClass) -EvidenceUsed @($environmentProfilePath, $environmentDriftPath, $runtimePosturePath) -Metrics ([ordered]@{
    drift_level = $environmentDriftLevel
    throttle_guidance = Normalize-Text (Get-PropValue -Object $runtimePosture -Name "throttle_guidance" -Default "")
}) -Details ([ordered]@{
    environment_id = Normalize-Text (Get-PropValue -Object $environmentProfile -Name "environment_id" -Default "")
    migration_detected = [bool](Get-PropValue -Object $environmentDrift -Name "migration_detected" -Default $false)
}) -RecommendedNextAction (Normalize-Text (Get-PropValue -Object $environmentDrift -Name "recommended_next_action" -Default "")) -LastUpdatedUtc (Convert-ToUtcIso (Get-Item -LiteralPath $environmentDriftPath).LastWriteTimeUtc)

$currentDomains["keepalive_ops"] = New-DomainSnapshot -DomainId "keepalive_ops" -Status $keepaliveStatus -Summary ("KeepAlive {0}; escalated={1}; repairs={2}/{3}; blocked={4}." -f $keepaliveStatus, [int](Get-PropValue -Object $keepalive -Name "escalated_issue_count" -Default 0), [int](Get-PropValue -Object $keepalive -Name "repair_success_count" -Default 0), [int](Get-PropValue -Object $keepalive -Name "repair_attempt_count" -Default 0), [int](Get-PropValue -Object $keepalive -Name "repair_blocked_count" -Default 0)) -EvidenceUsed @($keepalivePath, $selfHealPath, $dailyReportPath) -Metrics ([ordered]@{
    escalated_issue_count = [int](Get-PropValue -Object $keepalive -Name "escalated_issue_count" -Default 0)
    repair_attempt_count = [int](Get-PropValue -Object $keepalive -Name "repair_attempt_count" -Default 0)
    repair_success_count = [int](Get-PropValue -Object $keepalive -Name "repair_success_count" -Default 0)
    repair_blocked_count = [int](Get-PropValue -Object $keepalive -Name "repair_blocked_count" -Default 0)
}) -Details ([ordered]@{
    daily_report_status = Normalize-Status (Get-PropValue -Object $keepalive -Name "daily_report_status" -Default "")
    throttle_guidance = Normalize-Text (Get-PropValue -Object $keepalive -Name "throttle_guidance" -Default "")
}) -RecommendedNextAction (Normalize-Text (Get-PropValue -Object $keepalive -Name "recommended_next_action" -Default "")) -LastUpdatedUtc (Convert-ToUtcIso (Get-Item -LiteralPath $keepalivePath).LastWriteTimeUtc)

$currentDomains["self_improvement"] = New-DomainSnapshot -DomainId "self_improvement" -Status $selfImprovementStatus -Summary ("Self-improvement {0}; teacher_allowed={1}; active_improvements={2}." -f $selfImprovementStatus, [int](Get-PropValue -Object (Get-PropValue -Object $selfImprovement -Name "teacher_call_budget" -Default @{}) -Name "total_allowed" -Default 0), [int](Get-PropValue -Object $selfImprovement -Name "active_improvement_total" -Default 0)) -EvidenceUsed @($selfImprovementPath) -Metrics ([ordered]@{
    active_improvement_total = [int](Get-PropValue -Object $selfImprovement -Name "active_improvement_total" -Default 0)
    safe_to_test_total = [int](Get-PropValue -Object (Get-PropValue -Object $selfImprovement -Name "counts_by_execution_disposition" -Default @{}) -Name "safe_to_test" -Default 0)
}) -Details ([ordered]@{
    budget_posture = Normalize-Text (Get-PropValue -Object (Get-PropValue -Object $selfImprovement -Name "teacher_call_budget" -Default @{}) -Name "current_budget_posture" -Default "")
}) -RecommendedNextAction (Normalize-Text (Get-PropValue -Object $selfImprovement -Name "recommended_next_action" -Default "")) -LastUpdatedUtc (Convert-ToUtcIso (Get-Item -LiteralPath $selfImprovementPath).LastWriteTimeUtc)

$tenantSafetyIssues = [int](Get-PropValue -Object $tenantSafety -Name "issues_total" -Default 0)
$tenantSafetyCritical = [int](Get-PropValue -Object $tenantSafety -Name "critical_issues_total" -Default 0)
$currentDomains["security_posture"] = New-DomainSnapshot -DomainId "security_posture" -Status $securityStatus -Summary ("Security posture {0}; tenant_safety_issues={1}; audit_events={2}." -f $securityStatus, $tenantSafetyIssues, [int](Get-PropValue -Object (Get-PropValue -Object $securityPosture -Name "audit_posture" -Default @{}) -Name "total_events" -Default 0)) -EvidenceUsed @($securityPosturePath, $tenantSafetyPath) -Metrics ([ordered]@{
    tenant_safety_issues_total = $tenantSafetyIssues
    tenant_safety_critical_total = $tenantSafetyCritical
    audit_event_total = [int](Get-PropValue -Object (Get-PropValue -Object $securityPosture -Name "audit_posture" -Default @{}) -Name "total_events" -Default 0)
}) -Details ([ordered]@{
    tenant_isolation_posture = Normalize-Text (Get-PropValue -Object (Get-PropValue -Object $securityPosture -Name "tenant_isolation_posture" -Default @{}) -Name "status" -Default "")
}) -RecommendedNextAction $(if ($tenantSafetyIssues -gt 0) { "Review tenant safety warnings before promoting further self-improvement." } else { "No action required." }) -LastUpdatedUtc (Convert-ToUtcIso (Get-Item -LiteralPath $securityPosturePath).LastWriteTimeUtc)

$enabledTools = @((Get-PropValue -Object (Get-PropValue -Object $billingSummary -Name "tenant" -Default @{}) -Name "enabled_tools" -Default @()))
$billingProviderDisplay = if ($billingProviderMode) { $billingProviderMode } else { "unknown" }
$billingTenantStatus = Normalize-Text (Get-PropValue -Object (Get-PropValue -Object $billingSummary -Name "tenant" -Default @{}) -Name "status" -Default "")
$currentDomains["billing"] = New-DomainSnapshot -DomainId "billing" -Status $billingStatus -Summary ("Billing {0}; provider_mode={1}; enabled_tools={2}; tenant_status={3}." -f $billingStatus, $billingProviderDisplay, $enabledTools.Count, $billingTenantStatus) -EvidenceUsed @($billingSummaryPath) -Metrics ([ordered]@{
    enabled_tool_total = $enabledTools.Count
    subscription_total = [int](Get-PropValue -Object (Get-PropValue -Object $billingSummary -Name "subscription_counts" -Default @{}) -Name "total" -Default 0)
}) -Details ([ordered]@{
    provider_mode = $billingProviderMode
    plan_id = Normalize-Text (Get-PropValue -Object (Get-PropValue -Object $billingSummary -Name "tenant" -Default @{}) -Name "plan_id" -Default "")
}) -RecommendedNextAction $(if ($billingProviderMode -eq "stub") { "Keep billing in stub mode until live money setup is intentionally approved." } else { "No action required." }) -LastUpdatedUtc (Convert-ToUtcIso (Get-Item -LiteralPath $billingSummaryPath).LastWriteTimeUtc)

$mirrorPhaseDisplay = if ($mirrorPhase) { $mirrorPhase } else { "unknown" }
$currentDomains["mirror"] = New-DomainSnapshot -DomainId "mirror" -Status $mirrorStatus -Summary ("Mirror {0}; ok={1}; phase={2}." -f $mirrorStatus, $mirrorOk.ToString().ToLowerInvariant(), $mirrorPhaseDisplay) -EvidenceUsed @($mirrorPath) -Metrics ([ordered]@{
    ok = $mirrorOk
    phase = $mirrorPhase
}) -Details ([ordered]@{
    mirror_push_result = Normalize-Text (Get-PropValue -Object $mirrorUpdate -Name "mirror_push_result" -Default "")
}) -RecommendedNextAction $(if ($mirrorOk) { "No action required." } else { "Review mirror/checkpoint flow before promotion." }) -LastUpdatedUtc (Convert-ToUtcIso (Get-Item -LiteralPath $mirrorPath).LastWriteTimeUtc)

$publicLeakCount = [int](Get-PropValue -Object $brandExposure -Name "public_leak_count" -Default 0)
$currentDomains["brand_exposure"] = New-DomainSnapshot -DomainId "brand_exposure" -Status $brandStatus -Summary ("Brand exposure {0}; public_leaks={1}; scanned={2}." -f $brandStatus, $publicLeakCount, [int](Get-PropValue -Object $brandExposure -Name "total_surfaces_scanned" -Default 0)) -EvidenceUsed @($brandExposurePath) -Metrics ([ordered]@{
    public_leak_count = $publicLeakCount
    surfaces_scanned = [int](Get-PropValue -Object $brandExposure -Name "total_surfaces_scanned" -Default 0)
}) -Details ([ordered]@{
    public_brand_posture = Normalize-Text (Get-PropValue -Object $brandExposure -Name "public_brand_posture" -Default "")
}) -RecommendedNextAction (Normalize-Text (Get-PropValue -Object $brandExposure -Name "recommended_next_action" -Default "")) -LastUpdatedUtc (Convert-ToUtcIso (Get-Item -LiteralPath $brandExposurePath).LastWriteTimeUtc)

$currentDomains["live_docs"] = New-DomainSnapshot -DomainId "live_docs" -Status $liveDocsStatus -Summary ("Live docs {0}; docs_count={1}; stale_docs={2}." -f $liveDocsStatus, [int](Get-PropValue -Object $liveDocsSummary -Name "docs_count" -Default 0), [int](Get-PropValue -Object $liveDocsSummary -Name "stale_docs_count" -Default 0)) -EvidenceUsed @($liveDocsSummaryPath) -Metrics ([ordered]@{
    docs_count = [int](Get-PropValue -Object $liveDocsSummary -Name "docs_count" -Default 0)
    stale_docs_count = [int](Get-PropValue -Object $liveDocsSummary -Name "stale_docs_count" -Default 0)
}) -Details ([ordered]@{
    components_with_warnings = Convert-ToStringArray (Get-PropValue -Object $liveDocsSummary -Name "components_with_warnings" -Default @())
}) -RecommendedNextAction $(if ([int](Get-PropValue -Object $liveDocsSummary -Name "stale_docs_count" -Default 0) -gt 0) { "Regenerate stale live docs before promotion." } else { "No action required." }) -LastUpdatedUtc (Convert-ToUtcIso (Get-Item -LiteralPath $liveDocsSummaryPath).LastWriteTimeUtc)

$currentDomains["system_truth"] = New-DomainSnapshot -DomainId "system_truth" -Status $systemTruthStatus -Summary ("System truth {0}; warning_domains={1}; failing_domains={2}." -f $systemTruthStatus, [int](Get-PropValue -Object (Get-PropValue -Object $systemTruth -Name "summary" -Default @{}) -Name "warning_domain_count" -Default 0), [int](Get-PropValue -Object (Get-PropValue -Object $systemTruth -Name "summary" -Default @{}) -Name "failing_domain_count" -Default 0)) -EvidenceUsed @($systemTruthPath, $systemMetricsPath) -Metrics ([ordered]@{
    warning_domain_count = [int](Get-PropValue -Object (Get-PropValue -Object $systemTruth -Name "summary" -Default @{}) -Name "warning_domain_count" -Default 0)
    failing_domain_count = [int](Get-PropValue -Object (Get-PropValue -Object $systemTruth -Name "summary" -Default @{}) -Name "failing_domain_count" -Default 0)
    available_domain_count = [int](Get-PropValue -Object (Get-PropValue -Object $systemTruth -Name "summary" -Default @{}) -Name "available_domain_count" -Default 0)
}) -Details ([ordered]@{
    top_warning_domains = Convert-ToStringArray (Get-PropValue -Object (Get-PropValue -Object $systemTruth -Name "summary" -Default @{}) -Name "top_warning_domains" -Default @())
}) -RecommendedNextAction (Normalize-Text (Get-PropValue -Object $systemTruth -Name "recommended_next_action" -Default "")) -LastUpdatedUtc (Convert-ToUtcIso (Get-Item -LiteralPath $systemTruthPath).LastWriteTimeUtc)

$currentOverallStatus = Normalize-Status (Get-PropValue -Object $systemTruth -Name "overall_status" -Default (Get-PropValue -Object $validator -Name "overall_status" -Default "UNKNOWN"))
$currentBaselineTag = Normalize-Text (Get-PropValue -Object $systemTruth -Name "baseline_tag" -Default "")
if (-not $currentBaselineTag) {
    $currentBaselineTag = Normalize-Text (Get-PropValue -Object $validator -Name "baseline_tag" -Default "")
}
$currentSnapshot = [ordered]@{
    captured_at_utc = Convert-ToUtcIso (Get-NowUtc)
    overall_status = $currentOverallStatus
    baseline_tag = $currentBaselineTag
    domains = $currentDomains
    system_truth_artifact = $systemTruth
    validator_artifact = $validator
    system_truth_path = $systemTruthPath
    validator_path = $validatorPath
    keepalive_path = $keepalivePath
    host_path = $hostHealthPath
    billing_path = $billingSummaryPath
    security_path = $securityPosturePath
    mirror_path = $mirrorPath
}

$registry = Get-BaselineRegistry -Path $regressionBaselinesPath
$comparisonSelection = Select-ComparisonBaseline -Registry $registry -Policy $policy
$comparisonBaseline = Get-PropValue -Object $comparisonSelection -Name "baseline" -Default $null
$comparisonMode = Normalize-Text (Get-PropValue -Object $comparisonSelection -Name "comparison_mode" -Default "baseline_missing")
$trustedBaselineAvailable = [bool](Get-PropValue -Object $comparisonSelection -Name "trusted" -Default $false)

$seededBaselineThisRun = $false
if (-not $comparisonBaseline -and [bool](Get-PropValue -Object (Get-PropValue -Object $policy -Name "missing_baseline_handling" -Default @{}) -Name "seed_initial_baseline" -Default $true)) {
    $newBaseline = New-BaselineRecord -CurrentSnapshot $currentSnapshot -BaselineKind "seed"
    $existingBaselines = @((Get-PropValue -Object $registry -Name "baselines" -Default @()))
    $registry.baselines = @($existingBaselines) + @($newBaseline)
    $registry.current_active_baseline_id = $newBaseline.baseline_id
    $registry.current_trusted_baseline_id = Normalize-Text (Get-PropValue -Object $registry -Name "current_trusted_baseline_id" -Default "")
    $seededBaselineThisRun = $true
    $comparisonSelection = Select-ComparisonBaseline -Registry $registry -Policy $policy
    $comparisonBaseline = Get-PropValue -Object $comparisonSelection -Name "baseline" -Default $null
    $comparisonMode = Normalize-Text (Get-PropValue -Object $comparisonSelection -Name "comparison_mode" -Default "baseline_missing")
    $trustedBaselineAvailable = [bool](Get-PropValue -Object $comparisonSelection -Name "trusted" -Default $false)
}

$domainIds = Convert-ToStringArray (Get-PropValue -Object $policy -Name "comparison_domains" -Default @())
$comparisonRecords = @()
foreach ($domainId in $domainIds) {
    $currentDomain = if ($currentDomains.Contains($domainId)) { $currentDomains[$domainId] } else { $null }
    $priorDomainSnapshots = if ($comparisonBaseline) { Get-PropValue -Object $comparisonBaseline -Name "domain_snapshots" -Default @{} } else { @{} }
    $priorDomain = if ($priorDomainSnapshots -and (Test-ObjectHasKey -Object $priorDomainSnapshots -Name $domainId)) { Get-PropValue -Object $priorDomainSnapshots -Name $domainId -Default $null } else { $null }
    $comparisonRecords += @(Compare-DomainSnapshot -DomainId $domainId -PriorSnapshot $priorDomain -CurrentSnapshot $currentDomain -Policy $policy)
}

$worsenedRecords = @($comparisonRecords | Where-Object { (Normalize-Text (Get-PropValue -Object $_ -Name "classification" -Default "")) -eq "worsened" })
$warningRegressions = @($worsenedRecords | Where-Object { (Get-SeverityRank -Value (Get-PropValue -Object $_ -Name "severity" -Default "")) -le 2 })
$blockingRegressions = @($worsenedRecords | Where-Object { [bool](Get-PropValue -Object $_ -Name "blocks_promotion" -Default $false) })
$rollbackRegressions = @($worsenedRecords | Where-Object { [bool](Get-PropValue -Object $_ -Name "suggests_rollback" -Default $false) })
$improvedRecords = @($comparisonRecords | Where-Object { (Normalize-Text (Get-PropValue -Object $_ -Name "classification" -Default "")) -eq "improved" })
$unchangedRecords = @($comparisonRecords | Where-Object { (Normalize-Text (Get-PropValue -Object $_ -Name "classification" -Default "")) -eq "unchanged" })

$baselineAgeHours = if ($comparisonBaseline) { Get-AgeHours -Timestamp (Get-PropValue -Object $comparisonBaseline -Name "created_at_utc" -Default "") } else { [double]::PositiveInfinity }
$baselineStaleHoursLimit = [double](Get-PropValue -Object (Get-PropValue -Object $policy -Name "stale_baseline_handling" -Default @{}) -Name "max_age_hours" -Default 168)
$baselineStale = ($baselineAgeHours -gt $baselineStaleHoursLimit)

$baselineAvailable = $null -ne $comparisonBaseline
if (-not $baselineAvailable) {
    $comparisonResult = if ($seededBaselineThisRun) { "baseline_seeded_not_comparable" } else { "baseline_missing" }
}
elseif ($seededBaselineThisRun) {
    $comparisonResult = "baseline_seeded_not_comparable"
}
elseif ($worsenedRecords.Count -gt 0) {
    $comparisonResult = if ($blockingRegressions.Count -gt 0) { "worse_than_baseline" } else { "warning_regressions_detected" }
}
elseif ($improvedRecords.Count -gt 0) {
    $comparisonResult = if ($comparisonMode -eq "trusted") { "equal_or_better_than_baseline" } else { "seed_baseline_equal_or_better" }
}
else {
    $comparisonResult = if ($comparisonMode -eq "trusted") { "no_material_change" } else { "seed_baseline_no_material_change" }
}

$rollbackRecommended = ($rollbackRegressions.Count -gt 0)
$promotionBlockedReasons = @()
if (-not $trustedBaselineAvailable) {
    $promotionBlockedReasons += "trusted_baseline_missing"
}
if ($baselineStale -and [bool](Get-PropValue -Object (Get-PropValue -Object $policy -Name "promotion_blocking_rules" -Default @{}) -Name "block_on_stale_baseline" -Default $true)) {
    $promotionBlockedReasons += "baseline_stale"
}
foreach ($record in $blockingRegressions) {
    $promotionBlockedReasons += ("regression:{0}:{1}" -f (Get-PropValue -Object $record -Name "domain_id" -Default ""), (Get-PropValue -Object $record -Name "severity" -Default ""))
}
if ($rollbackRecommended) {
    $promotionBlockedReasons += "rollback_recommended"
}
if ($publicLeakCount -gt 0) {
    $promotionBlockedReasons += "public_brand_leak_present"
}
$promotionBlockedReasons = @($promotionBlockedReasons | Where-Object { Normalize-Text $_ } | Select-Object -Unique)
$promotionAllowed = ($promotionBlockedReasons.Count -eq 0)
$allowedWithWarnings = ($promotionAllowed -and (($warningRegressions.Count -gt 0) -or ($currentOverallStatus -eq "WARN")))

$overallStatus = "PASS"
if ($blockingRegressions.Count -gt 0 -and $rollbackRecommended) {
    $overallStatus = "FAIL"
}
elseif ($blockingRegressions.Count -gt 0 -or $warningRegressions.Count -gt 0 -or -not $trustedBaselineAvailable -or $baselineStale) {
    $overallStatus = "WARN"
}

$recommendedNextAction = if ($rollbackRecommended) {
    "Block promotion and review the rollback plan before making further changes."
}
elseif ($promotionBlockedReasons -contains "trusted_baseline_missing") {
    "Review the seeded baseline and explicitly promote a trusted baseline before allowing promotion."
}
elseif ($blockingRegressions.Count -gt 0) {
    "Review blocking regression evidence and do not promote until the degraded domains recover."
}
elseif ($warningRegressions.Count -gt 0) {
    "Review the warning regressions before promoting further self-improvement."
}
else {
    "No regression action required."
}

$rollbackScope = @($rollbackRegressions | ForEach-Object { Normalize-Text (Get-PropValue -Object $_ -Name "domain_id" -Default "") } | Where-Object { $_ } | Select-Object -Unique)
$artifactsToReview = @(
    $regressionGuardPath,
    $systemTruthPath,
    $validatorPath,
    $keepalivePath,
    $mirrorPath,
    $stackPidsPath,
    $startRunPath
) | Select-Object -Unique

$safeRollbackSteps = @()
if ($rollbackRecommended) {
    $safeRollbackSteps += [ordered]@{
        step = "Freeze promotion and self-improvement staging for the impacted domains."
        reason = "Blocking regressions were detected against the comparison baseline."
        source_path = $regressionGuardPath
    }
    $safeRollbackSteps += [ordered]@{
        step = "Review the baseline record and current truth spine side by side before changing files or services."
        reason = "Rollback should be evidence-led, not a blind repo revert."
        source_path = $regressionBaselinesPath
    }
    $safeRollbackSteps += [ordered]@{
        step = "If the regression is runtime-only, use the existing loopback-safe start/reset flow rather than destructive cleanup."
        reason = "Runtime truth drift and service degradation should be repaired through governed ops paths."
        source_path = $startRunPath
    }
    $safeRollbackSteps += [ordered]@{
        step = "If the regression is source/config related, review the latest mirror checkpoint and compare the affected artifacts before any manual revert."
        reason = "The mirror is the safest rollback reference available in the current baseline."
        source_path = $mirrorPath
    }
}
else {
    $safeRollbackSteps += [ordered]@{
        step = "No rollback execution is recommended."
        reason = "No blocking regression currently justifies a rollback."
        source_path = $regressionGuardPath
    }
}

$blockedRollbackReasons = @()
if (-not $rollbackRecommended) {
    $blockedRollbackReasons += "no_material_regression_detected"
}
if (-not $trustedBaselineAvailable) {
    $blockedRollbackReasons += "trusted_baseline_missing"
}

$rollbackReason = if ($rollbackRecommended) {
    "Blocking regressions suggest rollback review for: $(@($rollbackScope) -join ', ')."
}
else {
    "No current regression justifies rollback."
}

$rollbackPlan = [ordered]@{
    timestamp_utc = Convert-ToUtcIso (Get-NowUtc)
    rollback_recommended = $rollbackRecommended
    rollback_scope = @($rollbackScope)
    rollback_reason = $rollbackReason
    safe_rollback_steps = @($safeRollbackSteps)
    artifacts_to_review = @($artifactsToReview)
    preconditions = @(
        "Confirm the comparison baseline before manual rollback.",
        "Keep rollback loopback-safe and non-destructive until evidence justifies stronger action.",
        "Review mirror/checkpoint status before changing source or runtime state."
    )
    blocked_rollback_reasons = @($blockedRollbackReasons | Select-Object -Unique)
    owner_action_required = ($rollbackRecommended -or -not $trustedBaselineAvailable)
    baseline_reference = [ordered]@{
        baseline_id = Normalize-Text (Get-PropValue -Object $comparisonBaseline -Name "baseline_id" -Default "")
        comparison_mode = $comparisonMode
        trusted = $trustedBaselineAvailable
    }
}

$promotionGate = [ordered]@{
    timestamp_utc = Convert-ToUtcIso (Get-NowUtc)
    promotion_allowed = $promotionAllowed
    promotion_blocked = (-not $promotionAllowed)
    blocking_reasons = @($promotionBlockedReasons)
    allowed_with_warnings = $allowedWithWarnings
    gating_domains = @((@($blockingRegressions | ForEach-Object { Normalize-Text (Get-PropValue -Object $_ -Name "domain_id" -Default "") }) + @($warningRegressions | ForEach-Object { Normalize-Text (Get-PropValue -Object $_ -Name "domain_id" -Default "") })) | Where-Object { $_ } | Select-Object -Unique)
    baseline_reference = [ordered]@{
        baseline_id = Normalize-Text (Get-PropValue -Object $comparisonBaseline -Name "baseline_id" -Default "")
        baseline_tag = Normalize-Text (Get-PropValue -Object $comparisonBaseline -Name "baseline_tag" -Default "")
        comparison_mode = $comparisonMode
        baseline_available = $baselineAvailable
        trusted = $trustedBaselineAvailable
        stale = $baselineStale
    }
    recommended_next_action = $recommendedNextAction
}

$regressionGuard = [ordered]@{
    timestamp_utc = Convert-ToUtcIso (Get-NowUtc)
    overall_status = $overallStatus
    baseline_id = Normalize-Text (Get-PropValue -Object $comparisonBaseline -Name "baseline_id" -Default "")
    baseline_available = $baselineAvailable
    baseline_trusted = $trustedBaselineAvailable
    comparison_mode = $comparisonMode
    comparison_result = $comparisonResult
    regression_count = $worsenedRecords.Count
    blocking_regression_count = $blockingRegressions.Count
    warning_regression_count = $warningRegressions.Count
    improved_domain_count = $improvedRecords.Count
    unchanged_domain_count = $unchangedRecords.Count
    worsened_domain_count = $worsenedRecords.Count
    recommended_next_action = $recommendedNextAction
    rollback_recommended = $rollbackRecommended
    promotion_allowed = $promotionAllowed
    command_run = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Regression_Guard.ps1"
    repo_root = $repoRoot
    baseline_stale = $baselineStale
    comparison_records = @($comparisonRecords)
    source_artifacts = @(
        $systemTruthPath,
        $systemMetricsPath,
        $validatorPath,
        $hostHealthPath,
        $runtimePosturePath,
        $environmentProfilePath,
        $environmentDriftPath,
        $keepalivePath,
        $selfImprovementPath,
        $securityPosturePath,
        $tenantSafetyPath,
        $billingSummaryPath,
        $mirrorPath,
        $brandExposurePath,
        $liveDocsSummaryPath
    ) | Select-Object -Unique
    promotion_gate_path = $promotionGatePath
    rollback_plan_path = $rollbackPlanPath
    policy_path = $regressionPolicyPath
    baseline_registry_path = $regressionBaselinesPath
}

$registry.last_run_timestamp_utc = Convert-ToUtcIso (Get-NowUtc)
$registry.last_comparison_result = $comparisonResult
$registry.current_active_baseline_id = Normalize-Text (Get-PropValue -Object $comparisonBaseline -Name "baseline_id" -Default "")
if (-not $registry.current_active_baseline_id) {
    $registry.current_active_baseline_id = Normalize-Text (Get-PropValue -Object $registry -Name "current_active_baseline_id" -Default "")
}
$registry.history = @((Get-PropValue -Object $registry -Name "history" -Default @())) + @([ordered]@{
    timestamp_utc = Convert-ToUtcIso (Get-NowUtc)
    comparison_result = $comparisonResult
    overall_status = $overallStatus
    baseline_id = Normalize-Text (Get-PropValue -Object $comparisonBaseline -Name "baseline_id" -Default "")
    regression_count = $worsenedRecords.Count
    promotion_allowed = $promotionAllowed
})
$registry.history = @($registry.history | Select-Object -Last 20)

Write-JsonFile -Path $regressionBaselinesPath -Object $registry
Write-JsonFile -Path $rollbackPlanPath -Object $rollbackPlan
Write-JsonFile -Path $promotionGatePath -Object $promotionGate
Write-JsonFile -Path $regressionGuardPath -Object $regressionGuard

$regressionGuard
