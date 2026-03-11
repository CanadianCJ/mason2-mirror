[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-FlutterLauncher {
    $candidates = @("flutter.bat", "flutter")
    foreach ($candidate in $candidates) {
        $cmd = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($cmd) {
            return [string]$cmd.Source
        }
    }
    throw "Flutter launcher not found on PATH."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptDir "..\.."))
$portsPath = Join-Path $repoRoot "config\ports.json"

$bindHost = "127.0.0.1"
$onyxPort = 5353

if (Test-Path -LiteralPath $portsPath) {
    try {
        $ports = Get-Content -LiteralPath $portsPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        if ($ports.bind_host) {
            $bindHost = [string]$ports.bind_host
        }
        if ($ports.ports -and ($ports.ports.PSObject.Properties.Name -contains "onyx")) {
            $tmp = 0
            if ([int]::TryParse([string]$ports.ports.onyx, [ref]$tmp) -and $tmp -gt 0 -and $tmp -le 65535) {
                $onyxPort = $tmp
            }
        }
    }
    catch {
        # Keep defaults if ports contract is unreadable.
    }
}

if ($env:MASON_BIND_HOST) {
    $bindHost = [string]$env:MASON_BIND_HOST
}
if ($env:MASON_ONYX_PORT) {
    $tmp = 0
    if ([int]::TryParse([string]$env:MASON_ONYX_PORT, [ref]$tmp) -and $tmp -gt 0 -and $tmp -le 65535) {
        $onyxPort = $tmp
    }
}

if ($bindHost -ne "127.0.0.1") {
    throw "Onyx bind host must be 127.0.0.1."
}

Write-Host ("[Onyx] Starting Onyx web server on http://{0}:{1}..." -f $bindHost, $onyxPort)
Set-Location -LiteralPath $scriptDir
Write-Host "[Onyx] Working directory: $(Get-Location)"

$flutterExe = Resolve-FlutterLauncher
$env:CI = "true"
$env:FLUTTER_SUPPRESS_ANALYTICS = "true"
$env:PUB_ENVIRONMENT = "onyx_start_5353"

& $flutterExe `
  --no-version-check `
  run `
  -d web-server `
  --web-hostname $bindHost `
  --web-port $onyxPort
