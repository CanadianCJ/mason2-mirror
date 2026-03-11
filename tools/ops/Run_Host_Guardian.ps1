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
        [int]$Depth = 16
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
    if ($property) {
        return $property.Value
    }

    return $Default
}

function Convert-BytesToGiB {
    param([double]$Bytes)

    if ($Bytes -le 0) {
        return 0.0
    }

    return [math]::Round(($Bytes / 1GB), 2)
}

function Convert-KiBToGiB {
    param([double]$KiB)

    if ($KiB -le 0) {
        return 0.0
    }

    return [math]::Round((($KiB * 1KB) / 1GB), 2)
}

function Get-PressureLevelFromPercent {
    param(
        [double]$Value,
        [double]$CautionThreshold,
        [double]$ThrottleThreshold,
        [double]$ProtectThreshold
    )

    if ($Value -ge $ProtectThreshold) {
        return "protect_host"
    }
    if ($Value -ge $ThrottleThreshold) {
        return "throttle_heavy_jobs"
    }
    if ($Value -ge $CautionThreshold) {
        return "caution"
    }
    return "normal"
}

function Get-DiskPressureLevel {
    param(
        [double]$FreePercent,
        [double]$FreeGiB
    )

    if ($FreePercent -le 8 -or $FreeGiB -le 10) {
        return "protect_host"
    }
    if ($FreePercent -le 15 -or $FreeGiB -le 20) {
        return "throttle_heavy_jobs"
    }
    if ($FreePercent -le 22 -or $FreeGiB -le 35) {
        return "caution"
    }
    return "normal"
}

function Compare-PressureLevel {
    param(
        [string]$Left,
        [string]$Right
    )

    $rank = @{
        normal = 0
        caution = 1
        throttle_heavy_jobs = 2
        protect_host = 3
    }

    $leftValue = if ($rank.ContainsKey($Left)) { [int]$rank[$Left] } else { -1 }
    $rightValue = if ($rank.ContainsKey($Right)) { [int]$rank[$Right] } else { -1 }
    if ($leftValue -ge $rightValue) {
        return $Left
    }
    return $Right
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

    $portsCfg = Read-JsonSafe -Path (Join-Path $RepoRoot "config\ports.json") -Default $null
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

    $entries = @()
    if ($portsSource -is [System.Collections.IDictionary]) {
        foreach ($item in @($portsSource.GetEnumerator())) {
            $entries += [pscustomobject]@{
                name  = [string]$item.Key
                value = $item.Value
            }
        }
    }
    else {
        foreach ($prop in @($portsSource.PSObject.Properties)) {
            $entries += [pscustomobject]@{
                name  = [string]$prop.Name
                value = $prop.Value
            }
        }
    }

    foreach ($entry in $entries) {
        $normalizedName = [regex]::Replace(([string]$entry.name).ToLowerInvariant().Replace("-", "_"), "[^a-z0-9_]", "")
        if (-not $aliasToCanonical.ContainsKey($normalizedName)) {
            continue
        }

        $parsed = 0
        if ([int]::TryParse([string]$entry.value, [ref]$parsed) -and $parsed -gt 0 -and $parsed -le 65535) {
            $normalized[[string]$aliasToCanonical[$normalizedName]] = $parsed
        }
    }

    $result = [ordered]@{}
    foreach ($key in $stableKeys) {
        $result[$key] = [int]$normalized[$key]
    }
    return $result
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

    $parsed = 0
    if ([int]::TryParse([string]$match.Groups[1].Value, [ref]$parsed)) {
        return [int]$parsed
    }

    return $null
}

