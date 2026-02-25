$ErrorActionPreference = "SilentlyContinue"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$baseDir   = Split-Path -Parent $scriptDir

$logsDir    = Join-Path $baseDir "logs"
$reportsDir = Join-Path $baseDir "reports"

New-Item -ItemType Directory -Path $reportsDir -ErrorAction SilentlyContinue | Out-Null

$logsToScan = @(
    "stability_auto_applied.log",
    "pc_alerts.log",
    "athena_status.log"
)

$summary = @{
    generated_at = (Get-Date).ToString("s")
    sources      = @{}
}

foreach ($logName in $logsToScan) {
    $logPath = Join-Path $logsDir $logName
    if (-not (Test-Path $logPath)) { continue }

    $lines      = Get-Content $logPath -ErrorAction SilentlyContinue
    $errorLines = $lines | Where-Object { $_ -like "*[ERROR]*" }

    $summary.sources[$logName] = @{
        total_lines = $lines.Count
        error_lines = $errorLines.Count
    }
}

$outPath = Join-Path $reportsDir "m2_error_trends.json"
$summary | ConvertTo-Json -Depth 5 | Out-File $outPath -Encoding UTF8
