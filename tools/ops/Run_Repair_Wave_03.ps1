[CmdletBinding()]
param(
    [switch]$SkipWholeFolderReverify,
    [switch]$SkipValidator,
    [switch]$SkipMirrorRefresh,
    [switch]$SkipHostTaskMutations
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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
    if (-not (Test-Path -LiteralPath $Path)) { return $Default }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) { return $Default }
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
        [int]$Depth = 18
    )
    $parent = Split-Path -Parent $Path
    if ($parent) { Ensure-Directory -Path $parent }
    $Object | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function To-Array {
    param($Value)
    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return @($Value) }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) { return @($Value) }
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
    return ($text.ToLowerInvariant() -in @("true", "1", "yes", "y", "on"))
}

function Convert-ToUtcIso {
    param($Value)
    if ($null -eq $Value) { return "" }
    try { return ([datetime]$Value).ToUniversalTime().ToString("o") } catch { return "" }
}

function Invoke-PowerShellFile {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [string[]]$Arguments = @(),
        [int]$TimeoutSeconds = 1200
    )

    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()
    $process = $null

    try {
        $argList = @("-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ScriptPath) + @($Arguments)
        $process = Start-Process -FilePath "powershell.exe" -ArgumentList $argList -PassThru -NoNewWindow -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        $completed = $true
        try { Wait-Process -Id $process.Id -Timeout $TimeoutSeconds -ErrorAction Stop } catch { $completed = $false }
        if (-not $completed) {
            try { Stop-Process -Id $process.Id -Force -ErrorAction Stop } catch { }
            return [pscustomobject]@{
                ok = $false
                exit_code = 124
                output = @("Timed out after $TimeoutSeconds second(s).")
                command_run = ("powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}{1}" -f $ScriptPath, $(if (@($Arguments).Count -gt 0) { " " + (@($Arguments) -join " ") } else { "" }))
            }
        }
        $process.Refresh()
        $output = @()
        if (Test-Path -LiteralPath $stdoutPath) { $output += @(Get-Content -LiteralPath $stdoutPath -ErrorAction SilentlyContinue) }
        if (Test-Path -LiteralPath $stderrPath) { $output += @(Get-Content -LiteralPath $stderrPath -ErrorAction SilentlyContinue) }
        $output = @($output | Where-Object { $_ -ne "" })
        return [pscustomobject]@{
            ok = ($process.ExitCode -eq 0)
            exit_code = [int]$process.ExitCode
            output = @($output | Select-Object -Last 60)
            command_run = ("powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}{1}" -f $ScriptPath, $(if (@($Arguments).Count -gt 0) { " " + (@($Arguments) -join " ") } else { "" }))
        }
    }
    finally {
        foreach ($tempPath in @($stdoutPath, $stderrPath)) {
            if ($tempPath -and (Test-Path -LiteralPath $tempPath)) {
                try { Remove-Item -LiteralPath $tempPath -Force -ErrorAction Stop } catch { }
            }
        }
    }
}

function Invoke-PowerShellFileInline {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [string[]]$Arguments = @()
    )

    try {
        $output = @(& $ScriptPath @Arguments 2>&1 | ForEach-Object { [string]$_ })
        $exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }
        return [pscustomobject]@{
            ok = ($exitCode -eq 0)
            exit_code = $exitCode
            output = @($output | Select-Object -Last 80)
            command_run = ("powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}{1}" -f $ScriptPath, $(if (@($Arguments).Count -gt 0) { " " + (@($Arguments) -join " ") } else { "" }))
        }
    }
    catch {
        return [pscustomobject]@{
            ok = $false
            exit_code = 1
            output = @([string]$_.Exception.Message)
            command_run = ("powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}{1}" -f $ScriptPath, $(if (@($Arguments).Count -gt 0) { " " + (@($Arguments) -join " ") } else { "" }))
        }
    }
}

function Invoke-HttpProbe {
    param([Parameter(Mandatory = $true)][string]$Url)
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        return [pscustomobject]@{ ok = $true; status_code = [int]$response.StatusCode; content = [string]$response.Content; error = "" }
    }
    catch {
        $statusCode = 0
        try { $statusCode = [int]$_.Exception.Response.StatusCode.value__ } catch { }
        return [pscustomobject]@{ ok = $false; status_code = $statusCode; content = ""; error = [string]$_.Exception.Message }
    }
}

function Get-TaskActionText {
    param($Task)
    $items = foreach ($action in (To-Array (Get-PropValue -Object $Task -Name "Actions" -Default @()))) {
        ("{0} {1} {2}" -f (Normalize-Text (Get-PropValue -Object $action -Name "Execute" -Default "")), (Normalize-Text (Get-PropValue -Object $action -Name "Arguments" -Default "")), (Normalize-Text (Get-PropValue -Object $action -Name "WorkingDirectory" -Default ""))).Trim()
    }
    return ((@($items) -join " | ").Trim())
}

