[CmdletBinding()]
param(
    [ValidateSet('proposal', 'autoapply')]
    [string]$Mode = 'proposal',

    [int]$MaxSteps = 3,

    [ValidateSet('R0', 'R1')]
    [string]$RiskMax = 'R1'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$script:LogsDir = Join-Path $script:RepoRoot 'logs'
$script:StateKnowledgeDir = Join-Path $script:RepoRoot 'state\knowledge'
$script:NotificationsPath = Join-Path $script:StateKnowledgeDir 'notifications.jsonl'
$script:PlanPath = Join-Path $script:StateKnowledgeDir 'mason_teacher_plan_latest.json'
$script:ConfigPath = Join-Path $script:RepoRoot 'state\config\codex_autopilot.json'
$script:SmokeScriptPath = Join-Path $script:RepoRoot 'tools\SmokeTest_Mason2.ps1'
$script:TimestampUtc = (Get-Date).ToUniversalTime()
$script:TimestampFile = $script:TimestampUtc.ToString('yyyyMMdd_HHmmss')
$script:LogRelativePath = ('logs\codex_autopilot_{0}.log' -f $script:TimestampFile)
$script:LogPath = Join-Path $script:RepoRoot $script:LogRelativePath

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-RunLog {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [string]$Level = 'INFO'
    )

    $stamp = (Get-Date).ToUniversalTime().ToString('o')
    $line = '[{0}] [{1}] {2}' -f $stamp, $Level.ToUpperInvariant(), $Message
    Add-Content -LiteralPath $script:LogPath -Value $line -Encoding UTF8
    Write-Host $line
}

function Normalize-RelativePath {
    param([string]$Path)

    if (-not $Path) { return '' }
    $normalized = $Path.Trim().Replace('\', '/')

    while ($normalized.StartsWith('./', [System.StringComparison]::Ordinal)) {
        $normalized = $normalized.Substring(2)
    }

    while ($normalized.StartsWith('/', [System.StringComparison]::Ordinal)) {
        $normalized = $normalized.Substring(1)
    }

    return $normalized
}

function Read-JsonBomSafe {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if (-not $raw) {
        return $null
    }

    if ($raw.Length -gt 0 -and [int][char]$raw[0] -eq 0xFEFF) {
        $raw = $raw.Substring(1)
    }

    if (-not $raw.Trim()) {
        return $null
    }

    return ($raw | ConvertFrom-Json -ErrorAction Stop)
}

function Ensure-Array {
    param($Value)

    if ($null -eq $Value) { return @() }
    if ($Value -is [string]) { return @($Value) }
    if ($Value -is [System.Collections.IEnumerable]) { return @($Value) }
    return @($Value)
}

function Get-ObjectPropertyValue {
    param(
        $Object,
        [string[]]$Names
    )

    if ($null -eq $Object) {
        return $null
    }

    foreach ($name in $Names) {
        if ($Object.PSObject.Properties.Name -contains $name) {
            return $Object.$name
        }
    }

    return $null
}

function Get-RiskScore {
    param($RiskValue)

    $riskRaw = [string]$RiskValue
    if (-not $riskRaw.Trim()) {
        return 0
    }

    $risk = $riskRaw.Trim().ToUpperInvariant()
    if ($risk -match '^R(\d+)$') {
        return [int]$Matches[1]
    }
    if ($risk -match '^\d+$') {
        return [int]$risk
    }

    switch ($risk.ToLowerInvariant()) {
        'observe_only' { return 0 }
        'low' { return 1 }
        'medium' { return 2 }
        'high' { return 3 }
        default { return 99 }
    }
}

function New-StringHashSet {
    return (New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase))
}

function Merge-UniquePaths {
    param([string[]]$Paths)

    $set = New-StringHashSet
    $output = New-Object System.Collections.Generic.List[string]

    foreach ($path in $Paths) {
        $normalized = Normalize-RelativePath -Path $path
        if (-not $normalized) { continue }
        if ($set.Add($normalized)) {
            $output.Add($normalized) | Out-Null
        }
    }

    return @($output)
}

