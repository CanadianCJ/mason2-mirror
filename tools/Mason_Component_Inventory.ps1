[CmdletBinding()]
param(
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param([string]$CandidateRoot)
    if ($CandidateRoot -and (Test-Path -LiteralPath $CandidateRoot)) {
        return (Resolve-Path -LiteralPath $CandidateRoot).Path
    }
    return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
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
        [int]$Depth = 18
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

function Get-PropertyValue {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Default = $null
    )
    if ($null -eq $Object) { return $Default }
    if ($Object -is [hashtable]) {
        if ($Object.ContainsKey($Name)) { return $Object[$Name] }
        return $Default
    }
    if ($Object.PSObject -and ($Object.PSObject.Properties.Name -contains $Name)) {
        return $Object.$Name
    }
    return $Default
}

function Normalize-ComponentId {
    param([string]$Value)
    $raw = ([string]$Value).Trim().ToLowerInvariant()
    if (-not $raw) { return "unknown" }
    if ($raw -match "mason") { return "mason" }
    if ($raw -match "bridge") { return "bridge" }
    if ($raw -match "athena") { return "athena" }
    if ($raw -match "onyx") { return "onyx" }
    return $raw
}

function Resolve-PathInRepo {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$RelativeOrAbsolute
    )

    if ([System.IO.Path]::IsPathRooted($RelativeOrAbsolute)) {
        return $RelativeOrAbsolute
    }
    if ($RelativeOrAbsolute -eq ".") {
        return $BasePath
    }
    return Join-Path $BasePath $RelativeOrAbsolute
}

function Get-RelativePathSafe {
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$FullPath
    )
    try {
        $baseResolved = (Resolve-Path -LiteralPath $BasePath -ErrorAction Stop).Path
        $fullResolved = (Resolve-Path -LiteralPath $FullPath -ErrorAction Stop).Path
        if ($fullResolved.StartsWith($baseResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $fullResolved.Substring($baseResolved.Length).TrimStart("\", "/")
        }
        return $fullResolved
    }
    catch {
        return $FullPath
    }
}

function Get-PortListeners {
    param([int]$Port)

    $listeners = New-Object System.Collections.Generic.List[object]
    if ($Port -le 0) { return @() }

    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        try {
            $rows = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
            foreach ($row in @($rows)) {
                $listeners.Add([pscustomobject]@{
                        port          = [int]$Port
                        local_address = [string]$row.LocalAddress
                        owning_pid    = [int]$row.OwningProcess
                    }) | Out-Null
            }
            return @($listeners.ToArray())
        }
        catch {
            # fallback to netstat
        }
    }

    try {
        $lines = netstat -ano -p tcp
        foreach ($line in $lines) {
            if ($line -notmatch "LISTENING") { continue }
            if ($line -notmatch "^\s*TCP\s+(\S+):(\d+)\s+\S+\s+LISTENING\s+(\d+)") { continue }
            $localAddr = $Matches[1]
            $linePort = 0
            $pid = 0
            [int]::TryParse($Matches[2], [ref]$linePort) | Out-Null
            [int]::TryParse($Matches[3], [ref]$pid) | Out-Null
            if ($linePort -ne $Port) { continue }
            $listeners.Add([pscustomobject]@{
                    port          = [int]$Port
                    local_address = [string]$localAddr
                    owning_pid    = [int]$pid
                }) | Out-Null
        }
    }
    catch {
        return @()
    }

    return @($listeners.ToArray())
}

function Test-ProcessAlive {
    param([int]$ProcessId)
    if ($ProcessId -le 0) { return $false }
    return [bool](Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)
}

function Test-HttpEndpoint {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSec = 4
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
        $resp = Invoke-WebRequest @params
        return ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400)
    }
    catch {
        return $false
    }
}

function Get-PythonProcessesByCommand {
    param([string]$Pattern)
    if (-not $Pattern) { return @() }
    try {
        $rows = Get-CimInstance Win32_Process -Filter "Name='python.exe' OR Name='pythonw.exe'" -ErrorAction Stop
        return @($rows | Where-Object { $_.CommandLine -and $_.CommandLine -match $Pattern })
    }
    catch {
        return @()
    }
}

