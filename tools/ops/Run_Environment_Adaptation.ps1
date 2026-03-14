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

function Get-Sha256Hex {
    param([Parameter(Mandatory = $true)][string]$Value)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
        $hash = $sha.ComputeHash($bytes)
        return ([System.BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
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

function Get-HostClassification {
    param(
        [string]$Manufacturer,
        [string]$Model,
        [string]$OsCaption,
        [int]$PcSystemType
    )

    $manufacturerText = Normalize-Text $Manufacturer
    $modelText = Normalize-Text $Model
    $osText = Normalize-Text $OsCaption
    $combined = ("{0} {1}" -f $manufacturerText, $modelText).ToLowerInvariant()

    if ($osText -match "server") {
        return "server_like"
    }
    if ($combined -match "virtual|vmware|virtualbox|hyper-v|kvm|qemu|xen") {
        return "vm"
    }
    if ($PcSystemType -in @(2, 8, 9, 10, 14)) {
        return "laptop"
    }
    if ($PcSystemType -eq 4) {
        return "server_like"
    }
    return "desktop"
}

function Get-PreferredIdentityToken {
    param(
        [string]$MachineUuid,
        [string]$BiosSerial,
        [string]$Manufacturer,
        [string]$Model,
        [string]$Hostname
    )

    $candidates = @(
        Normalize-Text $MachineUuid,
        Normalize-Text $BiosSerial
    )

    foreach ($candidate in $candidates) {
        if (-not $candidate) {
            continue
        }
        $upper = $candidate.ToUpperInvariant()
        if ($upper -eq "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF") {
            continue
        }
        if ($upper -eq "00000000-0000-0000-0000-000000000000") {
            continue
        }
        if ($upper -eq "TO BE FILLED BY O.E.M.") {
            continue
        }
        return $candidate
    }

    return Normalize-Text ("{0}|{1}|{2}" -f $Hostname, $Manufacturer, $Model)
}

function Get-DiskInventory {
    $fixedDrives = @(Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop)
    $rows = @()
    $totalGiB = 0.0
    $freeGiB = 0.0
    foreach ($drive in $fixedDrives) {
        $sizeGiB = Convert-BytesToGiB -Bytes ([double]$drive.Size)
        $freeGiBRow = Convert-BytesToGiB -Bytes ([double]$drive.FreeSpace)
        $freePercent = if ([double]$drive.Size -gt 0) { [math]::Round((([double]$drive.FreeSpace / [double]$drive.Size) * 100), 2) } else { 0.0 }
        $totalGiB += $sizeGiB
        $freeGiB += $freeGiBRow
        $rows += [pscustomobject]@{
            drive        = [string]$drive.DeviceID
            volume_name  = [string]$drive.VolumeName
            filesystem   = [string]$drive.FileSystem
            size_gib     = $sizeGiB
            free_gib     = $freeGiBRow
            free_percent = $freePercent
        }
    }

    return [ordered]@{
        fixed_disks      = @($rows)
        fixed_disk_count = @($rows).Count
        total_gib        = [math]::Round($totalGiB, 2)
        free_gib         = [math]::Round($freeGiB, 2)
    }
}

function Get-GpuInventory {
    $rows = @()
    try {
        $controllers = @(Get-CimInstance Win32_VideoController -ErrorAction Stop)
        foreach ($controller in $controllers) {
            $name = Normalize-Text $controller.Name
            if (-not $name) {
                continue
            }
            $rows += [pscustomobject]@{
                name            = $name
                driver_version  = Normalize-Text $controller.DriverVersion
                adapter_ram_gib = Convert-BytesToGiB -Bytes ([double](Get-PropValue -Object $controller -Name "AdapterRAM" -Default 0))
            }
        }
    }
    catch {
        return [ordered]@{
            readable = $false
            gpus     = @()
        }
    }

    $uniqueRows = @($rows | Sort-Object name -Unique)
    return [ordered]@{
        readable = $true
        gpus     = @($uniqueRows)
    }
}

function Get-NetworkPosture {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)]$ContractPorts
    )

    $bindHost = "127.0.0.1"
    $portsCfg = Read-JsonSafe -Path (Join-Path $RepoRoot "config\ports.json") -Default $null
    $configuredBindHost = Normalize-Text (Get-PropValue -Object $portsCfg -Name "bind_host" -Default "")
    if ($configuredBindHost) {
        $bindHost = $configuredBindHost
    }

    $adapterRows = @()
    $readable = $true
    try {
        $ipEnabled = @(Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" -ErrorAction Stop)
        foreach ($adapter in $ipEnabled) {
            $ipAddresses = @()
            foreach ($ip in @($adapter.IPAddress)) {
                $normalized = Normalize-Text $ip
                if (-not $normalized) {
                    continue
                }
                if ($normalized -like "127.*" -or $normalized -like "::1*") {
                    continue
                }
                $ipAddresses += $normalized
            }

            $adapterRows += [pscustomobject]@{
                description  = Normalize-Text $adapter.Description
                dhcp_enabled = [bool]$adapter.DHCPEnabled
                ipv4_present = (@($ipAddresses | Where-Object { $_ -match '^\d+\.' }).Count -gt 0)
                ipv6_present = (@($ipAddresses | Where-Object { $_ -like "*:*" }).Count -gt 0)
            }
        }
    }
    catch {
        $readable = $false
    }

    return [ordered]@{
        readable                 = $readable
        bind_host                = $bindHost
        loopback_contract        = ($bindHost -eq "127.0.0.1")
        contract_ports           = $ContractPorts
        active_adapter_count     = @($adapterRows).Count
        adapter_descriptions     = @($adapterRows | Select-Object -ExpandProperty description -Unique)
        adapters                 = @($adapterRows)
        network_exposure_posture = if ($bindHost -eq "127.0.0.1") { "loopback_only" } else { "non_loopback_review_required" }
    }
}

function Invoke-HostGuardian {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $scriptPath = Join-Path $RepoRoot "tools\ops\Run_Host_Guardian.ps1"
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "Host guardian script is missing: $scriptPath"
    }

    $null = & powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $scriptPath -RootPath $RepoRoot
}