function Get-NewPaths {
    param(
        [string[]]$Current,
        [string[]]$Baseline
    )

    $baselineSet = New-StringHashSet
    foreach ($item in $Baseline) {
        $normalized = Normalize-RelativePath -Path $item
        if ($normalized) {
            $baselineSet.Add($normalized) | Out-Null
        }
    }

    $newPaths = New-Object System.Collections.Generic.List[string]
    foreach ($item in $Current) {
        $normalized = Normalize-RelativePath -Path $item
        if (-not $normalized) { continue }
        if (-not $baselineSet.Contains($normalized)) {
            $newPaths.Add($normalized) | Out-Null
        }
    }

    return @($newPaths | Sort-Object -Unique)
}

function Invoke-GitLines {
    param(
        [Parameter(Mandatory = $true)][string[]]$Args,
        [switch]$AllowFailure
    )

    $output = & git -C $script:RepoRoot @Args 2>&1
    $exitCode = $LASTEXITCODE
    $lines = @()
    foreach ($line in $output) {
        $lines += [string]$line
    }

    if (-not $AllowFailure -and $exitCode -ne 0) {
        throw ('git {0} failed with exit code {1}: {2}' -f ($Args -join ' '), $exitCode, ($lines -join ' | '))
    }

    return [pscustomobject]@{
        ExitCode = $exitCode
        Output   = $lines
    }
}

function Get-ChangeSnapshot {
    $trackedResult = Invoke-GitLines -Args @('diff', '--name-only', 'HEAD')
    $untrackedResult = Invoke-GitLines -Args @('ls-files', '--others', '--exclude-standard')

    $tracked = @()
    foreach ($line in $trackedResult.Output) {
        $normalized = Normalize-RelativePath -Path $line
        if ($normalized) {
            $tracked += $normalized
        }
    }

    $untracked = @()
    foreach ($line in $untrackedResult.Output) {
        $normalized = Normalize-RelativePath -Path $line
        if ($normalized) {
            $untracked += $normalized
        }
    }

    $tracked = @($tracked | Sort-Object -Unique)
    $untracked = @($untracked | Sort-Object -Unique)
    $all = Merge-UniquePaths -Paths @($tracked + $untracked)

    return [pscustomobject]@{
        tracked   = $tracked
        untracked = $untracked
        all       = $all
    }
}

