[CmdletBinding()]
param(
    # By default: DRY RUN (no backups written, no status changes)
    [switch]$Execute,
    # Explain only: produce per-item execution eligibility JSON and exit.
    [switch]$ExplainJson,
    # Roll back latest applied run using most recent component backups
    [switch]$RollbackLatest,
    # Apply mode:
    # R0 = existing behavior (all components capped at MaxRiskLevel, default R0)
    # R1 = Mason/Athena capped at R1, Onyx capped at R0
    [ValidateSet("R0", "R1")]
    [string]$Mode = "R0",
    # Max risk to execute (R0-R3). Safety default is R0.
    [string]$MaxRiskLevel = "R0",
    # Enforce AGENTS.md scope allowlists before execution.
    [switch]$RequireAllowlist
)

$ErrorActionPreference = "Stop"

function Write-ExecLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

function Read-Json {
    param(
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $text = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
    if (-not $text.Trim()) {
        return $null
    }

    try {
        return $text | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-ExecLog ("Failed to parse JSON at {0}: {1}" -f $Path, $_.Exception.Message) "WARN"
        return $null
    }
}

function Write-Json {
    param(
        [string]$Path,
        [Parameter(Mandatory = $true)]$Object
    )

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $json = $Object | ConvertTo-Json -Depth 20
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Read-JsonLines {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    $out = New-Object System.Collections.Generic.List[object]
    $lines = Get-Content -LiteralPath $Path -Encoding UTF8

    foreach ($line in $lines) {
        if (-not $line -or -not $line.Trim()) { continue }

        try {
            $out.Add(($line | ConvertFrom-Json -ErrorAction Stop))
        }
        catch {
            Write-ExecLog ("Skipping malformed JSONL entry in {0}" -f $Path) "WARN"
        }
    }

    return @($out)
}

function Append-ExecutorLog {
    param(
        [string]$Path,
        [hashtable]$Entry
    )

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $jsonLine = $Entry | ConvertTo-Json -Depth 10 -Compress
    Add-Content -LiteralPath $Path -Value $jsonLine -Encoding UTF8
}

function Get-RiskInt {
    param(
        $RiskLevel
    )

    if ($null -eq $RiskLevel) { return 0 }

    $s = [string]$RiskLevel

    if ($s -match '^\d+$') {
        return [int]$s
    }

    $m = [regex]::Match($s, '(\d+)')
    if ($m.Success) {
        return [int]$m.Groups[1].Value
    }

    switch ($s.ToLower()) {
        "observe_only" { return 0 }
        "low"          { return 1 }
        "medium"       { return 2 }
        "high"         { return 3 }
        default        { return 3 }
    }
}

function Normalize-ApprovalStatus {
    param($Value)

    $text = ([string]$Value).Trim().ToLowerInvariant()
    if (-not $text) { return "pending" }
    if ($text -eq "approved") { return "approve" }
    if ($text -eq "rejected") { return "reject" }
    return $text
}

function Get-ComponentRiskGateInt {
    param(
        [string]$ComponentId,
        [string]$Mode,
        [int]$DefaultMaxRiskInt
    )

    $modeNorm = ([string]$Mode).Trim().ToUpperInvariant()
    $cid = ([string]$ComponentId).Trim().ToLowerInvariant()

    if ($modeNorm -eq "R1") {
        if ($cid -eq "mason" -or $cid -eq "athena") {
            return [Math]::Min($DefaultMaxRiskInt, 1)
        }
        return [Math]::Min($DefaultMaxRiskInt, 0)
    }

    return $DefaultMaxRiskInt
}

function Normalize-ComponentName {
    param([string]$Value)

    $raw = [string]$Value
    if (-not $raw.Trim()) { return "" }
    $text = $raw.Trim().ToLowerInvariant()

    if ($text -like "*mason*") { return "mason" }
    if ($text -like "*athena*") { return "athena" }
    if ($text -like "*onyx*") { return "onyx" }
    return ""
}

function Resolve-ItemComponentId {
    param(
        $Item,
        [string]$Fallback = "unknown"
    )

    foreach ($field in @("component_id", "area", "teacher_domain", "domain")) {
        if ($Item -and ($Item.PSObject.Properties.Name -contains $field)) {
            $mapped = Normalize-ComponentName -Value ([string]$Item.$field)
            if ($mapped) { return $mapped }
        }
    }

    $fallbackMapped = Normalize-ComponentName -Value $Fallback
    if ($fallbackMapped) { return $fallbackMapped }
    return "unknown"
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

function Get-ExecutionAssessment {
    param(
        $Item,
        [string]$Mode,
        [int]$DefaultMaxRiskInt,
        [switch]$RequireAllowlist,
        [switch]$ExecutorAvailable = $true
    )

    $idRaw = ""
    if ($Item -and ($Item.PSObject.Properties.Name -contains "id")) {
        $idRaw = [string]$Item.id
    }
    $id = if ($idRaw.Trim()) { $idRaw.Trim() } else { "unknown" }

    $componentId = Resolve-ItemComponentId -Item $Item -Fallback ""
    if (-not $componentId) { $componentId = "unknown" }

    $statusRaw = ""
    if ($Item -and ($Item.PSObject.Properties.Name -contains "status")) {
        $statusRaw = [string]$Item.status
    }
    $statusNorm = Normalize-ApprovalStatus $statusRaw
    $isApprovedStatus = ($statusNorm -eq "approve")

    $riskRaw = ""
    if ($Item -and ($Item.PSObject.Properties.Name -contains "risk_level")) {
        $riskRaw = [string]$Item.risk_level
    }
    $riskInt = Get-RiskInt $riskRaw
    $riskLabel = if ($riskRaw.Trim()) { $riskRaw } else { "R{0}" -f $riskInt }

    $componentRiskGate = Get-ComponentRiskGateInt -ComponentId $componentId -Mode $Mode -DefaultMaxRiskInt $DefaultMaxRiskInt
    $withinRiskGate = ($riskInt -le $componentRiskGate)

    $allowResult = Test-AllowlistedScope -Item $Item -ComponentId $componentId
    $allowlisted = if ($RequireAllowlist) { [bool]$allowResult.allowed } else { $true }

    $blockedReasons = New-Object System.Collections.Generic.List[string]
    if (-not $ExecutorAvailable) { $blockedReasons.Add("missing_executor") }
    if (-not $isApprovedStatus) { $blockedReasons.Add("status_not_approved") }
    if (-not $withinRiskGate) { $blockedReasons.Add("risk_gate") }
    if ($RequireAllowlist -and -not $allowlisted) { $blockedReasons.Add("allowlist") }

    $willExecute = ($blockedReasons.Count -eq 0)

    return [pscustomobject]@{
        id                 = $id
        status             = $statusNorm
        component          = $componentId
        risk_level         = $riskLabel
        risk_int           = $riskInt
        allowlisted        = [bool]$allowlisted
        allow_reason       = [string]$allowResult.reason
        within_risk_gate   = [bool]$withinRiskGate
        component_risk_max = [int]$componentRiskGate
        will_execute       = [bool]$willExecute
        blocked_reasons    = @($blockedReasons)
        status_approved    = [bool]$isApprovedStatus
    }
}

function Resolve-ComponentConfig {
    param(
        [string]$ComponentId,
        $BackupPolicy
    )

    if (-not $BackupPolicy -or -not $BackupPolicy.components) {
        return $null
    }

    return $BackupPolicy.components."$ComponentId"
}

function Resolve-ComponentSourcePath {
    param(
        [string]$ComponentId,
        $BackupPolicy,
        [string]$Base
    )

    $comp = Resolve-ComponentConfig -ComponentId $ComponentId -BackupPolicy $BackupPolicy
    if (-not $comp) {
        return $null
    }

    $sourceRoot = $comp.source_root
    if (-not $sourceRoot) {
        return $null
    }

    return Join-Path $Base $sourceRoot
}

function Get-BackupRoot {
    param(
        $BackupPolicy,
        [string]$Base
    )

    $backupRootName = "backups"
    if ($BackupPolicy -and $BackupPolicy.backup_root) {
        $backupRootName = [string]$BackupPolicy.backup_root
    }

    return Join-Path $Base $backupRootName
}

function Get-LatestBackupForComponent {
    param(
        [string]$ComponentId,
        $BackupPolicy,
        [string]$Base
    )

    $backupRoot = Get-BackupRoot -BackupPolicy $BackupPolicy -Base $Base
    $componentRoot = Join-Path $backupRoot $ComponentId

    if (-not (Test-Path -LiteralPath $componentRoot)) {
        return $null
    }

    $latest = Get-ChildItem -Path $componentRoot -Filter "*.zip" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($latest) {
        return $latest.FullName
    }

    return $null
}

function Restore-ComponentFromBackup {
    param(
        [string]$ComponentId,
        [string]$BackupPath,
        $BackupPolicy,
        [string]$Base
    )

    if (-not (Test-Path -LiteralPath $BackupPath)) {
        Write-ExecLog ("Backup path does not exist for component '{0}': {1}" -f $ComponentId, $BackupPath) "WARN"
        return $false
    }

    $sourcePath = Resolve-ComponentSourcePath -ComponentId $ComponentId -BackupPolicy $BackupPolicy -Base $Base
    if (-not $sourcePath) {
        Write-ExecLog ("No source_root mapping for component '{0}' in backup policy; cannot restore." -f $ComponentId) "WARN"
        return $false
    }

    $targetParent = Split-Path -Parent $sourcePath
    if (-not $targetParent) {
        Write-ExecLog ("Could not resolve restore target parent for component '{0}'." -f $ComponentId) "WARN"
        return $false
    }

    if (-not (Test-Path -LiteralPath $targetParent)) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }

    Write-ExecLog ("Restoring component '{0}' from '{1}' -> '{2}'" -f $ComponentId, $BackupPath, $targetParent)

    try {
        Expand-Archive -LiteralPath $BackupPath -DestinationPath $targetParent -Force
        return $true
    }
    catch {
        Write-ExecLog ("Restore failed for component '{0}': {1}" -f $ComponentId, $_.Exception.Message) "WARN"
        return $false
    }
}

function Get-DateSortKey {
    param($Value)

    $dt = [DateTime]::MinValue
    if ([DateTime]::TryParse([string]$Value, [ref]$dt)) {
        return $dt.ToUniversalTime()
    }

    return [DateTime]::MinValue
}

function New-ComponentBackup {
    param(
        [string]$ComponentId,
        $BackupPolicy,
        [string]$Base
    )

    if (-not $BackupPolicy) {
        Write-ExecLog "No backup policy loaded - skipping backup." "WARN"
        return $null
    }

    $components = $BackupPolicy.components
    if (-not $components) {
        Write-ExecLog "backup_policy.json has no 'components' section - skipping backup." "WARN"
        return $null
    }

    $comp = $components."$ComponentId"
    if (-not $comp) {
        Write-ExecLog "No backup config for component '$ComponentId' - skipping backup." "WARN"
        return $null
    }

    $sourceRootStr = $comp.source_root
    if (-not $sourceRootStr) {
        Write-ExecLog "Component '$ComponentId' has no source_root in backup_policy.json - skipping backup." "WARN"
        return $null
    }

    if ($sourceRootStr -eq ".") {
        Write-ExecLog "Component '$ComponentId' source_root='.' - skipping full-tree backup for now." "WARN"
        return $null
    }

    $sourcePath = Join-Path $Base $sourceRootStr
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        Write-ExecLog "Source path '$sourcePath' for component '$ComponentId' not found - skipping backup." "WARN"
        return $null
    }

    $backupRootName = $BackupPolicy.backup_root
    if (-not $backupRootName) { $backupRootName = "backups" }

    $backupRoot    = Join-Path $Base $backupRootName
    $componentRoot = Join-Path $backupRoot $ComponentId

    if (-not (Test-Path -LiteralPath $componentRoot)) {
        New-Item -ItemType Directory -Path $componentRoot -Force | Out-Null
    }

    $stamp   = Get-Date -Format "yyyyMMdd_HHmmss"
    $zipName = "{0}_{1}.zip" -f $ComponentId, $stamp
    $zipPath = Join-Path $componentRoot $zipName

    Write-ExecLog "Creating backup for '$ComponentId' from '$sourcePath' -> '$zipPath'."

    try {
        Compress-Archive -Path $sourcePath -DestinationPath $zipPath -Force
    }
    catch {
        Write-ExecLog ("Failed to create backup for {0}: {1}" -f $ComponentId, $_.Exception.Message) "WARN"
        return $null
    }

    $max = $BackupPolicy.max_backups_per_component
    if (-not $max -or $max -le 0) { $max = 10 }

    try {
        $existing = Get-ChildItem -Path $componentRoot -Filter "*.zip" | Sort-Object LastWriteTime
        if ($existing.Count -gt $max) {
            $toRemove = $existing | Select-Object -First ($existing.Count - $max)
            foreach ($f in $toRemove) {
                Write-ExecLog "Pruning old backup '$($f.FullName)' for '$ComponentId'."
                Remove-Item -LiteralPath $f.FullName -Force
            }
        }
    }
    catch {
        Write-ExecLog ("Failed pruning backups for {0}: {1}" -f $ComponentId, $_.Exception.Message) "WARN"
    }

    return $zipPath
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

if ($Execute -and $RollbackLatest) {
    throw "Use either -Execute or -RollbackLatest, not both."
}
if ($ExplainJson -and $RollbackLatest) {
    throw "Use either -ExplainJson or -RollbackLatest, not both."
}
if ($ExplainJson -and $Execute) {
    throw "-ExplainJson does not apply changes. Do not combine with -Execute."
}

$modeNorm = ([string]$Mode).Trim().ToUpperInvariant()
if ($modeNorm -ne "R0" -and $modeNorm -ne "R1") {
    throw "Mode must be R0 or R1."
}

$DryRun = (-not $Execute) -or $ExplainJson
Write-ExecLog ("Mason_Apply_ApprovedChanges.ps1 starting (Mode={0} DryRun={1} ExplainJson={2} RollbackLatest={3})." -f $modeNorm, $DryRun, [bool]$ExplainJson, [bool]$RollbackLatest)

$ScriptPath = $MyInvocation.MyCommand.Path
$ToolsDir   = Split-Path -Parent $ScriptPath
$Base       = Split-Path -Parent $ToolsDir

$ConfigDir         = Join-Path $Base "config"
$StateKnowledgeDir = Join-Path $Base "state\knowledge"
$ReportsDir        = Join-Path $Base "reports"

$pendingPath      = Join-Path $StateKnowledgeDir "pending_patch_runs.json"
$backupPolicyPath = Join-Path $ConfigDir "backup_policy.json"
$riskPolicyPath   = Join-Path $ConfigDir "risk_policy.json"
$executorLogPath  = Join-Path $ReportsDir "mason_executor_log.jsonl"
$applySummaryPath = Join-Path $ReportsDir "approvals_apply_latest.json"
$explainPath      = Join-Path $ReportsDir "approvals_explain_latest.json"

$backupPolicy = Read-Json $backupPolicyPath
$riskPolicy   = Read-Json $riskPolicyPath  # reserved for future logic

if ($RollbackLatest) {
    $entries = Read-JsonLines -Path $executorLogPath

    if ($entries.Count -eq 0) {
        Write-ExecLog "No executor log entries found; rollback has nothing to restore." "WARN"
        return
    }

    $applyEntries = @($entries | Where-Object {
            $_.component_id -and
            ($_.action -eq "apply" -or -not $_.action) -and
            (-not $_.dry_run)
        })

    if ($applyEntries.Count -eq 0) {
        Write-ExecLog "No prior applied entries found in executor log; rollback skipped." "WARN"
        return
    }

    $latestRunIdEntry = $applyEntries |
        Where-Object { $_.run_id } |
        Sort-Object { Get-DateSortKey $_.executed_at } -Descending |
        Select-Object -First 1

    if ($latestRunIdEntry -and $latestRunIdEntry.run_id) {
        $selectedEntries = @($applyEntries | Where-Object { $_.run_id -eq $latestRunIdEntry.run_id })
        Write-ExecLog ("Rollback target selected by run_id={0} ({1} entries)." -f $latestRunIdEntry.run_id, $selectedEntries.Count)
    }
    else {
        $selectedEntries = @($applyEntries | Sort-Object { Get-DateSortKey $_.executed_at } -Descending | Select-Object -First 25)
        Write-ExecLog ("Rollback target selected by latest entries fallback ({0} entries)." -f $selectedEntries.Count) "WARN"
    }

    $componentMap = @{}
    foreach ($entry in ($selectedEntries | Sort-Object { Get-DateSortKey $_.executed_at } -Descending)) {
        $cid = [string]$entry.component_id
        if (-not $cid) { continue }
        if (-not $componentMap.ContainsKey($cid)) {
            $componentMap[$cid] = $entry
        }
    }

    $restoredCount = 0
    $failedCount = 0

    foreach ($cid in $componentMap.Keys) {
        $entry = $componentMap[$cid]
        $backupPath = $null

        if ($entry.backup_path -and ([string]$entry.backup_path -ne "<dry-run>") -and (Test-Path -LiteralPath ([string]$entry.backup_path))) {
            $backupPath = [string]$entry.backup_path
        }
        else {
            $backupPath = Get-LatestBackupForComponent -ComponentId $cid -BackupPolicy $backupPolicy -Base $Base
        }

        if (-not $backupPath) {
            Write-ExecLog ("No backup found to restore for component '{0}'." -f $cid) "WARN"
            $failedCount++

            Append-ExecutorLog -Path $executorLogPath -Entry ([ordered]@{
                    action       = "rollback"
                    component_id = $cid
                    success      = $false
                    reason       = "no_backup_found"
                    rollback_at  = (Get-Date).ToUniversalTime().ToString("o")
                })
            continue
        }

        $ok = Restore-ComponentFromBackup -ComponentId $cid -BackupPath $backupPath -BackupPolicy $backupPolicy -Base $Base
        if ($ok) { $restoredCount++ } else { $failedCount++ }

        Append-ExecutorLog -Path $executorLogPath -Entry ([ordered]@{
                action       = "rollback"
                component_id = $cid
                success      = $ok
                backup_path  = $backupPath
                rollback_at  = (Get-Date).ToUniversalTime().ToString("o")
            })
    }

    Write-ExecLog ("Rollback completed. restored={0}, failed={1}" -f $restoredCount, $failedCount)
    if ($failedCount -gt 0) {
        exit 2
    }

    return
}

$pending = Read-Json $pendingPath
if (-not $pending) {
    Write-ExecLog "No pending_patch_runs.json found or it is empty."
    $pending = @()
}

if (-not ($pending -is [System.Collections.IEnumerable])) {
    $pending = @($pending)
}

$utcNow    = (Get-Date).ToUniversalTime().ToString("o")
$runId     = [Guid]::NewGuid().ToString("N")
$changed   = $false
$processed = 0
$skipped   = 0
$approvedCandidates = 0
$maxRiskInt = Get-RiskInt $MaxRiskLevel
$explainRows = New-Object System.Collections.Generic.List[object]

Write-ExecLog ("Execution gate Mode={0}, MaxRiskLevel={1} (int={2}), RequireAllowlist={3}" -f $modeNorm, $MaxRiskLevel, $maxRiskInt, [bool]$RequireAllowlist)

foreach ($item in $pending) {
    if (-not $item) { continue }

    $assessment = Get-ExecutionAssessment `
        -Item $item `
        -Mode $modeNorm `
        -DefaultMaxRiskInt $maxRiskInt `
        -RequireAllowlist:$RequireAllowlist `
        -ExecutorAvailable:$true

    $explainRows.Add([ordered]@{
            id               = $assessment.id
            status           = $assessment.status
            component        = $assessment.component
            risk_level       = $assessment.risk_level
            allowlisted      = [bool]$assessment.allowlisted
            within_risk_gate = [bool]$assessment.within_risk_gate
            will_execute     = [bool]$assessment.will_execute
            blocked_reasons  = @($assessment.blocked_reasons)
        })

    if ($ExplainJson) {
        continue
    }

    if (-not $assessment.status_approved) {
        continue
    }

    $approvedCandidates++

    $id          = $assessment.id
    $componentId = $assessment.component
    $riskRaw     = $assessment.risk_level
    $riskInt     = [int]$assessment.risk_int

    $changeType = $null
    if ($item.PSObject.Properties.Name -contains "details") {
        $changeType = $item.details.change_type
    }

    if (-not $assessment.will_execute) {
        $skipped++
        $reasonText = @($assessment.blocked_reasons) -join ","
        Write-ExecLog ("Skipping '{0}' (component={1}, risk={2}) - blocked by {3}." -f $id, $componentId, $riskInt, $reasonText) "WARN"
        try {
            Append-ExecutorLog -Path $executorLogPath -Entry ([ordered]@{
                    action       = "apply_skip"
                    run_id       = $runId
                    id           = $id
                    component_id = $componentId
                    risk_level   = $riskRaw
                    risk_int     = $riskInt
                    dry_run      = $DryRun
                    reason       = "blocked"
                    blocked_reasons = @($assessment.blocked_reasons)
                    allowlisted  = [bool]$assessment.allowlisted
                    within_risk_gate = [bool]$assessment.within_risk_gate
                    component_risk_max = [int]$assessment.component_risk_max
                    allow_reason = [string]$assessment.allow_reason
                    max_risk     = $MaxRiskLevel
                    mode         = $modeNorm
                    executed_at  = $utcNow
                })
        }
        catch {
            Write-ExecLog ("Failed to append skip entry to executor log: {0}" -f $_.Exception.Message) "WARN"
        }
        continue
    }

    Write-ExecLog ("Processing approved item '{0}' (component={1}, risk={2}, change_type={3})." -f $id, $componentId, $riskInt, $changeType)
    $processed++

    $backupPath = $null
    if ($DryRun) {
        Write-ExecLog ("Dry-run: would create backup for component {0} according to backup_policy.json." -f $componentId)
        $backupPath = "<dry-run>"
    }
    else {
        $backupPath = New-ComponentBackup -ComponentId $componentId -BackupPolicy $backupPolicy -Base $Base
    }

    try {
        Append-ExecutorLog -Path $executorLogPath -Entry ([ordered]@{
                action       = "apply"
                run_id       = $runId
                id           = $id
                component_id = $componentId
                risk_level   = $riskRaw
                risk_int     = $riskInt
                change_type  = $changeType
                dry_run      = $DryRun
                mode         = $modeNorm
                backup_path  = $backupPath
                executed_at  = $utcNow
            })
    }
    catch {
        Write-ExecLog ("Failed to append to executor log: {0}" -f $_.Exception.Message) "WARN"
    }

    if ($DryRun) {
        $item.status = "approved_dry_run"

        if ($item.PSObject.Properties.Name -notcontains "last_checked") {
            Add-Member -InputObject $item -NotePropertyName "last_checked" -NotePropertyValue $utcNow
        }
        else {
            $item.last_checked = $utcNow
        }
    }
    else {
        $item.status = "executed"

        if ($item.PSObject.Properties.Name -notcontains "executed_at") {
            Add-Member -InputObject $item -NotePropertyName "executed_at" -NotePropertyValue $utcNow
        }
        else {
            $item.executed_at = $utcNow
        }
    }

    $changed = $true
}

if ($ExplainJson) {
    $rowsArray = $explainRows.ToArray()
    $summary = [ordered]@{
        total_items         = $rowsArray.Count
        will_execute_count  = @($rowsArray | Where-Object { $_.will_execute }).Count
        blocked_count       = @($rowsArray | Where-Object { -not $_.will_execute }).Count
    }
    $payload = [ordered]@{
        generated_at       = $utcNow
        mode               = $modeNorm
        max_risk_level     = $MaxRiskLevel
        require_allowlist  = [bool]$RequireAllowlist
        approvals          = $rowsArray
        summary            = $summary
    }
    Write-Json -Path $explainPath -Object $payload
    Write-ExecLog ("Explain JSON written to: {0}" -f $explainPath)
    Write-ExecLog "Explain mode complete - pending approvals were not modified."
    return
}

if ($changed -and -not $DryRun) {
    Write-ExecLog "Writing updated pending_patch_runs.json back to disk."
    Write-Json -Path $pendingPath -Object $pending
}
elseif ($changed -and $DryRun) {
    Write-ExecLog "Dry-run complete - NOT writing back pending_patch_runs.json."
}

$applySummary = [ordered]@{
    generated_at         = $utcNow
    run_id               = $runId
    mode                 = $modeNorm
    max_risk_level       = $MaxRiskLevel
    require_allowlist    = [bool]$RequireAllowlist
    dry_run              = [bool]$DryRun
    approved_candidates  = [int]$approvedCandidates
    applied_count        = [int]$processed
    skipped_count        = [int]$skipped
}
Write-Json -Path $applySummaryPath -Object $applySummary
Write-ExecLog ("Apply summary JSON written to: {0}" -f $applySummaryPath)

if ($processed -eq 0) {
    Write-ExecLog "No approved items found to process under current gates."
}
else {
    Write-ExecLog ("Processed {0} approved item(s). Skipped {1} approved item(s)." -f $processed, $skipped)
}

Write-ExecLog "Mason_Apply_ApprovedChanges.ps1 finished."
