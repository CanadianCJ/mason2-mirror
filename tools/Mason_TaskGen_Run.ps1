[CmdletBinding()]
param(
    [string]$RootPath = "",
    [switch]$DryRun,
    [ValidateRange(1, 2000)][int]$MaxItems = 200,
    [ValidateRange(1, 720)][int]$SinceHours = 24
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-TaskGenHost {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Mason_TaskGen_Run] [$Level] $Message"
}

function To-Array {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return $Value }
    return @($Value)
}

function To-OrderedMap {
    param($Value)
    $map = [ordered]@{}
    if ($null -eq $Value) { return $map }
    if ($Value -is [hashtable]) {
        foreach ($k in $Value.Keys) {
            $map[$k] = $Value[$k]
        }
        return $map
    }
    foreach ($p in $Value.PSObject.Properties) {
        $map[$p.Name] = $p.Value
    }
    return $map
}

function Convert-ToRiskInt {
    param($RiskValue)

    if ($null -eq $RiskValue) { return 1 }
    $raw = [string]$RiskValue
    if (-not $raw.Trim()) { return 1 }

    $n = 0
    if ([int]::TryParse($raw, [ref]$n)) {
        return [Math]::Min(3, [Math]::Max(0, $n))
    }

    $text = $raw.Trim().ToLowerInvariant()
    switch ($text) {
        "r0" { return 0 }
        "r1" { return 1 }
        "r2" { return 2 }
        "r3" { return 3 }
        "low" { return 1 }
        "medium" { return 2 }
        "high" { return 3 }
        "critical" { return 3 }
        "observe_only" { return 0 }
        default {
            $m = [regex]::Match($text, "(\d+)")
            if ($m.Success) {
                $v = [int]$m.Groups[1].Value
                return [Math]::Min(3, [Math]::Max(0, $v))
            }
            return 1
        }
    }
}

function Parse-DateUtc {
    param($Value)
    $dt = [datetime]::MinValue
    if ($Value -and [datetime]::TryParse([string]$Value, [ref]$dt)) {
        return $dt.ToUniversalTime()
    }
    return (Get-Date).ToUniversalTime()
}

function New-Sha256Hex {
    param([Parameter(Mandatory = $true)][string]$InputText)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputText)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($bytes)
    }
    finally {
        $sha.Dispose()
    }
    return (-join ($hash | ForEach-Object { $_.ToString("x2") }))
}

function Get-OrCreate-Id {
    param([Parameter(Mandatory = $true)][hashtable]$Item)

    if ($Item.Contains("id") -and ([string]$Item["id"]).Trim()) {
        return ([string]$Item["id"]).Trim()
    }

    $seed = "{0}|{1}|{2}|{3}" -f `
        ([string]$Item["title"]), `
        ([string]$Item["component_id"]), `
        ([string]$Item["source"]), `
        ([string]$Item["created_at"])
    $id = "item-" + (New-Sha256Hex -InputText $seed).Substring(0, 24)
    $Item["id"] = $id
    return $id
}

function New-TaskId {
    param(
        [Parameter(Mandatory = $true)][string]$TemplateKey,
        [Parameter(Mandatory = $true)][string]$Seed
    )
    $slug = ($TemplateKey.ToLowerInvariant() -replace "[^a-z0-9]+", "-").Trim("-")
    if (-not $slug) { $slug = "task" }
    if ($slug.Length -gt 24) { $slug = $slug.Substring(0, 24) }
    $hash = New-Sha256Hex -InputText $Seed
    return "taskgen-{0}-{1}" -f $slug, $hash.Substring(0, 10)
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
        throw "Failed to parse JSON file $Path : $($_.Exception.Message)"
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 20
    )

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $json = $Object | ConvertTo-Json -Depth $Depth
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Append-JsonLine {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object
    )

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $line = ($Object | ConvertTo-Json -Depth 12 -Compress)
    Add-Content -LiteralPath $Path -Value $line -Encoding UTF8
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
            $rel = $fullResolved.Substring($baseResolved.Length).TrimStart("\", "/")
            if ($rel) {
                return $rel.Replace("/", "\")
            }
        }
        return $fullResolved
    }
    catch {
        return $FullPath
    }
}

