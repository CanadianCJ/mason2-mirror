[CmdletBinding()]
param(
    [string]$RootPath = ""
)

$ErrorActionPreference = "Stop"

function Write-QueueLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Mason_Tasks_To_Approvals] [$Level] $Message"
}

function To-Array {
    param($Value)

    if ($null -eq $Value) { return @() }
    if ($Value -is [System.Array]) { return $Value }
    return @($Value)
}

function Invoke-QueueScript {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [hashtable]$NamedArguments = @{}
    )

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        Write-QueueLog "Queue script missing: $ScriptPath" "WARN"
        return
    }

    Write-QueueLog ("Running {0}" -f (Split-Path -Leaf $ScriptPath))
    & $ScriptPath @NamedArguments
}

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $RootPath) {
    $RootPath = Split-Path -Parent $scriptRoot
}

$toolsDir = Join-Path $RootPath "tools"
$stateDir = Join-Path $RootPath "state\knowledge"
$configDir = Join-Path $RootPath "config"

$teacherScript = Join-Path $toolsDir "Mason_Teacher_Queue_Suggestions.ps1"
$onyxScript = Join-Path $toolsDir "Mason_Onyx_Tasks_To_Approvals.ps1"
$pendingPath = Join-Path $stateDir "pending_patch_runs.json"
$riskPolicyPath = Join-Path $configDir "risk_policy.json"

if (-not (Test-Path -LiteralPath $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $pendingPath)) {
    "[]" | Set-Content -LiteralPath $pendingPath -Encoding UTF8
}

if (Test-Path -LiteralPath $riskPolicyPath) {
    try {
        $riskPolicy = Get-Content -LiteralPath $riskPolicyPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($riskPolicy.global.money_loop_enabled) {
            Write-QueueLog "risk_policy.global.money_loop_enabled is true; queueing continues, no auto-approval performed." "WARN"
        }
        if ($riskPolicy.global.high_risk_auto_apply) {
            Write-QueueLog "risk_policy.global.high_risk_auto_apply is true; queueing continues, no auto-approval performed." "WARN"
        }
    }
    catch {
        Write-QueueLog "Could not parse risk policy: $($_.Exception.Message)" "WARN"
    }
}

Invoke-QueueScript -ScriptPath $teacherScript -NamedArguments @{ RootDir = $RootPath }
Invoke-QueueScript -ScriptPath $onyxScript -NamedArguments @{ RootPath = $RootPath }

$raw = Get-Content -LiteralPath $pendingPath -Raw -Encoding UTF8
$parsed = @()
if ($raw.Trim()) {
    try {
        $parsed = To-Array ($raw | ConvertFrom-Json -ErrorAction Stop)
    }
    catch {
        throw "Invalid JSON in pending approvals file: $pendingPath"
    }
}

$seen = @{}
$deduped = New-Object System.Collections.Generic.List[object]
$duplicatesRemoved = 0

foreach ($item in $parsed) {
    if ($null -eq $item) { continue }

    $id = ""
    if ($item.PSObject.Properties.Name -contains "id" -and $item.id) {
        $id = [string]$item.id
    }

    if (-not $id.Trim()) {
        $deduped.Add($item)
        continue
    }

    if ($seen.ContainsKey($id)) {
        $duplicatesRemoved++
        continue
    }

    $seen[$id] = $true
    $deduped.Add($item)
}

$deduped | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $pendingPath -Encoding UTF8

Write-QueueLog ("Queued + deduped approvals. Total={0}, duplicates_removed={1}" -f $deduped.Count, $duplicatesRemoved)
Write-QueueLog ("Updated: {0}" -f $pendingPath)
