[CmdletBinding()]
param(
    [string]$RootPath = ""
)

$ErrorActionPreference = "Stop"

function Write-DoctorLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Mason_Doctor] [$Level] $Message"
}

function Read-JsonStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $status = [ordered]@{
        path   = $Path
        exists = (Test-Path -LiteralPath $Path)
        valid  = $false
        error  = $null
    }

    if (-not $status.exists) {
        $status.error = "missing"
        return [pscustomobject]$status
    }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if (-not $raw.Trim()) {
            $status.error = "empty"
            return [pscustomobject]$status
        }
        $null = $raw | ConvertFrom-Json -ErrorAction Stop
        $status.valid = $true
    }
    catch {
        $status.error = $_.Exception.Message
    }

    return [pscustomobject]$status
}

function To-Array {
    param($Value)

    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return $Value }
    return @($Value)
}

function Test-ProcessAlive {
    param([int]$ProcessId)
    if ($ProcessId -le 0) { return $false }
    return [bool](Get-Process -Id $ProcessId -ErrorAction SilentlyContinue)
}

function Find-ProcessByFragment {
    param([string]$Fragment)

    if ([string]::IsNullOrWhiteSpace($Fragment)) {
        return @()
    }

    try {
        $rows = Get-CimInstance Win32_Process -ErrorAction Stop | Where-Object {
            ($_.Name -ieq "powershell.exe" -or $_.Name -ieq "pwsh.exe") -and
            $_.CommandLine -and
            $_.CommandLine.IndexOf($Fragment, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
        }
        return @($rows)
    }
    catch {
        return @()
    }
}

function Get-PortListeners {
    param([int]$Port)

    $out = @()

    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        try {
            $rows = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
            foreach ($row in @($rows)) {
                $out += [pscustomobject]@{
                    local_address = [string]$row.LocalAddress
                    local_port    = [int]$row.LocalPort
                    owning_pid    = [int]$row.OwningProcess
                }
            }
            return $out
        }
        catch {
            # fall through
        }
    }

    try {
        $netstat = netstat -ano -p tcp
        foreach ($line in $netstat) {
            if ($line -notmatch "LISTENING") { continue }
            if ($line -notmatch "^\s*TCP\s+(\S+):(\d+)\s+\S+\s+LISTENING\s+(\d+)") { continue }

            $addr = $Matches[1]
            $linePort = [int]$Matches[2]
            $ownerPid = [int]$Matches[3]
            if ($linePort -ne $Port) { continue }

            $out += [pscustomobject]@{
                local_address = $addr
                local_port    = $linePort
                owning_pid    = $ownerPid
            }
        }
    }
    catch {
        return @()
    }

    return $out
}

function Test-LoopbackAddress {
    param([string]$Address)

    if ([string]::IsNullOrWhiteSpace($Address)) {
        return $false
    }

    $trimmed = $Address.Trim()
    if ($trimmed -in @("127.0.0.1", "::1", "localhost")) {
        return $true
    }

    if ($trimmed -match "^127\.") {
        return $true
    }

    return $false
}

function Get-PortDefinitions {
    param($PortsConfig)

    $defs = @()
    if (-not $PortsConfig) {
        return $defs
    }

    if (-not ($PortsConfig.PSObject.Properties.Name -contains "ports") -or -not $PortsConfig.ports) {
        return $defs
    }

    $componentMap = @{
        "mason_api" = "mason"
        "seed_api"  = "mason"
        "bridge"    = "bridge"
        "athena"    = "athena"
        "onyx"      = "onyx"
    }
    $expectedPidMap = @{
        "mason_api" = "mason_api_pid"
        "seed_api"  = "seed_api_pid"
        "bridge"    = "bridge_pid"
        "athena"    = "athena_pid"
        "onyx"      = "onyx_pid"
    }

    foreach ($prop in @($PortsConfig.ports.PSObject.Properties)) {
        if (-not $prop) { continue }
        $name = [string]$prop.Name
        $defs += [pscustomobject]@{
            name             = $name
            port             = $prop.Value
            component_id     = if ($componentMap.ContainsKey($name)) { $componentMap[$name] } else { "mason" }
            expected_pid_key = if ($expectedPidMap.ContainsKey($name)) { $expectedPidMap[$name] } else { $null }
        }
    }

    return $defs
}

