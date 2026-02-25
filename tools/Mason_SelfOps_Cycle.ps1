param(
    [string]$RootDir = $null
)

$ErrorActionPreference = "Stop"

function Write-SelfOpsLog {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[SelfOps] [$ts] [$Level] $Message"
}

function Get-UtcIso {
    return (Get-Date).ToUniversalTime().ToString("o")
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Read-JsonFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if (-not $raw -or -not $raw.Trim()) {
        return $null
    }

    try {
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-SelfOpsLog ("Failed to parse JSON at {0}: {1}" -f $Path, $_.Exception.Message) "ERROR"
        return $null
    }
}

function Write-JsonFile {
    param(
        [string]$Path,
        [Parameter(Mandatory = $true)]$Object
    )

    $dir = Split-Path -Parent $Path
    if ($dir) { Ensure-Directory -Path $dir }

    $json = $Object | ConvertTo-Json -Depth 20
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Ensure-Array {
    param($Value)

    if ($null -eq $Value) { return @() }
    if ($Value -is [string]) { return @($Value) }
    if ($Value -is [System.Collections.IEnumerable]) { return @($Value) }
    return @($Value)
}

function Set-ObjectProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Value
    )

    if ($Object.PSObject.Properties.Name -contains $Name) {
        $Object.$Name = $Value
    }
    else {
        Add-Member -InputObject $Object -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Get-RiskRank {
    param([string]$Risk)

    if (-not $Risk) { return 0 }
    $norm = $Risk.Trim().ToUpper()
    switch ($norm) {
        "R0" { return 0 }
        "R1" { return 1 }
        "R2" { return 2 }
        "R3" { return 3 }
        default {
            if ($norm -match '(\d+)') { return [int]$Matches[1] }
            return 999
        }
    }
}

function ConvertTo-Bool {
    param(
        $Value,
        [bool]$Default = $false
    )

    if ($null -eq $Value) { return $Default }
    if ($Value -is [bool]) { return $Value }

    $text = ([string]$Value).Trim().ToLowerInvariant()
    switch ($text) {
        "1" { return $true }
        "true" { return $true }
        "yes" { return $true }
        "y" { return $true }
        "on" { return $true }
        "0" { return $false }
        "false" { return $false }
        "no" { return $false }
        "n" { return $false }
        "off" { return $false }
        default { return $Default }
    }
}

function Normalize-Component {
    param([string]$Value)

    if (-not $Value) { return $null }
    $norm = $Value.Trim().ToLowerInvariant()

    if ($norm -like "*mason*") { return "mason" }
    if ($norm -like "*athena*") { return "athena" }
    if ($norm -like "*onyx*") { return "onyx" }

    return $null
}

function Resolve-ItemComponent {
    param($Item)

    foreach ($field in @("component_id", "area", "teacher_domain", "domain")) {
        if ($Item.PSObject.Properties.Name -contains $field) {
            $mapped = Normalize-Component -Value ([string]$Item.$field)
            if ($mapped) { return $mapped }
        }
    }

    return "mason"
}

function Is-PendingLikeStatus {
    param([string]$Status)

    if (-not $Status -or -not $Status.Trim()) {
        return $true
    }

    $s = $Status.Trim().ToLowerInvariant()
    return $s -in @("pending", "queued", "queue", "new", "ready", "open", "todo", "waiting", "pending_review")
}

function Test-HasActions {
    param($Item)

    if (-not ($Item.PSObject.Properties.Name -contains "actions")) {
        return $false
    }

    $actions = $Item.actions
    if ($null -eq $actions) {
        return $false
    }

    if ($actions -is [string]) {
        return ($actions.Trim().Length -gt 0)
    }

    if ($actions -is [System.Collections.IEnumerable]) {
        foreach ($a in $actions) {
            if ($null -eq $a) { continue }
            if (([string]$a).Trim().Length -gt 0) {
                return $true
            }
        }
        return $false
    }

    return $true
}

function Build-AllowlistText {
    param($Item)

    $parts = New-Object System.Collections.Generic.List[string]
    foreach ($field in @("title", "description", "operator_summary", "domain", "area", "teacher_domain", "teacher_area", "kind")) {
        if ($Item -and ($Item.PSObject.Properties.Name -contains $field)) {
            $value = [string]$Item.$field
            if ($value.Trim()) {
                $parts.Add($value.Trim())
            }
        }
    }
    return ($parts.ToArray() -join " ").ToLowerInvariant()
}

function Test-AllowlistedScope {
    param(
        $Item,
        [string]$ComponentId
    )

    $text = Build-AllowlistText -Item $Item
    $keywords = @()

    switch (([string]$ComponentId).ToLowerInvariant()) {
        "mason" {
            $keywords = @(
                "watchdog", "governor", "self-improve", "self improve",
                "reliability", "safe", "safety", "logging", "traceability",
                "retry", "backoff", "rollback", "recovery", "guard", "resource"
            )
        }
        "athena" {
            $keywords = @(
                "operator", "console", "workflow", "approval", "notification",
                "alert", "trust", "status", "observability", "audit", "ui"
            )
        }
        "onyx" {
            $keywords = @(
                "dashboard", "task", "invoice", "crm",
                "performance", "responsive", "security", "data handling"
            )
        }
        default {
            return [pscustomobject]@{
                allowed = $false
                reason  = "unknown_component"
            }
        }
    }

    foreach ($keyword in $keywords) {
        if ($text -like ("*" + $keyword + "*")) {
            return [pscustomobject]@{
                allowed = $true
                reason  = "keyword:" + $keyword
            }
        }
    }

    return [pscustomobject]@{
        allowed = $false
        reason  = "no_allowlist_keyword_match"
    }
}

function Resolve-WhyThisHelps {
    param($Item)

    $description = ""
    if ($Item -and ($Item.PSObject.Properties.Name -contains "description")) {
        $description = [string]$Item.description
    }

    if ($description -match '(?is)why this helps:\s*(.+)$') {
        return $Matches[1].Trim()
    }

    if ($description.Trim()) {
        return $description.Trim()
    }

    return "Improves reliability and keeps changes in a controlled scope."
}

function Resolve-OperatorSummary {
    param($Item)

    if ($Item -and ($Item.PSObject.Properties.Name -contains "operator_summary")) {
        $summary = [string]$Item.operator_summary
        if ($summary.Trim()) {
            return $summary.Trim()
        }
    }

    return Resolve-WhyThisHelps -Item $Item
}

function Get-LatestAutopilotDecisionUtc {
    param($Approvals)

    $latest = $null
    foreach ($item in (Ensure-Array $Approvals)) {
        if (-not $item) { continue }
        if (([string]$item.decision_by).Trim().ToLowerInvariant() -ne "auto") { continue }
        if (-not $item.decision_at) { continue }

        $dt = [DateTime]::MinValue
        if ([DateTime]::TryParse([string]$item.decision_at, [ref]$dt)) {
            $utc = $dt.ToUniversalTime()
            if ($null -eq $latest -or $utc -gt $latest) {
                $latest = $utc
            }
        }
    }

    return $latest
}

function Append-Notification {
    param(
        [string]$NotificationsPath,
        [string]$Level,
        [string]$Message,
        $Context
    )

    $dir = Split-Path -Parent $NotificationsPath
    if ($dir) { Ensure-Directory -Path $dir }

    $entry = [ordered]@{
        timestamp = Get-UtcIso
        level     = $Level
        component = "autopilot"
        message   = $Message
        context   = $Context
    }

    Add-Content -LiteralPath $NotificationsPath -Value ($entry | ConvertTo-Json -Depth 20 -Compress) -Encoding UTF8
}

function Invoke-SmokeTest {
    param([string]$RootDir)

    $smokeScript = Join-Path $RootDir "tools\SmokeTest_Mason2.ps1"
    if (-not (Test-Path -LiteralPath $smokeScript)) {
        Write-SelfOpsLog ("Smoke test script missing: {0}" -f $smokeScript) "ERROR"
        return [pscustomobject]@{
            pass      = $false
            exit_code = 127
            report    = $null
        }
    }

    & powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $smokeScript
    $exitCode = $LASTEXITCODE

    $reportPath = Join-Path $RootDir "reports\smoke_test_latest.json"
    $report = Read-JsonFile -Path $reportPath

    return [pscustomobject]@{
        pass      = ($exitCode -eq 0)
        exit_code = $exitCode
        report    = $report
    }
}

function Invoke-ApplyExecutor {
    param(
        [string]$RootDir,
        [string]$MaxRiskLevel = "R0",
        [switch]$RequireAllowlist
    )

    $scriptPath = Join-Path $RootDir "tools\Mason_Apply_ApprovedChanges.ps1"
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-SelfOpsLog ("Executor script missing: {0}" -f $scriptPath) "ERROR"
        return 127
    }

    $args = @(
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $scriptPath,
        "-Execute",
        "-MaxRiskLevel", $MaxRiskLevel
    )
    if ($RequireAllowlist) {
        $args += "-RequireAllowlist"
    }

    & powershell @args
    return $LASTEXITCODE
}

