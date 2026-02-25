param(
  [string]$Base = $env:MASON2_BASE,
  [int]$KeepBackups = 5,
  [int]$DaysLogs = 14,
  [int]$DaysForensics = 14,
  [int]$DaysReports = 14,
  [switch]$Force,
  [switch]$Confirm
)
$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($Base)) { throw "MASON2_BASE not set" }

$ops = @()

# Reports: rotate .jsonl older than N days and stale snapshots
$rep = Join-Path $Base 'reports'
if (Test-Path $rep) {
  Get-ChildItem $rep -File -Filter *.jsonl -EA SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysReports) } |
    ForEach-Object { $ops += @{Action='Delete';Path=$_.FullName;Reason="old report"} }
  Get-ChildItem $rep -File -Include 'dashboard-*.json','status-*.json','hud-*.json' -EA SilentlyContinue |
    ForEach-Object { $ops += @{Action='Delete';Path=$_.FullName;Reason='stale snapshot'} }
}

# Logs
$logs = Join-Path $Base 'logs'
if (Test-Path $logs) {
  Get-ChildItem $logs -Recurse -File -Include *.log,*.txt -EA SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysLogs) } |
    ForEach-Object { $ops += @{Action='Delete';Path=$_.FullName;Reason='old log'} }
}

# Forensics
$foren = Join-Path $Base 'forensics'
if (Test-Path $foren) {
  Get-ChildItem $foren -Recurse -File -Include *.zip,*.json,*.txt -EA SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DaysForensics) } |
    ForEach-Object { $ops += @{Action='Delete';Path=$_.FullName;Reason='old forensics'} }
}

# Backups: keep last N
$bk = Join-Path $Base 'backups\history'
if (Test-Path $bk) {
  $keep = Get-ChildItem $bk -File -Filter mason_*.zip -EA SilentlyContinue |
          Sort-Object LastWriteTime -Descending | Select-Object -First $KeepBackups
  Get-ChildItem $bk -File -Filter mason_*.zip -EA SilentlyContinue |
    Where-Object { $keep -notcontains $_ } |
    ForEach-Object { $ops += @{Action='Delete';Path=$_.FullName;Reason='exceeds keep'} }
}

# Stage, dist caches, queue retry >7d, big images
$stage = Join-Path $Base 'stage'
if (Test-Path $stage) {
  Get-ChildItem $stage -Recurse -Force -EA SilentlyContinue |
    ForEach-Object { $ops += @{Action='Delete';Path=$_.FullName;Reason='stage cleanup'} }
}
$dist = Join-Path $Base 'dist'
if (Test-Path $dist) {
  Get-ChildItem $dist -Recurse -Directory -Include cache,tmp,.cache,.temp -EA SilentlyContinue |
    ForEach-Object { $ops += @{Action='Delete';Path=$_.FullName;Reason='dist cache'} }
}
$qr = Join-Path $Base 'queue\retry'
if (Test-Path $qr) {
  Get-ChildItem $qr -Recurse -File -EA SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
    ForEach-Object { $ops += @{Action='Delete';Path=$_.FullName;Reason='stale retry'} }
}
Get-ChildItem $Base -Recurse -File -Include *.png,*.jpg,*.jpeg -EA SilentlyContinue |
  Where-Object { $_.Length -gt 25MB } |
  ForEach-Object { $ops += @{Action='Delete';Path=$_.FullName;Reason='image >25MB'} }

$ops = $ops | Sort-Object Path -Unique
"{0} candidate deletions" -f $ops.Count | Write-Host
foreach($op in $ops){
  "{0}  {1}" -f $op.Action, $op.Path | Write-Host
  if ($Force -and -not $Confirm) {
    try { Remove-Item -LiteralPath $op.Path -Recurse -Force -EA SilentlyContinue } catch {}
  }
}
Write-Host "Done." -ForegroundColor Yellow