function Get-ReportContext {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$Required,
        [Parameter(Mandatory = $true)][datetime]$CutoffUtc
    )

    $ctx = [ordered]@{
        name           = $Name
        path           = $Path
        exists         = $false
        parse_ok       = $false
        fresh          = $false
        required       = [bool]$Required
        last_write_utc = $null
        error          = $null
        data           = $null
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        if ($Required) {
            $ctx.error = "missing_required_file"
        }
        return [pscustomobject]$ctx
    }

    $ctx.exists = $true
    $item = Get-Item -LiteralPath $Path -ErrorAction Stop
    $ctx.last_write_utc = $item.LastWriteTimeUtc.ToString("o")
    $ctx.fresh = ($item.LastWriteTimeUtc -ge $CutoffUtc)

    try {
        $ctx.data = Read-JsonSafe -Path $Path -Default $null
        $ctx.parse_ok = $true
    }
    catch {
        $ctx.error = $_.Exception.Message
        $ctx.parse_ok = $false
    }

    return [pscustomobject]$ctx
}

function Normalize-QueueItem {
    param(
        [Parameter(Mandatory = $true)]$Item,
        [string]$DefaultSource = "manual"
    )

    $map = To-OrderedMap $Item

    $riskInput = $null
    if ($map.Contains("risk_level")) {
        $riskInput = $map["risk_level"]
    }
    elseif ($map.Contains("risk")) {
        $riskInput = $map["risk"]
    }
    $map["risk_level"] = [int](Convert-ToRiskInt $riskInput)
    $map["created_at"] = (Parse-DateUtc $map["created_at"]).ToString("o")

    if (-not $map.Contains("status") -or -not ([string]$map["status"]).Trim()) {
        $map["status"] = "pending"
    }
    if (-not $map.Contains("source") -or -not ([string]$map["source"]).Trim()) {
        $map["source"] = $DefaultSource
    }

    $null = Get-OrCreate-Id -Item $map
    return $map
}

function Dedupe-ByIdOldest {
    param(
        [Parameter(Mandatory = $true)]$Items
    )
    $seen = @{}
    $kept = New-Object System.Collections.Generic.List[object]
    $removed = 0

    foreach ($item in @($Items | Sort-Object { Parse-DateUtc $_["created_at"] })) {
        if ($null -eq $item) { continue }
        $id = Get-OrCreate-Id -Item $item
        if ($seen.ContainsKey($id)) {
            $removed++
            continue
        }
        $seen[$id] = $true
        $kept.Add($item)
    }

    return [pscustomobject]@{
        items         = @($kept.ToArray())
        removed_count = [int]$removed
    }
}

function Is-LoopbackAddress {
    param([string]$Address)

    if (-not $Address) { return $true }
    $raw = $Address.Trim().ToLowerInvariant()
    if (-not $raw) { return $true }

    if ($raw -eq "localhost" -or $raw -eq "::1" -or $raw -eq "[::1]") { return $true }
    if ($raw -like "127.*") { return $true }

    if ($raw -eq "0.0.0.0" -or $raw -eq "::" -or $raw -eq "[::]" -or $raw -eq "*") {
        return $false
    }

    return $false
}

function New-GeneratedTask {
    param(
        [Parameter(Mandatory = $true)][string]$TemplateKey,
        [Parameter(Mandatory = $true)][string]$ComponentId,
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][int]$RiskLevel,
        [Parameter(Mandatory = $true)][string[]]$EvidenceFiles,
        [Parameter(Mandatory = $true)][string]$Reason,
        [Parameter(Mandatory = $true)][string]$CreatedAtUtc
    )

    $evidence = @($EvidenceFiles | Where-Object { $_ -and $_.Trim() } | Select-Object -Unique)
    $seed = "{0}|{1}|{2}|{3}" -f $TemplateKey, $ComponentId, $Title, ($evidence -join "|")
    $id = New-TaskId -TemplateKey $TemplateKey -Seed $seed

    return [ordered]@{
        id             = $id
        component_id   = $ComponentId
        title          = $Title
        risk_level     = [int]$RiskLevel
        status         = "pending"
        source         = "taskgen"
        created_at     = $CreatedAtUtc
        evidence_files = $evidence
        kind           = "patch_run"
        template_key   = $TemplateKey
        taskgen_reason = $Reason
    }
}

function Add-GeneratedCandidate {
    param(
        [Parameter(Mandatory = $true)]$List,
        [Parameter(Mandatory = $true)][hashtable]$Task
    )
    $List.Add($Task) | Out-Null
}

# ---- Main ----
$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $RootPath) {
    $RootPath = Split-Path -Parent $scriptRoot
}

$reportsDir = Join-Path $RootPath "reports"
$stateDir = Join-Path $RootPath "state\knowledge"
$pendingPath = Join-Path $stateDir "pending_patch_runs.json"
$quarantinePath = Join-Path $stateDir "pending_patch_runs_quarantine.json"
$taskgenLastPath = Join-Path $reportsDir "taskgen_last.json"
$taskgenLogPath = Join-Path $reportsDir "taskgen_log.jsonl"

