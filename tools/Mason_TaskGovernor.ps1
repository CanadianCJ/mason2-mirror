[CmdletBinding()]
param()

<#
.SYNOPSIS
  Govern Windows Task Scheduler according to Mason's manifest and policy.

.DESCRIPTION
  - Loads scheduler_manifest.json and task_governor_policy.json.
  - Ensures "mason_managed" tasks exist and point at the expected scripts.
  - Creates/updates those tasks using schtasks.exe if allowed by policy.
  - Optionally disables/quarantines legacy Mason tasks that are not in manifest
    and appear to reference old/broken Mason directories.
  - Writes reports\task_governor_summary.json with actions taken.

  This version:
    - Uses schtasks.exe with correct quoting.
    - Maps repeat_minutes into MINUTE/HOURLY/DAILY/WEEKLY safely.
    - Runs tasks hidden (-WindowStyle Hidden).
#>

$ScriptDir = Split-Path -Parent $PSCommandPath
$MasonRoot = Split-Path -Parent $ScriptDir

$ConfigDir     = Join-Path $MasonRoot "config"
$ReportsDir    = Join-Path $MasonRoot "reports"
$QuarantineDir = Join-Path $MasonRoot "quarantine"

foreach ($dir in @($ConfigDir, $ReportsDir, $QuarantineDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

$ManifestPath    = Join-Path $ConfigDir "scheduler_manifest.json"
$PolicyPath      = Join-Path $ConfigDir "task_governor_policy.json"
$InventoryPath   = Join-Path $ReportsDir "task_inventory.json"
$QuarantineTasks = Join-Path $QuarantineDir "tasks_quarantined.json"
$SummaryPath     = Join-Path $ReportsDir "task_governor_summary.json"

# ---------- Load manifest ----------
if (-not (Test-Path $ManifestPath)) {
    throw "scheduler_manifest.json not found at $ManifestPath. Create it before running TaskGovernor."
}

try {
    $manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
} catch {
    throw "Failed to parse scheduler_manifest.json: $($_.Exception.Message)"
}

# ---------- Load policy ----------
if (Test-Path $PolicyPath) {
    try {
        $policy = Get-Content -Path $PolicyPath -Raw | ConvertFrom-Json
    } catch {
        throw "Failed to parse task_governor_policy.json: $($_.Exception.Message)"
    }
} else {
    Write-Warning "task_governor_policy.json not found; defaulting to report-only policy."
    $policy = [pscustomobject]@{
        version                        = 1
        mode                           = "report-only"
        quarantine_unknown_mason_tasks = $true
        quarantine_legacy_paths_contains = @("Broken mason", "Mason_old", "Mason_Backup")
        allow_task_creation            = $false
        allow_task_updates             = $false
        allow_task_disable             = $false
    }
}

# ---------- Ensure inventory exists ----------
if (-not (Test-Path $InventoryPath)) {
    Write-Verbose "Task inventory not found; generating via Mason_TaskInventory.ps1"
    $InventoryScriptPath = Join-Path (Join-Path $MasonRoot "tools") "Mason_TaskInventory.ps1"
    if (-not (Test-Path $InventoryScriptPath)) {
        throw "Mason_TaskInventory.ps1 not found at $InventoryScriptPath."
    }
    & $InventoryScriptPath
}

try {
    $inventory = Get-Content -Path $InventoryPath -Raw | ConvertFrom-Json
} catch {
    throw "Failed to parse task_inventory.json: $($_.Exception.Message)"
}

$inventoryByName = @{}
foreach ($task in $inventory.tasks) {
    $inventoryByName[$task.name] = $task
}

$MasonRootNormalized = [IO.Path]::GetFullPath($MasonRoot).TrimEnd('\')

$actionsTaken = @()
$quarantinedTasks = @()

# ---------- Helper: create/update scheduled task from manifest using schtasks.exe ----------
function New-MasonScheduledTask {
    param(
        [Parameter(Mandatory=$true)]
        [pscustomobject] $ManifestTask
    )

    $taskName = $ManifestTask.id
    $scriptRel = $ManifestTask.script_rel_path
    if (-not $scriptRel) {
        throw "Manifest task '$taskName' missing script_rel_path."
    }

    $scriptPath = Join-Path $MasonRoot $scriptRel
    if (-not (Test-Path $scriptPath)) {
        throw "Script path for task '$taskName' not found: $scriptPath"
    }

    # Determine schedule from triggers: prefer Simple, else AtStartup
    $primaryTrigger = $null
    foreach ($t in $ManifestTask.triggers) {
        if ($t.type -eq "Simple") {
            $primaryTrigger = $t
            break
        }
    }
    if (-not $primaryTrigger) {
        foreach ($t in $ManifestTask.triggers) {
            if ($t.type -eq "AtStartup") {
                $primaryTrigger = $t
                break
            }
        }
    }

    if (-not $primaryTrigger) {
        throw "Manifest task '$taskName' has no supported triggers (Simple/AtStartup)."
    }

    $scheduleType = $null
    $modifier = $null

    switch ($primaryTrigger.type) {
        "Simple" {
            $minutes = [int]($primaryTrigger.repeat_minutes)
            if ($minutes -le 0) {
                throw "Manifest task '$taskName' Simple trigger has invalid repeat_minutes: $minutes"
            }

            # Map minutes => MINUTE / HOURLY / DAILY / WEEKLY
            if ($minutes -lt 60) {
                # e.g. 10m
                $scheduleType = "MINUTE"
                $modifier = $minutes
            }
            elseif ($minutes -lt 1440) {
                # e.g. 60m => hourly
                $scheduleType = "HOURLY"
                $modifier = [math]::Max(1, [int]([math]::Round($minutes / 60.0)))
            }
            elseif ($minutes -lt 10080) {
                # e.g. 1440m => daily
                $scheduleType = "DAILY"
                $modifier = [math]::Max(1, [int]([math]::Round($minutes / 1440.0)))
            }
            else {
                # >= 7 days => weekly
                $scheduleType = "WEEKLY"
                $modifier = [math]::Max(1, [int]([math]::Round($minutes / 10080.0)))
            }
        }
        "AtStartup" {
            $scheduleType = "ONSTART"
        }
        default {
            throw "Unsupported trigger type '$($primaryTrigger.type)' for task '$taskName'."
        }
    }

    # Build the command that Windows will run (hidden window)
    $taskAction = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

    # Delete existing task if present
    & schtasks.exe /Delete /TN $taskName /F 2>$null | Out-Null

    # Wrap the taskAction in quotes so schtasks treats it as a single /TR value
    $taskActionQuoted = "`"$taskAction`""

    $argsList = @(
        "/Create",
        "/TN", $taskName,
        "/TR", $taskActionQuoted,
        "/F",
        "/RU", $env:USERNAME,
        "/SC", $scheduleType
    )

    if ($modifier -and $scheduleType -ne "ONSTART") {
        $argsList += @("/MO", $modifier)
    }

    $proc = Start-Process -FilePath "schtasks.exe" -ArgumentList $argsList -NoNewWindow -PassThru -Wait
    if ($proc.ExitCode -ne 0) {
        throw "schtasks.exe failed for task '$taskName' with exit code $($proc.ExitCode). Args: $($argsList -join ' ')"
    }

    return @{
        name       = $taskName
        scriptPath = $scriptPath
        action     = "created_or_replaced"
        schedule   = @{
            type     = $scheduleType
            modifier = $modifier
        }
    }
}

# ---------- 1) Ensure manifest tasks exist / are correct ----------
foreach ($mt in $manifest.tasks) {
    $taskName = $mt.id
    if (-not $taskName) { continue }

    $inventoryEntry = $null
    if ($inventoryByName.ContainsKey($taskName)) {
        $inventoryEntry = $inventoryByName[$taskName]
    }

    $needsCreateOrUpdate = $false
    $reason = ""

    if (-not $inventoryEntry) {
        $needsCreateOrUpdate = $true
        $reason = "missing"
    } else {
        # Compare expected script path
        $scriptRel = $mt.script_rel_path
        $expectedScriptPath = if ($scriptRel) { [IO.Path]::GetFullPath((Join-Path $MasonRoot $scriptRel)) } else { $null }
        $currentScriptPaths = @()
        if ($inventoryEntry.script_paths) {
            $currentScriptPaths = @($inventoryEntry.script_paths)
        }

        if ($expectedScriptPath -and $currentScriptPaths.Count -gt 0) {
            $match = $false
            foreach ($sp in $currentScriptPaths) {
                if ([IO.Path]::GetFullPath($sp).Equals($expectedScriptPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                    $match = $true
                    break
                }
            }
            if (-not $match) {
                $needsCreateOrUpdate = $true
                $reason = "script_mismatch"
            } else {
                $reason = "ok"
            }
        } else {
            $reason = "ok"
        }
    }

    $actionRecord = @{
        name    = $taskName
        reason  = if ($reason) { $reason } else { "ok" }
        allowed = $false
        action  = "none"
    }

    if ($needsCreateOrUpdate -and $policy.mode -eq "auto-fix-safe" -and $policy.allow_task_creation) {
        try {
            $created = New-MasonScheduledTask -ManifestTask $mt
            $actionRecord.allowed    = $true
            $actionRecord.action     = $created.action
            $actionRecord.scriptPath = $created.scriptPath
            $actionRecord.schedule   = $created.schedule
        } catch {
            $actionRecord.error = $_.Exception.Message
        }
    }

    $actionsTaken += $actionRecord
}

# ---------- 2) Quarantine legacy/unknown Mason tasks (future tightening) ----------
$legacyToQuarantine = @()

if ($inventory.tasks) {
    foreach ($task in $inventory.tasks) {
        if ($task.classification -ne "mason_legacy") { continue }

        $taskName = $task.name
        $shouldQuarantine = $false
        $reason = "legacy_mason_task"

        $legacyPatterns = @()
        if ($policy.quarantine_legacy_paths_contains) {
            $legacyPatterns = @($policy.quarantine_legacy_paths_contains)
        }

        $scriptPaths = @()
        if ($task.script_paths) { $scriptPaths = @($task.script_paths) }

        foreach ($sp in $scriptPaths) {
            foreach ($pat in $legacyPatterns) {
                if ($sp -like "*$pat*") {
                    $shouldQuarantine = $true
                    $reason = "legacy_path_match"
                    break
                }
            }
            if ($shouldQuarantine) { break }
        }

        if (-not $shouldQuarantine -and $policy.quarantine_unknown_mason_tasks) {
            $shouldQuarantine = $true
            $reason = "unknown_mason_task"
        }

        if ($shouldQuarantine) {
            $legacyToQuarantine += @{
                name            = $taskName
                path            = $task.path
                script_paths    = $scriptPaths
                reason          = $reason
                previouslyState = $task.state
            }

            $actionRecord = @{
                name    = $taskName
                reason  = $reason
                allowed = $false
                action  = "none"
            }

            if ($policy.mode -in @("auto-fix-safe","auto-fix-aggressive") -and $policy.allow_task_disable) {
                try {
                    Disable-ScheduledTask -TaskName $taskName -ErrorAction Stop | Out-Null
                    $actionRecord.allowed = $true
                    $actionRecord.action  = "disabled"
                } catch {
                    $actionRecord.error = $_.Exception.Message
                }
            }

            $actionsTaken += $actionRecord
        }
    }
}

if ($legacyToQuarantine.Count -gt 0) {
    $existingQuarantine = @()
    if (Test-Path $QuarantineTasks) {
        try {
            $existingQuarantine = Get-Content -Path $QuarantineTasks -Raw | ConvertFrom-Json
        } catch {
            $existingQuarantine = @()
        }
    }

    $newQuarantine = @()
    $newQuarantine += $existingQuarantine
    $newQuarantine += $legacyToQuarantine

    $newQuarantine | ConvertTo-Json -Depth 6 | Out-File -FilePath $QuarantineTasks -Encoding UTF8
}

$summary = @{
    generated_at      = (Get-Date).ToString("o")
    mason_root        = $MasonRootNormalized
    policy_mode       = $policy.mode
    actions           = $actionsTaken
    quarantined_count = $legacyToQuarantine.Count
}

$summary | ConvertTo-Json -Depth 6 | Out-File -FilePath $SummaryPath -Encoding UTF8

Write-Output "Task governor summary written to $SummaryPath"