function Compare-EnvironmentDimension {
    param(
        [System.Collections.Generic.List[string]]$Target,
        [string]$Name,
        $CurrentValue,
        $PreviousValue,
        [double]$NumericDeltaThreshold = 0
    )

    if ($NumericDeltaThreshold -gt 0) {
        $currentParsed = 0.0
        $previousParsed = 0.0
        $currentText = Normalize-Text $CurrentValue
        $previousText = Normalize-Text $PreviousValue
        if ([double]::TryParse($currentText, [ref]$currentParsed) -and [double]::TryParse($previousText, [ref]$previousParsed)) {
            if ([math]::Abs($currentParsed - $previousParsed) -ge $NumericDeltaThreshold) {
                [void]$Target.Add($Name)
            }
            return
        }
    }

    $currentNormalized = Normalize-Text $CurrentValue
    $previousNormalized = Normalize-Text $PreviousValue
    if ($currentNormalized -ne $previousNormalized) {
        [void]$Target.Add($Name)
    }
}

function Get-DriftAssessment {
    param(
        $Registry,
        [Parameter(Mandatory = $true)][string]$EnvironmentId,
        $CurrentIdentity,
        $CurrentCapability
    )

    $knownEntries = @((Get-PropValue -Object $Registry -Name "environments" -Default @()))
    $priorEnvironmentId = Normalize-Text (Get-PropValue -Object $Registry -Name "current_environment_id" -Default "")
    $currentEntry = $knownEntries | Where-Object { (Normalize-Text (Get-PropValue -Object $_ -Name "environment_id" -Default "")) -eq $EnvironmentId } | Select-Object -First 1

    if (@($knownEntries).Count -eq 0) {
        return [ordered]@{
            prior_environment_id    = ""
            drift_level             = "new_environment"
            changed_dimensions      = @("registry_bootstrap")
            recommended_next_action = "Keep the runtime posture guarded on this first recorded environment and compare future runs against this baseline."
            migration_detected      = $false
            safe_posture_adjustment = "bootstrap_guarded_baseline"
            current_entry_exists    = $false
        }
    }

    if (-not $currentEntry) {
        $changed = @("environment_id", "host_identity")
        if ($priorEnvironmentId) {
            $changed += "migration_candidate"
        }
        return [ordered]@{
            prior_environment_id    = $priorEnvironmentId
            drift_level             = "new_environment"
            changed_dimensions      = @($changed | Sort-Object -Unique)
            recommended_next_action = "Treat this host as a newly observed environment; keep heavy jobs throttled until one clean validation pass is captured here."
            migration_detected      = [bool]([string]::IsNullOrWhiteSpace($priorEnvironmentId) -eq $false)
            safe_posture_adjustment = "guard_new_environment"
            current_entry_exists    = $false
        }
    }

    $previousIdentity = Get-PropValue -Object $currentEntry -Name "host_identity_summary" -Default $null
    $previousCapability = Get-PropValue -Object $currentEntry -Name "capability_summary" -Default $null
    $changes = [System.Collections.Generic.List[string]]::new()
    Compare-EnvironmentDimension -Target $changes -Name "hostname" -CurrentValue (Get-PropValue -Object $CurrentIdentity -Name "hostname" -Default "") -PreviousValue (Get-PropValue -Object $previousIdentity -Name "hostname" -Default "")
    Compare-EnvironmentDimension -Target $changes -Name "os_build" -CurrentValue (Get-PropValue -Object $CurrentIdentity -Name "os_build" -Default "") -PreviousValue (Get-PropValue -Object $previousIdentity -Name "os_build" -Default "")
    Compare-EnvironmentDimension -Target $changes -Name "host_classification" -CurrentValue (Get-PropValue -Object $CurrentIdentity -Name "host_classification" -Default "") -PreviousValue (Get-PropValue -Object $previousIdentity -Name "host_classification" -Default "")
    Compare-EnvironmentDimension -Target $changes -Name "logical_processors" -CurrentValue (Get-PropValue -Object $CurrentCapability -Name "logical_processors" -Default 0) -PreviousValue (Get-PropValue -Object $previousCapability -Name "logical_processors" -Default 0)
    Compare-EnvironmentDimension -Target $changes -Name "ram_total_gib" -CurrentValue (Get-PropValue -Object $CurrentCapability -Name "ram_total_gib" -Default 0) -PreviousValue (Get-PropValue -Object $previousCapability -Name "ram_total_gib" -Default 0) -NumericDeltaThreshold 1
    Compare-EnvironmentDimension -Target $changes -Name "gpu_count" -CurrentValue (Get-PropValue -Object $CurrentCapability -Name "gpu_count" -Default 0) -PreviousValue (Get-PropValue -Object $previousCapability -Name "gpu_count" -Default 0)
    Compare-EnvironmentDimension -Target $changes -Name "fixed_disk_count" -CurrentValue (Get-PropValue -Object $CurrentCapability -Name "fixed_disk_count" -Default 0) -PreviousValue (Get-PropValue -Object $previousCapability -Name "fixed_disk_count" -Default 0)

    $driftLevel = "no_material_change"
    $recommendedNextAction = "No action required."
    $safePostureAdjustment = "retain_current_posture"
    if ($changes.Count -gt 0) {
        $significant = @($changes | Where-Object { $_ -in @("host_classification", "logical_processors", "ram_total_gib", "gpu_count", "fixed_disk_count") })
        if ($significant.Count -gt 0) {
            $driftLevel = "significant_change"
            $recommendedNextAction = "Keep runtime posture guarded and revalidate the stack on this changed environment before expanding heavy work."
            $safePostureAdjustment = "raise_monitoring_and_limit_heavy_jobs"
        }
        else {
            $driftLevel = "minor_change"
            $recommendedNextAction = "Review the minor host drift and keep monitoring elevated until the next stable validation pass."
            $safePostureAdjustment = "elevate_monitoring_temporarily"
        }
    }

    if ($priorEnvironmentId -and $priorEnvironmentId -ne $EnvironmentId -and $driftLevel -eq "no_material_change") {
        $driftLevel = "significant_change"
        $recommendedNextAction = "This run moved back to a previously known environment; confirm the runtime posture and validation state before broad work."
        $safePostureAdjustment = "migration_watch"
        [void]$changes.Add("environment_switch")
    }

    return [ordered]@{
        prior_environment_id    = $priorEnvironmentId
        drift_level             = $driftLevel
        changed_dimensions      = @($changes | Sort-Object -Unique)
        recommended_next_action = $recommendedNextAction
        migration_detected      = [bool]($priorEnvironmentId -and $priorEnvironmentId -ne $EnvironmentId)
        safe_posture_adjustment = $safePostureAdjustment
        current_entry_exists    = $true
    }
}