function Invoke-RollbackExecutor {
    param([string]$RootDir)

    $scriptPath = Join-Path $RootDir "tools\Mason_Apply_ApprovedChanges.ps1"
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-SelfOpsLog ("Rollback script missing: {0}" -f $scriptPath) "ERROR"
        return 127
    }

    & powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $scriptPath -RollbackLatest
    return $LASTEXITCODE
}

function Invoke-GenerateCodexWorkOrder {
    param(
        [string]$RootDir,
        [int]$MaxItems = 25
    )

    $scriptPath = Join-Path $RootDir "tools\Codex_WorkOrder_From_Approvals.ps1"
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-SelfOpsLog ("Work-order script missing: {0}" -f $scriptPath) "ERROR"
        return [pscustomobject]@{
            ok = $false
            count = 0
            output_path = (Join-Path $RootDir "reports\codex_workorder_latest.txt")
            message = "missing_workorder_script"
        }
    }

    $resultRaw = & powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $scriptPath -RootDir $RootDir -MaxItems $MaxItems
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        return [pscustomobject]@{
            ok = $false
            count = 0
            output_path = (Join-Path $RootDir "reports\codex_workorder_latest.txt")
            message = ("workorder_script_exit_{0}" -f $exitCode)
        }
    }

    $rawText = ""
    if ($resultRaw -is [System.Array]) {
        $rawText = ($resultRaw -join "`n")
    }
    else {
        $rawText = [string]$resultRaw
    }
    $rawText = $rawText.Trim()

    if (-not $rawText) {
        return [pscustomobject]@{
            ok = $false
            count = 0
            output_path = (Join-Path $RootDir "reports\codex_workorder_latest.txt")
            message = "workorder_script_empty_output"
        }
    }

    try {
        return ($rawText | ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        return [pscustomobject]@{
            ok = $false
            count = 0
            output_path = (Join-Path $RootDir "reports\codex_workorder_latest.txt")
            message = ("workorder_parse_error: {0}" -f $_.Exception.Message)
            raw = $rawText
        }
    }
}

