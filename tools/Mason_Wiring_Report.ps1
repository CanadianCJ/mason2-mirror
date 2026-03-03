[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$OutputPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-JsonSafe {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if (-not $raw.Trim()) {
            return $null
        }
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $null
    }
}

function To-RelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$Base,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $baseFull = [System.IO.Path]::GetFullPath($Base)
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if ($fullPath.StartsWith($baseFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $fullPath.Substring($baseFull.Length).TrimStart('\', '/').Replace('/', '\')
    }
    return $fullPath
}

function Get-ContractPort {
    param(
        [Parameter(Mandatory = $true)]$PortsConfig,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][int]$Default
    )

    if ($PortsConfig -and
        ($PortsConfig.PSObject.Properties.Name -contains "ports") -and
        $PortsConfig.ports -and
        ($PortsConfig.ports.PSObject.Properties.Name -contains $Key)) {
        $tmp = 0
        if ([int]::TryParse([string]$PortsConfig.ports.$Key, [ref]$tmp) -and $tmp -gt 0 -and $tmp -le 65535) {
            return [int]$tmp
        }
    }
    return [int]$Default
}

function Get-ReadinessEndpoints {
    param(
        [Parameter(Mandatory = $true)]$PortsConfig,
        [Parameter(Mandatory = $true)]$ServicesConfig
    )

    $bindHost = "127.0.0.1"
    if ($PortsConfig -and ($PortsConfig.PSObject.Properties.Name -contains "bind_host") -and $PortsConfig.bind_host) {
        $bindHost = [string]$PortsConfig.bind_host
    }

    $masonApiPort = Get-ContractPort -PortsConfig $PortsConfig -Key "mason_api" -Default 8383
    $seedApiPort = Get-ContractPort -PortsConfig $PortsConfig -Key "seed_api" -Default 8109
    $bridgePort = Get-ContractPort -PortsConfig $PortsConfig -Key "bridge" -Default 8484
    $athenaPort = Get-ContractPort -PortsConfig $PortsConfig -Key "athena" -Default 8000
    $onyxPort = Get-ContractPort -PortsConfig $PortsConfig -Key "onyx" -Default 5353

    $eps = @(
        [pscustomobject]@{ name = "mason_api_health"; url = "http://$bindHost`:$masonApiPort/health"; required = $false; source = "config/ports.json" }
        [pscustomobject]@{ name = "seed_api_health"; url = "http://$bindHost`:$seedApiPort/health"; required = $false; source = "config/ports.json" }
        [pscustomobject]@{ name = "bridge_health"; url = "http://$bindHost`:$bridgePort/health"; required = $true; source = "config/ports.json" }
        [pscustomobject]@{ name = "athena_health"; url = "http://$bindHost`:$athenaPort/api/health"; required = $true; source = "config/ports.json" }
        [pscustomobject]@{ name = "onyx_main_dart_js"; url = "http://$bindHost`:$onyxPort/main.dart.js"; required = $true; source = "config/ports.json" }
    )

    if ($ServicesConfig -and ($ServicesConfig.PSObject.Properties.Name -contains "readiness")) {
        foreach ($entry in @($ServicesConfig.readiness)) {
            if (-not $entry) { continue }
            if (-not ($entry.PSObject.Properties.Name -contains "url")) { continue }
            $url = [string]$entry.url
            if (-not $url.Trim()) { continue }
            $name = if ($entry.name) { [string]$entry.name } else { "configured_endpoint" }
            $already = @($eps | Where-Object { $_.name -eq $name -and $_.url -eq $url }).Count -gt 0
            if ($already) { continue }
            $eps += [pscustomobject]@{
                name     = $name
                url      = $url
                required = if ($entry.PSObject.Properties.Name -contains "required") { [bool]$entry.required } else { $true }
                source   = "config/services.json"
            }
        }
    }

    return @($eps)
}

function Get-PortLiteralsFromText {
    param([string]$Text)
    if (-not $Text) { return @() }

    $ports = New-Object System.Collections.Generic.List[int]
    $matches = [regex]::Matches($Text, "\b(5353|7000|8000|8109|8383|8484)\b")
    foreach ($m in $matches) {
        $portVal = 0
        if ([int]::TryParse([string]$m.Value, [ref]$portVal)) {
            if (-not $ports.Contains($portVal)) {
                $ports.Add($portVal)
            }
        }
    }
    return @($ports | Sort-Object)
}

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $RootPath) {
    $RootPath = Split-Path -Parent $scriptRoot
}
$RootPath = [System.IO.Path]::GetFullPath($RootPath)

if (-not $OutputPath) {
    $OutputPath = Join-Path $RootPath "reports\mason2_wiring_report.json"
}

