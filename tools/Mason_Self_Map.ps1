Param(
    [string]$RootDir
)

$ErrorActionPreference = "Stop"

# Default root = Mason2 folder (parent of \tools)
if (-not $RootDir -or -not (Test-Path $RootDir)) {
    $RootDir = Split-Path $PSScriptRoot -Parent
}

$rootFull = (Resolve-Path $RootDir).Path

$reportDir = Join-Path $rootFull "reports"
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
$reportPath = Join-Path $reportDir "mason_self_map.json"

# Directories to skip so the map is detailed but not insane
$excludeDirs = @(
    ".git", ".hg", ".svn",
    ".venv", "__pycache__",
    "node_modules",
    "build", "dist", ".dart_tool",
    "bin", "obj",
    "logs",
    ".idea", ".vscode"
)

$items    = @()
$dirCount = 0

Get-ChildItem -Path $rootFull -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object {
        # skip excluded directories anywhere in the path
        $relative = $_.FullName.Substring($rootFull.Length).TrimStart('\')
        $parts = $relative.Split('\')
        ($parts | Where-Object { $excludeDirs -contains $_ }).Count -eq 0
    } |
    ForEach-Object {
        $relative = $_.FullName.Substring($rootFull.Length).TrimStart('\')

        if ($_.PSIsContainer) {
            $dirCount++
        }
        else {
            $items += [PSCustomObject]@{
                path       = $relative
                size_bytes = $_.Length
                lastWrite  = $_.LastWriteTime
                ext        = $_.Extension
            }
        }
    }

# quick stats by extension so teacher/Mason can quickly see where the weight is
$byExt = $items |
    Group-Object -Property ext |
    Sort-Object -Property Count -Descending |
    Select-Object -First 100 |
    ForEach-Object {
        [PSCustomObject]@{
            ext   = $_.Name
            count = $_.Count
        }
    }

$map = [PSCustomObject]@{
    generatedAt_utc = (Get-Date).ToUniversalTime().ToString("o")
    root            = $rootFull
    total_files     = $items.Count
    total_dirs      = $dirCount
    by_extension    = $byExt
    files           = $items
}

$map | ConvertTo-Json -Depth 6 | Set-Content -Path $reportPath -Encoding UTF8

Write-Host "[SelfMap] Wrote Mason self map to $reportPath"
