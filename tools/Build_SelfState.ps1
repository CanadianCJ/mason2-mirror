<# 
    Build_SelfState.ps1
    --------------------
    Builds Mason's self_state.json in C:\...\Mason2\reports\self_state.json

    - Detects Mason base folder from script location.
    - Loads Phase 1 totals from the latest nightly snapshot if available.
    - Writes self_state.json via a temp file + atomic replace to avoid
      "file in use" errors when Athena/server.py are reading it.

    This script does NOT add Onyx health; that is done by
    Build_SelfState_WithOnyx.ps1 after this runs.
#>

[CmdletBinding()]
param(
    [string]$MasonBasePath
)

# --- Resolve Mason base folder -------------------------------------------------

try {
    # tools directory (this script lives in Mason2\tools)
    $scriptPath = $MyInvocation.MyCommand.Path
    $toolsDir   = Split-Path -Parent $scriptPath

    if (-not $MasonBasePath) {
        # Parent of tools is Mason root
        $MasonBasePath = Split-Path -Parent $toolsDir
    }

    Write-Host "[INFO] Mason base = $MasonBasePath"
} catch {
    Write-Warning "[WARN] Failed to resolve Mason base: $($_.Exception.Message)"
    throw
}

# --- Ensure reports folder exists ---------------------------------------------

$reportsDir = Join-Path $MasonBasePath "reports"
if (-not (Test-Path $reportsDir)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}
$outFile  = Join-Path $reportsDir "self_state.json"
$tempFile = $outFile + ".tmp"

# --- Phase 1 totals: try from latest nightly snapshot -------------------------

$phase        = 1
$phaseTotal   = $null
$phaseApplied = $null
$phasePending = $null
$phaseMissing = $null

$nightlyDir = Join-Path $reportsDir "nightly"
if (Test-Path $nightlyDir) {
    $nightlies = Get-ChildItem -Path $nightlyDir -Filter '*.json' |
                 Sort-Object LastWriteTime -Descending

    if ($nightlies.Count -gt 0) {
        $latestNightly = $nightlies[0].FullName
        try {
            $nightlyJson = Get-Content -Path $latestNightly -Raw | ConvertFrom-Json
            if ($nightlyJson -and $nightlyJson.phase1) {
                $phase        = $nightlyJson.phase1.phase
                $phaseTotal   = $nightlyJson.phase1.total
                $phaseApplied = $nightlyJson.phase1.applied
                $phasePending = $nightlyJson.phase1.pending
                $phaseMissing = $nightlyJson.phase1.missing
            }
        } catch {
            Write-Warning "[WARN] Failed to read nightly phase1 snapshot '$latestNightly': $($_.Exception.Message)"
        }
    }
}

$phaseTotals = @{
    total   = $phaseTotal
    applied = $phaseApplied
    pending = $phasePending
    missing = $phaseMissing
}

# --- Build self_state object ---------------------------------------------------

$state = [ordered]@{
    generatedAt = (Get-Date).ToString("o")     # ISO 8601
    basePath    = $MasonBasePath
    phase       = $phase
    phaseStatus = @{
        # NOTE: key is 'totals' (lowercase) to match server.py
        totals = $phaseTotals
    }
}

# Provide a safe default onyx_health block; Build_SelfState_WithOnyx.ps1
# will overwrite this with real values.
$state["onyx_health"] = @{
    up          = $null
    last_status = "UNKNOWN"
    last_ok     = $null
    last_error  = $null
}

# --- Write via temp file + atomic replace (to avoid file-lock errors) ---------

$json        = $state | ConvertTo-Json -Depth 6
$maxAttempts = 5
$attempt     = 0
$written     = $false

while (-not $written -and $attempt -lt $maxAttempts) {
    $attempt++
    try {
        # Write to temp file first
        $json | Set-Content -Path $tempFile -Encoding UTF8

        # Atomically replace the old self_state.json
        Move-Item -Path $tempFile -Destination $outFile -Force

        $written = $true
    } catch {
        Write-Warning "[WARN] Attempt $attempt to write self_state.json failed: $($_.Exception.Message)"
        Start-Sleep -Milliseconds 200
    }
}

if ($written) {
    Write-Host "[OK] self_state.json written to $outFile"
} else {
    Write-Error "[ERROR] Failed to write self_state.json after $maxAttempts attempts."
    # Best effort cleanup of temp file
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -ErrorAction SilentlyContinue
    }
}
