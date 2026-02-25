param(
  [string]$AthenaBase = "http://127.0.0.1:8000"
)

$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$base    = Split-Path -Parent $here
$reports = Join-Path $base "reports"
New-Item -ItemType Directory -Force -Path $reports | Out-Null

# 1) Status
$status = Invoke-RestMethod -Method Get -Uri "$AthenaBase/api/mason_status" -TimeoutSec 10

# 2) Chat ping
$payload = @{ message = "ping" } | ConvertTo-Json -Compress
$chat = Invoke-RestMethod -Method Post -Uri "$AthenaBase/api/chat" -ContentType "application/json" -Body $payload -TimeoutSec 10

$out = [pscustomobject]@{
  ts        = (Get-Date).ToString("o")
  status_ok = $status.ok
  chat_ok   = $chat.ok
  reply     = $chat.reply
  model     = $chat.model
  via       = $chat.via
}

$out | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 (Join-Path $reports "athena_smoketest.json")

if ($out.status_ok -and $out.chat_ok) {
  Write-Host "[Athena_SmokeTest] Result: healthy"
} else {
  Write-Host "[Athena_SmokeTest] Result: unhealthy"
}