function Get-NetstatListenerRows {
    param([int[]]$Ports)

    $portSet = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($port in @($Ports | Sort-Object -Unique)) {
        if ($port -gt 0) {
            [void]$portSet.Add([int]$port)
        }
    }

    $rows = @()
    foreach ($line in @(& netstat -ano -p tcp 2>$null)) {
        $trimmed = ([string]$line).Trim()
        if (-not $trimmed) {
            continue
        }
        if ($trimmed -notmatch '^\s*TCP\s+(\S+)\s+\S+\s+LISTENING\s+(\d+)\s*$') {
            continue
        }

        $endpoint = [string]$Matches[1]
        $pid = 0
        if (-not [int]::TryParse([string]$Matches[2], [ref]$pid) -or $pid -le 0) {
            continue
        }

        $port = Get-PortFromEndpoint -Endpoint $endpoint
        if ($null -eq $port -or -not $portSet.Contains([int]$port)) {
            continue
        }

        $localAddress = [string]$endpoint
        $splitMatch = [regex]::Match([string]$endpoint, '^(.*):(\d+)$')
        if ($splitMatch.Success) {
            $localAddress = [string]$splitMatch.Groups[1].Value
        }

        $rows += [pscustomobject]@{
            local_address = $localAddress
            local_port    = [int]$port
            owning_pid    = [int]$pid
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
            foreach ($row in @(Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction Stop)) {
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

function Invoke-HttpProbe {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSeconds = 8
    )

    try {
        $request = @{
            Uri         = $Url
            Method      = "Get"
            TimeoutSec  = $TimeoutSeconds
            ErrorAction = "Stop"
        }
        if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey("UseBasicParsing")) {
            $request["UseBasicParsing"] = $true
        }

        $response = Invoke-WebRequest @request
        return [pscustomobject]@{
            url         = $Url
            ok          = ([int]$response.StatusCode -eq 200)
            status_code = [int]$response.StatusCode
            error       = ""
        }
    }
    catch {
        return [pscustomobject]@{
            url         = $Url
            ok          = $false
            status_code = 0
            error       = Normalize-Text $_.Exception.Message
        }
    }
}

function Get-FolderUsageBytes {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return 0L
    }

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $item) {
        return 0L
    }

    if (-not $item.PSIsContainer) {
        return [int64]$item.Length
    }

    $measure = Get-ChildItem -LiteralPath $item.FullName -File -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
    if ($null -eq $measure.Sum) {
        return 0L
    }
    return [int64]$measure.Sum
}

function Get-ObservedFolderSizes {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $observedRoots = @(
        "MasonConsole",
        "Component - Onyx App",
        "bridge",
        "reports",
        "state",
        "tools",
        "config",
        "services",
        "roadmap"
    )

    $items = New-Object System.Collections.Generic.List[object]
    foreach ($relativePath in $observedRoots) {
        $fullPath = Join-Path $RepoRoot $relativePath
        if (-not (Test-Path -LiteralPath $fullPath)) {
            continue
        }

        $bytes = Get-FolderUsageBytes -Path $fullPath
        $items.Add([pscustomobject]@{
                path     = $relativePath
                bytes    = [int64]$bytes
                size_gib = Convert-BytesToGiB -Bytes $bytes
            }) | Out-Null
    }

    return @($items | Sort-Object bytes -Descending | Select-Object -First 8)
}

function Get-ReportsGrowthRisk {
    param([Parameter(Mandatory = $true)][string]$ReportsRoot)

    if (-not (Test-Path -LiteralPath $ReportsRoot)) {
        return [ordered]@{
            status             = "PASS"
            total_bytes        = 0
            total_gib          = 0.0
            log_bytes          = 0
            log_gib            = 0.0
            file_count         = 0
            largest_files      = @()
            recommended_action = "No action required."
            risky              = $false
        }
    }

    $files = @(Get-ChildItem -LiteralPath $ReportsRoot -File -Recurse -ErrorAction SilentlyContinue)
    $totalBytes = [int64](($files | Measure-Object -Property Length -Sum).Sum)
    $logFiles = @(
        $files | Where-Object {
            $extension = ([System.IO.Path]::GetExtension([string]$_.Name)).ToLowerInvariant()
            $extension -in @(".log", ".txt")
        }
    )
    $logBytes = [int64](($logFiles | Measure-Object -Property Length -Sum).Sum)
    $largest = @(
        $files |
        Sort-Object Length -Descending |
        Select-Object -First 6 |
        ForEach-Object {
            [pscustomobject]@{
                path     = [string]$_.FullName
                bytes    = [int64]$_.Length
                size_gib = Convert-BytesToGiB -Bytes ([int64]$_.Length)
            }
        }
    )

    $status = "PASS"
    $recommended = "No action required."
    if ($totalBytes -ge 2GB -or $logBytes -ge 512MB -or @($files).Count -ge 12000) {
        $status = "WARN"
        $recommended = "Review report and log growth; run the existing log maintenance path if retention needs trimming."
    }

    return [ordered]@{
        status             = $status
        total_bytes        = [int64]$totalBytes
        total_gib          = Convert-BytesToGiB -Bytes $totalBytes
        log_bytes          = [int64]$logBytes
        log_gib            = Convert-BytesToGiB -Bytes $logBytes
        file_count         = @($files).Count
        largest_files      = @($largest)
        recommended_action = $recommended
        risky              = ($status -ne "PASS")
    }
}

