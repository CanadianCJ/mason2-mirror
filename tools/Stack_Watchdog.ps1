[CmdletBinding()]
param(
    [int]$IntervalSeconds = 120,
    [int]$MaxRestartsPerHour = 3,
    [int]$MaxCycles = 0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($IntervalSeconds -lt 10) {
    throw "IntervalSeconds must be at least 10."
}
if ($MaxRestartsPerHour -lt 1) {
    throw "MaxRestartsPerHour must be at least 1."
}
if ($MaxCycles -lt 0) {
    throw "MaxCycles cannot be negative."
}

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$LogsDir = Join-Path $RepoRoot "logs"
$SmokeScript = Join-Path $PSScriptRoot "SmokeTest_Mason2.ps1"
$StartStackScript = Join-Path $RepoRoot "Start_Mason_Onyx_Stack.ps1"
$LogPath = Join-Path $LogsDir ("stack_watchdog_{0}.log" -f (Get-Date -Format "yyyyMMdd"))
$RestartWindow = New-TimeSpan -Hours 1

if (-not (Test-Path -LiteralPath $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

function Write-WatchdogLog {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")][string]$Level = "INFO"
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format "o"), $Level, $Message
    Write-Host $line
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

function Invoke-PowerShellFileNoProfile {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [string[]]$Arguments = @()
    )

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        return [pscustomobject]@{
            exit_code = 127
            output    = @("Script not found: $ScriptPath")
        }
    }

    $output = @()
    $exitCode = 1
    $previousErrorPreference = $ErrorActionPreference
    try {
        # Allow native stderr output to flow into 2>&1 capture instead of terminating this watchdog loop.
        $ErrorActionPreference = "Continue"
        $output = @(
            & powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1
        )
        $lastExitVar = Get-Variable -Name LASTEXITCODE -ErrorAction SilentlyContinue
        if ($lastExitVar -and $null -ne $lastExitVar.Value) {
            $exitCode = [int]$lastExitVar.Value
        } else {
            $exitCode = 0
        }
    } catch {
        $output += $_.Exception.Message
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            $output += $_.ErrorDetails.Message
        }
        $lastExitVar = Get-Variable -Name LASTEXITCODE -ErrorAction SilentlyContinue
        if ($lastExitVar -and $null -ne $lastExitVar.Value) {
            $nativeExitCode = [int]$lastExitVar.Value
            if ($nativeExitCode -ne 0) {
                $exitCode = $nativeExitCode
            }
        }
    } finally {
        $ErrorActionPreference = $previousErrorPreference
    }

    return [pscustomobject]@{
        exit_code = [int]$exitCode
        output    = @($output)
    }
}

function Write-OutputTail {
    param(
        [Parameter(Mandatory = $true)][string]$Prefix,
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)][object[]]$Output,
        [int]$TailCount = 5
    )

    $lines = @(
        $Output |
            ForEach-Object { [string]$_ } |
            Where-Object { $_ -and $_.Trim() }
    )

    if ($lines.Count -eq 0) {
        return
    }

    $tailLines = @($lines | Select-Object -Last $TailCount)
    foreach ($line in $tailLines) {
        Write-WatchdogLog -Message ("{0}{1}" -f $Prefix, $line)
    }
}

function Prune-RestartHistory {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)][System.Collections.Generic.List[datetime]]$History,
        [Parameter(Mandatory = $true)][datetime]$Now,
        [Parameter(Mandatory = $true)][timespan]$Window
    )

    for ($idx = $History.Count - 1; $idx -ge 0; $idx--) {
        if (($Now - $History[$idx]) -gt $Window) {
            $History.RemoveAt($idx)
        }
    }
}

function Get-NextRestartAllowedAt {
    param(
        [AllowEmptyCollection()]
        [Parameter(Mandatory = $true)][System.Collections.Generic.List[datetime]]$History
    )

    if ($History.Count -eq 0) {
        return Get-Date
    }

    $oldest = @($History | Sort-Object | Select-Object -First 1)[0]
    return $oldest.AddHours(1)
}

$restartHistory = New-Object "System.Collections.Generic.List[datetime]"
$cycleCount = 0

Write-WatchdogLog -Message ("Stack watchdog started (interval={0}s, max_restarts_per_hour={1}, log={2})." -f $IntervalSeconds, $MaxRestartsPerHour, $LogPath)
Write-WatchdogLog -Message "Child commands run with powershell -NoProfile."

if (-not (Test-Path -LiteralPath $SmokeScript)) {
    Write-WatchdogLog -Level "ERROR" -Message ("Smoke test script missing: {0}" -f $SmokeScript)
    exit 2
}

if (-not (Test-Path -LiteralPath $StartStackScript)) {
    Write-WatchdogLog -Level "ERROR" -Message ("Start stack script missing: {0}" -f $StartStackScript)
    exit 2
}

while ($true) {
    $cycleCount++
    $cycleStart = Get-Date
    Prune-RestartHistory -History $restartHistory -Now $cycleStart -Window $RestartWindow

    Write-WatchdogLog -Message ("Cycle {0} started. Restarts in last hour: {1}/{2}" -f $cycleCount, $restartHistory.Count, $MaxRestartsPerHour)

    $smokeRun = Invoke-PowerShellFileNoProfile -ScriptPath $SmokeScript
    Write-OutputTail -Prefix "SmokeTest> " -Output $smokeRun.output

    if ($smokeRun.exit_code -eq 0) {
        Write-WatchdogLog -Message "Smoke test PASS."
    } else {
        Write-WatchdogLog -Level "WARN" -Message ("Smoke test FAIL (exit_code={0})." -f $smokeRun.exit_code)
        Prune-RestartHistory -History $restartHistory -Now (Get-Date) -Window $RestartWindow

        if ($restartHistory.Count -ge $MaxRestartsPerHour) {
            $nextAllowedAt = Get-NextRestartAllowedAt -History $restartHistory
            Write-WatchdogLog -Level "ERROR" -Message ("Restart suppressed by hard backoff. Max {0} restart(s)/hour reached. Next allowed after {1}." -f $MaxRestartsPerHour, $nextAllowedAt.ToString("o"))
        } else {
            Write-WatchdogLog -Level "WARN" -Message "Attempting stack restart via Start_Mason_Onyx_Stack.ps1."
            $startRun = Invoke-PowerShellFileNoProfile -ScriptPath $StartStackScript
            $restartHistory.Add((Get-Date))
            Write-OutputTail -Prefix "StartStack> " -Output $startRun.output

            if ($startRun.exit_code -eq 0) {
                Write-WatchdogLog -Message "Restart command completed successfully."
            } else {
                Write-WatchdogLog -Level "ERROR" -Message ("Restart command failed (exit_code={0})." -f $startRun.exit_code)
            }
        }
    }

    if ($MaxCycles -gt 0 -and $cycleCount -ge $MaxCycles) {
        Write-WatchdogLog -Message ("MaxCycles={0} reached. Exiting watchdog." -f $MaxCycles)
        break
    }

    $elapsedSeconds = [int][Math]::Ceiling(((Get-Date) - $cycleStart).TotalSeconds)
    $sleepSeconds = [Math]::Max(0, $IntervalSeconds - $elapsedSeconds)
    Write-WatchdogLog -Message ("Cycle {0} complete. Sleeping {1}s." -f $cycleCount, $sleepSeconds)
    Start-Sleep -Seconds $sleepSeconds
}

exit 0