# -----------------------------------
# Resolve root and key paths
# -----------------------------------
if (-not $RootDir) {
    if ($PSCommandPath) {
        $RootDir = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    }
    else {
        $RootDir = "C:\Users\Chris\Desktop\Mason2"
    }
}

$stateKnowledgeDir = Join-Path $RootDir "state\knowledge"
$stateConfigDir = Join-Path $RootDir "state\config"
$approvalsPath = Join-Path $stateKnowledgeDir "pending_patch_runs.json"
$notificationsPath = Join-Path $stateKnowledgeDir "notifications.jsonl"
$autopilotPath = Join-Path $stateConfigDir "mason_autopilot.json"

Write-SelfOpsLog "=== Mason_SelfOps_Cycle starting ==="
Write-SelfOpsLog "RootDir = $RootDir"

$defaultAutopilot = [ordered]@{
    enabled                           = $true
    max_auto_risk                     = [ordered]@{
        mason  = "R1"
        athena = "R1"
        onyx   = "R0"
    }
    require_smoke_green_before_apply  = $true
    cooldown_minutes                  = 30
    max_auto_apply_per_cycle          = 10
    auto_apply_requires_actions_present = $true
}

if (-not (Test-Path -LiteralPath $autopilotPath)) {
    Write-SelfOpsLog ("Autopilot config missing. Creating default at {0}" -f $autopilotPath)
    Write-JsonFile -Path $autopilotPath -Object $defaultAutopilot
}

