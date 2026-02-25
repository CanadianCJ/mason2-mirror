

# === Mason teacher patch patch-001 (plan teacher-mason-plan-002) ===
# Mason Watchdog Improvements - Prevent Restart Storms

# Initialize or update restart tracking variables
if (-not (Test-Path variable:RestartHistory)) {
    $global:RestartHistory = @()
}

function Register-Restart {
    $now = Get-Date
    $global:RestartHistory += $now
    # Keep only restarts within last 10 minutes
    $global:RestartHistory = $global:RestartHistory | Where-Object { $_ -gt $now.AddMinutes(-10) }
}

function Can-Restart {
    # Allow max 5 restarts in 10 minutes
    if ($global:RestartHistory.Count -ge 5) {
        return $false
    }
    return $true
}

function Restart-ServiceWithGuard {
    if (-not (Can-Restart)) {
        Write-Output "[Watchdog] Restart suppressed to prevent restart storm."
        return
    }
    Register-Restart
    Write-Output "[Watchdog] Restarting service at $(Get-Date)"
    # Insert actual restart logic here, e.g., Restart-Service -Name 'MasonService'
}

# Example usage:
# Restart-ServiceWithGuard

# === end Mason teacher patch patch-001 ===

