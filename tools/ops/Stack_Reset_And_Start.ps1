[CmdletBinding()]
param(
    [string]$RootPath = "",
    [int]$ReadinessTimeoutSeconds = 240,
    [int]$HardTimeoutSeconds = 900
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-ResetLog {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Stack_Reset_And_Start] [$Level] $Message"
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
        [int]$Depth = 14
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $Object | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Write-LastFailureJson {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Component,
        [string]$Command,
        [int]$ExitCode = 1,
        [string]$StderrPath,
        [string]$Hint
    )

    $payload = [ordered]@{
        component     = [string]$Component
        command       = if ($Command) { [string]$Command } else { $null }
        exit_code     = [int]$ExitCode
        stderr_path   = if ($StderrPath) { [string]$StderrPath } else { $null }
        hint          = if ($Hint) { [string]$Hint } else { "Stack reset/start failed." }
        timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    }
    try {
        Write-JsonFile -Path $Path -Object $payload -Depth 8
    }
    catch {
        # Best effort only.
    }
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
    $stableKeys = @("mason_api", "seed_api", "bridge", "athena", "onyx")
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

    $normalized = [ordered]@{}
    foreach ($key in $stableKeys) {
        $normalized[$key] = [int]$defaults[$key]
    }

    $portsPath = Join-Path $RepoRoot "config\ports.json"
    $portsCfg = Read-JsonSafe -Path $portsPath -Default $null
    if (-not $portsCfg) {
        return $normalized
    }

    $portsSource = $null
    if ($portsCfg -is [System.Collections.IDictionary]) {
        if ($portsCfg.Contains("ports")) {
            $portsSource = $portsCfg["ports"]
        }
    }
    elseif ($portsCfg.PSObject.Properties.Name -contains "ports") {
        $portsSource = $portsCfg.ports
    }

    if (-not $portsSource) {
        return $normalized
    }

    # Snapshot source before iterating so any downstream writes do not mutate the active enumeration.
    $entries = @()
    if ($portsSource -is [System.Collections.IDictionary]) {
        $items = @($portsSource.GetEnumerator())
        foreach ($item in $items) {
            $entries += [pscustomobject]@{
                name = [string]$item.Key
                value = $item.Value
            }
        }
    }
    else {
        $props = @($portsSource.PSObject.Properties)
        foreach ($prop in $props) {
            $entries += [pscustomobject]@{
                name = [string]$prop.Name
                value = $prop.Value
            }
        }
    }

    foreach ($entry in $entries) {
        if (-not $entry.name) { continue }
        $normalizedName = [regex]::Replace(([string]$entry.name).ToLowerInvariant().Replace("-", "_"), "[^a-z0-9_]", "")
        if (-not $aliasToCanonical.ContainsKey($normalizedName)) { continue }

        $canonicalName = [string]$aliasToCanonical[$normalizedName]
        $tmp = 0
        if ([int]::TryParse([string]$entry.value, [ref]$tmp) -and $tmp -gt 0 -and $tmp -le 65535) {
            $normalized[$canonicalName] = $tmp
        }
    }

    $stableResult = [ordered]@{}
    foreach ($key in $stableKeys) {
        $stableResult[$key] = [int]$normalized[$key]
    }
    return $stableResult
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

function Get-NetstatListenerRows {
    param([int[]]$Ports)

    $portSet = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($portValue in @($Ports | Sort-Object -Unique)) {
        if ($portValue -gt 0) {
            [void]$portSet.Add([int]$portValue)
        }
    }

    $rows = @()
    $lines = @(& netstat -ano -p tcp 2>$null)
    foreach ($line in $lines) {
        $trimmed = ([string]$line).Trim()
        if (-not $trimmed) {
            continue
        }
        if ($trimmed -notmatch '^\s*TCP\s+(\S+)\s+\S+\s+LISTENING\s+(\d+)\s*$') {
            continue
        }

        $endpoint = [string]$Matches[1]
        $ownerPid = 0
        if (-not [int]::TryParse([string]$Matches[2], [ref]$ownerPid)) {
            continue
        }
        if ($ownerPid -le 0) {
            continue
        }

        $portParsed = Get-PortFromEndpoint -Endpoint $endpoint
        if ($null -eq $portParsed -or -not $portSet.Contains([int]$portParsed)) {
            continue
        }

        $localAddress = [string]$endpoint
        $splitMatch = [regex]::Match([string]$endpoint, '^(.*):(\d+)$')
        if ($splitMatch.Success) {
            $localAddress = [string]$splitMatch.Groups[1].Value
        }

        $rows += [pscustomobject]@{
            local_address = $localAddress
            local_port    = [int]$portParsed
            owning_pid    = [int]$ownerPid
        }
    }

    return @($rows)
}

function Get-PortSnapshot {
    param([int[]]$Ports)

    $netstatRows = @()
    $netstatLoaded = $false

    $rows = @()
    foreach ($port in @($Ports | Sort-Object -Unique)) {
        $listeners = @()
        try {
            $netRows = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction Stop
            foreach ($row in @($netRows)) {
                $listeners += [pscustomobject]@{
                    local_address = [string]$row.LocalAddress
                    local_port    = [int]$row.LocalPort
                    owning_pid    = [int]$row.OwningProcess
                }
            }
        }
        catch {
            $listeners = @()
        }

        if (@($listeners).Count -eq 0) {
            if (-not $netstatLoaded) {
                $netstatRows = @(Get-NetstatListenerRows -Ports $Ports)
                $netstatLoaded = $true
            }
            foreach ($row in @($netstatRows | Where-Object { [int]$_.local_port -eq [int]$port })) {
                $listeners += [pscustomobject]@{
                    local_address = [string]$row.local_address
                    local_port    = [int]$row.local_port
                    owning_pid    = [int]$row.owning_pid
                }
            }
        }

        $rows += [pscustomobject]@{
            port           = [int]$port
            listener_count = @($listeners).Count
            listeners      = @($listeners)
        }
    }

    return @($rows)
}

function Get-KnownRepoProcessCandidates {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)
    $fragments = @(
        $RepoRoot,
        "Start_Mason2.ps1",
        "Start_Bridge.ps1",
        "Start-Athena.ps1",
        "Start-Onyx5353.ps1",
        "mason_bridge_server.py",
        "MasonConsole\\server.py",
        "services\\mason_api\\serve_mason_api.py",
        "services\\seed_api\\serve_seed_api.py"
    )
    $result = @()
    try {
        $rows = Get-CimInstance Win32_Process -ErrorAction Stop
        foreach ($proc in @($rows)) {
            if (-not $proc.CommandLine) { continue }
            if ([int]$proc.ProcessId -eq [int]$PID) { continue }
            foreach ($fragment in $fragments) {
                if (-not $fragment) { continue }
                if ($proc.CommandLine.IndexOf($fragment, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $result += [pscustomobject]@{
                        pid         = [int]$proc.ProcessId
                        name        = [string]$proc.Name
                        command_line = [string]$proc.CommandLine
                        source      = "commandline"
                    }
                    break
                }
            }
        }
    }
    catch {
        Write-ResetLog ("Could not inspect process command lines: {0}" -f $_.Exception.Message) "WARN"
    }
    return @($result)
}

function Get-ProcessesByCommandFragment {
    param(
        [Parameter(Mandatory = $true)][string]$Fragment,
        [string[]]$ProcessNames = @()
    )

    if ([string]::IsNullOrWhiteSpace($Fragment)) {
        return @()
    }

    $normalizedNames = @($ProcessNames | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | ForEach-Object { ([string]$_).ToLowerInvariant() })
    try {
        $rows = Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
            $cmdLine = [string]$_.CommandLine
            if (-not $cmdLine) {
                return $false
            }
            if ($cmdLine.IndexOf($Fragment, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
                return $false
            }
            if ($normalizedNames.Count -eq 0) {
                return $true
            }
            return ($normalizedNames -contains ([string]$_.Name).ToLowerInvariant())
        }
        return @($rows | Sort-Object CreationDate, ProcessId)
    }
    catch {
        Write-ResetLog ("Could not inspect process command lines for singleton drift: {0}" -f $_.Exception.Message) "WARN"
        return @()
    }
}

function Get-UniquePortOwnersFromSnapshot {
    param(
        [Parameter(Mandatory = $true)][object[]]$PortSnapshot,
        [Parameter(Mandatory = $true)][int]$Port
    )

    $row = @($PortSnapshot | Where-Object { [int]$_.port -eq [int]$Port } | Select-Object -First 1)
    if ($row.Count -eq 0) {
        return @()
    }

    return @(
        $row[0].listeners |
        ForEach-Object { [int]$_.owning_pid } |
        Where-Object { $_ -gt 0 } |
        Sort-Object -Unique
    )
}

function Get-CanonicalRuntimePid {
    param(
        $StackState,
        [Parameter(Mandatory = $true)][string]$Component
    )

    if (-not $StackState) {
        return $null
    }

    $currentLive = $null
    if ($StackState.PSObject.Properties.Name -contains "current_live_pids") {
        $currentLive = $StackState.current_live_pids
    }
    if ($currentLive) {
        $rawValue = $null
        if ($currentLive -is [System.Collections.IDictionary]) {
            if ($currentLive.Contains($Component)) {
                $rawValue = $currentLive[$Component]
            }
        }
        else {
            $property = $currentLive.PSObject.Properties[$Component]
            if ($property) {
                $rawValue = $property.Value
            }
        }

        $parsed = 0
        if ([int]::TryParse([string]$rawValue, [ref]$parsed) -and $parsed -gt 0) {
            return [int]$parsed
        }
    }

    $topLevelKey = switch ($Component) {
        "mason_api" { "mason_api_pid" }
        "seed_api" { "seed_api_pid" }
        "bridge" { "bridge_pid" }
        "athena" { "athena_pid" }
        "onyx" { "onyx_pid" }
        default { $null }
    }
    if (-not $topLevelKey) {
        return $null
    }

    $topLevelValue = $null
    if ($StackState -is [System.Collections.IDictionary]) {
        if ($StackState.Contains($topLevelKey)) {
            $topLevelValue = $StackState[$topLevelKey]
        }
    }
    elseif ($StackState.PSObject.Properties.Name -contains $topLevelKey) {
        $topLevelValue = $StackState.$topLevelKey
    }

    $topLevelParsed = 0
    if ([int]::TryParse([string]$topLevelValue, [ref]$topLevelParsed) -and $topLevelParsed -gt 0) {
        return [int]$topLevelParsed
    }

    return $null
}

function Get-RuntimeSingletonDrift {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)]$ContractPorts,
        [Parameter(Mandatory = $true)][object[]]$PortSnapshot
    )

    $stackState = Read-JsonSafe -Path (Join-Path $RepoRoot "state\knowledge\stack_pids.json") -Default $null
    $findings = @()
    $singletonSpecs = @(
        [ordered]@{ component = "mason_api"; port = [int]$ContractPorts.mason_api }
        [ordered]@{ component = "seed_api";  port = [int]$ContractPorts.seed_api }
        [ordered]@{ component = "bridge";    port = [int]$ContractPorts.bridge }
        [ordered]@{ component = "athena";    port = [int]$ContractPorts.athena }
        [ordered]@{ component = "onyx";      port = [int]$ContractPorts.onyx }
    )

    foreach ($spec in $singletonSpecs) {
        $owners = @(Get-UniquePortOwnersFromSnapshot -PortSnapshot $PortSnapshot -Port ([int]$spec.port))
        if ($owners.Count -gt 1) {
            $findings += [pscustomobject]@{
                component = [string]$spec.component
                type      = "multiple_listener_owners"
                detail    = ("Port {0} has multiple listener owners: {1}" -f [int]$spec.port, (($owners | ForEach-Object { $_.ToString() }) -join ", "))
            }
        }

        $canonicalPid = Get-CanonicalRuntimePid -StackState $stackState -Component ([string]$spec.component)
        if ($owners.Count -eq 1 -and $canonicalPid -and ([int]$owners[0] -ne [int]$canonicalPid)) {
            $findings += [pscustomobject]@{
                component = [string]$spec.component
                type      = "stack_pid_mismatch"
                detail    = ("stack_pids canonical pid {0} does not match live listener pid {1} on port {2}" -f [int]$canonicalPid, [int]$owners[0], [int]$spec.port)
            }
        }
    }

    $serviceSpecs = @(
        [ordered]@{ component = "mason_api"; script = (Join-Path $RepoRoot "services\mason_api\serve_mason_api.py") }
        [ordered]@{ component = "seed_api";  script = (Join-Path $RepoRoot "services\seed_api\serve_seed_api.py") }
    )
    foreach ($service in $serviceSpecs) {
        $processes = @(Get-ProcessesByCommandFragment -Fragment ([string]$service.script) -ProcessNames @("python.exe", "pythonw.exe"))
        if ($processes.Count -gt 1) {
            $findings += [pscustomobject]@{
                component = [string]$service.component
                type      = "duplicate_service_processes"
                detail    = ("Found {0} matching service processes for {1}." -f $processes.Count, [string]$service.component)
            }
        }
    }

    return @($findings)
}

