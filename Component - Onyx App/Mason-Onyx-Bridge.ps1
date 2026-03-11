param(
  [string]$ApiBase = "http://127.0.0.1:8000",
  [Parameter(Mandatory)] [string]$Title,
  [Parameter(Mandatory)] [string]$Body
)
$ErrorActionPreference = "Stop"

if (-not $env:ONYX_API_KEY) {
  $persisted = [Environment]::GetEnvironmentVariable("ONYX_API_KEY","User")
  if ($persisted) { $env:ONYX_API_KEY = $persisted }
  else { throw "Set ONYX_API_KEY first (backend window prints it on start)." }
}

$payload = @{ title=$Title; body=$Body } | ConvertTo-Json
$resp = Invoke-RestMethod -Method Post -Uri "$ApiBase/onyx/updates" `
  -Headers @{ 'x-onyx-key' = $env:ONYX_API_KEY } `
  -ContentType 'application/json' -Body $payload
Write-Host "Published: $Title" -ForegroundColor Green
$resp | ConvertTo-Json -Depth 5
