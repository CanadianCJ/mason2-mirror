<#
    Build_SelfState_WithOnyx.ps1
    ----------------------------
    - Calls Build_SelfState.ps1 to build the base self_state.json
    - Checks Onyx health by testing port 5353 on localhost
    - Updates self_state.json.onyx_health with:
        up          (bool)
        last_status ("UP"/"DOWN"/"UNKNOWN")
        last_ok     (string timestamp when last seen UP)
        last_error  (last error string, if any)
    - Writes via temp file + atomic replace to avoid "file in use" errors.
#>

[CmdletBinding()]
param(
    [string]$MasonBasePath
)

# --- Resolve Mason base folder -------------------------------------------------

try {
    $scriptPath = $MyInvocation.MyCommand.Path
    $toolsDir   = Split-Path -Parent $scriptPath

    if (-not $MasonBasePath) {
        $MasonBasePath = Split-Path -Parent $toolsDir
    }

    Write-Host "[INFO] Mason base = $MasonBasePath"
} catch {
    Write-Warning "[WARN] Failed to resolve Mason base: $($_.Exception.Message)"
    throw
}

# --- Step 1: build base self_state --------------------------------------------

Write-Host "[INFO] Running Build_SelfState.ps1..."
$buildScript = Join-Path $toolsDir "Build_SelfState.ps1"
& $buildScript -MasonBasePath $MasonBasePath

$reportsDir = Join-Path $MasonBasePath "reports"
$outFile    = Join-Path $reportsDir "self_state.json"
$tempFile   = $outFile + ".tmp"

if (-not (Test-Path $outFile)) {
    Write-Error "[ERROR] self_state.json not found at $outFile after Build_SelfState.ps1"
    exit 1
}

# --- Step 2: load current state -----------------------------------------------

try {
    $raw   = Get-Content -Path $outFile -Raw
    $state = $raw | ConvertFrom-Json
} catch {
    Write-Error "[ERROR] Failed to load existing self_state.json: $($_.Exception.Message)"
    exit 1
}

$prevOnyx = $state.onyx_health

# Ensure we have an object to overwrite
if (-not $prevOnyx) {
    $prevOnyx = [pscustomobject]@{
        up          = $null
        last_status = "UNKNOWN"
        last_ok     = $null
        last_error  = $null
    }
}

# --- Step 3: check Onyx health (port 5353 on localhost) -----------------------

$port = 5353
$now  = Get-Date
$health = @{
    up          = $false
    last_status = "UNKNOWN"
    last_ok     = $prevOnyx.last_ok
    last_error  = $null
}

try {
    $conn = Test-NetConnection -ComputerName 'localhost' -Port $port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue

    if ($conn -and $conn.TcpTestSucceeded) {
        $health.up          = $true
        $health.last_status = "UP"
        $health.last_ok     = $now.ToString("yyyy-MM-dd HH:mm:ss")
        $health.last_error  = $null
        Write-Host "[OK] Onyx appears UP on port $port."
    }
    else {
        $health.up          = $false
        $health.last_status = "DOWN"
        $health.last_error  = "Port $port not listening or connection failed."
        Write-Warning "[WARN] Onyx appears DOWN on port $port."
    }
} catch {
    $health.up          = $false
    $health.last_status = "DOWN"
    $health.last_error  = $_.Exception.Message
    Write-Warning "[WARN] Onyx health check error: $($health.last_error)"
}

# --- Step 4: update state and write atomically --------------------------------

$state.onyx_health = $health

$json        = $state | ConvertTo-Json -Depth 6
$maxAttempts = 5
$attempt     = 0
$written     = $false

while (-not $written -and $attempt -lt $maxAttempts) {
    $attempt++
    try {
        $json | Set-Content -Path $tempFile -Encoding UTF8
        Move-Item -Path $tempFile -Destination $outFile -Force
        $written = $true
    } catch {
        Write-Warning "[WARN] Attempt $attempt to update self_state.json with onyx_health failed: $($_.Exception.Message)"
        Start-Sleep -Milliseconds 200
    }
}

if ($written) {
    Write-Host "[OK] self_state.json updated with onyx_health -> $outFile"
} else {
    Write-Error "[ERROR] Failed to update self_state.json with onyx_health after $maxAttempts attempts."
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}