$portsPath = Join-Path $RootPath "config\ports.json"
$servicesPath = Join-Path $RootPath "config\windows_services.json"
if (-not (Test-Path -LiteralPath $servicesPath)) {
    $servicesPath = Join-Path $RootPath "config\services.json"
}
$portsConfig = Read-JsonSafe -Path $portsPath
$servicesConfig = Read-JsonSafe -Path $servicesPath

$entrypointPaths = @(
    "Start_Mason2.ps1",
    "Start-Athena.ps1",
    "tools\Start_Bridge.ps1",
    "tools\launch\Start_Mason_FullStack.ps1",
    "tools\launch\Start_Mason_CoreOnly.ps1",
    "tools\launch\Create_Mason_Shortcuts.ps1",
    "Component - Onyx App\onyx_business_manager\Start-Onyx5353.ps1",
    "tools\Mason_Start_Core_NoApps.ps1",
    "tools\Mason_Start_All.ps1"
)

$entrypoints = @()
foreach ($relPath in $entrypointPaths) {
    $fullPath = Join-Path $RootPath $relPath
    $exists = Test-Path -LiteralPath $fullPath
    $content = ""
    $lastWriteUtc = $null
    if ($exists) {
        try {
            $content = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
            $item = Get-Item -LiteralPath $fullPath -ErrorAction Stop
            $lastWriteUtc = $item.LastWriteTimeUtc.ToString("o")
        }
        catch {
            $content = ""
        }
    }

    $entrypoints += [pscustomobject]@{
        path                       = $relPath
        exists                     = [bool]$exists
        last_write_utc             = $lastWriteUtc
        delegates_to_start_mason2  = ($content -match "Start_Mason2\.ps1")
        reads_ports_contract       = ($content -match "ports\.json" -or $content -match "MASON_(?:BIND_HOST|API_PORT|SEED_PORT|BRIDGE_PORT|ATHENA_PORT|ONYX_PORT)")
        uses_get_readiness         = ($content -match "Invoke-WebRequest" -or $content -match "Wait-ForEndpoints" -or $content -match "main\.dart\.js")
        port_literals              = @(Get-PortLiteralsFromText -Text $content)
    }
}

$bindHost = if ($portsConfig -and $portsConfig.bind_host) { [string]$portsConfig.bind_host } else { "127.0.0.1" }
$contractMasonApiPort = if ($portsConfig) { Get-ContractPort -PortsConfig $portsConfig -Key "mason_api" -Default 8383 } else { 8383 }
$contractSeedApiPort = if ($portsConfig) { Get-ContractPort -PortsConfig $portsConfig -Key "seed_api" -Default 8109 } else { 8109 }
$contractBridgePort = if ($portsConfig) { Get-ContractPort -PortsConfig $portsConfig -Key "bridge" -Default 8484 } else { 8484 }
$contractAthenaPort = if ($portsConfig) { Get-ContractPort -PortsConfig $portsConfig -Key "athena" -Default 8000 } else { 8000 }
$contractOnyxPort = if ($portsConfig) { Get-ContractPort -PortsConfig $portsConfig -Key "onyx" -Default 5353 } else { 5353 }
$portsContract = [ordered]@{
    bind_host = $bindHost
    ports = [ordered]@{
        mason_api = $contractMasonApiPort
        seed_api  = $contractSeedApiPort
        bridge    = $contractBridgePort
        athena    = $contractAthenaPort
        onyx      = $contractOnyxPort
    }
    sidecar7000_enabled = $false
}

$readinessEndpoints = if ($portsConfig) {
    @(Get-ReadinessEndpoints -PortsConfig $portsConfig -ServicesConfig $servicesConfig)
}
else {
    @()
}

$scriptComponentWiring = @(
    [pscustomobject]@{
        script = "Start_Mason2.ps1"
        starts_components = @("watcher", "mason_core", "bridge", "athena", "onyx", "tasks_to_approvals_loop")
        readiness_endpoints = @("mason_api_health", "seed_api_health", "bridge_health", "athena_health", "onyx_main_dart_js")
    }
    [pscustomobject]@{
        script = "tools\launch\Start_Mason_FullStack.ps1"
        starts_components = @("delegates:Start_Mason2.ps1", "profile:FullStack", "launcher_logging")
        readiness_endpoints = @("delegates:Start_Mason2.ps1")
    }
    [pscustomobject]@{
        script = "tools\launch\Start_Mason_CoreOnly.ps1"
        starts_components = @("delegates:Start_Mason2.ps1", "profile:CoreOnly", "launcher_logging")
        readiness_endpoints = @("delegates:Start_Mason2.ps1")
    }
)

