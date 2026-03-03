[CmdletBinding()]
param(
    [switch]$CoreOnly,
    [bool]$WithBridge = $true,
    [switch]$WithAthena,
    [switch]$WithOnyx,
    [switch]$FullStack,
    [switch]$NoWatcher,
    [switch]$EnableTaskGen,
    [int]$ReadinessTimeoutSeconds = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-LaunchLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$stamp] [Start_Mason2] [$Level] $Message"
}

function Read-JsonSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$Required
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        if ($Required) {
            throw "Required JSON file not found: $Path"
        }
        return $null
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if (-not $raw.Trim()) {
        if ($Required) {
            throw "Required JSON file is empty: $Path"
        }
        return $null
    }

    try {
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        if ($Required) {
            throw "Failed to parse JSON file $Path : $($_.Exception.Message)"
        }
        Write-LaunchLog "Failed to parse optional JSON file $Path : $($_.Exception.Message)" "WARN"
        return $null
    }
}

function Get-ContractPort {
    param(
        [Parameter(Mandatory = $true)]$PortsConfig,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][int]$Default
    )

    $value = $Default
    if ($PortsConfig -and
        ($PortsConfig.PSObject.Properties.Name -contains "ports") -and
        $PortsConfig.ports -and
        ($PortsConfig.ports.PSObject.Properties.Name -contains $Key)) {
        $tmp = 0
        if ([int]::TryParse([string]$PortsConfig.ports.$Key, [ref]$tmp) -and $tmp -gt 0 -and $tmp -le 65535) {
            $value = $tmp
        }
        else {
            throw "Invalid port value for '$Key' in config/ports.json."
        }
    }
    else {
        throw "Missing required ports contract key '$Key' in config/ports.json."
    }

    return [int]$value
}

function Get-ContractBindHost {
    param(
        [Parameter(Mandatory = $true)]$PortsConfig
    )

    $bindHostValue = "127.0.0.1"
    if ($PortsConfig -and ($PortsConfig.PSObject.Properties.Name -contains "bind_host") -and $PortsConfig.bind_host) {
        $bindHostValue = [string]$PortsConfig.bind_host
    }

    if ($bindHostValue -ne "127.0.0.1") {
        throw "config/ports.json bind_host must be 127.0.0.1. Refusing non-loopback binding."
    }

    return $bindHostValue
}

function Assert-Sidecar7000Off {
    param(
        [Parameter(Mandatory = $true)]$PortsConfig
    )

    if (-not $PortsConfig -or -not ($PortsConfig.PSObject.Properties.Name -contains "ports") -or -not $PortsConfig.ports) {
        return
    }

    foreach ($prop in @($PortsConfig.ports.PSObject.Properties)) {
        if (-not $prop) { continue }
        $portVal = 0
        if ([int]::TryParse([string]$prop.Value, [ref]$portVal)) {
            if ($portVal -eq 7000) {
                throw "Sidecar7000 must remain OFF. Found port 7000 in config/ports.json key '$($prop.Name)'."
            }
        }
    }
}

function ConvertTo-HashtableShallow {
    param($Value)

    if ($null -eq $Value) {
        return @{}
    }

    if ($Value -is [hashtable]) {
        return $Value
    }

    $out = @{}
    foreach ($p in $Value.PSObject.Properties) {
        $out[$p.Name] = $p.Value
    }
    return $out
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 12
    )

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $json = $Object | ConvertTo-Json -Depth $Depth
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Get-LogTailChars {
    param(
        [string]$Path,
        [int]$MaxChars = 200
    )

    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if (-not $raw) {
            return $null
        }
        if ($raw.Length -le $MaxChars) {
            return $raw
        }
        return $raw.Substring($raw.Length - $MaxChars)
    }
    catch {
        return $null
    }
}

function Resolve-EndpointComponent {
    param([string]$EndpointName)

    $name = ([string]$EndpointName).ToLowerInvariant()
    switch -Regex ($name) {
        "^bridge" { return "bridge" }
        "^athena" { return "athena" }
        "^onyx" { return "onyx" }
        "^mason_api" { return "mason_api" }
        "^seed_api" { return "seed_api" }
        default { return $name }
    }
}

function Write-StartFailureArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$ArtifactPath,
        [Parameter(Mandatory = $true)][string]$RunId,
        [Parameter(Mandatory = $true)]$RequiredFailures,
        [Parameter(Mandatory = $true)]$LaunchResults
    )

    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($failure in @($RequiredFailures)) {
        $component = Resolve-EndpointComponent -EndpointName $failure.name
        $launch = $null
        $launchCandidate = @($LaunchResults | Where-Object { $_.component -eq $component } | Select-Object -First 1)
        if ($launchCandidate.Count -gt 0) {
            $launch = $launchCandidate[0]
        }
        elseif ($component -eq "mason_api" -or $component -eq "seed_api") {
            $coreCandidate = @($LaunchResults | Where-Object { $_.component -eq "core" } | Select-Object -First 1)
            if ($coreCandidate.Count -gt 0) {
                $launch = $coreCandidate[0]
            }
        }
        $commandline = $null
        $stdoutPath = $null
        $stderrPath = $null
        $exitCode = $null

        if ($null -ne $launch) {
            $commandline = $launch.commandline
            $stdoutPath = $launch.stdout_log
            $stderrPath = $launch.stderr_log
            if ($launch.PSObject.Properties.Name -contains "process_alive") {
                if (-not [bool]$launch.process_alive) {
                    $exitCode = 1
                }
            }
        }

        $rows.Add([pscustomobject]@{
            component        = $component
            readiness_name   = [string]$failure.name
            readiness_url    = [string]$failure.url
            commandline      = $commandline
            exit_code        = $exitCode
            stderr_log       = $stderrPath
            stdout_log       = $stdoutPath
            stderr_tail_200  = Get-LogTailChars -Path $stderrPath -MaxChars 200
            stdout_tail_200  = Get-LogTailChars -Path $stdoutPath -MaxChars 200
            timestamp        = (Get-Date).ToUniversalTime().ToString("o")
            probe_error      = if ($failure.last_probe) { [string]$failure.last_probe.error } else { $null }
            probe_status     = if ($failure.last_probe) { $failure.last_probe.status_code } else { $null }
        }) | Out-Null
    }

    $payload = [ordered]@{
        generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        run_id           = $RunId
        failure_count    = @($rows).Count
        failures         = @($rows.ToArray())
    }
    Write-JsonFile -Path $ArtifactPath -Object $payload -Depth 12
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
        hint          = if ($Hint) { [string]$Hint } else { "Inspect start logs for failure details." }
        timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    }

    try {
        Write-JsonFile -Path $Path -Object $payload -Depth 8
        return $true
    }
    catch {
        Write-LaunchLog ("Could not write last failure JSON at {0}: {1}" -f $Path, $_.Exception.Message) "WARN"
        return $false
    }
}

function Test-ScheduledTaskExists {
    param(
        [Parameter(Mandatory = $true)][string]$TaskName,
        [string]$TaskPath = "\Mason2\"
    )

    if (-not (Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue)) {
        return $false
    }

    try {
        $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction Stop
        return ($null -ne $task)
    }
    catch {
        try {
            $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop | Select-Object -First 1
            return ($null -ne $task)
        }
        catch {
            return $false
        }
    }
}

