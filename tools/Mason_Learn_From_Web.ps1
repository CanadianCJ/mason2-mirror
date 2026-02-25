param(
    [Parameter(Mandatory = $true)]
    [string]$Topic,

    [Parameter(Mandatory = $true)]
    [ValidateSet("mason","pc","onyx","athena","business","tax")]
    [string]$Area
)

# Mason base folder = one level up from /tools
$Base = Split-Path $PSScriptRoot -Parent

# --- ensure knowledge folders exist ---
$knowledgeRoot = Join-Path $Base "knowledge"
if (-not (Test-Path $knowledgeRoot)) {
    New-Item -ItemType Directory -Path $knowledgeRoot | Out-Null
}

$areaRoot = Join-Path $knowledgeRoot $Area
if (-not (Test-Path $areaRoot)) {
    New-Item -ItemType Directory -Path $areaRoot | Out-Null
}

# --- build filename for this learning pull ---
$slug      = ($Topic -replace '[^a-zA-Z0-9]+','-').ToLower()
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outFile   = Join-Path $areaRoot ("learn-" + $slug + "-" + $timestamp + ".html")

# --- build a simple search URL (read-only) ---
$encoded = [uri]::EscapeDataString($Topic)
$url     = "https://www.bing.com/search?q=$encoded"

Write-Host "[Learn] Fetching web results for '$Topic' into:"
Write-Host "        $outFile"
Write-Host ""

try {
    Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing
    Write-Host "[Learn] Saved search page to $outFile"
}
catch {
    Write-Warning "[Learn] Failed to fetch '$Topic' : $($_.Exception.Message)"
}

# --- log that a learning pull happened ---
$logDir = Join-Path $Base "reports"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}

$logFile = Join-Path $logDir "mason_learn_log.txt"
$line    = "{0} | area={1} | topic={2} | file={3}" -f `
           (Get-Date).ToString("s"), $Area, $Topic, $outFile

Add-Content -Path $logFile -Value $line