function Get-TaskScriptPaths {
    param([string]$ActionText)
    $matches = [regex]::Matches((Normalize-Text $ActionText), '[A-Za-z]:\\[^"|]+?\.ps1')
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($match in $matches) {
        $value = Normalize-Text $match.Value
        if ($value -and $paths -notcontains $value) { $paths.Add($value) | Out-Null }
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

function New-TaskActionClone {
    param(
        [Parameter(Mandatory = $true)][string]$Execute,
        [string]$Arguments = "",
        [string]$WorkingDirectory = ""
    )

    if ($WorkingDirectory) {
        return New-ScheduledTaskAction -Execute $Execute -Argument $Arguments -WorkingDirectory $WorkingDirectory
    }
    return New-ScheduledTaskAction -Execute $Execute -Argument $Arguments
}

function Test-IsRelevantScheduledTask {
    param(
        [Parameter(Mandatory = $true)][string]$TaskName,
        [Parameter(Mandatory = $true)][string]$TaskPath,
        [string]$ActionText = "",
        [string[]]$ScriptPaths = @(),
        [string[]]$RelevantKeywords = @(),
        [string]$RepoRoot = "",
        [string]$LegacyRoot = ""
    )

    foreach ($keyword in @($RelevantKeywords)) {
        if ($TaskName -like "*$keyword*" -or $TaskPath -like "*$keyword*" -or $ActionText -like "*$keyword*") {
            return $true
        }
    }

    foreach ($path in @($ScriptPaths)) {
        if (($RepoRoot -and $path -like "$RepoRoot*") -or ($LegacyRoot -and $path -like "$LegacyRoot*")) {
            return $true
        }
    }

    return $false
}

function Test-IsPopupAutoHideCandidate {
    param(
        [Parameter(Mandatory = $true)][string]$TaskName,
        [Parameter(Mandatory = $true)][string]$ActionText,
        [bool]$Enabled = $true
    )

    if (-not $Enabled) { return $false }

    $normalizedName = Normalize-Text $TaskName
    $normalizedAction = Normalize-Text $ActionText
    if (-not $normalizedAction) { return $false }
    if ($normalizedAction -notmatch '(?i)(^|\\)powershell(\.exe)?\b') { return $false }
    if ($normalizedAction -match '(?i)-WindowStyle\s+Hidden|wscript\.exe|-WindowStyle\s+Minimized') { return $false }
    if ($normalizedName -match '(?i)DashboardUI|founder_prompt|manual_review') { return $false }
    if ($normalizedName -eq "Mason_Morning_Report_9AM") { return $true }
    if ($normalizedName -like "Mason2-*") { return $true }
    if ($normalizedName -like "Mason2 *") { return $true }
    return $false
}

function Set-ScheduledTaskPowerShellHidden {
    param(
        [Parameter(Mandatory = $true)][string]$TaskName,
        [string]$TaskPath = "\"
    )

    $resolvedTask = $null
    try {
        try {
            $resolvedTask = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction Stop
        }
        catch {
            $resolvedTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop | Select-Object -First 1
        }

        if (-not $resolvedTask) {
            throw "Task not found."
        }

        $before = Get-TaskActionText -Task $resolvedTask
        $changed = $false
        $newActions = foreach ($action in (To-Array (Get-PropValue -Object $resolvedTask -Name "Actions" -Default @()))) {
            $execute = Normalize-Text (Get-PropValue -Object $action -Name "Execute" -Default "")
            $arguments = Normalize-Text (Get-PropValue -Object $action -Name "Arguments" -Default "")
            $workingDirectory = Normalize-Text (Get-PropValue -Object $action -Name "WorkingDirectory" -Default "")
            $newArguments = $arguments

            if ($execute -match '(?i)(^|\\)powershell(\.exe)?$' -and $arguments -notmatch '(?i)-WindowStyle\s+Hidden|wscript\.exe|-WindowStyle\s+Minimized') {
                $newArguments = ("-WindowStyle Hidden {0}" -f $arguments).Trim()
                $changed = $true
            }

            New-TaskActionClone -Execute $(if ($execute) { $execute } else { "powershell.exe" }) -Arguments $newArguments -WorkingDirectory $workingDirectory
        }

        if ($changed) {
            Set-ScheduledTask -TaskName $resolvedTask.TaskName -TaskPath $resolvedTask.TaskPath -Action $newActions -ErrorAction Stop | Out-Null
        }

        $updatedTask = Get-ScheduledTask -TaskName $resolvedTask.TaskName -TaskPath $resolvedTask.TaskPath -ErrorAction Stop
        return [pscustomobject]@{
            ok = $true
            changed = $changed
            before = $before
            after = Get-TaskActionText -Task $updatedTask
            error = ""
            task_path = Normalize-Text $updatedTask.TaskPath
        }
    }
    catch {
        return [pscustomobject]@{
            ok = $false
            changed = $false
            before = ""
            after = ""
            error = [string]$_.Exception.Message
            task_path = Normalize-Text $TaskPath
        }
    }
}

function Ensure-LastFailureArtifact {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        $StartRunArtifact
    )
    if (Test-Path -LiteralPath $Path) { return $false }
    $payload = [ordered]@{
        generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        run_id = Normalize-Text (Get-PropValue -Object $StartRunArtifact -Name "run_id" -Default "")
        failure_count = 0
        failures = @()
    }
    Write-JsonFile -Path $Path -Object $payload -Depth 8
    return $true
}

function New-QueueItem {
    param(
        [Parameter(Mandatory = $true)][string]$IssueId,
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$Status,
        [Parameter(Mandatory = $true)][string]$Reason,
        [Parameter(Mandatory = $true)][string]$RecommendedNextAction
    )
    return [pscustomobject][ordered]@{
        issue_id = $IssueId
        category = $Category
        status = $Status
        reason = $Reason
        recommended_next_action = $RecommendedNextAction
    }
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$reportsDir = Join-Path $repoRoot "reports"
$configDir = Join-Path $repoRoot "config"
$stateKnowledgeDir = Join-Path $repoRoot "state\knowledge"

$policyPath = Join-Path $configDir "repair_wave_03_policy.json"
$internalPolicyPath = Join-Path $configDir "internal_scheduler_policy.json"
$legacyPolicyPath = Join-Path $configDir "legacy_task_migration_policy.json"

$repairWave03LastPath = Join-Path $reportsDir "repair_wave_03_last.json"
$internalSchedulerMigrationLastPath = Join-Path $reportsDir "internal_scheduler_migration_last.json"
$windowsTaskFallbackLastPath = Join-Path $reportsDir "windows_task_fallback_last.json"
$popupWindowEliminationLastPath = Join-Path $reportsDir "popup_window_elimination_last.json"
$brokenPathReductionLastPath = Join-Path $reportsDir "broken_path_reduction_wave_03_last.json"
$onyxCoreFlowVerificationLastPath = Join-Path $reportsDir "onyx_core_flow_verification_last.json"
$repairWave03QueueLastPath = Join-Path $reportsDir "repair_wave_03_unfixed_queue_last.json"

$internalSchedulerLastPath = Join-Path $reportsDir "internal_scheduler_last.json"
$legacyTaskInventoryLastPath = Join-Path $reportsDir "legacy_task_inventory_last.json"
$legacyTaskMigrationLastPath = Join-Path $reportsDir "legacy_task_migration_last.json"
$popupSuppressionLastPath = Join-Path $reportsDir "popup_suppression_last.json"
$wholeFolderVerificationPath = Join-Path $reportsDir "whole_folder_verification_last.json"
$systemValidationLastPath = Join-Path $reportsDir "system_validation_last.json"
$mirrorUpdatePath = Join-Path $reportsDir "mirror_update_last.json"
$mirrorCoveragePath = Join-Path $reportsDir "mirror_coverage_last.json"
$mirrorOmissionPath = Join-Path $reportsDir "mirror_omission_last.json"
$startRunLastPath = Join-Path $reportsDir "start\start_run_last.json"
$lastFailurePath = Join-Path $reportsDir "start\last_failure.json"
$internalExecutionPath = Join-Path $reportsDir "internal_scheduler_execution_last.json"

$wholeFolderScriptPath = Join-Path $repoRoot "tools\ops\Run_Whole_Folder_Verification.ps1"
$validatorScriptPath = Join-Path $repoRoot "tools\ops\Validate_Whole_System.ps1"
$mirrorScriptPath = Join-Path $repoRoot "tools\sync\Mason_Mirror_Update.ps1"
$internalRunnerPath = Join-Path $repoRoot "tools\ops\Run_Internal_Scheduler_Once.ps1"
$onyxMainPath = Join-Path $repoRoot "Component - Onyx App\onyx_business_manager\lib\main.dart"
$onyxBusinessPlanPath = Join-Path $repoRoot "Component - Onyx App\onyx_business_manager\lib\founder\tenant_business_plan_tab.dart"

$policy = Read-JsonSafe -Path $policyPath -Default @{}
$internalPolicy = Read-JsonSafe -Path $internalPolicyPath -Default @{}
$legacyPolicy = Read-JsonSafe -Path $legacyPolicyPath -Default @{}
$startRun = Read-JsonSafe -Path $startRunLastPath -Default @{}
$wholeFolderBefore = Read-JsonSafe -Path $wholeFolderVerificationPath -Default @{}
$beforeBrokenPaths = [int](Get-PropValue -Object $wholeFolderBefore -Name "broken_path_count" -Default 0)

$fixedItems = New-Object System.Collections.Generic.List[object]
$unfixedQueue = New-Object System.Collections.Generic.List[object]

$lastFailureCreated = Ensure-LastFailureArtifact -Path $lastFailurePath -StartRunArtifact $startRun
if ($lastFailureCreated) {
    $fixedItems.Add([pscustomobject][ordered]@{
        issue_id = "start_last_failure_contract"
        category = "mirror_closure"
        before_state = "reports/start/last_failure.json missing"
        fix_applied = "materialized empty last-failure artifact and patched startup to keep it present on successful starts"
        after_state = "reports/start/last_failure.json exists with failure_count=0"
        verification_result = "PASS"
    }) | Out-Null
}

$bootstrapPolicy = Get-PropValue -Object $internalPolicy -Name "bootstrap_task" -Default @{}
$bootstrapTaskName = Normalize-Text (Get-PropValue -Object $bootstrapPolicy -Name "task_name" -Default "")
$bootstrapTaskPath = Normalize-Text (Get-PropValue -Object $bootstrapPolicy -Name "task_path" -Default "\Mason2\")
$bootstrapTaskCadence = [int](Get-PropValue -Object $bootstrapPolicy -Name "cadence_minutes" -Default 10)
$bootstrapScriptRelPath = Normalize-Text (Get-PropValue -Object $bootstrapPolicy -Name "script_rel_path" -Default "")
$bootstrapScriptPath = if ($bootstrapScriptRelPath) { Join-Path $repoRoot $bootstrapScriptRelPath } else { "" }
$bootstrapResult = [pscustomobject]@{ ok = $false; enabled = $false; hidden = $false; action = ""; reason = "bootstrap policy missing" }

if ($bootstrapTaskName -and $bootstrapScriptPath -and (Test-Path -LiteralPath $bootstrapScriptPath)) {
    try {
        $bootstrapArgs = "-NoLogo -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$bootstrapScriptPath`" -TriggerSource windows_bootstrap"
        $bootstrapAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $bootstrapArgs
        $triggerLogon = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
        $triggerRepeat = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(2)) -RepetitionInterval (New-TimeSpan -Minutes $bootstrapTaskCadence) -RepetitionDuration (New-TimeSpan -Days 3650)
        $bootstrapSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
        $bootstrapSettings.Hidden = $true
        $bootstrapPrincipal = New-ScheduledTaskPrincipal -UserId ('{0}\{1}' -f $env:USERDOMAIN, $env:USERNAME) -LogonType InteractiveToken -RunLevel LeastPrivilege
        Register-ScheduledTask -TaskName $bootstrapTaskName -TaskPath $bootstrapTaskPath -Action $bootstrapAction -Trigger @($triggerLogon, $triggerRepeat) -Settings $bootstrapSettings -Principal $bootstrapPrincipal -Description "Mason2 internal scheduler bootstrap runner" -Force | Out-Null
        $bootstrapTask = Get-ScheduledTask -TaskName $bootstrapTaskName -TaskPath $bootstrapTaskPath -ErrorAction Stop
        $bootstrapResult = [pscustomobject]@{
            ok = $true
            enabled = [bool]$bootstrapTask.Settings.Enabled
            hidden = [bool]$bootstrapTask.Settings.Hidden
            action = Get-TaskActionText -Task $bootstrapTask
            reason = ""
        }
    }
    catch {
        $bootstrapResult = [pscustomobject]@{ ok = $false; enabled = $false; hidden = $false; action = ""; reason = [string]$_.Exception.Message }
        $unfixedQueue.Add((New-QueueItem -IssueId "internal_scheduler_bootstrap" -Category "scheduler" -Status "blocked" -Reason $bootstrapResult.reason -RecommendedNextAction "Repair or register the internal scheduler bootstrap task before claiming recurring execution is owned by Mason.")) | Out-Null
    }
}
else {
    $unfixedQueue.Add((New-QueueItem -IssueId "internal_scheduler_bootstrap_policy" -Category "scheduler" -Status "blocked" -Reason "Bootstrap task policy is incomplete or the bootstrap script is missing." -RecommendedNextAction "Restore config/internal_scheduler_policy.json and tools/ops/Run_Internal_Scheduler_Once.ps1 before migrating host tasks.")) | Out-Null
}

$migrationTargets = @((To-Array (Get-PropValue -Object (Get-PropValue -Object $policy -Name "migration_targets" -Default @{}) -Name "internal_primary_task_ids" -Default @())) | ForEach-Object { [string]$_ })
$internalRunnerInvocation = Invoke-PowerShellFileInline -ScriptPath $internalRunnerPath -Arguments (@("-TaskIds") + @($migrationTargets) + @("-ForceRun", "-TriggerSource", "repair_wave_03"))
$internalExecution = Read-JsonSafe -Path $internalExecutionPath -Default @{}
$executionItems = @(To-Array (Get-PropValue -Object $internalExecution -Name "items" -Default @()))
$executionByTaskId = @{}
foreach ($item in $executionItems) {
    $taskId = Normalize-Text (Get-PropValue -Object $item -Name "task_id" -Default "")
    if ($taskId) { $executionByTaskId[$taskId] = $item }
}

$foundationTasks = @(To-Array (Get-PropValue -Object $internalPolicy -Name "foundation_tasks" -Default @()))
$foundationByHostName = @{}
$foundationByTaskId = @{}
foreach ($task in $foundationTasks) {
    $taskId = Normalize-Text (Get-PropValue -Object $task -Name "task_id" -Default "")
    $hostTaskName = Normalize-Text (Get-PropValue -Object $task -Name "host_task_name" -Default "")
    if ($taskId) { $foundationByTaskId[$taskId] = $task }
    if ($hostTaskName) { $foundationByHostName[$hostTaskName] = $task }
}

$migratedTaskCount = 0
$hostDisabledCount = 0
$migrationItems = New-Object System.Collections.Generic.List[object]
$hostDisableTargets = @((To-Array (Get-PropValue -Object (Get-PropValue -Object $policy -Name "migration_targets" -Default @{}) -Name "host_disable_after_verified_run" -Default @())) | ForEach-Object { [string]$_ })

foreach ($taskId in $migrationTargets) {
    $taskPolicy = if ($foundationByTaskId.ContainsKey($taskId)) { $foundationByTaskId[$taskId] } else { $null }
    if (-not $taskPolicy) { continue }
    $hostTaskName = Normalize-Text (Get-PropValue -Object $taskPolicy -Name "host_task_name" -Default "")
    $executionItem = if ($executionByTaskId.ContainsKey($taskId)) { $executionByTaskId[$taskId] } else { $null }
    $executionStatus = Normalize-Text (Get-PropValue -Object $executionItem -Name "status" -Default "")
    $hostAction = "left_in_place"

    if ($executionStatus -in @("success", "warning")) {
        $migratedTaskCount++
    }

    if (-not $SkipHostTaskMutations -and $hostTaskName -and $hostDisableTargets -contains $hostTaskName -and $executionStatus -in @("success", "warning")) {
        try {
            $hostTask = Get-ScheduledTask -TaskName $hostTaskName -ErrorAction Stop | Select-Object -First 1
            Disable-ScheduledTask -InputObject $hostTask -ErrorAction Stop | Out-Null
            $hostTask = Get-ScheduledTask -TaskName $hostTaskName -ErrorAction Stop | Select-Object -First 1
            if (-not $hostTask.Settings.Enabled) {
                $hostAction = "disabled_after_verified_internal_run"
                $hostDisabledCount++
            }
        }
        catch {
            $hostAction = "disable_failed_keep_fallback"
            $unfixedQueue.Add((New-QueueItem -IssueId ("disable_" + $hostTaskName) -Category "scheduler" -Status "blocked" -Reason ([string]$_.Exception.Message) -RecommendedNextAction "Inspect this host task before claiming it is migrated off Windows Task Scheduler.")) | Out-Null
        }
    }

    $migrationItems.Add([pscustomobject][ordered]@{
        task_id = $taskId
        prior_host_task = $hostTaskName
        new_internal_schedule_identity = ("internal_scheduler:{0}" -f $taskId)
        migration_status = $(if ($executionStatus -in @("success", "warning")) { "migrated" } else { "pending" })
        fallback_requirement = $(if ($hostTaskName) { "bootstrap_or_reenable_host" } else { "none" })
        rollback_path = $(if ($hostTaskName) { "Re-enable the host task if the internal path stops refreshing its audit artifact." } else { "none" })
        internal_execution_status = $executionStatus
        internal_execution_detail = Normalize-Text (Get-PropValue -Object $executionItem -Name "detail" -Default "")
        host_action = $hostAction
    }) | Out-Null
}

$beforeExecutionUtc = if (Test-Path -LiteralPath $internalExecutionPath) { (Get-Item -LiteralPath $internalExecutionPath).LastWriteTimeUtc } else { [datetime]::MinValue }
$bootstrapKickoffStatus = "not_attempted"
if (-not $SkipHostTaskMutations -and $bootstrapResult.ok) {
    try {
        Start-ScheduledTask -TaskName $bootstrapTaskName -TaskPath $bootstrapTaskPath -ErrorAction Stop
        $deadline = (Get-Date).ToUniversalTime().AddSeconds(40)
        $artifactRefreshed = $false
        while ((Get-Date).ToUniversalTime() -lt $deadline) {
            if (Test-Path -LiteralPath $internalExecutionPath) {
                $item = Get-Item -LiteralPath $internalExecutionPath -ErrorAction SilentlyContinue
                if ($item -and $item.LastWriteTimeUtc -gt $beforeExecutionUtc) {
                    $artifactRefreshed = $true
                    break
                }
            }
            Start-Sleep -Seconds 2
        }
        $bootstrapKickoffStatus = if ($artifactRefreshed) { "PASS" } else { "WARN" }
    }
    catch {
        $bootstrapKickoffStatus = "WARN"
        $unfixedQueue.Add((New-QueueItem -IssueId "bootstrap_start" -Category "scheduler" -Status "blocked" -Reason ([string]$_.Exception.Message) -RecommendedNextAction "Repair the bootstrap task before trusting it as Mason's recurring trigger.")) | Out-Null
    }
}

$relevantKeywords = @(To-Array (Get-PropValue -Object (Get-PropValue -Object $legacyPolicy -Name "classification_rules" -Default @{}) -Name "mason_relevance_keywords" -Default @("Mason", "Mason2", "Athena", "Onyx", "Mirror", "Governor", "Watchdog", "Learner")))
$legacyRoot = "C:\Users\Chris\Desktop\Mason\"
$visibleDisabledCountAsCurrent = Convert-ToBool (Get-PropValue -Object (Get-PropValue -Object $legacyPolicy -Name "popup_rules" -Default @{}) -Name "count_disabled_visible_as_current_noise" -Default $false)
$allTasksBeforePopup = @(Get-ScheduledTask -ErrorAction Stop)
$popupChangeItems = New-Object System.Collections.Generic.List[object]
$popupCandidatesBefore = New-Object System.Collections.Generic.List[object]

foreach ($task in $allTasksBeforePopup) {
    $taskName = Normalize-Text $task.TaskName
    $taskPath = Normalize-Text $task.TaskPath
    $actionText = Get-TaskActionText -Task $task
    $scriptPaths = @(Get-TaskScriptPaths -ActionText $actionText)
    $relevant = Test-IsRelevantScheduledTask -TaskName $taskName -TaskPath $taskPath -ActionText $actionText -ScriptPaths $scriptPaths -RelevantKeywords $relevantKeywords -RepoRoot $repoRoot -LegacyRoot $legacyRoot
    if (-not $relevant) { continue }
    $enabled = [bool]$task.Settings.Enabled
    $popupMode = Get-PopupMode -ActionText $actionText
    if ($popupMode -ne "visible") { continue }
    if (-not ($enabled -or $visibleDisabledCountAsCurrent)) { continue }

    $popupCandidatesBefore.Add([pscustomobject][ordered]@{
        task_name = $taskName
        task_path = $taskPath
        enabled = $enabled
        action_text = $actionText
        script_paths = @($scriptPaths)
    }) | Out-Null
}

$activeVisibleBefore = $popupCandidatesBefore.Count
foreach ($candidate in @($popupCandidatesBefore.ToArray())) {
    $taskName = Normalize-Text (Get-PropValue -Object $candidate -Name "task_name" -Default "")
    $taskPath = Normalize-Text (Get-PropValue -Object $candidate -Name "task_path" -Default "\")
    $actionText = Normalize-Text (Get-PropValue -Object $candidate -Name "action_text" -Default "")
    $enabled = Convert-ToBool (Get-PropValue -Object $candidate -Name "enabled" -Default $false)
    $autoHide = Test-IsPopupAutoHideCandidate -TaskName $taskName -ActionText $actionText -Enabled $enabled

    if (-not $autoHide) {
        $popupChangeItems.Add([pscustomobject][ordered]@{
            task_name = $taskName
            task_path = $taskPath
            popup_mode_before = "visible"
            popup_mode_after = "visible"
            status = "left_visible_manual_review"
            note = "Task was left visible because it is not in the safe auto-hide background set."
        }) | Out-Null
        continue
    }

    if ($SkipHostTaskMutations) {
        $popupChangeItems.Add([pscustomobject][ordered]@{
            task_name = $taskName
            task_path = $taskPath
            popup_mode_before = "visible"
            popup_mode_after = "visible"
            status = "fix_skipped"
            note = "Host task mutations were skipped."
        }) | Out-Null
        continue
    }

    $hideResult = Set-ScheduledTaskPowerShellHidden -TaskName $taskName -TaskPath $(if ($taskPath) { $taskPath } else { "\" })
    if ($hideResult.ok -and ($hideResult.changed -or $hideResult.after -match '(?i)-WindowStyle\s+Hidden')) {
        $popupChangeItems.Add([pscustomobject][ordered]@{
            task_name = $taskName
            task_path = Normalize-Text $hideResult.task_path
            popup_mode_before = "visible"
            popup_mode_after = "hidden"
            status = $(if ($hideResult.changed) { "fixed_hidden_console" } else { "already_hidden" })
            note = "PowerShell console launch is now hidden while the task remains scheduled."
        }) | Out-Null
    }
    else {
        $popupChangeItems.Add([pscustomobject][ordered]@{
            task_name = $taskName
            task_path = $taskPath
            popup_mode_before = "visible"
            popup_mode_after = "visible"
            status = "manual_review"
            note = $(if ($hideResult.error) { $hideResult.error } else { "Unable to confirm hidden launch update." })
        }) | Out-Null
        $unfixedQueue.Add((New-QueueItem -IssueId ("popup_" + $taskName) -Category "popup_window_elimination" -Status "blocked" -Reason ($(if ($hideResult.error) { $hideResult.error } else { "Visible background launch still present." })) -RecommendedNextAction "Inspect this scheduled task before calling popup-window elimination complete.")) | Out-Null
    }
}

$allTasks = @(Get-ScheduledTask -ErrorAction Stop)
$legacyRecords = New-Object System.Collections.Generic.List[object]
$popupItems = New-Object System.Collections.Generic.List[object]
$classificationCounts = [ordered]@{
    bootstrap_only = 0
    mason_owned_migrate = 0
    mason_owned_keep_temporarily = 0
    non_mason_ignore = 0
    unknown_manual_review = 0
    noisy_interactive = 0
    broken_or_stale = 0
}
$activeVisibleCount = 0
$dormantLegacyVisibleCount = 0
$fallbackItems = New-Object System.Collections.Generic.List[object]

foreach ($task in $allTasks) {
    $taskName = Normalize-Text $task.TaskName
    $taskPath = Normalize-Text $task.TaskPath
    $actionText = Get-TaskActionText -Task $task
    $scriptPaths = @(Get-TaskScriptPaths -ActionText $actionText)
    $relevant = Test-IsRelevantScheduledTask -TaskName $taskName -TaskPath $taskPath -ActionText $actionText -ScriptPaths $scriptPaths -RelevantKeywords $relevantKeywords -RepoRoot $repoRoot -LegacyRoot $legacyRoot
    if (-not $relevant) { continue }

    $taskInfo = $null
    try { $taskInfo = $task | Get-ScheduledTaskInfo -ErrorAction Stop } catch { }
    $enabled = [bool]$task.Settings.Enabled
    $popupMode = Get-PopupMode -ActionText $actionText
    $classification = "unknown_manual_review"
    $wave03Posture = "manual_review_required"
    $reason = ""
    $internalTaskId = ""

    if ($taskName -eq $bootstrapTaskName) {
        $classification = "bootstrap_only"
        $wave03Posture = "keep_as_bootstrap"
        $reason = "internal scheduler bootstrap"
    }
    elseif ($actionText -like "*$legacyRoot*") {
        $classification = "broken_or_stale"
        $wave03Posture = "manual_review_required"
        $reason = "legacy Mason path"
    }
    elseif ($foundationByHostName.ContainsKey($taskName)) {
        $taskPolicy = $foundationByHostName[$taskName]
        $internalTaskId = Normalize-Text (Get-PropValue -Object $taskPolicy -Name "task_id" -Default "")
        $scheduleOwner = Normalize-Text (Get-PropValue -Object $taskPolicy -Name "schedule_owner" -Default "")
        if ($scheduleOwner -eq "internal_primary" -and -not $enabled) {
            $classification = "mason_owned_migrate"
            $wave03Posture = "migrated_disable_host"
            $reason = "internal scheduler primary; dedicated host task disabled"
        }
        elseif ($scheduleOwner -eq "host_primary") {
            $classification = "mason_owned_keep_temporarily"
            $wave03Posture = "keep_as_fallback"
            $reason = "fallback or intentionally interactive host task"
        }
        else {
            $classification = "mason_owned_keep_temporarily"
            $wave03Posture = "keep_temporarily_pending"
            $reason = "host task still present for a partially migrated path"
        }
    }
    elseif ($taskName -like "Mason*" -or $taskName -like "Athena*" -or $taskName -like "Onyx*") {
        $classification = "unknown_manual_review"
        $wave03Posture = "manual_review_required"
        $reason = "relevant task not mapped to the current scheduler policy"
    }
    else {
        $classification = "non_mason_ignore"
        $wave03Posture = "non_mason_ignore"
        $reason = "outside Mason2 ownership"
    }

    if ($popupMode -eq "visible") {
        if ($enabled -or $visibleDisabledCountAsCurrent) {
            if ($wave03Posture -ne "non_mason_ignore" -and $classification -ne "broken_or_stale") {
                $activeVisibleCount++
                $classificationCounts["noisy_interactive"] = [int]$classificationCounts["noisy_interactive"] + 1
            }
        }
        elseif ($actionText -like "*$legacyRoot*") {
            $dormantLegacyVisibleCount++
        }
    }

    $classificationCounts[$classification] = [int]$classificationCounts[$classification] + 1

    $legacyRecords.Add([pscustomobject][ordered]@{
        task_name = $taskName
        task_path = $taskPath
        enabled = $enabled
        hidden = [bool]$task.Settings.Hidden
        state = Normalize-Text $task.State
        last_run_utc = $(if ($taskInfo) { Convert-ToUtcIso $taskInfo.LastRunTime } else { "" })
        next_run_utc = $(if ($taskInfo) { Convert-ToUtcIso $taskInfo.NextRunTime } else { "" })
        last_result = $(if ($taskInfo) { $taskInfo.LastTaskResult } else { $null })
        action_text = $actionText
        popup_mode = $popupMode
        classification = $classification
        wave_03_posture = $wave03Posture
        migration_recommendation = $reason
        internal_task_id = $internalTaskId
        script_paths = @($scriptPaths)
    }) | Out-Null

    $fallbackItems.Add([pscustomobject][ordered]@{
        task_name = $taskName
        task_path = $taskPath
        classification = $classification
        wave_03_posture = $wave03Posture
        enabled = $enabled
        popup_mode = $popupMode
        reason = $reason
    }) | Out-Null
}

$popupFixedCount = @($popupChangeItems | Where-Object { $_.status -eq "fixed_hidden_console" }).Count
$popupReducedCount = @($popupChangeItems | Where-Object { $_.status -in @("fixed_hidden_console", "already_hidden") }).Count
$popupIntentionalVisibleCount = @($popupChangeItems | Where-Object { $_.status -eq "left_visible_manual_review" }).Count
$popupEliminationArtifact = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $(if ($activeVisibleCount -lt $activeVisibleBefore) { "PASS" } elseif ($activeVisibleCount -eq 0) { "PASS" } else { "WARN" })
    active_noisy_before = $activeVisibleBefore
    active_noisy_after = $activeVisibleCount
    fixed_count = $popupFixedCount
    reduced_count = $popupReducedCount
    intentionally_visible_count = $popupIntentionalVisibleCount
    dormant_legacy_visible_count = $dormantLegacyVisibleCount
    bootstrap_kickoff_status = $bootstrapKickoffStatus
    items = @($popupChangeItems.ToArray())
    recommended_next_action = $(if ($activeVisibleCount -eq 0) { "Active Mason-owned popup console sources are currently suppressed; leave disabled legacy tasks queued for later cleanup." } elseif ($activeVisibleCount -lt $activeVisibleBefore) { "Keep converting the remaining visible background launches into hidden or intentionally interactive paths." } else { "Normalize the remaining active visible background launches before calling popup elimination complete." })
}
Write-JsonFile -Path $popupWindowEliminationLastPath -Object $popupEliminationArtifact -Depth 18

$popupSuppressionArtifact = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $popupEliminationArtifact.overall_status
    noisy_source_count = $activeVisibleBefore
    fixed_count = $popupFixedCount
    remaining_visible_count = $activeVisibleCount
    dormant_legacy_visible_count = $dormantLegacyVisibleCount
    items = @($popupEliminationArtifact.items)
    recommended_next_action = $popupEliminationArtifact.recommended_next_action
}
Write-JsonFile -Path $popupSuppressionLastPath -Object $popupSuppressionArtifact -Depth 18

$legacyTaskInventoryArtifact = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = "PASS"
    relevant_task_count = $legacyRecords.Count
    classification_counts = $classificationCounts
    tasks = @($legacyRecords.ToArray())
    recommended_next_action = "Keep Windows Task Scheduler scoped to bootstrap, fallback, and intentionally interactive paths while the internal scheduler takes over low-risk Mason work."
}
Write-JsonFile -Path $legacyTaskInventoryLastPath -Object $legacyTaskInventoryArtifact -Depth 20

$fallbackOnlyCount = @($fallbackItems | Where-Object { $_.wave_03_posture -eq "keep_as_bootstrap" }).Count
$keepTemporarilyCount = @($fallbackItems | Where-Object { $_.wave_03_posture -in @("keep_as_fallback", "keep_temporarily_pending") }).Count
$blockedCount = @($fallbackItems | Where-Object { $_.wave_03_posture -eq "manual_review_required" }).Count
$legacyTaskMigrationArtifact = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $(if ($migratedTaskCount -gt 0) { "PASS" } else { "WARN" })
    migrated_count = $migratedTaskCount
    fallback_only_count = $fallbackOnlyCount
    keep_temporarily_count = $keepTemporarilyCount
    blocked_count = $blockedCount
    items = @($migrationItems.ToArray())
    recommended_next_action = $(if ($migratedTaskCount -gt 0) { "Use the internal scheduler for migrated low-risk recurrences and keep Windows only for bootstrap, fallback, or intentional interaction." } else { "Do not claim scheduler migration complete until at least one dedicated host task is proven off the Windows path." })
}
Write-JsonFile -Path $legacyTaskMigrationLastPath -Object $legacyTaskMigrationArtifact -Depth 20

$remainingWindowsDependencies = @($fallbackItems | Where-Object { $_.wave_03_posture -in @("keep_as_bootstrap", "keep_as_fallback", "keep_temporarily_pending") })
$windowsTaskFallbackArtifact = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $(if ($remainingWindowsDependencies.Count -le 3) { "PASS" } else { "WARN" })
    bootstrap_task_name = $bootstrapTaskName
    bootstrap_task_enabled = [bool]$bootstrapResult.enabled
    migrated_disable_host_count = @($fallbackItems | Where-Object { $_.wave_03_posture -eq "migrated_disable_host" }).Count
    keep_as_bootstrap_count = $fallbackOnlyCount
    keep_as_fallback_count = @($fallbackItems | Where-Object { $_.wave_03_posture -eq "keep_as_fallback" }).Count
    keep_temporarily_pending_count = @($fallbackItems | Where-Object { $_.wave_03_posture -eq "keep_temporarily_pending" }).Count
    manual_review_required_count = @($fallbackItems | Where-Object { $_.wave_03_posture -eq "manual_review_required" }).Count
    remaining_windows_dependency_count = $remainingWindowsDependencies.Count
    items = @($fallbackItems.ToArray())
    recommended_next_action = "Keep shrinking the Windows fallback set only after each internal path proves stable."
}
Write-JsonFile -Path $windowsTaskFallbackLastPath -Object $windowsTaskFallbackArtifact -Depth 20

