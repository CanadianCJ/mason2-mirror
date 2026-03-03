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
        [Parameter(Mandatory = $true)]$Object
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $Object | ConvertTo-Json -Depth 35 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-PortListeners {
    param([int]$Port)
    $rowsOut = @()
    try {
        $rows = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue
        foreach ($row in @($rows)) {
            $rowsOut += [pscustomobject]@{
                local_address = [string]$row.LocalAddress
                local_port    = [int]$row.LocalPort
                owning_pid    = [int]$row.OwningProcess
            }
        }
    }
    catch {
        $rowsOut = @()
    }
    return @($rowsOut)
}

function Test-Endpoint {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSec = 5
    )
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Get -TimeoutSec $TimeoutSec -UseBasicParsing -ErrorAction Stop
        return [pscustomobject]@{
            ok          = ($response.StatusCode -ge 200 -and $response.StatusCode -lt 300)
            status_code = [int]$response.StatusCode
            error       = $null
        }
    }
    catch {
        return [pscustomobject]@{
            ok          = $false
            status_code = $null
            error       = $_.Exception.Message
        }
    }
}

function Get-TaskState {
    param([Parameter(Mandatory = $true)][string]$TaskName)
    try {
        $task = Get-ScheduledTask -TaskPath "\Mason2\" -TaskName $TaskName -ErrorAction Stop
        return [pscustomobject]@{
            exists = $true
            state  = [string]$task.State
        }
    }
    catch {
        return [pscustomobject]@{
            exists = $false
            state  = "Missing"
        }
    }
}

function Add-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet("PASS", "WARN", "FAIL")][string]$Status,
        [Parameter(Mandatory = $true)][string]$Detail,
        $Data = $null
    )
    return [pscustomobject]@{
        name   = $Name
        status = $Status
        detail = $Detail
        data   = $Data
    }
}

function Get-ContractPort {
    param(
        [Parameter(Mandatory = $true)]$PortsObject,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][int]$DefaultPort
    )
    $value = $null
    try {
        $value = $PortsObject.$Name
    }
    catch {
        $value = $null
    }
    try {
        $port = [int]$value
        if ($port -gt 0) {
            return $port
        }
    }
    catch {
    }
    return $DefaultPort
}

function Resolve-ComponentForPortName {
    param([Parameter(Mandatory = $true)][string]$Name)
    switch ($Name) {
        "mason_api" { return "core" }
        "seed_api" { return "core" }
        default { return $Name }
    }
}

function Find-LatestComponentStderrLog {
    param(
        [Parameter(Mandatory = $true)][string]$ReportsDir,
        [Parameter(Mandatory = $true)][string]$ComponentId
    )

    $startDir = Join-Path $ReportsDir "start"
    if (-not (Test-Path -LiteralPath $startDir)) {
        return $null
    }

    $pattern = "*_{0}_*_stderr.log" -f $ComponentId
    $latest = Get-ChildItem -LiteralPath $startDir -File -Filter $pattern -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1
    if ($latest) {
        return $latest.FullName
    }
    return $null
}

function Get-TopErrorLine {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        $lines = Get-Content -LiteralPath $Path -Tail 200 -Encoding UTF8
        $match = @($lines | Where-Object { $_ -match "(Traceback|ERROR|Exception|Error|FATAL|failed)" } | Select-Object -First 1)
        if ($match.Count -gt 0) {
            return [string]$match[0]
        }
        $firstNonEmpty = @($lines | Where-Object { $_ -and $_.Trim() } | Select-Object -First 1)
        if ($firstNonEmpty.Count -gt 0) {
            return [string]$firstNonEmpty[0]
        }
    }
    catch {
        return $null
    }
    return $null
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$stateDir = Join-Path $repoRoot "state\knowledge"
$configDir = Join-Path $repoRoot "config"
$docsDir = Join-Path $repoRoot "docs"

$checks = @()

$portsConfigPath = Join-Path $configDir "ports.json"
$portsConfig = Read-JsonSafe -Path $portsConfigPath -Default @{}
$ports = [pscustomobject]@{}
if ($portsConfig -and ($portsConfig.PSObject.Properties.Name -contains "ports")) {
    $ports = $portsConfig.ports
}

$hasPorts = @($ports.PSObject.Properties).Count -gt 0
if ($hasPorts) {
    $checks += Add-Check -Name "ports_contract" -Status "PASS" -Detail "Ports contract loaded." -Data $ports
}
else {
    $checks += Add-Check -Name "ports_contract" -Status "FAIL" -Detail "config/ports.json missing or empty."
}

$athenaPort = Get-ContractPort -PortsObject $ports -Name "athena" -DefaultPort 8000
$onyxPort = Get-ContractPort -PortsObject $ports -Name "onyx" -DefaultPort 5353

