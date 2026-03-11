$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
if (-not $env:ONYX_API_KEY) {
  $existing = [Environment]::GetEnvironmentVariable("ONYX_API_KEY","User")
  if ($existing) { $env:ONYX_API_KEY = $existing } else {
    $env:ONYX_API_KEY = [guid]::NewGuid().ToString("N")
    [Environment]::SetEnvironmentVariable("ONYX_API_KEY", $env:ONYX_API_KEY, "User")
    Write-Host "Generated ONYX_API_KEY (User env): $($env:ONYX_API_KEY)" -ForegroundColor Yellow
  }
}
Write-Host "Backend starting at http://127.0.0.1:8000   (KEY: $($env:ONYX_API_KEY))" -ForegroundColor Green
py -3 -m uvicorn api:app --reload --host 127.0.0.1 --port 8000
