# PC_Memory_Hygiene.ps1
# Safe memory hygiene: clean old temp/log files and log RAM hotspots.
$ErrorActionPreference = "Stop"

# Mason2 root and logs
$rootDir = Split-Path $PSScriptRoot -Parent
$logDir  = Join-Path $rootDir "logs"

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$alertsLog = Join-Path $logDir "pc_alerts.log"

function Write-Alert {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts][$Level][PC_Memory_Hygiene] $Message"
    Add-Content -Path $alertsLog -Value $line
}

try {
    # 1) Read current RAM usage
    $os = Get-CimInstance Win32_OperatingSystem
    $totalMB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeMB  = [math]::Round($os.FreePhysicalMemory    / 1MB, 2)
    if ($totalMB -le 0) { throw "Total memory is zero or invalid." }

    $usedPct = [math]::Round((($totalMB - $freeMB) / $totalMB) * 100, 2)

    # 2) Clean safe temp directories (older than 7 days)
    $tempPaths = @(
        [IO.Path]::GetTempPath(),
        "$env:USERPROFILE\AppData\Local\Temp"
    ) | Select-Object -Unique

    $tempCutoff = (Get-Date).AddDays(-7)
    $deletedCount = 0

    foreach ($p in $tempPaths) {
        if (-not (Test-Path $p)) { continue }

        Get-ChildItem $p -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $tempCutoff } |
            ForEach-Object {
                try {
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                    $script:deletedCount++
                } catch {
                    # ignore individual file errors
                }
            }
    }

    # 3) Trim very old Mason2 logs (older than 30 days)
    $logCutoff = (Get-Date).AddDays(-30)

    if (Test-Path $logDir) {
        Get-ChildItem $logDir -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $logCutoff } |
            ForEach-Object {
                try {
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                } catch {
                }
            }
    }

    # 4) If high RAM, log top 10 RAM-heavy processes
    if ($usedPct -gt 80) {
        $topProcs = Get-Process |
            Sort-Object WorkingSet -Descending |
            Select-Object -First 10 `
                Name, Id, @{Name="RAM_MB";Expression={[math]::Round($_.WorkingSet/1MB,1)}}

        Write-Alert "High RAM usage detected: $usedPct% used ($([math]::Round($totalMB - $freeMB,1)) MB). Top 10 processes:"

        foreach ($p in $topProcs) {
            Write-Alert ("  {0} (PID {1}) - {2} MB" -f $p.Name, $p.Id, $p.RAM_MB)
        }
    }
    else {
        Write-Alert "Memory hygiene run complete. RAM used: $usedPct%. Deleted ~${deletedCount} old temp/log files."
    }

    exit 0
}
catch {
    Write-Alert "Error in PC_Memory_Hygiene.ps1: $_" "ERROR"
    exit 1
}
