[CmdletBinding()]
param()

# Mason_Disk_Trend_Watch.ps1
# Log disk free space over time for local fixed drives.

$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$baseDir   = Split-Path $scriptDir -Parent
$logDir    = Join-Path $baseDir "logs"

$logPath = Join-Path $logDir "disk_trend.log"
$timestamp = Get-Date

try {
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 3"
} catch {
    $disks = @()
}

foreach ($d in $disks) {
    if (-not $d.Size) { continue }
    $freePct = 0
    if ($d.Size -gt 0) {
        $freePct = [math]::Round(($d.FreeSpace / $d.Size) * 100, 2)
    }
    $obj = [pscustomobject]@{
        timestamp  = $timestamp.ToString("yyyy-MM-dd HH:mm:ss")
        drive      = $d.DeviceID
        size_gb    = [math]::Round($d.Size / 1GB, 2)
        free_gb    = [math]::Round($d.FreeSpace / 1GB, 2)
        free_pct   = $freePct
    }
    $obj | ConvertTo-Json -Compress | Out-File -FilePath $logPath -Encoding UTF8 -Append
}

