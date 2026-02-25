$ErrorActionPreference = "SilentlyContinue"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$baseDir   = Split-Path -Parent $scriptDir

$reportsDir = Join-Path $baseDir "reports"
New-Item -ItemType Directory -Path $reportsDir -ErrorAction SilentlyContinue | Out-Null

$roots = @(
    "C:\Users\Chris",
    (Join-Path $baseDir ".")
)

$result = @()

foreach ($root in $roots) {
    if (-not (Test-Path $root)) { continue }

    $folders = Get-ChildItem $root -Directory -ErrorAction SilentlyContinue
    foreach ($f in $folders) {
        $sizeBytes = (Get-ChildItem $f.FullName -Recurse -File -ErrorAction SilentlyContinue |
            Measure-Object Length -Sum).Sum
        if (-not $sizeBytes) { $sizeBytes = 0 }

        $result += [PSCustomObject]@{
            root    = $root
            path    = $f.FullName
            size_gb = [math]::Round($sizeBytes / 1GB, 3)
        }
    }
}

$top = $result | Sort-Object size_gb -Descending | Select-Object -First 50

$out = @{
    generated_at = (Get-Date).ToString("s")
    entries      = $top
}

$outPath = Join-Path $reportsDir "disk_usage_map.json"
$out | ConvertTo-Json -Depth 5 | Out-File $outPath -Encoding UTF8