function Resolve-ExpectedPortPid {
    param(
        $PortDef,
        $StackState
    )

    if (-not $PortDef) { return $null }
    $stack = $StackState

    if ($PortDef.PSObject.Properties.Name -contains "expected_pid" -and $PortDef.expected_pid) {
        $pidVal = 0
        if ([int]::TryParse([string]$PortDef.expected_pid, [ref]$pidVal)) {
            return $pidVal
        }
    }

    if ($PortDef.PSObject.Properties.Name -contains "expected_pid_key" -and $PortDef.expected_pid_key) {
        $key = [string]$PortDef.expected_pid_key
        if ($stack -and ($stack.PSObject.Properties.Name -contains $key)) {
            $pidVal = 0
            if ([int]::TryParse([string]$stack.$key, [ref]$pidVal)) {
                return $pidVal
            }
        }
    }

    if ($stack -and ($stack.PSObject.Properties.Name -contains "current_live_pids") -and $PortDef.PSObject.Properties.Name -contains "name") {
        $currentLive = $stack.current_live_pids
        if ($currentLive) {
            $liveKey = [string]$PortDef.name
            $liveValue = $null
            if ($currentLive -is [System.Collections.IDictionary]) {
                if ($currentLive.Contains($liveKey)) {
                    $liveValue = $currentLive[$liveKey]
                }
            }
            elseif ($currentLive.PSObject.Properties.Name -contains $liveKey) {
                $liveValue = $currentLive.$liveKey
            }

            $livePid = 0
            if ([int]::TryParse([string]$liveValue, [ref]$livePid) -and $livePid -gt 0) {
                return $livePid
            }
        }
    }

    if ($PortDef.PSObject.Properties.Name -contains "component_id" -and $PortDef.component_id -and $stack) {
        $component = ([string]$PortDef.component_id).ToLowerInvariant()
        switch ($component) {
            "mason" {
                foreach ($k in @("mason_core_pid", "core_launcher_pid")) {
                    if ($stack.PSObject.Properties.Name -contains $k) {
                        $pidVal = 0
                        if ([int]::TryParse([string]$stack.$k, [ref]$pidVal)) { return $pidVal }
                    }
                }
            }
            "athena" {
                if ($stack.PSObject.Properties.Name -contains "athena_pid") {
                    $pidVal = 0
                    if ([int]::TryParse([string]$stack.athena_pid, [ref]$pidVal)) { return $pidVal }
                }
            }
            "onyx" {
                if ($stack.PSObject.Properties.Name -contains "onyx_pid") {
                    $pidVal = 0
                    if ([int]::TryParse([string]$stack.onyx_pid, [ref]$pidVal)) { return $pidVal }
                }
            }
            "watcher" {
                if ($stack.PSObject.Properties.Name -contains "watcher_pid") {
                    $pidVal = 0
                    if ([int]::TryParse([string]$stack.watcher_pid, [ref]$pidVal)) { return $pidVal }
                }
            }
        }
    }

    return $null
}

function Get-WindowsServiceFindings {
    param($WindowsServicesConfig)

    $findings = @()
    if (-not $WindowsServicesConfig) {
        return @(
            [pscustomobject]@{
                name     = "windows_service_expectations"
                pass     = $false
                optional = $false
                detail   = "config/windows_services.json is missing or invalid."
                expected = $null
                actual   = $null
            }
        )
    }

    $expectList = @()
    if ($WindowsServicesConfig.PSObject.Properties.Name -contains "expect") {
        $expectList = @(To-Array $WindowsServicesConfig.expect)
    }

    if ($expectList.Count -eq 0) {
        return @(
            [pscustomobject]@{
                name     = "windows_service_expectations"
                pass     = $false
                optional = $false
                detail   = "No service expectations found in config/windows_services.json."
                expected = $null
                actual   = $null
            }
        )
    }

    foreach ($entry in $expectList) {
        if (-not $entry) { continue }
        $name = ""
        $expected = ""
        $optional = $false
        if ($entry.PSObject.Properties.Name -contains "name") { $name = [string]$entry.name }
        if ($entry.PSObject.Properties.Name -contains "status") { $expected = [string]$entry.status }
        if ($entry.PSObject.Properties.Name -contains "optional") { $optional = [bool]$entry.optional }

        if (-not $name.Trim()) {
            $findings += [pscustomobject]@{
                name     = "invalid_service_entry"
                pass     = $false
                optional = $optional
                detail   = "Service expectation entry is missing 'name'."
                expected = $expected
                actual   = $null
            }
            continue
        }

        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if (-not $svc) {
            $findings += [pscustomobject]@{
                name     = $name
                pass     = [bool]$optional
                optional = [bool]$optional
                detail   = if ($optional) { "Optional service not found." } else { "Service not found." }
                expected = $expected
                actual   = $null
            }
            continue
        }

        $actual = [string]$svc.Status
        $pass = $true
        if ($expected.Trim()) {
            $pass = ($actual -eq $expected)
        }

        $findings += [pscustomobject]@{
            name     = $name
            pass     = [bool]$pass
            optional = [bool]$optional
            detail   = if ($pass) { "Service status matches expectation." } else { "Service status differs from expectation." }
            expected = $expected
            actual   = $actual
        }
    }

    return $findings
}

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $RootPath) {
    $RootPath = Split-Path -Parent $scriptRoot
}

