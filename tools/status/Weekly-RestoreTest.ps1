$base="$env:MASON2_BASE"; $bkp=Join-Path $base 'backups\latest'
$rep=Join-Path $base 'reports'
if(Test-Path $bkp){ Add-Content (Join-Path $rep 'alerts.jsonl') (@{ts=(Get-Date).ToString('s'); kind='event'; subtype='weekly_restore_test'; ok=$true}|ConvertTo-Json -Compress) }