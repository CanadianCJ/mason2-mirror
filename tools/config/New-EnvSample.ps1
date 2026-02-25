param([switch]$WriteEnvIfMissing)

$Base=$env:MASON2_BASE; if([string]::IsNullOrWhiteSpace($Base)){ $Base=Split-Path -Parent $PSCommandPath }
$cfg = Join-Path $Base 'config'; New-Item -ItemType Directory -Force $cfg | Out-Null
$sample = @"
# Mason .env (sample)
# Copy to .env and adjust as needed

MASON_ENV=dev
MASON_LOG_LEVEL=info
MASON_DISK_MIN_FREE_PCT=10
MASON_HIGH_RISK=1
MASON_ALLOW_AUTO_HIGH_RISK=1
MASON_HIGH_RISK_WINDOW=00:00-23:59
MASON_HEALTH_STABLE_RUNS=1
MASON_MONEY_ENABLE=0
"@
$sample | Set-Content -Encoding UTF8 (Join-Path $cfg 'env.sample')

$dotenv = Join-Path $cfg '.env'
if($WriteEnvIfMissing -and -not (Test-Path $dotenv)){
  Copy-Item (Join-Path $cfg 'env.sample') $dotenv -Force
  Write-Host "[ OK ] Wrote default .env"
}else{
  Write-Host "[ OK ] Wrote env.sample"
}
