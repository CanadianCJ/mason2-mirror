param(
    [Parameter(Mandatory = $true)]
    [string]$ZipPath,

    [string]$Label = "manual-ingest",

    # Athena base URL
    [string]$AthenaUrl = "http://127.0.0.1:8000",

    # When present, DO NOT call /api/ingest_chunk (no LLM cost).
    [switch]$NoLLM
)

$ErrorActionPreference = "Stop"

Write-Host "[INFO] Mason_IngestZip starting..." -ForegroundColor Cyan
Write-Host "[INFO] ZipPath : $ZipPath"
Write-Host "[INFO] Label   : $Label"
Write-Host "[INFO] Athena  : $AthenaUrl"
Write-Host "[INFO] NoLLM   : $($NoLLM.IsPresent)" 

# --- Resolve paths and create ingest/report folders ---

$zipFull = (Resolve-Path $ZipPath).Path
$root    = Split-Path -Path $PSScriptRoot -Parent   # C:\Users\Chris\Desktop\Mason2

$ingestRoot  = Join-Path $root "ingest"
$reportsRoot = Join-Path $root "reports"

New-Item -ItemType Directory -Force -Path $ingestRoot  | Out-Null
New-Item -ItemType Directory -Force -Path $reportsRoot | Out-Null

$runId     = Get-Date -Format "yyyyMMdd_HHmmss"
$runDir    = Join-Path $ingestRoot $runId
$sourceDir = Join-Path $runDir "source"

New-Item -ItemType Directory -Force -Path $sourceDir | Out-Null

Write-Host "[INFO] Ingest run $runId for zip: $zipFull"
Write-Host "[INFO] Expand to: $sourceDir"

# --- Extract zip ---

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($zipFull, $sourceDir)

# --- Collect text-like files ---

$txtFiles = Get-ChildItem -Path $sourceDir -Recurse -File |
    Where-Object { $_.Extension -in ".txt", ".md", ".log", ".json" }

if (-not $txtFiles -or $txtFiles.Count -eq 0) {
    Write-Warning "[WARN] No text-like files found in zip."
    return
}

Write-Host "[INFO] Found $($txtFiles.Count) text-like files to ingest.`n"

# --- Ingest settings ---

$chunkSize = 1000              # must be <= max_chars allowed by API
$ingestUrl = "$AthenaUrl/api/ingest_chunk"

# Track summary for a small index JSON
$index = @{
    run_id  = $runId
    zip     = $zipFull
    label   = $Label
    no_llm  = $NoLLM.IsPresent
    files   = @()
}

function Convert-ToAsciiSafe {
    param(
        [string]$Text
    )
    # Keep:  LF (10), CR (13), and printable ASCII 32–126.
    $chars = $Text.ToCharArray()
    $builder = New-Object System.Text.StringBuilder
    foreach ($c in $chars) {
        $code = [int][char]$c
        if ( ($code -ge 32 -and $code -le 126) -or $code -eq 10 -or $code -eq 13 ) {
            [void]$builder.Append($c)
        } else {
            [void]$builder.Append(' ')
        }
    }
    return $builder.ToString()
}

foreach ($file in $txtFiles) {
    Write-Host "[INFO] Ingesting $($file.FullName)" -ForegroundColor Yellow

    # Read full file as UTF-8
    $raw = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8

    if ([string]::IsNullOrWhiteSpace($raw)) {
        Write-Warning "   [SKIP] File empty or whitespace."
        continue
    }

    # Brutal cleaning: force to ASCII-safe only
    $clean = Convert-ToAsciiSafe -Text $raw

    $originalLen = $clean.Length
    $totalLen    = $originalLen

    $offset   = 0
    $chunkNum = 0
    $okChunks = 0

    while ($offset -lt $totalLen) {
        $chunkNum += 1
        $len   = [Math]::Min($chunkSize, $totalLen - $offset)
        $chunk = $clean.Substring($offset, $len)
        $offset += $len

        Write-Host ("   - chunk {0} (pos {1}/{2}, len={3})" -f $chunkNum, $offset, $totalLen, $len)

        if ($NoLLM) {
            # Storage/index-only mode: do NOT call the LLM/API
            Write-Host "     -> SKIP LLM (NoLLM mode)" -ForegroundColor DarkYellow
            continue
        }

        # Build request body EXACTLY like Swagger / curl
        $bodyObj = @{
            content   = $chunk
            label     = $Label
            max_chars = $chunkSize
        }

        $json = $bodyObj | ConvertTo-Json -Depth 3

        try {
            $resp = Invoke-RestMethod -Uri $ingestUrl `
                                      -Method Post `
                                      -ContentType "application/json" `
                                      -Body $json `
                                      -ErrorAction Stop

            $okChunks += 1
            Write-Host "     -> OK (label='$($resp.label)')" -ForegroundColor Green
        }
        catch {
            Write-Warning "     -> FAILED: $($_.Exception.Message)"

            if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                Write-Warning ("        Body: " + $_.ErrorDetails.Message)
            }
        }
    }

    $index.files += [pscustomobject]@{
        path            = $file.FullName
        length          = $totalLen
        original_length = $originalLen
        chunk_size      = $chunkSize
        chunks_sent     = $chunkNum
        chunks_ok       = $okChunks
    }
}

# --- Write small index JSON for this run ---

$indexPath = Join-Path $reportsRoot ("ingest_index_{0}.json" -f $runId)
$index | ConvertTo-Json -Depth 5 | Set-Content -Path $indexPath -Encoding UTF8

Write-Host "`n[OK] Ingest run complete." -ForegroundColor Cyan
Write-Host "     Run ID:   $runId"
Write-Host "     Index:    $indexPath"
Write-Host "     Source:   $sourceDir"
if ($NoLLM) {
    Write-Host "     NOTE: NoLLM mode: chunks were NOT sent to /api/ingest_chunk (no API cost)." -ForegroundColor DarkYellow
}