function Get-VersionStamp {
    param(
        [Parameter(Mandatory = $true)][string]$ComponentRoot
    )

    if (-not (Test-Path -LiteralPath $ComponentRoot)) {
        return $null
    }

    $versionCandidates = @(
        (Join-Path $ComponentRoot "VERSION"),
        (Join-Path $ComponentRoot "version.txt"),
        (Join-Path $ComponentRoot "package.json"),
        (Join-Path $ComponentRoot "pubspec.yaml"),
        (Join-Path $ComponentRoot "pyproject.toml")
    )

    foreach ($path in $versionCandidates) {
        if (-not (Test-Path -LiteralPath $path)) { continue }

        $fileName = [System.IO.Path]::GetFileName($path).ToLowerInvariant()
        try {
            if ($fileName -eq "package.json") {
                $obj = Read-JsonSafe -Path $path -Default $null
                $ver = [string](Get-PropertyValue -Object $obj -Name "version" -Default "")
                if ($ver.Trim()) { return $ver.Trim() }
            }
            elseif ($fileName -eq "pubspec.yaml") {
                $lines = Get-Content -LiteralPath $path -Encoding UTF8
                foreach ($line in $lines) {
                    if ($line -match "^\s*version\s*:\s*(.+)$") {
                        return $Matches[1].Trim()
                    }
                }
            }
            elseif ($fileName -eq "pyproject.toml") {
                $lines = Get-Content -LiteralPath $path -Encoding UTF8
                foreach ($line in $lines) {
                    if ($line -match "^\s*version\s*=\s*['""](.+?)['""]\s*$") {
                        return $Matches[1].Trim()
                    }
                }
            }
            else {
                $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
                $line = ($raw -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
                if ($line) { return $line.Trim() }
            }
        }
        catch {
            continue
        }
    }

    return $null
}

function New-DriftFinding {
    param(
        [Parameter(Mandatory = $true)][string]$ComponentId,
        [Parameter(Mandatory = $true)][string]$Code,
        [Parameter(Mandatory = $true)][string]$Title,
        [ValidateRange(0, 3)][int]$RiskLevel = 1,
        [string[]]$EvidenceFiles = @()
    )

    $evidence = @($EvidenceFiles | Where-Object { $_ } | Select-Object -Unique)
    return [pscustomobject][ordered]@{
        component_id   = $ComponentId
        code           = $Code
        title          = $Title
        risk_level     = [int]$RiskLevel
        evidence_files = $evidence
    }
}

function Update-HistoryJsonl {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Entry,
        [int]$RetainDays = 7
    )

    $nowUtc = (Get-Date).ToUniversalTime()
    $cutoffUtc = $nowUtc.AddDays(-1 * $RetainDays)
    $linesOut = New-Object System.Collections.Generic.List[string]

    if (Test-Path -LiteralPath $Path) {
        foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
            if (-not $line -or -not $line.Trim()) { continue }
            try {
                $obj = $line | ConvertFrom-Json -ErrorAction Stop
                $tsRaw = [string](Get-PropertyValue -Object $obj -Name "generated_at_utc" -Default "")
                if (-not $tsRaw) { continue }
                $dt = [datetime]::MinValue
                if (-not [datetime]::TryParse($tsRaw, [ref]$dt)) { continue }
                if ($dt.ToUniversalTime() -lt $cutoffUtc) { continue }
                $linesOut.Add(($obj | ConvertTo-Json -Compress -Depth 12)) | Out-Null
            }
            catch {
                continue
            }
        }
    }

    $linesOut.Add(($Entry | ConvertTo-Json -Compress -Depth 12)) | Out-Null

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -LiteralPath $Path -Value $linesOut -Encoding UTF8
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$configDir = Join-Path $repoRoot "config"
$reportsDir = Join-Path $repoRoot "reports"
$stateDir = Join-Path $repoRoot "state\knowledge"
if (-not (Test-Path -LiteralPath $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

$componentRegistryPath = Join-Path $configDir "component_registry.json"
$portsPath = Join-Path $configDir "ports.json"
$stackPidPath = Join-Path $stateDir "stack_pids.json"
$inventoryPath = Join-Path $reportsDir "component_inventory.json"
$historyPath = Join-Path $reportsDir "component_inventory_history.jsonl"
$coreStatusPath = Join-Path $reportsDir "mason2_core_status.json"
$driftManifestPath = Join-Path $reportsDir "drift_manifest.json"
$driftHistoryPath = Join-Path $reportsDir "drift_manifest_history.jsonl"

$registry = Read-JsonSafe -Path $componentRegistryPath -Default ([ordered]@{ components = @() })
$portsConfig = Read-JsonSafe -Path $portsPath -Default ([ordered]@{ ports = [ordered]@{}; bind_host = "127.0.0.1" })
$stackState = Read-JsonSafe -Path $stackPidPath -Default ([ordered]@{})
$coreStatus = Read-JsonSafe -Path $coreStatusPath -Default $null
$driftManifest = Read-JsonSafe -Path $driftManifestPath -Default $null

$onyxLauncherPath = $null
$onyxLauncherCandidates = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot "Component - Onyx App") -Filter "Start-Onyx5353.ps1" -File -Recurse -ErrorAction SilentlyContinue)
if ($onyxLauncherCandidates.Count -gt 0) {
    $onyxLauncherPath = $onyxLauncherCandidates[0].FullName
}
$onyxLauncherRelative = if ($onyxLauncherPath) { Get-RelativePathSafe -BasePath $repoRoot -FullPath $onyxLauncherPath } else { "Component - Onyx App\onyx_business_manager\Start-Onyx5353.ps1" }

