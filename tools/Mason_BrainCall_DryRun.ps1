param(
    [string]$UserMessage = "Mason, give me a status summary and next steps."
)

$ErrorActionPreference = "Stop"

$basePath      = "C:\Users\Chris\Desktop\Mason2"
$reportsFolder = Join-Path $basePath "reports"
$logsFolder    = Join-Path $basePath "logs"

$contextPath   = Join-Path $reportsFolder "mason_brain_context.json"
$outputPath    = Join-Path $reportsFolder "mason_brain_call_example.json"
$logPath       = Join-Path $logsFolder "mason_brain_call.log"

if (-not (Test-Path $logsFolder)) {
    New-Item -ItemType Directory -Path $logsFolder -ErrorAction SilentlyContinue | Out-Null
}

function Write-Log {
    param(
        [string]$Message
    )
    $ts = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    Add-Content -Path $logPath -Value "[$ts] $Message"
}

Write-Log "=== Mason_BrainCall_DryRun started ==="

if (-not (Test-Path $contextPath)) {
    Write-Log "Context file not found at $contextPath"
    throw "mason_brain_context.json not found. Run Mason_Brain_Context_Builder.ps1 first."
}

# Load the brain context
try {
    $contextRaw = Get-Content -Path $contextPath -Raw
    $contextObj = $contextRaw | ConvertFrom-Json
}
catch {
    Write-Log "Failed to parse mason_brain_context.json: $_"
    throw
}

$nowUtc = [DateTime]::UtcNow

# Build the brain call payload
$payload = [PSCustomObject]@{
    type              = "mason_brain_call"
    version           = 1
    generated_at_utc  = $nowUtc.ToString("o")
    user_message      = $UserMessage
    context           = $contextObj.context
}

try {
    if (-not (Test-Path $reportsFolder)) {
        New-Item -ItemType Directory -Path $reportsFolder -ErrorAction SilentlyContinue | Out-Null
    }

    $json = $payload | ConvertTo-Json -Depth 12

    # Write to file
    Set-Content -Path $outputPath -Value $json -Encoding UTF8
    Write-Log "Wrote brain call example to $outputPath."

    # Also print to the console so we can see it
    Write-Host ""
    Write-Host "==== Mason brain call payload preview ===="
    Write-Host $json
    Write-Host "========================================="
    Write-Host ""
    Write-Host "File written to: $outputPath"
}
catch {
    Write-Log "Failed to write mason_brain_call_example.json: $_"
    throw
}

Write-Log "=== Mason_BrainCall_DryRun completed ==="
