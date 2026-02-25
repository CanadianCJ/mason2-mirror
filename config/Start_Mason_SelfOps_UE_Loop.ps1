$ErrorActionPreference = "Stop"

$Base        = "C:\Users\Chris\Desktop\Mason2"
$ToolsDir    = Join-Path $Base "tools"
$UECyclePath = Join-Path $ToolsDir "Mason_UE_Cycle_MasonSelfOps.ps1"
$BudgetFile  = Join-Path $Base "state\knowledge\mason_budget_state.json"

function Get-RemainingBudget {
    if (-not (Test-Path $BudgetFile)) {
        return 1.0  # no budget file yet -> assume OK
    }
    try {
        $b = Get-Content $BudgetFile -Raw | ConvertFrom-Json
        if ($b.remaining_ratio -ne $null) {
            return [double]$b.remaining_ratio
        }
        return 0.5
    } catch {
        return 0.5
    }
}

Write-Host "Starting Mason Self-Ops UE Loop (every 3 hours)..."
Write-Host "Press Ctrl+C to stop."

while ($true) {
    $rem = Get-RemainingBudget
    if ($rem -lt 0.1) {
        Write-Host "[UE-Loop] Budget low (remaining_ratio=$rem). Skipping this cycle."
    } else {
        Write-Host "[UE-Loop] Running Mason self-ops UE cycle (remaining_ratio=$rem)."
        & $UECyclePath
    }

    # Sleep for 3 hours
    Start-Sleep -Seconds (3 * 60 * 60)
}
