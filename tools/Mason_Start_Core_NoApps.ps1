[CmdletBinding()]
param(
    [switch]$NoWatcher
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-CoreStartLog {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Mason_Start_Core_NoApps] $Message"
}

function Start-CoreScript {
    param(
        [Parameter(Mandatory = $true)][string]$ToolsDir,
        [Parameter(Mandatory = $true)][string]$ScriptName,
        [Parameter(Mandatory = $true)][string]$StartReportsDir,
        [Parameter(Mandatory = $true)][string]$StartRunId
    )

    $path = Join-Path $ToolsDir $ScriptName
    if (-not (Test-Path -LiteralPath $path)) {
        Write-CoreStartLog "Missing script (skipped): $ScriptName"
        return $null
    }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeName = [regex]::Replace($ScriptName.ToLowerInvariant(), "[^a-z0-9._-]+", "_")
    $stdoutLog = Join-Path $StartReportsDir ("{0}_{1}_{2}_stdout.log" -f $StartRunId, $safeName, $stamp)
    $stderrLog = Join-Path $StartReportsDir ("{0}_{1}_{2}_stderr.log" -f $StartRunId, $safeName, $stamp)

    $proc = Start-Process powershell.exe -ArgumentList @(
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $path
    ) -WorkingDirectory $ToolsDir -WindowStyle Minimized -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog -PassThru

    Write-CoreStartLog ("Started {0} (PID {1}) -> stdout={2}; stderr={3}" -f $ScriptName, $proc.Id, $stdoutLog, $stderrLog)
    return $proc
}

function Resolve-PythonLauncher {
    $pythonCmd = Get-Command python.exe -ErrorAction SilentlyContinue
    if (-not $pythonCmd) {
        $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    }
    if (-not $pythonCmd) {
        throw "python launcher not found in PATH."
    }
    return [string]$pythonCmd.Source
}

function Get-EnvPortOrDefault {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$DefaultPort
    )

    $raw = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [int]$DefaultPort
    }

    $parsed = 0
    if (-not [int]::TryParse([string]$raw, [ref]$parsed) -or $parsed -lt 1 -or $parsed -gt 65535) {
        throw ("Invalid value for environment variable {0}: '{1}'" -f $Name, $raw)
    }
    return [int]$parsed
}

function Get-PortOwnerPids {
    param([Parameter(Mandatory = $true)][int]$Port)

    $owners = @()
    try {
        foreach ($row in @(Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction Stop)) {
            $parsedPid = [int]$row.OwningProcess
            if ($parsedPid -gt 0) {
                $owners += $parsedPid
            }
        }
    }
    catch {
        try {
            foreach ($line in @(netstat -ano -p tcp 2>$null)) {
                $pattern = "^\s*TCP\s+\S*:{0}\s+\S+\s+LISTENING\s+(\d+)\s*$" -f $Port
                if ($line -match $pattern) {
                    $parsedPid = 0
                    if ([int]::TryParse([string]$Matches[1], [ref]$parsedPid) -and $parsedPid -gt 0) {
                        $owners += $parsedPid
                    }
                }
            }
        }
        catch {
            return @()
        }
    }

    return @($owners | Sort-Object -Unique)
}

function Test-ServiceHealth {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSec = 3
    )

    try {
        $request = @{
            Uri         = $Url
            Method      = "Get"
            TimeoutSec  = $TimeoutSec
            ErrorAction = "Stop"
        }
        if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey("UseBasicParsing")) {
            $request["UseBasicParsing"] = $true
        }
        $response = Invoke-WebRequest @request
        return ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400)
    }
    catch {
        return $false
    }
}

function Get-ProcessesByCommandFragment {
    param(
        [Parameter(Mandatory = $true)][string]$Fragment,
        [string[]]$ProcessNames = @("python.exe", "pythonw.exe")
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
        Write-CoreStartLog ("WARN: Could not inspect process command lines for '{0}': {1}" -f $Fragment, $_.Exception.Message)
        return @()
    }
}

function Stop-RedundantServiceProcesses {
    param(
        [Parameter(Mandatory = $true)][string]$CommandFragment,
        [int[]]$KeepPids = @()
    )

    $keepSet = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($pidValue in @($KeepPids | Sort-Object -Unique)) {
        if ([int]$pidValue -gt 0) {
            [void]$keepSet.Add([int]$pidValue)
        }
    }

    $results = @()
    foreach ($proc in @(Get-ProcessesByCommandFragment -Fragment $CommandFragment)) {
        $pidValue = [int]$proc.ProcessId
        if ($pidValue -le 0 -or $keepSet.Contains($pidValue)) {
            continue
        }

        $row = [ordered]@{
            process_id = $pidValue
            stopped    = $false
            note       = $null
        }
        try {
            Stop-Process -Id $pidValue -Force -ErrorAction Stop
            $row.stopped = $true
            $row.note = "stopped_redundant_duplicate"
            Write-CoreStartLog ("Stopped redundant duplicate service PID {0} for {1}" -f $pidValue, $CommandFragment)
        }
        catch {
            $row.note = $_.Exception.Message
            Write-CoreStartLog ("WARN: Could not stop redundant duplicate service PID {0}: {1}" -f $pidValue, $_.Exception.Message)
        }
        $results += [pscustomobject]$row
    }

    return @($results)
}