function Get-StackPidPresence {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $stackPath = Join-Path $RepoRoot "state\knowledge\stack_pids.json"
    $stackData = Read-JsonSafe -Path $stackPath -Default $null
    if (-not $stackData) {
        return [ordered]@{
            readable           = $false
            path               = $stackPath
            tracked_pid_total  = 0
            tracked_pid_alive  = 0
            tracked_components = @()
            alive_components   = @()
        }
    }

    $tracked = @()
    foreach ($property in @($stackData.PSObject.Properties)) {
        if ($property.Name -notlike "*_pid") {
            continue
        }

        $parsedPid = 0
        $valueText = [string]$property.Value
        if ([string]::IsNullOrWhiteSpace($valueText)) {
            continue
        }

        if (-not [int]::TryParse($valueText, [ref]$parsedPid)) {
            continue
        }

        if ($parsedPid -le 0) {
            continue
        }

        $tracked += [pscustomobject]@{
            component = [string]$property.Name
            pid       = [int]$parsedPid
        }
    }

    $alive = @()
    foreach ($entry in @($tracked)) {
        try {
            $null = Get-Process -Id $entry.pid -ErrorAction Stop
            $alive += $entry
        }
        catch {
        }
    }

    return [ordered]@{
        readable           = $true
        path               = $stackPath
        tracked_pid_total  = @($tracked).Count
        tracked_pid_alive  = @($alive).Count
        tracked_components = @($tracked | Select-Object -First 25)
        alive_components   = @($alive | Select-Object -First 25)
    }
}

function Get-DefenderPosture {
    $result = [ordered]@{
        readable                   = $false
        am_service_enabled         = $null
        antivirus_enabled          = $null
        real_time_protection       = $null
        signature_last_updated_utc = $null
        signature_age_days         = $null
        status                     = "WARN"
        detail                     = "Windows Defender status could not be read."
    }

    try {
        $mp = Get-MpComputerStatus -ErrorAction Stop
        $signatureUpdated = $null
        if ($mp.AntivirusSignatureLastUpdated) {
            $signatureUpdated = (Get-Date $mp.AntivirusSignatureLastUpdated).ToUniversalTime()
        }

        $signatureAgeDays = $null
        if ($signatureUpdated) {
            $signatureAgeDays = [math]::Round(((Get-Date).ToUniversalTime() - $signatureUpdated).TotalDays, 2)
        }

        $status = "PASS"
        $detail = "Windows Defender is enabled and readable."
        if (-not [bool]$mp.AMServiceEnabled -or -not [bool]$mp.AntivirusEnabled -or -not [bool]$mp.RealTimeProtectionEnabled) {
            $status = "FAIL"
            $detail = "Windows Defender or real-time protection is disabled."
        }
        elseif ($null -ne $signatureAgeDays -and $signatureAgeDays -gt 7) {
            $status = "WARN"
            $detail = "Windows Defender signatures appear stale."
        }

        $result.readable = $true
        $result.am_service_enabled = [bool]$mp.AMServiceEnabled
        $result.antivirus_enabled = [bool]$mp.AntivirusEnabled
        $result.real_time_protection = [bool]$mp.RealTimeProtectionEnabled
        $result.signature_last_updated_utc = if ($signatureUpdated) { $signatureUpdated.ToString("o") } else { $null }
        $result.signature_age_days = $signatureAgeDays
        $result.status = $status
        $result.detail = $detail
    }
    catch {
        $result.detail = Normalize-Text $_.Exception.Message
    }

    return $result
}

