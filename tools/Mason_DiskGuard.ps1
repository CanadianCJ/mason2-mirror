# Mason_DiskGuard.ps1
# Simple disk space guard for Mason2
# Checks C: free space and writes a JSON report.
# Uses MASON_DISK_MIN_FREE_PCT if set, otherwise defaults to 10%.

$ErrorActionPreference = "Stop"

# Figure out Mason2 base folder and reports folder
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$base       = Split-Path $scriptRoot -Parent
$reportsDir = Join-Path $base "reports"

if (-not (Test-Path $reportsDir)) {
    New-Item -ItemType Directory -Path $reportsDir | Out-Null
}

# Read minimum free percent from env if available
$minPct = 10
$envValMachine = [Environment]::GetEnvironmentVariable("MASON_DISK_MIN_FREE_PCT", "Machine")
$envValUser    = [Environment]::GetEnvironmentVariable("MASON_DISK_MIN_FREE_PCT", "User")

if ([string]::IsNullOrWhiteSpace($envValMachine) -and
    [string]::IsNullOrWhiteSpace($envValUser)) {
    # leave default 10%
} else {
    $raw = if (-not [string]::IsNullOrWhiteSpace($envValMachine)) { $envValMachine } else { $envValUser }
    $tmp = 0
    if ([int]::TryParse($raw, [ref]$tmp)) {
        $minPct = $tmp
    }
}

# Get disk info for C: with permission-safe CIM handling
$disk = $null
$permissionError = $false
$permissionErrorMessage = $null
$cimErrorMessage = $null

try {
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop
}
catch {
    $msg = $_.Exception.Message
    if ($msg -match "Access denied|Access is denied|AccessDenied|0x80070005") {
        $permissionError = $true
        $permissionErrorMessage = $msg
        Write-Warning "Mason DiskGuard: CIM access denied; continuing with permission_error=true."
    }
    else {
        $cimErrorMessage = $msg
        Write-Warning "Mason DiskGuard: Could not read C: disk info. $msg"
    }
}

$totalGB = $null
$freeGB  = $null
$freePct = $null
$below   = $null

if ($disk) {
    $totalGB = [math]::Round(($disk.Size / 1GB), 2)
    $freeGB  = [math]::Round(($disk.FreeSpace / 1GB), 2)

    if ($totalGB -le 0) {
        Write-Warning "Mason DiskGuard: Total disk size is zero or invalid."
    }
    else {
        $freePct = [math]::Round(($freeGB / $totalGB) * 100, 2)
        $below   = $freePct -lt $minPct
    }
}

$report = [pscustomobject]@{
    generated_at_utc   = (Get-Date).ToUniversalTime().ToString("o")
    drive              = "C:"
    total_gb           = $totalGB
    free_gb            = $freeGB
    free_pct           = $freePct
    min_required_pct   = $minPct
    below_threshold    = $below
    permission_error   = $permissionError
    permission_message = $permissionErrorMessage
    cim_error_message  = $cimErrorMessage
}

$reportPath = Join-Path $reportsDir "mason_diskguard_report.json"
$report | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath -Encoding UTF8

Write-Host "Mason DiskGuard report written to $reportPath"

if ($below -eq $true) {
    Write-Warning "Mason DiskGuard: Free disk space is below threshold ($freePct% < $minPct%)."
}
