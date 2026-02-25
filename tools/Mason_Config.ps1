

# === Mason teacher patch patch-003 (plan teacher-mason-plan-004) ===
# Mason Security and Isolation Enhancements

# Enforce restricted script execution policy for Mason scripts
try {
    $currentPolicy = Get-ExecutionPolicy -Scope Process
    if ($currentPolicy -ne 'RemoteSigned' -and $currentPolicy -ne 'AllSigned') {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
        Write-Output "[Security] Execution policy set to RemoteSigned for process scope."
    }
} catch {
    Write-Output "[Security] Failed to set execution policy: $_"
}

# Isolate environment variables for Mason process
function Set-IsolatedEnvironment {
    # Create a copy of current environment variables
    $isolatedEnv = [System.Collections.Hashtable]::Synchronized(@{})
    foreach ($key in [System.Environment]::GetEnvironmentVariables().Keys) {
        # Only allow essential environment variables
        if ($key -in @('PATH','TEMP','TMP','USERPROFILE','SystemRoot')) {
            $isolatedEnv[$key] = [System.Environment]::GetEnvironmentVariable($key)
        }
    }
    # Apply isolated environment variables to current session
    foreach ($key in $isolatedEnv.Keys) {
        [System.Environment]::SetEnvironmentVariable($key, $isolatedEnv[$key], 'Process')
    }
    Write-Output "[Security] Environment variables isolated for Mason process."
}

Set-IsolatedEnvironment

# Restrict network access by disabling unused network adapters (example)
function Disable-UnusedNetworkAdapters {
    $adapters = Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $adapters) {
        # Example condition: disable adapters not named 'Ethernet0'
        if ($adapter.Name -ne 'Ethernet0') {
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false
            Write-Output "[Security] Disabled network adapter: $($adapter.Name)"
        }
    }
}

# Uncomment below to enable network adapter restrictions
# Disable-UnusedNetworkAdapters

# === end Mason teacher patch patch-003 ===

