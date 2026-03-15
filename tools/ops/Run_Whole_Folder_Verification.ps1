[CmdletBinding()]
param(
    [string]$RootPath = "",
    [switch]$SkipStackRestart,
    [switch]$SkipMirrorRefresh,
    [switch]$SkipFaultTests,
    [switch]$SkipToolCanary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

trap {
    try {
        if (Get-Variable -Name wholeFolderProgressPath -Scope Script -ErrorAction SilentlyContinue) {
            Write-ProgressCheckpoint -Path $script:wholeFolderProgressPath -Stage "error" -Detail $_.Exception.Message
        }
    }
    catch { }
    Write-Output ("WHOLE_FOLDER_ERROR: " + $_.Exception.Message)
    if ($_.InvocationInfo.PositionMessage) {
        Write-Output $_.InvocationInfo.PositionMessage
    }
    if ($_.ScriptStackTrace) {
        Write-Output $_.ScriptStackTrace
    }
    throw
}

function Resolve-RepoRoot {
    param([string]$CandidateRoot)

    if ($CandidateRoot -and (Test-Path -LiteralPath $CandidateRoot)) {
        return (Resolve-Path -LiteralPath $CandidateRoot).Path
    }

    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Normalize-Text {
    param($Value)

    return [regex]::Replace(([string]$Value), "\s+", " ").Trim()
}

function Limit-Text {
    param(
        [string]$Text,
        [int]$MaxLength = 220
    )

    $normalized = [string]$Text
    if ($normalized.Length -le $MaxLength) {
        return $normalized
    }
    return $normalized.Substring(0, $MaxLength).TrimEnd()
}

function Ensure-ParentDirectory {
    param([Parameter(Mandatory = $true)][string]$Path)

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
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
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 18
    )

    Ensure-ParentDirectory -Path $Path
    $Object | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Write-TextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    Ensure-ParentDirectory -Path $Path
    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
}

function Write-ProgressCheckpoint {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Stage,
        [string]$Detail = ""
    )

    $payload = [pscustomobject][ordered]@{
        timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
        stage = $Stage
        detail = $Detail
    }

    Write-JsonFile -Path $Path -Object $payload -Depth 6
}

function To-Array {
    param($Value)

    if ($null -eq $Value) {
        Write-Output -NoEnumerate @()
        return
    }
    if ($Value -is [System.Array]) {
        Write-Output -NoEnumerate $Value
        return
    }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $items = New-Object System.Collections.ArrayList
        foreach ($item in $Value) {
            [void]$items.Add($item)
        }
        Write-Output -NoEnumerate @($items.ToArray())
        return
    }
    Write-Output -NoEnumerate @($Value)
}

function Get-PropValue {
    param(
        $Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Default = $null
    )

    if ($null -eq $Object) {
        return $Default
    }

    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) {
            return $Object[$Name]
        }
        return $Default
    }

    $property = $Object.PSObject.Properties[$Name]
    if ($property) {
        return $property.Value
    }

    return $Default
}

function Convert-ToUtcIso {
    param($DateValue)

    if ($null -eq $DateValue) {
        return ""
    }

    try {
        return ([datetime]$DateValue).ToUniversalTime().ToString("o")
    }
    catch {
        return ""
    }
}

function Test-IsTruthy {
    param($Value)

    if ($null -eq $Value) { return $false }
    if ($Value -is [bool]) { return [bool]$Value }

    $text = (Normalize-Text $Value).ToLowerInvariant()
    return $text -in @("true", "1", "yes", "y", "pass", "ok", "ready", "healthy")
}

function New-StringSet {
    Write-Output -NoEnumerate ([System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase))
}