function Start-CorePythonService {
    param(
        [Parameter(Mandatory = $true)][string]$PythonExe,
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$ComponentName,
        [Parameter(Mandatory = $true)][int]$Port,
        [Parameter(Mandatory = $true)][string]$HealthUrl,
        [Parameter(Mandatory = $true)][string]$StartReportsDir,
        [Parameter(Mandatory = $true)][string]$StartRunId
    )

    $path = Join-Path $RepoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw ("Missing required service script: {0}" -f $path)
    }

    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $safeName = [regex]::Replace($ComponentName.ToLowerInvariant(), "[^a-z0-9._-]+", "_")
    $stdoutLog = Join-Path $StartReportsDir ("{0}_{1}_{2}_stdout.log" -f $StartRunId, $safeName, $stamp)
    $stderrLog = Join-Path $StartReportsDir ("{0}_{1}_{2}_stderr.log" -f $StartRunId, $safeName, $stamp)
    $args = @("-u", $path)
    $argText = ($args | ForEach-Object { if ([string]$_ -match "\s") { '"' + [string]$_ + '"' } else { [string]$_ } }) -join " "
    $commandline = "{0} {1}" -f $PythonExe, $argText
    $commandFragment = [string]$path
    $existingOwners = @(Get-PortOwnerPids -Port $Port)
    if ($existingOwners.Count -gt 0 -and (Test-ServiceHealth -Url $HealthUrl -TimeoutSec 3)) {
        $canonicalPid = [int]$existingOwners[0]
        $cleanupResults = @(Stop-RedundantServiceProcesses -CommandFragment $commandFragment -KeepPids @($canonicalPid))
        Write-CoreStartLog ("Reusing {0} on port {1} (listener PID {2})" -f $ComponentName, $Port, $canonicalPid)
        return [pscustomobject]@{
            component         = [string]$ComponentName
            script            = [string]$RelativePath
            pid               = [int]$canonicalPid
            listener_pid      = [int]$canonicalPid
            started_pid       = $null
            reused            = $true
            commandline       = [string]$commandline
            stdout_log        = [string]$stdoutLog
            stderr_log        = [string]$stderrLog
            duplicate_cleanup = @($cleanupResults)
        }
    }

    $proc = Start-Process -FilePath $PythonExe -ArgumentList $args -WorkingDirectory $RepoRoot -WindowStyle Minimized -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog -PassThru

    Write-CoreStartLog ("Started {0} (PID {1}) -> stdout={2}; stderr={3}" -f $RelativePath, $proc.Id, $stdoutLog, $stderrLog)
    $canonicalPid = [int]$proc.Id
    $deadline = (Get-Date).AddSeconds(8)
    while ((Get-Date) -lt $deadline) {
        $ownerPids = @(Get-PortOwnerPids -Port $Port)
        if ($ownerPids.Count -gt 0 -and (Test-ServiceHealth -Url $HealthUrl -TimeoutSec 2)) {
            $canonicalPid = [int]$ownerPids[0]
            break
        }
        Start-Sleep -Milliseconds 500
    }
    $cleanupResults = @(Stop-RedundantServiceProcesses -CommandFragment $commandFragment -KeepPids @($canonicalPid))
    return [pscustomobject]@{
        component         = [string]$ComponentName
        script            = [string]$RelativePath
        pid               = [int]$canonicalPid
        listener_pid      = [int]$canonicalPid
        started_pid       = [int]$proc.Id
        reused            = $false
        commandline       = [string]$commandline
        stdout_log        = [string]$stdoutLog
        stderr_log        = [string]$stderrLog
        duplicate_cleanup = @($cleanupResults)
    }
}

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$base = Split-Path -Parent $toolsDir
$stateDir = Join-Path $base "state\knowledge"
$stackPidPath = Join-Path $stateDir "stack_pids.json"
$reportsDir = Join-Path $base "reports"
$startReportsDir = Join-Path $reportsDir "start"
$startRunId = if ($env:MASON_START_RUN_ID) { [string]$env:MASON_START_RUN_ID } else { (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss_fff") }

New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
New-Item -ItemType Directory -Path $startReportsDir -Force | Out-Null

Write-CoreStartLog "Starting core loops (no Athena/Onyx app launch)."

$bindHost = if ($env:MASON_BIND_HOST) { [string]$env:MASON_BIND_HOST } else { "127.0.0.1" }
if ($bindHost -ne "127.0.0.1") {
    throw ("MASON_BIND_HOST must be 127.0.0.1. Received '{0}'." -f $bindHost)
}
$masonApiPort = Get-EnvPortOrDefault -Name "MASON_API_PORT" -DefaultPort 8383
$seedApiPort = Get-EnvPortOrDefault -Name "MASON_SEED_PORT" -DefaultPort 8109
$env:MASON_BIND_HOST = $bindHost
$env:MASON_API_PORT = [string]$masonApiPort
$env:MASON_SEED_PORT = [string]$seedApiPort
Write-CoreStartLog ("API contract: mason_api={0}, seed_api={1}, bind_host={2}" -f $masonApiPort, $seedApiPort, $bindHost)

$pythonExe = Resolve-PythonLauncher
$serviceSpecs = @(
    [pscustomobject]@{
        component  = "mason_api"
        script     = "services\mason_api\serve_mason_api.py"
        port       = $masonApiPort
        health_url = ("http://{0}:{1}/health" -f $bindHost, $masonApiPort)
    }
    [pscustomobject]@{
        component  = "seed_api"
        script     = "services\seed_api\serve_seed_api.py"
        port       = $seedApiPort
        health_url = ("http://{0}:{1}/health" -f $bindHost, $seedApiPort)
    }
)
$startedServices = New-Object System.Collections.Generic.List[object]
foreach ($service in $serviceSpecs) {
    $svc = Start-CorePythonService -PythonExe $pythonExe -RepoRoot $base -RelativePath $service.script -ComponentName $service.component -Port ([int]$service.port) -HealthUrl ([string]$service.health_url) -StartReportsDir $startReportsDir -StartRunId $startRunId
    if ($svc) {
        $startedServices.Add($svc)
    }
}

$coreScripts = @(
    "Mason_AutoLoop.ps1",
    "Mason_Watchdog.ps1",
    "Mason_DiskGuard.ps1",
    "Mason_Health_Aggregator.ps1",
    "Mason_Learner.ps1",
    "Mason_TaskGovernor.ps1",
    "Mason_UE_Loop_Mason.ps1",
    "Mason_SelfImprove_Loop.ps1"
)

if (-not $NoWatcher) {
    $coreScripts = @("Mason_Executor_Watcher.ps1") + $coreScripts
}

$started = New-Object System.Collections.Generic.List[object]
foreach ($scriptName in $coreScripts) {
    $proc = Start-CoreScript -ToolsDir $toolsDir -ScriptName $scriptName -StartReportsDir $startReportsDir -StartRunId $startRunId
    if ($proc) {
        $started.Add([pscustomobject]@{
            script = $scriptName
            pid    = [int]$proc.Id
        })
    }
}

$startedState = @(
    $started | ForEach-Object {
        [ordered]@{
            script = [string]$_.script
            pid    = [int]$_.pid
        }
    }
    $startedServices | ForEach-Object {
        [ordered]@{
            script = [string]$_.script
            pid    = [int]$_.pid
        }
    }
)
$startedServicesState = @(
    $startedServices | ForEach-Object {
        [ordered]@{
            component         = [string]$_.component
            script            = [string]$_.script
            pid               = [int]$_.pid
            listener_pid      = [int]$_.listener_pid
            started_pid       = if ($null -ne $_.started_pid) { [int]$_.started_pid } else { $null }
            reused            = [bool]$_.reused
            commandline       = [string]$_.commandline
            stdout_log        = [string]$_.stdout_log
            stderr_log        = [string]$_.stderr_log
            duplicate_cleanup = @($_.duplicate_cleanup)
        }
    }
)

$existing = [ordered]@{}
if (Test-Path -LiteralPath $stackPidPath) {
    try {
        $parsed = Get-Content -LiteralPath $stackPidPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($parsed -is [System.Collections.IDictionary]) {
            foreach ($entry in $parsed.GetEnumerator()) {
                $existing[[string]$entry.Key] = $entry.Value
            }
        }
        elseif ($parsed) {
            foreach ($p in @($parsed.PSObject.Properties)) {
                $existing[$p.Name] = $p.Value
            }
        }
    }
    catch {
        $existing = [ordered]@{}
    }
}

$existing["core_noapps_launched_at"] = (Get-Date).ToUniversalTime().ToString("o")
$existing["core_noapps_processes"] = @($startedState)
$existing["core_noapps_services"] = @($startedServicesState)
foreach ($svc in $startedServices.ToArray()) {
    if (-not $svc.component) {
        continue
    }
    $keyBase = [string]$svc.component
    $existing[("{0}_pid" -f $keyBase)] = [int]$svc.pid
    $existing[("{0}_stdout_log" -f $keyBase)] = [string]$svc.stdout_log
    $existing[("{0}_stderr_log" -f $keyBase)] = [string]$svc.stderr_log
}

try {
    $existing | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $stackPidPath -Encoding UTF8
    Write-CoreStartLog "Updated PID state: $stackPidPath"
}
catch {
    Write-CoreStartLog "WARN: Could not update PID state at $stackPidPath : $($_.Exception.Message)"
}

Write-CoreStartLog "Core launch complete."
