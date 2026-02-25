param(
    [string]$AthenaBase = "http://127.0.0.1:8000"
)

$here    = Split-Path -Parent $MyInvocation.MyCommand.Path
$base    = Split-Path -Parent $here
$reports = Join-Path $base "reports"
New-Item -ItemType Directory -Force -Path $reports | Out-Null

$outPath = Join-Path $reports "risk_levels_snapshot.json"

try {
    $res = Invoke-RestMethod -Uri "$AthenaBase/api/risk_levels" -TimeoutSec 10
} catch {
    $err = [pscustomobject]@{
        ok      = $false
        error   = $_.Exception.Message
        ts      = (Get-Date).ToString("o")
        source  = "$AthenaBase/api/risk_levels"
    }
    $err | ConvertTo-Json -Depth 6 | Set-Content -Path $outPath -Encoding UTF8
    Write-Host "[Mason_RiskSnapshot] ERROR: $($err.error)" -ForegroundColor Red
    return
}

$res | ConvertTo-Json -Depth 8 | Set-Content -Path $outPath -Encoding UTF8

# Small console summary for you / logs
if ($res.ok -and $res.areas) {
    $summary = $res.areas | ForEach-Object {
        "{0}: allowed={1} max_auto={2}" -f $_.area, $_.allowed_risk, $_.max_auto_risk
    }
    Write-Host "[Mason_RiskSnapshot] ok. Areas:" -ForegroundColor Green
    $summary | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "[Mason_RiskSnapshot] ok=$($res.ok) but no areas/levels in response." -ForegroundColor Yellow
}

Write-Host "[Mason_RiskSnapshot] Wrote: $outPath"
