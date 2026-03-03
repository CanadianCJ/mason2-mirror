[CmdletBinding()]
param(
    [string]$RootPath = "",
    [int]$ReadinessTimeoutSeconds = 90
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

function Get-PortSnapshot {
    param([int[]]$Ports)

    $rows = @()
    foreach ($port in @($Ports | Sort-Object -Unique)) {
        $listeners = @()
        try {
            $netRows = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
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
        "MasonConsole\\server.py"
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

if (-not $RootPath) {
    $RootPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}
$repoRoot = [System.IO.Path]::GetFullPath($RootPath)
$reportsDir = Join-Path $repoRoot "reports"
New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
$stackResetLastPath = Join-Path $reportsDir "stack_reset_last.json"

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

$beforeSnapshot = Get-PortSnapshot -Ports $targetPorts
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
try {
    & $startScript -FullStack -ReadinessTimeoutSeconds $ReadinessTimeoutSeconds
    if ($null -ne $LASTEXITCODE) {
        $startExit = [int]$LASTEXITCODE
    }
}
catch {
    $startException = $_.Exception.Message
    if ($startExit -eq 0) {
        $startExit = 1
    }
}

$afterSnapshot = Get-PortSnapshot -Ports $targetPorts
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

$coreUrls = @(
    "http://127.0.0.1:$($contractPorts.mason_api)/health",
    "http://127.0.0.1:$($contractPorts.seed_api)/health",
    "http://127.0.0.1:$($contractPorts.bridge)/health",
    "http://127.0.0.1:$($contractPorts.athena)/api/health",
    "http://127.0.0.1:$($contractPorts.onyx)/main.dart.js"
)
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
        exception               = $startException
        start_run_last          = $startRunLastPath
        start_failure_artifact  = $failureArtifactPath
        first_failure_component = $firstFailureComponent
        first_failure_log       = $firstFailureLog
        first_failure_error     = $firstFailureError
        readiness_all_ok        = [bool]$allReady
    }
    ports_before     = $beforeSnapshot
    ports_after      = $afterSnapshot
    ok               = [bool]$ok
    summary          = $summary
}

Write-JsonFile -Path $reportPath -Object $report -Depth 16
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
