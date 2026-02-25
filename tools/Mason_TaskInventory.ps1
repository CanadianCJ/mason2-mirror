[CmdletBinding()]
param()

<#
.SYNOPSIS
  Inventory all Windows scheduled tasks and classify them for Mason.

.DESCRIPTION
  - Reads Mason2 root from this script's location.
  - Loads scheduler_manifest.json (if present).
  - Enumerates all scheduled tasks via Get-ScheduledTask.
  - Classifies tasks as:
      - mason_managed (in manifest, points into Mason2)
      - mason_legacy (points into Mason2, but not in manifest)
      - system (Microsoft\Windows or similar)
      - external (3rd-party / other)
  - Writes reports\task_inventory.json with full details + summary.
#>

# Figure out Mason root from script location (…\Mason2\tools\this.ps1)
$ScriptDir = Split-Path -Parent $PSCommandPath
$MasonRoot = Split-Path -Parent $ScriptDir

$ConfigDir    = Join-Path $MasonRoot "config"
$ReportsDir   = Join-Path $MasonRoot "reports"
$QuarantineDir = Join-Path $MasonRoot "quarantine"

foreach ($dir in @($ConfigDir, $ReportsDir, $QuarantineDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

$ManifestPath = Join-Path $ConfigDir "scheduler_manifest.json"
$manifest = $null
$manifestTasksById = @{}

if (Test-Path $ManifestPath) {
    try {
        $manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
        if ($manifest.tasks) {
            foreach ($t in $manifest.tasks) {
                if ($t.id) {
                    $manifestTasksById[$t.id] = $t
                }
            }
        }
    } catch {
        Write-Warning "Failed to parse scheduler_manifest.json: $($_.Exception.Message)"
    }
} else {
    Write-Verbose "scheduler_manifest.json not found; proceeding without manifest mapping."
}

# Heuristic: anything under this path is "Mason-related"
$MasonRootNormalized = [IO.Path]::GetFullPath($MasonRoot).TrimEnd('\')

# Helper: extract any script path from a ScheduledTask action
function Get-TaskScriptPath {
    param(
        [Parameter(Mandatory=$true)]
        [Microsoft.Management.Infrastructure.CimInstance] $Action
    )

    # Typical pattern: powershell.exe -File "C:\path\to\script.ps1"
    $exec = $Action.Execute
    $args = $Action.Arguments

    $candidates = @()

    if ($exec) { $candidates += $exec }
    if ($args) { $candidates += $args }

    # Look for paths ending with .ps1
    foreach ($c in $candidates) {
        # Split on whitespace and quotes, crude but effective enough
        $tokens = $c -split '[\s"]+' | Where-Object { $_ -ne "" }
        foreach ($tok in $tokens) {
            if ($tok -like "*.ps1") {
                try {
                    $full = [IO.Path]::GetFullPath($tok)
                    return $full
                } catch {
                    # ignore invalid paths
                }
            }
        }
    }

    return $null
}

$allTasks = @()
try {
    $allTasks = Get-ScheduledTask -ErrorAction Stop
} catch {
    Write-Warning "Failed to enumerate scheduled tasks: $($_.Exception.Message)"
}

$inventory = @()
$summary = @{
    total                 = 0
    mason_managed         = 0
    mason_legacy          = 0
    system                = 0
    external              = 0
    errors                = 0
}

foreach ($task in $allTasks) {
    $summary.total++

    $taskName = $task.TaskName
    $taskPath = $task.TaskPath
    $taskState = $task.State.ToString()

    # Capture actions and script paths
    $actions = @()
    $scriptPaths = @()

    foreach ($action in $task.Actions) {
        $actions += @{
            execute  = $action.Execute
            arguments = $action.Arguments
            workingDirectory = $action.WorkingDirectory
        }

        $scriptPath = Get-TaskScriptPath -Action $action
        if ($scriptPath) {
            $scriptPaths += $scriptPath
        }
    }

    # Classification
    $classification = "external"
    $source         = "unknown"
    $manifestEntry  = $null
    $isSystemTask   = $false
    $isMasonScript  = $false

    # System task heuristic
    if ($taskPath -like "\Microsoft\Windows\*" -or $taskPath -like "\Microsoft\*") {
        $isSystemTask = $true
    }

    foreach ($sp in $scriptPaths) {
        if ($sp.StartsWith($MasonRootNormalized, [System.StringComparison]::OrdinalIgnoreCase)) {
            $isMasonScript = $true
            break
        }
    }

    if ($isSystemTask -and -not $isMasonScript) {
        $classification = "system"
        $source = "windows"
        $summary.system++
    } elseif ($isMasonScript) {
        # Check if in manifest by task name
        if ($manifestTasksById.ContainsKey($taskName)) {
            $classification = "mason_managed"
            $manifestEntry = $manifestTasksById[$taskName]
            $source = "manifest"
            $summary.mason_managed++
        } else {
            $classification = "mason_legacy"
            $source = "mason_unknown"
            $summary.mason_legacy++
        }
    } else {
        $classification = "external"
        $source = "non_mason"
        $summary.external++
    }

    $inventory += @{
        name            = $taskName
        path            = $taskPath
        state           = $taskState
        classification  = $classification
        source          = $source
        script_paths    = $scriptPaths
        actions         = $actions
        lastRunTime     = $task.LastRunTime
        nextRunTime     = $task.NextRunTime
    }
}

$report = @{
    generated_at = (Get-Date).ToString("o")
    mason_root   = $MasonRootNormalized
    manifest_found = [bool]$manifest
    summary      = $summary
    tasks        = $inventory
}

$InventoryPath = Join-Path $ReportsDir "task_inventory.json"
$report | ConvertTo-Json -Depth 6 | Out-File -FilePath $InventoryPath -Encoding UTF8

Write-Output "Task inventory written to $InventoryPath"
