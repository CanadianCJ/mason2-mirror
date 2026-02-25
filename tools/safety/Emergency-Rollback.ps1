param([switch]$Force)
$ErrorActionPreference='Stop'
$base="$env:MASON2_BASE"; $bkp=Join-Path $base 'backups\latest'; $dest=$base
if(-not (Test-Path $bkp)){ Write-Host "No backups found at $bkp" -ForegroundColor Yellow; exit 1 }
if(-not $Force){ Write-Host "About to restore from $bkp to $dest (read-only safe copy). Use -Force to overwrite." -ForegroundColor Yellow; exit 0 }
Copy-Item -Path (Join-Path $bkp '*') -Destination $dest -Recurse -Force
Add-Content (Join-Path $base 'reports\alerts.jsonl') (@{ts=(Get-Date).ToString('s'); kind='event'; subtype='rollback'; from=$bkp} | ConvertTo-Json -Compress)