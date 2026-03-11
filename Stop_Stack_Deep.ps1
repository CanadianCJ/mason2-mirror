[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $BaseDir) {
    $BaseDir = (Get-Location).Path
}

$LogsDir = Join-Path $BaseDir "logs"
$PreferredStopAllPath = Join-Path $BaseDir "tools\Stop_All.ps1"
$FallbackStopAllPath = Join-Path $BaseDir "Stop_All.ps1"
$StopAllPath = if (Test-Path -LiteralPath $PreferredStopAllPath) { $PreferredStopAllPath } else { $FallbackStopAllPath }
$StackPidPath = Join-Path $BaseDir "state\knowledge\stack_pids.json"
$TargetPorts = @(8000, 5353, 8383, 8109, 8484)
$AllowedProcessNames = @("python", "pythonw", "pwsh", "powershell", "dart", "dartvm", "flutter")
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$LogPath = Join-Path $LogsDir ("stop_stack_deep_{0}.txt" -f $Timestamp)

if (-not (Test-Path -LiteralPath $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir -Force | Out-Null
}

function Write-DeepLog {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")][string]$Level = "INFO"
    )

    $line = "{0} [{1}] {2}" -f (Get-Date -Format "o"), $Level, $Message
    Write-Host $line
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

function Get-PortFromEndpoint {
    param(
        [Parameter(Mandatory = $true)][string]$Endpoint
    )

    $match = [regex]::Match($Endpoint, ":(\d+)$")
    if (-not $match.Success) {
        return $null
    }

    $parsedPort = 0
    if ([int]::TryParse($match.Groups[1].Value, [ref]$parsedPort)) {
        return $parsedPort
    }

    return $null
}

function Get-PidsFromObject {
    param([Parameter(Mandatory = $true)]$InputObject)

    $ids = New-Object "System.Collections.Generic.List[int]"

    function Visit-Node {
        param(
            $Value,
            [string]$Name
        )

        if ($null -eq $Value) {
            return
        }

        if ($Value -is [System.Collections.IDictionary]) {
            foreach ($key in $Value.Keys) {
                Visit-Node -Value $Value[$key] -Name ([string]$key)
            }
            return
        }

        if ($Value -is [pscustomobject]) {
            foreach ($prop in $Value.PSObject.Properties) {
                Visit-Node -Value $prop.Value -Name $prop.Name
            }
            return
        }

        if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string])) {
            foreach ($item in $Value) {
                Visit-Node -Value $item -Name $Name
            }
            return
        }

        if ($Name -match "(?i)(^pid$|_pid$)") {
            $parsed = 0
            if ([int]::TryParse([string]$Value, [ref]$parsed) -and $parsed -gt 0) {
                $ids.Add($parsed) | Out-Null
            }
        }
    }

    Visit-Node -Value $InputObject -Name ""
    return @($ids | Sort-Object -Unique)
}