function Get-ComponentAgentRelativePaths {
    param([string]$RepoRootPath)

    $results = New-Object System.Collections.Generic.List[string]
    $componentDirs = @(Get-ChildItem -LiteralPath $RepoRootPath -Directory -Filter 'Component - *' -ErrorAction SilentlyContinue)

    foreach ($componentDir in $componentDirs) {
        $agentFiles = @(Get-ChildItem -LiteralPath $componentDir.FullName -Filter 'AGENTS.md' -File -Recurse -ErrorAction SilentlyContinue)
        foreach ($agentFile in $agentFiles) {
            $fullPath = [System.IO.Path]::GetFullPath($agentFile.FullName)
            if ($fullPath.StartsWith($RepoRootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                $relative = $fullPath.Substring($RepoRootPath.Length).TrimStart('\', '/')
                $normalized = Normalize-RelativePath -Path $relative
                if ($normalized) {
                    $results.Add($normalized) | Out-Null
                }
            }
        }
    }

    return @($results | Sort-Object -Unique)
}

function Test-AllowlistedPath {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [string[]]$ComponentAgentPaths
    )

    $normalized = (Normalize-RelativePath -Path $RelativePath).ToLowerInvariant()
    if (-not $normalized) {
        return [pscustomobject]@{ allowed = $true; reason = 'empty' }
    }

    foreach ($blockedToken in @('secrets', 'secret', 'key', 'token', '.env')) {
        if ($normalized.Contains($blockedToken)) {
            return [pscustomobject]@{ allowed = $false; reason = ('blocked_token:{0}' -f $blockedToken) }
        }
    }

    if ($normalized -eq 'start_mason_onyx_stack.ps1') {
        return [pscustomobject]@{ allowed = $true; reason = 'allowlist:file:start_mason_onyx_stack.ps1' }
    }
    if ($normalized -eq 'agents.md') {
        return [pscustomobject]@{ allowed = $true; reason = 'allowlist:file:agents.md' }
    }
    if ($normalized.StartsWith('tools/', [System.StringComparison]::Ordinal)) {
        return [pscustomobject]@{ allowed = $true; reason = 'allowlist:dir:tools' }
    }
    if ($normalized.StartsWith('athena/', [System.StringComparison]::Ordinal)) {
        return [pscustomobject]@{ allowed = $true; reason = 'allowlist:dir:athena' }
    }
    if ($normalized.StartsWith('component - onyx app/onyx_business_manager/', [System.StringComparison]::Ordinal)) {
        return [pscustomobject]@{ allowed = $true; reason = 'allowlist:dir:onyx_business_manager' }
    }
    if ($normalized.StartsWith('component - ', [System.StringComparison]::Ordinal) -and $normalized.EndsWith('/agents.md', [System.StringComparison]::Ordinal)) {
        return [pscustomobject]@{ allowed = $true; reason = 'allowlist:component_agents' }
    }

    foreach ($componentAgentPath in $ComponentAgentPaths) {
        $componentAgentNormalized = (Normalize-RelativePath -Path $componentAgentPath).ToLowerInvariant()
        if ($normalized -eq $componentAgentNormalized) {
            return [pscustomobject]@{ allowed = $true; reason = 'allowlist:component_agents' }
        }
    }

    return [pscustomobject]@{ allowed = $false; reason = 'outside_allowlist' }
}

function Invoke-SmokeTest {
    Write-RunLog -Message ('Running SmokeTest: powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File {0}' -f $script:SmokeScriptPath)
    $output = & powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $script:SmokeScriptPath 2>&1
    $exitCode = $LASTEXITCODE

    foreach ($line in $output) {
        Write-RunLog -Message ('[SmokeTest] {0}' -f [string]$line)
    }

    return [ordered]@{
        pass      = ($exitCode -eq 0)
        exit_code = $exitCode
    }
}

function Append-Notification {
    param(
        [Parameter(Mandatory = $true)][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][hashtable]$Context
    )

    Ensure-Directory -Path (Split-Path -Parent $script:NotificationsPath)

    $entry = [ordered]@{
        timestamp = (Get-Date).ToUniversalTime().ToString('o')
        level     = $Level
        component = 'codex_autopilot'
        message   = $Message
        context   = $Context
    }

    $jsonLine = $entry | ConvertTo-Json -Depth 20 -Compress
    Add-Content -LiteralPath $script:NotificationsPath -Value $jsonLine -Encoding UTF8
}

function Revert-NewChanges {
    param(
        [string[]]$TrackedPaths,
        [string[]]$UntrackedPaths
    )

    $trackedToRestore = @($TrackedPaths | Sort-Object -Unique)
    $untrackedToClean = @($UntrackedPaths | Sort-Object -Unique)

    if ($trackedToRestore.Count -gt 0) {
        Write-RunLog -Message ('Reverting tracked paths: {0}' -f ($trackedToRestore -join ', '))
        $restoreResult = Invoke-GitLines -Args (@('restore', '--source=HEAD', '--staged', '--worktree', '--') + $trackedToRestore) -AllowFailure
        foreach ($line in $restoreResult.Output) {
            Write-RunLog -Level 'WARN' -Message ('[git restore] {0}' -f $line)
        }
        if ($restoreResult.ExitCode -ne 0) {
            Write-RunLog -Level 'ERROR' -Message ('git restore failed during rollback (exit={0}).' -f $restoreResult.ExitCode)
        }
    }

    if ($untrackedToClean.Count -gt 0) {
        Write-RunLog -Message ('Cleaning untracked paths: {0}' -f ($untrackedToClean -join ', '))
        $cleanResult = Invoke-GitLines -Args (@('clean', '-fd', '--') + $untrackedToClean) -AllowFailure
        foreach ($line in $cleanResult.Output) {
            Write-RunLog -Level 'WARN' -Message ('[git clean] {0}' -f $line)
        }
        if ($cleanResult.ExitCode -ne 0) {
            Write-RunLog -Level 'ERROR' -Message ('git clean failed during rollback (exit={0}).' -f $cleanResult.ExitCode)
        }
    }
}

function Revert-AllowlistPaths {
    param([string[]]$AllowlistPathspecs)

    Write-RunLog -Message 'Reverting allowlist paths to HEAD (required failure rollback).'
    $restoreResult = Invoke-GitLines -Args (@('restore', '--source=HEAD', '--staged', '--worktree', '--') + $AllowlistPathspecs) -AllowFailure
    foreach ($line in $restoreResult.Output) {
        Write-RunLog -Level 'WARN' -Message ('[git restore] {0}' -f $line)
    }
    if ($restoreResult.ExitCode -ne 0) {
        Write-RunLog -Level 'ERROR' -Message ('git restore failed during allowlist rollback (exit={0}).' -f $restoreResult.ExitCode)
    }

    $untrackedAllowlist = Invoke-GitLines -Args (@('ls-files', '--others', '--exclude-standard', '--') + $AllowlistPathspecs) -AllowFailure
    $allowlistUntrackedPaths = @($untrackedAllowlist.Output | ForEach-Object { Normalize-RelativePath -Path $_ } | Where-Object { $_ })

    if ($allowlistUntrackedPaths.Count -gt 0) {
        Write-RunLog -Message 'Cleaning untracked files in allowlist paths (required failure rollback).'
        $cleanResult = Invoke-GitLines -Args (@('clean', '-fd', '--') + $AllowlistPathspecs) -AllowFailure
        foreach ($line in $cleanResult.Output) {
            Write-RunLog -Level 'WARN' -Message ('[git clean] {0}' -f $line)
        }
        if ($cleanResult.ExitCode -ne 0) {
            Write-RunLog -Level 'ERROR' -Message ('git clean failed during allowlist rollback (exit={0}).' -f $cleanResult.ExitCode)
        }
    }
    else {
        Write-RunLog -Message 'No untracked files in allowlist paths; git clean skipped.'
    }
}

function Build-CodexPrompt {
    param(
        [Parameter(Mandatory = $true)]$SelectedSteps,
        [Parameter(Mandatory = $true)][string]$RiskMaxLabel,
        [Parameter(Mandatory = $true)][int]$StepLimit
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('You are Codex running unattended in Mason2 autopilot mode.')
    $lines.Add('Goal: apply only scoped R0/R1 improvements from selected teacher steps with minimal diffs.')
    $lines.Add('')
    $lines.Add('Hard allowlist: only edit these paths:')
    $lines.Add('- tools/')
    $lines.Add('- athena/')
    $lines.Add('- Component - Onyx App/onyx_business_manager/')
    $lines.Add('- Start_Mason_Onyx_Stack.ps1')
    $lines.Add('- AGENTS.md and component AGENTS.md files')
    $lines.Add('')
    $lines.Add('Security constraints (hard stop):')
    $lines.Add('- Do NOT touch any path containing: secrets, secret, key, token, .env (case-insensitive).')
    $lines.Add('- Do NOT add feature creep, refactors, or unrelated edits.')
    $lines.Add('- Keep diffs minimal and directly tied to selected steps only.')
    $lines.Add('')
    $lines.Add(('Selected teacher steps (max {0}, risk <= {1}):' -f $StepLimit, $RiskMaxLabel))

    foreach ($step in $SelectedSteps) {
        $stepId = [string](Get-ObjectPropertyValue -Object $step -Names @('id'))
        $title = [string](Get-ObjectPropertyValue -Object $step -Names @('title'))
        $domain = [string](Get-ObjectPropertyValue -Object $step -Names @('domain'))
        $risk = [string](Get-ObjectPropertyValue -Object $step -Names @('risk_level'))
        $description = [string](Get-ObjectPropertyValue -Object $step -Names @('description'))
        $actions = Ensure-Array (Get-ObjectPropertyValue -Object $step -Names @('actions'))

        $lines.Add(('Step ID: {0}' -f $stepId))
        $lines.Add(('Title: {0}' -f $title))
        $lines.Add(('Domain: {0}; Risk: {1}' -f $domain, $risk))
        $lines.Add(('Description: {0}' -f $description))

        if ($actions.Count -gt 0) {
            $lines.Add('Actions:')
            foreach ($action in $actions) {
                $actionText = [string]$action
                if ($actionText.Trim()) {
                    $lines.Add(('- {0}' -f $actionText.Trim()))
                }
            }
        }
        else {
            $lines.Add('Actions: none listed')
        }

        $lines.Add('')
    }

    $lines.Add('Verification command policy (strict):')
    $lines.Add('Run ONLY this command for verification, and run it after edits:')
    $lines.Add('powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\SmokeTest_Mason2.ps1')
    $lines.Add('')
    $lines.Add('Output requirement:')
    $lines.Add('- Apply changes directly and keep output concise.')
    $lines.Add('- If a selected step requires out-of-allowlist changes, skip it.')

    return ($lines -join [Environment]::NewLine)
}

function Get-CurrentBranchName {
    $branchResult = Invoke-GitLines -Args @('rev-parse', '--abbrev-ref', 'HEAD')
    if ($branchResult.Output.Count -lt 1) {
        return ''
    }
    return $branchResult.Output[0].Trim()
}

Ensure-Directory -Path $script:LogsDir
Ensure-Directory -Path $script:StateKnowledgeDir
New-Item -ItemType File -Path $script:LogPath -Force | Out-Null

$runContext = [ordered]@{
    mode              = $Mode
    selected_step_ids = @()
    smoke_before      = $null
    smoke_after       = $null
    changed_files     = @()
    commit_hash       = $null
    log_path          = $script:LogRelativePath
}

Write-RunLog -Message ('Codex autopilot started. mode={0} max_steps={1} risk_max={2}' -f $Mode, $MaxSteps, $RiskMax)

$componentAgentPaths = Get-ComponentAgentRelativePaths -RepoRootPath $script:RepoRoot
$allowlistPathspecs = @(
    'tools',
    'athena',
    'Component - Onyx App/onyx_business_manager',
    'Start_Mason_Onyx_Stack.ps1',
    'AGENTS.md'
)
$allowlistPathspecs = Merge-UniquePaths -Paths @($allowlistPathspecs + $componentAgentPaths)

$statusArgs = @('status', '--porcelain', '--') + $allowlistPathspecs
$statusResult = Invoke-GitLines -Args $statusArgs
$dirtyAllowlistLines = @($statusResult.Output | Where-Object { $_ -and $_.Trim() })

if ($dirtyAllowlistLines.Count -gt 0) {
    Write-RunLog -Level 'ERROR' -Message 'Clean-tree gate failed in allowlisted code paths.'
    foreach ($line in $dirtyAllowlistLines) {
        Write-RunLog -Level 'ERROR' -Message ('[dirty] {0}' -f $line)
    }
    Append-Notification -Level 'error' -Message 'Autopilot refused to run: allowlisted code paths are dirty.' -Context $runContext
    exit 1
}

if (Test-Path -LiteralPath $script:ConfigPath) {
    try {
        $config = Read-JsonBomSafe -Path $script:ConfigPath
        if ($null -ne $config) {
            if (-not $PSBoundParameters.ContainsKey('Mode')) {
                $cfgModeValue = [string](Get-ObjectPropertyValue -Object $config -Names @('mode', 'Mode'))
                if ($cfgModeValue.Trim()) {
                    $cfgMode = $cfgModeValue.Trim().ToLowerInvariant()
                    if ($cfgMode -in @('proposal', 'autoapply')) {
                        $Mode = $cfgMode
                    }
                }
            }

            if (-not $PSBoundParameters.ContainsKey('MaxSteps')) {
                $cfgMaxStepsValue = Get-ObjectPropertyValue -Object $config -Names @('max_steps', 'MaxSteps')
                $cfgMaxSteps = 0
                if ($null -ne $cfgMaxStepsValue -and [int]::TryParse([string]$cfgMaxStepsValue, [ref]$cfgMaxSteps)) {
                    $MaxSteps = $cfgMaxSteps
                }
            }

            if (-not $PSBoundParameters.ContainsKey('RiskMax')) {
                $cfgRiskValue = [string](Get-ObjectPropertyValue -Object $config -Names @('risk_max', 'RiskMax'))
                if ($cfgRiskValue.Trim()) {
                    $cfgRisk = $cfgRiskValue.Trim().ToUpperInvariant()
                    if ($cfgRisk -in @('R0', 'R1')) {
                        $RiskMax = $cfgRisk
                    }
                }
            }
        }
    }
    catch {
        Write-RunLog -Level 'WARN' -Message ('Config parse failed at {0}: {1}. Using parameter defaults.' -f $script:ConfigPath, $_.Exception.Message)
    }
}

if ($MaxSteps -lt 1) { $MaxSteps = 1 }
$RiskMax = $RiskMax.ToUpperInvariant()
$runContext.mode = $Mode

Write-RunLog -Message ('Effective settings. mode={0} max_steps={1} risk_max={2}' -f $Mode, $MaxSteps, $RiskMax)

$baselineSnapshot = Get-ChangeSnapshot

$smokeBefore = Invoke-SmokeTest
$runContext.smoke_before = $smokeBefore

if (-not $smokeBefore.pass) {
    Write-RunLog -Level 'ERROR' -Message 'Pre-flight SmokeTest failed.'
    Append-Notification -Level 'error' -Message 'Autopilot aborted: pre-flight SmokeTest failed.' -Context $runContext
    exit 1
}

if (-not (Test-Path -LiteralPath $script:PlanPath)) {
    Write-RunLog -Message ('Teacher plan file missing at {0}.' -f $script:PlanPath)
    Append-Notification -Level 'info' -Message 'Nothing to do' -Context $runContext
    exit 0
}

$plan = $null
try {
    $plan = Read-JsonBomSafe -Path $script:PlanPath
}
catch {
    Write-RunLog -Level 'ERROR' -Message ('Failed to parse teacher plan: {0}' -f $_.Exception.Message)
    Append-Notification -Level 'error' -Message 'Autopilot aborted: failed to parse teacher plan JSON.' -Context $runContext
    exit 1
}

$steps = Ensure-Array (Get-ObjectPropertyValue -Object $plan -Names @('steps'))
if ($steps.Count -eq 0) {
    Write-RunLog -Message 'Teacher plan has no steps.'
    Append-Notification -Level 'info' -Message 'Nothing to do' -Context $runContext
    exit 0
}

$riskMaxScore = Get-RiskScore -RiskValue $RiskMax
$selectedSteps = New-Object System.Collections.Generic.List[object]

foreach ($step in $steps) {
    if ($null -eq $step) { continue }

    $riskLabel = [string](Get-ObjectPropertyValue -Object $step -Names @('risk_level', 'risk'))
    $riskScore = Get-RiskScore -RiskValue $riskLabel
    if ($riskScore -gt $riskMaxScore) { continue }

    $domain = [string](Get-ObjectPropertyValue -Object $step -Names @('domain', 'teacher_domain'))
    $domainNorm = $domain.Trim().ToLowerInvariant()
    if ($domainNorm -notin @('mason', 'athena', 'onyx')) { continue }

    $description = [string](Get-ObjectPropertyValue -Object $step -Names @('description'))
    if (-not $description.Trim()) { continue }
    if (-not $description.ToLowerInvariant().Contains('why this helps:')) { continue }

    $selectedSteps.Add($step) | Out-Null

    if ($selectedSteps.Count -ge $MaxSteps) {
        break
    }
}

if ($selectedSteps.Count -eq 0) {
    Write-RunLog -Message 'No eligible steps found after filters.'
    Append-Notification -Level 'info' -Message 'Nothing to do' -Context $runContext
    exit 0
}

$selectedStepIds = New-Object System.Collections.Generic.List[string]
foreach ($step in $selectedSteps) {
    $stepId = [string](Get-ObjectPropertyValue -Object $step -Names @('id'))
    if ($stepId.Trim()) {
        $selectedStepIds.Add($stepId.Trim()) | Out-Null
    }
}
$runContext.selected_step_ids = @($selectedStepIds)

$codexCommand = Get-Command codex -ErrorAction SilentlyContinue
if (-not $codexCommand) {
    Write-RunLog -Level 'ERROR' -Message 'codex executable not found in PATH.'
    Append-Notification -Level 'error' -Message 'Autopilot failed: codex executable not found.' -Context $runContext
    exit 1
}

$promptText = Build-CodexPrompt -SelectedSteps $selectedSteps -RiskMaxLabel $RiskMax -StepLimit $MaxSteps
Add-Content -LiteralPath $script:LogPath -Value ('=== CODEX PROMPT BEGIN ==={0}{1}{0}=== CODEX PROMPT END ===' -f [Environment]::NewLine, $promptText) -Encoding UTF8

Write-RunLog -Message 'Invoking codex exec non-interactively.'
$codexOutput = $promptText | & codex exec --cd $script:RepoRoot --sandbox workspace-write --ask-for-approval never --json - 2>&1
$codexExit = $LASTEXITCODE

foreach ($line in $codexOutput) {
    Write-RunLog -Message ('[codex] {0}' -f [string]$line)
}

Write-RunLog -Message ('codex exec completed with exit code {0}.' -f $codexExit)

$snapshotAfterCodex = Get-ChangeSnapshot
$newTrackedAfterCodex = Get-NewPaths -Current $snapshotAfterCodex.tracked -Baseline $baselineSnapshot.tracked
$newUntrackedAfterCodex = Get-NewPaths -Current $snapshotAfterCodex.untracked -Baseline $baselineSnapshot.untracked
$newAllAfterCodex = Merge-UniquePaths -Paths @($newTrackedAfterCodex + $newUntrackedAfterCodex)
$runContext.changed_files = $newAllAfterCodex

$requiredDiffCommandResult = Invoke-GitLines -Args @('diff', '--name-only') -AllowFailure
if ($requiredDiffCommandResult.Output.Count -gt 0) {
    foreach ($line in $requiredDiffCommandResult.Output) {
        Write-RunLog -Message ('[git diff --name-only] {0}' -f $line)
    }
}
else {
    Write-RunLog -Message '[git diff --name-only] (no changes)'
}

$allowlistViolations = New-Object System.Collections.Generic.List[string]
foreach ($changedPath in $newAllAfterCodex) {
    $allowResult = Test-AllowlistedPath -RelativePath $changedPath -ComponentAgentPaths $componentAgentPaths
    if (-not $allowResult.allowed) {
        $allowlistViolations.Add(('{0} ({1})' -f $changedPath, $allowResult.reason)) | Out-Null
    }
}

if ($allowlistViolations.Count -gt 0) {
    Write-RunLog -Level 'ERROR' -Message 'Allowlist gate failed after codex run.'
    foreach ($violation in $allowlistViolations) {
        Write-RunLog -Level 'ERROR' -Message ('[allowlist_violation] {0}' -f $violation)
    }

    Revert-NewChanges -TrackedPaths $newTrackedAfterCodex -UntrackedPaths $newUntrackedAfterCodex
    Append-Notification -Level 'error' -Message 'Autopilot failed: codex changed files outside allowlist; changes reverted.' -Context $runContext
    exit 1
}

if ($codexExit -ne 0) {
    Write-RunLog -Level 'ERROR' -Message 'codex exec failed; reverting detected changes.'
    Revert-NewChanges -TrackedPaths $newTrackedAfterCodex -UntrackedPaths $newUntrackedAfterCodex
    Append-Notification -Level 'error' -Message 'Autopilot failed: codex exec returned a non-zero exit code; changes reverted.' -Context $runContext
    exit 1
}

$smokeAfter = Invoke-SmokeTest
$runContext.smoke_after = $smokeAfter

if (-not $smokeAfter.pass) {
    Write-RunLog -Level 'ERROR' -Message 'Post-change SmokeTest failed; running automatic revert.'
    Revert-AllowlistPaths -AllowlistPathspecs $allowlistPathspecs

    $afterRevertSnapshot = Get-ChangeSnapshot
    $runContext.changed_files = Get-NewPaths -Current $afterRevertSnapshot.all -Baseline $baselineSnapshot.all

    Append-Notification -Level 'error' -Message ('Autopilot failed: post-change SmokeTest failed and rollback was applied. Log: {0}' -f $script:LogRelativePath) -Context $runContext
    exit 1
}

$finalSnapshot = Get-ChangeSnapshot
$finalNewTracked = Get-NewPaths -Current $finalSnapshot.tracked -Baseline $baselineSnapshot.tracked
$finalNewUntracked = Get-NewPaths -Current $finalSnapshot.untracked -Baseline $baselineSnapshot.untracked
$finalNewAll = Merge-UniquePaths -Paths @($finalNewTracked + $finalNewUntracked)
$runContext.changed_files = $finalNewAll

if ($finalNewAll.Count -eq 0) {
    Write-RunLog -Message 'No changes detected after codex run and smoke tests.'
    Append-Notification -Level 'info' -Message ('Autopilot completed successfully with no changes. Log: {0}' -f $script:LogRelativePath) -Context $runContext
    exit 0
}

$startingBranch = Get-CurrentBranchName
$proposalBranch = $null

if ($Mode -eq 'proposal') {
    $proposalBranch = ('autopilot/{0}' -f $script:TimestampFile)
    $branchCounter = 1

    while ((Invoke-GitLines -Args @('show-ref', '--verify', '--quiet', ('refs/heads/{0}' -f $proposalBranch)) -AllowFailure).ExitCode -eq 0) {
        $proposalBranch = ('autopilot/{0}-{1}' -f $script:TimestampFile, $branchCounter)
        $branchCounter++
    }

    Write-RunLog -Message ('Creating proposal branch: {0}' -f $proposalBranch)
    $switchResult = Invoke-GitLines -Args @('switch', '-c', $proposalBranch) -AllowFailure
    if ($switchResult.ExitCode -ne 0) {
        $switchResult = Invoke-GitLines -Args @('checkout', '-b', $proposalBranch) -AllowFailure
    }

    if ($switchResult.ExitCode -ne 0) {
        Write-RunLog -Level 'ERROR' -Message 'Failed to create proposal branch; reverting changes.'
        Revert-NewChanges -TrackedPaths $finalNewTracked -UntrackedPaths $finalNewUntracked
        Append-Notification -Level 'error' -Message 'Autopilot failed: could not create proposal branch; changes reverted.' -Context $runContext
        exit 1
    }
}
elseif ($Mode -eq 'autoapply') {
    $currentBranch = Get-CurrentBranchName
    if ($currentBranch -ne 'main') {
        Write-RunLog -Level 'ERROR' -Message ('Autoapply requires branch "main"; current branch is "{0}". Reverting changes.' -f $currentBranch)
        Revert-NewChanges -TrackedPaths $finalNewTracked -UntrackedPaths $finalNewUntracked
        Append-Notification -Level 'error' -Message ('Autopilot failed: autoapply mode requires current branch to be main. Log: {0}' -f $script:LogRelativePath) -Context $runContext
        exit 1
    }
}

Write-RunLog -Message 'Staging autopilot changes for commit.'
$addResult = Invoke-GitLines -Args (@('add', '--') + $finalNewAll) -AllowFailure
if ($addResult.ExitCode -ne 0) {
    Write-RunLog -Level 'ERROR' -Message 'git add failed; reverting changes.'
    Revert-NewChanges -TrackedPaths $finalNewTracked -UntrackedPaths $finalNewUntracked
    Append-Notification -Level 'error' -Message 'Autopilot failed: git add failed; changes reverted.' -Context $runContext
    exit 1
}

$stepIdSummary = 'none'
if ($runContext.selected_step_ids.Count -gt 0) {
    $stepIdSummary = ($runContext.selected_step_ids -join ',')
}

$commitMessage = ('codex_autopilot {0} {1} [{2}]' -f $Mode, $script:TimestampFile, $stepIdSummary)
Write-RunLog -Message ('Creating commit: {0}' -f $commitMessage)
$commitResult = Invoke-GitLines -Args @('commit', '-m', $commitMessage) -AllowFailure
if ($commitResult.ExitCode -ne 0) {
    Write-RunLog -Level 'ERROR' -Message 'git commit failed; reverting changes.'
    if ($Mode -eq 'proposal' -and $startingBranch.Trim()) {
        [void](Invoke-GitLines -Args @('switch', $startingBranch) -AllowFailure)
    }
    Revert-NewChanges -TrackedPaths $finalNewTracked -UntrackedPaths $finalNewUntracked
    Append-Notification -Level 'error' -Message 'Autopilot failed: git commit failed; changes reverted.' -Context $runContext
    exit 1
}

$commitHashResult = Invoke-GitLines -Args @('rev-parse', '--short', 'HEAD')
if ($commitHashResult.Output.Count -gt 0) {
    $runContext.commit_hash = $commitHashResult.Output[0].Trim()
}

if ($Mode -eq 'proposal' -and $proposalBranch) {
    Write-RunLog -Message ('Proposal commit created on branch {0} with hash {1}.' -f $proposalBranch, $runContext.commit_hash)
    Append-Notification -Level 'info' -Message ('Autopilot proposal succeeded. Branch={0} Commit={1} Log={2}' -f $proposalBranch, $runContext.commit_hash, $script:LogRelativePath) -Context $runContext
}
else {
    Write-RunLog -Message ('Autoapply commit created on main with hash {0}.' -f $runContext.commit_hash)
    Append-Notification -Level 'info' -Message ('Autopilot autoapply succeeded. Commit={0} Log={1}' -f $runContext.commit_hash, $script:LogRelativePath) -Context $runContext
}

exit 0
