param([int]$Tail=800)
$ErrorActionPreference='Stop'

$base="$env:MASON2_BASE"; $rep=Join-Path $base 'reports'

# Build the paths correctly (no trailing commas)
$files = 'http7001.jsonl','watchdog.jsonl' | ForEach-Object { Join-Path $rep $_ }
$logs  = $files | Where-Object { Test-Path $_ }

# Patterns to flag
$pat = '(?i)\brm\s+-rf\b|Remove-Item\s+-Recurse\s+-Force\s+[A-Z]:\\|format\s+c:|cipher\s+/w:|bcdedit\s+/deletevalue\s+'

$hits = @()
foreach($f in $logs){
  $lines = Get-Content -Path $f -Tail $Tail -ErrorAction SilentlyContinue
  foreach($ln in $lines){
    if($ln -match $pat){ $hits += [pscustomobject]@{ file=$f; line=$ln } }
  }
}

if($hits.Count -gt 0){
  foreach($h in $hits){
    $out = @{ ts=(Get-Date).ToString('s'); kind='alert'; subtype='dangerous_pattern'; file=$h.file; line=$h.line } |
           ConvertTo-Json -Compress
    Add-Content -Path (Join-Path $rep 'alerts.jsonl') -Value $out
  }
}

# Always exit 0 so the task shows SUCCESS when there are no hits
exit 0