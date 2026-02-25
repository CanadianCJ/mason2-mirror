[CmdletBinding()]
param(
    [string]$RootPath = "C:\Users\Chris\Desktop\Mason2",
    [string]$OutputPath
)

Write-Host "=== Mason Self Index (v2) ==="
Write-Host "RootPath   : $RootPath"

if (-not (Test-Path -LiteralPath $RootPath)) {
    throw "RootPath does not exist: $RootPath"
}

# Ensure reports folder + default output path
if (-not $OutputPath) {
    $reportsDir = Join-Path $RootPath "reports"
    if (-not (Test-Path -LiteralPath $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    }
    $OutputPath = Join-Path $reportsDir "self_index.json"
}

Write-Host "OutputPath : $OutputPath"
Write-Host ""

$root = Get-Item -LiteralPath $RootPath

# Directories we don't want to scan deeply
$excludedDirs = @(
    '.git', '.vs', '.idea',
    'node_modules', 'bin', 'obj',
    'packages', 'dist', 'build',
    'logs', 'log', 'temp', 'tmp',
    '__pycache__'
)

$items = New-Object System.Collections.Generic.List[object]
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "Walking file tree... (this may take a bit on first run)"

Get-ChildItem -LiteralPath $RootPath -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        # Filter out excluded directories by segment
        $full = $_.FullName
        $relative = $full.Substring($root.FullName.Length).TrimStart('\')
        $segments = $relative -split '\\'

        foreach ($seg in $segments) {
            if ($excludedDirs -contains $seg) { return $false }
        }
        return $true
    } |
    ForEach-Object {
        $file = $_
        $relative = $file.FullName.Substring($root.FullName.Length).TrimStart('\')

        $ext = $file.Extension
        if (-not $ext) { $ext = '' }

        # Simple category tagging for Mason
        $category = 'other'
        switch -Regex ($ext.ToLower()) {
            '\.ps1$'  { $category = 'script'; break }
            '\.psm1$' { $category = 'script'; break }
            '\.psd1$' { $category = 'script'; break }

            '\.json$' { $category = 'data';   break }
            '\.yml$'  { $category = 'data';   break }
            '\.yaml$' { $category = 'data';   break }

            '\.md$'   { $category = 'docs';   break }
            '\.txt$'  { $category = 'docs';   break }

            '\.log$'  { $category = 'logs';   break }

            '\.dart$' { $category = 'app';    break }
            '\.cs$'   { $category = 'app';    break }
        }

        $items.Add([PSCustomObject]@{
            path           = $relative
            full_path      = $file.FullName
            extension      = $ext
            category       = $category
            size_bytes     = $file.Length
            last_write_utc = $file.LastWriteTimeUtc.ToString("o")
        })
    }

$stopwatch.Stop()

Write-Host "Files indexed: $($items.Count)"
Write-Host "Elapsed ms   : $($stopwatch.ElapsedMilliseconds)"
Write-Host ""

# Build summaries for Mason
$summaryByCategory = $items |
    Group-Object -Property category |
    Sort-Object -Property Count -Descending |
    ForEach-Object {
        [PSCustomObject]@{
            category = $_.Name
            count    = $_.Count
        }
    }

$summaryByExtension = $items |
    Group-Object -Property extension |
    Sort-Object -Property Count -Descending |
    Select-Object -First 50 |
    ForEach-Object {
        [PSCustomObject]@{
            extension = $_.Name
            count     = $_.Count
        }
    }

$result = [PSCustomObject]@{
    generated_utc        = (Get-Date).ToUniversalTime().ToString("o")
    root_path            = $root.FullName
    total_files          = $items.Count
    build_ms             = $stopwatch.ElapsedMilliseconds
    summary_by_category  = $summaryByCategory
    summary_by_extension = $summaryByExtension
    items                = $items
}

$json = $result | ConvertTo-Json -Depth 6
$json | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "Self index written to:"
Write-Host "  $OutputPath"
Write-Host "=== Mason Self Index complete ==="
