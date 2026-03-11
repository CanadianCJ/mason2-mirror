[CmdletBinding()]
param()

# Mason_Log_Digest.ps1
# Summarise last-day stability signals into a human-readable digest.

$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$baseDir   = Split-Path $scriptDir -Parent
$logDir    = Join-Path $baseDir "logs"

$summaryPath = Join-Path $logDir "stability_daily_summary.txt"

function Get-JsonLinesSafe($path) {
    if (-not (Test-Path $path)) { return @() }
    $lines = Get-Content $path -ErrorAction SilentlyContinue
    $result = @()
    foreach ($line in $lines) {
        $trim = $line.Trim()
        if ($trim.StartsWith("{") -and $trim.EndsWith("}")) {
            try {
                $obj = $trim | ConvertFrom-Json
                $result += $obj
            }
            catch {
                # ignore bad JSON lines
            }
        }
    }
    return $result
}

$now = Get-Date
$cutoff = $now.AddDays(-1)

$pcMetrics = Get-JsonLinesSafe (Join-Path $logDir "pc_resource_watch.log") |
    Where-Object { $_.timestamp -and ([datetime]$_.timestamp) -ge $cutoff }

$pcAlerts  = Get-JsonLinesSafe (Join-Path $logDir "pc_alerts.log") |
    Where-Object { $_.timestamp -and ([datetime]$_.timestamp) -ge $cutoff }

$athenaAllLines = @()
if (Test-Path (Join-Path $logDir "athena_status.log")) {
    $athenaAllLines = Get-Content (Join-Path $logDir "athena_status.log") -ErrorAction SilentlyContinue
}

$athenaJson = @()
$athenaErrors = 0
foreach ($line in $athenaAllLines) {
    $trim = $line.Trim()
    if ($trim.StartsWith("{") -and $trim.EndsWith("}")) {
        try {
            $obj = $trim | ConvertFrom-Json
            if ($obj.timestamp -and ([datetime]$obj.timestamp) -ge $cutoff) {
                $athenaJson += $obj
            }
        }
        catch { }
    } elseif ($trim -like "*[ERROR]*") {
        $athenaErrors++
    }
}

$autoLogLines = @()
if (Test-Path (Join-Path $logDir "stability_auto_applied.log")) {
    $autoLogLines = Get-Content (Join-Path $logDir "stability_auto_applied.log") -ErrorAction SilentlyContinue
}

$autoTasksLastDay = $autoLogLines | Where-Object {
    $_ -match '^\[(?<ts>[\d\-:\s]+)\]' -and ([datetime]($matches['ts'])) -ge $cutoff
}

$ramAlerts = ($pcMetrics | Where-Object { $_.status -eq "ALERT" }).Count
$totalPcSamples = $pcMetrics.Count
$latestPc = $pcMetrics | Sort-Object { [datetime]$_.timestamp } -Descending | Select-Object -First 1
$latestAthena = $athenaJson | Sort-Object { [datetime]$_.timestamp } -Descending | Select-Object -First 1

$linesOut = @()
$linesOut += "===== Mason2 Stability Summary ====="
$linesOut += "Generated: $($now.ToString("yyyy-MM-dd HH:mm:ss"))"
$linesOut += ""

$linesOut += "--- PC RAM / CPU ---"
$linesOut += "Samples (last 24h): $totalPcSamples"
$linesOut += "Alert/Warn samples : $ramAlerts"
if ($latestPc) {
    $linesOut += ("Latest: {0} | CPU={1:N1}% | RAM={2:N1}% (free {3:N1} GB) | status={4}" -f `
        $latestPc.timestamp, $latestPc.cpu_pct, $latestPc.mem_used_pct, $latestPc.mem_free_gb, $latestPc.status)
}
$linesOut += ""

$linesOut += "--- Athena / Onyx ---"
$linesOut += "Athena error lines (all time): $athenaErrors"
if ($latestAthena) {
    $linesOut += ("Latest Athena snapshot: {0} | ok={1} | onyx.last_status={2}" -f `
        $latestAthena.timestamp, $latestAthena.ok, $latestAthena.onyx.last_status)
}
$linesOut += ""

$linesOut += "--- Auto-Applied Tasks ---"
$linesOut += ("Auto-apply log entries (last 24h): {0}" -f $autoTasksLastDay.Count)

$linesOut += ""
$linesOut += "===== End Summary ====="
$linesOut += ""

$summaryDir = Split-Path $summaryPath -Parent
if (-not (Test-Path $summaryDir)) {
    New-Item -ItemType Directory -Path $summaryDir | Out-Null
}

$linesOut | Out-File -FilePath $summaryPath -Encoding UTF8 -Append
