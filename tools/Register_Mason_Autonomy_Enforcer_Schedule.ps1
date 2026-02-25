param()

$ErrorActionPreference = "Stop"

$taskName   = "\Mason2\Mason2-AutonomyEnforcer-10m"
$scriptPath = "C:\Users\Chris\Desktop\Mason2\tools\Mason_Autonomy_Enforcer.ps1"

Write-Host "[INFO] Registering scheduled task: $taskName"

# Build the command to run PowerShell hidden
$psCommand = "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

try {
    schtasks.exe /Create `
        /TN $taskName `
        /TR $psCommand `
        /SC MINUTE `
        /MO 10 `
        /F `
        /RU $env:USERNAME | Out-Null

    Write-Host "[INFO] Task $taskName registered to run every 10 minutes."
    Write-Host "[INFO] Command: $psCommand"
} catch {
    Write-Host "[ERROR] Failed to register $taskName : $_"
}