$componentDefs = [ordered]@{}
$componentDefs["mason"] = [ordered]@{
    id           = "mason"
    label        = "Mason2"
    root_paths   = @(".")
    key_files    = @("Start_Mason2.ps1", "tools\Mason_Doctor.ps1")
    status_files = @("reports\mason2_core_status.json", "reports\mason2_doctor_report.json")
    pid_keys     = @("mason_api_pid", "seed_api_pid", "core_launcher_pid", "mason_core_pid")
    expected_ports = @("mason_api", "seed_api")
}
$componentDefs["bridge"] = [ordered]@{
    id           = "bridge"
    label        = "Bridge"
    root_paths   = @("bridge")
    key_files    = @("tools\Start_Bridge.ps1", "bridge\mason_bridge_server.py")
    status_files = @("reports\bridge_status.json")
    pid_keys     = @("bridge_pid", "bridge_launcher_pid")
    expected_ports = @("bridge")
}
$componentDefs["athena"] = [ordered]@{
    id           = "athena"
    label        = "Athena"
    root_paths   = @("MasonConsole")
    key_files    = @("Start-Athena.ps1", "MasonConsole\server.py")
    status_files = @("reports\athena_self_state.json")
    pid_keys     = @("athena_pid", "athena_launcher_pid")
    expected_ports = @("athena")
}
$componentDefs["onyx"] = [ordered]@{
    id           = "onyx"
    label        = "Onyx"
    root_paths   = @("Component - Onyx App")
    key_files    = @(
        "tools\launch\Start_Mason_FullStack.ps1",
        $onyxLauncherRelative
    )
    status_files = @("reports\onyx_health_status.json")
    pid_keys     = @("onyx_pid", "onyx_launcher_pid")
    expected_ports = @("onyx")
}

$registryComponents = @(To-Array (Get-PropertyValue -Object $registry -Name "components" -Default @()))
$registryIdCounts = @{}
foreach ($entry in $registryComponents) {
    if (-not $entry) { continue }
    $idRaw = [string](Get-PropertyValue -Object $entry -Name "id" -Default "")
    $id = Normalize-ComponentId -Value $idRaw
    if (-not $registryIdCounts.ContainsKey($id)) { $registryIdCounts[$id] = 0 }
    $registryIdCounts[$id] = [int]$registryIdCounts[$id] + 1

    $label = [string](Get-PropertyValue -Object $entry -Name "label" -Default $idRaw)
    $rootPaths = @((To-Array (Get-PropertyValue -Object $entry -Name "root_paths" -Default @())) | ForEach-Object { [string]$_ } | Where-Object { $_ })
    $statusSources = @((To-Array (Get-PropertyValue -Object $entry -Name "status_sources" -Default @())) | ForEach-Object { [string]$_ } | Where-Object { $_ })

    if (-not $componentDefs.Contains($id)) {
        $componentDefs[$id] = [ordered]@{
            id             = $id
            label          = if ($label) { $label } else { $id }
            root_paths     = if ($rootPaths.Count -gt 0) { $rootPaths } else { @(".") }
            key_files      = @()
            status_files   = $statusSources
            pid_keys       = @()
            expected_ports = @()
        }
    }
    else {
        if ($label) { $componentDefs[$id]["label"] = $label }
        if ($rootPaths.Count -gt 0) {
            $componentDefs[$id]["root_paths"] = @($componentDefs[$id]["root_paths"] + $rootPaths | Select-Object -Unique)
        }
        if ($statusSources.Count -gt 0) {
            $componentDefs[$id]["status_files"] = @($componentDefs[$id]["status_files"] + $statusSources | Select-Object -Unique)
        }
    }
}

