# Mason_Forensics_Cleanup.ps1
# Auto-cleans Mason2\forensics and Mason2\dumps of OLD files only.
# - Keeps the most recent $maxKeep files in each directory
# - Deletes older ones
# - Logs actions to logs\mason_cleanup.log
# - Writes a summary JSON to reports\mason_forensics_cleanup_summary.json

$ErrorActionPreference = "Stop"

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root     = Split-Path -Parent $toolsDir

$forensicsDir = Join-Path $root "forensics"
$dumpsDir     = Join-Path $root "dumps"
$logsDir      = Join-Path $root "logs"
$reportsDir   = Join-Path $root "reports"

foreach ($d in @($logsDir, $reportsDir)) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d | Out-Null
    }
}

$logPath    = Join-Path $logsDir "mason_cleanup.log"
$reportPath = Join-Path $reportsDir "mason_forensics_cleanup_summary.json"

# Keep this many most-recent files in each folder
$maxKeep = 200

function Write-CleanupLog {
    param(
        [string]$label,
        [string]$message,
        [string]$level = "INFO"
    )

    $ts   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}][{1}][{2}] {3}" -f $ts, $level, $label, $message
    Add-Content -Path $logPath -Value $line
}

function Cleanup-Dir {
    param(
        [string]$path,
        [string]$label
    )

    $result = [ordered]@{
        label              = $label
        path               = $path
        exists             = $false
        total_before_gb    = 0.0
        total_after_gb     = 0.0
        deleted_file_count = 0
        deleted_bytes      = 0
        kept_file_count    = 0
        kept_bytes         = 0
        max_keep           = $maxKeep
    }

    if (-not (Test-Path $path)) {
        Write-CleanupLog $label "Path does not exist, nothing to do: $path"
        return $result
    }

    $result.exists = $true

    $files = Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue
    if (-not $files -or $files.Count -eq 0) {
        Write-CleanupLog $label "No files found under $path"
        return $result
    }

    $totalBeforeBytes = ($files | Measure-Object Length -Sum).Sum
    if (-not $totalBeforeBytes) { $totalBeforeBytes = 0 }

    # Sort newest first
    $sorted = $files | Sort-Object LastWriteTime -Descending

    $keep   = $sorted | Select-Object -First $maxKeep
    $delete = $sorted | Select-Object -Skip  $maxKeep

    $result.kept_file_count = $keep.Count
    $result.kept_bytes      = ($keep | Measure-Object Length -Sum).Sum

    $deletedBytes = 0
    $deletedCount = 0

    foreach ($f in $delete) {
        try {
            $size = $f.Length
            Remove-Item -Path $f.FullName -Force -ErrorAction Stop
            $deletedCount += 1
            $deletedBytes += $size
        }
        catch {
            Write-CleanupLog $label "Failed to delete $($f.FullName): $_" "ERROR"
        }
    }

    $result.deleted_file_count = $deletedCount
    $result.deleted_bytes      = $deletedBytes

    # Recalculate after
    $remaining = Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue
    $totalAfterBytes = ($remaining | Measure-Object Length -Sum).Sum
    if (-not $totalAfterBytes) { $totalAfterBytes = 0 }

    $result.total_before_gb = [math]::Round($totalBeforeBytes / 1GB, 3)
    $result.total_after_gb  = [math]::Round($totalAfterBytes  / 1GB, 3)

    Write-CleanupLog $label (
        "Cleanup complete. Deleted {0} files (~{1:N2} GB), kept {2} newest files. Before={3:N3} GB, After={4:N3} GB." -f `
        $deletedCount,
        ($deletedBytes / 1GB),
        $result.kept_file_count,
        $result.total_before_gb,
        $result.total_after_gb
    )

    return $result
}

$forensicsResult = Cleanup-Dir -path $forensicsDir -label "forensics"
$dumpsResult     = Cleanup-Dir -path $dumpsDir     -label "dumps"

$summary = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    root         = $root
    max_keep     = $maxKeep
    entries      = @($forensicsResult, $dumpsResult)
}

$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Encoding UTF8

Write-Host "Mason forensics cleanup summary written to $reportPath"