$driftFindings = @()

if (-not $portsConfig) {
    $driftFindings += [pscustomobject]@{
        id       = "ports_contract_missing"
        severity = "error"
        pass     = $false
        detail   = "config/ports.json is missing or invalid."
        evidence = @("config/ports.json")
    }
}
else {
    $bindHostPass = ($bindHost -eq "127.0.0.1")
    $driftFindings += [pscustomobject]@{
        id       = "bind_host_loopback"
        severity = if ($bindHostPass) { "info" } else { "error" }
        pass     = [bool]$bindHostPass
        detail   = if ($bindHostPass) { "bind_host is loopback." } else { "bind_host must be 127.0.0.1." }
        evidence = @("config/ports.json")
    }

    $portValueMap = @{}
    foreach ($kv in @($portsContract.ports.GetEnumerator())) {
        $portText = [string]$kv.Value
        if (-not $portValueMap.ContainsKey($portText)) {
            $portValueMap[$portText] = @()
        }
        $portValueMap[$portText] += [string]$kv.Key
    }
    foreach ($portText in $portValueMap.Keys) {
        $keys = @($portValueMap[$portText])
        if ($keys.Count -gt 1) {
            $driftFindings += [pscustomobject]@{
                id       = "conflicting_ports_$portText"
                severity = "error"
                pass     = $false
                detail   = ("Multiple components share port {0}: {1}" -f $portText, ($keys -join ", "))
                evidence = @("config/ports.json")
            }
        }
    }

    $sidecarPresent = $false
    foreach ($kv in @($portsContract.ports.GetEnumerator())) {
        if ([int]$kv.Value -eq 7000) {
            $sidecarPresent = $true
            break
        }
    }
    $driftFindings += [pscustomobject]@{
        id       = "sidecar7000_off"
        severity = if ($sidecarPresent) { "error" } else { "info" }
        pass     = -not $sidecarPresent
        detail   = if ($sidecarPresent) { "Port 7000 is present in ports contract." } else { "Sidecar7000 is absent from ports contract." }
        evidence = @("config/ports.json")
    }
}

$wrapperDelegates = @($entrypoints | Where-Object { $_.path -ne "Start_Mason2.ps1" -and $_.delegates_to_start_mason2 })
$driftFindings += [pscustomobject]@{
    id       = "duplicate_launch_wrappers"
    severity = if ($wrapperDelegates.Count -gt 1) { "warn" } else { "info" }
    pass     = $true
    detail   = ("{0} wrapper entrypoint(s) delegate to Start_Mason2.ps1: {1}" -f $wrapperDelegates.Count, (($wrapperDelegates | ForEach-Object { $_.path }) -join ", "))
    evidence = @($wrapperDelegates | ForEach-Object { $_.path })
}

$missingEntrypoints = @($entrypoints | Where-Object { -not $_.exists } | ForEach-Object { $_.path })
if ($missingEntrypoints.Count -gt 0) {
    $driftFindings += [pscustomobject]@{
        id       = "missing_entrypoints"
        severity = "error"
        pass     = $false
        detail   = ("Missing expected entrypoint(s): {0}" -f ($missingEntrypoints -join ", "))
        evidence = $missingEntrypoints
    }
}

$onyxReadinessPresent = @($readinessEndpoints | Where-Object { $_.url -match "/main\.dart\.js$" }).Count -gt 0
$driftFindings += [pscustomobject]@{
    id       = "onyx_main_dart_readiness"
    severity = if ($onyxReadinessPresent) { "info" } else { "error" }
    pass     = [bool]$onyxReadinessPresent
    detail   = if ($onyxReadinessPresent) { "Onyx readiness gate includes GET /main.dart.js." } else { "Onyx readiness gate missing GET /main.dart.js." }
    evidence = @("Start_Mason2.ps1", "config/services.json", "config/ports.json")
}

$failCount = @($driftFindings | Where-Object { -not $_.pass -and $_.severity -eq "error" }).Count
$overall = if ($failCount -eq 0) { "PASS" } else { "FAIL" }

$outDir = Split-Path -Parent $OutputPath
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$report = [ordered]@{}
$report["generated_at_utc"] = (Get-Date).ToUniversalTime().ToString("o")
$report["root_path"] = $RootPath
$report["overall_result"] = $overall
$report["ports_contract"] = $portsContract
$report["detected_entrypoints"] = @($entrypoints)
$report["script_component_wiring"] = $scriptComponentWiring
$report["readiness_endpoints"] = $readinessEndpoints
$report["drift_findings"] = @($driftFindings)

$report | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host ("Wiring report written: {0}" -f $OutputPath)

if ($overall -eq "PASS") { exit 0 }
exit 2