$portMap = [ordered]@{}
if ($portsConfig -and (Get-PropertyValue -Object $portsConfig -Name "ports" -Default $null)) {
    $portObj = Get-PropertyValue -Object $portsConfig -Name "ports" -Default $null
    foreach ($prop in $portObj.PSObject.Properties) {
        $n = [string]$prop.Name
        $v = 0
        if ([int]::TryParse([string]$prop.Value, [ref]$v)) {
            $portMap[$n] = $v
        }
    }
}

$bindHost = [string](Get-PropertyValue -Object $portsConfig -Name "bind_host" -Default "127.0.0.1")
if (-not $bindHost) { $bindHost = "127.0.0.1" }
$athenaPort = if ($portMap.Contains("athena")) { [int]$portMap["athena"] } else { 8000 }
$masonConsoleEndpoint = "http://{0}:{1}/api/health" -f $bindHost, $athenaPort
$masonConsoleEndpointOk = Test-HttpEndpoint -Url $masonConsoleEndpoint -TimeoutSec 4
$masonConsoleListeners = @(Get-PortListeners -Port $athenaPort)
$masonConsoleProcesses = @(Get-PythonProcessesByCommand -Pattern "(?i)masonconsole.*server\.py|server\.py.*masonconsole")

$onyxLauncherExists = if ($onyxLauncherPath) { Test-Path -LiteralPath $onyxLauncherPath } else { Test-Path -LiteralPath (Join-Path $repoRoot $onyxLauncherRelative) }
$onyxLauncherLastWrite = $null
if ($onyxLauncherExists) {
    $onyxFile = if ($onyxLauncherPath) { $onyxLauncherPath } else { (Join-Path $repoRoot $onyxLauncherRelative) }
    try { $onyxLauncherLastWrite = (Get-Item -LiteralPath $onyxFile -ErrorAction Stop).LastWriteTimeUtc.ToString("o") } catch { $onyxLauncherLastWrite = $null }
}

$onyxLastStartStatus = $null
if ($coreStatus -and ($coreStatus.PSObject.Properties.Name -contains "launch_results")) {
    foreach ($entry in @($coreStatus.launch_results)) {
        if (-not $entry) { continue }
        $scriptVal = [string](Get-PropertyValue -Object $entry -Name "script" -Default "")
        if ($scriptVal -and $scriptVal.ToLowerInvariant().Contains("start-onyx5353.ps1")) {
            $onyxLastStartStatus = [ordered]@{
                started = [bool](Get-PropertyValue -Object $entry -Name "started" -Default $false)
                reused  = [bool](Get-PropertyValue -Object $entry -Name "reused" -Default $false)
                missing = [bool](Get-PropertyValue -Object $entry -Name "missing" -Default $false)
                pid     = (Get-PropertyValue -Object $entry -Name "pid" -Default $null)
                message = [string](Get-PropertyValue -Object $entry -Name "message" -Default "")
            }
            break
        }
    }
}

$lastDriftHistoryEntry = $null
if (Test-Path -LiteralPath $driftHistoryPath) {
    $lines = @(Get-Content -LiteralPath $driftHistoryPath -Encoding UTF8 | Where-Object { $_ -and $_.Trim() })
    if ($lines.Count -gt 0) {
        try {
            $lastDriftHistoryEntry = ($lines[-1] | ConvertFrom-Json -ErrorAction Stop)
        }
        catch {
            $lastDriftHistoryEntry = $null
        }
    }
}

$driftFindings = New-Object System.Collections.Generic.List[object]
$componentsOut = New-Object System.Collections.Generic.List[object]

