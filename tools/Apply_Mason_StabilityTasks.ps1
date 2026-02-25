param()

$ErrorActionPreference = "Stop"

# Base paths
$toolsPath     = $PSScriptRoot
$basePath      = Split-Path $toolsPath -Parent
$logsPath      = Join-Path $basePath "logs"
$reportsPath   = Join-Path $basePath "reports"
$queuePending  = Join-Path $basePath "queue\pending"
$queueApplied  = Join-Path $basePath "queue\applied"

# Ensure folders exist
@($logsPath, $reportsPath, $queuePending, $queueApplied) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -ErrorAction SilentlyContinue | Out-Null
    }
}

$applyLog = Join-Path $logsPath "stability_auto_applied.log"

function Write-ApplyLog {
    param(
        [string]$Level,
        [string]$TaskId,
        [string]$Message
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $applyLog -Value "[$ts][$Level][$TaskId] $Message"
}

Write-ApplyLog "INFO" "-" "Apply_Mason_StabilityTasks.ps1 started."

# -------------------------------------------------------
# Helper: run a tools\*.ps1 script for a given task
# -------------------------------------------------------
function Invoke-ToolScript {
    param(
        [string]$TaskId,
        [string]$ScriptName
    )

    $scriptPath = Join-Path $toolsPath $ScriptName

    if (-not (Test-Path $scriptPath)) {
        Write-ApplyLog "ERROR" $TaskId ("Script not found: " + $scriptPath)
        return $false
    }

    try {
        & $scriptPath
        Write-ApplyLog "INFO" $TaskId ("Script ran successfully: " + $scriptPath)
        return $true
    }
    catch {
        Write-ApplyLog "ERROR" $TaskId ("Script failed: " + $_.Exception.Message)
        return $false
    }
}

# -------------------------------------------------------
# Helper: special handler for m2-test-touch-file-001
# -------------------------------------------------------
function Invoke-TestTouchFile {
    param(
        [string]$TaskId
    )

    try {
        $markerPath = Join-Path $logsPath "mason_test_touch_marker.txt"
        $ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        Add-Content -Path $markerPath -Value "[$ts] Test task $TaskId touched this file."
        Write-ApplyLog "INFO" $TaskId ("Wrote test marker to " + $markerPath)
        return $true
    }
    catch {
        Write-ApplyLog "ERROR" $TaskId ("Failed to write test marker: " + $_.Exception.Message)
        return $false
    }
}

# -------------------------------------------------------
# Helper: PC high-RAM analysis handler (medium risk, experiment mode)
# -------------------------------------------------------
function Invoke-PcHighRamAnalysis {
    param(
        $Task,
        [string]$TaskId
    )

    try {
        $alertsLog    = $null
        $sampleAlerts = $null

        if ($Task.payload) {
            if ($Task.payload.alerts_log_path) {
                $alertsLog = $Task.payload.alerts_log_path
            }
            if ($Task.payload.sample_alerts) {
                $sampleAlerts = $Task.payload.sample_alerts
            }
        }

        # Capture current top RAM processes
        $processes = Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 15

        $procSummaries = @()
        foreach ($p in $processes) {
            $obj = [ordered]@{
                ProcessName   = $p.ProcessName
                Id            = $p.Id
                WorkingSetMB  = [math]::Round($p.WorkingSet64 / 1MB, 2)
                PagedMemoryMB = [math]::Round($p.PagedMemorySize64 / 1MB, 2)
                CPU           = $p.CPU
            }
            $procSummaries += New-Object psobject -Property $obj
        }

        $alertCount = 0
        if ($sampleAlerts) {
            $alertCount = $sampleAlerts.Count
        }

        $analysis = [ordered]@{
            generated_at         = (Get-Date).ToUniversalTime().ToString("o")
            alerts_log_path      = $alertsLog
            high_ram_alerts_seen = $alertCount
            sample_alerts        = $sampleAlerts
            top_processes        = $procSummaries
            notes                = @(
                "This is a read-only analysis experiment.",
                "Future automation could: warn about specific processes, suggest closing them, or move heavy work to off-peak hours."
            )
        }

        $json    = $analysis | ConvertTo-Json -Depth 6
        $outPath = Join-Path $reportsPath "pc_high_ram_analysis.json"
        $json | Out-File -FilePath $outPath -Encoding UTF8

        Write-ApplyLog "INFO" $TaskId ("Wrote PC high RAM analysis to " + $outPath)
        return $true
    }
    catch {
        Write-ApplyLog "ERROR" $TaskId ("Failed PC high RAM analysis: " + $_.Exception.Message)
        return $false
    }
}

# -------------------------------------------------------
# Helper: Onyx health investigation handler (medium risk, experiment mode)
# -------------------------------------------------------
function Invoke-OnyxHealthInvestigate {
    param(
        $Task,
        [string]$TaskId
    )

    try {
        $summaryPath = $null

        if ($Task.payload -and $Task.payload.onyx_health_summary_path) {
            $summaryPath = $Task.payload.onyx_health_summary_path
        } else {
            $summaryPath = Join-Path $reportsPath "onyx_health_summary.json"
        }

        $summary = $null
        if (Test-Path $summaryPath) {
            try {
                $raw     = Get-Content $summaryPath -Raw
                $summary = $raw | ConvertFrom-Json
            }
            catch {
                Write-ApplyLog "ERROR" $TaskId ("Failed to parse Onyx health summary JSON: " + $_.Exception.Message)
            }
        }

        $onyxHealthLog = Join-Path $logsPath "onyx_health.log"
        $recentLines   = @()
        $errorSamples  = @()

        if (Test-Path $onyxHealthLog) {
            $recentLines = Get-Content $onyxHealthLog -Tail 200
            $errorSamples = $recentLines | Where-Object {
                $_ -match "ERROR" -or $_ -match "Exception" -or $_ -match "timeout" -or $_ -match "5\d\d"
            } | Select-Object -First 20
        }

        $opinion      = $null
        $totalChecks  = $null
        $errorCount   = $null
        $warnCount    = $null
        $avgElapsedMs = $null

        if ($summary) {
            $opinion      = $summary.healthOpinion
            $totalChecks  = $summary.totalChecks
            $errorCount   = $summary.errorCount
            $warnCount    = $summary.warnCount
            $avgElapsedMs = $summary.avgElapsedMs
        }

        $investigation = [ordered]@{
            generated_at         = (Get-Date).ToUniversalTime().ToString("o")
            summary_path         = $summaryPath
            healthOpinion        = $opinion
            totalChecks          = $totalChecks
            errorCount           = $errorCount
            warnCount            = $warnCount
            avgElapsedMs         = $avgElapsedMs
            recent_error_samples = $errorSamples
            notes                = @(
                "Read-only investigation experiment. No config changes.",
                "Next steps could include: checking Onyx backend logs, database latency, and network conditions.",
                "Future automated tasks may add targeted retries, timeouts, or canary restarts based on these findings."
            )
        }

        $json    = $investigation | ConvertTo-Json -Depth 6
        $outPath = Join-Path $reportsPath "onyx_health_investigation.json"
        $json | Out-File -FilePath $outPath -Encoding UTF8

        Write-ApplyLog "INFO" $TaskId ("Wrote Onyx health investigation report to " + $outPath)
        return $true
    }
    catch {
        Write-ApplyLog "ERROR" $TaskId ("Failed Onyx health investigation: " + $_.Exception.Message)
        return $false
    }
}

# -------------------------------------------------------
# Process pending tasks
# -------------------------------------------------------
$pendingFiles = Get-ChildItem $queuePending -Filter "*.json" -ErrorAction SilentlyContinue

if (-not $pendingFiles) {
    Write-ApplyLog "INFO" "-" "No pending task JSON files found."
    Write-ApplyLog "INFO" "-" "Apply_Mason_StabilityTasks.ps1 finished."
    return
}

foreach ($file in $pendingFiles) {
    $fullPath = $file.FullName

    $task = $null
    try {
        $raw  = Get-Content $fullPath -Raw
        $task = $raw | ConvertFrom-Json
    }
    catch {
        Write-ApplyLog "ERROR" "-" ("Failed to parse task JSON: " + $fullPath + " : " + $_.Exception.Message)
        continue
    }

    $taskId = $task.id
    if (-not $taskId) {
        Write-ApplyLog "ERROR" "-" ("Task file missing id: " + $fullPath)
        continue
    }

    if (-not $task.auto_apply) {
        Write-ApplyLog "INFO" $taskId "Skipped (auto_apply != true); leaving for manual review."
        continue
    }

    Write-ApplyLog "INFO" $taskId ("Processing auto-apply task from " + $file.Name)

    $handled = $false

    switch ($taskId) {
        # Existing low-risk tasks
        "pc-memory-hygiene-001" {
            $handled = Invoke-ToolScript -TaskId $taskId -ScriptName "PC_Memory_Hygiene.ps1"
        }
        "pc-gentle-temp-clean-001" {
            $handled = Invoke-ToolScript -TaskId $taskId -ScriptName "PC_Gentle_Temp_Clean.ps1"
        }
        "m2-log-digest-001" {
            $handled = Invoke-ToolScript -TaskId $taskId -ScriptName "Mason_Log_Digest.ps1"
        }
        "m2-log-rotation-001" {
            $handled = Invoke-ToolScript -TaskId $taskId -ScriptName "Mason_Log_Rotation.ps1"
        }
        "m2-task-health-audit-001" {
            $handled = Invoke-ToolScript -TaskId $taskId -ScriptName "Mason_Task_Health_Audit.ps1"
        }
        "m2-disk-trend-watch-001" {
            $handled = Invoke-ToolScript -TaskId $taskId -ScriptName "Mason_Disk_Trend_Watch.ps1"
        }
        "m2-test-touch-file-001" {
            $handled = Invoke-TestTouchFile -TaskId $taskId
        }

        # New medium-risk experiment tasks (PC + Onyx)
        "pc-high-ram-analysis-001" {
            $handled = Invoke-PcHighRamAnalysis -Task $task -TaskId $taskId
        }
        "onyx-health-investigate-001" {
            $handled = Invoke-OnyxHealthInvestigate -Task $task -TaskId $taskId
        }

        Default {
            Write-ApplyLog "INFO" $taskId "No handler defined for this task id; leaving in pending."
            $handled = $false
        }
    }

    if ($handled) {
        try {
            $destPath = Join-Path $queueApplied $file.Name
            Move-Item -Path $fullPath -Destination $destPath -Force
            Write-ApplyLog "INFO" $taskId ("Task completed and moved to applied: " + $destPath)
        }
        catch {
            Write-ApplyLog "ERROR" $taskId ("Task handler succeeded, but failed to move JSON to applied: " + $_.Exception.Message)
        }
    }
}

Write-ApplyLog "INFO" "-" "Apply_Mason_StabilityTasks.ps1 finished."
