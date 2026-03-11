$ErrorActionPreference = "Stop"

function Write-Info {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host ("[INFO] {0}" -f $Message)
}

function Write-Ok {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host ("[OK] {0}" -f $Message)
}

$ScriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ScriptRoot)) {
    $ScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
}
if ([string]::IsNullOrWhiteSpace($ScriptRoot)) {
    $ScriptRoot = (Get-Location).Path
}

$BasePath = Split-Path -Path $ScriptRoot -Parent
$BaseModulePath = Join-Path $BasePath "lib\Mason.Base.psm1"

if (Test-Path -LiteralPath $BaseModulePath) {
    try {
        Import-Module -Name $BaseModulePath -Force -ErrorAction Stop
        if (Get-Command -Name Get-MasonBase -ErrorAction SilentlyContinue) {
            $resolved = Get-MasonBase -FromPath $ScriptRoot
            if (-not [string]::IsNullOrWhiteSpace($resolved)) {
                $BasePath = $resolved
            }
        }
        Write-Ok ("Imported base module: {0}" -f $BaseModulePath)
    } catch {
        Write-Warning ("Failed to import base module at '{0}': {1}" -f $BaseModulePath, $_.Exception.Message)
        Write-Warning "Continuing with fallback stop logic."
    }
} else {
    Write-Warning ("Base module not found at '{0}'. Continuing with fallback stop logic." -f $BaseModulePath)
}

try {
    $tasks = Get-ScheduledTask "Mason2-*" -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -ne "Mason2-Agent" }
    foreach ($task in $tasks) {
        try {
            Disable-ScheduledTask -TaskName $task.TaskName -ErrorAction SilentlyContinue | Out-Null
        } catch {
        }
    }
    Write-Ok ("Disabled {0} scheduled Mason2 tasks." -f $tasks.Count)
} catch {
    Write-Warning ("Scheduled task disable step failed: {0}" -f $_.Exception.Message)
}

$script:HandledPids = New-Object "System.Collections.Generic.HashSet[int]"

function Stop-PidTree {
    param(
        [Parameter(Mandatory = $true)][int]$ProcessId,
        [Parameter(Mandatory = $true)][string]$Reason
    )

    if ($ProcessId -le 0) {
        return
    }
    if ($script:HandledPids.Contains($ProcessId)) {
        return
    }
    $null = $script:HandledPids.Add($ProcessId)

    $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if (-not $proc) {
        Write-Info ("PID {0} already stopped ({1})." -f $ProcessId, $Reason)
        return
    }

    $taskkillOutput = @()
    $taskkillExit = 1
    try {
        $taskkillOutput = @(& taskkill /PID $ProcessId /T /F 2>&1)
        $taskkillExit = $LASTEXITCODE
    } catch {
        $taskkillExit = if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { [int]$LASTEXITCODE } else { 1 }
        $taskkillOutput = @($_.Exception.Message)
    }

    if ($taskkillExit -eq 0) {
        Write-Ok ("Stopped PID {0} ({1}) via taskkill. Reason: {2}" -f $ProcessId, $proc.ProcessName, $Reason)
        return
    }

    Write-Warning ("taskkill failed for PID {0} ({1}) [exit={2}]. Trying Stop-Process." -f $ProcessId, $proc.ProcessName, $taskkillExit)
    foreach ($line in $taskkillOutput) {
        if (-not [string]::IsNullOrWhiteSpace([string]$line)) {
            Write-Info ("taskkill: {0}" -f $line)
        }
    }

    try {
        Stop-Process -Id $ProcessId -Force -ErrorAction Stop
        Write-Ok ("Stopped PID {0} with Stop-Process fallback. Reason: {1}" -f $ProcessId, $Reason)
    } catch {
        Write-Warning ("Unable to stop PID {0}: {1}" -f $ProcessId, $_.Exception.Message)
    }
}