$configDir = Join-Path $RootPath "config"
$stateDir = Join-Path $RootPath "state\knowledge"
$reportsDir = Join-Path $RootPath "reports"
$toolsDir = Join-Path $RootPath "tools"

New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null

$reportPath = Join-Path $reportsDir "mason2_doctor_report.json"

$servicesPath = Join-Path $configDir "services.json"
$windowsServicesPath = Join-Path $configDir "windows_services.json"
$portsPath = Join-Path $configDir "ports.json"
$componentRegistryPath = Join-Path $configDir "component_registry.json"
$riskPolicyPath = Join-Path $configDir "risk_policy.json"
$backupPolicyPath = Join-Path $configDir "backup_policy.json"
$secretsPath = Join-Path $configDir "secrets_mason.json"

$servicesConfigStatus = Read-JsonStatus -Path $servicesPath
$windowsServicesStatus = Read-JsonStatus -Path $windowsServicesPath
$portsConfigStatus = Read-JsonStatus -Path $portsPath
$componentRegistryStatus = Read-JsonStatus -Path $componentRegistryPath
$riskPolicyStatus = Read-JsonStatus -Path $riskPolicyPath
$backupPolicyStatus = Read-JsonStatus -Path $backupPolicyPath
$secretsStatus = Read-JsonStatus -Path $secretsPath

$configChecks = @(
    $servicesConfigStatus
    $windowsServicesStatus
    $portsConfigStatus
    $componentRegistryStatus
    $riskPolicyStatus
    $backupPolicyStatus
    $secretsStatus
)

$approvalsChecks = @(
    Read-JsonStatus -Path (Join-Path $stateDir "pending_patch_runs.json")
    Read-JsonStatus -Path (Join-Path $stateDir "trust_index.json")
)

$servicesConfig = $null
if ($servicesConfigStatus.valid) {
    $servicesConfig = Get-Content -LiteralPath $servicesConfigStatus.path -Raw -Encoding UTF8 | ConvertFrom-Json
}
$windowsServicesConfig = $null
if ($windowsServicesStatus.valid) {
    $windowsServicesConfig = Get-Content -LiteralPath $windowsServicesStatus.path -Raw -Encoding UTF8 | ConvertFrom-Json
}
$portsConfig = $null
if ($portsConfigStatus.valid) {
    $portsConfig = Get-Content -LiteralPath $portsConfigStatus.path -Raw -Encoding UTF8 | ConvertFrom-Json
}