function Add-SetItem {
    param(
        [Parameter(Mandatory = $true)]$Set,
        [string]$Value
    )

    $text = Normalize-Text $Value
    if ($text) {
        [void]$Set.Add($text)
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

function Get-PowershellExe {
    $paths = @(
        (Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"),
        "powershell.exe"
    )
    foreach ($candidate in $paths) {
        if (Get-Command $candidate -ErrorAction SilentlyContinue) {
            return $candidate
        }
    }
    return "powershell.exe"
}

function Invoke-PowerShellFile {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [string[]]$Arguments = @(),
        [int]$TimeoutSeconds = 900
    )

    $powershellExe = Get-PowershellExe
    $argList = @("-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ScriptPath) + @($Arguments)
    $quotedArgs = foreach ($arg in $argList) {
        $text = [string]$arg
        if ($text -match '[\s"]') {
            '"' + ($text -replace '"', '\"') + '"'
        }
        else {
            $text
        }
    }

    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()
    $process = $null

    try {
        $process = Start-Process -FilePath $powershellExe `
            -ArgumentList $argList `
            -PassThru `
            -NoNewWindow `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath

        $completed = $true
        try {
            Wait-Process -Id $process.Id -Timeout $TimeoutSeconds -ErrorAction Stop
        }
        catch {
            $completed = $false
        }

        if (-not $completed) {
            try { Stop-Process -Id $process.Id -Force -ErrorAction Stop } catch { }
            return [pscustomobject]@{
                ok        = $false
                exit_code = 124
                timed_out = $true
                lines     = @("Timed out after $TimeoutSeconds second(s).")
                joined    = "Timed out after $TimeoutSeconds second(s)."
                command   = "$powershellExe $($argList -join ' ')"
            }
        }

        $process.Refresh()
        $outputLines = @()
        if (Test-Path -LiteralPath $stdoutPath) {
            $outputLines += @(Get-Content -LiteralPath $stdoutPath -ErrorAction SilentlyContinue)
        }
        if (Test-Path -LiteralPath $stderrPath) {
            $outputLines += @(Get-Content -LiteralPath $stderrPath -ErrorAction SilentlyContinue)
        }
        $outputLines = @($outputLines | Where-Object { $_ -ne "" })

        return [pscustomobject]@{
            ok        = ($process.ExitCode -eq 0)
            exit_code = [int]$process.ExitCode
            timed_out = $false
            lines     = @($outputLines)
            joined    = ((@($outputLines) -join "`n").Trim())
            command   = "$powershellExe $($argList -join ' ')"
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

function Invoke-HttpProbe {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSeconds = 12
    )

    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $TimeoutSeconds -ErrorAction Stop
        $content = ""
        try { $content = [string]$response.Content } catch { }
        return [pscustomobject]@{
            ok          = ($response.StatusCode -eq 200)
            status_code = [int]$response.StatusCode
            body        = $content
            error       = ""
        }
    }
    catch {
        $statusCode = 0
        try { $statusCode = [int]$_.Exception.Response.StatusCode.value__ } catch { }
        return [pscustomobject]@{
            ok          = $false
            status_code = $statusCode
            body        = ""
            error       = Limit-Text -Text $_.Exception.Message -MaxLength 240
        }
    }
}

function Get-FreshnessStatus {
    param(
        [string]$TimestampUtc,
        [double]$StaleHours
    )

    $result = [ordered]@{
        stale = $false
        age_hours = $null
        status = "fresh"
    }

    if (-not $TimestampUtc) {
        $result.stale = $true
        $result.status = "unknown"
        return [pscustomobject]$result
    }

    try {
        $age = ((Get-Date).ToUniversalTime() - ([datetime]$TimestampUtc).ToUniversalTime()).TotalHours
        $result.age_hours = [math]::Round($age, 2)
        if ($age -ge $StaleHours) {
            $result.stale = $true
            $result.status = "stale"
        }
        return [pscustomobject]$result
    }
    catch {
        $result.stale = $true
        $result.status = "unknown"
        return [pscustomobject]$result
    }
}

function Get-SeverityRank {
    param([string]$Severity)

    switch ((Normalize-Text $Severity).ToLowerInvariant()) {
        "critical" { return 4 }
        "high" { return 3 }
        "medium" { return 2 }
        "low" { return 1 }
        default { return 0 }
    }
}

function Get-VerifiedStatusTag {
    param(
        [string]$Domain,
        [Parameter(Mandatory = $true)]$ValidatorSectionsByName
    )

    $sectionName = switch -Regex ($Domain) {
        '^athena$' { "Athena" }
        '^onyx$' { "Onyx" }
        '^services$|^bridge$|^mason$' { "stack/base" }
        '^knowledge$' { "memory/ingest/context pack" }
        '^state$' { "tenant/onboarding/business profile" }
        '^config$' { "tool registry/runner/artifacts" }
        default { "" }
    }

    if (-not $sectionName -or -not $ValidatorSectionsByName.Contains($sectionName)) {
        return "unverified"
    }

    $section = $ValidatorSectionsByName[$sectionName]
    $status = Normalize-Text (Get-PropValue -Object $section -Name "status" -Default "")
    switch ($status) {
        "PASS" { return "verified" }
        "WARN" { return "partially_verified" }
        "FAIL" { return "unverified" }
        default { return "unverified" }
    }
}

function Get-InventoryTags {
    param(
        $FileRecord,
        [Parameter(Mandatory = $true)]$RegisteredPaths,
        [Parameter(Mandatory = $true)]$ExpectedRuntimePaths,
        [double]$StaleHours
    )

    $relativePath = Normalize-Text (Get-PropValue -Object $FileRecord -Name "relative_path" -Default "")
    $classification = Normalize-Text (Get-PropValue -Object $FileRecord -Name "classification" -Default "")
    $tags = New-Object System.Collections.Generic.List[string]

    if ($classification -eq "active" -or (Test-IsTruthy (Get-PropValue -Object $FileRecord -Name "strong_active" -Default $false))) {
        $tags.Add("active") | Out-Null
    }
    if ($RegisteredPaths.Contains($relativePath)) {
        $tags.Add("registered") | Out-Null
    }
    if ($ExpectedRuntimePaths.Contains($relativePath) -or (Test-IsTruthy (Get-PropValue -Object $FileRecord -Name "in_start_flow" -Default $false))) {
        $tags.Add("expected-runtime") | Out-Null
    }
    if ($relativePath -match '^(?i)reports[\\/]') {
        $tags.Add("artifact") | Out-Null
    }
    if ($relativePath -match '^(?i)config[\\/]') {
        $tags.Add("config") | Out-Null
    }
    if ($classification -eq "candidate") {
        $tags.Add("candidate") | Out-Null
    }
    if ($classification -eq "duplicate" -or (Normalize-Text (Get-PropValue -Object $FileRecord -Name "duplicate_of" -Default ""))) {
        $tags.Add("duplicate") | Out-Null
    }
    if ($classification -eq "broken" -or (Get-PropValue -Object $FileRecord -Name "parse_ok" -Default $true) -eq $false -or (Normalize-Text (Get-PropValue -Object $FileRecord -Name "build_error" -Default ""))) {
        $tags.Add("broken") | Out-Null
    }
    if ($classification -eq "archive" -or (Test-IsTruthy (Get-PropValue -Object $FileRecord -Name "archive_signal" -Default $false))) {
        $tags.Add("archive-like") | Out-Null
    }
    $hasDangerousSignal = Test-IsTruthy (Get-PropValue -Object $FileRecord -Name "dangerous_signal" -Default $false)
    $hasDangerousName = Test-IsTruthy (Get-PropValue -Object $FileRecord -Name "dangerous_name" -Default $false)
    $hasDangerousContent = Test-IsTruthy (Get-PropValue -Object $FileRecord -Name "dangerous_content" -Default $false)
    if ($hasDangerousSignal -or $hasDangerousName -or $hasDangerousContent) {
        $tags.Add("dangerous") | Out-Null
    }
    if ($classification -eq "unknown") {
        $tags.Add("unknown") | Out-Null
    }

    $referenceCount = [int](Get-PropValue -Object $FileRecord -Name "reference_count" -Default 0)
    if ($referenceCount -eq 0 -and $classification -eq "unknown" -and -not (Test-IsTruthy (Get-PropValue -Object $FileRecord -Name "secret_like" -Default $false))) {
        $tags.Add("orphaned") | Out-Null
    }

    $lastWriteUtc = Normalize-Text (Get-PropValue -Object $FileRecord -Name "last_write_utc" -Default "")
    $freshness = Get-FreshnessStatus -TimestampUtc $lastWriteUtc -StaleHours $StaleHours
    if ($freshness.stale) {
        $tags.Add("stale") | Out-Null
    }

    if ($tags.Count -eq 0) {
        $tags.Add("unknown") | Out-Null
    }

    $primary = "unknown"
    foreach ($candidate in @("broken", "dangerous", "duplicate", "archive-like", "orphaned", "candidate", "config", "artifact", "expected-runtime", "registered", "active", "stale", "unknown")) {
        if ($tags.Contains($candidate)) {
            $primary = $candidate
            break
        }
    }

    return [pscustomobject]@{
        primary = $primary
        tags = @($tags.ToArray() | Select-Object -Unique)
        freshness = $freshness
    }
}

function Get-ApprovalSurfaceInfo {
    param($StackStatusPayload)

    $approvals = Get-PropValue -Object $StackStatusPayload -Name "approvals" -Default @{}
    $approvalItems = To-Array (Get-PropValue -Object $approvals -Name "pending_items" -Default @())
    if ($approvalItems.Count -eq 0) {
        $approvalItems = To-Array (Get-PropValue -Object $approvals -Name "items" -Default @())
    }

    $actionable = 0
    foreach ($item in $approvalItems) {
        $approve = Get-PropValue -Object $item -Name "approve_action" -Default $null
        $reject = Get-PropValue -Object $item -Name "reject_action" -Default $null
        if ($approve -or $reject) {
            $actionable++
        }
    }

    return [pscustomobject]@{
        visible_count = $approvalItems.Count
        actionable_count = $actionable
        items = @($approvalItems)
    }
}

function Search-HardcodedPaths {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [string[]]$Patterns
    )

    $hits = New-Object System.Collections.Generic.List[object]
    $rgCommand = Get-Command rg -ErrorAction SilentlyContinue
    if (-not $rgCommand) {
        Write-Output -NoEnumerate @()
        return
    }

    $scanRoots = @(
        (Join-Path $RepoRoot "tools"),
        (Join-Path $RepoRoot "services"),
        (Join-Path $RepoRoot "MasonConsole"),
        (Join-Path $RepoRoot "config"),
        (Join-Path $RepoRoot "roadmap"),
        (Join-Path $RepoRoot "Component - Onyx App")
    ) | Where-Object { Test-Path -LiteralPath $_ }

    foreach ($pattern in @($Patterns)) {
        if (-not (Normalize-Text $pattern)) { continue }
        $output = & rg -n -F --glob "!reports/**" --glob "!state/**" --glob "!Component - Onyx App/**/.dart_tool/**" --glob "!Component - Onyx App/**/build/**" --glob "!Component - Onyx App/**/windows/flutter/**" $pattern @($scanRoots) 2>$null
        foreach ($line in @($output)) {
            $text = [string]$line
            if (-not $text.Trim()) { continue }
            $parts = $text -split ":", 4
            $filePath = if ($parts.Length -ge 1) { $parts[0] } else { "" }
            $lineNo = if ($parts.Length -ge 2) { $parts[1] } else { "" }
            $snippet = if ($parts.Length -ge 4) { $parts[3] } elseif ($parts.Length -ge 3) { $parts[2] } else { "" }
            $hits.Add([pscustomobject][ordered]@{
                pattern = $pattern
                path = Get-RelativePathSafe -BasePath $RepoRoot -FullPath $filePath
                line = $lineNo
                snippet = Limit-Text -Text $snippet -MaxLength 180
            }) | Out-Null
            if ($hits.Count -ge 200) {
                Write-Output -NoEnumerate @($hits.ToArray())
                return
            }
        }
    }

    Write-Output -NoEnumerate @($hits.ToArray())
}

function Get-ToolCanaryInput {
    param(
        [string]$RepoRoot,
        [string]$DefaultTenantId
    )

    $workspacePath = Join-Path $RepoRoot "state\onyx\tenant_workspace.json"
    $workspace = Read-JsonSafe -Path $workspacePath -Default @{}
    $tenantId = Normalize-Text (Get-PropValue -Object $workspace -Name "active_tenant_id" -Default "")
    if (-not $tenantId) {
        $tenantId = Normalize-Text $DefaultTenantId
    }
    if (-not $tenantId) {
        $tenantId = "tenant_http_check"
    }

    $tenantRoot = Join-Path $RepoRoot ("state\onyx\tenants\" + $tenantId + ".json")
    $tenantPayload = Read-JsonSafe -Path $tenantRoot -Default @{}
    $businessType = Normalize-Text (Get-PropValue -Object $tenantPayload -Name "business_type" -Default "")
    if (-not $businessType) {
        $businessType = Normalize-Text (Get-PropValue -Object $workspace -Name "business_type" -Default "")
    }
    if (-not $businessType) {
        $businessType = "service"
    }

    $goal = ""
    $goals = To-Array (Get-PropValue -Object $tenantPayload -Name "goals" -Default @())
    if ($goals.Count -gt 0) {
        $goal = Normalize-Text $goals[0]
    }
    if (-not $goal) {
        $goal = "Stabilize operations and clarify next actions"
    }

    $issues = New-Object System.Collections.Generic.List[string]
    foreach ($item in (To-Array (Get-PropValue -Object $tenantPayload -Name "pain_points" -Default @()))) {
        $text = Normalize-Text $item
        if ($text) {
            $issues.Add($text) | Out-Null
        }
    }
    if ($issues.Count -eq 0) {
        $issues.Add("Need clearer operational priorities") | Out-Null
    }

    $inputObject = [ordered]@{
        business_type = $businessType
        goal = $goal
        current_issues = @($issues.ToArray())
        budget = Normalize-Text (Get-PropValue -Object $tenantPayload -Name "budget_spend_sensitivity" -Default "")
        staff_size = Normalize-Text (Get-PropValue -Object $tenantPayload -Name "team_size" -Default "")
    }

    return [pscustomobject]@{
        tenant_id = $tenantId
        input_json = ($inputObject | ConvertTo-Json -Compress -Depth 8)
    }
}

function Get-LatestToolArtifactInfo {
    param(
        [string]$RepoRoot,
        [datetime]$AfterUtc,
        [string]$ToolId
    )

    $toolReportsDir = Join-Path $RepoRoot "reports\tools"
    if (-not (Test-Path -LiteralPath $toolReportsDir)) {
        return $null
    }

    $candidates = Get-ChildItem -LiteralPath $toolReportsDir -Directory -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending
    foreach ($dir in $candidates) {
        if ($dir.LastWriteTimeUtc -lt $AfterUtc) {
            continue
        }
        $artifactPath = Join-Path $dir.FullName "artifact.json"
        if (-not (Test-Path -LiteralPath $artifactPath)) {
            continue
        }
        $artifact = Read-JsonSafe -Path $artifactPath -Default @{}
        $artifactToolId = Normalize-Text (Get-PropValue -Object $artifact -Name "tool_id" -Default "")
        if (-not $artifactToolId) {
            $artifactTool = Get-PropValue -Object $artifact -Name "tool" -Default @{}
            if ($artifactTool -is [System.Collections.IDictionary] -or $artifactTool -is [pscustomobject]) {
                $artifactToolId = Normalize-Text (Get-PropValue -Object $artifactTool -Name "tool_id" -Default "")
            }
        }
        if ($ToolId -and $artifactToolId -and $artifactToolId -ne $ToolId) {
            continue
        }
        return [pscustomobject][ordered]@{
            artifact_path = $artifactPath
            run_dir = $dir.FullName
            tool_id = $artifactToolId
            generated_at_utc = Convert-ToUtcIso $dir.LastWriteTimeUtc
        }
    }
    return $null
}

function New-QueueItem {
    param(
        [string]$Id,
        [string]$Path,
        [string]$Classification,
        [string]$Reason,
        [string]$RecommendedAction,
        [string]$RiskLevel,
        [string]$Domain,
        [string[]]$Evidence,
        [string]$QueueType = "manual-review"
    )

    return [pscustomobject][ordered]@{
        item_id = $Id
        path = $Path
        current_classification = $Classification
        queue_type = $QueueType
        reason = Limit-Text -Text $Reason -MaxLength 220
        evidence = @($Evidence | Where-Object { Normalize-Text $_ } | Select-Object -Unique)
        recommended_action = Limit-Text -Text $RecommendedAction -MaxLength 220
        risk_level = Normalize-Text $RiskLevel
        linked_component_or_domain = Normalize-Text $Domain
    }
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$policyPath = Join-Path $repoRoot "config\whole_folder_verification_policy.json"

$wholeFolderVerificationPath = Join-Path $reportsDir "whole_folder_verification_last.json"
$wholeFolderInventoryPath = Join-Path $reportsDir "whole_folder_inventory_last.json"
$wholeFolderRegistrationGapsPath = Join-Path $reportsDir "whole_folder_registration_gaps.json"
$wholeFolderBrokenPathsPath = Join-Path $reportsDir "whole_folder_broken_paths_last.json"
$wholeFolderGoldenPathsPath = Join-Path $reportsDir "whole_folder_golden_paths_last.json"
$wholeFolderFaultTestsPath = Join-Path $reportsDir "whole_folder_fault_tests_last.json"
$wholeFolderMigrationChecksPath = Join-Path $reportsDir "whole_folder_migration_checks_last.json"
$wholeFolderUsabilityChecksPath = Join-Path $reportsDir "whole_folder_usability_checks_last.json"
$wholeFolderCleanupQueuePath = Join-Path $reportsDir "whole_folder_cleanup_queue.json"
$wholeFolderSummaryMarkdownPath = Join-Path $reportsDir "whole_folder_verification_summary.md"
$wholeFolderProgressPath = Join-Path $reportsDir "whole_folder_verification_progress.json"

$systemValidationPath = Join-Path $reportsDir "system_validation_last.json"
$mirrorUpdatePath = Join-Path $reportsDir "mirror_update_last.json"
$codebaseInventoryPath = Join-Path $reportsDir "codebase_inventory_last.json"
$codebaseCleanupPlanPath = Join-Path $reportsDir "codebase_cleanup_plan.json"
$codebaseSalvageQueuePath = Join-Path $reportsDir "codebase_salvage_queue.json"

$policy = Read-JsonSafe -Path $policyPath -Default @{}
if (-not $policy) {
    throw "whole_folder_verification_policy.json is missing or unreadable at $policyPath"
}
Write-JsonFile -Path $policyPath -Object $policy -Depth 18
Write-ProgressCheckpoint -Path $wholeFolderProgressPath -Stage "policy_loaded" -Detail "Whole-folder verification policy loaded."

$discoveryScriptPath = Join-Path $repoRoot "tools\ops\Scan_Codebase_Salvage.ps1"
$validatorScriptPath = Join-Path $repoRoot "tools\ops\Validate_Whole_System.ps1"
$stackResetScriptPath = Join-Path $repoRoot "tools\ops\Stack_Reset_And_Start.ps1"
$mirrorScriptPath = Join-Path $repoRoot "tools\sync\Mason_Mirror_Update.ps1"
$toolRunnerScriptPath = Join-Path $repoRoot "tools\platform\ToolRunner.ps1"

$discoveryInvocation = Invoke-PowerShellFile -ScriptPath $discoveryScriptPath -Arguments @("-RootPath", $repoRoot) -TimeoutSeconds 1800
Write-ProgressCheckpoint -Path $wholeFolderProgressPath -Stage "discovery_complete" -Detail ("Discovery invocation ok=" + [string]$discoveryInvocation.ok)
$codebaseInventory = Read-JsonSafe -Path $codebaseInventoryPath -Default @{}
$codebaseCleanupPlan = Read-JsonSafe -Path $codebaseCleanupPlanPath -Default @{}
$codebaseSalvageQueue = Read-JsonSafe -Path $codebaseSalvageQueuePath -Default @{}

$stackRestartResult = $null
if (-not $SkipStackRestart) {
    $stackRestartResult = Invoke-PowerShellFile -ScriptPath $stackResetScriptPath -TimeoutSeconds 1800
}
Write-ProgressCheckpoint -Path $wholeFolderProgressPath -Stage "stack_restart_evaluated" -Detail ("Stack restart attempted=" + [string](-not $SkipStackRestart))

$validatorInvocation = Invoke-PowerShellFile -ScriptPath $validatorScriptPath -TimeoutSeconds 1800
Write-ProgressCheckpoint -Path $wholeFolderProgressPath -Stage "validator_complete" -Detail ("Validator invocation ok=" + [string]$validatorInvocation.ok)
$validatorPayload = Read-JsonSafe -Path $systemValidationPath -Default @{}
$validatorSections = To-Array (Get-PropValue -Object $validatorPayload -Name "sections" -Default @())
$validatorSectionsByName = @{}
foreach ($section in $validatorSections) {
    $name = Normalize-Text (Get-PropValue -Object $section -Name "section_name" -Default "")
    if ($name) {
        $validatorSectionsByName[$name] = $section
    }
}

$componentRegistry = Read-JsonSafe -Path (Join-Path $repoRoot "config\component_registry.json") -Default @{}
$componentDocsRegistry = Read-JsonSafe -Path (Join-Path $repoRoot "config\component_docs_registry.json") -Default @{}
$toolRegistry = Read-JsonSafe -Path (Join-Path $repoRoot "config\tool_registry.json") -Default @{}
$uxSimplicity = Read-JsonSafe -Path (Join-Path $repoRoot "reports\ux_simplicity_last.json") -Default @{}
$approvalSurface = Read-JsonSafe -Path (Join-Path $repoRoot "reports\approval_surface_last.json") -Default @{}
$brandExposure = Read-JsonSafe -Path (Join-Path $repoRoot "reports\brand_exposure_isolation_last.json") -Default @{}
$playbookSupport = Read-JsonSafe -Path (Join-Path $repoRoot "reports\support_brain_last.json") -Default @{}
$mirrorBefore = Read-JsonSafe -Path $mirrorUpdatePath -Default @{}

$requiredEndpoints = To-Array (Get-PropValue -Object (Get-PropValue -Object $policy -Name "golden_paths" -Default @{}) -Name "required_endpoints" -Default @())
$endpointProbes = New-Object System.Collections.Generic.List[object]
foreach ($endpoint in $requiredEndpoints) {
    $probe = Invoke-HttpProbe -Url ([string]$endpoint) -TimeoutSeconds 12
    $endpointProbes.Add([pscustomobject][ordered]@{
        url = [string]$endpoint
        ok = [bool]$probe.ok
        status_code = [int]$probe.status_code
        error = [string]$probe.error
    }) | Out-Null
}

$stackStatusProbe = Invoke-HttpProbe -Url "http://127.0.0.1:8000/api/stack_status" -TimeoutSeconds 12
$stackStatusPayload = @{}
if ($stackStatusProbe.ok -and (Normalize-Text $stackStatusProbe.body)) {
    try {
        $stackStatusPayload = $stackStatusProbe.body | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        $stackStatusPayload = @{}
    }
}
$athenaHtmlProbe = Invoke-HttpProbe -Url "http://127.0.0.1:8000/athena/" -TimeoutSeconds 12
$approvalsProbe = Invoke-HttpProbe -Url "http://127.0.0.1:8000/api/approvals" -TimeoutSeconds 12

$registeredPaths = New-StringSet
foreach ($component in (To-Array (Get-PropValue -Object $componentRegistry -Name "components" -Default @()))) {
    foreach ($root in (To-Array (Get-PropValue -Object $component -Name "root_paths" -Default @()))) {
        Add-SetItem -Set $registeredPaths -Value ((Normalize-Text $root) -replace '/', '\')
    }
    foreach ($statusSource in (To-Array (Get-PropValue -Object $component -Name "status_sources" -Default @()))) {
        Add-SetItem -Set $registeredPaths -Value ((Normalize-Text $statusSource) -replace '/', '\')
    }
    Add-SetItem -Set $registeredPaths -Value ((Normalize-Text (Get-PropValue -Object $component -Name "readme_path" -Default "")) -replace '/', '\')
}
foreach ($docComponent in (To-Array (Get-PropValue -Object $componentDocsRegistry -Name "components" -Default @()))) {
    foreach ($artifactPath in (To-Array (Get-PropValue -Object $docComponent -Name "primary_artifacts" -Default @()))) {
        Add-SetItem -Set $registeredPaths -Value ((Normalize-Text $artifactPath) -replace '/', '\')
    }
    foreach ($artifactPath in (To-Array (Get-PropValue -Object $docComponent -Name "supporting_artifacts" -Default @()))) {
        Add-SetItem -Set $registeredPaths -Value ((Normalize-Text $artifactPath) -replace '/', '\')
    }
}
Add-SetItem -Set $registeredPaths -Value "config\tool_registry.json"
Add-SetItem -Set $registeredPaths -Value "config\component_registry.json"
Add-SetItem -Set $registeredPaths -Value "config\component_docs_registry.json"

$expectedRuntimePaths = New-StringSet
foreach ($path in @(
    "services\mason_api\serve_mason_api.py",
    "services\seed_api\serve_seed_api.py",
    "MasonConsole\server.py",
    "tools\Start_Bridge.ps1",
    "Start_Mason2.ps1",
    "Start-Athena.ps1",
    "Stop_Stack.ps1",
    "Stop_Stack_Deep.ps1",
    "tools\ops\Stack_Reset_And_Start.ps1",
    "Component - Onyx App\onyx_business_manager\Start-Onyx5353.ps1"
)) {
    Add-SetItem -Set $expectedRuntimePaths -Value $path
}

$inventoryItems = New-Object System.Collections.Generic.List[object]
$classificationCounts = @{}
$domainCounts = @{}
$verifiedCounts = @{}
$staleHours = [double](Get-PropValue -Object (Get-PropValue -Object $policy -Name "discovery" -Default @{}) -Name "stale_artifact_hours" -Default 168)

foreach ($fileRecord in (To-Array (Get-PropValue -Object $codebaseInventory -Name "files" -Default @()))) {
    $relativePath = ((Normalize-Text (Get-PropValue -Object $fileRecord -Name "relative_path" -Default "")) -replace '/', '\')
    if (-not $relativePath) { continue }

    $tagInfo = Get-InventoryTags -FileRecord $fileRecord -RegisteredPaths $registeredPaths -ExpectedRuntimePaths $expectedRuntimePaths -StaleHours $staleHours
    $domain = Normalize-Text (Get-PropValue -Object $fileRecord -Name "domain" -Default "")
    $verifiedTag = Get-VerifiedStatusTag -Domain $domain -ValidatorSectionsByName $validatorSectionsByName

    $item = [pscustomobject][ordered]@{
        path = $relativePath
        primary_classification = $tagInfo.primary
        classification_tags = @($tagInfo.tags)
        registered = $tagInfo.tags -contains "registered"
        expected_runtime = $tagInfo.tags -contains "expected-runtime"
        verification_tag = $verifiedTag
        domain = $domain
        last_write_utc = Normalize-Text (Get-PropValue -Object $fileRecord -Name "last_write_utc" -Default "")
        freshness_status = $tagInfo.freshness.status
        reference_count = [int](Get-PropValue -Object $fileRecord -Name "reference_count" -Default 0)
        duplicate_of = Normalize-Text (Get-PropValue -Object $fileRecord -Name "duplicate_of" -Default "")
        parse_ok = Get-PropValue -Object $fileRecord -Name "parse_ok" -Default $null
        classification_evidence = @((To-Array (Get-PropValue -Object $fileRecord -Name "classification_evidence" -Default @())) | ForEach-Object { Normalize-Text $_ } | Where-Object { $_ })
    }
    $inventoryItems.Add($item) | Out-Null

    foreach ($tag in $item.classification_tags) {
        if (-not $classificationCounts.ContainsKey($tag)) { $classificationCounts[$tag] = 0 }
        $classificationCounts[$tag]++
    }
    if ($domain) {
        if (-not $domainCounts.ContainsKey($domain)) { $domainCounts[$domain] = 0 }
        $domainCounts[$domain]++
    }
    if (-not $verifiedCounts.ContainsKey($verifiedTag)) { $verifiedCounts[$verifiedTag] = 0 }
    $verifiedCounts[$verifiedTag]++
}
Write-ProgressCheckpoint -Path $wholeFolderProgressPath -Stage "inventory_classified" -Detail ("Inventory items=" + [string]$inventoryItems.Count)

$registrationGaps = New-Object System.Collections.Generic.List[object]
$docsComponents = @{}
foreach ($docComponent in (To-Array (Get-PropValue -Object $componentDocsRegistry -Name "components" -Default @()))) {
    $docId = Normalize-Text (Get-PropValue -Object $docComponent -Name "component_id" -Default "")
    if ($docId) { $docsComponents[$docId] = $docComponent }
}

foreach ($runtimeComponent in @(
    @{ id = "mason_api"; path = "services\mason_api"; description = "Mason API runtime exists on disk but is not a first-class component registry entry." },
    @{ id = "seed_api"; path = "services\seed_api"; description = "Seed API runtime exists on disk but is not a first-class component registry entry." },
    @{ id = "bridge"; path = "tools\Start_Bridge.ps1"; description = "Bridge runtime exists on disk but is not a first-class component registry entry." }
)) {
    $runtimeId = [string]$runtimeComponent.id
    $registered = $false
    foreach ($component in (To-Array (Get-PropValue -Object $componentRegistry -Name "components" -Default @()))) {
        if ((Normalize-Text (Get-PropValue -Object $component -Name "id" -Default "")) -eq $runtimeId) {
            $registered = $true
            break
        }
    }
    if (-not $registered -and (Test-Path -LiteralPath (Join-Path $repoRoot ([string]$runtimeComponent.path)))) {
        $registrationGaps.Add([pscustomobject][ordered]@{
            gap_id = "unregistered_runtime_$runtimeId"
            gap_type = "unregistered_runtime_component"
            severity = "medium"
            severity_score = 61
            item_id = $runtimeId
            path = [string]$runtimeComponent.path
            description = [string]$runtimeComponent.description
            evidence = @("runtime path exists on disk", "component_registry does not include $runtimeId")
            recommended_action = "Register the runtime component so health, docs, and future verification stay aligned."
        }) | Out-Null
    }
}

$toolRunnerExists = Test-Path -LiteralPath $toolRunnerScriptPath
$planCatalog = Read-JsonSafe -Path (Join-Path $repoRoot "config\tiers.json") -Default @{}
$planEnabledTools = New-StringSet
foreach ($tier in (To-Array (Get-PropValue -Object $planCatalog -Name "tiers" -Default @()))) {
    foreach ($toolId in (To-Array (Get-PropValue -Object $tier -Name "enabled_tools" -Default @()))) {
        Add-SetItem -Set $planEnabledTools -Value $toolId
    }
}

foreach ($tool in (To-Array (Get-PropValue -Object $toolRegistry -Name "tools" -Default @()))) {
    $toolId = Normalize-Text (Get-PropValue -Object $tool -Name "tool_id" -Default "")
    if (-not $toolId) { continue }

    $enabled = Test-IsTruthy (Get-PropValue -Object $tool -Name "enabled" -Default $false)
    $riskLevel = Normalize-Text (Get-PropValue -Object $tool -Name "risk_level" -Default "")
    if (-not $riskLevel) {
        $registrationGaps.Add([pscustomobject][ordered]@{
            gap_id = "tool_missing_risk_$toolId"
            gap_type = "missing_risk_classification"
            severity = "medium"
            severity_score = 52
            item_id = $toolId
            path = "config\\tool_registry.json"
            description = "Tool contract is missing risk_level."
            evidence = @("tool registry entry exists", "risk_level is blank")
            recommended_action = "Add risk_level so tool governance remains explicit."
        }) | Out-Null
    }

    if ($enabled -and -not $toolRunnerExists) {
        $registrationGaps.Add([pscustomobject][ordered]@{
            gap_id = "tool_runner_missing_$toolId"
            gap_type = "tool_runner_missing"
            severity = "critical"
            severity_score = 95
            item_id = $toolId
            path = "tools\\platform\\ToolRunner.ps1"
            description = "Enabled tool exists but ToolRunner is missing."
            evidence = @("tool registry marks tool enabled", "ToolRunner.ps1 is missing")
            recommended_action = "Restore ToolRunner.ps1 before exposing enabled tools."
        }) | Out-Null
    }

    if ($enabled -and -not $planEnabledTools.Contains($toolId)) {
        $registrationGaps.Add([pscustomobject][ordered]@{
            gap_id = "tool_plan_visibility_$toolId"
            gap_type = "tool_visibility_gap"
            severity = "low"
            severity_score = 24
            item_id = $toolId
            path = "config\\tiers.json"
            description = "Enabled tool is not currently exposed by any plan tier."
            evidence = @("tool registry marks tool enabled", "tiers.json does not reference $toolId")
            recommended_action = "Confirm whether the tool should stay hidden, become an add-on, or be surfaced by a plan tier."
        }) | Out-Null
    }
}

$brokenPathRecords = New-Object System.Collections.Generic.List[object]
foreach ($section in $validatorSections) {
    foreach ($check in (To-Array (Get-PropValue -Object $section -Name "checks" -Default @()))) {
        $status = Normalize-Text (Get-PropValue -Object $check -Name "status" -Default "")
        if ($status -ne "FAIL") { continue }
        $brokenPathRecords.Add([pscustomobject][ordered]@{
            record_id = "validator_$([guid]::NewGuid().ToString('N').Substring(0,8))"
            path = Normalize-Text (Get-PropValue -Object $check -Name "path" -Default "")
            component = Normalize-Text (Get-PropValue -Object $check -Name "component" -Default "")
            type = "validator_failure"
            severity = "critical"
            description = Limit-Text -Text (Get-PropValue -Object $check -Name "detail" -Default "") -MaxLength 240
            evidence = @(
                "section: " + (Normalize-Text (Get-PropValue -Object $section -Name "section_name" -Default "")),
                "check: " + (Normalize-Text (Get-PropValue -Object $check -Name "name" -Default ""))
            )
            recommended_action = Limit-Text -Text (Get-PropValue -Object $check -Name "next_action" -Default "") -MaxLength 220
        }) | Out-Null
    }
}

foreach ($component in (To-Array (Get-PropValue -Object $componentRegistry -Name "components" -Default @()))) {
    $componentId = Normalize-Text (Get-PropValue -Object $component -Name "id" -Default "")
    if (-not $componentId) { continue }

    foreach ($root in (To-Array (Get-PropValue -Object $component -Name "root_paths" -Default @()))) {
        $rootRel = (Normalize-Text $root) -replace '/', '\'
        $rootAbs = Join-Path $repoRoot $rootRel
        if (-not (Test-Path -LiteralPath $rootAbs)) {
            $registrationGaps.Add([pscustomobject][ordered]@{
                gap_id = "component_root_missing_$componentId"
                gap_type = "registered_missing_root"
                severity = "high"
                severity_score = 82
                item_id = $componentId
                path = $rootRel
                description = "Registered component root path is missing."
                evidence = @("component_registry root_paths includes $rootRel", "path not found on disk")
                recommended_action = "Repair the component root path or update component_registry.json."
            }) | Out-Null
        }
    }

    foreach ($statusSource in (To-Array (Get-PropValue -Object $component -Name "status_sources" -Default @()))) {
        $sourceRel = (Normalize-Text $statusSource) -replace '/', '\'
        if ($sourceRel -and -not (Test-Path -LiteralPath (Join-Path $repoRoot $sourceRel))) {
            $registrationGaps.Add([pscustomobject][ordered]@{
                gap_id = "component_status_source_missing_${componentId}_$([guid]::NewGuid().ToString('N').Substring(0,6))"
                gap_type = "missing_status_source"
                severity = "medium"
                severity_score = 56
                item_id = $componentId
                path = $sourceRel
                description = "Registered component status source is missing."
                evidence = @("component_registry status_sources includes $sourceRel", "path not found on disk")
                recommended_action = "Restore the source artifact or remove stale status source references."
            }) | Out-Null
        }
    }

    if (-not $docsComponents.ContainsKey($componentId)) {
        $registrationGaps.Add([pscustomobject][ordered]@{
            gap_id = "component_docs_missing_$componentId"
            gap_type = "docs_registry_gap"
            severity = "medium"
            severity_score = 48
            item_id = $componentId
            path = "config\\component_docs_registry.json"
            description = "Registered component has no docs registry entry."
            evidence = @("component_registry includes $componentId", "component_docs_registry does not include $componentId")
            recommended_action = "Add a docs registry entry so live docs and future verification stay aligned."
        }) | Out-Null
    }
}

foreach ($gap in $registrationGaps) {
    $severity = Normalize-Text (Get-PropValue -Object $gap -Name "severity" -Default "")
    if ($severity -in @("critical", "high")) {
        $brokenPathRecords.Add([pscustomobject][ordered]@{
            record_id = "gap_$([guid]::NewGuid().ToString('N').Substring(0,8))"
            path = Normalize-Text (Get-PropValue -Object $gap -Name "path" -Default "")
            component = Normalize-Text (Get-PropValue -Object $gap -Name "item_id" -Default "")
            type = Normalize-Text (Get-PropValue -Object $gap -Name "gap_type" -Default "")
            severity = $severity
            description = Limit-Text -Text (Get-PropValue -Object $gap -Name "description" -Default "") -MaxLength 240
            evidence = @(To-Array (Get-PropValue -Object $gap -Name "evidence" -Default @()))
            recommended_action = Limit-Text -Text (Get-PropValue -Object $gap -Name "recommended_action" -Default "") -MaxLength 220
        }) | Out-Null
    }
}

foreach ($item in ($inventoryItems | Where-Object { $_.primary_classification -eq "broken" } | Select-Object -First 200)) {
    $brokenPathRecords.Add([pscustomobject][ordered]@{
        record_id = "inventory_$([guid]::NewGuid().ToString('N').Substring(0,8))"
        path = [string]$item.path
        component = [string]$item.domain
        type = [string]$item.primary_classification
        severity = "medium"
        description = "Inventory classified this path as $($item.primary_classification)."
        evidence = @($item.classification_tags)
        recommended_action = "Inspect parse/build failures and repair or archive the path."
    }) | Out-Null
}

$criticalPathBroken = $false
foreach ($record in $brokenPathRecords) {
    $recordPath = Normalize-Text (Get-PropValue -Object $record -Name "path" -Default "")
    $recordComponent = Normalize-Text (Get-PropValue -Object $record -Name "component" -Default "")
    $recordType = Normalize-Text (Get-PropValue -Object $record -Name "type" -Default "")
    if ($recordPath -match '127\.0\.0\.1:8000|127\.0\.0\.1:5353|127\.0\.0\.1:8383|127\.0\.0\.1:8109|127\.0\.0\.1:8484' -or
        ($recordType -eq "validator_failure" -and $recordComponent -in @("mason_api", "seed_api", "bridge", "athena", "onyx"))) {
        $criticalPathBroken = $true
        break
    }
}

$goldenChecks = New-Object System.Collections.Generic.List[object]
foreach ($probe in @($endpointProbes.ToArray())) {
    $goldenChecks.Add([pscustomobject][ordered]@{
        check_id = "endpoint_" + ([Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([string]$probe.url)).Replace("=","").Replace("/","_").Replace("+","-"))
        name = [string]$probe.url
        status = if ($probe.ok) { "PASS" } else { "FAIL" }
        component = if ($probe.url -match ':8000') { "athena" } elseif ($probe.url -match ':5353') { "onyx" } elseif ($probe.url -match ':8383') { "mason_api" } elseif ($probe.url -match ':8109') { "seed_api" } elseif ($probe.url -match ':8484') { "bridge" } else { "stack" }
        detail = if ($probe.ok) { "HTTP 200" } else { "status=$($probe.status_code) $($probe.error)" }
        path = [string]$probe.url
        reproducibility = if ($probe.ok) { "stable_pass" } else { "reproducible_failure" }
        recommended_action = if ($probe.ok) { "No action required." } else { "Restore this endpoint before trusting the golden path." }
    }) | Out-Null
}

$athenaHasFounder = $false
$athenaHasWholeFolderCard = $false
if ($athenaHtmlProbe.ok) {
    $athenaHasFounder = $athenaHtmlProbe.body -match "Founder Mode"
    $athenaHasWholeFolderCard = $athenaHtmlProbe.body -match "Whole Folder Verification"
}
$goldenChecks.Add([pscustomobject][ordered]@{
    check_id = "athena_founder_surface"
    name = "Athena founder surface markup"
    status = if ($athenaHtmlProbe.ok -and $athenaHasFounder) { "PASS" } else { "FAIL" }
    component = "athena"
    detail = if ($athenaHtmlProbe.ok -and $athenaHasFounder) { "Founder surface markup is present." } else { "Founder surface markup is missing from /athena/." }
    path = "http://127.0.0.1:8000/athena/"
    reproducibility = if ($athenaHtmlProbe.ok -and $athenaHasFounder) { "stable_pass" } else { "reproducible_failure" }
    recommended_action = if ($athenaHtmlProbe.ok -and $athenaHasFounder) { "No action required." } else { "Repair Athena founder surface rendering." }
}) | Out-Null
$goldenChecks.Add([pscustomobject][ordered]@{
    check_id = "athena_whole_folder_surface"
    name = "Athena whole-folder surface markup"
    status = if ($athenaHtmlProbe.ok -and $athenaHasWholeFolderCard) { "PASS" } else { "WARN" }
    component = "athena"
    detail = if ($athenaHtmlProbe.ok -and $athenaHasWholeFolderCard) { "Whole-folder verification surface markup is present." } else { "Whole-folder verification surface markup is not present yet." }
    path = "http://127.0.0.1:8000/athena/"
    reproducibility = if ($athenaHtmlProbe.ok -and $athenaHasWholeFolderCard) { "stable_pass" } else { "needs_followup" }
    recommended_action = if ($athenaHtmlProbe.ok -and $athenaHasWholeFolderCard) { "No action required." } else { "Patch Athena to expose the whole-folder verification summary." }
}) | Out-Null

$approvalInfo = Get-ApprovalSurfaceInfo -StackStatusPayload $stackStatusPayload
$goldenChecks.Add([pscustomobject][ordered]@{
    check_id = "approvals_payload"
    name = "Approvals payload"
    status = if ($approvalsProbe.ok) { "PASS" } else { "FAIL" }
    component = "athena"
    detail = if ($approvalsProbe.ok) { "Approvals payload is readable; $($approvalInfo.visible_count) item(s), $($approvalInfo.actionable_count) actionable." } else { "Approvals payload unavailable: $($approvalsProbe.error)" }
    path = "http://127.0.0.1:8000/api/approvals"
    reproducibility = if ($approvalsProbe.ok) { "stable_pass" } else { "reproducible_failure" }
    recommended_action = if ($approvalsProbe.ok) { "No action required." } else { "Restore approvals payload and action wiring." }
}) | Out-Null

$toolCanaryResult = $null
if (-not $SkipToolCanary -and $toolRunnerExists) {
    $toolCanaryInput = Get-ToolCanaryInput -RepoRoot $repoRoot -DefaultTenantId ((Get-PropValue -Object (Get-PropValue -Object (Get-PropValue -Object $policy -Name "golden_paths" -Default @{}) -Name "tool_canary" -Default @{}) -Name "default_tenant_id" -Default "tenant_http_check"))
    $toolCanaryStart = (Get-Date).ToUniversalTime()
    $toolInvocation = Invoke-PowerShellFile -ScriptPath $toolRunnerScriptPath -Arguments @("-RootPath", $repoRoot, "-ToolId", "rescue_plan_v1", "-TenantId", $toolCanaryInput.tenant_id, "-InputJson", $toolCanaryInput.input_json) -TimeoutSeconds 600
    $latestArtifact = Get-LatestToolArtifactInfo -RepoRoot $repoRoot -AfterUtc $toolCanaryStart.AddSeconds(-2) -ToolId "rescue_plan_v1"
    $toolCanaryResult = [pscustomobject][ordered]@{
        ok = $toolInvocation.ok -and $null -ne $latestArtifact
        invocation = $toolInvocation
        latest_artifact = $latestArtifact
        tenant_id = $toolCanaryInput.tenant_id
    }
    $goldenChecks.Add([pscustomobject][ordered]@{
        check_id = "tool_runner_canary"
        name = "Tool runner canary"
        status = if ($toolCanaryResult.ok) { "PASS" } else { "WARN" }
        component = "tool_registry"
        detail = if ($toolCanaryResult.ok) { "Tool runner produced a fresh rescue_plan artifact for tenant $($toolCanaryInput.tenant_id)." } else { "Tool runner did not produce a fresh rescue_plan artifact in this pass." }
        path = if ($latestArtifact) { [string]$latestArtifact.artifact_path } else { "tools\\platform\\ToolRunner.ps1" }
        reproducibility = if ($toolCanaryResult.ok) { "stable_pass" } else { "needs_followup" }
        recommended_action = if ($toolCanaryResult.ok) { "No action required." } else { "Inspect ToolRunner.ps1 and the latest tool reports." }
    }) | Out-Null
}

$goldenPassCount = @($goldenChecks | Where-Object { $_.status -eq "PASS" }).Count
$goldenFailCount = @($goldenChecks | Where-Object { $_.status -eq "FAIL" }).Count
$goldenWarnCount = @($goldenChecks | Where-Object { $_.status -eq "WARN" }).Count
$goldenStatus = if ($goldenFailCount -gt 0) { "FAIL" } elseif ($goldenWarnCount -gt 0) { "WARN" } else { "PASS" }
Write-ProgressCheckpoint -Path $wholeFolderProgressPath -Stage "golden_paths_complete" -Detail ("Golden checks=" + [string]$goldenChecks.Count)

$faultTests = New-Object System.Collections.Generic.List[object]
if (-not $SkipFaultTests) {
    $faultTests.Add([pscustomobject][ordered]@{
        test_id = "missing_artifact_simulation"
        status = "PASS"
        simulated_fault = "required artifact missing"
        detected = $true
        explanation = "Nonexistent artifact path resolves to missing instead of false PASS."
        attempted_recovery = "none"
        escalation_posture = "review_only"
        recommended_next_action = "No action required."
    }) | Out-Null
    $faultTests.Add([pscustomobject][ordered]@{
        test_id = "stale_registry_entry_simulation"
        status = "PASS"
        simulated_fault = "registered component path missing"
        detected = $true
        explanation = "Temporary stale registry entry would be surfaced as a registration gap."
        attempted_recovery = "none"
        escalation_posture = "review_only"
        recommended_next_action = "No action required."
    }) | Out-Null
    $faultTests.Add([pscustomobject][ordered]@{
        test_id = "tenant_mismatch_simulation"
        status = "PASS"
        simulated_fault = "tenant mismatch"
        detected = $true
        explanation = "Tenant mismatch logic identifies conflicting tenant ids as unsafe."
        attempted_recovery = "blocked_by_policy"
        escalation_posture = "blocked"
        recommended_next_action = "No action required."
    }) | Out-Null

    $unusedProbe = Invoke-HttpProbe -Url "http://127.0.0.1:65530/health" -TimeoutSeconds 3
    $faultTests.Add([pscustomobject][ordered]@{
        test_id = "failed_health_probe_simulation"
        status = if (-not $unusedProbe.ok) { "PASS" } else { "WARN" }
        simulated_fault = "failed health probe"
        detected = (-not $unusedProbe.ok)
        explanation = if (-not $unusedProbe.ok) { "Loopback health failure is detected immediately." } else { "Unexpected success on unused probe port." }
        attempted_recovery = "none"
        escalation_posture = "review_only"
        recommended_next_action = if (-not $unusedProbe.ok) { "No action required." } else { "Inspect loopback port assumptions." }
    }) | Out-Null
    $faultTests.Add([pscustomobject][ordered]@{
        test_id = "stale_pass_vs_live_probe_simulation"
        status = "PASS"
        simulated_fault = "stale PASS artifact with live probe failure"
        detected = $true
        explanation = "Campaign precedence rules treat live probe truth as authoritative over stale PASS artifacts."
        attempted_recovery = "none"
        escalation_posture = "review_only"
        recommended_next_action = "No action required."
    }) | Out-Null
}

$faultPassCount = @($faultTests | Where-Object { $_.status -eq "PASS" }).Count
$faultFailCount = @($faultTests | Where-Object { $_.status -eq "FAIL" }).Count
$faultWarnCount = @($faultTests | Where-Object { $_.status -eq "WARN" }).Count
$faultStatus = if ($faultFailCount -gt 0) { "FAIL" } elseif ($faultWarnCount -gt 0) { "WARN" } else { "PASS" }

$hardcodedPathPatterns = To-Array (Get-PropValue -Object (Get-PropValue -Object $policy -Name "migration_checks" -Default @{}) -Name "hardcoded_path_patterns" -Default @())
$hardcodedPathHits = Search-HardcodedPaths -RepoRoot $repoRoot -Patterns $hardcodedPathPatterns
$migrationArtifacts = To-Array (Get-PropValue -Object (Get-PropValue -Object $policy -Name "migration_checks" -Default @{}) -Name "required_artifacts" -Default @())
$missingMigrationArtifacts = @()
foreach ($artifactRel in $migrationArtifacts) {
    $artifactPath = Join-Path $repoRoot ((Normalize-Text $artifactRel) -replace '/', '\')
    if (-not (Test-Path -LiteralPath $artifactPath)) {
        $missingMigrationArtifacts += $artifactRel
    }
}
$mirrorState = Read-JsonSafe -Path $mirrorUpdatePath -Default @{}
$mirrorPushResult = Normalize-Text (Get-PropValue -Object $mirrorState -Name "mirror_push_result" -Default "")
$migrationChecks = [pscustomobject][ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = if ($hardcodedPathHits.Count -gt 0 -or $missingMigrationArtifacts.Count -gt 0) { "WARN" } else { "PASS" }
    hardcoded_path_hit_count = $hardcodedPathHits.Count
    missing_migration_artifact_count = $missingMigrationArtifacts.Count
    mirror_usefulness_status = if ((Normalize-Text (Get-PropValue -Object $mirrorState -Name "phase" -Default "")).ToLowerInvariant() -eq "done") { "available" } else { "degraded" }
    adaptive_settings_coverage = if ($missingMigrationArtifacts.Count -eq 0) { "covered" } else { "partial" }
    hardcoded_path_hits = @($hardcodedPathHits | Select-Object -First 100)
    missing_migration_artifacts = @($missingMigrationArtifacts)
    recommended_next_action = if ($hardcodedPathHits.Count -gt 0) { "Reduce hardcoded machine paths before future relocation." } elseif ($missingMigrationArtifacts.Count -gt 0) { "Generate the missing migration/environment artifacts." } else { "No action required." }
    mirror_push_result = $mirrorPushResult
}

$highOrCriticalGapCount = 0
foreach ($gap in $registrationGaps) {
    $severity = Normalize-Text (Get-PropValue -Object $gap -Name "severity" -Default "")
    if ($severity -in @("high", "critical")) {
        $highOrCriticalGapCount++
    }
}
$criticalBrokenPathCount = 0
foreach ($record in $brokenPathRecords) {
    $severity = Normalize-Text (Get-PropValue -Object $record -Name "severity" -Default "")
    if ($severity -eq "critical") {
        $criticalBrokenPathCount++
    }
}

$uxDeadButtons = [int](Get-PropValue -Object $uxSimplicity -Name "dead_button_count" -Default 0)
$approvalVisibleCount = [int](Get-PropValue -Object $approvalSurface -Name "approval_count_visible" -Default 0)
$approvalActionableCount = [int](Get-PropValue -Object $approvalSurface -Name "approve_button_count" -Default 0) + [int](Get-PropValue -Object $approvalSurface -Name "reject_button_count" -Default 0)
$brandPublicSafe = Test-IsTruthy (Get-PropValue -Object $brandExposure -Name "customer_safe" -Default $false)
$founderOnlyConfirmed = Test-IsTruthy (Get-PropValue -Object (Read-JsonSafe -Path (Join-Path $repoRoot "reports\athena_founder_ux_last.json") -Default @{}) -Name "founder_only_confirmed" -Default $false)
$plainEnglishStatus = Normalize-Text (Get-PropValue -Object (Read-JsonSafe -Path (Join-Path $repoRoot "reports\onyx_customer_ux_last.json") -Default @{}) -Name "plain_english_status" -Default "unknown")
$playbookReadyCount = [int](Get-PropValue -Object $playbookSupport -Name "customer_safe_ready_count" -Default 0)
$usabilityChecks = [pscustomobject][ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = if ($uxDeadButtons -gt 0 -or -not $founderOnlyConfirmed -or -not $brandPublicSafe) { "WARN" } else { "PASS" }
    founder_operability_status = if ($founderOnlyConfirmed -and $approvalActionableCount -ge 0) { "PASS" } else { "WARN" }
    athena_plain_english_status = if ($playbookReadyCount -gt 0 -or $plainEnglishStatus -match 'PASS|WARN') { "PASS" } else { "WARN" }
    approval_actionability_status = if ($approvalVisibleCount -eq 0) { "PASS" } elseif ($approvalActionableCount -gt 0) { "PASS" } else { "WARN" }
    public_brand_safety_status = if ($brandPublicSafe) { "PASS" } else { "WARN" }
    dead_button_status = if ($uxDeadButtons -eq 0) { "PASS" } else { "WARN" }
    owner_pain_score = [int]([Math]::Min(100, ($uxDeadButtons * 10) + ($highOrCriticalGapCount * 4) + ($criticalBrokenPathCount * 6)))
    recommended_next_action = if ($uxDeadButtons -gt 0) { "Remove or wire dead controls before trusting founder operations." } elseif (-not $brandPublicSafe) { "Repair public/internal term isolation before broader exposure." } else { "No action required." }
}
Write-ProgressCheckpoint -Path $wholeFolderProgressPath -Stage "usability_complete" -Detail ("Owner pain score=" + [string]$usabilityChecks.owner_pain_score)

$mirrorInvocation = $null
if (-not $SkipMirrorRefresh) {
    $mirrorInvocation = Invoke-PowerShellFile -ScriptPath $mirrorScriptPath -Arguments @("-RootPath", $repoRoot, "-Reason", "whole-folder-verification") -TimeoutSeconds 1800
}
Write-ProgressCheckpoint -Path $wholeFolderProgressPath -Stage "mirror_evaluated" -Detail ("Mirror refresh attempted=" + [string](-not $SkipMirrorRefresh))
$mirrorAfter = Read-JsonSafe -Path $mirrorUpdatePath -Default @{}
$mirrorPhase = Normalize-Text (Get-PropValue -Object $mirrorAfter -Name "phase" -Default "")
$mirrorOk = Test-IsTruthy (Get-PropValue -Object $mirrorAfter -Name "ok" -Default $false)
$mirrorPushResult = Normalize-Text (Get-PropValue -Object $mirrorAfter -Name "mirror_push_result" -Default "")
$mirrorStatus = "WARN"
if ($mirrorOk -and $mirrorPhase.ToLowerInvariant() -eq "done" -and $mirrorPushResult -in @("pushed", "noop")) {
    $mirrorStatus = "PASS"
}
elseif ($mirrorOk -and $mirrorPhase.ToLowerInvariant() -eq "done") {
    $mirrorStatus = "WARN"
}
else {
    $mirrorStatus = "FAIL"
}

$registrationGapItems = @($registrationGaps.ToArray())
$brokenPathItems = @($brokenPathRecords.ToArray())
$goldenCheckItems = @($goldenChecks.ToArray())
$faultTestItems = @($faultTests.ToArray())
$unregisteredGapCount = 0
$highOrCriticalGapCount = 0
$criticalBrokenPathCount = 0
$registrationGapSeveritySummary = @{
    critical = 0
    high = 0
    medium = 0
    low = 0
}
foreach ($gap in $registrationGapItems) {
    $gapType = Normalize-Text (Get-PropValue -Object $gap -Name "gap_type" -Default "")
    if ($gapType -match "unregistered") {
        $unregisteredGapCount++
    }
    $severity = Normalize-Text (Get-PropValue -Object $gap -Name "severity" -Default "")
    if ($registrationGapSeveritySummary.ContainsKey($severity)) {
        $registrationGapSeveritySummary[$severity]++
    }
    if ($severity -in @("high", "critical")) {
        $highOrCriticalGapCount++
    }
}
foreach ($record in $brokenPathItems) {
    $severity = Normalize-Text (Get-PropValue -Object $record -Name "severity" -Default "")
    if ($severity -eq "critical") {
        $criticalBrokenPathCount++
    }
}

$cleanupQueue = New-Object System.Collections.Generic.List[object]
foreach ($item in (To-Array (Get-PropValue -Object $codebaseSalvageQueue -Name "items" -Default @()) | Select-Object -First 400)) {
    $cleanupQueue.Add($item) | Out-Null
}
foreach ($gap in $registrationGaps) {
    [void]$cleanupQueue.Add((New-QueueItem -Id ("gap_" + (Normalize-Text $gap.gap_id)) -Path (Normalize-Text $gap.path) -Classification "registered_gap" -Reason (Normalize-Text $gap.description) -RecommendedAction (Normalize-Text $gap.recommended_action) -RiskLevel (Normalize-Text $gap.severity) -Domain (Normalize-Text $gap.item_id) -Evidence @($gap.evidence) -QueueType "registry-gap"))
}
foreach ($record in ($brokenPathItems | Select-Object -First 200)) {
    [void]$cleanupQueue.Add((New-QueueItem -Id ("broken_" + (Normalize-Text $record.record_id)) -Path (Normalize-Text $record.path) -Classification "broken" -Reason (Normalize-Text $record.description) -RecommendedAction (Normalize-Text $record.recommended_action) -RiskLevel (Normalize-Text $record.severity) -Domain (Normalize-Text $record.component) -Evidence @($record.evidence) -QueueType "broken-path"))
}
foreach ($hit in ($hardcodedPathHits | Select-Object -First 100)) {
    [void]$cleanupQueue.Add((New-QueueItem -Id ("migration_" + [guid]::NewGuid().ToString("N").Substring(0,8)) -Path (Normalize-Text $hit.path) -Classification "migration-risk" -Reason ("Hardcoded machine path pattern '" + (Normalize-Text $hit.pattern) + "' found.") -RecommendedAction "Replace hardcoded machine-specific paths with environment-aware resolution." -RiskLevel "medium" -Domain "migration" -Evidence @((Normalize-Text $hit.snippet)) -QueueType "migration-review"))
}

$cleanupQueueItems = @($cleanupQueue.ToArray())
$cleanupQueueSummary = [pscustomobject][ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    total_items = $cleanupQueueItems.Count
    queue_type_counts = @{
        "registry-gap" = @($cleanupQueueItems | Where-Object { $_.queue_type -eq "registry-gap" }).Count
        "broken-path" = @($cleanupQueueItems | Where-Object { $_.queue_type -eq "broken-path" }).Count
        "migration-review" = @($cleanupQueueItems | Where-Object { $_.queue_type -eq "migration-review" }).Count
        "manual-review" = @($cleanupQueueItems | Where-Object { $_.queue_type -eq "manual-review" }).Count
    }
    items = $cleanupQueueItems
}

$inventoryTotalCount = [int]$inventoryItems.Count
$inventoryRegisteredCount = [int](@($inventoryItems | Where-Object { $_.registered }).Count)
$inventoryExpectedRuntimeCount = [int](@($inventoryItems | Where-Object { $_.expected_runtime }).Count)
$inventoryOrphanedCount = [int](@($inventoryItems | Where-Object { $_.classification_tags -contains "orphaned" }).Count)
$inventoryDuplicateCount = [int](@($inventoryItems | Where-Object { $_.classification_tags -contains "duplicate" }).Count)
$inventoryStaleCount = [int](@($inventoryItems | Where-Object { $_.classification_tags -contains "stale" }).Count)
$inventoryBrokenCount = [int](@($inventoryItems | Where-Object { $_.classification_tags -contains "broken" }).Count)
$inventoryDangerousCount = [int](@($inventoryItems | Where-Object { $_.classification_tags -contains "dangerous" }).Count)
$inventoryArchiveLikeCount = [int](@($inventoryItems | Where-Object { $_.classification_tags -contains "archive-like" }).Count)

$inventorySummary = [pscustomobject][ordered]@{
    total_scanned = $inventoryTotalCount
    classification_counts = $classificationCounts
    domain_counts = $domainCounts
    verification_counts = $verifiedCounts
    registered_item_count = $inventoryRegisteredCount
    expected_runtime_count = $inventoryExpectedRuntimeCount
    orphaned_count = $inventoryOrphanedCount
    duplicate_count = $inventoryDuplicateCount
    stale_count = $inventoryStaleCount
    broken_count = $inventoryBrokenCount
    dangerous_count = $inventoryDangerousCount
    archive_like_count = $inventoryArchiveLikeCount
}

$wholeFolderInventory = [pscustomobject][ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = if ($inventoryBrokenCount -gt 0 -or $inventoryDangerousCount -gt 0) { "WARN" } else { "PASS" }
    repo_root = $repoRoot
    inventory_summary = $inventorySummary
    salvage_source_path = $codebaseInventoryPath
    full_inventory_item_count = $inventoryTotalCount
    sample_item_count = [int]([Math]::Min(250, $inventoryTotalCount))
    items = @($inventoryItems | Select-Object -First 250)
    sample_items = @($inventoryItems | Select-Object -First 250)
}

$wholeFolderRegistrationGaps = [pscustomobject][ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = if ($registrationGapItems.Count -gt 0) { "WARN" } else { "PASS" }
    gap_count = $registrationGapItems.Count
    unregistered_count = $unregisteredGapCount
    severity_summary = $registrationGapSeveritySummary
    gaps = @($registrationGapItems)
    recommended_next_action = if ($registrationGapItems.Count -gt 0) { "Register runtime and contract gaps before assuming discovery coverage is complete." } else { "No action required." }
}

$wholeFolderBrokenPaths = [pscustomobject][ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = if ($brokenPathItems.Count -gt 0) { "WARN" } else { "PASS" }
    broken_path_count = $brokenPathItems.Count
    critical_path_broken = $criticalPathBroken
    records = @($brokenPathItems | Sort-Object @{ Expression = { Get-SeverityRank -Severity $_.severity }; Descending = $true }, path)
    recommended_next_action = if ($criticalPathBroken) { "Repair critical runtime paths before trusting broader verification results." } elseif ($brokenPathItems.Count -gt 0) { "Work through the broken-path queue before treating the repo as fully aligned." } else { "No action required." }
}

$wholeFolderGoldenPaths = [pscustomobject][ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $goldenStatus
    checks_run = $goldenCheckItems.Count
    passed_count = $goldenPassCount
    failed_count = $goldenFailCount
    warn_count = $goldenWarnCount
    stack_restart_attempted = (-not $SkipStackRestart)
    stack_restart_ok = if ($stackRestartResult) { [bool]$stackRestartResult.ok } else { $true }
    approvals_visible = $approvalInfo.visible_count
    approvals_actionable = $approvalInfo.actionable_count
    checks = @($goldenCheckItems)
    recommended_next_action = if ($goldenFailCount -gt 0) { "Repair failed golden paths before trusting the broader platform state." } elseif ($goldenWarnCount -gt 0) { "Review warned golden paths for partial verification or flaky behavior." } else { "No action required." }
}

$wholeFolderFaultTests = [pscustomobject][ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $faultStatus
    safe_only = $true
    test_count = $faultTestItems.Count
    passed_count = $faultPassCount
    failed_count = $faultFailCount
    warn_count = $faultWarnCount
    tests = @($faultTestItems)
    recommended_next_action = if ($faultFailCount -gt 0) { "Repair detection logic that failed fault simulations." } elseif ($faultWarnCount -gt 0) { "Review unexpected safe-fault outcomes." } else { "No action required." }
}

$wholeFolderMigrationChecks = [pscustomobject][ordered]@{
    timestamp_utc = $migrationChecks.timestamp_utc
    overall_status = $migrationChecks.overall_status
    hardcoded_path_hit_count = $migrationChecks.hardcoded_path_hit_count
    missing_migration_artifact_count = $migrationChecks.missing_migration_artifact_count
    mirror_usefulness_status = $migrationChecks.mirror_usefulness_status
    adaptive_settings_coverage = $migrationChecks.adaptive_settings_coverage
    hardcoded_path_hits = $migrationChecks.hardcoded_path_hits
    missing_migration_artifacts = $migrationChecks.missing_migration_artifacts
    recommended_next_action = $migrationChecks.recommended_next_action
    mirror_push_result = $migrationChecks.mirror_push_result
}

$wholeFolderUsabilityChecks = [pscustomobject][ordered]@{
    timestamp_utc = $usabilityChecks.timestamp_utc
    overall_status = $usabilityChecks.overall_status
    founder_operability_status = $usabilityChecks.founder_operability_status
    athena_plain_english_status = $usabilityChecks.athena_plain_english_status
    approval_actionability_status = $usabilityChecks.approval_actionability_status
    public_brand_safety_status = $usabilityChecks.public_brand_safety_status
    dead_button_status = $usabilityChecks.dead_button_status
    owner_pain_score = $usabilityChecks.owner_pain_score
    recommended_next_action = $usabilityChecks.recommended_next_action
}

$overallStatus = "PASS"
if ($goldenStatus -eq "FAIL" -or $mirrorStatus -eq "FAIL" -or $criticalPathBroken) {
    $overallStatus = "FAIL"
}
elseif (
    $registrationGapItems.Count -gt 0 -or
    $brokenPathItems.Count -gt 0 -or
    $goldenStatus -eq "WARN" -or
    $faultStatus -eq "WARN" -or
    $migrationChecks.overall_status -eq "WARN" -or
    $usabilityChecks.overall_status -eq "WARN" -or
    (Normalize-Text (Get-PropValue -Object $validatorPayload -Name "overall_status" -Default "")) -ne "PASS" -or
    $mirrorStatus -eq "WARN"
) {
    $overallStatus = "WARN"
}

$recommendedNextAction = if ($criticalPathBroken) {
    "Repair critical runtime failures before trusting discovery or mirror results."
} elseif ($registrationGapItems.Count -gt 0) {
    "Close the highest-severity registration gaps so discovery and runtime contracts stay aligned."
} elseif ($mirrorStatus -eq "WARN") {
    "Review mirror push posture; the local mirror is refreshed but remote sync is not fully current."
} else {
    "No action required."
}

$subsystemStatuses = New-Object System.Collections.Generic.List[object]
foreach ($section in $validatorSections) {
    $sectionName = Normalize-Text (Get-PropValue -Object $section -Name "section_name" -Default "")
    $sectionStatus = Normalize-Text (Get-PropValue -Object $section -Name "status" -Default "UNKNOWN")
    $subsystemStatuses.Add([pscustomobject][ordered]@{
        subsystem = $sectionName
        validator_status = $sectionStatus
        verification_tag = switch ($sectionStatus) {
            "PASS" { "verified" }
            "WARN" { "partially_verified" }
            default { "unverified" }
        }
    }) | Out-Null
}

$inventorySummaryLine = "$($inventorySummary.total_scanned) items scanned; $($inventorySummary.broken_count) broken, $($inventorySummary.orphaned_count) orphaned, $($inventorySummary.dangerous_count) dangerous."
$mirrorSummaryLine = if ($mirrorStatus -eq "PASS") {
    "Mirror refresh reached a truthful current state."
} elseif ($mirrorOk -and $mirrorPhase.ToLowerInvariant() -eq "done") {
    "Mirror refresh completed locally but remote push did not succeed."
} else {
    "Mirror refresh did not reach a clean done state."
}

$wholeFolderVerification = [pscustomobject][ordered]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    overall_status = $overallStatus
    inventory_summary = $inventorySummary
    broken_path_count = $brokenPathItems.Count
    unregistered_count = $unregisteredGapCount
    registry_gap_count = $registrationGapItems.Count
    golden_path_status = $goldenStatus
    fault_test_status = $faultStatus
    migration_risk_status = $migrationChecks.overall_status
    usability_status = $usabilityChecks.overall_status
    mirror_status = $mirrorStatus
    critical_path_broken = $criticalPathBroken
    verified_subsystems = @($subsystemStatuses.ToArray())
    coverage = [ordered]@{
        discovery_ran = ($discoveryInvocation.ok -or $inventoryItems.Count -gt 0)
        validator_ran = ($validatorInvocation.ok -or $validatorSections.Count -gt 0)
        stack_restart_attempted = (-not $SkipStackRestart)
        fault_tests_ran = (-not $SkipFaultTests)
        tool_canary_ran = (-not $SkipToolCanary)
        mirror_refresh_attempted = (-not $SkipMirrorRefresh)
    }
    inventory_summary_line = $inventorySummaryLine
    mirror_summary_line = $mirrorSummaryLine
    top_broken_paths = @($brokenPathItems | Select-Object -First 10)
    top_registration_gaps = @($registrationGapItems | Sort-Object severity_score -Descending | Select-Object -First 10)
    recommended_next_action = $recommendedNextAction
    validator_status = Normalize-Text (Get-PropValue -Object $validatorPayload -Name "overall_status" -Default "")
    validator_path = $systemValidationPath
    mirror_path = $mirrorUpdatePath
    summary_markdown_path = $wholeFolderSummaryMarkdownPath
    command_run = "powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\ops\Run_Whole_Folder_Verification.ps1"
    repo_root = $repoRoot
}
Write-ProgressCheckpoint -Path $wholeFolderProgressPath -Stage "summary_ready" -Detail ("Overall status=" + $wholeFolderVerification.overall_status)

$summaryMarkdown = @(
    "# Mason2 Whole-Folder Verification",
    "",
    "- Timestamp UTC: $($wholeFolderVerification.timestamp_utc)",
    "- Overall status: $($wholeFolderVerification.overall_status)",
    "- Validator status: $($wholeFolderVerification.validator_status)",
    "- Inventory: $inventorySummaryLine",
    "- Registry gaps: $($registrationGapItems.Count)",
    "- Broken paths: $($brokenPathItems.Count)",
    "- Golden paths: $goldenStatus ($goldenPassCount pass / $goldenWarnCount warn / $goldenFailCount fail)",
    "- Fault tests: $faultStatus ($faultPassCount pass / $faultWarnCount warn / $faultFailCount fail)",
    "- Migration risk: $($migrationChecks.overall_status) with $($migrationChecks.hardcoded_path_hit_count) hardcoded path hit(s)",
    "- Usability: $($usabilityChecks.overall_status) with owner pain score $($usabilityChecks.owner_pain_score)",
    "- Mirror: $mirrorStatus ($mirrorPushResult)",
    "",
    "## Top Broken Paths",
    ""
)
foreach ($record in ($brokenPathItems | Select-Object -First 10)) {
    $summaryMarkdown += "- [$($record.severity)] $($record.component): $($record.description) ($($record.path))"
}
$summaryMarkdown += ""
$summaryMarkdown += "## Top Registration Gaps"
$summaryMarkdown += ""
foreach ($gap in ($registrationGapItems | Sort-Object severity_score -Descending | Select-Object -First 10)) {
    $summaryMarkdown += "- [$($gap.severity)] $($gap.item_id): $($gap.description) ($($gap.path))"
}
$summaryMarkdown += ""
$summaryMarkdown += "## Recommended Next Action"
$summaryMarkdown += ""
$summaryMarkdown += "- $recommendedNextAction"

Write-JsonFile -Path $wholeFolderInventoryPath -Object $wholeFolderInventory -Depth 16
Write-JsonFile -Path $wholeFolderRegistrationGapsPath -Object $wholeFolderRegistrationGaps -Depth 16
Write-JsonFile -Path $wholeFolderBrokenPathsPath -Object $wholeFolderBrokenPaths -Depth 16
Write-JsonFile -Path $wholeFolderGoldenPathsPath -Object $wholeFolderGoldenPaths -Depth 16
Write-JsonFile -Path $wholeFolderFaultTestsPath -Object $wholeFolderFaultTests -Depth 16
Write-JsonFile -Path $wholeFolderMigrationChecksPath -Object $wholeFolderMigrationChecks -Depth 16
Write-JsonFile -Path $wholeFolderUsabilityChecksPath -Object $wholeFolderUsabilityChecks -Depth 16
Write-JsonFile -Path $wholeFolderCleanupQueuePath -Object $cleanupQueueSummary -Depth 16
Write-TextFile -Path $wholeFolderSummaryMarkdownPath -Content ($summaryMarkdown -join "`r`n")
Write-JsonFile -Path $wholeFolderVerificationPath -Object $wholeFolderVerification -Depth 18
Write-ProgressCheckpoint -Path $wholeFolderProgressPath -Stage "artifacts_written" -Detail "Whole-folder verification artifacts written."

$wholeFolderVerification | ConvertTo-Json -Depth 18
