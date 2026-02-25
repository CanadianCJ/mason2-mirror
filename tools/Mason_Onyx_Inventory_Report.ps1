# Mason_Onyx_Inventory_Report.ps1
# Scans the Onyx Flutter project and writes a JSON inventory report
# into C:\Users\Chris\Desktop\Mason2\reports\onyx_inventory.json
# so Mason has a machine-readable map of Onyx's modules.

$ErrorActionPreference = "Stop"

# Figure out Mason2 root based on this script's location
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root     = Split-Path -Parent $toolsDir

$logDir    = Join-Path $root "logs"
$reportDir = Join-Path $root "reports"

if (-not (Test-Path $logDir))    { New-Item -ItemType Directory -Path $logDir    | Out-Null }
if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir | Out-Null }

$logPath    = Join-Path $logDir    "onyx_inventory.log"
$reportPath = Join-Path $reportDir "onyx_inventory.json"

function Write-InvLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $line = "[{0}][{1}] {2}" -f (Get-Date), $Level, $Message
    Add-Content -Path $logPath -Value $line
}

Write-InvLog "Starting Onyx inventory scan..."

# --- Locate Onyx root ---

# Preferred: environment variable, if you ever want to override
$OnyxRoot  = "C:\Users\Chris\Desktop\Mason2\Component - Onyx App\onyx_business_manager"

if (-not $onyxRoot -or -not (Test-Path $onyxRoot)) {
    # Fallback: your standard Onyx Flutter path
$OnyxRoot  = "C:\Users\Chris\Desktop\Mason2\Component - Onyx App\onyx_business_manager"
}

if (-not (Test-Path $onyxRoot)) {
    Write-InvLog "Onyx root not found at '$onyxRoot'." "ERROR"
    $report = [ordered]@{
        generatedAt = (Get-Date).ToString("s") + "Z"
        ok          = $false
        error       = "Onyx root not found"
        onyx_root   = $onyxRoot
        files       = @()
    }
    $report | ConvertTo-Json -Depth 6 | Set-Content -Path $reportPath -Encoding UTF8
    Write-InvLog "Wrote error report to $reportPath." "ERROR"
    exit 1
}

$libDir = Join-Path $onyxRoot "lib"
if (-not (Test-Path $libDir)) {
    Write-InvLog "Onyx lib directory not found at '$libDir'." "ERROR"
    $report = [ordered]@{
        generatedAt = (Get-Date).ToString("s") + "Z"
        ok          = $false
        error       = "Onyx lib directory not found"
        onyx_root   = $onyxRoot
        files       = @()
    }
    $report | ConvertTo-Json -Depth 6 | Set-Content -Path $reportPath -Encoding UTF8
    Write-InvLog "Wrote error report to $reportPath." "ERROR"
    exit 1
}

Write-InvLog "Using Onyx root: $onyxRoot"
Write-InvLog "Scanning lib dir: $libDir"

# --- Heuristics: what kind of features we care about ---

$featurePatterns = @(
    "invoice", "billing", "payment",
    "client", "customer", "contact",
    "deal", "job", "opportunity",
    "task", "todo", "checklist",
    "project",
    "expense", "cost", "spend",
    "dashboard", "home", "overview",
    "auth", "login", "signup",
    "business", "company", "settings", "profile"
)

# Helper to guess rough feature hints from filename / path
function Get-FeatureHints {
    param(
        [string]$relativePath
    )

    $nameLower = $relativePath.ToLower()
    $hits = @()

    foreach ($pat in $featurePatterns) {
        if ($nameLower -like "*$pat*") {
            $hits += $pat
        }
    }

    # Use unique hints only
    $hits = $hits | Select-Object -Unique
    return $hits
}

# --- Scan Dart files ---

$dartFiles = Get-ChildItem -Path $libDir -Recurse -File -Filter "*.dart" -ErrorAction SilentlyContinue

Write-InvLog ("Found {0} Dart files under lib\" -f $dartFiles.Count)

$featureEntries = @()

foreach ($file in $dartFiles) {
    $relativePath = $file.FullName.Substring($libDir.Length).TrimStart('\','/')

    $hints = Get-FeatureHints -relativePath $relativePath

    # We include everything, but mark important ones with hints.
    $entry = [ordered]@{
        relative_path  = $relativePath
        size_bytes     = $file.Length
        last_write     = $file.LastWriteTime.ToString("s") + "Z"
        feature_hints  = $hints
    }

    $featureEntries += $entry
}

# --- Build final report object ---

$important = $featureEntries | Where-Object { $_.feature_hints.Count -gt 0 }

$reportObj = [ordered]@{
    generatedAt        = (Get-Date).ToString("s") + "Z"
    ok                 = $true
    onyx_root          = $onyxRoot
    lib_dir            = $libDir
    total_dart_files   = $featureEntries.Count
    important_files    = $important
    all_files          = $featureEntries
}

$reportObj | ConvertTo-Json -Depth 8 | Set-Content -Path $reportPath -Encoding UTF8

Write-InvLog ("Onyx inventory report written to {0}" -f $reportPath)
Write-InvLog ("Important files (with feature hints): {0}" -f $important.Count)
Write-InvLog "Onyx inventory scan complete."

