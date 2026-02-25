[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-HttpStatusCode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    try {
        $requestParams = @{
            Uri         = $Url
            Method      = 'GET'
            TimeoutSec  = 10
            ErrorAction = 'Stop'
        }

        if ((Get-Command Invoke-WebRequest).Parameters.ContainsKey('UseBasicParsing')) {
            $requestParams['UseBasicParsing'] = $true
        }

        $response = Invoke-WebRequest @requestParams
        return [int]$response.StatusCode
    }
    catch {
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            return [int]$_.Exception.Response.StatusCode
        }

        return $null
    }
}

function Format-NullableValue {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $Value
    )

    if ($null -eq $Value) {
        return 'null'
    }

    return [string]$Value
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$reportsDir = Join-Path -Path $repoRoot -ChildPath 'reports'
$logsDir = Join-Path -Path $repoRoot -ChildPath 'logs'

New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
New-Item -Path $logsDir -ItemType Directory -Force | Out-Null

$timestamp = Get-Date
$timestampIso = $timestamp.ToString('o')
$timestampFile = $timestamp.ToString('yyyyMMdd_HHmmss')

$jsonPath = Join-Path -Path $reportsDir -ChildPath 'smoke_test_latest.json'
$logPath = Join-Path -Path $logsDir -ChildPath ("smoke_test_{0}.log" -f $timestampFile)

$athenaUrl = 'http://127.0.0.1:8000/api/health'
$onyxUrl = 'http://127.0.0.1:5353/flutter_bootstrap.js'

$athenaStatusCode = Get-HttpStatusCode -Url $athenaUrl
$onyxStatusCode = Get-HttpStatusCode -Url $onyxUrl

$athenaPass = $athenaStatusCode -eq 200
$onyxPass = $onyxStatusCode -eq 200

$requiredPorts = @(8000, 5353)
$listenerRows = @()
$netstatListenerRows = @()
$getNetListenerRows = @()

try {
    $getNetListenerRows = @(Get-NetTCPConnection -State Listen -LocalPort $requiredPorts -ErrorAction Stop)
}
catch {
    $netstatOutput = @(netstat -ano 2>$null)

    foreach ($line in $netstatOutput) {
        if ($line -match '^\s*TCP\s+(?<local>\S+)\s+(?<remote>\S+)\s+(?<state>\S+)\s+(?<pid>\d+)\s*$') {
            $state = $matches['state']
            if ($state -ine 'LISTENING') {
                continue
            }

            $localEndpoint = $matches['local']
            if ($localEndpoint -notmatch ':(?<port>\d+)$') {
                continue
            }

            $port = [int]$matches['port']
            if ($port -notin $requiredPorts) {
                continue
            }

            $localAddress = $localEndpoint.Substring(0, $localEndpoint.LastIndexOf(':'))
            $remoteEndpoint = $matches['remote']
            $remoteAddress = $remoteEndpoint
            $remotePort = 0

            if ($remoteEndpoint -match ':(?<remotePort>\d+)$') {
                $remotePort = [int]$matches['remotePort']
                $remoteAddress = $remoteEndpoint.Substring(0, $remoteEndpoint.LastIndexOf(':'))
            }

            $netstatListenerRows += [pscustomobject]@{
                LocalPort     = $port
                LocalAddress  = $localAddress
                RemoteAddress = $remoteAddress
                RemotePort    = $remotePort
                OwningProcess = [int]$matches['pid']
                State         = $state
            }
        }
    }
}

$listenerRows = @($getNetListenerRows + $netstatListenerRows)

$getNetPortListening = @{
    '8000' = (@($getNetListenerRows | Where-Object { $_.LocalPort -eq 8000 }).Count -gt 0)
    '5353' = (@($getNetListenerRows | Where-Object { $_.LocalPort -eq 5353 }).Count -gt 0)
}

$netstatPortListening = @{
    '8000' = (@($netstatListenerRows | Where-Object { $_.LocalPort -eq 8000 }).Count -gt 0)
    '5353' = (@($netstatListenerRows | Where-Object { $_.LocalPort -eq 5353 }).Count -gt 0)
}

$portListening = @{
    '8000' = ($getNetPortListening['8000'] -or $netstatPortListening['8000'])
    '5353' = ($getNetPortListening['5353'] -or $netstatPortListening['5353'])
}

$portsPass = $portListening['8000'] -and $portListening['5353']
$allPass = $athenaPass -and $onyxPass -and $portsPass
$result = if ($allPass) { 'PASS' } else { 'FAIL' }

$listenerDetails = @(
    $listenerRows |
        Sort-Object -Property LocalPort, LocalAddress, OwningProcess |
        ForEach-Object {
            [pscustomobject]@{
                localPort     = [int]$_.LocalPort
                localAddress  = [string]$_.LocalAddress
                remoteAddress = [string]$_.RemoteAddress
                remotePort    = [int]$_.RemotePort
                owningProcess = [int]$_.OwningProcess
                state         = [string]$_.State
            }
        }
)

$report = [pscustomobject]@{
    timestamp = $timestampIso
    result    = $result
    checks    = [pscustomobject]@{
        athena = [pscustomobject]@{
            url        = $athenaUrl
            statusCode = $athenaStatusCode
            pass       = $athenaPass
        }
        onyx   = [pscustomobject]@{
            url        = $onyxUrl
            statusCode = $onyxStatusCode
            pass       = $onyxPass
        }
    }
    ports     = [pscustomobject]@{
        required  = $requiredPorts
        listening = [pscustomobject]@{
            '8000' = $portListening['8000']
            '5353' = $portListening['5353']
        }
        listeners = $listenerDetails
    }
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $jsonPath -Encoding UTF8

$logLines = @(
    'Mason2 Smoke Test'
    ("Timestamp: {0}" -f $timestampIso)
    ("Result: {0}" -f $result)
    ''
    'HTTP Checks:'
    ("Athena  [GET {0}] status={1} pass={2}" -f $athenaUrl, (Format-NullableValue $athenaStatusCode), $athenaPass)
    ("Onyx    [GET {0}] status={1} pass={2}" -f $onyxUrl, (Format-NullableValue $onyxStatusCode), $onyxPass)
    ''
    'Port Checks:'
    ("Port 8000 listening={0}" -f $portListening['8000'])
    ("Port 5353 listening={0}" -f $portListening['5353'])
    ("Listener rows returned: {0}" -f @($listenerDetails).Count)
    ''
    ("JSON report: {0}" -f $jsonPath)
)

if (@($listenerDetails).Count -gt 0) {
    $logLines += 'Listeners:'
    foreach ($listener in $listenerDetails) {
        $logLines += ("port={0} local={1} remote={2}:{3} pid={4} state={5}" -f `
                $listener.localPort, `
                $listener.localAddress, `
                $listener.remoteAddress, `
                $listener.remotePort, `
                $listener.owningProcess, `
                $listener.state)
    }
}

$exitCode = if ($allPass) { 0 } else { 1 }
$logLines += ("ExitCode: {0}" -f $exitCode)
$logLines | Set-Content -Path $logPath -Encoding UTF8

exit $exitCode
