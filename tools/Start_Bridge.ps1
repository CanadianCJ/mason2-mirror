[CmdletBinding()]
param(
    [string]$RootPath = "",
    [int]$HealthTimeoutSeconds = 25
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-BridgeLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Start_Bridge] [$Level] $Message"
}

function Read-OpenAiKeyFromSecretsFile {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $null }

    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        if (-not $raw.Trim()) { return $null }
        $obj = $raw | ConvertFrom-Json -ErrorAction Stop

        if ($obj.PSObject.Properties.Name -contains "openai_api_key" -and $obj.openai_api_key) {
            return [string]$obj.openai_api_key
        }
        if ($obj.PSObject.Properties.Name -contains "OPENAI_API_KEY" -and $obj.OPENAI_API_KEY) {
            return [string]$obj.OPENAI_API_KEY
        }
        if ($obj.PSObject.Properties.Name -contains "openai" -and $obj.openai) {
            $openai = $obj.openai
            if ($openai.PSObject.Properties.Name -contains "api_key" -and $openai.api_key) {
                return [string]$openai.api_key
            }
        }
    }
    catch {
        Write-BridgeLog ("Could not parse secrets file metadata: {0}" -f $_.Exception.Message) "WARN"
    }

    return $null
}

function Resolve-BridgePython {
    param([string]$BridgeDir)

    $candidates = @(
        (Join-Path $BridgeDir ".venv\Scripts\python.exe"),
        (Join-Path $BridgeDir "venv\Scripts\python.exe")
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

function Get-BridgeHealth {
    param(
        [int]$Port,
        [string]$BindHost = "127.0.0.1"
    )

    $url = "http://{0}:{1}/health" -f $BindHost, $Port
    $result = [ordered]@{
        url                = $url
        ok                 = $false
        api_key_configured = $null
        status_code        = $null
    }

    try {
        $req = @{
            Uri         = $url
            Method      = "Get"
            TimeoutSec  = 3
            ErrorAction = "Stop"
        }
        if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey("UseBasicParsing")) {
            $req["UseBasicParsing"] = $true
        }

        $resp = Invoke-WebRequest @req
        $result.status_code = [int]$resp.StatusCode
        if ($resp.StatusCode -eq 200) {
            $result.ok = $true
            try {
                $json = $resp.Content | ConvertFrom-Json -ErrorAction Stop
                if ($json.PSObject.Properties.Name -contains "api_key_configured") {
                    $result.api_key_configured = [bool]$json.api_key_configured
                }
            }
            catch {
                # leave api_key_configured null
            }
        }
    }
    catch {
        $result.ok = $false
    }

    return [pscustomobject]$result
}

function Get-LastNonEmptyLine {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $lines = Get-Content -LiteralPath $Path -Encoding UTF8
        $nonEmpty = @($lines | Where-Object { $_ -and $_.Trim() })
        if ($nonEmpty.Count -gt 0) {
            return [string]$nonEmpty[-1]
        }
    }
    catch {
        return $null
    }
    return $null
}

function Write-BridgeStatusFile {
    param(
        [string]$Path,
        [hashtable]$Status
    )
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $Status | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $Path -Encoding UTF8
}

$scriptRoot = $PSScriptRoot
if (-not $scriptRoot) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $RootPath) {
    $RootPath = Split-Path -Parent $scriptRoot
}

$bridgeDir = Join-Path $RootPath "bridge"
$bridgeScript = Join-Path $bridgeDir "mason_bridge_server.py"
$reportsDir = Join-Path $RootPath "reports"
$startReportsDir = Join-Path $reportsDir "start"
$statusPath = Join-Path $reportsDir "bridge_status.json"
$secretsPath = Join-Path $RootPath "config\secrets_mason.json"

New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
New-Item -ItemType Directory -Path $startReportsDir -Force | Out-Null

$bindHost = "127.0.0.1"
if ($env:MASON_BIND_HOST) {
    $bindHost = [string]$env:MASON_BIND_HOST
}
if ($bindHost -ne "127.0.0.1") {
    throw "Bridge bind host must be 127.0.0.1."
}

$port = 8484
if ($env:MASON_BRIDGE_PORT) {
    $tmp = 0
    if ([int]::TryParse([string]$env:MASON_BRIDGE_PORT, [ref]$tmp) -and $tmp -gt 0) {
        $port = $tmp
    }
}
$env:MASON_BRIDGE_PORT = [string]$port

$apiKey = $null
$apiKeySource = $null
if ($env:OPENAI_API_KEY -and $env:OPENAI_API_KEY.Trim()) {
    $apiKey = [string]$env:OPENAI_API_KEY
    $apiKeySource = "env:OPENAI_API_KEY"
}
else {
    $apiKey = Read-OpenAiKeyFromSecretsFile -Path $secretsPath
    if ($apiKey -and $apiKey.Trim()) {
        $apiKeySource = "file:config/secrets_mason.json"
    }
}