$autopilot = Read-JsonFile -Path $autopilotPath
if (-not $autopilot) {
    Write-SelfOpsLog "Failed to load autopilot config; aborting cycle." "ERROR"
    return
}

$enabled = ConvertTo-Bool -Value $autopilot.enabled -Default $false
if (-not $enabled) {
    Write-SelfOpsLog "Autopilot disabled via state/config/mason_autopilot.json; no action taken."
    return
}

$approvals = Ensure-Array (Read-JsonFile -Path $approvalsPath)
if ($approvals.Count -eq 0) {
    Write-SelfOpsLog "No approval records found; nothing to auto-approve."
    return
}

$maxRiskByComponent = @{
    mason  = if ($autopilot.max_auto_risk.mason) { [string]$autopilot.max_auto_risk.mason } else { "R1" }
    athena = if ($autopilot.max_auto_risk.athena) { [string]$autopilot.max_auto_risk.athena } else { "R1" }
    onyx   = if ($autopilot.max_auto_risk.onyx) { [string]$autopilot.max_auto_risk.onyx } else { "R0" }
}

$requireSmokeGreen = ConvertTo-Bool -Value $autopilot.require_smoke_green_before_apply -Default $true
$actionsRequired = ConvertTo-Bool -Value $autopilot.auto_apply_requires_actions_present -Default $true
$cooldownMinutes = 30
if ($autopilot.cooldown_minutes -ne $null) {
    $parsed = 30
    if ([int]::TryParse([string]$autopilot.cooldown_minutes, [ref]$parsed) -and $parsed -ge 0) {
        $cooldownMinutes = $parsed
    }
}
$maxPerCycle = 10
if ($autopilot.max_auto_apply_per_cycle -ne $null) {
    $parsed = 10
    if ([int]::TryParse([string]$autopilot.max_auto_apply_per_cycle, [ref]$parsed) -and $parsed -gt 0) {
        $maxPerCycle = $parsed
    }
}

$eligibleR0 = New-Object System.Collections.Generic.List[object]
$eligibleR1 = New-Object System.Collections.Generic.List[object]

