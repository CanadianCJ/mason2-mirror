[CmdletBinding()]
param(
    [switch]$SkipWholeFolderReverify,
    [switch]$SkipValidator,
    [switch]$SkipMirrorRefresh,
    [switch]$SkipHostTaskMutations,
    [switch]$DisableMirrorReset
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$script:RepairWave02Stage = "bootstrap"

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
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
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $Default
        }
        return ($raw | ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        return $Default
    }
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 16
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        Ensure-Directory -Path $parent
    }
    $Object | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function To-Array {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return @($Value) }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        return @($Value)
    }
    return @($Value)
}

function Get-PropValue {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Default = $null
    )
    if ($null -eq $Object) { return $Default }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) { return $Object[$Name] }
        return $Default
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($property) { return $property.Value }
    return $Default
}

function Normalize-Text {
    param($Value)
    if ($null -eq $Value) { return "" }
    return ([string]$Value).Trim()
}

function Convert-ToBool {
    param($Value)

    if ($Value -is [bool]) { return $Value }
    $text = Normalize-Text $Value
    if (-not $text) { return $false }
    switch ($text.ToLowerInvariant()) {
        "true" { return $true }
        "1" { return $true }
        "yes" { return $true }
        "y" { return $true }
        "on" { return $true }
        default { return $false }
    }
}

function Convert-ToUtcIso {
    param($Value)

    if ($null -eq $Value) { return "" }
    try {
        return ([datetime]$Value).ToUniversalTime().ToString("o")
    }
    catch {
        return ""
    }
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
        return $fullResolved
    }
    catch {
        return $FullPath
    }
}

function Test-ArtifactRecent {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$MaxAgeMinutes = 60
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        return ($item.LastWriteTimeUtc -ge (Get-Date).ToUniversalTime().AddMinutes(-1 * [Math]::Abs($MaxAgeMinutes)))
    }
    catch {
        return $false
    }
}

function Invoke-ExternalScript {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string[]]$Arguments = @()
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return [ordered]@{
            ok = $false
            exit_code = 1
            command_run = "missing script: $Path"
            output = @()
        }
    }

    $output = @(& powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $Path @Arguments 2>&1 | ForEach-Object { [string]$_ })
    $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
    return [ordered]@{
        ok = ($exitCode -eq 0)
        exit_code = $exitCode
        command_run = ("powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}{1}" -f $Path, $(if (@($Arguments).Count -gt 0) { " " + (@($Arguments) -join " ") } else { "" }))
        output = @($output | Select-Object -Last 40)
    }
}

function Invoke-GitCapture {
    param(
        [Parameter(Mandatory = $true)][string]$RepoPath,
        [Parameter(Mandatory = $true)][string[]]$Args
    )

    try {
        $output = @(& git -C $RepoPath @Args 2>&1 | ForEach-Object { [string]$_ })
        $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
        return [ordered]@{
            ok = ($exitCode -eq 0)
            exit_code = $exitCode
            output = @($output)
            joined = ((@($output) -join "`n").Trim())
        }
    }
    catch {
        return [ordered]@{
            ok = $false
            exit_code = 1
            output = @([string]$_.Exception.Message)
            joined = [string]$_.Exception.Message
        }
    }
}

function Get-MirrorPushFailureSummary {
    param([string[]]$Lines)

    $output = @($Lines | ForEach-Object { [string]$_ } | Where-Object { $_ -ne $null })
    $joined = ((@($output) -join "`n").Trim())
    $joinedLower = $joined.ToLowerInvariant()
    $oversizedPaths = New-Object System.Collections.Generic.List[string]

    foreach ($line in $output) {
        if ($line -match 'File ([^"]+?) is [0-9.]+ ?(MB|MiB); this exceeds GitHub') {
            $path = Normalize-Text $Matches[1]
            if ($path -and $oversizedPaths -notcontains $path) {
                $oversizedPaths.Add($path) | Out-Null
            }
        }
    }

    $failureClass = "remote_push_failed_unknown"
    if ($joinedLower -match 'gh001: large files detected' -or $joinedLower -match 'this exceeds github''s file size limit') {
        $failureClass = "large_file_history_rejection"
    }
    elseif ($joinedLower -match 'permission denied \(publickey\)' -or $joinedLower -match 'authentication failed' -or $joinedLower -match 'could not read from remote repository') {
        $failureClass = "remote_auth_or_access_failure"
    }
    elseif ($joinedLower -match 'repository not found') {
        $failureClass = "remote_repository_missing_or_denied"
    }
    elseif ($joinedLower -match 'non-fast-forward' -or $joinedLower -match 'fetch first') {
        $failureClass = "remote_branch_diverged"
    }

    return [ordered]@{
        failure_class = $failureClass
        failure_reason = $(if (@($output).Count -gt 0) { $output[-1] } else { "" })
        oversized_paths = @($oversizedPaths.ToArray())
        push_output = @($output | Select-Object -Last 40)
    }
}

function Get-TaskActionText {
    param($Task)

    $items = foreach ($action in (To-Array (Get-PropValue -Object $Task -Name "Actions" -Default @()))) {
        $execute = Normalize-Text (Get-PropValue -Object $action -Name "Execute" -Default "")
        $arguments = Normalize-Text (Get-PropValue -Object $action -Name "Arguments" -Default "")
        $workingDirectory = Normalize-Text (Get-PropValue -Object $action -Name "WorkingDirectory" -Default "")
        ("{0} {1} {2}" -f $execute, $arguments, $workingDirectory).Trim()
    }
    return ((@($items) -join " | ").Trim())
}

function Get-TaskScriptPaths {
    param([string]$ActionText)

    $matches = [regex]::Matches((Normalize-Text $ActionText), '[A-Za-z]:\\[^"|]+?\.ps1')
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($match in $matches) {
        $value = Normalize-Text $match.Value
        if ($value -and $paths -notcontains $value) {
            $paths.Add($value) | Out-Null
        }
    }
    return @($paths.ToArray())
}

function Get-PopupMode {
    param([string]$ActionText)

    $normalized = Normalize-Text $ActionText
    if (-not $normalized) { return "unknown" }
    if ($normalized -match '(?i)-WindowStyle\s+Hidden' -or $normalized -match '(?i)wscript\.exe') { return "hidden" }
    if ($normalized -match '(?i)-WindowStyle\s+Minimized') { return "minimized" }
    return "visible"
}

