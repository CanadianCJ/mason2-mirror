# Start_Mason_Onyx_Stack.ps1
# One-shot launcher for Mason core stack + self-improvement + Onyx + Athena

[CmdletBinding()]
param(
    [switch]$UseToolsMasonStartAll
)

$ErrorActionPreference = "Stop"

# ---------- Paths ----------
# Base is the Mason2 folder (this script should live there)
$Base = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $Base) { $Base = (Get-Location).Path }

$ToolsDir   = Join-Path $Base "tools"
$BridgeDir  = Join-Path $Base "bridge"
$OnyxDir    = Join-Path $Base "Component - Onyx App\onyx_business_manager"
$AthenaDir  = Join-Path $Base "athena"
$LogsDir    = Join-Path $Base "logs"

# Mason scripts
$RootCoreStackScript   = Join-Path $Base "Start_All.ps1"
$ToolsCoreStackScript  = Join-Path $ToolsDir "Mason_Start_All.ps1"
$SelfImproveLoopScript = Join-Path $ToolsDir "Mason_SelfImprove_Loop.ps1"

# Bridge / Athena python entry points
$BridgeScriptPy  = Join-Path $BridgeDir "mason_bridge_server.py"
$AthenaServerPy  = "C:\Users\Chris\Desktop\Mason2\athena\server.py"
$AthenaWebDir    = Join-Path $AthenaDir "web"
$AthenaWebIndex  = Join-Path $AthenaWebDir "index.html"
$AthenaWebBackup = "C:\Users\Chris\Dropbox\Chrisjlkeeler Team Folder\Mason2\athena\web\index.html"

# Onyx entry point
$OnyxStartScript = Join-Path $OnyxDir "Start-Onyx5353.ps1"

# URLs for UIs
$AthenaUrl       = "http://127.0.0.1:8000/"
$OnyxUrl         = "http://127.0.0.1:5353/"
$AthenaHealthUrl = "http://127.0.0.1:8000/api/health"
$OnyxHealthUrl   = "http://127.0.0.1:5353/flutter_bootstrap.js"

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OnyxStdoutLog = Join-Path $LogsDir ("onyx_stdout_{0}.log" -f $Timestamp)
$OnyxStderrLog = Join-Path $LogsDir ("onyx_stderr_{0}.log" -f $Timestamp)
$StackSummaryLog = Join-Path $LogsDir ("stack_start_{0}.txt" -f $Timestamp)
$StateKnowledgeDir = Join-Path $Base "state\knowledge"
$StackPidStatePath = Join-Path $StateKnowledgeDir "stack_pids.json"
$StartTimestampUtc = ([DateTime]::UtcNow).ToString("o")
$StackPidState = [ordered]@{
    mason_core_pid   = $null
    self_improve_pid = $null
    bridge_pid       = $null
    athena_pid       = $null
    onyx_pid         = $null
    timestamp        = $StartTimestampUtc
    created_at_utc   = $StartTimestampUtc
    start_log_path   = $StackSummaryLog
}

# ---------- Helpers ----------

function Start-ChildPsCommand {
    param(
        [Parameter(Mandatory = $true)][string] $Command,
        [Parameter(Mandatory = $true)][string] $WorkingDirectory,
        [string] $Label = "Starting child process"
    )

    Write-Host "[Stack] $Label" -ForegroundColor Cyan
    return Start-Process powershell.exe -WindowStyle Minimized -WorkingDirectory $WorkingDirectory -ArgumentList @(
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-Command", $Command
    ) -PassThru
}

function Start-ChildPsScript {
    param(
        [Parameter(Mandatory = $true)][string] $ScriptPath,
        [Parameter(Mandatory = $true)][string] $WorkingDirectory,
        [string] $Label = "Starting child script"
    )

    Write-Host "[Stack] $Label" -ForegroundColor Cyan
    return Start-Process powershell.exe -WindowStyle Minimized -WorkingDirectory $WorkingDirectory -ArgumentList @(
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $ScriptPath
    ) -PassThru
}

function Warn-Missing {
    param([string] $What, [string] $Path)
    Write-Warning "[Stack] $What not found at: $Path"
}

function Ensure-AthenaWebIndex {
    param(
        [Parameter(Mandatory = $true)][string] $WebDir,
        [Parameter(Mandatory = $true)][string] $WebIndex,
        [string] $BackupIndex
    )

    if (-not (Test-Path $WebDir)) {
        New-Item -ItemType Directory -Path $WebDir -Force | Out-Null
    }

    if (Test-Path $WebIndex) {
        return
    }

    if ($BackupIndex -and (Test-Path $BackupIndex)) {
        Copy-Item -Path $BackupIndex -Destination $WebIndex -Force
        Write-Host "[Stack] Restored Athena web index from backup: $BackupIndex" -ForegroundColor Yellow
        return
    }

    Set-Content -Path $WebIndex -Encoding UTF8 -Value @(
        '<!doctype html>',
        '<html>',
        '<head><meta charset="utf-8"><title>Athena</title></head>',
        '<body><h1>Athena</h1></body>',
        '</html>'
    )
    Write-Warning "[Stack] Athena web index was missing; created placeholder at: $WebIndex"
}