function Stop-ProcessIdsBestEffort {
    param([int[]]$Pids)
    $rows = @()
    foreach ($pidValue in @($Pids | Sort-Object -Unique)) {
        if (-not $pidValue) { continue }
        if ([int]$pidValue -eq [int]$PID) { continue }
        $entry = [ordered]@{
            pid    = [int]$pidValue
            stopped = $false
            note   = $null
        }
        try {
            $proc = Get-Process -Id $pidValue -ErrorAction SilentlyContinue
            if (-not $proc) {
                $entry.note = "already_stopped"
            }
            else {
                Stop-Process -Id $pidValue -Force -ErrorAction Stop
                $entry.stopped = $true
                $entry.note = "stopped"
            }
        }
        catch {
            $entry.note = $_.Exception.Message
        }
        $rows += [pscustomobject]$entry
    }
    return @($rows)
}

function Test-HttpEndpoint {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSec = 3
    )
    try {
        $req = @{
            Uri         = $Url
            Method      = "Get"
            TimeoutSec  = $TimeoutSec
            ErrorAction = "Stop"
        }
        if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey("UseBasicParsing")) {
            $req["UseBasicParsing"] = $true
        }
        $resp = Invoke-WebRequest @req
        return ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400)
    }
    catch {
        return $false
    }
}

