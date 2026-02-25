# Mason_Health_Aggregator.ps1
# Simple, clean health snapshot for Mason + components.
# Reads a few known JSON summaries if they exist and writes a single aggregated JSON file.

$ErrorActionPreference = "Stop"

# ---------------------------
# 1. Resolve Mason base paths
# ---------------------------
$scriptRoot = $PSScriptRoot
$masonBase  = Split-Path $scriptRoot -Parent

$logsDir    = Join-Path $masonBase "logs"
$reportsDir = Join-Path $masonBase "reports"
$configDir  = Join-Path $masonBase "config"

if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
}

# Common report/config paths
$onyxHealthPath   = Join-Path $reportsDir "onyx_health_summary.json"
$riskStatePath    = Join-Path $reportsDir "risk_state.json"
$riskPolicyPath   = Join-Path $configDir  "risk_policy.json"
$ueConfigPath     = Join-Path $configDir  "universal_evolution.json"
$diskGuardLogPath = Join-Path $logsDir    "disk_guard.log"

# ---------------------------
# 2. Helper to load JSON safely
# ---------------------------
function Get-JsonSafe {
    param(
        [string]$Path
    )
    if (-not (Test-Path $Path)) {
        return $null
    }

    try {
        $raw = Get-Content -Path $Path -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($raw)) {
            return $null
        }
        return $raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return [pscustomobject]@{
            error   = "Failed to parse JSON"
            path    = $Path
            message = $_.Exception.Message
        }
    }
}

# ---------------------------
# 3. Collect basic system info
# ---------------------------
$sysInfo = [pscustomobject]@{
    machineName   = $env:COMPUTERNAME
    userName      = $env:USERNAME
    osVersion     = (Get-CimInstance Win32_OperatingSystem).Version
    totalMemoryMB = [int]((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB)
    freeSpace     = @()
}

# Collect free space for main drives
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $sysInfo.freeSpace += [pscustomobject]@{
        name    = $_.Name
        root    = $_.Root
        freeMB  = [int]($_.Free / 1MB)
        usedMB  = [int](($_.Used) / 1MB)
        totalMB = [int](($_.Used + $_.Free) / 1MB)
    }
}

# ---------------------------
# 4. Load component summaries
# ---------------------------
$onyxHealth   = Get-JsonSafe -Path $onyxHealthPath
$riskState    = Get-JsonSafe -Path $riskStatePath
$riskPolicy   = Get-JsonSafe -Path $riskPolicyPath
$ueConfig     = Get-JsonSafe -Path $ueConfigPath

# Disk guard log (plain text, if present)
$diskGuardLog = $null
if (Test-Path $diskGuardLogPath) {
    try {
        $diskGuardLog = Get-Content -Path $diskGuardLogPath -Tail 100 -ErrorAction Stop
    }
    catch {
        $diskGuardLog = @("Failed to read disk_guard.log: " + $_.Exception.Message)
    }
}

# ---------------------------
# 5. Build aggregated health object
# ---------------------------
$health = [pscustomobject]@{
    generatedAt  = (Get-Date).ToString("o")
    masonBase    = $masonBase

    system       = $sysInfo

    files = [pscustomobject]@{
        onyx_health_summary = $onyxHealthPath
        risk_state          = $riskStatePath
        risk_policy         = $riskPolicyPath
        ue_config           = $ueConfigPath
        disk_guard_log      = $diskGuardLogPath
    }

    onyx_health = $onyxHealth
    risk        = [pscustomobject]@{
        state  = $riskState
        policy = $riskPolicy
    }
    ue          = $ueConfig

    disk_guard  = [pscustomobject]@{
        last_lines = $diskGuardLog
    }
}

# ---------------------------
# 6. Write output JSON
# ---------------------------
$outPath = Join-Path $reportsDir "mason_health_aggregated.json"
$health | ConvertTo-Json -Depth 8 | Set-Content -Path $outPath -Encoding UTF8

Write-Host "Mason health aggregated to:"
Write-Host "  $outPath"
