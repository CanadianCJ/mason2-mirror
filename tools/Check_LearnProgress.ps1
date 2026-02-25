param()

$base      = "C:\Users\Chris\Desktop\Mason2"
$reports   = Join-Path $base "reports"
$brainDir  = Join-Path $base "brain"

Set-Location $base

# 1) Find all ingest index files
$indexes = Get-ChildItem $reports -Filter "ingest_index_*.json" -ErrorAction SilentlyContinue

if (-not $indexes) {
    Write-Host "No ingest_index_*.json files found under $reports" -ForegroundColor Yellow
    return
}

$totalPlanned = 0

foreach ($idx in $indexes) {
    $data = Get-Content $idx.FullName -Raw | ConvertFrom-Json

    foreach ($f in $data.files) {
        # how many 1000-char chunks we planned to send for this file
        $totalPlanned += [math]::Ceiling($f.length / $f.chunk_size)
    }
}

# 2) Count unique learned chunks from brain\learn_chunks_*.jsonl
$learnFiles = Get-ChildItem $brainDir -Filter "learn_chunks_*.jsonl" -ErrorAction SilentlyContinue

$learnedKeys = New-Object System.Collections.Generic.HashSet[string]

foreach ($lf in $learnFiles) {
    Get-Content $lf.FullName | ForEach-Object {
        $line = $_.Trim()
        if (-not $line) { return }

        try {
            $obj = $line | ConvertFrom-Json
            $key = "{0}|{1}|{2}" -f $obj.index_file, $obj.source_path, $obj.file_chunk
            [void]$learnedKeys.Add($key)
        }
        catch {
            # Ignore any weird/broken line instead of throwing a wall of errors
        }
    }
}

$learnedCount = $learnedKeys.Count
$remaining    = $totalPlanned - $learnedCount

Write-Host ""
Write-Host "PLANNED_CHUNKS = $totalPlanned"
Write-Host "LEARNED_CHUNKS = $learnedCount"
Write-Host "REMAINING      = $remaining"
