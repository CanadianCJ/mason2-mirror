param(
    [string]$BaseDir = ""
)

if (-not $BaseDir) {
    $BaseDir = Split-Path $PSScriptRoot -Parent
}

$reportsDir = Join-Path $BaseDir "reports"
$riskPath   = Join-Path $reportsDir "risk_state.json"
$uePath     = Join-Path $reportsDir "mason_ue_status.json"

if (-not (Test-Path $riskPath)) {
    Write-Host "[Status] risk_state.json not found at $riskPath" -ForegroundColor Red
    exit 1
}

$risk = Get-Content $riskPath -Raw | ConvertFrom-Json

$ue = $null
if (Test-Path $uePath) {
    try {
        $ue = Get-Content $uePath -Raw | ConvertFrom-Json
    } catch {
        Write-Host "[Status] Could not parse mason_ue_status.json (ignoring)." -ForegroundColor Yellow
    }
}

# helper: map numeric risk to R-level
function Get-RiskLabel([int]$n) {
    switch ($n) {
        0 { return "R0" }
        1 { return "R1" }
        2 { return "R2" }
        3 { return "R3" }
        default { return "R$n" }
    }
}

$lines = @()
$lines += "=== Mason Status Snapshot ==="
$lines += "GeneratedAt: $(Get-Date -Format 's')"
$lines += "Base:        $BaseDir"
$lines += ""

$lines += "Risk levels (by area):"
foreach ($area in $risk.areas) {
    $lines += ("- {0}: allowed={1}, start={2}, max_auto={3}" -f `
        $area.area,
        (Get-RiskLabel $area.allowed_risk),
        (Get-RiskLabel $area.start_risk),
        (Get-RiskLabel $area.max_auto_risk)
    )
}

$lines += ""
if ($ue -ne $null) {
    $lines += "UE snapshot:"
    $lines += "  generatedAt    : $($ue.generatedAt)"
    $lines += "  universal_evolution: $($ue.uePath)"
    if ($ue.businessPolicyPath) {
        $lines += "  businessPolicyPath: $($ue.businessPolicyPath)"
    }
    if ($ue.businessPolicy -eq $null) {
        $lines += "  businessPolicy  : (none loaded)"
    } else {
        $lines += "  businessPolicy  : (loaded)"
    }

    if ($ue.areas -and $ue.areas.Count -gt 0) {
        $lines += ""
        $lines += "UE areas:"
        foreach ($a in $ue.areas) {
            $lines += ("  - {0}: weight={1}, focus={2}" -f `
                $a.id,
                $a.weight,
                $a.focus
            )
        }
    } else {
        $lines += "  UE areas       : (none emitted yet)"
    }
} else {
    $lines += "UE snapshot: mason_ue_status.json not found."
}

$lines += ""
$lines += "=== Mason note ==="
$lines += "  Core autonomy mode is controlled by config\\mason_autonomy_mode.json."
$lines += "  Area risk policy is controlled by reports\\risk_state.json."

$statusPath = Join-Path $reportsDir "Mason_Status_Latest.txt"
$lines | Set-Content $statusPath -Encoding UTF8

Write-Host "[Status] Wrote Mason status snapshot to $statusPath" -ForegroundColor Green