function Get-FirewallPosture {
    $result = [ordered]@{
        readable             = $false
        all_profiles_enabled = $null
        profiles             = @()
        status               = "WARN"
        detail               = "Firewall profile state could not be read."
    }

    try {
        $profiles = @(Get-NetFirewallProfile -ErrorAction Stop)
        $normalizedProfiles = @(
            $profiles | ForEach-Object {
                [pscustomobject]@{
                    name                    = [string]$_.Name
                    enabled                 = [bool]$_.Enabled
                    default_inbound_action  = [string]$_.DefaultInboundAction
                    default_outbound_action = [string]$_.DefaultOutboundAction
                }
            }
        )
        $allEnabled = (@($normalizedProfiles | Where-Object { -not $_.enabled }).Count -eq 0)
        $status = if ($allEnabled) { "PASS" } else { "FAIL" }
        $detail = if ($allEnabled) { "All firewall profiles are enabled." } else { "One or more firewall profiles are disabled." }

        $result.readable = $true
        $result.all_profiles_enabled = [bool]$allEnabled
        $result.profiles = @($normalizedProfiles)
        $result.status = $status
        $result.detail = $detail
    }
    catch {
        $result.detail = Normalize-Text $_.Exception.Message
    }

    return $result
}

function Get-PendingRebootState {
    $result = [ordered]@{
        readable   = $true
        required   = $false
        indicators = @()
        status     = "PASS"
        detail     = "No reboot-required indicators found."
    }

    try {
        $keys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        )
        $indicators = New-Object System.Collections.Generic.List[string]
        foreach ($key in $keys) {
            if (Test-Path $key) {
                $indicators.Add($key) | Out-Null
            }
        }

        $pendingRename = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -ErrorAction SilentlyContinue).PendingFileRenameOperations
        if ($pendingRename) {
            $indicators.Add("HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations") | Out-Null
        }

        $required = (@($indicators).Count -gt 0)
        $result.required = $required
        $result.indicators = @($indicators | Sort-Object -Unique)
        if ($required) {
            $result.status = "WARN"
            $result.detail = "A Windows reboot is pending."
        }
    }
    catch {
        $result.readable = $false
        $result.status = "WARN"
        $result.detail = Normalize-Text $_.Exception.Message
    }

    return $result
}

$repoRoot = Get-RepoRoot -OverrideRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$hostHealthPath = Join-Path $reportsDir "host_health_last.json"
$resourcePressurePath = Join-Path $reportsDir "resource_pressure_last.json"
$hostSecurityPath = Join-Path $reportsDir "host_security_posture_last.json"
$maintenanceActionsPath = Join-Path $reportsDir "maintenance_actions_last.json"
$timestampUtc = (Get-Date).ToUniversalTime().ToString("o")
$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Host_Guardian.ps1"

$cpuPerf = $null
try {
    $cpuPerf = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction Stop
}
catch {
}

$cpuUsagePercent = $null
if ($cpuPerf -and $cpuPerf.PercentProcessorTime -ne $null) {
    $cpuUsagePercent = [math]::Round([double]$cpuPerf.PercentProcessorTime, 2)
}
else {
    try {
        $processors = @(Get-CimInstance Win32_Processor -ErrorAction Stop)
        if (@($processors).Count -gt 0) {
            $cpuUsagePercent = [math]::Round(([double](($processors | Measure-Object -Property LoadPercentage -Average).Average)), 2)
        }
    }
    catch {
        $cpuUsagePercent = 0.0
    }
}
if ($null -eq $cpuUsagePercent) {
    $cpuUsagePercent = 0.0
}
$cpuPressureLevel = Get-PressureLevelFromPercent -Value $cpuUsagePercent -CautionThreshold 65 -ThrottleThreshold 80 -ProtectThreshold 92

$os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
$memoryTotalGiB = Convert-KiBToGiB -KiB ([double]$os.TotalVisibleMemorySize)
$memoryFreeGiB = Convert-KiBToGiB -KiB ([double]$os.FreePhysicalMemory)
$memoryUsedGiB = [math]::Round(($memoryTotalGiB - $memoryFreeGiB), 2)
$memoryUsedPercent = if ($memoryTotalGiB -gt 0) { [math]::Round((($memoryUsedGiB / $memoryTotalGiB) * 100), 2) } else { 0.0 }
$memoryPressureLevel = Get-PressureLevelFromPercent -Value $memoryUsedPercent -CautionThreshold 75 -ThrottleThreshold 85 -ProtectThreshold 92

