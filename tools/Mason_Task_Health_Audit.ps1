[CmdletBinding()]
param()

# Mason_Task_Health_Audit.ps1
# Snapshot of Mason2 scheduled tasks health.

$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
$baseDir   = Split-Path $scriptDir -Parent
$logDir    = Join-Path $baseDir "logs"

$logPath = Join-Path $logDir "task_health.log"
$timestamp = Get-Date

try {
    $tasks = Get-ScheduledTask -TaskPath "\Mason2\" -ErrorAction Stop
} catch {
    $tasks = @()
}

$records = @()
foreach ($t in $tasks) {
    $info = [pscustomobject]@{
        timestamp      = $timestamp.ToString("yyyy-MM-dd HH:mm:ss")
        TaskName       = $t.TaskName
        State          = $t.State.ToString()
        LastRunTime    = $t.LastRunTime
        LastTaskResult = $t.LastTaskResult
        NextRunTime    = $t.NextRunTime
    }
    $records += $info
}

if ($records.Count -gt 0) {
    foreach ($r in $records) {
        $r | ConvertTo-Json -Compress | Out-File -FilePath $logPath -Encoding UTF8 -Append
    }
}