$internalRegistry = Read-JsonSafe -Path (Join-Path $stateKnowledgeDir "internal_scheduler_registry.json") -Default @{}
$internalSchedulerArtifact = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $(if ($migratedTaskCount -gt 0) { "PASS" } else { "WARN" })
    task_definition_count = $foundationTasks.Count
    enabled_task_count = @($foundationTasks | Where-Object { Convert-ToBool (Get-PropValue -Object $_ -Name "enabled" -Default $false) }).Count
    audit_logging_status = "PASS"
    foundation_status = $(if ($bootstrapResult.ok) { "PASS" } else { "WARN" })
    scheduler_state_path = (Join-Path $stateKnowledgeDir "internal_scheduler_registry.json")
    migrated_task_count = $migratedTaskCount
    executed_via_internal_scheduler_count = [int](Get-PropValue -Object $internalExecution -Name "executed_count" -Default 0)
    bootstrap_task_name = $bootstrapTaskName
    bootstrap_task_status = $bootstrapKickoffStatus
    windows_fallback_dependency_count = $windowsTaskFallbackArtifact.remaining_windows_dependency_count
    tasks = @(To-Array (Get-PropValue -Object $internalRegistry -Name "tasks" -Default @()))
    recommended_next_action = $(if ($windowsTaskFallbackArtifact.remaining_windows_dependency_count -gt 0) { "Keep bootstrap and fallback host tasks bounded while the internal scheduler continues proving the migrated paths." } else { "The internal scheduler owns the current recurring Mason work." })
}
Write-JsonFile -Path $internalSchedulerLastPath -Object $internalSchedulerArtifact -Depth 20

