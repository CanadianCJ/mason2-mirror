[CmdletBinding()]
param()

# Mason_Log_Rotation.ps1
# Move old logs into logs\archive to keep things tidy.

$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$baseDir   = Split-Path $scriptDir -Parent
$logDir    = Join-Path $baseDir "logs"
$archiveDir = Join-Path $logDir "archive"

if (-not (Test-Path $archiveDir)) {
    New-Item -ItemType Directory -Path $archiveDir | Out-Null
}

$now = Get-Date
$maxAgeDays = 7

Get-ChildItem $logDir -File -Filter "*.log" -ErrorAction SilentlyContinue | ForEach-Object {
    $ageDays = ($now - $_.LastWriteTime).TotalDays
    if ($ageDays -gt $maxAgeDays) {
        $stamp = $_.LastWriteTime.ToString("yyyyMMddHHmmss")
        $destName = "{0}.{1}.old" -f $_.Name, $stamp
        $destPath = Join-Path $archiveDir $destName
        try {
            Move-Item -Path $_.FullName -Destination $destPath -Force
        } catch { }
    }
}