function Update-IngestAutopilotStatus {
    param(
        [Parameter(Mandatory = $true)][string]$StatusPath,
        [Parameter(Mandatory = $true)][hashtable]$Fields
    )

    $current = [ordered]@{}
    if (Test-Path -LiteralPath $StatusPath) {
        try {
            $raw = Get-Content -LiteralPath $StatusPath -Raw -Encoding UTF8
            if ($raw.Trim()) {
                $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
                foreach ($p in $parsed.PSObject.Properties) {
                    $current[$p.Name] = $p.Value
                }
            }
        }
        catch {
            $current = [ordered]@{}
        }
    }

    foreach ($k in $Fields.Keys) {
        $current[$k] = $Fields[$k]
    }
    $current["updated_at_utc"] = (Get-Date).ToUniversalTime().ToString("o")

    Write-JsonFile -Path $StatusPath -Object $current -Depth 16
}

function Get-ProcessByCommandFragment {
    param(
        [Parameter(Mandatory = $true)][string]$Fragment
    )

    if ([string]::IsNullOrWhiteSpace($Fragment)) {
        return @()
    }

    try {
        $procs = Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
            ($_.Name -ieq "powershell.exe" -or $_.Name -ieq "pwsh.exe") -and
            $_.CommandLine -and
            $_.CommandLine.IndexOf($Fragment, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
        }
        return @($procs)
    }
    catch {
        Write-LaunchLog "Could not inspect process command lines: $($_.Exception.Message)" "WARN"
        return @()
    }
}

function Start-ScriptWindow {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [string[]]$ArgumentList = @(),
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [string]$ComponentId = "",
        [string]$LogsDirectory = "",
        [string]$RunId = "",
        [string]$ReuseFragment,
        [switch]$Minimized
    )

    $component = if ($ComponentId) { [string]$ComponentId } else { [System.IO.Path]::GetFileNameWithoutExtension($ScriptPath) }
    $logRoot = $LogsDirectory
    if (-not $logRoot) {
        $logRoot = Join-Path $WorkingDirectory "reports\start"
    }
    New-Item -ItemType Directory -Path $logRoot -Force | Out-Null

    $runToken = if ($RunId) { [string]$RunId } elseif ($env:MASON_START_RUN_ID) { [string]$env:MASON_START_RUN_ID } else { (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss_fff") }

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        return [pscustomobject]@{
            component    = $component
            script        = $ScriptPath
            started       = $false
            reused        = $false
            missing       = $true
            pid           = $null
            process_alive = $false
            commandline   = $null
            stdout_log    = $null
            stderr_log    = $null
            message       = "missing"
        }
    }

    if ($ReuseFragment) {
        $existing = Get-ProcessByCommandFragment -Fragment $ReuseFragment | Select-Object -First 1
        if ($existing) {
            return [pscustomobject]@{
                component    = $component
                script        = $ScriptPath
                started       = $false
                reused        = $true
                missing       = $false
                pid           = [int]$existing.ProcessId
                process_alive = $true
                commandline   = [string]$existing.CommandLine
                stdout_log    = $null
                stderr_log    = $null
                message       = "reused"
            }
        }
    }

    $scriptExtension = ([System.IO.Path]::GetExtension($ScriptPath)).ToLowerInvariant()
    $launcherExe = $null
    $args = @()
    switch ($scriptExtension) {
        ".py" {
            $pythonCmd = Get-Command python.exe -ErrorAction SilentlyContinue
            if (-not $pythonCmd) {
                $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
            }
            $launcherExe = if ($pythonCmd) { [string]$pythonCmd.Source } else { "python" }
            $args = @("-u", $ScriptPath)
        }
        ".js" {
            $nodeCmd = Get-Command node.exe -ErrorAction SilentlyContinue
            if (-not $nodeCmd) {
                $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
            }
            if (-not $nodeCmd) {
                throw "Node.js launcher not found for script: $ScriptPath"
            }
            $launcherExe = [string]$nodeCmd.Source
            $args = @($ScriptPath)
        }
        default {
            $psExe = (Get-Command powershell.exe -ErrorAction SilentlyContinue).Source
            if (-not $psExe) { $psExe = "powershell.exe" }
            $launcherExe = $psExe
            $args = @("-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ScriptPath)
        }
    }
    if ($ArgumentList -and $ArgumentList.Count -gt 0) {
        $args += $ArgumentList
    }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeComponent = [regex]::Replace($component.ToLowerInvariant(), "[^a-z0-9._-]+", "_")
    $stdoutLog = Join-Path $logRoot ("{0}_{1}_{2}_stdout.log" -f $runToken, $safeComponent, $stamp)
    $stderrLog = Join-Path $logRoot ("{0}_{1}_{2}_stderr.log" -f $runToken, $safeComponent, $stamp)
    $argText = ($args | ForEach-Object { if ([string]$_ -match "\s") { '"' + [string]$_ + '"' } else { [string]$_ } }) -join " "
    $commandline = "{0} {1}" -f $launcherExe, $argText

    $startParams = @{
        FilePath         = $launcherExe
        ArgumentList     = $args
        WorkingDirectory = $WorkingDirectory
        PassThru         = $true
        RedirectStandardOutput = $stdoutLog
        RedirectStandardError  = $stderrLog
        WindowStyle      = if ($Minimized) { "Minimized" } else { "Normal" }
    }

    $proc = Start-Process @startParams
    $processAlive = [bool](Get-Process -Id $proc.Id -ErrorAction SilentlyContinue)
    return [pscustomobject]@{
        component    = $component
        script        = $ScriptPath
        started       = $true
        reused        = $false
        missing       = $false
        pid           = [int]$proc.Id
        process_alive = $processAlive
        commandline   = $commandline
        stdout_log    = $stdoutLog
        stderr_log    = $stderrLog
        message       = "started"
    }
}

function Test-HttpEndpoint {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSec = 4
    )

    $probe = [ordered]@{
        url          = $Url
        ok           = $false
        status_code  = $null
        error        = $null
        checked_at   = (Get-Date).ToUniversalTime().ToString("o")
    }

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
        $probe.status_code = [int]$resp.StatusCode
        $probe.ok = ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400)
    }
    catch {
        $probe.error = $_.Exception.Message
    }

    return [pscustomobject]$probe
}