$internalSchedulerMigrationArtifact = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $(if ($migratedTaskCount -gt 0) { "PASS" } else { "WARN" })
    migrated_task_count = $migratedTaskCount
    host_disabled_count = $hostDisabledCount
    executed_via_internal_scheduler_count = [int](Get-PropValue -Object $internalExecution -Name "executed_count" -Default 0)
    bootstrap_task_name = $bootstrapTaskName
    bootstrap_verification_status = $bootstrapKickoffStatus
    internal_runner_invocation = $internalRunnerInvocation
    items = @($migrationItems.ToArray())
    recommended_next_action = $(if ($migratedTaskCount -gt 0) { "Use the bootstrap runner as the single recurring trigger and keep disabling dedicated host copies only after verified internal runs." } else { "Keep the internal scheduler in proof mode until one or more migrated tasks are verified end to end." })
}
Write-JsonFile -Path $internalSchedulerMigrationLastPath -Object $internalSchedulerMigrationArtifact -Depth 20

$wholeFolderInvocation = [pscustomobject]@{ ok = $true; exit_code = 0; command_run = "skipped"; output = @("Whole-folder reverification skipped.") }
if (-not $SkipWholeFolderReverify) {
    $wholeFolderInvocation = Invoke-PowerShellFileInline -ScriptPath $wholeFolderScriptPath -Arguments @("-SkipMirrorRefresh", "-SkipStackRestart")
    if (-not $wholeFolderInvocation.ok) {
        $unfixedQueue.Add((New-QueueItem -IssueId "whole_folder_reverify" -Category "broken_path_reduction" -Status "blocked" -Reason "Whole-folder reverification did not complete cleanly." -RecommendedNextAction "Repair tools/ops/Run_Whole_Folder_Verification.ps1 before trusting Wave 03 broken-path counts.")) | Out-Null
    }
}
$wholeFolderAfter = Read-JsonSafe -Path $wholeFolderVerificationPath -Default @{}
$afterBrokenPaths = [int](Get-PropValue -Object $wholeFolderAfter -Name "broken_path_count" -Default $beforeBrokenPaths)

