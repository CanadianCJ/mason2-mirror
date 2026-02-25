param([int]$Tail=400)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$base="$env:MASON2_BASE"; $rep=Join-Path $base 'reports'; $outDir=Join-Path $base 'forensics'
$src = @($rep,(Join-Path $base 'tools'),(Join-Path $base 'state'))
$zip = Join-Path $outDir ("forensic_" + (Get-Date -Format yyyyMMdd_HHmmss) + ".zip")
$temp = Join-Path $env:TEMP ("mason_forensic_" + [guid]::NewGuid())
New-Item -ItemType Directory -Force $temp | Out-Null
$src | % { if(Test-Path $_){ Copy-Item $_ -Recurse -Force -Destination (Join-Path $temp (Split-Path $_ -Leaf)) } }
(Get-ScheduledTask -TaskName 'Mason-*' -ErrorAction SilentlyContinue | Select TaskName,State,LastRunTime,NextRunTime) |
  ConvertTo-Json | Out-File (Join-Path $temp 'tasks.json') -Encoding utf8
systeminfo | Out-File (Join-Path $temp 'systeminfo.txt') -Encoding utf8
[System.IO.Compression.ZipFile]::CreateFromDirectory($temp,$zip)
Remove-Item $temp -Recurse -Force
$evt = @{ts=(Get-Date).ToString('s'); kind='event'; subtype='forensic_snapshot'; zip=$zip} | ConvertTo-Json -Compress
Add-Content (Join-Path $rep 'alerts.jsonl') $evt