function Get-RuntimePosture {
    param(
        [Parameter(Mandatory = $true)][string]$EnvironmentId,
        [Parameter(Mandatory = $true)][string]$HostClassification,
        $CapabilitySummary,
        $HostHealth,
        $ResourcePressure,
        $DriftAssessment
    )

    $logicalProcessors = [int](Get-PropValue -Object $CapabilitySummary -Name "logical_processors" -Default 0)
    $ramGiB = [double](Get-PropValue -Object $CapabilitySummary -Name "ram_total_gib" -Default 0)
    $runtimeHealthy = [bool](Get-PropValue -Object (Get-PropValue -Object $HostHealth -Name "mason_runtime_health" -Default $null) -Name "all_required_ports_listening" -Default $false)
    $throttleGuidance = Normalize-Text (Get-PropValue -Object $HostHealth -Name "throttle_guidance" -Default "")
    if (-not $throttleGuidance) {
        $throttleGuidance = Normalize-Text (Get-PropValue -Object $ResourcePressure -Name "pressure_level" -Default "normal")
    }

    $pressureLevel = if ($throttleGuidance) { $throttleGuidance } else { "normal" }
    $driftLevel = Normalize-Text (Get-PropValue -Object $DriftAssessment -Name "drift_level" -Default "no_material_change")
    $pendingReboot = [bool](Get-PropValue -Object (Get-PropValue -Object $HostHealth -Name "uptime" -Default $null) -Name "pending_reboot" -Default $false)
    $reportGrowth = Get-PropValue -Object (Get-PropValue -Object $HostHealth -Name "mason_runtime_health" -Default $null) -Name "report_growth" -Default $null
    $reportGrowthRisk = [bool](Get-PropValue -Object $reportGrowth -Name "risky" -Default $false)

    $capacityClass = "constrained"
    if ($logicalProcessors -ge 16 -and $ramGiB -ge 48) {
        $capacityClass = "high_capacity"
    }
    elseif ($logicalProcessors -ge 8 -and $ramGiB -ge 24) {
        $capacityClass = "balanced"
    }

    $learningPosture = "guarded"
    if (-not $runtimeHealthy) {
        $learningPosture = "stabilize_first"
    }
    elseif ($driftLevel -in @("new_environment", "significant_change")) {
        $learningPosture = "observe_then_expand"
    }
    elseif ($pressureLevel -in @("throttle_heavy_jobs", "protect_host")) {
        $learningPosture = "guarded"
    }
    elseif ($capacityClass -eq "high_capacity") {
        $learningPosture = "active_guarded"
    }

    $heavyJobsPosture = "lightweight_only"
    if (-not $runtimeHealthy -or $pressureLevel -eq "protect_host") {
        $heavyJobsPosture = "hold"
    }
    elseif ($pressureLevel -eq "throttle_heavy_jobs") {
        $heavyJobsPosture = "defer"
    }
    elseif ($driftLevel -in @("new_environment", "significant_change")) {
        $heavyJobsPosture = "limited_until_baselined"
    }
    elseif ($capacityClass -eq "high_capacity") {
        $heavyJobsPosture = "scheduled_allowed"
    }
    elseif ($capacityClass -eq "balanced") {
        $heavyJobsPosture = "lightweight_only"
    }
    else {
        $heavyJobsPosture = "minimal_only"
    }

    $monitoringPosture = "standard"
    if ($driftLevel -in @("new_environment", "significant_change")) {
        $monitoringPosture = "migration_watch"
    }
    elseif ($pendingReboot -or $pressureLevel -ne "normal") {
        $monitoringPosture = "elevated"
    }

    $cleanupPosture = "observe_only"
    if ($reportGrowthRisk) {
        $cleanupPosture = "recommend_trim_only"
    }

    $rationale = New-Object System.Collections.Generic.List[string]
    $rationale.Add(("Host classified as {0}; capacity profile is {1} ({2} logical processors, {3} GiB RAM)." -f $HostClassification, $capacityClass, $logicalProcessors, $ramGiB)) | Out-Null
    $rationale.Add(("Environment drift level is {0}." -f $driftLevel)) | Out-Null
    $rationale.Add(("Current throttle guidance is {0}." -f $pressureLevel)) | Out-Null
    if (-not $runtimeHealthy) {
        $rationale.Add("One or more required Mason services are not healthy, so posture stays conservative.") | Out-Null
    }
    if ($pendingReboot) {
        $rationale.Add("Windows reports a pending reboot, so monitoring remains elevated.") | Out-Null
    }
    if ($reportGrowthRisk) {
        $rationale.Add("Reports growth is elevated, so cleanup stays recommend-only rather than destructive.") | Out-Null
    }

    $recommendedNextAction = Normalize-Text (Get-PropValue -Object $DriftAssessment -Name "recommended_next_action" -Default "")
    if (-not $recommendedNextAction) {
        $recommendedNextAction = "No action required."
    }
    if (-not $runtimeHealthy) {
        $recommendedNextAction = "Restore required Mason runtime health before broadening runtime posture."
    }
    elseif ($pressureLevel -eq "protect_host") {
        $recommendedNextAction = "Protect the host and hold heavy jobs until CPU, memory, and disk pressure drop."
    }

    return [ordered]@{
        timestamp_utc           = (Get-Date).ToUniversalTime().ToString("o")
        environment_id          = $EnvironmentId
        host_classification     = $HostClassification
        learning_posture        = $learningPosture
        heavy_jobs_posture      = $heavyJobsPosture
        monitoring_posture      = $monitoringPosture
        cleanup_posture         = $cleanupPosture
        throttle_guidance       = $pressureLevel
        rationale               = @($rationale)
        recommended_next_action = $recommendedNextAction
        command_run             = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Environment_Adaptation.ps1"
    }
}