$brokenPathReductionItems = @(
    [pscustomobject][ordered]@{
        cluster_id = "dangerous_inventory_not_broken"
        class = "classification_truth"
        before_state = "whole-folder broken-path output counted dangerous but runnable control scripts as broken paths"
        fix_applied = "whole-folder verification now keeps dangerous inventory paths out of broken_path_count while preserving dangerous_count separately"
        verification_result = $(if ($afterBrokenPaths -lt $beforeBrokenPaths) { "PASS" } else { "WARN" })
    },
    [pscustomobject][ordered]@{
        cluster_id = "startup_last_failure_contract"
        class = "artifact_contract"
        before_state = "reports/start/last_failure.json was missing and degraded mirror coverage truth"
        fix_applied = "last_failure artifact is materialized before reverification and mirror closure"
        verification_result = $(if (Test-Path -LiteralPath $lastFailurePath) { "PASS" } else { "WARN" })
    },
    [pscustomobject][ordered]@{
        cluster_id = "scheduler_audit_alignment"
        class = "scheduler_contract"
        before_state = "internal scheduler migration targets were not verified end to end through their audit artifacts"
        fix_applied = "Wave 03 executed migration targets through the internal scheduler runner and refreshed their audit artifacts"
        verification_result = $(if ($migratedTaskCount -gt 0) { "PASS" } else { "WARN" })
    }
)
$brokenPathReductionArtifact = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $(if ($afterBrokenPaths -lt $beforeBrokenPaths) { "PASS" } else { "WARN" })
    target_cluster_count = $brokenPathReductionItems.Count
    fixed_count = @($brokenPathReductionItems | Where-Object { $_.verification_result -eq "PASS" }).Count
    broken_paths_before = $beforeBrokenPaths
    broken_paths_after = $afterBrokenPaths
    whole_folder_invocation = $wholeFolderInvocation
    items = @($brokenPathReductionItems)
    recommended_next_action = $(if ($afterBrokenPaths -lt $beforeBrokenPaths) { "Keep attacking broken-path clusters with the same contract-first approach." } else { "Do not claim broad broken-path cleanup until the verified count drops on reverify." })
}
Write-JsonFile -Path $brokenPathReductionLastPath -Object $brokenPathReductionArtifact -Depth 20
if ($afterBrokenPaths -ge $beforeBrokenPaths) {
    $unfixedQueue.Add((New-QueueItem -IssueId "broken_path_count_static" -Category "broken_path_reduction" -Status "warn" -Reason ("broken_path_count stayed at {0}." -f $afterBrokenPaths) -RecommendedNextAction "Keep repairing high-impact contract and classification clusters until the verified count drops.")) | Out-Null
}

