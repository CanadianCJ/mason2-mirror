# Mason_Forensics_Inventory.ps1
# Scans Mason2\forensics and Mason2\dumps for heavy files.
# NO DELETES. Writes a JSON report under reports\mason_forensics_inventory.json

$ErrorActionPreference = "Stop"

$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root     = Split-Path -Parent $toolsDir

$forensicsDir = Join-Path $root "forensics"
$dumpsDir     = Join-Path $root "dumps"
$reportsDir   = Join-Path $root "reports"

if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir | Out-Null
}

$reportPath = Join-Path $reportsDir "mason_forensics_inventory.json"

function Scan-Dir {
    param(
        [string]$path,
        [string]$label
    )

    if (-not (Test-Path $path)) {
        return [ordered]@{
            label         = $label
            path          = $path
            exists        = $false
            total_size_gb = 0
            file_count    = 0
            top_files     = @()
        }
    }

    $files = Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue

    $totalBytes = ($files | Measure-Object Length -Sum).Sum
    if (-not $totalBytes) { $totalBytes = 0 }

    # Top 50 largest files
    $top = $files |
        Sort-Object Length -Descending |
        Select-Object -First 50 |
        ForEach-Object {
            [ordered]@{
                name        = $_.Name
                full_path   = $_.FullName
                size_mb     = [math]::Round($_.Length / 1MB, 2)
                last_write  = $_.LastWriteTime.ToString("o")
                extension   = $_.Extension
            }
        }

    return [ordered]@{
        label         = $label
        path          = $path
        exists        = $true
        total_size_gb = [math]::Round($totalBytes / 1GB, 3)
        file_count    = $files.Count
        top_files     = $top
    }
}

$forensicsInfo = Scan-Dir -path $forensicsDir -label "mason_forensics"
$dumpsInfo     = Scan-Dir -path $dumpsDir     -label "mason_dumps"

$summary = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    root         = $root
    entries      = @($forensicsInfo, $dumpsInfo)
}

$summary | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Encoding UTF8

Write-Host "Mason forensics inventory written to $reportPath"