foreach ($id in $componentDefs.Keys) {
    $def = $componentDefs[$id]
    $label = [string]$def.label
    $rootCandidates = @($def.root_paths | Where-Object { $_ } | Select-Object -Unique)
    if ($rootCandidates.Count -eq 0) { $rootCandidates = @(".") }

    $resolvedRoot = Resolve-PathInRepo -BasePath $repoRoot -RelativeOrAbsolute $rootCandidates[0]
    foreach ($candidate in $rootCandidates) {
        $candidatePath = Resolve-PathInRepo -BasePath $repoRoot -RelativeOrAbsolute $candidate
        if (Test-Path -LiteralPath $candidatePath) {
            $resolvedRoot = $candidatePath
            break
        }
    }

    $rootExists = Test-Path -LiteralPath $resolvedRoot
    $rootLastWrite = $null
    if ($rootExists) {
        try {
            $item = Get-Item -LiteralPath $resolvedRoot -ErrorAction Stop
            $rootLastWrite = $item.LastWriteTimeUtc.ToString("o")
        }
        catch {
            $rootLastWrite = $null
        }
    }

    $versionStamp = if ($rootExists) { Get-VersionStamp -ComponentRoot $resolvedRoot } else { $null }

    $keyFileList = @(
        $def.key_files + $def.status_files |
        Where-Object { $_ } |
        ForEach-Object { ([string]$_).Replace("/", "\") } |
        Select-Object -Unique
    )
    $keyFilesOut = New-Object System.Collections.Generic.List[object]
    foreach ($kf in $keyFileList) {
        $full = Resolve-PathInRepo -BasePath $repoRoot -RelativeOrAbsolute $kf
        $exists = Test-Path -LiteralPath $full
        $lastWrite = $null
        if ($exists) {
            try { $lastWrite = (Get-Item -LiteralPath $full -ErrorAction Stop).LastWriteTimeUtc.ToString("o") } catch { $lastWrite = $null }
        }
        $keyFilesOut.Add([pscustomobject][ordered]@{
                path           = Get-RelativePathSafe -BasePath $repoRoot -FullPath $full
                exists         = [bool]$exists
                last_write_utc = $lastWrite
            }) | Out-Null

        if (-not $exists) {
            $driftFindings.Add((New-DriftFinding -ComponentId $id -Code "missing_key_file" -Title ("Missing key file: {0}" -f $kf) -RiskLevel 1 -EvidenceFiles @($kf))) | Out-Null
        }
    }

    $expectedPorts = New-Object System.Collections.Generic.List[object]
    foreach ($portName in @($def.expected_ports | Select-Object -Unique)) {
        if ($portMap.Contains($portName)) {
            $expectedPorts.Add([pscustomobject][ordered]@{ name = $portName; port = [int]$portMap[$portName] }) | Out-Null
        }
        else {
            $driftFindings.Add((New-DriftFinding -ComponentId $id -Code "missing_port_contract" -Title ("Missing port mapping '{0}' in config/ports.json" -f $portName) -RiskLevel 1 -EvidenceFiles @("config/ports.json"))) | Out-Null
        }
    }

    $pidRows = New-Object System.Collections.Generic.List[object]
    foreach ($pidKey in @($def.pid_keys | Select-Object -Unique)) {
        $pidVal = 0
        if ($stackState -and (Get-PropertyValue -Object $stackState -Name $pidKey -Default $null) -and [int]::TryParse([string](Get-PropertyValue -Object $stackState -Name $pidKey -Default 0), [ref]$pidVal)) {
            $pidRows.Add([pscustomobject][ordered]@{
                    source_key = $pidKey
                    pid        = [int]$pidVal
                    is_alive   = [bool](Test-ProcessAlive -ProcessId $pidVal)
                }) | Out-Null
        }
    }

    $listenersOut = New-Object System.Collections.Generic.List[object]
    foreach ($portRef in @($expectedPorts.ToArray())) {
        $listeners = @(Get-PortListeners -Port ([int]$portRef.port))
        $listenersOut.Add([pscustomobject][ordered]@{
                name       = [string]$portRef.name
                port       = [int]$portRef.port
                listeners  = $listeners
                count      = @($listeners).Count
            }) | Out-Null

        if (@($listeners).Count -gt 1) {
            $uniqueOwners = @($listeners | Select-Object -ExpandProperty owning_pid -Unique)
            if ($uniqueOwners.Count -gt 1) {
                $driftFindings.Add((New-DriftFinding -ComponentId $id -Code "multiple_listener_pids" -Title ("Port {0} has multiple listener PIDs." -f $portRef.port) -RiskLevel 1 -EvidenceFiles @("config/ports.json"))) | Out-Null
            }
        }

        $alivePidSet = New-Object System.Collections.Generic.HashSet[int]
        foreach ($pidRow in @($pidRows.ToArray())) {
            $isAlive = [bool](Get-PropertyValue -Object $pidRow -Name "is_alive" -Default $false)
            if (-not $isAlive) { continue }
            $pidCandidate = 0
            if ([int]::TryParse([string](Get-PropertyValue -Object $pidRow -Name "pid" -Default 0), [ref]$pidCandidate)) {
                $null = $alivePidSet.Add($pidCandidate)
            }
        }
        $alivePids = @($alivePidSet)
        if ($alivePids.Count -gt 0 -and @($listeners).Count -eq 0) {
            $driftFindings.Add((New-DriftFinding -ComponentId $id -Code "expected_pid_no_listener" -Title ("Expected running component has no listener on port {0}." -f $portRef.port) -RiskLevel 1 -EvidenceFiles @("state/knowledge/stack_pids.json"))) | Out-Null
        }
        elseif ($alivePids.Count -gt 0 -and @($listeners).Count -gt 0) {
            $ownerMatch = @($listeners | Where-Object { $alivePids -contains $_.owning_pid }).Count -gt 0
            if (-not $ownerMatch) {
                $driftFindings.Add((New-DriftFinding -ComponentId $id -Code "listener_pid_mismatch" -Title ("Port {0} is not owned by expected component PID." -f $portRef.port) -RiskLevel 1 -EvidenceFiles @("state/knowledge/stack_pids.json"))) | Out-Null
            }
        }
    }

    if (-not $rootExists) {
        $driftFindings.Add((New-DriftFinding -ComponentId $id -Code "component_root_missing" -Title ("Component root missing: {0}" -f (Get-RelativePathSafe -BasePath $repoRoot -FullPath $resolvedRoot)) -RiskLevel 1 -EvidenceFiles @())) | Out-Null
    }

    $componentsOut.Add([pscustomobject][ordered]@{
            component_id      = $id
            label             = $label
            root_path         = Get-RelativePathSafe -BasePath $repoRoot -FullPath $resolvedRoot
            root_exists       = [bool]$rootExists
            root_last_write_utc = $rootLastWrite
            version_stamp     = $versionStamp
            key_files         = @($keyFilesOut.ToArray())
            pids              = @($pidRows.ToArray())
            expected_ports    = @($expectedPorts.ToArray())
            port_listeners    = @($listenersOut.ToArray())
        }) | Out-Null
}

foreach ($entry in $registryIdCounts.GetEnumerator()) {
    if ([int]$entry.Value -gt 1) {
        $driftFindings.Add((New-DriftFinding -ComponentId ([string]$entry.Key) -Code "duplicate_component_registry_id" -Title ("Duplicate component id in registry: {0}" -f [string]$entry.Key) -RiskLevel 1 -EvidenceFiles @("config/component_registry.json"))) | Out-Null
    }
}

$portReverse = @{}
foreach ($name in $portMap.Keys) {
    $port = [int]$portMap[$name]
    if (-not $portReverse.ContainsKey($port)) {
        $portReverse[$port] = New-Object System.Collections.Generic.List[string]
    }
    $portReverse[$port].Add([string]$name) | Out-Null
}
foreach ($port in $portReverse.Keys) {
    $names = @($portReverse[$port].ToArray() | Select-Object -Unique)
    if ($names.Count -gt 1) {
        $driftFindings.Add((New-DriftFinding -ComponentId "mason" -Code "duplicate_port_contract" -Title ("Port {0} assigned to multiple contract keys: {1}" -f $port, ($names -join ", ")) -RiskLevel 1 -EvidenceFiles @("config/ports.json"))) | Out-Null
    }
}

$rootPathMap = @{}
foreach ($component in @($componentsOut.ToArray())) {
    $rootKey = [string](Get-PropertyValue -Object $component -Name "root_path" -Default "")
    if (-not $rootKey) { continue }
    if (-not $rootPathMap.ContainsKey($rootKey)) {
        $rootPathMap[$rootKey] = New-Object System.Collections.Generic.List[string]
    }
    $rootPathMap[$rootKey].Add([string]$component.component_id) | Out-Null
}
foreach ($rootKey in $rootPathMap.Keys) {
    $owners = @($rootPathMap[$rootKey].ToArray() | Select-Object -Unique)
    if ($owners.Count -gt 1) {
        $driftFindings.Add((New-DriftFinding -ComponentId "mason" -Code "duplicate_component_root" -Title ("Multiple components share same root path '{0}': {1}" -f $rootKey, ($owners -join ", ")) -RiskLevel 1 -EvidenceFiles @("config/component_registry.json"))) | Out-Null
    }
}

$driftList = @($driftFindings.ToArray())
$riskLow = @($driftList | Where-Object { [int]$_.risk_level -le 1 }).Count
$riskHigh = @($driftList | Where-Object { [int]$_.risk_level -gt 1 }).Count
$missingRoots = @($componentsOut.ToArray() | Where-Object { -not $_.root_exists }).Count
$activePortBindings = @(
    $componentsOut.ToArray() |
    ForEach-Object { $_.port_listeners } |
    ForEach-Object { $_ } |
    Where-Object { $_ -and $_.count -gt 0 }
).Count

$inventory = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    root_path        = $repoRoot
    sources          = [ordered]@{
        component_registry = $componentRegistryPath
        ports_contract     = $portsPath
        stack_pids         = $stackPidPath
    }
    ports_contract   = [ordered]@{
        bind_host = [string](Get-PropertyValue -Object $portsConfig -Name "bind_host" -Default "127.0.0.1")
        ports     = $portMap
    }
    runtime_status   = [ordered]@{
        masonconsole = [ordered]@{
            endpoint_url     = $masonConsoleEndpoint
            endpoint_ok      = [bool]$masonConsoleEndpointOk
            listener_count   = @($masonConsoleListeners).Count
            listener_pids    = @($masonConsoleListeners | ForEach-Object { [int]$_.owning_pid } | Select-Object -Unique)
            process_count    = @($masonConsoleProcesses).Count
            process_pids     = @($masonConsoleProcesses | ForEach-Object { [int]$_.ProcessId } | Select-Object -Unique)
        }
        onyx_launcher = [ordered]@{
            path           = $onyxLauncherRelative
            exists         = [bool]$onyxLauncherExists
            last_write_utc = $onyxLauncherLastWrite
            last_start     = $onyxLastStartStatus
        }
        drift = [ordered]@{
            manifest_path       = $driftManifestPath
            manifest_exists     = (Test-Path -LiteralPath $driftManifestPath)
            drift_count         = if ($driftManifest) { [int](Get-PropertyValue -Object $driftManifest -Name "drift_count" -Default 0) } else { $null }
            generated_at_utc    = if ($driftManifest) { [string](Get-PropertyValue -Object $driftManifest -Name "generated_at_utc" -Default "") } else { $null }
            fingerprint         = if ($driftManifest) { [string](Get-PropertyValue -Object $driftManifest -Name "drift_fingerprint" -Default "") } else { $null }
            last_change_utc     = if ($lastDriftHistoryEntry) { [string](Get-PropertyValue -Object $lastDriftHistoryEntry -Name "generated_at_utc" -Default "") } else { $null }
            expected_pipeline   = if ($driftManifest) { [bool](Get-PropertyValue -Object $driftManifest -Name "expected_update_pipeline" -Default $false) } else { $null }
        }
    }
    components       = @($componentsOut.ToArray())
    drift_findings   = $driftList
    summary          = [ordered]@{
        component_count        = $componentsOut.Count
        missing_component_roots = $missingRoots
        drift_findings_total   = $driftList.Count
        drift_low_risk_count   = $riskLow
        drift_high_risk_count  = $riskHigh
        active_port_bindings   = [int]$activePortBindings
        masonconsole_endpoint_ok = [bool]$masonConsoleEndpointOk
        onyx_launcher_found    = [bool]$onyxLauncherExists
    }
}

Write-JsonFile -Path $inventoryPath -Object $inventory -Depth 24

$historyEntry = [ordered]@{
    generated_at_utc = $inventory.generated_at_utc
    summary          = $inventory.summary
    component_ids    = @($componentsOut.ToArray() | ForEach-Object { [string]$_.component_id })
}
Update-HistoryJsonl -Path $historyPath -Entry $historyEntry -RetainDays 7

[pscustomobject]@{
    ok            = $true
    inventory     = $inventoryPath
    history       = $historyPath
    summary       = $inventory.summary
} | ConvertTo-Json -Depth 10