New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
New-Item -ItemType Directory -Path $stateDir -Force | Out-Null

if (-not (Test-Path -LiteralPath $pendingPath)) {
    "[]" | Set-Content -LiteralPath $pendingPath -Encoding UTF8
}
if (-not (Test-Path -LiteralPath $quarantinePath)) {
    "[]" | Set-Content -LiteralPath $quarantinePath -Encoding UTF8
}

$generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
$cutoffUtc = (Get-Date).ToUniversalTime().AddHours(-1 * $SinceHours)

$doctorPath = Join-Path $reportsDir "mason2_doctor_report.json"
$securityPath = Join-Path $reportsDir "security_posture.json"
$bridgePath = Join-Path $reportsDir "bridge_status.json"
$corePath = Join-Path $reportsDir "mason2_core_status.json"
$componentInventoryPath = Join-Path $reportsDir "component_inventory.json"

$reportContexts = New-Object System.Collections.Generic.List[object]
$reportContexts.Add((Get-ReportContext -Name "doctor" -Path $doctorPath -Required -CutoffUtc $cutoffUtc)) | Out-Null
$reportContexts.Add((Get-ReportContext -Name "security" -Path $securityPath -Required -CutoffUtc $cutoffUtc)) | Out-Null
$reportContexts.Add((Get-ReportContext -Name "bridge" -Path $bridgePath -Required -CutoffUtc $cutoffUtc)) | Out-Null
$reportContexts.Add((Get-ReportContext -Name "core" -Path $corePath -Required -CutoffUtc $cutoffUtc)) | Out-Null
$reportContexts.Add((Get-ReportContext -Name "component_inventory" -Path $componentInventoryPath -CutoffUtc $cutoffUtc)) | Out-Null

$onyxHealthStatusPath = Join-Path $reportsDir "onyx_health_status.json"
$onyxHealthSummaryPath = Join-Path $reportsDir "onyx_health_summary.json"
$onyxCodeHealthPath = Join-Path $reportsDir "onyx_code_health.json"
$reportContexts.Add((Get-ReportContext -Name "onyx_health_status" -Path $onyxHealthStatusPath -CutoffUtc $cutoffUtc)) | Out-Null
$reportContexts.Add((Get-ReportContext -Name "onyx_health_summary" -Path $onyxHealthSummaryPath -CutoffUtc $cutoffUtc)) | Out-Null
$reportContexts.Add((Get-ReportContext -Name "onyx_code_health" -Path $onyxCodeHealthPath -CutoffUtc $cutoffUtc)) | Out-Null

$latestOnyxPrelaunch = Get-ChildItem -Path $reportsDir -Filter "onyx_prelaunch_health_*.json" -File -ErrorAction SilentlyContinue |
    Sort-Object -Property LastWriteTimeUtc -Descending |
    Select-Object -First 1
if ($latestOnyxPrelaunch) {
    $reportContexts.Add((Get-ReportContext -Name "onyx_prelaunch_latest" -Path $latestOnyxPrelaunch.FullName -CutoffUtc $cutoffUtc)) | Out-Null
}

$reportsByName = @{}
foreach ($ctx in @($reportContexts.ToArray())) {
    $reportsByName[$ctx.name] = $ctx
}

$contextProblems = New-Object System.Collections.Generic.List[object]
foreach ($ctx in @($reportContexts.ToArray())) {
    if ($ctx.required -and -not $ctx.exists) {
        $contextProblems.Add([pscustomobject]@{ name = $ctx.name; issue = "missing_required_file" }) | Out-Null
    }
    elseif ($ctx.required -and -not $ctx.parse_ok) {
        $contextProblems.Add([pscustomobject]@{ name = $ctx.name; issue = "parse_error"; error = $ctx.error }) | Out-Null
    }
    elseif ($ctx.required -and -not $ctx.fresh) {
        $contextProblems.Add([pscustomobject]@{ name = $ctx.name; issue = "stale_report"; last_write_utc = $ctx.last_write_utc }) | Out-Null
    }
}

$pendingRaw = Read-JsonSafe -Path $pendingPath -Default @()
$quarantineRaw = Read-JsonSafe -Path $quarantinePath -Default @()
$pendingInput = @()
foreach ($item in To-Array $pendingRaw) {
    if ($null -eq $item) { continue }
    $pendingInput += Normalize-QueueItem -Item $item -DefaultSource "manual"
}
$quarantineInput = @()
foreach ($item in To-Array $quarantineRaw) {
    if ($null -eq $item) { continue }
    $quarantineInput += Normalize-QueueItem -Item $item -DefaultSource "manual"
}

