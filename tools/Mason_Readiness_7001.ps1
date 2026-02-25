[CmdletBinding()]
param(
    [int]$MaxLastOkAgeSec = 300
)

$ErrorActionPreference = "Stop"

# 1) Load Mason base & helper modules
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Base.psm1') -Force
$MasonBase = Get-MasonBase -FromPath $PSScriptRoot
Set-Location $MasonBase

Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Net.psm1') -Force
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\Mason.Logging.psm1') -Force

# 2) Paths & initial state
$Base = "$env:USERPROFILE\Desktop\Mason2"
$log  = Join-Path $Base 'reports\http7001.jsonl'

$now  = Get-Date
$live = $false

# 3) Check the /healthz endpoint on port 7001
try {
    $c = (Invoke-MasonHttp -Uri 'http://127.0.0.1:7001/healthz' -TimeoutSec 3).Content.Trim()
    if ($c -eq 'ok') { $live = $true }
}
catch {
    # leave $live = $false; we'll still log readiness below
}

# 4) Decide if it's "ready" based on last ok hit in http7001.jsonl
$ready = $false

if (Test-Path $log) {
    $tail   = Get-Content $log -Tail 200
    $lastok = ($tail |
        Select-String -SimpleMatch '"event":"postboot_ok"','"event":"hit"' |
        Select-Object -Last 1).Line

    if ($lastok) {
        $ts = ($lastok | ConvertFrom-Json).ts
        if ($ts) {
            $age = ($now - [datetime]$ts).TotalSeconds
            if ($age -lt $MaxLastOkAgeSec) {
                $ready = $true
            }
        }
    }
}

# 5) Build readiness object AS A HASHTABLE (this is the key fix)
$data = @{
    ts    = $now.ToString('s')
    live  = $live
    ready = $ready
}

# 6) Write JSON report
$reportPath = Join-Path $Base 'reports\readiness7001.json'
$data | ConvertTo-Json -Compress | Set-Content $reportPath -Encoding UTF8

# 7) Log via Mason logging pipeline (expects a hashtable for -Data)
Out-MasonJsonl -Kind 'server7001' -Event 'readiness' -Level 'INFO' -Data $data

# 8) Exit code used by other tools / schedulers
if ($live -and $ready) {
    exit 0
}
else {
    exit 2
}