function Get-PidsFromObject {
    param([Parameter(Mandatory = $true)][object]$InputObject)

    $ids = New-Object "System.Collections.Generic.List[int]"

    function Visit-Node {
        param(
            [object]$Value,
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

        if ([string]::IsNullOrWhiteSpace($Name)) {
            return
        }

        if ($Name -match "(?i)(^pid$|_pid$)") {
            $parsed = 0
            if ([int]::TryParse([string]$Value, [ref]$parsed) -and $parsed -gt 0) {
                $ids.Add($parsed)
            }
        }
    }

    Visit-Node -Value $InputObject -Name ""
    return @($ids | Sort-Object -Unique)
}

function Get-ListeningPidsByPort {
    param([Parameter(Mandatory = $true)][int]$Port)

    try {
        $conns = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction Stop
        if (-not $conns) {
            return @()
        }
        return @($conns | Select-Object -ExpandProperty OwningProcess -Unique)
    } catch {
        $pattern = "^\s*TCP\s+\S*:{0}\s+\S+\s+LISTENING\s+(\d+)\s*$" -f $Port
        $pidMatches = @()
        foreach ($line in (& netstat -ano -p tcp 2>$null)) {
            if ($line -match $pattern) {
                $parsedPid = 0
                if ([int]::TryParse([string]$Matches[1], [ref]$parsedPid) -and $parsedPid -gt 0) {
                    $pidMatches += $parsedPid
                }
            }
        }
        return @($pidMatches | Sort-Object -Unique)
    }
}

$StackPidPath = Join-Path $BasePath "state\knowledge\stack_pids.json"
$TargetPorts = @(8383, 8109, 8484, 8000, 5353)

Write-Info ("Using base path: {0}" -f $BasePath)

if (Test-Path -LiteralPath $StackPidPath) {
    try {
        $state = Get-Content -LiteralPath $StackPidPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        $pidsFromState = Get-PidsFromObject -InputObject $state
        if ($pidsFromState.Count -gt 0) {
            Write-Info ("Stopping PIDs from stack state: {0}" -f (($pidsFromState | ForEach-Object { $_.ToString() }) -join ", "))
            foreach ($statePid in $pidsFromState) {
                Stop-PidTree -ProcessId $statePid -Reason "stack_pids.json"
            }
        } else {
            Write-Info "No PID values found in stack_pids.json."
        }
    } catch {
        Write-Warning ("Could not parse stack PID state at '{0}': {1}" -f $StackPidPath, $_.Exception.Message)
    }
} else {
    Write-Info ("PID state file not found: {0}" -f $StackPidPath)
}

foreach ($port in $TargetPorts) {
    $owners = @(Get-ListeningPidsByPort -Port $port)
    if ($owners.Count -eq 0) {
        Write-Info ("No listener on port {0}." -f $port)
        continue
    }

    Write-Info ("Port {0} listener PID(s): {1}" -f $port, (($owners | ForEach-Object { $_.ToString() }) -join ", "))
    foreach ($ownerPid in $owners) {
        Stop-PidTree -ProcessId $ownerPid -Reason ("listening on port {0}" -f $port)
    }
}

Start-Sleep -Milliseconds 300

$remainingByPort = @{}
foreach ($port in $TargetPorts) {
    $remaining = @(Get-ListeningPidsByPort -Port $port)
    $remainingByPort[$port] = $remaining
}

$stillListening = $false
foreach ($port in $TargetPorts) {
    $remaining = @($remainingByPort[$port])
    if ($remaining.Count -gt 0) {
        $stillListening = $true
        Write-Warning ("Port {0} still listening with PID(s): {1}" -f $port, (($remaining | ForEach-Object { $_.ToString() }) -join ", "))
    } else {
        Write-Ok ("Port {0} is clear." -f $port)
    }
}

if ($stillListening) {
    Write-Warning "Stop_All completed with remaining listeners."
    exit 1
}

Write-Ok "Stop_All completed successfully."