foreach ($item in $approvals) {
    if (-not $item) { continue }
    if (-not $item.id) { continue }

    if (-not (Is-PendingLikeStatus -Status ([string]$item.status))) {
        continue
    }

    if ($item.PSObject.Properties.Name -contains "requires_human_approval") {
        $requiresHuman = ConvertTo-Bool -Value $item.requires_human_approval -Default $false
        if ($requiresHuman) { continue }
    }

    if ($actionsRequired -and -not (Test-HasActions -Item $item)) {
        continue
    }

    $component = Resolve-ItemComponent -Item $item
    if (-not $component) { continue }
    if ($component -notin @("mason", "athena", "onyx")) {
        continue
    }

    $maxRisk = if ($maxRiskByComponent.ContainsKey($component)) { $maxRiskByComponent[$component] } else { "R0" }
    $itemRisk = if ($item.risk_level) { [string]$item.risk_level } else { "R0" }
    $itemRiskRank = Get-RiskRank -Risk $itemRisk
    $maxRiskRank = Get-RiskRank -Risk $maxRisk

    if ($itemRiskRank -gt $maxRiskRank) {
        continue
    }

    if ($itemRiskRank -gt 1) {
        continue
    }

    $allowResult = Test-AllowlistedScope -Item $item -ComponentId $component
    if (-not $allowResult.allowed) {
        Write-SelfOpsLog ("Skipping {0} ({1}) - out of AGENTS allowlist ({2})." -f [string]$item.id, $component, $allowResult.reason) "WARN"
        continue
    }

    $entry = [pscustomobject]@{
        id           = [string]$item.id
        item         = $item
        component    = $component
        risk_label   = if ($itemRiskRank -eq 0) { "R0" } else { "R1" }
        allow_reason = $allowResult.reason
    }

    if ($itemRiskRank -eq 0) {
        $eligibleR0.Add($entry)
    }
    elseif ($itemRiskRank -eq 1) {
        $eligibleR1.Add($entry)
    }
}

if ($eligibleR0.Count -eq 0 -and $eligibleR1.Count -eq 0) {
    Write-SelfOpsLog "No eligible pending approvals matched autopilot policy this cycle."
    return
}

$lastAutoDecision = Get-LatestAutopilotDecisionUtc -Approvals $approvals
$r0ApplyAllowedByCooldown = $true
if ($eligibleR0.Count -gt 0 -and $lastAutoDecision -and $cooldownMinutes -gt 0) {
    $minutesSince = ((Get-Date).ToUniversalTime() - $lastAutoDecision).TotalMinutes
    if ($minutesSince -lt $cooldownMinutes) {
        $r0ApplyAllowedByCooldown = $false
        Write-SelfOpsLog ("Cooldown active ({0}m < {1}m). R0 auto-apply will be skipped this cycle." -f [int][Math]::Floor($minutesSince), $cooldownMinutes)
    }
}

$r0Candidates = @()
if ($r0ApplyAllowedByCooldown) {
    $r0Candidates = @($eligibleR0 | Select-Object -First $maxPerCycle)
}
$r1Candidates = @($eligibleR1)

$preSmoke = [pscustomobject]@{
    pass      = $true
    exit_code = 0
    report    = $null
}

if ($r0Candidates.Count -gt 0) {
    Write-SelfOpsLog "Running pre-apply smoke test before R0 auto-apply..."
    $preSmoke = Invoke-SmokeTest -RootDir $RootDir
    Write-SelfOpsLog ("Pre-smoke pass={0} exit_code={1}" -f $preSmoke.pass, $preSmoke.exit_code)

    if ($requireSmokeGreen -and -not $preSmoke.pass) {
        Write-SelfOpsLog "Pre-smoke is FAIL and require_smoke_green_before_apply=true; skipping R0 apply." "WARN"
        Append-Notification -NotificationsPath $notificationsPath -Level "warn" -Message "R0 auto-apply skipped; pre-smoke is not green." -Context ([ordered]@{
                r0_candidate_count = $r0Candidates.Count
                r0_candidate_ids   = @($r0Candidates | ForEach-Object { $_.id })
                pre_smoke          = [ordered]@{
                    pass      = $preSmoke.pass
                    exit_code = $preSmoke.exit_code
                    result    = if ($preSmoke.report) { $preSmoke.report.result } else { $null }
                    timestamp = if ($preSmoke.report) { $preSmoke.report.timestamp } else { $null }
                }
                skipped_reason      = "pre_smoke_failed"
            })
        $r0Candidates = @()
    }
}

$nowUtc = Get-UtcIso
$r0ApprovedIds = New-Object System.Collections.Generic.List[string]
$r1ApprovedIds = New-Object System.Collections.Generic.List[string]
$approvalsChanged = $false