$pendingBase = @($pendingInput | Where-Object { ([string]$_.source).ToLowerInvariant() -ne "taskgen" })
$quarantineBase = @($quarantineInput | Where-Object { ([string]$_.source).ToLowerInvariant() -ne "taskgen" })

$pendingBaseDedup = Dedupe-ByIdOldest -Items $pendingBase
$quarantineBaseDedup = Dedupe-ByIdOldest -Items $quarantineBase
$pendingBaseItems = @($pendingBaseDedup.items)
$quarantineBaseItems = @($quarantineBaseDedup.items)

$generatedCandidates = New-Object System.Collections.Generic.List[object]

# --- Mapping: missing port mapping -> ports contract task (R1) ---
$doctorCtx = $reportsByName["doctor"]
if ($doctorCtx -and $doctorCtx.exists -and $doctorCtx.parse_ok -and $doctorCtx.fresh) {
    $doctorPortsMissing = $false
    $doctorChecks = $doctorCtx.data.checks
    if ($doctorChecks -and ($doctorChecks.PSObject.Properties.Name -contains "ports")) {
        foreach ($entry in To-Array $doctorChecks.ports) {
            if ($null -eq $entry) { continue }
            $entryMap = To-OrderedMap $entry
            $detail = [string]$entryMap["detail"]
            $passFlag = $null
            if ($entryMap.Contains("pass")) {
                $passFlag = [bool]$entryMap["pass"]
            }
            if (($null -ne $passFlag -and -not $passFlag) -or ($detail -match "(?i)no\s+'?ports'? definitions found|missing.+port")) {
                $doctorPortsMissing = $true
                break
            }
        }
    }
    if ($doctorPortsMissing) {
        $evidence = @(Get-RelativePathSafe -BasePath $RootPath -FullPath $doctorPath)
        $task = New-GeneratedTask `
            -TemplateKey "ports_contract" `
            -ComponentId "mason" `
            -Title "Define Mason ports contract in config/ports.json" `
            -RiskLevel 1 `
            -EvidenceFiles $evidence `
            -Reason "doctor_ports_mapping_missing" `
            -CreatedAtUtc $generatedAtUtc
        Add-GeneratedCandidate -List $generatedCandidates -Task $task
    }
}

# --- Mapping: port binding exposure (0.0.0.0/::) -> loopback-only task (R2, quarantine) ---
$securityCtx = $reportsByName["security"]
if ($securityCtx -and $securityCtx.exists -and $securityCtx.parse_ok -and $securityCtx.fresh) {
    $securityData = $securityCtx.data
    $exposedPorts = New-Object System.Collections.Generic.HashSet[string]
    $loopbackBlock = $securityData.loopback_bindings
    if ($loopbackBlock -and ($loopbackBlock.PSObject.Properties.Name -contains "ports_checked")) {
        foreach ($portEntry in To-Array $loopbackBlock.ports_checked) {
            if ($null -eq $portEntry) { continue }
            $map = To-OrderedMap $portEntry
            $portText = if ($map.Contains("port")) { [string]$map["port"] } else { "unknown" }
            $hasExposure = $false
            $listeners = @()
            if ($map.Contains("listeners")) {
                $listeners = To-Array $map["listeners"]
            }
            foreach ($listener in $listeners) {
                if ($null -eq $listener) { continue }
                $listenerMap = To-OrderedMap $listener
                $addr = ""
                foreach ($field in @("local_address", "LocalAddress", "address", "ip")) {
                    if ($listenerMap.Contains($field) -and ([string]$listenerMap[$field]).Trim()) {
                        $addr = [string]$listenerMap[$field]
                        break
                    }
                }
                if (-not (Is-LoopbackAddress -Address $addr)) {
                    $hasExposure = $true
                    break
                }
            }
            if (-not $hasExposure) {
                $loopbackOnly = $true
                if ($map.Contains("loopback_only")) {
                    $loopbackOnly = [bool]$map["loopback_only"]
                }
                $listenerCount = 0
                if ($map.Contains("listener_count")) {
                    try { $listenerCount = [int]$map["listener_count"] } catch { $listenerCount = 0 }
                }
                if ($listenerCount -gt 0 -and -not $loopbackOnly) {
                    $hasExposure = $true
                }
            }

            if ($hasExposure) {
                $null = $exposedPorts.Add($portText)
            }
        }
    }

    foreach ($portText in @($exposedPorts | Sort-Object)) {
        $title = "Bind Mason service port $portText to loopback only (127.0.0.1/::1)"
        $evidence = @(Get-RelativePathSafe -BasePath $RootPath -FullPath $securityPath)
        $task = New-GeneratedTask `
            -TemplateKey "bind_loopback_only_port_$portText" `
            -ComponentId "mason" `
            -Title $title `
            -RiskLevel 2 `
            -EvidenceFiles $evidence `
            -Reason "security_port_binding_exposure" `
            -CreatedAtUtc $generatedAtUtc
        Add-GeneratedCandidate -List $generatedCandidates -Task $task
    }
}