$originalKey = $env:OPENAI_API_KEY
$originalKeyExists = ($null -ne $originalKey -and $originalKey.Trim())
if (-not $originalKeyExists -and $apiKey) {
    $env:OPENAI_API_KEY = $apiKey
}

$healthBefore = Get-BridgeHealth -Port $port -BindHost $bindHost
if ($healthBefore.ok) {
    $status = [ordered]@{
        generated_at_utc    = (Get-Date).ToUniversalTime().ToString("o")
        bridge_script       = $bridgeScript
        port                = $port
        running             = $true
        started_new_process = $false
        health_ok           = $true
        api_key_configured  = $healthBefore.api_key_configured
        api_key_source      = if ($apiKeySource) { $apiKeySource } else { "unknown_or_external" }
        last_error_line     = $null
    }
    Write-BridgeStatusFile -Path $statusPath -Status $status
    Write-BridgeLog ("Bridge already healthy on {0}" -f $healthBefore.url)
    if (-not $originalKeyExists) {
        Remove-Item Env:OPENAI_API_KEY -ErrorAction SilentlyContinue
    }
    return
}

if (-not (Test-Path -LiteralPath $bridgeScript)) {
    $status = [ordered]@{
        generated_at_utc    = (Get-Date).ToUniversalTime().ToString("o")
        bridge_script       = $bridgeScript
        port                = $port
        running             = $false
        started_new_process = $false
        health_ok           = $false
        api_key_configured  = [bool]($apiKey -and $apiKey.Trim())
        api_key_source      = $apiKeySource
        last_error_line     = "Bridge script missing."
    }
    Write-BridgeStatusFile -Path $statusPath -Status $status
    throw "Bridge script missing: $bridgeScript"
}

$pythonExe = Resolve-BridgePython -BridgeDir $bridgeDir
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$stdoutLog = Join-Path $startReportsDir ("bridge_{0}_stdout.log" -f $stamp)
$stderrLog = Join-Path $startReportsDir ("bridge_{0}_stderr.log" -f $stamp)

Write-BridgeLog ("Starting bridge on http://{0}:{1}" -f $bindHost, $port)

$bridgeProc = $null
$lastErrorLine = $null
try {
    $bridgeProc = Start-Process -FilePath $pythonExe -ArgumentList @("-u", $bridgeScript) -WorkingDirectory $bridgeDir -WindowStyle Minimized -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog -PassThru
}
catch {
    $lastErrorLine = $_.Exception.Message
}
finally {
    if (-not $originalKeyExists) {
        Remove-Item Env:OPENAI_API_KEY -ErrorAction SilentlyContinue
    }
}

$healthOk = $false
$health = $null
$apiKeyConfigured = $null
$running = $false
$bridgePid = $null

if ($bridgeProc) {
    $bridgePid = [int]$bridgeProc.Id
    $deadline = (Get-Date).AddSeconds($HealthTimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $running = [bool](Get-Process -Id $bridgePid -ErrorAction SilentlyContinue)
        if (-not $running) { break }

        $health = Get-BridgeHealth -Port $port -BindHost $bindHost
        if ($health.ok) {
            $healthOk = $true
            $apiKeyConfigured = $health.api_key_configured
            break
        }

        Start-Sleep -Seconds 1
    }

    if (-not $healthOk) {
        $health = Get-BridgeHealth -Port $port -BindHost $bindHost
        $healthOk = [bool]$health.ok
        if ($health.PSObject.Properties.Name -contains "api_key_configured") {
            $apiKeyConfigured = $health.api_key_configured
        }
    }

    $running = [bool](Get-Process -Id $bridgePid -ErrorAction SilentlyContinue)
}

if (-not $lastErrorLine) {
    $lastErrorLine = Get-LastNonEmptyLine -Path $stderrLog
}

$statusObj = [ordered]@{
    generated_at_utc    = (Get-Date).ToUniversalTime().ToString("o")
    bridge_script       = $bridgeScript
    python_exe          = $pythonExe
    port                = $port
    pid                 = $bridgePid
    running             = $running
    started_new_process = [bool]$bridgeProc
    health_url          = "http://$bindHost`:$port/health"
    health_ok           = $healthOk
    api_key_configured  = if ($null -ne $apiKeyConfigured) { [bool]$apiKeyConfigured } else { [bool]($apiKey -and $apiKey.Trim()) }
    api_key_source      = $apiKeySource
    stdout_log          = $stdoutLog
    stderr_log          = $stderrLog
    last_error_line     = $lastErrorLine
}

Write-BridgeStatusFile -Path $statusPath -Status $statusObj
Write-BridgeLog ("Status report written: {0}" -f $statusPath)
if (-not $healthOk) {
    Write-BridgeLog ("Bridge health did not become ready within timeout. stderr={0}" -f $stderrLog) "WARN"
    throw ("Bridge failed readiness probe at http://{0}:{1}/health. See logs: {2}" -f $bindHost, $port, $stderrLog)
}