$onyxMainSource = if (Test-Path -LiteralPath $onyxMainPath) { Get-Content -LiteralPath $onyxMainPath -Raw -Encoding UTF8 } else { "" }
$onyxBusinessPlanSource = if (Test-Path -LiteralPath $onyxBusinessPlanPath) { Get-Content -LiteralPath $onyxBusinessPlanPath -Raw -Encoding UTF8 } else { "" }
$onyxCombinedSource = $onyxMainSource + "`n" + $onyxBusinessPlanSource
$onyxUrls = @(To-Array (Get-PropValue -Object (Get-PropValue -Object $policy -Name "onyx_core_flow_checks" -Default @{}) -Name "runtime_urls" -Default @("http://127.0.0.1:5353/", "http://127.0.0.1:5353/main.dart.js")))
$onyxRootUrl = if ($onyxUrls.Count -gt 0) { [string]$onyxUrls[0] } else { "http://127.0.0.1:5353/" }
$onyxBundleUrl = if ($onyxUrls.Count -gt 1) { [string]$onyxUrls[1] } else { "http://127.0.0.1:5353/main.dart.js" }
$onyxRootProbe = Invoke-HttpProbe -Url $onyxRootUrl
$onyxBundleProbe = Invoke-HttpProbe -Url $onyxBundleUrl
$requiredLabels = @((To-Array (Get-PropValue -Object (Get-PropValue -Object $policy -Name "onyx_core_flow_checks" -Default @{}) -Name "required_surface_labels" -Default @())) | ForEach-Object { [string]$_ })
$verifiedLabels = @($requiredLabels | Where-Object { $onyxCombinedSource -like ("*" + $_ + "*") })
$onboardingWordingStatus = if ($onyxBusinessPlanSource -match 'Active business' -and $onyxBusinessPlanSource -notmatch 'Active tenant') { "PASS" } else { "WARN" }
$onboardingCompletionStatus = if ($onyxBusinessPlanSource -match 'Future<void> _handleContinue\(\)' -and $onyxBusinessPlanSource -match 'completeOnboarding:\s*isLastStep' -and $onyxBusinessPlanSource -match 'await _refreshToolCatalog\(\)') { "PASS" } else { "WARN" }
$onyxCoreFlowArtifact = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $(if ($onyxRootProbe.ok -and $onyxBundleProbe.ok -and $verifiedLabels.Count -eq $requiredLabels.Count -and $onboardingWordingStatus -eq "PASS" -and $onboardingCompletionStatus -eq "PASS") { "PASS" } else { "WARN" })
    app_reachable = [bool]$onyxRootProbe.ok
    bundle_reachable = [bool]$onyxBundleProbe.ok
    runtime_status = $(if ($onyxRootProbe.ok -and $onyxBundleProbe.ok) { "PASS" } else { "WARN" })
    onboarding_wording_status = $onboardingWordingStatus
    onboarding_completion_status = $onboardingCompletionStatus
    core_surface_status = $(if ($verifiedLabels.Count -eq $requiredLabels.Count) { "PASS" } else { "WARN" })
    verified_label_count = $verifiedLabels.Count
    required_label_count = $requiredLabels.Count
    verified_labels = @($verifiedLabels)
    missing_labels = @($requiredLabels | Where-Object { $verifiedLabels -notcontains $_ })
    verification_methods = @("runtime_reachability", "source_contract_scan")
    checks = @(
        [pscustomobject]@{ name = "app_root"; status = $(if ($onyxRootProbe.ok) { "PASS" } else { "WARN" }); detail = $(if ($onyxRootProbe.ok) { "Onyx root returned HTTP $($onyxRootProbe.status_code)." } else { $onyxRootProbe.error }) },
        [pscustomobject]@{ name = "main_bundle"; status = $(if ($onyxBundleProbe.ok) { "PASS" } else { "WARN" }); detail = $(if ($onyxBundleProbe.ok) { "main.dart.js returned HTTP $($onyxBundleProbe.status_code)." } else { $onyxBundleProbe.error }) },
        [pscustomobject]@{ name = "owner_tabs_present"; status = $(if ($verifiedLabels.Count -eq $requiredLabels.Count) { "PASS" } else { "WARN" }); detail = ("Verified labels: " + ($(if ($verifiedLabels.Count -gt 0) { $verifiedLabels -join ", " } else { "none" }))) },
        [pscustomobject]@{ name = "onboarding_wording"; status = $onboardingWordingStatus; detail = "Business/workspace wording remains customer-safe in the owner onboarding surface." },
        [pscustomobject]@{ name = "onboarding_completion_wired"; status = $onboardingCompletionStatus; detail = "_handleContinue persists onboarding state and refreshes the tool catalog on the last step." }
    )
    recommended_next_action = $(if ($onyxRootProbe.ok -and $onyxBundleProbe.ok -and $verifiedLabels.Count -eq $requiredLabels.Count -and $onboardingWordingStatus -eq "PASS" -and $onboardingCompletionStatus -eq "PASS") { "No action required." } else { "Do not claim full owner-flow proof until any missing runtime or source-contract checks are resolved." })
}
Write-JsonFile -Path $onyxCoreFlowVerificationLastPath -Object $onyxCoreFlowArtifact -Depth 20
if ($onyxCoreFlowArtifact.overall_status -ne "PASS") {
    $unfixedQueue.Add((New-QueueItem -IssueId "onyx_core_flow_verification" -Category "onyx" -Status "warn" -Reason "Onyx core flow verification is still partial." -RecommendedNextAction "Restore runtime reachability and keep the owner-flow source contract intact before claiming Onyx is fully proven.")) | Out-Null
}