$endpointTargets = @(
    [pscustomobject]@{ name = "athena_health"; url = "http://127.0.0.1:$athenaPort/api/health" },
    [pscustomobject]@{ name = "onyx_smoke"; url = "http://127.0.0.1:$onyxPort/main.dart.js" }
)
foreach ($target in $endpointTargets) {
    $probe = Test-Endpoint -Url $target.url
    $status = "WARN"
    $detail = "Endpoint unavailable."
    if ($probe.ok) {
        $status = "PASS"
        $detail = "Endpoint responding."
    }
    $checks += Add-Check -Name ("endpoint_" + $target.name) -Status $status -Detail $detail -Data ([ordered]@{
        url         = $target.url
        status_code = $probe.status_code
        error       = $probe.error
        remediation_hint = if ($target.name -eq "onyx_smoke") { "Verify Onyx launcher is running and main.dart.js is served before browser open." } else { "Check endpoint process and logs under reports/start." }
    })
}

$startRunLastPath = Join-Path $reportsDir "start\start_run_last.json"
$startRunLast = Read-JsonSafe -Path $startRunLastPath -Default $null
$launchResults = @()
if ($startRunLast -and ($startRunLast.PSObject.Properties.Name -contains "launch_results")) {
    $launchResults = @($startRunLast.launch_results)
}

foreach ($entry in @("mason_api", "seed_api", "bridge", "athena", "onyx")) {
    $port = Get-ContractPort -PortsObject $ports -Name $entry -DefaultPort 0
    if ($port -le 0) {
        $checks += Add-Check -Name ("listener_" + $entry) -Status "WARN" -Detail "Port missing from contract."
        continue
    }
    $listeners = @(Get-PortListeners -Port $port)
    $status = "WARN"
    $detail = "No listener on expected port."
    $componentId = Resolve-ComponentForPortName -Name $entry
    $launch = @($launchResults | Where-Object { $_.component -eq $componentId } | Select-Object -First 1)
    $stderrLog = $null
    if ($launch.Count -gt 0 -and $launch[0] -and ($launch[0].PSObject.Properties.Name -contains "stderr_log")) {
        $stderrLog = [string]$launch[0].stderr_log
    }
    if (-not $stderrLog) {
        $stderrLog = Find-LatestComponentStderrLog -ReportsDir $reportsDir -ComponentId $componentId
    }
    $topErrorLine = Get-TopErrorLine -Path $stderrLog
    $remediationHint = "Check $componentId logs in reports/start and rerun tools\\ops\\Stack_Reset_And_Start.ps1."
    if ($listeners.Count -gt 0) {
        $status = "PASS"
        $detail = "Listener present."
        $remediationHint = $null
    }
    $checks += Add-Check -Name ("listener_" + $entry) -Status $status -Detail $detail -Data ([ordered]@{
        port              = $port
        listeners         = $listeners
        stderr_log        = $stderrLog
        top_error_line    = $topErrorLine
        remediation_hint  = $remediationHint
        start_run_report  = $startRunLastPath
    })
}

$taskStates = [ordered]@{
    ingest_autopilot = Get-TaskState -TaskName "Mason2 Ingest Autopilot"
    mirror_update    = Get-TaskState -TaskName "Mason2 Mirror Update"
}
$taskStatus = "PASS"
if ((-not $taskStates.ingest_autopilot.exists) -or (-not $taskStates.mirror_update.exists)) {
    $taskStatus = "WARN"
}
$checks += Add-Check -Name "scheduled_tasks" -Status $taskStatus -Detail "Scheduled task status captured." -Data $taskStates

$mirrorDeltaPath = Join-Path $docsDir "mirror_delta.json"
$mirrorManifestPath = Join-Path $docsDir "mirror_manifest.json"
$mirrorDelta = Read-JsonSafe -Path $mirrorDeltaPath -Default $null
$mirrorManifest = Read-JsonSafe -Path $mirrorManifestPath -Default $null
$mirrorStatus = "WARN"
if ($mirrorDelta -or $mirrorManifest) {
    $mirrorStatus = "PASS"
}
$checks += Add-Check -Name "mirror_status" -Status $mirrorStatus -Detail "Mirror status files checked." -Data ([ordered]@{
    mirror_delta_path      = $mirrorDeltaPath
    mirror_manifest_path   = $mirrorManifestPath
    mirror_delta_exists    = [bool]$mirrorDelta
    mirror_manifest_exists = [bool]$mirrorManifest
})

$ingestStatusPath = Join-Path $reportsDir "ingest_autopilot_status.json"
$ingestStatus = Read-JsonSafe -Path $ingestStatusPath -Default $null
$ingestCheckStatus = "WARN"
$ingestMode = $null
$ingestReason = $null
if ($ingestStatus) {
    $ingestCheckStatus = "PASS"
    try { $ingestMode = [string]$ingestStatus.mode } catch { $ingestMode = $null }
    try { $ingestReason = [string]$ingestStatus.mode_reason } catch { $ingestReason = $null }
}
$checks += Add-Check -Name "ingest_status" -Status $ingestCheckStatus -Detail "Ingest status file checked." -Data ([ordered]@{
    path        = $ingestStatusPath
    mode        = $ingestMode
    mode_reason = $ingestReason
})

