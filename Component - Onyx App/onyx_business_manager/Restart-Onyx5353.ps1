Param()

Set-Location -Path (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "[Onyx] Restarting Onyx web server on port 5353..."

# Stop anything on 5353
& .\Stop-Onyx5353.ps1

# Small pause
Start-Sleep -Seconds 2

# Start fresh
& .\Start-Onyx5353.ps1