$fixedDrives = @(Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop)
$diskRows = @()
$worstDiskPressure = "normal"
$systemDriveRow = $null
foreach ($drive in $fixedDrives) {
    $sizeBytes = [double]$drive.Size
    $freeBytes = [double]$drive.FreeSpace
    $freePercent = if ($sizeBytes -gt 0) { [math]::Round((($freeBytes / $sizeBytes) * 100), 2) } else { 0.0 }
    $freeGiB = Convert-BytesToGiB -Bytes $freeBytes
    $pressureLevel = Get-DiskPressureLevel -FreePercent $freePercent -FreeGiB $freeGiB
    $worstDiskPressure = Compare-PressureLevel -Left $worstDiskPressure -Right $pressureLevel

    $row = [pscustomobject]@{
        drive          = [string]$drive.DeviceID
        volume_name    = [string]$drive.VolumeName
        size_gib       = Convert-BytesToGiB -Bytes $sizeBytes
        free_gib       = $freeGiB
        free_percent   = $freePercent
        pressure_level = $pressureLevel
    }
    $diskRows += $row
    if ($drive.DeviceID -eq $env:SystemDrive) {
        $systemDriveRow = $row
    }
}
if (-not $systemDriveRow -and @($diskRows).Count -gt 0) {
    $systemDriveRow = $diskRows[0]
}

$processCount = @(Get-Process -ErrorAction SilentlyContinue).Count
$lastBoot = (Get-Date $os.LastBootUpTime).ToUniversalTime()
$uptimeSpan = (Get-Date).ToUniversalTime() - $lastBoot
$pendingReboot = Get-PendingRebootState

$contractPorts = Get-ContractPorts -RepoRoot $repoRoot
$portOrder = @("mason_api", "seed_api", "bridge", "athena", "onyx")
$componentUrls = [ordered]@{
    mason_api = "http://127.0.0.1:{0}/health"
    seed_api  = "http://127.0.0.1:{0}/health"
    bridge    = "http://127.0.0.1:{0}/health"
    athena    = "http://127.0.0.1:{0}/api/health"
    onyx      = "http://127.0.0.1:{0}/main.dart.js"
}
$portSnapshot = Get-PortSnapshot -Ports @($contractPorts.Values)
$runtimeChecks = New-Object System.Collections.Generic.List[object]
$missingRuntimeComponents = New-Object System.Collections.Generic.List[string]
foreach ($component in $portOrder) {
    $port = [int]$contractPorts[$component]
    $portRow = @($portSnapshot | Where-Object { [int]$_.port -eq $port } | Select-Object -First 1)
    $isListening = ($portRow -and [int]$portRow.listener_count -gt 0)
    $url = [string]::Format($componentUrls[$component], $port)
    $probe = Invoke-HttpProbe -Url $url -TimeoutSeconds 8
    $status = "PASS"
    if (-not $isListening -or -not [bool]$probe.ok) {
        $status = "FAIL"
        $missingRuntimeComponents.Add($component) | Out-Null
    }

    $runtimeChecks.Add([pscustomobject]@{
            component      = $component
            port           = $port
            listening      = [bool]$isListening
            listener_count = if ($portRow) { [int]$portRow.listener_count } else { 0 }
            owning_pids    = if ($portRow) { @($portRow.listeners | ForEach-Object { [int]$_.owning_pid } | Sort-Object -Unique) } else { @() }
            health_url     = $url
            health_ok      = [bool]$probe.ok
            health_status  = if ($probe.ok) { "PASS" } else { "FAIL" }
            status         = $status
            error          = [string]$probe.error
        }) | Out-Null
}

$reportsGrowth = Get-ReportsGrowthRisk -ReportsRoot $reportsDir
$stackPidPresence = Get-StackPidPresence -RepoRoot $repoRoot
$observedFolders = Get-ObservedFolderSizes -RepoRoot $repoRoot

