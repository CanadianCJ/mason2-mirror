[CmdletBinding()]
param(
    [int]$IntervalMinutes = 15
)

$ErrorActionPreference = "Stop"

# Base folder: C:\Users\Chris\Desktop\Mason2
$base = Split-Path -Parent $PSScriptRoot
Set-Location $base

Write-Host "[OnyxAutoLoop] Mason Onyx auto-loop starting from $base" -ForegroundColor Cyan
Write-Host "[OnyxAutoLoop] Interval: $IntervalMinutes minute(s). Press Ctrl+C to stop." -ForegroundColor Cyan

while ($true) {
    try {
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host ""
        Write-Host "[$ts] [OnyxAutoLoop] Running Onyx health + analyzer -> tasks -> approvals..." -ForegroundColor Yellow

        # 1) Refresh Onyx health + feature map
        .\tools\Mason_Onyx_Prelaunch_Healthcheck.ps1
        .\tools\Mason_Onyx_Health_Summary.ps1

        # 2) Generate fix tasks from analyzer output
        .\tools\Mason_Onyx_Analyzer_To_Tasks.ps1

        # 3) Convert those tasks into approvals
        .\tools\Mason_Onyx_Tasks_To_Approvals.ps1

        Write-Host "[$ts] [OnyxAutoLoop] Cycle complete. Waiting $IntervalMinutes minute(s)..." -ForegroundColor Green
    }
    catch {
        Write-Host "[OnyxAutoLoop] ERROR during cycle: $($_.Exception.Message)" -ForegroundColor Red
    }

    Start-Sleep -Seconds ($IntervalMinutes * 60)
}
