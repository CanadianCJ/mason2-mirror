

# === Mason teacher patch patch-002 (plan teacher-mason-plan-003) ===
# Mason Resource Guard and Log Rotation Enhancements

# Function to check system resource usage
function Check-ResourceUsage {
    $cpuThreshold = 80 # percent
    $memoryThresholdMB = 500 # MB

    $cpuUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $mem = Get-CimInstance Win32_OperatingSystem
    $freeMemMB = $mem.FreePhysicalMemory / 1024

    if ($cpuUsage -gt $cpuThreshold) {
        Write-Output "[ResourceGuard] High CPU usage detected: $([math]::Round($cpuUsage,2))%"
        return $false
    }
    if ($freeMemMB -lt $memoryThresholdMB) {
        Write-Output "[ResourceGuard] Low available memory detected: $([math]::Round($freeMemMB,2)) MB"
        return $false
    }
    return $true
}

# Log rotation function
function Rotate-Logs {
    param(
        [string]$LogDir = "$PSScriptRoot\\logs",
        [int]$MaxLogSizeMB = 10,
        [int]$MaxLogAgeDays = 7
    )

    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir | Out-Null
    }

    Get-ChildItem -Path $LogDir -Filter '*.log' | ForEach-Object {
        $file = $_
        $sizeMB = $file.Length / 1MB
        $ageDays = (Get-Date) - $file.LastWriteTime

        if ($sizeMB -gt $MaxLogSizeMB -or $ageDays.Days -gt $MaxLogAgeDays) {
            $archiveName = "$($file.BaseName)_$((Get-Date).ToString('yyyyMMddHHmmss')).log"
            $archivePath = Join-Path $LogDir 'archive'
            if (-not (Test-Path $archivePath)) {
                New-Item -ItemType Directory -Path $archivePath | Out-Null
            }
            Move-Item -Path $file.FullName -Destination (Join-Path $archivePath $archiveName)
            Write-Output "[LogRotation] Archived log file: $($file.Name)"
        }
    }
}

# Example usage:
# if (Check-ResourceUsage) { Write-Output "Resources OK" } else { Write-Output "Resource limits exceeded" }
# Rotate-Logs

# === end Mason teacher patch patch-002 ===