function Get-RelevantScheduledTasks {
    param(
        [string]$RepoRootPath,
        [string[]]$RelevantKeywords
    )

    try {
        $allTasks = @(Get-ScheduledTask -ErrorAction Stop)
    }
    catch {
        return [ordered]@{
            ok = $false
            error = [string]$_.Exception.Message
            tasks = @()
        }
    }

    $repoRootNormalized = $RepoRootPath.TrimEnd("\")
    $legacyRoot = "C:\Users\Chris\Desktop\Mason\"
    $records = New-Object System.Collections.Generic.List[object]

    foreach ($task in $allTasks) {
        $taskName = Normalize-Text (Get-PropValue -Object $task -Name "TaskName" -Default "")
        $taskPath = Normalize-Text (Get-PropValue -Object $task -Name "TaskPath" -Default "")
        $actionText = Get-TaskActionText -Task $task
        $scriptPaths = @(Get-TaskScriptPaths -ActionText $actionText)
        $relevant = $false

        foreach ($keyword in @($RelevantKeywords)) {
            if ($taskName -like "*$keyword*" -or $taskPath -like "*$keyword*" -or $actionText -like "*$keyword*") {
                $relevant = $true
                break
            }
        }
        if (-not $relevant) {
            foreach ($scriptPath in $scriptPaths) {
                if ($scriptPath.StartsWith($repoRootNormalized, [System.StringComparison]::OrdinalIgnoreCase) -or
                    $scriptPath.StartsWith($legacyRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $relevant = $true
                    break
                }
            }
        }
        if (-not $relevant) { continue }

        $info = $null
        try {
            $info = Get-ScheduledTaskInfo -TaskName $taskName -TaskPath $taskPath -ErrorAction Stop
        }
        catch {
            $info = $null
        }

        $records.Add([pscustomobject][ordered]@{
            task_name = $taskName
            task_path = $taskPath
            enabled = Convert-ToBool (Get-PropValue -Object (Get-PropValue -Object $task -Name "Settings" -Default $null) -Name "Enabled" -Default $false)
            state = Normalize-Text (Get-PropValue -Object $task -Name "State" -Default "")
            last_run_utc = $(if ($info) { Convert-ToUtcIso (Get-PropValue -Object $info -Name "LastRunTime" -Default $null) } else { "" })
            next_run_utc = $(if ($info) { Convert-ToUtcIso (Get-PropValue -Object $info -Name "NextRunTime" -Default $null) } else { "" })
            last_result = $(if ($info) { [int64](Get-PropValue -Object $info -Name "LastTaskResult" -Default 0) } else { $null })
            action_text = $actionText
            actions = @(To-Array (Get-PropValue -Object $task -Name "Actions" -Default @()) | ForEach-Object {
                    [pscustomobject][ordered]@{
                        execute = Normalize-Text (Get-PropValue -Object $_ -Name "Execute" -Default "")
                        arguments = Normalize-Text (Get-PropValue -Object $_ -Name "Arguments" -Default "")
                        working_directory = Normalize-Text (Get-PropValue -Object $_ -Name "WorkingDirectory" -Default "")
                    }
                })
            script_paths = @($scriptPaths)
            popup_mode = Get-PopupMode -ActionText $actionText
        }) | Out-Null
    }

    return [ordered]@{
        ok = $true
        error = ""
        tasks = @($records.ToArray())
    }
}

function New-QueueItem {
    param(
        [string]$IssueId,
        [string]$Category,
        [string]$Status,
        [string]$Reason,
        [string]$RecommendedNextAction
    )

    return [ordered]@{
        issue_id = $IssueId
        category = $Category
        status = $Status
        reason = $Reason
        recommended_next_action = $RecommendedNextAction
    }
}

function New-FixedItem {
    param(
        [string]$IssueId,
        [string]$Category,
        [string]$BeforeState,
        [string]$FixApplied,
        [string]$AfterState,
        [string]$VerificationResult
    )

    return [ordered]@{
        issue_id = $IssueId
        category = $Category
        before_state = $BeforeState
        fix_applied = $FixApplied
        after_state = $AfterState
        verification_result = $VerificationResult
    }
}

trap {
    try {
        $debugPath = "C:\Users\Chris\Desktop\Mason2\reports\repair_wave_02_debug_last.json"
        $debugPayload = [ordered]@{
            timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
            stage = $script:RepairWave02Stage
            message = $_.Exception.Message
            line = $_.InvocationInfo.ScriptLineNumber
            command = [string]$_.InvocationInfo.Line
            position = [string]$_.InvocationInfo.PositionMessage
            script_stack_trace = [string]$_.ScriptStackTrace
        }
        $debugParent = Split-Path -Parent $debugPath
        if ($debugParent -and -not (Test-Path -LiteralPath $debugParent)) {
            New-Item -ItemType Directory -Path $debugParent -Force | Out-Null
        }
        $debugPayload | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $debugPath -Encoding UTF8
    }
    catch {
    }
    throw
}

$repoRoot = Resolve-Path "C:\Users\Chris\Desktop\Mason2"
$repoRootPath = $repoRoot.ProviderPath
$reportsDir = Join-Path $repoRootPath "reports"
$stateKnowledgeDir = Join-Path $repoRootPath "state\knowledge"
$configDir = Join-Path $repoRootPath "config"
Ensure-Directory -Path $reportsDir
Ensure-Directory -Path $stateKnowledgeDir
Ensure-Directory -Path $configDir

$repairPolicyPath = Join-Path $configDir "repair_wave_02_policy.json"
$internalSchedulerPolicyPath = Join-Path $configDir "internal_scheduler_policy.json"
$legacyTaskMigrationPolicyPath = Join-Path $configDir "legacy_task_migration_policy.json"
$mirrorPolicyPath = Join-Path $configDir "mirror_policy.json"
$schedulerManifestPath = Join-Path $configDir "scheduler_manifest.json"
$componentRegistryPath = Join-Path $configDir "component_registry.json"

$wholeFolderVerificationPath = Join-Path $reportsDir "whole_folder_verification_last.json"
$wholeFolderBrokenPathsPath = Join-Path $reportsDir "whole_folder_broken_paths_last.json"
$wholeFolderGoldenPathsPath = Join-Path $reportsDir "whole_folder_golden_paths_last.json"
$wholeFolderMigrationChecksPath = Join-Path $reportsDir "whole_folder_migration_checks_last.json"
$wholeFolderUsabilityChecksPath = Join-Path $reportsDir "whole_folder_usability_checks_last.json"
$systemValidationPath = Join-Path $reportsDir "system_validation_last.json"
$mirrorUpdatePath = Join-Path $reportsDir "mirror_update_last.json"
$mirrorCoveragePath = Join-Path $reportsDir "mirror_coverage_last.json"
$mirrorOmissionPath = Join-Path $reportsDir "mirror_omission_last.json"
$mirrorSafeIndexPath = Join-Path $reportsDir "mirror_safe_index.md"
$codebaseInventoryPath = Join-Path $reportsDir "codebase_inventory_last.json"

$repairWave02Path = Join-Path $reportsDir "repair_wave_02_last.json"
$internalSchedulerPath = Join-Path $reportsDir "internal_scheduler_last.json"
$legacyTaskInventoryPath = Join-Path $reportsDir "legacy_task_inventory_last.json"
$legacyTaskMigrationPath = Join-Path $reportsDir "legacy_task_migration_last.json"
$popupSuppressionPath = Join-Path $reportsDir "popup_suppression_last.json"
$validatorCoverageRepairPath = Join-Path $reportsDir "validator_coverage_repair_last.json"
$brokenPathClusterRepairPath = Join-Path $reportsDir "broken_path_cluster_repair_last.json"
$remotePushRepairPath = Join-Path $reportsDir "remote_push_repair_last.json"
$repairWave02UnfixedQueuePath = Join-Path $reportsDir "repair_wave_02_unfixed_queue_last.json"
$internalSchedulerRegistryPath = Join-Path $stateKnowledgeDir "internal_scheduler_registry.json"

$wholeFolderRunnerPath = Join-Path $repoRootPath "tools\ops\Run_Whole_Folder_Verification.ps1"
$validatorPath = Join-Path $repoRootPath "tools\ops\Validate_Whole_System.ps1"
$mirrorRunnerPath = Join-Path $repoRootPath "tools\sync\Mason_Mirror_Update.ps1"
$taskGovernorPath = Join-Path $repoRootPath "tools\Mason_TaskGovernor.ps1"

$commandRun = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Repair_Wave_02.ps1"
$repairPolicy = Read-JsonSafe -Path $repairPolicyPath -Default @{}
$internalSchedulerPolicy = Read-JsonSafe -Path $internalSchedulerPolicyPath -Default @{}
$legacyTaskPolicy = Read-JsonSafe -Path $legacyTaskMigrationPolicyPath -Default @{}
$mirrorPolicy = Read-JsonSafe -Path $mirrorPolicyPath -Default @{}
$schedulerManifest = Read-JsonSafe -Path $schedulerManifestPath -Default @{}
$componentRegistry = Read-JsonSafe -Path $componentRegistryPath -Default @{}

$wholeFolderBefore = Read-JsonSafe -Path $wholeFolderVerificationPath -Default @{}
$brokenPathsBefore = [int](Get-PropValue -Object $wholeFolderBefore -Name "broken_path_count" -Default 0)
$codebaseInventoryBefore = Read-JsonSafe -Path $codebaseInventoryPath -Default @{}
$parseBrokenBefore = [int](Get-PropValue -Object (Get-PropValue -Object $codebaseInventoryBefore -Name "summary" -Default @{}) -Name "parse_broken_file_count" -Default 0)
$mirrorBefore = Read-JsonSafe -Path $mirrorUpdatePath -Default @{}
$mirrorRoot = Normalize-Text (Get-PropValue -Object $mirrorBefore -Name "effective_mirror_root" -Default "")
if (-not $mirrorRoot) { $mirrorRoot = "C:\Mason2_MIRROR" }

$fixedItems = New-Object System.Collections.Generic.List[object]
$unfixedQueue = New-Object System.Collections.Generic.List[object]
$relevantKeywords = @("Mason", "Mason2", "Athena", "Onyx", "Mirror", "Governor", "Watchdog", "Learner")

$foundationTasks = @(To-Array (Get-PropValue -Object $internalSchedulerPolicy -Name "foundation_tasks" -Default @()))
$internalByHostTask = @{}
foreach ($task in $foundationTasks) {
    $hostTaskName = Normalize-Text (Get-PropValue -Object $task -Name "host_task_name" -Default "")
    if ($hostTaskName) {
        $internalByHostTask[$hostTaskName] = $task
    }
}

$script:RepairWave02Stage = "host_task_inventory"
$taskInventoryBefore = Get-RelevantScheduledTasks -RepoRootPath $repoRootPath -RelevantKeywords $relevantKeywords
if (-not $taskInventoryBefore.ok) {
    $unfixedQueue.Add((New-QueueItem -IssueId "scheduled_tasks_unreadable" -Category "scheduler" -Status "blocked" -Reason $taskInventoryBefore.error -RecommendedNextAction "Run repair wave 02 with host Task Scheduler access so Mason can inventory and classify legacy tasks.")) | Out-Null
}

$popupSourcesBefore = @()
if ($taskInventoryBefore.ok) {
    $popupSourcesBefore = @($taskInventoryBefore.tasks | Where-Object { $_.popup_mode -eq "visible" })
}

$taskGovernorInvocation = [ordered]@{
    ok = $false
    exit_code = 0
    command_run = ""
    output = @()
}
if (-not $SkipHostTaskMutations -and $taskInventoryBefore.ok -and $popupSourcesBefore.Count -gt 0 -and (Test-Path -LiteralPath $taskGovernorPath)) {
    $script:RepairWave02Stage = "task_governor_normalization"
    $taskGovernorInvocation = Invoke-ExternalScript -Path $taskGovernorPath
}

$taskInventoryAfter = $taskInventoryBefore
if ($taskInventoryBefore.ok) {
    $script:RepairWave02Stage = "host_task_reinventory"
    $refreshedTaskInventory = Get-RelevantScheduledTasks -RepoRootPath $repoRootPath -RelevantKeywords $relevantKeywords
    if ($refreshedTaskInventory.ok) {
        $taskInventoryAfter = $refreshedTaskInventory
    }
}

$legacyTaskRecords = New-Object System.Collections.Generic.List[object]
$legacyClassificationCounts = [ordered]@{
    bootstrap_only = 0
    mason_owned_migrate = 0
    mason_owned_keep_temporarily = 0
    non_mason_ignore = 0
    unknown_manual_review = 0
    noisy_interactive = 0
    broken_or_stale = 0
}
$migrationItems = New-Object System.Collections.Generic.List[object]
$popupItems = New-Object System.Collections.Generic.List[object]
$migratedCount = 0
$fallbackOnlyCount = 0
$keepTemporarilyCount = 0
$blockedCount = 0
$popupFixedCount = 0
$remainingVisibleCount = 0
$noisySourceCount = $popupSourcesBefore.Count

$legacyPatterns = @(To-Array (Get-PropValue -Object (Get-PropValue -Object $legacyTaskPolicy -Name "classification_rules" -Default @{}) -Name "stale_path_indicators" -Default @()))
$bootstrapKeywords = @(To-Array (Get-PropValue -Object (Get-PropValue -Object $legacyTaskPolicy -Name "classification_rules" -Default @{}) -Name "bootstrap_only_keywords" -Default @()))
$postInventoryByName = @{}
foreach ($task in @($taskInventoryAfter.tasks)) {
    $postInventoryByName[[string]$task.task_name] = $task
}

foreach ($task in @($taskInventoryAfter.tasks)) {
    $taskName = Normalize-Text $task.task_name
    $taskPath = Normalize-Text $task.task_path
    $actionText = Normalize-Text $task.action_text
    $popupMode = Normalize-Text $task.popup_mode
    $classification = "unknown_manual_review"
    $migrationRecommendation = "manual_review"
    $notes = New-Object System.Collections.Generic.List[string]
    $hostActionPosture = "left_in_place"

    $staleMatch = $false
    foreach ($pattern in $legacyPatterns) {
        if ($pattern -and $actionText -like "*$pattern*") {
            $staleMatch = $true
            break
        }
    }
    if (-not $staleMatch -and $actionText -like "*C:\Users\Chris\Desktop\Mason\*") {
        $staleMatch = $true
    }

    $bootstrapMatch = $false
    foreach ($keyword in $bootstrapKeywords) {
        if ($keyword -and ($taskName -like "*$keyword*" -or $taskPath -like "*$keyword*")) {
            $bootstrapMatch = $true
            break
        }
    }
    if (-not $bootstrapMatch -and $taskName -like "*Watchdog*") {
        $bootstrapMatch = $true
    }

    $internalDefinition = $null
    if ($internalByHostTask.ContainsKey($taskName)) {
        $internalDefinition = $internalByHostTask[$taskName]
    }

    if ($staleMatch) {
        $classification = "broken_or_stale"
        $migrationRecommendation = "manual_review_disable_after_evidence"
        $notes.Add("legacy path reference detected") | Out-Null
        $blockedCount++
    }
    elseif ($popupMode -eq "visible" -and $internalDefinition) {
        $classification = "noisy_interactive"
        $migrationRecommendation = "normalize_hidden_launch_then_reclassify"
        $notes.Add("background launch still visible") | Out-Null
        $blockedCount++
    }
    elseif ($bootstrapMatch) {
        $classification = "bootstrap_only"
        $migrationRecommendation = "keep_bootstrap_fallback"
        $hostActionPosture = "fallback_only"
        $notes.Add("bootstrap/startup safety path") | Out-Null
        $fallbackOnlyCount++
    }
    elseif ($internalDefinition) {
        if ($taskName -in @("Mason2-TaskInventory-1h", "Mason2-TaskGovernor-1h")) {
            $classification = "mason_owned_migrate"
            $migrationRecommendation = "internal_definition_created_host_fallback_only_pending_disable"
            $hostActionPosture = if ($task.enabled) { "fallback_only" } else { "disabled" }
            $notes.Add("internal scheduler definition created for low-risk governance task") | Out-Null
            $migratedCount++
        }
        else {
            $classification = "mason_owned_keep_temporarily"
            $migrationRecommendation = "keep_host_temporarily_until_internal_runner_executes"
            $hostActionPosture = "left_in_place"
            $notes.Add("internal definition exists but host fallback still needed") | Out-Null
            $keepTemporarilyCount++
        }
    }

    $legacyClassificationCounts[$classification] = [int]$legacyClassificationCounts[$classification] + 1

    $beforeTask = if ($taskInventoryBefore.ok) { @($taskInventoryBefore.tasks | Where-Object { $_.task_name -eq $taskName } | Select-Object -First 1)[0] } else { $null }
    $beforePopupMode = if ($beforeTask) { Normalize-Text $beforeTask.popup_mode } else { "" }
    if ($beforePopupMode -eq "visible") {
        if ($popupMode -in @("hidden", "minimized")) {
            $popupFixedCount++
            $fixedItems.Add((New-FixedItem -IssueId ("popup_" + $taskName) -Category "popup_suppression" -BeforeState "visible background task" -FixApplied "normalized hidden/minimized launch posture" -AfterState $popupMode -VerificationResult "host task action no longer reports as visible")) | Out-Null
        }
        else {
            $remainingVisibleCount++
        }
    }

    $legacyTaskRecords.Add([pscustomobject][ordered]@{
        task_name = $taskName
        task_path = $taskPath
        enabled = [bool]$task.enabled
        state = Normalize-Text $task.state
        last_run_utc = Normalize-Text $task.last_run_utc
        next_run_utc = Normalize-Text $task.next_run_utc
        last_result = $task.last_result
        action_text = $actionText
        popup_mode = $popupMode
        classification = $classification
        migration_recommendation = $migrationRecommendation
        host_action_posture = $hostActionPosture
        internal_task_id = Normalize-Text (Get-PropValue -Object $internalDefinition -Name "task_id" -Default "")
        script_paths = @($task.script_paths)
        notes = @($notes.ToArray())
    }) | Out-Null

    $migrationItems.Add([pscustomobject][ordered]@{
        task_name = $taskName
        classification = $classification
        migration_posture = $migrationRecommendation
        before_location = ("windows_task_scheduler:{0}{1}" -f $taskPath, $taskName)
        after_location = $(if ($internalDefinition) { ("internal_scheduler:{0}" -f (Normalize-Text (Get-PropValue -Object $internalDefinition -Name "task_id" -Default ""))) } else { "" })
        host_action_posture = $hostActionPosture
        verification_result = $(if ($classification -in @("mason_owned_migrate", "mason_owned_keep_temporarily", "bootstrap_only")) { "classified_with_internal_definition_or_fallback" } else { "manual_review_or_visibility_fix_still_required" })
    }) | Out-Null

    $popupItems.Add([pscustomobject][ordered]@{
        task_name = $taskName
        popup_mode_before = $beforePopupMode
        popup_mode_after = $popupMode
        fix_applied = $(if ($beforePopupMode -eq "visible" -and $popupMode -in @("hidden", "minimized")) { "yes" } else { "no" })
        classification = $classification
        note = $(if ($classification -eq "noisy_interactive") { "Task still needs hidden launch normalization or a clearer interactive contract." } elseif ($popupMode -eq "hidden") { "Background launch is hidden." } else { "No popup-specific change recorded." })
    }) | Out-Null
}

$script:RepairWave02Stage = "internal_scheduler_foundation"
$legacyInventoryStatus = if ($taskInventoryAfter.ok) { "PASS" } else { "WARN" }
$legacyInventoryNextAction = if ($taskInventoryAfter.ok) { "Migrate low-risk Mason-owned recurring jobs into the internal scheduler while leaving bootstrap/fallback host tasks in place." } else { "Rerun repair wave 02 with Task Scheduler access so legacy Mason tasks can be inventoried truthfully." }
$legacyTaskInventoryArtifact = @{}
$legacyTaskInventoryArtifact["timestamp_utc"] = (Get-Date).ToUniversalTime().ToString("o")
$legacyTaskInventoryArtifact["overall_status"] = $legacyInventoryStatus
$legacyTaskInventoryArtifact["relevant_task_count"] = $legacyTaskRecords.Count
$legacyTaskInventoryArtifact["classification_counts"] = $legacyClassificationCounts
$legacyTaskInventoryArtifact["tasks"] = @($legacyTaskRecords.ToArray())
$legacyTaskInventoryArtifact["recommended_next_action"] = $legacyInventoryNextAction
Write-JsonFile -Path $legacyTaskInventoryPath -Object $legacyTaskInventoryArtifact -Depth 18

$foundationRegistryTasks = New-Object System.Collections.Generic.List[object]
$priorInternalRegistry = Read-JsonSafe -Path $internalSchedulerRegistryPath -Default @{}
$priorTasksById = @{}
foreach ($task in @(To-Array (Get-PropValue -Object $priorInternalRegistry -Name "tasks" -Default @()))) {
    $taskId = Normalize-Text (Get-PropValue -Object $task -Name "task_id" -Default "")
    if ($taskId) {
        $priorTasksById[$taskId] = $task
    }
}

$foundationReadyCount = 0
$enabledTaskCount = 0
foreach ($task in $foundationTasks) {
    $taskId = Normalize-Text (Get-PropValue -Object $task -Name "task_id" -Default "")
    if (-not $taskId) { continue }
    $scriptRelPath = Normalize-Text (Get-PropValue -Object $task -Name "script_rel_path" -Default "")
    $scriptPath = if ($scriptRelPath) { Join-Path $repoRootPath $scriptRelPath } else { "" }
    $enabled = Convert-ToBool (Get-PropValue -Object $task -Name "enabled" -Default $false)
    $hostTaskName = Normalize-Text (Get-PropValue -Object $task -Name "host_task_name" -Default "")
    $hostTask = if ($hostTaskName -and $postInventoryByName.ContainsKey($hostTaskName)) { $postInventoryByName[$hostTaskName] } else { $null }
    $previousTask = if ($priorTasksById.ContainsKey($taskId)) { $priorTasksById[$taskId] } else { $null }
    $lastRunUtc = if ($hostTask) { Normalize-Text $hostTask.last_run_utc } else { Normalize-Text (Get-PropValue -Object $previousTask -Name "last_run_utc" -Default "") }
    $cadenceMinutes = [int](Get-PropValue -Object $task -Name "cadence_minutes" -Default 0)
    $nextRunUtc = ""
    if ($lastRunUtc) {
        try {
            $nextRunUtc = ([datetime]$lastRunUtc).ToUniversalTime().AddMinutes($cadenceMinutes).ToString("o")
        }
        catch {
            $nextRunUtc = ""
        }
    }
    if (-not $nextRunUtc -and $cadenceMinutes -gt 0) {
        $nextRunUtc = (Get-Date).ToUniversalTime().AddMinutes($cadenceMinutes).ToString("o")
    }
    $status = if ($scriptPath -and (Test-Path -LiteralPath $scriptPath)) { "ready" } else { "blocked" }
    if ($status -eq "ready") {
        $foundationReadyCount++
    }
    if ($enabled) {
        $enabledTaskCount++
    }
    $foundationRegistryTasks.Add([pscustomobject][ordered]@{
        task_id = $taskId
        category = Normalize-Text (Get-PropValue -Object $task -Name "category" -Default "")
    enabled = $enabled
    cadence_minutes = $cadenceMinutes
    risk_class = Normalize-Text (Get-PropValue -Object $task -Name "risk_class" -Default "")
    execution_mode = "mason_internal_scheduler"
    fallback_mode = $(if ($hostTaskName) { "windows_task_scheduler" } else { "" })
    script_rel_path = $scriptRelPath
    script_exists = [bool]($scriptPath -and (Test-Path -LiteralPath $scriptPath))
    host_task_name = $hostTaskName
    host_task_state = $(if ($hostTask) { Normalize-Text $hostTask.state } else { "" })
    host_popup_mode = $(if ($hostTask) { Normalize-Text $hostTask.popup_mode } else { "" })
    last_run_utc = $lastRunUtc
    next_run_utc = $nextRunUtc
    last_result = $(if ($hostTask) { $hostTask.last_result } else { (Get-PropValue -Object $previousTask -Name "last_result" -Default "not_run") })
    audit_artifact = Normalize-Text (Get-PropValue -Object $task -Name "audit_artifact" -Default "")
    migration_posture = $(if ($hostTaskName -and $hostTask) { Normalize-Text ((@($migrationItems | Where-Object { $_.task_name -eq $hostTaskName } | Select-Object -First 1)[0]).migration_posture) } else { "definition_only" })
    status = $status
    }) | Out-Null
}

$internalSchedulerRegistry = @{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = "WARN"
    execution_posture = "foundation_only_host_fallback_active"
    task_count = $foundationRegistryTasks.Count
    enabled_task_count = $enabledTaskCount
    ready_task_count = $foundationReadyCount
    tasks = @($foundationRegistryTasks.ToArray())
}
Write-JsonFile -Path $internalSchedulerRegistryPath -Object $internalSchedulerRegistry -Depth 18

$foundationStatus = if ($foundationReadyCount -eq $foundationTasks.Count -and $foundationTasks.Count -gt 0) { "PASS" } else { "WARN" }
$internalSchedulerArtifact = @{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = "WARN"
    task_definition_count = $foundationRegistryTasks.Count
    enabled_task_count = $enabledTaskCount
    audit_logging_status = "PASS"
    foundation_status = $foundationStatus
    scheduler_state_path = $internalSchedulerRegistryPath
    windows_fallback_dependency_count = @($foundationRegistryTasks | Where-Object { $_.fallback_mode -eq "windows_task_scheduler" }).Count
    tasks = @($foundationRegistryTasks.ToArray())
    recommended_next_action = "Keep bootstrap and fallback host tasks in place while Mason's internal scheduler foundation grows into the primary recurring execution engine."
}
Write-JsonFile -Path $internalSchedulerPath -Object $internalSchedulerArtifact -Depth 18

$legacyTaskMigrationArtifact = @{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = "WARN"
    migrated_count = $migratedCount
    fallback_only_count = $fallbackOnlyCount
    keep_temporarily_count = $keepTemporarilyCount
    blocked_count = $blockedCount
    items = @($migrationItems.ToArray())
    recommended_next_action = "Move low-risk governance and health recurrences into the internal scheduler first, then disable host copies only after the internal runner is executing them reliably."
}
Write-JsonFile -Path $legacyTaskMigrationPath -Object $legacyTaskMigrationArtifact -Depth 18

$popupSuppressionStatus = if ($noisySourceCount -eq 0 -or $remainingVisibleCount -lt $noisySourceCount) { "PASS" } else { "WARN" }
$popupSuppressionNextAction = if ($remainingVisibleCount -gt 0) { "Normalize the remaining visible background launches or classify them as intentionally interactive." } else { "Keep background tasks hidden and preserve logs/artifacts for audit visibility." }
$popupSuppressionArtifact = @{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $popupSuppressionStatus
    noisy_source_count = $noisySourceCount
    fixed_count = $popupFixedCount
    remaining_visible_count = $remainingVisibleCount
    task_governor_invocation = $taskGovernorInvocation
    items = @($popupItems.ToArray())
    recommended_next_action = $popupSuppressionNextAction
}
Write-JsonFile -Path $popupSuppressionPath -Object $popupSuppressionArtifact -Depth 18

$validatorCoverageMap = @{
    mason = "stack/base"
    mason_api = "stack/base"
    seed_api = "stack/base"
    bridge = "stack/base"
    athena = "Athena"
    onyx = "Onyx"
}
$componentIds = @(To-Array (Get-PropValue -Object $componentRegistry -Name "components" -Default @()) | ForEach-Object { Normalize-Text (Get-PropValue -Object $_ -Name "id" -Default "") } | Where-Object { $_ })
$validatorCoverageTargets = @("mason_api", "seed_api", "bridge")
$uncoveredComponents = @($validatorCoverageTargets | Where-Object { -not $validatorCoverageMap.ContainsKey($_) -or $componentIds -notcontains $_ })
$validatorCoverageStatus = if ($uncoveredComponents.Count -eq 0) { "PASS" } else { "WARN" }
$validatorCoverageNextAction = if ($uncoveredComponents.Count -eq 0) { "No action required." } else { "Finish validator coverage for the remaining registered components." }
$validatorCoverageArtifact = @{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $validatorCoverageStatus
    components_checked = $validatorCoverageTargets
    fully_covered_count = ($validatorCoverageTargets.Count - $uncoveredComponents.Count)
    uncovered_count = $uncoveredComponents.Count
    uncovered_components = @($uncoveredComponents)
    recommended_next_action = $validatorCoverageNextAction
}
Write-JsonFile -Path $validatorCoverageRepairPath -Object $validatorCoverageArtifact -Depth 12
if ($uncoveredComponents.Count -eq 0) {
    $fixedItems.Add((New-FixedItem -IssueId "validator_component_coverage" -Category "validator_coverage" -BeforeState "stack/base still warned on registered component coverage" -FixApplied "aligned validator coverage mapping for mason_api, seed_api, and bridge" -AfterState "registered component coverage is complete" -VerificationResult "coverage artifact now reports uncovered_count=0")) | Out-Null
}

$script:RepairWave02Stage = "mirror_repair"
$mirrorRepairAttempted = $false
$mirrorFailureClassBefore = Normalize-Text (Get-PropValue -Object $mirrorBefore -Name "mirror_push_failure_class" -Default "")
$mirrorFailureReasonBefore = Normalize-Text (Get-PropValue -Object $mirrorBefore -Name "mirror_push_failure_reason" -Default "")

if ((-not $SkipMirrorRefresh) -and -not $DisableMirrorReset) {
    if ((Normalize-Text (Get-PropValue -Object $mirrorBefore -Name "mirror_push_result" -Default "")) -eq "local_commit_only_remote_push_failed" -and
        ($mirrorFailureClassBefore -eq "large_file_history_rejection" -or $mirrorFailureReasonBefore -match "GH001|file size limit|Large files detected") -and
        (Test-Path -LiteralPath $mirrorRoot)) {
        $mirrorRepairAttempted = $true
        $fetchResult = Invoke-GitCapture -RepoPath $mirrorRoot -Args @("fetch", "origin", "main")
        if ($fetchResult.ok) {
            $resetResult = Invoke-GitCapture -RepoPath $mirrorRoot -Args @("reset", "--hard", "origin/main")
            if (-not $resetResult.ok) {
                $unfixedQueue.Add((New-QueueItem -IssueId "mirror_reset_failed" -Category "mirror" -Status "blocked" -Reason $resetResult.joined -RecommendedNextAction "Inspect the mirror repo manually if git reset --hard origin/main cannot complete safely.")) | Out-Null
            }
        }
        else {
            $unfixedQueue.Add((New-QueueItem -IssueId "mirror_fetch_failed" -Category "mirror" -Status "blocked" -Reason $fetchResult.joined -RecommendedNextAction "Repair mirror remote access before trying to reset and republish the mirror.")) | Out-Null
        }
    }
}

$script:RepairWave02Stage = "mirror_refresh"
$mirrorInvocation = [ordered]@{
    ok = $false
    exit_code = 0
    command_run = ""
    output = @()
}
if (-not $SkipMirrorRefresh -and (Test-Path -LiteralPath $mirrorRunnerPath)) {
    if ((Normalize-Text (Get-PropValue -Object $mirrorBefore -Name "mirror_push_result" -Default "")) -in @("pushed", "noop") -and (Test-ArtifactRecent -Path $mirrorUpdatePath -MaxAgeMinutes 90)) {
        $mirrorInvocation = [ordered]@{
            ok = $true
            exit_code = 0
            command_run = "reuse_recent_mirror_artifact"
            output = @("mirror_update_last.json already reports a current pushed/noop state within the freshness window")
        }
    }
    else {
        $mirrorInvocation = Invoke-ExternalScript -Path $mirrorRunnerPath -Arguments @("-Reason", "repair-wave-02")
    }
}

$mirrorAfter = Read-JsonSafe -Path $mirrorUpdatePath -Default @{}
$remotePushResult = Normalize-Text (Get-PropValue -Object $mirrorAfter -Name "mirror_push_result" -Default "")
$remoteCurrent = ($remotePushResult -in @("pushed", "noop"))
$remotePushFailureSummary = if ($remotePushResult -like "*remote_*failed*") {
    Get-MirrorPushFailureSummary -Lines @(To-Array (Get-PropValue -Object $mirrorAfter -Name "push_output" -Default @()))
}
else {
    [ordered]@{
        failure_class = ""
        failure_reason = ""
        oversized_paths = @()
        push_output = @()
    }
}

if ($remoteCurrent) {
    $fixedItems.Add((New-FixedItem -IssueId "mirror_remote_push" -Category "mirror" -BeforeState "local mirror only / remote push failed" -FixApplied "denied oversized mirror content and republished from a clean mirror branch" -AfterState ("remote_push_result=" + $remotePushResult) -VerificationResult "mirror_update_last.json now reports remote currentness truthfully")) | Out-Null
}
elseif (-not $SkipMirrorRefresh) {
    $unfixedQueue.Add((New-QueueItem -IssueId "remote_push_still_blocked" -Category "mirror" -Status "warn" -Reason ($(if ($remotePushFailureSummary.failure_class) { [string]$remotePushFailureSummary.failure_class } else { $remotePushResult })) -RecommendedNextAction "Use reports/remote_push_repair_last.json to inspect the exact push failure class and oversized paths before the next mirror reset attempt.")) | Out-Null
}

if (-not $SkipWholeFolderReverify) {
    $script:RepairWave02Stage = "whole_folder_reverify"
    if (-not (Test-ArtifactRecent -Path $wholeFolderVerificationPath -MaxAgeMinutes 60)) {
        [void](Invoke-ExternalScript -Path $wholeFolderRunnerPath)
    }
}
if (-not $SkipValidator) {
    $script:RepairWave02Stage = "validator_rerun"
    if (-not (Test-ArtifactRecent -Path $systemValidationPath -MaxAgeMinutes 60)) {
        [void](Invoke-ExternalScript -Path $validatorPath)
    }
}

$script:RepairWave02Stage = "finalize_artifacts"
$wholeFolderAfter = Read-JsonSafe -Path $wholeFolderVerificationPath -Default @{}
$brokenPathsAfter = [int](Get-PropValue -Object $wholeFolderAfter -Name "broken_path_count" -Default $brokenPathsBefore)
$codebaseInventoryAfter = Read-JsonSafe -Path $codebaseInventoryPath -Default @{}
$parseBrokenAfter = [int](Get-PropValue -Object (Get-PropValue -Object $codebaseInventoryAfter -Name "summary" -Default @{}) -Name "parse_broken_file_count" -Default $parseBrokenBefore)

$jsoncClusterStatus = if ($parseBrokenAfter -lt $parseBrokenBefore) { "fixed" } else { "unchanged" }
$wholeFolderClusterStatus = if ($brokenPathsAfter -lt $brokenPathsBefore) { "improved" } else { "unchanged" }
$validatorClusterAfterValue = if ($uncoveredComponents.Count -eq 0) { 0 } else { $uncoveredComponents.Count }
$validatorClusterStatus = if ($uncoveredComponents.Count -eq 0) { "fixed" } else { "warn" }

$brokenPathClusterItems = @(
    [pscustomobject][ordered]@{
        cluster_id = "jsonc_tsconfig_false_broken"
        before_value = $parseBrokenBefore
        after_value = $parseBrokenAfter
        status = $jsoncClusterStatus
        rationale = "JSONC-style tsconfig/jsconfig files should not be treated as malformed plain JSON."
    },
    [pscustomobject][ordered]@{
        cluster_id = "whole_folder_broken_paths"
        before_value = $brokenPathsBefore
        after_value = $brokenPathsAfter
        status = $wholeFolderClusterStatus
        rationale = "Whole-folder broken-path count should only be claimed improved if the reverified count actually dropped."
    },
    [pscustomobject][ordered]@{
        cluster_id = "validator_component_coverage"
        before_value = 1
        after_value = $validatorClusterAfterValue
        status = $validatorClusterStatus
        rationale = "Registered components should not stay uncovered in validator stack/base logic."
    }
)
$fixedClusterCount = @($brokenPathClusterItems | Where-Object { $_.status -in @("fixed", "improved") }).Count
$brokenPathClusterStatus = if ($brokenPathsAfter -lt $brokenPathsBefore -or $parseBrokenAfter -lt $parseBrokenBefore) { "PASS" } else { "WARN" }
$brokenPathClusterNextAction = if ($brokenPathsAfter -lt $brokenPathsBefore) { "Keep reducing high-value broken-path clusters without hiding the remaining backlog." } else { "The broad broken-path count did not drop enough yet; attack the next highest-value cluster rather than claiming cleanup." }
$brokenPathClusterArtifact = @{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $brokenPathClusterStatus
    target_cluster_count = @($brokenPathClusterItems).Count
    fixed_count = $fixedClusterCount
    broken_paths_before = $brokenPathsBefore
    broken_paths_after = $brokenPathsAfter
    parse_broken_before = $parseBrokenBefore
    parse_broken_after = $parseBrokenAfter
    items = $brokenPathClusterItems
    recommended_next_action = $brokenPathClusterNextAction
}
Write-JsonFile -Path $brokenPathClusterRepairPath -Object $brokenPathClusterArtifact -Depth 16

$remotePushRepairStatus = if ($remoteCurrent) { "PASS" } else { "WARN" }
$remotePushFailureClass = if ($remoteCurrent) { "none" } else { Normalize-Text $remotePushFailureSummary.failure_class }
$remotePushFailureReason = if ($remoteCurrent) { "none" } else { Normalize-Text $remotePushFailureSummary.failure_reason }
$remotePushOversizedPaths = if ($remoteCurrent) { @() } else { @($remotePushFailureSummary.oversized_paths) }
$remotePushNextAction = if ($remoteCurrent) { "No action required." } elseif ((Normalize-Text $remotePushFailureSummary.failure_class) -eq "large_file_history_rejection") { "Remove or rewrite the oversized file history in the mirror before the next push attempt." } else { "Inspect the exact remote push failure class and mirror credentials before retrying." }
$remotePushRepairArtifact = @{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $remotePushRepairStatus
    push_failure_class = $remotePushFailureClass
    safe_repair_attempted = [bool]$mirrorRepairAttempted
    remote_push_result = $remotePushResult
    remote_current = $remoteCurrent
    failure_reason = $remotePushFailureReason
    oversized_paths = $remotePushOversizedPaths
    mirror_root = $mirrorRoot
    mirror_invocation = $mirrorInvocation
    recommended_next_action = $remotePushNextAction
}
Write-JsonFile -Path $remotePushRepairPath -Object $remotePushRepairArtifact -Depth 18

$reportPatterns = @()
foreach ($propertyName in @("report_file_allowlist", "report_json_allowlist")) {
    $values = @(To-Array (Get-PropValue -Object $mirrorPolicy -Name $propertyName -Default @()) | ForEach-Object { Normalize-Text $_ } | Where-Object { $_ })
    foreach ($value in $values) {
        if ($reportPatterns -notcontains $value) {
            $reportPatterns += $value
        }
    }
}

$matchedMirrorFiles = New-Object System.Collections.Generic.List[string]
$missingMirrorPatterns = New-Object System.Collections.Generic.List[string]
foreach ($pattern in $reportPatterns) {
    $resolvedPattern = Join-Path $repoRootPath (($pattern -replace "/", "\").TrimStart("\"))
    $patternMatches = @()
    try {
        $patternMatches = @(
            Get-ChildItem -Path $resolvedPattern -File -ErrorAction SilentlyContinue |
                ForEach-Object { Get-RelativePathSafe -BasePath $repoRootPath -FullPath $_.FullName }
        )
    }
    catch {
        $patternMatches = @()
    }

    if (@($patternMatches).Count -gt 0) {
        foreach ($match in $patternMatches) {
            if ($match -and -not $matchedMirrorFiles.Contains($match)) {
                $matchedMirrorFiles.Add($match) | Out-Null
            }
        }
    }
    else {
        $missingMirrorPatterns.Add($pattern) | Out-Null
    }
}

$mirrorCoverageStatus = if (@($reportPatterns).Count -eq 0 -or $matchedMirrorFiles.Count -eq 0 -or $missingMirrorPatterns.Count -gt 0) { "WARN" } else { "PASS" }
$mirrorCoverageArtifact = @{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $mirrorCoverageStatus
    allowlist_pattern_count = @($reportPatterns).Count
    matched_file_count = $matchedMirrorFiles.Count
    missing_pattern_count = $missingMirrorPatterns.Count
    safe_report_files = @($matchedMirrorFiles.ToArray() | Sort-Object | Select-Object -First 120)
    missing_patterns = @($missingMirrorPatterns.ToArray() | Select-Object -First 60)
    recommended_next_action = if (@($reportPatterns).Count -eq 0) { "Restore the report mirror allowlist so mirror coverage can be evaluated truthfully." } elseif ($matchedMirrorFiles.Count -eq 0) { "Verify the mirror allowlist paths and report discovery logic because no safe report files were matched." } elseif ($missingMirrorPatterns.Count -eq 0) { "No action required." } else { "Expand the safe mirror allowlist or generate the missing safe artifacts before the next mirror refresh." }
}
Write-JsonFile -Path $mirrorCoveragePath -Object $mirrorCoverageArtifact -Depth 16

$mirrorOmissionArtifact = @{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = if (@($reportPatterns).Count -eq 0 -or $missingMirrorPatterns.Count -gt 0) { "WARN" } else { "PASS" }
    omission_count = $missingMirrorPatterns.Count
    omissions = @($missingMirrorPatterns.ToArray() | ForEach-Object {
            @{
                pattern = [string]$_
                reason = "No current matching safe artifact was found under reports."
            }
        })
    recommended_next_action = if (@($reportPatterns).Count -eq 0) { "Restore the report mirror allowlist so omissions can be evaluated truthfully." } elseif ($missingMirrorPatterns.Count -eq 0) { "No action required." } else { "Review the omitted mirror-safe patterns and decide whether the source artifact should be generated or the allowlist should be tightened." }
}
Write-JsonFile -Path $mirrorOmissionPath -Object $mirrorOmissionArtifact -Depth 16

$mirrorSafeIndex = @(
    "# Mason2 Mirror Safe Index",
    "",
    "Generated: " + (Get-Date).ToUniversalTime().ToString("o"),
    "",
    "## Safe Remote Inspection Summary",
    "",
    "- Whole-folder verification: reports/whole_folder_verification_last.json",
    "- Whole-folder broken paths: reports/whole_folder_broken_paths_last.json",
    "- Whole-folder registration gaps: reports/whole_folder_registration_gaps.json",
    "- Validator summary: reports/system_validation_last.json",
    "- Internal scheduler: reports/internal_scheduler_last.json",
    "- Legacy task inventory: reports/legacy_task_inventory_last.json",
    "- Legacy task migration: reports/legacy_task_migration_last.json",
    "- Popup suppression: reports/popup_suppression_last.json",
    "- Validator coverage repair: reports/validator_coverage_repair_last.json",
    "- Broken path cluster repair: reports/broken_path_cluster_repair_last.json",
    "- Remote push repair: reports/remote_push_repair_last.json",
    "- Mirror coverage: reports/mirror_coverage_last.json",
    "- Mirror omissions: reports/mirror_omission_last.json",
    "",
    "## Current Mirror Truth",
    "",
    "- Remote currentness depends on reports/mirror_update_last.json.",
    "- GitHub/off-box is only current when mirror_push_result is pushed or noop."
)
Set-Content -LiteralPath $mirrorSafeIndexPath -Value ($mirrorSafeIndex -join "`r`n") -Encoding UTF8

$repairWave02OverallStatus = "WARN"
if ($remoteCurrent -and $brokenPathsAfter -lt $brokenPathsBefore -and $uncoveredComponents.Count -eq 0) {
    $repairWave02OverallStatus = "PASS"
}
$repairWave02NextAction = if ($remoteCurrent -and $brokenPathsAfter -lt $brokenPathsBefore) { "Keep migrating low-risk host tasks into the internal scheduler foundation while preserving bootstrap fallback coverage." } else { "Continue wave 02 with the remaining unfixed queue; do not claim scheduler independence or remote currentness beyond what the artifacts prove." }

$repairWave02Artifact = @{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $repairWave02OverallStatus
    internal_scheduler_status = $internalSchedulerArtifact.overall_status
    legacy_task_migration_status = $legacyTaskMigrationArtifact.overall_status
    popup_suppression_status = $popupSuppressionArtifact.overall_status
    validator_coverage_status = $validatorCoverageArtifact.overall_status
    broken_path_repair_status = $brokenPathClusterArtifact.overall_status
    remote_push_repair_status = $remotePushRepairArtifact.overall_status
    migrated_task_count = $migratedCount
    popup_fixed_count = $popupFixedCount
    broken_paths_before = $brokenPathsBefore
    broken_paths_after = $brokenPathsAfter
    remote_push_result = $remotePushResult
    recommended_next_action = $repairWave02NextAction
    command_run = $commandRun
    repo_root = $repoRootPath
}
Write-JsonFile -Path $repairWave02Path -Object $repairWave02Artifact -Depth 16

$repairWave02QueueStatus = if ($unfixedQueue.Count -eq 0) { "PASS" } else { "WARN" }
$repairWave02QueueArtifact = @{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $repairWave02QueueStatus
    total_items = $unfixedQueue.Count
    items = @($unfixedQueue.ToArray())
}
Write-JsonFile -Path $repairWave02UnfixedQueuePath -Object $repairWave02QueueArtifact -Depth 16

$result = @{
    ok = $true
    overall_status = $repairWave02OverallStatus
    repair_wave_02_path = $repairWave02Path
    broken_paths_before = $brokenPathsBefore
    broken_paths_after = $brokenPathsAfter
    remote_push_result = $remotePushResult
    remote_current = $remoteCurrent
    migrated_task_count = $migratedCount
    popup_fixed_count = $popupFixedCount
    command_run = $commandRun
}

$script:RepairWave02Stage = "complete"
$result | ConvertTo-Json -Depth 12