foreach ($entry in $r1Candidates) {
    $item = $entry.item
    Set-ObjectProperty -Object $item -Name "status" -Value "approve"
    Set-ObjectProperty -Object $item -Name "decision_by" -Value "auto"
    Set-ObjectProperty -Object $item -Name "decision_at" -Value $nowUtc
    Set-ObjectProperty -Object $item -Name "note" -Value "auto-approved by Mason autopilot (R1 manual apply gate)"
    $r1ApprovedIds.Add([string]$entry.id)
    $approvalsChanged = $true
}

foreach ($entry in $r0Candidates) {
    $item = $entry.item
    Set-ObjectProperty -Object $item -Name "status" -Value "approve"
    Set-ObjectProperty -Object $item -Name "decision_by" -Value "auto"
    Set-ObjectProperty -Object $item -Name "decision_at" -Value $nowUtc
    Set-ObjectProperty -Object $item -Name "note" -Value "auto-approved by Mason autopilot (R0 allowlist gate)"
    $r0ApprovedIds.Add([string]$entry.id)
    $approvalsChanged = $true
}

if ($approvalsChanged) {
    Write-JsonFile -Path $approvalsPath -Object $approvals
}

Write-SelfOpsLog ("Auto-approved R0={0} and R1={1} item(s)." -f $r0ApprovedIds.Count, $r1ApprovedIds.Count)

if ($r1ApprovedIds.Count -gt 0) {
    $workOrder = Invoke-GenerateCodexWorkOrder -RootDir $RootDir -MaxItems 50
    $workOrderPath = if ($workOrder.output_path) { [string]$workOrder.output_path } else { (Join-Path $RootDir "reports\codex_workorder_latest.txt") }

    $sampleR1 = $r1Candidates | Select-Object -First 1
    $sampleSummary = if ($sampleR1) { Resolve-OperatorSummary -Item $sampleR1.item } else { "Approved R1 changes requiring operator execution." }
    $sampleWhy = if ($sampleR1) { Resolve-WhyThisHelps -Item $sampleR1.item } else { "Keeps medium-risk work human-reviewed and deterministic." }

    $runInstruction = ("Run in Codex from {0}: open reports\\codex_workorder_latest.txt and paste the work order." -f $RootDir)
    $workOrderContext = [ordered]@{
        what_it_is        = "Codex work order generated from approved R1 items"
        why_it_helps      = $sampleWhy
        risk_level        = "R1"
        operator_summary  = $sampleSummary
        approved_r1_count = $r1ApprovedIds.Count
        approved_r1_ids   = @($r1ApprovedIds)
        workorder_ok       = [bool]$workOrder.ok
        workorder_count    = if ($workOrder.count -ne $null) { [int]$workOrder.count } else { 0 }
        workorder_path     = $workOrderPath
        run_in_codex       = $runInstruction
        message            = if ($workOrder.message) { [string]$workOrder.message } else { "" }
    }

    $workOrderLevel = "error"
    $workOrderMessage = "Failed to generate Codex Work Order (R1)."
    if ($workOrder.ok) {
        $workOrderLevel = "info"
        $workOrderMessage = "Generated Codex Work Order (R1)."
    }
    Append-Notification -NotificationsPath $notificationsPath -Level $workOrderLevel -Message $workOrderMessage -Context $workOrderContext
}

if ($r0ApprovedIds.Count -eq 0) {
    Write-SelfOpsLog "No R0 approvals selected for auto-apply."
    Write-SelfOpsLog "=== Mason_SelfOps_Cycle completed ==="
    return
}

Write-SelfOpsLog "Running Mason_Apply_ApprovedChanges.ps1 -Execute -MaxRiskLevel R0 -RequireAllowlist ..."
$executorExit = Invoke-ApplyExecutor -RootDir $RootDir -MaxRiskLevel "R0" -RequireAllowlist
Write-SelfOpsLog ("Executor exit code = {0}" -f $executorExit)

