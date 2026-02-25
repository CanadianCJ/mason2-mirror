[CmdletBinding()]
param(
    [int[]]$Ports = @(7001),
    [switch]$VerifyOnly
)

$ErrorActionPreference = "Continue"

function Write-FirewallLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$ts] [Mason_Firewall_LoopbackOnly] [$Level] $Message"
}

function Test-FirewallRulePresent {
    param([string]$DisplayName)

    if (-not (Get-Command Get-NetFirewallRule -ErrorAction SilentlyContinue)) {
        return $false
    }

    try {
        $rule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue | Select-Object -First 1
        return [bool]$rule
    }
    catch {
        return $false
    }
}

$root = Split-Path -Parent $PSScriptRoot
$reportsDir = Join-Path $root "reports"
$reportPath = Join-Path $reportsDir "mason_firewall_loopback.json"
New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null

$results = New-Object System.Collections.Generic.List[object]

foreach ($port in $Ports) {
    $allowName = "Mason2-$port-Allow-Loopback"
    $blockName = "Mason2-$port-Block-Remote"

    $applyError = $null

    if (-not $VerifyOnly) {
        try {
            & netsh advfirewall firewall delete rule name="$allowName" | Out-Null
            & netsh advfirewall firewall add rule name="$allowName" dir=in action=allow protocol=TCP localport=$port remoteip=127.0.0.1,::1 profile=any | Out-Null
            & netsh advfirewall firewall delete rule name="$blockName" | Out-Null
            & netsh advfirewall firewall add rule name="$blockName" dir=in action=block protocol=TCP localport=$port remoteip=any profile=any | Out-Null
        }
        catch {
            $applyError = $_.Exception.Message
        }
    }

    $allowPresent = Test-FirewallRulePresent -DisplayName $allowName
    $blockPresent = Test-FirewallRulePresent -DisplayName $blockName
    $pass = ($allowPresent -and $blockPresent)

    $result = [pscustomobject]@{
        port             = [int]$port
        allow_rule       = $allowName
        block_rule       = $blockName
        allow_present    = $allowPresent
        block_present    = $blockPresent
        apply_error      = $applyError
        verify_only      = [bool]$VerifyOnly
        pass             = $pass
    }
    $results.Add($result)

    if ($pass) {
        Write-FirewallLog "Loopback-only firewall rules verified for port $port."
    }
    else {
        Write-FirewallLog "Loopback-only firewall rules NOT verified for port $port." "WARN"
        if ($applyError) {
            Write-FirewallLog ("Apply error: {0}" -f $applyError) "WARN"
        }
    }
}

$report = [ordered]@{
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
    verify_only      = [bool]$VerifyOnly
    results          = @($results)
    overall_pass     = (@($results | Where-Object { -not $_.pass }).Count -eq 0)
}

$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $reportPath -Encoding UTF8
Write-FirewallLog ("Report: {0}" -f $reportPath)

if ($report.overall_pass) {
    exit 0
}
exit 2
