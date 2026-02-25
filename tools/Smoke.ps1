param([string]$Base)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($Base)) { $Base = $env:MASON2_BASE }
if ([string]::IsNullOrWhiteSpace($Base)) { $Base = Split-Path -Parent $PSCommandPath }
$manifest = Get-Content (Join-Path $Base 'manifest.json') -Raw | ConvertFrom-Json


$fail = @()
foreach($m in $manifest.modules){
$ok = $false
if ($m.health.type -eq 'http'){
try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 -Uri $m.health.url; $ok = ($r.StatusCode -eq 200) } catch { $ok = $false }
}
if ($ok){ Write-Host ("[PASS] {0} -> {1}" -f $m.id,$m.health.url) -ForegroundColor Green }
else { Write-Host ("[FAIL] {0}" -f $m.id) -ForegroundColor Red; $fail += $m.id }
}


if ($fail.Count -gt 0){ exit 2 } else { exit 0 }