function Get-MasonOwnedPidSet {
    param(
        [Parameter(Mandatory = $true)][string]$RepoRoot,
        [Parameter(Mandatory = $true)][string]$PidStatePath
    )

    $owned = New-Object "System.Collections.Generic.HashSet[int]"

    if (Test-Path -LiteralPath $PidStatePath) {
        try {
            $stateRaw = Get-Content -LiteralPath $PidStatePath -Raw -Encoding UTF8
            if ($stateRaw.Trim()) {
                $state = $stateRaw | ConvertFrom-Json -ErrorAction Stop
                foreach ($pidValue in @(Get-PidsFromObject -InputObject $state)) {
                    if ($pidValue -gt 0) {
                        [void]$owned.Add([int]$pidValue)
                    }
                }
            }
        }
        catch {
            Write-DeepLog -Level "WARN" -Message ("Could not parse stack PID state at {0}: {1}" -f $PidStatePath, $_.Exception.Message)
        }
    }

    try {
        $rows = @(Get-CimInstance Win32_Process -ErrorAction Stop)
        foreach ($row in $rows) {
            if (-not $row.CommandLine) { continue }
            if ($row.CommandLine.IndexOf($RepoRoot, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                [void]$owned.Add([int]$row.ProcessId)
            }
        }
    }
    catch {
        Write-DeepLog -Level "WARN" -Message ("Could not inspect process command lines for Mason ownership: {0}" -f $_.Exception.Message)
    }

    return $owned
}

function Invoke-StopAll {
    if (-not (Test-Path -LiteralPath $StopAllPath)) {
        Write-DeepLog -Level "ERROR" -Message ("Stop_All.ps1 not found: {0}" -f $StopAllPath)
        return 1
    }

    Write-DeepLog -Message ("Running Stop_All.ps1 first: {0}" -f $StopAllPath)
    $output = @()
    $exitCode = 1
    $stdoutPath = Join-Path $env:TEMP ("stop_all_stdout_{0}.log" -f ([Guid]::NewGuid().ToString("N")))
    $stderrPath = Join-Path $env:TEMP ("stop_all_stderr_{0}.log" -f ([Guid]::NewGuid().ToString("N")))
    try {
        $proc = Start-Process -FilePath "powershell.exe" -ArgumentList @(
            "-NoLogo",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            $StopAllPath
        ) -NoNewWindow -Wait -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        $exitCode = [int]$proc.ExitCode
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
        if (Test-Path -LiteralPath $stdoutPath) {
            $output += @(Get-Content -LiteralPath $stdoutPath -Encoding UTF8 -ErrorAction SilentlyContinue)
        }
        if (Test-Path -LiteralPath $stderrPath) {
            $output += @(Get-Content -LiteralPath $stderrPath -Encoding UTF8 -ErrorAction SilentlyContinue)
        }
        Remove-Item -LiteralPath $stdoutPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $stderrPath -Force -ErrorAction SilentlyContinue
    }

    foreach ($line in @($output)) {
        if ($null -ne $line) {
            Write-DeepLog -Message ("Stop_All> {0}" -f [string]$line)
        }
    }

    if ($exitCode -ne 0) {
        Write-DeepLog -Level "WARN" -Message ("Stop_All exited with code {0}. Continuing deep stop." -f $exitCode)
    } else {
        Write-DeepLog -Message "Stop_All completed successfully."
    }

    return [int]$exitCode
}

function Get-TargetPortOwners {
    param(
        [Parameter(Mandatory = $true)][int[]]$Ports
    )

    $netstatRows = & netstat -ano 2>$null
    if (-not $netstatRows) {
        return @()
    }

    $procToPorts = @{}

    foreach ($line in $netstatRows) {
        $trimmed = ([string]$line).Trim()
        if (-not $trimmed) {
            continue
        }

        $tokens = $trimmed -split "\s+"
        if ($tokens.Count -lt 4) {
            continue
        }

        $protocol = $tokens[0].ToUpperInvariant()
        if ($protocol -ne "TCP" -and $protocol -ne "UDP") {
            continue
        }

        if ($protocol -eq "TCP") {
            if ($tokens.Count -lt 5) {
                continue
            }

            $state = $tokens[3].ToUpperInvariant()
            if ($state -ne "LISTENING") {
                continue
            }
        }

        $localEndpoint = [string]$tokens[1]
        $localPort = Get-PortFromEndpoint -Endpoint $localEndpoint
        if ($null -eq $localPort -or $Ports -notcontains $localPort) {
            continue
        }

        $ownerPidToken = [string]$tokens[$tokens.Count - 1]
        $ownerProcessId = 0
        if (-not [int]::TryParse($ownerPidToken, [ref]$ownerProcessId)) {
            continue
        }
        if ($ownerProcessId -le 0) {
            continue
        }

        if (-not $procToPorts.ContainsKey($ownerProcessId)) {
            $procToPorts[$ownerProcessId] = New-Object "System.Collections.Generic.List[int]"
        }
        $procToPorts[$ownerProcessId].Add($localPort)
    }

    $owners = New-Object "System.Collections.Generic.List[object]"

    foreach ($ownerProcessId in ($procToPorts.Keys | Sort-Object)) {
        $proc = Get-Process -Id $ownerProcessId -ErrorAction SilentlyContinue
        $procName = if ($proc) { [string]$proc.ProcessName } else { "<exited>" }
        $portArray = @(@($procToPorts[$ownerProcessId]) | Sort-Object -Unique)

        $owners.Add([pscustomobject]@{
                process_id   = [int]$ownerProcessId
                process_name = $procName
                ports        = $portArray
            })
    }

    return @($owners.ToArray())
}

function Stop-AllowedPortOwner {
    param(
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [Parameter(Mandatory = $true)][string]$ProcessName,
        [Parameter(Mandatory = $true)][int[]]$Ports,
        [Parameter(Mandatory = $true)][string[]]$AllowedNames,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[int]]$OwnedPids
    )

    $nameNorm = $ProcessName.Trim().ToLowerInvariant()
    $portsText = ($Ports | Sort-Object | ForEach-Object { $_.ToString() }) -join ", "

    if (-not $nameNorm -or $nameNorm -eq "<exited>") {
        Write-DeepLog -Message ("Skipping PID {0}: process already exited (ports: {1})." -f $ProcessId, $portsText)
        return $false
    }

    if ($AllowedNames -notcontains $nameNorm) {
        Write-DeepLog -Level "WARN" -Message ("Skipping PID {0} ({1}) on port(s) {2}: process name not in allowlist." -f $ProcessId, $ProcessName, $portsText)
        return $false
    }

    if (-not $OwnedPids.Contains([int]$ProcessId)) {
        Write-DeepLog -Level "WARN" -Message ("Skipping PID {0} ({1}) on port(s) {2}: not tracked as Mason-owned." -f $ProcessId, $ProcessName, $portsText)
        return $false
    }

    Write-DeepLog -Message ("Stopping allowlisted PID {0} ({1}) on port(s) {2}..." -f $ProcessId, $ProcessName, $portsText)
    $taskkillOutput = @()
    $taskkillExit = 0
    try {
        $taskkillOutput = @(& taskkill /PID $ProcessId /T /F 2>&1)
        $taskkillExit = $LASTEXITCODE
    } catch {
        $taskkillExit = 1
        $lastExitVar = Get-Variable -Name LASTEXITCODE -ErrorAction SilentlyContinue
        if ($lastExitVar -and $null -ne $lastExitVar.Value) {
            $nativeExitCode = [int]$lastExitVar.Value
            if ($nativeExitCode -ne 0) {
                $taskkillExit = $nativeExitCode
            }
        }
        $taskkillOutput = @($taskkillOutput)
        $taskkillOutput += $_.Exception.Message
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            $taskkillOutput += $_.ErrorDetails.Message
        }
    }

    foreach ($line in @($taskkillOutput)) {
        if ($null -ne $line) {
            Write-DeepLog -Message ("taskkill: {0}" -f [string]$line)
        }
    }

    if ($taskkillExit -ne 0) {
        Write-DeepLog -Level "WARN" -Message ("taskkill exited {0} for PID {1}; trying Stop-Process fallback." -f $taskkillExit, $ProcessId)
        try {
            Stop-Process -Id $ProcessId -Force -ErrorAction Stop
            Write-DeepLog -Message ("Stop-Process fallback succeeded for PID {0}." -f $ProcessId)
        } catch {
            Write-DeepLog -Level "WARN" -Message ("Stop-Process fallback failed for PID {0}: {1}" -f $ProcessId, $_.Exception.Message)
        }
    }

    $stillRunning = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if ($stillRunning) {
        Write-DeepLog -Level "WARN" -Message ("PID {0} still running after stop attempt." -f $ProcessId)
        return $false
    }

    Write-DeepLog -Message ("PID {0} stopped." -f $ProcessId)
    return $true
}