$pressureLevel = "normal"
foreach ($candidate in @($cpuPressureLevel, $memoryPressureLevel, $worstDiskPressure)) {
    $pressureLevel = Compare-PressureLevel -Left $pressureLevel -Right $candidate
}
if ($reportsGrowth.risky -and $pressureLevel -eq "normal") {
    $pressureLevel = "caution"
}
if ([bool]$pendingReboot.required -and $pressureLevel -eq "normal") {
    $pressureLevel = "caution"
}
$heavyJobsAllowed = ($pressureLevel -eq "normal" -or $pressureLevel -eq "caution")

$resourceRationale = New-Object System.Collections.Generic.List[string]
$resourceRationale.Add(("CPU usage is {0}% ({1})." -f $cpuUsagePercent, $cpuPressureLevel)) | Out-Null
$resourceRationale.Add(("Memory usage is {0}% ({1} GiB used / {2} GiB total; {3})." -f $memoryUsedPercent, $memoryUsedGiB, $memoryTotalGiB, $memoryPressureLevel)) | Out-Null
if ($systemDriveRow) {
    $resourceRationale.Add(("System drive {0} has {1}% free ({2} GiB free; {3})." -f $systemDriveRow.drive, $systemDriveRow.free_percent, $systemDriveRow.free_gib, $systemDriveRow.pressure_level)) | Out-Null
}
if ($reportsGrowth.risky) {
    $resourceRationale.Add(("Reports folder growth is elevated ({0} GiB total, {1} GiB logs)." -f $reportsGrowth.total_gib, $reportsGrowth.log_gib)) | Out-Null
}
if ([bool]$pendingReboot.required) {
    $resourceRationale.Add("A Windows reboot is pending; avoid piling on heavy maintenance work.") | Out-Null
}

$masonRuntimeStatus = "PASS"
if (@($missingRuntimeComponents).Count -gt 0) {
    $masonRuntimeStatus = "FAIL"
}
elseif ($reportsGrowth.risky) {
    $masonRuntimeStatus = "WARN"
}

$hostOverallStatus = "PASS"
if ($pressureLevel -eq "protect_host" -or $masonRuntimeStatus -eq "FAIL") {
    $hostOverallStatus = "FAIL"
}
elseif ($pressureLevel -ne "normal" -or $reportsGrowth.risky -or [bool]$pendingReboot.required) {
    $hostOverallStatus = "WARN"
}

$recommendedNextAction = "No action required."
if (@($missingRuntimeComponents).Count -gt 0) {
    $recommendedNextAction = ("Restore Mason runtime components: {0}." -f ((@($missingRuntimeComponents) | Sort-Object -Unique) -join ", "))
}
elseif ($pressureLevel -eq "protect_host") {
    $recommendedNextAction = "Protect the host: defer Mason heavy jobs and free space or memory pressure before further work."
}
elseif ($pressureLevel -eq "throttle_heavy_jobs") {
    $recommendedNextAction = "Throttle heavy Mason jobs until CPU, memory, or disk pressure drops."
}
elseif ([bool]$pendingReboot.required) {
    $recommendedNextAction = "Schedule a controlled Windows reboot to clear the pending reboot state."
}
elseif ($reportsGrowth.risky) {
    $recommendedNextAction = $reportsGrowth.recommended_action
}

$resourcePressure = [ordered]@{
    timestamp_utc      = $timestampUtc
    cpu_pressure       = [ordered]@{
        usage_percent  = $cpuUsagePercent
        pressure_level = $cpuPressureLevel
    }
    memory_pressure    = [ordered]@{
        used_percent   = $memoryUsedPercent
        used_gib       = $memoryUsedGiB
        total_gib      = $memoryTotalGiB
        available_gib  = $memoryFreeGiB
        pressure_level = $memoryPressureLevel
    }
    disk_pressure      = [ordered]@{
        system_drive              = if ($systemDriveRow) { $systemDriveRow.drive } else { $env:SystemDrive }
        system_drive_free_percent = if ($systemDriveRow) { $systemDriveRow.free_percent } else { $null }
        system_drive_free_gib     = if ($systemDriveRow) { $systemDriveRow.free_gib } else { $null }
        worst_pressure_level      = $worstDiskPressure
        drives                    = @($diskRows)
    }
    pressure_level     = $pressureLevel
    heavy_jobs_allowed = [bool]$heavyJobsAllowed
    rationale          = @($resourceRationale)
    command_run        = $commandRun
    repo_root          = $repoRoot
}

