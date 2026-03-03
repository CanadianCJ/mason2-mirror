[CmdletBinding()]
param(
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-RepoRoot {
    param([string]$CandidateRoot)
    if ($CandidateRoot -and (Test-Path -LiteralPath $CandidateRoot)) {
        return (Resolve-Path -LiteralPath $CandidateRoot).Path
    }
    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Object,
        [int]$Depth = 14
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $Object | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Get-ListeningPid {
    param([int]$Port)

    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        try {
            $row = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop | Select-Object -First 1
            if ($row -and $row.OwningProcess) {
                return [int]$row.OwningProcess
            }
        }
        catch {
            # fallback below
        }
    }

    $lines = netstat -ano -p tcp
    foreach ($line in $lines) {
        if ($line -match "^\s*TCP\s+\S+:(\d+)\s+\S+\s+LISTENING\s+(\d+)") {
            $lp = 0
            $ownerPid = 0
            [int]::TryParse($Matches[1], [ref]$lp) | Out-Null
            [int]::TryParse($Matches[2], [ref]$ownerPid) | Out-Null
            if ($lp -eq $Port -and $ownerPid -gt 0) {
                return $ownerPid
            }
        }
    }

    return $null
}

function Invoke-HttpCheck {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [int]$TimeoutSec = 6
    )

    try {
        $resp = Invoke-WebRequest -Uri $Url -Method Get -UseBasicParsing -TimeoutSec $TimeoutSec -ErrorAction Stop
        return [pscustomobject]@{
            ok          = $true
            status_code = [int]$resp.StatusCode
            body        = [string]$resp.Content
            error       = $null
        }
    }
    catch {
        $statusCode = $null
        $body = $null
        if ($_.Exception.Response) {
            try {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
            catch {
                $statusCode = $null
            }
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $body = $reader.ReadToEnd()
                $reader.Close()
            }
            catch {
                $body = $null
            }
        }

        return [pscustomobject]@{
            ok          = $false
            status_code = $statusCode
            body        = $body
            error       = $_.Exception.Message
        }
    }
}