$repoRoot = Get-RepoRoot -OverrideRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$knowledgeDir = Join-Path $repoRoot "state\knowledge"
$environmentProfilePath = Join-Path $reportsDir "environment_profile_last.json"
$environmentDriftPath = Join-Path $reportsDir "environment_drift_last.json"
$runtimePosturePath = Join-Path $reportsDir "runtime_posture_last.json"
$environmentRegistryPath = Join-Path $knowledgeDir "environment_registry.json"
$hostHealthPath = Join-Path $reportsDir "host_health_last.json"
$resourcePressurePath = Join-Path $reportsDir "resource_pressure_last.json"
$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Environment_Adaptation.ps1"
$timestampUtc = (Get-Date).ToUniversalTime().ToString("o")

Invoke-HostGuardian -RepoRoot $repoRoot

$hostHealth = Read-JsonSafe -Path $hostHealthPath -Default $null
$resourcePressure = Read-JsonSafe -Path $resourcePressurePath -Default $null
if (-not $hostHealth -or -not $resourcePressure) {
    throw "Environment adaptation requires fresh host guardian artifacts."
}

$computerSystem = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
$computerSystemProduct = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction Stop
$bios = Get-CimInstance Win32_BIOS -ErrorAction Stop
$operatingSystem = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
$processors = @(Get-CimInstance Win32_Processor -ErrorAction Stop)

