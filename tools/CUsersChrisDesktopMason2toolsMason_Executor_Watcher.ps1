[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Write-WatcherLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [$Level] $Message"
}

Write-WatcherLog "Mason_Executor_Watcher.ps1 starting..."

# Figure out Mason root from this script's location
$ToolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Base     = Split-Path -Parent $ToolsDir

$StateKnowledgeDir = Join-Path $Base "state\knowledge"
$pendingPath       = Join-Path $StateKnowledgeDir "pending_patch_runs.json"
$autoPath          = Join-Path $StateKnowledgeDir "pending_auto_apply_requests.json"
$executorPath      = Join-Path $ToolsDir "Mason_Apply_ApprovedChanges.ps1"

Write-WatcherLog "Base              : $Base"
Write-WatcherLog "State/knowledge   : $StateKnowledgeDir"
Write-WatcherLog "Pending patch file: $pendingPath"
Write-WatcherLog "Auto-apply file   : $autoPath"
Write-WatcherLog "Executor script   : $executorPath"

if (-not (Test-Path -LiteralPath $executorPath)) {
    Write-WatcherLog "Executor script not found. Exiting." "ERROR"
    exit 1
}

if (-not (Test-Path -LiteralPath $StateKnowledgeDir)) {
    Write-WatcherLog "State/knowledge directory not found. Creating it."
    New-Item -ItemType Directory -Path $StateKnowledgeDir | Out-Null
}

# Debounce timer
$script:LastRunUtc = [DateTime]::UtcNow.AddMinutes(-10)

function Invoke-ExecutorIfNeeded {
    param(
        [string]$Reason
    )

    $nowUtc = [DateTime]::UtcNow
    $span   = New-TimeSpan -Start $script:LastRunUtc -End $nowUtc

    # Simple debounce so multiple rapid file events don't spam the executor
    if ($span.TotalSeconds -lt 5) {
        Write-WatcherLog "Change detected ($Reason) but debounced (last run $($span.TotalSeconds) seconds ago)." "INFO"
        return
    }

    # Only bother if the pending file exists
    if (-not (Test-Path -LiteralPath $pendingPath)) {
        Write-WatcherLog "Change detected ($Reason) but pending_patch_runs.json does not exist. Skipping executor." "WARN"
        $script:LastRunUtc = [DateTime]::UtcNow
        return
    }

    Write-WatcherLog "Change detected ($Reason). Running Mason_Apply_ApprovedChanges.ps1 -Execute..."

    try {
        & $executorPath -Execute
        Write-WatcherLog "Executor run completed."
    }
    catch {
        Write-WatcherLog ("Executor error: {0}" -f $_.Exception.Message) "ERROR"
    }

    $script:LastRunUtc = [DateTime]::UtcNow
}

# If there is already something pending/approved when the watcher starts,
# you can uncomment this initial call if you want it to process immediately:
# Invoke-ExecutorIfNeeded -Reason "initial start"

# FileSystemWatcher to observe the knowledge directory
$fsw = New-Object System.IO.FileSystemWatcher
$fsw.Path                  = $StateKnowledgeDir
$fsw.Filter                = "*.json"
$fsw.IncludeSubdirectories = $false
$fsw.EnableRaisingEvents   = $true
$fsw.NotifyFilter          = [IO.NotifyFilters]'FileName, LastWrite, Size'

Write-WatcherLog "FileSystemWatcher set on $StateKnowledgeDir for *.json changes."

# Event handlers
$actionScript = {
    param($Event, $pendingPathLocal, $autoPathLocal)

    try {
        $fullPath = $Event.SourceEventArgs.FullPath

        # Only care about our two approval-related files
        if (($fullPath -ne $pendingPathLocal) -and ($fullPath -ne $autoPathLocal)) {
            return
        }

        $reason = "{0} on {1}" -f $Event.EventName, $fullPath
        Write-WatcherLog "File event: $reason"
        Invoke-ExecutorIfNeeded -Reason $reason
    }
    catch {
        Write-WatcherLog ("Watcher event error: {0}" -f $_.Exception.Message) "ERROR"
    }
}

# Register for Changed and Created events
$changedHandler = Register-ObjectEvent -InputObject $fsw -EventName Changed -SourceIdentifier "MasonExecutorWatcherChanged" -Action $actionScript -MessageData @($pendingPath, $autoPath)
$createdHandler = Register-ObjectEvent -InputObject $fsw -EventName Created -SourceIdentifier "MasonExecutorWatcherCreated" -Action $actionScript -MessageData @($pendingPath, $autoPath)

Write-WatcherLog "Mason executor watcher is now running. It will trigger the executor when approval files change."
Write-WatcherLog "Press Ctrl+C to stop this watcher window."

# Keep the script alive to process events
while ($true) {
    Wait-Event -Timeout 60 | Out-Null
}