$hostHealth = [ordered]@{
    timestamp_utc             = $timestampUtc
    overall_status            = $hostOverallStatus
    cpu                       = [ordered]@{
        usage_percent  = $cpuUsagePercent
        pressure_level = $cpuPressureLevel
    }
    memory                    = [ordered]@{
        total_gib      = $memoryTotalGiB
        available_gib  = $memoryFreeGiB
        used_gib       = $memoryUsedGiB
        used_percent   = $memoryUsedPercent
        pressure_level = $memoryPressureLevel
    }
    disk                      = [ordered]@{
        system_drive              = if ($systemDriveRow) { $systemDriveRow.drive } else { $env:SystemDrive }
        system_drive_free_gib     = if ($systemDriveRow) { $systemDriveRow.free_gib } else { $null }
        system_drive_free_percent = if ($systemDriveRow) { $systemDriveRow.free_percent } else { $null }
        pressure_level            = $worstDiskPressure
        fixed_drives              = @($diskRows)
    }
    uptime                    = [ordered]@{
        last_boot_utc  = $lastBoot.ToString("o")
        uptime_days    = [math]::Round($uptimeSpan.TotalDays, 2)
        uptime_human   = ("{0}d {1}h {2}m" -f [math]::Floor($uptimeSpan.TotalDays), $uptimeSpan.Hours, $uptimeSpan.Minutes)
        pending_reboot = [bool]$pendingReboot.required
    }
    process_count_total       = $processCount
    top_large_observed_folders = @($observedFolders)
    mason_runtime_health      = [ordered]@{
        status                       = $masonRuntimeStatus
        contract_ports               = $contractPorts
        listener_health              = @($runtimeChecks.ToArray())
        all_required_ports_listening = (@($missingRuntimeComponents).Count -eq 0)
        report_growth                = $reportsGrowth
        stack_pid_presence           = $stackPidPresence
    }
    recommended_next_action   = $recommendedNextAction
    throttle_guidance         = $pressureLevel
    command_run               = $commandRun
    repo_root                 = $repoRoot
}

$defenderPosture = Get-DefenderPosture
$firewallPosture = Get-FirewallPosture
$securityDrift = New-Object System.Collections.Generic.List[string]
if ($defenderPosture.status -eq "FAIL") {
    $securityDrift.Add("Windows Defender or real-time protection is disabled.") | Out-Null
}
elseif ($defenderPosture.status -eq "WARN") {
    $securityDrift.Add([string]$defenderPosture.detail) | Out-Null
}
if ($firewallPosture.status -eq "FAIL") {
    $securityDrift.Add("One or more Windows Firewall profiles are disabled.") | Out-Null
}
elseif ($firewallPosture.status -eq "WARN") {
    $securityDrift.Add([string]$firewallPosture.detail) | Out-Null
}
if ([bool]$pendingReboot.required) {
    $securityDrift.Add("Windows reports a pending reboot.") | Out-Null
}

$hostSecurityStatus = "PASS"
if ($defenderPosture.status -eq "FAIL" -or $firewallPosture.status -eq "FAIL") {
    $hostSecurityStatus = "FAIL"
}
elseif ($defenderPosture.status -ne "PASS" -or $firewallPosture.status -ne "PASS" -or [bool]$pendingReboot.required) {
    $hostSecurityStatus = "WARN"
}

$securityNextAction = "No action required."
if ($hostSecurityStatus -eq "FAIL") {
    $securityNextAction = "Restore host security controls before allowing broader automation or risky maintenance."
}
elseif ([bool]$pendingReboot.required) {
    $securityNextAction = "Schedule a controlled reboot and confirm Defender and Firewall posture afterwards."
}
elseif ($hostSecurityStatus -eq "WARN") {
    $securityNextAction = "Review host security warnings and keep automation in a guarded posture."
}

$hostSecurity = [ordered]@{
    timestamp_utc           = $timestampUtc
    defender_state          = $defenderPosture
    firewall_state          = $firewallPosture
    reboot_required         = $pendingReboot
    risky_drift_items       = @($securityDrift)
    host_security_status    = $hostSecurityStatus
    recommended_next_action = $securityNextAction
    command_run             = $commandRun
    repo_root               = $repoRoot
}

