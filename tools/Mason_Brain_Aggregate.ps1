param(
    [string]$Base = "C:\Users\Chris\Desktop\Mason2"
)

$ErrorActionPreference = "Stop"

function Write-BrainLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

try {
    if (-not (Test-Path $Base)) {
        throw "Base path not found: $Base"
    }

    $brainDir    = Join-Path $Base "brain"
    $reportsDir  = Join-Path $Base "reports"

    if (-not (Test-Path $brainDir)) {
        throw "Brain directory not found: $brainDir"
    }

    if (-not (Test-Path $reportsDir)) {
        New-Item -ItemType Directory -Force -Path $reportsDir | Out-Null
    }

    $outputBrainPath   = Join-Path $brainDir   "Mason_Brain.json"
    $outputSummaryPath = Join-Path $reportsDir "mason_brain_summary.json"

    Write-BrainLog "Mason_Brain_Aggregate starting..."
    Write-BrainLog "Base:      $Base"
    Write-BrainLog "Brain dir: $brainDir"

    # Find all learn_chunks_*.jsonl files
    $chunkFiles = Get-ChildItem -Path $brainDir -Filter "learn_chunks_*.jsonl" -File -ErrorAction SilentlyContinue

    if (-not $chunkFiles -or $chunkFiles.Count -eq 0) {
        throw "No learn_chunks_*.jsonl files found in $brainDir"
    }

    Write-BrainLog "Found $($chunkFiles.Count) learn_chunks_*.jsonl file(s)."

    # Aggregation structures
    $byLabel = @{}
    $byFile  = @{}
    $totalChunks      = 0
    $failedLines      = 0
    $seenKeys         = New-Object System.Collections.Generic.HashSet[string]
    $perFileChunkCount = @{}

    foreach ($file in $chunkFiles) {
        Write-BrainLog "Processing $($file.Name)..."
        $lineNumber = 0

        $perFileKey = $file.Name
        if (-not $perFileChunkCount.ContainsKey($perFileKey)) {
            $perFileChunkCount[$perFileKey] = 0
        }

        Get-Content -LiteralPath $file.FullName | ForEach-Object {
            $line = $_
            $lineNumber++

            if (-not $line.Trim()) {
                return
            }

            try {
                $obj = $line | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                $failedLines++
                Write-BrainLog "Failed to parse JSON line $lineNumber in $($file.Name): $($_.Exception.Message)" "WARN"
                return
            }

            $labelProp  = $null
            $indexFile  = $null
            $sourcePath = $null
            $fileChunk  = $null

            if ($obj.PSObject.Properties.Name -contains "label") {
                $labelProp = $obj.label
            }
            if ($obj.PSObject.Properties.Name -contains "index_file") {
                $indexFile = $obj.index_file
            }
            if ($obj.PSObject.Properties.Name -contains "source_path") {
                $sourcePath = $obj.source_path
            }
            if ($obj.PSObject.Properties.Name -contains "file_chunk") {
                $fileChunk = $obj.file_chunk
            }

            $keyParts = @()
            if ($indexFile)  { $keyParts += "idx=$indexFile" }
            if ($sourcePath) { $keyParts += "src=$sourcePath" }
            if ($fileChunk -ne $null) { $keyParts += "chunk=$fileChunk" }
            if ($labelProp)  { $keyParts += "label=$labelProp" }

            if ($keyParts.Count -eq 0) {
                $hash = [System.BitConverter]::ToString(
                    (New-Object -TypeName System.Security.Cryptography.SHA1Managed).ComputeHash(
                        [System.Text.Encoding]::UTF8.GetBytes($line)
                    )
                ).Replace("-", "")
                $key = "sha1=$hash"
            }
            else {
                $key = ($keyParts -join "|")
            }

            if ($seenKeys.Contains($key)) {
                return
            }
            [void]$seenKeys.Add($key)

            $labelKey = if ($labelProp) { [string]$labelProp } else { "unknown" }

            $fileKey = $null
            if ($obj.PSObject.Properties.Name -contains "source_file" -and $obj.source_file) {
                $fileKey = [string]$obj.source_file
            }
            elseif ($sourcePath) {
                try {
                    $fileKey = Split-Path -Path $sourcePath -Leaf
                }
                catch {
                    $fileKey = $sourcePath
                }
            }
            else {
                $fileKey = "unknown"
            }

            if (-not $byLabel.ContainsKey($labelKey)) {
                $byLabel[$labelKey] = @()
            }
            if (-not $byFile.ContainsKey($fileKey)) {
                $byFile[$fileKey] = @()
            }

            $byLabel[$labelKey] += $obj
            $byFile[$fileKey]   += $obj

            $totalChunks++
            $perFileChunkCount[$perFileKey]++

        }
    }

    Write-BrainLog "Aggregation complete. Unique chunks: $totalChunks. Failed lines: $failedLines."

    $brain = [ordered]@{
        version            = 1
        generated_at_utc   = (Get-Date).ToUniversalTime().ToString("o")
        mason_base         = $Base
        total_chunk_files  = $chunkFiles.Count
        total_chunks       = $totalChunks
        failed_lines       = $failedLines
        by_label           = $byLabel
        by_file            = $byFile
    }

    $json = $brain | ConvertTo-Json -Depth 6
    $brainDirParent = Split-Path -Path $outputBrainPath -Parent
    if (-not (Test-Path $brainDirParent)) {
        New-Item -ItemType Directory -Force -Path $brainDirParent | Out-Null
    }
    $json | Out-File -LiteralPath $outputBrainPath -Encoding UTF8

    $labelCounts = @{}
    foreach ($k in $byLabel.Keys) {
        $labelCounts[$k] = $byLabel[$k].Count
    }

    $summary = [ordered]@{
        generated_at_utc  = $brain.generated_at_utc
        mason_base        = $Base
        total_chunk_files = $chunkFiles.Count
        total_chunks      = $totalChunks
        failed_lines      = $failedLines
        label_counts      = $labelCounts
        source_files      = $perFileChunkCount
    }

    $summary | ConvertTo-Json -Depth 6 | Out-File -LiteralPath $outputSummaryPath -Encoding UTF8

    Write-BrainLog "Wrote Mason_Brain.json to $outputBrainPath"
    Write-BrainLog "Wrote mason_brain_summary.json to $outputSummaryPath"
    Write-BrainLog "Mason_Brain_Aggregate completed."
}
catch {
    Write-BrainLog "ERROR: $($_.Exception.Message)" "ERROR"
    exit 1
}