function Wait-ForEndpoints {
    param(
        [Parameter(Mandatory = $true)]$Endpoints,
        [int]$TimeoutSeconds = 90,
        [int]$PollSeconds = 2
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $state = @()

    foreach ($ep in $Endpoints) {
        $state += [pscustomobject]@{
            name      = [string]$ep.name
            url       = [string]$ep.url
            required  = [bool]$ep.required
            source    = [string]$ep.source
            ready     = $false
            attempts  = 0
            last_probe = $null
        }
    }

    while ((Get-Date) -lt $deadline) {
        foreach ($entry in $state) {
            if ($entry.ready) { continue }
            $probe = Test-HttpEndpoint -Url $entry.url
            $entry.attempts = [int]$entry.attempts + 1
            $entry.last_probe = $probe
            if ($probe.ok) {
                $entry.ready = $true
            }
        }

        $requiredPending = @($state | Where-Object { $_.required -and -not $_.ready })
        if ($requiredPending.Count -eq 0) {
            break
        }

        Start-Sleep -Seconds $PollSeconds
    }

    return $state
}

function Get-ReadinessEndpoints {
    param(
        $PortsConfig,
        $ServicesConfig,
        [string]$BindHost,
        [bool]$BridgeEnabled,
        [bool]$AthenaEnabled,
        [bool]$OnyxEnabled
    )

    $eps = @()

    $masonApiPort = Get-ContractPort -PortsConfig $PortsConfig -Key "mason_api" -Default 8383
    $seedApiPort = Get-ContractPort -PortsConfig $PortsConfig -Key "seed_api" -Default 8109
    $bridgePort = Get-ContractPort -PortsConfig $PortsConfig -Key "bridge" -Default 8484
    $athenaPort = Get-ContractPort -PortsConfig $PortsConfig -Key "athena" -Default 8000
    $onyxPort = Get-ContractPort -PortsConfig $PortsConfig -Key "onyx" -Default 5353

    $eps += [pscustomobject]@{
        name     = "mason_api_health"
        url      = ("http://{0}:{1}/health" -f $BindHost, $masonApiPort)
        required = $true
        source   = "config/ports.json"
    }
    $eps += [pscustomobject]@{
        name     = "seed_api_health"
        url      = ("http://{0}:{1}/health" -f $BindHost, $seedApiPort)
        required = $true
        source   = "config/ports.json"
    }
    $eps += [pscustomobject]@{
        name     = "bridge_health"
        url      = ("http://{0}:{1}/health" -f $BindHost, $bridgePort)
        required = [bool]$BridgeEnabled
        source   = "config/ports.json"
    }
    $eps += [pscustomobject]@{
        name     = "athena_health"
        url      = ("http://{0}:{1}/api/health" -f $BindHost, $athenaPort)
        required = [bool]$AthenaEnabled
        source   = "config/ports.json"
    }
    $eps += [pscustomobject]@{
        name     = "onyx_main_dart_js"
        url      = ("http://{0}:{1}/main.dart.js" -f $BindHost, $onyxPort)
        required = [bool]$OnyxEnabled
        source   = "config/ports.json"
    }

    if ($ServicesConfig -and ($ServicesConfig.PSObject.Properties.Name -contains "readiness")) {
        foreach ($cfg in @($ServicesConfig.readiness)) {
            if (-not $cfg) { continue }
            if (-not ($cfg.PSObject.Properties.Name -contains "url")) { continue }
            $url = [string]$cfg.url
            if (-not $url.Trim()) { continue }

            $name = if ($cfg.name) { [string]$cfg.name } else { "configured_endpoint" }
            $duplicate = @($eps | Where-Object { $_.name -eq $name -and $_.url -eq $url }).Count -gt 0
            if ($duplicate) { continue }

            $eps += [pscustomobject]@{
                name     = $name
                url      = $url
                required = if ($cfg.PSObject.Properties.Name -contains "required") { [bool]$cfg.required } else { $true }
                source   = "config/services.json"
            }
        }
    }

    return $eps
}

function Get-PortFromUrl {
    param([string]$Url)

    if (-not $Url) { return $null }
    try {
        $uri = [System.Uri]$Url
        if ($uri.Port -gt 0) {
            return [int]$uri.Port
        }
    }
    catch {
        return $null
    }
    return $null
}

function Get-PortSnapshot {
    param(
        [int[]]$Ports
    )

    $snapshots = @()
    foreach ($port in @($Ports | Sort-Object -Unique)) {
        $listeners = @()
        if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
            try {
                $rows = Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue
                foreach ($row in @($rows)) {
                    $listeners += [pscustomobject]@{
                        local_address = [string]$row.LocalAddress
                        owning_pid    = [int]$row.OwningProcess
                    }
                }
            }
            catch {
                $listeners = @()
            }
        }

        $snapshots += [pscustomobject]@{
            port            = [int]$port
            listener_count  = @($listeners).Count
            listeners       = @($listeners)
        }
    }
    return $snapshots
}

function Get-ReportSnapshot {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $exists = Test-Path -LiteralPath $Path
    $lastWriteUtc = $null
    $length = $null
    if ($exists) {
        try {
            $item = Get-Item -LiteralPath $Path -ErrorAction Stop
            $lastWriteUtc = $item.LastWriteTimeUtc.ToString("o")
            $length = [int64]$item.Length
        }
        catch {
            $exists = $false
        }
    }

    return [pscustomobject]@{
        path           = $Path
        exists         = [bool]$exists
        last_write_utc = $lastWriteUtc
        bytes          = $length
    }
}

function Invoke-PreWatcherPrep {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string]$RootPath,
        [hashtable]$NamedArguments = @{}
    )

    $result = [ordered]@{
        script   = $ScriptPath
        success  = $false
        message  = $null
    }

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        $result.message = "missing"
        return [pscustomobject]$result
    }

    try {
        Write-LaunchLog ("Running pre-watcher prep: {0}" -f (Split-Path -Leaf $ScriptPath))
        $invokeParams = [ordered]@{
            RootPath = $RootPath
        }
        if ($NamedArguments) {
            foreach ($k in $NamedArguments.Keys) {
                if (-not $k) { continue }
                if ($k -eq "RootPath") { continue }
                $invokeParams[$k] = $NamedArguments[$k]
            }
        }
        & $ScriptPath @invokeParams | Out-Null
        $result.success = $true
        $result.message = "ok"
    }
    catch {
        $result.message = $_.Exception.Message
    }

    return [pscustomobject]$result
}

function Find-OnyxLauncher {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot
    )

    $onyxRoot = Join-Path $RepoRoot "Component - Onyx App\onyx_business_manager"
    if (-not (Test-Path -LiteralPath $onyxRoot)) {
        return [pscustomobject]@{
            exists          = $false
            path            = $null
            valid_loopback  = $false
            message         = "onyx_root_missing"
        }
    }

    $candidate = Get-ChildItem -LiteralPath $onyxRoot -Filter "Start-Onyx5353.ps1" -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object FullName |
        Select-Object -First 1
    if (-not $candidate) {
        return [pscustomobject]@{
            exists          = $false
            path            = $null
            valid_loopback  = $false
            message         = "launcher_missing"
        }
    }

    $content = ""
    try {
        $content = Get-Content -LiteralPath $candidate.FullName -Raw -Encoding UTF8
    }
    catch {
        $content = ""
    }

    $mentionsHostArg = $content -match "--web-hostname"
    $enforcesLoopback = ($content -match "127\.0\.0\.1") -or ($content -match "MASON_BIND_HOST") -or ($content -match "bind host must be 127\.0\.0\.1")
    $valid = ($mentionsHostArg -and $enforcesLoopback)

    return [pscustomobject]@{
        exists          = $true
        path            = $candidate.FullName
        valid_loopback  = [bool]$valid
        message         = if ($valid) { "ok" } else { "launcher_missing_loopback_guard" }
    }
}