function Resolve-MasonConsolePython {
    param([string]$ConsoleDir)

    $candidates = @(
        (Join-Path $ConsoleDir ".venv\Scripts\python.exe"),
        (Join-Path $ConsoleDir "venv\Scripts\python.exe"),
        "python"
    )

    foreach ($candidate in $candidates) {
        if ($candidate -eq "python") {
            return $candidate
        }
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return "python"
}

function Get-TailnetIp {
    try {
        $ts = & tailscale ip -4 2>$null
        foreach ($line in $ts) {
            $v = ([string]$line).Trim()
            if ($v -match "^100\.") {
                return $v
            }
        }
    }
    catch {
        # fallback below
    }

    try {
        $ipcfg = ipconfig
        foreach ($line in $ipcfg) {
            if ($line -match "(\d+\.\d+\.\d+\.\d+)") {
                $ip = [string]$Matches[1]
                if ($ip.StartsWith("100.")) {
                    return $ip
                }
            }
        }
    }
    catch {
        return $null
    }

    return $null
}

$repoRoot = Resolve-RepoRoot -CandidateRoot $RootPath
$reportsDir = Join-Path $repoRoot "reports"
$reportPath = Join-Path $reportsDir "activate_athena_8000_report.json"
$stdoutLog = Join-Path $reportsDir "masonconsole_8000_stdout.log"
$stderrLog = Join-Path $reportsDir "masonconsole_8000_stderr.log"
$consoleDir = Join-Path $repoRoot "MasonConsole"

$result = [ordered]@{
    started_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    repo_root      = $repoRoot
    previous_pid   = $null
    stop_result    = [ordered]@{
        attempted           = $false
        stopped             = $false
        elevation_required  = $false
        error               = $null
    }
    start_pid      = $null
    smoke_results  = [ordered]@{
        health         = $null
        athena_pwa     = $null
        status_unsigned = $null
        version        = $null
    }
    local_url      = "http://127.0.0.1:8000/athena/"
    tailnet_url    = $null
    stdout_log     = $stdoutLog
    stderr_log     = $stderrLog
    ok             = $false
}
$initialTailnetIp = Get-TailnetIp
if ($initialTailnetIp) {
    $result.tailnet_url = "http://$initialTailnetIp`:8000/athena/"
}

if (-not (Test-Path -LiteralPath $consoleDir)) {
    $result.stop_result.error = "missing_masonconsole_dir"
    Write-JsonFile -Path $reportPath -Object $result
    exit 1
}

$existingPid = Get-ListeningPid -Port 8000
$result.previous_pid = $existingPid

if ($existingPid) {
    $result.stop_result.attempted = $true
    try {
        Stop-Process -Id $existingPid -Force -ErrorAction Stop
        Start-Sleep -Seconds 1
        $still = Get-ListeningPid -Port 8000
        $result.stop_result.stopped = ($null -eq $still)
        if (-not $result.stop_result.stopped) {
            $result.stop_result.error = "listener_still_active"
        }
    }
    catch {
        $result.stop_result.stopped = $false
        $result.stop_result.error = $_.Exception.Message
        if ($_.Exception.Message -match "Access is denied") {
            $result.stop_result.elevation_required = $true
        }
    }

    if (-not $result.stop_result.stopped) {
        Write-JsonFile -Path $reportPath -Object $result
        if ($result.stop_result.elevation_required) {
            exit 2
        }
        exit 1
    }
}

if (Test-Path -LiteralPath $stdoutLog) { Remove-Item -LiteralPath $stdoutLog -Force -ErrorAction SilentlyContinue }
if (Test-Path -LiteralPath $stderrLog) { Remove-Item -LiteralPath $stderrLog -Force -ErrorAction SilentlyContinue }

$pythonExe = Resolve-MasonConsolePython -ConsoleDir $consoleDir

try {
    $proc = Start-Process `
        -FilePath $pythonExe `
        -ArgumentList @("-m", "uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000") `
        -WorkingDirectory $consoleDir `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog `
        -PassThru `
        -ErrorAction Stop
    $result.start_pid = [int]$proc.Id
}
catch {
    $result.stop_result.error = "start_failed: $($_.Exception.Message)"
    Write-JsonFile -Path $reportPath -Object $result
    exit 1
}

$deadline = (Get-Date).ToUniversalTime().AddSeconds(30)
$ready = $false
while ((Get-Date).ToUniversalTime() -lt $deadline) {
    $h = Invoke-HttpCheck -Url "http://127.0.0.1:8000/api/health" -TimeoutSec 4
    if ($h.status_code -eq 200) {
        $ready = $true
        break
    }
    Start-Sleep -Milliseconds 800
}

$health = Invoke-HttpCheck -Url "http://127.0.0.1:8000/api/health"
$athena = Invoke-HttpCheck -Url "http://127.0.0.1:8000/athena/"
$statusUnsigned = Invoke-HttpCheck -Url "http://127.0.0.1:8000/api/status"
$version = Invoke-HttpCheck -Url "http://127.0.0.1:8000/api/version"

$result.smoke_results.health = [ordered]@{
    url       = "http://127.0.0.1:8000/api/health"
    pass      = ($health.status_code -eq 200)
    status    = $health.status_code
    error     = $health.error
}
$result.smoke_results.athena_pwa = [ordered]@{
    url       = "http://127.0.0.1:8000/athena/"
    pass      = ($athena.status_code -eq 200)
    status    = $athena.status_code
    error     = $athena.error
}
$result.smoke_results.status_unsigned = [ordered]@{
    url       = "http://127.0.0.1:8000/api/status"
    pass      = (($statusUnsigned.status_code -eq 401) -and ([string]$statusUnsigned.body -match "missing_signature_headers"))
    status    = $statusUnsigned.status_code
    error     = $statusUnsigned.error
}
$versionBody = $null
try {
    if ($version.body) { $versionBody = $version.body | ConvertFrom-Json -ErrorAction Stop }
}
catch {
    $versionBody = $null
}
$result.smoke_results.version = [ordered]@{
    url        = "http://127.0.0.1:8000/api/version"
    pass       = ($version.status_code -eq 200 -and $versionBody -and $versionBody.build_timestamp_utc)
    status     = $version.status_code
    build_utc  = if ($versionBody) { [string]$versionBody.build_timestamp_utc } else { $null }
    git_commit = if ($versionBody) { [string]$versionBody.git_commit_short } else { $null }
    error      = $version.error
}

$tailnetIp = Get-TailnetIp
if ($tailnetIp) {
    $result.tailnet_url = "http://$tailnetIp`:8000/athena/"
}

$result.ok = (
    [bool]$result.smoke_results.health.pass -and
    [bool]$result.smoke_results.athena_pwa.pass -and
    [bool]$result.smoke_results.status_unsigned.pass -and
    [bool]$result.smoke_results.version.pass
)
$result.completed_at_utc = (Get-Date).ToUniversalTime().ToString("o")

Write-JsonFile -Path $reportPath -Object $result

if ($result.ok) {
    exit 0
}
exit 1