$actionsConsidered = New-Object System.Collections.Generic.List[object]
$actionsPerformed = New-Object System.Collections.Generic.List[object]
$actionsBlocked = New-Object System.Collections.Generic.List[object]

$actionsConsidered.Add([ordered]@{
        action_id          = "observe_host_metrics"
        decision           = "observed_only"
        reason             = "Collect authoritative host CPU, memory, disk, uptime, runtime, and security signals."
        evidence           = "reports/host_health_last.json, reports/resource_pressure_last.json, reports/host_security_posture_last.json"
        recommended_action = "No action required."
        risk_level         = "low"
    }) | Out-Null

if ($reportsGrowth.risky -and (Test-Path -LiteralPath (Join-Path $repoRoot "tools\Log_Maintenance.ps1"))) {
    $actionsConsidered.Add([ordered]@{
            action_id          = "recommend_log_maintenance"
            decision           = "recommended_safe"
            reason             = "Report or log growth is elevated but destructive cleanup is not allowed in this chunk."
            evidence           = ("reports total={0} GiB; logs={1} GiB" -f $reportsGrowth.total_gib, $reportsGrowth.log_gib)
            recommended_action = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\Log_Maintenance.ps1"
            risk_level         = "low"
        }) | Out-Null
}

$blockedCleanup = [ordered]@{
    action_id          = "delete_temp_or_archive_content"
    decision           = "blocked_by_policy"
    reason             = "Broad host cleanup could delete valuable or active local assets."
    evidence           = "Host guardian is visibility-first in this chunk."
    recommended_action = "Manual review only; do not auto-delete."
    risk_level         = "medium"
}
$actionsConsidered.Add($blockedCleanup) | Out-Null
$actionsBlocked.Add($blockedCleanup) | Out-Null

$blockedSecurityChange = [ordered]@{
    action_id          = "change_host_security_controls"
    decision           = "blocked_by_policy"
    reason             = "Disabling or reconfiguring security controls is not allowed in this chunk."
    evidence           = "No disabling Defender, Firewall, or making major registry/system changes."
    recommended_action = "Owner-approved manual change only."
    risk_level         = "high"
}
$actionsConsidered.Add($blockedSecurityChange) | Out-Null
$actionsBlocked.Add($blockedSecurityChange) | Out-Null

$decisionCounts = [ordered]@{
    observed_only       = @($actionsConsidered | Where-Object { $_.decision -eq "observed_only" }).Count
    recommended_safe    = @($actionsConsidered | Where-Object { $_.decision -eq "recommended_safe" }).Count
    auto_safe_performed = @($actionsConsidered | Where-Object { $_.decision -eq "auto_safe_performed" }).Count
    blocked_by_policy   = @($actionsConsidered | Where-Object { $_.decision -eq "blocked_by_policy" }).Count
}

$maintenanceActions = [ordered]@{
    timestamp_utc      = $timestampUtc
    actions_considered = @($actionsConsidered.ToArray())
    actions_performed  = @($actionsPerformed.ToArray())
    actions_blocked    = @($actionsBlocked.ToArray())
    decision_counts    = $decisionCounts
    policy_posture     = "observe_and_recommend_only"
    notes              = @(
        "No destructive host actions were performed.",
        "No security controls were disabled or reconfigured.",
        "Throttle guidance is advisory and based on current host pressure plus Mason runtime signals."
    )
    command_run        = $commandRun
    repo_root          = $repoRoot
}

Write-JsonFile -Path $hostHealthPath -Object $hostHealth -Depth 18
Write-JsonFile -Path $resourcePressurePath -Object $resourcePressure -Depth 18
Write-JsonFile -Path $hostSecurityPath -Object $hostSecurity -Depth 18
Write-JsonFile -Path $maintenanceActionsPath -Object $maintenanceActions -Depth 18

$summary = [ordered]@{
    timestamp_utc            = $timestampUtc
    host_health_path         = $hostHealthPath
    resource_pressure_path   = $resourcePressurePath
    host_security_path       = $hostSecurityPath
    maintenance_actions_path = $maintenanceActionsPath
    overall_status           = $hostOverallStatus
    throttle_guidance        = $pressureLevel
    recommended_next_action  = $recommendedNextAction
}

$summary | ConvertTo-Json -Depth 8