function Open-ReadyBrowsers {
    param(
        [Parameter(Mandatory = $true)]$Readiness,
        [Parameter(Mandatory = $true)][bool]$AthenaEnabled,
        [Parameter(Mandatory = $true)][bool]$OnyxEnabled
    )

    $opened = New-Object System.Collections.Generic.List[string]
    if ($AthenaEnabled) {
        $athena = @($Readiness | Where-Object { $_.name -eq "athena_health" } | Select-Object -First 1)
        if ($athena -and $athena.ready) {
            try {
                Start-Process ("http://127.0.0.1:{0}/athena/" -f $env:MASON_ATHENA_PORT) | Out-Null
                $opened.Add("athena") | Out-Null
            }
            catch {
                Write-LaunchLog ("Could not open Athena browser URL: {0}" -f $_.Exception.Message) "WARN"
            }
        }
    }

    if ($OnyxEnabled) {
        $onyx = @($Readiness | Where-Object { $_.name -eq "onyx_main_dart_js" } | Select-Object -First 1)
        if ($onyx -and $onyx.ready) {
            try {
                Start-Process ("http://127.0.0.1:{0}/" -f $env:MASON_ONYX_PORT) | Out-Null
                $opened.Add("onyx") | Out-Null
            }
            catch {
                Write-LaunchLog ("Could not open Onyx browser URL: {0}" -f $_.Exception.Message) "WARN"
            }
        }
    }

    return @($opened.ToArray())
}

$script:StartRunIdContext = $null
$script:StartFailureArtifactPathContext = $null
$script:StartFailureTrapWritten = $false
$script:RequestedStartModeContext = if ($FullStack) { "-FullStack" } elseif ($CoreOnly) { "-CoreOnly" } else { "" }
$script:LastFailurePathContext = $null
$script:LastFailureTrapWritten = $false

trap {
    if (-not $script:StartFailureTrapWritten -and $script:StartFailureArtifactPathContext -and $script:StartRunIdContext) {
        try {
            $payload = [ordered]@{
                generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
                run_id           = [string]$script:StartRunIdContext
                failure_count    = 1
                failures         = @(
                    [ordered]@{
                        component        = "launcher"
                        readiness_name   = "startup_exception"
                        readiness_url    = $null
                        commandline      = ("powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}" -f $MyInvocation.MyCommand.Path)
                        exit_code        = 1
                        stderr_log       = $null
                        stdout_log       = $null
                        stderr_tail_200  = [string]$_.Exception.Message
                        stdout_tail_200  = $null
                        timestamp        = (Get-Date).ToUniversalTime().ToString("o")
                        probe_error      = [string]$_.Exception.Message
                        probe_status     = $null
                    }
                )
            }
            Write-JsonFile -Path $script:StartFailureArtifactPathContext -Object $payload -Depth 12
            $script:StartFailureTrapWritten = $true
        }
        catch {
            # Best effort only; preserve original exception flow.
        }
    }
    if (-not $script:LastFailureTrapWritten) {
        try {
            $lastFailurePath = $script:LastFailurePathContext
            if (-not $lastFailurePath) {
                $trapBase = Split-Path -Parent $MyInvocation.MyCommand.Path
                if (-not $trapBase) {
                    $trapBase = (Get-Location).Path
                }
                $lastFailurePath = Join-Path (Join-Path $trapBase "reports\start") "last_failure.json"
            }

            $hintMessage = if ($_.Exception -and $_.Exception.Message) { [string]$_.Exception.Message } else { "Startup failed with an exception." }
            $modeArg = if ($script:RequestedStartModeContext) { " {0}" -f $script:RequestedStartModeContext } else { "" }
            $commandText = ("powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}{1}" -f $MyInvocation.MyCommand.Path, $modeArg)
            $written = Write-LastFailureJson -Path $lastFailurePath -Component "launcher" -Command $commandText -ExitCode 1 -StderrPath $null -Hint $hintMessage
            if ($written) {
                $script:LastFailureTrapWritten = $true
            }
        }
        catch {
            # Best effort only; preserve original exception flow.
        }
    }
    throw
}

# ---- Main ----
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Base) {
    $Base = (Get-Location).Path
}

$ConfigDir = Join-Path $Base "config"
$ToolsDir = Join-Path $Base "tools"
$StateKnowledgeDir = Join-Path $Base "state\knowledge"
$ReportsDir = Join-Path $Base "reports"
$StartReportsDir = Join-Path $ReportsDir "start"
$KnowledgeDir = Join-Path $Base "knowledge"
$KnowledgeInboxDir = Join-Path $KnowledgeDir "inbox"
$KnowledgePendingLlmDir = Join-Path $KnowledgeDir "pending_llm"

New-Item -ItemType Directory -Path $StateKnowledgeDir -Force | Out-Null
New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
New-Item -ItemType Directory -Path $StartReportsDir -Force | Out-Null
New-Item -ItemType Directory -Path $KnowledgeInboxDir -Force | Out-Null
New-Item -ItemType Directory -Path $KnowledgePendingLlmDir -Force | Out-Null

