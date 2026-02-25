$ErrorActionPreference = "Stop"

$Base      = "C:\Users\Chris\Desktop\Mason2"
$IndexPath = Join-Path $Base "state\knowledge\ue_knowledge_index.json"

$ScanRoots = @(
    "brain",
    "reports",
    "learn",
    "config",
    "docs"
)

$RootPaths = $ScanRoots | ForEach-Object { Join-Path $Base $_ }

function Get-FileSnapshot {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return @()
    }

    Get-ChildItem -Path $Path -Recurse -File | ForEach-Object {
        [pscustomobject]@{
            path     = $_.FullName.Substring($Base.Length + 1)  # relative
            size     = $_.Length
            modified = $_.LastWriteTimeUtc.ToString("o")
        }
    }
}

# Load existing index if present
$existingIndex = @{}
if (Test-Path $IndexPath) {
    try {
        $raw = Get-Content $IndexPath -Raw
        if ($raw.Trim().Length -gt 0) {
            $existingIndex = $raw | ConvertFrom-Json
        }
    } catch {
        Write-Host "[UE-Intake] WARNING: Failed to parse existing index: $($_.Exception.Message)"
        $existingIndex = @{}
    }
}

if (-not $existingIndex.files) {
    $existingIndex = @{
        version   = 1
        last_scan = (Get-Date).ToString("o")
        files     = @{}
    }
}

$filesIndex = $existingIndex.files
$changes    = @()

foreach ($root in $RootPaths) {
    if (-not (Test-Path $root)) { continue }

    $snap = Get-FileSnapshot -Path $root
    foreach ($f in $snap) {
        $rel = $f.path
        $key = $rel.ToLowerInvariant()

        $prev    = $null
        $changed = $false

        if ($filesIndex.ContainsKey($key)) {
            $prev = $filesIndex[$key]
        }

        if (-not $prev) {
            $changed = $true
        } else {
            if ($prev.size -ne $f.size -or $prev.modified -ne $f.modified) {
                $changed = $true
            }
        }

        if ($changed) {
            $filesIndex[$key] = @{
                path      = $f.path
                size      = $f.size
                modified  = $f.modified
                last_seen = (Get-Date).ToString("o")
                status    = "new_or_changed"
            }
            $changes += $filesIndex[$key]
        }
    }
}

$existingIndex.last_scan = (Get-Date).ToString("o")
$existingIndex.files     = $filesIndex

($existingIndex | ConvertTo-Json -Depth 6) | Set-Content -Path $IndexPath -Encoding UTF8

if ($changes.Count -gt 0) {
    Write-Host "[UE-Intake] Detected $($changes.Count) new/changed file(s)."
} else {
    Write-Host "[UE-Intake] No new or changed files."
}