$hostname = Normalize-Text $env:COMPUTERNAME
$manufacturer = Normalize-Text $computerSystem.Manufacturer
$model = Normalize-Text $computerSystem.Model
$machineUuid = Normalize-Text $computerSystemProduct.UUID
$biosSerial = Normalize-Text $bios.SerialNumber
$osCaption = Normalize-Text $operatingSystem.Caption
$osVersion = Normalize-Text $operatingSystem.Version
$osBuild = Normalize-Text $operatingSystem.BuildNumber
$architecture = Normalize-Text $operatingSystem.OSArchitecture
$pcSystemType = [int](Get-PropValue -Object $computerSystem -Name "PCSystemType" -Default 0)
$hostClassification = Get-HostClassification -Manufacturer $manufacturer -Model $model -OsCaption $osCaption -PcSystemType $pcSystemType

$cpuNames = @($processors | ForEach-Object { Normalize-Text $_.Name } | Where-Object { $_ } | Sort-Object -Unique)
$cpuModel = if ($cpuNames.Count -gt 0) { $cpuNames[0] } else { "" }
$cpuCoreCount = [int](($processors | Measure-Object -Property NumberOfCores -Sum).Sum)
$logicalProcessors = [int](($processors | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum)
$ramTotalGiB = Convert-KiBToGiB -KiB ([double]$operatingSystem.TotalVisibleMemorySize)

$gpuInventory = Get-GpuInventory
$diskInventory = Get-DiskInventory
$contractPorts = Get-ContractPorts -RepoRoot $repoRoot
$networkPosture = Get-NetworkPosture -RepoRoot $repoRoot -ContractPorts $contractPorts

$identityToken = Get-PreferredIdentityToken -MachineUuid $machineUuid -BiosSerial $biosSerial -Manufacturer $manufacturer -Model $model -Hostname $hostname
$identityBasis = Normalize-Text ("{0}|{1}|{2}|{3}|{4}" -f $identityToken, $manufacturer, $model, $hostname, $architecture)
$environmentId = "env_{0}" -f (Get-Sha256Hex -Value $identityBasis).Substring(0, 12)

$hostIdentitySummary = [ordered]@{
    hostname            = $hostname
    manufacturer        = $manufacturer
    model               = $model
    machine_uuid        = $machineUuid
    bios_serial         = $biosSerial
    os_caption          = $osCaption
    os_version          = $osVersion
    os_build            = $osBuild
    architecture        = $architecture
    host_classification = $hostClassification
}

$capabilitySummary = [ordered]@{
    cpu_model            = $cpuModel
    cpu_core_count       = $cpuCoreCount
    logical_processors   = $logicalProcessors
    ram_total_gib        = $ramTotalGiB
    gpu_count            = @((Get-PropValue -Object $gpuInventory -Name "gpus" -Default @())).Count
    gpu_names            = @((Get-PropValue -Object $gpuInventory -Name "gpus" -Default @()) | ForEach-Object { Normalize-Text (Get-PropValue -Object $_ -Name "name" -Default "") } | Where-Object { $_ })
    fixed_disk_count     = [int](Get-PropValue -Object $diskInventory -Name "fixed_disk_count" -Default 0)
    total_fixed_disk_gib = [double](Get-PropValue -Object $diskInventory -Name "total_gib" -Default 0)
    free_fixed_disk_gib  = [double](Get-PropValue -Object $diskInventory -Name "free_gib" -Default 0)
}

$serviceAvailability = [ordered]@{
    contract_ports              = $contractPorts
    required_services_listening = [bool](Get-PropValue -Object (Get-PropValue -Object $hostHealth -Name "mason_runtime_health" -Default $null) -Name "all_required_ports_listening" -Default $false)
    listener_health             = @((Get-PropValue -Object (Get-PropValue -Object $hostHealth -Name "mason_runtime_health" -Default $null) -Name "listener_health" -Default @()))
}

$environmentProfile = [ordered]@{
    timestamp_utc          = $timestampUtc
    environment_id         = $environmentId
    host_classification    = $hostClassification
    host_identity_summary  = $hostIdentitySummary
    capability_summary     = $capabilitySummary
    os                     = [ordered]@{
        edition      = $osCaption
        version      = $osVersion
        build        = $osBuild
        architecture = $architecture
    }
    cpu                    = [ordered]@{
        model              = $cpuModel
        core_count         = $cpuCoreCount
        logical_processors = $logicalProcessors
    }
    memory                 = [ordered]@{
        total_gib = $ramTotalGiB
    }
    gpu                    = $gpuInventory
    disk                   = $diskInventory
    network_posture        = $networkPosture
    service_availability   = $serviceAvailability
    host_pressure_snapshot = [ordered]@{
        overall_status    = Normalize-Text (Get-PropValue -Object $hostHealth -Name "overall_status" -Default "")
        throttle_guidance = Normalize-Text (Get-PropValue -Object $hostHealth -Name "throttle_guidance" -Default "")
        pressure_level    = Normalize-Text (Get-PropValue -Object $resourcePressure -Name "pressure_level" -Default "")
    }
    command_run            = $commandRun
    repo_root              = $repoRoot
}

$registry = Read-JsonSafe -Path $environmentRegistryPath -Default ([ordered]@{
        generated_at_utc       = ""
        current_environment_id = ""
        prior_environment_id   = ""
        environments           = @()
    })

$driftAssessment = Get-DriftAssessment -Registry $registry -EnvironmentId $environmentId -CurrentIdentity $hostIdentitySummary -CurrentCapability $capabilitySummary
$runtimePosture = Get-RuntimePosture -EnvironmentId $environmentId -HostClassification $hostClassification -CapabilitySummary $capabilitySummary -HostHealth $hostHealth -ResourcePressure $resourcePressure -DriftAssessment $driftAssessment

$environmentDrift = [ordered]@{
    timestamp_utc           = $timestampUtc
    current_environment_id  = $environmentId
    prior_environment_id    = Normalize-Text (Get-PropValue -Object $driftAssessment -Name "prior_environment_id" -Default "")
    drift_level             = Normalize-Text (Get-PropValue -Object $driftAssessment -Name "drift_level" -Default "no_material_change")
    changed_dimensions      = @((Get-PropValue -Object $driftAssessment -Name "changed_dimensions" -Default @()))
    recommended_next_action = Normalize-Text (Get-PropValue -Object $driftAssessment -Name "recommended_next_action" -Default "No action required.")
    migration_detected      = [bool](Get-PropValue -Object $driftAssessment -Name "migration_detected" -Default $false)
    safe_posture_adjustment = Normalize-Text (Get-PropValue -Object $driftAssessment -Name "safe_posture_adjustment" -Default "retain_current_posture")
    command_run             = $commandRun
    repo_root               = $repoRoot
}

$environments = New-Object System.Collections.Generic.List[object]
$priorCurrentId = Normalize-Text (Get-PropValue -Object $registry -Name "current_environment_id" -Default "")
$currentEntryFound = $false
foreach ($entry in @((Get-PropValue -Object $registry -Name "environments" -Default @()))) {
    $entryEnvironmentId = Normalize-Text (Get-PropValue -Object $entry -Name "environment_id" -Default "")
    $notes = @((Get-PropValue -Object $entry -Name "notes" -Default @()))
    $migrationEvents = New-Object System.Collections.Generic.List[object]
    foreach ($event in @((Get-PropValue -Object $entry -Name "migration_events" -Default @()))) {
        $migrationEvents.Add($event) | Out-Null
    }

    if ($entryEnvironmentId -eq $environmentId) {
        $currentEntryFound = $true
        if ([bool](Get-PropValue -Object $environmentDrift -Name "migration_detected" -Default $false) -or (Normalize-Text (Get-PropValue -Object $environmentDrift -Name "drift_level" -Default "")) -in @("new_environment", "significant_change")) {
            $migrationEvents.Add([ordered]@{
                    observed_at_utc   = $timestampUtc
                    event_type        = "environment_observed"
                    prior_environment = Normalize-Text (Get-PropValue -Object $environmentDrift -Name "prior_environment_id" -Default "")
                    drift_level       = Normalize-Text (Get-PropValue -Object $environmentDrift -Name "drift_level" -Default "")
                    note              = Normalize-Text (Get-PropValue -Object $environmentDrift -Name "recommended_next_action" -Default "")
                }) | Out-Null
        }

        $environments.Add([ordered]@{
                environment_id        = $environmentId
                first_seen_utc        = Normalize-Text (Get-PropValue -Object $entry -Name "first_seen_utc" -Default $timestampUtc)
                last_seen_utc         = $timestampUtc
                host_identity_summary = $hostIdentitySummary
                capability_summary    = $capabilitySummary
                current_status        = "active"
                notes                 = @($notes)
                migration_events      = @($migrationEvents.ToArray())
            }) | Out-Null
        continue
    }

    $status = Normalize-Text (Get-PropValue -Object $entry -Name "current_status" -Default "known")
    if ($entryEnvironmentId -eq $priorCurrentId) {
        $status = "known"
    }

    $environments.Add([ordered]@{
            environment_id        = $entryEnvironmentId
            first_seen_utc        = Normalize-Text (Get-PropValue -Object $entry -Name "first_seen_utc" -Default "")
            last_seen_utc         = Normalize-Text (Get-PropValue -Object $entry -Name "last_seen_utc" -Default "")
            host_identity_summary = Get-PropValue -Object $entry -Name "host_identity_summary" -Default $null
            capability_summary    = Get-PropValue -Object $entry -Name "capability_summary" -Default $null
            current_status        = if ($status) { $status } else { "known" }
            notes                 = @($notes)
            migration_events      = @($migrationEvents.ToArray())
        }) | Out-Null
}

if (-not $currentEntryFound) {
    $migrationEvents = @()
    if ([bool](Get-PropValue -Object $environmentDrift -Name "migration_detected" -Default $false) -or (Normalize-Text (Get-PropValue -Object $environmentDrift -Name "drift_level" -Default "")) -eq "new_environment") {
        $migrationEvents += [ordered]@{
            observed_at_utc   = $timestampUtc
            event_type        = "environment_discovered"
            prior_environment = Normalize-Text (Get-PropValue -Object $environmentDrift -Name "prior_environment_id" -Default "")
            drift_level       = Normalize-Text (Get-PropValue -Object $environmentDrift -Name "drift_level" -Default "")
            note              = Normalize-Text (Get-PropValue -Object $environmentDrift -Name "recommended_next_action" -Default "")
        }
    }

    $environments.Add([ordered]@{
            environment_id        = $environmentId
            first_seen_utc        = $timestampUtc
            last_seen_utc         = $timestampUtc
            host_identity_summary = $hostIdentitySummary
            capability_summary    = $capabilitySummary
            current_status        = "active"
            notes                 = @("Discovered by Run_Environment_Adaptation.ps1.")
            migration_events      = @($migrationEvents)
        }) | Out-Null
}

$environmentRegistry = [ordered]@{
    generated_at_utc       = $timestampUtc
    current_environment_id = $environmentId
    prior_environment_id   = $priorCurrentId
    last_drift_level       = Normalize-Text (Get-PropValue -Object $environmentDrift -Name "drift_level" -Default "")
    environments           = @($environments.ToArray())
}

Write-JsonFile -Path $environmentProfilePath -Object $environmentProfile -Depth 20
Write-JsonFile -Path $environmentDriftPath -Object $environmentDrift -Depth 20
Write-JsonFile -Path $runtimePosturePath -Object $runtimePosture -Depth 20
Write-JsonFile -Path $environmentRegistryPath -Object $environmentRegistry -Depth 20

$summary = [ordered]@{
    timestamp_utc             = $timestampUtc
    environment_profile_path  = $environmentProfilePath
    environment_drift_path    = $environmentDriftPath
    runtime_posture_path      = $runtimePosturePath
    environment_registry_path = $environmentRegistryPath
    environment_id            = $environmentId
    host_classification       = $hostClassification
    drift_level               = Normalize-Text (Get-PropValue -Object $environmentDrift -Name "drift_level" -Default "")
    throttle_guidance         = Normalize-Text (Get-PropValue -Object $runtimePosture -Name "throttle_guidance" -Default "")
    recommended_next_action   = Normalize-Text (Get-PropValue -Object $runtimePosture -Name "recommended_next_action" -Default "")
}

$summary | ConvertTo-Json -Depth 12
