[CmdletBinding()]
param(
    [int]$TailLines = 120
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-ShowLog {
    param([string]$Message)
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$stamp] [Show_Last_Start_Failures] $Message"
}

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptRoot)
$startReportsDir = Join-Path $repoRoot "reports\start"
$lastFailurePath = Join-Path $startReportsDir "last_failure.json"

Write-ShowLog ("Repo root: {0}" -f $repoRoot)
Write-Host ""
Write-Host "=== reports/start/last_failure.json ==="
if (Test-Path -LiteralPath $lastFailurePath) {
    Get-Content -LiteralPath $lastFailurePath -Raw -Encoding UTF8
}
else {
    Write-Host "MISSING: $lastFailurePath"
}

Write-Host ""
Write-Host "=== newest reports/start/*stderr*.log tail ==="
$newestStderr = Get-ChildItem -LiteralPath $startReportsDir -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "*stderr*.log" } |
    Sort-Object LastWriteTimeUtc -Descending |
    Select-Object -First 1
if ($newestStderr) {
    Write-Host ("File: {0}" -f $newestStderr.FullName)
    Get-Content -LiteralPath $newestStderr.FullName -Tail ([Math]::Max(1, [int]$TailLines)) -ErrorAction SilentlyContinue
}
else {
    Write-Host "No stderr logs found in $startReportsDir"
}

Write-Host ""
Write-Host "=== listening ports (8383, 8109, 8484, 8000, 5353) ==="
$targetPorts = @(8383, 8109, 8484, 8000, 5353)
$portRows = New-Object System.Collections.Generic.List[object]
foreach ($port in $targetPorts) {
    $listeners = @()
    try {
        $listeners = @(Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue)
    }
    catch {
        $listeners = @()
    }

    if (@($listeners).Count -eq 0) {
        $portRows.Add([pscustomobject]@{
            LocalAddress  = "-"
            LocalPort     = [int]$port
            OwningProcess = "-"
        }) | Out-Null
        continue
    }

    foreach ($row in @($listeners)) {
        $portRows.Add([pscustomobject]@{
            LocalAddress  = [string]$row.LocalAddress
            LocalPort     = [int]$row.LocalPort
            OwningProcess = [int]$row.OwningProcess
        }) | Out-Null
    }
}

if ($portRows.Count -gt 0) {
    $portRows.ToArray() | Sort-Object LocalPort, OwningProcess | Format-Table -AutoSize
}
else {
    Write-Host "No data."
}

