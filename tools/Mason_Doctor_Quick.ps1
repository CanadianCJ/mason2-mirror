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
    $Object | ConvertTo-Json -Depth 25 | Set-Content -LiteralPath $Path -Encoding UTF8
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

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$stateDir = Join-Path $repoRoot "state\knowledge"
$configDir = Join-Path $repoRoot "config"
$docsDir = Join-Path $repoRoot "docs"

$portsConfigPath = Join-Path $configDir "ports.json"
$portsConfig = Read-JsonSafe -Path $portsConfigPath -Default @{}
$ports = [pscustomobject]@{}
if ($portsConfig -and ($portsConfig.PSObject.Properties.Name -contains "ports")) {
    $ports = $portsConfig.ports
}

$checks = @()
foreach ($entry in @("mason_api", "seed_api", "bridge", "athena", "onyx")) {
    $port = Get-ContractPort -PortsObject $ports -Name $entry -DefaultPort 0
    if ($port -le 0) {
        $checks += Add-Check -Name ("port_" + $entry) -Status "WARN" -Detail "Port mapping missing."
        continue
    }
    $listeners = @(Get-PortListeners -Port $port)
    $status = "WARN"
    $detail = "No listener on $port."
    if ($listeners.Count -gt 0) {
        $status = "PASS"
        $detail = "Listener present on $port."
    }
    $checks += Add-Check -Name ("port_" + $entry) -Status $status -Detail $detail -Data ([ordered]@{
        port      = $port
        listeners = $listeners
    })
}

$athenaPort = Get-ContractPort -PortsObject $ports -Name "athena" -DefaultPort 8000
$athenaHealth = Test-Endpoint -Url ("http://127.0.0.1:{0}/api/health" -f $athenaPort)
$healthStatus = "WARN"
$healthDetail = "Athena health endpoint unavailable."
if ($athenaHealth.ok) {
    $healthStatus = "PASS"
    $healthDetail = "Athena health endpoint responding."
}
$checks += Add-Check -Name "athena_health" -Status $healthStatus -Detail $healthDetail -Data ([ordered]@{
    endpoint    = "http://127.0.0.1:$athenaPort/api/health"
    status_code = $athenaHealth.status_code
    error       = $athenaHealth.error
})

$ingestStatusPath = Join-Path $reportsDir "ingest_autopilot_status.json"
$ingestStatus = Read-JsonSafe -Path $ingestStatusPath -Default $null
$ingestCheckStatus = "WARN"
$ingestDetail = "Ingest status report missing."
$ingestMode = $null
if ($ingestStatus) {
    $ingestCheckStatus = "PASS"
    $ingestDetail = "Ingest status report exists."
    try {
        $ingestMode = [string]$ingestStatus.mode
    }
    catch {
        $ingestMode = $null
    }
}
$checks += Add-Check -Name "last_ingest_status" -Status $ingestCheckStatus -Detail $ingestDetail -Data ([ordered]@{
    path = $ingestStatusPath
    mode = $ingestMode
})

$mirrorDeltaPath = Join-Path $docsDir "mirror_delta.json"
$mirrorDelta = Read-JsonSafe -Path $mirrorDeltaPath -Default $null
$mirrorStatus = "WARN"
$mirrorDetail = "Mirror delta report missing."
if ($mirrorDelta) {
    $mirrorStatus = "PASS"
    $mirrorDetail = "Mirror delta report exists."
}
$checks += Add-Check -Name "last_mirror_status" -Status $mirrorStatus -Detail $mirrorDetail -Data ([ordered]@{
    path = $mirrorDeltaPath
})

$pendingLlmDir = Join-Path $repoRoot "knowledge\pending_llm"
$pendingLlmCount = 0
if (Test-Path -LiteralPath $pendingLlmDir) {
    $pendingLlmCount = @(Get-ChildItem -LiteralPath $pendingLlmDir -Recurse -File -Filter *.json -ErrorAction SilentlyContinue).Count
}

$pendingApprovalsPath = Join-Path $stateDir "pending_patch_runs.json"
$pendingApprovals = Read-JsonSafe -Path $pendingApprovalsPath -Default @()
$approvalsCount = @($pendingApprovals).Count
$checks += Add-Check -Name "pending_queues" -Status "PASS" -Detail "Queue counts captured." -Data ([ordered]@{
    pending_llm_count       = $pendingLlmCount
    pending_approvals_count = $approvalsCount
})

$ingestTask = Get-TaskState -TaskName "Mason2 Ingest Autopilot"
$mirrorTask = Get-TaskState -TaskName "Mason2 Mirror Update"
$taskStatus = "WARN"
if ($ingestTask.exists -or $mirrorTask.exists) {
    $taskStatus = "PASS"
}
$checks += Add-Check -Name "scheduled_tasks" -Status $taskStatus -Detail "Scheduled task presence evaluated." -Data ([ordered]@{
    ingest_autopilot = $ingestTask
    mirror_update    = $mirrorTask
})

$freeGb = 0.0
try {
    $drive = Get-PSDrive -Name C -ErrorAction Stop
    $freeGb = [Math]::Round(([double]$drive.Free / 1GB), 2)
}
catch {
    $freeGb = 0.0
}
$diskStatus = "PASS"
if ($freeGb -lt 2.0) {
    $diskStatus = "FAIL"
}
elseif ($freeGb -lt 5.0) {
    $diskStatus = "WARN"
}
$checks += Add-Check -Name "disk_guard" -Status $diskStatus -Detail "Drive C free space check." -Data ([ordered]@{
    free_gb = $freeGb
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

$reportPath = Join-Path $reportsDir "mason2_doctor_quick_report.json"
$report = [pscustomobject]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    root_path        = $repoRoot
    overall_result   = $overall
    summary          = [pscustomobject]@{
        fail_count = $failCount
        warn_count = $warnCount
        pass_count = $passCount
    }
    checks           = @($checks)
    report_path      = $reportPath
}

Write-JsonFile -Path $reportPath -Object $report
$report | ConvertTo-Json -Depth 25
exit 0
