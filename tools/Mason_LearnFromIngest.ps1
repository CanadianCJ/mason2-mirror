param(
    [int]$MaxChunks = 0,          # 0 = no global limit, process everything
    [string]$AthenaUrl = "http://127.0.0.1:8000"
)

$ErrorActionPreference = "Stop"

Write-Host "[Learn] Mason_LearnFromIngest (RESUME / RETRY) starting..." -ForegroundColor Cyan
Write-Host "[Learn] Athena URL : $AthenaUrl"
Write-Host "[Learn] MaxChunks  : $MaxChunks (0 = unlimited)"
Write-Host ""

# -------------------------------------------------------
# Resolve base paths
# -------------------------------------------------------
$root       = Split-Path -Parent $PSScriptRoot        # C:\Users\Chris\Desktop\Mason2
$reportsDir = Join-Path $root "reports"
$brainDir   = Join-Path $root "brain"

New-Item -ItemType Directory -Force -Path $brainDir   | Out-Null

# -------------------------------------------------------
# Load existing learned chunks so we can SKIP already-done work
# -------------------------------------------------------
$existing = @{}   # key = "<index_file>|<source_path>|<file_chunk>"
$brainFiles = Get-ChildItem -Path $brainDir -Filter "learn_chunks_*.jsonl" -ErrorAction SilentlyContinue

if ($brainFiles) {
    foreach ($bf in $brainFiles) {
        Write-Host "[Learn] Scanning existing brain file: $($bf.Name)"
        foreach ($line in Get-Content -LiteralPath $bf.FullName -ErrorAction SilentlyContinue) {
            $t = $line.Trim()
            if (-not $t) { continue }

            try {
                $obj = $t | ConvertFrom-Json
            }
            catch {
                continue
            }

            $idxName   = $obj.index_file
            $srcPath   = $obj.source_path
            $fileChunk = $obj.file_chunk

            if ($idxName -and $srcPath -ne $null -and $fileChunk -ne $null) {
                $key = "{0}|{1}|{2}" -f $idxName, $srcPath, $fileChunk
                $existing[$key] = $true
            }
        }
    }
}

$knownCount = $existing.Keys.Count
Write-Host "[Learn] Found $knownCount previously-learned chunk records to skip if re-seen."
Write-Host ""

# -------------------------------------------------------
# Helper: log to file + console
# -------------------------------------------------------
$runId      = Get-Date -Format "yyyyMMdd_HHmmss"
$chunksPath = Join-Path $brainDir ("learn_chunks_{0}.jsonl" -f $runId)
$logPath    = Join-Path $brainDir ("learn_log_{0}.txt" -f $runId)

function Write-Log {
    param(
        [string]$Message
    )
    $ts   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[{0}] {1}" -f $ts, $Message
    Write-Host $line
    $line | Out-File -FilePath $logPath -Append -Encoding UTF8
}

Write-Log "RunId: $runId"
Write-Log "Root : $root"
Write-Log "ReportsDir: $reportsDir"
Write-Log "BrainDir  : $brainDir"
Write-Log "KnownChunks: $knownCount"
Write-Log ""

# -------------------------------------------------------
# Helper: very simple ASCII-safe cleaner (same idea as ingest)
# -------------------------------------------------------
function Convert-ToAsciiSafe {
    param(
        [string]$Text
    )
    $chars   = $Text.ToCharArray()
    $builder = New-Object System.Text.StringBuilder
    foreach ($c in $chars) {
        $code = [int][char]$c
        if ( ($code -ge 32 -and $code -le 126) -or $code -eq 10 -or $code -eq 13 ) {
            [void]$builder.Append($c)
        }
        else {
            [void]$builder.Append(' ')
        }
    }
    return $builder.ToString()
}

# -------------------------------------------------------
# Find ingest index JSON files
# -------------------------------------------------------
$indexFiles = Get-ChildItem -Path $reportsDir -Filter "ingest_index_*.json" -File -ErrorAction SilentlyContinue |
              Sort-Object Name

if (-not $indexFiles -or $indexFiles.Count -eq 0) {
    Write-Log "[ERROR] No ingest_index_*.json files found under $reportsDir"
    throw "No ingest indexes found. Run Mason_IngestZip.ps1 first."
}

Write-Host "[Learn] Found $($indexFiles.Count) ingest index file(s):"
foreach ($idx in $indexFiles) {
    Write-Host "  - $($idx.Name)"
}
Write-Host ""

# -------------------------------------------------------
# Main loop: walk each index, then each file, then each chunk
# -------------------------------------------------------
$globalChunk = 0
$newSuccess  = 0
$failedCount = 0
$maxRetries  = 4
$stopAll     = $false