$startRunId = "{0}_{1}" -f (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss_fff"), ([guid]::NewGuid().ToString("N").Substring(0, 6))
$env:MASON_START_RUN_ID = $startRunId
$startRunManifestPath = Join-Path $StartReportsDir ("start_run_{0}.json" -f $startRunId)
$startRunLastPath = Join-Path $StartReportsDir "start_run_last.json"
$startFailureArtifactPath = Join-Path $StartReportsDir ("start_failures_{0}.json" -f $startRunId)
$lastFailurePath = Join-Path $StartReportsDir "last_failure.json"
$script:StartRunIdContext = $startRunId
$script:StartFailureArtifactPathContext = $startFailureArtifactPath
$script:LastFailurePathContext = $lastFailurePath
if (Test-Path -LiteralPath $lastFailurePath) {
    Remove-Item -LiteralPath $lastFailurePath -Force -ErrorAction SilentlyContinue
}

$stackPidPath = Join-Path $StateKnowledgeDir "stack_pids.json"
$stackLastPidPath = Join-Path $StateKnowledgeDir "stack_last_pids.json"
$statusPath = Join-Path $ReportsDir "mason2_core_status.json"

$servicesPath = Join-Path $ConfigDir "services.json"
$portsPath = Join-Path $ConfigDir "ports.json"
$componentRegistryPath = Join-Path $ConfigDir "component_registry.json"
$riskPolicyPath = Join-Path $ConfigDir "risk_policy.json"
$backupPolicyPath = Join-Path $ConfigDir "backup_policy.json"
$ingestPolicyPath = Join-Path $ConfigDir "ingest_policy.json"
$ingestAutopilotStatusPath = Join-Path $ReportsDir "ingest_autopilot_status.json"
$ingestInstallTaskPath = Join-Path $ToolsDir "ingest\Install_Mason_Ingest_Autopilot_Task.ps1"
$ingestRunOncePath = Join-Path $ToolsDir "ingest\Mason_IngestDrop_Once.ps1"
$mirrorInstallTaskPath = Join-Path $ToolsDir "sync\Install_Mason_Mirror_Update_Task.ps1"
$componentInventoryPath = Join-Path $ToolsDir "Mason_Component_Inventory.ps1"

$servicesConfig = Read-JsonSafe -Path $servicesPath -Required
$portsConfig = Read-JsonSafe -Path $portsPath -Required
$componentRegistry = Read-JsonSafe -Path $componentRegistryPath -Required
$riskPolicy = Read-JsonSafe -Path $riskPolicyPath -Required
$backupPolicy = Read-JsonSafe -Path $backupPolicyPath -Required
$ingestPolicy = Read-JsonSafe -Path $ingestPolicyPath

$ingestEnabled = $false
$ingestAutoInstall = $false
$ingestAutoRunOnBoot = $false
if ($ingestPolicy -and ($ingestPolicy.PSObject.Properties.Name -contains "enabled")) {
    $ingestEnabled = [bool]$ingestPolicy.enabled
}
if ($ingestPolicy -and ($ingestPolicy.PSObject.Properties.Name -contains "auto_install_task")) {
    $ingestAutoInstall = [bool]$ingestPolicy.auto_install_task
}
if ($ingestPolicy -and ($ingestPolicy.PSObject.Properties.Name -contains "auto_run_on_boot")) {
    $ingestAutoRunOnBoot = [bool]$ingestPolicy.auto_run_on_boot
}

if ($ingestEnabled) {
    $ingestDropDir = if ($ingestPolicy -and ($ingestPolicy.PSObject.Properties.Name -contains "drop_dir") -and $ingestPolicy.drop_dir) { [string]$ingestPolicy.drop_dir } else { (Join-Path $Base "drop\ingest") }
    $ingestProcessedDir = if ($ingestPolicy -and ($ingestPolicy.PSObject.Properties.Name -contains "processed_dir") -and $ingestPolicy.processed_dir) { [string]$ingestPolicy.processed_dir } else { (Join-Path $Base "drop\processed") }

    New-Item -ItemType Directory -Path $ingestDropDir -Force | Out-Null
    New-Item -ItemType Directory -Path $ingestProcessedDir -Force | Out-Null

    $ingestTaskExists = Test-ScheduledTaskExists -TaskName "Mason2 Ingest Autopilot" -TaskPath "\Mason2\"
    $mirrorTaskExists = Test-ScheduledTaskExists -TaskName "Mason2 Mirror Update" -TaskPath "\Mason2\"
    $bootstrapWarnings = New-Object System.Collections.Generic.List[string]

    if (-not $ingestTaskExists) {
        if ($ingestAutoInstall -and (Test-Path -LiteralPath $ingestInstallTaskPath)) {
            try {
                & $ingestInstallTaskPath -RootPath $Base | Out-Null
                $ingestTaskExists = Test-ScheduledTaskExists -TaskName "Mason2 Ingest Autopilot" -TaskPath "\Mason2\"
            }
            catch {
                $bootstrapWarnings.Add(("Auto-install failed for ingest task: {0}" -f $_.Exception.Message)) | Out-Null
            }
        }
        elseif (-not $ingestAutoInstall) {
            $bootstrapWarnings.Add("Scheduled task 'Mason2 Ingest Autopilot' is missing. Set ingest_policy.auto_install_task=true or run tools\\ingest\\Install_Mason_Ingest_Autopilot_Task.ps1.") | Out-Null
        }
    }
    if (-not $ingestTaskExists) {
        $bootstrapWarnings.Add("Scheduled task 'Mason2 Ingest Autopilot' is still missing after bootstrap checks. Run tools\\ingest\\Install_Mason_Ingest_Autopilot_Task.ps1 and verify Task Scheduler permissions.") | Out-Null
    }

    if (-not $mirrorTaskExists -and $ingestAutoInstall -and (Test-Path -LiteralPath $mirrorInstallTaskPath)) {
        try {
            & $mirrorInstallTaskPath -RootPath $Base | Out-Null
            $mirrorTaskExists = Test-ScheduledTaskExists -TaskName "Mason2 Mirror Update" -TaskPath "\Mason2\"
        }
        catch {
            $bootstrapWarnings.Add(("Auto-install failed for mirror update task: {0}" -f $_.Exception.Message)) | Out-Null
        }
    }
    elseif (-not $mirrorTaskExists -and -not $ingestAutoInstall) {
        $bootstrapWarnings.Add("Scheduled task 'Mason2 Mirror Update' is missing. Set ingest_policy.auto_install_task=true or run tools\\sync\\Install_Mason_Mirror_Update_Task.ps1.") | Out-Null
    }
    if (-not $mirrorTaskExists) {
        $bootstrapWarnings.Add("Scheduled task 'Mason2 Mirror Update' is still missing after bootstrap checks. Run tools\\sync\\Install_Mason_Mirror_Update_Task.ps1 and verify Task Scheduler permissions.") | Out-Null
    }

    $bootRunResult = "skipped"
    if ($ingestAutoRunOnBoot) {
        if (Test-Path -LiteralPath $ingestRunOncePath) {
            try {
                & $ingestRunOncePath -RootPath $Base | Out-Null
                $bootRunResult = "ok"
            }
            catch {
                $bootRunResult = "failed"
                $bootstrapWarnings.Add(("Boot ingest run failed: {0}" -f $_.Exception.Message)) | Out-Null
            }
        }
        else {
            $bootRunResult = "missing_script"
            $bootstrapWarnings.Add(("Boot ingest script missing: {0}" -f $ingestRunOncePath)) | Out-Null
        }
    }

    if ($bootstrapWarnings.Count -gt 0 -or -not $ingestTaskExists) {
        foreach ($warn in @($bootstrapWarnings.ToArray())) {
            Write-LaunchLog $warn "WARN"
        }
        Update-IngestAutopilotStatus -StatusPath $ingestAutopilotStatusPath -Fields @{
            mode = "warning"
            autopilot_bootstrap = [ordered]@{
                ingest_enabled            = $ingestEnabled
                auto_install_task         = $ingestAutoInstall
                auto_run_on_boot          = $ingestAutoRunOnBoot
                ingest_task_exists        = $ingestTaskExists
                mirror_task_exists        = $mirrorTaskExists
                boot_run_result           = $bootRunResult
                warnings                  = @($bootstrapWarnings.ToArray())
            }
        }
    }
}

$bindHost = Get-ContractBindHost -PortsConfig $portsConfig
Assert-Sidecar7000Off -PortsConfig $portsConfig

$masonApiPort = Get-ContractPort -PortsConfig $portsConfig -Key "mason_api" -Default 8383
$seedApiPort = Get-ContractPort -PortsConfig $portsConfig -Key "seed_api" -Default 8109
$bridgePort = Get-ContractPort -PortsConfig $portsConfig -Key "bridge" -Default 8484
$athenaPort = Get-ContractPort -PortsConfig $portsConfig -Key "athena" -Default 8000
$onyxPort = Get-ContractPort -PortsConfig $portsConfig -Key "onyx" -Default 5353

$env:MASON_BIND_HOST = $bindHost
$env:MASON_API_PORT = [string]$masonApiPort
$env:MASON_SEED_PORT = [string]$seedApiPort
$env:MASON_BRIDGE_PORT = [string]$bridgePort
$env:MASON_ATHENA_PORT = [string]$athenaPort
$env:MASON_ONYX_PORT = [string]$onyxPort
$env:MASON_SIDECAR7000_ENABLED = "false"

$bridgeEnabled = [bool]$WithBridge
if ($FullStack) {
    $WithAthena = $true
    $WithOnyx = $true
    $bridgeEnabled = $true
}
if ($CoreOnly) {
    $WithAthena = $false
    $WithOnyx = $false
    $bridgeEnabled = $false
}

$athenaEnabled = [bool]$WithAthena -or [bool]$FullStack
$onyxEnabled = [bool]$WithOnyx -or [bool]$FullStack

$profile = "CoreOnly"
if ($athenaEnabled -and $onyxEnabled) {
    $profile = "CoreWithAthenaOnyx"
}
elseif ($athenaEnabled) {
    $profile = "CoreWithAthena"
}
elseif ($onyxEnabled) {
    $profile = "CoreWithOnyx"
}

$onyxLauncher = Find-OnyxLauncher -RepoRoot $Base
$onyxStartPath = if ($onyxLauncher.exists) { [string]$onyxLauncher.path } else { (Join-Path $Base "Component - Onyx App\onyx_business_manager\Start-Onyx5353.ps1") }

Write-LaunchLog "Mode: $profile"
Write-LaunchLog ("Ports contract: mason_api={0}, seed_api={1}, bridge={2}, athena={3}, onyx={4}, bind_host={5}" -f $masonApiPort, $seedApiPort, $bridgePort, $athenaPort, $onyxPort, $bindHost)
if ($onyxEnabled) {
    if (-not $onyxLauncher.exists) {
        Write-LaunchLog "Onyx launcher was not discovered under Component - Onyx App\\onyx_business_manager." "WARN"
    }
    elseif (-not $onyxLauncher.valid_loopback) {
        Write-LaunchLog ("Onyx launcher found but loopback contract validation failed: {0}" -f $onyxLauncher.path) "WARN"
    }
}

$coreNoAppsPath = Join-Path $ToolsDir "Mason_Start_Core_NoApps.ps1"
$coreFallbackPath = Join-Path $ToolsDir "Mason_Start_All.ps1"
$watcherPath = Join-Path $ToolsDir "Mason_Executor_Watcher.ps1"
$tasksLoopPath = Join-Path $ToolsDir "Mason_Tasks_To_Approvals_Loop.ps1"
$riskNormalizePath = Join-Path $ToolsDir "Mason_Risk_Normalize.ps1"
$floodControlPath = Join-Path $ToolsDir "Mason_Approvals_FloodControl.ps1"
$driftManifestPath = Join-Path $ToolsDir "Mason_Drift_Manifest.ps1"
$taskGenPath = Join-Path $ToolsDir "Mason_TaskGen_Run.ps1"
$bridgeStartPath = Join-Path $ToolsDir "Start_Bridge.ps1"
$athenaStartPath = Join-Path $Base "Start-Athena.ps1"
$approvalsPosturePath = Join-Path $ReportsDir "approvals_posture.json"
$bridgeStatusPath = Join-Path $ReportsDir "bridge_status.json"
$watcherTriggerPath = Join-Path $ReportsDir "watcher_last_trigger.json"
$riskNormalizeReportPath = Join-Path $ReportsDir "risk_normalize_report.json"
$componentInventoryReportPath = Join-Path $ReportsDir "component_inventory.json"
$driftManifestReportPath = Join-Path $ReportsDir "drift_manifest.json"

$launchResults = New-Object System.Collections.Generic.List[object]
$preWatcherPrepResults = New-Object System.Collections.Generic.List[object]
$pidUpdates = [ordered]@{
    mode                     = $profile
    start_run_id             = $startRunId
    start_reports_dir        = $StartReportsDir
    canonical_launcher_pid   = [int]$PID
    canonical_launcher_start = (Get-Date).ToUniversalTime().ToString("o")
}

if (Test-Path -LiteralPath $componentInventoryPath) {
    $inventoryPrep = Invoke-PreWatcherPrep -ScriptPath $componentInventoryPath -RootPath $Base
    $preWatcherPrepResults.Add($inventoryPrep)
    if (-not $inventoryPrep.success) {
        Write-LaunchLog ("Component inventory generation failed: {0}" -f $inventoryPrep.message) "WARN"
    }
}
else {
    Write-LaunchLog ("Component inventory script missing: {0}" -f $componentInventoryPath) "WARN"
}

foreach ($prepScript in @($riskNormalizePath, $floodControlPath, $driftManifestPath)) {
    $prep = Invoke-PreWatcherPrep -ScriptPath $prepScript -RootPath $Base
    $preWatcherPrepResults.Add($prep)
    if (-not $prep.success) {
        if ($prep.script -eq $driftManifestPath) {
            Write-LaunchLog ("Optional pre-watcher prep failed for drift manifest: {0}" -f $prep.message) "WARN"
        }
        else {
            throw ("Pre-watcher prep failed for {0}: {1}" -f $prep.script, $prep.message)
        }
    }
}

$taskGenParams = [ordered]@{
    MaxItems   = 200
    SinceHours = 24
}
if (-not $EnableTaskGen) {
    $taskGenParams["DryRun"] = $true
    Write-LaunchLog "Running TaskGen in dry-run mode (use -EnableTaskGen for live queue updates)."
}
else {
    Write-LaunchLog "Running TaskGen in live mode."
}

$taskGenPrep = Invoke-PreWatcherPrep -ScriptPath $taskGenPath -RootPath $Base -NamedArguments $taskGenParams
$preWatcherPrepResults.Add($taskGenPrep)
if (-not $taskGenPrep.success) {
    if ($EnableTaskGen) {
        throw ("TaskGen failed in live mode: {0}" -f $taskGenPrep.message)
    }
    Write-LaunchLog ("TaskGen dry-run failed: {0}" -f $taskGenPrep.message) "WARN"
}

if (-not $NoWatcher) {
    $watcherResult = Start-ScriptWindow `
        -ScriptPath $watcherPath `
        -WorkingDirectory $ToolsDir `
        -ComponentId "watcher" `
        -LogsDirectory $StartReportsDir `
        -RunId $startRunId `
        -ReuseFragment "Mason_Executor_Watcher.ps1" `
        -Minimized

    $launchResults.Add($watcherResult)
    if ($watcherResult.pid) {
        $pidUpdates["watcher_pid"] = [int]$watcherResult.pid
    }
}
else {
    Write-LaunchLog "Watcher launch skipped by -NoWatcher." "WARN"
}

$coreScript = if (Test-Path -LiteralPath $coreNoAppsPath) { $coreNoAppsPath } else { $coreFallbackPath }
$coreArgs = @()
if ($coreScript -eq $coreNoAppsPath) {
    $coreArgs += "-NoWatcher"
}

$coreResult = Start-ScriptWindow `
    -ScriptPath $coreScript `
    -ArgumentList $coreArgs `
    -WorkingDirectory $ToolsDir `
    -ComponentId "core" `
    -LogsDirectory $StartReportsDir `
    -RunId $startRunId `
    -ReuseFragment (Split-Path -Leaf $coreScript) `
    -Minimized

$launchResults.Add($coreResult)
if ($coreResult.pid) {
    $pidUpdates["core_launcher_pid"] = [int]$coreResult.pid
    $pidUpdates["core_launcher_script"] = $coreScript
}

$coreGateEndpoints = @(
    [pscustomobject]@{
        name     = "mason_api_health"
        url      = ("http://{0}:{1}/health" -f $bindHost, $masonApiPort)
        required = $true
        source   = "core_gate"
    }
    [pscustomobject]@{
        name     = "seed_api_health"
        url      = ("http://{0}:{1}/health" -f $bindHost, $seedApiPort)
        required = $true
        source   = "core_gate"
    }
)
Write-LaunchLog ("Core readiness gate: mason_api + seed_api (timeout={0}s)." -f $ReadinessTimeoutSeconds)
$coreGateReadiness = @(Wait-ForEndpoints -Endpoints $coreGateEndpoints -TimeoutSeconds $ReadinessTimeoutSeconds -PollSeconds 2)
$coreGateFailures = @($coreGateReadiness | Where-Object { $_.required -and -not $_.ready })
$coreGatePassed = ($coreGateFailures.Count -eq 0)
if (-not $coreGatePassed) {
    Write-LaunchLog "Core readiness gate failed. Downstream startup (Bridge/Athena/Onyx) will be skipped." "ERROR"
}

if ($coreGatePassed -and $bridgeEnabled) {
    $bridgeResult = Start-ScriptWindow `
        -ScriptPath $bridgeStartPath `
        -ArgumentList @("-RootPath", $Base) `
        -WorkingDirectory $ToolsDir `
        -ComponentId "bridge" `
        -LogsDirectory $StartReportsDir `
        -RunId $startRunId `
        -ReuseFragment "Start_Bridge.ps1" `
        -Minimized

    $launchResults.Add($bridgeResult)
    if ($bridgeResult.pid) {
        $pidUpdates["bridge_launcher_pid"] = [int]$bridgeResult.pid
    }
}
elseif ($bridgeEnabled) {
    Write-LaunchLog "Bridge launch skipped due to core readiness gate failure." "WARN"
}

if ($coreGatePassed -and $athenaEnabled) {
    $athenaResult = Start-ScriptWindow `
        -ScriptPath $athenaStartPath `
        -WorkingDirectory $Base `
        -ComponentId "athena" `
        -LogsDirectory $StartReportsDir `
        -RunId $startRunId `
        -ReuseFragment "Start-Athena.ps1" `
        -Minimized

    $launchResults.Add($athenaResult)
    if ($athenaResult.pid) {
        $pidUpdates["athena_pid"] = [int]$athenaResult.pid
    }
}
elseif ($athenaEnabled) {
    Write-LaunchLog "Athena launch skipped due to core readiness gate failure." "WARN"
}

if ($coreGatePassed -and $onyxEnabled) {
    $onyxResult = Start-ScriptWindow `
        -ScriptPath $onyxStartPath `
        -WorkingDirectory (Split-Path -Parent $onyxStartPath) `
        -ComponentId "onyx" `
        -LogsDirectory $StartReportsDir `
        -RunId $startRunId `
        -ReuseFragment "Start-Onyx5353.ps1" `
        -Minimized

    $launchResults.Add($onyxResult)
    if ($onyxResult.pid) {
        $pidUpdates["onyx_pid"] = [int]$onyxResult.pid
    }
}
elseif ($onyxEnabled) {
    Write-LaunchLog "Onyx launch skipped due to core readiness gate failure." "WARN"
}

if ($coreGatePassed -and $profile -eq "CoreOnly") {
    $tasksLoopResult = Start-ScriptWindow `
        -ScriptPath $tasksLoopPath `
        -WorkingDirectory $ToolsDir `
        -ArgumentList @("-IntervalSeconds", "120") `
        -ComponentId "approvals_loop" `
        -LogsDirectory $StartReportsDir `
        -RunId $startRunId `
        -ReuseFragment "Mason_Tasks_To_Approvals_Loop.ps1" `
        -Minimized

    $launchResults.Add($tasksLoopResult)
    if ($tasksLoopResult.pid) {
        $pidUpdates["tasks_to_approvals_loop_pid"] = [int]$tasksLoopResult.pid
    }
}
elseif ($profile -eq "CoreOnly") {
    Write-LaunchLog "Approvals loop skipped due to core readiness gate failure." "WARN"
}

$endpoints = @(Get-ReadinessEndpoints -PortsConfig $portsConfig -ServicesConfig $servicesConfig -BindHost $bindHost -BridgeEnabled $bridgeEnabled -AthenaEnabled $athenaEnabled -OnyxEnabled $onyxEnabled)
if ($CoreOnly) {
    $coreOnlyNames = @("mason_api_health", "seed_api_health")
    $coreOnlyEndpoints = New-Object System.Collections.Generic.List[object]
    foreach ($ep in @($endpoints)) {
        $required = ($coreOnlyNames -contains [string]$ep.name)
        $coreOnlyEndpoints.Add([pscustomobject]@{
            name      = [string]$ep.name
            url       = [string]$ep.url
            required  = [bool]$required
            source    = [string]$ep.source
        }) | Out-Null
    }
    $endpoints = @($coreOnlyEndpoints.ToArray())
}

$readiness = @()
if (-not $coreGatePassed) {
    $readiness = @($coreGateReadiness)
}
else {
    Write-LaunchLog ("Running readiness probes ({0} endpoint(s), timeout={1}s)." -f @($endpoints).Count, $ReadinessTimeoutSeconds)
    $readiness = @(Wait-ForEndpoints -Endpoints $endpoints -TimeoutSeconds $ReadinessTimeoutSeconds -PollSeconds 2)
}

$requiredFailures = @($readiness | Where-Object { $_.required -and -not $_.ready })
$overallStatus = if ($requiredFailures.Count -eq 0) { "PASS" } else { "FAIL" }
$openedBrowsers = @()
if ($overallStatus -eq "PASS") {
    $openedBrowsers = @(Open-ReadyBrowsers -Readiness $readiness -AthenaEnabled $athenaEnabled -OnyxEnabled $onyxEnabled)
}

$existingPidState = @{}
if (Test-Path -LiteralPath $stackPidPath) {
    try {
        Copy-Item -LiteralPath $stackPidPath -Destination $stackLastPidPath -Force
        $existingPidState = ConvertTo-HashtableShallow (Read-JsonSafe -Path $stackPidPath)
    }
    catch {
        Write-LaunchLog "Could not preserve previous stack_pids.json: $($_.Exception.Message)" "WARN"
        $existingPidState = @{}
    }
}

foreach ($key in $pidUpdates.Keys) {
    $existingPidState[$key] = $pidUpdates[$key]
}
$existingPidState["timestamp"] = (Get-Date).ToUniversalTime().ToString("o")
$existingPidState["status_file"] = $statusPath

Write-JsonFile -Path $stackPidPath -Object $existingPidState -Depth 12

$launchResultsArray = @()
if ($launchResults) {
    try {
        $launchResultsArray = @($launchResults.ToArray())
    }
    catch {
        $launchResultsArray = @($launchResults)
    }
}
$readinessArray = @($readiness)
$componentCount = @($componentRegistry.components).Count
$prepArray = @()
if ($preWatcherPrepResults) {
    try {
        $prepArray = @($preWatcherPrepResults.ToArray())
    }
    catch {
        $prepArray = @($preWatcherPrepResults)
    }
}

$startFailureArtifactWritten = $false
$failureArtifactPathForStatus = $null
if ($overallStatus -eq "FAIL") {
    $failureComponent = "launcher"
    $modeArg = if ($script:RequestedStartModeContext) { " {0}" -f $script:RequestedStartModeContext } else { "" }
    $failureCommand = ("powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}{1}" -f $MyInvocation.MyCommand.Path, $modeArg)
    $failureExitCode = 2
    $failureStderrPath = $null
    $failureHint = "Startup readiness failed. Check required endpoint health probes and stderr logs."

    $firstFailure = @($requiredFailures | Select-Object -First 1)
    if ($firstFailure.Count -gt 0) {
        $probeFailure = $firstFailure[0]
        $resolvedComponent = Resolve-EndpointComponent -EndpointName $probeFailure.name
        if ($resolvedComponent) {
            $failureComponent = $resolvedComponent
        }
        if ($probeFailure.PSObject.Properties.Name -contains "url" -and $probeFailure.url) {
            $failureHint = ("Readiness probe did not pass for {0}" -f [string]$probeFailure.url)
        }
        if ($probeFailure.last_probe -and $probeFailure.last_probe.error) {
            $failureHint = ("Readiness probe error: {0}" -f [string]$probeFailure.last_probe.error)
        }
    }

    $launchFailure = @($launchResultsArray | Where-Object { $_.component -eq $failureComponent } | Select-Object -First 1)
    if ($launchFailure.Count -eq 0 -and ($failureComponent -eq "mason_api" -or $failureComponent -eq "seed_api")) {
        $launchFailure = @($launchResultsArray | Where-Object { $_.component -eq "core" } | Select-Object -First 1)
    }
    if ($launchFailure.Count -gt 0) {
        $launchRow = $launchFailure[0]
        if ($launchRow.commandline) {
            $failureCommand = [string]$launchRow.commandline
        }
        elseif ($launchRow.script) {
            $failureCommand = ("powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}" -f [string]$launchRow.script)
        }
        if ($launchRow.stderr_log) {
            $failureStderrPath = [string]$launchRow.stderr_log
        }
        if (($launchRow.PSObject.Properties.Name -contains "process_alive") -and (-not [bool]$launchRow.process_alive)) {
            $failureExitCode = 1
        }
    }

    $lastFailureWritten = Write-LastFailureJson -Path $lastFailurePath -Component $failureComponent -Command $failureCommand -ExitCode $failureExitCode -StderrPath $failureStderrPath -Hint $failureHint
    if ($lastFailureWritten) {
        $script:LastFailureTrapWritten = $true
        Write-LaunchLog ("Last failure artifact written: {0}" -f $lastFailurePath) "ERROR"
    }
}
if ($overallStatus -eq "FAIL") {
    try {
        Write-StartFailureArtifact -ArtifactPath $startFailureArtifactPath -RunId $startRunId -RequiredFailures $requiredFailures -LaunchResults $launchResultsArray
        $startFailureArtifactWritten = $true
        $failureArtifactPathForStatus = $startFailureArtifactPath
        Write-LaunchLog ("Startup failure artifact written: {0}" -f $startFailureArtifactPath) "ERROR"
    }
    catch {
        Write-LaunchLog ("Failed to write startup failure artifact: {0}" -f $_.Exception.Message) "ERROR"
    }
}

$knownPorts = New-Object System.Collections.Generic.List[int]
foreach ($contractPort in @($masonApiPort, $seedApiPort, $bridgePort, $athenaPort, $onyxPort)) {
    if (-not $knownPorts.Contains([int]$contractPort)) {
        $knownPorts.Add([int]$contractPort)
    }
}
foreach ($endpoint in $readinessArray) {
    $port = Get-PortFromUrl -Url $endpoint.url
    if ($null -ne $port -and -not $knownPorts.Contains([int]$port)) {
        $knownPorts.Add([int]$port)
    }
}

$portSnapshot = Get-PortSnapshot -Ports @($knownPorts)
$reportSnapshots = @(
    Get-ReportSnapshot -Path $approvalsPosturePath
    Get-ReportSnapshot -Path $bridgeStatusPath
    Get-ReportSnapshot -Path $riskNormalizeReportPath
    Get-ReportSnapshot -Path $driftManifestReportPath
    Get-ReportSnapshot -Path $watcherTriggerPath
    Get-ReportSnapshot -Path $componentInventoryReportPath
    Get-ReportSnapshot -Path $ingestAutopilotStatusPath
)

$startRunManifest = [ordered]@{
    generated_at_utc       = (Get-Date).ToUniversalTime().ToString("o")
    run_id                 = $startRunId
    overall_status         = $overallStatus
    mode                   = $profile
    start_reports_dir      = $StartReportsDir
    status_report_path     = $statusPath
    stack_pid_state_path   = $stackPidPath
    start_failure_artifact = if ($startFailureArtifactWritten) { $startFailureArtifactPath } else { $null }
    launch_results         = $launchResultsArray
    readiness              = $readinessArray
    ports                  = $portSnapshot
    opened_browsers        = $openedBrowsers
}
Write-JsonFile -Path $startRunManifestPath -Object $startRunManifest -Depth 14
Write-JsonFile -Path $startRunLastPath -Object $startRunManifest -Depth 14

$statusBlob = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    mode             = $profile
    bridge_enabled   = [bool]$bridgeEnabled
    pre_watcher_prep = $prepArray
    launch_results   = $launchResultsArray
    opened_browsers  = $openedBrowsers
    onyx_launcher    = $onyxLauncher
    start_run_id     = $startRunId
    start_run_report = $startRunManifestPath
    start_failure_artifact = $failureArtifactPathForStatus
    ports            = $portSnapshot
    last_reports     = $reportSnapshots
    readiness        = $readinessArray
    overall_status   = $overallStatus
    config_sources   = [ordered]@{
        services_json           = $servicesPath
        ports_json              = $portsPath
        component_registry_json = $componentRegistryPath
        risk_policy_json        = $riskPolicyPath
        backup_policy_json      = $backupPolicyPath
        ingest_policy_json      = $ingestPolicyPath
        component_inventory_json = $componentInventoryReportPath
        drift_manifest_json     = $driftManifestReportPath
        onyx_launcher_path      = $onyxStartPath
        component_count         = $componentCount
    }
    ports_contract = [ordered]@{
        bind_host = $bindHost
        ports     = [ordered]@{
            mason_api = $masonApiPort
            seed_api  = $seedApiPort
            bridge    = $bridgePort
            athena    = $athenaPort
            onyx      = $onyxPort
        }
        sidecar7000_enabled = $false
    }
    policy_guardrails = [ordered]@{
        high_risk_auto_apply = [bool]$riskPolicy.global.high_risk_auto_apply
        money_loop_enabled   = [bool]$riskPolicy.global.money_loop_enabled
    }
    backups = [ordered]@{
        backup_root = [string]$backupPolicy.backup_root
    }
    stack_pid_state_path = $stackPidPath
}

Write-JsonFile -Path $statusPath -Object $statusBlob -Depth 14

Write-LaunchLog "Stack PID state updated: $stackPidPath"
Write-LaunchLog "Status report written: $statusPath"
Write-LaunchLog "Readiness overall status: $overallStatus"

if ($overallStatus -eq "FAIL") {
    exit 2
}

exit 0
