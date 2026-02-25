param(
    [string]$Base      = "C:\Users\Chris\Desktop\Mason2",
    [int]   $MaxChunks = 50  # 0 = unlimited, otherwise cap
)

$ErrorActionPreference = "Stop"

function Write-JsonLineSafe {
    param(
        [string]$Path,
        [object]$Obj
    )
    try {
        $dir = Split-Path -Path $Path -Parent
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
        }

        $json = $Obj | ConvertTo-Json -Depth 10 -Compress
        Add-Content -LiteralPath $Path -Value $json
    }
    catch {
        Write-Warning "[Learner_10m] Failed to write JSON line to $Path : $($_.Exception.Message)"
    }
}

if (-not (Test-Path $Base)) {
    Write-Error "[Learner_10m] Base path not found: $Base"
    exit 1
}

Set-Location $Base

$reportsDir = Join-Path $Base "reports"
New-Item -ItemType Directory -Force -Path $reportsDir | Out-Null

# Cadence heartbeat so Mason can see the learner is alive
$logPath = Join-Path $reportsDir "cadence.jsonl"
$evt = @{
    ts      = (Get-Date).ToString("s")
    name    = "Learner"
    cadence = "10m"
    host    = $env:COMPUTERNAME
    result  = "ok"
}
Write-JsonLineSafe -Path $logPath -Obj $evt

Write-Host "[Learner_10m] Base      : $Base"
Write-Host "[Learner_10m] MaxChunks : $MaxChunks"
Write-Host ""

$toolsDir     = Join-Path $Base "tools"
$ingestScript = Join-Path $toolsDir "Mason_LearnFromIngest.ps1"
$webScript    = Join-Path $toolsDir "Mason_Learn_From_Web.ps1"

# 1) Learn from ingest (your big zip runs)
if (Test-Path $ingestScript) {
    Write-Host "[Learner_10m] [1/2] Running Mason_LearnFromIngest.ps1 ..." -ForegroundColor Cyan
    & $ingestScript -MaxChunks $MaxChunks
}
else {
    Write-Warning "[Learner_10m] Mason_LearnFromIngest.ps1 not found at $ingestScript"
}

# 2) Learn from web (small pass, optional)
if (Test-Path $webScript) {
    Write-Host "[Learner_10m] [2/2] Running Mason_Learn_From_Web.ps1 ..." -ForegroundColor Cyan
    & $webScript
}
else {
    Write-Warning "[Learner_10m] Mason_Learn_From_Web.ps1 not found at $webScript"
}

Write-Host ""
Write-Host "[Learner_10m] Done." -ForegroundColor Green