# --- Mapping: secrets hygiene fail -> secret guardrail task (R2, quarantine) ---
if ($securityCtx -and $securityCtx.exists -and $securityCtx.parse_ok -and $securityCtx.fresh) {
    $securityData = $securityCtx.data
    $secretsFail = $false
    $violationCount = 0
    if ($securityData.secrets_scan) {
        $scan = $securityData.secrets_scan
        if ($scan.PSObject.Properties.Name -contains "violation_count") {
            try { $violationCount = [int]$scan.violation_count } catch { $violationCount = 0 }
        }
        $scanPass = $true
        if ($scan.PSObject.Properties.Name -contains "pass") {
            $scanPass = [bool]$scan.pass
        }
        if (-not $scanPass -or $violationCount -gt 0) {
            $secretsFail = $true
        }
    }
    if ($secretsFail) {
        $evidence = @(
            Get-RelativePathSafe -BasePath $RootPath -FullPath $securityPath
            Get-RelativePathSafe -BasePath $RootPath -FullPath $doctorPath
        ) | Select-Object -Unique

        $task = New-GeneratedTask `
            -TemplateKey "secret_scan_guardrail" `
            -ComponentId "mason" `
            -Title "Harden secret scan guardrails and remediate secret hygiene violations" `
            -RiskLevel 2 `
            -EvidenceFiles $evidence `
            -Reason "security_secrets_scan_failed" `
            -CreatedAtUtc $generatedAtUtc
        Add-GeneratedCandidate -List $generatedCandidates -Task $task
    }
}

# --- Mapping: Onyx serve checks -> Onyx smoke/serve 200 task (R1) ---
$onyxEvidence = New-Object System.Collections.Generic.List[string]
$onyxFailureReasons = New-Object System.Collections.Generic.List[string]

$onyxStatusCtx = $reportsByName["onyx_health_status"]
if ($onyxStatusCtx -and $onyxStatusCtx.exists -and $onyxStatusCtx.parse_ok -and $onyxStatusCtx.fresh) {
    $statusData = $onyxStatusCtx.data
    $okFieldExists = $statusData.PSObject.Properties.Name -contains "ok"
    $okValue = if ($okFieldExists) { [bool]$statusData.ok } else { $true }
    $statusCode = $null
    if ($statusData.PSObject.Properties.Name -contains "statusCode") {
        try { $statusCode = [int]$statusData.statusCode } catch { $statusCode = $null }
    }
    if (($okFieldExists -and -not $okValue) -or ($null -ne $statusCode -and $statusCode -ne 200)) {
        $onyxEvidence.Add((Get-RelativePathSafe -BasePath $RootPath -FullPath $onyxStatusCtx.path)) | Out-Null
        $onyxFailureReasons.Add("onyx_health_status_not_ok") | Out-Null
    }
}

$onyxSummaryCtx = $reportsByName["onyx_health_summary"]
if ($onyxSummaryCtx -and $onyxSummaryCtx.exists -and $onyxSummaryCtx.parse_ok -and $onyxSummaryCtx.fresh) {
    $summaryData = $onyxSummaryCtx.data
    $healthOpinion = ""
    if ($summaryData.PSObject.Properties.Name -contains "healthOpinion") {
        $healthOpinion = [string]$summaryData.healthOpinion
    }
    $errorCount = 0
    if ($summaryData.PSObject.Properties.Name -contains "errorCount") {
        try { $errorCount = [int]$summaryData.errorCount } catch { $errorCount = 0 }
    }
    if (($healthOpinion -and $healthOpinion.ToLowerInvariant() -ne "healthy") -or $errorCount -gt 0) {
        $onyxEvidence.Add((Get-RelativePathSafe -BasePath $RootPath -FullPath $onyxSummaryCtx.path)) | Out-Null
        $onyxFailureReasons.Add("onyx_health_summary_unhealthy") | Out-Null
    }
}

$onyxCodeCtx = $reportsByName["onyx_code_health"]
if ($onyxCodeCtx -and $onyxCodeCtx.exists -and $onyxCodeCtx.parse_ok -and $onyxCodeCtx.fresh) {
    $codeData = $onyxCodeCtx.data
    $analyzeExit = 0
    if ($codeData.PSObject.Properties.Name -contains "analyze_exit_code") {
        try { $analyzeExit = [int]$codeData.analyze_exit_code } catch { $analyzeExit = 0 }
    }
    if ($analyzeExit -gt 0) {
        $onyxEvidence.Add((Get-RelativePathSafe -BasePath $RootPath -FullPath $onyxCodeCtx.path)) | Out-Null
        $onyxFailureReasons.Add("onyx_analyzer_nonzero_exit") | Out-Null
    }
}

$coreCtx = $reportsByName["core"]
if ($coreCtx -and $coreCtx.exists -and $coreCtx.parse_ok -and $coreCtx.fresh) {
    if ($coreCtx.data.readiness) {
        foreach ($entry in To-Array $coreCtx.data.readiness) {
            if ($null -eq $entry) { continue }
            $url = [string]$entry.url
            $ready = $true
            if ($entry.PSObject.Properties.Name -contains "ready") {
                $ready = [bool]$entry.ready
            }
            if ($url -match ":5353" -and -not $ready) {
                $onyxEvidence.Add((Get-RelativePathSafe -BasePath $RootPath -FullPath $coreCtx.path)) | Out-Null
                $onyxFailureReasons.Add("core_readiness_onyx_endpoint_unready") | Out-Null
                break
            }
        }
    }
}

if ($onyxEvidence.Count -gt 0) {
    $task = New-GeneratedTask `
        -TemplateKey "onyx_smoke_serve_200" `
        -ComponentId "onyx" `
        -Title "Restore Onyx smoke/serve HTTP 200 health checks" `
        -RiskLevel 1 `
        -EvidenceFiles @($onyxEvidence | Select-Object -Unique) `
        -Reason ((@($onyxFailureReasons | Select-Object -Unique) -join ",")) `
        -CreatedAtUtc $generatedAtUtc
    Add-GeneratedCandidate -List $generatedCandidates -Task $task
}

# --- Mapping: component inventory drift -> wiring consistency task (R1 default) ---
$inventoryCtx = $reportsByName["component_inventory"]
if ($inventoryCtx -and $inventoryCtx.exists -and $inventoryCtx.parse_ok -and $inventoryCtx.fresh) {
    $inventoryData = $inventoryCtx.data
    $driftList = @()
    if ($inventoryData -and ($inventoryData.PSObject.Properties.Name -contains "drift_findings")) {
        $driftList = @(To-Array $inventoryData.drift_findings)
    }

    $driftCount = 0
    foreach ($finding in $driftList) {
        if ($null -eq $finding) { continue }
        if ($driftCount -ge 40) { break }

        $map = To-OrderedMap $finding
        $componentId = "mason"
        if ($map.Contains("component_id") -and ([string]$map["component_id"]).Trim()) {
            $componentId = [string]$map["component_id"]
        }

        $code = "inventory_drift"
        if ($map.Contains("code") -and ([string]$map["code"]).Trim()) {
            $code = [string]$map["code"]
        }

        $title = ""
        if ($map.Contains("title") -and ([string]$map["title"]).Trim()) {
            $title = [string]$map["title"]
        }
        if (-not $title) {
            $title = "Resolve component inventory drift ($code)"
        }

        $risk = 1
        if ($map.Contains("risk_level")) {
            $risk = [int](Convert-ToRiskInt $map["risk_level"])
        }

        $evidence = New-Object System.Collections.Generic.List[string]
        $evidence.Add((Get-RelativePathSafe -BasePath $RootPath -FullPath $componentInventoryPath)) | Out-Null
        if ($map.Contains("evidence_files")) {
            foreach ($ev in To-Array $map["evidence_files"]) {
                $evText = [string]$ev
                if ($evText.Trim()) {
                    $evidence.Add($evText) | Out-Null
                }
            }
        }

        $task = New-GeneratedTask `
            -TemplateKey ("component_inventory_{0}" -f $code) `
            -ComponentId $componentId `
            -Title $title `
            -RiskLevel $risk `
            -EvidenceFiles @($evidence.ToArray() | Select-Object -Unique) `
            -Reason ("component_inventory_drift:{0}" -f $code) `
            -CreatedAtUtc $generatedAtUtc

        Add-GeneratedCandidate -List $generatedCandidates -Task $task
        $driftCount++
    }
}

$candidateDedup = Dedupe-ByIdOldest -Items @($generatedCandidates.ToArray())
$generatedItems = @($candidateDedup.items)

$generatedLowRisk = New-Object System.Collections.Generic.List[object]
$generatedHighRisk = New-Object System.Collections.Generic.List[object]
foreach ($task in $generatedItems) {
    $risk = [int](Convert-ToRiskInt $task["risk_level"])
    $task["risk_level"] = $risk
    if ($risk -le 1) {
        $generatedLowRisk.Add($task) | Out-Null
    }
    else {
        if (-not $task.Contains("quarantine_reason")) {
            $task["quarantine_reason"] = "risk_gt_r1_gate"
        }
        $generatedHighRisk.Add($task) | Out-Null
    }
}

$eligibleExisting = New-Object System.Collections.Generic.List[object]
$existingRiskOverflow = New-Object System.Collections.Generic.List[object]
foreach ($item in $pendingBaseItems) {
    $risk = [int](Convert-ToRiskInt $item["risk_level"])
    $item["risk_level"] = $risk
    if ($risk -le 1) {
        $eligibleExisting.Add($item) | Out-Null
    }
    else {
        if (-not $item.Contains("quarantine_reason")) {
            $item["quarantine_reason"] = "risk_gt_r1_gate"
        }
        $existingRiskOverflow.Add($item) | Out-Null
    }
}

$generatedEligibleSorted = @($generatedLowRisk.ToArray() | Sort-Object { Parse-DateUtc $_["created_at"] })
$existingEligibleSorted = @($eligibleExisting.ToArray() | Sort-Object { Parse-DateUtc $_["created_at"] })

$selectedPending = New-Object System.Collections.Generic.List[object]
foreach ($item in $generatedEligibleSorted) {
    if ($selectedPending.Count -ge $MaxItems) { break }
    $selectedPending.Add($item) | Out-Null
}

$remainingSlots = [Math]::Max(0, ($MaxItems - $selectedPending.Count))
$existingSelected = @()
if ($remainingSlots -gt 0) {
    $existingSelected = @($existingEligibleSorted | Select-Object -First $remainingSlots)
    foreach ($item in $existingSelected) {
        $selectedPending.Add($item) | Out-Null
    }
}

$generatedSelectedIds = @{}
foreach ($item in @($generatedEligibleSorted)) {
    $generatedSelectedIds[[string]$item["id"]] = $false
}
foreach ($item in @($selectedPending.ToArray())) {
    $id = [string]$item["id"]
    if ($generatedSelectedIds.ContainsKey($id)) {
        $generatedSelectedIds[$id] = $true
    }
}

$floodOverflow = New-Object System.Collections.Generic.List[object]
foreach ($item in $generatedEligibleSorted) {
    $id = [string]$item["id"]
    if (-not $generatedSelectedIds[$id]) {
        $item["quarantine_reason"] = "taskgen_flood_control_overflow"
        $floodOverflow.Add($item) | Out-Null
    }
}

$existingSelectedIdSet = @{}
foreach ($item in $existingSelected) {
    $existingSelectedIdSet[[string]$item["id"]] = $true
}
foreach ($item in $existingEligibleSorted) {
    $id = [string]$item["id"]
    if (-not $existingSelectedIdSet.ContainsKey($id)) {
        if (-not $item.Contains("quarantine_reason")) {
            $item["quarantine_reason"] = "taskgen_flood_control_overflow"
        }
        $floodOverflow.Add($item) | Out-Null
    }
}

$finalPending = @($selectedPending.ToArray() | Sort-Object { Parse-DateUtc $_["created_at"] })

$quarantineMerged = @()
$quarantineMerged += $quarantineBaseItems
$quarantineMerged += @($generatedHighRisk.ToArray())
$quarantineMerged += @($existingRiskOverflow.ToArray())
$quarantineMerged += @($floodOverflow.ToArray())
$finalQuarantineDedup = Dedupe-ByIdOldest -Items $quarantineMerged
$finalQuarantine = @($finalQuarantineDedup.items | Sort-Object { Parse-DateUtc $_["created_at"] })

$finalPendingTaskgen = @($finalPending | Where-Object { ([string]$_.source).ToLowerInvariant() -eq "taskgen" })
$finalQuarantineTaskgen = @($finalQuarantine | Where-Object { ([string]$_.source).ToLowerInvariant() -eq "taskgen" })

$pendingTaskgenSet = @{}
foreach ($item in $finalPendingTaskgen) { $pendingTaskgenSet[[string]$item["id"]] = $true }
$quarantineTaskgenSet = @{}
foreach ($item in $finalQuarantineTaskgen) { $quarantineTaskgenSet[[string]$item["id"]] = $true }

$taskgenLast = [ordered]@{
    generated_at_utc = $generatedAtUtc
    dry_run          = [bool]$DryRun
    max_items        = $MaxItems
    since_hours      = $SinceHours
    paths            = [ordered]@{
        pending      = $pendingPath
        quarantine   = $quarantinePath
        taskgen_last = $taskgenLastPath
        taskgen_log  = $taskgenLogPath
    }
    report_inputs     = @(
        @($reportContexts.ToArray()) | ForEach-Object {
            [ordered]@{
                name           = $_.name
                path           = $_.path
                exists         = [bool]$_.exists
                parse_ok       = [bool]$_.parse_ok
                fresh          = [bool]$_.fresh
                required       = [bool]$_.required
                last_write_utc = $_.last_write_utc
                error          = $_.error
            }
        }
    )
    required_report_issues = @($contextProblems.ToArray())
    counts           = [ordered]@{
        pending_before                       = $pendingInput.Count
        quarantine_before                    = $quarantineInput.Count
        generated_candidates_total           = $generatedItems.Count
        generated_low_risk_total             = @($generatedLowRisk.ToArray()).Count
        generated_high_risk_total            = @($generatedHighRisk.ToArray()).Count
        generated_queued_visible             = $finalPendingTaskgen.Count
        generated_quarantined                = $finalQuarantineTaskgen.Count
        existing_risk_overflow_to_quarantine = @($existingRiskOverflow.ToArray()).Count
        flood_overflow_to_quarantine         = @($floodOverflow.ToArray()).Count
        pending_after                        = $finalPending.Count
        quarantine_after                     = $finalQuarantine.Count
        dedup_removed_candidates             = [int]$candidateDedup.removed_count
        dedup_removed_pending_base           = [int]$pendingBaseDedup.removed_count
        dedup_removed_quarantine_base        = [int]$quarantineBaseDedup.removed_count
        dedup_removed_quarantine_final       = [int]$finalQuarantineDedup.removed_count
    }
    queued_generated  = @($finalPendingTaskgen | ForEach-Object {
            [ordered]@{
                id             = $_["id"]
                component_id   = $_["component_id"]
                title          = $_["title"]
                risk_level     = $_["risk_level"]
                evidence_files = @($_["evidence_files"])
                reason         = $_["taskgen_reason"]
            }
        })
    quarantined_generated = @($finalQuarantineTaskgen | ForEach-Object {
            [ordered]@{
                id                = $_["id"]
                component_id      = $_["component_id"]
                title             = $_["title"]
                risk_level        = $_["risk_level"]
                quarantine_reason = $_["quarantine_reason"]
                evidence_files    = @($_["evidence_files"])
                reason            = $_["taskgen_reason"]
            }
        })
}

if (-not $DryRun) {
    Write-JsonFile -Path $pendingPath -Object $finalPending -Depth 24
    Write-JsonFile -Path $quarantinePath -Object $finalQuarantine -Depth 24
}

Write-JsonFile -Path $taskgenLastPath -Object $taskgenLast -Depth 24

foreach ($task in $generatedItems) {
    $id = [string]$task["id"]
    $outcome = "dropped"
    if ($pendingTaskgenSet.ContainsKey($id)) {
        $outcome = if ($DryRun) { "would_queue" } else { "queued" }
    }
    elseif ($quarantineTaskgenSet.ContainsKey($id)) {
        $outcome = if ($DryRun) { "would_quarantine" } else { "quarantined" }
    }

    $event = [ordered]@{
        timestamp_utc     = $generatedAtUtc
        work_order        = "WO-MASON2-TASKGEN-0001"
        dry_run           = [bool]$DryRun
        outcome           = $outcome
        id                = $task["id"]
        component_id      = $task["component_id"]
        title             = $task["title"]
        risk_level        = $task["risk_level"]
        quarantine_reason = $task["quarantine_reason"]
        reason            = $task["taskgen_reason"]
        evidence_files    = @($task["evidence_files"])
    }
    Append-JsonLine -Path $taskgenLogPath -Object $event
}

Write-TaskGenHost ("Generated candidate tasks: {0}" -f $generatedItems.Count)
Write-TaskGenHost ("Visible taskgen queued: {0}" -f $finalPendingTaskgen.Count)
Write-TaskGenHost ("Taskgen quarantined: {0}" -f $finalQuarantineTaskgen.Count)
Write-TaskGenHost ("TaskGen report: {0}" -f $taskgenLastPath)
if ($DryRun) {
    Write-TaskGenHost "Dry run completed - queue files were not modified." "WARN"
}
else {
    Write-TaskGenHost "Queue files updated."
}

exit 0
