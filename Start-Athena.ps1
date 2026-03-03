[CmdletBinding()]
param(
    [string]$RootPath = "",
    [int]$ReadinessTimeoutSeconds = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-PortsContract {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if (-not $raw.Trim()) {
        return $null
    }
    try {
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $null
    }
}

function Resolve-MasonConsolePython {
    param([string]$ConsoleDir)

    $candidates = @(
        (Join-Path $ConsoleDir ".venv\Scripts\python.exe"),
        (Join-Path $ConsoleDir "venv\Scripts\python.exe")
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        return $pythonCmd.Source
    }
    return "python"
}

function Test-Endpoint {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSec = 4
    )

    try {
        $req = @{
            Uri         = $Url
            Method      = "Get"
            TimeoutSec  = $TimeoutSec
            ErrorAction = "Stop"
        }
        if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey("UseBasicParsing")) {
            $req["UseBasicParsing"] = $true
        }
        $resp = Invoke-WebRequest @req
        return ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400)
    }
    catch {
        return $false
    }
}

function Get-LogTailChars {
    param(
        [string]$Path,
        [int]$MaxChars = 200
    )

    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if (-not $raw) {
            return $null
        }
        if ($raw.Length -le $MaxChars) {
            return $raw
        }
        return $raw.Substring($raw.Length - $MaxChars)
    }
    catch {
        return $null
    }
}

if (-not $RootPath) {
    $RootPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    if (-not $RootPath) {
        $RootPath = (Get-Location).Path
    }
}

$MasonRoot = [System.IO.Path]::GetFullPath($RootPath)
$ConsoleRoot = Join-Path $MasonRoot "MasonConsole"
$portsPath = Join-Path $MasonRoot "config\ports.json"
$portsConfig = Read-PortsContract -Path $portsPath

$bindHost = "127.0.0.1"
$athenaPort = 8000
if ($portsConfig) {
    if ($portsConfig.bind_host) {
        $bindHost = [string]$portsConfig.bind_host
    }
    if ($portsConfig.ports -and ($portsConfig.ports.PSObject.Properties.Name -contains "athena")) {
        $tmpPort = 0
        if ([int]::TryParse([string]$portsConfig.ports.athena, [ref]$tmpPort) -and $tmpPort -gt 0 -and $tmpPort -le 65535) {
            $athenaPort = $tmpPort
        }
    }
}

if ($env:MASON_BIND_HOST) {
    $bindHost = [string]$env:MASON_BIND_HOST
}
if ($env:MASON_ATHENA_PORT) {
    $tmpPort = 0
    if ([int]::TryParse([string]$env:MASON_ATHENA_PORT, [ref]$tmpPort) -and $tmpPort -gt 0 -and $tmpPort -le 65535) {
        $athenaPort = $tmpPort
    }
}

if ($bindHost -ne "127.0.0.1") {
    throw "Athena bind host must be 127.0.0.1."
}
if (-not (Test-Path -LiteralPath $ConsoleRoot)) {
    throw "MasonConsole directory missing: $ConsoleRoot"
}

$reportsDir = Join-Path $MasonRoot "reports"
$startReportsDir = Join-Path $reportsDir "start"
New-Item -ItemType Directory -Path $startReportsDir -Force | Out-Null

$runId = if ($env:MASON_START_RUN_ID) { [string]$env:MASON_START_RUN_ID } else { (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss_fff") }
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$stdoutLog = Join-Path $startReportsDir ("athena_{0}_{1}_stdout.log" -f $runId, $stamp)
$stderrLog = Join-Path $startReportsDir ("athena_{0}_{1}_stderr.log" -f $runId, $stamp)
$healthUrl = "http://{0}:{1}/api/health" -f $bindHost, $athenaPort

if (Test-Endpoint -Url $healthUrl -TimeoutSec 3) {
    Write-Host ("[Athena] Already healthy on {0}" -f $healthUrl) -ForegroundColor Cyan
    return
}

$pythonExe = Resolve-MasonConsolePython -ConsoleDir $ConsoleRoot
Write-Host ("[Athena] Starting Athena API on {0} using {1}" -f $healthUrl, $pythonExe) -ForegroundColor Cyan

Set-Location -LiteralPath $ConsoleRoot

$athenaProc = Start-Process `
    -FilePath $pythonExe `
    -ArgumentList @("-m", "uvicorn", "server:app", "--host", $bindHost, "--port", [string]$athenaPort) `
    -WorkingDirectory $ConsoleRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput $stdoutLog `
    -RedirectStandardError $stderrLog `
    -PassThru

$deadline = (Get-Date).AddSeconds([Math]::Max(5, $ReadinessTimeoutSeconds))
$healthy = $false
while ((Get-Date) -lt $deadline) {
    if (Test-Endpoint -Url $healthUrl -TimeoutSec 3) {
        $healthy = $true
        break
    }

    $alive = [bool](Get-Process -Id $athenaProc.Id -ErrorAction SilentlyContinue)
    if (-not $alive) {
        break
    }
    Start-Sleep -Seconds 1
}

if (-not $healthy) {
    $stderrTail = Get-LogTailChars -Path $stderrLog -MaxChars 200
    $stdoutTail = Get-LogTailChars -Path $stdoutLog -MaxChars 200
    throw ("Athena failed readiness at {0}. stderr={1}; stderr_tail_200={2}; stdout_tail_200={3}" -f $healthUrl, $stderrLog, $stderrTail, $stdoutTail)
}

Wait-Process -Id $athenaProc.Id
if ($athenaProc.HasExited -and $athenaProc.ExitCode -ne 0) {
    $stderrTail = Get-LogTailChars -Path $stderrLog -MaxChars 200
    throw ("Athena process exited with code {0}. stderr={1}; stderr_tail_200={2}" -f $athenaProc.ExitCode, $stderrLog, $stderrTail)
}