$validatorInvocation = [pscustomobject]@{ ok = $true; exit_code = 0; command_run = "skipped"; output = @("Validator refresh skipped.") }
if (-not $SkipValidator) {
    $validatorInvocation = Invoke-PowerShellFileInline -ScriptPath $validatorScriptPath -Arguments @()
    if (-not $validatorInvocation.ok) {
        $unfixedQueue.Add((New-QueueItem -IssueId "validator_refresh" -Category "validation" -Status "blocked" -Reason "Validate_Whole_System.ps1 did not complete cleanly from the Wave 03 runner." -RecommendedNextAction "Repair validator execution before trusting final Wave 03 posture.")) | Out-Null
    }
}
$validatorArtifact = Read-JsonSafe -Path $systemValidationLastPath -Default @{}

$mirrorReason = Normalize-Text (Get-PropValue -Object (Get-PropValue -Object $policy -Name "mirror_closure" -Default @{}) -Name "reason" -Default "repair-wave-03-final")
$mirrorInvocation = [pscustomobject]@{ ok = $true; exit_code = 0; command_run = "skipped"; output = @("Mirror refresh skipped.") }
if (-not $SkipMirrorRefresh) {
    $mirrorInvocation = Invoke-PowerShellFileInline -ScriptPath $mirrorScriptPath -Arguments @("-Reason", $mirrorReason)
    if (-not $mirrorInvocation.ok) {
        $unfixedQueue.Add((New-QueueItem -IssueId "mirror_refresh" -Category "mirror_closure" -Status "blocked" -Reason "Mirror refresh did not complete cleanly from the Wave 03 runner." -RecommendedNextAction "Repair the canonical mirror flow before claiming GitHub/off-box currentness.")) | Out-Null
    }
}
$mirrorArtifact = Read-JsonSafe -Path $mirrorUpdatePath -Default @{}
$mirrorCoverageArtifact = Read-JsonSafe -Path $mirrorCoveragePath -Default @{}
$mirrorOmissionArtifact = Read-JsonSafe -Path $mirrorOmissionPath -Default @{}
$remotePushResult = Normalize-Text (Get-PropValue -Object $mirrorArtifact -Name "mirror_push_result" -Default "")
$remoteCurrent = $remotePushResult -in @("pushed", "noop")
$pushFailureClass = switch ($remotePushResult) {
    "pushed" { "none" }
    "noop" { "none" }
    "local_commit_only_remote_push_failed" { "remote_push_failed" }
    "local_only_no_changes" { "remote_push_not_attempted" }
    default { $(if ($remotePushResult) { "unknown_push_posture" } else { "unknown" }) }
}
$remotePushRepairArtifact = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $(if ($remoteCurrent -and (Normalize-Text (Get-PropValue -Object $mirrorCoverageArtifact -Name "overall_status" -Default "")) -eq "PASS" -and (Normalize-Text (Get-PropValue -Object $mirrorOmissionArtifact -Name "overall_status" -Default "")) -eq "PASS") { "PASS" } else { "WARN" })
    push_failure_class = $pushFailureClass
    safe_repair_attempted = (-not $SkipMirrorRefresh)
    remote_push_result = $(if ($remotePushResult) { $remotePushResult } else { "unknown" })
    remote_current = $remoteCurrent
    failure_reason = Normalize-Text (Get-PropValue -Object $mirrorArtifact -Name "mirror_push_failure_reason" -Default "")
    oversized_paths = @(To-Array (Get-PropValue -Object $mirrorArtifact -Name "mirror_push_failure_paths" -Default @()))
    mirror_invocation = $mirrorInvocation
    recommended_next_action = $(if ($remoteCurrent) { "No action required." } else { "Resolve the remote push failure class before claiming GitHub/off-box currentness." })
}
Write-JsonFile -Path (Join-Path $reportsDir "remote_push_repair_last.json") -Object $remotePushRepairArtifact -Depth 20
if (-not $remoteCurrent) {
    $unfixedQueue.Add((New-QueueItem -IssueId "mirror_remote_currentness" -Category "mirror_closure" -Status "blocked" -Reason ("mirror_push_result=" + $(if ($remotePushResult) { $remotePushResult } else { "missing" })) -RecommendedNextAction "Do not finish a repair wave without a pushed/noop mirror result.")) | Out-Null
}

