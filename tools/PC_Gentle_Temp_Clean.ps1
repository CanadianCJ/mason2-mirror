[CmdletBinding()]
param()

# PC_Gentle_Temp_Clean.ps1
# Very conservative temp-file cleanup in standard temp dirs.

$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$baseDir   = Split-Path $scriptDir -Parent
$logDir    = Join-Path $baseDir "logs"
$logPath   = Join-Path $logDir "pc_temp_cleanup.log"

$dirs = @()
if ($env:TEMP)         { $dirs += $env:TEMP }
$dirs += "C:\Windows\Temp"

$now = Get-Date
$minAgeDays = 7

$deletedCount = 0
$errors = 0

foreach ($dir in $dirs) {
    if (-not (Test-Path $dir)) { continue }
    try {
        Get-ChildItem $dir -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if (-not $_.PSIsContainer) {
                $ageDays = ($now - $_.LastWriteTime).TotalDays
                if ($ageDays -ge $minAgeDays) {
                    try {
                        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                        $deletedCount++
                    } catch { $errors++ }
                }
            }
        }
    } catch {
        $errors++
    }
}

$entry = "[{0}][INFO][PC_Gentle_Temp_Clean] Deleted approx {1} old temp files. Errors={2}" -f `
    $now.ToString("yyyy-MM-dd HH:mm:ss"), $deletedCount, $errors

$entry | Out-File -FilePath $logPath -Encoding UTF8 -Append
