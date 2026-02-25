Param()

$ErrorActionPreference = "Stop"

# Base dir = parent of tools
$root = Split-Path $PSScriptRoot -Parent

$reportsDir    = Join-Path $root "reports"
$riskPath      = Join-Path $reportsDir "risk_state.json"
$ueStatusPath  = Join-Path $reportsDir "mason_ue_status.json"
$selfStatePath = Join-Path $reportsDir "mason_self_state.json"
$onyxHealthPath= Join-Path $reportsDir "onyx_health_summary.json"

$knowledgeDir  = Join-Path $root "knowledge\mason"
$statusPath    = Join-Path $reportsDir "Mason_Status_Latest.txt"

# Helper to read JSON safely
function Read-JsonSafe {
    param(
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        return $null
    }
    try {
        return (Get-Content $Path -Raw | ConvertFrom-Json)
    } catch {
        return $null
    }
}

$risk      = Read-JsonSafe -Path $riskPath
$ueStatus  = Read-JsonSafe -Path $ueStatusPath
$selfState = Read-JsonSafe -Path $selfStatePath
$onyxHealth= Read-JsonSafe -Path $onyxHealthPath

$lines = @()

$lines += "=== Mason Status Snapshot ==="
$lines += "GeneratedAt: $(Get-Date -Format o)"
$lines += "Base:        $root"
$lines += ""

# Risk levels + basic metrics
$lines += "Risk levels (by area):"
if ($risk -and $risk.areas) {
    foreach ($area in $risk.areas) {
        $name   = $area.area
        $ar     = $area.allowed_risk
        $sr     = $area.start_risk
        $max    = $area.max_auto_risk

        $succ   = $area.metrics.successful_tasks
        $fail   = $area.metrics.failed_tasks
        $rb     = $area.metrics.rollbacks
        $hrs    = $area.metrics.hours_health_green

        $lines += "- $name: allowed_risk=$ar, start_risk=$sr, max_auto_risk=$max"
        $lines += "    metrics: successful=$succ, failed=$fail, rollbacks=$rb, hours_health_green=$hrs"
    }
} else {
    $lines += "- (risk_state.json missing or empty)"
}
$lines += ""

# UE snapshot pointer
$lines += "UE snapshot file:"
$lines += "  $ueStatusPath"
$lines += ""

# Self state pointer
$lines += "Self state snapshot:"
$lines += "  $selfStatePath"
$lines += ""

# Onyx health pointer
$lines += "Onyx health summary:"
$lines += "  $onyxHealthPath"
$lines += ""

# Simple UE activity summary based on knowledge\mason
$lines += "=== Mason UE activity (mason area) ==="

if (Test-Path $knowledgeDir) {
    $files = Get-ChildItem $knowledgeDir -File -ErrorAction SilentlyContinue
    if ($files -and $files.Count -gt 0) {
        $lines += "Knowledge files in $knowledgeDir: $($files.Count)"

        # Group by logical topic prefix
        $topicGroups = $files |
            Group-Object {
                # File names look like: learn-mason-core-ops-basics-YYYYMMDD-HHMMSS.html
                $name = $_.Name
                if ($name -match "^learn-(.+?)-\d{8}-\d{6}\.html$") {
                    return $matches[1]
                } else {
                    return "other"
                }
            }

        foreach ($g in $topicGroups) {
            $topic = $g.Name
            $count = $g.Count
            $latest = ($g.Group | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
            $lines += "- $topic: $count snapshots (latest: $($latest.LastWriteTime.ToString('u')))"
        }
    } else {
        $lines += "No knowledge files found yet in $knowledgeDir."
    }
} else {
    $lines += "Knowledge dir not found: $knowledgeDir"
}

$lines += ""

# Write output
$lines | Set-Content -Path $statusPath -Encoding UTF8

Write-Host "[Status] Wrote Mason status snapshot to $statusPath"
