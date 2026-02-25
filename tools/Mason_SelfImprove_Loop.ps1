param(
    [int]$IntervalMinutes = 5
)

# Figure out the tools directory from this script path
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

function Write-LoopLog {
    param([string]$Message)

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[SelfImproveLoop] [$timestamp] $Message"
}

Write-LoopLog "Starting Mason_SelfImprove_Loop.ps1 (interval = $IntervalMinutes minute(s))."
Write-LoopLog "Root directory: $root"
Write-LoopLog "Press Ctrl + C in this window to stop the loop."

while ($true) {
    try {
        Write-LoopLog "Running Mason_SelfImprove_Once.ps1..."
        . "$root\Mason_SelfImprove_Once.ps1"
        Write-LoopLog "Mason_SelfImprove_Once.ps1 finished."
    }
    catch {
        Write-LoopLog "ERROR in Mason_SelfImprove_Once.ps1: $($_.Exception.Message)"
    }

    Write-LoopLog "Sleeping for $IntervalMinutes minute(s)..."
    Start-Sleep -Seconds ($IntervalMinutes * 30)
}