function Test-Http200 {
    param([Parameter(Mandatory = $true)][string] $Url)

    try {
        $requestParams = @{
            Uri         = $Url
            Method      = "Get"
            TimeoutSec  = 5
            ErrorAction = "Stop"
        }

        if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey("UseBasicParsing")) {
            $requestParams["UseBasicParsing"] = $true
        }

        $response = Invoke-WebRequest @requestParams
        return ($response.StatusCode -eq 200)
    } catch {
        return $false
    }
}

function Wait-ForReadiness {
    param(
        [Parameter(Mandatory = $true)][string] $AthenaCheckUrl,
        [Parameter(Mandatory = $true)][string] $OnyxCheckUrl,
        [int] $TimeoutSeconds = 90,
        [int] $PollSeconds = 2
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $athenaReady = $false
    $onyxReady = $false

    while ((Get-Date) -lt $deadline) {
        if (-not $athenaReady) {
            $athenaReady = Test-Http200 -Url $AthenaCheckUrl
        }

        if (-not $onyxReady) {
            $onyxReady = Test-Http200 -Url $OnyxCheckUrl
        }

        if ($athenaReady -and $onyxReady) {
            break
        }

        Start-Sleep -Seconds $PollSeconds
    }

    return [PSCustomObject]@{
        Athena = $athenaReady
        Onyx   = $onyxReady
    }
}

function Save-StackPidState {
    param(
        [Parameter(Mandatory = $true)][System.Collections.IDictionary] $StackPidState,
        [Parameter(Mandatory = $true)][string] $KnowledgeDir,
        [Parameter(Mandatory = $true)][string] $PidStatePath
    )

    if (-not (Test-Path $KnowledgeDir)) {
        New-Item -ItemType Directory -Path $KnowledgeDir -Force | Out-Null
    }

    $json = $StackPidState | ConvertTo-Json -Depth 5
    Set-Content -Path $PidStatePath -Encoding UTF8 -Value $json
    Write-Host "[Stack] PID state written: $PidStatePath"
}

if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

Write-Host "=== Mason + Onyx + Athena stack launcher ===" -ForegroundColor Green
Write-Host "Base    : $Base"
Write-Host "Tools   : $ToolsDir"
Write-Host "OnyxDir : $OnyxDir"
Write-Host "Athena  : $AthenaDir"
Write-Host "Logs    : $LogsDir"
Write-Host ""

Save-StackPidState -StackPidState $StackPidState -KnowledgeDir $StateKnowledgeDir -PidStatePath $StackPidStatePath

# ---------- 1) Mason core stack ----------

if ($UseToolsMasonStartAll -and -not (Test-Path $ToolsCoreStackScript)) {
    Warn-Missing "Requested tools\Mason_Start_All.ps1" $ToolsCoreStackScript
}

$CoreStackScript = $RootCoreStackScript
$CoreStackWorkingDir = $Base
$CoreStackLabel = "Start_All.ps1"

if ($UseToolsMasonStartAll -and (Test-Path $ToolsCoreStackScript)) {
    $CoreStackScript = $ToolsCoreStackScript
    $CoreStackWorkingDir = $ToolsDir
    $CoreStackLabel = "tools\Mason_Start_All.ps1"
}

if (Test-Path $CoreStackScript) {
    $coreProcess = Start-ChildPsScript -ScriptPath $CoreStackScript -WorkingDirectory $CoreStackWorkingDir -Label "Launching Mason core stack ($CoreStackLabel)..."
    if ($coreProcess) {
        $StackPidState["mason_core_pid"] = [int]$coreProcess.Id
        Save-StackPidState -StackPidState $StackPidState -KnowledgeDir $StateKnowledgeDir -PidStatePath $StackPidStatePath
        Write-Host "[Stack] mason_core_pid: $($coreProcess.Id)"
    }
} else {
    Warn-Missing "Mason core stack script ($CoreStackLabel)" $CoreStackScript
}

# ---------- 2) Mason self-improvement loop ----------

if (Test-Path $SelfImproveLoopScript) {
    $selfImproveProcess = Start-ChildPsScript -ScriptPath $SelfImproveLoopScript -WorkingDirectory $ToolsDir -Label "Launching Mason self-improvement loop..."
    if ($selfImproveProcess) {
        $StackPidState["self_improve_pid"] = [int]$selfImproveProcess.Id
        Save-StackPidState -StackPidState $StackPidState -KnowledgeDir $StateKnowledgeDir -PidStatePath $StackPidStatePath
        Write-Host "[Stack] self_improve_pid: $($selfImproveProcess.Id)"
    }
} else {
    Warn-Missing "Mason_SelfImprove_Loop.ps1" $SelfImproveLoopScript
}

# ---------- 3) Mason bridge server ----------

if (Test-Path $BridgeScriptPy) {
    $cmd = "python `"$BridgeScriptPy`""
    $bridgeProcess = Start-ChildPsCommand -Command $cmd -WorkingDirectory $BridgeDir -Label "Launching Mason bridge server (mason_bridge_server.py)..."
    if ($bridgeProcess) {
        $StackPidState["bridge_pid"] = [int]$bridgeProcess.Id
        Save-StackPidState -StackPidState $StackPidState -KnowledgeDir $StateKnowledgeDir -PidStatePath $StackPidStatePath
        Write-Host "[Stack] bridge_pid: $($bridgeProcess.Id)"
    }
} else {
    Warn-Missing "Bridge script (mason_bridge_server.py)" $BridgeScriptPy
}

# ---------- 4) Onyx app ----------

if (Test-Path $OnyxStartScript) {
    Write-Host "[Stack] Launching Onyx via Start-Onyx5353.ps1..." -ForegroundColor Cyan
    $OnyxStartScriptArg = "`"$OnyxStartScript`""
    $onyxProcess = Start-Process powershell.exe -WindowStyle Minimized -WorkingDirectory $OnyxDir -ArgumentList @(
        "-NoLogo",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", $OnyxStartScriptArg
    ) -RedirectStandardOutput $OnyxStdoutLog -RedirectStandardError $OnyxStderrLog -PassThru
    if ($onyxProcess) {
        $StackPidState["onyx_pid"] = [int]$onyxProcess.Id
        Save-StackPidState -StackPidState $StackPidState -KnowledgeDir $StateKnowledgeDir -PidStatePath $StackPidStatePath
        Write-Host "[Stack] onyx_pid: $($onyxProcess.Id)"
    }
    Write-Host "[Stack] Onyx logs:"
    Write-Host "        stdout -> $OnyxStdoutLog"
    Write-Host "        stderr -> $OnyxStderrLog"
} else {
    Warn-Missing "Onyx start script (Start-Onyx5353.ps1)" $OnyxStartScript
}

# ---------- 5) Athena backend ----------

Ensure-AthenaWebIndex -WebDir $AthenaWebDir -WebIndex $AthenaWebIndex -BackupIndex $AthenaWebBackup

if (Test-Path $AthenaServerPy) {
    $cmd = "python `"$AthenaServerPy`""
    $athenaProcess = Start-ChildPsCommand -Command $cmd -WorkingDirectory $AthenaDir -Label "Launching Athena backend (server.py)..."
    if ($athenaProcess) {
        $StackPidState["athena_pid"] = [int]$athenaProcess.Id
        Save-StackPidState -StackPidState $StackPidState -KnowledgeDir $StateKnowledgeDir -PidStatePath $StackPidStatePath
        Write-Host "[Stack] athena_pid: $($athenaProcess.Id)"
    }
} else {
    Warn-Missing "Athena server script (server.py)" $AthenaServerPy
}

# ---------- 6) Readiness gating ----------

Write-Host ""
Write-Host "[Stack] Waiting up to 90s for readiness checks..." -ForegroundColor Cyan
Write-Host "        Athena: $AthenaHealthUrl"
Write-Host "        Onyx  : $OnyxHealthUrl"

$readiness = Wait-ForReadiness -AthenaCheckUrl $AthenaHealthUrl -OnyxCheckUrl $OnyxHealthUrl -TimeoutSeconds 90

$AthenaStatus = if ($readiness.Athena) { "PASS" } else { "FAIL" }
$OnyxStatus = if ($readiness.Onyx) { "PASS" } else { "FAIL" }
$OverallStatus = if ($readiness.Athena -and $readiness.Onyx) { "PASS" } else { "FAIL" }

$summaryLines = @(
    "Stack Start Summary"
    "Timestamp: $(Get-Date -Format o)"
    "Base: $Base"
    "Mason core script: $CoreStackScript"
    "Athena health ($AthenaHealthUrl): $AthenaStatus"
    "Onyx health ($OnyxHealthUrl): $OnyxStatus"
    "Overall readiness: $OverallStatus"
    "Onyx stdout log: $OnyxStdoutLog"
    "Onyx stderr log: $OnyxStderrLog"
)
Set-Content -Path $StackSummaryLog -Encoding UTF8 -Value $summaryLines

Write-Host "[Stack] Summary log: $StackSummaryLog"
Write-Host "[Stack] Athena readiness: $AthenaStatus"
Write-Host "[Stack] Onyx readiness  : $OnyxStatus"

# ---------- 7) Open UIs only after readiness ----------

if ($readiness.Athena -and $readiness.Onyx) {
    Write-Host "[Stack] Opening Athena and Onyx in your browser..." -ForegroundColor Cyan
    Start-Process $AthenaUrl | Out-Null
    Start-Process $OnyxUrl   | Out-Null
} else {
    Write-Warning "[Stack] Browser tabs not opened because readiness checks did not pass for both services."
}

Write-Host ""
Write-Host "[Stack] Launch complete. All child windows will keep running even if you close this one." -ForegroundColor Green
