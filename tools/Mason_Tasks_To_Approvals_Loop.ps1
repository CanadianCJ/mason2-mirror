[CmdletBinding()]
param(
    [int]$IntervalSeconds = 120,
    [string]$RootPath = ""
)

$ErrorActionPreference = "Continue"

function Write-TasksLoopLog {
    param([string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Mason_Tasks_To_Approvals_Loop] $Message"
}

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $RootPath) {
    $RootPath = Split-Path -Parent $scriptRoot
}

$scriptPath = Join-Path (Join-Path $RootPath "tools") "Mason_Tasks_To_Approvals.ps1"

Write-TasksLoopLog ("Starting loop (interval={0}s)." -f $IntervalSeconds)
Write-TasksLoopLog ("Script: {0}" -f $scriptPath)

while ($true) {
    try {
        if (Test-Path -LiteralPath $scriptPath) {
            & $scriptPath -RootPath $RootPath
        }
        else {
            Write-TasksLoopLog "Queue script missing; waiting for next cycle."
        }
    }
    catch {
        Write-TasksLoopLog ("Queue loop error: {0}" -f $_.Exception.Message)
    }

    Start-Sleep -Seconds $IntervalSeconds
}
