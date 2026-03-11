# Stop-Onyx5353.ps1
# Safely stop anything listening on TCP port 5353 (Onyx web server)

Write-Host "[Onyx] Looking for processes listening on port 5353..."

try {
    $connections = Get-NetTCPConnection -LocalPort 5353 -ErrorAction SilentlyContinue
} catch {
    Write-Warning ("[Onyx] Failed to query TCP connections on port 5353: {0}" -f $_.Exception.Message)
    return
}

if (-not $connections) {
    Write-Host "[Onyx] Nothing is listening on port 5353."
    return
}

# Get unique PIDs from OwningProcess
$pids = $connections | Select-Object -ExpandProperty OwningProcess | Sort-Object -Unique

foreach ($procId in $pids) {
    try {
        $proc = Get-Process -Id $procId -ErrorAction Stop
        Write-Host ("[Onyx] Stopping process {0} (PID {1})..." -f $proc.ProcessName, $procId)
        Stop-Process -Id $procId -Force -ErrorAction Stop
        Write-Host ("[Onyx] Process {0} stopped." -f $procId)
    } catch {
        Write-Warning ("[Onyx] Failed to stop PID {0}: {1}" -f $procId, $_.Exception.Message)
    }
}

Write-Host "[Onyx] Stop-Onyx5353.ps1 completed."