foreach ($idx in $indexFiles) {
    if ($stopAll) { break }

    Write-Log "[Index] $($idx.Name)"
    $idxData = Get-Content -LiteralPath $idx.FullName -Raw | ConvertFrom-Json

    $label = $idxData.label
    Write-Log "  Label: $label"
    Write-Log "  Files: $($idxData.files.Count)"

    foreach ($fileEntry in $idxData.files) {
        if ($stopAll) { break }

        $sourcePath = $fileEntry.path
        $fileLength = [int]$fileEntry.length
        $chunkSize  = if ($fileEntry.chunk_size) { [int]$fileEntry.chunk_size } else { 12000 }

        Write-Log "  [File] $sourcePath (len=$fileLength, chunkSize=$chunkSize)"

        if (-not (Test-Path -LiteralPath $sourcePath)) {
            Write-Log "    [WARN] Source file not found, skipping."
            continue
        }

        $raw = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8

        if ([string]::IsNullOrWhiteSpace($raw)) {
            Write-Log "    [WARN] File empty/whitespace, skipping."
            continue
        }

        $clean     = Convert-ToAsciiSafe -Text $raw
        $totalLen  = $clean.Length
        $offset    = 0
        $fileChunk = 0

        while ($offset -lt $totalLen) {
            $fileChunk++
            $globalChunk++

            if ($MaxChunks -gt 0 -and $globalChunk -gt $MaxChunks) {
                Write-Log "[WARN] MaxChunks reached ($MaxChunks). Stopping after chunk $globalChunk."
                $stopAll = $true
                break
            }

            $len   = [Math]::Min($chunkSize, $totalLen - $offset)
            $chunk = $clean.Substring($offset, $len)
            $offset += $len

            $chunkKey = "{0}|{1}|{2}" -f $idx.Name, $sourcePath, $fileChunk
            if ($existing.ContainsKey($chunkKey)) {
                Write-Log ("    [SKIP] Chunk {0} (fileChunk={1}, len={2}) already learned in a previous run." -f $globalChunk, $fileChunk, $len)
                continue
            }

            Write-Log ("    - Chunk {0} (fileChunk={1}, len={2}) -> sending to /api/chat" -f $globalChunk, $fileChunk, $len)

            $prompt = @"
You are Mason's internal learning process.

You are reading a chunk of Chris's Mason/Onyx/Athena project data from file:
  $($sourcePath)
Index file: $($idx.Name)
Label: $($label)

Your job:
1) Extract the most important facts, policies/rules, roadmap items, and open questions/risks.
2) Return a single JSON object exactly in this schema:

{
  "file": "<just the filename>",
  "chunk_index": <0-based index within this file>,
  "label": "<label>",
  "important_facts": [ "...", "..." ],
  "policies_and_rules": [ "...", "..." ],
  "todo_or_roadmap_items": [ "...", "..." ],
  "open_questions_or_risks": [ "...", "..." ]
}

Only output JSON, nothing else.

Here is the chunk (UTF-8 text):

""" 
$chunk
"""
"@

            $bodyObj = @{
                message = $prompt
            }

            $jsonBody = $bodyObj | ConvertTo-Json -Depth 4

            $attempt  = 0
            $success  = $false

            while (-not $success -and $attempt -lt $maxRetries) {
                $attempt++
                try {
                    $resp = Invoke-RestMethod -Uri "$AthenaUrl/api/chat" `
                                              -Method Post `
                                              -ContentType "application/json" `
                                              -Body $jsonBody `
                                              -TimeoutSec 120

                    if (-not $resp.ok) {
                        Write-Log ("      [WARN] Chat call NOT ok for chunk {0} (attempt {1}). ok={2}" -f $globalChunk, $attempt, $resp.ok)
                        if ($attempt -lt $maxRetries) {
                            Start-Sleep -Seconds (5 * $attempt)
                        }
                        continue
                    }

                    $replyText = [string]$resp.reply

                    $parsed = $null
                    try {
                        $parsed = $replyText | ConvertFrom-Json
                    }
                    catch {
                        Write-Log ("      [WARN] Failed to parse reply JSON for chunk {0} (attempt {1}). Storing raw text." -f $globalChunk, $attempt)
                    }

                    $record = [pscustomobject]@{
                        run_id       = $runId
                        index_file   = $idx.Name
                        label        = $label
                        source_path  = $sourcePath
                        global_chunk = $globalChunk
                        file_chunk   = $fileChunk
                        text_length  = $len
                        model_reply  = $replyText
                        parsed       = $parsed
                    }

                    $record | ConvertTo-Json -Depth 6 | Out-File -FilePath $chunksPath -Append -Encoding UTF8

                    $existing[$chunkKey] = $true
                    $newSuccess++
                    $success = $true
                    Write-Log ("      [OK] Learned chunk {0} (fileChunk={1}) on attempt {2}" -f $globalChunk, $fileChunk, $attempt)
                }
                catch {
                    $failedMsg = $_.Exception.Message
                    Write-Log ("      [WARN] Chat call FAILED for chunk {0} (attempt {1}): {2}" -f $globalChunk, $attempt, $failedMsg)
                    if ($attempt -lt $maxRetries) {
                        Start-Sleep -Seconds (5 * $attempt)
                    }
                    else {
                        $failedCount++
                        Write-Log ("      [ERR] Giving up on chunk {0} after {1} attempts." -f $globalChunk, $maxRetries)
                    }
                }
            } # while attempts
        } # while chunks
    } # foreach file
} # foreach index

Write-Host ""
Write-Host "[Learn] DONE." -ForegroundColor Cyan
Write-Host "  Run ID:            $runId"
Write-Host "  Chunks file:       $chunksPath"
Write-Host "  Log file:          $logPath"
Write-Host "  Known chunks in DB: $knownCount"
Write-Host "  New successes:     $newSuccess"
Write-Host "  Failed chunks:     $failedCount"

Write-Log ""
Write-Log "SUMMARY: newSuccess=$newSuccess failed=$failedCount knownAlready=$knownCount"
