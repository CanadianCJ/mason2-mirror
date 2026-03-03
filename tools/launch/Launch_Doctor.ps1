[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptDir '..\..'))
$launcherDir = Join-Path $repoRoot 'reports\launcher'
$lastFullstackPath = Join-Path $launcherDir 'last_fullstack.json'

Write-Host '=== Mason Launch Doctor ==='
Write-Host ('Repo root: {0}' -f $repoRoot)
Write-Host ('Launcher log dir: {0}' -f $launcherDir)

if (Test-Path -LiteralPath $lastFullstackPath) {
    try {
        $last = Get-Content -LiteralPath $lastFullstackPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        Write-Host 'last_fullstack.json summary:'
        Write-Host ('  started_at: {0}' -f $last.started_at)
        Write-Host ('  success: {0}' -f $last.success)
        Write-Host ('  log_path: {0}' -f $last.log_path)
        Write-Host ('  error_summary: {0}' -f $last.error_summary)
    }
    catch {
        Write-Host ("last_fullstack.json exists but could not be parsed: {0}" -f $_.Exception.Message)
    }
}
else {
    Write-Host 'last_fullstack.json summary: not found'
}

$newestFullstackLog = Get-ChildItem -Path $launcherDir -Filter 'fullstack_*.log' -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($newestFullstackLog) {
    Write-Host ('Newest fullstack log: {0}' -f $newestFullstackLog.FullName)
}
else {
    Write-Host 'Newest fullstack log: none found'
}

$ports = @(8383, 8109, 8484, 8000, 5353)
$rows = New-Object System.Collections.Generic.List[object]
$canCheckTcp = [bool](Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue)

foreach ($port in $ports) {
    if (-not $canCheckTcp) {
        $rows.Add([pscustomobject]@{
            Port = $port
            State = 'unknown'
            PID = ''
            Process = 'Get-NetTCPConnection unavailable'
        })
        continue
    }

    $listeners = @(Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue)
    if ($listeners.Count -eq 0) {
        $rows.Add([pscustomobject]@{
            Port = $port
            State = 'not_listening'
            PID = ''
            Process = ''
        })
        continue
    }

    $pidList = @($listeners | Select-Object -ExpandProperty OwningProcess -Unique | Sort-Object)
    foreach ($pid in $pidList) {
        $processName = '(exited)'
        try {
            $processName = (Get-Process -Id $pid -ErrorAction Stop).ProcessName
        }
        catch {
            $processName = '(exited)'
        }

        $rows.Add([pscustomobject]@{
            Port = $port
            State = 'listening'
            PID = [int]$pid
            Process = $processName
        })
    }
}

Write-Host 'Port listeners (8383, 8109, 8484, 8000, 5353):'
$rows | Sort-Object Port, PID | Format-Table -AutoSize