Write-SelfOpsLog "Running post-apply smoke test..."
$postSmoke = Invoke-SmokeTest -RootDir $RootDir
Write-SelfOpsLog ("Post-smoke pass={0} exit_code={1}" -f $postSmoke.pass, $postSmoke.exit_code)

$shouldRollback = ($executorExit -ne 0) -or (-not $postSmoke.pass)
if ($shouldRollback) {
    $trigger = if ($executorExit -ne 0) { "executor_exit_nonzero" } else { "post_smoke_failed" }
    Write-SelfOpsLog ("Failure detected ({0}); invoking rollback." -f $trigger) "WARN"

    $rollbackExit = Invoke-RollbackExecutor -RootDir $RootDir
    Write-SelfOpsLog ("Rollback exit code = {0}" -f $rollbackExit)

    $updatedApprovals = Ensure-Array (Read-JsonFile -Path $approvalsPath)
    $rollbackAt = Get-UtcIso
    foreach ($id in $r0ApprovedIds) {
        $match = $updatedApprovals | Where-Object { $_.id -eq $id } | Select-Object -First 1
        if (-not $match) { continue }

        Set-ObjectProperty -Object $match -Name "status" -Value "rollback"
        Set-ObjectProperty -Object $match -Name "rollback_at" -Value $rollbackAt
        Set-ObjectProperty -Object $match -Name "rollback_reason" -Value ("autopilot rollback: {0}" -f $trigger)
    }
    Write-JsonFile -Path $approvalsPath -Object $updatedApprovals

    $failureContext = [ordered]@{
        auto_applied_r0_count = $r0ApprovedIds.Count
        auto_applied_r0_ids   = @($r0ApprovedIds)
        auto_approved_r1_count = $r1ApprovedIds.Count
        auto_approved_r1_ids   = @($r1ApprovedIds)
        executor_exit_code    = $executorExit
        rollback_exit_code    = $rollbackExit
        trigger               = $trigger
        pre_smoke             = [ordered]@{
            pass      = $preSmoke.pass
            exit_code = $preSmoke.exit_code
            result    = if ($preSmoke.report) { $preSmoke.report.result } else { $null }
            timestamp = if ($preSmoke.report) { $preSmoke.report.timestamp } else { $null }
        }
        post_smoke            = [ordered]@{
            pass      = $postSmoke.pass
            exit_code = $postSmoke.exit_code
            result    = if ($postSmoke.report) { $postSmoke.report.result } else { $null }
            timestamp = if ($postSmoke.report) { $postSmoke.report.timestamp } else { $null }
        }
    }

    Append-Notification -NotificationsPath $notificationsPath -Level "error" -Message "Auto-apply failed; rolled back" -Context $failureContext
    Write-SelfOpsLog "=== Mason_SelfOps_Cycle completed with rollback ===" "WARN"
    return
}

$successContext = [ordered]@{
    auto_applied_r0_count = $r0ApprovedIds.Count
    auto_applied_r0_ids   = @($r0ApprovedIds)
    auto_approved_r1_count = $r1ApprovedIds.Count
    auto_approved_r1_ids   = @($r1ApprovedIds)
    executor_exit_code    = $executorExit
    pre_smoke             = [ordered]@{
        pass      = $preSmoke.pass
        exit_code = $preSmoke.exit_code
        result    = if ($preSmoke.report) { $preSmoke.report.result } else { $null }
        timestamp = if ($preSmoke.report) { $preSmoke.report.timestamp } else { $null }
    }
    post_smoke            = [ordered]@{
        pass      = $postSmoke.pass
        exit_code = $postSmoke.exit_code
        result    = if ($postSmoke.report) { $postSmoke.report.result } else { $null }
        timestamp = if ($postSmoke.report) { $postSmoke.report.timestamp } else { $null }
    }
}

Append-Notification -NotificationsPath $notificationsPath -Level "info" -Message ("Auto-applied {0} R0 change(s)" -f $r0ApprovedIds.Count) -Context $successContext
Write-SelfOpsLog "=== Mason_SelfOps_Cycle completed ==="
