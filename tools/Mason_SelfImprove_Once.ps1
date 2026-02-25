<# 
    Mason_SelfImprove_Once.ps1

    Run ONE full self-improvement cycle for Mason (and later Athena) in a single command:

      1) Ask the Teacher for a new self-improvement plan
      2) Import the plan to mason_teacher_suggestions.json
      3) Queue suggestions into pending_patch_runs.json
      4) Run Mason_SelfOps_Cycle.ps1 to auto-approve & execute within guardrails

    Usage (from the tools folder):

        .\Mason_SelfImprove_Once.ps1
#>

param()

$ErrorActionPreference = "Stop"

# Resolve paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir   = Split-Path $ScriptDir -Parent

function Write-Info ($msg) {
    Write-Host "[SelfImproveOnce] $msg"
}

function Invoke-MasonTool {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ScriptName
    )

    $path = Join-Path $ScriptDir $ScriptName
    if (-not (Test-Path $path)) {
        Write-Host "[SelfImproveOnce] WARNING: Tool not found: $path" -ForegroundColor Yellow
        return $false
    }

    Write-Info "Running $ScriptName..."

    try {
        # If the script throws, $ErrorActionPreference = 'Stop' will bubble it up
        & $path
    }
        catch {
        # Safely print the error without confusing PowerShell's variable parsing
        $msg = "[SelfImproveOnce] ERROR running {0}:{1}{2}" -f $ScriptName, [Environment]::NewLine, ($_ | Out-String)
        Write-Host $msg -ForegroundColor Red
        return $false
    }


    # Don’t trust $LASTEXITCODE here – many scripts use non-zero codes even on success
    return $true
}


Write-Info "=== Mason_SelfImprove_Once starting ==="
Write-Info ("RootDir = {0}" -f $RootDir)

# 1) Ask Teacher for a new self-improvement plan
if (-not (Invoke-MasonTool -ScriptName "Mason_Teacher_SelfImprove_Mason.ps1")) {
    Write-Info "Teacher self-improve step failed; aborting cycle."
    exit 1
}

# 2) Import the latest plan into mason_teacher_suggestions.json
if (-not (Invoke-MasonTool -ScriptName "Mason_Teacher_Import_Plan.ps1")) {
    Write-Info "Teacher import step failed; aborting cycle."
    exit 1
}

# 3) Queue suggestions into pending_patch_runs.json
if (-not (Invoke-MasonTool -ScriptName "Mason_Teacher_Queue_Suggestions.ps1")) {
    Write-Info "Teacher queue step failed; aborting cycle."
    exit 1
}

# 4) Run SelfOps_Cycle to auto-approve & execute within guardrails
if (-not (Invoke-MasonTool -ScriptName "Mason_SelfOps_Cycle.ps1")) {
    Write-Info "SelfOps cycle step failed."
    exit 1
}

Write-Info "=== Mason_SelfImprove_Once completed ==="
exit 0