function Wait-EndpointsReady {
    param(
        [Parameter(Mandatory = $true)][string[]]$Urls,
        [int]$TimeoutSeconds = 90
    )

    $deadline = (Get-Date).AddSeconds([Math]::Max(5, $TimeoutSeconds))
    while ((Get-Date) -lt $deadline) {
        $allReady = $true
        foreach ($url in $Urls) {
            if (-not (Test-HttpEndpoint -Url $url -TimeoutSec 3)) {
                $allReady = $false
                break
            }
        }
        if ($allReady) {
            return $true
        }
        Start-Sleep -Seconds 2
    }
    return $false
}

function Test-EndpointsReadyOnce {
    param(
        [Parameter(Mandatory = $true)][string[]]$Urls
    )
    foreach ($url in $Urls) {
        if (-not (Test-HttpEndpoint -Url $url -TimeoutSec 3)) {
            return $false
        }
    }
    return $true
}

if (-not $RootPath) {
    $RootPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$repoRoot = [System.IO.Path]::GetFullPath($RootPath)
$reportsDir = Join-Path $repoRoot "reports"
New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
$stackResetLastPath = Join-Path $reportsDir "stack_reset_last.json"
$script:StackResetLastPathContext = $stackResetLastPath

trap {
    if ($script:StackResetLastPathContext) {
        try {
            Write-JsonFile -Path $script:StackResetLastPathContext -Object ([ordered]@{
                ok            = $false
                phase         = "exception"
                error         = [string]$_.Exception.Message
                timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
            }) -Depth 8
        }
        catch {
            # Best effort only.
        }
    }
    throw
}

$runId = (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss_fff")
$reportPath = Join-Path $reportsDir ("stack_reset_{0}.json" -f $runId)

$contractPorts = $null
try {
    $contractPorts = Get-ContractPorts -RepoRoot $repoRoot
}
catch {
    $errorMessage = $_.Exception.Message
    Write-JsonFile -Path $stackResetLastPath -Object ([ordered]@{
        ok = $false
        error = $errorMessage
        phase = "get_contract_ports"
        timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    }) -Depth 8
    Write-ResetLog ("Get-ContractPorts failed: {0}" -f $errorMessage) "ERROR"
    exit 1
}

$targetPorts = @(
    [int]$contractPorts.mason_api,
    [int]$contractPorts.seed_api,
    [int]$contractPorts.bridge,
    [int]$contractPorts.athena,
    [int]$contractPorts.onyx
)
$coreUrls = @(
    "http://127.0.0.1:$($contractPorts.mason_api)/health",
    "http://127.0.0.1:$($contractPorts.seed_api)/health",
    "http://127.0.0.1:$($contractPorts.bridge)/health",
    "http://127.0.0.1:$($contractPorts.athena)/api/health",
    "http://127.0.0.1:$($contractPorts.onyx)/main.dart.js"
)

$alreadyGreen = Wait-EndpointsReady -Urls $coreUrls -TimeoutSeconds ([Math]::Min([Math]::Max(5, $ReadinessTimeoutSeconds), 12))
if ($alreadyGreen) {
    $shortSnapshot = Get-PortSnapshot -Ports $targetPorts
    $singletonDrift = @(Get-RuntimeSingletonDrift -RepoRoot $repoRoot -ContractPorts $contractPorts -PortSnapshot $shortSnapshot)
    if ($singletonDrift.Count -eq 0) {
        $shortReport = [ordered]@{
            generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
            run_id           = $runId
            root_path        = $repoRoot
            target_ports     = $targetPorts
            ok               = $true
            phase            = "already_green_short_circuit"
            summary          = "All required endpoints were already healthy and singleton runtime truth was clean. Relaunch skipped."
            ports_before     = $shortSnapshot
            ports_after      = $shortSnapshot
            singleton_drift_before = @()
            singleton_drift_after  = @()
            stop_phase       = [ordered]@{
                skipped = $true
                reason  = "already_green"
            }
            start_phase      = [ordered]@{
                skipped = $true
                reason  = "already_green"
            }
        }
        Write-JsonFile -Path $reportPath -Object $shortReport -Depth 16
        Write-JsonFile -Path $stackResetLastPath -Object $shortReport -Depth 16
        Write-ResetLog "All required endpoints are already healthy and singleton runtime truth is clean; short-circuiting without relaunch."
        exit 0
    }

    $driftSummary = (($singletonDrift | ForEach-Object { $_.detail }) -join "; ")
    Write-ResetLog ("Endpoints are healthy but singleton drift was detected; continuing with full reset/start. {0}" -f $driftSummary) "WARN"
}

$beforeSnapshot = Get-PortSnapshot -Ports $targetPorts
$beforeSingletonDrift = @(Get-RuntimeSingletonDrift -RepoRoot $repoRoot -ContractPorts $contractPorts -PortSnapshot $beforeSnapshot)
$listenerPids = New-Object System.Collections.Generic.List[int]
foreach ($row in @($beforeSnapshot)) {
    foreach ($listener in @($row.listeners)) {
        $pidValue = [int]$listener.owning_pid
        if ($pidValue -gt 0 -and -not $listenerPids.Contains($pidValue)) {
            $listenerPids.Add($pidValue) | Out-Null
        }
    }
}

$knownCandidates = @(Get-KnownRepoProcessCandidates -RepoRoot $repoRoot)
$candidatePids = New-Object System.Collections.Generic.List[int]
foreach ($cand in $knownCandidates) {
    if ($cand.pid -gt 0 -and -not $candidatePids.Contains([int]$cand.pid)) {
        $candidatePids.Add([int]$cand.pid) | Out-Null
    }
}

$allPids = New-Object System.Collections.Generic.List[int]
foreach ($pidValue in @($listenerPids.ToArray() + $candidatePids.ToArray() | Sort-Object -Unique)) {
    if ($pidValue -gt 0 -and -not $allPids.Contains([int]$pidValue)) {
        $allPids.Add([int]$pidValue) | Out-Null
    }
}

Write-ResetLog ("Stopping process candidates: {0}" -f (@($allPids.ToArray()).Count))
$stopResults = Stop-ProcessIdsBestEffort -Pids @($allPids.ToArray())
Start-Sleep -Seconds 2

$startScript = Join-Path $repoRoot "Start_Mason2.ps1"
if (-not (Test-Path -LiteralPath $startScript)) {
    throw "Missing start script: $startScript"
}

Write-ResetLog "Starting stack in deterministic order (Core -> Bridge -> Athena -> Onyx) via Start_Mason2.ps1 -FullStack"
$startExit = 0
$startException = $null
$startTimedOut = $false
$startStdoutPath = Join-Path $reportsDir "stack_reset_start_stdout.log"
$startStderrPath = Join-Path $reportsDir "stack_reset_start_stderr.log"
try {
    if (Test-Path -LiteralPath $startStdoutPath) {
        Remove-Item -LiteralPath $startStdoutPath -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $startStderrPath) {
        Remove-Item -LiteralPath $startStderrPath -Force -ErrorAction SilentlyContinue
    }

    $startArgs = @(
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        ('"' + $startScript + '"'),
        "-FullStack",
        "-ReadinessTimeoutSeconds",
        [string]$ReadinessTimeoutSeconds
    )

    $startProc = Start-Process -FilePath "powershell.exe" `
        -ArgumentList $startArgs `
        -WorkingDirectory $repoRoot `
        -PassThru `
        -RedirectStandardOutput $startStdoutPath `
        -RedirectStandardError $startStderrPath

    $startDeadline = (Get-Date).AddSeconds([Math]::Max(30, $HardTimeoutSeconds))
    $procStillRunning = $true
    while ((Get-Date) -lt $startDeadline) {
        if (Test-EndpointsReadyOnce -Urls $coreUrls) {
            $startExit = 0
            break
        }

        $procStillRunning = [bool](Get-Process -Id $startProc.Id -ErrorAction SilentlyContinue)
        if (-not $procStillRunning) {
            $startProc.Refresh()
            $startExit = [int]$startProc.ExitCode
            break
        }

        Start-Sleep -Seconds 2
    }

    if ((Get-Date) -ge $startDeadline -and $startExit -eq 0 -and -not (Test-EndpointsReadyOnce -Urls $coreUrls)) {
        $startTimedOut = $true
    }

    if ($startTimedOut) {
        try {
            Stop-Process -Id $startProc.Id -Force -ErrorAction SilentlyContinue
        }
        catch {
            # Best effort kill.
        }
        $startExit = 124
    }
}
catch {
    $startException = $_.Exception.Message
    if ($startExit -eq 0) {
        $startExit = 1
    }
}

if ($startTimedOut) {
    $timeoutHint = "Stack reset/start timed out after $HardTimeoutSeconds second(s)."
    if (-not $startException) {
        $startException = $timeoutHint
    }
    $lastFailurePath = Join-Path (Join-Path $repoRoot "reports\start") "last_failure.json"
    $startCommand = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\\tools\\ops\\Stack_Reset_And_Start.ps1 -RootPath `"$repoRoot`""
    Write-LastFailureJson -Path $lastFailurePath -Component "launcher" -Command $startCommand -ExitCode 124 -StderrPath $startStderrPath -Hint $timeoutHint
}

$afterSnapshot = Get-PortSnapshot -Ports $targetPorts
$afterSingletonDrift = @(Get-RuntimeSingletonDrift -RepoRoot $repoRoot -ContractPorts $contractPorts -PortSnapshot $afterSnapshot)
$startRunLastPath = Join-Path $repoRoot "reports\start\start_run_last.json"
$startRunLast = Read-JsonSafe -Path $startRunLastPath -Default $null
$failureArtifactPath = $null
$firstFailureComponent = $null
$firstFailureLog = $null
$firstFailureError = $null
if ($startRunLast -and ($startRunLast.PSObject.Properties.Name -contains "start_failure_artifact") -and $startRunLast.start_failure_artifact) {
    $failureArtifactPath = [string]$startRunLast.start_failure_artifact
}
$failureArtifact = if ($failureArtifactPath) { Read-JsonSafe -Path $failureArtifactPath -Default $null } else { $null }
if ($failureArtifact -and ($failureArtifact.PSObject.Properties.Name -contains "failures")) {
    $firstFailure = @($failureArtifact.failures | Select-Object -First 1)
    if ($firstFailure.Count -gt 0) {
        $firstFailureComponent = [string]$firstFailure[0].component
        $firstFailureLog = [string]$firstFailure[0].stderr_log
        $firstFailureError = [string]$firstFailure[0].probe_error
    }
}

$allReady = Wait-EndpointsReady -Urls $coreUrls -TimeoutSeconds $ReadinessTimeoutSeconds

$ok = ($startExit -eq 0 -and -not $startException -and $allReady)
$summary = if ($ok) {
    "Stack reset/start succeeded."
}
elseif ($firstFailureComponent) {
    "FAILED: $firstFailureComponent. Log: $firstFailureLog"
}
elseif ($startException) {
    "FAILED: start script exception: $startException"
}
else {
    "FAILED: readiness did not pass for all components."
}

$report = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    run_id           = $runId
    root_path        = $repoRoot
    start_order      = @("core", "bridge", "athena", "onyx")
    target_ports     = $targetPorts
    stop_phase       = [ordered]@{
        listener_pids  = @($listenerPids.ToArray())
        candidate_pids = @($candidatePids.ToArray())
        stop_results   = @($stopResults)
    }
    start_phase      = [ordered]@{
        script_path             = $startScript
        exit_code               = [int]$startExit
        timed_out               = [bool]$startTimedOut
        hard_timeout_seconds    = [int]$HardTimeoutSeconds
        exception               = $startException
        stdout_log              = $startStdoutPath
        stderr_log              = $startStderrPath
        start_run_last          = $startRunLastPath
        start_failure_artifact  = $failureArtifactPath
        first_failure_component = $firstFailureComponent
        first_failure_log       = $firstFailureLog
        first_failure_error     = $firstFailureError
        readiness_all_ok        = [bool]$allReady
    }
    ports_before     = $beforeSnapshot
    ports_after      = $afterSnapshot
    singleton_drift_before = @($beforeSingletonDrift)
    singleton_drift_after  = @($afterSingletonDrift)
    ok               = [bool]$ok
    summary          = $summary
}

Write-JsonFile -Path $reportPath -Object $report -Depth 16
Write-JsonFile -Path $stackResetLastPath -Object $report -Depth 16
Write-ResetLog ("Report written: {0}" -f $reportPath)

if (-not $ok) {
    Write-ResetLog $summary "ERROR"
    if ($firstFailureLog) {
        Write-ResetLog ("See log: {0}" -f $firstFailureLog) "ERROR"
    }
    exit 1
}

Write-ResetLog "Stack reset and start completed."
exit 0