$approvalsPath = Join-Path $stateDir "pending_patch_runs.json"
$approvals = Read-JsonSafe -Path $approvalsPath -Default @()
$approvalsPosturePath = Join-Path $reportsDir "approvals_posture.json"
$approvalsPosture = Read-JsonSafe -Path $approvalsPosturePath -Default $null
$approvalsStatus = "WARN"
if ($approvalsPosture) {
    $approvalsStatus = "PASS"
}
$checks += Add-Check -Name "approvals_posture" -Status $approvalsStatus -Detail "Approvals posture file checked." -Data ([ordered]@{
    posture_path            = $approvalsPosturePath
    posture_exists          = [bool]$approvalsPosture
    pending_approvals_count = @($approvals).Count
})

$pendingLlmDir = Join-Path $repoRoot "knowledge\pending_llm"
$pendingLlmCount = 0
if (Test-Path -LiteralPath $pendingLlmDir) {
    $pendingLlmCount = @(Get-ChildItem -LiteralPath $pendingLlmDir -Recurse -File -Filter *.json -ErrorAction SilentlyContinue).Count
}
$checks += Add-Check -Name "pending_llm_queue" -Status "PASS" -Detail "Pending LLM queue counted." -Data ([ordered]@{
    dir   = $pendingLlmDir
    count = $pendingLlmCount
})

$onyxLauncher = Join-Path $repoRoot "Component - Onyx App\onyx_business_manager\Start-Onyx5353.ps1"
$onyxExists = Test-Path -LiteralPath $onyxLauncher
$onyxStatus = "WARN"
$onyxDetail = "Onyx launcher not found."
if ($onyxExists) {
    $onyxStatus = "PASS"
    $onyxDetail = "Onyx launcher found."
}
$checks += Add-Check -Name "onyx_launcher" -Status $onyxStatus -Detail $onyxDetail -Data ([ordered]@{
    path   = $onyxLauncher
    exists = $onyxExists
})

$currencyPolicyPath = Join-Path $configDir "currency_policy.json"
$currencyPolicy = Read-JsonSafe -Path $currencyPolicyPath -Default $null
$budgetStatePath = Join-Path $stateDir "budget_state.json"
$budgetState = Read-JsonSafe -Path $budgetStatePath -Default $null

$currencyStatus = "PASS"
$currencyDetail = "CAD currency policy and budget fields present."
$baseCurrency = $null
$weeklyRemainingCad = $null
if (-not $currencyPolicy) {
    $currencyStatus = "WARN"
    $currencyDetail = "Currency policy missing. Run WO-CURRENCY-CAD-0001."
}
else {
    try { $baseCurrency = [string]$currencyPolicy.base_currency } catch { $baseCurrency = $null }
    if ($baseCurrency -ne "CAD") {
        $currencyStatus = "WARN"
        $currencyDetail = "Currency policy still USD; run WO-CURRENCY-CAD-0001."
    }
}
if ($budgetState -and ($budgetState.PSObject.Properties.Name -contains "weekly_remaining_cad")) {
    $weeklyRemainingCad = $budgetState.weekly_remaining_cad
}
else {
    if ($currencyStatus -eq "PASS") {
        $currencyStatus = "WARN"
        $currencyDetail = "Budget state lacks CAD fields; run WO-CURRENCY-CAD-0001."
    }
}
$checks += Add-Check -Name "currency_cad_audit" -Status $currencyStatus -Detail $currencyDetail -Data ([ordered]@{
    currency_policy_path = $currencyPolicyPath
    budget_state_path    = $budgetStatePath
    base_currency        = $baseCurrency
    weekly_remaining_cad = $weeklyRemainingCad
})

$failCount = @($checks | Where-Object { $_.status -eq "FAIL" }).Count
$warnCount = @($checks | Where-Object { $_.status -eq "WARN" }).Count
$passCount = @($checks | Where-Object { $_.status -eq "PASS" }).Count
$overall = "PASS"
if ($failCount -gt 0) {
    $overall = "FAIL"
}
elseif ($warnCount -gt 0) {
    $overall = "WARN"
}

$reportPath = Join-Path $reportsDir "mason2_e2e_verify.json"
$report = [pscustomobject]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    root_path        = $repoRoot
    overall_status   = $overall
    summary          = [pscustomobject]@{
        fail_count = $failCount
        warn_count = $warnCount
        pass_count = $passCount
    }
    checks           = @($checks)
    report_path      = $reportPath
}

Write-JsonFile -Path $reportPath -Object $report
$report | ConvertTo-Json -Depth 35
exit 0
