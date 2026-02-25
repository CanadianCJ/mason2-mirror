# PC_Resource_Monitor.ps1
# Logs overall CPU/RAM stats every run,
# and when status = "ALERT", also logs top RAM hogs into pc_alerts.log.

$ErrorActionPreference = "Stop"

$baseDir  = "C:\Users\Chris\Desktop\Mason2"
$logDir   = Join-Path $baseDir "logs"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$resourceLog = Join-Path $logDir "pc_resource_watch.log"
$alertsLog   = Join-Path $logDir "pc_alerts.log"

function Write-ResourceError {
    param(
        [string]$message
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[${ts}][ERROR][PC_Resource_Monitor] $message"
    Add-Content -Path $resourceLog -Value $line
}

try {
    # --- CPU ---
    $cpuSample = Get-Counter '\Processor(_Total)\% Processor Time'
    $cpuPct = [math]::Round($cpuSample.CounterSamples.CookedValue, 2)

    # --- RAM ---
    $os = Get-CimInstance Win32_OperatingSystem
    $totalBytes = [double]$os.TotalVisibleMemorySize * 1KB
    $freeBytes  = [double]$os.FreePhysicalMemory * 1KB

    if ($totalBytes -le 0) {
        throw "TotalVisibleMemorySize was zero or negative."
    }

    $usedBytes = $totalBytes - $freeBytes
    $memUsedPct = [math]::Round(($usedBytes / $totalBytes) * 100, 2)

    $memTotalGB = [math]::Round($totalBytes / 1GB, 2)
    $memFreeGB  = [math]::Round($freeBytes / 1GB, 2)

    # --- Status ---
    $status = "OK"
    if ($memUsedPct -ge 85 -or $cpuPct -ge 90) {
        $status = "ALERT"
    }

    $tsNow = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # --- Base JSON line (what you're already seeing) ---
    $entry = [ordered]@{
        timestamp    = $tsNow
        cpu_pct      = $cpuPct
        mem_used_pct = $memUsedPct
        mem_total_gb = $memTotalGB
        mem_free_gb  = $memFreeGB
        status       = $status
    }

    ($entry | ConvertTo-Json -Compress) | Add-Content -Path $resourceLog

    # --- Extra detail ONLY when in ALERT ---
    if ($status -eq "ALERT") {
        $topProcs = Get-Process |
            Sort-Object WorkingSet -Descending |
            Select-Object -First 5 `
                Name, Id, `
                @{Name="RAM_MB";Expression={[math]::Round($_.WorkingSet/1MB,1)}}

        $alertEntry = [ordered]@{
            timestamp    = $tsNow
            cpu_pct      = $cpuPct
            mem_used_pct = $memUsedPct
            mem_total_gb = $memTotalGB
            mem_free_gb  = $memFreeGB
            top_processes = $topProcs
        }

        ($alertEntry | ConvertTo-Json -Depth 4 -Compress) | Add-Content -Path $alertsLog
    }

}
catch {
    Write-ResourceError $_.Exception.Message
}