$stackPidPath = Join-Path $stateDir "stack_pids.json"
$stackState = $null
$stackStateStatus = Read-JsonStatus -Path $stackPidPath
if ($stackStateStatus.valid) {
    $stackState = Get-Content -LiteralPath $stackPidPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

$knownPidKeys = @(
    "watcher_pid", "core_launcher_pid", "mason_core_pid", "mason_api_pid",
    "seed_api_pid", "bridge_pid", "bridge_launcher_pid", "athena_pid",
    "athena_launcher_pid", "onyx_pid", "onyx_launcher_pid",
    "fullstack_launcher_pid", "tasks_to_approvals_loop_pid"
)

$runningPidDetails = @()
if ($stackState) {
    foreach ($k in $knownPidKeys) {
        if ($stackState.PSObject.Properties.Name -contains $k) {
            $pidVal = 0
            if ([int]::TryParse([string]$stackState.$k, [ref]$pidVal)) {
                $runningPidDetails += [pscustomobject]@{
                    key      = $k
                    pid      = $pidVal
                    is_alive = (Test-ProcessAlive -ProcessId $pidVal)
                }
            }
        }
    }
}

$watcherByCmd = @(Find-ProcessByFragment -Fragment "Mason_Executor_Watcher.ps1")
$coreByCmd = @(
    Find-ProcessByFragment -Fragment "Mason_Start_Core_NoApps.ps1";
    Find-ProcessByFragment -Fragment "Mason_AutoLoop.ps1";
    Find-ProcessByFragment -Fragment "Mason_Start_All.ps1";
    Find-ProcessByFragment -Fragment "Start_Mason_Onyx_Stack.Legacy.ps1"
) | Where-Object { $_ } | Select-Object -Unique ProcessId, Name, CommandLine

$stackRunning = (@($runningPidDetails | Where-Object { $_.is_alive }).Count -gt 0) -or ($watcherByCmd.Count -gt 0) -or ($coreByCmd.Count -gt 0)
$watcherRunning = ($watcherByCmd.Count -gt 0) -or (@($runningPidDetails | Where-Object { $_.key -eq "watcher_pid" -and $_.is_alive }).Count -gt 0)
$coreRunning = ($coreByCmd.Count -gt 0) -or (@($runningPidDetails | Where-Object { $_.key -eq "core_launcher_pid" -and $_.is_alive }).Count -gt 0)

$runtimeChecks = @(
    [pscustomobject]@{
        name   = "stack_running"
        pass   = $stackRunning
        detail = if ($stackRunning) { "Stack appears active." } else { "No active stack processes detected." }
    },
    [pscustomobject]@{
        name   = "watcher_running_when_stack_active"
        pass   = if ($stackRunning) { $watcherRunning } else { $true }
        detail = if ($watcherRunning) { "Watcher is running." } elseif ($stackRunning) { "Stack is active but watcher is not running." } else { "Stack inactive; watcher check skipped." }
    },
    [pscustomobject]@{
        name   = "core_running_when_stack_active"
        pass   = if ($stackRunning) { $coreRunning } else { $true }
        detail = if ($coreRunning) { "Core loops detected." } elseif ($stackRunning) { "Stack is active but core loops are not detected." } else { "Stack inactive; core check skipped." }
    }
)

$windowsServiceFindings = @(Get-WindowsServiceFindings -WindowsServicesConfig $windowsServicesConfig)

$portFindings = @()
$portDefs = Get-PortDefinitions -PortsConfig $portsConfig

$bindHostValue = ""
if ($portsConfig -and ($portsConfig.PSObject.Properties.Name -contains "bind_host") -and $portsConfig.bind_host) {
    $bindHostValue = [string]$portsConfig.bind_host
}
if (-not $bindHostValue) {
    $bindHostValue = "127.0.0.1"
}
$bindHostPass = ($bindHostValue -eq "127.0.0.1")
$portFindings += [pscustomobject]@{
    name         = "bind_host_loopback"
    pass         = [bool]$bindHostPass
    detail       = if ($bindHostPass) { "bind_host is loopback." } else { "bind_host must be 127.0.0.1." }
    port         = $null
    expected_pid = $null
    listeners    = @()
}

if ($portDefs.Count -eq 0) {
    $portFindings += [pscustomobject]@{
        name        = "ports_contract_present"
        pass        = $false
        detail      = "No ports definitions found in config/ports.json."
        port        = $null
        expected_pid = $null
        listeners   = @()
    }
}
else {
    foreach ($pd in $portDefs) {
        $port = 0
        if (-not [int]::TryParse([string]$pd.port, [ref]$port)) {
            $portFindings += [pscustomobject]@{
                name        = if ($pd.name) { [string]$pd.name } else { "invalid_port_entry" }
                pass        = $false
                detail      = "Port value is not an integer."
                port        = [string]$pd.port
                expected_pid = $null
                listeners   = @()
            }
            continue
        }

        $expectedPid = Resolve-ExpectedPortPid -PortDef $pd -StackState $stackState
        $listeners = @(Get-PortListeners -Port $port)

        $pass = $true
        $detail = "Port is free."

        if ($listeners.Count -gt 0) {
            if ($null -ne $expectedPid) {
                $ownerMatch = @($listeners | Where-Object { $_.owning_pid -eq $expectedPid }).Count -gt 0
                if ($ownerMatch) {
                    $pass = $true
                    $detail = "Port owned by expected PID."
                }
                else {
                    $pass = $false
                    $detail = "Port is occupied by unexpected PID(s)."
                }
            }
            else {
                $pass = $true
                $detail = "Port is occupied; expected PID mapping not available."
            }

            $nonLoopback = @($listeners | Where-Object { -not (Test-LoopbackAddress -Address ([string]$_.local_address)) })
            if ($nonLoopback.Count -gt 0) {
                $pass = $false
                $detail = "Port has non-loopback listener(s)."
            }
        }

        $portFindings += [pscustomobject]@{
            name         = if ($pd.name) { [string]$pd.name } else { "port_$port" }
            pass         = $pass
            detail       = $detail
            port         = $port
            expected_pid = $expectedPid
            listeners    = $listeners
        }
    }
}

$securityScript = Join-Path $toolsDir "Mason_Secrets_Scan.ps1"
$securityReportPath = Join-Path $reportsDir "security_posture.json"
$securityPass = $true
$securitySummary = $null
$inventoryScriptPath = Join-Path $toolsDir "Mason_Component_Inventory.ps1"
$inventoryReportPath = Join-Path $reportsDir "component_inventory.json"
$inventoryPass = $false
$inventorySummary = $null
$driftScriptPath = Join-Path $toolsDir "Mason_Drift_Manifest.ps1"
$driftReportPath = Join-Path $reportsDir "drift_manifest.json"
$driftPass = $false
$driftSummary = $null

if (Test-Path -LiteralPath $securityScript) {
    try {
        & $securityScript -RootPath $RootPath | Out-Null
    }
    catch {
        Write-DoctorLog "Security scan invocation failed: $($_.Exception.Message)" "WARN"
    }
}

if (Test-Path -LiteralPath $securityReportPath) {
    try {
        $securitySummary = Get-Content -LiteralPath $securityReportPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        $securityPass = [bool]$securitySummary.overall_pass
    }
    catch {
        $securityPass = $false
    }
}
else {
    $securityPass = $false
}

if (Test-Path -LiteralPath $inventoryScriptPath) {
    try {
        & $inventoryScriptPath -RootPath $RootPath | Out-Null
    }
    catch {
        Write-DoctorLog "Component inventory invocation failed: $($_.Exception.Message)" "WARN"
    }
}

if (Test-Path -LiteralPath $inventoryReportPath) {
    try {
        $inventorySummary = Get-Content -LiteralPath $inventoryReportPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        $inventoryPass = $true
    }
    catch {
        $inventoryPass = $false
    }
}
else {
    $inventoryPass = $false
}

if (Test-Path -LiteralPath $driftScriptPath) {
    try {
        & $driftScriptPath -RootPath $RootPath | Out-Null
    }
    catch {
        Write-DoctorLog "Drift manifest invocation failed: $($_.Exception.Message)" "WARN"
    }
}

if (Test-Path -LiteralPath $driftReportPath) {
    try {
        $driftSummary = Get-Content -LiteralPath $driftReportPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        $driftPass = $true
    }
    catch {
        $driftPass = $false
    }
}
else {
    $driftPass = $false
}

$riskPolicyPath = Join-Path $configDir "risk_policy.json"
$riskPolicyGuardrailsPass = $false
if (Test-Path -LiteralPath $riskPolicyPath) {
    try {
        $riskPolicy = Get-Content -LiteralPath $riskPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        $riskPolicyGuardrailsPass = (-not [bool]$riskPolicy.global.high_risk_auto_apply) -and (-not [bool]$riskPolicy.global.money_loop_enabled)
    }
    catch {
        $riskPolicyGuardrailsPass = $false
    }
}

$configPass = (@($configChecks | Where-Object { -not $_.valid }).Count -eq 0)
$approvalsPass = (@($approvalsChecks | Where-Object { -not $_.valid }).Count -eq 0)
$runtimePass = (@($runtimeChecks | Where-Object { -not $_.pass }).Count -eq 0)
$windowsServicesPass = (@($windowsServiceFindings | Where-Object { -not $_.pass -and -not $_.optional }).Count -eq 0)
$portsPass = (@($portFindings | Where-Object { -not $_.pass }).Count -eq 0)

$overallPass = ($configPass -and $approvalsPass -and $runtimePass -and $windowsServicesPass -and $portsPass -and $securityPass -and $riskPolicyGuardrailsPass -and $inventoryPass -and $driftPass)

$nextSteps = New-Object System.Collections.Generic.List[string]
if (-not $configPass) {
    $nextSteps.Add("Fix missing/invalid JSON under .\\config, then rerun doctor.")
}
if (-not $approvalsPass) {
    $nextSteps.Add("Rebuild approvals state: powershell -ExecutionPolicy Bypass -File .\\tools\\Mason_Tasks_To_Approvals.ps1")
}
if (-not $runtimePass) {
    $nextSteps.Add("Start core stack: powershell -ExecutionPolicy Bypass -File .\\Start_Mason2.ps1 -CoreOnly")
}
if (-not $windowsServicesPass) {
    $nextSteps.Add("Review service expectations in .\\config\\windows_services.json and ensure required services are present/running.")
}
if (-not $portsPass) {
    $nextSteps.Add("Repair contract values in .\\config\\ports.json (ports + bind_host=127.0.0.1).")
}
if (-not $securityPass) {
    $nextSteps.Add("Run security posture check: powershell -ExecutionPolicy Bypass -File .\\tools\\Mason_Secrets_Scan.ps1 -FailOnViolation")
}
if (-not $riskPolicyGuardrailsPass) {
    $nextSteps.Add("Set risk guardrails in .\\config\\risk_policy.json: high_risk_auto_apply=false, money_loop_enabled=false.")
}
if (-not $inventoryPass) {
    $nextSteps.Add("Build component inventory: powershell -ExecutionPolicy Bypass -File .\\tools\\Mason_Component_Inventory.ps1")
}
if (-not $driftPass) {
    $nextSteps.Add("Build drift manifest: powershell -ExecutionPolicy Bypass -File .\\tools\\Mason_Drift_Manifest.ps1")
}
if ($nextSteps.Count -eq 0) {
    $nextSteps.Add("No action required.")
}

$doctorReport = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    root_path        = $RootPath
    overall_result   = if ($overallPass) { "PASS" } else { "FAIL" }
    checks           = [ordered]@{
        config_files        = $configChecks
        approvals_files     = $approvalsChecks
        runtime             = $runtimeChecks
        windows_services    = $windowsServiceFindings
        ports               = $portFindings
        security_posture_ok = $securityPass
        risk_guardrails_ok  = $riskPolicyGuardrailsPass
        component_inventory = [ordered]@{
            pass          = [bool]$inventoryPass
            summary       = if ($inventorySummary) { $inventorySummary.summary } else { $null }
            report_path   = $inventoryReportPath
        }
        drift_manifest     = [ordered]@{
            pass        = [bool]$driftPass
            drift_count = if ($driftSummary) { $driftSummary.drift_count } else { $null }
            report_path = $driftReportPath
        }
    }
    stack             = [ordered]@{
        stack_running       = $stackRunning
        watcher_running     = $watcherRunning
        core_running        = $coreRunning
        stack_pid_path      = $stackPidPath
        pid_statuses        = $runningPidDetails
    }
    next_steps         = @($nextSteps)
    report_paths       = [ordered]@{
        doctor_report        = $reportPath
        security_posture     = $securityReportPath
        ports_contract       = $portsPath
        windows_services_cfg = $windowsServicesPath
        component_inventory  = $inventoryReportPath
        drift_manifest       = $driftReportPath
    }
}

$doctorReport | ConvertTo-Json -Depth 14 | Set-Content -LiteralPath $reportPath -Encoding UTF8

if ($overallPass) {
    Write-DoctorLog "PASS"
}
else {
    Write-DoctorLog "FAIL" "WARN"
}

Write-DoctorLog "Next step command(s):"
foreach ($step in $nextSteps) {
    Write-DoctorLog (" - {0}" -f $step)
}
Write-DoctorLog ("Report written: {0}" -f $reportPath)

if ($overallPass) {
    exit 0
}

exit 2