Write-DeepLog -Message "Starting deep stack stop..."
Write-DeepLog -Message ("Log path: {0}" -f $LogPath)
Write-DeepLog -Message ("Stop_All path: {0}" -f $StopAllPath)
Write-DeepLog -Message ("Target ports: {0}" -f (($TargetPorts | ForEach-Object { $_.ToString() }) -join ", "))
Write-DeepLog -Message ("Allowed process names: {0}" -f ($AllowedProcessNames -join ", "))

$masonOwnedPids = Get-MasonOwnedPidSet -RepoRoot $BaseDir -PidStatePath $StackPidPath
Write-DeepLog -Message ("Mason-owned PID candidates: {0}" -f $masonOwnedPids.Count)

$stopAllExitCode = Invoke-StopAll
Start-Sleep -Seconds 1

$totalStopped = 0
$maxPasses = 3
for ($pass = 1; $pass -le $maxPasses; $pass++) {
    $owners = Get-TargetPortOwners -Ports $TargetPorts
    if (-not $owners -or $owners.Count -eq 0) {
        Write-DeepLog -Message ("Deep stop pass {0}: no target port owners remain." -f $pass)
        break
    }

    Write-DeepLog -Message ("Deep stop pass {0}: found {1} PID(s) still holding target ports." -f $pass, $owners.Count)
    foreach ($owner in $owners) {
        $stopped = Stop-AllowedPortOwner `
            -ProcessId ([int]$owner.process_id) `
            -ProcessName ([string]$owner.process_name) `
            -Ports ([int[]]$owner.ports) `
            -AllowedNames $AllowedProcessNames `
            -OwnedPids $masonOwnedPids
        if ($stopped) {
            $totalStopped++
        }
    }

    Start-Sleep -Seconds 1
}

$remainingOwners = Get-TargetPortOwners -Ports $TargetPorts
if ($remainingOwners -and $remainingOwners.Count -gt 0) {
    foreach ($owner in $remainingOwners) {
        $portsText = (([int[]]$owner.ports | Sort-Object | ForEach-Object { $_.ToString() }) -join ", ")
        Write-DeepLog -Level "WARN" -Message ("Remaining port holder PID {0} ({1}) on ports {2}." -f $owner.process_id, $owner.process_name, $portsText)
    }
} else {
    Write-DeepLog -Message "All target ports are clear for allowlisted processes."
}

Write-DeepLog -Message ("Deep stop complete. stop_all_exit={0}, additionally_stopped={1}, remaining_holders={2}" -f $stopAllExitCode, $totalStopped, @($remainingOwners).Count)
