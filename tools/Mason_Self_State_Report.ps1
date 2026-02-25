param()

$ErrorActionPreference = "Stop"

$basePath      = "C:\Users\Chris\Desktop\Mason2"
$reportsFolder = Join-Path $basePath "reports"
$logsFolder    = Join-Path $basePath "logs"

$inputPath  = Join-Path $reportsFolder "mason_self_review.json"
$outputPath = Join-Path $reportsFolder "mason_self_state.json"
$logPath    = Join-Path $logsFolder "mason_self_state.log"

if (-not (Test-Path $logsFolder)) {
    New-Item -ItemType Directory -Path $logsFolder -ErrorAction SilentlyContinue | Out-Null
}

function Write-Log {
    param(
        [string]$Message
    )
    $ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    Add-Content -Path $logPath -Value "[$ts] $Message"
}

Write-Log "=== Mason_Self_State_Report started ==="

if (-not (Test-Path $inputPath)) {
    Write-Log "Self-review file not found at $inputPath. Exiting."
    exit 0
}

try {
    $reviewJson = Get-Content -Path $inputPath -Raw
    $review     = $reviewJson | ConvertFrom-Json
}
catch {
    Write-Log "Failed to parse self-review json: $_"
    exit 1
}

$nowUtc      = [DateTime]::UtcNow
$cutoffHours = 48
$cutoffUtc   = $nowUtc.AddHours(-$cutoffHours)

$totalApplied   = 0
$byArea         = @{}
$lastAppliedUtc = $null

if ($review.stability_history) {
    $totalApplied = [int]$review.stability_history.totalAppliedTasks

    if ($review.stability_history.byAreaAndRisk) {
        foreach ($areaProp in $review.stability_history.byAreaAndRisk.PSObject.Properties) {
            $areaName  = $areaProp.Name
            $areaValue = $areaProp.Value
            $areaTotal = 0

            foreach ($riskProp in $areaValue.PSObject.Properties) {
                $areaTotal += [int]$riskProp.Value
            }

            $byArea[$areaName] = $areaTotal
        }
    }

    if ($review.stability_history.latestTasks) {
        foreach ($t in $review.stability_history.latestTasks) {
            if ($t.applied_at) {
                $taskUtc = $null

                try {
                    # Try DateTimeOffset (handles offsets like -05:00)
                    $dto = [DateTimeOffset]$t.applied_at
                    $taskUtc = $dto.UtcDateTime
                }
                catch {
                    try {
                        # Fallback to DateTime then convert to UTC
                        $dt = [DateTime]::Parse($t.applied_at)
                        $taskUtc = $dt.ToUniversalTime()
                    }
                    catch {
                        Write-Log "Could not parse applied_at '$($t.applied_at)' for task $($t.id)"
                        continue
                    }
                }

                if (-not $lastAppliedUtc -or $taskUtc -gt $lastAppliedUtc) {
                    $lastAppliedUtc = $taskUtc
                }
            }
        }
    }
}

$hasRecentAutoApply = $false
if ($lastAppliedUtc) {
    if ($lastAppliedUtc -gt $cutoffUtc) {
        $hasRecentAutoApply = $true
    }
}

$state = [PSCustomObject]@{
    generated_at_utc         = $nowUtc.ToString("o")
    source_self_review_utc   = $review.generated_at
    has_ever_auto_applied    = ($totalApplied -gt 0)
    total_auto_applied_tasks = $totalApplied
    auto_applied_by_area     = $byArea
    last_auto_apply_utc      = $(if ($lastAppliedUtc) { $lastAppliedUtc.ToString("o") } else { $null })
    recent_window_hours      = $cutoffHours
    has_recent_auto_apply    = $hasRecentAutoApply
    onyx_health_opinion      = $(if ($review.onyx_health) { $review.onyx_health.healthOpinion } else { $null })
    onyx_error_count         = $(if ($review.onyx_health) { [int]$review.onyx_health.errorCount } else { $null })
    onyx_avg_elapsed_ms      = $(if ($review.onyx_health) { [int]$review.onyx_health.avgElapsedMs } else { $null })
    pc_high_ram_alerts_seen  = $(if ($review.pc_high_ram) { [int]$review.pc_high_ram.high_ram_alerts_seen } else { $null })
}

try {
    $stateJson = $state | ConvertTo-Json -Depth 6
    if (-not (Test-Path $reportsFolder)) {
        New-Item -ItemType Directory -Path $reportsFolder -ErrorAction SilentlyContinue | Out-Null
    }
    Set-Content -Path $outputPath -Value $stateJson -Encoding UTF8
    Write-Log "Wrote Mason self-state to $outputPath."
}
catch {
    Write-Log "Failed to write mason_self_state.json: $_"
    exit 1
}

Write-Log "=== Mason_Self_State_Report completed ==="