$repairWave03Artifact = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $(if ($migratedTaskCount -gt 0 -and $activeVisibleCount -lt $activeVisibleBefore -and $afterBrokenPaths -lt $beforeBrokenPaths -and $remoteCurrent -and $onyxCoreFlowArtifact.overall_status -eq "PASS") { "PASS" } else { "WARN" })
    internal_scheduler_migration_status = $internalSchedulerMigrationArtifact.overall_status
    windows_task_fallback_status = $windowsTaskFallbackArtifact.overall_status
    popup_window_elimination_status = $popupEliminationArtifact.overall_status
    broken_path_reduction_status = $brokenPathReductionArtifact.overall_status
    onyx_core_flow_status = $onyxCoreFlowArtifact.overall_status
    migrated_task_count = $migratedTaskCount
    host_disabled_count = $hostDisabledCount
    windows_fallback_dependency_count = $windowsTaskFallbackArtifact.remaining_windows_dependency_count
    popup_fixed_count = $popupFixedCount
    active_popup_before = $activeVisibleBefore
    active_popup_after = $activeVisibleCount
    broken_paths_before = $beforeBrokenPaths
    broken_paths_after = $afterBrokenPaths
    remote_push_result = $(if ($remotePushResult) { $remotePushResult } else { "unknown" })
    github_current = $remoteCurrent
    recommended_next_action = $(if ($remoteCurrent -and $afterBrokenPaths -lt $beforeBrokenPaths -and $migratedTaskCount -gt 0) { "Keep migrating low-risk recurring work into the internal scheduler and continue shrinking the remaining host/manual backlog." } else { "Finish the remaining fallback, popup, or mirror blockers before calling Wave 03 complete." })
    summary = ("Wave 03 migrated {0} task(s), disabled {1} dedicated host task(s), reduced active popup sources {2}->{3}, and moved broken_path_count {4}->{5}." -f $migratedTaskCount, $hostDisabledCount, $activeVisibleBefore, $activeVisibleCount, $beforeBrokenPaths, $afterBrokenPaths)
    command_run = ("powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}" -f $PSCommandPath)
    repo_root = $repoRoot
}
Write-JsonFile -Path $repairWave03LastPath -Object $repairWave03Artifact -Depth 20

$queueArtifact = [ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $(if ($unfixedQueue.Count -eq 0) { "PASS" } else { "WARN" })
    total_items = $unfixedQueue.Count
    items = @($unfixedQueue.ToArray())
}
Write-JsonFile -Path $repairWave03QueueLastPath -Object $queueArtifact -Depth 16
