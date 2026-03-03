[CmdletBinding()]
param(
    [switch]$TestMode
)

$ErrorActionPreference = "Stop"

function Write-WatcherLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

function Get-FileStamp {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return 0L
    }

    try {
        return [long](Get-Item -LiteralPath $Path).LastWriteTimeUtc.Ticks
    }
    catch {
        return 0L
    }
}

Write-WatcherLog "Mason_Executor_Watcher.ps1 starting..."

$ToolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Base = Split-Path -Parent $ToolsDir

$script:StateKnowledgeDir = Join-Path $Base "state\knowledge"
$script:ReportsDir = Join-Path $Base "reports"
$script:pendingPath = Join-Path $StateKnowledgeDir "pending_patch_runs.json"
$script:autoPath = Join-Path $StateKnowledgeDir "pending_auto_apply_requests.json"
$script:executorPath = Join-Path $ToolsDir "Mason_Apply_ApprovedChanges.ps1"
$script:triggerReportPath = Join-Path $ReportsDir "watcher_last_trigger.json"
$script:LastRunUtc = [DateTime]::UtcNow.AddMinutes(-10)

Write-WatcherLog "Base              : $Base"
Write-WatcherLog "State/knowledge   : $StateKnowledgeDir"
Write-WatcherLog "Reports           : $ReportsDir"
Write-WatcherLog "Pending patch file: $pendingPath"
Write-WatcherLog "Auto-apply file   : $autoPath"
Write-WatcherLog "Executor script   : $executorPath"
Write-WatcherLog ("TestMode          : {0}" -f [bool]$TestMode)

if (-not $TestMode -and -not (Test-Path -LiteralPath $executorPath)) {
    Write-WatcherLog "Executor script not found. Exiting." "ERROR"
    exit 1
}

if (-not (Test-Path -LiteralPath $StateKnowledgeDir)) {
    New-Item -ItemType Directory -Path $StateKnowledgeDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

function Invoke-ExecutorIfNeeded {
    param([string]$Reason)

    $nowUtc = [DateTime]::UtcNow
    $span = New-TimeSpan -Start $script:LastRunUtc -End $nowUtc

    if ($span.TotalSeconds -lt 5) {
        Write-WatcherLog "Change detected ($Reason) but debounced (last run $([math]::Round($span.TotalSeconds,2)) seconds ago)." "INFO"
        return
    }

    if (-not (Test-Path -LiteralPath $script:pendingPath)) {
        Write-WatcherLog "Change detected ($Reason) but pending_patch_runs.json does not exist. Skipping." "WARN"
        $script:LastRunUtc = [DateTime]::UtcNow
        return
    }

    if ($TestMode) {
        Write-WatcherLog "Change detected ($Reason). TestMode active; writing trigger report only."
    }
    else {
        Write-WatcherLog "Change detected ($Reason). Running Mason_Apply_ApprovedChanges.ps1 -Execute..."
    }

    try {
        $trigger = [ordered]@{
            triggered_at_utc = (Get-Date).ToUniversalTime().ToString("o")
            reason           = $Reason
            pending_path     = $script:pendingPath
            executor_path    = $script:executorPath
            test_mode        = [bool]$TestMode
        }
        $trigger | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $script:triggerReportPath -Encoding UTF8
    }
    catch {
        Write-WatcherLog ("Failed to write trigger report: {0}" -f $_.Exception.Message) "WARN"
    }

    if (-not $TestMode) {
        try {
            & $script:executorPath -Execute
            Write-WatcherLog "Executor run completed."
        }
        catch {
            Write-WatcherLog ("Executor error: {0}" -f $_.Exception.Message) "ERROR"
        }
    }

    $script:LastRunUtc = [DateTime]::UtcNow
}

$fsw = New-Object System.IO.FileSystemWatcher
$fsw.Path = $StateKnowledgeDir
$fsw.Filter = "*.json"
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents = $true
$fsw.NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite, Size'

Write-WatcherLog "FileSystemWatcher set on $StateKnowledgeDir for *.json changes."

$actionScript = {
    param($sender, $eventArgs)

    try {
        $fullPath = [string]$eventArgs.FullPath
        if ([string]::IsNullOrWhiteSpace($fullPath) -and $eventArgs.Name) {
            $fullPath = Join-Path $script:StateKnowledgeDir ([string]$eventArgs.Name)
        }
        if ([string]::IsNullOrWhiteSpace($fullPath)) {
            return
        }

        $fullPathNorm = ($fullPath -replace "/", "\").Trim().ToLowerInvariant()
        $pendingNorm = (($script:pendingPath -replace "/", "\")).Trim().ToLowerInvariant()
        $autoNorm = (($script:autoPath -replace "/", "\")).Trim().ToLowerInvariant()

        if (($fullPathNorm -ne $pendingNorm) -and ($fullPathNorm -ne $autoNorm)) {
            return
        }

        $reason = "{0} on {1}" -f $eventArgs.ChangeType, $fullPath
        Write-WatcherLog "File event: $reason"
        Invoke-ExecutorIfNeeded -Reason $reason
    }
    catch {
        Write-WatcherLog ("Watcher event error: {0}" -f $_.Exception.Message) "ERROR"
    }
}

$changedHandler = Register-ObjectEvent -InputObject $fsw -EventName Changed -SourceIdentifier "MasonExecutorWatcherChanged" -Action $actionScript
$createdHandler = Register-ObjectEvent -InputObject $fsw -EventName Created -SourceIdentifier "MasonExecutorWatcherCreated" -Action $actionScript
$renamedHandler = Register-ObjectEvent -InputObject $fsw -EventName Renamed -SourceIdentifier "MasonExecutorWatcherRenamed" -Action $actionScript

Write-WatcherLog "Mason executor watcher is now running. It will trigger when approval files change."
Write-WatcherLog "Press Ctrl+C to stop this watcher window."

$script:LastPendingStamp = Get-FileStamp -Path $script:pendingPath
$script:LastAutoStamp = Get-FileStamp -Path $script:autoPath

while ($true) {
    Wait-Event -Timeout 2 | Out-Null

    $pendingStamp = Get-FileStamp -Path $script:pendingPath
    if ($pendingStamp -ne $script:LastPendingStamp) {
        $script:LastPendingStamp = $pendingStamp
        Invoke-ExecutorIfNeeded -Reason ("Poll change on {0}" -f $script:pendingPath)
    }

    $autoStamp = Get-FileStamp -Path $script:autoPath
    if ($autoStamp -ne $script:LastAutoStamp) {
        $script:LastAutoStamp = $autoStamp
        Invoke-ExecutorIfNeeded -Reason ("Poll change on {0}" -f $script:autoPath)
    }
}
