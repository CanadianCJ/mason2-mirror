[CmdletBinding()]
param(
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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
        [int]$Depth = 18
    )

    Ensure-Parent -Path $Path
    $Object | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
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

function Get-RepoRoot {
    param([string]$OverrideRoot)

    if ($OverrideRoot -and (Test-Path -LiteralPath $OverrideRoot)) {
        return (Resolve-Path -LiteralPath $OverrideRoot).Path
    }

    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

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
    param([datetime]$DateTimeValue)
    return $DateTimeValue.ToUniversalTime().ToString("o")
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

function Get-AgeMinutes {
    param($Timestamp)

    $parsed = Parse-DateSafe -Value $Timestamp
    if ($null -eq $parsed) {
        return [double]::PositiveInfinity
    }

    return [math]::Round(((Get-NowUtc) - $parsed.UtcDateTime).TotalMinutes, 2)
}

function Get-RelativePathSafe {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$FullPath
    )

    try {
        $baseResolved = (Resolve-Path -LiteralPath $BasePath -ErrorAction Stop).Path.TrimEnd([char[]]@([char]'\'))
        $fullResolved = (Resolve-Path -LiteralPath $FullPath -ErrorAction Stop).Path
        if ($fullResolved.StartsWith($baseResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $fullResolved.Substring($baseResolved.Length).TrimStart([char[]]@([char]'\', [char]'/'))
        }
    }
    catch {
    }

    return $FullPath
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
    $aliasToCanonical = @{
        mason = "mason_api"
        masonapi = "mason_api"
        mason_api = "mason_api"
        seed = "seed_api"
        seedapi = "seed_api"
        seed_api = "seed_api"
        bridge = "bridge"
        athena = "athena"
        onyx = "onyx"
    }

    $portsCfg = Read-JsonSafe -Path (Join-Path $RepoRoot "config\ports.json") -Default $null
    $portsSource = Get-PropValue -Object $portsCfg -Name "ports" -Default $null
    if (-not $portsSource) {
        return $defaults
    }

    foreach ($property in @($portsSource.PSObject.Properties)) {
        $normalizedName = [regex]::Replace(([string]$property.Name).ToLowerInvariant().Replace("-", "_"), "[^a-z0-9_]", "")
        if (-not $aliasToCanonical.ContainsKey($normalizedName)) {
            continue
        }

        $parsed = 0
        if ([int]::TryParse([string]$property.Value, [ref]$parsed) -and $parsed -gt 0 -and $parsed -le 65535) {
            $defaults[[string]$aliasToCanonical[$normalizedName]] = [int]$parsed
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
            $port = [int]$row.LocalPort
            if (-not $portSet.Contains($port)) {
                continue
            }
            $rows += [pscustomobject]@{
                local_port    = $port
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
        return [pscustomobject]@{
            ok             = ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400)
            status_code    = [int]$response.StatusCode
            error          = ""
            checked_at_utc = Convert-ToUtcIso (Get-NowUtc)
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

        return [pscustomobject]@{
            ok             = $false
            status_code    = $statusCode
            error          = $_.Exception.Message
            checked_at_utc = Convert-ToUtcIso (Get-NowUtc)
        }
    }
}

function Get-CurrentLivePidMap {
    param([Parameter(Mandatory = $true)][string]$Path)

    $result = @{}
    $payload = Read-JsonSafe -Path $Path -Default $null
    if (-not $payload) {
        return $result
    }

    $current = Get-PropValue -Object $payload -Name "current_live_pids" -Default $null
    if (-not $current) {
        return $result
    }

    foreach ($property in @($current.PSObject.Properties)) {
        $parsedPid = 0
        if ([int]::TryParse([string]$property.Value, [ref]$parsedPid) -and $parsedPid -gt 0) {
            $result[[string]$property.Name] = [int]$parsedPid
        }
    }

    return $result
}

function Convert-ToMutableMap {
    param($Object)

    $result = [ordered]@{}
    if ($null -eq $Object) {
        return $result
    }

    if ($Object -is [System.Collections.IDictionary]) {
        foreach ($key in @($Object.Keys)) {
            $result[[string]$key] = $Object[$key]
        }
        return $result
    }

    foreach ($property in @($Object.PSObject.Properties)) {
        $result[[string]$property.Name] = $property.Value
    }
    return $result
}

function Get-CanonicalKeepAlivePolicy {
    param(
        [Parameter(Mandatory = $true)][string]$PolicyPath,
        [Parameter(Mandatory = $true)][string]$RepoRoot
    )

    $current = Read-JsonSafe -Path $PolicyPath -Default $null
    $required = @(
        "policy_name",
        "policy_posture",
        "allowed_low_risk_repair_actions",
        "blocked_action_classes",
        "retry_policy",
        "escalation_thresholds",
        "daily_report_policy",
        "service_scope",
        "truth_source_precedence",
        "restart_suppression_rules",
        "duplicate_repair_suppression",
        "owner_escalation_guidance"
    )

    $isValid = $true
    if (-not $current) {
        $isValid = $false
    }
    else {
        foreach ($key in $required) {
            if (-not (Test-ObjectHasKey -Object $current -Name $key)) {
                $isValid = $false
                break
            }
        }
    }

    if (-not $isValid) {
        throw "keepalive_policy.json is missing required canonical keys."
    }

    return $current
}

function Get-ActionConfig {
    param(
        [Parameter(Mandatory = $true)]$Policy,
        [Parameter(Mandatory = $true)][string]$ActionId
    )

    foreach ($action in @($Policy.allowed_low_risk_repair_actions)) {
        if ((Normalize-Text (Get-PropValue -Object $action -Name "action_id" -Default "")).ToLowerInvariant() -eq $ActionId.ToLowerInvariant()) {
            return $action
        }
    }

    return $null
}

function Get-IssueState {
    param(
        $State,
        [Parameter(Mandatory = $true)][string]$IssueId
    )

    $issues = Get-PropValue -Object $State -Name "issues" -Default $null
    if (-not $issues) {
        return $null
    }

    if ($issues -is [System.Collections.IDictionary] -and $issues.Contains($IssueId)) {
        return $issues[$IssueId]
    }

    $property = $issues.PSObject.Properties[$IssueId]
    if ($null -ne $property) {
        return $property.Value
    }

    return $null
}

function Get-ComponentState {
    param(
        $State,
        [Parameter(Mandatory = $true)][string]$Component
    )

    $components = Get-PropValue -Object $State -Name "components" -Default $null
    if (-not $components) {
        return $null
    }

    if ($components -is [System.Collections.IDictionary] -and $components.Contains($Component)) {
        return $components[$Component]
    }

    $property = $components.PSObject.Properties[$Component]
    if ($null -ne $property) {
        return $property.Value
    }

    return $null
}

function Get-CooldownStatus {
    param(
        $IssueState,
        $ComponentState
    )

    $now = Get-NowUtc
    $issueCooldownUntil = Parse-DateSafe -Value (Get-PropValue -Object $IssueState -Name "cooldown_until_utc" -Default "")
    if ($issueCooldownUntil -and $issueCooldownUntil.UtcDateTime -gt $now) {
        return [ordered]@{
            active = $true
            reason = "issue_cooldown"
            until_utc = Convert-ToUtcIso $issueCooldownUntil.UtcDateTime
        }
    }

    $componentCooldownUntil = Parse-DateSafe -Value (Get-PropValue -Object $ComponentState -Name "restart_cooldown_until_utc" -Default "")
    if ($componentCooldownUntil -and $componentCooldownUntil.UtcDateTime -gt $now) {
        return [ordered]@{
            active = $true
            reason = "component_restart_cooldown"
            until_utc = Convert-ToUtcIso $componentCooldownUntil.UtcDateTime
        }
    }

    return [ordered]@{
        active = $false
        reason = ""
        until_utc = ""
    }
}

function Get-IssueAttemptCountInWindow {
    param($IssueState)

    $windowStart = Parse-DateSafe -Value (Get-PropValue -Object $IssueState -Name "window_started_utc" -Default "")
    $attemptCount = [int](Get-PropValue -Object $IssueState -Name "attempt_count_in_window" -Default 0)
    if ($null -eq $windowStart) {
        return 0
    }

    if (((Get-NowUtc) - $windowStart.UtcDateTime).TotalHours -gt 24) {
        return 0
    }

    return $attemptCount
}

function Get-RepairDecision {
    param(
        [Parameter(Mandatory = $true)]$Issue,
        [Parameter(Mandatory = $true)]$Policy,
        $IssueState,
        $ComponentState,
        [hashtable]$AttemptedIssuesThisRun,
        [hashtable]$AttemptedActionsThisRun
    )

    $decision = [ordered]@{
        policy_decision = "blocked_by_policy"
        action_id = Normalize-Text (Get-PropValue -Object $Issue -Name "action_id" -Default "")
        action_attempted_or_blocked = "blocked_by_policy"
        cooldown_status = Get-CooldownStatus -IssueState $IssueState -ComponentState $ComponentState
        escalation_decision = "escalate"
        reason = ""
    }

    if (-not [bool](Get-PropValue -Object $Issue -Name "repair_allowed" -Default $false)) {
        $decision.reason = Normalize-Text (Get-PropValue -Object $Issue -Name "blocked_reason" -Default "Repair is blocked by policy.")
        return $decision
    }

    if (-not $decision.action_id) {
        $decision.reason = "No allowed repair action is mapped to this issue."
        return $decision
    }

    if ($AttemptedIssuesThisRun.ContainsKey([string](Get-PropValue -Object $Issue -Name "issue_id" -Default ""))) {
        $decision.policy_decision = "suppressed_duplicate_issue"
        $decision.action_attempted_or_blocked = "suppressed_duplicate_issue"
        $decision.reason = "Duplicate repair suppression is active for this issue in the current run."
        return $decision
    }

    if ($AttemptedActionsThisRun.ContainsKey($decision.action_id)) {
        $decision.policy_decision = "suppressed_duplicate_action"
        $decision.action_attempted_or_blocked = "suppressed_duplicate_action"
        $decision.reason = "Only one action per run is allowed for this repair action."
        return $decision
    }

    if ([bool]$decision.cooldown_status.active) {
        $decision.policy_decision = "suppressed_by_cooldown"
        $decision.action_attempted_or_blocked = "suppressed_by_cooldown"
        $decision.reason = "Cooldown is active for this issue/component."
        return $decision
    }

    $maxAttempts = [int](Get-PropValue -Object (Get-PropValue -Object $Policy -Name "retry_policy" -Default $null) -Name "max_attempts_per_issue_per_24h" -Default 2)
    $attemptsInWindow = Get-IssueAttemptCountInWindow -IssueState $IssueState
    if ($attemptsInWindow -ge $maxAttempts) {
        $decision.policy_decision = "suppressed_retry_limit"
        $decision.action_attempted_or_blocked = "suppressed_retry_limit"
        $decision.reason = "Per-issue retry limit has already been reached in the last 24 hours."
        return $decision
    }

    $decision.policy_decision = "allowed_repair"
    $decision.action_attempted_or_blocked = "not_attempted_yet"
    $decision.escalation_decision = "hold_until_result"
    $decision.reason = "Live evidence supports a single low-risk repair attempt."
    return $decision
}

function Get-ServiceHealthUrl {
    param(
        [Parameter(Mandatory = $true)]$ServiceDef,
        [Parameter(Mandatory = $true)][int]$Port
    )

    $healthPath = Normalize-Text (Get-PropValue -Object $ServiceDef -Name "health_path" -Default "/health")
    if (-not $healthPath.StartsWith("/")) {
        $healthPath = "/$healthPath"
    }
    return "http://127.0.0.1:{0}{1}" -f $Port, $healthPath
}

function Get-ServiceEvaluation {
    param(
        [Parameter(Mandatory = $true)]$ServiceDef,
        [Parameter(Mandatory = $true)][int]$Port,
        [Parameter(Mandatory = $true)][hashtable]$ListenerMap,
        [Parameter(Mandatory = $true)][hashtable]$CurrentLivePidMap
    )

    $component = Normalize-Text (Get-PropValue -Object $ServiceDef -Name "component" -Default "")
    $displayName = Normalize-Text (Get-PropValue -Object $ServiceDef -Name "display_name" -Default $component)
    $healthUrl = Get-ServiceHealthUrl -ServiceDef $ServiceDef -Port $Port
    $probe = Invoke-LoopbackProbe -Url $healthUrl
    $listeners = @()
    if ($ListenerMap.ContainsKey($Port)) {
        $listeners = @($ListenerMap[$Port])
    }
    $listenerPids = @($listeners | ForEach-Object { [int]$_.owning_pid } | Sort-Object -Unique)
    $currentLivePid = $null
    if ($CurrentLivePidMap.ContainsKey($component)) {
        $currentLivePid = [int]$CurrentLivePidMap[$component]
    }
    $pidTruthAligned = $true
    if ($listenerPids.Count -gt 0 -and $null -ne $currentLivePid) {
        $pidTruthAligned = ($listenerPids -contains [int]$currentLivePid)
    }

    $status = "PASS"
    if ($listenerPids.Count -eq 0 -or -not [bool]$probe.ok) {
        $status = "FAIL"
    }

    return [ordered]@{
        component = $component
        display_name = $displayName
        port = [int]$Port
        listening = ($listenerPids.Count -gt 0)
        listener_count = $listenerPids.Count
        listener_pids = @($listenerPids)
        health_ok = [bool]$probe.ok
        health_status_code = [int]$probe.status_code
        health_error = Normalize-Text $probe.error
        health_url = $healthUrl
        current_live_pid = $currentLivePid
        current_live_pid_aligned = [bool]$pidTruthAligned
        status = $status
    }
}

function Wait-For-ComponentsHealthy {
    param(
        [Parameter(Mandatory = $true)][object[]]$ServiceDefs,
        [Parameter(Mandatory = $true)][hashtable]$PortsByComponent,
        [int]$TimeoutSeconds = 120
    )

    $deadline = (Get-NowUtc).AddSeconds($TimeoutSeconds)
    do {
        $allHealthy = $true
        $observed = @()
        foreach ($serviceDef in @($ServiceDefs)) {
            $component = Normalize-Text (Get-PropValue -Object $serviceDef -Name "component" -Default "")
            if (-not $PortsByComponent.ContainsKey($component)) {
                $allHealthy = $false
                continue
            }

            $port = [int]$PortsByComponent[$component]
            $listenerMap = Get-ListenerMap -Ports @($port)
            $currentLive = @{}
            $evaluation = Get-ServiceEvaluation -ServiceDef $serviceDef -Port $port -ListenerMap $listenerMap -CurrentLivePidMap $currentLive
            $observed += $evaluation
            if (-not [bool]$evaluation.listening -or -not [bool]$evaluation.health_ok) {
                $allHealthy = $false
            }
        }

        if ($allHealthy) {
            return [ordered]@{
                success = $true
                observations = @($observed)
            }
        }

        Start-Sleep -Seconds 5
    } while ((Get-NowUtc) -lt $deadline)

    return [ordered]@{
        success = $false
        observations = @($observed)
    }
}

function Invoke-PolicyAction {
    param(
        [Parameter(Mandatory = $true)]$ActionConfig,
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][object[]]$ServiceDefs,
        [Parameter(Mandatory = $true)][hashtable]$PortsByComponent
    )

    if (-not $ActionConfig) {
        return [ordered]@{
            success = $false
            launch_mode = "inline"
            exit_code = 1
            detail = "Missing action configuration."
            script_path = ""
            started_process_id = $null
            observations = @()
        }
    }

    $actionId = Normalize-Text (Get-PropValue -Object $ActionConfig -Name "action_id" -Default "")
    $relativeScriptPath = Normalize-Text (Get-PropValue -Object $ActionConfig -Name "relative_script_path" -Default "")
    $launchMode = Normalize-Text (Get-PropValue -Object $ActionConfig -Name "launch_mode" -Default "inline")
    $scriptPath = Join-Path $RepoRoot $relativeScriptPath
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        return [ordered]@{
            success = $false
            launch_mode = $launchMode
            exit_code = 1
            detail = "Missing action script: $scriptPath"
            script_path = $scriptPath
            started_process_id = $null
            observations = @()
        }
    }

    $args = New-Object System.Collections.Generic.List[string]
    [void]$args.Add("-NoLogo")
    [void]$args.Add("-NoProfile")
    [void]$args.Add("-ExecutionPolicy")
    [void]$args.Add("Bypass")
    [void]$args.Add("-File")
    [void]$args.Add($scriptPath)

    switch ($actionId) {
        "restart_bridge" {
            [void]$args.Add("-RootPath")
            [void]$args.Add($RepoRoot)
        }
        "restart_athena" {
            [void]$args.Add("-RootPath")
            [void]$args.Add($RepoRoot)
        }
        "refresh_validator" {
            [void]$args.Add("-RootPath")
            [void]$args.Add($RepoRoot)
        }
        "refresh_host_guardian" {
            [void]$args.Add("-RootPath")
            [void]$args.Add($RepoRoot)
        }
        "refresh_environment_adaptation" {
            [void]$args.Add("-RootPath")
            [void]$args.Add($RepoRoot)
        }
        default {
        }
    }

    if ($launchMode -eq "background") {
        try {
            $proc = Start-Process -FilePath "powershell.exe" -ArgumentList $args.ToArray() -WorkingDirectory (Split-Path -Parent $scriptPath) -WindowStyle Minimized -PassThru
            $waitResult = Wait-For-ComponentsHealthy -ServiceDefs $ServiceDefs -PortsByComponent $PortsByComponent -TimeoutSeconds 120
            return [ordered]@{
                success = [bool]$waitResult.success
                launch_mode = $launchMode
                exit_code = $null
                detail = if ($waitResult.success) { "Service health recovered after background action." } else { "Background action did not restore component health before timeout." }
                script_path = $scriptPath
                started_process_id = if ($proc) { [int]$proc.Id } else { $null }
                observations = @($waitResult.observations)
            }
        }
        catch {
            return [ordered]@{
                success = $false
                launch_mode = $launchMode
                exit_code = 1
                detail = $_.Exception.Message
                script_path = $scriptPath
                started_process_id = $null
                observations = @()
            }
        }
    }

    try {
        $proc = Start-Process -FilePath "powershell.exe" -ArgumentList $args.ToArray() -WorkingDirectory (Split-Path -Parent $scriptPath) -WindowStyle Hidden -Wait -PassThru
        $exitCode = 0
        if ($proc) {
            $exitCode = [int]$proc.ExitCode
        }

        return [ordered]@{
            success = ($exitCode -eq 0)
            launch_mode = $launchMode
            exit_code = $exitCode
            detail = if ($exitCode -eq 0) { "Inline action completed successfully." } else { "Inline action exited with code $exitCode." }
            script_path = $scriptPath
            started_process_id = if ($proc) { [int]$proc.Id } else { $null }
            observations = @()
        }
    }
    catch {
        return [ordered]@{
            success = $false
            launch_mode = $launchMode
            exit_code = 1
            detail = $_.Exception.Message
            script_path = $scriptPath
            started_process_id = $null
            observations = @()
        }
    }
}

function New-IssueRecord {
    param(
        [Parameter(Mandatory = $true)][string]$IssueId,
        [Parameter(Mandatory = $true)][string]$Component,
        [Parameter(Mandatory = $true)][string]$Severity,
        [Parameter(Mandatory = $true)][string]$Summary,
        [string[]]$Evidence = @(),
        [string[]]$TruthSource = @(),
        [string]$ActionId = "",
        [bool]$RepairAllowed = $false,
        [string]$BlockedReason = "",
        [int]$Priority = 50
    )

    return [ordered]@{
        issue_id = $IssueId
        component = $Component
        severity = $Severity
        summary = $Summary
        evidence = @($Evidence)
        truth_source = @($TruthSource)
        action_id = $ActionId
        repair_allowed = [bool]$RepairAllowed
        blocked_reason = $BlockedReason
        priority = [int]$Priority
    }
}

function Update-IssueState {
    param(
        [Parameter(Mandatory = $true)][hashtable]$IssueStore,
        [Parameter(Mandatory = $true)]$IssueRecord,
        [Parameter(Mandatory = $true)]$IssueDecision,
        [Parameter(Mandatory = $true)]$Policy,
        [Parameter(Mandatory = $true)][datetime]$NowUtc
    )

    $issueId = [string](Get-PropValue -Object $IssueRecord -Name "issue_id" -Default "")
    if (-not $IssueStore.ContainsKey($issueId)) {
        $IssueStore[$issueId] = [ordered]@{}
    }

    $current = $IssueStore[$issueId]
    if (-not ($current -is [System.Collections.IDictionary])) {
        $current = Convert-ToMutableMap -Object $current
        $IssueStore[$issueId] = $current
    }
    $windowStarted = Parse-DateSafe -Value (Get-PropValue -Object $current -Name "window_started_utc" -Default "")
    $attemptCount = [int](Get-PropValue -Object $current -Name "attempt_count_in_window" -Default 0)
    if ($null -eq $windowStarted -or (($NowUtc - $windowStarted.UtcDateTime).TotalHours -gt 24)) {
        $windowStarted = [datetimeoffset]$NowUtc
        $attemptCount = 0
    }

    $actionState = Normalize-Text (Get-PropValue -Object $IssueDecision -Name "action_attempted_or_blocked" -Default "")
    if ($actionState -eq "attempted" -or $actionState -eq "attempted_success") {
        $attemptCount += 1
    }

    $retryPolicy = Get-PropValue -Object $Policy -Name "retry_policy" -Default $null
    $perIssueMinutes = [int](Get-PropValue -Object $retryPolicy -Name "per_issue_cooldown_minutes" -Default 45)
    $artifactCooldownMinutes = [int](Get-PropValue -Object $retryPolicy -Name "artifact_refresh_cooldown_minutes" -Default 120)
    $cooldownMinutes = $perIssueMinutes
    if ((Normalize-Text (Get-PropValue -Object $IssueRecord -Name "action_id" -Default "")).StartsWith("refresh_")) {
        $cooldownMinutes = $artifactCooldownMinutes
    }

    $current["last_seen_utc"] = Convert-ToUtcIso $NowUtc
    $current["window_started_utc"] = Convert-ToUtcIso $windowStarted.UtcDateTime
    $current["attempt_count_in_window"] = $attemptCount
    $current["last_policy_decision"] = Normalize-Text (Get-PropValue -Object $IssueDecision -Name "policy_decision" -Default "")
    $current["last_action_state"] = $actionState
    $current["last_result"] = Normalize-Text (Get-PropValue -Object $IssueDecision -Name "result" -Default "")

    if ($actionState -eq "attempted" -or $actionState -eq "attempted_success") {
        $current["last_action_at_utc"] = Convert-ToUtcIso $NowUtc
        $current["cooldown_until_utc"] = Convert-ToUtcIso ($NowUtc.AddMinutes($cooldownMinutes))
    }

    return $IssueStore
}

function Update-ComponentState {
    param(
        [Parameter(Mandatory = $true)][hashtable]$ComponentStore,
        [Parameter(Mandatory = $true)]$IssueRecord,
        [Parameter(Mandatory = $true)]$IssueDecision,
        [Parameter(Mandatory = $true)]$Policy,
        [Parameter(Mandatory = $true)][datetime]$NowUtc
    )

    $component = [string](Get-PropValue -Object $IssueRecord -Name "component" -Default "")
    if (-not $component) {
        return $ComponentStore
    }
    if (-not $ComponentStore.ContainsKey($component)) {
        $ComponentStore[$component] = [ordered]@{}
    }

    $current = $ComponentStore[$component]
    if (-not ($current -is [System.Collections.IDictionary])) {
        $current = Convert-ToMutableMap -Object $current
        $ComponentStore[$component] = $current
    }
    $actionState = Normalize-Text (Get-PropValue -Object $IssueDecision -Name "action_attempted_or_blocked" -Default "")
    if ($actionState -eq "attempted" -or $actionState -eq "attempted_success") {
        $retryPolicy = Get-PropValue -Object $Policy -Name "retry_policy" -Default $null
        $componentCooldownMinutes = [int](Get-PropValue -Object $retryPolicy -Name "per_component_restart_cooldown_minutes" -Default 45)
        $current["last_restart_at_utc"] = Convert-ToUtcIso $NowUtc
        $current["restart_cooldown_until_utc"] = Convert-ToUtcIso ($NowUtc.AddMinutes($componentCooldownMinutes))
    }

    $current["last_seen_issue_id"] = [string](Get-PropValue -Object $IssueRecord -Name "issue_id" -Default "")
    $current["last_seen_utc"] = Convert-ToUtcIso $NowUtc
    return $ComponentStore
}

function Get-SeverityRank {
    param([string]$Severity)

    switch ((Normalize-Text $Severity).ToLowerInvariant()) {
        "critical" { return 4 }
        "high" { return 3 }
        "medium" { return 2 }
        "low" { return 1 }
        default { return 0 }
    }
}

$repoRoot = Get-RepoRoot -OverrideRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$keepAliveReportPath = Join-Path $reportsDir "keepalive_last.json"
$selfHealReportPath = Join-Path $reportsDir "self_heal_last.json"
$dailyReportPath = Join-Path $reportsDir "daily_report_last.json"
$escalationQueuePath = Join-Path $reportsDir "escalation_queue_last.json"
$policyPath = Join-Path $repoRoot "config\keepalive_policy.json"
$keepAliveStatePath = Join-Path $repoRoot "state\knowledge\keepalive_state.json"
$systemValidationPath = Join-Path $reportsDir "system_validation_last.json"
$hostHealthPath = Join-Path $reportsDir "host_health_last.json"
$runtimePosturePath = Join-Path $reportsDir "runtime_posture_last.json"
$environmentProfilePath = Join-Path $reportsDir "environment_profile_last.json"
$selfImprovementPath = Join-Path $reportsDir "self_improvement_governor_last.json"
$startRunPath = Join-Path $reportsDir "start\start_run_last.json"
$mirrorPath = Join-Path $reportsDir "mirror_update_last.json"
$stackPidsPath = Join-Path $repoRoot "state\knowledge\stack_pids.json"
$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_KeepAlive_SelfHeal.ps1"

$policy = Get-CanonicalKeepAlivePolicy -PolicyPath $policyPath -RepoRoot $repoRoot
$previousDailyReport = Read-JsonSafe -Path $dailyReportPath -Default $null
$priorStateRaw = Read-JsonSafe -Path $keepAliveStatePath -Default $null
$priorIssues = @{}
$priorComponents = @{}
if ($priorStateRaw) {
    $issuesRaw = Get-PropValue -Object $priorStateRaw -Name "issues" -Default $null
    if ($issuesRaw) {
        foreach ($property in @($issuesRaw.PSObject.Properties)) {
            $priorIssues[[string]$property.Name] = $property.Value
        }
    }
    $componentsRaw = Get-PropValue -Object $priorStateRaw -Name "components" -Default $null
    if ($componentsRaw) {
        foreach ($property in @($componentsRaw.PSObject.Properties)) {
            $priorComponents[[string]$property.Name] = $property.Value
        }
    }
}

$ports = Get-ContractPorts -RepoRoot $repoRoot
$portsByComponent = @{}
foreach ($key in @($ports.Keys)) {
    $portsByComponent[[string]$key] = [int]$ports[$key]
}
$listenerMap = Get-ListenerMap -Ports @($portsByComponent.Values)
$currentLivePidMap = Get-CurrentLivePidMap -Path $stackPidsPath

$serviceEvaluations = @()
$serviceDefsByComponent = @{}
foreach ($serviceDef in @($policy.service_scope)) {
    $component = Normalize-Text (Get-PropValue -Object $serviceDef -Name "component" -Default "")
    if (-not $component) {
        continue
    }
    if (-not $portsByComponent.ContainsKey($component)) {
        continue
    }
    $serviceDefsByComponent[$component] = $serviceDef
    $serviceEvaluations += Get-ServiceEvaluation -ServiceDef $serviceDef -Port ([int]$portsByComponent[$component]) -ListenerMap $listenerMap -CurrentLivePidMap $currentLivePidMap
}

$validationData = Read-JsonSafe -Path $systemValidationPath -Default $null
$hostHealthData = Read-JsonSafe -Path $hostHealthPath -Default $null
$runtimePostureData = Read-JsonSafe -Path $runtimePosturePath -Default $null
$environmentProfileData = Read-JsonSafe -Path $environmentProfilePath -Default $null
$selfImprovementData = Read-JsonSafe -Path $selfImprovementPath -Default $null
$startRunData = Read-JsonSafe -Path $startRunPath -Default $null
$mirrorData = Read-JsonSafe -Path $mirrorPath -Default $null

$issues = @()

foreach ($evaluation in @($serviceEvaluations)) {
    $component = [string]$evaluation.component
    $mode = ""
    if (-not [bool]$evaluation.listening) {
        $mode = "not_listening"
    }
    elseif (-not [bool]$evaluation.health_ok) {
        $mode = "health_failed"
    }

    if (-not $mode) {
        continue
    }

    $serviceDef = $serviceDefsByComponent[$component]
    $autoRepairModes = @((Get-PropValue -Object $serviceDef -Name "auto_repair_modes" -Default @()))
    $actionId = Normalize-Text (Get-PropValue -Object $serviceDef -Name "low_risk_action_id" -Default "")
    $repairAllowed = ($autoRepairModes -contains $mode) -and [bool]$actionId
    $blockedReason = ""
    if (-not $repairAllowed) {
        $blockedReason = "Policy does not allow automatic repair for this service failure mode."
    }
    elseif ($component -eq "onyx" -and [bool]$evaluation.listening -and -not [bool]$evaluation.health_ok) {
        $repairAllowed = $false
        $blockedReason = "Onyx is bound but unhealthy; keepalive will not replace a bound UI process blindly."
    }

    $issues += New-IssueRecord `
        -IssueId ("service.{0}.{1}" -f $component, $mode) `
        -Component $component `
        -Severity ($(if ($component -in @("mason_api", "seed_api", "athena")) { "high" } elseif ($component -eq "bridge") { "medium" } else { "medium" })) `
        -Summary ("{0} is {1}." -f $evaluation.display_name, $mode.Replace("_", " ")) `
        -Evidence @(
            ("listening={0}" -f [bool]$evaluation.listening),
            ("health_ok={0}" -f [bool]$evaluation.health_ok),
            ("health_status_code={0}" -f [int]$evaluation.health_status_code),
            ("health_error={0}" -f (Normalize-Text $evaluation.health_error)),
            ("start_run_overall_status={0}" -f (Normalize-Text (Get-PropValue -Object $startRunData -Name "overall_status" -Default "")))
        ) `
        -TruthSource @("live_loopback_probe", "listener_snapshot", "stack_pids.current_live_pids", "start_run_last") `
        -ActionId $actionId `
        -RepairAllowed $repairAllowed `
        -BlockedReason $blockedReason `
        -Priority 100
}

$artifactRules = @(
    [ordered]@{
        issue_id = "artifact.system_validation.stale_or_missing"
        component = "validator"
        path = $systemValidationPath
        timestamp_field = "timestamp_utc"
        threshold_hours = 24
        action_id = "refresh_validator"
        summary = "Whole-system validator artifact is missing or stale."
        required_keys = @("timestamp_utc", "overall_status", "sections")
        priority = 60
    },
    [ordered]@{
        issue_id = "artifact.host_guardian.stale_or_missing"
        component = "host_guardian"
        path = $hostHealthPath
        timestamp_field = "timestamp_utc"
        threshold_hours = 24
        action_id = "refresh_host_guardian"
        summary = "Host guardian artifact is missing or stale."
        required_keys = @("timestamp_utc", "overall_status", "throttle_guidance")
        priority = 40
    },
    [ordered]@{
        issue_id = "artifact.environment_adaptation.stale_or_missing"
        component = "environment"
        path = $runtimePosturePath
        timestamp_field = "timestamp_utc"
        threshold_hours = 24
        action_id = "refresh_environment_adaptation"
        summary = "Runtime posture artifact is missing or stale."
        required_keys = @("timestamp_utc", "environment_id", "throttle_guidance")
        priority = 30
    }
)

foreach ($rule in $artifactRules) {
    $path = [string]$rule.path
    $data = Read-JsonSafe -Path $path -Default $null
    $missing = $false
    $missingFields = @()
    if (-not $data) {
        $missing = $true
    }
    else {
        foreach ($requiredKey in @($rule.required_keys)) {
            if (-not (Test-ObjectHasKey -Object $data -Name $requiredKey)) {
                $missingFields += $requiredKey
            }
        }
    }

    $ageHours = [double]::PositiveInfinity
    if ($data) {
        $ageHours = Get-AgeHours -Timestamp (Get-PropValue -Object $data -Name ([string]$rule.timestamp_field) -Default "")
    }

    $isStale = ($ageHours -gt [double]$rule.threshold_hours)
    if (-not $missing -and $missingFields.Count -eq 0 -and -not $isStale) {
        continue
    }

    $reason = if ($missing) {
        "Artifact is missing or unreadable."
    }
    elseif ($missingFields.Count -gt 0) {
        "Artifact is missing required keys: $($missingFields -join ', ')."
    }
    else {
        "Artifact age exceeds $($rule.threshold_hours) hour policy threshold."
    }

    $issues += New-IssueRecord `
        -IssueId ([string]$rule.issue_id) `
        -Component ([string]$rule.component) `
        -Severity "low" `
        -Summary ([string]$rule.summary) `
        -Evidence @(
            ("artifact_path={0}" -f $path),
            ("artifact_age_hours={0}" -f $ageHours),
            $reason
        ) `
        -TruthSource @("artifact_timestamp", "policy_thresholds") `
        -ActionId ([string]$rule.action_id) `
        -RepairAllowed $true `
        -BlockedReason "" `
        -Priority ([int]$rule.priority)
}

$unresolvedGovernanceIssues = @()
$warnSections = @()
if ($validationData) {
    $sections = @((Get-PropValue -Object $validationData -Name "sections" -Default @()))
    foreach ($section in @($sections)) {
        if ((Normalize-Text (Get-PropValue -Object $section -Name "status" -Default "")).ToUpperInvariant() -eq "WARN") {
            $warnSections += $section
        }
    }
}

foreach ($section in @($warnSections)) {
    $sectionName = Normalize-Text (Get-PropValue -Object $section -Name "section_name" -Default "warning")
    $component = switch ($sectionName) {
        "self-improvement governor" { "self_improvement" }
        "security/legal/tenant safety" { "security_posture" }
        "billing/entitlements" { "billing" }
        default { "governance" }
    }
    $severity = switch ($component) {
        "security_posture" { "high" }
        "billing" { "medium" }
        "self_improvement" { "medium" }
        default { "low" }
    }
    $safeSection = ([regex]::Replace($sectionName.ToLowerInvariant(), "[^a-z0-9]+", "_")).Trim("_")
    $unresolvedGovernanceIssues += New-IssueRecord `
        -IssueId ("validator.warn.{0}" -f $safeSection) `
        -Component $component `
        -Severity $severity `
        -Summary ("Validator warning persists: {0}" -f $sectionName) `
        -Evidence @(
            ("validator_status={0}" -f (Normalize-Text (Get-PropValue -Object $section -Name "status" -Default ""))),
            ("recommended_next_action={0}" -f (Normalize-Text (Get-PropValue -Object $section -Name "recommended_next_action" -Default ""))),
            ("artifact_path={0}" -f (Normalize-Text (Get-PropValue -Object $section -Name "relevant_log_or_artifact_path" -Default "")))
        ) `
        -TruthSource @("system_validation_last") `
        -ActionId "" `
        -RepairAllowed $false `
        -BlockedReason "This issue is governance- or approval-gated and should escalate instead of auto-healing." `
        -Priority 20
}

$pendingReboot = $false
$hostUptime = Get-PropValue -Object $hostHealthData -Name "uptime" -Default $null
if ($hostUptime) {
    $pendingReboot = [bool](Get-PropValue -Object $hostUptime -Name "pending_reboot" -Default $false)
}
if ($pendingReboot) {
    $unresolvedGovernanceIssues += New-IssueRecord `
        -IssueId "host.pending_reboot" `
        -Component "host" `
        -Severity "medium" `
        -Summary "Windows reports a pending reboot." `
        -Evidence @(
            "host_guardian.pending_reboot=true",
            ("host_recommended_next_action={0}" -f (Normalize-Text (Get-PropValue -Object $hostHealthData -Name "recommended_next_action" -Default "")))
        ) `
        -TruthSource @("host_guardian_last") `
        -ActionId "" `
        -RepairAllowed $false `
        -BlockedReason "KeepAlive does not reboot the host automatically." `
        -Priority 25
}

$issues += $unresolvedGovernanceIssues

$attemptedIssuesThisRun = @{}
$attemptedActionsThisRun = @{}
$repairAttempts = @()
$issueDecisions = @()
$escalations = @()
$repairAttemptCount = 0
$repairSuccessCount = 0
$repairBlockedCount = 0
$recoverableIssueCount = 0
$escalatedIssueCount = 0
$nowUtc = Get-NowUtc

$sortedIssues = @($issues | Sort-Object @{ Expression = { -1 * [int](Get-PropValue -Object $_ -Name "priority" -Default 0) } }, @{ Expression = { -1 * (Get-SeverityRank -Severity (Get-PropValue -Object $_ -Name "severity" -Default "")) } }, issue_id)
$repairBudget = [int](Get-PropValue -Object (Get-PropValue -Object $policy -Name "retry_policy" -Default $null) -Name "max_repairs_per_run" -Default 1)

foreach ($issue in @($sortedIssues)) {
    $issueId = [string](Get-PropValue -Object $issue -Name "issue_id" -Default "")
    $component = [string](Get-PropValue -Object $issue -Name "component" -Default "")
    $issueState = Get-IssueState -State $priorStateRaw -IssueId $issueId
    $componentState = Get-ComponentState -State $priorStateRaw -Component $component
    $decision = Get-RepairDecision -Issue $issue -Policy $policy -IssueState $issueState -ComponentState $componentState -AttemptedIssuesThisRun $attemptedIssuesThisRun -AttemptedActionsThisRun $attemptedActionsThisRun

    if ($decision.policy_decision -eq "allowed_repair") {
        $recoverableIssueCount += 1
    }

    $actionState = [string]$decision.action_attempted_or_blocked
    $resultText = ""
    $rollbackPath = ""
    $recommendedNextStep = ""

    if ($decision.policy_decision -eq "allowed_repair" -and $repairAttemptCount -lt $repairBudget) {
        $actionConfig = Get-ActionConfig -Policy $policy -ActionId ([string]$decision.action_id)
        $repairServices = @()
        if ($actionConfig) {
            $repairComponents = @((Get-PropValue -Object $actionConfig -Name "components" -Default @()))
            foreach ($repairComponent in @($repairComponents)) {
                $repairComponentText = Normalize-Text $repairComponent
                if ($serviceDefsByComponent.ContainsKey($repairComponentText)) {
                    $repairServices += $serviceDefsByComponent[$repairComponentText]
                }
            }
        }

        $actionResult = Invoke-PolicyAction -ActionConfig $actionConfig -RepoRoot $repoRoot -ServiceDefs $repairServices -PortsByComponent $portsByComponent
        $repairAttemptCount += 1
        $attemptedIssuesThisRun[$issueId] = $true
        $attemptedActionsThisRun[[string]$decision.action_id] = $true
        $actionState = if ($actionResult.success) { "attempted_success" } else { "attempted" }
        $decision.action_attempted_or_blocked = $actionState
        $resultText = if ($actionResult.success) { "repair_succeeded" } else { "repair_failed" }
        $decision.result = $resultText
        $decision.escalation_decision = if ($actionResult.success) { "none" } else { "escalate" }
        $decision.reason = Normalize-Text $actionResult.detail
        $rollbackPath = "Run .\Stop_Stack.ps1 and then .\tools\ops\Stack_Reset_And_Start.ps1 if the repair destabilizes the baseline."
        $recommendedNextStep = if ($actionResult.success) {
            "No further action required unless the issue recurs."
        }
        else {
            "Use the canonical stack reset/start flow if the component stays unhealthy."
        }

        if ($actionResult.success) {
            $repairSuccessCount += 1
        }
        else {
            $escalatedIssueCount += 1
            $escalations += [ordered]@{
                issue_id = $issueId
                component = $component
                severity = [string](Get-PropValue -Object $issue -Name "severity" -Default "medium")
                owner_action_required = $true
                why_not_auto_healed = "A single low-risk repair attempt did not restore health."
                recommended_next_step = $recommendedNextStep
            }
        }

        $repairAttempts += [ordered]@{
            issue_id = $issueId
            action_id = [string]$decision.action_id
            result = $resultText
            detail = Normalize-Text $actionResult.detail
            started_process_id = Get-PropValue -Object $actionResult -Name "started_process_id" -Default $null
            observations = @((Get-PropValue -Object $actionResult -Name "observations" -Default @()))
        }
    }
    elseif ($decision.policy_decision -eq "allowed_repair" -and $repairAttemptCount -ge $repairBudget) {
        $actionState = "deferred_due_single_action_limit"
        $decision.action_attempted_or_blocked = $actionState
        $decision.policy_decision = "deferred_due_single_action_limit"
        $decision.result = "deferred"
        $decision.escalation_decision = "defer_to_next_run"
        $decision.reason = "A single repair action has already been used in this run."
        $recommendedNextStep = "Allow the next scheduled keepalive pass to reevaluate this recoverable issue."
    }
    else {
        $decision.result = "not_auto_healed"
        $repairBlockedCount += 1
        $recommendedNextStep = Normalize-Text (Get-PropValue -Object $issue -Name "blocked_reason" -Default "")
        if (-not $recommendedNextStep) {
            $recommendedNextStep = Normalize-Text (Get-PropValue -Object $decision -Name "reason" -Default "")
        }
        if (-not $recommendedNextStep) {
            $recommendedNextStep = "Review the issue manually."
        }
        if ($decision.policy_decision -ne "defer_to_next_run") {
            $escalatedIssueCount += 1
            $escalations += [ordered]@{
                issue_id = $issueId
                component = $component
                severity = [string](Get-PropValue -Object $issue -Name "severity" -Default "medium")
                owner_action_required = $true
                why_not_auto_healed = $recommendedNextStep
                recommended_next_step = if ($component -eq "billing") {
                    "Configure external billing and webhook settings only when ready for live money."
                }
                elseif ($component -eq "security_posture") {
                    "Review tenant isolation and security posture findings before authorizing changes."
                }
                elseif ($component -eq "self_improvement") {
                    "Keep teacher-backed or blocked items out of staging until owner review."
                }
                elseif ($component -eq "host") {
                    "Plan a safe reboot window when appropriate."
                }
                else {
                    $recommendedNextStep
                }
            }
        }
    }

    $issueDecisionRecord = [ordered]@{
        issue_id = $issueId
        component = $component
        severity = [string](Get-PropValue -Object $issue -Name "severity" -Default "medium")
        summary = [string](Get-PropValue -Object $issue -Name "summary" -Default "")
        evidence = @((Get-PropValue -Object $issue -Name "evidence" -Default @()))
        truth_source = @((Get-PropValue -Object $issue -Name "truth_source" -Default @()))
        policy_decision = [string]$decision.policy_decision
        action_attempted_or_blocked = $actionState
        action_id = [string](Get-PropValue -Object $issue -Name "action_id" -Default "")
        result = [string](Get-PropValue -Object $decision -Name "result" -Default $resultText)
        cooldown_status = [ordered]@{
            active = [bool](Get-PropValue -Object (Get-PropValue -Object $decision -Name "cooldown_status" -Default $null) -Name "active" -Default $false)
            reason = [string](Get-PropValue -Object (Get-PropValue -Object $decision -Name "cooldown_status" -Default $null) -Name "reason" -Default "")
            until_utc = [string](Get-PropValue -Object (Get-PropValue -Object $decision -Name "cooldown_status" -Default $null) -Name "until_utc" -Default "")
        }
        escalation_decision = [string]$decision.escalation_decision
        recommended_next_step = $recommendedNextStep
        rollback_path = $rollbackPath
    }
    $issueDecisions += $issueDecisionRecord
    Update-IssueState -IssueStore $priorIssues -IssueRecord $issue -IssueDecision $issueDecisionRecord -Policy $policy -NowUtc $nowUtc | Out-Null
    Update-ComponentState -ComponentStore $priorComponents -IssueRecord $issue -IssueDecision $issueDecisionRecord -Policy $policy -NowUtc $nowUtc | Out-Null
}

$healthyAreas = @()
foreach ($evaluation in @($serviceEvaluations | Where-Object { $_.status -eq "PASS" })) {
    $healthyAreas += ("{0} healthy on {1}" -f $evaluation.display_name, $evaluation.port)
}
if ($validationData -and ((Normalize-Text (Get-PropValue -Object $validationData -Name "overall_status" -Default "")).ToUpperInvariant() -eq "WARN")) {
    $healthyAreas += "Validator baseline remains functional with zero fails."
}
if ($mirrorData -and [bool](Get-PropValue -Object $mirrorData -Name "ok" -Default $false)) {
    $healthyAreas += "Mirror checkpoint remains readable and marked ok."
}

$warnings = @()
foreach ($escalation in @($escalations)) {
    $warnings += ("{0}: {1}" -f $escalation.component, $escalation.why_not_auto_healed)
}

$attemptedSummary = @()
foreach ($attempt in @($repairAttempts)) {
    $attemptedSummary += ("{0} -> {1}" -f $attempt.action_id, $attempt.result)
}
if ($attemptedSummary.Count -eq 0) {
    $attemptedSummary += "No low-risk repair was attempted in this run."
}

$refusedSummary = @()
foreach ($issueDecision in @($issueDecisions | Where-Object { $_.action_attempted_or_blocked -notin @("attempted", "attempted_success", "deferred_due_single_action_limit") })) {
    $refusedSummary += ("{0}: {1}" -f $issueDecision.issue_id, $issueDecision.recommended_next_step)
}

$blockedSummary = @()
foreach ($issueDecision in @($issueDecisions | Where-Object { $_.escalation_decision -eq "escalate" })) {
    $blockedSummary += ("{0}: {1}" -f $issueDecision.component, $issueDecision.recommended_next_step)
}

$ownerReview = @()
foreach ($escalation in @($escalations)) {
    if ([bool]$escalation.owner_action_required) {
        $ownerReview += ("{0}: {1}" -f $escalation.component, $escalation.recommended_next_step)
    }
}

$changesSincePrior = @()
if ($previousDailyReport) {
    $previousPosture = Normalize-Text (Get-PropValue -Object $previousDailyReport -Name "overall_posture" -Default "")
    $currentPostureCandidate = if ($escalatedIssueCount -gt 0 -or $repairBlockedCount -gt 0) { "WARN" } elseif ($repairSuccessCount -gt 0) { "PASS" } else { "PASS" }
    if ($previousPosture -and $previousPosture -ne $currentPostureCandidate) {
        $changesSincePrior += ("overall_posture {0} -> {1}" -f $previousPosture, $currentPostureCandidate)
    }
    $previousEscalationCount = [int](Get-PropValue -Object $previousDailyReport -Name "escalation_count" -Default 0)
    if ($previousEscalationCount -ne $escalatedIssueCount) {
        $changesSincePrior += ("escalation_count {0} -> {1}" -f $previousEscalationCount, $escalatedIssueCount)
    }
    $previousRepairCount = [int](Get-PropValue -Object $previousDailyReport -Name "repair_attempt_count" -Default 0)
    if ($previousRepairCount -ne $repairAttemptCount) {
        $changesSincePrior += ("repair_attempt_count {0} -> {1}" -f $previousRepairCount, $repairAttemptCount)
    }
}
if ($changesSincePrior.Count -eq 0) {
    $changesSincePrior += "No material change from the prior daily report could be determined."
}

$runtimeThrottle = Normalize-Text (Get-PropValue -Object $runtimePostureData -Name "throttle_guidance" -Default "")
if (-not $runtimeThrottle) {
    $runtimeThrottle = Normalize-Text (Get-PropValue -Object $hostHealthData -Name "throttle_guidance" -Default "")
}
if (-not $runtimeThrottle) {
    $runtimeThrottle = "normal"
}

$overallStatus = "PASS"
if ($escalatedIssueCount -gt 0 -or $repairBlockedCount -gt 0) {
    $overallStatus = "WARN"
}
if (@($serviceEvaluations | Where-Object { $_.status -eq "FAIL" }).Count -gt 0 -and $repairSuccessCount -eq 0 -and $recoverableIssueCount -gt 0) {
    $overallStatus = "WARN"
}

$recommendedNextAction = "No action required."
if ($escalations.Count -gt 0) {
    $recommendedNextAction = [string]$escalations[0].recommended_next_step
}
elseif ($repairAttempts.Count -gt 0 -and $repairSuccessCount -gt 0) {
    $recommendedNextAction = "Monitor the repaired service during the next keepalive cycle."
}

$keepAliveReport = [ordered]@{
    timestamp_utc = Convert-ToUtcIso $nowUtc
    overall_status = $overallStatus
    policy_posture = [string](Get-PropValue -Object $policy -Name "policy_posture" -Default "conservative_loopback_only")
    services_evaluated = @($serviceEvaluations)
    healthy_service_count = @($serviceEvaluations | Where-Object { $_.status -eq "PASS" }).Count
    recoverable_issue_count = $recoverableIssueCount
    escalated_issue_count = $escalatedIssueCount
    repair_attempt_count = $repairAttemptCount
    repair_success_count = $repairSuccessCount
    repair_blocked_count = $repairBlockedCount
    throttle_guidance = $runtimeThrottle
    daily_report_status = $overallStatus
    recommended_next_action = $recommendedNextAction
    command_run = $commandRun
    repo_root = $repoRoot
    policy_path = $policyPath
    state_path = $keepAliveStatePath
}

$selfHealReport = [ordered]@{
    timestamp_utc = Convert-ToUtcIso $nowUtc
    overall_status = $overallStatus
    issues = @($issueDecisions)
    repair_attempt_count = $repairAttemptCount
    repair_success_count = $repairSuccessCount
    repair_blocked_count = $repairBlockedCount
    escalated_issue_count = $escalatedIssueCount
    command_run = $commandRun
    repo_root = $repoRoot
    state_path = $keepAliveStatePath
}

$dailyReport = [ordered]@{
    timestamp_utc = Convert-ToUtcIso $nowUtc
    overall_status = $overallStatus
    overall_posture = $overallStatus
    healthy_areas = @($healthyAreas)
    warnings = @($warnings)
    changed_since_prior_run = @($changesSincePrior)
    what_mason_attempted = @($attemptedSummary)
    what_mason_refused_to_do = @($refusedSummary)
    what_remains_blocked = @($blockedSummary)
    what_needs_owner_review = @($ownerReview)
    repair_attempt_count = $repairAttemptCount
    escalation_count = $escalatedIssueCount
    recommended_next_action = $recommendedNextAction
    command_run = $commandRun
    repo_root = $repoRoot
}

$escalationQueueReport = [ordered]@{
    timestamp_utc = Convert-ToUtcIso $nowUtc
    overall_status = if ($escalations.Count -gt 0) { "WARN" } else { "PASS" }
    escalation_count = $escalations.Count
    escalations = @($escalations)
    recommended_next_action = $recommendedNextAction
    command_run = $commandRun
    repo_root = $repoRoot
}

$statePayload = [ordered]@{
    generated_at_utc = Convert-ToUtcIso $nowUtc
    last_run_status = $overallStatus
    last_recommended_next_action = $recommendedNextAction
    issues = [ordered]@{}
    components = [ordered]@{}
}
foreach ($key in @($priorIssues.Keys | Sort-Object)) {
    $statePayload.issues[$key] = $priorIssues[$key]
}
foreach ($key in @($priorComponents.Keys | Sort-Object)) {
    $statePayload.components[$key] = $priorComponents[$key]
}

Write-JsonFile -Path $keepAliveStatePath -Object $statePayload -Depth 18
Write-JsonFile -Path $keepAliveReportPath -Object $keepAliveReport -Depth 18
Write-JsonFile -Path $selfHealReportPath -Object $selfHealReport -Depth 18
Write-JsonFile -Path $dailyReportPath -Object $dailyReport -Depth 18
Write-JsonFile -Path $escalationQueuePath -Object $escalationQueueReport -Depth 18

$keepAliveReport | ConvertTo-Json -Depth 10
