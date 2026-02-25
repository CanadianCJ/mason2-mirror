$ErrorActionPreference = "SilentlyContinue"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$baseDir   = Split-Path -Parent $scriptDir

$logsDir = Join-Path $baseDir "logs"
New-Item -ItemType Directory -Path $logsDir -ErrorAction SilentlyContinue | Out-Null

$logPath = Join-Path $logsDir "task_self_heal.log"

function Write-HealLog {
    param(
        [string]$Message
    )
    $line = "[{0}][TASK_SELF_HEAL] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logPath -Value $line
}

$expected = @(
    "Mason2-ApplyStability-10m",
    "Mason2-ApplyStability-NightlyWindow",
    "Mason2-AthenaStatus-10m",
    "Mason2-PCResource-10m",
    "Mason2-StabilityPlanner-1h"
)

foreach ($name in $expected) {
    $task = Get-ScheduledTask -TaskPath "\Mason2\" -TaskName $name -ErrorAction SilentlyContinue
    if (-not $task) {
        Write-HealLog "Task '$name' is missing (no action taken, just logging)."
        continue
    }

    if ($task.State -eq "Disabled") {
        try {
            Enable-ScheduledTask -TaskPath "\Mason2\" -TaskName $name -ErrorAction Stop
            Write-HealLog "Task '$name' was disabled and has been re-enabled."
        }
        catch {
            Write-HealLog "Failed to re-enable '$name': $_"
        }
    }
}
