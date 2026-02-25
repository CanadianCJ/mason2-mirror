[CmdletBinding()]
param(
    [ValidateRange(1, 1440)]
    [int]$IntervalMinutes = 10,
    [switch]$RunOnce
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logsDir = Join-Path $repoRoot 'logs'
if (-not (Test-Path -LiteralPath $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
}

$runStamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd_HHmmss')
$logPath = Join-Path $logsDir ("keepalive_{0}.log" -f $runStamp)

$smokeScript = Join-Path $PSScriptRoot 'SmokeTest_Mason2.ps1'
$stopHardScript = Join-Path $repoRoot 'Stop_Stack_Hard.ps1'
$stopFallbackScript = Join-Path $repoRoot 'Stop_Stack.ps1'
$startStackScript = Join-Path $repoRoot 'Start_Mason_Onyx_Stack.ps1'
$notifyUrl = 'http://127.0.0.1:8000/api/notify'

function Get-UtcNowIso {
    return (Get-Date).ToUniversalTime().ToString('o')
}

function Write-KeepAliveLog {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $line = '[{0}] [{1}] {2}' -f (Get-UtcNowIso), $Level, $Message
    Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8
    Write-Host $line
}

function Invoke-PowerShellFile {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [string[]]$Arguments = @()
    )

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        return [pscustomobject]@{
            ok        = $false
            script    = $ScriptPath
            exit_code = 127
            output    = @()
            message   = "Missing script: $ScriptPath"
        }
    }

    $argList = @(
        '-NoLogo',
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $ScriptPath
    ) + $Arguments

    Write-KeepAliveLog -Message ("Invoking script: {0}" -f $ScriptPath)
    $output = & powershell @argList 2>&1
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }

    $textLines = @()
    foreach ($line in @($output)) {
        $rendered = [string]$line
        if (-not [string]::IsNullOrWhiteSpace($rendered)) {
            $textLines += $rendered
            Write-KeepAliveLog -Message ("  | {0}" -f $rendered)
        }
    }

    return [pscustomobject]@{
        ok        = ($exitCode -eq 0)
        script    = $ScriptPath
        exit_code = $exitCode
        output    = $textLines
        message   = ''
    }
}

function Send-AthenaNotification {
    param(
        [Parameter(Mandatory = $true)][ValidateSet('info', 'warn', 'error')][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][hashtable]$Context,
        [int]$MaxAttempts = 3
    )

    $payload = @{
        timestamp = Get-UtcNowIso
        level     = $Level
        component = 'keepalive'
        message   = $Message
        context   = $Context
    }
    $json = $payload | ConvertTo-Json -Depth 8

    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri $notifyUrl -Method Post -ContentType 'application/json' -Body $json -TimeoutSec 10
            $ok = $true
            if ($response -is [hashtable] -or $response -is [pscustomobject]) {
                if ($null -ne $response.ok) {
                    $ok = [bool]$response.ok
                }
            }

            if ($ok) {
                Write-KeepAliveLog -Message ("Athena notification posted (attempt {0}/{1})." -f $attempt, $MaxAttempts)
                return $true
            }

            Write-KeepAliveLog -Level 'WARN' -Message ("Athena notification returned non-ok response (attempt {0}/{1})." -f $attempt, $MaxAttempts)
        }
        catch {
            Write-KeepAliveLog -Level 'WARN' -Message ("Athena notification failed (attempt {0}/{1}): {2}" -f $attempt, $MaxAttempts, $_.Exception.Message)
        }

        if ($attempt -lt $MaxAttempts) {
            Start-Sleep -Seconds 3
        }
    }

    return $false
}

