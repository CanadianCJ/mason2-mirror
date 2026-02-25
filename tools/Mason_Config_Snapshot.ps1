$ErrorActionPreference = "SilentlyContinue"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$baseDir   = Split-Path -Parent $scriptDir

$backupDir = Join-Path $baseDir "backups"
New-Item -ItemType Directory -Path $backupDir -ErrorAction SilentlyContinue | Out-Null

$items = @()

$paths = @(
    "self_state.json",
    "persistent_memory.json",
    "plans"
)

foreach ($p in $paths) {
    $full = Join-Path $baseDir $p
    if (Test-Path $full) {
        $items += $full
    }
}

if ($items.Count -eq 0) { exit 0 }

$ts      = Get-Date -Format "yyyyMMdd-HHmmss"
$zipPath = Join-Path $backupDir "mason-config-$ts.zip"

Compress-Archive -Path $items -DestinationPath $zipPath -Force -ErrorAction SilentlyContinue
