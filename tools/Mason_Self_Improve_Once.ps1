param(
    [string]$RootPath = "C:\Users\Chris\Desktop\Mason2",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$toolsDir = Join-Path $RootPath "tools"

Write-Host "=== Mason Self Improve Once ==="
Write-Host "RootPath = $RootPath"
Write-Host "DryRun   = $DryRun"

# 1) Ask Mason for a fresh low-risk patch plan
& (Join-Path $toolsDir "Mason_Request_PatchPlan.ps1") -RootPath $RootPath

# 2) Apply the plan with safe rules
if ($DryRun) {
    & (Join-Path $toolsDir "Mason_Apply_PatchPlan.ps1") -RootPath $RootPath -DryRun
} else {
    & (Join-Path $toolsDir "Mason_Apply_PatchPlan.ps1") -RootPath $RootPath
}

Write-Host "=== Mason Self Improve Once COMPLETE ==="