function Invoke-KeepAliveCycle {
    param(
        [Parameter(Mandatory = $true)][int]$CycleNumber
    )

    $cycleStart = Get-Date
    Write-KeepAliveLog -Message ("KeepAlive cycle #{0} started." -f $CycleNumber)

    $initialSmoke = Invoke-PowerShellFile -ScriptPath $smokeScript
    $initialPass = ($initialSmoke.exit_code -eq 0)

    $restartAttempts = 0
    $stopResult = $null
    $startResult = $null
    $finalSmoke = $initialSmoke
    $finalPass = $initialPass
    $stopScriptUsed = ''

    if (-not $initialPass) {
        $restartAttempts = 1
        Write-KeepAliveLog -Level 'WARN' -Message 'Initial smoke test failed. Starting restart sequence.'

        if (Test-Path -LiteralPath $stopHardScript) {
            $stopScriptUsed = $stopHardScript
            $stopResult = Invoke-PowerShellFile -ScriptPath $stopHardScript
        }
        else {
            Write-KeepAliveLog -Level 'WARN' -Message ("Missing hard stop script: {0}. Falling back to Stop_Stack.ps1." -f $stopHardScript)

            if (Test-Path -LiteralPath $stopFallbackScript) {
                $stopScriptUsed = $stopFallbackScript
                $stopResult = Invoke-PowerShellFile -ScriptPath $stopFallbackScript
            }
            else {
                $stopScriptUsed = 'missing'
                $stopResult = [pscustomobject]@{
                    ok        = $false
                    script    = $stopFallbackScript
                    exit_code = 127
                    output    = @()
                    message   = "Missing stop script: $stopFallbackScript"
                }
                Write-KeepAliveLog -Level 'ERROR' -Message $stopResult.message
            }
        }

        $startResult = Invoke-PowerShellFile -ScriptPath $startStackScript
        $finalSmoke = Invoke-PowerShellFile -ScriptPath $smokeScript
        $finalPass = ($finalSmoke.exit_code -eq 0)
    }

    $finalStatus = if ($finalPass) { 'HEALTHY' } else { 'UNHEALTHY' }
    $initialLabel = if ($initialPass) { 'PASS' } else { 'FAIL' }
    $finalLabel = if ($finalPass) { 'PASS' } else { 'FAIL' }

    $notifyLevel = if ($initialPass -and $finalPass) {
        'info'
    }
    elseif ((-not $initialPass) -and $finalPass) {
        'warn'
    }
    else {
        'error'
    }

    $summary = "KeepAlive cycle #${CycleNumber}: initial_smoke=$initialLabel; restart_attempts=$restartAttempts; final_smoke=$finalLabel; final_status=$finalStatus"

    $context = @{
        cycle_number            = $CycleNumber
        interval_minutes        = $IntervalMinutes
        run_once                = [bool]$RunOnce
        initial_smoke_result    = $initialLabel
        initial_smoke_exit_code = [int]$initialSmoke.exit_code
        restart_attempts        = $restartAttempts
        stop_script_used        = $stopScriptUsed
        stop_exit_code          = if ($null -eq $stopResult) { $null } else { [int]$stopResult.exit_code }
        start_exit_code         = if ($null -eq $startResult) { $null } else { [int]$startResult.exit_code }
        final_smoke_result      = $finalLabel
        final_smoke_exit_code   = [int]$finalSmoke.exit_code
        final_status            = $finalStatus
        cycle_started_utc       = $cycleStart.ToUniversalTime().ToString('o')
        cycle_finished_utc      = (Get-Date).ToUniversalTime().ToString('o')
        notify_url              = $notifyUrl
        log_path                = $logPath
    }

    $logLevel = if ($notifyLevel -eq 'info') { 'INFO' } elseif ($notifyLevel -eq 'warn') { 'WARN' } else { 'ERROR' }
    Write-KeepAliveLog -Level $logLevel -Message $summary

    $posted = Send-AthenaNotification -Level $notifyLevel -Message $summary -Context $context
    if (-not $posted) {
        Write-KeepAliveLog -Level 'ERROR' -Message 'Unable to post Athena notification after retries.'
    }

    return [pscustomobject]@{
        initial_pass = $initialPass
        final_pass   = $finalPass
        level        = $notifyLevel
        summary      = $summary
    }
}

Write-KeepAliveLog -Message 'KeepAlive_Stack started.'
Write-KeepAliveLog -Message ("IntervalMinutes={0}; RunOnce={1}" -f $IntervalMinutes, [bool]$RunOnce)
Write-KeepAliveLog -Message 'Expected runner: powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\tools\KeepAlive_Stack.ps1'

if (-not (Test-Path -LiteralPath $smokeScript)) {
    Write-KeepAliveLog -Level 'ERROR' -Message ("Smoke test script missing: {0}" -f $smokeScript)
    exit 1
}
if (-not (Test-Path -LiteralPath $startStackScript)) {
    Write-KeepAliveLog -Level 'ERROR' -Message ("Start stack script missing: {0}" -f $startStackScript)
    exit 1
}

$cycle = 0
while ($true) {
    $cycle += 1
    $cycleWallStart = Get-Date

    try {
        [void](Invoke-KeepAliveCycle -CycleNumber $cycle)
    }
    catch {
        $errorSummary = "KeepAlive cycle #${cycle} crashed: $($_.Exception.Message)"
        Write-KeepAliveLog -Level 'ERROR' -Message $errorSummary
        $context = @{
            cycle_number      = $cycle
            interval_minutes  = $IntervalMinutes
            run_once          = [bool]$RunOnce
            final_status      = 'ERROR'
            error             = $_.Exception.Message
            cycle_finished_utc = (Get-Date).ToUniversalTime().ToString('o')
            log_path          = $logPath
        }
        [void](Send-AthenaNotification -Level 'error' -Message $errorSummary -Context $context)
    }

    if ($RunOnce) {
        break
    }

    $elapsed = (Get-Date) - $cycleWallStart
    $sleepSeconds = [Math]::Max(0, [int][Math]::Ceiling(($IntervalMinutes * 60) - $elapsed.TotalSeconds))
    Write-KeepAliveLog -Message ("Cycle #{0} complete. Sleeping {1}s before next run." -f $cycle, $sleepSeconds)
    if ($sleepSeconds -gt 0) {
        Start-Sleep -Seconds $sleepSeconds
    }
}

Write-KeepAliveLog -Message 'KeepAlive_Stack exiting.'
exit 0
